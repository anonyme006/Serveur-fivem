(() => {
  const RES =
    typeof GetParentResourceName === 'function'
      ? GetParentResourceName()
      : 'esx_losplantos_inventory';

  const app = document.getElementById('app');
  const listEl = document.getElementById('itemList');
  const weightEl = document.getElementById('weightBar');
  const actionsEl = document.getElementById('actions');
  const contextMenu = document.getElementById('contextMenu');
  const bannerImg = document.querySelector('.inventory__banner-img');

  const modal = document.getElementById('actionModal');
  const modalTitle = document.getElementById('modalTitle');
  const modalIcon = document.getElementById('modalIcon');
  const modalLabel = document.getElementById('modalLabel');
  const modalCount = document.getElementById('modalCount');
  const qtyInput = document.getElementById('qtyInput');
  const playersBlock = document.getElementById('playersBlock');
  const playerList = document.getElementById('playerList');
  const playersEmpty = document.getElementById('playersEmpty');
  const modalConfirm = document.getElementById('modalConfirm');
  const modalCancel = document.getElementById('modalCancel');

  let items = [];
  let nearbyPlayers = [];
  let selected = 1;
  let selectedPlayerId = null;
  let open = false;
  let modalOpen = false;
  let modalAction = null; // give | trade | drop

  const ACTION_TITLES = {
    give: 'Donner',
    trade: 'Échanger',
    drop: 'Jeter',
  };

  if (bannerImg) {
    bannerImg.addEventListener('error', () => {
      bannerImg.dataset.fallback = '1';
    });
  }

  function formatWeight(n, forceDecimals) {
    const v = Number(n) || 0;
    if (forceDecimals || !Number.isInteger(v)) return v.toFixed(2);
    return String(v);
  }

  function updateWeight(weight, maxWeight) {
    weightEl.textContent = `INVENTAIRE ${formatWeight(weight, true)} / ${formatWeight(maxWeight, false)} KG`;
  }

  function post(name, data = {}) {
    return fetch(`https://${RES}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).catch(() => ({}));
  }

  function currentItem() {
    return items[selected - 1] || null;
  }

  function hideContext() {
    contextMenu.classList.add('hidden');
  }

  function showContext(x, y) {
    contextMenu.classList.remove('hidden');
    const pad = 8;
    const w = contextMenu.offsetWidth || 150;
    const h = contextMenu.offsetHeight || 160;
    contextMenu.style.left = `${Math.max(pad, Math.min(x, window.innerWidth - w - pad))}px`;
    contextMenu.style.top = `${Math.max(pad, Math.min(y, window.innerHeight - h - pad))}px`;
  }

  function scrollSelectedIntoView() {
    const row = listEl.querySelector('.inventory__item.is-selected');
    if (row) row.scrollIntoView({ block: 'nearest' });
  }

  function clampQty() {
    const item = currentItem();
    const max = item ? Number(item.count) || 1 : 1;
    let v = parseInt(qtyInput.value, 10);
    if (Number.isNaN(v) || v < 1) v = 1;
    if (v > max) v = max;
    qtyInput.value = String(v);
    qtyInput.max = String(max);
    return v;
  }

  function renderPlayers() {
    playerList.innerHTML = '';
    const has = nearbyPlayers.length > 0;
    playersEmpty.classList.toggle('hidden', has);
    playerList.classList.toggle('hidden', !has);

    nearbyPlayers.forEach((p) => {
      const li = document.createElement('li');
      li.className = 'modal__player' + (selectedPlayerId === p.id ? ' is-selected' : '');
      li.innerHTML = `<span>${p.name || ('ID ' + p.id)}</span><span class="modal__player-dist">${(p.distance || 0).toFixed(1)} m</span>`;
      li.addEventListener('click', () => {
        selectedPlayerId = p.id;
        renderPlayers();
        updateModalConfirm();
      });
      playerList.appendChild(li);
    });
  }

  function updateModalConfirm() {
    const needsPlayer = modalAction === 'give' || modalAction === 'trade';
    const qtyOk = clampQty() >= 1;
    modalConfirm.disabled = !qtyOk || (needsPlayer && !selectedPlayerId);
  }

  function closeModal() {
    modalOpen = false;
    modalAction = null;
    selectedPlayerId = null;
    nearbyPlayers = [];
    modal.classList.add('hidden');
  }

  async function openModal(action) {
    const item = currentItem();
    if (!item) return;

    if (action === 'drop' && item.canRemove === false) {
      post('notify', { message: 'Cet objet ne peut pas être jeté' });
      return;
    }
    if ((action === 'give' || action === 'trade') && item.canRemove === false) {
      post('notify', { message: 'Cet objet ne peut pas être donné' });
      return;
    }

    modalAction = action;
    modalOpen = true;
    modalTitle.textContent = ACTION_TITLES[action] || 'Action';
    modalIcon.src = item.image || 'img/default.svg';
    modalLabel.textContent = item.label || item.name;
    modalCount.textContent = `x${item.count ?? 0}`;
    qtyInput.value = '1';
    qtyInput.max = String(item.count || 1);
    selectedPlayerId = null;

    const needsPlayer = action === 'give' || action === 'trade';
    playersBlock.classList.toggle('hidden', !needsPlayer);

    if (needsPlayer) {
      try {
        const res = await fetch(`https://${RES}/getNearbyPlayers`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json; charset=UTF-8' },
          body: '{}',
        });
        const data = await res.json();
        nearbyPlayers = Array.isArray(data) ? data : data.players || [];
      } catch (_) {
        nearbyPlayers = [];
      }

      if (nearbyPlayers.length === 1) {
        selectedPlayerId = nearbyPlayers[0].id;
      }
      renderPlayers();
    }

    modal.classList.remove('hidden');
    updateModalConfirm();
    qtyInput.focus();
    qtyInput.select();
  }

  function confirmModal() {
    const item = currentItem();
    if (!item || !modalAction) return;
    const count = clampQty();

    if (modalAction === 'drop') {
      post('drop', { index: selected, count });
    } else if (modalAction === 'give' || modalAction === 'trade') {
      if (!selectedPlayerId) return;
      post(modalAction === 'trade' ? 'trade' : 'give', {
        index: selected,
        count,
        target: selectedPlayerId,
      });
    }

    closeModal();
  }

  function useItem() {
    const item = currentItem();
    if (!item) return;
    post('use', { index: selected });
  }

  function runAction(action) {
    hideContext();
    if (!items.length) return;

    if (action === 'use') {
      useItem();
      return;
    }
    if (action === 'give' || action === 'trade' || action === 'drop') {
      openModal(action);
    }
  }

  function updateActionButtons() {
    const item = currentItem();
    const canRemove = item ? item.canRemove !== false : false;
    actionsEl.querySelectorAll('button').forEach((btn) => {
      const a = btn.dataset.action;
      if (a === 'use') {
        btn.disabled = !item;
      } else {
        btn.disabled = !item || !canRemove;
      }
    });
    contextMenu.querySelectorAll('button').forEach((btn) => {
      const a = btn.dataset.action;
      if (a === 'use') {
        btn.disabled = !item;
      } else {
        btn.disabled = !item || !canRemove;
      }
    });
  }

  function render() {
    listEl.innerHTML = '';

    if (!items.length) {
      const empty = document.createElement('li');
      empty.className = 'inventory__empty';
      empty.textContent = 'Inventaire vide';
      listEl.appendChild(empty);
      updateActionButtons();
      return;
    }

    items.forEach((item, i) => {
      const index = i + 1;
      const li = document.createElement('li');
      li.className = 'inventory__item' + (index === selected ? ' is-selected' : '');
      li.setAttribute('role', 'option');
      li.setAttribute('aria-selected', index === selected ? 'true' : 'false');
      li.dataset.index = String(index);

      const img = document.createElement('img');
      img.className = 'inventory__item-icon';
      img.src = item.image || 'img/default.svg';
      img.alt = '';
      img.draggable = false;
      img.onerror = () => {
        img.src = 'img/default.svg';
      };

      const name = document.createElement('span');
      name.className = 'inventory__item-name';
      name.textContent = item.label || item.name;

      const count = document.createElement('span');
      count.className = 'inventory__item-count';
      count.textContent = `x${item.count ?? 0}`;

      li.appendChild(img);
      li.appendChild(name);
      li.appendChild(count);

      li.addEventListener('click', () => {
        if (modalOpen) return;
        hideContext();
        selected = index;
        render();
        post('select', { index });
      });

      li.addEventListener('dblclick', () => {
        if (modalOpen) return;
        selected = index;
        render();
        useItem();
      });

      li.addEventListener('contextmenu', (e) => {
        if (modalOpen) return;
        e.preventDefault();
        selected = index;
        render();
        post('select', { index });
        showContext(e.clientX, e.clientY);
      });

      listEl.appendChild(li);
    });

    scrollSelectedIntoView();
    updateActionButtons();
  }

  function setSelected(index) {
    if (!items.length || modalOpen) return;
    selected = Math.min(Math.max(1, index), items.length);
    render();
    post('select', { index: selected });
  }

  function move(delta) {
    if (!items.length || modalOpen) return;
    let next = selected + delta;
    if (next < 1) next = items.length;
    if (next > items.length) next = 1;
    setSelected(next);
  }

  function openInventory(data) {
    items = Array.isArray(data.items) ? data.items : [];
    selected = Math.min(Math.max(1, data.selected || 1), Math.max(1, items.length));
    updateWeight(data.weight, data.maxWeight);
    app.classList.remove('hidden');
    open = true;
    hideContext();
    if (!modalOpen) closeModal();
    render();
  }

  function closeInventory() {
    open = false;
    hideContext();
    closeModal();
    app.classList.add('hidden');
    items = [];
  }

  actionsEl.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-action]');
    if (!btn || !open || btn.disabled) return;
    runAction(btn.dataset.action);
  });

  contextMenu.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-action]');
    if (!btn || btn.disabled) return;
    runAction(btn.dataset.action);
  });

  document.addEventListener('click', (e) => {
    if (!contextMenu.contains(e.target)) hideContext();
  });

  document.getElementById('qtyMinus').addEventListener('click', () => {
    qtyInput.value = String(Math.max(1, (parseInt(qtyInput.value, 10) || 1) - 1));
    updateModalConfirm();
  });
  document.getElementById('qtyPlus').addEventListener('click', () => {
    const item = currentItem();
    const max = item ? Number(item.count) || 1 : 1;
    qtyInput.value = String(Math.min(max, (parseInt(qtyInput.value, 10) || 1) + 1));
    updateModalConfirm();
  });
  document.getElementById('qtyMax').addEventListener('click', () => {
    const item = currentItem();
    qtyInput.value = String(item ? item.count || 1 : 1);
    updateModalConfirm();
  });
  qtyInput.addEventListener('input', updateModalConfirm);
  modalCancel.addEventListener('click', closeModal);
  modalConfirm.addEventListener('click', confirmModal);

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    switch (msg.action) {
      case 'open':
        openInventory(msg.data || {});
        break;
      case 'close':
        closeInventory();
        break;
      case 'select':
        setSelected(msg.index || 1);
        break;
      case 'key':
        if (!open || modalOpen) return;
        if (msg.key === 'up') move(-1);
        if (msg.key === 'down') move(1);
        if (msg.key === 'enter') useItem();
        break;
      case 'nearbyPlayers':
        nearbyPlayers = Array.isArray(msg.players) ? msg.players : [];
        if (nearbyPlayers.length === 1) selectedPlayerId = nearbyPlayers[0].id;
        renderPlayers();
        updateModalConfirm();
        break;
      case 'update':
        if (!open) return;
        openInventory(Object.assign({ selected }, msg.data || {}));
        break;
      default:
        break;
    }
  });

  window.addEventListener('keydown', (e) => {
    if (!open) return;

    if (modalOpen) {
      if (e.key === 'Escape') {
        e.preventDefault();
        closeModal();
      } else if (e.key === 'Enter') {
        e.preventDefault();
        if (!modalConfirm.disabled) confirmModal();
      }
      return;
    }

    if (e.key === 'Escape') {
      e.preventDefault();
      post('close');
      closeInventory();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      move(-1);
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      move(1);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      useItem();
    } else if (e.key === 'g' || e.key === 'G') {
      e.preventDefault();
      runAction('give');
    } else if (e.key === 'e' || e.key === 'E') {
      e.preventDefault();
      runAction('trade');
    } else if (e.key === 'j' || e.key === 'J') {
      e.preventDefault();
      runAction('drop');
    } else if (e.key === 'Backspace') {
      e.preventDefault();
      post('close');
      closeInventory();
    }
  });

  // Preview navigateur (hors FiveM)
  if (!window.invokeNative) {
    document.body.style.background =
      'radial-gradient(ellipse at 65% 45%, #4a5a3a 0%, #2a3228 40%, #121610 100%)';

    const originalFetch = window.fetch.bind(window);
    window.fetch = async (url, opts) => {
      if (String(url).includes('/getNearbyPlayers')) {
        return {
          json: async () => [
            { id: 2, name: 'Alex Martin', distance: 1.4 },
            { id: 5, name: 'Sam Dupont', distance: 2.7 },
          ],
        };
      }
      if (String(url).includes('https://')) {
        return { json: async () => ({ ok: true }) };
      }
      return originalFetch(url, opts);
    };

    openInventory({
      weight: 42.17,
      maxWeight: 60,
      selected: 1,
      items: [
        { name: 'phone', label: 'Téléphone', count: 1, usable: true, canRemove: true, image: 'img/phone.svg' },
        { name: 'umbrella', label: 'Parapluie', count: 1, usable: true, canRemove: true, image: 'img/umbrella.svg' },
        { name: 'compass', label: 'Boussole', count: 1, usable: true, canRemove: true, image: 'img/compass.svg' },
        { name: 'gps', label: 'GPS', count: 1, usable: true, canRemove: true, image: 'img/gps.svg' },
        {
          name: 'jus_multivitamine',
          label: 'Bouteille de Jus Multivitaminé',
          count: 4,
          usable: true,
          canRemove: true,
          image: 'img/juice.svg',
        },
        { name: 'jumelles', label: 'Jumelles', count: 1, usable: true, canRemove: true, image: 'img/binoculars.svg' },
        { name: 'cheeseburger', label: 'Cheeseburger', count: 1, usable: true, canRemove: true, image: 'img/burger.svg' },
        { name: 'finger_shokobite', label: 'Finger Shokobite', count: 1, usable: true, canRemove: true, image: 'img/snack.svg' },
        {
          name: 'poulet_barquette',
          label: 'Poulet en barquette',
          count: 70,
          usable: true,
          canRemove: true,
          image: 'img/chicken.svg',
        },
      ],
    });
  }
})();
