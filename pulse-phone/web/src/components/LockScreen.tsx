import type { ReactNode } from 'react';

interface LockScreenProps {
  time: string;
  date: string;
  onUnlock: () => void;
}

export function LockScreen({ time, date, onUnlock }: LockScreenProps): ReactNode {
  return (
    <div className="lock-screen">
      <div className="lock-brand">Pulse</div>
      <div className="lock-time">{time}</div>
      <div className="lock-date">{date}</div>
      <button type="button" className="lock-hint" onClick={onUnlock}>
        Glisser pour déverrouiller
      </button>
    </div>
  );
}
