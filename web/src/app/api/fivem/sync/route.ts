import { NextResponse } from "next/server";
import { verifyServerHmac } from "@/lib/security/hmac";
import { fivemSyncSchema } from "@/lib/validations";
import { execute } from "@/lib/db/pool";
import { rateLimit } from "@/lib/security/rate-limit";

export async function POST(request: Request) {
  const limited = rateLimit("fivem-sync", 120, 60_000);
  if (!limited.ok) {
    return NextResponse.json({ error: "Rate limited" }, { status: 429 });
  }

  const raw = await request.text();
  const verified = await verifyServerHmac(request.headers, raw);
  if (!verified.ok) {
    return NextResponse.json({ error: verified.reason }, { status: 401 });
  }

  let json: unknown;
  try {
    json = JSON.parse(raw);
  } catch {
    return NextResponse.json({ error: "JSON invalide" }, { status: 400 });
  }

  const parsed = fivemSyncSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalide" }, { status: 400 });
  }

  const { event, player } = parsed.data;

  await execute(
    `INSERT INTO portal_activities (citizenid, category, summary, meta_json)
     VALUES (:citizenid, :category, :summary, :meta)`,
    {
      citizenid: player.citizenid,
      category: "sync",
      summary: `Événement serveur: ${event}`,
      meta: JSON.stringify({ event, cash: player.cash, bank: player.bank }),
    },
  );

  return NextResponse.json({ ok: true });
}
