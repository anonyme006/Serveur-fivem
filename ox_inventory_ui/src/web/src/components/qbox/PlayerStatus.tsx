import React, { useEffect, useRef, useState } from 'react';
import { useAppSelector } from '../../store';
import { selectPlayerStatus } from '../../store/qboxUi';

const StatBar: React.FC<{
  emoji: string;
  value: number;
  tone: 'health' | 'armor' | 'hunger' | 'thirst';
}> = ({ emoji, value, tone }) => {
  const prev = useRef(value);
  const [pulse, setPulse] = useState(false);

  useEffect(() => {
    if (prev.current === value) return;
    prev.current = value;
    setPulse(true);
    const timer = window.setTimeout(() => setPulse(false), 600);
    return () => window.clearTimeout(timer);
  }, [value]);

  return (
    <div className={`player-stat-compact player-stat-compact--${tone}${pulse ? ' player-stat-compact--pulse' : ''}`}>
      <div className="player-stat-compact-top">
        <span className="player-stat-compact-emoji">{emoji}</span>
        <span className="player-stat-compact-value">{value}%</span>
      </div>
      <div className="player-stat-compact-track">
        <div className="player-stat-compact-fill" style={{ width: `${value}%` }} />
      </div>
    </div>
  );
};

const PlayerStatus: React.FC = () => {
  const { config, hunger, thirst, health, armor } = useAppSelector(selectPlayerStatus);

  const hasAny =
    config.showHealth || config.showArmor || config.showHunger || config.showThirst;

  if (!hasAny) return null;

  return (
    <div className="player-status-row">
      {config.showHealth && <StatBar emoji="❤️" value={health} tone="health" />}
      {config.showHunger && <StatBar emoji="🍔" value={hunger} tone="hunger" />}
      {config.showThirst && <StatBar emoji="💧" value={thirst} tone="thirst" />}
      {config.showArmor && <StatBar emoji="🛡️" value={armor} tone="armor" />}
    </div>
  );
};

export default PlayerStatus;
