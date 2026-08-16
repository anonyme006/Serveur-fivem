import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ArrowDown,
  ArrowUp,
  Building2,
  MapPin,
  Package,
  Plus,
  Save,
  Search,
  Settings2,
  Shield,
  Store,
  Trash2,
  Users,
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Button } from '../components/Button';
import { Field, Input, Select, Textarea, Toggle } from '../components/Form';
import { ConfirmDialog, Modal } from '../components/Modal';
import { NavItem, PanelShell } from '../components/Panel';
import { EmptyState, ErrorState, LoadingState } from '../components/States';
import { fetchNuiResult } from '../lib/nui';
import { formatMoney, uid } from '../lib/utils';
import { useAppStore } from '../stores/appStore';
import {
  emptyShop,
  LOCATION_LABELS,
  type AdminEntry,
  type AppSettings,
  type InventoryItem,
  type LocationType,
  type OwnershipMode,
  type Shop,
  type ShopCategory,
  type ShopLocation,
  type ShopProduct,
  type ShopSummary,
} from '../types';

type AdminNav = 'collection' | 'create' | 'admins' | 'settings';
type WizardSection =
  | 'general'
  | 'ownership'
  | 'locations'
  | 'blip'
  | 'categories'
  | 'products'
  | 'access'
  | 'payments'
  | 'garage';

const WIZARD_SECTIONS: { id: WizardSection; label: string }[] = [
  { id: 'general', label: 'Général' },
  { id: 'ownership', label: 'Propriété' },
  { id: 'locations', label: 'Emplacements' },
  { id: 'blip', label: 'Blip carte' },
  { id: 'categories', label: 'Catégories' },
  { id: 'products', label: 'Produits' },
  { id: 'access', label: 'Accès / PNJ' },
  { id: 'payments', label: 'Paiements' },
  { id: 'garage', label: 'Garage' },
];

const SINGLE_LOCATIONS: LocationType[] = [
  'management',
  'storage',
  'delivery',
  'garage',
  'vehicle_spawn',
  'vehicle_return',
];

