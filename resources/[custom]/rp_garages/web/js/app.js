const app = document.getElementById('app');
const list = document.getElementById('list');
const title = document.getElementById('title');
const search = document.getElementById('search');
let state = { garage: null, vehicles: [] };

const post = (name, data = {}) =>
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });

function render(filter = '') {
  list.innerHTML = '';
  const q = filter.toLowerCase();
  state.vehicles
    .filter((v) => !q || String(v.plate).toLowerCase().includes(q) || String(v.vehicle).toLowerCase().includes(q))
    .forEach((v) => {
      const el = document.createElement('div');
      el.className = 'card';
      const isImpound = state.garage?.type === 'impound';
      el.innerHTML = `
        <div class="meta">
          <strong>${v.vehicle}</strong>
          <small>${v.plate} · Moteur ${Math.floor((v.engine || 1000) / 10)}% · Carrosserie ${Math.floor((v.body || 1000) / 10)}%</small>
        </div>
        <button class="primary">${isImpound ? 'Récupérer' : 'Sortir'}</button>`;
      el.querySelector('button').onclick = () => {
        if (isImpound) post('release', { vehicleId: v.id });
        else post('spawn', { garageId: state.garage.id, vehicleId: v.id });
        app.classList.add('hidden');
      };
      list.appendChild(el);
    });
}

document.getElementById('close').onclick = () => {
  app.classList.add('hidden');
  post('close');
};
document.getElementById('btn-store').onclick = () => {
  post('store', { garageId: state.garage.id });
  app.classList.add('hidden');
};
search.oninput = () => render(search.value);

window.addEventListener('message', (e) => {
  if (e.data?.action === 'open') {
    state.garage = e.data.garage;
    state.vehicles = e.data.vehicles || [];
    title.textContent = state.garage.label;
    app.classList.remove('hidden');
    render();
  }
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    app.classList.add('hidden');
    post('close');
  }
});
