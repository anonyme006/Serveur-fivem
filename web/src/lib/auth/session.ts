import { getIronSession, type SessionOptions } from "iron-session";
import { cookies } from "next/headers";
import { execute, query } from "@/lib/db/pool";
import { randomToken, sha256 } from "@/lib/security/hmac";
import type { RowDataPacket } from "mysql2";

export type PortalSessionData = {
  sessionId?: string;
  accountId?: number;
  discordId?: string;
  discordUsername?: string;
  discordAvatar?: string | null;
  role?: "player" | "moderator" | "admin" | "owner";
  selectedCitizenId?: string | null;
  csrfSecret?: string;
  isLoggedIn?: boolean;
};

export const sessionOptions: SessionOptions = {
  password: process.env.SESSION_SECRET || "dev-only-change-me-32chars-minimum!!",
  cookieName: "serenity_portal",
  cookieOptions: {
    secure: process.env.NODE_ENV === "production",
    httpOnly: true,
    sameSite: "lax",
    path: "/",
  },
};

export async function getSession() {
  return getIronSession<PortalSessionData>(await cookies(), sessionOptions);
}

export async function createDbSession(accountId: number, meta?: { ip?: string; ua?: string }) {
  const id = crypto.randomUUID();
  const csrfSecret = randomToken(32);
  const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 7);

  await execute(
    `INSERT INTO portal_sessions
      (id, account_id, csrf_secret, ip_hash, user_agent_hash, expires_at)
     VALUES (:id, :accountId, :csrf, :ip, :ua, :expires)`,
    {
      id,
      accountId,
      csrf: csrfSecret,
      ip: meta?.ip ? sha256(meta.ip) : null,
      ua: meta?.ua ? sha256(meta.ua) : null,
      expires: expiresAt,
    },
  );

  return { id, csrfSecret, expiresAt };
}

export async function revokeDbSession(sessionId: string) {
  await execute(
    `UPDATE portal_sessions SET revoked_at = UTC_TIMESTAMP() WHERE id = :id`,
    { id: sessionId },
  );
}

export async function getActiveLink(accountId: number) {
  const rows = await query<RowDataPacket[]>(
    `SELECT id, license, user_id, linked_citizenid
     FROM portal_account_links
     WHERE account_id = :accountId AND is_active = 1
     LIMIT 1`,
    { accountId },
  );
  return rows[0]
    ? {
        id: Number(rows[0].id),
        license: String(rows[0].license),
        userId: rows[0].user_id == null ? null : Number(rows[0].user_id),
        linkedCitizenId: rows[0].linked_citizenid
          ? String(rows[0].linked_citizenid)
          : null,
      }
    : null;
}

export function isStaff(role?: string | null) {
  return role === "moderator" || role === "admin" || role === "owner";
}

export function isAdmin(role?: string | null) {
  return role === "admin" || role === "owner";
}

export async function requireUser() {
  const session = await getSession();
  if (!session.isLoggedIn || !session.accountId || !session.sessionId) {
    return { ok: false as const, status: 401, error: "Non authentifié" };
  }
  return { ok: true as const, session };
}

export async function requireSelectedCharacter() {
  const auth = await requireUser();
  if (!auth.ok) return auth;

  const link = await getActiveLink(auth.session.accountId!);
  if (!link) {
    return { ok: false as const, status: 403, error: "Compte Discord non lié" };
  }

  const citizenid = auth.session.selectedCitizenId;
  if (!citizenid) {
    return { ok: false as const, status: 409, error: "Aucun personnage sélectionné" };
  }

  // Ownership check: character license must match linked license
  const rows = await query<RowDataPacket[]>(
    `SELECT citizenid, license FROM players WHERE citizenid = :citizenid LIMIT 1`,
    { citizenid },
  );
  const row = rows[0];
  if (!row || String(row.license) !== link.license) {
    return { ok: false as const, status: 403, error: "Personnage non autorisé" };
  }

  return {
    ok: true as const,
    session: auth.session,
    citizenid,
    license: link.license,
  };
}

export async function writeAudit(input: {
  actorAccountId?: number | null;
  actorDiscordId?: string | null;
  action: string;
  targetType?: string;
  targetId?: string;
  ip?: string;
  meta?: Record<string, unknown>;
}) {
  await execute(
    `INSERT INTO portal_audit_log
      (actor_account_id, actor_discord_id, action, target_type, target_id, ip_hash, meta_json)
     VALUES (:actor, :discord, :action, :targetType, :targetId, :ip, :meta)`,
    {
      actor: input.actorAccountId ?? null,
      discord: input.actorDiscordId ?? null,
      action: input.action,
      targetType: input.targetType ?? null,
      targetId: input.targetId ?? null,
      ip: input.ip ? sha256(input.ip) : null,
      meta: input.meta ? JSON.stringify(input.meta) : null,
    },
  );
}
