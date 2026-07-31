import { Logo } from "./Logo";

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="site-footer__brand">
        <Logo size={22} />
        <span>RE ROLL</span>
      </div>
      <div className="site-footer__links">
        <a href="https://discord.gg" target="_blank" rel="noreferrer">
          Discord
        </a>
        <a href="mailto:contact@reroll.gg">Contact</a>
      </div>
    </footer>
  );
}
