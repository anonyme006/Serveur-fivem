import L from 'leaflet'
import { useEffect, useMemo, useRef } from 'react'
import type { CreatorEntity } from '../types'
import 'leaflet/dist/leaflet.css'

/** Convert GTA world coords → Leaflet CRS.Simple (rsg satellite tiles, 0–256). */
function gameToMap(x: number, y: number): [number, number] {
  // San Andreas approx bounds used by common FiveM map UIs
  const minX = -4000
  const maxX = 4500
  const minY = -4000
  const maxY = 8000
  const mapX = ((x - minX) / (maxX - minX)) * 256
  const mapY = (1 - (y - minY) / (maxY - minY)) * 256
  return [mapY, mapX]
}

function mapToGame(lat: number, lng: number): { x: number; y: number } {
  const minX = -4000
  const maxX = 4500
  const minY = -4000
  const maxY = 8000
  const x = minX + (lng / 256) * (maxX - minX)
  const y = minY + (1 - lat / 256) * (maxY - minY)
  return { x, y }
}

type Props = {
  items: CreatorEntity[]
  selectedId?: number | null
  onSelect: (entity: CreatorEntity) => void
  onEdit: (entity: CreatorEntity) => void
}

export default function GtaMap({ items, selectedId, onSelect, onEdit }: Props) {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const mapRef = useRef<L.Map | null>(null)
  const layerRef = useRef<L.LayerGroup | null>(null)

  const pins = useMemo(
    () =>
      items.filter((it) => it.coords && typeof it.coords.x === 'number' && typeof it.coords.y === 'number'),
    [items],
  )

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return

    const crs = L.extend({}, L.CRS.Simple, {
      transformation: new L.Transformation(1, 0, 1, 0),
    }) as L.CRS

    const map = L.map(containerRef.current, {
      crs,
      minZoom: 1,
      maxZoom: 5,
      zoomControl: false,
      attributionControl: false,
      preferCanvas: true,
    })

    // Satellite-style GTA tiles (public tile servers used by many FiveM UIs)
    L.tileLayer('https://s.rsg.scot/sc/tiles/satellite/{z}/{x}/{y}.jpg', {
      minZoom: 0,
      maxZoom: 5,
      noWrap: true,
      errorTileUrl:
        'data:image/svg+xml,' +
        encodeURIComponent(
          `<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><rect fill="#1a2330" width="256" height="256"/></svg>`,
        ),
    }).addTo(map)

    // Fallback dark ocean if tiles fail — already handled by errorTileUrl
    map.setView([128, 128], 2)

    const layer = L.layerGroup().addTo(map)
    layerRef.current = layer
    mapRef.current = map

    return () => {
      map.remove()
      mapRef.current = null
      layerRef.current = null
    }
  }, [])

  useEffect(() => {
    const map = mapRef.current
    const layer = layerRef.current
    if (!map || !layer) return

    layer.clearLayers()

    pins.forEach((entity) => {
      const c = entity.coords!
      const [lat, lng] = gameToMap(c.x, c.y)
      const active = entity.id === selectedId

      const icon = L.divIcon({
        className: 'cc-pin-wrap',
        html: `
          <div class="cc-pin ${active ? 'is-active' : ''} ${entity.active ? '' : 'is-off'}">
            <span class="cc-pin-dot"></span>
            <span class="cc-pin-label">${escapeHtml(entity.label || entity.name)}</span>
          </div>
        `,
        iconSize: [0, 0],
        iconAnchor: [0, 0],
      })

      const marker = L.marker([lat, lng], { icon })
      marker.on('click', () => {
        onSelect(entity)
        onEdit(entity)
      })
      marker.addTo(layer)
    })

    if (selectedId) {
      const selected = pins.find((p) => p.id === selectedId)
      if (selected?.coords) {
        const [lat, lng] = gameToMap(selected.coords.x, selected.coords.y)
        map.panTo([lat, lng], { animate: true })
      }
    }
  }, [pins, selectedId, onSelect, onEdit])

  const zoom = (delta: number) => {
    const map = mapRef.current
    if (!map) return
    map.setZoom(map.getZoom() + delta)
  }

  return (
    <div className="map-panel">
      <div className="map-head">CARTE</div>
      <div className="map-frame">
        <div className="map-controls">
          <button type="button" className="map-ctrl" onClick={() => zoom(1)} title="Zoom +">+</button>
          <button type="button" className="map-ctrl" onClick={() => zoom(-1)} title="Zoom -">−</button>
          <button
            type="button"
            className="map-ctrl"
            title="Recentrer"
            onClick={() => mapRef.current?.setView([128, 128], 2)}
          >
            ⌖
          </button>
        </div>
        <div ref={containerRef} className="map-canvas" />
      </div>
      <p className="map-hint">Molette = zoom · glisser = déplacer · clic pin = éditer</p>
    </div>
  )
}

function escapeHtml(str: string) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

export { gameToMap, mapToGame }
