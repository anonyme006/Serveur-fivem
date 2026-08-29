export interface QboxUiConfig {
  accentColor: string;
  showHunger: boolean;
  showThirst: boolean;
  showHealth: boolean;
  showArmor: boolean;
  showRemoveOutfit: boolean;
}

export interface PlayerStatusState {
  config: QboxUiConfig;
  hunger: number;
  thirst: number;
  health: number;
  armor: number;
}

export const defaultQboxUiConfig: QboxUiConfig = {
  accentColor: '#d4af37',
  showHunger: true,
  showThirst: true,
  showHealth: true,
  showArmor: true,
  showRemoveOutfit: true,
};

export const defaultPlayerStatus: PlayerStatusState = {
  config: defaultQboxUiConfig,
  hunger: 100,
  thirst: 100,
  health: 100,
  armor: 0,
};
