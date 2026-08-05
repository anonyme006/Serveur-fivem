(() => {
    const app = document.getElementById('app');
    const jobList = document.getElementById('jobList');
    const confirmBtn = document.getElementById('confirmBtn');
    const sloganEl = document.getElementById('slogan');

    let jobs = [];
    let selectedId = null;

    const LOCK_SVG = `<svg class="lock-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M17 8h-1V6a4 4 0 0 0-8 0v2H7a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V10a2 2 0 0 0-2-2zm-7-2a2 2 0 1 1 4 0v2h-4V6zm7 14H7V10h10v10z"/></svg>`;

    function post(name, data = {}) {
        fetch(`https://esx_interim/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        }).catch(() => {});
    }

    function render() {
        jobList.innerHTML = '';
        jobs.forEach((job) => {
            const li = document.createElement('li');
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'job-item';
            btn.dataset.id = job.id;
            btn.setAttribute('role', 'option');

            if (job.locked) btn.classList.add('locked');
            if (selectedId === job.id) btn.classList.add('selected');

            const lockHtml = job.locked ? LOCK_SVG : '<span class="lock-spacer"></span>';
            const sub = job.subtitle ? `<span class="job-sub">(${job.subtitle})</span>` : '';
            btn.innerHTML = `${lockHtml}<span class="job-label">${job.label}${sub}</span>`;

            btn.addEventListener('click', () => {
                if (job.locked) return;
                selectedId = job.id;
                confirmBtn.disabled = false;
                render();
            });

            li.appendChild(btn);
            jobList.appendChild(li);
        });
    }

    confirmBtn.addEventListener('click', () => {
        if (!selectedId) return;
        post('selectJob', { id: selectedId });
    });

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        if (data.action === 'open') {
            jobs = Array.isArray(data.jobs) ? data.jobs : [];
            selectedId = null;
            confirmBtn.disabled = true;
            if (data.slogan) sloganEl.textContent = data.slogan;
            if (data.confirmLabel) confirmBtn.textContent = data.confirmLabel;
            app.classList.remove('hidden');
            render();
        } else if (data.action === 'close') {
            app.classList.add('hidden');
            selectedId = null;
        }
    });

    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            post('close');
        }
    });
})();
