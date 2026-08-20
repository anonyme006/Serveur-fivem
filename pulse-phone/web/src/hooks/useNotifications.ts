import { usePhoneStore } from '@/stores/phoneStore';

export function useNotifications() {
  const notifications = usePhoneStore((s) => s.notifications);
  const pushNotification = usePhoneStore((s) => s.pushNotification);
  return { notifications, pushNotification };
}
