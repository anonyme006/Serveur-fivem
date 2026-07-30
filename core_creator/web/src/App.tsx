import { useCallback, useEffect, useMemo, useState } from 'react'
import type { BootstrapData, CreatorEntity, ModuleName } from './types'
import { nui, onNuiMessage } from './lib/nui'
import GtaMap from './components/GtaMap'
import './styles/app.css'

const MODULE_LABELS: Record<string, string> = {
  shops: 'Boutiques',
  blips: 'Blips',
  vehicles: 'Véhicules & clés',
  farms: 'Farming',
  jobs: 'Métiers',
  garages: 'Garages',
  gangs: 'Gangs',
  apartments: 'Appartements',
  robberies: 'Braquages',
}

const MODULE_COUNT_LABEL: Record<string, string> = {
  shops: 'boutiques',
  blips: 'blips',
  farms: 'farmings',
  jobs: 'métiers',
  garages: 'garages',
  gangs: 'gangs',
  apartments: 'appartements',
  robberies: 'braquages',
  vehicles: 'outils véhicule',
}

function defaultEntity(): CreatorEntity {
  return {
    name: '',
    label: '',
    coords: { x: 0, y: 0, z: 0, w: 0 },
    data: {},
    active: true,
  }
}

function moduleDefaults(module: ModuleName): Record<string, unknown> {
  switch (module) {
    case 'shops':
      return {
        type: 'general',
        mode: 'buy',
        currency: 'money',
        interactDistance: 2.0,
        interaction: 'marker',
        ped: { enabled: false, model: 'a_m_y_business_01', scenario: 'WORLD_HUMAN_CLIPBOARD' },
        blip: { enabled: true, sprite: 52, colour: 2, scale: 0.85, shortRange: true },
        items: [{ name: 'bread', price: 10, stock: 100, currency: 'money' }],
        schedule: { enabled: false, open: 8, close: 22 },
      }
    case 'blips':
      return { sprite: 1, colour: 0, scale: 0.85, display: 4, shortRange: true, category: 'general' }
    case 'farms':
      return {
        cooldown: 1500,
        stages: [
          {
            type: 'harvest',
            label: 'Récolte',
            coords: { x: 0, y: 0, z: 0 },
            rewardItem: 'wood',
            minAmount: 1,
            maxAmount: 3,
            duration: 3000,
            chance: 100,
          },
        ],
      }
    case 'jobs':
      return {
        grades: [
          { grade: 0, name: 'recruit', label: 'Recrue', salary: 50 },
          { grade: 1, name: 'boss', label: 'Patron', salary: 200 },
        ],
        points: [],
        blip: { enabled: true, sprite: 498, colour: 3, scale: 0.8 },
      }
    case 'garages':
      return { type: 'public', spawnPrice: 0, impoundPrice: 500, spawns: [], store: null, interaction: 'marker' }
    case 'gangs':
      return {
        color: '#ef5b5b',
        grades: [
          { grade: 0, name: 'member', label: 'Membre' },
          { grade: 1, name: 'boss', label: 'Chef' },
        ],
        points: [],
        blip: { enabled: true, sprite: 84, colour: 1, scale: 0.85 },
      }
    case 'apartments':
      return { price: 150000, rent: 0, currency: 'bank', interior: null, shell: 'default' }
    case 'robberies':
      return {
        type: 'store',
        minPolice: 2,
        globalCooldown: 1800,
        playerCooldown: 3600,
        alarm: true,
        requiredItems: [{ name: 'lockpick', count: 1, consume: true }],
        stages: [{ label: 'Caisse', coords: { x: 0, y: 0, z: 0 }, duration: 8000 }],
        rewards: [{ type: 'money', account: 'black_money', min: 500, max: 1500, chance: 100 }],
      }
    default:
      return {}
  }
}

