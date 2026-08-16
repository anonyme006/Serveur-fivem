import { X } from 'lucide-react';
import { useAppStore } from '../stores/appStore';

export function Toasts() {
  const { toasts, dismissToast } = useAppStore();
  if (!toasts.length) return null;
  return (
    <div className="toasts">
      {toasts.map((t) => (
        <div key={t.id} className={`toast ${t.type}`}>
          <div style={{ flex: 1 }}>{t.message}</div>
          <button type="button" className="btn btn-ghost btn-icon btn-sm" onClick={() => dismissToast(t.id)}>
            <X size={14} />
          </button>
        </div>
      ))}
    </div>
  );
}
