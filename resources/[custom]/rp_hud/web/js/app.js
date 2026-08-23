const hud = document.getElementById('hud');
const setWidth = (id, value) => {
  const el = document.getElementById(id);
  if (el) el.style.width = Math.max(0, Math.min(100, value || 0)) + '%';
};

window.addEventListener('message', (e) => {
  const { action, data, show } = e.data || {};
  if (action === 'toggle') {
    hud.classList.toggle('hidden', !show);
    return;
  }
  if (action === 'update' && data) {
    setWidth('health', data.health);
    setWidth('armor', data.armor);
    document.getElementById('mic').classList.toggle('active', !!data.talking);
    if (data.street) document.getElementById('location').textContent = data.street;
    const veh = document.getElementById('vehicle');
    if (data.vehicle) {
      veh.classList.remove('hidden');
      document.getElementById('speed').textContent = data.speed || 0;
      document.getElementById('fuel').textContent = Math.floor(data.fuel || 0) + '%';
    } else {
      veh.classList.add('hidden');
    }
  }
  if (action === 'needs' && data) {
    setWidth('hunger', data.hunger);
    setWidth('thirst', data.thirst);
    setWidth('stress', data.stress);
    if (data.cash != null) {
      document.getElementById('money').classList.remove('hidden');
      document.getElementById('cash').textContent = data.cash;
      document.getElementById('bank').textContent = data.bank;
    }
  }
});
