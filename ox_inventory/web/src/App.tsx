import React, { useState, useEffect } from 'react';
import InventoryComponent from './components/inventory';
import useNuiEvent from './hooks/useNuiEvent';
import { Items } from './store/items';
import { Locale } from './store/locale';
import { setImagePath } from './store/imagepath';
import { setUiConfig } from './store/uiConfig';
import { setPrefs } from './store/preferences';
import { setFastSlots } from './store/fastSlots';
import { setupInventory } from './store/inventory';
import { setPlayerStatus } from './store/qboxUi';
import { PlayerStatusState } from './typings/qboxUi';
import { Inventory, UiConfigMessage } from './typings';
import { useAppDispatch } from './store';
import { debugData } from './utils/debugData';
import DragPreview from './components/utils/DragPreview';
import { fetchNui } from './utils/fetchNui';
import { useDragDropManager } from 'react-dnd';
import KeyPress from './components/utils/KeyPress';

debugData([
  {
    action: 'init',
    data: {
      locale: {},
      imagepath: 'images',
      leftInventory: { id: 'test', type: 'player', slots: 60, maxWeight: 85000, items: [] },
      fastSlots: [1, 2, 3, 4, 5],
      items: {
        iron: { name: 'iron', label: 'Iron', stack: true, usable: false, close: false, count: 0, rarity: 'common' },
        copper: { name: 'copper', label: 'Copper', stack: true, usable: false, close: false, count: 0, rarity: 'uncommon' },
        lockpick: { name: 'lockpick', label: 'Lockpick', stack: false, usable: true, close: true, count: 0, rarity: 'uncommon' },
        armour: { name: 'armour', label: 'Body Armour', stack: false, usable: true, close: true, count: 0, rarity: 'epic', clothing: 'armour' },
        phone: { name: 'phone', label: 'Phone', stack: false, usable: true, close: true, count: 0, rarity: 'rare' },
        water: { name: 'water', label: 'Water', stack: true, usable: true, close: true, count: 0, rarity: 'common' },
        bandage: { name: 'bandage', label: 'Bandage', stack: true, usable: true, close: true, count: 0, rarity: 'common' },
      },
      uiConfig: {
        layout: 'slots',
        grid: { columns: 10, allowRotate: true },
        hotbar: { enabled: true, count: 5 },
        clothing: {
          enabled: true,
          slots: [
            { index: 51, name: 'hat', label: 'Hat', side: 'left' },
            { index: 52, name: 'glasses', label: 'Glasses', side: 'left' },
            { index: 53, name: 'mask', label: 'Mask', side: 'left' },
            { index: 54, name: 'earpiece', label: 'Earpiece', side: 'left' },
            { index: 55, name: 'torso', label: 'Torso', side: 'left' },
            { index: 56, name: 'armour', label: 'Armour', side: 'right' },
            { index: 57, name: 'backpack', label: 'Backpack', side: 'right' },
            { index: 58, name: 'gloves', label: 'Gloves', side: 'right' },
            { index: 59, name: 'legs', label: 'Legs', side: 'right' },
            { index: 60, name: 'shoes', label: 'Shoes', side: 'right' },
          ],
        },
        rarity: {
          enabled: true,
          default: 'common',
          tiers: {
            common: { label: 'Common', color: '#9CA3AF', order: 1 },
            uncommon: { label: 'Uncommon', color: '#4ADE80', order: 2 },
            rare: { label: 'Rare', color: '#38BDF8', order: 3 },
            epic: { label: 'Epic', color: '#A855F7', order: 4 },
            legendary: { label: 'Legendary', color: '#F59E0B', order: 5 },
            mythic: { label: 'Mythic', color: '#FB7185', order: 6 },
          },
        },
        theme: {
          name: 'yellow',
          colors: {
            backgroundColor1: 'rgba(75, 83, 24, 0)',
            backgroundColor2: 'rgba(71, 80, 18, 0.05)',
            backgroundColor3: 'rgba(118, 134, 24, 0.1)',
            rgbColor1: 'rgba(192, 224, 15, 0.10)',
            rgbColor2: 'rgba(192, 224, 15, 0.05)',
            mainColor: '#C0E00F',
            secondaryColor: '#697A08',
            textShadow: 'rgba(192, 224, 15, 0.36)',
            photoShadowColor: 'rgba(192, 224, 15, 0.30)',
          },
        },
      },
    },
  },
]);

