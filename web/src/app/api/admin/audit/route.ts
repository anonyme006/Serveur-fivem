import { NextResponse } from "next/server";
import { isAdmin, requireUser } from "@/lib/auth/session";
import { query } from "@/lib/db/pool";
import type { RowDataPacket } from "mysql2";

export async function GET() {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });
  if (!isAdmin(auth.session.role)) {
    return NextResponse.json({ error: "Permissions insuffisantes" }, { status: 403 });
  }

  const rows = await query<RowDataPacket[]>(
    `SELECT id, actor_account_id, actor_discord_id, action, target_type, target_id, created_at
     FROM portal_audit_log
     ORDER BY created_at DESC
     LIMIT 150`,
  );

  return NextResponse.json({
    entries: rows.map((r) => ({
      id: Number(r.id),
      actorAccountId: r.actor_account_id == null ? null : Number(r.actor_account_id),
      actorDiscordId: r.actor_discord_id ? String(r.actor_discord_id) : null,
      action: String(r.action),
      targetType: r.target_type ? String(r.target_type) : null,
      targetId: r.target_id ? String(r.target_id) : null,
      createdAt: String(r.created_at),
    })),
  });
}
