import { useCallback, useEffect, useRef, useState, type PointerEvent, type ReactNode } from 'react';
import { StatusBar } from '@/components/StatusBar';
import { LockScreen } from '@/components/LockScreen';
import { HomeScreen } from '@/components/HomeScreen';
import { AppHost } from '@/components/AppHost';
import { NotificationCenter } from '@/components/NotificationCenter';
import { usePhone } from '@/hooks/usePhone';
import { fetchNui } from '@/nui/fetchNui';

export function Phone(): ReactNode {
  const phone = usePhone();
  const shellRef = useRef<HTMLDivElement>(null);
  const [closing, setClosing] = useState(false);
  const dragging = useRef(false);
  const offset = useRef({ x: 0, y: 0 });

  useEffect(() => {
    if (!phone.visible) setClosing(false);
  }, [phone.visible]);

  const onPointerDown = useCallback((e: PointerEvent<HTMLDivElement>) => {
    if (!shellRef.current) return;
    dragging.current = true;
    const rect = shellRef.current.getBoundingClientRect();
    offset.current = { x: e.clientX - rect.left - rect.width / 2, y: e.clientY - rect.top - rect.height / 2 };
    (e.target as HTMLElement).setPointerCapture?.(e.pointerId);
  }, []);

  const onPointerMove = useCallback(
    (e: PointerEvent<HTMLDivElement>) => {
      if (!dragging.current) return;
      const x = (e.clientX - offset.current.x) / window.innerWidth;
      const y = (e.clientY - offset.current.y) / window.innerHeight;
      phone.setPosition({
        x: Math.min(0.95, Math.max(0.15, x)),
        y: Math.min(0.9, Math.max(0.2, y)),
      });
    },
    [phone],
  );

  const onPointerUp = useCallback(() => {
    if (!dragging.current) return;
    dragging.current = false;
    void fetchNui('phone:setPosition', phone.position);
  }, [phone.position]);

  if (!phone.visible && !closing) return null;

  const wallpaper = phone.profile?.wallpaper ?? phone.config?.wallpaper ?? 'ocean';
  const apps = phone.config?.apps ?? {};

  return (
    <div
      ref={shellRef}
      className={`phone-shell ${phone.visible ? 'open' : ''} ${closing ? 'closing' : ''}`}
      style={{ left: `${phone.position.x * 100}%`, top: `${phone.position.y * 100}%` }}
    >
      <div className="drag-handle" onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} />
      <div className="phone-bezel">
        <div className={`phone-screen wallpaper-${wallpaper}`}>
          <StatusBar time={phone.time} battery={phone.battery} signal={phone.signal} />
          <NotificationCenter />
          {phone.locked ? (
            <LockScreen time={phone.time} date={phone.date} onUnlock={() => void phone.unlock()} />
          ) : phone.activeApp ? (
            <AppHost app={phone.activeApp} onBack={() => void phone.closeApp()} />
          ) : (
            <HomeScreen appsEnabled={apps} onOpenApp={(app) => void phone.openApp(app)} />
          )}
        </div>
      </div>
    </div>
  );
}
