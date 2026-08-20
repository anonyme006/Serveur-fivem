import { useEffect, useState, type ReactNode } from 'react';
import { useNotifications } from '@/hooks/useNotifications';

export function NotificationCenter(): ReactNode {
  const { notifications } = useNotifications();
  const [visible, setVisible] = useState(notifications);

  useEffect(() => {
    setVisible(notifications.slice(0, 3));
    const timers = notifications.slice(0, 3).map((n) =>
      window.setTimeout(() => {
        setVisible((prev) => prev.filter((x) => x.id !== n.id));
      }, n.duration ?? 4500),
    );
    return () => timers.forEach((t) => clearTimeout(t));
  }, [notifications]);

  if (!visible.length) return null;

  return (
    <div className="toast-stack">
      {visible.map((n) => (
        <div key={n.id} className="toast">
          <strong>{n.title}</strong>
          <span>{n.body}</span>
        </div>
      ))}
    </div>
  );
}
