import { Link } from "react-router-dom";
import { ChevronDown } from "lucide-react";
import { Logo } from "../components/Logo";
import { Skyline } from "../components/Skyline";

const leftNav = [
  { label: "Accueil", to: "/" },
  { label: "Le serveur", to: "#serveur" },
  { label: "Nous rejoindre", to: "/login" },
];

const rightNav = [
  { label: "Participer", to: "#participer" },
  { label: "Discord", href: "https://discord.gg" },
  { label: "Les lives", to: "#lives" },
  { label: "Panel", to: "/login" },
];

export function Landing() {
  return (
    <div className="landing">
      <div className="skyline-bg" aria-hidden="true">
        <Skyline className="skyline-bg__art landing__skyline" />
      </div>

      <header className="landing__nav">
        <nav className="landing__nav-side" aria-label="Navigation gauche">
          {leftNav.map((item) =>
            item.to.startsWith("#") ? (
              <a key={item.label} href={item.to}>
                {item.label}
              </a>
            ) : (
              <Link key={item.label} to={item.to}>
                {item.label}
              </Link>
            ),
          )}
        </nav>

        <Link to="/" className="landing__nav-logo" aria-label="RE ROLL">
          <Logo size={36} />
        </Link>

        <nav className="landing__nav-side landing__nav-side--right" aria-label="Navigation droite">
          {rightNav.map((item) =>
            "href" in item && item.href ? (
              <a key={item.label} href={item.href} target="_blank" rel="noreferrer">
                {item.label}
              </a>
            ) : (
              <Link key={item.label} to={item.to!}>
                {item.label}
              </Link>
            ),
          )}
        </nav>
      </header>

      <main className="landing__hero">
        <div className="landing__brand">
          <Logo size={140} framed className="landing__die" />
          <div className="landing__titles">
            <h1>
              <span>RE</span>
              <span className="landing__roll">ROLL</span>
            </h1>
            <p className="landing__tagline">Mourir n&apos;est plus un choix</p>
            <div className="landing__ctas">
              <Link to="/login" className="btn btn--ghost">
                Nous rejoindre
              </Link>
              <a
                href="https://discord.gg"
                target="_blank"
                rel="noreferrer"
                className="btn btn--ghost"
              >
                Discord
              </a>
              <a href="#participer" className="btn btn--ghost">
                Participer
              </a>
            </div>
          </div>
        </div>
      </main>

      <div className="landing__scroll" aria-hidden="true">
        <ChevronDown size={22} />
        <ChevronDown size={22} />
        <ChevronDown size={22} />
      </div>
    </div>
  );
}
