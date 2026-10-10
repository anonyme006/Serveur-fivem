"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { formatMoney } from "@/lib/utils";

type Character = {
  citizenid: string;
  firstname: string;
  lastname: string;
  cash: number;
  bank: number;
  jobLabel: string;
};

export default function CharactersPage() {
  const router = useRouter();
  const [characters, setCharacters] = useState<Character[]>([]);
  const [linked, setLinked] = useState(true);
  const [selected, setSelected] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetch("/api/characters/select").then((r) => r.json()),
      fetch("/api/csrf").then((r) => r.json()),
    ])
      .then(([chars]) => {
        setLinked(Boolean(chars.linked));
        setCharacters(chars.characters || []);
        setSelected(chars.selectedCitizenId);
      })
      .catch(() => setError("Impossible de charger les personnages"))
      .finally(() => setLoading(false));
  }, []);

  async function selectCharacter(citizenid: string) {
    setError(null);
    const csrf = await fetch("/api/csrf").then((r) => r.json());
    const res = await fetch("/api/characters/select", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ citizenid, csrfToken: csrf.csrfToken }),
    });
    const data = await res.json();
    if (!res.ok) {
      setError(data.error || "Sélection impossible");
      return;
    }
    setSelected(citizenid);
    router.push("/dashboard");
  }

  if (loading) {
    return <div className="text-white/50">Chargement des personnages…</div>;
  }

  if (!linked) {
    return (
      <Card className="max-w-xl fade-up">
        <CardHeader>
          <CardTitle>Liaison requise</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4 text-white/70">
          <p>
            Ton Discord n&apos;est pas encore lié à un compte FiveM. En jeu,
            tape <code className="text-[var(--accent)]">/portal link</code> puis
            saisis le code ici.
          </p>
          <Button onClick={() => router.push("/link")}>Lier mon compte</Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <div className="fade-up">
        <h1 className="font-[family-name:var(--font-display)] text-3xl tracking-wide">
          Choisis ton personnage
        </h1>
        <p className="mt-2 text-white/55">
          Les données ne sont jamais mélangées entre personnages du même compte.
        </p>
      </div>
      {error && (
        <div className="rounded-md border border-rose-400/30 bg-rose-500/10 px-3 py-2 text-sm text-rose-100">
          {error}
        </div>
      )}
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {characters.map((c, idx) => (
          <Card
            key={c.citizenid}
            className={`fade-up cursor-pointer transition hover:border-[var(--accent)]/40 ${
              selected === c.citizenid ? "border-[var(--accent)]/50" : ""
            }`}
            style={{ animationDelay: `${idx * 60}ms` }}
          >
            <CardHeader>
              <CardTitle>
                {c.firstname} {c.lastname}
              </CardTitle>
              <p className="text-xs text-white/40">{c.citizenid}</p>
            </CardHeader>
            <CardContent className="space-y-3 text-sm text-white/70">
              <div>Job : {c.jobLabel}</div>
              <div>Cash : {formatMoney(c.cash)}</div>
              <div>Banque : {formatMoney(c.bank)}</div>
              <Button className="w-full" onClick={() => selectCharacter(c.citizenid)}>
                Consulter
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
