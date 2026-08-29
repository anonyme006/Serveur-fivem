export interface QboxUiConfig {
  showHunger: boolean;
  showThirst: boolean;
  showHealth: boolean;
  showArmor: boolean;
}

export interface PlayerStatusState {
  config: QboxUiConfig;
  hunger: number;
  thirst: number;
  health: number;
  armor: number;
}

export const defaultQboxUiConfig: QboxUiConfig = {
  showHunger: true,
  showThirst: true,
  showHealth: true,
  showArmor: false,
};

export const defaultPlayerStatus: PlayerStatusState = {
  config: defaultQboxUiConfig,
  hunger: 100,
  thirst: 100,
  health: 100,
  armor: 0,
};
