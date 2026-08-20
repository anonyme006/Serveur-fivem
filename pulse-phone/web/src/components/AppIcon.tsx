import type { ReactNode } from 'react';

interface AppIconProps {
  label: string;
  glyph: string;
  color: string;
  onClick?: () => void;
}

export function AppIcon({ label, glyph, color, onClick }: AppIconProps): ReactNode {
  return (
    <button type="button" className="app-icon" onClick={onClick}>
      <span className="app-icon__glyph" style={{ background: color }}>
        {glyph}
      </span>
      <span className="app-icon__label">{label}</span>
    </button>
  );
}
