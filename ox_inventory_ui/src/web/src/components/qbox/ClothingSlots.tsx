import React from 'react';
import { fetchNui } from '../../utils/fetchNui';
import { ClothingSlot } from '../../typings/qboxUi';
import ClothingIcon from './ClothingIcons';

interface Props {
  slots: ClothingSlot[];
  side: 'left' | 'right';
}

const ClothingSlots: React.FC<Props> = ({ slots, side }) => {
  if (!slots.length) return null;

  return (
    <div className={`clothing-slots clothing-slots--${side}`}>
      {slots.map((slot) => (
        <button
          key={slot.id}
          type="button"
          title={slot.label}
          className={`clothing-slot ${slot.equipped ? 'clothing-slot--equipped' : ''}`}
          onClick={() => fetchNui('qboxUi:clickClothingSlot', { id: slot.id })}
        >
          <span className="clothing-slot-icon">
            <ClothingIcon name={slot.icon} />
          </span>
          <span className="clothing-slot-label">{slot.label}</span>
        </button>
      ))}
    </div>
  );
};

export default ClothingSlots;
