import type { ApiResult } from '../types'

declare global {
  interface Window {
    GetParentResourceName?: () => string
  }
}

function resourceName() {
  return window.GetParentResourceName?.() ?? 'core_creator'
}

export async function nui<T = unknown>(event: string, data: unknown = {}): Promise<ApiResult<T>> {
  try {
    const res = await fetch(`https://${resourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    })
    return (await res.json()) as ApiResult<T>
  } catch {
    return { ok: false, message: 'nui_error' }
  }
}

export function onNuiMessage(handler: (action: string, data: unknown) => void) {
  const listener = (event: MessageEvent) => {
    const payload = event.data
    if (!payload || typeof payload !== 'object') return
    handler(payload.action, payload.data)
  }
  window.addEventListener('message', listener)
  return () => window.removeEventListener('message', listener)
}
