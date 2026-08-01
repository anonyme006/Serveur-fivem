(() => {
    const root = document.getElementById('notify-root');
    const toasts = new Map();
    let seq = 0;

    function escapeHtml(str) {
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function applyLayout(data = {}) {
        if (data.position) root.dataset.position = data.position;
        if (data.vertical) root.dataset.vertical = data.vertical;
    }

    function removeToast(id, immediate) {
        const entry = toasts.get(id);
        if (!entry) return;

        if (entry.timer) {
            clearTimeout(entry.timer);
            entry.timer = null;
        }

        const el = entry.el;
        if (immediate) {
            el.remove();
            toasts.delete(id);
            return;
        }

        el.classList.add('is-leaving');
        setTimeout(() => {
            el.remove();
            toasts.delete(id);
        }, 280);
    }

    function enforceMax(maxVisible) {
        const limit = Math.max(1, Number(maxVisible) || 5);
        while (toasts.size > limit) {
            const oldestId = toasts.keys().next().value;
            removeToast(oldestId, true);
        }
    }

    function notify(data = {}) {
        applyLayout(data);

        const id = data.id != null ? String(data.id) : `n-${++seq}`;
        if (toasts.has(id)) {
            removeToast(id, true);
        }

        const color = data.color || '#E74C3C';
        const duration = Math.max(0, Number(data.duration) || 5000);
        const showDuration = data.showDuration !== false && duration > 0;
        const title = (data.title || '').trim();
        const description = (data.description || '').trim();

        if (!title && !description) return;

        const el = document.createElement('div');
        el.className = 'toast';
        el.style.setProperty('--accent', color);
        el.dataset.id = id;
        el.dataset.type = data.type || 'inform';

        const iconHtml = data.icon
            ? `<div class="toast-icon"><i class="fa-solid ${escapeHtml(data.icon)}"></i></div>`
            : '';

        const titleHtml = title ? `<div class="toast-title">${escapeHtml(title)}</div>` : '';
        const descHtml = description ? `<div class="toast-desc">${escapeHtml(description)}</div>` : '';

        el.innerHTML = `
            <div class="toast-inner">
                ${iconHtml}
                <div class="toast-text">
                    ${titleHtml}
                    ${descHtml}
                </div>
            </div>
            ${showDuration ? '<div class="toast-progress is-animating"><span></span></div>' : ''}
        `;

        if (showDuration) {
            const bar = el.querySelector('.toast-progress > span');
            if (bar) {
                bar.style.animationDuration = `${duration}ms`;
            }
        }

        el.addEventListener('click', () => removeToast(id, false));

        root.appendChild(el);
        toasts.set(id, { el, timer: null });
        enforceMax(data.maxVisible);

        if (duration > 0) {
            const entry = toasts.get(id);
            entry.timer = setTimeout(() => removeToast(id, false), duration);
        }
    }

    function clearAll() {
        for (const id of [...toasts.keys()]) {
            removeToast(id, true);
        }
    }

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        switch (data.action) {
            case 'notify':
                notify(data);
                break;
            case 'clear':
                clearAll();
                break;
            case 'layout':
                applyLayout(data);
                break;
            default:
                break;
        }
    });

    window.__notifyPreview = { notify, clearAll, applyLayout };
})();
