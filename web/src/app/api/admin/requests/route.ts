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
    `SELECT * FROM portal_admin_requests ORDER BY created_at DESC LIMIT 100`,
  );
  return NextResponse.json({
    requests: rows.map((r) => ({
      id: Number(r.id),
      publicId: String(r.public_id),
      accountId: Number(r.account_id),
      citizenid: r.citizenid ? String(r.citizenid) : null,
      requestType: String(r.request_type),
      status: String(r.status),
      createdAt: String(r.created_at),
    })),
  });
}

const patchSchema = z.object({
  publicId: z.string().min(4).max(16),
  status: z.enum(["pending", "approved", "rejected"]),
  note: z.string().max(255).optional(),
  csrfToken: z.string().min(16),
});

export async function PATCH(request: Request) {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });
  if (!isStaff(auth.session.role)) {
    return NextResponse.json({ error: "Permissions insuffisantes" }, { status: 403 });
  }

  const body = await request.json().catch(() => null);
  const parsed = patchSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalide" }, { status: 400 });
  }
  if (!verifyCsrfToken(auth.session, parsed.data.csrfToken)) {
    return NextResponse.json({ error: "CSRF invalide" }, { status: 403 });
  }

  // Staff may approve/reject requests but NEVER mutate money/vehicles/permissions of players here.
  await execute(
    `UPDATE portal_admin_requests
     SET status = :status, handled_by = :staff, handled_note = :note
     WHERE public_id = :publicId`,
    {
      status: parsed.data.status,
      staff: auth.session.accountId,
      note: parsed.data.note ?? null,
      publicId: parsed.data.publicId,
    },
  );

  await writeAudit({
    actorAccountId: auth.session.accountId,
    actorDiscordId: auth.session.discordId,
    action: "admin.request.update",
    targetType: "admin_request",
    targetId: parsed.data.publicId,
    meta: { status: parsed.data.status },
  });

  return NextResponse.json({ ok: true });
}
