import {
  createContext,
  createElement,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { fetchNui } from '../lib/nui';
import type { AppMode, ManagementData, Shop } from '../types';

interface Toast {
  id: number;
  type: 'success' | 'error' | 'info';
  message: string;
}

interface AppState {
  visible: boolean;
  mode: AppMode | null;
  shopId: number | null;
  shop: Shop | null;
  management: ManagementData | null;
  loading: boolean;
  toasts: Toast[];
  setVisible: (v: boolean) => void;
  setMode: (m: AppMode | null) => void;
  setShop: (s: Shop | null) => void;
  setShopId: (id: number | null) => void;
  setManagement: (m: ManagementData | null) => void;
  setLoading: (v: boolean) => void;
  pushToast: (type: Toast['type'], message: string) => void;
  dismissToast: (id: number) => void;
  closeUi: () => Promise<void>;
  hydrate: (payload: {
    visible?: boolean;
    mode?: AppMode;
    shopId?: number;
    shop?: Shop;
    management?: ManagementData;
  }) => void;
}

const AppContext = createContext<AppState | null>(null);

let toastSeq = 1;

export function AppProvider({ children }: { children: ReactNode }) {
  const [visible, setVisible] = useState(false);
  const [mode, setMode] = useState<AppMode | null>(null);
  const [shopId, setShopId] = useState<number | null>(null);
  const [shop, setShop] = useState<Shop | null>(null);
  const [management, setManagement] = useState<ManagementData | null>(null);
  const [loading, setLoading] = useState(false);
  const [toasts, setToasts] = useState<Toast[]>([]);

  const pushToast = useCallback((type: Toast['type'], message: string) => {
    const id = toastSeq++;
    setToasts((t) => [...t, { id, type, message }]);
    window.setTimeout(() => {
      setToasts((t) => t.filter((x) => x.id !== id));
    }, 3200);
  }, []);

  const dismissToast = useCallback((id: number) => {
    setToasts((t) => t.filter((x) => x.id !== id));
  }, []);

  const closeUi = useCallback(async () => {
    setVisible(false);
    setMode(null);
    try {
      await fetchNui('close');
    } catch {
      /* ignore */
    }
  }, []);

  const hydrate = useCallback(
    (payload: {
      visible?: boolean;
      mode?: AppMode;
      shopId?: number;
      shop?: Shop;
      management?: ManagementData;
    }) => {
      if (typeof payload.visible === 'boolean') setVisible(payload.visible);
      if (payload.mode) setMode(payload.mode);
      if (typeof payload.shopId === 'number') setShopId(payload.shopId);
      if (payload.shop) {
        setShop(payload.shop);
        setShopId(payload.shop.id);
      }
      if (payload.management) {
        setManagement(payload.management);
        setShop(payload.management.shop);
        setShopId(payload.management.shop.id);
      }
    },
    [],
  );

  const value = useMemo(
    () => ({
      visible,
      mode,
      shopId,
      shop,
      management,
      loading,
      toasts,
      setVisible,
      setMode,
      setShop,
      setShopId,
      setManagement,
      setLoading,
      pushToast,
      dismissToast,
      closeUi,
      hydrate,
    }),
    [
      visible,
      mode,
      shopId,
      shop,
      management,
      loading,
      toasts,
      pushToast,
      dismissToast,
      closeUi,
      hydrate,
    ],
  );

  return createElement(AppContext.Provider, { value }, children);
}

export function useAppStore() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useAppStore must be used within AppProvider');
  return ctx;
}
