import {
  DEFAULT_PERMISSIONS,
  emptyShop,
  type AdminEntry,
  type AppSettings,
  type DeliveryJob,
  type Employee,
  type InventoryItem,
  type ManagementData,
  type NuiOk,
  type Shop,
  type ShopSummary,
  type StockOrder,
  type Transaction,
} from '../types';

let shops: Shop[] = [
  {
    ...emptyShop({
      id: 1,
      slug: 'ltd-grove',
      name: 'LTD Grove Street',
      description: 'Épicerie de quartier ouverte 24/7.',
      logo_url: 'https://i.imgur.com/8Km9tLL.png',
      ownership_mode: 'owned',
      owner_citizenid: 'ABC12345',
      buy_price: 75000,
      balance: 12450,
      is_open: true,
      resale_enabled: true,
      resale_percent: 70,
      employee_count: 3,
      product_count: 4,
      low_stock_count: 1,
      pending_orders: 1,
    }),
    categories: [
      { id: 1, label: 'Nourriture', icon: 'utensils', sort_order: 0, enabled: true },
      { id: 2, label: 'Boissons', icon: 'cup-soda', sort_order: 1, enabled: true },
    ],
    products: [
      {
        id: 1,
        category_id: 1,
        item_name: 'sandwich',
        label: 'Sandwich',
        price: 45,
        wholesale_price: 20,
        stock: 24,
        max_stock: 50,
        enabled: true,
        sort_order: 0,
      },
      {
        id: 2,
        category_id: 2,
        item_name: 'water',
        label: 'Eau',
        price: 15,
        wholesale_price: 5,
        stock: 3,
        max_stock: 100,
        enabled: true,
        sort_order: 1,
      },
      {
        id: 3,
        category_id: 2,
        item_name: 'cola',
        label: 'Cola',
        price: 25,
        wholesale_price: 10,
        stock: 0,
        max_stock: 80,
        enabled: true,
        sort_order: 2,
      },
      {
        id: 4,
        category_id: 1,
        item_name: 'chips',
        label: 'Chips',
        price: 30,
        wholesale_price: 12,
        stock: 18,
        max_stock: 60,
        enabled: true,
        sort_order: 3,
      },
    ],
    locations: [
      { id: 1, location_type: 'customer', label: 'Entrée', x: 25.7, y: -1347.3, z: 29.5, w: 270 },
      { id: 2, location_type: 'management', label: 'Bureau', x: 28.2, y: -1339.1, z: 29.5, w: 180 },
      { id: 3, location_type: 'storage', label: 'Réserve', x: 30.1, y: -1338.0, z: 29.5, w: 0 },
    ],
    vehicles: [{ id: 1, model: 'boxville2', label: 'Camionette', enabled: true }],
  },
  {
    ...emptyShop({
      id: 2,
      slug: '247-paleto',
      name: '24/7 Paleto',
      description: 'Supérette Paleto Bay.',
      logo_url: '',
      ownership_mode: 'purchasable',
      buy_price: 95000,
      enabled: true,
      is_open: false,
      product_count: 0,
      employee_count: 0,
    }),
  },
];

let admins: AdminEntry[] = [
  { id: 1, identifier: 'license:abc123', label: 'Fondateur' },
  { id: 2, identifier: 'license:def456', label: 'Staff' },
];

let settings: AppSettings = {
  low_stock_threshold: 5,
  max_categories: 32,
  max_products: 250,
  max_employees: 40,
  default_capacity: 500,
  instant_delivery: true,
  self_delivery: true,
  public_delivery: true,
  public_reward_percent: 12,
  allow_cash_default: true,
  allow_bank_default: true,
};

const inventory: InventoryItem[] = [
  { name: 'sandwich', label: 'Sandwich' },
  { name: 'water', label: 'Eau' },
  { name: 'cola', label: 'Cola' },
  { name: 'chips', label: 'Chips' },
  { name: 'phone', label: 'Téléphone' },
  { name: 'radio', label: 'Radio' },
  { name: 'bandage', label: 'Bandage' },
  { name: 'lockpick', label: 'Lockpick' },
];

let nextShopId = 3;
let nextAdminId = 3;
let nextEmployeeId = 10;
let nextOrderId = 5;
let nextJobId = 3;
let nextTxId = 20;

interface ShopManagementState {
  employees: Employee[];
  transactions: Transaction[];
  stock_orders: StockOrder[];
}

