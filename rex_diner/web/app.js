(() => {
    const app = document.getElementById('app');
    const content = document.getElementById('content');
    const modal = document.getElementById('modal');
    const modalCard = document.getElementById('modal-card');

    const state = {
        open: false,
        page: 'dashboard',
        data: null,
        cart: [],
        discount: false,
        discountPercent: 10,
        salesFilter: 'today',
        clockTimer: null,
    };

    const resourceName = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'rex_diner';

    async function nui(event, data = {}) {
        try {
            const resp = await fetch(`https://${resourceName}/${event}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data),
            });
            return await resp.json();
        } catch (e) {
            console.error(event, e);
            return null;
        }
    }

    function money(amount) {
        const n = Math.floor(Number(amount) || 0);
        const cur = state.data?.currency || '$';
        return `${n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} ${cur}`;
    }

    function formatSeconds(sec) {
        sec = Math.max(0, Math.floor(Number(sec) || 0));
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        return `${String(h).padStart(2, '0')}h${String(m).padStart(2, '0')}`;
    }

    function nowParts() {
        const d = new Date();
        const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
        const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
        const time = d.toLocaleTimeString('fr-FR', { hour12: false });
        const date = `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`;
        const stamp = `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()} ${time}`;
        return { time, date, stamp };
    }

    function can(perm) {
        if (!perm) return true;
        return !!(state.data?.permissions?.[perm]);
    }

    function feature(name) {
        return state.data?.features?.[name] !== false;
    }

    function setHeader() {
        const p = state.data?.player || {};
        document.getElementById('user-avatar').textContent = p.avatar || 'R';
        document.getElementById('user-name').textContent = p.name || 'Employé';
        document.getElementById('user-grade').textContent = p.gradeLabel || 'Grade';
        document.getElementById('footer-brand').textContent =
            `${(state.data?.restaurant?.label || 'REX DINER').toUpperCase()} — GESTION RESTAURANT`;

        document.querySelectorAll('.side-link').forEach((el) => {
            const perm = el.dataset.perm;
            const page = el.dataset.nav;
            let disabled = perm && !can(perm);
            if (page === 'billing' && !feature('billing')) disabled = true;
            if (page === 'deliveries' && !feature('deliveries')) disabled = true;
            if (page === 'stock' && !feature('stock')) disabled = true;
            if (page === 'employees' && !feature('employees')) disabled = true;
            if (page === 'orders' && !feature('deliveries') && !feature('stock')) disabled = true;
            el.classList.toggle('disabled', !!disabled);
            el.classList.toggle('active', el.dataset.nav === state.page);
        });
        document.querySelectorAll('.nav-chip').forEach((el) => {
            el.classList.toggle('active', el.dataset.nav === 'dashboard' && state.page === 'dashboard');
        });
    }

    function startClock() {
        if (state.clockTimer) clearInterval(state.clockTimer);
        const tick = () => {
            const { time } = nowParts();
            const el = document.getElementById('footer-clock');
            if (el) el.textContent = time;
            const live = document.getElementById('live-clock');
            if (live) live.textContent = time;
            const liveDate = document.getElementById('live-date');
            if (liveDate) liveDate.textContent = nowParts().date;
            const ticketTime = document.getElementById('ticket-time');
            if (ticketTime) ticketTime.textContent = nowParts().stamp;
        };
        tick();
        state.clockTimer = setInterval(tick, 1000);
    }

    function cartSubtotal() {
        return state.cart.reduce((sum, l) => sum + l.price * l.quantity, 0);
    }

    function cartTotal() {
        const sub = cartSubtotal();
        if (!state.discount) return sub;
        return Math.max(0, Math.floor(sub * (1 - state.discountPercent / 100)));
    }

    function cartReason() {
        return state.cart.map((l) => `${l.label} x${l.quantity}`).join(' ');
    }

    function addToCart(product) {
        const existing = state.cart.find((l) => l.id === product.id);
        if (existing) {
            existing.quantity += 1;
        } else {
            state.cart.push({
                id: product.id,
                label: product.label,
                price: product.price,
                quantity: 1,
                color: product.color,
            });
        }
        if (state.page === 'sales' || state.page === 'products' || state.page === 'dashboard') {
            render();
        }
    }

    function updateQty(id, delta) {
        const line = state.cart.find((l) => l.id === id);
        if (!line) return;
        line.quantity += delta;
        if (line.quantity <= 0) {
            state.cart = state.cart.filter((l) => l.id !== id);
        }
        render();
    }

    function removeLine(id) {
        state.cart = state.cart.filter((l) => l.id !== id);
        render();
    }

    function clearCart() {
        state.cart = [];
        state.discount = false;
        render();
    }

    function productCards(products) {
        return (products || []).map((p) => `
            <article class="product-card" data-add="${p.id}" style="background: linear-gradient(160deg, ${p.color || '#334155'}88, #182535 70%);">
                <div class="plus"><i class="fa-solid fa-plus"></i></div>
                <h3>${escapeHtml(p.label)}</h3>
                <div class="price">${money(p.price)}</div>
                <div class="cat">${escapeHtml(p.category || '')}</div>
            </article>
        `).join('');
    }

    function ticketHtml() {
        const p = state.data?.player || {};
        const lines = state.cart.length === 0
            ? `<div class="ticket-empty"><i class="fa-solid fa-bag-shopping"></i><div>Panier vide. Ajoutez des produits</div></div>`
            : state.cart.map((l) => `
                <div class="ticket-line">
                    <div>
                        <strong>${escapeHtml(l.label)}</strong>
                        <div class="qty-controls" style="margin-top:8px;">
                            <button data-qty="${l.id}" data-delta="-1">−</button>
                            <span>${l.quantity}</span>
                            <button data-qty="${l.id}" data-delta="1">+</button>
                            <button data-remove="${l.id}" title="Supprimer"><i class="fa-solid fa-trash" style="color:#ef4444;"></i></button>
                        </div>
                    </div>
                    <div class="line-total">${money(l.price * l.quantity)}</div>
                </div>
            `).join('');

        const sub = cartSubtotal();
        const total = cartTotal();

        return `
            <div class="panel ticket">
                <div class="panel-title">Ticket de Caisse</div>
                <div class="ticket-meta">
                    <div>${escapeHtml(p.name || '')}</div>
                    <div id="ticket-time">${nowParts().stamp}</div>
                </div>
                <div class="ticket-list">${lines}</div>
                <div class="ticket-summary">
                    <div class="summary-row"><span>Sous-total</span><span>${money(sub)}</span></div>
                    <label class="discount-row">
                        <input type="checkbox" id="discount-check" ${state.discount ? 'checked' : ''} />
                        Appliquer une réduction (${state.discountPercent}%)
                    </label>
                    <div class="summary-row total"><span>Total</span><span>${money(total)}</span></div>
                    <div class="ticket-actions">
                        <button class="btn btn-secondary" id="btn-cancel-ticket">Annuler</button>
                        <button class="btn btn-primary" id="btn-validate-ticket" ${state.cart.length ? '' : 'disabled'}>
                            <i class="fa-solid fa-check"></i> Valider
                        </button>
                    </div>
                </div>
            </div>
        `;
    }

    function escapeHtml(str) {
        return String(str ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function chartHtml(chartWeek) {
        const days = chartWeek || [];
        const max = Math.max(1, ...days.map((d) => Number(d.total) || 0));
        if (!days.length) {
            return `<div style="color:var(--muted);font-size:13px;">Aucune vente sur 7 jours.</div>`;
        }
        return `<div class="chart-bars">${days.map((d) => {
            const h = Math.max(4, Math.round(((Number(d.total) || 0) / max) * 100));
            const label = String(d.day || '').slice(5);
            return `<div class="chart-bar"><div class="bar" style="height:${h}%"></div><span>${escapeHtml(label)}</span></div>`;
        }).join('')}</div>`;
    }

    function renderDashboard() {
        const p = state.data?.player || {};
        const s = state.data?.stats || {};
        const service = state.data?.service || {};
        return `
            <div class="page">
                <section class="welcome">
                    <div class="welcome-left">
                        <div class="welcome-kicker"><i class="fa-solid fa-basket-shopping"></i> Restauration & Alimentation & Bar</div>
                        <h2>Bonjour, ${escapeHtml(p.name || '')}</h2>
                        <div class="duty">
                            <span class="duty-dot ${p.onDuty ? 'on' : ''}"></span>
                            ${escapeHtml(p.gradeLabel || '')} — ${(state.data?.restaurant?.label || '').toUpperCase()}
                            · ${p.onDuty ? 'En service' : 'Hors service'}
                        </div>
                        <div style="margin-top:12px;display:flex;gap:8px;">
                            <button class="btn ${p.onDuty ? 'btn-danger' : 'btn-primary'}" id="btn-service">
                                ${p.onDuty ? '🔴 Quitter le service' : '🟢 Prendre le service'}
                            </button>
                            <button class="btn btn-purple" data-goto="sales">+ Nouvelle vente</button>
                        </div>
                    </div>
                    <div class="welcome-clock">
                        <strong id="live-clock">${nowParts().time}</strong>
                        <span id="live-date">${nowParts().date}</span>
                        <div style="margin-top:10px;font-size:12px;color:var(--muted);">
                            Aujourd'hui ${formatSeconds(service.today)} · Semaine ${formatSeconds(service.week)}
                        </div>
                    </div>
                </section>

                <section class="grid-stats">
                    <div class="stat-card"><div class="stat-icon"><i class="fa-solid fa-dollar-sign"></i></div><div class="stat-meta"><span>Total des ventes</span><strong>${money(s.salesTotal)}</strong></div></div>
                    <div class="stat-card"><div class="stat-icon"><i class="fa-solid fa-bag-shopping"></i></div><div class="stat-meta"><span>Nombre de ventes</span><strong>${s.salesCount || 0}</strong></div></div>
                    <div class="stat-card"><div class="stat-icon"><i class="fa-solid fa-chart-line"></i></div><div class="stat-meta"><span>Gains livraisons</span><strong>${money(s.deliveryEarnings)}</strong></div></div>
                    <div class="stat-card"><div class="stat-icon"><i class="fa-solid fa-truck"></i></div><div class="stat-meta"><span>Livraisons</span><strong>${s.deliveryCount || 0}</strong></div></div>
                    <div class="stat-card"><div class="stat-icon"><i class="fa-solid fa-wallet"></i></div><div class="stat-meta"><span>Salaire (${p.commissionPercent || 0}%)</span><strong>${money(s.commission)}</strong></div></div>
                </section>

                <section class="two-col">
                    <div class="panel">
                        <div class="panel-title">Ventes 7 jours</div>
                        ${chartHtml(s.chartWeek)}
                        <div style="margin-top:12px;display:grid;grid-template-columns:repeat(3,1fr);gap:8px;font-size:12px;color:var(--muted);">
                            <div>Jour<br><strong style="color:var(--text)">${money(s.salesToday)}</strong></div>
                            <div>Semaine<br><strong style="color:var(--text)">${money(s.salesWeek)}</strong></div>
                            <div>Mois<br><strong style="color:var(--text)">${money(s.salesMonth)}</strong></div>
                        </div>
                    </div>
                    <div class="panel">
                        <div class="panel-title">Produits populaires</div>
                        <div class="list">
                            ${(s.topProducts || []).map((tp) => `
                                <div class="list-item">
                                    <div><strong>${escapeHtml(tp.product_label)}</strong><div style="font-size:12px;color:var(--muted)">${tp.qty || 0} vendus</div></div>
                                    <strong>${money(tp.revenue)}</strong>
                                </div>
                            `).join('') || '<div style="color:var(--muted)">Pas encore de données.</div>'}
                        </div>
                    </div>
                </section>

                <section>
                    <div class="panel-title" style="margin-bottom:10px;">Accès rapide</div>
                    <div class="quick-grid">
                        <div class="quick-card" data-goto="sales"><div class="quick-icon" style="background:#20c66b"><i class="fa-solid fa-calculator"></i></div><h4>Comptabilité</h4><p>Gestion des ventes</p></div>
                        <div class="quick-card" data-goto="orders"><div class="quick-icon" style="background:#f59e0b"><i class="fa-solid fa-cart-shopping"></i></div><h4>Commande produits</h4><p>Ingrédients à commander</p></div>
                        <div class="quick-card" data-goto="employees"><div class="quick-icon" style="background:#8b5cf6"><i class="fa-solid fa-users"></i></div><h4>Employés</h4><p>Gestion de l'équipe</p></div>
                        <div class="quick-card" data-goto="stock"><div class="quick-icon" style="background:#ef4444"><i class="fa-solid fa-boxes-stacked"></i></div><h4>Stock</h4><p>Inventaire cuisine</p></div>
                        <div class="quick-card" data-goto="billing"><div class="quick-icon" style="background:#3b82f6"><i class="fa-solid fa-file-invoice"></i></div><h4>Factures</h4><p>TPE & facturation</p></div>
                        <div class="quick-card" data-goto="deliveries"><div class="quick-icon" style="background:#14b8a6"><i class="fa-solid fa-truck"></i></div><h4>Livraisons</h4><p>Suivi des commandes</p></div>
                    </div>
                </section>
            </div>
        `;
    }

    function renderSales() {
        const products = state.data?.products || [];
        return `
            <div class="page">
                <div class="page-header">
                    <h1>Caisse</h1>
                    <p>Ajoutez des produits puis validez le ticket.</p>
                </div>
                <div class="sales-layout">
                    <div class="panel">
                        <div class="panel-title">Menu des Produits</div>
                        <div class="products-grid">${productCards(products)}</div>
                    </div>
                    ${ticketHtml()}
                </div>
            </div>
        `;
    }

    function renderProducts() {
        return `
            <div class="page">
                <div class="page-header"><h1>Produits</h1><p>Catalogue vendable du restaurant.</p></div>
                <div class="products-grid">${productCards(state.data?.products || [])}</div>
            </div>
        `;
    }

    function renderRecipes() {
        const recipes = state.data?.recipes || [];
        return `
            <div class="page">
                <div class="page-header"><h1>Recettes</h1><p>Préparez les plats depuis la cuisine ou ici.</p></div>
                <div class="quick-grid">
                    ${recipes.map((r) => `
                        <div class="recipe-card">
                            <h3>${escapeHtml(r.label)}</h3>
                            <div style="font-size:12px;color:var(--muted);">${Math.floor((r.time || 0) / 1000)}s · Grade ${r.grade || 0}+</div>
                            <div class="ingredients">
                                ${(r.ingredients || []).map((i) => `<span class="ing">${i.amount}× ${escapeHtml(i.label)}</span>`).join('')}
                            </div>
                            <button class="btn btn-primary" data-craft="${r.id}" style="width:100%;">
                                <i class="fa-solid fa-fire"></i> Préparer
                            </button>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }

    async function renderHistory() {
        const res = await nui('getSales', { period: state.salesFilter });
        const sales = res?.sales || [];
        return `
            <div class="page">
                <div class="page-header"><h1>Historique des ventes</h1><p>Filtres temporels et détail des tickets.</p></div>
                <div class="filters">
                    ${['today', 'week', 'month', 'all'].map((f) => `
                        <button class="chip ${state.salesFilter === f ? 'active' : ''}" data-filter="${f}">
                            ${f === 'today' ? "Aujourd'hui" : f === 'week' ? 'Semaine' : f === 'month' ? 'Mois' : 'Tout'}
                        </button>
                    `).join('')}
                </div>
                <div class="list">
                    ${sales.map((s) => `
                        <div class="list-item">
                            <div>
                                <strong>#${s.id}</strong>
                                <div style="font-size:12px;color:var(--muted);margin-top:4px;">
                                    ${escapeHtml(s.created_at || '')} · ${escapeHtml(s.customer_name || 'Client')} · par ${escapeHtml(s.employee_name || '')}
                                </div>
                                <div style="font-size:12px;color:var(--muted);margin-top:2px;">${escapeHtml(s.items_summary || '')}</div>
                            </div>
                            <strong style="color:var(--green)">${money(s.amount)}</strong>
                        </div>
                    `).join('') || '<div class="panel">Aucune vente.</div>'}
                </div>
            </div>
        `;
    }

    async function renderStock() {
        const res = await nui('getStock');
        const stock = res?.stock || [];
        return `
            <div class="page">
                <div class="page-header"><h1>Gestion du stock</h1><p>Niveaux actuels et alertes.</p></div>
                <div class="list">
                    ${stock.map((item) => `
                        <div class="list-item">
                            <div style="display:flex;gap:12px;align-items:center;">
                                <span style="font-size:22px;">${item.icon || '📦'}</span>
                                <div>
                                    <strong>${escapeHtml(item.label)}</strong>
                                    <div style="font-size:12px;color:var(--muted);">Min ${item.min} · Max ${item.max}</div>
                                </div>
                            </div>
                            <div style="text-align:right;">
                                <strong style="font-size:20px;">${item.quantity}</strong>
                                <div style="margin-top:4px;">
                                    <span class="badge ${item.status}">${item.status === 'ok' ? '🟢 Stock normal' : item.status === 'low' ? '🟠 Stock faible' : '🔴 Rupture'}</span>
                                </div>
                            </div>
                        </div>
                    `).join('') || '<div class="panel">Stock vide.</div>'}
                </div>
            </div>
        `;
    }

    async function renderOrders() {
        const stockRes = await nui('getStock');
        const stock = stockRes?.stock || [];
        return `
            <div class="page">
                <div class="page-header"><h1>Commander des produits</h1><p>Passez une commande fournisseur.</p></div>
                <div class="panel form-grid" id="order-form">
                    ${stock.map((item) => `
                        <div class="field" style="display:grid;grid-template-columns:1fr 120px;gap:10px;align-items:end;">
                            <div>
                                <label>${item.icon || ''} ${escapeHtml(item.label)} <span style="color:var(--muted)">(stock ${item.quantity})</span></label>
                                <div style="font-size:12px;color:var(--muted);">Prix unit. ${money(item.orderPrice)}</div>
                            </div>
                            <input type="number" min="0" max="500" value="0" data-order-item="${item.item}" />
                        </div>
                    `).join('')}
                    <button class="btn btn-primary" id="btn-place-order"><i class="fa-solid fa-paper-plane"></i> Passer la commande</button>
                </div>
            </div>
        `;
    }

    async function renderDeliveries() {
        const res = await nui('getOrders');
        const orders = res?.orders || [];
        return `
            <div class="page">
                <div class="page-header"><h1>Livraisons</h1><p>Prenez en charge les commandes fournisseur.</p></div>
                <div class="list">
                    ${orders.map((o) => `
                        <div class="list-item" style="align-items:flex-start;">
                            <div>
                                <strong>Commande #${o.id}</strong>
                                <div style="font-size:12px;color:var(--muted);margin:6px 0;">
                                    ${(o.items || []).map((it) => `${it.quantity}x ${escapeHtml(it.label)}`).join(' · ')}
                                </div>
                                <span class="badge ${o.delivery_status === 'waiting' ? 'low' : o.delivery_status === 'completed' ? 'ok' : 'online'}">
                                    ${o.delivery_status === 'waiting' ? '🚚 En attente' : o.delivery_status === 'in_progress' ? '🚚 En livraison' : o.status}
                                </span>
                            </div>
                            <div style="display:flex;flex-direction:column;gap:8px;align-items:flex-end;">
                                <strong>${money(o.total_cost)}</strong>
                                ${o.delivery_status === 'waiting' && o.delivery_id ? `
                                    <button class="btn btn-primary" data-take-delivery="${o.delivery_id}">Prendre la livraison</button>
                                ` : ''}
                            </div>
                        </div>
                    `).join('') || '<div class="panel">Aucune livraison.</div>'}
                </div>
            </div>
        `;
    }

    async function renderEmployees() {
        const res = await nui('getEmployees');
        const employees = res?.employees || [];
        const me = state.data?.player?.name;
        return `
            <div class="page">
                <div class="page-header" style="display:flex;justify-content:space-between;align-items:end;">
                    <div>
                        <h1>Employés</h1>
                        <p>Équipe connectée et gestion des grades.</p>
                    </div>
                    ${can('employees') ? `<button class="btn btn-primary" id="btn-hire"><i class="fa-solid fa-user-plus"></i> Recruter</button>` : ''}
                </div>
                <div class="list">
                    ${employees.map((e) => `
                        <div class="list-item ${e.name === me ? 'highlight' : ''}">
                            <div>
                                <strong>${escapeHtml(e.name)}</strong>
                                <div style="font-size:12px;color:var(--muted);margin-top:4px;">
                                    ${escapeHtml(e.gradeLabel)} — ${e.commission}%
                                    · Ventes ${money(e.totalSales)}
                                    · Service ${formatSeconds(e.serviceSeconds)}
                                </div>
                            </div>
                            <div style="display:flex;gap:8px;align-items:center;">
                                <span class="badge ${e.online ? 'online' : 'offline'}">${e.online ? (e.onDuty ? 'En service' : 'En ligne') : 'Hors ligne'}</span>
                                ${can('employees') ? `
                                    <select data-grade-for="${escapeHtml(e.identifier)}" style="background:var(--bg-2);color:var(--text);border:1px solid var(--border);border-radius:8px;padding:6px;">
                                        ${[0,1,2,3,4].map((g) => `<option value="${g}" ${g === e.grade ? 'selected' : ''}>${g}</option>`).join('')}
                                    </select>
                                    <button class="btn btn-danger" data-fire="${escapeHtml(e.identifier)}">Licencier</button>
                                ` : ''}
                            </div>
                        </div>
                    `).join('') || '<div class="panel">Aucun employé.</div>'}
                </div>
            </div>
        `;
    }

    async function renderBilling() {
        const invoicesRes = await nui('getInvoices');
        const invoices = invoicesRes?.invoices || [];
        return `
            <div class="page">
                <div class="page-header"><h1>Factures</h1><p>Créer une facture TPE sécurisée.</p></div>
                <div class="two-col">
                    <div class="panel">
                        <div class="panel-title">Créer une facture</div>
                        <div class="form-grid">
                            <div class="field"><label>Montant</label><input id="inv-amount" type="number" min="1" value="${cartTotal() || 20000}" /></div>
                            <div class="field"><label>Raison</label><input id="inv-reason" type="text" value="${escapeHtml(cartReason() || 'Formule Mini Dino x15')}" /></div>
                            <div class="field"><label>ID cible</label><input id="inv-target" type="number" min="1" placeholder="106" /></div>
                            <button class="btn btn-purple" id="btn-create-invoice">Créer</button>
                            <button class="btn btn-secondary" id="btn-pick-nearby">Choisir un joueur proche</button>
                        </div>
                    </div>
                    <div class="panel">
                        <div class="panel-title">Historique</div>
                        <div class="list">
                            ${invoices.map((inv) => `
                                <div class="list-item">
                                    <div>
                                        <strong>#${inv.id} · ${money(inv.amount)}</strong>
                                        <div style="font-size:12px;color:var(--muted);">${escapeHtml(inv.reason || '')}</div>
                                        <div style="font-size:12px;color:var(--muted);">${escapeHtml(inv.target_name)} · ${escapeHtml(inv.status)}</div>
                                    </div>
                                    <span class="badge ${inv.status === 'paid' ? 'ok' : inv.status === 'pending' ? 'low' : 'out'}">${inv.status}</span>
                                </div>
                            `).join('') || '<div style="color:var(--muted)">Aucune facture.</div>'}
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    async function renderSettings() {
        const notes = state.data?.patchNotes || [];
        return `
            <div class="page">
                <div class="page-header"><h1>Paramètres</h1><p>Informations restaurant et notes de version.</p></div>
                <div class="two-col">
                    <div class="panel">
                        <div class="panel-title">Restaurant</div>
                        <div class="form-grid">
                            <div class="field"><label>Clé</label><input value="${escapeHtml(state.data?.restaurant?.key || '')}" disabled /></div>
                            <div class="field"><label>Label</label><input value="${escapeHtml(state.data?.restaurant?.label || '')}" disabled /></div>
                            <div class="field"><label>Job</label><input value="${escapeHtml(state.data?.restaurant?.job || '')}" disabled /></div>
                        </div>
                    </div>
                    <div class="panel">
                        <div class="panel-title">Patch Notes</div>
                        ${notes.map((n) => `
                            <div style="margin-bottom:14px;">
                                <strong>v${escapeHtml(n.version)}</strong> <span style="color:var(--muted);font-size:12px;">${escapeHtml(n.date || '')}</span>
                                <ul style="margin-top:8px;padding-left:18px;color:var(--muted);font-size:13px;">
                                    ${(n.notes || []).map((x) => `<li>${escapeHtml(x)}</li>`).join('')}
                                </ul>
                            </div>
                        `).join('') || '<div style="color:var(--muted)">Aucune note.</div>'}
                    </div>
                </div>
            </div>
        `;
    }

    async function render() {
        setHeader();
        let html = '';
        switch (state.page) {
            case 'dashboard': html = renderDashboard(); break;
            case 'sales': html = renderSales(); break;
            case 'products': html = renderProducts(); break;
            case 'recipes': html = renderRecipes(); break;
            case 'history': html = await renderHistory(); break;
            case 'stock': html = await renderStock(); break;
            case 'orders': html = await renderOrders(); break;
            case 'deliveries': html = await renderDeliveries(); break;
            case 'employees': html = await renderEmployees(); break;
            case 'billing': html = await renderBilling(); break;
            case 'settings': html = await renderSettings(); break;
            default: html = renderDashboard();
        }
        content.innerHTML = html;
        bindPageEvents();
    }

    function openModal(html) {
        modalCard.innerHTML = html;
        modal.classList.remove('hidden');
    }

    function closeModal() {
        modal.classList.add('hidden');
        modalCard.innerHTML = '';
    }

    async function openPaymentModal() {
        const players = await nui('getNearbyPlayers') || [];
        if (!players.length) {
            await nui('notify', { title: 'Caisse', description: 'Aucun client à proximité.', type: 'error' });
            return;
        }
        openModal(`
            <h3>Client</h3>
            <div class="list" style="max-height:280px;overflow:auto;">
                ${players.map((p) => `
                    <div class="list-item">
                        <div>
                            <strong>ID ${p.id}</strong>
                            <div style="font-size:12px;color:var(--muted);">${escapeHtml(p.name)} · ${p.distance}m</div>
                        </div>
                        <div style="display:flex;gap:6px;">
                            <button class="btn btn-primary" data-pay="${p.id}" data-method="cash">Cash</button>
                            <button class="btn btn-purple" data-pay="${p.id}" data-method="bank">Carte</button>
                            <button class="btn btn-secondary" data-bill="${p.id}">Facturer</button>
                        </div>
                    </div>
                `).join('')}
            </div>
            <div class="modal-actions">
                <button class="btn btn-secondary" id="modal-close">Retour</button>
            </div>
        `);
    }

    async function processSale(targetId, method) {
        const result = await nui('processSale', {
            targetId: Number(targetId),
            cart: state.cart.map((l) => ({ id: l.id, quantity: l.quantity })),
            paymentMethod: method,
            discount: state.discount ? state.discountPercent : 0,
        });
        if (!result?.ok) {
            await nui('notify', { title: 'Caisse', description: result?.error || 'Échec paiement', type: 'error' });
            return;
        }
        clearCart();
        closeModal();
        const refreshed = await nui('refresh');
        if (refreshed?.ok) state.data = refreshed;
        await render();
    }

    function bindPageEvents() {
        content.querySelectorAll('[data-add]').forEach((el) => {
            el.addEventListener('click', () => {
                const id = el.getAttribute('data-add');
                const product = (state.data?.products || []).find((p) => p.id === id);
                if (product) addToCart(product);
            });
        });

        content.querySelectorAll('[data-qty]').forEach((el) => {
            el.addEventListener('click', () => {
                updateQty(el.getAttribute('data-qty'), Number(el.getAttribute('data-delta')));
            });
        });

        content.querySelectorAll('[data-remove]').forEach((el) => {
            el.addEventListener('click', () => removeLine(el.getAttribute('data-remove')));
        });

        content.querySelectorAll('[data-goto]').forEach((el) => {
            el.addEventListener('click', () => navigate(el.getAttribute('data-goto')));
        });

        const discount = document.getElementById('discount-check');
        if (discount) {
            discount.addEventListener('change', () => {
                state.discount = discount.checked;
                render();
            });
        }

        const cancel = document.getElementById('btn-cancel-ticket');
        if (cancel) cancel.addEventListener('click', clearCart);

        const validate = document.getElementById('btn-validate-ticket');
        if (validate) validate.addEventListener('click', openPaymentModal);

        const serviceBtn = document.getElementById('btn-service');
        if (serviceBtn) {
            serviceBtn.addEventListener('click', async () => {
                const result = await nui('toggleService');
                if (result?.ok) {
                    const refreshed = await nui('refresh');
                    if (refreshed?.ok) state.data = refreshed;
                    await render();
                } else {
                    await nui('notify', { title: 'Service', description: 'Impossible de changer le service.', type: 'error' });
                }
            });
        }

        content.querySelectorAll('[data-craft]').forEach((el) => {
            el.addEventListener('click', async () => {
                await nui('startCraft', { recipeId: el.getAttribute('data-craft') });
            });
        });

        content.querySelectorAll('[data-filter]').forEach((el) => {
            el.addEventListener('click', () => {
                state.salesFilter = el.getAttribute('data-filter') === 'all' ? '' : el.getAttribute('data-filter');
                render();
            });
        });

        const placeOrder = document.getElementById('btn-place-order');
        if (placeOrder) {
            placeOrder.addEventListener('click', async () => {
                const items = [];
                content.querySelectorAll('[data-order-item]').forEach((input) => {
                    const qty = Number(input.value || 0);
                    if (qty > 0) items.push({ item: input.getAttribute('data-order-item'), quantity: qty });
                });
                const result = await nui('createOrder', items);
                await nui('notify', {
                    title: 'Commandes',
                    description: result?.ok ? `Commande #${result.data} créée` : (result?.data || 'Échec'),
                    type: result?.ok ? 'success' : 'error',
                });
                if (result?.ok) navigate('deliveries');
            });
        }

        content.querySelectorAll('[data-take-delivery]').forEach((el) => {
            el.addEventListener('click', async () => {
                const result = await nui('takeDelivery', { deliveryId: Number(el.getAttribute('data-take-delivery')) });
                await nui('notify', {
                    title: 'Livraisons',
                    description: result?.ok ? 'Livraison prise en charge' : (result?.data || 'Échec'),
                    type: result?.ok ? 'success' : 'error',
                });
                if (result?.ok) await nui('close');
            });
        });

        const hire = document.getElementById('btn-hire');
        if (hire) {
            hire.addEventListener('click', async () => {
                const players = await nui('getNearbyPlayers') || [];
                if (!players.length) {
                    await nui('notify', { title: 'Employés', description: 'Aucun joueur proche.', type: 'error' });
                    return;
                }
                openModal(`
                    <h3>Recruter</h3>
                    <div class="form-grid">
                        <div class="field"><label>Joueur</label>
                            <select id="hire-target">${players.map((p) => `<option value="${p.id}">ID ${p.id} — ${escapeHtml(p.name)}</option>`).join('')}</select>
                        </div>
                        <div class="field"><label>Grade</label>
                            <select id="hire-grade">
                                <option value="0">Stagiaire</option>
                                <option value="1" selected>Employé</option>
                                <option value="2">Cuisinier</option>
                                <option value="3">Manager</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-actions">
                        <button class="btn btn-secondary" id="modal-close">Retour</button>
                        <button class="btn btn-primary" id="hire-confirm">Recruter</button>
                    </div>
                `);
                document.getElementById('hire-confirm')?.addEventListener('click', async () => {
                    const result = await nui('hireEmployee', {
                        targetId: Number(document.getElementById('hire-target').value),
                        grade: Number(document.getElementById('hire-grade').value),
                    });
                    closeModal();
                    await nui('notify', {
                        title: 'Employés',
                        description: result?.message || (result?.ok ? 'OK' : 'Échec'),
                        type: result?.ok ? 'success' : 'error',
                    });
                    await render();
                });
            });
        }

        content.querySelectorAll('[data-fire]').forEach((el) => {
            el.addEventListener('click', async () => {
                const result = await nui('fireEmployee', { citizenid: el.getAttribute('data-fire') });
                await nui('notify', {
                    title: 'Employés',
                    description: result?.message || '',
                    type: result?.ok ? 'success' : 'error',
                });
                await render();
            });
        });

        content.querySelectorAll('[data-grade-for]').forEach((el) => {
            el.addEventListener('change', async () => {
                const result = await nui('setEmployeeGrade', {
                    citizenid: el.getAttribute('data-grade-for'),
                    grade: Number(el.value),
                });
                await nui('notify', {
                    title: 'Employés',
                    description: result?.message || '',
                    type: result?.ok ? 'success' : 'error',
                });
                await render();
            });
        });

        const createInv = document.getElementById('btn-create-invoice');
        if (createInv) {
            createInv.addEventListener('click', async () => {
                const result = await nui('createInvoice', {
                    targetId: Number(document.getElementById('inv-target').value),
                    amount: Number(document.getElementById('inv-amount').value),
                    reason: document.getElementById('inv-reason').value,
                });
                await nui('notify', {
                    title: 'Factures',
                    description: result?.ok ? `Facture #${result.invoiceId} créée` : (result?.error || 'Échec'),
                    type: result?.ok ? 'success' : 'error',
                });
                if (result?.ok) await render();
            });
        }

        const pickNearby = document.getElementById('btn-pick-nearby');
        if (pickNearby) {
            pickNearby.addEventListener('click', async () => {
                const players = await nui('getNearbyPlayers') || [];
                if (!players.length) return;
                document.getElementById('inv-target').value = players[0].id;
            });
        }
    }

    async function navigate(page) {
        if (!page) return;
        const link = document.querySelector(`.side-link[data-nav="${page}"]`);
        if (link?.classList.contains('disabled')) {
            await nui('notify', { title: 'Tablette', description: 'Permission insuffisante.', type: 'error' });
            return;
        }
        state.page = page;
        await render();
    }

    document.getElementById('btn-close').addEventListener('click', () => nui('close'));
    document.getElementById('btn-refresh').addEventListener('click', async () => {
        const refreshed = await nui('refresh');
        if (refreshed?.ok) {
            state.data = refreshed;
            await render();
        }
    });
    document.getElementById('btn-patch').addEventListener('click', () => navigate('settings'));
    document.getElementById('btn-theme').addEventListener('click', () => {
        document.body.classList.toggle('light');
    });

    document.querySelectorAll('[data-nav]').forEach((el) => {
        el.addEventListener('click', () => navigate(el.dataset.nav));
    });

    modal.addEventListener('click', (e) => {
        if (e.target === modal || e.target.id === 'modal-close') closeModal();
        const pay = e.target.closest?.('[data-pay]');
        if (pay) {
            processSale(pay.getAttribute('data-pay'), pay.getAttribute('data-method'));
        }
        const bill = e.target.closest?.('[data-bill]');
        if (bill) {
            closeModal();
            state.page = 'billing';
            render().then(() => {
                const target = document.getElementById('inv-target');
                const amount = document.getElementById('inv-amount');
                const reason = document.getElementById('inv-reason');
                if (target) target.value = bill.getAttribute('data-bill');
                if (amount) amount.value = cartTotal();
                if (reason) reason.value = cartReason();
            });
        }
    });

    window.addEventListener('message', (event) => {
        const msg = event.data || {};
        if (msg.action === 'open') {
            state.open = true;
            state.data = msg.data;
            state.page = msg.page || 'dashboard';
            app.classList.remove('hidden');
            startClock();
            render();
        }
        if (msg.action === 'close') {
            state.open = false;
            app.classList.add('hidden');
            closeModal();
            if (state.clockTimer) clearInterval(state.clockTimer);
        }
        if (msg.action === 'serviceUpdate' && state.data?.player) {
            state.data.player.onDuty = !!msg.onDuty;
            render();
        }
    });

    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && state.open) nui('close');
    });
})();
