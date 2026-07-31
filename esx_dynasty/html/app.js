(() => {
  const app = document.getElementById('app');
  const companyPanel = document.getElementById('companyPanel');
  const housingPanel = document.getElementById('housingPanel');
  const detailModal = document.getElementById('detailModal');

  const state = {
    view: 'company',
    locale: {},
    currency: '$',
    data: null,
    playerPos: null,
    companyTab: 'dashboard',
    housingView: 'list',
    filterType: null,
    selectedProperty: null,
  };

  const resName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'esx_dynasty';

  function t(key, fallback) {
    return state.locale[key] || fallback || key;
  }

  function money(n) {
    const v = Number(n) || 0;
    return `${state.currency}${v.toLocaleString('fr-FR')}`;
  }

  function nui(name, payload = {}) {
    return fetch(`https://${resName}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload),
    }).then(async (r) => {
      try { return await r.json(); }
      catch { return {}; }
    }).catch(() => ({}));
  }

  function applyI18n() {
    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      if (state.locale[key]) el.textContent = state.locale[key];
    });
    const newsInput = document.getElementById('newsInput');
    if (newsInput) newsInput.placeholder = t('news_placeholder', newsInput.placeholder);
    const search = document.getElementById('propertySearch');
    if (search) search.placeholder = t('search_placeholder', search.placeholder);
    const billboard = document.getElementById('billboardInput');
    if (billboard) billboard.placeholder = t('billboard_placeholder', billboard.placeholder);
  }

  function setVisible(view) {
    state.view = view;
    app.classList.remove('hidden');
    companyPanel.classList.toggle('hidden', view !== 'company');
    housingPanel.classList.toggle('hidden', view !== 'housing');
    detailModal.classList.add('hidden');
  }

  function closeAll() {
    app.classList.add('hidden');
    companyPanel.classList.add('hidden');
    housingPanel.classList.add('hidden');
    detailModal.classList.add('hidden');
    nui('close');
  }

  function timeAgo(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    if (Number.isNaN(d.getTime())) return String(dateStr);
    const diff = Date.now() - d.getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `il y a ${Math.max(1, mins)} min`;
    const hours = Math.floor(mins / 60);
    if (hours < 48) return `il y a ${hours} h`;
    const days = Math.floor(hours / 24);
    if (days < 60) return `il y a ${days} j`;
    const months = Math.floor(days / 30);
    return `il y a ${months} mois`;
  }

  function statusLabel(status) {
    const map = {
      libre: t('free', 'Libre'),
      vente: t('for_sale', 'À vendre'),
      location: t('for_rent', 'Location'),
      occupe: t('occupied', 'Occupé'),
    };
    return map[status] || status;
  }

  function statusBadgeClass(status) {
    return status || 'libre';
  }

  function displayPrice(p) {
    if (p.status === 'location' || (p.price_rent > 0 && p.price_sale <= 0)) {
      return `${money(p.price_rent)}${t('rent_week', '/sem')}`;
    }
    if (p.price_sale > 0) return money(p.price_sale);
    if (p.price_rent > 0) return `${money(p.price_rent)}${t('rent_week', '/sem')}`;
    return '—';
  }

  // ─── Company tabs ──────────────────────────────────────────

  function setCompanyTab(tab) {
    state.companyTab = tab;
    document.querySelectorAll('#companyNav .nav-item').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.tab === tab);
    });
    document.querySelectorAll('#companyPanel .tab').forEach((el) => {
      el.classList.toggle('active', el.id === `tab-${tab}`);
    });
  }

  function renderNews() {
    const grid = document.getElementById('newsGrid');
    const news = (state.data && state.data.news) || [];
    if (!news.length) {
      grid.innerHTML = `<div class="empty-state" style="grid-column:1/-1">${t('no_news', 'Aucune actualité')}</div>`;
      return;
    }
    grid.innerHTML = news.slice(0, 9).map((n) => `
      <article class="news-card">
        <div class="news-top">
          <span class="news-author">${escapeHtml(n.author || '—')}</span>
          <span class="tag ${escapeHtml(n.type || 'normal')}">${escapeHtml(n.type || 'normal')}</span>
        </div>
        <div class="news-body">${escapeHtml(n.content || '')}</div>
        <div class="news-time">${timeAgo(n.created_at)}</div>
      </article>
    `).join('');
  }

  function renderEmployees() {
    const body = document.getElementById('employeesBody');
    const employees = (state.data && state.data.employees) || [];
    document.getElementById('employeesCount').textContent = `${employees.length} agents`;
    const canManage = state.data && state.data.permissions && state.data.permissions.manageEmployees;
    document.getElementById('hireBtn').disabled = !canManage;

    if (!employees.length) {
      body.innerHTML = `<tr><td colspan="4">${t('no_employees', 'Aucun employé')}</td></tr>`;
      return;
    }

    body.innerHTML = employees.map((e) => `
      <tr>
        <td>${escapeHtml(e.name)}</td>
        <td>${escapeHtml(String(e.grade_label ?? e.grade))}</td>
        <td class="${e.online ? 'online-dot' : 'offline-dot'}">${e.online ? t('online', 'En ligne') : t('offline', 'Hors ligne')}</td>
        <td>
          <div class="row-actions">
            <button class="btn ghost" data-act="promote" data-id="${escapeHtml(e.identifier)}" data-grade="${e.grade}" ${!canManage ? 'disabled' : ''}>${t('promote', 'Promouvoir')}</button>
            <button class="btn ghost" data-act="demote" data-id="${escapeHtml(e.identifier)}" data-grade="${e.grade}" ${!canManage ? 'disabled' : ''}>${t('demote', 'Rétrograder')}</button>
            <button class="btn danger" data-act="fire" data-id="${escapeHtml(e.identifier)}" ${!canManage ? 'disabled' : ''}>${t('fire', 'Licencier')}</button>
          </div>
        </td>
      </tr>
    `).join('');
  }

  function renderVehicles() {
    const grid = document.getElementById('vehicleGrid');
    const vehicles = (state.data && state.data.vehicles) || [];
    const grade = state.data && state.data.player ? state.data.player.grade : 0;
    grid.innerHTML = vehicles.map((v) => {
      const locked = grade < (v.minGrade || 0);
      return `
        <article class="vehicle-card">
          <div>
            <h3>${escapeHtml(v.label)}</h3>
            <p>${escapeHtml(v.model)} · grade ≥ ${v.minGrade || 0}</p>
          </div>
          <button class="btn primary" data-spawn="${escapeHtml(v.model)}" ${locked ? 'disabled' : ''}>
            ${locked ? t('vehicle_locked', 'Grade insuffisant') : t('spawn_vehicle', 'Sortir')}
          </button>
        </article>
      `;
    }).join('');
  }

  function renderBillboard() {
    const b = (state.data && state.data.billboard) || {};
    document.getElementById('billboardInput').value = b.content || '';
    document.getElementById('billboardMeta').textContent = b.updated_by
      ? `Mis à jour par ${b.updated_by}`
      : '—';
    const can = state.data && state.data.permissions && state.data.permissions.manageBillboard;
    document.getElementById('saveBillboardBtn').disabled = !can;
    document.getElementById('billboardInput').disabled = !can;
  }

  function renderCompany() {
    if (!state.data) return;
    const p = state.data.player || {};
    document.getElementById('companyPlayerName').textContent = p.name || '—';
    document.getElementById('companyJobLabel').textContent = p.job_label || 'Agent immobilier';
    document.getElementById('dashTitle').textContent = p.job_label || 'Agent immobilier';

    const canNews = state.data.permissions && state.data.permissions.postNews;
    document.getElementById('postNewsBtn').disabled = !canNews;
    document.getElementById('newsInput').disabled = !canNews;

    renderNews();
    renderEmployees();
    renderVehicles();
    renderBillboard();
  }

  // ─── Housing ───────────────────────────────────────────────

  function fillInteriors() {
    const sel = document.getElementById('fInterior');
    const interiors = (state.data && state.data.interiors) || [];
    sel.innerHTML = interiors.map((i) =>
      `<option value="${escapeHtml(i.id)}" data-type="${escapeHtml(i.type)}">${escapeHtml(i.label)}</option>`
    ).join('');
  }

  function renderStats() {
    const s = (state.data && state.data.stats) || {};
    document.getElementById('statsRow').innerHTML = `
      <div class="stat-chip"><div class="stat-ico">⌂</div><div><div class="n">${s.total || 0}</div><div class="l">${t('stat_total', 'Biens')}</div></div></div>
      <div class="stat-chip"><div class="stat-ico">A</div><div><div class="n">${s.agents || 0}</div><div class="l">${t('stat_players', 'Agents')}</div></div></div>
      <div class="stat-chip"><div class="stat-ico">●</div><div><div class="n">${s.online || 0}</div><div class="l">${t('stat_online', 'En ligne')}</div></div></div>
      <div class="stat-chip"><div class="stat-ico">✓</div><div><div class="n">${s.active || 0}</div><div class="l">${t('stat_active', 'Actifs')}</div></div></div>
      <div class="stat-chip"><div class="stat-ico">K</div><div><div class="n">${s.keys || 0}</div><div class="l">${t('stat_keys', 'Clés')}</div></div></div>
    `;
  }

  function getFilteredProperties() {
    let list = [...((state.data && state.data.properties) || [])];
    const q = (document.getElementById('propertySearch').value || '').trim().toLowerCase();
    const status = document.getElementById('sortStatus').value;
    const priceSort = document.getElementById('sortPrice').value;

    if (state.filterType === 'appartement') {
      list = list.filter((p) => (p.property_type || '').toLowerCase().includes('appart'));
    }
    if (status !== 'all') list = list.filter((p) => p.status === status);
    if (q) {
      list = list.filter((p) =>
        `${p.label} ${p.address} ${p.owner_name || ''} ${p.renter_name || ''} ${p.property_type || ''}`
          .toLowerCase()
          .includes(q)
      );
    }

    list.sort((a, b) => {
      const pa = Math.max(a.price_sale || 0, a.price_rent || 0);
      const pb = Math.max(b.price_sale || 0, b.price_rent || 0);
      return priceSort === 'low' ? pa - pb : pb - pa;
    });
    return list;
  }

  function renderProperties() {
    const grid = document.getElementById('propertyGrid');
    const empty = document.getElementById('propertyEmpty');
    const list = getFilteredProperties();
    if (!list.length) {
      grid.innerHTML = '';
      empty.classList.remove('hidden');
      return;
    }
    empty.classList.add('hidden');
    grid.innerHTML = list.map((p) => {
      const owner = p.owner_name || p.renter_name || '—';
      const keys = (p.keys || []).map((k) => k.player_name || k.identifier).slice(0, 2).join(', ') || '—';
      return `
        <article class="property-card" data-id="${p.id}">
          <div class="property-thumb">
            <span class="badge ${statusBadgeClass(p.status)}">${escapeHtml(statusLabel(p.status))}</span>
          </div>
          <div class="property-body">
            <div class="property-title-row">
              <h3>${escapeHtml(p.label)}</h3>
              <span class="property-price">${escapeHtml(displayPrice(p))}</span>
            </div>
            <div class="property-type">${escapeHtml(p.property_type || p.interior || '')}</div>
            <div class="property-line">
              <svg viewBox="0 0 24 24"><path d="M12 21s7-5.5 7-11a7 7 0 1 0-14 0c0 5.5 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/></svg>
              <span>${escapeHtml(p.address || 'Sans adresse')}</span>
            </div>
            <div class="property-line">
              <svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="3"/><path d="M5 19c0-3.5 3-6 7-6s7 2.5 7 6"/></svg>
              <span>${t('owner', 'Propriétaire')}: ${escapeHtml(owner)}</span>
            </div>
            <div class="property-line">
              <svg viewBox="0 0 24 24"><path d="M7 11V8a5 5 0 0 1 10 0v3"/><rect x="5" y="11" width="14" height="10" rx="2"/></svg>
              <span>${t('keys', 'Clés')}: ${escapeHtml(keys)}</span>
            </div>
          </div>
        </article>
      `;
    }).join('');
  }

  function setHousingView(view) {
    state.housingView = view;
    document.querySelectorAll('#housingNav .nav-item').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.hview === view || (view === 'create' && btn.dataset.hview === 'create'));
    });
    document.getElementById('housingListView').classList.toggle('active', view !== 'create');
    document.getElementById('housingCreateView').classList.toggle('active', view === 'create');

    if (view === 'apartments') {
      state.filterType = 'appartement';
      renderProperties();
    } else if (view === 'list' || view === 'search') {
      state.filterType = null;
      renderProperties();
      if (view === 'search') document.getElementById('propertySearch').focus();
    } else if (view === 'create') {
      resetForm();
    }
  }

  function resetForm() {
    document.getElementById('propertyForm').reset();
    document.getElementById('editId').value = '';
    document.getElementById('createTitle').textContent = t('create_property', 'Créer un logement');
    document.getElementById('submitPropertyBtn').textContent = t('create', 'Créer');
    if (state.playerPos) {
      document.getElementById('fX').value = state.playerPos.x.toFixed(2);
      document.getElementById('fY').value = state.playerPos.y.toFixed(2);
      document.getElementById('fZ').value = state.playerPos.z.toFixed(2);
      document.getElementById('fH').value = (state.playerPos.h || 0).toFixed(2);
    }
    const canCreate = state.data && state.data.permissions && state.data.permissions.createProperty;
    document.getElementById('submitPropertyBtn').disabled = !canCreate;
  }

  function fillForm(p) {
    document.getElementById('editId').value = p.id;
    document.getElementById('fLabel').value = p.label || '';
    document.getElementById('fAddress').value = p.address || '';
    document.getElementById('fInterior').value = p.interior || '';
    document.getElementById('fType').value = p.property_type || 'appartement';
    document.getElementById('fStatus').value = p.status || 'libre';
    document.getElementById('fSale').value = p.price_sale || 0;
    document.getElementById('fRent').value = p.price_rent || 0;
    document.getElementById('fDesc').value = p.description || '';
    document.getElementById('fX').value = p.entrance?.x ?? '';
    document.getElementById('fY').value = p.entrance?.y ?? '';
    document.getElementById('fZ').value = p.entrance?.z ?? '';
    document.getElementById('fH').value = p.entrance?.h ?? 0;
    document.getElementById('gX').value = p.garage?.x ?? '';
    document.getElementById('gY').value = p.garage?.y ?? '';
    document.getElementById('gZ').value = p.garage?.z ?? '';
    document.getElementById('gH').value = p.garage?.h ?? '';
    document.getElementById('createTitle').textContent = t('edit_property', 'Modifier le logement');
    document.getElementById('submitPropertyBtn').textContent = t('update', 'Mettre à jour');
    setHousingView('create');
  }

  function openDetail(id) {
    const p = ((state.data && state.data.properties) || []).find((x) => x.id === id);
    if (!p) return;
    state.selectedProperty = p;
    const perms = (state.data && state.data.permissions) || {};

    document.getElementById('detailBadge').textContent = statusLabel(p.status);
    document.getElementById('detailBadge').className = `badge ${statusBadgeClass(p.status)}`;
    document.getElementById('detailTitle').textContent = p.label;
    document.getElementById('detailAddress').textContent = p.address || '—';
    document.getElementById('detailSale').textContent = money(p.price_sale);
    document.getElementById('detailRent').textContent = `${money(p.price_rent)}${t('rent_week', '/sem')}`;
    document.getElementById('detailDesc').textContent = p.description || '';
    document.getElementById('detailOwner').textContent = p.owner_name || '—';
    document.getElementById('detailRenter').textContent = p.renter_name || '—';
    document.getElementById('detailInterior').textContent = p.interior || '—';
    document.getElementById('detailType').textContent = p.property_type || '—';

    const keysList = document.getElementById('keysList');
    const keys = p.keys || [];
    keysList.innerHTML = keys.length
      ? keys.map((k) => `
          <li>
            <span>${escapeHtml(k.player_name || k.identifier)}</span>
            ${perms.sellProperty ? `<button class="btn ghost" data-remove-key="${escapeHtml(k.identifier)}">${t('remove_keys', 'Retirer')}</button>` : ''}
          </li>
        `).join('')
      : '<li><span>Aucune clé</span></li>';

    const actions = document.getElementById('detailActions');
    actions.innerHTML = `
      ${perms.editProperty ? `<button class="btn ghost" id="actEdit">${t('edit_property', 'Modifier')}</button>` : ''}
      ${perms.sellProperty ? `<button class="btn primary" id="actSell">${t('sell_to_player', 'Vendre (proche)')}</button>` : ''}
      ${perms.rentProperty ? `<button class="btn primary" id="actRent">${t('rent_to_player', 'Louer (proche)')}</button>` : ''}
      ${perms.sellProperty ? `<button class="btn ghost" id="actKeys">${t('give_keys', 'Donner clés')}</button>` : ''}
      ${perms.sellProperty ? `<button class="btn ghost" id="actRevoke">${t('revoke', 'Résilier')}</button>` : ''}
      ${perms.deleteProperty ? `<button class="btn danger" id="actDelete">${t('delete_property', 'Supprimer')}</button>` : ''}
    `;

    detailModal.classList.remove('hidden');
  }

  async function refreshData() {
    const data = await nui('refresh');
    if (data && data.player) {
      state.data = data;
      fillInteriors();
      renderCompany();
      renderStats();
      renderProperties();
    }
  }

  function collectForm() {
    const garageX = document.getElementById('gX').value;
    const garage = garageX !== '' ? {
      x: Number(document.getElementById('gX').value),
      y: Number(document.getElementById('gY').value),
      z: Number(document.getElementById('gZ').value),
      h: Number(document.getElementById('gH').value) || 0,
    } : null;

    return {
      id: document.getElementById('editId').value || undefined,
      label: document.getElementById('fLabel').value.trim(),
      address: document.getElementById('fAddress').value.trim(),
      interior: document.getElementById('fInterior').value,
      property_type: document.getElementById('fType').value,
      status: document.getElementById('fStatus').value,
      price_sale: Number(document.getElementById('fSale').value) || 0,
      price_rent: Number(document.getElementById('fRent').value) || 0,
      description: document.getElementById('fDesc').value.trim(),
      entrance: {
        x: Number(document.getElementById('fX').value),
        y: Number(document.getElementById('fY').value),
        z: Number(document.getElementById('fZ').value),
        h: Number(document.getElementById('fH').value) || 0,
      },
      garage,
      clear_garage: garageX === '',
    };
  }

  function escapeHtml(str) {
    return String(str ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  // ─── Events ────────────────────────────────────────────────

  document.getElementById('companyCloseBtn').addEventListener('click', closeAll);
  document.getElementById('companyLogout').addEventListener('click', closeAll);
  document.getElementById('housingLogout').addEventListener('click', closeAll);
  document.getElementById('detailClose').addEventListener('click', () => detailModal.classList.add('hidden'));

  document.getElementById('companyNav').addEventListener('click', (e) => {
    const btn = e.target.closest('.nav-item');
    if (!btn) return;
    if (btn.id === 'openHousingFromCompany' || btn.dataset.tab === 'housing-link') {
      openHousing();
      return;
    }
    if (btn.dataset.tab) setCompanyTab(btn.dataset.tab);
  });

  document.querySelectorAll('.tool-go').forEach((btn) => {
    btn.addEventListener('click', () => setCompanyTab(btn.dataset.goto));
  });
  document.getElementById('toolHousingBtn').addEventListener('click', openHousing);

  async function openHousing() {
    const data = await nui('switchView', { view: 'housing' });
    if (data && data.player) state.data = data;
    setVisible('housing');
    fillInteriors();
    renderStats();
    setHousingView('list');
    renderProperties();
  }

  document.getElementById('backToCompany').addEventListener('click', async () => {
    const data = await nui('switchView', { view: 'company' });
    if (data && data.player) state.data = data;
    setVisible('company');
    renderCompany();
    setCompanyTab('dashboard');
  });

  document.getElementById('housingNav').addEventListener('click', (e) => {
    const btn = e.target.closest('.nav-item');
    if (!btn || !btn.dataset.hview) return;
    setHousingView(btn.dataset.hview);
  });

  document.getElementById('propertySearch').addEventListener('input', renderProperties);
  document.getElementById('sortPrice').addEventListener('change', renderProperties);
  document.getElementById('sortStatus').addEventListener('change', renderProperties);

  document.getElementById('propertyGrid').addEventListener('click', (e) => {
    const card = e.target.closest('.property-card');
    if (!card) return;
    openDetail(Number(card.dataset.id));
  });

  document.getElementById('postNewsBtn').addEventListener('click', async () => {
    const content = document.getElementById('newsInput').value.trim();
    const type = document.getElementById('newsType').value;
    if (!content) return;
    const res = await nui('postNews', { content, type });
    if (res.ok) {
      document.getElementById('newsInput').value = '';
      if (res.news) state.data.news = res.news;
      renderNews();
    }
  });

  document.getElementById('saveBillboardBtn').addEventListener('click', async () => {
    const content = document.getElementById('billboardInput').value;
    const res = await nui('saveBillboard', { content });
    if (res.ok && res.billboard) {
      state.data.billboard = res.billboard;
      renderBillboard();
    }
  });

  document.getElementById('hireBtn').addEventListener('click', async () => {
    const res = await nui('hireNearby');
    if (res.ok && res.employees) {
      state.data.employees = res.employees;
      renderEmployees();
    }
  });

  document.getElementById('employeesBody').addEventListener('click', async (e) => {
    const btn = e.target.closest('button[data-act]');
    if (!btn) return;
    const id = btn.dataset.id;
    const grade = Number(btn.dataset.grade);
    if (btn.dataset.act === 'fire') {
      const res = await nui('fireEmployee', { identifier: id });
      if (res.ok && res.employees) {
        state.data.employees = res.employees;
        renderEmployees();
      }
    } else if (btn.dataset.act === 'promote') {
      const res = await nui('setEmployeeGrade', { identifier: id, grade: Math.min(3, grade + 1) });
      if (res.ok && res.employees) {
        state.data.employees = res.employees;
        renderEmployees();
      }
    } else if (btn.dataset.act === 'demote') {
      const res = await nui('setEmployeeGrade', { identifier: id, grade: Math.max(0, grade - 1) });
      if (res.ok && res.employees) {
        state.data.employees = res.employees;
        renderEmployees();
      }
    }
  });

  document.getElementById('vehicleGrid').addEventListener('click', async (e) => {
    const btn = e.target.closest('[data-spawn]');
    if (!btn) return;
    await nui('spawnVehicle', { model: btn.dataset.spawn });
  });

  document.getElementById('storeVehicleBtn').addEventListener('click', () => nui('storeVehicle'));

  document.getElementById('useCurrentPosBtn').addEventListener('click', async () => {
    const pos = await nui('getPlayerPos');
    if (pos && pos.x != null) {
      state.playerPos = pos;
      document.getElementById('fX').value = Number(pos.x).toFixed(2);
      document.getElementById('fY').value = Number(pos.y).toFixed(2);
      document.getElementById('fZ').value = Number(pos.z).toFixed(2);
      document.getElementById('fH').value = Number(pos.h || 0).toFixed(2);
    }
  });

  document.getElementById('useGaragePosBtn').addEventListener('click', async () => {
    const pos = await nui('getPlayerPos');
    if (pos && pos.x != null) {
      document.getElementById('gX').value = Number(pos.x).toFixed(2);
      document.getElementById('gY').value = Number(pos.y).toFixed(2);
      document.getElementById('gZ').value = Number(pos.z).toFixed(2);
      document.getElementById('gH').value = Number(pos.h || 0).toFixed(2);
    }
  });

  document.getElementById('clearGarageBtn').addEventListener('click', () => {
    ['gX', 'gY', 'gZ', 'gH'].forEach((id) => { document.getElementById(id).value = ''; });
  });

  document.getElementById('cancelCreateBtn').addEventListener('click', () => setHousingView('list'));

  document.getElementById('fInterior').addEventListener('change', () => {
    const opt = document.getElementById('fInterior').selectedOptions[0];
    if (opt && opt.dataset.type) document.getElementById('fType').value = opt.dataset.type;
  });

  document.getElementById('propertyForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const payload = collectForm();
    if (!payload.label || Number.isNaN(payload.entrance.x)) return;

    const editing = Boolean(payload.id);
    const res = editing
      ? await nui('updateProperty', payload)
      : await nui('createProperty', payload);

    if (res.ok) {
      await refreshData();
      setHousingView('list');
    }
  });

  document.getElementById('detailActions').addEventListener('click', async (e) => {
    const p = state.selectedProperty;
    if (!p) return;
    if (e.target.id === 'actEdit') {
      detailModal.classList.add('hidden');
      fillForm(p);
    } else if (e.target.id === 'actSell') {
      const res = await nui('sellProperty', { id: p.id });
      if (res.ok) { detailModal.classList.add('hidden'); await refreshData(); }
    } else if (e.target.id === 'actRent') {
      const res = await nui('rentProperty', { id: p.id });
      if (res.ok) { detailModal.classList.add('hidden'); await refreshData(); }
    } else if (e.target.id === 'actKeys') {
      const res = await nui('giveKeys', { id: p.id });
      if (res.ok) { await refreshData(); openDetail(p.id); }
    } else if (e.target.id === 'actRevoke') {
      const res = await nui('revokeProperty', { id: p.id });
      if (res.ok) { detailModal.classList.add('hidden'); await refreshData(); }
    } else if (e.target.id === 'actDelete') {
      const res = await nui('deleteProperty', { id: p.id });
      if (res.ok) { detailModal.classList.add('hidden'); await refreshData(); }
    }
  });

  document.getElementById('keysList').addEventListener('click', async (e) => {
    const btn = e.target.closest('[data-remove-key]');
    if (!btn || !state.selectedProperty) return;
    const res = await nui('removeKeys', {
      id: state.selectedProperty.id,
      identifier: btn.dataset.removeKey,
    });
    if (res.ok) {
      await refreshData();
      openDetail(state.selectedProperty.id);
    }
  });

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !app.classList.contains('hidden')) {
      if (!detailModal.classList.contains('hidden')) {
        detailModal.classList.add('hidden');
        return;
      }
      closeAll();
    }
  });

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') {
      state.locale = msg.locale || {};
      state.currency = msg.currency || '$';
      state.data = msg.data;
      state.playerPos = msg.playerPos || null;
      applyI18n();
      fillInteriors();
      if (msg.view === 'housing') {
        setVisible('housing');
        renderStats();
        setHousingView('list');
        renderProperties();
      } else {
        setVisible('company');
        renderCompany();
        setCompanyTab('dashboard');
      }
    } else if (msg.action === 'close') {
      app.classList.add('hidden');
      companyPanel.classList.add('hidden');
      housingPanel.classList.add('hidden');
      detailModal.classList.add('hidden');
    }
  });
})();
