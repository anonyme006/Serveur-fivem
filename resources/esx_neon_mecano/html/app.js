const pager = document.getElementById('pager');
const codeEl = document.getElementById('code');
const msgEl = document.getElementById('message');
const payoutEl = document.getElementById('payout');

function post(name) {
    fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    });
}

document.getElementById('btn-accept').addEventListener('click', () => post('accept'));
document.getElementById('btn-decline').addEventListener('click', () => post('decline'));
document.getElementById('btn-close').addEventListener('click', () => post('close'));

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'show') {
        codeEl.textContent = data.code || 'DEP-???';
        msgEl.textContent = data.message || '';
        payoutEl.textContent = data.payout ? `Gain estimé : ${data.payout}$` : 'Mission dépannage';
        pager.classList.remove('hidden');
    }

    if (data.action === 'hide') {
        pager.classList.add('hidden');
    }

    if (data.action === 'beep') {
        pager.classList.remove('hidden');
        pager.classList.add('beep-flash');
        setTimeout(() => pager.classList.remove('beep-flash'), 500);
    }
});
