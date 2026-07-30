(() => {
  const RES =
    typeof GetParentResourceName === 'function'
      ? GetParentResourceName()
      : 'esx_losplantos_shop';

  const app = document.getElementById('app');
  const listEl = document.getElementById('itemList');
  const shopNameEl = document.getElementById('shopName');
  const shopLabelEl = document.getElementById('shopLabel');
  const bannerImg = document.querySelector('.shop__banner-img');

  let items = [];
  let selected = 1;
  let quantity = 1;
  let maxQuantity = 100;
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

  function clampQty(v) {
    const max = maxQuantity || 100;
    return Math.min(max, Math.max(1, v));
  }

  function changeQty(delta) {
    quantity = clampQty(quantity + delta);
    render();
  }

  function buySelected() {
    if (!items.length) return;
    post('buy', { shopId, index: selected, count: quantity });
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
      const isSelected = index === selected;
      const li = document.createElement('li');
      li.className = 'shop__item' + (isSelected ? ' is-selected' : '');
      li.setAttribute('role', 'option');
      li.setAttribute('aria-selected', isSelected ? 'true' : 'false');

      const img = document.createElement('img');
      img.className = 'shop__item-icon';
      img.src = item.image || 'img/default.svg';
      img.alt = '';
      img.draggable = false;
      img.onerror = () => {
        img.src = 'img/default.svg';
      };

      const main = document.createElement('div');
      main.className = 'shop__item-main';

      const name = document.createElement('span');
      name.className = 'shop__item-name';
      name.textContent = item.label || item.name;

      const price = document.createElement('span');
      price.className = 'shop__item-price';
      price.textContent = formatPrice(item.price);

      main.appendChild(name);
      main.appendChild(price);

      const qty = document.createElement('span');
      qty.className = 'shop__item-qty';
      // Format screenshot : sélectionné "< 1 >", sinon "1"
      qty.textContent = isSelected ? `< ${quantity} >` : '1';

      li.appendChild(img);
      li.appendChild(main);
      li.appendChild(qty);

      li.addEventListener('click', () => {
        if (selected !== index) {
          selected = index;
          quantity = 1;
        }
        render();
        post('select', { index, count: quantity });
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
    const next = Math.min(Math.max(1, index), items.length);
    if (next !== selected) quantity = 1;
    selected = next;
    render();
    post('select', { index: selected, count: quantity });
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
    quantity = clampQty(data.count || 1);
    maxQuantity = data.maxQuantity || 100;
    shopNameEl.textContent = (data.name || 'MAGASIN').toUpperCase();
    shopLabelEl.textContent = (data.label || 'MAGASIN').toUpperCase();
    app.classList.remove('hidden');
    open = true;
    render();
  }

  function closeShop() {
    open = false;
    app.classList.add('hidden');
    items = [];
    shopId = null;
    quantity = 1;
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
        if (msg.key === 'left') changeQty(-1);
        if (msg.key === 'right') changeQty(1);
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
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault();
      changeQty(-1);
    } else if (e.key === 'ArrowRight') {
      e.preventDefault();
      changeQty(1);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      buySelected();
    }
  });

  // Preview navigateur — Twenty Four Seven
  if (!window.invokeNative) {
    document.body.style.background =
      'radial-gradient(ellipse at 60% 40%, #4a5a3a 0%, #2a3228 50%, #121610 100%)';
    openShop({
      shopId: 'twentyfourseven',
      name: 'TWENTY FOUR SEVEN',
      label: 'MAGASIN',
      selected: 1,
      maxQuantity: 100,
      items: [
        { name: 'phone', label: 'Téléphone', price: 200, image: 'img/phone.svg' },
        { name: 'umbrella', label: 'Parapluie', price: 60, image: 'img/umbrella.svg' },
        { name: 'water', label: "Bouteille d'eau", price: 20, image: 'img/water.svg' },
        { name: 'sandwich', label: 'Club sandwich', price: 20, image: 'img/sandwich.svg' },
        { name: 'pizza', label: 'Pizza', price: 45, image: 'img/pizza.svg' },
        { name: 'hotdog', label: 'Hot Dog', price: 20, image: 'img/hotdog.svg' },
        { name: 'burger', label: 'Cheeseburger', price: 35, image: 'img/burger.svg' },
        { name: 'beer', label: 'Bière', price: 30, image: 'img/beer.svg' },
        { name: 'gps', label: 'GPS', price: 250, image: 'img/gps.svg' },
      ],
    });
  }
})();
