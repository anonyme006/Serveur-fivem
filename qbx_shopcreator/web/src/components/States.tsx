import { Loader2 } from 'lucide-react';
import type { ReactNode } from 'react';
import { Button } from './Button';

export function LoadingState({ label = 'Chargement…' }: { label?: string }) {
  return (
    <div className="loading-state">
      <div className="spinner" />
      <h3>{label}</h3>
    </div>
  );
}

export function EmptyState({
  icon,
  title,
  description,
  action,
}: {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="empty-state">
      {icon}
      <h3>{title}</h3>
      {description ? <p>{description}</p> : null}
      {action}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="error-state">
      <Loader2 size={28} color="#fca5a5" />
      <h3>Une erreur est survenue</h3>
      <p>{message}</p>
      {onRetry ? (
        <Button variant="primary" onClick={onRetry}>
          Réessayer
        </Button>
      ) : null}
    </div>
  );
}
