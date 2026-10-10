import Link from "next/link";
import { Logo } from "@/components/brand/Logo";
import { Button } from "@/components/ui/button";
import { branding } from "@/lib/branding";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const params = await searchParams;
  const error = params.error;

  return (
    <div className="relative flex min-h-screen items-center justify-center px-4">
      <div className="pointer-events-none absolute inset-0 portal-atmosphere" />
      <div className="relative z-10 w-full max-w-md rounded-2xl border border-white/10 bg-[#10151b]/85 p-8 shadow-[0_30px_80px_rgba(0,0,0,0.45)] backdrop-blur-xl fade-up">
        <Logo className="mb-8 justify-center" />
        <h1 className="text-center font-[family-name:var(--font-display)] text-3xl tracking-wide">
          Connexion à {branding.name}
        </h1>
        <p className="mt-3 text-center text-sm text-white/55">
          Joueurs et staff : un seul compte Discord. Nous lisons ton identifiant,
          ton avatar et ton pseudo — jamais ton mot de passe.
        </p>
        {error && (
          <div className="mt-4 rounded-md border border-rose-400/30 bg-rose-500/10 px-3 py-2 text-sm text-rose-200">
            Échec de l&apos;authentification Discord ({error}).
          </div>
        )}
        <Button asChild className="mt-8 w-full pulse-glow" size="lg">
          <Link href="/api/auth/discord">Continuer avec Discord</Link>
        </Button>
        <p className="mt-6 text-center text-xs text-white/35">
          Après connexion, lie ton personnage via un code généré en jeu
          (`/portal link`).
        </p>
      </div>
    </div>
  );
}
