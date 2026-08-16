import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react';
import {
  ArrowDown,
  ArrowUp,
  Boxes,
  ClipboardList,
  LayoutDashboard,
  Package,
  Palette,
  Plus,
  Save,
  ShoppingCart,
  Trash2,
  Truck,
  Users,
  Warehouse,
} from 'lucide-react';
import { Badge } from '../components/Badge';
import { Button } from '../components/Button';
import { Field, Input, Textarea, Toggle } from '../components/Form';
import { ConfirmDialog, Modal } from '../components/Modal';
import { NavItem, PanelShell } from '../components/Panel';
import { EmptyState, LoadingState } from '../components/States';
import { fetchNuiResult } from '../lib/nui';
import { formatMoney, uid } from '../lib/utils';
import { useAppStore } from '../stores/appStore';
import {
  PERMISSION_GROUPS,
  PERMISSION_LABELS,
  type DeliveryMethod,
  type Employee,
  type EmployeePermissions,
  type ManagementData,
  type OrderStatus,
  type PermissionKey,
  type ShopCategory,
  type ShopProduct,
  type StockOrderItem,
  type Transaction,
  type TransactionType,
} from '../types';

type MgmtNav =
  | 'dashboard'
  | 'categories'
  | 'products'
  | 'stock_orders'
  | 'orders'
  | 'storage'
  | 'employees'
  | 'customization';

type TxFilter = 'all' | 'sales' | 'deposits' | 'withdrawals' | 'ownership' | 'shop_changes';

const NAV_ITEMS: { id: MgmtNav; label: string; icon: ReactNode; perms: PermissionKey[] }[] = [
  {
    id: 'dashboard',
    label: 'Tableau de bord',
    icon: <LayoutDashboard size={15} />,
    perms: ['control_status', 'view_balance', 'view_activity', 'deposit_funds', 'withdraw_funds'],
  },
  { id: 'categories', label: 'Catégories', icon: <Package size={15} />, perms: ['manage_products'] },
  { id: 'products', label: 'Produits', icon: <Boxes size={15} />, perms: ['manage_products'] },
  {
    id: 'stock_orders',
    label: 'Commandes stock',
    icon: <ShoppingCart size={15} />,
    perms: ['create_stock_orders'],
  },
  { id: 'orders', label: 'Commandes', icon: <ClipboardList size={15} />, perms: ['collect_stock_orders', 'create_stock_orders'] },
  { id: 'storage', label: 'Stockage', icon: <Warehouse size={15} />, perms: ['deposit_stock', 'withdraw_stock'] },
  { id: 'employees', label: 'Employés', icon: <Users size={15} />, perms: ['manage_employees', 'manage_permissions'] },
  { id: 'customization', label: 'Personnalisation', icon: <Palette size={15} />, perms: ['customize_storefront'] },
];

const TX_FILTERS: { id: TxFilter; label: string; types?: TransactionType[] }[] = [
  { id: 'all', label: 'Tout' },
  { id: 'sales', label: 'Ventes', types: ['sale'] },
  { id: 'deposits', label: 'Dépôts', types: ['deposit'] },
  { id: 'withdrawals', label: 'Retraits', types: ['withdrawal'] },
  { id: 'ownership', label: 'Propriété', types: ['ownership'] },
  { id: 'shop_changes', label: 'Modifications', types: ['shop_change'] },
];

const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  pending: 'En attente',
  accepted: 'Acceptée',
  in_transit: 'En transit',
  delivered: 'Livrée',
  cancelled: 'Annulée',
};

const METHOD_LABELS: Record<DeliveryMethod, string> = {
  instant: 'Instantanée',
  self: 'Personnelle',
  public: 'Publique',
};

function canAny(perms: EmployeePermissions, isOwner: boolean, keys: PermissionKey[]) {
  if (isOwner) return true;
  return keys.some((k) => perms[k]);
}

function can(perms: EmployeePermissions, isOwner: boolean, key: PermissionKey) {
  return isOwner || perms[key];
}

