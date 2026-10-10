import type { Metadata } from "next";
import { Manrope, Syne } from "next/font/google";
import "./globals.css";
import { branding } from "@/lib/branding";

const manrope = Manrope({
  subsets: ["latin"],
  variable: "--font-manrope",
});

const syne = Syne({
  subsets: ["latin"],
  variable: "--font-syne",
});

export const metadata: Metadata = {
  title: `${branding.name} — Portail joueur`,
  description: branding.tagline,
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr">
      <body
        className={`${manrope.variable} ${syne.variable} antialiased`}
        style={
          {
            "--font-ui": "var(--font-manrope), sans-serif",
            "--font-display": "var(--font-syne), sans-serif",
            "--accent": branding.accent,
            "--accent-soft": branding.accentSoft,
          } as React.CSSProperties
        }
      >
        {children}
      </body>
    </html>
  );
}
