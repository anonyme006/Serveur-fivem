import { X } from 'lucide-react';
import type { ReactNode } from 'react';
import { Button } from './Button';

export function PanelShell({
  title,
  subtitle,
  children,
  onClose,
  size = 'default',
  actions,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
  onClose: () => void;
  size?: 'default' | 'compact' | 'narrow';
  actions?: ReactNode;
}) {
  return (
    <div className={`panel-shell ${size === 'compact' ? 'compact' : ''} ${size === 'narrow' ? 'narrow' : ''}`}>
      <header className="topbar">
        <div className="topbar-brand">
          <div className="logo-mark">SC</div>
          <div>
            <h1>{title}</h1>
            {subtitle ? <p>{subtitle}</p> : null}
          </div>
        </div>
        <div className="topbar-actions">
          {actions}
          <Button variant="ghost" size="icon" onClick={onClose} title="Fermer (ESC)">
            <X size={18} />
          </Button>
        </div>
      </header>
      {children}
    </div>
  );
}

export function NavItem({
  active,
  icon,
  label,
  onClick,
}: {
  active?: boolean;
  icon: ReactNode;
  label: string;
  onClick: () => void;
}) {
  return (
    <button type="button" className={`nav-item ${active ? 'active' : ''}`} onClick={onClick}>
      {icon}
      <span>{label}</span>
    </button>
  );
}
