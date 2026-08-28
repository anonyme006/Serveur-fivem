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
          className={`clothing-slot ${slot.equipped ? 'clothing-slot--equipped' : ''}`}
          onClick={() => fetchNui('qboxUi:clickClothingSlot', { id: slot.id })}
        >
          <ClothingIcon name={slot.icon} />
          <div className="clothing-slot-body">
            <span className="clothing-slot-label">{slot.label}</span>
            <span className="clothing-slot-meta">
              {slot.equipped ? 'Équipé' : 'Vide'} · x{slot.quantity}
            </span>
          </div>
        </button>
      ))}
    </div>
  );
};

export default ClothingSlots;
