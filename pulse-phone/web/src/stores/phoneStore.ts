import { create } from 'zustand';
import type {
  AppId,
  CallState,
  NotificationItem,
  PhoneConfigPayload,
  PhoneProfile,
} from '@/types/phone';

interface PhoneStore {
  visible: boolean;
  locked: boolean;
  activeApp: AppId | null;
  profile: PhoneProfile | null;
  config: PhoneConfigPayload | null;
  battery: number;
  signal: number;
  time: string;
  date: string;
  notifications: NotificationItem[];
  call: CallState | null;
  position: { x: number; y: number };
  setOpen: (payload: { profile: PhoneProfile; config: PhoneConfigPayload }) => void;
  setClosed: () => void;
  unlock: () => void;
  lock: () => void;
  openApp: (app: AppId) => void;
  closeApp: () => void;
  pushNotification: (n: Omit<NotificationItem, 'id' | 'createdAt'> & { id?: string }) => void;
  setStatus: (partial: { battery?: number; signal?: number; time?: string; date?: string }) => void;
  setCall: (call: CallState | null) => void;
  setPosition: (pos: { x: number; y: number }) => void;
}

function clockNow(): string {
  const d = new Date();
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

function dateNow(): string {
  return new Intl.DateTimeFormat('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(new Date());
}

export const usePhoneStore = create<PhoneStore>((set, get) => ({
  visible: false,
  locked: true,
  activeApp: null,
  profile: null,
  config: null,
  battery: 100,
  signal: 4,
  time: clockNow(),
  date: dateNow(),
  notifications: [],
  call: null,
  position: { x: 0.82, y: 0.55 },

  setOpen: ({ profile, config }) =>
    set({
      visible: true,
      locked: true,
      activeApp: null,
      profile,
      config,
      battery: profile.battery ?? 100,
      signal: profile.signal ?? 4,
      time: profile.time ?? clockNow(),
      date: profile.date ?? dateNow(),
      position: config.position ?? get().position,
    }),

  setClosed: () =>
    set({
      visible: false,
      locked: true,
      activeApp: null,
      call: null,
    }),

  unlock: () => set({ locked: false }),
  lock: () => set({ locked: true, activeApp: null }),
  openApp: (app) => set({ activeApp: app, locked: false }),
  closeApp: () => set({ activeApp: null }),

  pushNotification: (n) => {
    const item: NotificationItem = {
      id: n.id ?? `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      type: n.type,
      title: n.title,
      body: n.body,
      duration: n.duration,
      payload: n.payload,
      createdAt: Date.now(),
    };
    set({ notifications: [item, ...get().notifications].slice(0, 20) });
  },

  setStatus: (partial) => set(partial),
  setCall: (call) => set({ call }),
  setPosition: (position) => set({ position }),
}));
