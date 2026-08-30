const app = document.getElementById('app');
const companyName = document.getElementById('company-name');
const companyTagline = document.getElementById('company-tagline');
const companyLogo = document.getElementById('company-logo');
const resourceStatus = document.getElementById('resource-status');

function setVisible(visible) {
    app.classList.toggle('hidden', !visible);
}

function applyConfig(config) {
    if (!config || !config.company) return;

    companyName.textContent = config.company.name;
    companyTagline.textContent = config.company.slogan || companyTagline.textContent;

    if (config.company.logo) {
        companyLogo.src = config.company.logo;
    }

    if (config.colors && config.colors.primary) {
        document.documentElement.style.setProperty('--sat-primary', config.colors.primary);
    }
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {
        case 'open':
            applyConfig(data.config);
            resourceStatus.textContent = data.status || 'Prêt';
            setVisible(true);
            break;
        case 'close':
            setVisible(false);
            break;
        case 'update':
            if (data.status) {
                resourceStatus.textContent = data.status;
            }
            break;
        default:
            break;
    }
});

document.addEventListener('keyup', (event) => {
    if (event.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({}),
        }).catch(() => {});
    }
});

setVisible(false);
