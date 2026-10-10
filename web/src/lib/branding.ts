export const branding = {
  name: process.env.NEXT_PUBLIC_SERVER_NAME || "Serenity V",
  tagline:
    process.env.NEXT_PUBLIC_SERVER_TAGLINE ||
    "Portail joueur Qbox — personnage, garage, banque.",
  accent: process.env.NEXT_PUBLIC_ACCENT_COLOR || "#3ecfb2",
  accentSoft: process.env.NEXT_PUBLIC_ACCENT_SOFT || "#1a8f7a",
  discordInvite: process.env.NEXT_PUBLIC_DISCORD_INVITE || "",
};
