import React from 'react';
import { fetchNui } from '../../utils/fetchNui';

const RemoveOutfitButton: React.FC = () => (
  <button type="button" className="remove-outfit-button" onClick={() => fetchNui('qboxUi:removeOutfit', {})}>
    Retirer tenue
  </button>
);

export default RemoveOutfitButton;
