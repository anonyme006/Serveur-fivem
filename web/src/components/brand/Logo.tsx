import { branding } from "@/lib/branding";
import { cn } from "@/lib/utils";

export function Logo({
  className,
  showWordmark = true,
  size = 40,
}: {
  className?: string;
  showWordmark?: boolean;
  size?: number;
}) {
  return (
    <div className={cn("flex items-center gap-3", className)}>
      <svg
        width={size}
        height={size}
        viewBox="0 0 64 64"
        fill="none"
        aria-hidden="true"
        className="drop-shadow-[0_0_18px_rgba(62,207,178,0.35)]"
      >
        <defs>
          <linearGradient id="sv" x1="8" y1="4" x2="56" y2="60" gradientUnits="userSpaceOnUse">
            <stop stopColor="#7af0d6" />
            <stop offset="1" stopColor="#1f9d86" />
          </linearGradient>
        </defs>
        <path
          d="M32 4L56 18V46L32 60L8 46V18L32 4Z"
          stroke="url(#sv)"
          strokeWidth="2.5"
          fill="rgba(62,207,178,0.08)"
        />
        <path
          d="M20 34C20 24 26 18 32 18C40 18 44 24 44 30C44 40 34 42 34 48"
          stroke="url(#sv)"
          strokeWidth="3.2"
          strokeLinecap="round"
        />
        <circle cx="34" cy="54" r="2.4" fill="#7af0d6" />
      </svg>
      {showWordmark && (
        <div className="leading-none">
          <div className="font-[family-name:var(--font-display)] text-2xl tracking-[0.08em] text-white">
            {branding.name}
          </div>
          <div className="mt-1 text-[10px] uppercase tracking-[0.28em] text-white/45">
            Player Portal
          </div>
        </div>
      )}
    </div>
  );
}
