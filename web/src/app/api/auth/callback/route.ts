import { NextResponse } from "next/server";
import {
  exchangeDiscordCode,
  fetchDiscordUser,
  upsertPortalAccount,
} from "@/lib/auth/discord";
import {
  createDbSession,
  getSession,
  writeAudit,
} from "@/lib/auth/session";
import { cookies } from "next/headers";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const jar = await cookies();

  try {
    let account: Awaited<ReturnType<typeof upsertPortalAccount>>;

    if (process.env.DEV_AUTH_BYPASS === "true" && url.searchParams.get("dev") === "1") {
      account = await upsertPortalAccount({
        id: process.env.DEV_DISCORD_ID || "100000000000000001",
        username: process.env.DEV_DISCORD_USERNAME || "alex.dev",
        avatar: "abcd",
      });
    } else {
      const code = url.searchParams.get("code");
      const state = url.searchParams.get("state");
      const expected = jar.get("portal_oauth_state")?.value;
      if (!code || !state || !expected || state !== expected) {
        return NextResponse.redirect(new URL("/login?error=oauth_state", request.url));
      }

      const token = await exchangeDiscordCode(code);
      const user = await fetchDiscordUser(token.access_token);
      account = await upsertPortalAccount({
        id: user.id,
        username: user.global_name || user.username,
        avatar: user.avatar,
      });
    }

    const dbSession = await createDbSession(account.id, {
      ip: request.headers.get("x-forwarded-for") || undefined,
      ua: request.headers.get("user-agent") || undefined,
    });

    const session = await getSession();
    session.isLoggedIn = true;
    session.sessionId = dbSession.id;
    session.accountId = account.id;
    session.discordId = account.discordId;
    session.discordUsername = account.discordUsername;
    session.discordAvatar = account.discordAvatar;
    session.role = account.role;
    session.selectedCitizenId = null;
    session.csrfSecret = dbSession.csrfSecret;
    await session.save();

    await writeAudit({
      actorAccountId: account.id,
      actorDiscordId: account.discordId,
      action: "auth.login",
      ip: request.headers.get("x-forwarded-for") || undefined,
    });

    jar.delete("portal_oauth_state");
    return NextResponse.redirect(new URL("/characters", request.url));
  } catch (err) {
    console.error(err);
    return NextResponse.redirect(new URL("/login?error=oauth", request.url));
  }
}
