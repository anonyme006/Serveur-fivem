import { useState } from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import {
  Car,
  ChevronDown,
  Cloud,
  Home,
  Image,
  LogOut,
  Menu,
  Skull,
  User,
  X,
} from "lucide-react";
import { BrandMark } from "./Logo";
import { serverStatus } from "../data/mock";

const personnelLinks = [
  { to: "/panel/personnage", label: "Personnage", icon: User },
  { to: "/panel/vehicules", label: "Vehicules", icon: Car },
  { to: "/panel/images", label: "Mes images", icon: Image },
];

export function Sidebar() {
  const location = useLocation();
  const navigate = useNavigate();
  const personnelOpenByDefault = personnelLinks.some((link) =>
    location.pathname.startsWith(link.to),
  );
  const [personnelOpen, setPersonnelOpen] = useState(personnelOpenByDefault);
  const [mobileOpen, setMobileOpen] = useState(false);

  const closeMobile = () => setMobileOpen(false);

  const content = (
    <>
      <div className="sidebar__top">
        <BrandMark size={48} className="sidebar__brand" />
        <div className={`sidebar__status ${serverStatus.online ? "is-online" : ""}`}>
          <span className="sidebar__status-dot" aria-hidden="true" />
          <span>Serveur {serverStatus.online ? "en ligne" : "hors ligne"}</span>
        </div>
      </div>

      <nav className="sidebar__nav" aria-label="Navigation panel">
        <NavLink
          to="/panel"
          end
          className={({ isActive }) => `sidebar__link ${isActive ? "is-active" : ""}`}
          onClick={closeMobile}
        >
          <Home size={18} />
          <span>Accueil</span>
        </NavLink>

        <button
          type="button"
          className={`sidebar__link sidebar__toggle ${personnelOpen ? "is-open" : ""}`}
          onClick={() => setPersonnelOpen((open) => !open)}
          aria-expanded={personnelOpen}
        >
          <User size={18} />
          <span>Personnel</span>
          <ChevronDown size={16} className="sidebar__chevron" />
        </button>

        {personnelOpen && (
          <div className="sidebar__submenu">
            {personnelLinks.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                className={({ isActive }) =>
                  `sidebar__sublink ${isActive ? "is-active" : ""}`
                }
                onClick={closeMobile}
              >
                <Icon size={16} />
                <span>{label}</span>
              </NavLink>
            ))}
          </div>
        )}

        <NavLink
          to="/panel/mrp"
          className={({ isActive }) => `sidebar__link ${isActive ? "is-active" : ""}`}
          onClick={closeMobile}
        >
          <Skull size={18} />
          <span>Demandes MRP</span>
        </NavLink>

        <NavLink
          to="/panel/medias"
          className={({ isActive }) => `sidebar__link ${isActive ? "is-active" : ""}`}
          onClick={closeMobile}
        >
          <Cloud size={18} />
          <span>Mes medias</span>
        </NavLink>
      </nav>

      <button
        type="button"
        className="sidebar__logout"
        onClick={() => {
          closeMobile();
          navigate("/login");
        }}
      >
        <LogOut size={18} />
        <span>DECONNEXION</span>
      </button>
    </>
  );

  return (
    <>
      <button
        type="button"
        className="sidebar__burger"
        onClick={() => setMobileOpen(true)}
        aria-label="Ouvrir le menu"
      >
        <Menu size={22} />
      </button>

      <aside className="sidebar">{content}</aside>

      {mobileOpen && (
        <div className="sidebar__drawer" role="dialog" aria-modal="true">
          <div className="sidebar__drawer-backdrop" onClick={closeMobile} />
          <aside className="sidebar sidebar--drawer">
            <button
              type="button"
              className="sidebar__close"
              onClick={closeMobile}
              aria-label="Fermer le menu"
            >
              <X size={20} />
            </button>
            {content}
          </aside>
        </div>
      )}
    </>
  );
}
