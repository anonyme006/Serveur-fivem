import { useEffect, useMemo, useState } from 'react'
import type { BootstrapData, CreatorEntity, ModuleName } from './types'
import { nui, onNuiMessage } from './lib/nui'
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

const defaultEntity = (): CreatorEntity => ({
  name: '',
  label: '',
  coords: { x: 0, y: 0, z: 0, w: 0 },
  data: {},
  active: true,
})

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
      return {
        type: 'public',
        spawnPrice: 0,
        impoundPrice: 500,
        spawns: [],
        store: null,
        interaction: 'marker',
      }
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
      return {
        price: 150000,
        rent: 0,
        currency: 'bank',
        interior: null,
        shell: 'default',
      }
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

export default function App() {
  const [visible, setVisible] = useState(false)
  const [boot, setBoot] = useState<BootstrapData | null>(null)
  const [page, setPage] = useState<'dashboard' | ModuleName>('dashboard')
  const [items, setItems] = useState<CreatorEntity[]>([])
  const [search, setSearch] = useState('')
  const [filterActive, setFilterActive] = useState<'all' | 'on' | 'off'>('all')
  const [editor, setEditor] = useState<CreatorEntity | null>(null)
  const [dataJson, setDataJson] = useState('{}')
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' | 'inform' } | null>(null)
  const [placementCoords, setPlacementCoords] = useState<string>('')
  const [confirmDelete, setConfirmDelete] = useState<CreatorEntity | null>(null)
  const [vehicleForm, setVehicleForm] = useState({ model: 'adder', plate: '', target: '', color1: 0, color2: 0, spawn: true })

  const showToast = (text: string, type: 'success' | 'error' | 'inform' = 'inform') => {
    setToast({ text, type })
    window.setTimeout(() => setToast(null), 2800)
  }

  const loadList = async (module: ModuleName) => {
    const res = await nui<CreatorEntity[]>('list', { module })
    if (res.ok && Array.isArray(res.data)) setItems(res.data)
    else setItems([])
  }

  useEffect(() => {
    return onNuiMessage((action, data) => {
      if (action === 'open') {
        setBoot(data as BootstrapData)
        setVisible(true)
        setPage('dashboard')
      }
      if (action === 'close') setVisible(false)
      if (action === 'placementCoords' && data) {
        const c = data as { x: number; y: number; z: number; w: number }
        setPlacementCoords(`${c.x}, ${c.y}, ${c.z}, ${c.w}`)
      }
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
    }
  }, [page])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return items.filter((it) => {
      const activeOk =
        filterActive === 'all' || (filterActive === 'on' ? it.active : !it.active)
      const searchOk =
        !q ||
        it.name.toLowerCase().includes(q) ||
        it.label.toLowerCase().includes(q)
      return activeOk && searchOk
    })
  }, [items, search, filterActive])

  if (!visible) return null

  const openCreate = () => {
    if (page === 'dashboard' || page === 'vehicles') return
    const entity = defaultEntity()
    entity.data = moduleDefaults(page)
    setEditor(entity)
    setDataJson(JSON.stringify(entity.data, null, 2))
  }

  const openEdit = (entity: CreatorEntity) => {
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
    const payload = { module: page, entity }
    const res = entity.id ? await nui('update', payload) : await nui('create', payload)
    if (!res.ok) {
      showToast(res.message || 'Erreur', 'error')
      return
    }
    showToast(entity.id ? 'Modifié' : 'Créé', 'success')
    setEditor(null)
    await loadList(page)
    const bootRes = await nui<BootstrapData>('list', { module: page })
    void bootRes
  }

  const doToggle = async (entity: CreatorEntity) => {
    if (page === 'dashboard' || page === 'vehicles') return
    const res = await nui('toggle', { module: page, id: entity.id, active: !entity.active })
    if (res.ok) {
      showToast('État mis à jour', 'success')
      loadList(page)
    }
  }

  const doDuplicate = async (entity: CreatorEntity) => {
    if (page === 'dashboard' || page === 'vehicles') return
    const res = await nui('duplicate', { module: page, id: entity.id })
    if (res.ok) {
      showToast('Dupliqué', 'success')
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

  const doExport = async (entity: CreatorEntity) => {
    if (page === 'dashboard' || page === 'vehicles') return
    const res = await nui('exportOne', { module: page, id: entity.id })
    if (!res.ok || !res.data) return
    const blob = new Blob([JSON.stringify(res.data, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${page}_${entity.name}.json`
    a.click()
    URL.revokeObjectURL(url)
    showToast('Export prêt', 'success')
  }

  const doImport = async () => {
    if (page === 'dashboard' || page === 'vehicles') return
    const input = document.createElement('input')
    input.type = 'file'
    input.accept = 'application/json'
    input.onchange = async () => {
      const file = input.files?.[0]
      if (!file) return
      try {
        const text = await file.text()
        const json = JSON.parse(text)
        const entity = json.entity || json
        const res = await nui('importOne', { module: page, entity, onConflict: 'rename' })
        if (res.ok) {
          showToast('Import OK', 'success')
          loadList(page)
        } else showToast(res.message || 'Erreur import', 'error')
      } catch {
        showToast('Fichier invalide', 'error')
      }
    }
    input.click()
  }

  const usePlayerCoords = async () => {
    const res = await nui<{ x: number; y: number; z: number; w: number }>('getPlayerCoords')
    if (res.ok && res.data && editor) {
      setEditor({ ...editor, coords: res.data })
      showToast('Coords joueur appliquées', 'success')
    }
  }

  const startPlacement = async () => {
    await nui('startPlacement', { previewModel: page === 'blips' ? undefined : undefined })
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

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <h1>Core Creator</h1>
          <p>{boot?.framework || 'framework'} · {boot?.locale || 'fr'}</p>
        </div>
        <button className={`nav-btn ${page === 'dashboard' ? 'active' : ''}`} onClick={() => setPage('dashboard')}>
          Tableau de bord
        </button>
        {(boot?.modules || []).map((m) => (
          <button key={m} className={`nav-btn ${page === m ? 'active' : ''}`} onClick={() => setPage(m)}>
            {MODULE_LABELS[m] || m}
          </button>
        ))}
      </aside>

      <section className="main">
        <header className="topbar">
          <h2>{page === 'dashboard' ? 'Tableau de bord' : MODULE_LABELS[page] || page}</h2>
          <div className="topbar-actions">
            {placementCoords && <span className="coords-live">{placementCoords}</span>}
            <button className="btn ghost" onClick={() => nui('close')}>Fermer</button>
          </div>
        </header>

        <div className="content">
          {page === 'dashboard' && (
            <>
              <div className="cards">
                {(boot?.modules || []).map((m) => (
                  <button key={m} className="card" style={{ cursor: 'pointer', textAlign: 'left' }} onClick={() => setPage(m)}>
                    <div className="label">{MODULE_LABELS[m]}</div>
                    <div className="value">{boot?.counts?.[m] ?? 0}</div>
                  </button>
                ))}
              </div>
              <p className="empty" style={{ textAlign: 'left', paddingTop: 24 }}>
                Créez et gérez boutiques, blips, farms, jobs, garages, gangs, appartements et braquages sans éditer les fichiers Lua.
              </p>
            </>
          )}

          {page === 'vehicles' && (
            <div className="modal" style={{ position: 'relative', width: '100%', maxHeight: 'none' }}>
              <h3>Créer un véhicule / clés</h3>
              <div className="form-grid">
                <div className="field"><label>Modèle</label><input value={vehicleForm.model} onChange={(e) => setVehicleForm({ ...vehicleForm, model: e.target.value })} /></div>
                <div className="field"><label>Plaque (auto si vide)</label><input value={vehicleForm.plate} onChange={(e) => setVehicleForm({ ...vehicleForm, plate: e.target.value })} /></div>
                <div className="field"><label>ID joueur cible</label><input value={vehicleForm.target} onChange={(e) => setVehicleForm({ ...vehicleForm, target: e.target.value })} /></div>
                <div className="field"><label>Couleur 1</label><input type="number" value={vehicleForm.color1} onChange={(e) => setVehicleForm({ ...vehicleForm, color1: Number(e.target.value) })} /></div>
                <div className="field"><label>Couleur 2</label><input type="number" value={vehicleForm.color2} onChange={(e) => setVehicleForm({ ...vehicleForm, color2: Number(e.target.value) })} /></div>
              </div>
              <div className="modal-actions">
                <button className="btn primary" onClick={createVehicle}>Créer & spawn</button>
              </div>
            </div>
          )}

          {page !== 'dashboard' && page !== 'vehicles' && (
            <>
              <div className="toolbar">
                <input className="search" placeholder="Rechercher..." value={search} onChange={(e) => setSearch(e.target.value)} />
                <select className="btn" value={filterActive} onChange={(e) => setFilterActive(e.target.value as 'all' | 'on' | 'off')}>
                  <option value="all">Tous</option>
                  <option value="on">Actifs</option>
                  <option value="off">Inactifs</option>
                </select>
                <button className="btn" onClick={doImport}>Importer</button>
                <button className="btn primary" onClick={openCreate}>Créer</button>
              </div>

              {filtered.length === 0 ? (
                <div className="empty">Aucune création trouvée</div>
              ) : (
                <table className="table">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Nom</th>
                      <th>Label</th>
                      <th>État</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.map((it) => (
                      <tr key={it.id}>
                        <td>{it.id}</td>
                        <td>{it.name}</td>
                        <td>{it.label}</td>
                        <td><span className={`badge ${it.active ? 'on' : 'off'}`}>{it.active ? 'Actif' : 'Inactif'}</span></td>
                        <td>
                          <div className="row-actions">
                            <button className="btn" onClick={() => openEdit(it)}>Modifier</button>
                            <button className="btn" onClick={() => doDuplicate(it)}>Dupliquer</button>
                            <button className="btn" onClick={() => doToggle(it)}>{it.active ? 'Désactiver' : 'Activer'}</button>
                            <button className="btn" onClick={() => doExport(it)}>Export</button>
                            <button className="btn danger" onClick={() => setConfirmDelete(it)}>Supprimer</button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </>
          )}
        </div>
      </section>

      {editor && (
        <div className="modal-backdrop">
          <div className="modal">
            <h3>{editor.id ? 'Modifier' : 'Créer'} — {MODULE_LABELS[page]}</h3>
            <div className="form-grid">
              <div className="field"><label>Nom interne</label><input value={editor.name} onChange={(e) => setEditor({ ...editor, name: e.target.value })} /></div>
              <div className="field"><label>Label</label><input value={editor.label} onChange={(e) => setEditor({ ...editor, label: e.target.value })} /></div>
              <div className="field"><label>X</label><input type="number" value={editor.coords?.x ?? 0} onChange={(e) => setEditor({ ...editor, coords: { ...(editor.coords || { x:0,y:0,z:0 }), x: Number(e.target.value) } })} /></div>
              <div className="field"><label>Y</label><input type="number" value={editor.coords?.y ?? 0} onChange={(e) => setEditor({ ...editor, coords: { ...(editor.coords || { x:0,y:0,z:0 }), y: Number(e.target.value) } })} /></div>
              <div className="field"><label>Z</label><input type="number" value={editor.coords?.z ?? 0} onChange={(e) => setEditor({ ...editor, coords: { ...(editor.coords || { x:0,y:0,z:0 }), z: Number(e.target.value) } })} /></div>
              <div className="field"><label>Heading</label><input type="number" value={editor.coords?.w ?? 0} onChange={(e) => setEditor({ ...editor, coords: { ...(editor.coords || { x:0,y:0,z:0 }), w: Number(e.target.value) } })} /></div>
              <div className="field full">
                <label>Data JSON (module)</label>
                <textarea value={dataJson} onChange={(e) => setDataJson(e.target.value)} />
              </div>
            </div>
            <div className="modal-actions">
              <button className="btn" onClick={usePlayerCoords}>Coords joueur</button>
              <button className="btn" onClick={startPlacement}>Placement 3D</button>
              <button className="btn ghost" onClick={() => setEditor(null)}>Annuler</button>
              <button className="btn primary" onClick={saveEditor}>Enregistrer</button>
            </div>
          </div>
        </div>
      )}

      {confirmDelete && (
        <div className="modal-backdrop">
          <div className="modal" style={{ width: 420 }}>
            <h3>Confirmation</h3>
            <p>Supprimer définitivement <strong>{confirmDelete.label}</strong> ?</p>
            <div className="modal-actions">
              <button className="btn ghost" onClick={() => setConfirmDelete(null)}>Annuler</button>
              <button className="btn danger" onClick={doDelete}>Supprimer</button>
            </div>
          </div>
        </div>
      )}

      {toast && <div className={`toast ${toast.type}`}>{toast.text}</div>}
    </div>
  )
}
