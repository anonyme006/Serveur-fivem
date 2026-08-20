const app = document.getElementById('app');
const nav = document.getElementById('navCategories');
const panels = {
    services: document.getElementById('panelServices'),
    diagnostic: document.getElementById('panelDiagnostic'),
    billing: document.getElementById('panelBilling'),
    orders: document.getElementById('panelOrders'),
    employees: document.getElementById('panelEmployees'),
    dashboard: document.getElementById('panelDashboard'),
    stock: document.getElementById('panelStock'),
    management: document.getElementById('panelManagement'),
};

let state = {
    menu: null,
    vehicle: null,
    category: 'repair',
    permissions: {},
};

const ICON_MAP = {
    wrench: 'fa-wrench',
    stethoscope: 'fa-stethoscope',
    'gauge-high': 'fa-gauge-high',
    car: 'fa-car',
    circle: 'fa-circle',
    'oil-can': 'fa-oil-can',
    'boxes-stacked': 'fa-boxes-stacked',
    'file-invoice-dollar': 'fa-file-invoice-dollar',
    'clipboard-list': 'fa-clipboard-list',
    users: 'fa-users',
    building: 'fa-building',
};

function post(name, data = {}) {
    return fetch(`https://kx_mechanic/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).then((r) => r.json()).catch(() => ({ ok: false }));
}

function money(amount) {
    return `${Number(amount || 0).toLocaleString('fr-FR')}$`;
}

function duration(ms) {
    return `${Math.round((ms || 0) / 1000)} s`;
}

function showToast(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.classList.remove('hidden');
    clearTimeout(showToast._t);
    showToast._t = setTimeout(() => toast.classList.add('hidden'), 2800);
}

function hideAllPanels() {
    Object.values(panels).forEach((panel) => panel.classList.add('hidden'));
}

function setTitle(title, subtitle) {
    document.getElementById('viewTitle').textContent = title;
    document.getElementById('viewSubtitle').textContent = subtitle || '';
}

function updateVehicleBadge() {
    const badge = document.getElementById('vehicleBadge');
    if (!state.vehicle) {
        badge.classList.add('hidden');
        return;
    }
    badge.classList.remove('hidden');
    document.getElementById('vehPlate').textContent = state.vehicle.plate || '----';
    document.getElementById('vehModel').textContent = state.vehicle.model || 'Véhicule';
}

function canSeeCategory(id) {
    const map = {
        repair: 'repair',
        diagnostic: 'diagnose',
        performance: 'performance',
        body: 'body',
        tires: 'tires',
        maintenance: 'maintenance',
        stock: 'stock',
        billing: 'billing',
        orders: 'orders',
        employees: 'employees',
        management: 'management',
    };
    const perm = map[id];
    if (!perm) return true;
    return !!state.permissions[perm];
}

function renderNav() {
    nav.innerHTML = '';
    if (!state.menu) return;

    state.menu.categories.forEach((cat) => {
        if (!canSeeCategory(cat.id)) return;
        if (cat.id === 'performance' && state.menu.config && !state.menu.config.enablePerformance) return;
        if (cat.id === 'maintenance' && state.menu.config && !state.menu.config.enableMaintenance) return;
        if (cat.id === 'billing' && state.menu.config && !state.menu.config.enableBilling) return;
        if (cat.id === 'orders' && state.menu.config && !state.menu.config.enableOrders) return;

        const btn = document.createElement('button');
        btn.className = `nav-btn${state.category === cat.id ? ' active' : ''}`;
        btn.innerHTML = `<i class="fa-solid ${ICON_MAP[cat.icon] || 'fa-circle'}"></i><span>${cat.label}</span>`;
        btn.addEventListener('click', () => selectCategory(cat.id));
        nav.appendChild(btn);
    });

    if (state.permissions.dashboard && state.menu.config?.enableDashboard) {
        const dash = document.createElement('button');
        dash.className = `nav-btn${state.category === 'dashboard' ? ' active' : ''}`;
        dash.innerHTML = `<i class="fa-solid fa-chart-line"></i><span>Tableau de bord</span>`;
        dash.addEventListener('click', () => selectCategory('dashboard'));
        nav.appendChild(dash);
    }
}

function renderServices(categoryId) {
    hideAllPanels();
    panels.services.classList.remove('hidden');
    const category = state.menu.categories.find((c) => c.id === categoryId);
    if (!category) {
        panels.services.innerHTML = '<div class="card"><p>Aucune catégorie.</p></div>';
        return;
    }

    setTitle(category.label, 'Interventions disponibles');
    const grid = document.createElement('div');
    grid.className = 'grid';

    if (categoryId === 'diagnostic') {
        const card = document.createElement('div');
        card.className = 'card';
        card.innerHTML = `
            <h3>Diagnostic complet</h3>
            <p>Analyse moteur, transmission, freins, suspension, pneus, fluides et température.</p>
            <div class="card-meta">
                <span class="pill accent">${money(50)}</span>
                <span class="pill">5 s</span>
            </div>
            <button class="btn" id="runDiagnose"><i class="fa-solid fa-stethoscope"></i> Lancer le diagnostic</button>
        `;
        grid.appendChild(card);
        panels.services.innerHTML = '';
        panels.services.appendChild(grid);
        document.getElementById('runDiagnose').addEventListener('click', () => post('diagnose'));
        return;
    }

    (category.services || []).forEach((service, index) => {
        const card = document.createElement('div');
        card.className = 'card';
        card.style.animationDelay = `${index * 0.03}s`;
        const materials = (service.materials || [])
            .map((m) => `<li>${m.count}x ${m.label}</li>`)
            .join('') || '<li>Aucun matériel</li>';

        card.innerHTML = `
            <h3>${service.label}</h3>
            <p>${service.description}</p>
            <div class="card-meta">
                <span class="pill accent">Prix : ${money(service.price)}</span>
                <span class="pill">Durée : ${duration(service.duration)}</span>
            </div>
            <ul class="materials"><strong>Matériel :</strong>${materials}</ul>
            <div class="btn-row">
                <button class="btn" data-service="${service.id}">Lancer</button>
            </div>
        `;
        grid.appendChild(card);
    });

    panels.services.innerHTML = '';
    panels.services.appendChild(grid);
    panels.services.querySelectorAll('[data-service]').forEach((btn) => {
        btn.addEventListener('click', () => {
            post('runService', { serviceId: btn.dataset.service });
        });
    });
}

function renderDiagnostic(report) {
    hideAllPanels();
    panels.diagnostic.classList.remove('hidden');
    setTitle('Rapport de diagnostic', report.plate ? `Plaque ${report.plate}` : 'Analyse terminée');

    const comps = (report.components || []).map((c) => `
        <div class="diag-card">
            <div class="label">${c.label}</div>
            <div class="bar">${c.bar || ''}</div>
            <div class="value">${c.percent}%</div>
            <div class="progress"><span style="width:${c.percent}%"></span></div>
        </div>
    `).join('');

    const tires = (report.tires || []).map((t) => `
        <div class="diag-card">
            <div class="label">${t.label}</div>
            <div class="value">${t.percent}%</div>
            <div class="progress"><span style="width:${t.percent}%"></span></div>
        </div>
    `).join('');

    panels.diagnostic.innerHTML = `
        <div class="card" style="margin-bottom:14px">
            <div class="card-meta">
                <span class="pill">Kilométrage : ${report.mileage || 0} km</span>
                <span class="pill">Pneus : ${report.tire_type || 'stock'}</span>
                <span class="pill">Dernier entretien : ${report.last_service || 'N/A'}</span>
            </div>
        </div>
        <div class="diag-grid">${comps}</div>
        <h2 style="margin:18px 0 10px;font-size:18px">Pneus</h2>
        <div class="diag-grid">${tires}</div>
        <div class="btn-row" style="margin-top:16px">
            <button class="btn secondary" id="backMenu">Retour menu</button>
        </div>
    `;

    document.getElementById('backMenu')?.addEventListener('click', () => {
        selectCategory(state.category || 'repair');
    });
}

async function renderBilling() {
    hideAllPanels();
    panels.billing.classList.remove('hidden');
    setTitle('Facturation', 'Créer une facture client');

    const playersRes = await post('getNearbyPlayers');
    const players = playersRes.players || [];
    const services = [];
    state.menu.categories.forEach((cat) => {
        (cat.services || []).forEach((s) => services.push(s));
    });

    panels.billing.innerHTML = `
        <div class="form">
            <label>Client
                <select id="invoicePlayer">
                    ${players.map((p) => `<option value="${p.id}">${p.name} (#${p.id})</option>`).join('') || '<option value="">Aucun joueur proche</option>'}
                </select>
            </label>
            <div class="checklist" id="invoiceItems">
                ${services.map((s) => `
                    <label><input type="checkbox" value="${s.id}" data-price="${s.price}" /> ${s.label} — ${money(s.price)}</label>
                `).join('')}
            </div>
            <div class="card-meta"><span class="pill accent" id="invoiceTotal">Total : 0$</span></div>
            <button class="btn" id="sendInvoice">Envoyer la facture</button>
        </div>
    `;

    const updateTotal = () => {
        let total = 0;
        panels.billing.querySelectorAll('#invoiceItems input:checked').forEach((el) => {
            total += Number(el.dataset.price || 0);
        });
        document.getElementById('invoiceTotal').textContent = `Total : ${money(total)}`;
    };

    panels.billing.querySelectorAll('#invoiceItems input').forEach((el) => {
        el.addEventListener('change', updateTotal);
    });

    document.getElementById('sendInvoice').addEventListener('click', async () => {
        const targetId = Number(document.getElementById('invoicePlayer').value);
        const items = [...panels.billing.querySelectorAll('#invoiceItems input:checked')].map((el) => el.value);
        const result = await post('createInvoice', { targetId, items });
        showToast(result.message || (result.ok ? 'Facture envoyée' : 'Erreur'));
        post('notify', { message: result.message || '', type: result.ok ? 'success' : 'error' });
    });
}

async function renderOrders() {
    hideAllPanels();
    panels.orders.classList.remove('hidden');
    setTitle('Commandes', 'Approvisionnement atelier');

    const result = await post('getOrders');
    const catalog = result.catalog || [];
    const orders = result.orders || [];

    panels.orders.innerHTML = `
        <div class="form">
            <label>Produit
                <select id="orderProduct">
                    ${catalog.map((c) => `<option value="${c.item}">${c.label} — ${money(c.unitPrice)}</option>`).join('')}
                </select>
            </label>
            <label>Quantité
                <input id="orderQty" type="number" min="1" max="100" value="5" />
            </label>
            <button class="btn" id="placeOrder">Commander</button>
        </div>
        <table class="table">
            <thead>
                <tr><th>N°</th><th>Produit</th><th>Qté</th><th>Total</th><th>Statut</th><th>Date</th></tr>
            </thead>
            <tbody>
                ${orders.map((o) => `
                    <tr>
                        <td>${o.order_number}</td>
                        <td>${o.product_label}</td>
                        <td>${o.quantity}</td>
                        <td>${money(o.total_price)}</td>
                        <td>${String(o.status || '').toUpperCase()}</td>
                        <td>${o.created_at || ''}</td>
                    </tr>
                `).join('') || '<tr><td colspan="6">Aucune commande</td></tr>'}
            </tbody>
        </table>
    `;

    document.getElementById('placeOrder').addEventListener('click', async () => {
        const product = document.getElementById('orderProduct').value;
        const quantity = Number(document.getElementById('orderQty').value || 1);
        const res = await post('createOrder', { product, quantity });
        showToast(res.message || 'Commande');
        if (res.ok) renderOrders();
    });
}

async function renderEmployees() {
    hideAllPanels();
    panels.employees.classList.remove('hidden');
    setTitle('Employés', 'Recrutement et grades');

    const [empRes, nearRes] = await Promise.all([post('getEmployees'), post('getNearbyPlayers')]);
    const employees = empRes.employees || [];
    const grades = empRes.grades || {};
    const nearby = nearRes.players || [];

    panels.employees.innerHTML = `
        <div class="form">
            <label>Recruter un joueur proche
                <select id="hireTarget">
                    ${nearby.map((p) => `<option value="${p.id}">${p.name}</option>`).join('') || '<option value="">Aucun</option>'}
                </select>
            </label>
            <button class="btn" id="hireBtn">Recruter</button>
        </div>
        <table class="table">
            <thead><tr><th>Nom</th><th>Grade</th><th>Salaire</th><th>Actions</th></tr></thead>
            <tbody>
                ${employees.map((e) => `
                    <tr>
                        <td>${e.name}</td>
                        <td>
                            <select data-grade="${e.citizenid}">
                                ${Object.keys(grades).map((g) => `<option value="${g}" ${Number(e.grade) === Number(g) ? 'selected' : ''}>${grades[g].label}</option>`).join('')}
                            </select>
                        </td>
                        <td>${money(e.salary)}</td>
                        <td class="btn-row">
                            <button class="btn secondary" data-save="${e.citizenid}">Sauver</button>
                            <button class="btn danger" data-fire="${e.citizenid}">Licencier</button>
                        </td>
                    </tr>
                `).join('') || '<tr><td colspan="4">Aucun employé</td></tr>'}
            </tbody>
        </table>
    `;

    document.getElementById('hireBtn')?.addEventListener('click', async () => {
        const targetId = Number(document.getElementById('hireTarget').value);
        const res = await post('hireEmployee', { targetId });
        showToast(res.message || '');
        if (res.ok) renderEmployees();
    });

    panels.employees.querySelectorAll('[data-save]').forEach((btn) => {
        btn.addEventListener('click', async () => {
            const citizenid = btn.dataset.save;
            const grade = Number(panels.employees.querySelector(`[data-grade="${citizenid}"]`).value);
            const res = await post('setEmployeeGrade', { citizenid, grade });
            showToast(res.message || '');
        });
    });

    panels.employees.querySelectorAll('[data-fire]').forEach((btn) => {
        btn.addEventListener('click', async () => {
            const res = await post('fireEmployee', { citizenid: btn.dataset.fire });
            showToast(res.message || '');
            if (res.ok) renderEmployees();
        });
    });
}

async function renderDashboard() {
    hideAllPanels();
    panels.dashboard.classList.remove('hidden');
    setTitle('Tableau de bord', 'Performance de l\'atelier');

    const result = await post('getDashboard');
    if (!result.ok) {
        panels.dashboard.innerHTML = `<div class="card"><p>${result.message || 'Accès refusé'}</p></div>`;
        return;
    }

    const d = result.data;
    const chart = d.chart || [];
    const maxRevenue = Math.max(...chart.map((c) => Number(c.revenue || 0)), 1);

    panels.dashboard.innerHTML = `
        <div class="stats-grid">
            <div class="stat"><span>CA du jour</span><strong>${money(d.day?.revenue)}</strong></div>
            <div class="stat"><span>CA de la semaine</span><strong>${money(d.week?.revenue)}</strong></div>
            <div class="stat"><span>CA du mois</span><strong>${money(d.month?.revenue)}</strong></div>
            <div class="stat"><span>Réparations (jour)</span><strong>${d.day?.repairs || 0}</strong></div>
        </div>
        <div class="stats-grid">
            <div class="stat"><span>Véhicules traités (semaine)</span><strong>${d.week?.vehicles || 0}</strong></div>
            <div class="stat"><span>Meilleur mécanicien</span><strong style="font-size:16px">${d.bestMechanic?.mechanic_name || '—'}</strong></div>
            <div class="stat"><span>Pièces utilisées (jour)</span><strong>${d.day?.parts || 0}</strong></div>
            <div class="stat"><span>Stock faible</span><strong>${(d.lowStock || []).length}</strong></div>
        </div>
        <div class="chart">
            ${chart.map((c) => {
                const h = Math.max(4, Math.round((Number(c.revenue || 0) / maxRevenue) * 120));
                return `<div class="col"><i style="height:${h}px"></i><span>${String(c.day || '').slice(5)}</span></div>`;
            }).join('') || '<div class="col"><span>Pas de données</span></div>'}
        </div>
        <div class="grid">
            <div class="card">
                <h3>Stock faible</h3>
                <ul class="materials">
                    ${(d.lowStock || []).map((s) => `<li>${s.label} : ${s.count}</li>`).join('') || '<li>Tout est OK</li>'}
                </ul>
            </div>
            <div class="card">
                <h3>Pièces consommées (7j)</h3>
                <ul class="materials">
                    ${(d.partsUsed || []).map((p) => `<li>${p.item} : ${p.total}</li>`).join('') || '<li>Aucune</li>'}
                </ul>
            </div>
        </div>
        <div class="btn-row" style="margin-top:12px">
            <button class="btn secondary" id="loadHistory">Historique des réparations</button>
        </div>
        <div id="historyBox"></div>
    `;

    document.getElementById('loadHistory')?.addEventListener('click', async () => {
        const hist = await post('getHistory', {});
        const rows = (hist.history || []).map((h) => `
            <tr>
                <td>${h.id}</td>
                <td>${h.plate}</td>
                <td>${h.repair_label}</td>
                <td>${h.mechanic_name}</td>
                <td>${money(h.price)}</td>
                <td>${h.created_at || ''}</td>
            </tr>
        `).join('');
        document.getElementById('historyBox').innerHTML = `
            <table class="table" style="margin-top:12px">
                <thead><tr><th>ID</th><th>Plaque</th><th>Réparation</th><th>Mécanicien</th><th>Prix</th><th>Date</th></tr></thead>
                <tbody>${rows || '<tr><td colspan="6">Vide</td></tr>'}</tbody>
            </table>
        `;
    });
}

async function renderStock() {
    hideAllPanels();
    panels.stock.classList.remove('hidden');
    setTitle('Stock', 'Coffre et historique');

    const log = await post('getStockLog');
    panels.stock.innerHTML = `
        <div class="btn-row" style="margin-bottom:14px">
            <button class="btn" id="openStash"><i class="fa-solid fa-box-open"></i> Ouvrir le stockage</button>
        </div>
        <table class="table">
            <thead><tr><th>Action</th><th>Item</th><th>Qté</th><th>Employé</th><th>Raison</th><th>Date</th></tr></thead>
            <tbody>
                ${(log.log || []).map((l) => `
                    <tr>
                        <td>${l.action}</td>
                        <td>${l.item}</td>
                        <td>${l.amount}</td>
                        <td>${l.player_name || '—'}</td>
                        <td>${l.reason || ''}</td>
                        <td>${l.created_at || ''}</td>
                    </tr>
                `).join('') || '<tr><td colspan="6">Aucun mouvement</td></tr>'}
            </tbody>
        </table>
    `;

    document.getElementById('openStash')?.addEventListener('click', () => post('openStash'));
}

function renderManagement() {
    hideAllPanels();
    panels.management.classList.remove('hidden');
    setTitle('Gestion entreprise', 'Pilotage global');

    panels.management.innerHTML = `
        <div class="grid">
            <div class="card">
                <h3>Tableau de bord</h3>
                <p>Consultez le CA, les réparations et le stock faible.</p>
                <button class="btn" id="goDash">Ouvrir</button>
            </div>
            <div class="card">
                <h3>Employés</h3>
                <p>Recruter, promouvoir, rétrograder ou licencier.</p>
                <button class="btn" id="goEmp">Ouvrir</button>
            </div>
            <div class="card">
                <h3>Commandes</h3>
                <p>Commander des pièces auprès des fournisseurs.</p>
                <button class="btn" id="goOrd">Ouvrir</button>
            </div>
            <div class="card">
                <h3>Stock</h3>
                <p>Accéder au coffre entreprise et à l'historique.</p>
                <button class="btn" id="goStock">Ouvrir</button>
            </div>
        </div>
    `;

    document.getElementById('goDash')?.addEventListener('click', () => selectCategory('dashboard'));
    document.getElementById('goEmp')?.addEventListener('click', () => selectCategory('employees'));
    document.getElementById('goOrd')?.addEventListener('click', () => selectCategory('orders'));
    document.getElementById('goStock')?.addEventListener('click', () => selectCategory('stock'));
}

function selectCategory(id) {
    state.category = id;
    renderNav();

    if (id === 'billing') return renderBilling();
    if (id === 'orders') return renderOrders();
    if (id === 'employees') return renderEmployees();
    if (id === 'dashboard') return renderDashboard();
    if (id === 'stock') return renderStock();
    if (id === 'management') return renderManagement();
    return renderServices(id);
}

function openUI(payload) {
    state.menu = payload.menu || state.menu;
    state.vehicle = payload.vehicle || null;
    state.permissions = (payload.menu && payload.menu.permissions) || state.permissions || {};
    state.category = payload.defaultCategory || state.category || 'repair';

    if (payload.shopName) {
        document.getElementById('shopName').textContent = payload.shopName;
    }
    if (payload.menu?.playerName) {
        document.getElementById('playerMeta').textContent = `${payload.menu.playerName} · Grade ${payload.menu.job?.grade ?? 0}`;
    }

    app.classList.remove('hidden');
    updateVehicleBadge();

    if (payload.view === 'diagnostic' && payload.report) {
        renderDiagnostic(payload.report);
        return;
    }

    renderNav();
    selectCategory(state.category);
}

function closeUI() {
    app.classList.add('hidden');
    post('close');
}

document.getElementById('btnClose').addEventListener('click', closeUI);

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !app.classList.contains('hidden')) {
        closeUI();
    }
});

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};
    if (action === 'open') openUI(data || {});
    if (action === 'close') app.classList.add('hidden');
    if (action === 'serviceCompleted') {
        showToast(data?.message || 'Intervention terminée');
    }
});