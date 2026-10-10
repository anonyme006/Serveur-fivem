import { NextResponse } from "next/server";
import { getSession, revokeDbSession, writeAudit } from "@/lib/auth/session";

export async function POST(request: Request) {
  const session = await getSession();
  if (session.sessionId) {
    await revokeDbSession(session.sessionId);
  }
  if (session.accountId) {
    await writeAudit({
      actorAccountId: session.accountId,
      actorDiscordId: session.discordId,
      action: "auth.logout",
      ip: request.headers.get("x-forwarded-for") || undefined,
    });
  }
  session.destroy();
  return NextResponse.json({ ok: true });
}
