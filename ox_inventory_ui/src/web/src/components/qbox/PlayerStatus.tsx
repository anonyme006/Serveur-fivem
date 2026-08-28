import React from 'react';
import { useAppSelector } from '../../store';
import { selectPlayerStatus } from '../../store/qboxUi';

const StatBar: React.FC<{
  label: string;
  emoji: string;
  value: number;
  tone?: 'accent' | 'health' | 'armor' | 'hunger' | 'thirst';
}> = ({ label, emoji, value, tone = 'accent' }) => (
  <div className={`player-stat player-stat--${tone}`}>
    <div className="player-stat-header">
      <span className="player-stat-label">
        {emoji} {label}
      </span>
      <span className="player-stat-value">{value}%</span>
    </div>
    <div className="player-stat-track">
      <div className="player-stat-fill" style={{ width: `${value}%` }} />
    </div>
  </div>
);

const PlayerStatus: React.FC = () => {
  const { config, hunger, thirst, health, armor } = useAppSelector(selectPlayerStatus);

  const hasAny =
    config.showHealth || config.showArmor || config.showHunger || config.showThirst;

  if (!hasAny) return null;

  return (
    <div className="player-status-panel">
      {config.showHealth && <StatBar label="Santé" emoji="❤️" value={health} tone="health" />}
      {config.showArmor && <StatBar label="Armure" emoji="🛡️" value={armor} tone="armor" />}
      {config.showHunger && <StatBar label="Faim" emoji="🍔" value={hunger} tone="hunger" />}
      {config.showThirst && <StatBar label="Soif" emoji="💧" value={thirst} tone="thirst" />}
    </div>
  );
};

export default PlayerStatus;
