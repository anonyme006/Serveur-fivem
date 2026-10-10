"use client";

import { useEffect, useState } from "react";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";

type SessionPayload = {
  authenticated: boolean;
  user?: {
    discordUsername: string;
    avatarUrl: string;
    role: string;
    selectedCitizenId: string | null;
    linked: boolean;
  };
};

export function PortalShell({ children }: { children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [session, setSession] = useState<SessionPayload | null>(null);

  useEffect(() => {
    fetch("/api/auth/session")
      .then((r) => r.json())
      .then(setSession)
      .catch(() => setSession({ authenticated: false }));
  }, []);

  const isStaff =
    session?.user?.role === "moderator" ||
    session?.user?.role === "admin" ||
    session?.user?.role === "owner";

  return (
    <div className="relative flex min-h-screen bg-[var(--bg)] text-white">
      <div className="pointer-events-none absolute inset-0 portal-atmosphere" />
      <Sidebar
        isStaff={isStaff}
        mobileOpen={mobileOpen}
        onClose={() => setMobileOpen(false)}
      />
      <div className="relative z-10 flex min-w-0 flex-1 flex-col">
        <Topbar
          username={session?.user?.discordUsername}
          avatarUrl={session?.user?.avatarUrl}
          citizenLabel={session?.user?.selectedCitizenId}
          onMenu={() => setMobileOpen(true)}
        />
        <main className="flex-1 p-4 md:p-6 lg:p-8">{children}</main>
      </div>
    </div>
  );
}
