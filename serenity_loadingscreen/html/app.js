(() => {
  const cfg = window.SERENITY_LOADING || {};
  const tipEl = document.getElementById('tip');
  const taglineEl = document.getElementById('tagline');
  const labelEl = document.getElementById('loadLabel');
  const pctEl = document.getElementById('loadPct');
  const barFill = document.getElementById('barFill');
  const barTrack = document.querySelector('.bar-track');
  const canvas = document.getElementById('particles');
  const ctx = canvas.getContext('2d');

  if (taglineEl && cfg.tagline) {
    taglineEl.textContent = cfg.tagline;
  }

  const stages = [
    { min: 0, label: 'Connexion au serveur…' },
    { min: 12, label: 'Établissement de la connexion…' },
    { min: 35, label: 'Chargement des ressources…' },
    { min: 60, label: 'Initialisation de la session…' },
    { min: 85, label: 'Presque prêt…' },
  ];

  let progress = 0;
  let gotNativeProgress = false;
  let tipIndex = 0;
  const tips = Array.isArray(cfg.tips) && cfg.tips.length ? cfg.tips : ['Bienvenue sur Serenity V RP'];

  function setProgress(value, fromNative) {
    if (fromNative) gotNativeProgress = true;

    progress = Math.max(0, Math.min(100, value));
    const pct = Math.floor(progress);

    barFill.style.width = pct + '%';
    pctEl.textContent = pct + '%';
    barTrack.setAttribute('aria-valuenow', String(pct));

    if (pct > 0) {
      barTrack.classList.remove('is-loading');
    }

    for (let i = stages.length - 1; i >= 0; i--) {
      if (progress >= stages[i].min) {
        labelEl.textContent = stages[i].label;
        break;
      }
    }
  }

  function extractFraction(data) {
    if (!data) return null;
    if (typeof data.loadFraction === 'number') return data.loadFraction;
    if (typeof data.progress === 'number') return data.progress;
    if (typeof data.count === 'number' && typeof data.total === 'number' && data.total > 0) {
      return data.count / data.total;
    }
    return null;
  }

  function handleProgress(data) {
    const fraction = extractFraction(data);
    if (fraction === null) return;
    setProgress(fraction * 100, true);
  }

  const handlers = {
    loadProgress: handleProgress,
    onLogLine(data) {
      if (data && data.message) {
        labelEl.textContent = String(data.message).slice(0, 80);
      }
    },
    startInitFunctionOrder: handleProgress,
    initFunctionInvoking: handleProgress,
    initFunctionInvoked: handleProgress,
    endInitFunction: handleProgress,
    startDataFileEntries: handleProgress,
    performMapLoadFunction: handleProgress,
    onDataFileEntry: handleProgress,
  };

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (typeof data.loadFraction === 'number') {
      handleProgress(data);
      return;
    }

    const fn = handlers[data.eventName] || handlers[data.type];
    if (fn) fn(data);
  });

  // Pulse orange visible tant que la barre est à 0
  barTrack.classList.add('is-loading');

  // Fallback : avance la barre si FiveM n'envoie pas loadProgress tout de suite
  const fallback = setInterval(() => {
    if (gotNativeProgress) {
      clearInterval(fallback);
      return;
    }
    if (progress >= 96) {
      clearInterval(fallback);
      return;
    }
    setProgress(progress + 1.8);
  }, 220);

  function showTip(index) {
    tipEl.classList.add('is-fading');
    setTimeout(() => {
      tipEl.textContent = tips[index % tips.length];
      tipEl.classList.remove('is-fading');
    }, 280);
  }

  showTip(0);
  setInterval(() => {
    tipIndex = (tipIndex + 1) % tips.length;
    showTip(tipIndex);
  }, cfg.tipInterval || 6500);

  // Particles
  const particles = [];
  const COUNT = 28;

  function resize() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }

  function spawn() {
    particles.length = 0;
    for (let i = 0; i < COUNT; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        r: Math.random() * 1.8 + 0.4,
        vx: (Math.random() - 0.5) * 0.25,
        vy: -0.15 - Math.random() * 0.35,
        a: Math.random() * 0.45 + 0.15,
        gold: Math.random() > 0.72,
      });
    }
  }

  function tick() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (const p of particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.y < -10) {
        p.y = canvas.height + 10;
        p.x = Math.random() * canvas.width;
      }
      if (p.x < -10) p.x = canvas.width + 10;
      if (p.x > canvas.width + 10) p.x = -10;

      ctx.beginPath();
      ctx.fillStyle = p.gold
        ? `rgba(245, 197, 66, ${p.a})`
        : `rgba(255, 140, 40, ${p.a})`;
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fill();
    }
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', () => {
    resize();
    spawn();
  });

  resize();
  spawn();
  tick();
})();
