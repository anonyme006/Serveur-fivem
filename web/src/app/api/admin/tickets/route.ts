import { NextResponse } from "next/server";
import { isStaff, requireUser, writeAudit } from "@/lib/auth/session";
import { execute, query } from "@/lib/db/pool";
import { z } from "zod";
import { verifyCsrfToken } from "@/lib/security/csrf";
import type { RowDataPacket } from "mysql2";

export async function GET() {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });
  if (!isStaff(auth.session.role)) {
    return NextResponse.json({ error: "Permissions insuffisantes" }, { status: 403 });
  }

  const rows = await query<RowDataPacket[]>(
    `SELECT t.*, a.discord_username
     FROM portal_tickets t
     LEFT JOIN portal_accounts a ON a.id = t.account_id
     ORDER BY t.updated_at DESC LIMIT 100`,
  );

  return NextResponse.json({
    tickets: rows.map((r) => ({
      id: Number(r.id),
      publicId: String(r.public_id),
      subject: String(r.subject),
      status: String(r.status),
      priority: String(r.priority),
      citizenid: r.citizenid ? String(r.citizenid) : null,
      discordUsername: r.discord_username ? String(r.discord_username) : null,
      createdAt: String(r.created_at),
      updatedAt: String(r.updated_at),
    })),
  });
}

const updateSchema = z.object({
  publicId: z.string().min(4).max(16),
  status: z.enum(["open", "pending", "resolved", "closed"]),
  csrfToken: z.string().min(16),
});

export async function PATCH(request: Request) {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });
  if (!isStaff(auth.session.role)) {
    return NextResponse.json({ error: "Permissions insuffisantes" }, { status: 403 });
  }

  const body = await request.json().catch(() => null);
  const parsed = updateSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalide" }, { status: 400 });
  }
  if (!verifyCsrfToken(auth.session, parsed.data.csrfToken)) {
    return NextResponse.json({ error: "CSRF invalide" }, { status: 403 });
  }

  await execute(
    `UPDATE portal_tickets
     SET status = :status, assigned_to = :staff
     WHERE public_id = :publicId`,
    {
      status: parsed.data.status,
      staff: auth.session.accountId,
      publicId: parsed.data.publicId,
    },
  );

  await writeAudit({
    actorAccountId: auth.session.accountId,
    actorDiscordId: auth.session.discordId,
    action: "admin.ticket.update",
    targetType: "ticket",
    targetId: parsed.data.publicId,
    meta: { status: parsed.data.status },
  });

  return NextResponse.json({ ok: true });
}
