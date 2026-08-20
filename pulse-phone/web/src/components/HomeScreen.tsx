import type { ReactNode } from 'react';
import { AppIcon } from '@/components/AppIcon';
import type { AppId } from '@/types/phone';

interface HomeScreenProps {
  appsEnabled: Record<string, boolean>;
  onOpenApp: (app: AppId) => void;
}

const GRID: { id: AppId; label: string; glyph: string; color: string }[] = [
  { id: 'phone', label: 'Téléphone', glyph: '☎', color: 'linear-gradient(145deg,#16a34a,#15803d)' },
  { id: 'contacts', label: 'Contacts', glyph: '◉', color: 'linear-gradient(145deg,#ca8a04,#a16207)' },
  { id: 'messages', label: 'Messages', glyph: '✎', color: 'linear-gradient(145deg,#0284c7,#0369a1)' },
  { id: 'services', label: 'Services', glyph: '▣', color: 'linear-gradient(145deg,#0d9488,#0f766e)' },
  { id: 'bank', label: 'Banque', glyph: '₤', color: 'linear-gradient(145deg,#4d7c0f,#3f6212)' },
  { id: 'wallet', label: 'Wallet', glyph: '▢', color: 'linear-gradient(145deg,#b45309,#92400e)' },
  { id: 'garage', label: 'Garage', glyph: '▣', color: 'linear-gradient(145deg,#475569,#334155)' },
  { id: 'marketplace', label: 'Market', glyph: '◈', color: 'linear-gradient(145deg,#be123c,#9f1239)' },
  { id: 'gps', label: 'GPS', glyph: '◎', color: 'linear-gradient(145deg,#0e7490,#155e75)' },
  { id: 'settings', label: 'Réglages', glyph: '⚙', color: 'linear-gradient(145deg,#64748b,#475569)' },
];

const DOCK: AppId[] = ['phone', 'messages', 'services', 'settings'];

export function HomeScreen({ appsEnabled, onOpenApp }: HomeScreenProps): ReactNode {
  const visible = GRID.filter((a) => appsEnabled[a.id] !== false);
  const dockApps = DOCK.map((id) => visible.find((a) => a.id === id)).filter(Boolean) as typeof GRID;

  return (
    <div className="home-screen">
      <div className="home-grid">
        {visible
          .filter((a) => !DOCK.includes(a.id))
          .map((app) => (
            <AppIcon
              key={app.id}
              label={app.label}
              glyph={app.glyph}
              color={app.color}
              onClick={() => onOpenApp(app.id)}
            />
          ))}
      </div>
      <div className="dock">
        {dockApps.map((app) => (
          <AppIcon
            key={app.id}
            label={app.label}
            glyph={app.glyph}
            color={app.color}
            onClick={() => onOpenApp(app.id)}
          />
        ))}
      </div>
    </div>
  );
}
