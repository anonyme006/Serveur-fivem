import { NextResponse } from "next/server";
import { getActiveLink, getSession } from "@/lib/auth/session";
import { discordAvatarUrl } from "@/lib/auth/discord";
import { branding } from "@/lib/branding";

export async function GET() {
  const session = await getSession();
  if (!session.isLoggedIn || !session.accountId) {
    return NextResponse.json({ authenticated: false, branding });
  }

  const link = await getActiveLink(session.accountId);
  return NextResponse.json({
    authenticated: true,
    branding,
    user: {
      accountId: session.accountId,
      discordId: session.discordId,
      discordUsername: session.discordUsername,
      avatarUrl: discordAvatarUrl(session.discordId || "0", session.discordAvatar),
      role: session.role,
      selectedCitizenId: session.selectedCitizenId ?? null,
      linked: Boolean(link),
      license: link?.license ?? null,
    },
  });
}
