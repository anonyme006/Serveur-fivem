import { execute, query } from "@/lib/db/pool";
import type { RowDataPacket } from "mysql2";

const DISCORD_API = "https://discord.com/api/v10";

export function getDiscordAuthUrl(state: string) {
  const clientId = process.env.DISCORD_CLIENT_ID;
  const redirectUri = process.env.DISCORD_REDIRECT_URI;
  if (!clientId || !redirectUri) {
    throw new Error("DISCORD_CLIENT_ID / DISCORD_REDIRECT_URI manquants");
  }

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: "identify",
    state,
    prompt: "none",
  });

  return `https://discord.com/api/oauth2/authorize?${params.toString()}`;
}

export async function exchangeDiscordCode(code: string) {
  const body = new URLSearchParams({
    client_id: process.env.DISCORD_CLIENT_ID || "",
    client_secret: process.env.DISCORD_CLIENT_SECRET || "",
    grant_type: "authorization_code",
    code,
    redirect_uri: process.env.DISCORD_REDIRECT_URI || "",
  });

  const res = await fetch(`${DISCORD_API}/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });

  if (!res.ok) {
    throw new Error(`Discord token exchange failed (${res.status})`);
  }

  return res.json() as Promise<{ access_token: string; token_type: string }>;
}

export async function fetchDiscordUser(accessToken: string) {
  const res = await fetch(`${DISCORD_API}/users/@me`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) throw new Error(`Discord user fetch failed (${res.status})`);
  return res.json() as Promise<{
    id: string;
    username: string;
    global_name?: string | null;
    avatar?: string | null;
  }>;
}

export async function upsertPortalAccount(user: {
  id: string;
  username: string;
  avatar?: string | null;
}) {
  await execute(
    `INSERT INTO portal_accounts (discord_id, discord_username, discord_avatar)
     VALUES (:id, :username, :avatar)
     ON DUPLICATE KEY UPDATE
       discord_username = VALUES(discord_username),
       discord_avatar = VALUES(discord_avatar),
       updated_at = CURRENT_TIMESTAMP`,
    {
      id: user.id,
      username: user.username,
      avatar: user.avatar ?? null,
    },
  );

  const rows = await query<RowDataPacket[]>(
    `SELECT id, discord_id, discord_username, discord_avatar, role, is_banned
     FROM portal_accounts WHERE discord_id = :id LIMIT 1`,
    { id: user.id },
  );

  const row = rows[0];
  if (!row) throw new Error("Impossible de créer le compte portail");
  if (Number(row.is_banned) === 1) throw new Error("Compte banni");

  return {
    id: Number(row.id),
    discordId: String(row.discord_id),
    discordUsername: String(row.discord_username),
    discordAvatar: row.discord_avatar ? String(row.discord_avatar) : null,
    role: String(row.role) as "player" | "moderator" | "admin" | "owner",
  };
}

export function discordAvatarUrl(discordId: string, avatar: string | null | undefined) {
  if (!avatar) return `https://cdn.discordapp.com/embed/avatars/${Number(discordId) % 5}.png`;
  return `https://cdn.discordapp.com/avatars/${discordId}/${avatar}.png?size=128`;
}
