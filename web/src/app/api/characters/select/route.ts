import { NextResponse } from "next/server";
import { selectCharacterSchema } from "@/lib/validations";
import {
  getActiveLink,
  getSession,
  requireUser,
  writeAudit,
} from "@/lib/auth/session";
import { verifyCsrfToken } from "@/lib/security/csrf";
import { getCharactersByLicense } from "@/lib/qbox/adapter";
import { execute } from "@/lib/db/pool";

export async function GET() {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  const link = await getActiveLink(auth.session.accountId!);
  if (!link) {
    return NextResponse.json({ linked: false, characters: [] });
  }

  const characters = await getCharactersByLicense(link.license);
  return NextResponse.json({
    linked: true,
    selectedCitizenId: auth.session.selectedCitizenId ?? null,
    characters,
  });
}

export async function POST(request: Request) {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  const body = await request.json().catch(() => null);
  const parsed = selectCharacterSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.issues[0]?.message }, { status: 400 });
  }
  if (!verifyCsrfToken(auth.session, parsed.data.csrfToken)) {
    return NextResponse.json({ error: "CSRF invalide" }, { status: 403 });
  }

  const link = await getActiveLink(auth.session.accountId!);
  if (!link) {
    return NextResponse.json({ error: "Compte non lié" }, { status: 403 });
  }

  const characters = await getCharactersByLicense(link.license);
  const selected = characters.find((c) => c.citizenid === parsed.data.citizenid);
  if (!selected) {
    return NextResponse.json(
      { error: "Personnage introuvable sur ce compte" },
      { status: 403 },
    );
  }

  const session = await getSession();
  session.selectedCitizenId = selected.citizenid;
  await session.save();

  await execute(
    `UPDATE portal_sessions SET selected_citizenid = :citizenid WHERE id = :id`,
    { citizenid: selected.citizenid, id: session.sessionId },
  );

  await writeAudit({
    actorAccountId: auth.session.accountId,
    actorDiscordId: auth.session.discordId,
    action: "character.select",
    targetType: "citizenid",
    targetId: selected.citizenid,
  });

  return NextResponse.json({ ok: true, citizenid: selected.citizenid });
}
