import { NextResponse } from "next/server";
import { getSession } from "@/lib/auth/session";
import { createCsrfToken } from "@/lib/security/csrf";

export async function GET() {
  const session = await getSession();
  if (!session.isLoggedIn) {
    return NextResponse.json({ error: "Non authentifié" }, { status: 401 });
  }
  return NextResponse.json({ csrfToken: createCsrfToken(session) });
}
