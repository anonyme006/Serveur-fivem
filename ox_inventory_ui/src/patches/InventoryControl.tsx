import React, { useState, useRef, useEffect } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, setItemAmount } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import UsefulControls from './UsefulControls';

const formatAmount = (n: number) => (n > 0 ? n.toLocaleString('en-US') : '0');
const digitsOnly = (s: string) => s.replace(/\D/g, '');
const countDigitsBefore = (s: string, index: number) => digitsOnly(s.substring(0, index)).length;

const IconInfo = () => (
  <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" />
    <path d="M12 11v6" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" />
    <circle cx="12" cy="7.5" r="1.2" fill="currentColor" />
  </svg>
);

const IconUse = () => (
  <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <path d="M9 11.5V6.2a1.2 1.2 0 0 1 2.4 0V11" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    <path d="M11.4 11V7.8a1.2 1.2 0 0 1 2.4 0V11" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    <path d="M13.8 11V8.5a1.2 1.2 0 0 1 2.4 0V12.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    <path d="M8.2 12.2V10.8A1.3 1.3 0 0 1 9.5 9.5h.2" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    <path
      d="M8.2 12.2c0 0-.8 1.2-.8 3.2 0 2.6 1.9 4.6 4.4 4.6h2.2c2.2 0 3.8-1.5 4.2-3.4l.8-3.6a1.4 1.4 0 0 0-1.4-1.7H16"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

const IconGive = () => (
  <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <path
      d="M7 8h10M13 4l4 4-4 4M17 16H7M11 20l-4-4 4-4"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

const IconClose = () => (
  <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <path d="M7 7l10 10M17 7L7 17" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" />
  </svg>
);

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();

  const [infoVisible, setInfoVisible] = useState(false);
  const [value, setValue] = useState(formatAmount(itemAmount));
  const inputRef = useRef<HTMLInputElement>(null);
  const cursorRef = useRef<number | null>(null);

  const [, use] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onUse(source.item);
    },
  }));

  const [, give] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onGive(source.item);
    },
  }));

  const commitValue = (raw: string, cursorIndex: number) => {
    const digitsBefore = countDigitsBefore(raw, cursorIndex);
    const num = parseInt(digitsOnly(raw), 10) || 0;

    setValue(formatAmount(num));
    dispatch(setItemAmount(num));
    cursorRef.current = digitsBefore;
  };

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) =>
    commitValue(event.target.value, event.target.selectionStart ?? 0);

  const handleKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    const el = event.currentTarget;
    const pos = el.selectionStart ?? 0;

    if (pos !== el.selectionEnd) return;

    if (event.key === 'Backspace' && el.value[pos - 1] === ',') {
      event.preventDefault();
      commitValue(el.value.slice(0, pos - 2) + el.value.slice(pos), pos - 2);
    } else if (event.key === 'Delete' && el.value[pos] === ',') {
      event.preventDefault();
      commitValue(el.value.slice(0, pos) + el.value.slice(pos + 2), pos);
    }
  };

  useEffect(() => {
    if (!inputRef.current || cursorRef.current === null) return;
    let newPos = 0;
    let count = 0;

    for (let i = 0; i < value.length && count < cursorRef.current; i++) {
      if (/\d/.test(value[i])) count++;
      newPos++;
    }

    inputRef.current.setSelectionRange(newPos, newPos);
    cursorRef.current = null;
  }, [value]);

  return (
    <>
      <UsefulControls infoVisible={infoVisible} setInfoVisible={setInfoVisible} />
      <div className="inventory-control">
        <div className="inventory-control-wrapper">
          <input
            className="inventory-control-input"
            type="text"
            ref={inputRef}
            value={value}
            onChange={handleChange}
            onKeyDown={handleKeyDown}
            min={0}
          />
          <button className="inventory-control-button btn-info" type="button" onClick={() => setInfoVisible(true)}>
            <span className="btn-icon">
              <IconInfo />
            </span>
            <span>{Locale.ui_usefulcontrols || 'Information'}</span>
          </button>
          <button
            className="inventory-control-button btn-use"
            type="button"
            ref={(el) => {
              use(el);
            }}
          >
            <span className="btn-icon">
              <IconUse />
            </span>
            <span>{Locale.ui_use || 'Utiliser'}</span>
          </button>
          <button
            className="inventory-control-button btn-give"
            type="button"
            ref={(el) => {
              give(el);
            }}
          >
            <span className="btn-icon">
              <IconGive />
            </span>
            <span>{Locale.ui_give || 'Échanger'}</span>
          </button>
          <button className="inventory-control-button btn-close" type="button" onClick={() => fetchNui('exit')}>
            <span className="btn-icon">
              <IconClose />
            </span>
            <span>{Locale.ui_close || 'Fermer'}</span>
          </button>
        </div>
      </div>
    </>
  );
};

export default InventoryControl;
