export interface QboxUiConfig {
  accentColor: string;
  showHunger: boolean;
  showThirst: boolean;
  showHealth: boolean;
  showArmor: boolean;
  showCharacter: boolean;
  enableClothingSlots: boolean;
  enableCharacterRotation: boolean;
  enableCharacterZoom: boolean;
  characterBackground: 'transparent' | 'dark';
}

export interface PlayerStatusState {
  config: QboxUiConfig;
  hunger: number;
  thirst: number;
  health: number;
  armor: number;
}

export interface ClothingSlot {
  id: string;
  label: string;
  icon: string;
  equipped: boolean;
  drawable: number;
  texture: number;
  quantity: number;
}

export interface ClothingSlotsState {
  left: ClothingSlot[];
  right: ClothingSlot[];
}

export const defaultQboxUiConfig: QboxUiConfig = {
  accentColor: '#d946ef',
  showHunger: true,
  showThirst: true,
  showHealth: true,
  showArmor: true,
  showCharacter: true,
  enableClothingSlots: true,
  enableCharacterRotation: true,
  enableCharacterZoom: true,
  characterBackground: 'dark',
};

export const defaultPlayerStatus: PlayerStatusState = {
  config: defaultQboxUiConfig,
  hunger: 100,
  thirst: 100,
  health: 100,
  armor: 0,
};

export const defaultClothingSlots: ClothingSlotsState = {
  left: [],
  right: [],
};
