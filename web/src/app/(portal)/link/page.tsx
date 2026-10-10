"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export default function LinkPage() {
  const router = useRouter();
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setOk(null);
    try {
      const csrf = await fetch("/api/csrf").then((r) => r.json());
      const res = await fetch("/api/link", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code, csrfToken: csrf.csrfToken }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Échec");
      setOk(`Compte lié (${data.license}).`);
      setTimeout(() => router.push("/characters"), 800);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <Card className="max-w-xl fade-up">
      <CardHeader>
        <CardTitle>Liaison Discord ↔ personnage</CardTitle>
      </CardHeader>
      <CardContent>
        <ol className="mb-5 list-decimal space-y-2 pl-5 text-sm text-white/60">
          <li>Connecte-toi en jeu avec le bon personnage.</li>
          <li>
            Tape <code className="text-[var(--accent)]">/portal link</code>.
          </li>
          <li>Saisis le code à usage unique ci-dessous (pas un citizenid tiers).</li>
        </ol>
        <form onSubmit={submit} className="space-y-3">
          <Input
            inputMode="numeric"
            maxLength={6}
            placeholder="Code à 6 chiffres"
            value={code}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
          />
          {error && <p className="text-sm text-rose-300">{error}</p>}
          {ok && <p className="text-sm text-[var(--accent)]">{ok}</p>}
          <Button type="submit" disabled={loading || code.length !== 6}>
            {loading ? "Vérification…" : "Confirmer la liaison"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
