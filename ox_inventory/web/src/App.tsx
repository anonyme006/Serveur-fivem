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
      leftInventory: { id: 'test', type: 'player', slots: 60, maxWeight: 5000, items: [] },
      items: {
        iron: { name: 'iron', label: 'Iron', stack: true, usable: false, close: false, count: 0, rarity: 'common' },
        copper: {
          name: 'copper',
          label: 'Copper',
          stack: true,
          usable: false,
          close: false,
          count: 0,
          rarity: 'uncommon',
        },
        powersaw: {
          name: 'powersaw',
          label: 'Power Saw',
          stack: false,
          usable: false,
          close: false,
          count: 0,
          rarity: 'rare',
          grid: [2, 1],
        },
        lockpick: {
          name: 'lockpick',
          label: 'Lockpick',
          stack: false,
          usable: true,
          close: true,
          count: 0,
          rarity: 'uncommon',
          grid: [1, 2],
        },
        backwoods: {
          name: 'backwoods',
          label: 'Backwoods',
          stack: false,
          usable: true,
          close: false,
          count: 0,
          rarity: 'legendary',
        },
        armour: {
          name: 'armour',
          label: 'Body Armour',
          stack: false,
          usable: true,
          close: true,
          count: 0,
          rarity: 'epic',
          grid: [2, 2],
          clothing: 'armour',
        },
      },
      uiConfig: {
        layout: 'slots',
        grid: { columns: 10, allowRotate: true },
        clothing: {
          enabled: true,
          slots: [
            { index: 51, name: 'mask', label: 'Masque', side: 'left' },
            { index: 52, name: 'hat', label: 'Chapeau', side: 'left' },
            { index: 53, name: 'glasses', label: 'Lunettes', side: 'left' },
            { index: 54, name: 'torso', label: 'Haut', side: 'left' },
            { index: 55, name: 'armour', label: 'Veste', side: 'left' },
            { index: 56, name: 'legs', label: 'Pantalon', side: 'left' },
            { index: 57, name: 'shoes', label: 'Chaussures', side: 'left' },
            { index: 58, name: 'earpiece', label: 'Boucles d\'oreilles', side: 'right' },
            { index: 59, name: 'backpack', label: 'Sac', side: 'right' },
            { index: 60, name: 'belt', label: 'Ceinture', side: 'right' },
            { index: 61, name: 'gloves', label: 'Bras/Gants', side: 'right' },
            { index: 62, name: 'chain', label: 'Chaînes', side: 'right' },
            { index: 63, name: 'watch', label: 'Montre', side: 'right' },
            { index: 64, name: 'bracelet', label: 'Bracelet', side: 'right' },
            { index: 65, name: 'decals', label: 'Décalque', side: 'right' },
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
          name: 'gold',
          colors: {
            backgroundColor1: 'rgba(40, 34, 18, 0)',
            backgroundColor2: 'rgba(50, 42, 20, 0.05)',
            backgroundColor3: 'rgba(80, 68, 28, 0.12)',
            rgbColor1: 'rgba(212, 175, 55, 0.12)',
            rgbColor2: 'rgba(212, 175, 55, 0.06)',
            mainColor: '#d4af37',
            secondaryColor: '#8a7028',
            textShadow: 'rgba(212, 175, 55, 0.36)',
            photoShadowColor: 'rgba(212, 175, 55, 0.30)',
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
        accentColor: '#d4af37',
        showHealth: true,
        showHunger: true,
        showThirst: true,
        showArmor: true,
        showRemoveOutfit: true,
      },
      hunger: 72,
      thirst: 58,
      health: 85,
      armor: 40,
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
        label: 'Bob Smith',
        weight: 3000,
        maxWeight: 5000,
        items: [
          {
            slot: 1,
            name: 'iron',
            weight: 3000,
            metadata: {
              description: `name: Svetozar Miletic  \n Gender: Male`,
              ammo: 3,
              mustard: '60%',
              ketchup: '30%',
              mayo: '10%',
            },
            count: 5,
          },
          { slot: 2, name: 'powersaw', weight: 0, count: 1, metadata: { durability: 75 } },
          { slot: 3, name: 'copper', weight: 100, count: 12, metadata: { type: 'Special' } },
          {
            slot: 4,
            name: 'water',
            weight: 100,
            count: 1,
            metadata: { description: 'Generic item description' },
          },
          { slot: 5, name: 'water', weight: 100, count: 1 },
          {
            slot: 6,
            name: 'backwoods',
            weight: 100,
            count: 1,
            metadata: {
              label: 'Russian Cream',
              imageurl: 'https://i.imgur.com/2xHhTTz.png',
            },
          },
          { slot: 7, name: 'armour', weight: 3000, count: 1 },
        ],
      },
      rightInventory: {
        id: 'shop',
        type: 'crafting',
        slots: 5000,
        label: 'Bob Smith',
        weight: 3000,
        maxWeight: 5000,
        items: [
          {
            slot: 1,
            name: 'lockpick',
            weight: 500,
            price: 300,
            ingredients: {
              iron: 5,
              copper: 12,
              powersaw: 0.1,
            },
            metadata: {
              description: 'Simple lockpick that breaks easily and can pick basic door locks',
            },
          },
        ],
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
