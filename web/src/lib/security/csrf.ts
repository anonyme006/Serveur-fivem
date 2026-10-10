import { createHmac, timingSafeEqual } from "crypto";
import type { PortalSessionData } from "@/lib/auth/session";

export function createCsrfToken(session: PortalSessionData) {
  if (!session.csrfSecret || !session.sessionId) return null;
  return createHmac("sha256", session.csrfSecret)
    .update(session.sessionId)
    .digest("hex");
}

export function verifyCsrfToken(session: PortalSessionData, token: string | null | undefined) {
  const expected = createCsrfToken(session);
  if (!expected || !token) return false;
  const a = Buffer.from(expected);
  const b = Buffer.from(token);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}
