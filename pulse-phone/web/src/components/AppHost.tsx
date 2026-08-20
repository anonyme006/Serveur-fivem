import type { ReactNode } from 'react';
import type { AppId } from '@/types/phone';
import { ServicesApp } from '@/apps/ServicesApp';

interface AppHostProps {
  app: AppId;
  onBack: () => void;
}

const TITLES: Record<AppId, string> = {
  phone: 'Téléphone',
  contacts: 'Contacts',
  messages: 'Messages',
  services: 'Services',
  bank: 'Banque',
  wallet: 'Wallet',
  garage: 'Garage',
  marketplace: 'Marketplace',
  gps: 'GPS',
  settings: 'Réglages',
  companyManage: 'Entreprise',
};

export function AppHost({ app, onBack }: AppHostProps): ReactNode {
  if (app === 'services') {
    return (
      <div className="app-frame app-frame--services">
        <button type="button" className="svc-close-app" onClick={onBack} aria-label="Fermer">
          ‹ Accueil
        </button>
        <ServicesApp />
      </div>
    );
  }

  return (
    <div className="app-frame">
      <div className="app-header">
        <button type="button" className="back-btn" onClick={onBack} aria-label="Retour">
          ‹
        </button>
        <h2>{TITLES[app]}</h2>
      </div>
      <div className="app-body">
        <p className="placeholder">
          Module <strong>{TITLES[app]}</strong> — fondation prête. L’UI complète arrive à l’étape suivante.
        </p>
      </div>
    </div>
  );
}
