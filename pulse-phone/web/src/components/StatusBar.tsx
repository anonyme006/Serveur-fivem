import type { ReactNode } from 'react';

interface StatusBarProps {
  time: string;
  battery: number;
  signal: number;
}

export function StatusBar({ time, battery, signal }: StatusBarProps): ReactNode {
  const level = Math.max(0, Math.min(4, signal));
  return (
    <div className="status-bar">
      <span>{time}</span>
      <div className="status-bar__meta">
        <div className="signal" aria-label={`Signal ${level}/4`}>
          {[1, 2, 3, 4].map((i) => (
            <span key={i} className={i <= level ? 'on' : ''} />
          ))}
        </div>
        <span>5G</span>
        <div className="battery" aria-label={`Batterie ${battery}%`}>
          <i style={{ width: `${Math.max(8, Math.min(100, battery))}%` }} />
        </div>
      </div>
    </div>
  );
}
