import React, { useCallback, useRef } from 'react';
import { fetchNui } from '../../utils/fetchNui';
import { useAppSelector } from '../../store';
import { selectQboxUiConfig } from '../../store/qboxUi';

const CharacterPreview: React.FC = () => {
  const config = useAppSelector(selectQboxUiConfig);
  const dragging = useRef(false);
  const lastX = useRef(0);
  const zoom = useRef(1);

  const onMouseDown = useCallback((event: React.MouseEvent) => {
    if (!config.enableCharacterRotation) return;
    dragging.current = true;
    lastX.current = event.clientX;
  }, [config.enableCharacterRotation]);

  const onMouseUp = useCallback(() => {
    dragging.current = false;
  }, []);

  const onMouseMove = useCallback(
    (event: React.MouseEvent) => {
      if (!dragging.current || !config.enableCharacterRotation) return;
      const delta = (event.clientX - lastX.current) * 0.6;
      lastX.current = event.clientX;
      fetchNui('qboxUi:rotateCharacter', { delta });
    },
    [config.enableCharacterRotation]
  );

  const onWheel = useCallback(
    (event: React.WheelEvent) => {
      if (!config.enableCharacterZoom) return;
      event.preventDefault();
      zoom.current = Math.min(1.6, Math.max(0.6, zoom.current - event.deltaY * 0.001));
      fetchNui('qboxUi:zoomCharacter', { zoom: zoom.current });
    },
    [config.enableCharacterZoom]
  );

  if (!config.showCharacter) return null;

  return (
    <div
      className={`character-preview character-preview--${config.characterBackground}`}
      onMouseDown={onMouseDown}
      onMouseUp={onMouseUp}
      onMouseLeave={onMouseUp}
      onMouseMove={onMouseMove}
      onWheel={onWheel}
    >
      <div className="character-preview-frame" />
      <p className="character-preview-hint">Glisser pour tourner · Molette pour zoomer</p>
    </div>
  );
};

export default CharacterPreview;
