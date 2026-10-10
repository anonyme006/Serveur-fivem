import Link from "next/link";
import { Logo } from "@/components/brand/Logo";
import { Button } from "@/components/ui/button";
import { branding } from "@/lib/branding";

export default function HomePage() {
  return (
    <div className="relative min-h-screen overflow-hidden">
      <div className="pointer-events-none absolute inset-0 portal-atmosphere" />
      <div className="relative z-10 mx-auto flex min-h-screen max-w-6xl flex-col px-6 py-8">
        <header className="flex items-center justify-between fade-up">
          <Logo />
          <Button asChild variant="secondary" size="sm">
            <Link href="/login">Connexion</Link>
          </Button>
        </header>

        <section className="flex flex-1 flex-col justify-center gap-8 py-16 md:max-w-2xl">
          <div className="fade-up">
            <p className="mb-4 text-xs uppercase tracking-[0.35em] text-[var(--accent)]">
              Qbox · Ox · Serenity
            </p>
            <h1 className="font-[family-name:var(--font-display)] text-5xl leading-[0.95] tracking-tight text-white md:text-7xl">
              {branding.name}
            </h1>
            <p className="mt-5 max-w-lg text-lg text-white/60">{branding.tagline}</p>
          </div>
          <div className="fade-up-delay flex flex-wrap gap-3">
            <Button asChild size="lg" className="pulse-glow">
              <Link href="/login">Entrer avec Discord</Link>
            </Button>
            <Button asChild size="lg" variant="secondary">
              <Link href="/login">Accéder au portail</Link>
            </Button>
          </div>
        </section>
      </div>
    </div>
  );
}