function modeLabel(module: ModuleName, entity: CreatorEntity): { text: string; tone: 'blue' | 'green' | 'gray' } {
  const data = entity.data || {}
  if (module === 'shops') {
    const mode = String(data.mode || 'buy')
    return mode === 'sell'
      ? { text: 'Vente', tone: 'green' }
      : { text: 'Achat', tone: 'blue' }
  }
  if (module === 'garages') {
    const type = String(data.type || 'public')
    if (type === 'impound') return { text: 'Fourrière', tone: 'blue' }
    if (type === 'job' || type === 'gang') return { text: 'Owned', tone: 'blue' }
    return { text: 'Self-service', tone: 'green' }
  }
  if (module === 'robberies') return { text: String(data.type || 'custom'), tone: 'blue' }
  if (module === 'farms') return { text: `${Array.isArray(data.stages) ? data.stages.length : 0} étapes`, tone: 'gray' }
  if (module === 'jobs' || module === 'gangs') {
    const grades = Array.isArray(data.grades) ? data.grades.length : 0
    return { text: `${grades} grades`, tone: 'gray' }
  }
  return { text: entity.active ? 'Actif' : 'Off', tone: entity.active ? 'green' : 'gray' }
}

function pointsCount(entity: CreatorEntity): number {
  const data = entity.data || {}
  if (Array.isArray(data.stages)) return data.stages.length
  if (Array.isArray(data.points)) return data.points.length
  if (Array.isArray(data.spawns)) return data.spawns.length + (entity.coords ? 1 : 0)
  if (Array.isArray(data.items)) return data.items.length
  return entity.coords ? 1 : 0
}

function metaLine(module: ModuleName, entity: CreatorEntity): string {
  const data = entity.data || {}
  if (module === 'shops') return String(data.job || data.type || 'shop')
  if (module === 'garages') return String(data.type || 'public')
  if (module === 'jobs') return 'job'
  if (module === 'gangs') return 'gang'
  if (module === 'robberies') return String(data.type || 'robbery')
  if (module === 'apartments') return data.owner ? 'owned' : 'available'
  return module
}

