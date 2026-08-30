const toast = document.getElementById('toast');
const dot = document.getElementById('dot');
const statusEl = document.getElementById('status');
const labelEl = document.getElementById('label');

let hideTimer = null;

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || data.action !== 'status') return;

    if (hideTimer) {
        clearTimeout(hideTimer);
        hideTimer = null;
    }

    const onDuty = data.onDuty === true;
    dot.className = 'dot ' + (onDuty ? 'on' : 'off');
    statusEl.textContent = onDuty ? 'En service' : 'Hors service';
    labelEl.textContent = data.label || '';

    toast.classList.remove('hidden');

    hideTimer = setTimeout(() => {
        toast.classList.add('hidden');
    }, data.duration || 3500);
});
