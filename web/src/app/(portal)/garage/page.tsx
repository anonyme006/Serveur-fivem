"use client";

import { useEffect, useMemo, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

type Vehicle = {
  id: number;
  vehicle: string;
  plate: string;
  garage: string | null;
  statusLabel: string;
  fuel: number | null;
  engine: number | null;
  body: number | null;
  state: number;
};

export default function GaragePage() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [q, setQ] = useState("");
  const [state, setState] = useState<string>("");
  const [selected, setSelected] = useState<Vehicle | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [note, setNote] = useState<string | null>(null);

  async function load() {
    setError(null);
    const params = new URLSearchParams();
    if (q) params.set("q", q);
    if (state !== "") params.set("state", state);
    const res = await fetch(`/api/garage?${params.toString()}`);
    const data = await res.json();
    if (!res.ok) {
      setError(data.error || "Erreur garage");
      setVehicles([]);
      return;
    }
    setVehicles(data.vehicles || []);
    setNote(data.note || null);
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filters = useMemo(
    () => [
      { value: "", label: "Tous" },
      { value: "1", label: "Rangé" },
      { value: "0", label: "Sorti" },
      { value: "2", label: "Fourrière" },
    ],
    [],
  );

  return (
    <div className="space-y-6">
      <div className="fade-up">
        <h1 className="font-[family-name:var(--font-display)] text-3xl">Garage</h1>
        <p className="mt-2 text-white/55">
          Lecture seule — toute action véhicule est validée par le serveur FiveM.
        </p>
      </div>

      <Card className="fade-up-delay">
        <CardContent className="flex flex-col gap-3 p-4 md:flex-row">
          <Input
            placeholder="Recherche plaque, modèle, garage…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          <div className="flex flex-wrap gap-2">
            {filters.map((f) => (
              <Button
                key={f.label}
                size="sm"
                variant={state === f.value ? "default" : "secondary"}
                onClick={() => setState(f.value)}
              >
                {f.label}
              </Button>
            ))}
            <Button onClick={load}>Filtrer</Button>
          </div>
        </CardContent>
      </Card>

      {error && (
        <div className="rounded-md border border-rose-400/30 bg-rose-500/10 px-3 py-2 text-sm">
          {error}
        </div>
      )}
      {note && <p className="text-sm text-white/40">{note}</p>}

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="space-y-3 lg:col-span-2">
          {vehicles.map((v) => (
            <button
              key={v.id}
              type="button"
              onClick={() => setSelected(v)}
              className="w-full rounded-xl border border-white/8 bg-[var(--panel)] px-4 py-3 text-left transition hover:border-[var(--accent)]/40"
            >
              <div className="flex items-center justify-between gap-3">
                <div>
                  <div className="font-semibold capitalize">{v.vehicle}</div>
                  <div className="text-sm text-white/45">
                    {v.plate} · {v.garage || "—"}
                  </div>
                </div>
                <span className="rounded-md bg-white/5 px-2 py-1 text-xs uppercase tracking-wide">
                  {v.statusLabel}
                </span>
              </div>
            </button>
          ))}
          {vehicles.length === 0 && !error && (
            <p className="text-white/45">Aucun véhicule pour ce personnage.</p>
          )}
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Fiche véhicule</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm text-white/70">
            {!selected && <p>Sélectionne un véhicule.</p>}
            {selected && (
              <>
                <div>Modèle : <strong className="text-white capitalize">{selected.vehicle}</strong></div>
                <div>Plaque : {selected.plate}</div>
                <div>Garage : {selected.garage || "—"}</div>
                <div>Statut : {selected.statusLabel}</div>
                <div>Carburant : {selected.fuel ?? "—"}%</div>
                <div>Moteur : {selected.engine ?? "—"}</div>
                <div>Carrosserie : {selected.body ?? "—"}</div>
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
