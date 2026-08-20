import { usePhoneStore } from '@/stores/phoneStore';
import { fetchNui } from '@/nui/fetchNui';
import type { AppId } from '@/types/phone';

export function usePhone() {
  const store = usePhoneStore();

  return {
    ...store,
    close: async () => {
      await fetchNui('phone:close');
      store.setClosed();
    },
    unlock: async () => {
      await fetchNui('phone:unlock');
      store.unlock();
    },
    lock: async () => {
      await fetchNui('phone:lock');
      store.lock();
    },
    openApp: async (app: AppId) => {
      const res = await fetchNui<{ ok: boolean }>('phone:openApp', { app }, { ok: true });
      if (res?.ok) store.openApp(app);
    },
    closeApp: async () => {
      await fetchNui('phone:closeApp');
      store.closeApp();
    },
  };
}
