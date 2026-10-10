import { NextResponse } from "next/server";
import { requireSelectedCharacter } from "@/lib/auth/session";
import { getBankHistory } from "@/lib/qbox/adapter";
import { bankQuerySchema } from "@/lib/validations";

export async function GET(request: Request) {
  const auth = await requireSelectedCharacter();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  const url = new URL(request.url);
  const parsed = bankQuerySchema.safeParse({
    from: url.searchParams.get("from") || undefined,
    to: url.searchParams.get("to") || undefined,
    page: url.searchParams.get("page") || undefined,
    pageSize: url.searchParams.get("pageSize") || undefined,
  });
  if (!parsed.success) {
    return NextResponse.json({ error: "Paramètres invalides" }, { status: 400 });
  }

  const result = await getBankHistory(auth.citizenid, {
    from: parsed.data.from ? new Date(parsed.data.from) : undefined,
    to: parsed.data.to ? new Date(parsed.data.to) : undefined,
    page: parsed.data.page,
    pageSize: parsed.data.pageSize,
  });

  if (result.missingCharacter) {
    return NextResponse.json({ error: "Personnage introuvable" }, { status: 404 });
  }

  return NextResponse.json({
    ...result,
    readOnly: true,
    note: "Aucune modification de solde n'est possible depuis le navigateur.",
  });
}
