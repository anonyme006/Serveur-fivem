import { NextResponse } from "next/server";
import { getDiscordAuthUrl } from "@/lib/auth/discord";
import { randomToken } from "@/lib/security/hmac";
import { rateLimit } from "@/lib/security/rate-limit";
import { getSession } from "@/lib/auth/session";

export async function GET(request: Request) {
  const ip = request.headers.get("x-forwarded-for") || "local";
  const limited = rateLimit(`oauth:${ip}`, 20, 60_000);
  if (!limited.ok) {
    return NextResponse.json({ error: "Trop de requêtes" }, { status: 429 });
  }

  // Dev bypass for local QA without Discord app
  if (process.env.DEV_AUTH_BYPASS === "true") {
    return NextResponse.redirect(new URL("/api/auth/callback?dev=1", request.url));
  }

  try {
    const state = randomToken(16);
    const session = await getSession();
    session.isLoggedIn = false;
    (session as { oauthState?: string }).oauthState = state;
    await session.save();

    // iron-session typing: stash state on cookie via custom field
    const url = getDiscordAuthUrl(state);
    const res = NextResponse.redirect(url);
    res.cookies.set("portal_oauth_state", state, {
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: 600,
    });
    return res;
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message }, { status: 500 });
  }
}
