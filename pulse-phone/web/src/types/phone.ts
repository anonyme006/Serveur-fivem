export type ThemeMode = 'dark' | 'light';

export type AppId =
  | 'phone'
  | 'contacts'
  | 'messages'
  | 'services'
  | 'bank'
  | 'wallet'
  | 'garage'
  | 'marketplace'
  | 'gps'
  | 'settings'
  | 'companyManage';

export interface PhoneColors {
  accent: string;
  accentSoft: string;
  danger: string;
  warning: string;
  success: string;
  surface: string;
  surfaceElevated: string;
  text: string;
  textMuted: string;
}

export interface PhoneProfile {
  citizenid: string;
  firstname: string;
  lastname: string;
  phoneNumber: string;
  wallpaper: string;
  theme: ThemeMode;
  battery: number;
  signal: number;
  time?: string;
  date?: string;
}

export interface PhoneConfigPayload {
  theme: ThemeMode;
  wallpaper: string;
  colors: PhoneColors;
  apps: Record<string, boolean>;
  locale: string;
  position: { x: number; y: number };
  animations: { openMs: number; closeMs: number };
  sounds: { enabled: boolean; volume: number };
}

export interface NotificationItem {
  id: string;
  type: string;
  title: string;
  body: string;
  duration?: number;
  payload?: unknown;
  createdAt: number;
}

export interface CompanyPublic {
  id: string;
  label: string;
  description: string;
  number: string;
  category: string;
  status: 'open' | 'busy' | 'closed';
  employeesOnline: number;
  logo?: string | null;
  position?: { x: number; y: number; z: number } | null;
}

export interface CallState {
  id: number;
  number: string;
  name?: string;
  direction: 'incoming' | 'outgoing';
  status: string;
  companyId?: string;
  channel?: number;
}

export type NuiIncomingAction =
  | 'phone:init'
  | 'phone:open'
  | 'phone:close'
  | 'phone:status'
  | 'notifications:push'
  | 'calls:update'
  | 'sounds:play'
  | 'serviceRequest'
  | string;
