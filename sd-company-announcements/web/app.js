(function () {
  "use strict";

  var booted = false;
  var state = {
    view: "list", // list | detail | form
    bootstrap: null,
    announcements: [],
    current: null,
    search: "",
    form: null,
    formDirty: false,
    formMode: "create", // create | edit
    loading: false,
  };

  var TYPE_ICONS = {
    information: "ℹ️",
    meeting: "📅",
    recruitment: "👥",
    event: "🎉",
    urgent: "🚨",
    other: "📌",
  };

  var LABELS = {
    type: {
      information: "Information",
      meeting: "Réunion",
      recruitment: "Recrutement",
      event: "Événement",
      urgent: "Urgent",
      other: "Autre",
    },
    priority: {
      normal: "Normale",
      important: "Importante",
      urgent: "Urgente",
    },
    status: {
      draft: "Brouillon",
      published: "Publiée",
      archived: "Archivée",
    },
  };

  var ERRORS = {
    no_player: "Joueur introuvable.",
    no_job: "Vous n'avez pas de métier.",
    company_disabled: "Votre entreprise n'est pas autorisée.",
    grade_denied: "Grade insuffisant.",
    denied: "Accès refusé.",
    no_permission: "Permission insuffisante.",
    not_found: "Annonce introuvable.",
    title_required: "Le titre est obligatoire.",
    content_required: "Le contenu est obligatoire.",
    invalid_type: "Type invalide.",
    invalid_priority: "Priorité invalide.",
    invalid_status: "Statut invalide.",
    db_error: "Erreur base de données.",
    invalid_payload: "Données invalides.",
  };

  function el(id) {
    return document.getElementById(id);
  }

  function root() {
    return el("root");
  }

  function esc(str) {
    return String(str == null ? "" : str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function isDev() {
    return typeof window.invokeNative === "undefined";
  }

  function mockBootstrap() {
    return {
      ok: true,
      company: "police",
      companyLabel: "LSPD",
      playerName: "Kevin",
      identifier: "char1:dev",
      permissions: { create: true, edit: true, delete: true, publish: true, view: true },
      meta: {
        types: [
          { value: "information", label: "Information" },
          { value: "meeting", label: "Réunion" },
          { value: "recruitment", label: "Recrutement" },
          { value: "event", label: "Événement" },
          { value: "urgent", label: "Urgent" },
          { value: "other", label: "Autre" },
        ],
        priorities: [
          { value: "normal", label: "Normale" },
          { value: "important", label: "Importante" },
          { value: "urgent", label: "Urgente" },
        ],
        statuses: [
          { value: "draft", label: "Brouillon" },
          { value: "published", label: "Publiée" },
          { value: "archived", label: "Archivée" },
        ],
        limits: { TitleMax: 150, ContentMax: 4000 },
      },
    };
  }

  function mockAnnouncements() {
    return [
      {
        id: 1,
        title: "Réunion importante",
        content: "Réunion à 20h au QG. Présence obligatoire pour tous les officiers en service.",
        type: "meeting",
        priority: "urgent",
        status: "published",
        authorName: "Kevin",
        createdAt: "2026-08-22 14:30:00",
        updatedAt: "2026-08-22 15:10:00",
      },
      {
        id: 2,
        title: "Recrutement cadets",
        content: "Ouverture des candidatures pour le grade de cadet. Transmettre le dossier au capitaine.",
        type: "recruitment",
        priority: "important",
        status: "published",
        authorName: "Sophie",
        createdAt: "2026-08-21 09:00:00",
        updatedAt: "2026-08-21 09:00:00",
      },
      {
        id: 3,
        title: "Note interne — brouillon",
        content: "Rappel procédures d'interpellation. À finaliser avant publication.",
        type: "information",
        priority: "normal",
        status: "draft",
        authorName: "Kevin",
        createdAt: "2026-08-20 18:22:00",
        updatedAt: "2026-08-20 18:22:00",
      },
    ];
  }

  function fetchData(event, data) {
    if (typeof window.fetchNui === "function") {
      return Promise.resolve(window.fetchNui(event, data || {}));
    }
    if (typeof window.fetchNuiStrict === "function") {
      return Promise.resolve(window.fetchNuiStrict(event, data || {}));
    }
    return Promise.resolve(mockFetch(event, data || {}));
  }

  function mockFetch(event, data) {
    if (event === "getBootstrap") return mockBootstrap();
    if (event === "getAnnouncements") {
      var list = mockAnnouncements();
      var q = (data.search || "").toLowerCase();
      if (q) {
        list = list.filter(function (a) {
          return (
            a.title.toLowerCase().indexOf(q) !== -1 ||
            a.content.toLowerCase().indexOf(q) !== -1
          );
        });
      }
      return { ok: true, announcements: list, permissions: mockBootstrap().permissions };
    }
    if (event === "getAnnouncement") {
      var found = mockAnnouncements().find(function (a) {
        return a.id === Number(data.id);
      });
      return {
        ok: !!found,
        announcement: found,
        canEdit: true,
        canDelete: true,
        canPublish: true,
        permissions: mockBootstrap().permissions,
      };
    }
    if (event === "createAnnouncement" || event === "updateAnnouncement") {
      return {
        ok: true,
        announcement: Object.assign(
          {
            id: data.id || Date.now(),
            authorName: "Kevin",
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          },
          data
        ),
      };
    }
    if (
      event === "deleteAnnouncement" ||
      event === "publishAnnouncement" ||
      event === "archiveAnnouncement"
    ) {
      return { ok: true, id: data.id };
    }
    return { ok: false };
  }

  function errMsg(code) {
    return ERRORS[code] || "Une erreur est survenue.";
  }

  function toast(msg) {
    var node = el("toast");
    if (!node) {
      node = document.createElement("div");
      node.id = "toast";
      node.className = "toast";
      document.body.appendChild(node);
    }
    node.textContent = msg;
    node.classList.add("show");
    clearTimeout(toast._t);
    toast._t = setTimeout(function () {
      node.classList.remove("show");
    }, 2200);
  }

  function formatDate(value) {
    if (!value) return "—";
    var d = new Date(String(value).replace(" ", "T"));
    if (isNaN(d.getTime())) return String(value);
    var dd = String(d.getDate()).padStart(2, "0");
    var mm = String(d.getMonth() + 1).padStart(2, "0");
    var yyyy = d.getFullYear();
    var hh = String(d.getHours()).padStart(2, "0");
    var mi = String(d.getMinutes()).padStart(2, "0");
    return dd + "/" + mm + "/" + yyyy + " · " + hh + ":" + mi;
  }

  function shortDate(value) {
    if (!value) return "—";
    var d = new Date(String(value).replace(" ", "T"));
    if (isNaN(d.getTime())) return String(value);
    return (
      String(d.getDate()).padStart(2, "0") +
      "/" +
      String(d.getMonth() + 1).padStart(2, "0") +
      "/" +
      d.getFullYear()
    );
  }

  function perms() {
    return (state.bootstrap && state.bootstrap.permissions) || {};
  }

  function labelOf(kind, value) {
    return (LABELS[kind] && LABELS[kind][value]) || value || "—";
  }

  function iconOf(type) {
    return TYPE_ICONS[type] || "📌";
  }

  /* ---------- Theme ---------- */
  function applyTheme(s) {
    if (!s) return;
    var theme = (s.display && s.display.theme) || s.theme;
    if (theme === "light" || theme === "dark") {
      document.body.setAttribute("data-theme", theme);
    }
  }

  function initSettings() {
    if (typeof window.GetSettings === "function") {
      Promise.resolve(window.GetSettings())
        .then(applyTheme)
        .catch(function () {});
    } else if (window.matchMedia) {
      var dark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      document.body.setAttribute("data-theme", dark ? "dark" : "light");
    } else {
      document.body.setAttribute("data-theme", "dark");
    }
    if (typeof window.OnSettingsChange === "function") {
      window.OnSettingsChange(applyTheme);
    }
  }

  /* ---------- Confirm helpers (sd-phone native when available) ---------- */
  function confirmDialog(title, description) {
    return new Promise(function (resolve) {
      if (typeof window.ShowConfirm === "function") {
        Promise.resolve(window.ShowConfirm(description || title)).then(function (ok) {
          resolve(!!ok);
        });
        return;
      }
      if (typeof window.SetPopUp === "function") {
        window.SetPopUp({
          title: title,
          description: description || "",
          buttons: [
            {
              title: "Annuler",
              cb: function () {
                resolve(false);
              },
            },
            {
              title: "Confirmer",
              cb: function () {
                resolve(true);
              },
            },
          ],
        });
        return;
      }
      resolve(window.confirm(description || title));
    });
  }

  /* ---------- Navigation ---------- */
  function goList() {
    state.view = "list";
    state.current = null;
    state.form = null;
    state.formDirty = false;
    render();
  }

  function goDetail(ann) {
    state.view = "detail";
    state.current = ann;
    state.form = null;
    state.formDirty = false;
    render();
    loadDetail(ann.id);
  }

  function emptyForm() {
    return {
      id: null,
      title: "",
      content: "",
      type: "information",
      priority: "normal",
      status: "draft",
    };
  }

  function goCreate() {
    if (!perms().create) {
      toast("Permission insuffisante.");
      return;
    }
    state.view = "form";
    state.formMode = "create";
    state.form = emptyForm();
    state.formDirty = false;
    render();
  }

  function goEdit(ann) {
    state.view = "form";
    state.formMode = "edit";
    state.form = {
      id: ann.id,
      title: ann.title || "",
      content: ann.content || "",
      type: ann.type || "information",
      priority: ann.priority || "normal",
      status: ann.status || "draft",
    };
    state.formDirty = false;
    render();
  }

  async function tryLeaveForm(next) {
    if (!state.formDirty) {
      next();
      return;
    }
    var ok = await confirmDialog(
      "Modifications non sauvegardées",
      "Voulez-vous quitter sans enregistrer ?"
    );
    if (ok) {
      state.formDirty = false;
      next();
    }
  }

  /* ---------- Data ---------- */
  async function loadBootstrap() {
    state.loading = true;
    render();
    var res = await fetchData("getBootstrap");
    state.loading = false;
    if (!res || !res.ok) {
      state.bootstrap = res || { ok: false, error: "denied" };
      render();
      return;
    }
    state.bootstrap = res;
    await loadList();
  }

  async function loadList() {
    state.loading = true;
    render();
    var res = await fetchData("getAnnouncements", { search: state.search });
    state.loading = false;
    if (res && res.ok) {
      state.announcements = res.announcements || [];
      if (res.permissions) state.bootstrap.permissions = res.permissions;
    } else {
      toast(errMsg(res && res.error));
    }
    render();
  }

  async function loadDetail(id) {
    var res = await fetchData("getAnnouncement", { id: id });
    if (res && res.ok && res.announcement) {
      state.current = Object.assign({}, res.announcement, {
        _canEdit: res.canEdit,
        _canDelete: res.canDelete,
        _canPublish: res.canPublish,
      });
      if (state.view === "detail") render();
    }
  }

  async function saveForm(asStatus) {
    if (!state.form) return;
    var payload = {
      id: state.form.id,
      title: state.form.title,
      content: state.form.content,
      type: state.form.type,
      priority: state.form.priority,
      status: asStatus || state.form.status || "draft",
    };

    if (!payload.title.trim()) {
      toast(errMsg("title_required"));
      return;
    }
    if (!payload.content.trim()) {
      toast(errMsg("content_required"));
      return;
    }

    if (asStatus === "published" && !perms().publish) {
      toast(errMsg("no_permission"));
      return;
    }

    var event =
      state.formMode === "edit" ? "updateAnnouncement" : "createAnnouncement";
    var res = await fetchData(event, payload);
    if (!res || !res.ok) {
      toast(errMsg(res && res.error));
      return;
    }

    state.formDirty = false;
    toast(asStatus === "published" ? "Annonce validée" : "Annonce enregistrée");
    await loadList();
    if (res.announcement) {
      goDetail(res.announcement);
    } else {
      goList();
    }
  }

  async function deleteCurrent() {
    if (!state.current) return;
    var ok = await confirmDialog(
      "Supprimer",
      "Voulez-vous vraiment supprimer cette annonce ?"
    );
    if (!ok) return;
    var res = await fetchData("deleteAnnouncement", { id: state.current.id });
    if (!res || !res.ok) {
      toast(errMsg(res && res.error));
      return;
    }
    toast("Annonce supprimée");
    await loadList();
    goList();
  }

  async function publishCurrent() {
    if (!state.current) return;
    var res = await fetchData("publishAnnouncement", { id: state.current.id });
    if (!res || !res.ok) {
      toast(errMsg(res && res.error));
      return;
    }
    toast("Annonce validée");
    if (res.announcement) state.current = res.announcement;
    await loadList();
    render();
  }

  async function archiveCurrent() {
    if (!state.current) return;
    var res = await fetchData("archiveAnnouncement", { id: state.current.id });
    if (!res || !res.ok) {
      toast(errMsg(res && res.error));
      return;
    }
    toast("Annonce archivée");
    if (res.announcement) state.current = res.announcement;
    await loadList();
    render();
  }

  /* ---------- Render ---------- */
  function searchIcon() {
    return (
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">' +
      '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>'
    );
  }

  function renderCard(a, index) {
    return (
      '<article class="ann-card priority-' +
      esc(a.priority) +
      '" data-id="' +
      esc(a.id) +
      '" style="animation-delay:' +
      index * 0.04 +
      's">' +
      '<div class="card-top">' +
      "<h3 class=\"card-title\">" +
      esc(iconOf(a.type) + " " + a.title) +
      "</h3>" +
      '<div class="badges">' +
      '<span class="badge priority-' +
      esc(a.priority) +
      '">' +
      esc(labelOf("priority", a.priority)) +
      "</span>" +
      '<span class="badge status-' +
      esc(a.status) +
      '">' +
      esc(labelOf("status", a.status)) +
      "</span>" +
      "</div></div>" +
      '<p class="card-excerpt">' +
      esc(a.content) +
      "</p>" +
      '<div class="card-meta"><span>' +
      esc(a.authorName || "—") +
      " · " +
      esc(shortDate(a.createdAt)) +
      "</span><span>" +
      esc(labelOf("type", a.type)) +
      "</span></div></article>"
    );
  }

  function renderList() {
    var p = perms();
    var cards = state.announcements.map(renderCard).join("");
    var body;
    if (state.loading && !state.announcements.length) {
      body = '<div class="loading">Chargement…</div>';
    } else if (!state.announcements.length) {
      body =
        '<div class="empty"><span class="emoji">📭</span>Aucune annonce pour le moment.</div>';
    } else {
      body = '<div class="list">' + cards + "</div>";
    }

    return (
      '<div class="app" data-view="list">' +
      '<div class="topbar"><h1>Annonces</h1></div>' +
      '<div class="company-chip">' +
      esc((state.bootstrap && state.bootstrap.companyLabel) || "") +
      "</div>" +
      '<div class="search-wrap"><div class="search">' +
      searchIcon() +
      '<input id="search" type="search" placeholder="Rechercher…" value="' +
      esc(state.search) +
      '" /></div></div>' +
      body +
      (p.create
        ? '<button class="fab" id="fab-create" title="Nouvelle annonce">＋</button>'
        : '<button class="fab hidden" id="fab-create">＋</button>') +
      "</div>"
    );
  }

  function renderDetail() {
    var a = state.current || {};
    var canEdit = a._canEdit || perms().edit;
    var canDelete = a._canDelete || perms().delete;
    var canPublish = a._canPublish || perms().publish;

    return (
      '<div class="app" data-view="detail">' +
      '<div class="topbar">' +
      '<button class="back" id="btn-back">← Retour</button>' +
      "<h1>Détail</h1>" +
      (canEdit
        ? '<button class="action" id="btn-edit">Modifier</button>'
        : "") +
      "</div>" +
      '<div class="panel">' +
      '<div class="detail-hero">' +
      '<div class="badges">' +
      '<span class="badge priority-' +
      esc(a.priority) +
      '">' +
      esc(labelOf("priority", a.priority)) +
      "</span>" +
      '<span class="badge status-' +
      esc(a.status) +
      '">' +
      esc(labelOf("status", a.status)) +
      "</span>" +
      '<span class="badge">' +
      esc(iconOf(a.type) + " " + labelOf("type", a.type)) +
      "</span></div>" +
      "<h2>" +
      esc(a.title || "") +
      "</h2></div>" +
      '<div class="detail-body">' +
      esc(a.content || "") +
      "</div>" +
      '<div class="meta-grid">' +
      '<div class="meta-row"><span class="k">Auteur</span><span class="v">' +
      esc(a.authorName || "—") +
      "</span></div>" +
      '<div class="meta-row"><span class="k">Créée le</span><span class="v">' +
      esc(formatDate(a.createdAt)) +
      "</span></div>" +
      '<div class="meta-row"><span class="k">Modifiée le</span><span class="v">' +
      esc(formatDate(a.updatedAt)) +
      "</span></div></div>" +
      '<div class="btn-row">' +
      (canPublish && a.status !== "published"
        ? '<button class="btn primary" id="btn-publish">Valider</button>'
        : "") +
      (canPublish && a.status !== "archived"
        ? '<button class="btn warn" id="btn-archive">Archiver</button>'
        : "") +
      (canDelete
        ? '<button class="btn danger" id="btn-delete">Supprimer</button>'
        : "") +
      "</div></div></div>"
    );
  }

  function optionList(kind, selected) {
    var meta = (state.bootstrap && state.bootstrap.meta && state.bootstrap.meta[kind]) || [];
    var canPublish = perms().publish;
    var entries;
    if (!meta.length) {
      var fallback =
        LABELS[kind === "types" ? "type" : kind === "priorities" ? "priority" : "status"];
      entries = Object.keys(fallback).map(function (k) {
        return { value: k, label: fallback[k] };
      });
    } else {
      entries = meta;
    }
    return entries
      .filter(function (entry) {
        if (kind !== "statuses") return true;
        if (canPublish) return true;
        return entry.value === "draft" || entry.value === selected;
      })
      .map(function (entry) {
        return (
          '<option value="' +
          esc(entry.value) +
          '"' +
          (entry.value === selected ? " selected" : "") +
          ">" +
          esc(entry.label) +
          "</option>"
        );
      })
      .join("");
  }

  function renderFormPreview(f) {
    var title = (f.title && f.title.trim()) || "Titre de l’annonce";
    var content =
      (f.content && f.content.trim()) || "Le contenu apparaîtra ici…";
    var author =
      (state.bootstrap && state.bootstrap.playerName) || "Vous";
    return (
      '<div class="preview-block">' +
      '<div class="preview-label">Aperçu</div>' +
      '<article class="ann-card priority-' +
      esc(f.priority || "normal") +
      ' preview-card">' +
      '<div class="card-top">' +
      '<h3 class="card-title">' +
      esc(iconOf(f.type) + " " + title) +
      "</h3>" +
      '<div class="badges">' +
      '<span class="badge priority-' +
      esc(f.priority || "normal") +
      '">' +
      esc(labelOf("priority", f.priority || "normal")) +
      "</span>" +
      '<span class="badge status-published">Validée</span>' +
      "</div></div>" +
      '<p class="card-excerpt">' +
      esc(content) +
      "</p>" +
      '<div class="card-meta"><span>' +
      esc(author) +
      " · aperçu</span><span>" +
      esc(labelOf("type", f.type || "information")) +
      "</span></div></article></div>"
    );
  }

  function renderForm() {
    var f = state.form || emptyForm();
    var isEdit = state.formMode === "edit";
    var canPublish = perms().publish;

    return (
      '<div class="app" data-view="form">' +
      '<div class="topbar">' +
      '<button class="back" id="btn-back">← Annuler</button>' +
      "<h1>" +
      (isEdit ? "Modifier" : "Nouvelle annonce") +
      "</h1></div>" +
      '<div class="panel">' +
      '<div class="field"><label>Titre</label>' +
      '<input id="f-title" maxlength="150" value="' +
      esc(f.title) +
      '" placeholder="Titre de l\'annonce" /></div>' +
      '<div class="field"><label>Contenu</label>' +
      '<textarea id="f-content" maxlength="4000" placeholder="Contenu…">' +
      esc(f.content) +
      "</textarea></div>" +
      '<div class="field"><label>Type</label>' +
      '<select id="f-type">' +
      optionList("types", f.type) +
      "</select></div>" +
      '<div class="field"><label>Priorité</label>' +
      '<select id="f-priority">' +
      optionList("priorities", f.priority) +
      "</select></div>" +
      '<div class="field"><label>Statut</label>' +
      '<select id="f-status">' +
      optionList("statuses", f.status) +
      "</select></div>" +
      '<div id="form-preview">' +
      renderFormPreview(f) +
      "</div>" +
      '<div class="form-actions">' +
      '<button class="btn" id="btn-cancel">Annuler</button>' +
      '<button class="btn" id="btn-save">Enregistrer</button>' +
      (canPublish
        ? '<button class="btn primary span-2" id="btn-validate">Valider l’annonce</button>'
        : "") +
      "</div></div></div>"
    );
  }

  function renderDenied() {
    var msg = errMsg(state.bootstrap && state.bootstrap.error);
    return (
      '<div class="app"><div class="topbar"><h1>Annonces</h1></div>' +
      '<div class="denied"><span class="emoji">🔒</span>' +
      esc(msg) +
      "</div></div>"
    );
  }

  function render() {
    var mount = root();
    if (!mount) return;

    if (!state.bootstrap) {
      mount.innerHTML =
        '<div class="app"><div class="loading">Chargement…</div></div>';
      return;
    }

    if (!state.bootstrap.ok) {
      mount.innerHTML = renderDenied();
      return;
    }

    if (state.view === "detail") mount.innerHTML = renderDetail();
    else if (state.view === "form") mount.innerHTML = renderForm();
    else mount.innerHTML = renderList();

    bindEvents();
  }

  function syncFormFromDom() {
    if (!state.form) return;
    var title = el("f-title");
    var content = el("f-content");
    var type = el("f-type");
    var priority = el("f-priority");
    var status = el("f-status");
    if (title) state.form.title = title.value;
    if (content) state.form.content = content.value;
    if (type) state.form.type = type.value;
    if (priority) state.form.priority = priority.value;
    if (status) state.form.status = status.value;
  }

  function markDirty() {
    state.formDirty = true;
    syncFormFromDom();
    refreshFormPreview();
  }

  function refreshFormPreview() {
    var box = el("form-preview");
    if (!box || !state.form) return;
    box.innerHTML = renderFormPreview(state.form);
  }

  function bindEvents() {
    var fab = el("fab-create");
    if (fab) fab.addEventListener("click", goCreate);

    var search = el("search");
    if (search) {
      var timer;
      search.addEventListener("input", function () {
        state.search = search.value;
        clearTimeout(timer);
        timer = setTimeout(function () {
          loadList();
        }, 280);
      });
    }

    document.querySelectorAll(".ann-card:not(.preview-card)").forEach(function (card) {
      card.addEventListener("click", function () {
        var id = Number(card.getAttribute("data-id"));
        var found = state.announcements.find(function (a) {
          return a.id === id;
        });
        if (found) goDetail(found);
      });
    });

    var back = el("btn-back");
    if (back) {
      back.addEventListener("click", function () {
        if (state.view === "form") {
          tryLeaveForm(goList);
        } else {
          goList();
        }
      });
    }

    var edit = el("btn-edit");
    if (edit) {
      edit.addEventListener("click", function () {
        goEdit(state.current);
      });
    }

    var del = el("btn-delete");
    if (del) del.addEventListener("click", deleteCurrent);

    var pub = el("btn-publish");
    if (pub) pub.addEventListener("click", publishCurrent);

    var arch = el("btn-archive");
    if (arch) arch.addEventListener("click", archiveCurrent);

    var cancel = el("btn-cancel");
    if (cancel) {
      cancel.addEventListener("click", function () {
        tryLeaveForm(goList);
      });
    }

    var save = el("btn-save");
    if (save) {
      save.addEventListener("click", function () {
        syncFormFromDom();
        var status = state.form.status || "draft";
        if (status === "published" && !perms().publish) status = "draft";
        if (status === "published") status = "draft";
        saveForm("draft");
      });
    }

    var validateBtn = el("btn-validate");
    if (validateBtn) {
      validateBtn.addEventListener("click", function () {
        syncFormFromDom();
        saveForm("published");
      });
    }

    ["f-title", "f-content", "f-type", "f-priority", "f-status"].forEach(function (id) {
      var node = el(id);
      if (!node) return;
      node.addEventListener("input", markDirty);
      node.addEventListener("change", markDirty);
    });
  }

  function initPush() {
    if (typeof window.useNuiEvent === "function") {
      window.useNuiEvent("announcementsChanged", function () {
        if (state.view === "list" || state.view === "detail") {
          loadList();
          if (state.view === "detail" && state.current) {
            loadDetail(state.current.id);
          }
        }
      });
    }
    if (typeof window.OnAppOpen === "function") {
      window.OnAppOpen(function () {
        if (state.bootstrap && state.bootstrap.ok) loadList();
      });
    }
  }

  function whenReady() {
    return new Promise(function (resolve) {
      if (window.componentsLoaded) return resolve();
      var poll = setInterval(function () {
        if (window.componentsLoaded) {
          clearInterval(poll);
          resolve();
        }
      }, 50);
      window.addEventListener("message", function (e) {
        if (e.data === "componentsLoaded") {
          clearInterval(poll);
          resolve();
        }
      });
    });
  }

  function boot() {
    if (booted) return;
    booted = true;
    initSettings();
    initPush();
    loadBootstrap().then(function () {
      if (!isDev() || !state.bootstrap || !state.bootstrap.ok) return;
      var hash = (window.location.hash || "").replace(/^#/, "");
      var params = new URLSearchParams(window.location.search || "");
      var view = hash || params.get("view");
      if (view === "form" || view === "create") {
        goCreate();
        if (params.get("demo") === "1" || hash.indexOf("demo") !== -1) {
          state.form.title = "Briefing soirée";
          state.form.content =
            "Point opérationnel à 20h au QG. Présence requise pour l’équipe de nuit.";
          state.form.type = "meeting";
          state.form.priority = "urgent";
          state.formDirty = false;
          render();
        }
      } else if (view === "detail") {
        if (state.announcements[0]) goDetail(state.announcements[0]);
      }
    });
  }

  if (isDev()) {
    document.documentElement.style.visibility = "visible";
    document.body.style.visibility = "visible";
    boot();
  } else {
    whenReady().then(boot);
  }
})();
