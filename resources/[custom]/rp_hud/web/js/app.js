const hud = document.getElementById('hud');
const setBar = (id, value) => {
  const el = document.getElementById(id);
  if (!el) return;
  el.style.height = `${Math.max(0, Math.min(100, Number(value) || 0))}%`;
};

window.addEventListener('message', (event) => {
  const msg = event.data || {};
  if (msg.action === 'toggle') {
    hud.classList.toggle('hidden', !msg.show);
    return;
  }
  if (msg.action === 'brand' && msg.name) {
    document.getElementById('brand-name').textContent = msg.name;
    return;
  }
  if (msg.action === 'update') {
    const d = msg.data || {};
    setBar('health', d.health);
    setBar('armor', d.armor);
    document.getElementById('mic').classList.toggle('active', !!d.talking);
    if (typeof d.street === 'string') {
      document.getElementById('location').textContent = d.street;
    }
    const veh = document.getElementById('vehicle');
    if (d.vehicle) {
      veh.classList.remove('hidden');
      document.getElementById('speed').textContent = d.speed || 0;
      document.getElementById('fuel').style.width = `${Math.max(0, Math.min(100, d.fuel || 0))}%`;
    } else {
      veh.classList.add('hidden');
    }
  }
  if (msg.action === 'needs') {
    const d = msg.data || {};
    setBar('hunger', d.hunger);
    setBar('thirst', d.thirst);
    if (d.showStress) {
      document.querySelector('[data-need="stress"]').classList.remove('hidden');
      setBar('stress', d.stress);
    }
  }
});
