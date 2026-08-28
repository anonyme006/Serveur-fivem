import React, { useEffect, useRef, useState } from 'react';
import { useAppSelector } from '../../store';
import { selectPlayerStatus } from '../../store/qboxUi';

const SEGMENTS = 20;

const BlockBar: React.FC<{ value: number; tone: string }> = ({ value, tone }) => {
  const filled = Math.round((value / 100) * SEGMENTS);

  return (
    <div className={`player-stat-blocks player-stat-blocks--${tone}`} aria-hidden="true">
      {Array.from({ length: SEGMENTS }, (_, index) => (
        <span key={index} className={index < filled ? 'player-stat-block player-stat-block--filled' : 'player-stat-block'} />
      ))}
    </div>
  );
};

const StatBar: React.FC<{
  label: string;
  emoji: string;
  value: number;
  tone: 'health' | 'armor' | 'hunger' | 'thirst';
}> = ({ label, emoji, value, tone }) => {
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
    <div className={`player-stat player-stat--${tone}${pulse ? ' player-stat--pulse' : ''}`}>
      <div className="player-stat-header">
        <span className="player-stat-label">
          {emoji} {label}
        </span>
        <span className="player-stat-value">{value}%</span>
      </div>
      <div className="player-stat-track">
        <div className="player-stat-fill" style={{ width: `${value}%` }} />
      </div>
      <BlockBar value={value} tone={tone} />
    </div>
  );
};

const PlayerStatus: React.FC = () => {
  const { config, hunger, thirst, health, armor } = useAppSelector(selectPlayerStatus);

  const hasAny =
    config.showHealth || config.showArmor || config.showHunger || config.showThirst;

  if (!hasAny) return null;

  return (
    <div className="player-status-panel">
      {config.showHealth && <StatBar label="Santé" emoji="❤️" value={health} tone="health" />}
      {config.showHunger && <StatBar label="Faim" emoji="🍔" value={hunger} tone="hunger" />}
      {config.showThirst && <StatBar label="Soif" emoji="💧" value={thirst} tone="thirst" />}
      {config.showArmor && <StatBar label="Armure" emoji="🛡️" value={armor} tone="armor" />}
    </div>
  );
};

export default PlayerStatus;
