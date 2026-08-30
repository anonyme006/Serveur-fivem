(() => {
  const cfg = window.SERENITY_LOADING || {};
  const tipEl = document.getElementById('tip');
  const taglineEl = document.getElementById('tagline');
  const labelEl = document.getElementById('loadLabel');
  const pctEl = document.getElementById('loadPct');
  const barFill = document.getElementById('barFill');
  const bar = document.querySelector('.bar');
  const canvas = document.getElementById('particles');
  const ctx = canvas.getContext('2d');

  if (taglineEl && cfg.tagline) {
    taglineEl.textContent = cfg.tagline;
  }

  const stages = [
    { min: 0, label: 'Connexion au serveur…' },
    { min: 15, label: 'Chargement des assets…' },
    { min: 40, label: 'Initialisation de la session…' },
    { min: 70, label: 'Préparation de Los Santos…' },
    { min: 90, label: 'Presque prêt…' },
  ];

  let progress = 0;
  let tipIndex = 0;
  const tips = Array.isArray(cfg.tips) && cfg.tips.length ? cfg.tips : ['Bienvenue sur Serenity V RP'];

  function setProgress(value) {
    progress = Math.max(0, Math.min(100, value));
    barFill.style.width = progress + '%';
    pctEl.textContent = Math.floor(progress) + '%';
    bar.setAttribute('aria-valuenow', String(Math.floor(progress)));

    for (let i = stages.length - 1; i >= 0; i--) {
      if (progress >= stages[i].min) {
        labelEl.textContent = stages[i].label;
        break;
      }
    }
  }

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

  // FiveM load progress events
  const handlers = {
    loadProgress(data) {
      const loadFraction = data && typeof data.loadFraction === 'number'
        ? data.loadFraction
        : 0;
      setProgress(loadFraction * 100);
    },
    onLogLine() {},
  };

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;
    const fn = handlers[data.eventName];
    if (fn) fn(data);
  });

  // Fallback preview hors FiveM
  if (!window.invokeNative) {
    let fake = 0;
    const id = setInterval(() => {
      fake += Math.random() * 4 + 1.2;
      if (fake >= 100) {
        fake = 100;
        clearInterval(id);
      }
      setProgress(fake);
    }, 180);
  }

  // Particles — billets / poussière lumineuse
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
        : `rgba(90, 210, 255, ${p.a})`;
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
