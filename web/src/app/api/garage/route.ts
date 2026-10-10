import { NextResponse } from "next/server";
import { requireSelectedCharacter } from "@/lib/auth/session";
import { getVehicle, getVehicles } from "@/lib/qbox/adapter";
import { garageQuerySchema } from "@/lib/validations";

export async function GET(request: Request) {
  const auth = await requireSelectedCharacter();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  const url = new URL(request.url);
  const idParam = url.searchParams.get("id");
  if (idParam) {
    const id = Number(idParam);
    const result = await getVehicle(auth.citizenid, id);
    if (result.missing) {
      return NextResponse.json(
        { error: "Table player_vehicles absente", readOnly: true },
        { status: 503 },
      );
    }
    if (!result.vehicle) {
      return NextResponse.json({ error: "Véhicule introuvable" }, { status: 404 });
    }
    return NextResponse.json({ vehicle: result.vehicle, readOnly: true });
  }

  const parsed = garageQuerySchema.safeParse({
    q: url.searchParams.get("q") || undefined,
    state: url.searchParams.get("state") || undefined,
  });
  if (!parsed.success) {
    return NextResponse.json({ error: "Filtres invalides" }, { status: 400 });
  }

  const result = await getVehicles(auth.citizenid, parsed.data);
  if (result.missing) {
    return NextResponse.json(
      {
        error: "Table player_vehicles absente (qbx_vehicles).",
        vehicles: [],
        readOnly: true,
      },
      { status: 503 },
    );
  }

  return NextResponse.json({
    vehicles: result.vehicles,
    readOnly: true,
    note: "Actions véhicule réservées au serveur FiveM.",
  });
}
