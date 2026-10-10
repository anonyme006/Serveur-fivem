"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export default function AdminPage() {
  const [q, setQ] = useState("");
  const [players, setPlayers] = useState<Array<Record<string, unknown>>>([]);
  const [tickets, setTickets] = useState<Array<Record<string, unknown>>>([]);
  const [dossiers, setDossiers] = useState<Array<Record<string, unknown>>>([]);
  const [requests, setRequests] = useState<Array<Record<string, unknown>>>([]);
  const [audit, setAudit] = useState<Array<Record<string, unknown>>>([]);
  const [error, setError] = useState<string | null>(null);

  async function bootstrap() {
    setError(null);
    const [t, d, r, a] = await Promise.all([
      fetch("/api/admin/tickets"),
      fetch("/api/admin/dossiers"),
      fetch("/api/admin/requests"),
      fetch("/api/admin/audit"),
    ]);
    if (t.status === 403) {
      setError("Accès staff requis.");
      return;
    }
    setTickets((await t.json()).tickets || []);
    setDossiers((await d.json()).dossiers || []);
    setRequests((await r.json()).requests || []);
    if (a.ok) setAudit((await a.json()).entries || []);
  }

  useEffect(() => {
    bootstrap();
  }, []);

  async function search() {
    const res = await fetch(`/api/admin/players?q=${encodeURIComponent(q)}`);
    const data = await res.json();
    if (!res.ok) {
      setError(data.error || "Recherche impossible");
      return;
    }
    setPlayers(data.players || []);
  }

  return (
    <div className="space-y-6">
      <div className="fade-up">
        <h1 className="font-[family-name:var(--font-display)] text-3xl">Administration</h1>
        <p className="mt-2 text-white/55">
          Permissions vérifiées serveur. Aucune modification d&apos;argent, véhicules
          ou identifiants joueur depuis le portail.
        </p>
      </div>
      {error && <p className="text-rose-300">{error}</p>}

      <Card>
        <CardHeader>
          <CardTitle>Recherche joueurs</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex gap-2">
            <Input
              placeholder="citizenid, Discord, nom RP…"
              value={q}
              onChange={(e) => setQ(e.target.value)}
            />
            <Button onClick={search}>Rechercher</Button>
          </div>
          <div className="space-y-2">
            {players.map((p) => (
              <div
                key={String(p.citizenid)}
                className="rounded-lg border border-white/8 px-3 py-2 text-sm"
              >
                <strong>
                  {String(p.firstname)} {String(p.lastname)}
                </strong>{" "}
                · {String(p.citizenid)} · Discord {String(p.discordId || "—")}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4 xl:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Tickets</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            {tickets.map((t) => (
              <div key={String(t.publicId)} className="border-b border-white/5 py-2">
                #{String(t.publicId)} · {String(t.subject)} · {String(t.status)}
              </div>
            ))}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Dossiers</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            {dossiers.map((d) => (
              <div key={String(d.publicId)} className="border-b border-white/5 py-2">
                #{String(d.publicId)} · {String(d.title)} · {String(d.citizenid)}
              </div>
            ))}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Demandes admin</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            {requests.length === 0 && <p className="text-white/45">Aucune demande.</p>}
            {requests.map((r) => (
              <div key={String(r.publicId)} className="border-b border-white/5 py-2">
                #{String(r.publicId)} · {String(r.requestType)} · {String(r.status)}
              </div>
            ))}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Historique d&apos;actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            {audit.map((a) => (
              <div key={String(a.id)} className="border-b border-white/5 py-2">
                {String(a.action)} · {String(a.targetId || "—")} ·{" "}
                {new Date(String(a.createdAt)).toLocaleString("fr-FR")}
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
