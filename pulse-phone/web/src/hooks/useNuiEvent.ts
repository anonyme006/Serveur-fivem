import { useEffect, useRef } from 'react';

interface NuiMessage<T> {
  action: string;
  data?: T;
}

export function useNuiEvent<T = unknown>(action: string, handler: (data: T) => void): void {
  const saved = useRef(handler);
  saved.current = handler;

  useEffect(() => {
    const listener = (event: MessageEvent<NuiMessage<T>>) => {
      if (!event.data || event.data.action !== action) return;
      saved.current(event.data.data as T);
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [action]);
}
