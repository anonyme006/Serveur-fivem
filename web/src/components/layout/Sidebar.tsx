"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Banknote,
  Car,
  FolderOpen,
  LayoutDashboard,
  Link2,
  Shield,
  Ticket,
  Users,
} from "lucide-react";
import { Logo } from "@/components/brand/Logo";
import { cn } from "@/lib/utils";

const links = [
  { href: "/dashboard", label: "Tableau de bord", icon: LayoutDashboard },
  { href: "/characters", label: "Personnages", icon: Users },
  { href: "/garage", label: "Garage", icon: Car },
  { href: "/bank", label: "Banque", icon: Banknote },
  { href: "/tickets", label: "Tickets", icon: Ticket },
  { href: "/dossiers", label: "Dossiers", icon: FolderOpen },
  { href: "/link", label: "Liaison", icon: Link2 },
  { href: "/admin", label: "Admin", icon: Shield, staff: true },
];

export function Sidebar({
  isStaff,
  mobileOpen,
  onClose,
}: {
  isStaff?: boolean;
  mobileOpen?: boolean;
  onClose?: () => void;
}) {
  const pathname = usePathname();

  const nav = (
    <aside className="flex h-full w-[260px] flex-col border-r border-white/8 bg-[#0b0e11]/95 px-4 py-5 backdrop-blur-xl">
      <Logo />
      <div className="mt-6 mb-3 text-[11px] uppercase tracking-[0.22em] text-white/35">
        Navigation
      </div>
      <nav className="flex flex-1 flex-col gap-1">
        {links
          .filter((l) => !l.staff || isStaff)
          .map(({ href, label, icon: Icon }) => {
            const active = pathname === href || pathname.startsWith(`${href}/`);
            return (
              <Link
                key={href}
                href={href}
                onClick={onClose}
                className={cn(
                  "group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm transition-all",
                  active
                    ? "bg-[var(--accent)]/15 text-[var(--accent)] shadow-[inset_0_0_0_1px_rgba(62,207,178,0.25)]"
                    : "text-white/65 hover:bg-white/5 hover:text-white",
                )}
              >
                <Icon size={18} className="opacity-80" />
                <span>{label}</span>
              </Link>
            );
          })}
      </nav>
      <p className="mt-4 text-[11px] leading-relaxed text-white/30">
        Lecture seule côté web. Les actions véhicule / argent passent par FiveM.
      </p>
    </aside>
  );

  return (
    <>
      <div className="hidden lg:block">{nav}</div>
      {mobileOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <button
            className="absolute inset-0 bg-black/70"
            aria-label="Fermer le menu"
            onClick={onClose}
          />
          <div className="absolute inset-y-0 left-0 animate-in slide-in-from-left">
            {nav}
          </div>
        </div>
      )}
    </>
  );
}
