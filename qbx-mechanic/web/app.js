const app = document.getElementById('app');
const panels = {
    vehicle: document.getElementById('panel-vehicle'),
    diagnostic: document.getElementById('panel-diagnostic'),
    actions: document.getElementById('panel-actions'),
    billing: document.getElementById('panel-billing'),
};

function post(action, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    });
}

function setVisible(visible) {
    app.classList.toggle('hidden', !visible);
}

function switchTab(tab) {
    document.querySelectorAll('.nav-item').forEach((btn) => {
        btn.classList.toggle('active', btn.dataset.tab === tab);
    });

    Object.entries(panels).forEach(([key, panel]) => {
        panel.classList.toggle('active', key === tab);
    });
}

document.querySelectorAll('.nav-item').forEach((btn) => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

document.getElementById('btn-close').addEventListener('click', () => {
    setVisible(false);
    post('close');
});

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};

    switch (action) {
        case 'open':
            setVisible(true);
            if (data?.shopLabel) {
                document.getElementById('shop-label').textContent = data.shopLabel;
            }
            if (data?.colors) {
                Object.entries(data.colors).forEach(([key, value]) => {
                    document.documentElement.style.setProperty(`--${key.replace(/([A-Z])/g, '-$1').toLowerCase()}`, value);
                });
            }
            break;
        case 'close':
            setVisible(false);
            break;
        case 'setTab':
            if (data?.tab) switchTab(data.tab);
            break;
        default:
            break;
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        setVisible(false);
        post('close');
    }
});

setVisible(false);
