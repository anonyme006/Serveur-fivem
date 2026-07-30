(() => {
  const RESOURCE = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName()
    : 'ox_inventory_ui';

  const SLOT_COUNT = 25;
  const isBrowser = !window.invokeNative;

  const state = {
    visible: false,
    player: { id: 'player', label: 'Joueur', maxWeight: 60000, weight: 0, slots: [] },
    other: null,
    selected: null, // { inventory: 'player'|'other', slot: number }
    quantity: 0,
  };

  const els = {
    app: document.getElementById('app'),
    playerName: document.getElementById('playerName'),
    playerWeight: document.getElementById('playerWeight'),
    playerWeightFill: document.getElementById('playerWeightFill'),
    playerGrid: document.getElementById('playerGrid'),
    otherPanel: document.getElementById('otherPanel'),
    otherName: document.getElementById('otherName'),
    otherWeight: document.getElementById('otherWeight'),
    otherWeightFill: document.getElementById('otherWeightFill'),
    otherGrid: document.getElementById('otherGrid'),
    qtyInput: document.getElementById('qtyInput'),
    btnInfo: document.getElementById('btnInfo'),
    btnUse: document.getElementById('btnUse'),
    btnGive: document.getElementById('btnGive'),
    btnClose: document.getElementById('btnClose'),
    tooltip: document.getElementById('itemTooltip'),
    tipTitle: document.getElementById('tipTitle'),
    tipMeta: document.getElementById('tipMeta'),
    tipDesc: document.getElementById('tipDesc'),
    infoModal: document.getElementById('infoModal'),
    infoClose: document.getElementById('infoClose'),
  };

  function nui(event, data = {}) {
    if (isBrowser) {
      console.debug('[nui]', event, data);
      return Promise.resolve({ ok: true });
    }
    return fetch(`https://${RESOURCE}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).then((r) => r.json()).catch(() => ({}));
  }

  function formatKg(grams) {
    const kg = (Number(grams) || 0) / 1000;
    return kg.toFixed(1);
  }

  function formatWeightLabel(weight, maxWeight) {
    return `${formatKg(weight)} / ${formatKg(maxWeight)} kg`;
  }

  function weightPct(weight, maxWeight) {
    if (!maxWeight) return 0;
    return Math.min(100, Math.max(0, (weight / maxWeight) * 100));
  }

  function formatItemWeight(grams) {
    const g = Number(grams) || 0;
    if (g >= 1000) return `${(g / 1000).toFixed(2).replace(/\.?0+$/, '')}kg`;
    return `${g}g`;
  }

  function itemImage(item) {
    if (!item) return '';
    if (item.imageurl) return item.imageurl;
    const name = item.name || item.item || '';
    if (!name) return '';
    // Compatible ox_inventory images path when served from that resource
    return `nui://ox_inventory/web/images/${name}.png`;
  }

  function emptySlots(count = SLOT_COUNT) {
    return Array.from({ length: count }, (_, i) => ({ slot: i + 1 }));
  }

  function normalizeInventory(inv) {
    if (!inv) return null;
    const slots = emptySlots(inv.slots || SLOT_COUNT);
    const items = inv.items || inv.inventory || [];

    if (Array.isArray(items)) {
      items.forEach((it) => {
        if (!it || it.slot == null) return;
        const idx = Number(it.slot) - 1;
        if (idx >= 0 && idx < slots.length) slots[idx] = { ...slots[idx], ...it };
      });
    } else if (typeof items === 'object') {
      Object.values(items).forEach((it) => {
        if (!it || it.slot == null) return;
        const idx = Number(it.slot) - 1;
        if (idx >= 0 && idx < slots.length) slots[idx] = { ...slots[idx], ...it };
      });
    }

    return {
      id: inv.id || inv.type || 'inventory',
      type: inv.type || 'other',
      label: inv.label || inv.name || '',
      maxWeight: inv.maxWeight ?? 60000,
      weight: inv.weight ?? 0,
      slots,
    };
  }

  function renderSlot(slotData, inventoryKey) {
    const el = document.createElement('div');
    el.className = 'slot';
    el.dataset.inventory = inventoryKey;
    el.dataset.slot = String(slotData.slot);

    const hasItem = !!(slotData.name || slotData.label);
    const isSelected =
      state.selected &&
      state.selected.inventory === inventoryKey &&
      state.selected.slot === slotData.slot;

    if (isSelected) el.classList.add('selected');

    if (hasItem) {
      const qty = slotData.count ?? slotData.amount ?? 1;
      const weight = (slotData.weight || 0) * (qty || 1);

      const qtyEl = document.createElement('span');
      qtyEl.className = 'slot-qty';
      qtyEl.textContent = `${qty}x`;
      el.appendChild(qtyEl);

      const wEl = document.createElement('span');
      wEl.className = 'slot-weight';
      wEl.textContent = formatItemWeight(slotData.weight || weight);
      el.appendChild(wEl);

      const img = document.createElement('div');
      img.className = 'slot-img';
      const src = itemImage(slotData);
      if (src) img.style.backgroundImage = `url('${src}')`;
      el.appendChild(img);

      const label = document.createElement('div');
      label.className = 'slot-label';
      label.textContent = slotData.label || slotData.name || '';
      el.appendChild(label);

      if (inventoryKey === 'player' && slotData.slot <= 5) {
        const hot = document.createElement('span');
        hot.className = 'slot-hot';
        hot.textContent = String(slotData.slot);
        el.appendChild(hot);
      }
    }

    el.addEventListener('click', (e) => {
      e.preventDefault();
      selectSlot(inventoryKey, slotData.slot, hasItem ? slotData : null);
    });

    el.addEventListener('dblclick', (e) => {
      e.preventDefault();
      if (hasItem && inventoryKey === 'player') useSelected();
    });

    el.addEventListener('mouseenter', (e) => {
      if (!hasItem) return hideTooltip();
      showTooltip(slotData, e.clientX, e.clientY);
    });
    el.addEventListener('mousemove', (e) => {
      if (!hasItem) return;
      positionTooltip(e.clientX, e.clientY);
    });
    el.addEventListener('mouseleave', hideTooltip);

    return el;
  }

  function renderGrid(container, inventory, inventoryKey) {
    container.innerHTML = '';
    if (!inventory) return;
    inventory.slots.forEach((slot) => {
      container.appendChild(renderSlot(slot, inventoryKey));
    });
  }

  function render() {
    els.playerName.textContent = state.player.label || 'Joueur';
    els.playerWeight.textContent = formatWeightLabel(state.player.weight, state.player.maxWeight);
    els.playerWeightFill.style.width = `${weightPct(state.player.weight, state.player.maxWeight)}%`;
    renderGrid(els.playerGrid, state.player, 'player');

    if (state.other) {
      els.otherPanel.classList.remove('hidden');
      els.otherName.textContent = state.other.label || '';
      els.otherWeight.textContent = formatWeightLabel(state.other.weight, state.other.maxWeight);
      els.otherWeightFill.style.width = `${weightPct(state.other.weight, state.other.maxWeight)}%`;
      renderGrid(els.otherGrid, state.other, 'other');
    } else {
      // Toujours afficher la grille droite vide (comme le visuel)
      els.otherPanel.classList.remove('hidden');
      els.otherName.textContent = '';
      els.otherWeight.textContent = formatWeightLabel(0, 60000);
      els.otherWeightFill.style.width = '0%';
      renderGrid(els.otherGrid, { slots: emptySlots(SLOT_COUNT) }, 'other');
    }

    els.qtyInput.value = String(state.quantity || 0);
  }

  function selectSlot(inventory, slot, item) {
    if (!item) {
      state.selected = null;
      render();
      return;
    }
    state.selected = { inventory, slot, item };
    render();
    nui('selectItem', { inventory, slot });
  }

  function showTooltip(item, x, y) {
    els.tipTitle.textContent = item.label || item.name || '';
    const qty = item.count ?? item.amount ?? 1;
    els.tipMeta.textContent = `${qty}x · ${formatItemWeight(item.weight || 0)}`;
    els.tipDesc.textContent = item.description || item.metadata?.description || '';
    els.tooltip.classList.remove('hidden');
    positionTooltip(x, y);
  }

  function positionTooltip(x, y) {
    const pad = 14;
    els.tooltip.style.left = `${x + pad}px`;
    els.tooltip.style.top = `${y + pad}px`;
  }

  function hideTooltip() {
    els.tooltip.classList.add('hidden');
  }

  function openInventory(payload = {}) {
    const left = payload.leftInventory || payload.player || payload.left;
    const right = payload.rightInventory || payload.other || payload.right;

    if (left) state.player = normalizeInventory(left);
    if (payload.playerName) state.player.label = payload.playerName;

    state.other = right ? normalizeInventory(right) : null;
    state.selected = null;
    state.quantity = Number(payload.itemAmount ?? payload.quantity ?? 0) || 0;
    state.visible = true;

    els.app.classList.remove('hidden');
    els.app.setAttribute('aria-hidden', 'false');
    render();
  }

  function closeInventory() {
    state.visible = false;
    state.selected = null;
    hideTooltip();
    els.infoModal.classList.add('hidden');
    els.app.classList.add('hidden');
    els.app.setAttribute('aria-hidden', 'true');
    nui('exit');
    nui('closeInventory');
  }

  function useSelected() {
    if (!state.selected || state.selected.inventory !== 'player') return;
    const { slot, item } = state.selected;
    nui('useItem', {
      slot,
      name: item.name,
      count: state.quantity || 1,
    });
  }

  function giveSelected() {
    if (!state.selected || state.selected.inventory !== 'player') return;
    const { slot, item } = state.selected;
    nui('giveItem', {
      slot,
      name: item.name,
      count: state.quantity || 1,
    });
  }

  // Events
  els.btnClose.addEventListener('click', closeInventory);
  els.btnUse.addEventListener('click', useSelected);
  els.btnGive.addEventListener('click', giveSelected);
  els.btnInfo.addEventListener('click', () => els.infoModal.classList.remove('hidden'));
  els.infoClose.addEventListener('click', () => els.infoModal.classList.add('hidden'));
  els.infoModal.addEventListener('click', (e) => {
    if (e.target === els.infoModal) els.infoModal.classList.add('hidden');
  });

  els.qtyInput.addEventListener('input', () => {
    const digits = els.qtyInput.value.replace(/\D/g, '');
    state.quantity = parseInt(digits || '0', 10) || 0;
    els.qtyInput.value = String(state.quantity);
    nui('setItemAmount', { count: state.quantity });
  });

  window.addEventListener('keydown', (e) => {
    if (!state.visible) return;
    if (e.key === 'Escape') {
      e.preventDefault();
      closeInventory();
    }
  });

  window.addEventListener('message', (event) => {
    const data = event.data || {};
    const action = data.action || data.type;

    switch (action) {
      case 'setupInventory':
      case 'openInventory':
      case 'displayInventory':
      case 'setInventoryVisible':
        if (data.action === 'setInventoryVisible' && data.data === false) {
          state.visible = false;
          els.app.classList.add('hidden');
          return;
        }
        openInventory(data.data || data);
        break;
      case 'closeInventory':
      case 'hideInventory':
        state.visible = false;
        els.app.classList.add('hidden');
        break;
      case 'refreshSlots':
      case 'updateSlots': {
        const payload = data.data || data;
        if (payload.leftInventory || payload.player) {
          state.player = normalizeInventory(payload.leftInventory || payload.player);
        }
        if (payload.rightInventory || payload.other) {
          state.other = normalizeInventory(payload.rightInventory || payload.other);
        }
        if (Array.isArray(payload.items) && payload.inventory === 'player') {
          // refresh individual slots
          payload.items.forEach((it) => {
            if (!it || it.slot == null) return;
            const idx = Number(it.slot) - 1;
            if (idx >= 0 && idx < state.player.slots.length) {
              state.player.slots[idx] = { slot: it.slot, ...it.item };
            }
          });
        }
        render();
        break;
      }
      default:
        break;
    }
  });

  // ——— Preview / démo navigateur ———
  function loadDemo() {
    document.body.classList.add('preview');
    openInventory({
      playerName: 'Jack Owen',
      leftInventory: {
        id: 'player',
        label: 'Jack Owen',
        maxWeight: 60000,
        weight: 2500,
        slots: 25,
        items: [
          {
            slot: 1,
            name: 'phone',
            label: 'Téléphone',
            count: 1,
            weight: 250,
            description: 'Un smartphone moderne.',
          },
          {
            slot: 2,
            name: 'burger',
            label: 'Le Gros',
            count: 2,
            weight: 220,
            description: 'Un burger bien garni.',
          },
          {
            slot: 3,
            name: 'cola',
            label: 'Soda',
            count: 5,
            weight: 330,
            description: 'Boisson gazeuse fraîche.',
          },
          {
            slot: 4,
            name: 'id_card',
            label: "Carte d'identité",
            count: 1,
            weight: 10,
            description: 'Documents officiels.',
          },
        ],
      },
      rightInventory: {
        id: 'drop',
        label: '',
        maxWeight: 60000,
        weight: 0,
        slots: 25,
        items: [],
      },
    });
  }

  if (isBrowser || new URLSearchParams(location.search).has('preview')) {
    loadDemo();
  }

  // Expose for preview.html
  window.OxInventoryUI = { openInventory, closeInventory, loadDemo, render };
})();
