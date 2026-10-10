import React from 'react';

const icons: Record<string, React.ReactNode> = {
  mask: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M4 10c2-3 5-4 8-4s6 1 8 4v4c-2 2-5 3-8 3s-6-1-8-3v-4Z" stroke="currentColor" strokeWidth="1.8" />
      <circle cx="9" cy="11" r="1" fill="currentColor" />
      <circle cx="15" cy="11" r="1" fill="currentColor" />
    </svg>
  ),
  hat: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M4 14h16l-2-6H6l-2 6Z" stroke="currentColor" strokeWidth="1.8" />
      <path d="M7 14v2h10v-2" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  glasses: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="8" cy="12" r="3" stroke="currentColor" strokeWidth="1.8" />
      <circle cx="16" cy="12" r="3" stroke="currentColor" strokeWidth="1.8" />
      <path d="M11 12h2" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  top: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M8 6l4-2 4 2v14H8V6Z" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  vest: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M9 4h6l2 4v12H7V8l2-4Z" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  pants: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M8 4h8l-1 16h-2l-1-10-1 10h-2L8 4Z" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  shoes: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M4 14h13l3 3v3H4v-6Z" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  chain: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="12" cy="8" r="3" stroke="currentColor" strokeWidth="1.8" />
      <path d="M12 11v8" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  earrings: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="8" cy="14" r="2" stroke="currentColor" strokeWidth="1.8" />
      <circle cx="16" cy="14" r="2" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  bag: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M7 8V6a5 5 0 0 1 10 0v2" stroke="currentColor" strokeWidth="1.8" />
      <rect x="5" y="8" width="14" height="12" rx="2" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  belt: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <rect x="4" y="10" width="16" height="4" rx="1" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  watch: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="12" cy="12" r="5" stroke="currentColor" strokeWidth="1.8" />
      <path d="M12 9v3l2 2" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  bracelet: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <ellipse cx="12" cy="12" rx="7" ry="4" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  decals: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M6 6h12v12H6z" stroke="currentColor" strokeWidth="1.8" />
      <path d="M9 9h6v6H9z" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  accessory: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M12 3l2 4 4 1-3 3 1 4-4-2-4 2 1-4-3-3 4-1-2-4Z" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  torso: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M9 5h6l2 4v10H7V9l2-4Z" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
  arms: (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M4 10l3-3 2 2-2 2M20 10l-3-3-2 2 2 2M12 8v8" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  ),
};

export const ClothingIcon: React.FC<{ name: string }> = ({ name }) => (
  <span className="clothing-slot-icon">{icons[name] || icons.accessory}</span>
);

export default ClothingIcon;