const managementState: Record<number, ShopManagementState> = {
  1: {
    employees: [
      {
        id: 1,
        citizenid: 'ABC12345',
        name: 'Jean Dupont',
        permissions: { ...DEFAULT_PERMISSIONS, open_business: true, view_balance: true, manage_products: true },
        active: true,
        hired_at: '2026-01-10T12:00:00Z',
      },
      {
        id: 2,
        citizenid: 'XYZ98765',
        name: 'Marie Martin',
        permissions: { ...DEFAULT_PERMISSIONS, deposit_stock: true, create_stock_orders: true },
        active: true,
        hired_at: '2026-02-01T09:30:00Z',
      },
    ],
    transactions: [
      {
        id: 1,
        tx_type: 'sale',
        amount: 45,
        player_name: 'Client',
        description: 'Vente Sandwich x1',
        created_at: '2026-08-16T10:00:00Z',
      },
      {
        id: 2,
        tx_type: 'deposit',
        amount: 500,
        player_name: 'Jean Dupont',
        description: 'Dépôt compte entreprise',
        created_at: '2026-08-15T18:20:00Z',
      },
      {
        id: 3,
        tx_type: 'withdrawal',
        amount: -200,
        player_name: 'Jean Dupont',
        description: 'Retrait fonds',
        created_at: '2026-08-14T14:10:00Z',
      },
      {
        id: 4,
        tx_type: 'ownership',
        amount: -75000,
        player_name: 'Jean Dupont',
        description: 'Achat du commerce',
        created_at: '2026-01-05T08:00:00Z',
      },
      {
        id: 5,
        tx_type: 'shop_change',
        amount: 0,
        player_name: 'Admin',
        description: 'Mise à jour catégories',
        created_at: '2026-08-12T11:00:00Z',
      },
    ],
    stock_orders: [
      {
        id: 1,
        method: 'public',
        status: 'pending',
        total_cost: 200,
        ordered_by_name: 'Marie Martin',
        created_at: '2026-08-16T09:00:00Z',
        items: [{ product_id: 2, item_name: 'water', label: 'Eau', quantity: 40, unit_cost: 5 }],
      },
    ],
  },
};

function getMgmtState(shopId: number): ShopManagementState {
  if (!managementState[shopId]) {
    managementState[shopId] = { employees: [], transactions: [], stock_orders: [] };
  }
  return managementState[shopId];
}

function ok<T>(data?: T, message?: string): NuiOk<T> {
  return { ok: true, data, message };
}

function fail(error: string): NuiOk {
  return { ok: false, error };
}

function managementFor(shopId: number): ManagementData | null {
  const shop = shops.find((s) => s.id === shopId);
  if (!shop) return null;
  const state = getMgmtState(shopId);
  const storageUsed = shop.products.reduce((sum, p) => sum + p.stock, 0);
  return {
    shop: {
      ...shop,
      product_count: shop.products.length,
      employee_count: state.employees.length,
      low_stock_count: shop.products.filter((p) => p.stock > 0 && p.stock <= 5).length,
      pending_orders: state.stock_orders.filter((o) => o.status === 'pending').length,
    },
    employees: state.employees.map((e) => ({ ...e, permissions: { ...e.permissions } })),
    transactions: [...state.transactions],
    stock_orders: [...state.stock_orders],
    permissions: Object.fromEntries(Object.keys(DEFAULT_PERMISSIONS).map((k) => [k, true])) as ManagementData['permissions'],
    storage_used: storageUsed,
    is_owner: true,
  };
}

const deliveryJobs: DeliveryJob[] = [
  {
    id: 1,
    shop_id: 1,
    shop_name: 'LTD Grove Street',
    item_count: 40,
    reward: 350,
    origin_label: 'Entrepôt portuaire',
    dest_label: 'LTD Grove Street',
    status: 'open',
  },
  {
    id: 2,
    shop_id: 1,
    shop_name: 'LTD Grove Street',
    item_count: 12,
    reward: 180,
    origin_label: 'Entrepôt portuaire',
    dest_label: 'Réserve LTD',
    status: 'open',
  },
];

