import { PortalShell } from "@/components/layout/PortalShell";
import { getSession } from "@/lib/auth/session";
import { redirect } from "next/navigation";

export default async function PortalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getSession();
  if (!session.isLoggedIn) {
    redirect("/login");
  }

  return <PortalShell>{children}</PortalShell>;
}
