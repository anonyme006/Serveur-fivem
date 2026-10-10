"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatMoney } from "@/lib/utils";
import {
  Area,
  AreaChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

type Dash = {
  discord: { id?: string; username?: string; avatarUrl: string };
  character: {
    citizenid: string;
    firstname: string;
    lastname: string;
    cash: number;
    bank: number;
    jobLabel: string;
  };
  playtime: { label: string; seconds: number };
  vehicleCount: number | null;
  recentTransactions: Array<{ id: string; amount: number; message: string; type: string }>;
  bankWarning: string | null;
  notifications: Array<{ id: number; title: string; body: string; level: string }>;
  activities: Array<{ id: number; summary: string; createdAt: string }>;
  error?: string;
};

export default function DashboardPage() {
  const [data, setData] = useState<Dash | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/dashboard")
      .then(async (r) => {
        const json = await r.json();
        if (!r.ok) throw new Error(json.error || "Erreur");
        setData(json);
      })
      .catch((e) => setError(e.message));
  }, []);

  if (error) {
    return (
      <Card className="max-w-xl">
        <CardContent className="p-6 text-rose-200">{error}</CardContent>
      </Card>
    );
  }

  if (!data) {
    return <div className="text-white/50">Chargement du tableau de bord…</div>;
  }

  const chartData = data.recentTransactions
    .slice()
    .reverse()
    .map((t, i) => ({
      name: `#${i + 1}`,
      amount: t.type === "withdraw" ? -Math.abs(t.amount) : Math.abs(t.amount),
    }));

  return (
    <div className="space-y-6">
      <div className="fade-up flex flex-wrap items-center gap-4">
        <Image
          src={data.discord.avatarUrl}
          alt=""
          width={64}
          height={64}
          className="rounded-full ring-2 ring-[var(--accent)]/40"
          unoptimized
        />
        <div>
          <h1 className="font-[family-name:var(--font-display)] text-3xl tracking-wide">
            {data.character.firstname} {data.character.lastname}
          </h1>
          <p className="text-white/50">
            {data.discord.username} · Discord {data.discord.id} ·{" "}
            {data.character.citizenid}
          </p>
        </div>
      </div>

      <div className="stat-grid fade-up-delay">
        {[
          { label: "Liquide", value: formatMoney(data.character.cash) },
          { label: "Banque", value: formatMoney(data.character.bank) },
          { label: "Temps de jeu", value: data.playtime.label },
          {
            label: "Véhicules",
            value: data.vehicleCount == null ? "N/A" : String(data.vehicleCount),
          },
        ].map((s) => (
          <Card key={s.label}>
            <CardContent className="p-5">
              <div className="text-xs uppercase tracking-[0.18em] text-white/40">
                {s.label}
              </div>
              <div className="mt-2 font-[family-name:var(--font-display)] text-2xl">
                {s.value}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardHeader>
            <CardTitle>Activité bancaire récente</CardTitle>
          </CardHeader>
          <CardContent className="h-64">
            {data.bankWarning && (
              <p className="mb-3 text-sm text-[var(--warning)]">{data.bankWarning}</p>
            )}
            {chartData.length === 0 ? (
              <p className="text-white/45">Aucune transaction disponible.</p>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#3ecfb2" stopOpacity={0.45} />
                      <stop offset="100%" stopColor="#3ecfb2" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="name" stroke="#66707c" />
                  <YAxis stroke="#66707c" />
                  <Tooltip
                    contentStyle={{
                      background: "#12161c",
                      border: "1px solid rgba(255,255,255,0.08)",
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="amount"
                    stroke="#3ecfb2"
                    fill="url(#g)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Notifications</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {data.notifications.length === 0 && (
              <p className="text-sm text-white/45">Aucune notification.</p>
            )}
            {data.notifications.map((n) => (
              <div
                key={n.id}
                className="rounded-lg border border-white/8 bg-black/20 px-3 py-2"
              >
                <div className="text-sm font-semibold">{n.title}</div>
                <div className="text-xs text-white/55">{n.body}</div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Dernières activités</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {data.activities.map((a) => (
            <div
              key={a.id}
              className="flex items-center justify-between border-b border-white/5 py-2 text-sm last:border-0"
            >
              <span>{a.summary}</span>
              <span className="text-white/35">
                {new Date(a.createdAt).toLocaleString("fr-FR")}
              </span>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
