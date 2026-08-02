(() => {
  const app = document.getElementById('app');
  const grid = document.getElementById('vehicle-grid');
  const empty = document.getElementById('empty-state');
  const emptyLabel = document.getElementById('empty-label');
  const searchInput = document.getElementById('search');
  const titleEl = document.getElementById('garage-title');
  const typeEl = document.getElementById('garage-type');
  const tpl = document.getElementById('tpl-card');

  const state = {
    open: false,
    vehicles: [],
    filtered: [],
    sort: 'name',
    query: '',
    locale: {},
    isImpound: false,
    garage: null,
  };

  const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'core_garage';

  function t(key, fallback) {
    return state.locale[key] || fallback || key;
  }

  function post(name, data = {}) {
    return fetch(`https://${resourceName}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).catch(() => null);
  }

  function applyTheme(ui = {}) {
    const root = document.documentElement;
    const map = {
      accent: '--accent',
      accentSoft: '--accent-soft',
      bg: '--bg',
      panel: '--panel',
      text: '--text',
      muted: '--muted',
      success: '--success',
      warning: '--warning',
      danger: '--danger',
      radius: '--radius',
    };
    Object.entries(map).forEach(([key, cssVar]) => {
      if (ui[key] != null) root.style.setProperty(cssVar, ui[key]);
    });
  }

  function statusLabel(status) {
    if (status === 'stored') return t('nui_status_stored', 'Rangé');
    if (status === 'out') return t('nui_status_out', 'Sorti');
    if (status === 'impound') return t('nui_status_impound', 'Fourrière');
    return status;
  }

  function meterColorClass(value) {
    if (value < 30) return 'low';
    if (value < 60) return 'mid';
    return 'high';
  }

  function sortVehicles(list) {
    const copy = [...list];
    if (state.sort === 'category') {
      copy.sort((a, b) =>
        String(a.categoryLabel || a.category || '').localeCompare(String(b.categoryLabel || b.category || ''), 'fr', { sensitivity: 'base' })
        || String(a.name).localeCompare(String(b.name), 'fr', { sensitivity: 'base' })
      );
    } else if (state.sort === 'date') {
      copy.sort((a, b) => {
        const da = Date.parse(a.lastIn || a.lastOut || 0) || 0;
        const db = Date.parse(b.lastIn || b.lastOut || 0) || 0;
        return db - da;
      });
    } else {
      copy.sort((a, b) => String(a.name).localeCompare(String(b.name), 'fr', { sensitivity: 'base' }));
    }
    return copy;
  }

  function filterVehicles() {
    const q = state.query.trim().toLowerCase();
    let list = state.vehicles;
    if (q) {
      list = list.filter((v) => {
        const hay = `${v.name} ${v.plate} ${v.categoryLabel || ''} ${v.modelName || ''}`.toLowerCase();
        return hay.includes(q);
      });
    }
    state.filtered = sortVehicles(list);
    render();
  }

  function setMeter(card, key, value) {
    const meter = card.querySelector(`[data-meter="${key}"]`);
    if (!meter) return;
    const val = Math.max(0, Math.min(100, Number(value) || 0));
    meter.querySelector('.meter__val').textContent = `${val}%`;
    const bar = meter.querySelector('.meter__bar i');
    requestAnimationFrame(() => {
      bar.style.width = `${val}%`;
    });
  }

  function render() {
    grid.innerHTML = '';

    if (!state.filtered.length) {
      empty.classList.remove('hidden');
      emptyLabel.textContent = t('nui_empty', 'Aucun véhicule');
      return;
    }

    empty.classList.add('hidden');

    state.filtered.forEach((vehicle) => {
      const node = tpl.content.firstElementChild.cloneNode(true);
      const img = node.querySelector('.card__img');
      const badge = node.querySelector('.badge');
      const cta = node.querySelector('.card__cta');

      img.src = vehicle.image || '';
      img.alt = vehicle.name || '';
      img.onerror = () => {
        img.style.opacity = '0';
      };

      node.querySelector('.card__name').textContent = vehicle.name || '—';
      node.querySelector('.card__plate').textContent = vehicle.plate || '—';
      node.querySelector('.card__category').textContent = vehicle.categoryLabel || vehicle.category || '';

      badge.textContent = statusLabel(vehicle.status);
      badge.classList.add(`badge--${vehicle.status || 'stored'}`);

      setMeter(node, 'engine', vehicle.engine);
      setMeter(node, 'body', vehicle.body);
      setMeter(node, 'fuel', vehicle.fuel);

      node.querySelector('.meter[data-meter="engine"] .meter__label').textContent = t('nui_engine', 'Moteur');
      node.querySelector('.meter[data-meter="body"] .meter__label').textContent = t('nui_body', 'Carrosserie');
      node.querySelector('.meter[data-meter="fuel"] .meter__label').textContent = t('nui_fuel', 'Réservoir');

      const metas = node.querySelectorAll('.meta');
      metas[0].querySelector('.meta__label').textContent = t('nui_mileage', 'Kilométrage');
      metas[0].querySelector('.meta__value').textContent = vehicle.mileageLabel || `${vehicle.mileage || 0} km`;
      metas[1].querySelector('.meta__label').textContent = t('nui_insurance', 'Assurance');
      const ins = metas[1].querySelector('.meta__value');
      if (vehicle.insured) {
        ins.textContent = t('nui_insured', 'Assuré');
        ins.classList.add('is-yes');
      } else {
        ins.textContent = t('nui_not_insured', 'Non assuré');
        ins.classList.add('is-no');
      }

      const canTake = vehicle.status === 'stored' || vehicle.status === 'impound';
      if (state.isImpound || vehicle.status === 'impound') {
        const fee = vehicle.impoundFee || (state.garage && state.garage.impoundPrice) || 0;
        cta.textContent = `${t('nui_retrieve', 'Récupérer')}${fee ? ` · $${fee}` : ''}`;
        cta.classList.add('is-impound');
      } else {
        cta.textContent = t('nui_take_out', 'Sortir');
      }

      cta.disabled = !canTake;
      if (vehicle.status === 'out') {
        cta.textContent = t('nui_status_out', 'Sorti');
      }

      const take = () => {
        if (cta.disabled) return;
        post('takeOut', {
          plate: vehicle.plate,
          impound: state.isImpound || vehicle.status === 'impound',
        });
      };

      cta.addEventListener('click', take);
      node.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') take();
      });

      grid.appendChild(node);
    });
  }

  function open(payload) {
    state.open = true;
    state.vehicles = payload.vehicles || [];
    state.locale = payload.locale || {};
    state.isImpound = !!payload.isImpound;
    state.garage = payload.garage || {};
    state.query = '';
    searchInput.value = '';

    applyTheme(payload.ui || {});

    titleEl.textContent = (payload.garage && payload.garage.label) || t('nui_title', 'Garage');
    typeEl.textContent = state.isImpound ? t('impound', 'Fourrière') : t('garage', 'Garage');
    searchInput.placeholder = t('nui_search', 'Rechercher…');

    document.querySelectorAll('.sort__btn').forEach((btn) => {
      const key = btn.dataset.sort;
      if (key === 'name') btn.textContent = t('nui_sort_name', 'Nom');
      if (key === 'category') btn.textContent = t('nui_sort_category', 'Catégorie');
      if (key === 'date') btn.textContent = t('nui_sort_date', 'Date');
    });

    app.classList.remove('hidden');
    app.setAttribute('aria-hidden', 'false');
    filterVehicles();
    searchInput.focus();
  }

  function close() {
    if (!state.open) return;
    state.open = false;
    app.classList.add('hidden');
    app.setAttribute('aria-hidden', 'true');
    grid.innerHTML = '';
    post('close');
  }

  searchInput.addEventListener('input', () => {
    state.query = searchInput.value || '';
    filterVehicles();
  });

  document.querySelectorAll('.sort__btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.sort__btn').forEach((b) => b.classList.remove('is-active'));
      btn.classList.add('is-active');
      state.sort = btn.dataset.sort;
      filterVehicles();
    });
  });

  document.querySelectorAll('[data-close]').forEach((el) => {
    el.addEventListener('click', close);
  });

  window.addEventListener('keydown', (e) => {
    if (!state.open) return;
    if (e.key === 'Escape') close();
  });

  window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') open(data.payload || {});
    if (data.action === 'close') {
      state.open = false;
      app.classList.add('hidden');
      app.setAttribute('aria-hidden', 'true');
      grid.innerHTML = '';
    }
  });
})();