function formatDate(iso: string) {
  try {
    return new Intl.DateTimeFormat('fr-FR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(iso));
  } catch {
    return iso;
  }
}

export function ManagementPage() {
  const { shopId, management, setManagement, closeUi, pushToast } = useAppStore();
  const [nav, setNav] = useState<MgmtNav>('dashboard');
  const [loading, setLoading] = useState(false);
  const [categories, setCategories] = useState<ShopCategory[]>([]);
  const [products, setProducts] = useState<ShopProduct[]>([]);
  const [customName, setCustomName] = useState('');
  const [customDescription, setCustomDescription] = useState('');
  const [customLogo, setCustomLogo] = useState('');
  const [fundAmount, setFundAmount] = useState('');
  const [txFilter, setTxFilter] = useState<TxFilter>('all');
  const [saving, setSaving] = useState(false);
  const [orderCart, setOrderCart] = useState<Record<number, number>>({});
  const [orderMethod, setOrderMethod] = useState<DeliveryMethod>('instant');
  const [hireForm, setHireForm] = useState({ citizenid: '', name: '' });
  const [permEmployee, setPermEmployee] = useState<Employee | null>(null);
  const [permDraft, setPermDraft] = useState<EmployeePermissions | null>(null);
  const [sellConfirm, setSellConfirm] = useState(false);
  const [selling, setSelling] = useState(false);

  const shop = management?.shop ?? null;
  const perms = management?.permissions;
  const isOwner = management?.is_owner ?? false;

  const reload = useCallback(async () => {
    if (!shopId) return;
    setLoading(true);
    const res = await fetchNuiResult<ManagementData>('getManagementData', { shopId });
    setLoading(false);
    if (!res.ok || !res.data) {
      pushToast('error', res.error ?? 'Impossible de recharger les données');
      return;
    }
    setManagement(res.data);
  }, [shopId, setManagement, pushToast]);

  useEffect(() => {
    if (!management) return;
    setCategories(management.shop.categories.map((c) => ({ ...c })));
    setProducts(management.shop.products.map((p) => ({ ...p })));
    setCustomName(management.shop.name);
    setCustomDescription(management.shop.description);
    setCustomLogo(management.shop.logo_url);
  }, [management]);

  const visibleNav = useMemo(() => {
    if (!perms) return NAV_ITEMS;
    return NAV_ITEMS.filter((item) => canAny(perms, isOwner, item.perms));
  }, [perms, isOwner]);

  useEffect(() => {
    if (!visibleNav.some((n) => n.id === nav) && visibleNav.length > 0) {
      setNav(visibleNav[0].id);
    }
  }, [visibleNav, nav]);

  const filteredTx = useMemo(() => {
    const list = management?.transactions ?? [];
    const def = TX_FILTERS.find((f) => f.id === txFilter);
    if (!def?.types) return list;
    return list.filter((t) => def.types!.includes(t.tx_type));
  }, [management?.transactions, txFilter]);

  const cartLines = useMemo(() => {
    if (!shop) return [] as { product: ShopProduct; quantity: number }[];
    return Object.entries(orderCart)
      .filter(([, qty]) => qty > 0)
      .map(([id, quantity]) => {
        const product = shop.products.find((p) => p.id === Number(id));
        return product ? { product, quantity } : null;
      })
      .filter(Boolean) as { product: ShopProduct; quantity: number }[];
  }, [orderCart, shop]);

  const cartTotalCost = useMemo(
    () => cartLines.reduce((s, l) => s + l.product.wholesale_price * l.quantity, 0),
    [cartLines],
  );

  const cartTotalQty = useMemo(() => cartLines.reduce((s, l) => s + l.quantity, 0), [cartLines]);

  const storageUsed = (management?.storage_used ?? 0) + cartTotalQty;
  const storageCapacity = shop?.storage_capacity ?? 0;

  if (!management || !shop || !perms) {
    return (
      <PanelShell title="Gestion" onClose={() => void closeUi()} size="compact">
        <LoadingState label="Chargement de la gestion…" />
      </PanelShell>
    );
  }

  const updateStatus = async (partial: { is_open?: boolean; auto_hours?: boolean }) => {
    const res = await fetchNuiResult('updateShopStatus', { shopId: shop.id, ...partial });
    if (!res.ok) {
      pushToast('error', res.error ?? 'Mise à jour impossible');
      return;
    }
    pushToast('success', res.message ?? 'Statut mis à jour');
    void reload();
  };

  const deposit = async () => {
    const amount = Number(fundAmount);
    if (!amount || amount <= 0) {
      pushToast('error', 'Montant invalide');
      return;
    }
    setSaving(true);
    const res = await fetchNuiResult('depositFunds', { shopId: shop.id, amount });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Dépôt impossible');
      return;
    }
    pushToast('success', res.message ?? 'Dépôt effectué');
    setFundAmount('');
    void reload();
  };

  const withdraw = async () => {
    const amount = Number(fundAmount);
    if (!amount || amount <= 0) {
      pushToast('error', 'Montant invalide');
      return;
    }
    setSaving(true);
    const res = await fetchNuiResult('withdrawFunds', { shopId: shop.id, amount });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Retrait impossible');
      return;
    }
    pushToast('success', res.message ?? 'Retrait effectué');
    setFundAmount('');
    void reload();
  };

  const saveCategories = async () => {
    setSaving(true);
    const res = await fetchNuiResult('saveCategories', { shopId: shop.id, categories });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Sauvegarde impossible');
      return;
    }
    pushToast('success', res.message ?? 'Catégories enregistrées');
    void reload();
  };

  const saveProducts = async () => {
    setSaving(true);
    const res = await fetchNuiResult('saveProducts', { shopId: shop.id, products });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Sauvegarde impossible');
      return;
    }
    pushToast('success', res.message ?? 'Produits enregistrés');
    void reload();
  };

  const createStockOrder = async () => {
    if (!cartLines.length) {
      pushToast('error', 'Panier vide');
      return;
    }
    if (storageUsed > storageCapacity) {
      pushToast('error', 'Capacité de stockage dépassée');
      return;
    }
    setSaving(true);
    const items: StockOrderItem[] = cartLines.map((l) => ({
      product_id: l.product.id!,
      item_name: l.product.item_name,
      label: l.product.label,
      quantity: l.quantity,
      unit_cost: l.product.wholesale_price,
    }));
    const res = await fetchNuiResult('createStockOrder', {
      shopId: shop.id,
      method: orderMethod,
      items: items.map((i) => ({ product_id: i.product_id, quantity: i.quantity })),
    });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Commande impossible');
      return;
    }
    pushToast('success', res.message ?? 'Commande créée');
    setOrderCart({});
    void reload();
  };

  const openStorage = async () => {
    const res = await fetchNuiResult('openStorage', { shopId: shop.id });
    if (!res.ok) pushToast('error', res.error ?? 'Ouverture impossible');
  };

  const hireEmployee = async () => {
    if (!hireForm.citizenid.trim()) {
      pushToast('error', 'Citizen ID requis');
      return;
    }
    setSaving(true);
    const res = await fetchNuiResult<Employee>('hireEmployee', {
      shopId: shop.id,
      citizenid: hireForm.citizenid.trim(),
      name: hireForm.name.trim() || 'Employé',
    });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Recrutement impossible');
      return;
    }
    pushToast('success', res.message ?? 'Employé recruté');
    setHireForm({ citizenid: '', name: '' });
    void reload();
  };

  const fireEmployee = async (employeeId: number) => {
    setSaving(true);
    const res = await fetchNuiResult('fireEmployee', { shopId: shop.id, employeeId });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Licenciement impossible');
      return;
    }
    pushToast('success', res.message ?? 'Employé licencié');
    void reload();
  };

  const savePermissions = async () => {
    if (!permEmployee || !permDraft) return;
    setSaving(true);
    const res = await fetchNuiResult('updateEmployeePermissions', {
      shopId: shop.id,
      employeeId: permEmployee.id,
      permissions: permDraft,
    });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Mise à jour impossible');
      return;
    }
    pushToast('success', res.message ?? 'Permissions mises à jour');
    setPermEmployee(null);
    setPermDraft(null);
    void reload();
  };

  const saveCustomization = async () => {
    setSaving(true);
    const res = await fetchNuiResult('saveShop', {
      shop: {
        ...shop,
        name: customName,
        description: customDescription,
        logo_url: customLogo,
      },
    });
    setSaving(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Sauvegarde impossible');
      return;
    }
    pushToast('success', res.message ?? 'Vitrine mise à jour');
    void reload();
  };

  const confirmSell = async () => {
    setSelling(true);
    const res = await fetchNuiResult('sellShop', { shopId: shop.id });
    setSelling(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Vente impossible');
      return;
    }
    pushToast('success', res.message ?? 'Commerce revendu');
    setSellConfirm(false);
    void closeUi();
  };

  const moveCategory = (index: number, dir: -1 | 1) => {
    const next = [...categories];
    const target = index + dir;
    if (target < 0 || target >= next.length) return;
    [next[index], next[target]] = [next[target], next[index]];
    setCategories(next.map((c, i) => ({ ...c, sort_order: i })));
  };

  const renderDashboard = () => (
    <>
      <div className="content-header">
        <div>
          <h2>Tableau de bord</h2>
          <p>Vue d'ensemble de {shop.name}</p>
        </div>
        <Button variant="ghost" size="sm" onClick={() => void reload()} disabled={loading}>
          <RefreshIcon /> Actualiser
        </Button>
      </div>

      <div className="stat-grid">
        {can(perms, isOwner, 'view_balance') ? (
          <div className="stat-card">
            <div className="label">Solde</div>
            <div className="value money">{formatMoney(shop.balance)}</div>
          </div>
        ) : null}
        <div className="stat-card">
          <div className="label">Produits</div>
          <div className="value">{shop.product_count ?? shop.products.length}</div>
        </div>
        <div className="stat-card">
          <div className="label">Employés</div>
          <div className="value">{shop.employee_count ?? management.employees.length}</div>
        </div>
        <div className="stat-card">
          <div className="label">Stock bas</div>
          <div className="value">{shop.low_stock_count ?? 0}</div>
        </div>
        <div className="stat-card">
          <div className="label">Commandes en attente</div>
          <div className="value">{shop.pending_orders ?? management.stock_orders.length}</div>
        </div>
      </div>

      {can(perms, isOwner, 'control_status') ? (
        <>
          <Toggle
            checked={shop.is_open}
            onChange={(v) => void updateStatus({ is_open: v })}
            label="Commerce ouvert"
            description="Visible pour les clients"
          />
          <Toggle
            checked={shop.auto_hours}
            onChange={(v) => void updateStatus({ auto_hours: v })}
            label="Horaires automatiques"
            description={`${shop.open_hour}h – ${shop.close_hour}h`}
          />
        </>
      ) : null}

      {can(perms, isOwner, 'deposit_funds') || can(perms, isOwner, 'withdraw_funds') ? (
        <>
          <div className="divider" />
          <h3 style={{ margin: '0 0 10px', fontFamily: 'var(--font-display)', fontSize: '1rem' }}>
            Compte entreprise
          </h3>
          <div className="field-row">
            <Field label="Montant">
              <Input
                type="number"
                min={1}
                value={fundAmount}
                onChange={(e) => setFundAmount(e.target.value)}
                placeholder="0"
              />
            </Field>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, paddingBottom: 12 }}>
              {can(perms, isOwner, 'deposit_funds') ? (
                <Button variant="primary" disabled={saving} onClick={() => void deposit()}>
                  Déposer
                </Button>
              ) : null}
              {can(perms, isOwner, 'withdraw_funds') ? (
                <Button variant="secondary" disabled={saving} onClick={() => void withdraw()}>
                  Retirer
                </Button>
              ) : null}
            </div>
          </div>
        </>
      ) : null}

      {can(perms, isOwner, 'view_activity') ? (
        <>
          <div className="divider" />
          <div className="content-header" style={{ marginBottom: 8 }}>
            <h3 style={{ margin: 0, fontFamily: 'var(--font-display)', fontSize: '1rem' }}>Activité</h3>
          </div>
          <div className="chip-row">
            {TX_FILTERS.map((f) => (
              <button
                key={f.id}
                type="button"
                className={`chip ${txFilter === f.id ? 'active' : ''}`}
                onClick={() => setTxFilter(f.id)}
              >
                {f.label}
              </button>
            ))}
          </div>
          {filteredTx.length === 0 ? (
            <EmptyState title="Aucune transaction" />
          ) : (
            <table className="table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Type</th>
                  <th>Description</th>
                  <th>Montant</th>
                </tr>
              </thead>
              <tbody>
                {filteredTx.map((tx: Transaction) => (
                  <tr key={tx.id}>
                    <td className="muted">{formatDate(tx.created_at)}</td>
                    <td>
                      <Badge tone="gray">{tx.tx_type}</Badge>
                    </td>
                    <td>
                      <div>{tx.description}</div>
                      {tx.player_name ? <div className="muted">{tx.player_name}</div> : null}
                    </td>
                    <td className="money">{formatMoney(tx.amount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </>
      ) : null}
    </>
  );

  const renderCategories = () => (
    <>
      <div className="content-header">
        <div>
          <h2>Catégories</h2>
          <p>Organisez l'affichage de la boutique</p>
        </div>
        <div className="inline-actions">
          <Button
            size="sm"
            variant="secondary"
            onClick={() =>
              setCategories([
                ...categories,
                {
                  tempId: uid('cat'),
                  label: 'Nouvelle catégorie',
                  icon: 'package',
                  sort_order: categories.length,
                  enabled: true,
                },
              ])
            }
          >
            <Plus size={14} /> Ajouter
          </Button>
          <Button size="sm" variant="primary" disabled={saving} onClick={() => void saveCategories()}>
            <Save size={14} /> Enregistrer
          </Button>
        </div>
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
                  setCategories(next);
                }}
              />
            </Field>
            <Field label="Icône">
              <Input
                value={cat.icon}
                onChange={(e) => {
                  const next = [...categories];
                  next[index] = { ...cat, icon: e.target.value };
                  setCategories(next);
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
                setCategories(next);
              }}
              label="Activée"
            />
            <Button size="sm" variant="ghost" onClick={() => moveCategory(index, -1)}>
              <ArrowUp size={14} />
            </Button>
            <Button size="sm" variant="ghost" onClick={() => moveCategory(index, 1)}>
              <ArrowDown size={14} />
            </Button>
            <Button
              size="sm"
              variant="danger"
              onClick={() => setCategories(categories.filter((_, i) => i !== index))}
            >
              <Trash2 size={14} />
            </Button>
          </div>
        </div>
      ))}
    </>
  );

  const renderProducts = () => (
    <>
      <div className="content-header">
        <div>
          <h2>Produits</h2>
          <p>Prix, stock et disponibilité</p>
        </div>
        <Button size="sm" variant="primary" disabled={saving} onClick={() => void saveProducts()}>
          <Save size={14} /> Enregistrer
        </Button>
      </div>
      {products.length === 0 ? (
        <EmptyState title="Aucun produit" />
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Produit</th>
              <th>Prix</th>
              <th>Gros</th>
              <th>Stock</th>
              <th>Max</th>
              <th>Actif</th>
            </tr>
          </thead>
          <tbody>
            {products.map((p, index) => (
              <tr key={p.id ?? p.tempId ?? index}>
                <td>
                  <div>{p.label}</div>
                  <div className="muted">{p.item_name}</div>
                </td>
                <td>
                  <Input
                    type="number"
                    value={p.price}
                    onChange={(e) => {
                      const next = [...products];
                      next[index] = { ...p, price: Number(e.target.value) };
                      setProducts(next);
                    }}
                  />
                </td>
                <td>
                  <Input
                    type="number"
                    value={p.wholesale_price}
                    onChange={(e) => {
                      const next = [...products];
                      next[index] = { ...p, wholesale_price: Number(e.target.value) };
                      setProducts(next);
                    }}
                  />
                </td>
                <td>
                  <Input
                    type="number"
                    value={p.stock}
                    onChange={(e) => {
                      const next = [...products];
                      next[index] = { ...p, stock: Number(e.target.value) };
                      setProducts(next);
                    }}
                  />
                </td>
                <td>
                  <Input
                    type="number"
                    value={p.max_stock}
                    onChange={(e) => {
                      const next = [...products];
                      next[index] = { ...p, max_stock: Number(e.target.value) };
                      setProducts(next);
                    }}
                  />
                </td>
                <td>
                  <Toggle
                    checked={p.enabled}
                    onChange={(v) => {
                      const next = [...products];
                      next[index] = { ...p, enabled: v };
                      setProducts(next);
                    }}
                    label=""
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </>
  );

  const renderStockOrders = () => (
    <>
      <div className="content-header">
        <div>
          <h2>Commandes de stock</h2>
          <p>
            Capacité : {storageUsed} / {storageCapacity}
          </p>
        </div>
        <Button size="sm" variant="primary" disabled={saving || !cartLines.length} onClick={() => void createStockOrder()}>
          Commander {cartTotalCost > 0 ? formatMoney(cartTotalCost) : ''}
        </Button>
      </div>

      <div className="chip-row">
        {(['instant', 'self', 'public'] as DeliveryMethod[]).map((m) => (
          <button
            key={m}
            type="button"
            className={`chip ${orderMethod === m ? 'active' : ''}`}
            onClick={() => setOrderMethod(m)}
          >
            {METHOD_LABELS[m]}
          </button>
        ))}
      </div>

      {cartLines.length > 0 ? (
        <div className="card" style={{ marginBottom: 12 }}>
          <strong>Panier ({cartTotalQty} unités)</strong>
          {cartLines.map((l) => (
            <div key={l.product.id} className="cart-line">
              <span>
                {l.product.label} × {l.quantity}
              </span>
              <span className="money">{formatMoney(l.product.wholesale_price * l.quantity)}</span>
            </div>
          ))}
        </div>
      ) : null}

      <div className="product-grid">
        {shop.products.map((p) => {
          const qty = orderCart[p.id!] ?? 0;
          return (
            <div key={p.id} className="product-card">
              <div style={{ fontWeight: 600 }}>{p.label}</div>
              <div className="muted">Gros : {formatMoney(p.wholesale_price)}</div>
              <div className="qty-row">
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={() =>
                    setOrderCart((c) => ({ ...c, [p.id!]: Math.max(0, (c[p.id!] ?? 0) - 1) }))
                  }
                >
                  −
                </Button>
                <input
                  className="input"
                  type="number"
                  min={0}
                  value={qty}
                  onChange={(e) =>
                    setOrderCart((c) => ({ ...c, [p.id!]: Math.max(0, Number(e.target.value)) }))
                  }
                />
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={() => setOrderCart((c) => ({ ...c, [p.id!]: (c[p.id!] ?? 0) + 1 }))}
                >
                  +
                </Button>
              </div>
            </div>
          );
        })}
      </div>
    </>
  );

  const renderOrders = () => (
    <>
      <div className="content-header">
        <div>
          <h2>Commandes</h2>
          <p>Historique des approvisionnements</p>
        </div>
      </div>
      {management.stock_orders.length === 0 ? (
        <EmptyState title="Aucune commande" icon={<Truck size={28} color="#6b7280" />} />
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>#</th>
              <th>Date</th>
              <th>Méthode</th>
              <th>Statut</th>
              <th>Total</th>
              <th>Articles</th>
            </tr>
          </thead>
          <tbody>
            {management.stock_orders.map((order) => (
              <tr key={order.id}>
                <td>{order.id}</td>
                <td className="muted">{formatDate(order.created_at)}</td>
                <td>{METHOD_LABELS[order.method]}</td>
                <td>
                  <Badge tone={order.status === 'pending' ? 'amber' : order.status === 'delivered' ? 'green' : 'gray'}>
                    {ORDER_STATUS_LABELS[order.status]}
                  </Badge>
                </td>
                <td className="money">{formatMoney(order.total_cost)}</td>
                <td>
                  {order.items.map((i) => (
                    <div key={`${order.id}-${i.product_id}`} className="muted">
                      {i.label ?? i.item_name} × {i.quantity}
                    </div>
                  ))}
                  {order.ordered_by_name ? (
                    <div className="muted">Par {order.ordered_by_name}</div>
                  ) : null}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </>
  );

  const renderStorage = () => (
    <>
      <div className="content-header">
        <div>
          <h2>Stockage</h2>
          <p>
            {management.storage_used} / {shop.storage_capacity} unités utilisées
          </p>
        </div>
      </div>
      <EmptyState
        title="Inventaire du commerce"
        description="Ouvrez le stockage pour déposer ou retirer des articles physiquement."
        action={
          <Button variant="primary" onClick={() => void openStorage()}>
            <Warehouse size={16} /> Ouvrir le stockage
          </Button>
        }
      />
    </>
  );

  const renderEmployees = () => (
    <>
      <div className="content-header">
        <div>
          <h2>Employés</h2>
          <p>{management.employees.length} membre(s)</p>
        </div>
      </div>

      {can(perms, isOwner, 'manage_employees') ? (
        <div className="card" style={{ marginBottom: 14 }}>
          <h3 style={{ margin: '0 0 10px', fontSize: '0.95rem' }}>Recruter</h3>
          <div className="field-row">
            <Field label="Citizen ID">
              <Input
                value={hireForm.citizenid}
                onChange={(e) => setHireForm((f) => ({ ...f, citizenid: e.target.value }))}
                placeholder="ABC12345"
              />
            </Field>
            <Field label="Nom">
              <Input
                value={hireForm.name}
                onChange={(e) => setHireForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="Prénom Nom"
              />
            </Field>
          </div>
          <Button variant="primary" size="sm" disabled={saving} onClick={() => void hireEmployee()}>
            <Plus size={14} /> Recruter
          </Button>
        </div>
      ) : null}

      {management.employees.length === 0 ? (
        <EmptyState title="Aucun employé" />
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Citizen ID</th>
              <th>Statut</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {management.employees.map((emp) => (
              <tr key={emp.id}>
                <td>{emp.name}</td>
                <td className="muted">{emp.citizenid}</td>
                <td>
                  <Badge tone={emp.active ? 'green' : 'gray'}>{emp.active ? 'Actif' : 'Inactif'}</Badge>
                </td>
                <td>
                  <div className="inline-actions">
                    {can(perms, isOwner, 'manage_permissions') ? (
                      <Button
                        size="sm"
                        variant="secondary"
                        onClick={() => {
                          setPermEmployee(emp);
                          setPermDraft({ ...emp.permissions });
                        }}
                      >
                        Permissions
                      </Button>
                    ) : null}
                    {can(perms, isOwner, 'manage_employees') ? (
                      <Button size="sm" variant="danger" onClick={() => void fireEmployee(emp.id)}>
                        Licencier
                      </Button>
                    ) : null}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </>
  );

  const renderCustomization = () => (
    <>
      <div className="content-header">
        <div>
          <h2>Personnalisation</h2>
          <p>Identité visuelle de la boutique</p>
        </div>
        <Button size="sm" variant="primary" disabled={saving} onClick={() => void saveCustomization()}>
          <Save size={14} /> Enregistrer
        </Button>
      </div>

      {can(perms, isOwner, 'customize_storefront') ? (
        <>
          <Field label="Nom du commerce">
            <Input value={customName} onChange={(e) => setCustomName(e.target.value)} />
          </Field>
          <Field label="Description">
            <Textarea value={customDescription} onChange={(e) => setCustomDescription(e.target.value)} />
          </Field>
          <Field label="URL du logo">
            <Input value={customLogo} onChange={(e) => setCustomLogo(e.target.value)} placeholder="https://…" />
          </Field>
          {customLogo ? (
            <img className="shop-logo" src={customLogo} alt="" style={{ marginBottom: 12 }} />
          ) : null}
        </>
      ) : null}

      {isOwner && shop.resale_enabled ? (
        <>
          <div className="divider" />
          <div className="card">
            <h3 style={{ margin: '0 0 8px', fontSize: '0.95rem' }}>Revendre le commerce</h3>
            <p className="muted" style={{ margin: '0 0 12px' }}>
              Remboursement estimé : {formatMoney(Math.floor(shop.buy_price * (shop.resale_percent / 100)))}
            </p>
            <Button variant="danger" onClick={() => setSellConfirm(true)}>
              Vendre le commerce
            </Button>
          </div>
        </>
      ) : null}
    </>
  );

  const renderContent = () => {
    switch (nav) {
      case 'dashboard':
        return renderDashboard();
      case 'categories':
        return renderCategories();
      case 'products':
        return renderProducts();
      case 'stock_orders':
        return renderStockOrders();
      case 'orders':
        return renderOrders();
      case 'storage':
        return renderStorage();
      case 'employees':
        return renderEmployees();
      case 'customization':
        return renderCustomization();
      default:
        return null;
    }
  };

  return (
    <>
      <PanelShell
        title={shop.name}
        subtitle="Gestion du commerce"
        onClose={() => void closeUi()}
        actions={
          shop.logo_url ? (
            <img className="shop-logo" src={shop.logo_url} alt="" style={{ width: 32, height: 32 }} />
          ) : null
        }
      >
        <div className="layout">
          <aside className="sidebar">
            <div className="sidebar-section">Navigation</div>
            {visibleNav.map((item) => (
              <NavItem
                key={item.id}
                active={nav === item.id}
                icon={item.icon}
                label={item.label}
                onClick={() => setNav(item.id)}
              />
            ))}
          </aside>
          <main className="content">{loading ? <LoadingState /> : renderContent()}</main>
        </div>
      </PanelShell>

      <Modal
        open={!!permEmployee && !!permDraft}
        title={`Permissions — ${permEmployee?.name ?? ''}`}
        onClose={() => {
          setPermEmployee(null);
          setPermDraft(null);
        }}
        wide
        footer={
          <>
            <Button
              variant="ghost"
              onClick={() => {
                setPermEmployee(null);
                setPermDraft(null);
              }}
            >
              Annuler
            </Button>
            <Button variant="primary" disabled={saving} onClick={() => void savePermissions()}>
              Enregistrer
            </Button>
          </>
        }
      >
        {permDraft
          ? PERMISSION_GROUPS.map((group) => (
              <div key={group.id} style={{ marginBottom: 14 }}>
                <div className="sidebar-section" style={{ paddingLeft: 0 }}>
                  {group.label}
                </div>
                {group.keys.map((key) => (
                  <Toggle
                    key={key}
                    checked={permDraft[key]}
                    onChange={(v) => setPermDraft((d) => (d ? { ...d, [key]: v } : d))}
                    label={PERMISSION_LABELS[key]}
                  />
                ))}
              </div>
            ))
          : null}
      </Modal>

      <ConfirmDialog
        open={sellConfirm}
        title="Revendre le commerce"
        message="Cette action est irréversible. Vous perdrez la propriété du commerce."
        confirmLabel="Confirmer la vente"
        danger
        loading={selling}
        onConfirm={() => void confirmSell()}
        onCancel={() => setSellConfirm(false)}
      />
    </>
  );
}

function RefreshIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M21 12a9 9 0 1 1-2.64-6.36" />
      <path d="M21 3v6h-6" />
    </svg>
  );
}
