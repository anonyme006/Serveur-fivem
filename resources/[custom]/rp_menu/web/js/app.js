const app = document.getElementById('app');
const content = document.getElementById('content');
const title = document.getElementById('title');
const subtitle = document.getElementById('subtitle');
const nav = document.getElementById('nav');

let state = { player: null, licenses: [], section: 'character' };

const post = (name, data = {}) =>
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  });

const sections = [
  { id: 'character', label: 'Personnage', title: 'Personnage', sub: 'Identité & informations' },
  { id: 'job', label: 'Travail', title: 'Travail', sub: 'Métier, service, entreprise' },
  { id: 'licenses', label: 'Licences', title: 'Licences', sub: 'Permis & documents' },
  { id: 'actions', label: 'Actions', title: 'Actions', sub: 'Animations, factures, paramètres' },
];

function renderNav() {
  nav.innerHTML = '';
  sections.forEach((s) => {
    const b = document.createElement('button');
    b.textContent = s.label;
    b.className = state.section === s.id ? 'active' : '';
    b.onclick = () => {
      state.section = s.id;
      render();
    };
    nav.appendChild(b);
  });
}

function renderCharacter() {
  const p = state.player || {};
  content.innerHTML = `
    <div class="grid">
      <div class="card"><span>Nom</span><strong>${p.name || '—'}</strong></div>
      <div class="card"><span>Citizen ID</span><strong>${p.citizenid || '—'}</strong></div>
      <div class="card"><span>Naissance</span><strong>${p.birthdate || '—'}</strong></div>
      <div class="card"><span>Nationalité</span><strong>${p.nationality || '—'}</strong></div>
      <div class="card"><span>Téléphone</span><strong>${p.phone || '—'}</strong></div>
      <div class="card"><span>Liquidités</span><strong>${p.cash ?? 0} $ · Banque ${p.bank ?? 0} $</strong></div>
    </div>`;
}

function renderJob() {
  const job = (state.player && state.player.job) || {};
  content.innerHTML = `
    <div class="list">
      <div class="row"><div><strong>${job.label || job.name || 'Sans emploi'}</strong><br><small>Grade ${job.grade?.name || '—'} · Service ${job.onduty ? 'oui' : 'non'}</small></div></div>
    </div>
    <div class="actions">
      <button data-act="duty">Prise / fin de service</button>
      <button class="secondary" data-act="business">Infos entreprise</button>
    </div>`;
  content.querySelectorAll('button[data-act]').forEach((btn) => {
    btn.onclick = () => post(btn.dataset.act);
  });
}

function renderLicenses() {
  const rows = (state.licenses || []).map((l) => `
    <div class="row">
      <div><strong>${l.label}</strong><br><small>${l.owned ? 'Possédé' : 'Non possédé'}</small></div>
    </div>`).join('');
  content.innerHTML = `<div class="list">${rows || '<div class="row">Aucune licence</div>'}</div>`;
}

function renderActions() {
  content.innerHTML = `
    <div class="actions">
      <button data-act="anims">Animations</button>
      <button class="secondary" data-act="invoices">Factures</button>
      <button class="secondary" data-act="logout">Déconnexion personnage</button>
    </div>`;
  content.querySelectorAll('button[data-act]').forEach((btn) => {
    btn.onclick = () => post(btn.dataset.act);
  });
}

function render() {
  const meta = sections.find((s) => s.id === state.section) || sections[0];
  title.textContent = meta.title;
  subtitle.textContent = meta.sub;
  renderNav();
  if (state.section === 'character') renderCharacter();
  if (state.section === 'job') renderJob();
  if (state.section === 'licenses') renderLicenses();
  if (state.section === 'actions') renderActions();
}

document.getElementById('close').onclick = () => {
  app.classList.add('hidden');
  post('close');
};

window.addEventListener('message', (e) => {
  const msg = e.data || {};
  if (msg.action === 'open') {
    state.player = msg.player;
    state.licenses = msg.licenses || [];
    state.section = 'character';
    if (msg.brand) document.getElementById('brand').textContent = msg.brand;
    app.classList.remove('hidden');
    render();
  }
  if (msg.action === 'close') app.classList.add('hidden');
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !app.classList.contains('hidden')) {
    app.classList.add('hidden');
    post('close');
  }
});
