export type AppMode = 'admin' | 'storefront' | 'management' | 'deliveries';

export type OwnershipMode = 'none' | 'purchasable' | 'owned';
export type DeliveryMethod = 'instant' | 'self' | 'public';
export type OrderStatus = 'pending' | 'accepted' | 'in_transit' | 'delivered' | 'cancelled';
export type JobStatus = 'open' | 'accepted' | 'completed' | 'cancelled';
export type TransactionType =
  | 'sale'
  | 'deposit'
  | 'withdrawal'
  | 'ownership'
  | 'stock_order'
  | 'delivery_payout'
  | 'shop_change'
  | 'refund';

export type LocationType =
  | 'customer'
  | 'management'
  | 'storage'
  | 'delivery'
  | 'garage'
  | 'vehicle_spawn'
  | 'vehicle_return';

export type PermissionKey =
  | 'open_business'
  | 'control_status'
  | 'view_balance'
  | 'deposit_funds'
  | 'withdraw_funds'
  | 'view_activity'
  | 'manage_products'
  | 'deposit_stock'
  | 'withdraw_stock'
  | 'create_stock_orders'
  | 'collect_stock_orders'
  | 'publish_delivery_jobs'
  | 'automatic_delivery'
  | 'upgrade_storage'
  | 'manage_employees'
  | 'manage_permissions'
  | 'use_garage'
  | 'customize_storefront';

export type EmployeePermissions = Record<PermissionKey, boolean>;

export interface Vec4 {
  x: number;
  y: number;
  z: number;
  w: number;
}

export interface ShopLocation {
  id?: number;
  location_type: LocationType;
  label?: string | null;
  x: number;
  y: number;
  z: number;
  w: number;
}

export interface ShopCategory {
  id?: number;
  tempId?: string;
  label: string;
  icon: string;
  sort_order: number;
  enabled: boolean;
}

export interface ShopProduct {
  id?: number;
  tempId?: string;
  category_id?: number | null;
  categoryTempId?: string | null;
  item_name: string;
  label: string;
  image?: string | null;
  price: number;
  wholesale_price: number;
  stock: number;
  max_stock: number;
  enabled: boolean;
  sort_order: number;
}

export interface BusinessVehicle {
  id?: number;
  tempId?: string;
  model: string;
  label: string;
  enabled: boolean;
}

export interface ShopBlip {
  enabled: boolean;
  sprite: number;
  color: number;
  scale: number;
  name: string;
}

export interface ShopNpc {
  enabled: boolean;
  model: string;
  scenario: string;
  x?: number | null;
  y?: number | null;
  z?: number | null;
  w?: number | null;
}

export interface Shop {
  id: number;
  slug: string;
  name: string;
  description: string;
  logo_url: string;
  enabled: boolean;
  infinite_stock: boolean;
  default_stock: number;
  storage_capacity: number;
  auto_hours: boolean;
  open_hour: number;
  close_hour: number;
  is_open: boolean;
  ownership_mode: OwnershipMode;
  owner_citizenid: string | null;
  buy_price: number;
  resale_enabled: boolean;
  resale_percent: number;
  balance: number;
  allow_cash: boolean;
  allow_bank: boolean;
  blip: ShopBlip;
  npc: ShopNpc;
  locations: ShopLocation[];
  categories: ShopCategory[];
  products: ShopProduct[];
  vehicles: BusinessVehicle[];
  employee_count?: number;
  product_count?: number;
  low_stock_count?: number;
  pending_orders?: number;
}

export interface ShopSummary {
  id: number;
  slug: string;
  name: string;
  description: string;
  logo_url: string;
  enabled: boolean;
  is_open: boolean;
  ownership_mode: OwnershipMode;
  buy_price: number;
  product_count: number;
  employee_count: number;
}

export interface InventoryItem {
  name: string;
  label: string;
  image?: string;
  weight?: number;
}

export interface AdminEntry {
  id: number;
  identifier: string;
  label: string;
}

export interface AppSettings {
  low_stock_threshold: number;
  max_categories: number;
  max_products: number;
  max_employees: number;
  default_capacity: number;
  instant_delivery: boolean;
  self_delivery: boolean;
  public_delivery: boolean;
  public_reward_percent: number;
  allow_cash_default: boolean;
  allow_bank_default: boolean;
}

export interface CartLine {
  product_id: number;
  item_name: string;
  label: string;
  price: number;
  quantity: number;
  max_stock: number;
  stock: number;
  image?: string | null;
}

export interface Employee {
  id: number;
  citizenid: string;
  name: string;
  permissions: EmployeePermissions;
  active: boolean;
  hired_at?: string;
}

