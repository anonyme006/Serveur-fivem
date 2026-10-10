import { NextResponse } from "next/server";
import { requireUser, requireSelectedCharacter, writeAudit } from "@/lib/auth/session";
import { ticketCreateSchema } from "@/lib/validations";
import { verifyCsrfToken } from "@/lib/security/csrf";
import { execute, query } from "@/lib/db/pool";
import { randomToken } from "@/lib/security/hmac";
import type { RowDataPacket } from "mysql2";

export async function GET() {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  const rows = await query<RowDataPacket[]>(
    `SELECT id, public_id, subject, status, priority, citizenid, created_at, updated_at
     FROM portal_tickets
     WHERE account_id = :accountId
     ORDER BY updated_at DESC
     LIMIT 50`,
    { accountId: auth.session.accountId },
  );

  return NextResponse.json({
    tickets: rows.map((r) => ({
      id: Number(r.id),
      publicId: String(r.public_id),
      subject: String(r.subject),
      status: String(r.status),
      priority: String(r.priority),
      citizenid: r.citizenid ? String(r.citizenid) : null,
      createdAt: String(r.created_at),
      updatedAt: String(r.updated_at),
    })),
  });
}

export async function POST(request: Request) {
  const auth = await requireSelectedCharacter();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  const body = await request.json().catch(() => null);
  const parsed = ticketCreateSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.issues[0]?.message }, { status: 400 });
  }
  if (!verifyCsrfToken(auth.session, parsed.data.csrfToken)) {
    return NextResponse.json({ error: "CSRF invalide" }, { status: 403 });
  }

  const publicId = randomToken(4).slice(0, 8).toUpperCase();
  const result = await execute(
    `INSERT INTO portal_tickets (public_id, account_id, citizenid, subject)
     VALUES (:publicId, :accountId, :citizenid, :subject)`,
    {
      publicId,
      accountId: auth.session.accountId,
      citizenid: auth.citizenid,
      subject: parsed.data.subject,
    },
  );

  await execute(
    `INSERT INTO portal_ticket_messages (ticket_id, account_id, body, is_staff)
     VALUES (:ticketId, :accountId, :body, 0)`,
    {
      ticketId: result.insertId,
      accountId: auth.session.accountId,
      body: parsed.data.body,
    },
  );

  await writeAudit({
    actorAccountId: auth.session.accountId,
    actorDiscordId: auth.session.discordId,
    action: "ticket.create",
    targetType: "ticket",
    targetId: publicId,
  });

  return NextResponse.json({ ok: true, publicId });
}
