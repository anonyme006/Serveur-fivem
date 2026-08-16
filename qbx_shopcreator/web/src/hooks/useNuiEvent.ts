import { useEffect, useRef } from 'react';
import { onNuiMessage } from '../lib/nui';

export function useNuiEvent<T>(action: string, handler: (data: T) => void) {
  const saved = useRef(handler);
  saved.current = handler;

  useEffect(() => {
    return onNuiMessage<T>(action, (data) => saved.current(data));
  }, [action]);
}
