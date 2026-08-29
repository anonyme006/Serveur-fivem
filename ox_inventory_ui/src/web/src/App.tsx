import InventoryComponent from './components/inventory';
import useNuiEvent from './hooks/useNuiEvent';
import { Items } from './store/items';
import { Locale } from './store/locale';
import { setImagePath } from './store/imagepath';
import { setupInventory } from './store/inventory';
import { Inventory } from './typings';
import { useAppDispatch } from './store';
import { debugData } from './utils/debugData';
import DragPreview from './components/utils/DragPreview';
import { fetchNui } from './utils/fetchNui';
import { useDragDropManager } from 'react-dnd';
import KeyPress from './components/utils/KeyPress';

debugData([
  {
    action: 'initQboxUi',
    data: {
      config: {
        accentColor: '#d4af37',
        showHunger: true,
        showThirst: true,
        showHealth: true,
        showArmor: true,
        showCharacter: true,
        showClothing: true,
        enableCharacterRotation: true,
        enableCharacterZoom: true,
        characterBackground: 'dark',
      },
      hunger: 82,
      thirst: 67,
      health: 100,
      armor: 50,
    },
  },
  {
    action: 'updateClothingSlots',
    data: {
      left: [
        { id: 'mask', label: 'Masque', icon: 'mask', equipped: false, drawable: 0, texture: 0, quantity: 0 },
        { id: 'hat', label: 'Chapeau', icon: 'hat', equipped: true, drawable: 1, texture: 0, quantity: 1 },
        { id: 'glasses', label: 'Lunettes', icon: 'glasses', equipped: false, drawable: -1, texture: 0, quantity: 0 },
        { id: 'top', label: 'Haut', icon: 'top', equipped: true, drawable: 4, texture: 0, quantity: 1 },
        { id: 'vest', label: 'Veste', icon: 'vest', equipped: false, drawable: 0, texture: 0, quantity: 0 },
        { id: 'pants', label: 'Pantalon', icon: 'pants', equipped: true, drawable: 3, texture: 0, quantity: 1 },
        { id: 'shoes', label: 'Chaussures', icon: 'shoes', equipped: true, drawable: 2, texture: 0, quantity: 1 },
      ],
      right: [
        { id: 'chain', label: 'Chaînes', icon: 'chain', equipped: true, drawable: 1, texture: 0, quantity: 1 },
        { id: 'ears', label: 'Boucles d\'oreilles', icon: 'earrings', equipped: false, drawable: -1, texture: 0, quantity: 0 },
        { id: 'bag', label: 'Sac', icon: 'bag', equipped: false, drawable: 0, texture: 0, quantity: 0 },
        { id: 'belt', label: 'Ceinture', icon: 'belt', equipped: false, drawable: 0, texture: 0, quantity: 0 },
        { id: 'watch', label: 'Montre', icon: 'watch', equipped: false, drawable: -1, texture: 0, quantity: 0 },
        { id: 'bracelet', label: 'Bracelet', icon: 'bracelet', equipped: false, drawable: -1, texture: 0, quantity: 0 },
        { id: 'decals', label: 'Décalque', icon: 'decals', equipped: false, drawable: 0, texture: 0, quantity: 0 },
        { id: 'arms', label: 'Bras/Gants', icon: 'arms', equipped: true, drawable: 1, texture: 0, quantity: 1 },
      ],
    },
  },
  {
    action: 'setupInventory',
    data: {
      leftInventory: {
        id: 'test',
        type: 'player',
        slots: 50,
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

  useNuiEvent<{
    locale: { [key: string]: string };
    items: typeof Items;
    leftInventory: Inventory;
    imagepath: string;
  }>('init', ({ locale, items, leftInventory, imagepath }) => {
    for (const name in locale) Locale[name] = locale[name];
    for (const name in items) Items[name] = items[name];

    setImagePath(imagepath);
    dispatch(setupInventory({ leftInventory }));
  });

  fetchNui('uiLoaded', {});

  useNuiEvent('closeInventory', () => {
    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  return (
    <div className="app-wrapper">
      <InventoryComponent />
      <DragPreview />
      <KeyPress />
    </div>
  );
};

addEventListener('dragstart', function (event) {
  event.preventDefault();
});

export default App;
