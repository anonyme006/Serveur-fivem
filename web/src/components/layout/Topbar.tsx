"use client";

import Image from "next/image";
import { LogOut, Menu } from "lucide-react";
import { Button } from "@/components/ui/button";

export function Topbar({
  username,
  avatarUrl,
  citizenLabel,
  onMenu,
}: {
  username?: string;
  avatarUrl?: string;
  citizenLabel?: string | null;
  onMenu?: () => void;
}) {
  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    window.location.href = "/login";
  }

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-white/8 bg-[#0b0e11]/70 px-4 backdrop-blur-xl md:px-6">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" className="lg:hidden" onClick={onMenu}>
          <Menu size={18} />
        </Button>
        <div>
          <div className="text-sm text-white/50">Session</div>
          <div className="text-sm font-semibold text-white">
            {citizenLabel || "Aucun personnage sélectionné"}
          </div>
        </div>
      </div>
      <div className="flex items-center gap-3">
        {avatarUrl && (
          <Image
            src={avatarUrl}
            alt=""
            width={36}
            height={36}
            className="rounded-full ring-2 ring-[var(--accent)]/40"
            unoptimized
          />
        )}
        <div className="hidden sm:block text-right">
          <div className="text-sm font-medium">{username}</div>
          <div className="text-xs text-white/40">Discord</div>
        </div>
        <Button variant="secondary" size="sm" onClick={logout}>
          <LogOut size={14} />
          Quitter
        </Button>
      </div>
    </header>
  );
}
