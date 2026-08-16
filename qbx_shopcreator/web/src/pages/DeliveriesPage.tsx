import { useCallback, useEffect, useState } from 'react';
import { MapPin, Package, RefreshCw, Truck } from 'lucide-react';
import { Badge } from '../components/Badge';
import { Button } from '../components/Button';
import { PanelShell } from '../components/Panel';
import { EmptyState, LoadingState } from '../components/States';
import { fetchNuiResult } from '../lib/nui';
import { formatMoney } from '../lib/utils';
import { useAppStore } from '../stores/appStore';
import type { DeliveryJob } from '../types';

export function DeliveriesPage() {
  const { closeUi, pushToast } = useAppStore();
  const [jobs, setJobs] = useState<DeliveryJob[]>([]);
  const [loading, setLoading] = useState(true);
  const [acceptingId, setAcceptingId] = useState<number | null>(null);

  const loadJobs = useCallback(async () => {
    setLoading(true);
    const res = await fetchNuiResult<DeliveryJob[]>('getDeliveryJobs');
    setLoading(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Impossible de charger les missions');
      return;
    }
    setJobs(res.data ?? []);
  }, [pushToast]);

  useEffect(() => {
    void loadJobs();
  }, [loadJobs]);

  const acceptJob = async (jobId: number) => {
    setAcceptingId(jobId);
    const res = await fetchNuiResult<DeliveryJob>('acceptDelivery', { jobId, id: jobId });
    setAcceptingId(null);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Acceptation impossible');
      return;
    }
    pushToast('success', res.message ?? 'Mission acceptée');
    setJobs((prev) => prev.filter((j) => j.id !== jobId));
  };

  return (
    <PanelShell
      title="Livraisons"
      subtitle="Missions disponibles"
      onClose={() => void closeUi()}
      size="compact"
      actions={
        <Button variant="ghost" size="sm" onClick={() => void loadJobs()} disabled={loading}>
          <RefreshCw size={14} /> Actualiser
        </Button>
      }
    >
      <div className="content">
        {loading ? (
          <LoadingState label="Chargement des missions…" />
        ) : jobs.length === 0 ? (
          <EmptyState
            icon={<Truck size={32} color="#6b7280" />}
            title="Aucune mission"
            description="Il n'y a pas de livraison disponible pour le moment."
            action={
              <Button variant="secondary" onClick={() => void loadJobs()}>
                <RefreshCw size={14} /> Actualiser
              </Button>
            }
          />
        ) : (
          <div className="card-grid">
            {jobs.map((job) => (
              <div key={job.id} className="card">
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, marginBottom: 10 }}>
                  <div>
                    <div style={{ fontWeight: 650 }}>{job.shop_name}</div>
                    <div className="muted">Mission #{job.id}</div>
                  </div>
                  <Badge tone="purple">{formatMoney(job.reward)}</Badge>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12, fontSize: '0.85rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <MapPin size={14} color="#9ca3af" />
                    <span>
                      {job.origin_label} → {job.dest_label}
                    </span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <Package size={14} color="#9ca3af" />
                    <span>{job.item_count} articles</span>
                  </div>
                </div>
                <Button
                  variant="primary"
                  size="sm"
                  disabled={acceptingId === job.id}
                  onClick={() => void acceptJob(job.id)}
                >
                  {acceptingId === job.id ? 'Acceptation…' : 'Accepter'}
                </Button>
              </div>
            ))}
          </div>
        )}
      </div>
    </PanelShell>
  );
}
