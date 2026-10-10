"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { formatMoney } from "@/lib/utils";

type Tx = {
  id: string;
  amount: number;
  message: string;
  type: string;
  time: number;
};

export default function BankPage() {
  const [cash, setCash] = useState(0);
  const [bank, setBank] = useState(0);
  const [txs, setTxs] = useState<Tx[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [warning, setWarning] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function load(nextPage = page) {
    setError(null);
    const params = new URLSearchParams({ page: String(nextPage), pageSize: "10" });
    if (from) params.set("from", from);
    if (to) params.set("to", to);
    const res = await fetch(`/api/bank?${params}`);
    const data = await res.json();
    if (!res.ok) {
      setError(data.error || "Erreur banque");
      return;
    }
    setCash(data.cash);
    setBank(data.bank);
    setTxs(data.transactions || []);
    setTotal(data.total || 0);
    setWarning(data.warning);
    setPage(data.page || nextPage);
  }

  useEffect(() => {
    load(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const pages = Math.max(1, Math.ceil(total / 10));

  return (
    <div className="space-y-6">
      <div className="fade-up">
        <h1 className="font-[family-name:var(--font-display)] text-3xl">Banque</h1>
        <p className="mt-2 text-white/55">
          Soldes Qbox en lecture seule. Aucune modification depuis le navigateur.
        </p>
      </div>

      <div className="stat-grid fade-up-delay">
        <Card>
          <CardContent className="p-5">
            <div className="text-xs uppercase tracking-[0.18em] text-white/40">Banque</div>
            <div className="mt-2 font-[family-name:var(--font-display)] text-3xl">
              {formatMoney(bank)}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="text-xs uppercase tracking-[0.18em] text-white/40">Liquide</div>
            <div className="mt-2 font-[family-name:var(--font-display)] text-3xl">
              {formatMoney(cash)}
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Historique</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-3 md:grid-cols-[1fr_1fr_auto]">
            <Input type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
            <Input type="date" value={to} onChange={(e) => setTo(e.target.value)} />
            <Button onClick={() => load(1)}>Appliquer</Button>
          </div>
          {warning && <p className="text-sm text-[var(--warning)]">{warning}</p>}
          {error && <p className="text-sm text-rose-300">{error}</p>}
          <div className="divide-y divide-white/5">
            {txs.map((t) => (
              <div key={t.id} className="flex items-center justify-between py-3 text-sm">
                <div>
                  <div className="font-medium">{t.message}</div>
                  <div className="text-xs text-white/40">
                    {t.time
                      ? new Date(t.time * 1000).toLocaleString("fr-FR")
                      : "Date inconnue"}{" "}
                    · {t.type}
                  </div>
                </div>
                <div
                  className={
                    t.type === "withdraw" ? "text-rose-300" : "text-[var(--accent)]"
                  }
                >
                  {t.type === "withdraw" ? "-" : "+"}
                  {formatMoney(Math.abs(t.amount))}
                </div>
              </div>
            ))}
            {txs.length === 0 && !error && (
              <p className="py-4 text-white/45">Aucune transaction sur cette période.</p>
            )}
          </div>
          <div className="flex items-center justify-between">
            <Button
              variant="secondary"
              disabled={page <= 1}
              onClick={() => load(page - 1)}
            >
              Précédent
            </Button>
            <span className="text-sm text-white/45">
              Page {page} / {pages}
            </span>
            <Button
              variant="secondary"
              disabled={page >= pages}
              onClick={() => load(page + 1)}
            >
              Suivant
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
