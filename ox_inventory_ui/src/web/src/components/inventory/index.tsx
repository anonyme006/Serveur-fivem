import React, { useEffect, useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import InventoryControl from './InventoryControl';
import InventoryHotbar from './InventoryHotbar';
import { useAppDispatch } from '../../store';
import { refreshSlots, setAdditionalMetadata, setupInventory } from '../../store/inventory';
import { useExitListener } from '../../hooks/useExitListener';
import type { Inventory as InventoryProps } from '../../typings';
import RightInventory from './RightInventory';
import LeftInventory from './LeftInventory';
import Tooltip from '../utils/Tooltip';
import { closeTooltip } from '../../store/tooltip';
import InventoryContext from './InventoryContext';
import { closeContextMenu } from '../../store/contextMenu';
import Fade from '../utils/transitions/Fade';
import PlayerStatus from '../qbox/PlayerStatus';
import CharacterPreview from '../qbox/CharacterPreview';
import ClothingSlots from '../qbox/ClothingSlots';
import { setClothingSlots, setPlayerStatus } from '../../store/qboxUi';
import { useAppSelector } from '../../store';
import { selectClothingSlots, selectQboxUiConfig } from '../../store/qboxUi';
import { ClothingSlotsState, PlayerStatusState } from '../../typings/qboxUi';

const Inventory: React.FC = () => {
  const [inventoryVisible, setInventoryVisible] = useState(false);
  const dispatch = useAppDispatch();
  const clothingSlots = useAppSelector(selectClothingSlots);
  const config = useAppSelector(selectQboxUiConfig);

  useNuiEvent<boolean>('setInventoryVisible', setInventoryVisible);
  useNuiEvent<false>('closeInventory', () => {
    setInventoryVisible(false);
    dispatch(closeContextMenu());
    dispatch(closeTooltip());
  });
  useExitListener(setInventoryVisible);

  useNuiEvent<{
    leftInventory?: InventoryProps;
    rightInventory?: InventoryProps;
  }>('setupInventory', (data) => {
    dispatch(setupInventory(data));
    !inventoryVisible && setInventoryVisible(true);
  });

  useNuiEvent('refreshSlots', (data) => dispatch(refreshSlots(data)));

  useNuiEvent('displayMetadata', (data: Array<{ metadata: string; value: string }>) => {
    dispatch(setAdditionalMetadata(data));
  });

  useNuiEvent<PlayerStatusState>('initQboxUi', (data) => {
    dispatch(setPlayerStatus(data));
  });

  useNuiEvent<Partial<PlayerStatusState>>('updatePlayerStatus', (data) => {
    dispatch(setPlayerStatus(data));
  });

  useNuiEvent<ClothingSlotsState>('updateClothingSlots', (data) => {
    dispatch(setClothingSlots(data));
  });

  useEffect(() => {
    document.documentElement.style.setProperty('--accent-color', config.accentColor);
  }, [config.accentColor]);

  return (
    <>
      <Fade in={inventoryVisible}>
        <div className="inventory-shell">
          <PlayerStatus />
          <div className="inventory-wrapper">
            {config.enableClothingSlots && <ClothingSlots slots={clothingSlots.left} side="left" />}
            <div className="inventory-center-column">
              <CharacterPreview />
              <div className="inventory-player-column">
                <LeftInventory />
                <InventoryControl />
              </div>
            </div>
            <div className="inventory-right-column">
              {config.enableClothingSlots && <ClothingSlots slots={clothingSlots.right} side="right" />}
              <RightInventory />
            </div>
          </div>
        </div>
      </Fade>
      <InventoryHotbar />
    </>
  );
};

export default Inventory;
