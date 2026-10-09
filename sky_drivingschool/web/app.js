(() => {
  const app = document.getElementById('app');
  const practicalHud = document.getElementById('practicalHud');
  let state = {
    school: null,
    player: null,
    categories: [],
    licenses: [],
    history: [],
    pointsHistory: [],
    strings: {},
    isAdmin: false,
    requireTheory: true,
    selectedCategory: null,
    theory: null,
    theoryIndex: 0,
    theoryAnswers: {},
    theoryTimer: null,
    admin: null,
  };

  const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'sky_drivingschool';
  const isPreview = new URLSearchParams(location.search).get('preview') === '1'
    || window.parent !== window;

  function post(name, data = {}) {
    if (isPreview) {
      // Browser preview: no FiveM NUI callbacks
      if (name === 'close') return Promise.resolve({ ok: true });
      if (name === 'refreshSchool') return Promise.resolve({ ok: true, data: { school: state.school, player: state.player, categories: state.categories, licenses: state.licenses, history: state.history, pointsHistory: state.pointsHistory, stats: state.stats, isAdmin: state.isAdmin, requireTheory: state.requireTheory } });
      if (name === 'adminDashboard') return Promise.resolve(state.admin || { ok: false, error: 'Open Admin from preview toolbar' });
      if (name === 'startTheory' || name === 'startPractical' || name === 'submitTheory' || name === 'cancelTheory') {
        return Promise.resolve({ ok: false, error: 'Preview mode — actions are visual only' });
      }
      return Promise.resolve({ ok: true });
    }
    return fetch(`https://${resourceName}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).then((r) => r.json()).catch(() => ({ ok: false }));
  }

  function $(sel, root = document) { return root.querySelector(sel); }
  function $all(sel, root = document) { return [...root.querySelectorAll(sel)]; }

  function showView(view) {
    $all('.view').forEach((el) => el.classList.add('hidden'));
    const el = document.getElementById(`view-${view}`);
    if (el) el.classList.remove('hidden');
    $all('.nav-btn').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.view === view);
    });
    if (view === 'catalog') renderCatalog();
    if (view === 'history') renderHistory();
    if (view === 'licenseCard') renderLicenseCard();
    if (view === 'admin') loadAdmin();
    if (view === 'home') renderHome();
  }

  function openUI(view, data) {
    if (data) applyDashboard(data);
    app.classList.remove('hidden');
    if (view === 'theory' && data && data.questions) {
      startTheoryUI(data);
      return;
    }
    if (view === 'theoryResult') {
      renderTheoryResult(data);
      showView('theoryResult');
      return;
    }
    if (view === 'practicalResult') {
      renderPracticalResult(data);
      showView('practicalResult');
      return;
    }
    if (view === 'licenseCard') {
      if (data && data.cards) {
        state.licenses = data.cards;
        state.player = state.player || { firstName: data.firstName, lastName: data.lastName };
      }
      showView('licenseCard');
      return;
    }
    if (view === 'admin') {
      state.admin = data;
      renderAdmin(data);
      showView('admin');
      return;
    }
    showView(view || 'home');
  }

  function closeUI() {
    app.classList.add('hidden');
    clearTheoryTimer();
    post('close');
  }

  function applyDashboard(data) {
    if (!data) return;
    if (data.school) state.school = data.school;
    if (data.player) state.player = data.player;
    if (data.categories) state.categories = data.categories;
    if (data.licenses) state.licenses = data.licenses;
    if (data.history) state.history = data.history;
    if (data.pointsHistory) state.pointsHistory = data.pointsHistory;
    if (data.strings) state.strings = data.strings;
    if (typeof data.isAdmin === 'boolean') state.isAdmin = data.isAdmin;
    if (typeof data.requireTheory === 'boolean') state.requireTheory = data.requireTheory;
    if (data.stats) state.stats = data.stats;
    $('#schoolLabel').textContent = (state.school && state.school.label) || 'Driving School';
    $('#navAdmin').classList.toggle('hidden', !state.isAdmin);
  }

  function money(n) {
    return `$${Number(n || 0).toLocaleString('en-US')}`;
  }

  function iconFor(icon) {
    const map = {
      car: 'CAR', motorcycle: 'MOTO', truck: 'TRK', bus: 'CDL',
      ship: 'BOAT', plane: 'AIR',
    };
    return map[icon] || 'DMV';
  }

  function statusBadge(status) {
    if (status === 'valid') return '<span class="badge ok">Valid</span>';
    if (status === 'suspended') return '<span class="badge warn">Suspended</span>';
    if (status === 'revoked') return '<span class="badge bad">Revoked</span>';
    return '<span class="badge neutral">Not held</span>';
  }

  function renderHome() {
    const p = state.player || {};
    $('#playerMeta').textContent = `${p.firstName || ''} ${p.lastName || ''} · Bank ${money(p.bank)} · Cash ${money(p.cash)}`;
    const owned = (state.licenses || []).filter((l) => l.status === 'valid').length;
    const attempts = state.stats ? (state.stats.theory_attempts || 0) + (state.stats.practical_attempts || 0) : state.history.length;
    $('#homeStats').innerHTML = `
      <div class="stat"><div class="label">Valid licenses</div><div class="value">${owned}</div></div>
      <div class="stat"><div class="label">Exams on record</div><div class="value">${attempts}</div></div>
      <div class="stat"><div class="label">Categories offered</div><div class="value">${state.categories.length}</div></div>
    `;
  }

  function renderCatalog() {
    const grid = $('#catalogGrid');
    grid.innerHTML = state.categories.map((c) => `
      <article class="cat-card" data-cat="${c.id}" style="border-left-color:${c.color || '#1e5aab'}">
        <h3>${c.label}</h3>
        <p>${c.description || ''}</p>
        <div class="cat-meta">
          <span>Theory ${money(c.theoryPrice)} · Road ${money(c.practicalPrice)}</span>
          ${c.hasLicense ? '<span class="badge ok">Owned</span>' : (c.hasTheory ? '<span class="badge warn">Theory OK</span>' : '<span class="badge neutral">Open</span>')}
        </div>
      </article>
    `).join('');
    $all('.cat-card', grid).forEach((el) => {
      el.addEventListener('click', () => openEnroll(el.dataset.cat));
    });
  }

  function openEnroll(categoryId) {
    const c = state.categories.find((x) => x.id === categoryId);
    if (!c) return;
    state.selectedCategory = c;
    const now = Math.floor(Date.now() / 1000);
    const theoryWait = (c.theoryRetakeAt || 0) > now;
    const pracWait = (c.practicalRetakeAt || 0) > now;
    $('#enrollPanel').innerHTML = `
      <div class="enroll-box">
        <h2>${c.label}</h2>
        <p class="muted">${c.description || ''}</p>
        <div class="price-row">
          <div class="price-pill"><span>Theory exam</span><strong>${money(c.theoryPrice)}</strong></div>
          <div class="price-pill"><span>Practical exam</span><strong>${money(c.practicalPrice)}</strong></div>
          <div class="price-pill"><span>License points</span><strong>${c.maxPoints || 12}/${c.maxPoints || 12}</strong></div>
        </div>
        <p class="muted">
          ${c.hasLicense ? 'You already hold this license.' : ''}
          ${!c.hasLicense && state.requireTheory && !c.hasTheory ? 'Theory must be passed before the road test.' : ''}
          ${theoryWait ? 'Theory retake cooldown active.' : ''}
          ${pracWait ? 'Practical retake cooldown active.' : ''}
        </p>
        <div class="enroll-actions">
          <button class="btn primary" id="btnTheory" ${c.hasLicense || theoryWait ? 'disabled' : ''}>Start Theory</button>
          <button class="btn primary" id="btnPractical" ${c.hasLicense || pracWait || (state.requireTheory && !c.hasTheory) ? 'disabled' : ''}>Start Practical</button>
          <button class="btn ghost" data-view="catalog">Cancel</button>
        </div>
      </div>
    `;
    showView('enroll');
    $('#btnTheory')?.addEventListener('click', async () => {
      const res = await post('startTheory', { schoolId: state.school?.id, category: c.id });
      if (!res.ok) return alert(res.error || 'Unable to start theory');
      startTheoryUI(res.exam);
    });
    $('#btnPractical')?.addEventListener('click', async () => {
      const res = await post('startPractical', { schoolId: state.school?.id, category: c.id });
      if (!res.ok) alert(res.error || 'Unable to start practical');
    });
    $all('[data-view="catalog"]', $('#enrollPanel')).forEach((b) => b.addEventListener('click', () => showView('catalog')));
  }

  function clearTheoryTimer() {
    if (state.theoryTimer) {
      clearInterval(state.theoryTimer);
      state.theoryTimer = null;
    }
  }

  function startTheoryUI(exam) {
    clearTheoryTimer();
    state.theory = exam;
    state.theoryIndex = 0;
    state.theoryAnswers = {};
    state.theoryEndsAt = Date.now() + (exam.timeSeconds || 600) * 1000;
    $('#theoryTitle').textContent = `${exam.label} — Theory`;
    showView('theory');
    renderQuestion();
    state.theoryTimer = setInterval(() => {
      const rem = Math.max(0, Math.floor((state.theoryEndsAt - Date.now()) / 1000));
      const m = String(Math.floor(rem / 60)).padStart(2, '0');
      const s = String(rem % 60).padStart(2, '0');
      $('#theoryTimer').textContent = `${m}:${s}`;
      if (rem <= 0) {
        clearTheoryTimer();
        submitTheory();
      }
    }, 250);
  }

  function renderQuestion() {
    const exam = state.theory;
    if (!exam) return;
    const q = exam.questions[state.theoryIndex];
    const total = exam.questions.length;
    $('#theoryProgress').textContent = `Question ${state.theoryIndex + 1} / ${total}`;
    $('#theoryBar').style.width = `${((state.theoryIndex + 1) / total) * 100}%`;
    const selected = state.theoryAnswers[q.id];
    const sign = q.image
      ? `<div class="sign-preview" title="${q.image}">${(q.image || '').replace('sign_', '').slice(0, 6).toUpperCase()}</div>`
      : '';
    $('#questionCard').innerHTML = `
      ${sign}
      <h3>${q.question}</h3>
      <div class="answers">
        ${q.answers.map((a, i) => `
          <button class="answer ${selected === i ? 'selected' : ''}" data-i="${i}">${String.fromCharCode(65 + i)}. ${a}</button>
        `).join('')}
      </div>
    `;
    $all('.answer', $('#questionCard')).forEach((btn) => {
      btn.addEventListener('click', () => {
        state.theoryAnswers[q.id] = Number(btn.dataset.i);
        renderQuestion();
      });
    });
    $('#theoryPrev').disabled = state.theoryIndex <= 0;
    $('#theoryNext').textContent = state.theoryIndex >= total - 1 ? 'Submit' : 'Next';
  }

  async function submitTheory() {
    clearTheoryTimer();
    const res = await post('submitTheory', { answers: state.theoryAnswers });
    if (!res.ok) {
      alert(res.error || 'Submit failed');
      return;
    }
    renderTheoryResult(res.result);
    showView('theoryResult');
    // refresh school data in background
    const refreshed = await post('refreshSchool', { schoolId: state.school?.id });
    if (refreshed.ok) applyDashboard(refreshed.data);
  }

  function renderTheoryResult(result) {
    const pass = result && result.passed;
    $('#theoryResultPanel').innerHTML = `
      <div class="result-box ${pass ? 'pass' : 'fail'}">
        <h2>${pass ? 'Theory Passed' : 'Theory Failed'}</h2>
        <div class="score">${result.score}%</div>
        <p class="muted">${result.correct}/${result.total} correct · Required ${result.passPercent}%</p>
        <div class="review-list">
          ${(result.review || []).map((r, i) => `
            <div class="review-item">${i + 1}. ${r.correct ? '✓ Correct' : `✗ Incorrect (answer ${String.fromCharCode(65 + (r.expected || 0))})`}</div>
          `).join('')}
        </div>
        <div class="enroll-actions" style="justify-content:center;margin-top:18px">
          <button class="btn primary" data-view="catalog">Back to Licenses</button>
          ${pass ? '<button class="btn success" id="goPractical">Continue to Practical</button>' : ''}
        </div>
      </div>
    `;
    $all('[data-view]', $('#theoryResultPanel')).forEach((b) => b.addEventListener('click', () => showView(b.dataset.view)));
    $('#goPractical')?.addEventListener('click', async () => {
      await post('startPractical', { schoolId: state.school?.id, category: result.category });
    });
  }

  function renderPracticalResult(result) {
    const pass = result && result.passed;
    $('#practicalResultPanel').innerHTML = `
      <div class="result-box ${pass ? 'pass' : 'fail'}">
        <h2>${pass ? 'Road Test Passed' : 'Road Test Failed'}</h2>
        <div class="score">${result.score}</div>
        <p class="muted">Pass score ${result.passScore} · Checkpoints ${result.checkpointsHit}/${result.checkpointTotal} · Errors ${result.errorCount}</p>
        <div class="review-list">
          ${(result.errors || []).map((e) => `
            <div class="review-item">${e.type}${e.amount ? ` (−${e.amount})` : ''}</div>
          `).join('') || '<div class="review-item">No infractions recorded.</div>'}
        </div>
        ${pass && result.documentId ? `<p class="muted">Document ID: ${result.documentId}</p>` : ''}
        <div class="enroll-actions" style="justify-content:center;margin-top:18px">
          <button class="btn primary" data-view="licenseCard">View License Card</button>
          <button class="btn ghost" data-view="home">Home</button>
        </div>
      </div>
    `;
    $all('[data-view]', $('#practicalResultPanel')).forEach((b) => b.addEventListener('click', () => showView(b.dataset.view)));
  }

  function renderLicenseCard() {
    const p = state.player || {};
    const cards = state.licenses || [];
    const owned = cards.filter((c) => c.status && c.status !== 'none');
    const primary = owned.find((c) => c.status === 'valid') || owned[0] || cards[0];
    $('#licenseCardPanel').innerHTML = `
      <div class="dl-card">
        <div class="dl-header">
          <strong>CALIFORNIA DRIVER LICENSE</strong>
          <span>${primary ? statusBadge(primary.status) : ''}</span>
        </div>
        <div class="dl-body">
          <div class="photo">${(p.firstName || 'A').charAt(0)}${(p.lastName || 'B').charAt(0)}</div>
          <div class="dl-fields">
            <div class="name">${p.firstName || primary?.firstName || ''} ${p.lastName || primary?.lastName || ''}</div>
            <div>DOC: ${primary?.documentId || '—'}</div>
            <div>Issued: ${primary?.issuedAt ? String(primary.issuedAt).slice(0, 10) : '—'}</div>
            <div>Class focus: ${primary?.short || '—'}</div>
          </div>
        </div>
      </div>
      <h3 style="color:var(--navy);margin:8px 0">Points by category</h3>
      <div class="points-list">
        ${cards.map((c) => `
          <div class="points-row">
            <div class="left">
              <div class="icon-bubble" style="background:${c.color || '#0b2a4a'}">${iconFor(c.icon)}</div>
              <div>
                <strong>${c.label}</strong>
                <div class="muted" style="margin:0">${statusBadge(c.status)}</div>
              </div>
            </div>
            <div><strong>${c.status === 'none' ? '—' : `${c.points}/${c.maxPoints}`}</strong> pts</div>
          </div>
        `).join('')}
      </div>
    `;
  }

  function renderHistory() {
    const exams = state.history || [];
    const points = state.pointsHistory || [];
    $('#historyExams').innerHTML = exams.length ? `
      <table>
        <thead><tr><th>Date</th><th>Type</th><th>Category</th><th>Score</th><th>Result</th></tr></thead>
        <tbody>
          ${exams.map((e) => `
            <tr>
              <td>${String(e.created_at || '').slice(0, 19)}</td>
              <td>${e.exam_type}</td>
              <td>${e.category}</td>
              <td>${e.score}</td>
              <td>${Number(e.passed) === 1 ? '<span class="badge ok">Pass</span>' : '<span class="badge bad">Fail</span>'}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    ` : '<p class="muted">No exam history yet.</p>';

    $('#historyPoints').innerHTML = points.length ? `
      <table>
        <thead><tr><th>Date</th><th>Category</th><th>Action</th><th>Delta</th><th>Balance</th><th>Reason</th><th>By</th></tr></thead>
        <tbody>
          ${points.map((p) => `
            <tr>
              <td>${String(p.created_at || '').slice(0, 19)}</td>
              <td>${p.category}</td>
              <td>${p.action}</td>
              <td>${p.points_delta > 0 ? '+' : ''}${p.points_delta}</td>
              <td>${p.points_before} → ${p.points_after}</td>
              <td>${p.reason || ''}</td>
              <td>${p.actor_name || p.actor_citizenid || ''}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    ` : '<p class="muted">No points history yet.</p>';
  }

  async function loadAdmin() {
    const res = await post('adminDashboard');
    if (!res.ok) {
      $('#adminPanel').innerHTML = `<p class="muted">${res.error || 'No permission'}</p>`;
      return;
    }
    state.admin = res;
    renderAdmin(res);
  }

  function renderAdmin(data) {
    const stats = data.stats || {};
    const active = data.active || [];
    const cats = data.categories || state.categories || [];
    $('#adminPanel').innerHTML = `
      <div class="admin-grid">
        <div class="stat"><div class="label">Total exams</div><div class="value">${stats.totalExams || 0}</div></div>
        <div class="stat"><div class="label">Theory passes</div><div class="value">${stats.theoryPasses || 0}</div></div>
        <div class="stat"><div class="label">Practical passes</div><div class="value">${stats.practicalPasses || 0}</div></div>
        <div class="stat"><div class="label">Active exams</div><div class="value">${stats.activeExams || 0}</div></div>
      </div>

      <div class="admin-section">
        <h3>Active exams</h3>
        ${active.length ? `
          <table>
            <thead><tr><th>Player</th><th>Type</th><th>Category</th><th>Score</th><th></th></tr></thead>
            <tbody>
              ${active.map((a) => `
                <tr>
                  <td>${a.name} (${a.source})</td>
                  <td>${a.type}</td>
                  <td>${a.category}</td>
                  <td>${a.score ?? '—'}</td>
                  <td>${data.canCancel ? `<button class="btn danger btn-sm" data-cancel="${a.source}">Cancel</button>` : ''}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        ` : '<p class="muted">No exams in progress.</p>'}
      </div>

      <div class="admin-section">
        <h3>Lookup / points</h3>
        <div class="form-row">
          <input id="admTarget" type="number" placeholder="Server ID" />
          <button class="btn primary" id="admLookup">Lookup</button>
        </div>
        <div id="admLookupResult"></div>
        ${data.canManagePoints ? `
          <div class="form-row" style="margin-top:10px">
            <input id="admPtsTarget" type="number" placeholder="Server ID" />
            <select id="admPtsCat">${cats.map((c) => `<option value="${c.id}">${c.label}</option>`).join('')}</select>
            <input id="admPtsAmount" type="number" placeholder="Points" min="1" />
            <input id="admPtsReason" type="text" placeholder="Reason (required)" />
            <button class="btn danger" id="admRemovePts">Remove points</button>
            ${data.canRestore ? '<button class="btn success" id="admRestorePts">Restore points</button>' : ''}
          </div>
          <div class="form-row">
            <select id="admInfraction">
              <option value="">Or apply configured infraction…</option>
              ${Object.entries(data.infractions || {}).map(([k, v]) => `<option value="${k}">${v.label} (−${v.points})</option>`).join('')
                || Object.entries(window.__infractions || {}).map(([k, v]) => `<option value="${k}">${v.label} (−${v.points})</option>`).join('')}
            </select>
            <button class="btn danger" id="admApplyInf">Apply infraction</button>
          </div>
        ` : ''}
        ${data.canRevoke ? `
          <div class="form-row">
            <input id="admRevTarget" type="number" placeholder="Server ID" />
            <select id="admRevCat">${cats.map((c) => `<option value="${c.id}">${c.label}</option>`).join('')}</select>
            <input id="admRevReason" type="text" placeholder="Revoke reason" />
            <button class="btn danger" id="admRevoke">Revoke license</button>
          </div>
        ` : ''}
      </div>

      ${data.canEditPrices ? `
        <div class="admin-section">
          <h3>Session price override</h3>
          <div class="form-row">
            <select id="admPriceCat">${cats.map((c) => `<option value="${c.id}">${c.label}</option>`).join('')}</select>
            <input id="admTheoryPrice" type="number" placeholder="Theory $" />
            <input id="admPracticalPrice" type="number" placeholder="Practical $" />
            <button class="btn primary" id="admSetPrice">Apply</button>
          </div>
          <p class="muted">Permanent changes belong in config.lua. Overrides last until resource restart.</p>
        </div>
      ` : ''}

      <div class="admin-section">
        <h3>Recent exams</h3>
        <table>
          <thead><tr><th>Citizen</th><th>Type</th><th>Cat</th><th>Score</th><th>Pass</th></tr></thead>
          <tbody>
            ${(data.recent || []).slice(0, 15).map((e) => `
              <tr>
                <td>${e.citizenid}</td><td>${e.exam_type}</td><td>${e.category}</td>
                <td>${e.score}</td><td>${Number(e.passed) === 1 ? 'Yes' : 'No'}</td>
              </tr>
            `).join('') || '<tr><td colspan="5">None</td></tr>'}
          </tbody>
        </table>
      </div>
    `;

    $all('[data-cancel]').forEach((btn) => {
      btn.addEventListener('click', async () => {
        await post('adminCancelExam', { target: Number(btn.dataset.cancel) });
        loadAdmin();
      });
    });
    $('#admLookup')?.addEventListener('click', async () => {
      const target = Number($('#admTarget').value);
      const res = await post('adminLookup', { target });
      if (!res.ok) {
        $('#admLookupResult').innerHTML = `<p class="muted">${res.error}</p>`;
        return;
      }
      $('#admLookupResult').innerHTML = `
        <p><strong>${res.name}</strong> · ${res.citizenid}</p>
        <div class="points-list">
          ${(res.licenses || []).map((l) => `
            <div class="points-row"><span>${l.label}</span><span>${l.status} · ${l.points}/${l.maxPoints}</span></div>
          `).join('')}
        </div>
      `;
    });
    $('#admRemovePts')?.addEventListener('click', async () => {
      const res = await post('adminRemovePoints', {
        target: Number($('#admPtsTarget').value),
        category: $('#admPtsCat').value,
        amount: Number($('#admPtsAmount').value),
        reason: $('#admPtsReason').value,
      });
      alert(res.ok ? 'Points updated' : (res.error || 'Failed'));
    });
    $('#admRestorePts')?.addEventListener('click', async () => {
      const res = await post('adminRestorePoints', {
        target: Number($('#admPtsTarget').value),
        category: $('#admPtsCat').value,
        amount: Number($('#admPtsAmount').value),
        reason: $('#admPtsReason').value,
      });
      alert(res.ok ? 'Points restored' : (res.error || 'Failed'));
    });
    $('#admApplyInf')?.addEventListener('click', async () => {
      const res = await post('adminRemovePoints', {
        target: Number($('#admPtsTarget').value),
        category: $('#admPtsCat').value,
        infraction: $('#admInfraction').value,
        reason: $('#admPtsReason').value || 'Configured infraction',
      });
      alert(res.ok ? 'Infraction applied' : (res.error || 'Failed'));
    });
    $('#admRevoke')?.addEventListener('click', async () => {
      const res = await post('adminRevoke', {
        target: Number($('#admRevTarget').value),
        category: $('#admRevCat').value,
        reason: $('#admRevReason').value,
      });
      alert(res.ok ? 'License revoked' : (res.error || 'Failed'));
    });
    $('#admSetPrice')?.addEventListener('click', async () => {
      const res = await post('adminSetPrice', {
        category: $('#admPriceCat').value,
        theoryPrice: Number($('#admTheoryPrice').value),
        practicalPrice: Number($('#admPracticalPrice').value),
      });
      alert(res.ok ? `Prices set (theory ${res.theoryPrice}, practical ${res.practicalPrice})` : (res.error || 'Failed'));
    });
  }

  function updatePracticalHud(data) {
    if (!data) return;
    if (data.active === false) {
      practicalHud.classList.add('hidden');
      return;
    }
    if (data.active) practicalHud.classList.remove('hidden');
    if (!practicalHud.classList.contains('hidden')) {
      if (data.label) $('#phTitle').textContent = data.label;
      if (data.score != null) $('#phScore').textContent = data.score;
      if (data.checkpoint != null && data.total != null) $('#phCp').textContent = `${data.checkpoint}/${data.total}`;
      if (data.remaining != null) {
        const m = String(Math.floor(data.remaining / 60)).padStart(2, '0');
        const s = String(data.remaining % 60).padStart(2, '0');
        $('#phTime').textContent = `${m}:${s}`;
      }
      if (data.speedLimit) $('#phLimit').textContent = `${data.speedLimit} mph`;
      if (data.lastInfraction) {
        $('#phAlert').textContent = `${data.lastInfraction}${data.deduction ? ` (−${data.deduction})` : ''}`;
        setTimeout(() => { $('#phAlert').textContent = ''; }, 2500);
      }
    }
  }

  // Events
  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') openUI(msg.view, msg.data);
    if (msg.action === 'close') {
      app.classList.add('hidden');
      clearTheoryTimer();
    }
    if (msg.action === 'practicalHud') {
      if (msg.data && msg.data.active) updatePracticalHud(msg.data);
      else updatePracticalHud(msg.data || msg);
    }
    if (msg.action === 'practicalEnd') practicalHud.classList.add('hidden');
    if (msg.action === 'theoryForceClose') {
      clearTheoryTimer();
      showView('home');
    }
    if (msg.action === 'previewEnroll' && msg.category) {
      openEnroll(msg.category);
    }
  });

  if (isPreview) {
    window.parent.postMessage({ action: 'previewReady' }, '*');
  }

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !app.classList.contains('hidden')) {
      if (!$('#view-theory').classList.contains('hidden')) return; // force quit button during exam
      closeUI();
    }
  });

  $('#btnClose').addEventListener('click', () => {
    if (!$('#view-theory').classList.contains('hidden')) return;
    closeUI();
  });
  $('#btnRefresh').addEventListener('click', async () => {
    const res = await post('refreshSchool', { schoolId: state.school?.id });
    if (res.ok) {
      applyDashboard(res.data);
      showView($('.nav-btn.active')?.dataset.view || 'home');
    }
  });

  $all('.nav-btn').forEach((btn) => {
    btn.addEventListener('click', () => showView(btn.dataset.view));
  });
  $all('[data-view]').forEach((btn) => {
    if (btn.classList.contains('nav-btn')) return;
    btn.addEventListener('click', () => showView(btn.dataset.view));
  });

  $('#theoryPrev').addEventListener('click', () => {
    if (state.theoryIndex > 0) {
      state.theoryIndex -= 1;
      renderQuestion();
    }
  });
  $('#theoryNext').addEventListener('click', () => {
    if (!state.theory) return;
    if (state.theoryIndex >= state.theory.questions.length - 1) submitTheory();
    else {
      state.theoryIndex += 1;
      renderQuestion();
    }
  });
  $('#theoryQuit').addEventListener('click', async () => {
    clearTheoryTimer();
    await post('cancelTheory');
    showView('home');
  });

  $all('.tab').forEach((tab) => {
    tab.addEventListener('click', () => {
      $all('.tab').forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      const exams = tab.dataset.tab === 'exams';
      $('#historyExams').classList.toggle('hidden', !exams);
      $('#historyPoints').classList.toggle('hidden', exams);
    });
  });
})();
