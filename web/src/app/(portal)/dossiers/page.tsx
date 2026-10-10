"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

type Dossier = {
  publicId: string;
  title: string;
  status: string;
  citizenid: string;
  createdAt: string;
};

export default function DossiersPage() {
  const [dossiers, setDossiers] = useState<Dossier[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/dossiers")
      .then(async (r) => {
        const data = await r.json();
        if (!r.ok) throw new Error(data.error || "Erreur");
        setDossiers(data.dossiers || []);
      })
      .catch((e) => setError(e.message));
  }, []);

  return (
    <div className="space-y-6">
      <div className="fade-up">
        <h1 className="font-[family-name:var(--font-display)] text-3xl">Dossiers</h1>
        <p className="mt-2 text-white/55">
          Consultation des dossiers liés à ton personnage (ou vue staff).
        </p>
      </div>
      {error && <p className="text-rose-300">{error}</p>}
      <div className="grid gap-3">
        {dossiers.map((d) => (
          <Card key={d.publicId}>
            <CardHeader>
              <CardTitle className="text-lg">{d.title}</CardTitle>
            </CardHeader>
            <CardContent className="text-sm text-white/60">
              #{d.publicId} · {d.citizenid} · {d.status} ·{" "}
              {new Date(d.createdAt).toLocaleString("fr-FR")}
            </CardContent>
          </Card>
        ))}
        {dossiers.length === 0 && !error && (
          <p className="text-white/45">Aucun dossier.</p>
        )}
      </div>
    </div>
  );
}
