/**
 * NUI Discord Gate
 * L'invite Discord vient UNIQUEMENT de la config Lua (via messages / callbacks).
 * Jamais de lien hardcodé ici.
 */

const app = document.getElementById('app');
const screens = {
  verify: document.getElementById('screen-verify'),
  success: document.getElementById('screen-success'),
  denied_role: document.getElementById('screen-denied_role'),
  denied_link: document.getElementById('screen-denied_link'),
  denied_member: document.getElementById('screen-denied_member'),
  characters: document.getElementById('screen-characters'),
};

/** @type {string} */
let discordInvite = '';
let citizenRoleName = 'Citoyen';

function resourceName() {
  try {
    return GetParentResourceName();
  } catch (_) {
    return 'rr_discord_gate';
  }
}

function nui(name, data = {}) {
  return fetch(`https://${resourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  })
    .then((r) => r.json())
    .catch(() => ({}));
}

/**
 * Ouvre une URL externe depuis la NUI FiveM.
 * Utilise invokeNative('openUrl') — le joueur n'a pas besoin de quitter FiveM.
 */
function openExternalUrl(url) {
  if (!url || typeof url !== 'string') return false;

  // Méthode FiveM CEF officielle
  try {
    if (typeof window.invokeNative === 'function') {
      window.invokeNative('openUrl', url);
      return true;
    }
  } catch (_) {
    /* fallthrough */
  }

  // Fallback navigateur / preview hors jeu
  try {
    window.open(url, '_blank', 'noopener,noreferrer');
    return true;
  } catch (_) {
    return false;
  }
}

async function openDiscord() {
  // Ouvre d'abord avec l'invite déjà poussée depuis Config.Discord.Invite
  // (évite d'attendre un fetch NUI qui peut échouer / timeout hors CEF FiveM).
  const cached = discordInvite;
  if (cached) {
    openExternalUrl(cached);
  }

  // Rafraîchit depuis la config Lua (source unique de vérité)
  let res = {};
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 1500);
    res = await fetch(`https://${resourceName()}/openDiscord`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({}),
      signal: ctrl.signal,
    }).then((r) => r.json()).catch(() => ({}));
    clearTimeout(t);
  } catch (_) {
    res = {};
  }

  if (res && res.invite) {
    discordInvite = res.invite;
    // Si on n'avait pas encore d'invite en cache, ouvrir maintenant
    if (!cached) {
      openExternalUrl(discordInvite);
    }
  } else if (!cached) {
    console.warn('[rr_discord_gate] Invite Discord manquante — vérifier Config.Discord.Invite');
  }
}

function hideAllScreens() {
  Object.values(screens).forEach((el) => {
    if (el) el.classList.add('hidden');
  });
}

function setRoleLabels(name) {
  citizenRoleName = name || 'Citoyen';
  document.querySelectorAll('.role-name').forEach((el) => {
    el.textContent = `«\u00a0${citizenRoleName}\u00a0»`;
  });
}

function showScreen(name, data = {}) {
  app.classList.remove('hidden');
  hideAllScreens();
  const el = screens[name];
  if (!el) return;
  el.classList.remove('hidden');

  if (data.invite) {
    discordInvite = data.invite;
  }
  if (data.citizenRoleName) {
    setRoleLabels(data.citizenRoleName);
  }

  if (name === 'success') {
    renderSuccess(data.checks || data.data?.checks);
  }

  if (name === 'characters') {
    const payload = data.data || data;
    renderCharacters(payload);
  }
}

function renderSuccess(checks) {
  const list = document.getElementById('success-checks');
  list.innerHTML = '';
  const items = checks || [
    { label: 'Discord vérifié', ok: true },
    { label: `Rôle ${citizenRoleName} détecté`, ok: true },
  ];
  items.forEach((item) => {
    const li = document.createElement('li');
    li.innerHTML = `<span class="check-mark">✓</span><span>${item.label}</span>`;
    list.appendChild(li);
  });
}

function renderCharacters(payload = {}) {
  const loading = document.getElementById('chars-loading');
  const list = document.getElementById('chars-list');
  const createBtn = document.getElementById('btn-create');

  if (payload.invite) discordInvite = payload.invite;

  if (payload.loading) {
    loading.classList.remove('hidden');
    list.innerHTML = '';
    createBtn.classList.add('hidden');
    return;
  }

  loading.classList.add('hidden');
  createBtn.classList.remove('hidden');
  list.innerHTML = '';

  const chars = payload.characters || [];
  const max = payload.maxCharacters || 4;

  if (!chars.length) {
    const empty = document.createElement('div');
    empty.className = 'char-empty';
    empty.textContent = 'Aucun personnage — crée ton premier personnage.';
    list.appendChild(empty);
  } else {
    chars.forEach((char, i) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'char-slot';
      btn.style.animationDelay = `${i * 0.06}s`;
      const name = `${char.firstname || ''} ${char.lastname || ''}`.trim() || 'Personnage';
      const meta = [char.job, char.cid != null ? `Slot ${char.cid}` : null]
        .filter(Boolean)
        .join(' · ');
      btn.innerHTML = `<strong>${name}</strong><span>${meta}</span>`;
      btn.addEventListener('click', () => nui('selectCharacter', { id: char.id }));
      list.appendChild(btn);
    });
  }

  createBtn.disabled = chars.length >= max;
  createBtn.style.opacity = createBtn.disabled ? '0.45' : '1';
}

// Boutons Discord (tous les écrans)
document.querySelectorAll('[data-open-discord]').forEach((btn) => {
  btn.addEventListener('click', (e) => {
    e.preventDefault();
    openDiscord();
  });
});

document.querySelectorAll('[data-recheck]').forEach((btn) => {
  btn.addEventListener('click', () => nui('recheck'));
});

document.getElementById('btn-create').addEventListener('click', () => {
  nui('createCharacter');
});

window.addEventListener('message', (event) => {
  const msg = event.data || {};
  if (msg.action === 'show') {
    if (msg.invite) discordInvite = msg.invite;
    if (msg.citizenRoleName) setRoleLabels(msg.citizenRoleName);
    showScreen(msg.screen, msg);
  }
  if (msg.action === 'hide') {
    app.classList.add('hidden');
    hideAllScreens();
  }
});

// Init : récupère l'invite depuis la config Lua
nui('ready').then((res) => {
  if (res && res.invite) discordInvite = res.invite;
  if (res && res.citizenRoleName) setRoleLabels(res.citizenRoleName);
});

// Preview hors FiveM (?preview=denied_role|verify|…)
(function preview() {
  const params = new URLSearchParams(window.location.search);
  const screen = params.get('preview');
  if (!screen) return;
  // Invite factice UNIQUEMENT pour preview navigateur — en jeu, toujours Config.Discord.Invite
  discordInvite = params.get('invite') || 'https://discord.gg/TONINVITE';
  setRoleLabels(params.get('role') || 'Citoyen');
  if (screen === 'success') {
    showScreen('success', {
      checks: [
        { label: 'Discord vérifié', ok: true },
        { label: 'Rôle Citoyen détecté', ok: true },
      ],
    });
  } else if (screen === 'characters') {
    showScreen('characters', {
      data: {
        characters: [
          { id: '1', firstname: 'Alex', lastname: 'Moreau', job: 'Sans emploi', cid: 1 },
          { id: '2', firstname: 'Léa', lastname: 'Martin', job: 'EMS', cid: 2 },
        ],
        maxCharacters: 4,
        invite: discordInvite,
      },
    });
  } else {
    showScreen(screen, { invite: discordInvite });
  }
})();
