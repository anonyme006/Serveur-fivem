(() => {
    const resourceName = (typeof GetParentResourceName === 'function')
        ? GetParentResourceName()
        : 'esx_hud';

    const hud = document.getElementById('hud');
    const statusHud = document.getElementById('status-hud');
    const vehicleHud = document.getElementById('vehicle-hud');
    const editOverlay = document.getElementById('edit-overlay');

    const healthFill = document.getElementById('health-fill');
    const hungerFill = document.getElementById('hunger-fill');
    const thirstFill = document.getElementById('thirst-fill');

    const speedValue = document.getElementById('speed-value');
    const speedUnit = document.getElementById('speed-unit');
    const plateText = document.getElementById('plate-text');
    const fuelLabel = document.getElementById('fuel-label');

    const rpmArc = document.getElementById('rpm-arc');
    const engineArc = document.getElementById('engine-arc');
    const fuelArc = document.getElementById('fuel-arc');

    const engineGauge = document.querySelector('.gauge-engine');
    const fuelGauge = document.querySelector('.gauge-fuel');

    const ARC_RATIO = 0.75;
    let editing = false;
    let vehicleForceShow = false;
    let positions = {
        status: { left: 1.55, top: 97.6 },
        vehicle: { left: 42.0, top: 82.0 },
    };
    let positionsBeforeEdit = null;

    function setupArc(el, radius) {
        const circumference = 2 * Math.PI * radius;
        const visible = circumference * ARC_RATIO;
        el.style.strokeDasharray = `${visible} ${circumference}`;
        el.dataset.visible = String(visible);
        el.style.strokeDashoffset = String(visible);
    }

    setupArc(rpmArc, 58);
    setupArc(engineArc, 42);
    setupArc(fuelArc, 42);

    function setArc(el, percent) {
        const pct = Math.max(0, Math.min(100, percent)) / 100;
        const visible = parseFloat(el.dataset.visible);
        el.style.strokeDashoffset = String(visible * (1 - pct));
    }

    function setBar(el, percent) {
        const pct = Math.max(0, Math.min(100, percent));
        el.style.transform = `scaleX(${pct / 100})`;
    }

    function fuelRangeLabel(fuel) {
        if (fuel <= 15) return 'Low Fuel';
        if (fuel <= 40) return 'Reserve';
        return 'Normal Range';
    }

    function applyPosition(el, pos) {
        if (!el || !pos) return;
        el.style.left = `${pos.left}%`;
        el.style.top = `${pos.top}%`;
        el.style.right = 'auto';
        el.style.bottom = 'auto';
        el.style.transform = 'none';
    }

    function applyAllPositions() {
        applyPosition(statusHud, positions.status);
        applyPosition(vehicleHud, positions.vehicle);
    }

    function getCurrentPositions() {
        const sw = window.innerWidth || 1;
        const sh = window.innerHeight || 1;

        const read = (el) => {
            const rect = el.getBoundingClientRect();
            return {
                left: Math.round((rect.left / sw) * 10000) / 100,
                top: Math.round((rect.top / sh) * 10000) / 100,
            };
        };

        return {
            status: read(statusHud),
            vehicle: read(vehicleHud),
        };
    }

    function post(name, data = {}) {
        fetch(`https://${resourceName}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        }).catch(() => {});
    }

    function setEditMode(enabled) {
        editing = enabled;
        document.body.classList.toggle('editing', enabled);
        editOverlay.classList.toggle('hidden', !enabled);

        if (enabled) {
            positionsBeforeEdit = JSON.parse(JSON.stringify(positions));
            vehicleForceShow = true;
            vehicleHud.classList.remove('hidden');
            // Valeurs démo pour le speedo pendant l'édition
            speedValue.textContent = speedValue.textContent || '96';
            plateText.textContent = plateText.textContent || '------';
        } else {
            vehicleForceShow = false;
        }
    }

    function saveAndClose() {
        positions = getCurrentPositions();
        applyAllPositions();
        post('savePositions', { positions });
        setEditMode(false);
        post('closeEdit');
    }

    function cancelAndClose() {
        if (positionsBeforeEdit) {
            positions = positionsBeforeEdit;
            applyAllPositions();
        }
        setEditMode(false);
        post('closeEdit');
    }

    function resetPositions(defaults) {
        if (defaults && defaults.status && defaults.vehicle) {
            positions = {
                status: { ...defaults.status },
                vehicle: { ...defaults.vehicle },
            };
        }
        applyAllPositions();
    }

    // Drag & drop
    let drag = null;

    function onPointerDown(e) {
        if (!editing) return;
        const el = e.currentTarget;
        const rect = el.getBoundingClientRect();
        drag = {
            el,
            key: el.dataset.hud,
            offsetX: e.clientX - rect.left,
            offsetY: e.clientY - rect.top,
        };
        el.classList.add('dragging');
        el.setPointerCapture?.(e.pointerId);
        e.preventDefault();
    }

    function onPointerMove(e) {
        if (!drag) return;
        const sw = window.innerWidth || 1;
        const sh = window.innerHeight || 1;
        const el = drag.el;
        const w = el.offsetWidth;
        const h = el.offsetHeight;

        let x = e.clientX - drag.offsetX;
        let y = e.clientY - drag.offsetY;

        x = Math.max(0, Math.min(sw - w, x));
        y = Math.max(0, Math.min(sh - h, y));

        const left = (x / sw) * 100;
        const top = (y / sh) * 100;

        el.style.left = `${left}%`;
        el.style.top = `${top}%`;
        el.style.right = 'auto';
        el.style.bottom = 'auto';
        el.style.transform = 'none';

        positions[drag.key] = { left, top };
    }

    function onPointerUp() {
        if (!drag) return;
        drag.el.classList.remove('dragging');
        drag = null;
    }

    statusHud.addEventListener('pointerdown', onPointerDown);
    vehicleHud.addEventListener('pointerdown', onPointerDown);
    window.addEventListener('pointermove', onPointerMove);
    window.addEventListener('pointerup', onPointerUp);

    window.addEventListener('keydown', (e) => {
        if (!editing) return;

        if (e.key === 'Enter') {
            e.preventDefault();
            saveAndClose();
        } else if (e.key === 'Escape') {
            e.preventDefault();
            cancelAndClose();
        } else if (e.key === 'r' || e.key === 'R') {
            e.preventDefault();
            post('requestReset');
        }
    });

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || !data.action) return;

        switch (data.action) {
            case 'setVisible':
                hud.classList.toggle('hidden', !data.visible);
                break;

            case 'setPositions':
                if (data.positions) {
                    positions = {
                        status: { ...positions.status, ...data.positions.status },
                        vehicle: { ...positions.vehicle, ...data.positions.vehicle },
                    };
                    applyAllPositions();
                }
                break;

            case 'editMode':
                setEditMode(!!data.enabled);
                if (data.positions) {
                    positions = {
                        status: { ...positions.status, ...data.positions.status },
                        vehicle: { ...positions.vehicle, ...data.positions.vehicle },
                    };
                    applyAllPositions();
                }
                break;

            case 'resetPositions':
                resetPositions(data.defaults);
                break;

            case 'updateStatus':
                setBar(healthFill, data.health);
                setBar(hungerFill, data.hunger);
                setBar(thirstFill, data.thirst);
                break;

            case 'updateVehicle':
                if (!data.show && !vehicleForceShow) {
                    vehicleHud.classList.add('hidden');
                    break;
                }

                vehicleHud.classList.remove('hidden');
                if (data.show) {
                    speedValue.textContent = String(Math.floor(data.speed || 0));
                    speedUnit.textContent = (data.unit === 'mph') ? 'MPH' : 'KM/H';
                    plateText.textContent = data.plate || '------';

                    setArc(rpmArc, data.rpm || 0);
                    setArc(engineArc, data.engine || 0);
                    setArc(fuelArc, data.fuel || 0);

                    const fuel = data.fuel || 0;
                    const engine = data.engine || 0;

                    fuelLabel.textContent = fuelRangeLabel(fuel);
                    fuelGauge.classList.toggle('low', fuel <= 15);
                    engineGauge.classList.toggle('low', engine <= 30);
                }
                break;
        }
    });

    applyAllPositions();
})();
