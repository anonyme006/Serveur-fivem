import {
  Car,
  Cross,
  Fish,
  Heart,
  Helicopter,
  IdCard,
  Plane,
  Sailboat,
  Shield,
  Target,
  Truck,
} from "lucide-react";
import { character, licenses } from "../../data/mock";

const licenseIcons: Record<string, typeof Car> = {
  car: Car,
  truck: Truck,
  moto: Car,
  heli: Helicopter,
  plane: Plane,
  boat: Sailboat,
  weapon: Shield,
  hunt: Target,
  fish: Fish,
  firstaid: Cross,
};

export function Personnage() {
  return (
    <section className="character-page">
      <header className="character-page__header">
        <div>
          <h1>
            Personnage {character.firstName} {character.lastName}{" "}
            <span className="character-page__gender" aria-label="Homme">
              ♂
            </span>{" "}
            <Heart size={18} className="character-page__heart" fill="currentColor" />
          </h1>
          <p className="character-page__online">
            {character.online ? "En ligne" : "Hors ligne"}
          </p>
        </div>
      </header>

      <div className="panel-section">
        <h2>Informations du personnage</h2>
        <div className="info-grid">
          <Info label="Prénom" value={character.firstName} />
          <Info label="Nom" value={character.lastName} />
          <Info label="Nom du joueur" value={character.playerName} />
          <Info label="Numéro de téléphone" value={character.phone} />
          <Info label="Carte grise" value={character.registration} />
          <Info label="Temps de jeu" value={character.playtime} />
        </div>
      </div>

      <div className="panel-section">
        <h2>Job</h2>
        <div className="job-row">
          <span>
            <em>Job:</em> {character.job}
          </span>
          <span>
            <em>Grade:</em> {character.grade}
          </span>
        </div>
      </div>

      <div className="panel-section">
        <h2>Permis</h2>
        <div className="license-grid">
          {licenses.map((license) => {
            const Icon = licenseIcons[license.id] ?? IdCard;
            return (
              <div key={license.id} className="license-item">
                <Icon size={18} />
                <div>
                  <strong>{license.label}</strong>
                  <span>{license.status}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="info-item">
      <span className="info-item__label">{label}</span>
      <span className="info-item__value">{value}</span>
    </div>
  );
}