debugData([
  {
    action: 'initQboxUi',
    data: {
      config: {
        showHealth: true,
        showHunger: true,
        showThirst: true,
        showArmor: false,
      },
      hunger: 82,
      thirst: 57,
      health: 100,
      armor: 0,
    },
  },
]);

debugData([
  {
    action: 'setupInventory',
    data: {
      leftInventory: {
        id: 'test',
        type: 'player',
        slots: 60,
        label: 'Samuel Black',
        weight: 27200,
        maxWeight: 85000,
        items: [
          { slot: 1, name: 'lockpick', weight: 500, count: 1 },
          { slot: 2, name: 'phone', weight: 200, count: 1 },
          { slot: 3, name: 'bandage', weight: 100, count: 3 },
          { slot: 4, name: 'water', weight: 100, count: 2 },
          { slot: 5, name: 'armour', weight: 3000, count: 1 },
          { slot: 6, name: 'iron', weight: 2000, count: 2 },
          { slot: 7, name: 'copper', weight: 100, count: 5 },
          { slot: 8, name: 'lockpick', weight: 500, count: 1 },
          { slot: 9, name: 'water', weight: 100, count: 1 },
          { slot: 10, name: 'bandage', weight: 100, count: 2 },
          { slot: 11, name: 'iron', weight: 2000, count: 1 },
          { slot: 12, name: 'copper', weight: 100, count: 4 },
          { slot: 13, name: 'phone', weight: 200, count: 1 },
          { slot: 14, name: 'water', weight: 100, count: 1 },
          { slot: 15, name: 'lockpick', weight: 500, count: 1 },
          { slot: 16, name: 'bandage', weight: 100, count: 1 },
          { slot: 17, name: 'iron', weight: 2000, count: 1 },
          { slot: 18, name: 'copper', weight: 100, count: 3 },
        ],
      },
      rightInventory: {
        id: 'other',
        type: 'stash',
        slots: 50,
        label: 'Other Inventory',
        weight: 0,
        maxWeight: 85000,
        items: [],
      },
    },
  },
]);

const App: React.FC = () => {
  const dispatch = useAppDispatch();
  const manager = useDragDropManager();
  const [noBackdrop, setNoBackdrop] = useState(false);

  useNuiEvent<{
    locale: { [key: string]: string };
    items: typeof Items;
    leftInventory: Inventory;
    imagepath: string;
    uiConfig?: UiConfigMessage;
    backpackInventory?: Inventory;
    fastSlots?: number[];
  }>('init', ({ locale, items, leftInventory, imagepath, uiConfig, backpackInventory, fastSlots }) => {
    for (const name in locale) Locale[name] = locale[name];
    for (const name in items) Items[name] = items[name];

    setImagePath(imagepath);
    setUiConfig(uiConfig);
    setPrefs(uiConfig?.prefs);
    setFastSlots(fastSlots);
    dispatch(setupInventory({ leftInventory, backpackInventory }));
    fetchNui<PlayerStatusState>('qboxUi:requestInit', {}).then((data) => {
      if (data) dispatch(setPlayerStatus(data));
    });
  });

  useNuiEvent<number[]>('setFastSlots', setFastSlots);

  fetchNui('uiLoaded', {});

  useNuiEvent('closeInventory', () => {
    manager.dispatch({ type: 'dnd-core/END_DRAG' });
    setNoBackdrop(false); // Reset on close
  });

  useNuiEvent<boolean>('setNoBackdrop', setNoBackdrop);

  // Apply no-backdrop-mode class to body and #root for proper pointer-events passthrough
  useEffect(() => {
    const root = document.getElementById('root');
    if (noBackdrop) {
      document.body.classList.add('no-backdrop-mode');
      root?.classList.add('no-backdrop-mode');
    } else {
      document.body.classList.remove('no-backdrop-mode');
      root?.classList.remove('no-backdrop-mode');
    }
  }, [noBackdrop]);

  // When in no-backdrop mode, detect clicks on the right side and transfer focus to sd-crafting
  useEffect(() => {
    if (!noBackdrop) return;

    const handleClick = (e: MouseEvent) => {
      const screenMidpoint = window.innerWidth / 2;
      if (e.clientX > screenMidpoint) {
        // Click was on the right side - transfer focus to sd-crafting
        fetchNui('transferFocusToCrafting', {});
      }
    };

    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, [noBackdrop]);

  return (
    <div className={`app-wrapper${noBackdrop ? ' no-backdrop-mode' : ''}`}>
      <InventoryComponent />
      <DragPreview />
      <KeyPress />
    </div>
  );
};

addEventListener("dragstart", function(event) {
  event.preventDefault()
})

export default App;
