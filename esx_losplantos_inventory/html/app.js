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

  let items = [];
  let selected = 1;
  let open = false;

  if (bannerImg) {
    bannerImg.addEventListener('error', () => {
      bannerImg.dataset.fallback = '1';
    });
  }

  function formatWeight(n, forceDecimals) {
    const v = Number(n) || 0;
    if (forceDecimals || !Number.isInteger(v)) {
      return v.toFixed(2);
    }
    return String(v);
  }

  function updateWeight(weight, maxWeight) {
    // Format d'origine : "INVENTAIRE 42.17 / 60 KG"
    weightEl.textContent = `INVENTAIRE ${formatWeight(weight, true)} / ${formatWeight(maxWeight, false)} KG`;
  }

  function post(name, data = {}) {
    return fetch(`https://${RES}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).catch(() => {});
  }

  function hideContext() {
    contextMenu.classList.add('hidden');
  }

  function showContext(x, y) {
    contextMenu.classList.remove('hidden');
    const pad = 8;
    const w = contextMenu.offsetWidth || 140;
    const h = contextMenu.offsetHeight || 120;
    const left = Math.min(x, window.innerWidth - w - pad);
    const top = Math.min(y, window.innerHeight - h - pad);
    contextMenu.style.left = `${Math.max(pad, left)}px`;
    contextMenu.style.top = `${Math.max(pad, top)}px`;
  }

  function scrollSelectedIntoView() {
    const row = listEl.querySelector('.inventory__item.is-selected');
    if (row) row.scrollIntoView({ block: 'nearest' });
  }

  function runAction(action) {
    if (!items.length) return;
    if (action === 'use') post('use', { index: selected });
    if (action === 'give') post('give', { index: selected, count: 1 });
    if (action === 'drop') post('drop', { index: selected, count: 1 });
    hideContext();
  }

  function render() {
    listEl.innerHTML = '';

    if (!items.length) {
      const empty = document.createElement('li');
      empty.className = 'inventory__empty';
      empty.textContent = 'Inventaire vide';
      listEl.appendChild(empty);
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
        hideContext();
        selected = index;
        render();
        post('select', { index });
      });

      li.addEventListener('dblclick', () => {
        selected = index;
        render();
        post('use', { index });
      });

      li.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        selected = index;
        render();
        post('select', { index });
        showContext(e.clientX, e.clientY);
      });

      listEl.appendChild(li);
    });

    scrollSelectedIntoView();
  }

  function setSelected(index) {
    if (!items.length) return;
    selected = Math.min(Math.max(1, index), items.length);
    render();
    post('select', { index: selected });
  }

  function move(delta) {
    if (!items.length) return;
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
    render();
  }

  function closeInventory() {
    open = false;
    hideContext();
    app.classList.add('hidden');
    items = [];
  }

  actionsEl.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-action]');
    if (!btn || !open) return;
    runAction(btn.dataset.action);
  });

  contextMenu.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-action]');
    if (!btn) return;
    runAction(btn.dataset.action);
  });

  document.addEventListener('click', (e) => {
    if (!contextMenu.contains(e.target)) hideContext();
  });

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
        if (!open) return;
        if (msg.key === 'up') move(-1);
        if (msg.key === 'down') move(1);
        if (msg.key === 'enter') post('use', { index: selected });
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
    if (e.key === 'Escape' || e.key === 'Backspace') {
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
      post('use', { index: selected });
    }
  });

  // Preview navigateur (hors FiveM)
  if (!window.invokeNative) {
    document.body.style.background =
      'radial-gradient(ellipse at 65% 45%, #4a5a3a 0%, #2a3228 40%, #121610 100%)';
    openInventory({
      weight: 42.17,
      maxWeight: 60,
      selected: 1,
      items: [
        { name: 'phone', label: 'Téléphone', count: 1, image: 'img/phone.svg' },
        { name: 'umbrella', label: 'Parapluie', count: 1, image: 'img/umbrella.svg' },
        { name: 'compass', label: 'Boussole', count: 1, image: 'img/compass.svg' },
        { name: 'gps', label: 'GPS', count: 1, image: 'img/gps.svg' },
        {
          name: 'jus_multivitamine',
          label: 'Bouteille de Jus Multivitaminé',
          count: 4,
          image: 'img/juice.svg',
        },
        { name: 'jumelles', label: 'Jumelles', count: 1, image: 'img/binoculars.svg' },
        { name: 'cheeseburger', label: 'Cheeseburger', count: 1, image: 'img/burger.svg' },
        { name: 'finger_shokobite', label: 'Finger Shokobite', count: 1, image: 'img/snack.svg' },
        {
          name: 'poulet_barquette',
          label: 'Poulet en barquette',
          count: 70,
          image: 'img/chicken.svg',
        },
      ],
    });
  }
})();
