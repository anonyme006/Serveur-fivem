import { NextResponse } from "next/server";
import { linkCodeSchema } from "@/lib/validations";
import { requireUser, writeAudit } from "@/lib/auth/session";
import { verifyCsrfToken } from "@/lib/security/csrf";
import { rateLimit } from "@/lib/security/rate-limit";
import { sha256 } from "@/lib/security/hmac";
import { execute, query } from "@/lib/db/pool";
import type { RowDataPacket } from "mysql2";

export async function POST(request: Request) {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  const limited = rateLimit(`link:${auth.session.accountId}`, 8, 60_000);
  if (!limited.ok) {
    return NextResponse.json({ error: "Trop de tentatives" }, { status: 429 });
  }

  const body = await request.json().catch(() => null);
  const parsed = linkCodeSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.issues[0]?.message }, { status: 400 });
  }

  if (!verifyCsrfToken(auth.session, parsed.data.csrfToken)) {
    return NextResponse.json({ error: "CSRF invalide" }, { status: 403 });
  }

  const codeHash = sha256(parsed.data.code);
  const rows = await query<RowDataPacket[]>(
    `SELECT id, citizenid, license, fivem_discord_id, expires_at, used_at
     FROM portal_link_codes
     WHERE code_hash = :hash
     LIMIT 1`,
    { hash: codeHash },
  );

  const row = rows[0];
  if (!row || row.used_at) {
    return NextResponse.json({ error: "Code invalide ou déjà utilisé" }, { status: 400 });
  }

  if (new Date(String(row.expires_at)).getTime() < Date.now()) {
    return NextResponse.json({ error: "Code expiré" }, { status: 400 });
  }

  const fivemDiscord = row.fivem_discord_id ? String(row.fivem_discord_id) : null;
  if (fivemDiscord && auth.session.discordId && fivemDiscord !== auth.session.discordId) {
    await writeAudit({
      actorAccountId: auth.session.accountId,
      actorDiscordId: auth.session.discordId,
      action: "link.denied_discord_mismatch",
      targetType: "citizenid",
      targetId: String(row.citizenid),
      meta: { fivemDiscord },
    });
    return NextResponse.json(
      { error: "Le Discord en jeu ne correspond pas à ce compte." },
      { status: 403 },
    );
  }

  // Révoque les liaisons actives existantes pour ce license / compte
  await execute(
    `UPDATE portal_account_links
     SET is_active = 0, revoked_at = UTC_TIMESTAMP()
     WHERE (account_id = :accountId OR license = :license) AND is_active = 1`,
    { accountId: auth.session.accountId, license: String(row.license) },
  );

  await execute(
    `INSERT INTO portal_account_links
      (account_id, license, linked_citizenid, is_active)
     VALUES (:accountId, :license, :citizenid, 1)`,
    {
      accountId: auth.session.accountId,
      license: String(row.license),
      citizenid: String(row.citizenid),
    },
  );

  await execute(
    `UPDATE portal_link_codes
     SET used_at = UTC_TIMESTAMP(), used_by_account_id = :accountId
     WHERE id = :id`,
    { accountId: auth.session.accountId, id: Number(row.id) },
  );

  await writeAudit({
    actorAccountId: auth.session.accountId,
    actorDiscordId: auth.session.discordId,
    action: "link.success",
    targetType: "license",
    targetId: String(row.license),
    meta: { citizenid: String(row.citizenid) },
  });

  return NextResponse.json({
    ok: true,
    license: String(row.license),
    citizenid: String(row.citizenid),
  });
}
