import { useEffect, useState, type ReactNode } from 'react';
import { fetchNui, isEnvBrowser } from '@/nui/fetchNui';
import type { CompanyPublic } from '@/types/phone';

const MOCK: CompanyPublic[] = [
  {
    id: 'police',
    label: 'Police',
    description: 'Forces de l’ordre et urgences.',
    number: '911',
    category: 'public',
    status: 'open',
    employeesOnline: 4,
  },
  {
    id: 'ambulance',
    label: 'EMS',
    description: 'Services médicaux d’urgence.',
    number: '912',
    category: 'public',
    status: 'busy',
    employeesOnline: 1,
  },
  {
    id: 'mechanic',
    label: 'LS Customs',
    description: 'Réparation et dépannage véhicules.',
    number: '5551001',
    category: 'service',
    status: 'open',
    employeesOnline: 3,
  },
  {
    id: 'burgershot',
    label: 'Burger Shot',
    description: 'Fast-food emblématique de Los Santos.',
    number: '5552001',
    category: 'food',
    status: 'closed',
    employeesOnline: 0,
  },
];

const STATUS_COLOR: Record<CompanyPublic['status'], string> = {
  open: '#22c55e',
  busy: '#f59e0b',
  closed: '#e11d48',
};

const STATUS_LABEL: Record<CompanyPublic['status'], string> = {
  open: 'Ouvert',
  busy: 'Occupé',
  closed: 'Fermé',
};

export function ServicesApp(): ReactNode {
  const [companies, setCompanies] = useState<CompanyPublic[]>([]);
  const [selected, setSelected] = useState<CompanyPublic | null>(null);

  useEffect(() => {
    void (async () => {
      const list = await fetchNui<CompanyPublic[]>(
        'services:getCompanies',
        {},
        isEnvBrowser() ? MOCK : [],
      );
      setCompanies(list ?? []);
    })();
  }, []);

  if (selected) {
    return (
      <div>
        <button type="button" className="back-btn" onClick={() => setSelected(null)}>
          ‹
        </button>
        <h3 style={{ margin: '10px 0 6px' }}>{selected.label}</h3>
        <div className="status-pill">
          <span className="status-dot" style={{ background: STATUS_COLOR[selected.status] }} />
          {STATUS_LABEL[selected.status]}
        </div>
        <p className="company-meta" style={{ marginTop: 8 }}>
          {selected.employeesOnline} employés disponibles
        </p>
        <p className="placeholder" style={{ marginTop: 10 }}>
          {selected.description}
        </p>
        <div style={{ display: 'grid', gap: 8, marginTop: 16 }}>
          <ActionBtn
            label="Appeler"
            onClick={() => fetchNui('calls:start', { number: selected.number, companyId: selected.id })}
          />
          <ActionBtn
            label="Envoyer une demande"
            onClick={() =>
              fetchNui('services:createRequest', {
                companyId: selected.id,
                serviceType: 'general',
                description: 'Demande depuis Pulse Phone',
              })
            }
          />
          <ActionBtn label="Voir les informations" onClick={() => undefined} />
        </div>
      </div>
    );
  }

  return (
    <div>
      {companies.map((c) => (
        <button
          key={c.id}
          type="button"
          className="company-card"
          style={{ width: '100%', textAlign: 'left' }}
          onClick={() => setSelected(c)}
        >
          <h3>{c.label}</h3>
          <div className="status-pill">
            <span className="status-dot" style={{ background: STATUS_COLOR[c.status] }} />
            {STATUS_LABEL[c.status]} · {c.employeesOnline} dispo
          </div>
          <span className="company-meta">{c.category}</span>
        </button>
      ))}
      {!companies.length && <p className="placeholder">Aucune entreprise configurée.</p>}
    </div>
  );
}

function ActionBtn({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        padding: '12px 14px',
        borderRadius: 12,
        background: 'rgba(13,148,136,0.18)',
        border: '1px solid rgba(20,184,166,0.35)',
        textAlign: 'left',
        fontWeight: 600,
      }}
    >
      {label}
    </button>
  );
}
