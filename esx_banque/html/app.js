(() => {
  const app = document.getElementById('app');
  const bankShell = document.getElementById('bankShell');
  const panelTitle = document.getElementById('panelTitle');
  const totalBalance = document.getElementById('totalBalance');
  const personalAccounts = document.getElementById('personalAccounts');
  const businessAccounts = document.getElementById('businessAccounts');
  const businessSectionLabel = document.getElementById('businessSectionLabel');
  const favoritesList = document.getElementById('favoritesList');
  const txList = document.getElementById('txList');
  const txEmpty = document.getElementById('txEmpty');
  const txBadge = document.getElementById('txBadge');
  const selectedBalance = document.getElementById('selectedBalance');
  const modal = document.getElementById('modal');
  const modalTitle = document.getElementById('modalTitle');
  const modalBody = document.getElementById('modalBody');
  const modalConfirm = document.getElementById('modalConfirm');
  const modalCancel = document.getElementById('modalCancel');
  const modalClose = document.getElementById('modalClose');

  let state = {
    mode: 'bank',
    currency: '$',
    locale: {},
    data: null,
    selected: null, // account object
    activeAction: 'withdraw',
    pendingFavTarget: null,
  };

  const isNui = typeof GetParentResourceName === 'function';
  const resourceName = isNui ? GetParentResourceName() : 'esx_banque';

  async function nui(event, data = {}) {
    if (!isNui) {
      return mockNui(event, data);
    }
    const res = await fetch(`https://${resourceName}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    try {
      return await res.json();
    } catch {
      return {};
    }
  }

  function formatMoney(amount) {
    const n = Math.floor(Number(amount) || 0);
    const formatted = Math.abs(n).toLocaleString('fr-FR').replace(/\u202f/g, ' ');
    const sign = n < 0 ? '-' : '';
    return `${sign}${state.currency} ${formatted}`;
  }

  function formatSigned(amount) {
    const n = Math.floor(Number(amount) || 0);
    const abs = Math.abs(n).toLocaleString('fr-FR').replace(/\u202f/g, ' ');
    if (n > 0) return `+${state.currency}${abs}`;
    if (n < 0) return `-${state.currency}${abs}`;
    return `${state.currency}${abs}`;
  }

  function formatDate(raw) {
    if (!raw) return '';
    const d = new Date(raw);
    if (Number.isNaN(d.getTime())) return String(raw);
    return d.toLocaleString('fr-FR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  function closeUI() {
    app.classList.add('hidden');
    closeModal();
    nui('close');
  }

  function openUI(payload) {
    state.mode = payload.mode || 'bank';
    state.currency = payload.currency || '$';
    state.locale = payload.locale || {};
    state.data = payload.data;

    panelTitle.textContent =
      state.mode === 'atm'
        ? (state.locale.atm_title || 'Distributeur (DAB)')
        : (state.locale.bank_title || 'Banque');

    bankShell.classList.toggle('atm-mode', state.mode === 'atm');
    app.classList.remove('hidden');

    const accounts = state.data?.accounts || [];
    state.selected = accounts[0] || null;
    renderAll();
  }

  function applyData(data) {
    if (!data) return;
    state.data = data;
    if (state.selected) {
      const found = (data.accounts || []).find(
        (a) => a.id === state.selected.id && a.type === state.selected.type
      );
      state.selected = found || data.accounts?.[0] || null;
    } else {
      state.selected = data.accounts?.[0] || null;
    }
    renderAll();
  }

  function renderAll() {
    totalBalance.textContent = formatMoney(state.data?.totalBalance || 0);
    renderAccounts();
    renderFavorites();
    renderTransactions();
    updateActionPermissions();
  }

  function avatarSvg(type) {
    if (type === 'business') {
      return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
        <path d="M4 20V8l8-4 8 4v12"/><path d="M9 20v-6h6v6"/><path d="M4 20h16"/>
      </svg>`;
    }
    return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
      <circle cx="12" cy="8" r="3.5"/><path d="M5 19c1.5-3.5 4-5 7-5s5.5 1.5 7 5"/>
    </svg>`;
  }

  function renderAccounts() {
    const accounts = state.data?.accounts || [];
    const personal = accounts.filter((a) => a.type === 'personal');
    const business = accounts.filter((a) => a.type === 'business');

    personalAccounts.innerHTML = personal
      .map((acc) => accountCardHtml(acc))
      .join('') || '<p class="empty-hint">Aucun compte</p>';

    if (business.length === 0) {
      businessSectionLabel.style.display = 'none';
      businessAccounts.innerHTML = '';
    } else {
      businessSectionLabel.style.display = '';
      businessAccounts.innerHTML = business.map((acc) => accountCardHtml(acc)).join('');
    }

    document.querySelectorAll('.account-card').forEach((el) => {
      el.addEventListener('click', () => {
        const type = el.dataset.type;
        const id = el.dataset.id;
        state.selected = accounts.find((a) => a.type === type && a.id === id) || null;
        renderAll();
      });
    });
  }

  function accountCardHtml(acc) {
    const selected =
      state.selected && state.selected.id === acc.id && state.selected.type === acc.type
        ? 'selected'
        : '';
    const meta =
      acc.type === 'business'
        ? `<div class="account-meta">${acc.gradeLabel || ''} · ${acc.job || ''}</div>`
        : '';
    return `
      <div class="account-card ${selected}" data-type="${acc.type}" data-id="${acc.id}">
        <div class="account-avatar ${acc.type === 'business' ? 'business' : ''}">
          ${avatarSvg(acc.type)}
        </div>
        <div class="account-info">
          <div class="account-name">${escapeHtml(acc.name)}</div>
          <div class="account-number">${escapeHtml(acc.accountNumber || '')}</div>
          ${meta}
        </div>
        <div class="account-balance">${formatMoney(acc.balance)}</div>
      </div>
    `;
  }

  function renderFavorites() {
    const favs = state.data?.favorites || [];
    if (!favs.length) {
      favoritesList.innerHTML = '<p class="empty-hint">Aucun favori (0)</p>';
      return;
    }
    favoritesList.innerHTML = favs
      .map(
        (f) => `
      <div class="fav-item" data-id="${f.id}" data-number="${escapeAttr(f.account_number)}" data-name="${escapeAttr(f.name)}">
        <div>
          <div class="fav-name">${escapeHtml(f.name)}</div>
          <div class="fav-num">${escapeHtml(f.account_number)}</div>
        </div>
        <button class="fav-remove" data-remove="${f.id}" title="Supprimer">×</button>
      </div>`
      )
      .join('');

    favoritesList.querySelectorAll('.fav-item').forEach((el) => {
      el.addEventListener('click', (e) => {
        if (e.target.closest('.fav-remove')) return;
        state.pendingFavTarget = {
          name: el.dataset.name,
          accountNumber: el.dataset.number,
        };
        openActionModal('transfer');
      });
    });

    favoritesList.querySelectorAll('.fav-remove').forEach((btn) => {
      btn.addEventListener('click', async (e) => {
        e.stopPropagation();
        const id = Number(btn.dataset.remove);
        const result = await nui('removeFavorite', { id });
        if (result?.favorites) {
          state.data.favorites = result.favorites;
          renderFavorites();
        }
      });
    });
  }

  function getSelectedHistory() {
    if (!state.selected || !state.data) return [];
    if (state.selected.type === 'business') {
      return state.data.history?.business || [];
    }
    return state.data.history?.personal || [];
  }

  function txIcon(type, amount) {
    const n = Number(amount) || 0;
    if (type === 'deposit' || type === 'transfer_in' || n > 0) {
      return { cls: 'credit', svg: billSvg() };
    }
    if (type === 'transfer' || type === 'transfer_out') {
      return { cls: 'transfer', svg: transferSvg() };
    }
    return { cls: 'debit', svg: cardSvg() };
  }

  function billSvg() {
    return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
      <rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/>
    </svg>`;
  }

  function cardSvg() {
    return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
      <rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 10h18"/>
    </svg>`;
  }

  function transferSvg() {
    return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
      <path d="M7 8h12M15 4l4 4-4 4M17 16H5M9 20l-4-4 4-4"/>
    </svg>`;
  }

  function renderTransactions() {
    const acc = state.selected;
    txBadge.textContent = acc ? acc.name : '—';
    selectedBalance.textContent = formatMoney(acc?.balance || 0);

    const rows = getSelectedHistory();
    // Clear list but keep empty node structure
    txList.innerHTML = '';
    const empty = document.createElement('div');
    empty.className = 'tx-empty';
    empty.id = 'txEmpty';
    empty.innerHTML = `
      <svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.5">
        <rect x="12" y="8" width="24" height="32" rx="2"/>
        <path d="M18 16h12M18 22h12M18 28h8"/>
      </svg>
      <p>${state.locale.no_transactions || 'Aucune transaction pour ce compte'}</p>
    `;

    if (!rows.length) {
      txList.appendChild(empty);
      return;
    }

    rows.forEach((tx, i) => {
      const amount = Number(tx.amount) || 0;
      const icon = txIcon(tx.type, amount);
      const row = document.createElement('div');
      row.className = 'tx-row';
      row.style.animationDelay = `${i * 0.04}s`;
      row.innerHTML = `
        <div class="tx-icon ${icon.cls}">${icon.svg}</div>
        <div class="tx-details">
          <div class="tx-label">${escapeHtml(tx.label || tx.type)}</div>
          <div class="tx-date">${formatDate(tx.created_at)}</div>
          ${tx.actor_name && acc?.type === 'business' ? `<div class="tx-actor">Par ${escapeHtml(tx.actor_name)}</div>` : ''}
        </div>
        <div class="tx-amount ${amount >= 0 ? 'positive' : 'negative'}">${formatSigned(amount)}</div>
      `;
      txList.appendChild(row);
    });
  }

  function updateActionPermissions() {
    const acc = state.selected;
    document.querySelectorAll('.action-btn').forEach((btn) => {
      const action = btn.dataset.action;
      btn.classList.toggle('active', action === state.activeAction);
      let disabled = !acc;
      if (acc?.type === 'business') {
        if (action === 'withdraw' && !acc.canWithdraw) disabled = true;
        if (action === 'transfer' && !acc.canTransfer) disabled = true;
      }
      btn.disabled = disabled;
    });
  }

  function openActionModal(action) {
    state.activeAction = action;
    updateActionPermissions();

    if (action === 'csv') {
      exportCsv();
      return;
    }

    const titles = {
      transfer: 'Virement',
      deposit: 'Dépôt',
      withdraw: 'Retrait',
    };

    modalTitle.textContent = titles[action] || 'Action';
    const acc = state.selected;
    let html = `
      <div class="modal-hint">Compte : <strong>${escapeHtml(acc?.name || '')}</strong> — ${formatMoney(acc?.balance || 0)}</div>
      <div class="field">
        <label>Montant</label>
        <input type="number" id="modalAmount" min="1" step="1" placeholder="0" autofocus />
      </div>
    `;

    if (action === 'transfer') {
      const favValue = state.pendingFavTarget?.accountNumber || '';
      const favName = state.pendingFavTarget?.name || '';
      html += `
        <div class="field">
          <label>N° de compte destinataire</label>
          <input type="text" id="modalTarget" placeholder="US7FL..." value="${escapeAttr(favValue)}" />
        </div>
        <div class="field">
          <label>Ou ID serveur (joueur connecté)</label>
          <input type="number" id="modalServerId" min="1" placeholder="Ex: 12" />
        </div>
      `;
      if (favName) {
        html += `<div class="modal-hint">Destinataire favori : ${escapeHtml(favName)}</div>`;
      }
    }

    if (action === 'deposit') {
      html += `<div class="modal-hint">Espèces disponibles : ${formatMoney(state.data?.personal?.cash || 0)}</div>`;
    }

    modalBody.innerHTML = html;
    modal.classList.remove('hidden');
    state.pendingFavTarget = null;

    setTimeout(() => {
      document.getElementById('modalAmount')?.focus();
    }, 50);
  }

  function closeModal() {
    modal.classList.add('hidden');
  }

  async function confirmModal() {
    const action = state.activeAction;
    const amountEl = document.getElementById('modalAmount');
    const amount = Number(amountEl?.value || 0);
    if (!amount || amount < 1) return;

    const payload = {
      amount,
      accountType: state.selected?.type || 'personal',
    };

    if (action === 'transfer') {
      payload.targetAccount = document.getElementById('modalTarget')?.value?.trim() || '';
      payload.targetServerId = document.getElementById('modalServerId')?.value || '';
    }

    modalConfirm.disabled = true;
    const result = await nui(action, payload);
    modalConfirm.disabled = false;

    if (result?.ok) {
      closeModal();
      if (result.data) applyData(result.data);
      else {
        const fresh = await nui('refresh');
        applyData(fresh);
      }
    }
  }

  async function exportCsv() {
    const result = await nui('exportCsv', {
      accountType: state.selected?.type || 'personal',
    });
    const rows = result?.transactions || getSelectedHistory();
    const header = 'Date;Type;Libellé;Montant;Acteur;Solde après\n';
    const body = rows
      .map((tx) =>
        [
          tx.created_at || '',
          tx.type || '',
          `"${(tx.label || '').replace(/"/g, '""')}"`,
          tx.amount || 0,
          tx.actor_name || '',
          tx.balance_after ?? '',
        ].join(';')
      )
      .join('\n');

    const blob = new Blob([header + body], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `releve_${state.selected?.type || 'compte'}_${Date.now()}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  function escapeHtml(str) {
    return String(str ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function escapeAttr(str) {
    return escapeHtml(str).replace(/'/g, '&#39;');
  }

  // Events
  document.getElementById('closeBtn').addEventListener('click', closeUI);
  modalCancel.addEventListener('click', closeModal);
  modalClose.addEventListener('click', closeModal);
  modalConfirm.addEventListener('click', confirmModal);

  document.querySelectorAll('.action-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      if (btn.disabled) return;
      openActionModal(btn.dataset.action);
    });
  });

  document.getElementById('addFavBtn').addEventListener('click', async () => {
    const name = document.getElementById('favName').value.trim();
    const accountNumber = document.getElementById('favNumber').value.trim();
    if (!name || !accountNumber) return;
    const result = await nui('addFavorite', { name, accountNumber });
    if (result?.ok && result.favorites) {
      state.data.favorites = result.favorites;
      document.getElementById('favName').value = '';
      document.getElementById('favNumber').value = '';
      renderFavorites();
    }
  });

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (!modal.classList.contains('hidden')) {
        closeModal();
      } else if (!app.classList.contains('hidden')) {
        closeUI();
      }
    }
  });

  window.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || !msg.action) return;
    if (msg.action === 'open') openUI(msg);
    if (msg.action === 'close') {
      app.classList.add('hidden');
      closeModal();
    }
  });

  // ─── Mock preview (browser) ───────────────────────────────
  function mockNui(event, data) {
    if (event === 'close') return {};
    if (event === 'refresh') return Promise.resolve(mockData());
    if (event === 'deposit' || event === 'withdraw' || event === 'transfer') {
      const d = mockData();
      const amount = Number(data.amount) || 0;
      if (data.accountType === 'business') {
        d.business.balance += event === 'deposit' ? amount : -amount;
        d.accounts[1].balance = d.business.balance;
      } else {
        d.personal.balance += event === 'deposit' ? amount : -amount;
        d.accounts[0].balance = d.personal.balance;
      }
      d.totalBalance = d.personal.balance + (d.business?.balance || 0);
      return Promise.resolve({ ok: true, amount, data: d });
    }
    if (event === 'addFavorite') {
      const favs = state.data.favorites || [];
      favs.push({
        id: Date.now(),
        name: data.name,
        account_number: data.accountNumber,
      });
      return Promise.resolve({ ok: true, favorites: favs });
    }
    if (event === 'removeFavorite') {
      const favs = (state.data.favorites || []).filter((f) => f.id !== data.id);
      return Promise.resolve({ ok: true, favorites: favs });
    }
    if (event === 'exportCsv' || event === 'getHistory') {
      return Promise.resolve({
        transactions:
          data.accountType === 'business'
            ? mockData().history.business
            : mockData().history.personal,
      });
    }
    return {};
  }

  function mockData() {
    return {
      playerName: 'Jack Owen',
      identifier: 'char1:abc',
      totalBalance: 15800,
      personal: {
        id: 'char1:abc',
        type: 'personal',
        name: 'Jack Owen',
        accountNumber: 'US7FL1615969984',
        balance: 5000,
        cash: 1200,
      },
      business: {
        id: 'society_police',
        type: 'business',
        name: 'Los Santos Police',
        accountNumber: 'ENT-POLICE',
        balance: 10800,
        job: 'police',
        grade: 3,
        gradeLabel: 'Lieutenant',
        canWithdraw: true,
        canTransfer: true,
        canDeposit: true,
        exists: true,
      },
      accounts: [
        {
          id: 'char1:abc',
          type: 'personal',
          name: 'Jack Owen',
          accountNumber: 'US7FL1615969984',
          balance: 5000,
          cash: 1200,
        },
        {
          id: 'society_police',
          type: 'business',
          name: 'Los Santos Police',
          accountNumber: 'ENT-POLICE',
          balance: 10800,
          job: 'police',
          grade: 3,
          gradeLabel: 'Lieutenant',
          canWithdraw: true,
          canTransfer: true,
          canDeposit: true,
          exists: true,
        },
      ],
      favorites: [],
      history: {
        personal: [
          {
            type: 'withdraw',
            label: 'permis',
            amount: -500,
            created_at: '2026-06-24T19:19:00',
            actor_name: 'Jack Owen',
          },
          {
            type: 'deposit',
            label: 'Salaire de Vega du 24-06-2026',
            amount: 80,
            created_at: '2026-06-24T20:17:00',
            actor_name: 'Jack Owen',
          },
        ],
        business: [
          {
            type: 'withdraw',
            label: 'Retrait entreprise — Jack Owen',
            amount: -2000,
            created_at: '2026-06-24T14:00:00',
            actor_name: 'Jack Owen',
          },
          {
            type: 'deposit',
            label: 'Dépôt entreprise — Jack Owen',
            amount: 5000,
            created_at: '2026-06-23T10:00:00',
            actor_name: 'Jack Owen',
          },
        ],
      },
    };
  }

  // Auto-preview when opened in browser
  if (!isNui) {
    openUI({
      mode: 'bank',
      currency: '$',
      locale: {
        bank_title: 'Banque',
        atm_title: 'Distributeur (DAB)',
        no_transactions: 'Aucune transaction pour ce compte',
      },
      data: mockData(),
    });
  }
})();
