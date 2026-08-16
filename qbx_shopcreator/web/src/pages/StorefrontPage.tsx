import { useMemo, useState } from 'react';
import { CreditCard, Minus, Plus, ShoppingBag, Wallet } from 'lucide-react';
import { Badge } from '../components/Badge';
import { Button } from '../components/Button';
import { PanelShell, NavItem } from '../components/Panel';
import { EmptyState } from '../components/States';
import { fetchNuiResult } from '../lib/nui';
import { formatMoney, stockLabel, stockTone } from '../lib/utils';
import { useAppStore } from '../stores/appStore';
import type { CartLine, ShopProduct } from '../types';

export function StorefrontPage() {
  const { shop, closeUi, pushToast } = useAppStore();
  const [categoryId, setCategoryId] = useState<number | 'all'>('all');
  const [cart, setCart] = useState<CartLine[]>([]);
  const [payment, setPayment] = useState<'cash' | 'bank'>('cash');
  const [qtyDraft, setQtyDraft] = useState<Record<number, number>>({});
  const [checkingOut, setCheckingOut] = useState(false);

  const total = useMemo(() => cart.reduce((s, l) => s + l.price * l.quantity, 0), [cart]);

  if (!shop) {
    return (
      <PanelShell title="Boutique" onClose={() => void closeUi()} size="compact">
        <EmptyState title="Magasin indisponible" description="Aucune donnée magasin reçue." />
      </PanelShell>
    );
  }

  const categories = shop.categories.filter((c) => c.enabled);
  const products = shop.products.filter((p) => {
    if (!p.enabled) return false;
    if (categoryId === 'all') return true;
    return p.category_id === categoryId;
  });

  const addToCart = (product: ShopProduct) => {
    const qty = Math.max(1, qtyDraft[product.id!] ?? 1);
    if (!shop.infinite_stock && product.stock <= 0) {
      pushToast('error', 'Rupture de stock');
      return;
    }
    if (!shop.infinite_stock && qty > product.stock) {
      pushToast('error', 'Quantité supérieure au stock');
      return;
    }
    setCart((prev) => {
      const existing = prev.find((l) => l.product_id === product.id);
      if (existing) {
        const nextQty = existing.quantity + qty;
        if (!shop.infinite_stock && nextQty > product.stock) {
          pushToast('error', 'Stock insuffisant');
          return prev;
        }
        return prev.map((l) => (l.product_id === product.id ? { ...l, quantity: nextQty } : l));
      }
      return [
        ...prev,
        {
          product_id: product.id!,
          item_name: product.item_name,
          label: product.label,
          price: product.price,
          quantity: qty,
          max_stock: product.max_stock,
          stock: product.stock,
          image: product.image,
        },
      ];
    });
  };

  const updateQty = (productId: number, quantity: number) => {
    setCart((prev) =>
      prev
        .map((l) => (l.product_id === productId ? { ...l, quantity: Math.max(0, quantity) } : l))
        .filter((l) => l.quantity > 0),
    );
  };

  const checkout = async () => {
    if (!cart.length) return;
    if (payment === 'cash' && !shop.allow_cash) {
      pushToast('error', 'Espèces non acceptées');
      return;
    }
    if (payment === 'bank' && !shop.allow_bank) {
      pushToast('error', 'Banque non acceptée');
      return;
    }
    setCheckingOut(true);
    const res = await fetchNuiResult('purchase', {
      shopId: shop.id,
      payment,
      cart: cart.map((l) => ({ product_id: l.product_id, quantity: l.quantity })),
    });
    setCheckingOut(false);
    if (!res.ok) {
      pushToast('error', res.error ?? 'Achat impossible');
      return;
    }
    pushToast('success', res.message ?? 'Achat effectué');
    setCart([]);
  };

  const defaultPayment =
    shop.allow_cash ? 'cash' : shop.allow_bank ? 'bank' : 'cash';
  if (payment === 'cash' && !shop.allow_cash && shop.allow_bank && payment !== defaultPayment) {
    /* keep state controlled below */
  }

  return (
    <PanelShell
      title={shop.name}
      subtitle="Boutique"
      onClose={() => void closeUi()}
      actions={
        shop.ownership_mode === 'purchasable' ? (
          <Button
            variant="primary"
            size="sm"
            onClick={async () => {
              const res = await fetchNuiResult('buyShop', { shopId: shop.id });
              if (!res.ok) return pushToast('error', res.error ?? 'Achat impossible');
              pushToast('success', res.message ?? 'Commerce acheté');
            }}
          >
            Acheter {formatMoney(shop.buy_price)}
          </Button>
        ) : null
      }
    >
      <div className="layout storefront">
        <aside className="sidebar">
          <div style={{ display: 'flex', gap: 10, alignItems: 'center', padding: '4px 8px 12px' }}>
            {shop.logo_url ? (
              <img className="shop-logo" src={shop.logo_url} alt="" />
            ) : (
              <div className="shop-logo fallback">{shop.name.slice(0, 2).toUpperCase()}</div>
            )}
            <div style={{ minWidth: 0 }}>
              <div style={{ fontWeight: 650, fontSize: '0.9rem' }}>{shop.name}</div>
              <Badge tone={shop.is_open ? 'green' : 'red'}>{shop.is_open ? 'Ouvert' : 'Fermé'}</Badge>
            </div>
          </div>
          <div className="sidebar-section">Catégories</div>
          <NavItem
            active={categoryId === 'all'}
            icon={<ShoppingBag size={15} />}
            label="Tous"
            onClick={() => setCategoryId('all')}
          />
          {categories.map((c) => (
            <NavItem
              key={c.id}
              active={categoryId === c.id}
              icon={<PackageIcon />}
              label={c.label}
              onClick={() => setCategoryId(c.id!)}
            />
          ))}
        </aside>

        <main className="content">
          {!shop.is_open ? (
            <EmptyState title="Commerce fermé" description="Revenez pendant les heures d'ouverture." />
          ) : products.length === 0 ? (
            <EmptyState title="Aucun produit" description="Cette catégorie est vide." />
          ) : (
            <div className="product-grid">
              {products.map((p) => (
                <div key={p.id} className="product-card">
                  <div className="thumb">
                    {p.image ? <img src={p.image} alt="" /> : <ShoppingBag size={22} />}
                  </div>
                  <div style={{ fontWeight: 600 }}>{p.label}</div>
                  <div className="price">{formatMoney(p.price)}</div>
                  <Badge tone={stockTone(p.stock, shop.infinite_stock)}>
                    {stockLabel(p.stock, shop.infinite_stock)}
                    {!shop.infinite_stock ? ` · ${p.stock}` : ''}
                  </Badge>
                  <div className="qty-row">
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() =>
                        setQtyDraft((d) => ({ ...d, [p.id!]: Math.max(1, (d[p.id!] ?? 1) - 1) }))
                      }
                    >
                      <Minus size={14} />
                    </Button>
                    <input
                      className="input"
                      type="number"
                      min={1}
                      value={qtyDraft[p.id!] ?? 1}
                      onChange={(e) => setQtyDraft((d) => ({ ...d, [p.id!]: Number(e.target.value) }))}
                    />
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => setQtyDraft((d) => ({ ...d, [p.id!]: (d[p.id!] ?? 1) + 1 }))}
                    >
                      <Plus size={14} />
                    </Button>
                  </div>
                  <Button
                    variant="primary"
                    size="sm"
                    disabled={!shop.infinite_stock && p.stock <= 0}
                    onClick={() => addToCart(p)}
                  >
                    Ajouter
                  </Button>
                </div>
              ))}
            </div>
          )}
        </main>

        <aside className="cart-panel">
          <h2 style={{ margin: '0 0 12px', fontFamily: 'var(--font-display)', fontSize: '1.05rem' }}>Panier</h2>
          {cart.length === 0 ? (
            <p className="muted">Votre panier est vide.</p>
          ) : (
            cart.map((line) => (
              <div key={line.product_id} className="cart-line">
                <div>
                  <div>{line.label}</div>
                  <div className="muted">
                    {formatMoney(line.price)} × {line.quantity}
                  </div>
                </div>
                <div className="qty-row">
                  <Button size="icon" variant="ghost" onClick={() => updateQty(line.product_id, line.quantity - 1)}>
                    <Minus size={12} />
                  </Button>
                  <span>{line.quantity}</span>
                  <Button size="icon" variant="ghost" onClick={() => updateQty(line.product_id, line.quantity + 1)}>
                    <Plus size={12} />
                  </Button>
                </div>
              </div>
            ))
          )}
          <div className="divider" />
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
            <span className="muted">Total</span>
            <strong className="money">{formatMoney(total)}</strong>
          </div>
          <div className="chip-row">
            {shop.allow_cash ? (
              <button
                type="button"
                className={`chip ${payment === 'cash' ? 'active' : ''}`}
                onClick={() => setPayment('cash')}
              >
                <Wallet size={12} /> Espèces
              </button>
            ) : null}
            {shop.allow_bank ? (
              <button
                type="button"
                className={`chip ${payment === 'bank' ? 'active' : ''}`}
                onClick={() => setPayment('bank')}
              >
                <CreditCard size={12} /> Banque
              </button>
            ) : null}
          </div>
          <Button variant="primary" disabled={!cart.length || checkingOut} onClick={() => void checkout()}>
            {checkingOut ? 'Paiement…' : 'Payer'}
          </Button>
        </aside>
      </div>
    </PanelShell>
  );
}

function PackageIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
    </svg>
  );
}
