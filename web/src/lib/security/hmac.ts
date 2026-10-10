import { createHmac, createHash, randomBytes, timingSafeEqual } from "crypto";
import { execute, query } from "@/lib/db/pool";
import type { RowDataPacket } from "mysql2";

export function sha256(value: string) {
  return createHash("sha256").update(value).digest("hex");
}

export function hmacSha256(secret: string, payload: string) {
  return createHmac("sha256", secret).update(payload).digest("hex");
}

export function randomToken(bytes = 32) {
  return randomBytes(bytes).toString("hex");
}

function safeEqualHex(a: string, b: string) {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  if (ba.length !== bb.length) return false;
  return timingSafeEqual(ba, bb);
}

export async function verifyServerHmac(headers: Headers, rawBody: string) {
  const secret = process.env.PORTAL_API_SECRET;
  if (!secret) return { ok: false as const, reason: "PORTAL_API_SECRET manquant" };

  const timestamp = headers.get("x-portal-timestamp");
  const nonce = headers.get("x-portal-nonce");
  const signature = headers.get("x-portal-signature");

  if (!timestamp || !nonce || !signature) {
    return { ok: false as const, reason: "Headers d'auth manquants" };
  }

  const ts = Number(timestamp);
  if (!Number.isFinite(ts)) return { ok: false as const, reason: "Timestamp invalide" };

  const skew = Math.abs(Math.floor(Date.now() / 1000) - ts);
  if (skew > 60) return { ok: false as const, reason: "Timestamp expiré (anti-rejeu)" };

  const expected = hmacSha256(secret, `${timestamp}.${nonce}.${rawBody}`);
  if (!safeEqualHex(expected, signature)) {
    return { ok: false as const, reason: "Signature invalide" };
  }

  try {
    const existing = await query<RowDataPacket[]>(
      `SELECT nonce FROM portal_api_nonces WHERE nonce = :nonce LIMIT 1`,
      { nonce: sha256(nonce) },
    );
    if (existing.length) return { ok: false as const, reason: "Nonce déjà utilisé" };

    await execute(
      `INSERT INTO portal_api_nonces (nonce, expires_at)
       VALUES (:nonce, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 5 MINUTE))`,
      { nonce: sha256(nonce) },
    );
  } catch (err) {
    return { ok: false as const, reason: `Nonce store: ${(err as Error).message}` };
  }

  return { ok: true as const };
}
