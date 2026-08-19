(() => {
  const app = document.getElementById('app');
  const content = document.getElementById('content');
  const modal = document.getElementById('modal');
  const box = document.getElementById('modal-box');
  const res = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'rex_diner';

  const S = {
    open: false,
    page: 'dashboard',
    data: null,
    cart: [],
    discount: false,
    discountPct: 10,
    salesFilter: 'today',
    timer: null,
  };

  async function nui(event, data = {}) {
    try {
      const r = await fetch(`https://${res}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
      });
      return await r.json();
    } catch (e) {
      console.error(event, e);
      return null;
    }
  }

  const esc = (s) => String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  const money = (n) => {
    const v = Math.floor(Number(n) || 0);
    return `${v.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} ${S.data?.currency || '$'}`;
  };
  const dur = (sec) => {
    sec = Math.max(0, Math.floor(Number(sec) || 0));
    return `${String(Math.floor(sec / 3600)).padStart(2, '0')}h${String(Math.floor((sec % 3600) / 60)).padStart(2, '0')}`;
  };
  const now = () => {
    const d = new Date();
    const days = ['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi'];
    const months = ['Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    return {
      time: d.toLocaleTimeString('fr-FR', { hour12: false }),
      date: `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`,
      stamp: `${String(d.getDate()).padStart(2,'0')}/${String(d.getMonth()+1).padStart(2,'0')}/${d.getFullYear()} ${d.toLocaleTimeString('fr-FR',{hour12:false})}`,
    };
  };
  const can = (p) => !p || !!S.data?.permissions?.[p];
  const feat = (n) => S.data?.features?.[n] !== false;

  function header() {
    const p = S.data?.player || {};
    document.getElementById('avatar').textContent = p.avatar || 'R';
    document.getElementById('uname').textContent = p.name || 'Employé';
    document.getElementById('ugrade').textContent = p.gradeLabel || 'Grade';
    document.getElementById('brand').textContent = `${(S.data?.restaurant?.label || 'REX DINER').toUpperCase()} — GESTION`;
    document.querySelectorAll('.link').forEach((el) => {
      const perm = el.dataset.perm;
      const page = el.dataset.nav;
      let off = perm && !can(perm);
      if (page === 'billing' && !feat('billing')) off = true;
      if (page === 'deliveries' && !feat('deliveries')) off = true;
      if (page === 'stock' && !feat('stock')) off = true;
      if (page === 'employees' && !feat('employees')) off = true;
      if (page === 'orders' && !feat('deliveries') && !feat('stock')) off = true;
      el.classList.toggle('disabled', !!off);
      el.classList.toggle('active', el.dataset.nav === S.page);
    });
  }

  function clock() {
    if (S.timer) clearInterval(S.timer);
    const tick = () => {
      const n = now();
      const c = document.getElementById('clock'); if (c) c.textContent = n.time;
      const l = document.getElementById('live'); if (l) l.textContent = n.time;
      const ld = document.getElementById('livedate'); if (ld) ld.textContent = n.date;
      const t = document.getElementById('ticket-time'); if (t) t.textContent = n.stamp;
    };
    tick();
    S.timer = setInterval(tick, 1000);
  }

  const subtotal = () => S.cart.reduce((s, l) => s + l.price * l.quantity, 0);
  const total = () => {
    const s = subtotal();
    return S.discount ? Math.max(0, Math.floor(s * (1 - S.discountPct / 100))) : s;
  };
  const reason = () => S.cart.map((l) => `${l.label} x${l.quantity}`).join(' ');

  function add(product) {
    const e = S.cart.find((l) => l.id === product.id);
    if (e) e.quantity += 1;
    else S.cart.push({ id: product.id, label: product.label, price: product.price, quantity: 1 });
    render();
  }
  function qty(id, d) {
    const l = S.cart.find((x) => x.id === id);
    if (!l) return;
    l.quantity += d;
    if (l.quantity <= 0) S.cart = S.cart.filter((x) => x.id !== id);
    render();
  }
  function clearCart() { S.cart = []; S.discount = false; render(); }

  function productGrid(list) {
    return (list || []).map((p) => `
      <article class="pcard" data-add="${p.id}" style="background:linear-gradient(160deg,${p.color||'#334155'}88,#182535 70%)">
        <div class="plus"><i class="fa-solid fa-plus"></i></div>
        <h3>${esc(p.label)}</h3>
        <div class="price">${money(p.price)}</div>
        <div class="cat">${esc(p.category||'')}</div>
      </article>`).join('');
  }

  function ticket() {
    const p = S.data?.player || {};
    const lines = !S.cart.length
      ? `<div class="empty"><i class="fa-solid fa-bag-shopping"></i>Panier vide. Ajoutez des produits</div>`
      : S.cart.map((l) => `
        <div class="line">
          <div>
            <strong>${esc(l.label)}</strong>
            <div class="qty">
              <button data-qty="${l.id}" data-d="-1">−</button>
              <span>${l.quantity}</span>
              <button data-qty="${l.id}" data-d="1">+</button>
              <button data-rm="${l.id}"><i class="fa-solid fa-trash" style="color:#ef4444"></i></button>
            </div>
          </div>
          <div class="lt">${money(l.price * l.quantity)}</div>
        </div>`).join('');
    return `
      <div class="panel ticket">
        <div class="pt">Ticket de Caisse</div>
        <div class="tmeta"><div>${esc(p.name||'')}</div><div id="ticket-time">${now().stamp}</div></div>
        <div class="tlist">${lines}</div>
        <div class="sum">
          <div class="row"><span>Sous-total</span><span>${money(subtotal())}</span></div>
          <label class="check"><input type="checkbox" id="disc" ${S.discount?'checked':''}/> Appliquer une réduction (${S.discountPct}%)</label>
          <div class="row total"><span>Total</span><span>${money(total())}</span></div>
          <div class="actions">
            <button class="btn btn-s" id="cancel-ticket">Annuler</button>
            <button class="btn btn-p" id="ok-ticket" ${S.cart.length?'':'disabled'}><i class="fa-solid fa-check"></i> Valider</button>
          </div>
        </div>
      </div>`;
  }

  function chart(days) {
    days = days || [];
    if (!days.length) return `<div class="muted">Aucune vente sur 7 jours.</div>`;
    const max = Math.max(1, ...days.map((d) => Number(d.total) || 0));
    return `<div class="bars">${days.map((d) => {
      const h = Math.max(4, Math.round(((Number(d.total)||0)/max)*100));
      return `<div class="bar-col"><div class="b" style="height:${h}%"></div><span>${esc(String(d.day||'').slice(5))}</span></div>`;
    }).join('')}</div>`;
  }

  function dashboard() {
    const p = S.data?.player || {}, s = S.data?.stats || {}, sv = S.data?.service || {};
    return `<div class="page">
      <section class="welcome">
        <div>
          <div class="kicker"><i class="fa-solid fa-basket-shopping"></i> Restauration & Alimentation & Bar</div>
          <h2>Bonjour, ${esc(p.name||'')}</h2>
          <div class="duty"><span class="dot ${p.onDuty?'on':''}"></span>${esc(p.gradeLabel||'')} — ${(S.data?.restaurant?.label||'').toUpperCase()} · ${p.onDuty?'En service':'Hors service'}</div>
          <div style="margin-top:12px;display:flex;gap:8px">
            <button class="btn ${p.onDuty?'btn-d':'btn-p'}" id="btn-service">${p.onDuty?'🔴 Quitter le service':'🟢 Prendre le service'}</button>
            <button class="btn btn-v" data-go="sales">+ Nouvelle vente</button>
          </div>
        </div>
        <div class="clockbox">
          <strong id="live">${now().time}</strong>
          <span id="livedate" class="muted">${now().date}</span>
          <div class="muted" style="margin-top:10px;font-size:12px">Aujourd'hui ${dur(sv.today)} · Semaine ${dur(sv.week)}</div>
        </div>
      </section>
      <section class="stats">
        <div class="stat"><i class="fa-solid fa-dollar-sign"></i><div><span>Total des ventes</span><strong>${money(s.salesTotal)}</strong></div></div>
        <div class="stat"><i class="fa-solid fa-bag-shopping"></i><div><span>Nombre de ventes</span><strong>${s.salesCount||0}</strong></div></div>
        <div class="stat"><i class="fa-solid fa-chart-line"></i><div><span>Gains livraisons</span><strong>${money(s.deliveryEarnings)}</strong></div></div>
        <div class="stat"><i class="fa-solid fa-truck"></i><div><span>Livraisons</span><strong>${s.deliveryCount||0}</strong></div></div>
        <div class="stat"><i class="fa-solid fa-wallet"></i><div><span>Salaire (${p.commissionPercent||0}%)</span><strong>${money(s.commission)}</strong></div></div>
      </section>
      <section class="two">
        <div class="panel"><div class="pt">Ventes 7 jours</div>${chart(s.chartWeek)}
          <div style="margin-top:12px;display:grid;grid-template-columns:repeat(3,1fr);gap:8px;font-size:12px;color:var(--mut)">
            <div>Jour<br><strong style="color:var(--txt)">${money(s.salesToday)}</strong></div>
            <div>Semaine<br><strong style="color:var(--txt)">${money(s.salesWeek)}</strong></div>
            <div>Mois<br><strong style="color:var(--txt)">${money(s.salesMonth)}</strong></div>
          </div>
        </div>
        <div class="panel"><div class="pt">Produits populaires</div>
          <div class="list">${(s.topProducts||[]).map((tp)=>`<div class="item"><div><strong>${esc(tp.product_label)}</strong><div class="muted" style="font-size:12px">${tp.qty||0} vendus</div></div><strong>${money(tp.revenue)}</strong></div>`).join('')||'<div class="muted">Pas encore de données.</div>'}
          </div>
        </div>
      </section>
      <section>
        <div class="pt" style="margin-bottom:10px">Accès rapide</div>
        <div class="quick">
          <div class="qcard" data-go="sales"><div class="qi" style="background:#20c66b"><i class="fa-solid fa-calculator"></i></div><h4>Comptabilité</h4><p>Gestion des ventes</p></div>
          <div class="qcard" data-go="orders"><div class="qi" style="background:#f59e0b"><i class="fa-solid fa-cart-shopping"></i></div><h4>Commandes</h4><p>Ingrédients à commander</p></div>
          <div class="qcard" data-go="employees"><div class="qi" style="background:#8b5cf6"><i class="fa-solid fa-users"></i></div><h4>Employés</h4><p>Gestion de l'équipe</p></div>
          <div class="qcard" data-go="stock"><div class="qi" style="background:#ef4444"><i class="fa-solid fa-boxes-stacked"></i></div><h4>Stock</h4><p>Inventaire cuisine</p></div>
          <div class="qcard" data-go="billing"><div class="qi" style="background:#3b82f6"><i class="fa-solid fa-file-invoice"></i></div><h4>Factures</h4><p>TPE & facturation</p></div>
          <div class="qcard" data-go="deliveries"><div class="qi" style="background:#14b8a6"><i class="fa-solid fa-truck"></i></div><h4>Livraisons</h4><p>Suivi des commandes</p></div>
        </div>
      </section>
    </div>`;
  }

  function sales() {
    return `<div class="page"><div><h1>Caisse</h1><p class="muted">Ajoutez des produits puis validez le ticket.</p></div>
      <div class="sales"><div class="panel"><div class="pt">Menu des Produits</div><div class="products">${productGrid(S.data?.products)}</div></div>${ticket()}</div></div>`;
  }
  function products() {
    return `<div class="page"><div><h1>Produits</h1><p class="muted">Catalogue vendable.</p></div><div class="products">${productGrid(S.data?.products)}</div></div>`;
  }
  function recipes() {
    return `<div class="page"><div><h1>Recettes</h1><p class="muted">Préparez depuis la cuisine ou ici.</p></div>
      <div class="quick">${(S.data?.recipes||[]).map((r)=>`
        <div class="rcard"><h3>${esc(r.label)}</h3>
          <div class="muted" style="font-size:12px">${Math.floor((r.time||0)/1000)}s · Grade ${r.grade||0}+</div>
          <div class="ings">${(r.ingredients||[]).map((i)=>`<span class="ing">${i.amount}× ${esc(i.label)}</span>`).join('')}</div>
          <button class="btn btn-p" data-craft="${r.id}" style="width:100%"><i class="fa-solid fa-fire"></i> Préparer</button>
        </div>`).join('')}</div></div>`;
  }

  async function history() {
    const res = await nui('getSales', { period: S.salesFilter });
    const salesList = res?.sales || [];
    return `<div class="page"><div><h1>Historique des ventes</h1><p class="muted">Filtres et tickets.</p></div>
      <div class="filters">${[['today',"Aujourd'hui"],['week','Semaine'],['month','Mois'],['','Tout']].map(([f,l])=>`
        <button class="chipf ${S.salesFilter===f?'active':''}" data-filter="${f}">${l}</button>`).join('')}</div>
      <div class="list">${salesList.map((s)=>`
        <div class="item"><div><strong>#${s.id}</strong>
          <div class="muted" style="font-size:12px;margin-top:4px">${esc(s.created_at||'')} · ${esc(s.customer_name||'Client')} · ${esc(s.employee_name||'')}</div>
          <div class="muted" style="font-size:12px">${esc(s.items_summary||'')}</div>
        </div><strong style="color:var(--green)">${money(s.amount)}</strong></div>`).join('')||'<div class="panel">Aucune vente.</div>'}</div></div>`;
  }

  async function stock() {
    const res = await nui('getStock');
    const items = res?.stock || [];
    return `<div class="page"><div><h1>Gestion du stock</h1><p class="muted">Niveaux et alertes.</p></div>
      <div class="list">${items.map((i)=>`
        <div class="item"><div style="display:flex;gap:12px;align-items:center"><span style="font-size:22px">${i.icon||'📦'}</span>
          <div><strong>${esc(i.label)}</strong><div class="muted" style="font-size:12px">Min ${i.min} · Max ${i.max}</div></div></div>
          <div style="text-align:right"><strong style="font-size:20px">${i.quantity}</strong>
            <div style="margin-top:4px"><span class="badge ${i.status}">${i.status==='ok'?'🟢 Stock normal':i.status==='low'?'🟠 Stock faible':'🔴 Rupture'}</span></div>
          </div></div>`).join('')||'<div class="panel">Stock vide.</div>'}</div></div>`;
  }

  async function orders() {
    const res = await nui('getStock');
    const items = res?.stock || [];
    return `<div class="page"><div><h1>Commander des produits</h1><p class="muted">Commande fournisseur.</p></div>
      <div class="panel form" id="order-form">${items.map((i)=>`
        <div class="field" style="display:grid;grid-template-columns:1fr 120px;gap:10px;align-items:end">
          <div><label>${i.icon||''} ${esc(i.label)} <span class="muted">(stock ${i.quantity})</span></label>
            <div class="muted" style="font-size:12px">Prix unit. ${money(i.orderPrice)}</div></div>
          <input type="number" min="0" max="500" value="0" data-oi="${i.item}"/>
        </div>`).join('')}
        <button class="btn btn-p" id="place-order"><i class="fa-solid fa-paper-plane"></i> Passer la commande</button>
      </div></div>`;
  }

  async function deliveries() {
    const res = await nui('getOrders');
    const list = res?.orders || [];
    return `<div class="page"><div><h1>Livraisons</h1><p class="muted">Prenez en charge les commandes.</p></div>
      <div class="list">${list.map((o)=>`
        <div class="item" style="align-items:flex-start"><div>
          <strong>Commande #${o.id}</strong>
          <div class="muted" style="font-size:12px;margin:6px 0">${(o.items||[]).map((it)=>`${it.quantity}x ${esc(it.label)}`).join(' · ')}</div>
          <span class="badge ${o.delivery_status==='waiting'?'low':o.delivery_status==='completed'?'ok':'on'}">
            ${o.delivery_status==='waiting'?'🚚 En attente':o.delivery_status==='in_progress'?'🚚 En livraison':o.status}
          </span></div>
          <div style="display:flex;flex-direction:column;gap:8px;align-items:flex-end">
            <strong>${money(o.total_cost)}</strong>
            ${o.delivery_status==='waiting'&&o.delivery_id?`<button class="btn btn-p" data-take="${o.delivery_id}">Prendre la livraison</button>`:''}
          </div></div>`).join('')||'<div class="panel">Aucune livraison.</div>'}</div></div>`;
  }

  async function employees() {
    const res = await nui('getEmployees');
    const list = res?.employees || [];
    const me = S.data?.player?.name;
    return `<div class="page">
      <div style="display:flex;justify-content:space-between;align-items:end">
        <div><h1>Employés</h1><p class="muted">Équipe et grades.</p></div>
        ${can('employees')?`<button class="btn btn-p" id="hire"><i class="fa-solid fa-user-plus"></i> Recruter</button>`:''}
      </div>
      <div class="list">${list.map((e)=>`
        <div class="item ${e.name===me?'me':''}"><div>
          <strong>${esc(e.name)}</strong>
          <div class="muted" style="font-size:12px;margin-top:4px">${esc(e.gradeLabel)} — ${e.commission}% · Ventes ${money(e.totalSales)} · Service ${dur(e.serviceSeconds)}</div>
        </div>
        <div style="display:flex;gap:8px;align-items:center">
          <span class="badge ${e.online?'on':'off'}">${e.online?(e.onDuty?'En service':'En ligne'):'Hors ligne'}</span>
          ${can('employees')?`
            <select data-grade="${esc(e.identifier)}" style="background:#121e30;color:var(--txt);border:1px solid var(--line);border-radius:8px;padding:6px">
              ${[0,1,2,3,4].map((g)=>`<option value="${g}" ${g===e.grade?'selected':''}>${g}</option>`).join('')}
            </select>
            <button class="btn btn-d" data-fire="${esc(e.identifier)}">Licencier</button>`:''}
        </div></div>`).join('')||'<div class="panel">Aucun employé.</div>'}</div></div>`;
  }

  async function billing() {
    const inv = (await nui('getInvoices'))?.invoices || [];
    return `<div class="page"><div><h1>Factures</h1><p class="muted">Créer une facture TPE.</p></div>
      <div class="two">
        <div class="panel"><div class="pt">Créer une facture</div>
          <div class="form">
            <div class="field"><label>Montant</label><input id="inv-a" type="number" min="1" value="${total()||20000}"/></div>
            <div class="field"><label>Raison</label><input id="inv-r" type="text" value="${esc(reason()||'Formule Mini Dino x15')}"/></div>
            <div class="field"><label>ID cible</label><input id="inv-t" type="number" min="1" placeholder="106"/></div>
            <button class="btn btn-v" id="mk-inv">Créer</button>
            <button class="btn btn-s" id="pick-near">Choisir un joueur proche</button>
          </div>
        </div>
        <div class="panel"><div class="pt">Historique</div>
          <div class="list">${inv.map((i)=>`
            <div class="item"><div><strong>#${i.id} · ${money(i.amount)}</strong>
              <div class="muted" style="font-size:12px">${esc(i.reason||'')}</div>
              <div class="muted" style="font-size:12px">${esc(i.target_name)} · ${esc(i.status)}</div>
            </div><span class="badge ${i.status==='paid'?'ok':i.status==='pending'?'low':'out'}">${i.status}</span></div>`).join('')||'<div class="muted">Aucune facture.</div>'}
          </div>
        </div>
      </div></div>`;
  }

  function settings() {
    const notes = S.data?.patchNotes || [];
    return `<div class="page"><div><h1>Paramètres</h1><p class="muted">Restaurant & patch notes.</p></div>
      <div class="two">
        <div class="panel"><div class="pt">Restaurant</div>
          <div class="form">
            <div class="field"><label>Clé</label><input value="${esc(S.data?.restaurant?.key||'')}" disabled/></div>
            <div class="field"><label>Label</label><input value="${esc(S.data?.restaurant?.label||'')}" disabled/></div>
            <div class="field"><label>Job</label><input value="${esc(S.data?.restaurant?.job||'')}" disabled/></div>
          </div>
        </div>
        <div class="panel"><div class="pt">Patch Notes</div>
          ${notes.map((n)=>`<div style="margin-bottom:14px"><strong>v${esc(n.version)}</strong> <span class="muted" style="font-size:12px">${esc(n.date||'')}</span>
            <ul style="margin-top:8px;padding-left:18px;color:var(--mut);font-size:13px">${(n.notes||[]).map((x)=>`<li>${esc(x)}</li>`).join('')}</ul></div>`).join('')||'<div class="muted">Aucune note.</div>'}
        </div>
      </div></div>`;
  }

  async function render() {
    header();
    let html = '';
    switch (S.page) {
      case 'dashboard': html = dashboard(); break;
      case 'sales': html = sales(); break;
      case 'products': html = products(); break;
      case 'recipes': html = recipes(); break;
      case 'history': html = await history(); break;
      case 'stock': html = await stock(); break;
      case 'orders': html = await orders(); break;
      case 'deliveries': html = await deliveries(); break;
      case 'employees': html = await employees(); break;
      case 'billing': html = await billing(); break;
      case 'settings': html = settings(); break;
      default: html = dashboard();
    }
    content.innerHTML = html;
    bind();
  }

  function openModal(html) { box.innerHTML = html; modal.classList.remove('hidden'); }
  function closeModal() { modal.classList.add('hidden'); box.innerHTML = ''; }

  async function payModal() {
    const players = await nui('getNearbyPlayers') || [];
    if (!players.length) {
      await nui('notify', { title: 'Caisse', description: 'Aucun client à proximité.', type: 'error' });
      return;
    }
    openModal(`<h3>Client</h3>
      <div class="list" style="max-height:280px;overflow:auto">${players.map((p)=>`
        <div class="item"><div><strong>ID ${p.id}</strong><div class="muted" style="font-size:12px">${esc(p.name)} · ${p.distance}m</div></div>
          <div style="display:flex;gap:6px">
            <button class="btn btn-p" data-pay="${p.id}" data-m="cash">Cash</button>
            <button class="btn btn-v" data-pay="${p.id}" data-m="bank">Carte</button>
            <button class="btn btn-s" data-bill="${p.id}">Facturer</button>
          </div></div>`).join('')}</div>
      <div class="ma"><button class="btn btn-s" id="modal-close">Retour</button></div>`);
  }

  async function processSale(targetId, method) {
    const result = await nui('processSale', {
      targetId: Number(targetId),
      cart: S.cart.map((l) => ({ id: l.id, quantity: l.quantity })),
      paymentMethod: method,
      discount: S.discount ? S.discountPct : 0,
    });
    if (!result?.ok) {
      await nui('notify', { title: 'Caisse', description: result?.error || 'Échec', type: 'error' });
      return;
    }
    clearCart();
    closeModal();
    const refreshed = await nui('refresh');
    if (refreshed?.ok) S.data = refreshed;
    await render();
  }

  function bind() {
    content.querySelectorAll('[data-add]').forEach((el) => el.addEventListener('click', () => {
      const p = (S.data?.products || []).find((x) => x.id === el.dataset.add);
      if (p) add(p);
    }));
    content.querySelectorAll('[data-qty]').forEach((el) => el.addEventListener('click', () => qty(el.dataset.qty, Number(el.dataset.d))));
    content.querySelectorAll('[data-rm]').forEach((el) => el.addEventListener('click', () => { S.cart = S.cart.filter((x) => x.id !== el.dataset.rm); render(); }));
    content.querySelectorAll('[data-go]').forEach((el) => el.addEventListener('click', () => nav(el.dataset.go)));
    const disc = document.getElementById('disc');
    if (disc) disc.addEventListener('change', () => { S.discount = disc.checked; render(); });
    document.getElementById('cancel-ticket')?.addEventListener('click', clearCart);
    document.getElementById('ok-ticket')?.addEventListener('click', payModal);
    document.getElementById('btn-service')?.addEventListener('click', async () => {
      const r = await nui('toggleService');
      if (r?.ok) {
        const refreshed = await nui('refresh');
        if (refreshed?.ok) S.data = refreshed;
        await render();
      }
    });
    content.querySelectorAll('[data-craft]').forEach((el) => el.addEventListener('click', () => nui('startCraft', { recipeId: el.dataset.craft })));
    content.querySelectorAll('[data-filter]').forEach((el) => el.addEventListener('click', () => { S.salesFilter = el.dataset.filter; render(); }));
    document.getElementById('place-order')?.addEventListener('click', async () => {
      const items = [];
      content.querySelectorAll('[data-oi]').forEach((input) => {
        const q = Number(input.value || 0);
        if (q > 0) items.push({ item: input.dataset.oi, quantity: q });
      });
      const r = await nui('createOrder', items);
      await nui('notify', { title: 'Commandes', description: r?.ok ? `Commande #${r.data}` : (r?.data || 'Échec'), type: r?.ok ? 'success' : 'error' });
      if (r?.ok) nav('deliveries');
    });
    content.querySelectorAll('[data-take]').forEach((el) => el.addEventListener('click', async () => {
      const r = await nui('takeDelivery', { deliveryId: Number(el.dataset.take) });
      await nui('notify', { title: 'Livraisons', description: r?.ok ? 'Prise en charge' : (r?.data || 'Échec'), type: r?.ok ? 'success' : 'error' });
      if (r?.ok) await nui('close');
    }));
    document.getElementById('hire')?.addEventListener('click', async () => {
      const players = await nui('getNearbyPlayers') || [];
      if (!players.length) return nui('notify', { title: 'Employés', description: 'Aucun joueur proche.', type: 'error' });
      openModal(`<h3>Recruter</h3><div class="form">
        <div class="field"><label>Joueur</label><select id="h-t">${players.map((p)=>`<option value="${p.id}">ID ${p.id} — ${esc(p.name)}</option>`).join('')}</select></div>
        <div class="field"><label>Grade</label><select id="h-g"><option value="0">Stagiaire</option><option value="1" selected>Employé</option><option value="2">Cuisinier</option><option value="3">Manager</option></select></div>
      </div><div class="ma"><button class="btn btn-s" id="modal-close">Retour</button><button class="btn btn-p" id="h-ok">Recruter</button></div>`);
      document.getElementById('h-ok')?.addEventListener('click', async () => {
        const r = await nui('hireEmployee', { targetId: Number(document.getElementById('h-t').value), grade: Number(document.getElementById('h-g').value) });
        closeModal();
        await nui('notify', { title: 'Employés', description: r?.message || '', type: r?.ok ? 'success' : 'error' });
        await render();
      });
    });
    content.querySelectorAll('[data-fire]').forEach((el) => el.addEventListener('click', async () => {
      const r = await nui('fireEmployee', { citizenid: el.dataset.fire });
      await nui('notify', { title: 'Employés', description: r?.message || '', type: r?.ok ? 'success' : 'error' });
      await render();
    }));
    content.querySelectorAll('[data-grade]').forEach((el) => el.addEventListener('change', async () => {
      const r = await nui('setEmployeeGrade', { citizenid: el.dataset.grade, grade: Number(el.value) });
      await nui('notify', { title: 'Employés', description: r?.message || '', type: r?.ok ? 'success' : 'error' });
      await render();
    }));
    document.getElementById('mk-inv')?.addEventListener('click', async () => {
      const r = await nui('createInvoice', {
        targetId: Number(document.getElementById('inv-t').value),
        amount: Number(document.getElementById('inv-a').value),
        reason: document.getElementById('inv-r').value,
      });
      await nui('notify', { title: 'Factures', description: r?.ok ? `Facture #${r.invoiceId}` : (r?.error || 'Échec'), type: r?.ok ? 'success' : 'error' });
      if (r?.ok) await render();
    });
    document.getElementById('pick-near')?.addEventListener('click', async () => {
      const players = await nui('getNearbyPlayers') || [];
      if (players[0]) document.getElementById('inv-t').value = players[0].id;
    });
  }

  async function nav(page) {
    if (!page) return;
    const link = document.querySelector(`.link[data-nav="${page}"]`);
    if (link?.classList.contains('disabled')) {
      await nui('notify', { title: 'Tablette', description: 'Permission insuffisante.', type: 'error' });
      return;
    }
    S.page = page;
    await render();
  }

  document.getElementById('btn-close').onclick = () => nui('close');
  document.getElementById('btn-refresh').onclick = async () => {
    const r = await nui('refresh');
    if (r?.ok) { S.data = r; await render(); }
  };
  document.getElementById('btn-patch').onclick = () => nav('settings');
  document.querySelectorAll('[data-nav]').forEach((el) => el.addEventListener('click', () => nav(el.dataset.nav)));

  modal.addEventListener('click', (e) => {
    if (e.target === modal || e.target.id === 'modal-close') closeModal();
    const pay = e.target.closest?.('[data-pay]');
    if (pay) processSale(pay.dataset.pay, pay.dataset.m);
    const bill = e.target.closest?.('[data-bill]');
    if (bill) {
      closeModal();
      S.page = 'billing';
      render().then(() => {
        const t = document.getElementById('inv-t');
        const a = document.getElementById('inv-a');
        const r = document.getElementById('inv-r');
        if (t) t.value = bill.dataset.bill;
        if (a) a.value = total();
        if (r) r.value = reason();
      });
    }
  });

  window.addEventListener('message', (e) => {
    const msg = e.data || {};
    if (msg.action === 'open') {
      S.open = true; S.data = msg.data; S.page = msg.page || 'dashboard';
      app.classList.remove('hidden'); clock(); render();
    }
    if (msg.action === 'close') {
      S.open = false; app.classList.add('hidden'); closeModal();
      if (S.timer) clearInterval(S.timer);
    }
    if (msg.action === 'serviceUpdate' && S.data?.player) {
      S.data.player.onDuty = !!msg.onDuty; render();
    }
  });

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && S.open) nui('close');
  });

  // Preview navigateur (hors FiveM) — ?preview=1 ou ouverture hors resource FiveM
  const isPreview = typeof GetParentResourceName !== 'function'
    || new URLSearchParams(location.search).has('preview');
  if (isPreview) {
    const mock = {
      ok: true,
      player: {
        firstname: 'Paquito', lastname: 'Morales', name: 'Paquito Morales',
        grade: 1, gradeLabel: 'Employé', onDuty: true,
        commissionRate: 0.25, commissionPercent: 25, avatar: 'P',
      },
      restaurant: { key: 'rex_diner', label: 'Rex Diner', job: 'rex_diner' },
      permissions: {
        tablet: true, sales: true, service: true, recipes: true, billing: true,
        kitchen: true, employees: true, stock: true, orders: true, deliveries: true,
        finances: true, settings: true,
      },
      stats: {
        salesTotal: 68500, salesCount: 17, salesToday: 24000, salesWeek: 51200, salesMonth: 68500,
        deliveryCount: 1, deliveryEarnings: 1350, commission: 17463, mySales: 24000,
        topProducts: [
          { product_label: 'Formule Mini Dino', qty: 15, revenue: 12000 },
          { product_label: 'Plat', qty: 10, revenue: 5000 },
          { product_label: 'Burger', qty: 5, revenue: 3000 },
        ],
        chartWeek: [
          { day: '2026-08-13', total: 4200 }, { day: '2026-08-14', total: 8100 },
          { day: '2026-08-15', total: 6500 }, { day: '2026-08-16', total: 9200 },
          { day: '2026-08-17', total: 7800 }, { day: '2026-08-18', total: 8700 },
          { day: '2026-08-19', total: 24000 },
        ],
      },
      service: { today: 16320, week: 78420, onDuty: true },
      products: [
        { id: 'formula_jurassic_royal', label: 'Formule Jurassic Royal', price: 1400, category: 'Menus', color: '#C0392B' },
        { id: 'formula_mini_dino', label: 'Formule Mini Dino', price: 800, category: 'Menus', color: '#E74C3C' },
        { id: 'plat', label: 'Plat', price: 500, category: 'Petite Faim', color: '#E67E22' },
        { id: 'burger', label: 'Burger', price: 600, category: 'Petite Faim', color: '#D35400' },
        { id: 'dessert', label: 'Dessert', price: 600, category: 'Desserts', color: '#8E44AD' },
        { id: 'boisson', label: 'Boisson', price: 400, category: 'Boissons', color: '#5D6D7E' },
      ],
      recipes: [
        { id: 'burger_classic', label: 'Burger Classic', time: 10000, grade: 2, ingredients: [
          { label: 'Pain', amount: 1 }, { label: 'Viande', amount: 1 }, { label: 'Fromage', amount: 1 },
        ]},
        { id: 'fries', label: 'Frites', time: 7000, grade: 1, ingredients: [
          { label: 'Pomme de terre', amount: 2 }, { label: 'Huile', amount: 1 },
        ]},
      ],
      patchNotes: ConfigPatchNotes(),
      currency: '$', maxDiscount: 50,
      features: { billing: true, deliveries: true, crafting: true, employees: true, stock: true },
    };

    // Mock NUI callbacks for preview navigation
    const originalNui = nui;
    window.__previewStock = [
      { item: 'meat', label: 'Viande', icon: '🥩', quantity: 42, max: 200, min: 20, status: 'ok', orderPrice: 25 },
      { item: 'bread', label: 'Pain', icon: '🍞', quantity: 86, max: 200, min: 30, status: 'ok', orderPrice: 8 },
      { item: 'cheese', label: 'Fromage', icon: '🧀', quantity: 31, max: 150, min: 20, status: 'ok', orderPrice: 12 },
      { item: 'lettuce', label: 'Salade', icon: '🥬', quantity: 8, max: 150, min: 20, status: 'low', orderPrice: 6 },
      { item: 'potato', label: 'Pommes de terre', icon: '🥔', quantity: 120, max: 250, min: 40, status: 'ok', orderPrice: 4 },
      { item: 'oil', label: 'Huile', icon: '🫒', quantity: 0, max: 100, min: 15, status: 'out', orderPrice: 10 },
    ];
    // redefine nui via closure replacement for preview-only events
    async function previewNui(event, data = {}) {
      if (event === 'close') return { ok: true };
      if (event === 'refresh') return mock;
      if (event === 'getStats') return mock.stats;
      if (event === 'getStock') return { ok: true, stock: window.__previewStock };
      if (event === 'getOrders') return { ok: true, orders: [
        { id: 1048, total_cost: 1850, status: 'pending', delivery_id: 12, delivery_status: 'waiting',
          items: [{ quantity: 50, label: 'Viande' }, { quantity: 100, label: 'Pain' }, { quantity: 50, label: 'Fromage' }] },
      ]};
      if (event === 'getSales') return { ok: true, sales: [
        { id: 1045, created_at: '14/08/2026 20:18', customer_name: 'Aaron Banning', employee_name: 'Paquito Morales', amount: 24000, items_summary: 'Formule Mini Dino x15, Plat x10, Burger x5' },
        { id: 1044, created_at: '14/08/2026 19:02', customer_name: 'Michael Smith', employee_name: 'James Peterson', amount: 12000, items_summary: 'Formule Jurassic Royal x5' },
      ]};
      if (event === 'getEmployees') return { ok: true, employees: [
        { identifier: 'a', name: 'James Peterson', grade: 4, gradeLabel: 'Patron', commission: 30, online: true, onDuty: true, totalSales: 40000, totalCommission: 12000, serviceSeconds: 90000 },
        { identifier: 'b', name: 'Paquito Morales', grade: 1, gradeLabel: 'Employé', commission: 25, online: true, onDuty: true, totalSales: 24000, totalCommission: 17463, serviceSeconds: 78420 },
        { identifier: 'c', name: 'Jay Horton', grade: 1, gradeLabel: 'Employé', commission: 25, online: false, onDuty: false, totalSales: 8000, totalCommission: 2000, serviceSeconds: 36000 },
      ]};
      if (event === 'getInvoices') return { ok: true, invoices: [
        { id: 88, amount: 24000, reason: 'Formule Mini Dino x15 Plat x10 Burger x5', target_name: 'Aaron Banning', status: 'paid' },
        { id: 87, amount: 20000, reason: 'Formule Mini Dino x15', target_name: 'Aaron Banning', status: 'pending' },
      ]};
      if (event === 'getNearbyPlayers') return [
        { id: 106, name: 'Aaron Banning', distance: 1.4 },
        { id: 112, name: 'Michael Smith', distance: 3.2 },
      ];
      if (event === 'notify' || event === 'toggleService' || event === 'processSale' || event === 'createInvoice'
        || event === 'createOrder' || event === 'takeDelivery' || event === 'hireEmployee'
        || event === 'fireEmployee' || event === 'setEmployeeGrade' || event === 'startCraft') {
        console.log('[preview]', event, data);
        return { ok: true, data: 1, message: 'OK (preview)', invoiceId: 99, sale: {} };
      }
      return originalNui(event, data);
    }
    // Monkey-patch by reassigning calls — replace nui usage through window hook
    const nuiRef = { fn: previewNui };
    // Override fetch-based nui: wrap existing function name in closure by replacing event handlers after open
    // Simplest: assign to outer nui via eval-style — redefine by posting open then patching
    Object.defineProperty(window, '__rexNui', { get: () => nuiRef.fn });

    // Patch: replace nui calls by swapping the const binding isn't possible; instead intercept fetch
    const realFetch = window.fetch.bind(window);
    window.fetch = async (url, opts) => {
      if (typeof url === 'string' && url.includes('https://rex_diner/')) {
        const event = url.split('/').pop();
        const body = opts && opts.body ? JSON.parse(opts.body) : {};
        const result = await previewNui(event, body);
        return {
          ok: true,
          json: async () => result,
        };
      }
      return realFetch(url, opts);
    };

    const page = new URLSearchParams(location.search).get('page') || 'dashboard';
    window.postMessage({ action: 'open', page, data: mock }, '*');

    // Seed cart on sales preview
    if (page === 'sales') {
      setTimeout(() => {
        S.cart = [
          { id: 'formula_mini_dino', label: 'Formule Mini Dino', price: 800, quantity: 15 },
          { id: 'burger', label: 'Burger', price: 600, quantity: 2 },
        ];
        render();
      }, 100);
    }
  }

  function ConfigPatchNotes() {
    return [{ version: '2.0.0', date: '19/08/2026', notes: [
      'Refonte complète du resource rex_diner',
      'Tablette NUI premium multi-pages',
      'Ventes, factures, craft, stock et livraisons',
    ]}];
  }
})();
