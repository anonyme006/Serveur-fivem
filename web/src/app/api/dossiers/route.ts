import { NextResponse } from "next/server";
import { isStaff, requireSelectedCharacter, requireUser } from "@/lib/auth/session";
import { query } from "@/lib/db/pool";
import type { RowDataPacket } from "mysql2";

export async function GET() {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  if (isStaff(auth.session.role)) {
    const rows = await query<RowDataPacket[]>(
      `SELECT id, public_id, citizenid, title, status, created_at, updated_at
       FROM portal_dossiers ORDER BY updated_at DESC LIMIT 100`,
    );
    return NextResponse.json({
      dossiers: rows.map((r) => ({
        id: Number(r.id),
        publicId: String(r.public_id),
        citizenid: String(r.citizenid),
        title: String(r.title),
        status: String(r.status),
        createdAt: String(r.created_at),
        updatedAt: String(r.updated_at),
      })),
    });
  }

  const selected = await requireSelectedCharacter();
  if (!selected.ok) {
    return NextResponse.json({ error: selected.error }, { status: selected.status });
  }

  const rows = await query<RowDataPacket[]>(
    `SELECT id, public_id, citizenid, title, status, created_at, updated_at
     FROM portal_dossiers
     WHERE citizenid = :citizenid
     ORDER BY updated_at DESC LIMIT 50`,
    { citizenid: selected.citizenid },
  );

  return NextResponse.json({
    dossiers: rows.map((r) => ({
      id: Number(r.id),
      publicId: String(r.public_id),
      citizenid: String(r.citizenid),
      title: String(r.title),
      status: String(r.status),
      createdAt: String(r.created_at),
      updatedAt: String(r.updated_at),
    })),
  });
}
