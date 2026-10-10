import { NextResponse } from "next/server";
import { getSchemaStatus } from "@/lib/qbox/adapter";

export async function GET() {
  try {
    const schema = await getSchemaStatus();
    return NextResponse.json({
      ok: schema.missingCritical.length === 0,
      service: "serenity-player-portal",
      schema,
    });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: (err as Error).message },
      { status: 503 },
    );
  }
}
