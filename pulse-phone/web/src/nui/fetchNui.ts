const isBrowser = typeof window !== 'undefined';

export function isEnvBrowser(): boolean {
  return isBrowser && !(window as unknown as { invokeNative?: unknown }).invokeNative;
}

export async function fetchNui<T = unknown>(
  eventName: string,
  data?: unknown,
  mockData?: T,
): Promise<T> {
  if (isEnvBrowser()) {
    return (mockData ?? ({ ok: true } as T));
  }

  const resource = (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName?.()
    ?? 'pulse-phone';

  const resp = await fetch(`https://${resource}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  });

  try {
    return (await resp.json()) as T;
  } catch {
    return undefined as T;
  }
}

export function useNuiEvent<T = unknown>(action: string, handler: (data: T) => void): void {
  // implemented in hooks/useNuiEvent.ts — keep helper types here
  void action;
  void handler;
}
