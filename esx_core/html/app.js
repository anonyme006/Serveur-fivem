const app = document.getElementById('app');
const titleEl = document.getElementById('title');
const nameEl = document.getElementById('playerName');
const accountsEl = document.getElementById('accounts');
const keysTitleEl = document.getElementById('keysTitle');
const keysListEl = document.getElementById('keysList');
const closeBtn = document.getElementById('closeBtn');

let labels = {};

function money(n) {
  return new Intl.NumberFormat('fr-FR').format(Math.floor(Number(n) or 0)) + ' $';
}

function closeUi() {
  app.classList.add('hidden');
  fetch(`https://${GetParentResourceName()}/close`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{}',
  });
}

closeBtn.addEventListener('click', closeUi);

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeUi();
});

function renderAccounts(accounts) {
  accountsEl.innerHTML = '';
  (accounts || []).forEach((acc) => {
    const div = document.createElement('div');
    div.className = 'account';
    div.innerHTML = `<span>${acc.label}</span><strong>${money(acc.amount)}</strong>`;
    accountsEl.appendChild(div);
  });
}

function renderKeys(keys, noKeys) {
  keysListEl.innerHTML = '';
  if (!keys || keys.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty';
    empty.textContent = noKeys || 'Aucune clé';
    keysListEl.appendChild(empty);
    return;
  }

  keys.forEach((key) => {
    const card = document.createElement('div');
    card.className = 'key-card';

    const typeLabel = key.type === 'house'
      ? (labels.house || 'Habitation — %s').replace('%s', key.label || key.ref)
      : (labels.vehicle || 'Véhicule — %s').replace('%s', key.label || key.ref);

    const meta = document.createElement('div');
    meta.className = 'key-meta';
    meta.innerHTML = `<strong>${typeLabel}</strong><small>${key.temporary ? 'Temporaire' : (key.isOwner ? 'Propriétaire' : 'Détenteur')}</small>`;

    const actions = document.createElement('div');
    actions.className = 'key-actions';

    const give = document.createElement('button');
    give.textContent = labels.give || 'Donner';
    give.addEventListener('click', () => {
      fetch(`https://${GetParentResourceName()}/giveKey`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: key.type, ref: key.ref, id: key.id }),
      });
    });
    actions.appendChild(give);

    if (key.id && !key.implicit) {
      const remove = document.createElement('button');
      remove.className = 'danger';
      remove.textContent = labels.remove || 'Retirer';
      remove.addEventListener('click', () => {
        fetch(`https://${GetParentResourceName()}/removeKey`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ id: key.id }),
        }).then(() => {
          card.remove();
          if (!keysListEl.children.length) renderKeys([], noKeys);
        });
      });
      actions.appendChild(remove);
    }

    card.appendChild(meta);
    card.appendChild(actions);
    keysListEl.appendChild(card);
  });
}

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'open') {
    labels = data.labels || {};
    titleEl.textContent = data.title || 'Portefeuille';
    nameEl.textContent = data.name || '';
    keysTitleEl.textContent = data.keysTitle || 'Trousseau';
    renderAccounts(data.accounts);
    renderKeys(data.keys, data.noKeys);
    app.classList.remove('hidden');
  }
  if (data.action === 'close') {
    app.classList.add('hidden');
  }
});
