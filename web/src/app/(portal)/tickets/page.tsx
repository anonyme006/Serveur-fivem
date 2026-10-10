"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

type Ticket = {
  publicId: string;
  subject: string;
  status: string;
  priority: string;
  createdAt: string;
};

export default function TicketsPage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [message, setMessage] = useState<string | null>(null);

  async function load() {
    const res = await fetch("/api/tickets");
    const data = await res.json();
    setTickets(data.tickets || []);
  }

  useEffect(() => {
    load();
  }, []);

  async function createTicket(e: React.FormEvent) {
    e.preventDefault();
    setMessage(null);
    const csrf = await fetch("/api/csrf").then((r) => r.json());
    const res = await fetch("/api/tickets", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ subject, body, csrfToken: csrf.csrfToken }),
    });
    const data = await res.json();
    if (!res.ok) {
      setMessage(data.error || "Erreur");
      return;
    }
    setSubject("");
    setBody("");
    setMessage(`Ticket ${data.publicId} créé.`);
    load();
  }

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <Card className="fade-up">
        <CardHeader>
          <CardTitle>Nouveau ticket</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={createTicket} className="space-y-3">
            <Input
              placeholder="Sujet"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
            />
            <textarea
              className="min-h-32 w-full rounded-md border border-white/10 bg-black/30 p-3 text-sm"
              placeholder="Décris ta demande…"
              value={body}
              onChange={(e) => setBody(e.target.value)}
            />
            {message && <p className="text-sm text-white/70">{message}</p>}
            <Button type="submit">Envoyer</Button>
          </form>
        </CardContent>
      </Card>

      <Card className="fade-up-delay">
        <CardHeader>
          <CardTitle>Mes tickets</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {tickets.map((t) => (
            <div
              key={t.publicId}
              className="rounded-lg border border-white/8 bg-black/20 px-3 py-2"
            >
              <div className="flex items-center justify-between gap-2">
                <div className="font-medium">{t.subject}</div>
                <span className="text-xs uppercase text-white/45">{t.status}</span>
              </div>
              <div className="text-xs text-white/40">
                #{t.publicId} · {new Date(t.createdAt).toLocaleString("fr-FR")}
              </div>
            </div>
          ))}
          {tickets.length === 0 && (
            <p className="text-sm text-white/45">Aucun ticket pour le moment.</p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
