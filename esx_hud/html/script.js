(() => {
    const hud = document.getElementById('hud');
    const vehicleHud = document.getElementById('vehicle-hud');

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

    // Circumference = 2 * PI * r
    // Arc visible ~ 270° (3/4 du cercle) pour le look HUD
    const ARC_RATIO = 0.75;

    function setupArc(el, radius) {
        const circumference = 2 * Math.PI * radius;
        const visible = circumference * ARC_RATIO;
        el.style.strokeDasharray = `${visible} ${circumference}`;
        el.dataset.circumference = String(circumference);
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

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || !data.action) return;

        switch (data.action) {
            case 'setVisible':
                hud.classList.toggle('hidden', !data.visible);
                if (data.statusBottom) {
                    document.documentElement.style.setProperty('--status-bottom', data.statusBottom);
                }
                if (data.statusLeft) {
                    document.documentElement.style.setProperty('--status-left', data.statusLeft);
                }
                if (data.vehicleBottom) {
                    document.documentElement.style.setProperty('--vehicle-bottom', data.vehicleBottom);
                }
                break;

            case 'updateStatus':
                setBar(healthFill, data.health);
                setBar(hungerFill, data.hunger);
                setBar(thirstFill, data.thirst);
                break;

            case 'updateVehicle':
                if (!data.show) {
                    vehicleHud.classList.add('hidden');
                    break;
                }

                vehicleHud.classList.remove('hidden');
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
                break;
        }
    });
})();
