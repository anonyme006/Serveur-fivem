import type { ButtonHTMLAttributes, ReactNode } from 'react';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'success';

interface Props extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: 'sm' | 'md' | 'icon';
  children?: ReactNode;
}

export function Button({ variant = 'secondary', size = 'md', className = '', children, ...rest }: Props) {
  const classes = ['btn', `btn-${variant}`, size === 'sm' ? 'btn-sm' : '', size === 'icon' ? 'btn-icon' : '', className]
    .filter(Boolean)
    .join(' ');
  return (
    <button type="button" className={classes} {...rest}>
      {children}
    </button>
  );
}
