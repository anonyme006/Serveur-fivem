import { NextResponse } from "next/server";
import { requireSelectedCharacter } from "@/lib/auth/session";
import {
  getBankHistory,
  getCharacter,
  getPlaytimeSeconds,
  getRecentActivities,
  getRecentNotifications,
  getVehicles,
} from "@/lib/qbox/adapter";
import { discordAvatarUrl } from "@/lib/auth/discord";

export async function GET() {
  const auth = await requireSelectedCharacter();
  if (!auth.ok) return NextResponse.json({ error: auth.error }, { status: auth.status });

  const character = await getCharacter(auth.citizenid);
  if (!character) {
    return NextResponse.json({ error: "Personnage introuvable" }, { status: 404 });
  }

  const [playtime, vehicles, bank, notifications, activities] = await Promise.all([
    getPlaytimeSeconds(auth.citizenid),
    getVehicles(auth.citizenid),
    getBankHistory(auth.citizenid, { page: 1, pageSize: 5 }),
    getRecentNotifications(auth.citizenid),
    getRecentActivities(auth.citizenid),
  ]);

  return NextResponse.json({
    discord: {
      id: auth.session.discordId,
      username: auth.session.discordUsername,
      avatarUrl: discordAvatarUrl(
        auth.session.discordId || "0",
        auth.session.discordAvatar,
      ),
    },
    character,
    playtime,
    vehicleCount: vehicles.missing ? null : vehicles.vehicles.length,
    vehiclesMissing: vehicles.missing,
    recentTransactions:
      bank.missingCharacter || !("transactions" in bank) ? [] : bank.transactions,
    bankWarning: "warning" in bank ? bank.warning : null,
    notifications,
    activities,
  });
}