export default function App() {
  const [visible, setVisible] = useState(false)
  const [boot, setBoot] = useState<BootstrapData | null>(null)
  const [page, setPage] = useState<'dashboard' | ModuleName>('dashboard')
  const [items, setItems] = useState<CreatorEntity[]>([])
  const [search, setSearch] = useState('')
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [editor, setEditor] = useState<CreatorEntity | null>(null)
  const [dataJson, setDataJson] = useState('{}')
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' | 'inform' } | null>(null)
  const [confirmDelete, setConfirmDelete] = useState<CreatorEntity | null>(null)
  const [vehicleForm, setVehicleForm] = useState({
    model: 'adder',
    plate: '',
    target: '',
    color1: 0,
    color2: 0,
    spawn: true,
  })

  const showToast = (text: string, type: 'success' | 'error' | 'inform' = 'inform') => {
    setToast({ text, type })
    window.setTimeout(() => setToast(null), 2600)
  }

  const loadList = useCallback(async (module: ModuleName) => {
    const res = await nui<CreatorEntity[]>('list', { module })
    if (res.ok && Array.isArray(res.data)) {
      setItems(res.data)
      const counts = { ...(boot?.counts || {}) }
      counts[module] = res.data.length
      if (boot) setBoot({ ...boot, counts })
    } else {
      setItems([])
    }
  }, [boot])

  useEffect(() => {
    return onNuiMessage((action, data) => {
      if (action === 'open') {
        setBoot(data as BootstrapData)
        setVisible(true)
        setPage('dashboard')
        setSelectedId(null)
      }
      if (action === 'close') setVisible(false)
      if (action === 'placementResult' && data && editor) {
        const c = data as { x: number; y: number; z: number; w: number }
        setEditor({ ...editor, coords: c })
        showToast('Coordonnées placées', 'success')
      }
    })
  }, [editor])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) nui('close')
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [visible])

  useEffect(() => {
    if (page !== 'dashboard' && page !== 'vehicles') {
      loadList(page)
      setSearch('')
      setSelectedId(null)
    }
  }, [page]) // eslint-disable-line react-hooks/exhaustive-deps

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return items.filter((it) => {
      if (!q) return true
      return (
        it.name.toLowerCase().includes(q) ||
        it.label.toLowerCase().includes(q) ||
        String(it.id || '').includes(q)
      )
    })
  }, [items, search])

  const title =
    page === 'dashboard' ? 'Core Creator' : MODULE_LABELS[page] || page

  const subtitle =
    page === 'dashboard'
      ? `${boot?.modules?.length || 0} modules actifs`
      : page === 'vehicles'
        ? 'Création & clés'
        : `${filtered.length} ${MODULE_COUNT_LABEL[page] || 'éléments'}`

  if (!visible) return null

  const openCreate = () => {
    if (page === 'dashboard' || page === 'vehicles') return
    const entity = defaultEntity()
    entity.data = moduleDefaults(page)
    setEditor(entity)
    setDataJson(JSON.stringify(entity.data, null, 2))
  }

  const openEdit = (entity: CreatorEntity) => {
    setSelectedId(entity.id ?? null)
    setEditor({ ...entity, data: entity.data || {} })
    setDataJson(JSON.stringify(entity.data || {}, null, 2))
  }

  const saveEditor = async () => {
    if (!editor || page === 'dashboard' || page === 'vehicles') return
    let parsed: Record<string, unknown> = {}
    try {
      parsed = JSON.parse(dataJson)
    } catch {
      showToast('JSON data invalide', 'error')
      return
    }
    const entity = { ...editor, data: parsed }
    const res = entity.id
      ? await nui('update', { module: page, entity })
      : await nui('create', { module: page, entity })
    if (!res.ok) {
      showToast(res.message || 'Erreur', 'error')
      return
    }
    showToast(entity.id ? 'Modifié' : 'Créé', 'success')
    setEditor(null)
    await loadList(page)
  }

  const doToggle = async (entity: CreatorEntity) => {
    if (page === 'dashboard' || page === 'vehicles') return
    const res = await nui('toggle', { module: page, id: entity.id, active: !entity.active })
    if (res.ok) {
      showToast(entity.active ? 'Désactivé' : 'Activé', 'success')
      loadList(page)
    }
  }

  const doDelete = async () => {
    if (!confirmDelete || page === 'dashboard' || page === 'vehicles') return
    const res = await nui('delete', { module: page, id: confirmDelete.id })
    setConfirmDelete(null)
    if (res.ok) {
      showToast('Supprimé', 'success')
      loadList(page)
    } else showToast(res.message || 'Erreur', 'error')
  }

  const doTeleport = async (entity: CreatorEntity) => {
    if (!entity.coords) {
      showToast('Pas de coordonnées', 'error')
      return
    }
    const res = await nui('teleport', { coords: entity.coords })
    if (res.ok) showToast('Téléportation', 'success')
  }

  const reload = async () => {
    if (page === 'dashboard' || page === 'vehicles') {
      const res = await nui<BootstrapData>('bootstrap')
      if (res.ok && res.data) setBoot(res.data)
      showToast('Rechargé', 'success')
      return
    }
    await loadList(page)
    showToast('Liste rechargée', 'success')
  }

  const usePlayerCoords = async () => {
    const res = await nui<{ x: number; y: number; z: number; w: number }>('getPlayerCoords')
    if (res.ok && res.data && editor) {
      setEditor({ ...editor, coords: res.data })
      showToast('Coords joueur appliquées', 'success')
    }
  }

  const startPlacement = async () => {
    await nui('startPlacement', {})
  }

  const createVehicle = async () => {
    const coords = await nui<{ x: number; y: number; z: number; w: number }>('getPlayerCoords')
    await nui('vehicleAction', {
      action: 'create',
      payload: {
        model: vehicleForm.model,
        plate: vehicleForm.plate,
        target: vehicleForm.target ? Number(vehicleForm.target) : undefined,
        color1: Number(vehicleForm.color1),
        color2: Number(vehicleForm.color2),
        spawn: vehicleForm.spawn,
        coords: coords.data,
      },
    })
    showToast('Véhicule demandé', 'success')
  }

  const onSelectPin = useCallback((entity: CreatorEntity) => {
    setSelectedId(entity.id ?? null)
  }, [])

  return (
    <div className="app-root">
      <div className="shell">
        <aside className="sidebar">
          <div className="brand">
            <h1>Core Creator</h1>
            <span>{boot?.framework || 'auto'}</span>
          </div>
          <button
            className={`nav-item ${page === 'dashboard' ? 'active' : ''}`}
            onClick={() => setPage('dashboard')}
          >
            Tableau de bord
          </button>
          {(boot?.modules || []).map((m) => (
            <button
              key={m}
              className={`nav-item ${page === m ? 'active' : ''}`}
              onClick={() => setPage(m)}
            >
              <span>{MODULE_LABELS[m] || m}</span>
              <span className="nav-count">{boot?.counts?.[m] ?? 0}</span>
            </button>
          ))}
        </aside>

        <section className="main">
          <header className="header">
            <div>
              <h2>{title}</h2>
              <p className="subtitle">{subtitle}</p>
            </div>
            <button className="btn-close" onClick={() => nui('close')} aria-label="Fermer">
              ×
            </button>
          </header>

          <div className="body">
            <div className="list-panel">
              {page === 'dashboard' && (
                <div className="dashboard-grid">
                  {(boot?.modules || []).map((m) => (
                    <button key={m} className="dash-card" onClick={() => setPage(m)}>
                      <div className="label">{MODULE_LABELS[m]}</div>
                      <div className="value">{boot?.counts?.[m] ?? 0}</div>
                    </button>
                  ))}
                </div>
              )}

              {page === 'vehicles' && (
                <div className="modal" style={{ position: 'relative', width: '100%', maxHeight: 'none' }}>
                  <h3>Créer un véhicule</h3>
                  <div className="form-grid">
                    <div className="field">
                      <label>Modèle</label>
                      <input value={vehicleForm.model} onChange={(e) => setVehicleForm({ ...vehicleForm, model: e.target.value })} />
                    </div>
                    <div className="field">
                      <label>Plaque</label>
                      <input value={vehicleForm.plate} onChange={(e) => setVehicleForm({ ...vehicleForm, plate: e.target.value })} />
                    </div>
                    <div className="field">
                      <label>ID joueur cible</label>
                      <input value={vehicleForm.target} onChange={(e) => setVehicleForm({ ...vehicleForm, target: e.target.value })} />
                    </div>
                    <div className="field">
                      <label>Couleur 1</label>
                      <input type="number" value={vehicleForm.color1} onChange={(e) => setVehicleForm({ ...vehicleForm, color1: Number(e.target.value) })} />
                    </div>
                  </div>
                  <div className="modal-actions">
                    <button className="btn primary" onClick={createVehicle}>Créer & spawn</button>
                  </div>
                </div>
              )}

              {page !== 'dashboard' && page !== 'vehicles' && (
                <>
                  <div className="toolbar">
                    <input
                      className="search"
                      placeholder="Rechercher..."
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                    />
                    <button className="btn" onClick={reload}>Reload</button>
                    <button className="btn primary" onClick={openCreate}>+ Create New</button>
                  </div>

                  <div className="table-wrap">
                    {filtered.length === 0 ? (
                      <div className="empty">Aucune création trouvée</div>
                    ) : (
                      <table className="table">
                        <thead>
                          <tr>
                            <th>Nom</th>
                            <th>ID / Job</th>
                            <th>Mode</th>
                            <th>Points</th>
                            <th>Statut</th>
                            <th>Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {filtered.map((it) => {
                            const mode = modeLabel(page, it)
                            return (
                              <tr
                                key={it.id}
                                className={selectedId === it.id ? 'selected' : ''}
                                onClick={() => setSelectedId(it.id ?? null)}
                              >
                                <td className="cell-name">{it.label}</td>
                                <td>
                                  <div className="cell-id">
                                    <span className="id">{it.name}</span>
                                    <span className="meta">{metaLine(page, it)}</span>
                                  </div>
                                </td>
                                <td>
                                  <span className={`pill ${mode.tone}`}>{mode.text}</span>
                                </td>
                                <td>{pointsCount(it)}</td>
                                <td>
                                  <span className={it.active ? 'status-on' : 'status-off'}>
                                    {it.active ? 'Actif' : 'Inactif'}
                                  </span>
                                </td>
                                <td onClick={(e) => e.stopPropagation()}>
                                  <div className="actions">
                                    <button className="action" onClick={() => openEdit(it)}>Edit</button>
                                    <button className="action" onClick={() => doTeleport(it)}>TP</button>
                                    <button className="action" onClick={() => doToggle(it)}>
                                      {it.active ? 'Disable' : 'Enable'}
                                    </button>
                                    <button className="action danger" onClick={() => setConfirmDelete(it)}>
                                      Delete
                                    </button>
                                  </div>
                                </td>
                              </tr>
                            )
                          })}
                        </tbody>
                      </table>
                    )}
                  </div>
                </>
              )}
            </div>

            <GtaMap
              items={page === 'dashboard' || page === 'vehicles' ? [] : filtered}
              selectedId={selectedId}
              onSelect={onSelectPin}
              onEdit={openEdit}
            />
          </div>
        </section>

        {editor && (
          <div className="modal-backdrop">
            <div className="modal">
              <h3>{editor.id ? 'Modifier' : 'Créer'} — {MODULE_LABELS[page]}</h3>
              <div className="form-grid">
                <div className="field">
                  <label>Nom interne</label>
                  <input value={editor.name} onChange={(e) => setEditor({ ...editor, name: e.target.value })} />
                </div>
                <div className="field">
                  <label>Label</label>
                  <input value={editor.label} onChange={(e) => setEditor({ ...editor, label: e.target.value })} />
                </div>
                <div className="field">
                  <label>X</label>
                  <input
                    type="number"
                    value={editor.coords?.x ?? 0}
                    onChange={(e) =>
                      setEditor({
                        ...editor,
                        coords: { ...(editor.coords || { x: 0, y: 0, z: 0 }), x: Number(e.target.value) },
                      })
                    }
                  />
                </div>
                <div className="field">
                  <label>Y</label>
                  <input
                    type="number"
                    value={editor.coords?.y ?? 0}
                    onChange={(e) =>
                      setEditor({
                        ...editor,
                        coords: { ...(editor.coords || { x: 0, y: 0, z: 0 }), y: Number(e.target.value) },
                      })
                    }
                  />
                </div>
                <div className="field">
                  <label>Z</label>
                  <input
                    type="number"
                    value={editor.coords?.z ?? 0}
                    onChange={(e) =>
                      setEditor({
                        ...editor,
                        coords: { ...(editor.coords || { x: 0, y: 0, z: 0 }), z: Number(e.target.value) },
                      })
                    }
                  />
                </div>
                <div className="field">
                  <label>Heading</label>
                  <input
                    type="number"
                    value={editor.coords?.w ?? 0}
                    onChange={(e) =>
                      setEditor({
                        ...editor,
                        coords: { ...(editor.coords || { x: 0, y: 0, z: 0 }), w: Number(e.target.value) },
                      })
                    }
                  />
                </div>
                <div className="field full">
                  <label>Data JSON</label>
                  <textarea value={dataJson} onChange={(e) => setDataJson(e.target.value)} />
                </div>
              </div>
              <div className="modal-actions">
                <button className="btn" onClick={usePlayerCoords}>Coords joueur</button>
                <button className="btn" onClick={startPlacement}>Placement 3D</button>
                <button className="btn" onClick={() => setEditor(null)}>Annuler</button>
                <button className="btn primary" onClick={saveEditor}>Enregistrer</button>
              </div>
            </div>
          </div>
        )}

        {confirmDelete && (
          <div className="modal-backdrop">
            <div className="modal" style={{ width: 420 }}>
              <h3>Confirmation</h3>
              <p style={{ color: 'var(--text-dim)', marginBottom: 8 }}>
                Supprimer définitivement <strong style={{ color: '#fff' }}>{confirmDelete.label}</strong> ?
              </p>
              <div className="modal-actions">
                <button className="btn" onClick={() => setConfirmDelete(null)}>Annuler</button>
                <button className="btn" style={{ background: 'var(--red-soft)', borderColor: 'rgba(239,68,68,.4)', color: '#fca5a5' }} onClick={doDelete}>
                  Delete
                </button>
              </div>
            </div>
          </div>
        )}

        {toast && <div className={`toast ${toast.type}`}>{toast.text}</div>}
      </div>
    </div>
  )
}
