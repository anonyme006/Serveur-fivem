import type { ReactNode } from 'react';

type Tone = 'green' | 'red' | 'amber' | 'purple' | 'gray';

export function Badge({ tone = 'gray', children }: { tone?: Tone; children: ReactNode }) {
  return <span className={`badge badge-${tone}`}>{children}</span>;
}
