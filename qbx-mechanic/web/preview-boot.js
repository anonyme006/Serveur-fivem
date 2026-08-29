const app = document.getElementById('app');
const panels = {
    vehicle: document.getElementById('panel-vehicle'),
    diagnostic: document.getElementById('panel-diagnostic'),
    actions: document.getElementById('panel-actions'),
    billing: document.getElementById('panel-billing'),
};

const titles = {
    vehicle: ['Atelier mécanique', 'Véhicule connecté — intervention en cours'],
    diagnostic: ['Diagnostic véhicule', 'Analyse complète des composants'],
    actions: ['Actions mécanicien', 'Sélectionnez une prestation'],
    billing: ['Facturation client', 'Récapitulatif avant envoi'],
};

function switchTab(tab) {
    document.querySelectorAll('.nav-item').forEach((btn) => {
        btn.classList.toggle('active', btn.dataset.tab === tab);
    });

    Object.entries(panels).forEach(([key, panel]) => {
        panel.classList.toggle('active', key === tab);
    });

    const [title, subtitle] = titles[tab] || titles.vehicle;
    document.getElementById('panel-title').textContent = title;
    document.getElementById('panel-subtitle').textContent = subtitle;
}

document.querySelectorAll('.nav-item').forEach((btn) => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

document.getElementById('btn-close')?.addEventListener('click', () => {
    app.style.opacity = '0.5';
    setTimeout(() => { app.style.opacity = '1'; }, 400);
});

document.querySelectorAll('.client-option').forEach((el) => {
    el.addEventListener('click', () => {
        document.querySelectorAll('.client-option').forEach((o) => o.classList.remove('selected'));
        el.classList.add('selected');
    });
});

switchTab('vehicle');
