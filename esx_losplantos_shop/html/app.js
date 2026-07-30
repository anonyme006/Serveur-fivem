(() => {
  const RES =
    typeof GetParentResourceName === 'function'
      ? GetParentResourceName()
      : 'esx_losplantos_shop';

  const app = document.getElementById('app');
  const listEl = document.getElementById('itemList');
  const titleEl = document.getElementById('shopTitle');
  const bannerImg = document.querySelector('.shop__banner-img');

  let items = [];
  let selected = 1;
  let open = false;
  let shopId = null;

  if (bannerImg) {
    bannerImg.addEventListener('error', () => {
      bannerImg.dataset.fallback = '1';
    });
  }

  function formatPrice(n) {
    const v = Math.floor(Number(n) || 0);
    try {
      return (
        '$' +
        v.toLocaleString('fr-FR', { maximumFractionDigits: 0 }).replace(/\u202f/g, ' ')
      );
    } catch (_) {
      return '$' + String(v).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    }
  }

  function post(name, data = {}) {
    return fetch(`https://${RES}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).catch(() => {});
  }

  function scrollSelectedIntoView() {
    const row = listEl.querySelector('.shop__item.is-selected');
    if (row) row.scrollIntoView({ block: 'nearest' });
  }

  function buySelected() {
    if (!items.length) return;
    post('buy', { shopId, index: selected });
  }

  function render() {
    listEl.innerHTML = '';

    if (!items.length) {
      const empty = document.createElement('li');
      empty.className = 'shop__empty';
      empty.textContent = 'Magasin vide';
      listEl.appendChild(empty);
      return;
    }

    items.forEach((item, i) => {
      const index = i + 1;
      const li = document.createElement('li');
      li.className = 'shop__item' + (index === selected ? ' is-selected' : '');
      li.setAttribute('role', 'option');
      li.setAttribute('aria-selected', index === selected ? 'true' : 'false');

      const img = document.createElement('img');
      img.className = 'shop__item-icon';
      img.src = item.image || 'img/default.svg';
      img.alt = '';
      img.draggable = false;
      img.onerror = () => {
        img.src = 'img/default.svg';
      };

      const name = document.createElement('span');
      name.className = 'shop__item-name';
      name.textContent = item.label || item.name;

      const price = document.createElement('span');
      price.className = 'shop__item-price';
      price.textContent = formatPrice(item.price);

      li.appendChild(img);
      li.appendChild(name);
      li.appendChild(price);

      li.addEventListener('click', () => {
        selected = index;
        render();
        post('select', { index });
      });

      li.addEventListener('dblclick', () => {
        selected = index;
        render();
        buySelected();
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

  function openShop(data) {
    shopId = data.shopId || null;
    items = Array.isArray(data.items) ? data.items : [];
    selected = Math.min(Math.max(1, data.selected || 1), Math.max(1, items.length));
    titleEl.textContent = (data.label || 'MAGASIN').toUpperCase();
    app.classList.remove('hidden');
    open = true;
    render();
  }

  function closeShop() {
    open = false;
    app.classList.add('hidden');
    items = [];
    shopId = null;
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    switch (msg.action) {
      case 'open':
        openShop(msg.data || {});
        break;
      case 'close':
        closeShop();
        break;
      case 'select':
        setSelected(msg.index || 1);
        break;
      case 'key':
        if (!open) return;
        if (msg.key === 'up') move(-1);
        if (msg.key === 'down') move(1);
        if (msg.key === 'enter') buySelected();
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
      closeShop();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      move(-1);
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      move(1);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      buySelected();
    }
  });

  // Preview navigateur
  if (!window.invokeNative) {
    document.body.style.background =
      'radial-gradient(ellipse at 60% 40%, #5a4a3a 0%, #2a2820 50%, #121210 100%)';
    openShop({
      shopId: 'ammunation_melee',
      label: 'MAGASIN',
      selected: 1,
      items: [
        { name: 'WEAPON_KNUCKLE', label: 'Poing américain', price: 777, image: 'img/knuckle.svg' },
        { name: 'WEAPON_GOLFCLUB', label: 'Club de golf', price: 2500, image: 'img/golfclub.svg' },
        { name: 'WEAPON_CROWBAR', label: 'Pied de biche', price: 800, image: 'img/crowbar.svg' },
        { name: 'WEAPON_SWITCHBLADE', label: "Couteau à cran d'arrêt", price: 900, image: 'img/switchblade.svg' },
        { name: 'WEAPON_KNIFE', label: 'Couteau', price: 250, image: 'img/knife.svg' },
        { name: 'WEAPON_BAT', label: 'Batte', price: 500, image: 'img/bat.svg' },
        { name: 'WEAPON_MACHETE', label: 'Machette', price: 1500, image: 'img/machete.svg' },
        { name: 'WEAPON_FLASHLIGHT', label: 'Lampe torche', price: 100, image: 'img/flashlight.svg' },
      ],
    });
  }
})();
