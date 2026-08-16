export function formatMoney(amount: number): string {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  })
    .format(amount)
    .replace('US$', '$');
}

export function stockTone(stock: number, infinite?: boolean): 'green' | 'amber' | 'red' {
  if (infinite) return 'green';
  if (stock <= 0) return 'red';
  if (stock <= 5) return 'amber';
  return 'green';
}

export function stockLabel(stock: number, infinite?: boolean): string {
  if (infinite) return 'Illimité';
  if (stock <= 0) return 'Rupture';
  if (stock <= 5) return 'Stock bas';
  return 'En stock';
}

export function uid(prefix = 'tmp'): string {
  return `${prefix}_${Math.random().toString(36).slice(2, 9)}`;
}
