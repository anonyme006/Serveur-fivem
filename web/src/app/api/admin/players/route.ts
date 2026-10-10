import { NextResponse } from "next/server";
import { isStaff, requireUser, writeAudit } from "@/lib/auth/session";
import { adminSearchSchema } from "@/lib/validations";
import { searchPlayersAdmin } from "@/lib/qbox/adapter";

export async function GET(request: Request) {
  const auth = await requireUser();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });
  if (!isStaff(auth.session.role)) {
    return NextResponse.json({ error: "Permissions insuffisantes" }, { status: 403 });
  }

  const url = new URL(request.url);
  const parsed = adminSearchSchema.safeParse({ q: url.searchParams.get("q") || "" });
  if (!parsed.success) {
    return NextResponse.json({ error: "Recherche trop courte" }, { status: 400 });
  }

  const players = await searchPlayersAdmin(parsed.data.q);
  await writeAudit({
    actorAccountId: auth.session.accountId,
    actorDiscordId: auth.session.discordId,
    action: "admin.players.search",
    meta: { q: parsed.data.q, count: players.length },
  });

  return NextResponse.json({ players });
}
