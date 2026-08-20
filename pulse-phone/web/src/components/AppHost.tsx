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
  return (
    <div className="app-frame">
      <div className="app-header">
        <button type="button" className="back-btn" onClick={onBack} aria-label="Retour">
          ‹
        </button>
        <h2>{TITLES[app]}</h2>
      </div>
      <div className="app-body">
        {app === 'services' ? (
          <ServicesApp />
        ) : (
          <p className="placeholder">
            Module <strong>{TITLES[app]}</strong> — fondation prête. L’UI complète arrive à l’étape suivante.
          </p>
        )}
      </div>
    </div>
  );
}
