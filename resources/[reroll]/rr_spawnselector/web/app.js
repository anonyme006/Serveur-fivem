const app = document.getElementById('app');
const list = document.getElementById('list');

function nui(name, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  }).then((r) => r.json()).catch(() => ({}));
}

function render(spawns = []) {
  list.innerHTML = '';
  spawns.forEach((spawn) => {
    const btn = document.createElement('button');
    btn.className = 'spawn';
    btn.type = 'button';
    btn.innerHTML = `<strong>${spawn.label}</strong><span>${spawn.description || ''}</span>`;
    btn.addEventListener('click', () => nui('selectSpawn', { id: spawn.id }));
    list.appendChild(btn);
  });
}

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'open') {
    render(data.spawns || []);
    app.classList.remove('hidden');
  }
  if (data.action === 'close') {
    app.classList.add('hidden');
  }
});

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') nui('close');
});
