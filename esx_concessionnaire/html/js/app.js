(() => {
    const app = document.getElementById('app');
    const categoriesEl = document.getElementById('categories');
    const listEl = document.getElementById('vehicle-list');
    const searchEl = document.getElementById('search');
    const titleEl = document.getElementById('shop-title');
    const btnBuy = document.getElementById('btn-buy');
    const btnClose = document.getElementById('btn-close');
    const modal = document.getElementById('confirm-modal');
    const confirmText = document.getElementById('confirm-text');
    const confirmOk = document.getElementById('confirm-ok');
    const confirmCancel = document.getElementById('confirm-cancel');

    let categories = [];
    let vehicles = [];
    let locale = {};
    let activeCategory = null;
    let selected = null;
    let searchQuery = '';
    let buying = false;

    const resourceName = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'esx_concessionnaire';

    function post(endpoint, data = {}) {
        return fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        }).then((r) => r.json()).catch(() => null);
    }

    function formatPrice(n) {
        return '$' + Number(n || 0).toLocaleString('en-US');
    }

    function getFiltered() {
        const q = searchQuery.trim().toLowerCase();
        return vehicles.filter((v) => {
            const catOk = !activeCategory || v.category === activeCategory;
            const searchOk = !q ||
                (v.name && v.name.toLowerCase().includes(q)) ||
                (v.model && v.model.toLowerCase().includes(q)) ||
                (v.categoryLabel && v.categoryLabel.toLowerCase().includes(q));
            return catOk && searchOk;
        });
    }

    function renderCategories() {
        categoriesEl.innerHTML = '';
        categories.forEach((cat) => {
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'cat-btn' + (activeCategory === cat.id ? ' active' : '');
            btn.textContent = cat.label;
            btn.addEventListener('click', () => {
                activeCategory = cat.id;
                renderCategories();
                const filtered = getFiltered();
                if (filtered.length) {
                    selectVehicle(filtered[0], false);
                } else {
                    selected = null;
                    btnBuy.disabled = true;
                }
                renderList();
            });
            categoriesEl.appendChild(btn);
        });
    }

    function selectVehicle(vehicle, scrollIntoView) {
        selected = vehicle;
        btnBuy.disabled = !vehicle || buying;
        renderList();
        if (vehicle) {
            post('preview', { model: vehicle.model });
        }
        if (scrollIntoView && vehicle) {
            const row = listEl.querySelector(`[data-model="${CSS.escape(vehicle.model)}"]`);
            if (row) row.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }
    }

    function renderList() {
        const filtered = getFiltered();
        listEl.innerHTML = '';

        if (!filtered.length) {
            const empty = document.createElement('div');
            empty.className = 'empty-state';
            empty.textContent = locale.empty || 'Aucun véhicule trouvé.';
            listEl.appendChild(empty);
            return;
        }

        filtered.forEach((v) => {
            const row = document.createElement('div');
            row.className = 'vehicle-row' + (selected && selected.model === v.model ? ' selected' : '');
            row.setAttribute('role', 'listitem');
            row.dataset.model = v.model;

            const meta = document.createElement('div');
            meta.className = 'vehicle-meta';

            const name = document.createElement('div');
            name.className = 'vehicle-name';
            name.textContent = v.name;

            const cat = document.createElement('div');
            cat.className = 'vehicle-cat';
            cat.textContent = v.categoryLabel || v.category;

            meta.appendChild(name);
            meta.appendChild(cat);

            const price = document.createElement('div');
            price.className = 'vehicle-price';
            price.textContent = formatPrice(v.price);

            row.appendChild(meta);
            row.appendChild(price);

            row.addEventListener('click', () => selectVehicle(v, false));
            row.addEventListener('dblclick', () => {
                selectVehicle(v, false);
                openConfirm();
            });

            listEl.appendChild(row);
        });
    }

    function openUI(payload) {
        categories = payload.categories || [];
        vehicles = payload.vehicles || [];
        locale = payload.locale || {};

        titleEl.textContent = locale.title || 'Voiture';
        searchEl.placeholder = locale.search || 'Rechercher un véhicule...';
        btnBuy.textContent = locale.buy || 'Acheter';
        btnClose.textContent = locale.close || 'Fermer';
        confirmOk.textContent = locale.buy || 'Acheter';
        confirmCancel.textContent = locale.cancel || 'Annuler';

        activeCategory = categories[0] ? categories[0].id : null;
        searchQuery = '';
        searchEl.value = '';
        buying = false;
        modal.classList.add('hidden');

        app.classList.remove('hidden');
        renderCategories();

        const filtered = getFiltered();
        if (filtered.length) {
            selectVehicle(filtered[0], false);
        } else {
            selected = null;
            btnBuy.disabled = true;
            renderList();
        }
    }

    function closeUI() {
        app.classList.add('hidden');
        modal.classList.add('hidden');
        selected = null;
        buying = false;
    }

    function openConfirm() {
        if (!selected || buying) return;
        confirmText.textContent = `Acheter ${selected.name} pour ${formatPrice(selected.price)} ?`;
        modal.classList.remove('hidden');
    }

    function closeConfirm() {
        modal.classList.add('hidden');
    }

    async function confirmBuy() {
        if (!selected || buying) return;
        buying = true;
        btnBuy.disabled = true;
        confirmOk.disabled = true;

        const result = await post('buy', { model: selected.model });
        buying = false;
        confirmOk.disabled = false;

        if (result && result.ok) {
            closeConfirm();
            // client ferme le NUI après achat
        } else {
            btnBuy.disabled = !selected;
            closeConfirm();
        }
    }

    btnClose.addEventListener('click', () => post('close'));
    btnBuy.addEventListener('click', openConfirm);
    confirmCancel.addEventListener('click', closeConfirm);
    confirmOk.addEventListener('click', confirmBuy);

    searchEl.addEventListener('input', () => {
        searchQuery = searchEl.value;
        renderList();
    });

    document.addEventListener('keydown', (e) => {
        if (app.classList.contains('hidden')) return;
        if (e.key === 'Escape') {
            if (!modal.classList.contains('hidden')) {
                closeConfirm();
            } else {
                post('close');
            }
        }
    });

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        if (data.action === 'open') {
            openUI(data);
        } else if (data.action === 'close') {
            closeUI();
        }
    });
})();
