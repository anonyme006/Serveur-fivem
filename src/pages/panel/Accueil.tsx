import { Play } from "lucide-react";
import { Logo } from "../../components/Logo";
import { serverStatus } from "../../data/mock";

export function Accueil() {
  return (
    <section className="home-panel">
      <div className="home-panel__brand">
        <Logo size={96} />
        <div>
          <h1>
            <span>RE</span>
            <span className="accent">ROLL</span>
          </h1>
          <p className="home-panel__tagline">Mourir n&apos;est plus un choix</p>
        </div>
      </div>

      <div className="status-box">
        <div className="status-box__header">Statut du compte</div>
        <div
          className={`status-box__body ${
            serverStatus.whitelistAccepted ? "is-success" : "is-pending"
          }`}
        >
          {serverStatus.whitelistAccepted ? (
            <>
              <span className="status-box__check" aria-hidden="true">
                ✓
              </span>
              Votre whitelist a été acceptée. Bienvenue sur le serveur !
            </>
          ) : (
            <>Votre demande de whitelist est en cours d&apos;examen.</>
          )}
        </div>
      </div>

      <button type="button" className="queue-btn">
        <span className="queue-btn__main">
          <Play size={20} fill="currentColor" />
          Rejoindre la file
        </span>
        <span className="queue-btn__meta">{serverStatus.players} en ligne</span>
      </button>
    </section>
  );
}
