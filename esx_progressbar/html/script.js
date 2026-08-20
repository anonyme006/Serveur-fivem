(() => {
    const root = document.getElementById('progress-root');
    const track = document.getElementById('progress-track');
    const fill = document.getElementById('progress-fill');
    const labelEl = document.getElementById('progress-label');

    let hideTimer = null;
    let animFrame = null;
    let startTs = 0;
    let duration = 0;
    let running = false;

    function applyTheme(data = {}) {
        const rootStyle = document.documentElement.style;
        if (data.fillColor) rootStyle.setProperty('--fill', data.fillColor);
        if (data.trackColor) rootStyle.setProperty('--track', data.trackColor);
        if (data.width != null) rootStyle.setProperty('--bar-width', `${data.width}vw`);
        if (data.height != null) rootStyle.setProperty('--bar-height', `${data.height}px`);
        if (data.position) root.dataset.position = data.position;
    }

    function setPercent(pct) {
        const value = Math.max(0, Math.min(100, pct));
        fill.style.width = `${value}%`;
        track.setAttribute('aria-valuenow', String(Math.round(value)));
    }

    function stopAnim() {
        if (animFrame != null) {
            cancelAnimationFrame(animFrame);
            animFrame = null;
        }
        running = false;
    }

    function tick(now) {
        if (!running) return;
        const elapsed = now - startTs;
        const pct = duration > 0 ? (elapsed / duration) * 100 : 100;
        setPercent(pct);
        if (elapsed < duration) {
            animFrame = requestAnimationFrame(tick);
        } else {
            setPercent(100);
            running = false;
            animFrame = null;
        }
    }

    function hide(immediate) {
        stopAnim();
        if (hideTimer) {
            clearTimeout(hideTimer);
            hideTimer = null;
        }

        if (immediate) {
            root.classList.remove('is-visible', 'is-hiding');
            root.classList.add('hidden');
            fill.classList.remove('animating');
            setPercent(0);
            return;
        }

        root.classList.remove('is-visible');
        root.classList.add('is-hiding');
        hideTimer = setTimeout(() => {
            root.classList.add('hidden');
            root.classList.remove('is-hiding');
            fill.classList.remove('animating');
            setPercent(0);
            hideTimer = null;
        }, 170);
    }

    function start(data = {}) {
        stopAnim();
        if (hideTimer) {
            clearTimeout(hideTimer);
            hideTimer = null;
        }

        applyTheme(data);

        const label = (data.label || '').trim();
        if (label) {
            labelEl.textContent = label;
            labelEl.classList.remove('hidden');
        } else {
            labelEl.textContent = '';
            labelEl.classList.add('hidden');
        }

        duration = Math.max(0, Number(data.duration) || 0);
        startTs = performance.now();
        running = true;

        fill.classList.remove('animating');
        setPercent(0);

        root.classList.remove('hidden', 'is-hiding');
        // force reflow for entrance animation restart
        void root.offsetWidth;
        root.classList.add('is-visible');

        if (duration <= 0) {
            setPercent(100);
            running = false;
            return;
        }

        animFrame = requestAnimationFrame(tick);
    }

    function cancel() {
        hide(false);
    }

    function finish() {
        setPercent(100);
        stopAnim();
        hide(false);
    }

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        switch (data.action) {
            case 'start':
                start(data);
                break;
            case 'cancel':
                cancel();
                break;
            case 'finish':
                finish();
                break;
            case 'theme':
                applyTheme(data);
                break;
            case 'setPercent':
                setPercent(Number(data.percent) || 0);
                break;
            default:
                break;
        }
    });

    // Preview / debug helper in browser
    window.__progressPreview = { start, cancel, finish, setPercent, applyTheme };
})();