export function AdminPage() {
  const { closeUi, pushToast } = useAppStore();
  const [nav, setNav] = useState<AdminNav>('collection');
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<Shop | null>(null);
  const [wizardSection, setWizardSection] = useState<WizardSection>('general');
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<ShopSummary | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [admins, setAdmins] = useState<AdminEntry[]>([]);
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [adminForm, setAdminForm] = useState({ identifier: '', label: '' });
  const [productSearch, setProductSearch] = useState('');
  const [catalogOpen, setCatalogOpen] = useState(false);
  const [catalogSelected, setCatalogSelected] = useState<string[]>([]);

  const loadShops = useCallback(async () => {
    setLoading(true);
    setError(null);
    const res = await fetchNuiResult<ShopSummary[]>('getShops');
    setLoading(false);
    if (!res.ok) {
      setError(res.error ?? 'Impossible de charger les magasins');
      return;
    }
    setShops(res.data ?? []);
  }, []);

  const loadAdmins = useCallback(async () => {
    const res = await fetchNuiResult<AdminEntry[]>('getAdmins');
    if (res.ok) setAdmins(res.data ?? []);
    else pushToast('error', res.error ?? 'Erreur admins');
  }, [pushToast]);

  const loadSettings = useCallback(async () => {
    const res = await fetchNuiResult<AppSettings>('getSettings');
    if (res.ok) setSettings(res.data ?? null);
    else pushToast('error', res.error ?? 'Erreur paramètres');
  }, [pushToast]);

  const loadInventory = useCallback(async () => {
    const res = await fetchNuiResult<InventoryItem[]>('getInventoryItems');
    if (res.ok) setInventory(res.data ?? []);
  }, []);

  useEffect(() => {
    void loadShops();
  }, [loadShops]);

  useEffect(() => {
    if (nav === 'admins') void loadAdmins();
    if (nav === 'settings') void loadSettings();
  }, [nav, loadAdmins, loadSettings]);

  const startCreate = () => {
    setEditing(emptyShop({ name: '', blip: { enabled: true, sprite: 52, color: 2, scale: 0.75, name: '' } }));
    setWizardSection('general');
    setNav('create');
  };

  const startEdit = async (id: number) => {
    setLoading(true);
    const res = await fetchNuiResult<Shop>('getShop', { id, shopId: id });
    setLoading(false);
    if (!res.ok || !res.data) {
      pushToast('error', res.error ?? 'Magasin introuvable');
      return;
    }
    setEditing(res.data);
    setWizardSection('general');
    setNav('create');
    void loadInventory();
  };

  const saveShop = async () => {
    if (!editing) return;
    if (!editing.name.trim()) {
      pushToast('error', 'Le nom est requis');
      setWizardSection('general');
      return;
    }
    setSaving(true);
    const res = await fetchNuiResult<Shop>('saveShop', { shop: editing });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Échec de sauvegarde');
      return;
    }
    pushToast('success', res.message ?? 'Magasin enregistré');
    if (res.data) setEditing(res.data);
    setNav('collection');
    void loadShops();
  };

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    const res = await fetchNuiResult('deleteShop', { id: deleteTarget.id, shopId: deleteTarget.id });
    setDeleting(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Suppression impossible');
      return;
    }
    pushToast('success', res.message ?? 'Magasin supprimé');
    setDeleteTarget(null);
    void loadShops();
  };

  const patch = (partial: Partial<Shop>) => {
    setEditing((s) => (s ? { ...s, ...partial } : s));
  };

  const setLocation = async (type: LocationType, multi = false) => {
    if (!editing) return;
    const res = await fetchNuiResult<{ x: number; y: number; z: number; w: number }>('useCurrentPosition', {
      type,
    });
    if (!res.ok || !res.data) {
      pushToast('error', res.error ?? 'Position indisponible');
      return;
    }
    const loc: ShopLocation = {
      location_type: type,
      label: LOCATION_LABELS[type],
      ...res.data,
    };
    setEditing((s) => {
      if (!s) return s;
      if (multi || type === 'customer') {
        return { ...s, locations: [...s.locations, loc] };
      }
      return {
        ...s,
        locations: [...s.locations.filter((l) => l.location_type !== type), loc],
      };
    });
    pushToast('success', 'Position enregistrée');
  };

  const removeLocations = (type: LocationType, index?: number) => {
    setEditing((s) => {
      if (!s) return s;
      if (type === 'customer' && typeof index === 'number') {
        const customers = s.locations.filter((l) => l.location_type === 'customer');
        const others = s.locations.filter((l) => l.location_type !== 'customer');
        customers.splice(index, 1);
        return { ...s, locations: [...others, ...customers] };
      }
      return { ...s, locations: s.locations.filter((l) => l.location_type !== type) };
    });
  };

  const addCategoriesFromCatalog = () => {
    if (!editing) return;
    const items = inventory.filter((i) => catalogSelected.includes(i.name));
    const existing = new Set(editing.products.map((p) => p.item_name));
    const added: ShopProduct[] = items
      .filter((i) => !existing.has(i.name))
      .map((i, idx) => ({
        tempId: uid('prod'),
        item_name: i.name,
        label: i.label,
        image: i.image ?? null,
        price: 50,
        wholesale_price: 20,
        stock: editing.default_stock,
        max_stock: 100,
        enabled: true,
        sort_order: editing.products.length + idx,
        category_id: editing.categories[0]?.id ?? null,
        categoryTempId: editing.categories[0]?.tempId ?? null,
      }));
    patch({ products: [...editing.products, ...added] });
    setCatalogOpen(false);
    setCatalogSelected([]);
    pushToast('success', `${added.length} produit(s) ajouté(s)`);
  };

  const filteredProducts = useMemo(() => {
    if (!editing) return [];
    const q = productSearch.trim().toLowerCase();
    if (!q) return editing.products;
    return editing.products.filter(
      (p) => p.label.toLowerCase().includes(q) || p.item_name.toLowerCase().includes(q),
    );
  }, [editing, productSearch]);

  return (
    <PanelShell title="Administration Suite" subtitle="Shops Creator" onClose={() => void closeUi()}>
      <div className="layout">
        <aside className="sidebar">
          <div className="sidebar-section">Navigation</div>
          <NavItem active={nav === 'collection'} icon={<Store size={16} />} label="Collection" onClick={() => setNav('collection')} />
          <NavItem
            active={nav === 'create'}
            icon={<Plus size={16} />}
            label={editing?.id ? 'Édition' : 'Créer'}
            onClick={startCreate}
          />
          <NavItem active={nav === 'admins'} icon={<Shield size={16} />} label="Admins" onClick={() => setNav('admins')} />
          <NavItem
            active={nav === 'settings'}
            icon={<Settings2 size={16} />}
            label="Paramètres"
            onClick={() => setNav('settings')}
          />
        </aside>

        <main className="content">
          {nav === 'collection' && (
            <>
              <div className="content-header">
                <div>
                  <h2>Collection</h2>
                  <p>Gérez tous les commerces du serveur.</p>
                </div>
                <Button variant="primary" onClick={startCreate}>
                  <Plus size={16} /> Nouveau magasin
                </Button>
              </div>
              {loading ? <LoadingState /> : null}
              {error ? <ErrorState message={error} onRetry={() => void loadShops()} /> : null}
              {!loading && !error && shops.length === 0 ? (
                <EmptyState
                  icon={<Building2 size={36} />}
                  title="Aucun magasin"
                  description="Créez votre premier commerce pour commencer."
                  action={
                    <Button variant="primary" onClick={startCreate}>
                      Créer
                    </Button>
                  }
                />
              ) : null}
              {!loading && !error && shops.length > 0 ? (
                <div className="card-grid">
                  {shops.map((shop) => (
                    <div key={shop.id} className="card">
                      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                        {shop.logo_url ? (
                          <img className="shop-logo" src={shop.logo_url} alt="" />
                        ) : (
                          <div className="shop-logo fallback">{shop.name.slice(0, 2).toUpperCase()}</div>
                        )}
                        <div style={{ minWidth: 0, flex: 1 }}>
                          <div style={{ fontWeight: 650 }}>{shop.name}</div>
                          <div className="muted" style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {shop.description || 'Aucune description'}
                          </div>
                        </div>
                      </div>
                      <div className="chip-row" style={{ marginTop: 12 }}>
                        <Badge tone={shop.enabled ? 'green' : 'red'}>{shop.enabled ? 'Actif' : 'Inactif'}</Badge>
                        <Badge tone={shop.is_open ? 'green' : 'amber'}>{shop.is_open ? 'Ouvert' : 'Fermé'}</Badge>
                        <Badge tone="purple">{shop.ownership_mode}</Badge>
                      </div>
                      <div className="muted" style={{ marginBottom: 10 }}>
                        {shop.product_count} produits · {shop.employee_count} employés
                        {shop.ownership_mode === 'purchasable' ? ` · ${formatMoney(shop.buy_price)}` : ''}
                      </div>
                      <div className="inline-actions">
                        <Button size="sm" variant="primary" onClick={() => void startEdit(shop.id)}>
                          Éditer
                        </Button>
                        <Button size="sm" variant="danger" onClick={() => setDeleteTarget(shop)}>
                          <Trash2 size={14} /> Supprimer
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : null}
            </>
          )}

          {nav === 'create' && editing && (
            <>
              <div className="content-header">
                <div>
                  <h2>{editing.id ? `Éditer — ${editing.name || 'Magasin'}` : 'Créer un magasin'}</h2>
                  <p>Configurez chaque section puis enregistrez.</p>
                </div>
                <div className="inline-actions">
                  <Button variant="ghost" onClick={() => { setEditing(null); setNav('collection'); }}>
                    Annuler
                  </Button>
                  <Button variant="primary" disabled={saving} onClick={() => void saveShop()}>
                    <Save size={16} /> {saving ? 'Enregistrement…' : 'Enregistrer'}
                  </Button>
                </div>
              </div>

              <div className="wizard-layout">
                <div className="wizard-nav">
                  {WIZARD_SECTIONS.map((s) => (
                    <button
                      key={s.id}
                      type="button"
                      className={`nav-item ${wizardSection === s.id ? 'active' : ''}`}
                      onClick={() => setWizardSection(s.id)}
                    >
                      {s.label}
                    </button>
                  ))}
                </div>

                <div>
                  {wizardSection === 'general' && (
                    <>
                      <div className="field-row">
                        <Field label="Nom">
                          <Input value={editing.name} onChange={(e) => patch({ name: e.target.value })} />
                        </Field>
                        <Field label="Slug (optionnel)">
                          <Input value={editing.slug} onChange={(e) => patch({ slug: e.target.value })} />
                        </Field>
                      </div>
                      <Field label="Description">
                        <Textarea value={editing.description} onChange={(e) => patch({ description: e.target.value })} />
                      </Field>
                      <Field label="URL du logo">
                        <Input value={editing.logo_url} onChange={(e) => patch({ logo_url: e.target.value })} />
                      </Field>
                      <div className="field-row three">
                        <Field label="Stock par défaut">
                          <Input
                            type="number"
                            value={editing.default_stock}
                            onChange={(e) => patch({ default_stock: Number(e.target.value) })}
                          />
                        </Field>
                        <Field label="Capacité stockage">
                          <Input
                            type="number"
                            value={editing.storage_capacity}
                            onChange={(e) => patch({ storage_capacity: Number(e.target.value) })}
                          />
                        </Field>
                        <Field label="Ouverture / Fermeture">
                          <div style={{ display: 'flex', gap: 8 }}>
                            <Input
                              type="number"
                              step="0.5"
                              value={editing.open_hour}
                              onChange={(e) => patch({ open_hour: Number(e.target.value) })}
                            />
                            <Input
                              type="number"
                              step="0.5"
                              value={editing.close_hour}
                              onChange={(e) => patch({ close_hour: Number(e.target.value) })}
                            />
                          </div>
                        </Field>
                      </div>
                      <Toggle checked={editing.enabled} onChange={(v) => patch({ enabled: v })} label="Magasin activé" />
                      <Toggle
                        checked={editing.infinite_stock}
                        onChange={(v) => patch({ infinite_stock: v })}
                        label="Stock illimité"
                      />
                      <Toggle
                        checked={editing.auto_hours}
                        onChange={(v) => patch({ auto_hours: v })}
                        label="Horaires automatiques"
                      />
                    </>
                  )}

                  {wizardSection === 'ownership' && (
                    <>
                      <Field label="Mode de propriété">
                        <Select
                          value={editing.ownership_mode}
                          onChange={(e) => patch({ ownership_mode: e.target.value as OwnershipMode })}
                        >
                          <option value="none">Aucun</option>
                          <option value="purchasable">Achetable</option>
                          <option value="owned">Possédé</option>
                        </Select>
                      </Field>
                      <div className="field-row">
                        <Field label="Prix d'achat">
                          <Input
                            type="number"
                            value={editing.buy_price}
                            onChange={(e) => patch({ buy_price: Number(e.target.value) })}
                          />
                        </Field>
                        <Field label="Fonds initiaux (balance)">
                          <Input
                            type="number"
                            value={editing.balance}
                            onChange={(e) => patch({ balance: Number(e.target.value) })}
                          />
                        </Field>
                      </div>
                      <Toggle
                        checked={editing.resale_enabled}
                        onChange={(v) => patch({ resale_enabled: v })}
                        label="Revente autorisée"
                      />
                      <Field label="Pourcentage de revente">
                        <Input
                          type="number"
                          value={editing.resale_percent}
                          onChange={(e) => patch({ resale_percent: Number(e.target.value) })}
                        />
                      </Field>
                      <Field label="CitizenID propriétaire">
                        <Input
                          value={editing.owner_citizenid ?? ''}
                          onChange={(e) => patch({ owner_citizenid: e.target.value || null })}
                        />
                      </Field>
                      {editing.id > 0 && editing.ownership_mode === 'owned' ? (
                        <div className="inline-actions">
                          <Button
                            variant="secondary"
                            onClick={async () => {
                              const res = await fetchNuiResult<Shop>('sellShop', { shopId: editing.id });
                              if (!res.ok) return pushToast('error', res.error ?? 'Échec');
                              pushToast('success', res.message ?? 'Revendu');
                              if (res.data) setEditing(res.data);
                            }}
                          >
                            Transférer / Revendre
                          </Button>
                        </div>
                      ) : null}
                    </>
                  )}

                  {wizardSection === 'locations' && (
                    <>
                      <div className="card" style={{ marginBottom: 12 }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <strong>
                            <MapPin size={14} style={{ verticalAlign: 'middle' }} /> Points clients
                          </strong>
                          <Button size="sm" variant="primary" onClick={() => void setLocation('customer', true)}>
                            Position actuelle
                          </Button>
                        </div>
                        {editing.locations.filter((l) => l.location_type === 'customer').length === 0 ? (
                          <p className="muted">Aucun point client.</p>
                        ) : (
                          editing.locations
                            .filter((l) => l.location_type === 'customer')
                            .map((l, idx) => (
                              <div key={`${l.x}-${idx}`} className="cart-line">
                                <span>
                                  {l.x.toFixed(1)}, {l.y.toFixed(1)}, {l.z.toFixed(1)}
                                </span>
                                <Button size="sm" variant="danger" onClick={() => removeLocations('customer', idx)}>
                                  Retirer
                                </Button>
                              </div>
                            ))
                        )}
                      </div>
                      {SINGLE_LOCATIONS.map((type) => {
                        const loc = editing.locations.find((l) => l.location_type === type);
                        return (
                          <div key={type} className="card" style={{ marginBottom: 10 }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, alignItems: 'center' }}>
                              <div>
                                <strong>{LOCATION_LABELS[type]}</strong>
                                <div className="muted">
                                  {loc
                                    ? `${loc.x.toFixed(1)}, ${loc.y.toFixed(1)}, ${loc.z.toFixed(1)}`
                                    : 'Non défini'}
                                </div>
                              </div>
                              <div className="inline-actions">
                                <Button size="sm" variant="primary" onClick={() => void setLocation(type)}>
                                  Position actuelle
                                </Button>
                                {loc ? (
                                  <Button size="sm" variant="danger" onClick={() => removeLocations(type)}>
                                    Retirer
                                  </Button>
                                ) : null}
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </>
                  )}

                  {wizardSection === 'blip' && (
                    <>
                      <Toggle
                        checked={editing.blip.enabled}
                        onChange={(v) => patch({ blip: { ...editing.blip, enabled: v } })}
                        label="Blip activé"
                      />
                      <div className="field-row three">
                        <Field label="Sprite">
                          <Input
                            type="number"
                            value={editing.blip.sprite}
                            onChange={(e) => patch({ blip: { ...editing.blip, sprite: Number(e.target.value) } })}
                          />
                        </Field>
                        <Field label="Couleur">
                          <Input
                            type="number"
                            value={editing.blip.color}
                            onChange={(e) => patch({ blip: { ...editing.blip, color: Number(e.target.value) } })}
                          />
                        </Field>
                        <Field label="Échelle">
                          <Input
                            type="number"
                            step="0.05"
                            value={editing.blip.scale}
                            onChange={(e) => patch({ blip: { ...editing.blip, scale: Number(e.target.value) } })}
                          />
                        </Field>
                      </div>
                      <Field label="Nom du blip">
                        <Input
                          value={editing.blip.name}
                          onChange={(e) => patch({ blip: { ...editing.blip, name: e.target.value } })}
                        />
                      </Field>
                    </>
                  )}

                  {wizardSection === 'categories' && (
                    <CategoriesEditor
                      categories={editing.categories}
                      onChange={(categories) => patch({ categories })}
                    />
                  )}

                  {wizardSection === 'products' && (
                    <>
                      <div className="search-bar">
                        <Search size={16} color="#9ca3af" />
                        <Input
                          placeholder="Rechercher un produit…"
                          value={productSearch}
                          onChange={(e) => setProductSearch(e.target.value)}
                        />
                        <Button
                          variant="primary"
                          onClick={() => {
                            void loadInventory();
                            setCatalogOpen(true);
                          }}
                        >
                          <Package size={16} /> Catalogue
                        </Button>
                      </div>
                      {filteredProducts.length === 0 ? (
                        <EmptyState title="Aucun produit" description="Ajoutez des items depuis le catalogue." />
                      ) : (
                        <table className="table">
                          <thead>
                            <tr>
                              <th>Produit</th>
                              <th>Prix</th>
                              <th>Gros</th>
                              <th>Stock</th>
                              <th>Max</th>
                              <th>Catégorie</th>
                              <th />
                            </tr>
                          </thead>
                          <tbody>
                            {filteredProducts.map((p, idx) => {
                              const realIndex = editing.products.findIndex(
                                (x) => (x.id && x.id === p.id) || (x.tempId && x.tempId === p.tempId),
                              );
                              return (
                                <tr key={p.id ?? p.tempId ?? idx}>
                                  <td>
                                    <div>{p.label}</div>
                                    <div className="muted">{p.item_name}</div>
                                  </td>
                                  <td>
                                    <Input
                                      type="number"
                                      value={p.price}
                                      onChange={(e) => {
                                        const products = [...editing.products];
                                        products[realIndex] = { ...p, price: Number(e.target.value) };
                                        patch({ products });
                                      }}
                                    />
                                  </td>
                                  <td>
                                    <Input
                                      type="number"
                                      value={p.wholesale_price}
                                      onChange={(e) => {
                                        const products = [...editing.products];
                                        products[realIndex] = { ...p, wholesale_price: Number(e.target.value) };
                                        patch({ products });
                                      }}
                                    />
                                  </td>
                                  <td>
                                    <Input
                                      type="number"
                                      value={p.stock}
                                      onChange={(e) => {
                                        const products = [...editing.products];
                                        products[realIndex] = { ...p, stock: Number(e.target.value) };
                                        patch({ products });
                                      }}
                                    />
                                  </td>
                                  <td>
                                    <Input
                                      type="number"
                                      value={p.max_stock}
                                      onChange={(e) => {
                                        const products = [...editing.products];
                                        products[realIndex] = { ...p, max_stock: Number(e.target.value) };
                                        patch({ products });
                                      }}
                                    />
                                  </td>
                                  <td>
                                    <Select
                                      value={String(p.category_id ?? p.categoryTempId ?? '')}
                                      onChange={(e) => {
                                        const val = e.target.value;
                                        const cat = editing.categories.find(
                                          (c) => String(c.id ?? c.tempId) === val,
                                        );
                                        const products = [...editing.products];
                                        products[realIndex] = {
                                          ...p,
                                          category_id: cat?.id ?? null,
                                          categoryTempId: cat?.tempId ?? null,
                                        };
                                        patch({ products });
                                      }}
                                    >
                                      <option value="">—</option>
                                      {editing.categories.map((c) => (
                                        <option key={c.id ?? c.tempId} value={String(c.id ?? c.tempId)}>
                                          {c.label}
                                        </option>
                                      ))}
                                    </Select>
                                  </td>
                                  <td>
                                    <div className="inline-actions">
                                      <Toggle
                                        checked={p.enabled}
                                        onChange={(v) => {
                                          const products = [...editing.products];
                                          products[realIndex] = { ...p, enabled: v };
                                          patch({ products });
                                        }}
                                        label=""
                                      />
                                      <Button
                                        size="sm"
                                        variant="danger"
                                        onClick={() =>
                                          patch({
                                            products: editing.products.filter((_, i) => i !== realIndex),
                                          })
                                        }
                                      >
                                        <Trash2 size={14} />
                                      </Button>
                                    </div>
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      )}
                    </>
                  )}

                  {wizardSection === 'access' && (
                    <>
                      <Toggle
                        checked={editing.npc.enabled}
                        onChange={(v) => patch({ npc: { ...editing.npc, enabled: v } })}
                        label="PNJ activé"
                      />
                      <Field label="Modèle PNJ">
                        <Input
                          value={editing.npc.model}
                          onChange={(e) => patch({ npc: { ...editing.npc, model: e.target.value } })}
                        />
                      </Field>
                      <Field label="Scénario">
                        <Input
                          value={editing.npc.scenario}
                          onChange={(e) => patch({ npc: { ...editing.npc, scenario: e.target.value } })}
                        />
                      </Field>
                    </>
                  )}

                  {wizardSection === 'payments' && (
                    <>
                      <Toggle checked={editing.allow_cash} onChange={(v) => patch({ allow_cash: v })} label="Espèces" />
                      <Toggle checked={editing.allow_bank} onChange={(v) => patch({ allow_bank: v })} label="Banque" />
                    </>
                  )}

                  {wizardSection === 'garage' && (
                    <GarageEditor
                      vehicles={editing.vehicles}
                      onChange={(vehicles) => patch({ vehicles })}
                    />
                  )}
                </div>
              </div>
            </>
          )}

          {nav === 'admins' && (
            <>
              <div className="content-header">
                <div>
                  <h2>Admins</h2>
                  <p>Identifiants autorisés à utiliser le créateur.</p>
                </div>
              </div>
              <div className="card" style={{ marginBottom: 14 }}>
                <div className="field-row">
                  <Field label="Identifiant (license:…)">
                    <Input
                      value={adminForm.identifier}
                      onChange={(e) => setAdminForm((f) => ({ ...f, identifier: e.target.value }))}
                    />
                  </Field>
                  <Field label="Label">
                    <Input value={adminForm.label} onChange={(e) => setAdminForm((f) => ({ ...f, label: e.target.value }))} />
                  </Field>
                </div>
                <Button
                  variant="primary"
                  onClick={async () => {
                    const res = await fetchNuiResult<AdminEntry>('addAdmin', adminForm);
                    if (!res.ok) return pushToast('error', res.error ?? 'Échec');
                    pushToast('success', res.message ?? 'Admin ajouté');
                    setAdminForm({ identifier: '', label: '' });
                    void loadAdmins();
                  }}
                >
                  <Users size={16} /> Ajouter
                </Button>
              </div>
              {admins.length === 0 ? (
                <EmptyState title="Aucun admin" description="Ajoutez un identifiant." />
              ) : (
                <table className="table">
                  <thead>
                    <tr>
                      <th>Label</th>
                      <th>Identifiant</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {admins.map((a) => (
                      <tr key={a.id}>
                        <td>{a.label || '—'}</td>
                        <td className="muted">{a.identifier}</td>
                        <td>
                          <Button
                            size="sm"
                            variant="danger"
                            onClick={async () => {
                              const res = await fetchNuiResult('removeAdmin', { id: a.id });
                              if (!res.ok) return pushToast('error', res.error ?? 'Échec');
                              pushToast('success', res.message ?? 'Retiré');
                              void loadAdmins();
                            }}
                          >
                            Retirer
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </>
          )}

          {nav === 'settings' && settings && (
            <>
              <div className="content-header">
                <div>
                  <h2>Paramètres</h2>
                  <p>Configuration globale du resource.</p>
                </div>
                <Button
                  variant="primary"
                  onClick={async () => {
                    const res = await fetchNuiResult<AppSettings>('saveSettings', settings);
                    if (!res.ok) return pushToast('error', res.error ?? 'Échec');
                    pushToast('success', res.message ?? 'Sauvegardé');
                    if (res.data) setSettings(res.data);
                  }}
                >
                  <Save size={16} /> Sauvegarder
                </Button>
              </div>
              <div className="field-row three">
                <Field label="Seuil stock bas">
                  <Input
                    type="number"
                    value={settings.low_stock_threshold}
                    onChange={(e) => setSettings({ ...settings, low_stock_threshold: Number(e.target.value) })}
                  />
                </Field>
                <Field label="Max catégories">
                  <Input
                    type="number"
                    value={settings.max_categories}
                    onChange={(e) => setSettings({ ...settings, max_categories: Number(e.target.value) })}
                  />
                </Field>
                <Field label="Max produits">
                  <Input
                    type="number"
                    value={settings.max_products}
                    onChange={(e) => setSettings({ ...settings, max_products: Number(e.target.value) })}
                  />
                </Field>
              </div>
              <div className="field-row">
                <Field label="Max employés">
                  <Input
                    type="number"
                    value={settings.max_employees}
                    onChange={(e) => setSettings({ ...settings, max_employees: Number(e.target.value) })}
                  />
                </Field>
                <Field label="Capacité par défaut">
                  <Input
                    type="number"
                    value={settings.default_capacity}
                    onChange={(e) => setSettings({ ...settings, default_capacity: Number(e.target.value) })}
                  />
                </Field>
              </div>
              <Toggle
                checked={settings.instant_delivery}
                onChange={(v) => setSettings({ ...settings, instant_delivery: v })}
                label="Livraison instantanée"
              />
              <Toggle
                checked={settings.self_delivery}
                onChange={(v) => setSettings({ ...settings, self_delivery: v })}
                label="Livraison self"
              />
              <Toggle
                checked={settings.public_delivery}
                onChange={(v) => setSettings({ ...settings, public_delivery: v })}
                label="Livraisons publiques"
              />
              <Field label="% récompense publique">
                <Input
                  type="number"
                  value={settings.public_reward_percent}
                  onChange={(e) => setSettings({ ...settings, public_reward_percent: Number(e.target.value) })}
                />
              </Field>
              <Toggle
                checked={settings.allow_cash_default}
                onChange={(v) => setSettings({ ...settings, allow_cash_default: v })}
                label="Espèces par défaut"
              />
              <Toggle
                checked={settings.allow_bank_default}
                onChange={(v) => setSettings({ ...settings, allow_bank_default: v })}
                label="Banque par défaut"
              />
            </>
          )}

          {nav === 'settings' && !settings ? <LoadingState /> : null}
        </main>
      </div>

      <ConfirmDialog
        open={!!deleteTarget}
        title="Supprimer le magasin"
        message={`Supprimer définitivement « ${deleteTarget?.name} » ? Cette action est irréversible.`}
        confirmLabel="Supprimer"
        danger
        loading={deleting}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => void confirmDelete()}
      />

      <Modal
        open={catalogOpen}
        title="Catalogue d'items"
        wide
        onClose={() => setCatalogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setCatalogOpen(false)}>
              Annuler
            </Button>
            <Button variant="primary" onClick={addCategoriesFromCatalog} disabled={!catalogSelected.length}>
              Ajouter ({catalogSelected.length})
            </Button>
          </>
        }
      >
        <p>Sélectionnez les items à ajouter comme produits.</p>
        <div style={{ maxHeight: 360, overflow: 'auto' }}>
          {inventory.map((item) => {
            const checked = catalogSelected.includes(item.name);
            return (
              <label key={item.name} className="toggle-row" style={{ cursor: 'pointer' }}>
                <div>
                  <div style={{ fontWeight: 560 }}>{item.label}</div>
                  <div className="muted">{item.name}</div>
                </div>
                <input
                  type="checkbox"
                  checked={checked}
                  onChange={() =>
                    setCatalogSelected((sel) =>
                      checked ? sel.filter((n) => n !== item.name) : [...sel, item.name],
                    )
                  }
                />
              </label>
            );
          })}
        </div>
      </Modal>
    </PanelShell>
  );
}

function CategoriesEditor({
  categories,
  onChange,
}: {
  categories: ShopCategory[];
  onChange: (c: ShopCategory[]) => void;
}) {
  const move = (index: number, dir: -1 | 1) => {
    const next = [...categories];
    const target = index + dir;
    if (target < 0 || target >= next.length) return;
    [next[index], next[target]] = [next[target], next[index]];
    onChange(next.map((c, i) => ({ ...c, sort_order: i })));
  };

  return (
    <>
      <div className="content-header" style={{ marginBottom: 10 }}>
        <div>
          <h2 style={{ fontSize: '1rem' }}>Catégories</h2>
        </div>
        <Button
          size="sm"
          variant="primary"
          onClick={() =>
            onChange([
              ...categories,
              { tempId: uid('cat'), label: 'Nouvelle catégorie', icon: 'package', sort_order: categories.length, enabled: true },
            ])
          }
        >
          <Plus size={14} /> Ajouter
        </Button>
      </div>
      {categories.length === 0 ? <EmptyState title="Aucune catégorie" /> : null}
      {categories.map((cat, index) => (
        <div key={cat.id ?? cat.tempId} className="card" style={{ marginBottom: 8 }}>
          <div className="field-row">
            <Field label="Label">
              <Input
                value={cat.label}
                onChange={(e) => {
                  const next = [...categories];
                  next[index] = { ...cat, label: e.target.value };
                  onChange(next);
                }}
              />
            </Field>
            <Field label="Icône">
              <Input
                value={cat.icon}
                onChange={(e) => {
                  const next = [...categories];
                  next[index] = { ...cat, icon: e.target.value };
                  onChange(next);
                }}
              />
            </Field>
          </div>
          <div className="inline-actions">
            <Toggle
              checked={cat.enabled}
              onChange={(v) => {
                const next = [...categories];
                next[index] = { ...cat, enabled: v };
                onChange(next);
              }}
              label="Activée"
            />
            <Button size="sm" variant="ghost" onClick={() => move(index, -1)}>
              <ArrowUp size={14} />
            </Button>
            <Button size="sm" variant="ghost" onClick={() => move(index, 1)}>
              <ArrowDown size={14} />
            </Button>
            <Button size="sm" variant="danger" onClick={() => onChange(categories.filter((_, i) => i !== index))}>
              <Trash2 size={14} />
            </Button>
          </div>
        </div>
      ))}
    </>
  );
}

function GarageEditor({
  vehicles,
  onChange,
}: {
  vehicles: Shop['vehicles'];
  onChange: (v: Shop['vehicles']) => void;
}) {
  return (
    <>
      <div className="inline-actions" style={{ marginBottom: 12 }}>
        <Button
          variant="primary"
          size="sm"
          onClick={() =>
            onChange([...vehicles, { tempId: uid('veh'), model: 'boxville2', label: 'Nouveau véhicule', enabled: true }])
          }
        >
          <Plus size={14} /> Ajouter véhicule
        </Button>
      </div>
      {vehicles.length === 0 ? <EmptyState title="Aucun véhicule" /> : null}
      {vehicles.map((v, index) => (
        <div key={v.id ?? v.tempId} className="card" style={{ marginBottom: 8 }}>
          <div className="field-row">
            <Field label="Modèle">
              <Input
                value={v.model}
                onChange={(e) => {
                  const next = [...vehicles];
                  next[index] = { ...v, model: e.target.value };
                  onChange(next);
                }}
              />
            </Field>
            <Field label="Label">
              <Input
                value={v.label}
                onChange={(e) => {
                  const next = [...vehicles];
                  next[index] = { ...v, label: e.target.value };
                  onChange(next);
                }}
              />
            </Field>
          </div>
          <div className="inline-actions">
            <Toggle
              checked={v.enabled}
              onChange={(checked) => {
                const next = [...vehicles];
                next[index] = { ...v, enabled: checked };
                onChange(next);
              }}
              label="Activé"
            />
            <Button size="sm" variant="danger" onClick={() => onChange(vehicles.filter((_, i) => i !== index))}>
              <Trash2 size={14} />
            </Button>
          </div>
        </div>
      ))}
    </>
  );
}