export async function mockNui<T>(eventName: string, data?: unknown): Promise<T> {
  await new Promise((r) => setTimeout(r, 120 + Math.random() * 180));
  const body = (data ?? {}) as Record<string, unknown>;

  switch (eventName) {
    case 'close':
      return ok() as T;

    case 'getShops': {
      const list: ShopSummary[] = shops.map((s) => ({
        id: s.id,
        slug: s.slug,
        name: s.name,
        description: s.description,
        logo_url: s.logo_url,
        enabled: s.enabled,
        is_open: s.is_open,
        ownership_mode: s.ownership_mode,
        buy_price: s.buy_price,
        product_count: s.products.length,
        employee_count: s.employee_count ?? 0,
      }));
      return ok(list) as T;
    }

    case 'getShop': {
      const shop = shops.find((s) => s.id === body.id || s.id === body.shopId);
      return (shop ? ok(shop) : fail('Magasin introuvable')) as T;
    }

    case 'saveShop': {
      const shop = body.shop as Shop;
      if (!shop?.name?.trim()) return fail('Nom requis') as T;
      if (shop.id && shops.some((s) => s.id === shop.id)) {
        shops = shops.map((s) => (s.id === shop.id ? { ...s, ...shop } : s));
        return ok(shops.find((s) => s.id === shop.id), 'Magasin enregistré') as T;
      }
      const created: Shop = {
        ...emptyShop(shop),
        id: nextShopId++,
        slug: shop.slug || shop.name.toLowerCase().replace(/\s+/g, '-').slice(0, 48),
      };
      shops = [...shops, created];
      return ok(created, 'Magasin créé') as T;
    }

    case 'deleteShop': {
      const id = Number(body.id ?? body.shopId);
      shops = shops.filter((s) => s.id !== id);
      return ok(null, 'Magasin supprimé') as T;
    }

    case 'getInventoryItems':
      return ok(inventory) as T;

    case 'getAdmins':
      return ok(admins) as T;

    case 'addAdmin': {
      const identifier = String(body.identifier ?? '');
      const label = String(body.label ?? '');
      if (!identifier) return fail('Identifiant requis') as T;
      if (admins.some((a) => a.identifier === identifier)) return fail('Déjà admin') as T;
      const entry = { id: nextAdminId++, identifier, label };
      admins = [...admins, entry];
      return ok(entry, 'Admin ajouté') as T;
    }

    case 'removeAdmin': {
      const id = Number(body.id);
      admins = admins.filter((a) => a.id !== id);
      return ok(null, 'Admin retiré') as T;
    }

    case 'getSettings':
      return ok(settings) as T;

    case 'saveSettings': {
      settings = { ...settings, ...(body as Partial<AppSettings>) };
      return ok(settings, 'Paramètres sauvegardés') as T;
    }

    case 'purchase': {
      const shopId = Number(body.shopId);
      const cart = (body.cart as { product_id: number; quantity: number }[]) ?? [];
      const shop = shops.find((s) => s.id === shopId);
      if (!shop) return fail('Magasin introuvable') as T;
      for (const line of cart) {
        const product = shop.products.find((p) => p.id === line.product_id);
        if (!product) return fail('Produit introuvable') as T;
        if (!shop.infinite_stock && product.stock < line.quantity) return fail('Stock insuffisant') as T;
        if (!shop.infinite_stock) product.stock -= line.quantity;
      }
      return ok(null, 'Achat effectué') as T;
    }

    case 'buyShop': {
      const shop = shops.find((s) => s.id === Number(body.shopId));
      if (!shop) return fail('Magasin introuvable') as T;
      shop.ownership_mode = 'owned';
      shop.owner_citizenid = String(body.citizenid ?? 'LOCALDEV');
      return ok(shop, 'Commerce acheté') as T;
    }

    case 'sellShop': {
      const shop = shops.find((s) => s.id === Number(body.shopId));
      if (!shop) return fail('Magasin introuvable') as T;
      shop.ownership_mode = 'purchasable';
      shop.owner_citizenid = null;
      return ok(shop, 'Commerce revendu') as T;
    }

    case 'getManagementData': {
      const data = managementFor(Number(body.shopId));
      return (data ? ok(data) : fail('Données indisponibles')) as T;
    }

    case 'updateShopStatus': {
      const shop = shops.find((s) => s.id === Number(body.shopId));
      if (!shop) return fail('Magasin introuvable') as T;
      if (typeof body.is_open === 'boolean') shop.is_open = body.is_open;
      if (typeof body.auto_hours === 'boolean') shop.auto_hours = body.auto_hours;
      return ok(shop, 'Statut mis à jour') as T;
    }

    case 'depositFunds': {
      const shop = shops.find((s) => s.id === Number(body.shopId));
      if (!shop) return fail('Magasin introuvable') as T;
      const amount = Number(body.amount ?? 0);
      if (amount <= 0) return fail('Montant invalide') as T;
      shop.balance += amount;
      const state = getMgmtState(shop.id);
      state.transactions.unshift({
        id: nextTxId++,
        tx_type: 'deposit',
        amount,
        player_name: 'Vous',
        description: 'Dépôt compte entreprise',
        created_at: new Date().toISOString(),
      });
      return ok({ balance: shop.balance }, 'Dépôt effectué') as T;
    }

    case 'withdrawFunds': {
      const shop = shops.find((s) => s.id === Number(body.shopId));
      if (!shop) return fail('Magasin introuvable') as T;
      const amount = Number(body.amount ?? 0);
      if (amount <= 0) return fail('Montant invalide') as T;
      if (shop.balance < amount) return fail('Fonds insuffisants') as T;
      shop.balance -= amount;
      const state = getMgmtState(shop.id);
      state.transactions.unshift({
        id: nextTxId++,
        tx_type: 'withdrawal',
        amount: -amount,
        player_name: 'Vous',
        description: 'Retrait fonds',
        created_at: new Date().toISOString(),
      });
      return ok({ balance: shop.balance }, 'Retrait effectué') as T;
    }

    case 'saveCategories': {
      const shop = shops.find((s) => s.id === Number(body.shopId));
      if (!shop) return fail('Magasin introuvable') as T;
      shop.categories = (body.categories as Shop['categories']) ?? shop.categories;
      return ok(shop.categories, 'Catégories sauvegardées') as T;
    }

    case 'saveProducts': {
      const shop = shops.find((s) => s.id === Number(body.shopId));
      if (!shop) return fail('Magasin introuvable') as T;
      shop.products = (body.products as Shop['products']) ?? shop.products;
      return ok(shop.products, 'Produits sauvegardés') as T;
    }

    case 'createStockOrder': {
      const shop = shops.find((s) => s.id === Number(body.shopId));
      if (!shop) return fail('Magasin introuvable') as T;
      const items = (body.items as { product_id: number; quantity: number }[]) ?? [];
      const method = String(body.method ?? 'instant') as StockOrder['method'];
      let total = 0;
      const orderItems: StockOrder['items'] = [];
      for (const line of items) {
        const p = shop.products.find((x) => x.id === line.product_id);
        if (!p) continue;
        total += p.wholesale_price * line.quantity;
        orderItems.push({
          product_id: p.id!,
          item_name: p.item_name,
          label: p.label,
          quantity: line.quantity,
          unit_cost: p.wholesale_price,
        });
        if (method === 'instant') p.stock = Math.min(p.max_stock, p.stock + line.quantity);
      }
      if (shop.balance < total) return fail('Fonds insuffisants') as T;
      shop.balance -= total;
      const orderId = nextOrderId++;
      const state = getMgmtState(shop.id);
      state.stock_orders.unshift({
        id: orderId,
        method,
        status: method === 'instant' ? 'delivered' : 'pending',
        total_cost: total,
        ordered_by_name: 'Vous',
        created_at: new Date().toISOString(),
        items: orderItems,
      });
      state.transactions.unshift({
        id: nextTxId++,
        tx_type: 'stock_order',
        amount: -total,
        player_name: 'Vous',
        description: `Commande stock #${orderId}`,
        created_at: new Date().toISOString(),
      });
      return ok({ id: orderId, total_cost: total }, 'Commande créée') as T;
    }

    case 'hireEmployee': {
      const shopId = Number(body.shopId);
      const state = getMgmtState(shopId);
      const employee: Employee = {
        id: nextEmployeeId++,
        citizenid: String(body.citizenid),
        name: String(body.name ?? 'Employé'),
        permissions: { ...DEFAULT_PERMISSIONS },
        active: true,
        hired_at: new Date().toISOString(),
      };
      state.employees.push(employee);
      return ok(employee, 'Employé recruté') as T;
    }

    case 'fireEmployee': {
      const shopId = Number(body.shopId);
      const employeeId = Number(body.employeeId ?? body.id);
      const state = getMgmtState(shopId);
      state.employees = state.employees.filter((e) => e.id !== employeeId);
      return ok(null, 'Employé licencié') as T;
    }

    case 'updateEmployeePermissions': {
      const shopId = Number(body.shopId);
      const employeeId = Number(body.employeeId ?? body.id);
      const permissions = body.permissions as Employee['permissions'];
      const state = getMgmtState(shopId);
      const idx = state.employees.findIndex((e) => e.id === employeeId);
      if (idx >= 0) state.employees[idx] = { ...state.employees[idx], permissions: { ...permissions } };
      return ok(permissions, 'Permissions mises à jour') as T;
    }

    case 'getDeliveryJobs':
    case 'listDeliveryJobs':
      return ok(deliveryJobs.filter((j) => j.status === 'open')) as T;

    case 'acceptDelivery': {
      const job = deliveryJobs.find((j) => j.id === Number(body.jobId ?? body.id));
      if (!job) return fail('Mission introuvable') as T;
      job.status = 'accepted';
      return ok(job, 'Mission acceptée') as T;
    }

    case 'openStorage':
      return ok(null) as T;

    case 'spawnBusinessVehicle':
      return ok(null, 'Véhicule sorti') as T;

    case 'storeBusinessVehicle':
      return ok(null, 'Véhicule rangé') as T;

    case 'requestPosition':
      return ok({ x: 25.7, y: -1347.3, z: 29.5, w: 270 }) as T;

    case 'useCurrentPosition':
      return ok({
        x: 100 + Math.random() * 10,
        y: -1300 + Math.random() * 20,
        z: 29.5,
        w: Math.floor(Math.random() * 360),
      }) as T;

    default:
      console.warn('[mockNui] unhandled', eventName, data);
      return ok(null) as T;
  }
}
