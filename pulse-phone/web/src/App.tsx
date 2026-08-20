import { useEffect } from 'react';
import { Phone } from '@/components/Phone';
import { useNuiEvent } from '@/hooks/useNuiEvent';
import { usePhoneStore } from '@/stores/phoneStore';
import { fetchNui, isEnvBrowser } from '@/nui/fetchNui';
import type { CallState, PhoneConfigPayload, PhoneProfile } from '@/types/phone';
import '@/styles/phone.css';

function DevToolbar() {
  const setOpen = usePhoneStore((s) => s.setOpen);
  const setClosed = usePhoneStore((s) => s.setClosed);
  const visible = usePhoneStore((s) => s.visible);

  if (!isEnvBrowser()) return null;

  return (
    <div style={{ position: 'fixed', left: 16, bottom: 16, zIndex: 50, display: 'flex', gap: 8 }}>
      <button
        type="button"
        style={{ padding: '10px 14px', borderRadius: 10, background: '#0d9488', color: '#fff', pointerEvents: 'auto' }}
        onClick={() => {
          if (visible) {
            setClosed();
            return;
          }
          setOpen({
            profile: {
              citizenid: 'DEV001',
              firstname: 'Kevin',
              lastname: 'Demo',
              phoneNumber: '5550199',
              wallpaper: 'ocean',
              theme: 'dark',
              battery: 87,
              signal: 4,
            },
            config: {
              theme: 'dark',
              wallpaper: 'ocean',
              colors: {
                accent: '#0D9488',
                accentSoft: '#14B8A6',
                danger: '#E11D48',
                warning: '#F59E0B',
                success: '#22C55E',
                surface: '#0F172A',
                surfaceElevated: '#1E293B',
                text: '#F8FAFC',
                textMuted: '#94A3B8',
              },
              apps: {
                phone: true,
                contacts: true,
                messages: true,
                services: true,
                bank: true,
                wallet: true,
                garage: true,
                marketplace: true,
                gps: true,
                settings: true,
              },
              locale: 'fr',
              position: { x: 0.72, y: 0.52 },
              animations: { openMs: 280, closeMs: 220 },
              sounds: { enabled: true, volume: 0.45 },
            },
          });
        }}
      >
        {visible ? 'Fermer Pulse' : 'Ouvrir Pulse'}
      </button>
    </div>
  );
}

export default function App() {
  const setOpen = usePhoneStore((s) => s.setOpen);
  const setClosed = usePhoneStore((s) => s.setClosed);
  const setStatus = usePhoneStore((s) => s.setStatus);
  const pushNotification = usePhoneStore((s) => s.pushNotification);
  const setCall = usePhoneStore((s) => s.setCall);

  useNuiEvent<{ profile: PhoneProfile; config: PhoneConfigPayload }>('phone:open', (data) => {
    if (!data) return;
    setOpen(data);
  });

  useNuiEvent('phone:close', () => setClosed());

  useNuiEvent<{ battery?: number; signal?: number; time?: string; date?: string }>('phone:status', (data) => {
    if (data) setStatus(data);
  });

  useNuiEvent<{ type: string; title: string; body: string; duration?: number; payload?: unknown }>(
    'notifications:push',
    (data) => {
      if (!data) return;
      pushNotification(data);
    },
  );

  useNuiEvent<CallState>('calls:update', (data) => {
    setCall(data ?? null);
  });

  useEffect(() => {
    void fetchNui('phone:ready');
    const id = window.setInterval(() => {
      const d = new Date();
      setStatus({
        time: `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`,
      });
    }, 15000);
    return () => clearInterval(id);
  }, [setStatus]);

  return (
    <div className={`app-root ${isEnvBrowser() ? 'dev-bg' : ''}`}>
      <Phone />
      <DevToolbar />
    </div>
  );
}
