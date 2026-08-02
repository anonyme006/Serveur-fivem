const app = document.getElementById('app');
const tagline = document.getElementById('tagline');
const cause = document.getElementById('cause');
const clock = document.getElementById('clock');
const emsBtn = document.getElementById('ems');

let remaining = 300;
let timerId = null;
let called = false;

function nui(name, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  }).then((r) => r.json()).catch(() => ({}));
}

function format(sec) {
  const m = Math.floor(sec / 60).toString().padStart(2, '0');
  const s = Math.floor(sec % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}

function tick() {
  clock.textContent = format(remaining);
  if (remaining <= 0) {
    clearInterval(timerId);
    timerId = null;
    return;
  }
  remaining -= 1;
}

function openUi(data = {}) {
  if (data.tagline) tagline.textContent = data.tagline;
  if (data.cause) cause.textContent = data.cause;
  remaining = Number(data.bleedOut) || 300;
  called = false;
  emsBtn.disabled = false;
  emsBtn.textContent = 'Appeler les EMS';
  app.classList.remove('hidden');
  if (timerId) clearInterval(timerId);
  tick();
  timerId = setInterval(tick, 1000);
}

function closeUi() {
  app.classList.add('hidden');
  if (timerId) clearInterval(timerId);
  timerId = null;
}

emsBtn.addEventListener('click', async () => {
  if (called) return;
  called = true;
  emsBtn.disabled = true;
  emsBtn.textContent = 'Secours alertés';
  await nui('callEms');
});

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'open') openUi(data);
  if (data.action === 'close') closeUi();
});
