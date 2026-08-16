import { useEffect } from 'react';
import { Toasts } from './components/Toasts';
import { useNuiEvent } from './hooks/useNuiEvent';
import { debugSetVisible, fetchNuiResult, isEnvBrowser } from './lib/nui';
import { AdminPage } from './pages/AdminPage';
import { DeliveriesPage } from './pages/DeliveriesPage';
import { ManagementPage } from './pages/ManagementPage';
import { StorefrontPage } from './pages/StorefrontPage';
import { useAppStore } from './stores/appStore';
import './styles/global.css';
import type { AppMode, ManagementData, SetVisiblePayload, Shop } from './types';

export function App() {
  const { visible, mode, hydrate, closeUi, setShop } = useAppStore();

  useNuiEvent<SetVisiblePayload>('setVisible', (data) => {
    hydrate(data);
  });

  useNuiEvent<Shop>('setShop', (data) => {
    setShop(data);
  });

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') void closeUi();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [closeUi]);

  useEffect(() => {
    if (!isEnvBrowser()) return;

    const params = new URLSearchParams(window.location.search);
    const devMode = (params.get('mode') as AppMode | null) ?? 'management';

    const bootstrap = async () => {
      if (devMode === 'admin') {
        debugSetVisible({ visible: true, mode: 'admin' });
        return;
      }

      if (devMode === 'storefront') {
        const res = await fetchNuiResult<Shop>('getShop', { shopId: 1 });
        if (res.ok && res.data) {
          debugSetVisible({ visible: true, mode: 'storefront', shop: res.data, shopId: res.data.id });
        }
        return;
      }

      if (devMode === 'deliveries') {
        debugSetVisible({ visible: true, mode: 'deliveries' });
        return;
      }

      const res = await fetchNuiResult<ManagementData>('getManagementData', { shopId: 1 });
      if (res.ok && res.data) {
        debugSetVisible({
          visible: true,
          mode: 'management',
          shopId: res.data.shop.id,
          management: res.data,
        });
      }
    };

    void bootstrap();
  }, []);

  if (!visible) return null;

  let page = null;
  switch (mode) {
    case 'admin':
      page = <AdminPage />;
      break;
    case 'storefront':
      page = <StorefrontPage />;
      break;
    case 'management':
      page = <ManagementPage />;
      break;
    case 'deliveries':
      page = <DeliveriesPage />;
      break;
    default:
      return null;
  }

  return (
    <div className="app-root">
      {page}
      <Toasts />
    </div>
  );
}
