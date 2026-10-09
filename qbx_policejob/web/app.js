(() => {
    const app = document.getElementById('app');
    const titleEl = document.getElementById('panel-title');
    const bodyEl = document.getElementById('panel-body');
    const closeBtn = document.getElementById('btn-close');

    const resourceName = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'qbx_policejob';

    function post(name, data = {}) {
        return fetch(`https://${resourceName}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        }).catch(() => undefined);
    }

    function openPanel(payload = {}) {
        if (titleEl) titleEl.textContent = payload.title || 'Police';
        if (bodyEl && payload.html) {
            bodyEl.innerHTML = payload.html;
        }
        app.classList.remove('hidden');
        app.setAttribute('aria-hidden', 'false');
    }

    function closePanel() {
        app.classList.add('hidden');
        app.setAttribute('aria-hidden', 'true');
        post('close');
    }

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        if (data.action === 'open') openPanel(data);
        if (data.action === 'close') {
            app.classList.add('hidden');
            app.setAttribute('aria-hidden', 'true');
        }
    });

    closeBtn?.addEventListener('click', closePanel);

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !app.classList.contains('hidden')) {
            closePanel();
        }
    });
})();
