import type { NuiOk } from '../types';

const resourceName = (): string => {
  if (typeof window.GetParentResourceName === 'function') {
    return window.GetParentResourceName();
  }
  return 'qbx_shopcreator';
};

export function isEnvBrowser(): boolean {
  return !(window as Window).invokeNative;
}

export async function fetchNui<T>(eventName: string, data?: unknown, delay = 0): Promise<T> {
  if (delay > 0) {
    await new Promise((r) => setTimeout(r, delay));
  }

  if (isEnvBrowser()) {
    const { mockNui } = await import('./mock');
    return mockNui<T>(eventName, data);
  }

  const resp = await fetch(`https://${resourceName()}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  });

  const text = await resp.text();
  if (!text) return {} as T;
  try {
    return JSON.parse(text) as T;
  } catch {
    return text as unknown as T;
  }
}

export async function fetchNuiResult<T>(eventName: string, data?: unknown): Promise<NuiOk<T>> {
  try {
    const result = await fetchNui<NuiOk<T> | T>(eventName, data);
    if (result && typeof result === 'object' && 'ok' in (result as object)) {
      return result as NuiOk<T>;
    }
    return { ok: true, data: result as T };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'Erreur réseau' };
  }
}

type NuiHandler<T> = (data: T) => void;

export function useNuiEvent<T>(action: string, handler: NuiHandler<T>): void {
  // Imported lazily in hooks — see useNuiEvent hook file for React binding.
  void action;
  void handler;
}

export function onNuiMessage<T>(action: string, handler: NuiHandler<T>): () => void {
  const listener = (event: MessageEvent) => {
    const payload = event.data;
    if (!payload || typeof payload !== 'object') return;
    if (payload.action !== action) return;
    handler(payload.data as T);
  };
  window.addEventListener('message', listener);
  return () => window.removeEventListener('message', listener);
}

export function debugSetVisible(data: unknown) {
  window.dispatchEvent(new MessageEvent('message', { data: { action: 'setVisible', data } }));
}
