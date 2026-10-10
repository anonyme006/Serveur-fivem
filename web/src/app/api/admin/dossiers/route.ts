import { NextResponse } from "next/server";
import { isStaff, requireUser, writeAudit } from "@/lib/auth/session";
import { execute, query } from "@/lib/db/pool";
import { z } from "zod";
import { verifyCsrfToken } from "@/lib/security/csrf";
import { randomToken } from "@/lib/security/hmac";
import type { RowDataPacket } from "mysql2";

export async function GET() {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });
  if (!isStaff(auth.session.role)) {
    return NextResponse.json({ error: "Permissions insuffisantes" }, { status: 403 });
  }

  const rows = await query<RowDataPacket[]>(
    `SELECT * FROM portal_dossiers ORDER BY updated_at DESC LIMIT 100`,
  );
  return NextResponse.json({
    dossiers: rows.map((r) => ({
      id: Number(r.id),
      publicId: String(r.public_id),
      citizenid: String(r.citizenid),
      title: String(r.title),
      status: String(r.status),
      notes: r.notes ? String(r.notes) : null,
      createdAt: String(r.created_at),
    })),
  });
}

const createSchema = z.object({
  citizenid: z.string().min(3).max(50),
  title: z.string().min(3).max(180),
  notes: z.string().max(4000).optional(),
  csrfToken: z.string().min(16),
});

export async function POST(request: Request) {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });
  if (!isStaff(auth.session.role)) {
    return NextResponse.json({ error: "Permissions insuffisantes" }, { status: 403 });
  }

  const body = await request.json().catch(() => null);
  const parsed = createSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalide" }, { status: 400 });
  }
  if (!verifyCsrfToken(auth.session, parsed.data.csrfToken)) {
    return NextResponse.json({ error: "CSRF invalide" }, { status: 403 });
  }

  const publicId = randomToken(4).slice(0, 8).toUpperCase();
  await execute(
    `INSERT INTO portal_dossiers (public_id, citizenid, title, notes, created_by)
     VALUES (:publicId, :citizenid, :title, :notes, :createdBy)`,
    {
      publicId,
      citizenid: parsed.data.citizenid,
      title: parsed.data.title,
      notes: parsed.data.notes ?? null,
      createdBy: auth.session.accountId,
    },
  );

  await writeAudit({
    actorAccountId: auth.session.accountId,
    actorDiscordId: auth.session.discordId,
    action: "admin.dossier.create",
    targetType: "dossier",
    targetId: publicId,
  });

  return NextResponse.json({ ok: true, publicId });
}