export interface Transaction {
  id: number;
  tx_type: TransactionType;
  amount: number;
  citizenid?: string | null;
  player_name?: string | null;
  description: string;
  created_at: string;
}

export interface StockOrderItem {
  product_id: number;
  item_name: string;
  label?: string;
  quantity: number;
  unit_cost: number;
}

export interface StockOrder {
  id: number;
  method: DeliveryMethod;
  status: OrderStatus;
  total_cost: number;
  ordered_by_name?: string;
  created_at: string;
  items: StockOrderItem[];
}

export interface DeliveryJob {
  id: number;
  shop_id: number;
  shop_name: string;
  item_count: number;
  reward: number;
  origin_label: string;
  dest_label: string;
  status: JobStatus;
}

export interface ManagementData {
  shop: Shop;
  employees: Employee[];
  transactions: Transaction[];
  stock_orders: StockOrder[];
  permissions: EmployeePermissions;
  storage_used: number;
  is_owner: boolean;
}

export interface NuiOk<T = unknown> {
  ok: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface SetVisiblePayload {
  visible: boolean;
  mode?: AppMode;
  shopId?: number;
  shop?: Shop;
  management?: ManagementData;
}

export const DEFAULT_PERMISSIONS: EmployeePermissions = {
  open_business: false,
  control_status: false,
  view_balance: false,
  deposit_funds: false,
  withdraw_funds: false,
  view_activity: false,
  manage_products: false,
  deposit_stock: false,
  withdraw_stock: false,
  create_stock_orders: false,
  collect_stock_orders: false,
  publish_delivery_jobs: false,
  automatic_delivery: false,
  upgrade_storage: false,
  manage_employees: false,
  manage_permissions: false,
  use_garage: false,
  customize_storefront: false,
};

export const PERMISSION_GROUPS: { id: string; label: string; keys: PermissionKey[] }[] = [
  {
    id: 'dashboard',
    label: 'Tableau de bord & fonds',
    keys: [
      'open_business',
      'control_status',
      'view_balance',
      'deposit_funds',
      'withdraw_funds',
      'view_activity',
    ],
  },
  {
    id: 'products',
    label: 'Produits & stock',
    keys: [
      'manage_products',
      'deposit_stock',
      'withdraw_stock',
      'create_stock_orders',
      'collect_stock_orders',
      'publish_delivery_jobs',
      'automatic_delivery',
      'upgrade_storage',
    ],
  },
  {
    id: 'team',
    label: 'Équipe & opérations',
    keys: ['manage_employees', 'manage_permissions', 'use_garage', 'customize_storefront'],
  },
];

export const PERMISSION_LABELS: Record<PermissionKey, string> = {
  open_business: 'Ouvrir le commerce',
  control_status: 'Contrôler le statut',
  view_balance: 'Voir le solde',
  deposit_funds: 'Déposer des fonds',
  withdraw_funds: 'Retirer des fonds',
  view_activity: 'Voir l’activité',
  manage_products: 'Gérer les produits',
  deposit_stock: 'Déposer du stock',
  withdraw_stock: 'Retirer du stock',
  create_stock_orders: 'Créer des commandes',
  collect_stock_orders: 'Récupérer les commandes',
  publish_delivery_jobs: 'Publier des livraisons',
  automatic_delivery: 'Livraison automatique',
  upgrade_storage: 'Améliorer le stockage',
  manage_employees: 'Gérer les employés',
  manage_permissions: 'Gérer les permissions',
  use_garage: 'Utiliser le garage',
  customize_storefront: 'Personnaliser la vitrine',
};

export const LOCATION_LABELS: Record<LocationType, string> = {
  customer: 'Point client',
  management: 'Gestion',
  storage: 'Stockage',
  delivery: 'Livraison',
  garage: 'Garage',
  vehicle_spawn: 'Spawn véhicule',
  vehicle_return: 'Retour véhicule',
};

export function emptyShop(partial?: Partial<Shop>): Shop {
  return {
    id: 0,
    slug: '',
    name: '',
    description: '',
    logo_url: '',
    enabled: true,
    infinite_stock: false,
    default_stock: 0,
    storage_capacity: 500,
    auto_hours: false,
    open_hour: 8,
    close_hour: 22,
    is_open: true,
    ownership_mode: 'none',
    owner_citizenid: null,
    buy_price: 50000,
    resale_enabled: false,
    resale_percent: 70,
    balance: 0,
    allow_cash: true,
    allow_bank: true,
    blip: { enabled: true, sprite: 52, color: 2, scale: 0.75, name: '' },
    npc: { enabled: false, model: 'mp_m_shopkeep_01', scenario: 'WORLD_HUMAN_STAND_IMPATIENT' },
    locations: [],
    categories: [],
    products: [],
    vehicles: [],
    ...partial,
  };
}
