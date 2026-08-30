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
  const musicEl = document.getElementById('loadingMusic');
  const audioDock = document.getElementById('audioDock');
  const playBtn = document.getElementById('playBtn');
  const stopBtn = document.getElementById('stopBtn');
  const volumeSlider = document.getElementById('volumeSlider');
  const volumePct = document.getElementById('volumePct');
  const volDownBtn = document.getElementById('volDownBtn');
  const volUpBtn = document.getElementById('volUpBtn');
  const musicCfg = cfg.music || {};

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

  barTrack.classList.add('is-loading');

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

  // Musique de chargement
  let isPlaying = musicCfg.defaultOn !== false;
  const volumeStep = typeof musicCfg.volumeStep === 'number' ? musicCfg.volumeStep : 0.05;

  function clampVolume(value) {
    return Math.max(0, Math.min(1, value));
  }

  function getVolumePercent() {
    if (!musicEl) return 0;
    return Math.round(musicEl.volume * 100);
  }

  function setVolume(value) {
    if (!musicEl) return;

    const clamped = clampVolume(value);
    musicEl.volume = clamped;

    if (volumeSlider) {
      volumeSlider.value = String(getVolumePercent());
      volumeSlider.style.setProperty('--vol', getVolumePercent() + '%');
    }
    if (volumePct) {
      volumePct.textContent = getVolumePercent() + '%';
    }
  }

  function updatePlayState() {
    if (!playBtn || !stopBtn) return;

    const playing = musicEl && !musicEl.paused;
    playBtn.classList.toggle('is-active', playing);
    stopBtn.classList.toggle('is-active', !playing);
    playBtn.setAttribute('aria-pressed', playing ? 'true' : 'false');
    stopBtn.setAttribute('aria-pressed', !playing ? 'true' : 'false');
  }

  function playMusic() {
    if (!musicEl || !musicCfg.enabled) return Promise.resolve();

    isPlaying = true;
    return musicEl.play()
      .then(() => updatePlayState())
      .catch(() => {
        isPlaying = false;
        updatePlayState();
      });
  }

  function stopMusic() {
    if (!musicEl) return;

    musicEl.pause();
    musicEl.currentTime = 0;
    isPlaying = false;
    updatePlayState();
  }

  function adjustVolume(delta) {
    if (!musicEl) return;
    setVolume(musicEl.volume + delta);
  }

  if (musicEl && musicCfg.enabled && musicCfg.file) {
    musicEl.src = musicCfg.file;
    musicEl.loop = musicCfg.loop !== false;
    setVolume(typeof musicCfg.volume === 'number' ? musicCfg.volume : 0.35);
    updatePlayState();

    playBtn?.addEventListener('click', () => playMusic());
    stopBtn?.addEventListener('click', () => stopMusic());

    volumeSlider?.addEventListener('input', () => {
      setVolume(Number(volumeSlider.value) / 100);
    });

    volDownBtn?.addEventListener('click', () => adjustVolume(-volumeStep));
    volUpBtn?.addEventListener('click', () => adjustVolume(volumeStep));

    musicEl.addEventListener('play', updatePlayState);
    musicEl.addEventListener('pause', updatePlayState);

    if (musicCfg.autoplay !== false && isPlaying) {
      const startMusic = () => playMusic();

      if (document.readyState === 'complete') {
        startMusic();
      } else {
        window.addEventListener('load', startMusic, { once: true });
      }

      document.addEventListener('click', (event) => {
        if (audioDock && audioDock.contains(event.target)) return;
        if (isPlaying && musicEl.paused) playMusic();
      }, { once: true });
    }
  } else if (audioDock) {
    audioDock.hidden = true;
  }

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
