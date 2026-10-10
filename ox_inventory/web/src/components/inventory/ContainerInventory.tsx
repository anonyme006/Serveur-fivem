import React from 'react';
import InventoryGrid from './InventoryGrid';
import SpatialGrid from './SpatialGrid';
import { useAppSelector } from '../../store';
import { selectContainerInventory } from '../../store/inventory';
import { hasContainerPanel } from '../../helpers';
import { UiConfig } from '../../store/uiConfig';

export const useShowContainer = (): boolean => useAppSelector((state) => hasContainerPanel(state.inventory));

const ContainerInventory: React.FC = () => {
  const containerInventory = useAppSelector(selectContainerInventory);
  const show = useShowContainer();

  if (!show) return null;

  return UiConfig.layout === 'grid' ? (
    <SpatialGrid inventory={containerInventory} />
  ) : (
    <InventoryGrid inventory={containerInventory} />
  );
};

export default ContainerInventory;
