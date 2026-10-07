(() => {
  const cardEl = document.getElementById('card');
  const licensesEl = document.getElementById('licenses');
  const hintEl = document.getElementById('hint');
  let closeKey = 'Backspace';
  let autoCloseTimer = null;
  let previousPoints = {};

  function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value || '—';
  }

  function statusClass(lic) {
    if (lic.valid) return 'ok';
    if (lic.owned) return 'warn';
    return 'bad';
  }

  function renderLicenses(list) {
    licensesEl.innerHTML = '';
    (list || []).forEach((lic) => {
      const row = document.createElement('article');
      row.className = 'license-row';
      row.dataset.type = lic.name;

      const prev = previousPoints[lic.name];
      if (prev !== undefined && prev !== lic.points) {
        row.classList.add('is-updated');
        setTimeout(() => row.classList.remove('is-updated'), 1200);
      }
      previousPoints[lic.name] = lic.points;

      row.innerHTML = `
        <div class="license-accent" style="--accent:${lic.color || '#ff8c42'}"></div>
        <div class="license-meta">
          <h2>${lic.label}</h2>
          <p>${lic.short || ''}</p>
        </div>
        <div class="license-points">
          <div class="pts">${lic.owned ? `${lic.points} / ${lic.maxPoints}` : '—'}</div>
          <span class="status ${statusClass(lic)}">${lic.status || ''}</span>
        </div>
      `;
      licensesEl.appendChild(row);
    });
  }

  function fillCard(data) {
    setText('firstname', data.firstname);
    setText('lastname', data.lastname);
    setText('birthdate', data.birthdate);
    setText('sex', data.sex);
    setText('nationality', data.nationality);
    setText('citizenid', data.citizenid);
    renderLicenses(data.licenses);
  }

  function closeCard() {
    if (autoCloseTimer) {
      clearTimeout(autoCloseTimer);
      autoCloseTimer = null;
    }
    cardEl.classList.add('is-closing');
    setTimeout(() => {
      cardEl.hidden = true;
      cardEl.classList.remove('is-closing');
      previousPoints = {};
    }, 220);
    fetch(`https://${GetParentResourceName()}/closeCard`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: '{}',
    }).catch(() => {});
  }

  function openCard(payload) {
    closeKey = payload.closeKey || 'Backspace';
    hintEl.textContent = `${closeKey} pour fermer`;
    fillCard(payload.card || {});
    cardEl.hidden = false;
    cardEl.classList.remove('is-closing');

    if (autoCloseTimer) clearTimeout(autoCloseTimer);
    const ms = Number(payload.autoCloseMs) || 0;
    if (ms > 0) {
      autoCloseTimer = setTimeout(closeCard, ms);
    }
  }

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'open') {
      openCard(data);
    } else if (data.action === 'update') {
      fillCard(data.card || {});
    } else if (data.action === 'close') {
      cardEl.hidden = true;
      previousPoints = {};
    }
  });

  window.addEventListener('keydown', (event) => {
    if (cardEl.hidden) return;
    if (event.key === closeKey || event.key === 'Escape') {
      closeCard();
    }
  });
})();
