import { Outlet } from "react-router-dom";
import { Sidebar } from "./Sidebar";
import { SiteFooter } from "./SiteFooter";
import { Skyline } from "./Skyline";

export function PanelLayout() {
  return (
    <div className="panel-shell">
      <Sidebar />
      <div className="panel-main">
        <div className="skyline-bg panel-skyline" aria-hidden="true">
          <Skyline className="skyline-bg__art" />
        </div>
        <div className="panel-content">
          <Outlet />
        </div>
        <SiteFooter />
      </div>
    </div>
  );
}
