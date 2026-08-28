const VehicleHud = (() => {
  const root = document.getElementById('vehicle-hud');
  const rpmFill = document.getElementById('rpm-fill');
  const speedEl = document.getElementById('speed');
  const speedUnitEl = document.getElementById('speed-unit');
  const gearEl = document.getElementById('gear');
  const fuelItem = document.getElementById('fuel-item');
  const fuelText = document.getElementById('fuel-text');
  const engineItem = document.getElementById('engine-item');
  const engineFill = document.getElementById('engine-fill');
  const engineText = document.getElementById('engine-text');
  const signalLeft = document.getElementById('signal-left');
  const signalRight = document.getElementById('signal-right');
  const lightsIcon = document.getElementById('lights-icon');
  const seatbeltIcon = document.getElementById('seatbelt-icon');
  const brakeIcon = document.getElementById('brake-icon');
  const doorsList = document.getElementById('doors-list');
  const locationEl = document.getElementById('vehicle-location');

  const RPM_CIRC = 553;
  let padDigits = 3;
  let animations = true;
  let lastSpeed = null;
  let lastGear = null;
  let visible = false;

  const doorLabels = {
    driver: 'Conducteur',
    passenger: 'Passager',
    rear_left: 'Arrière G',
    rear_right: 'Arrière D',
    hood: 'Capot',
    trunk: 'Coffre',
  };

  const setRpm = (value) => {
    const clamped = Math.max(0, Math.min(1, Number(value) || 0));
    rpmFill.style.strokeDashoffset = String(RPM_CIRC - (RPM_CIRC * clamped));
  };

  const setSpeed = (value) => {
    const num = Math.max(0, Math.floor(Number(value) || 0));
    const text = String(num).padStart(padDigits, '0');
    if (lastSpeed !== num) {
      speedEl.textContent = text;
      if (animations) {
        speedEl.classList.remove('tick');
        void speedEl.offsetWidth;
        speedEl.classList.add('tick');
      }
      lastSpeed = num;
    }
  };

  const setGear = (gear) => {
    if (gear == null) {
      gearEl.classList.add('hidden');
      return;
    }
    gearEl.classList.remove('hidden');
    if (lastGear !== gear) {
      gearEl.textContent = gear;
      if (animations) {
        gearEl.classList.remove('changed');
        void gearEl.offsetWidth;
        gearEl.classList.add('changed');
      }
      lastGear = gear;
    }
  };

  const setFuel = (fuel, low, critical, enabled) => {
    if (!enabled || fuel == null) {
      fuelItem.classList.add('hidden');
      return;
    }
    fuelItem.classList.remove('hidden', 'warning', 'critical');
    fuelText.textContent = `${Math.round(fuel)}%`;
    if (critical) fuelItem.classList.add('critical');
    else if (low) fuelItem.classList.add('warning');
  };

  const setEngine = (engine, warning, critical, enabled) => {
    if (!enabled || engine == null) {
      engineItem.classList.add('hidden');
      return;
    }
    engineItem.classList.remove('hidden', 'warning', 'critical');
    engineText.textContent = `${engine}%`;
    engineFill.style.width = `${engine}%`;
    if (critical) engineItem.classList.add('critical');
    else if (warning) engineItem.classList.add('warning');
  };

  const setIndicators = (state, enabled) => {
    signalLeft.classList.toggle('active', enabled && (state === 'left' || state === 'warning'));
    signalRight.classList.toggle('active', enabled && (state === 'right' || state === 'warning'));
  };

  const setLights = (state, enabled) => {
    lightsIcon.classList.remove('state-low', 'state-high', 'active', 'hidden');
    if (!enabled) {
      lightsIcon.classList.add('hidden');
      return;
    }
    if (state === 'low') {
      lightsIcon.classList.add('active', 'state-low');
    } else if (state === 'high') {
      lightsIcon.classList.add('active', 'state-high');
    }
  };

  const setSeatbelt = (buckled, enabled) => {
    seatbeltIcon.classList.remove('unbuckled', 'active', 'hidden');
    if (!enabled || buckled == null) {
      seatbeltIcon.classList.add('hidden');
      return;
    }
    if (buckled) seatbeltIcon.classList.add('active');
    else seatbeltIcon.classList.add('unbuckled');
  };

  const setBrake = (braking, enabled) => {
    brakeIcon.classList.toggle('hidden', !enabled);
    brakeIcon.classList.toggle('active', enabled && braking);
  };

  const setDoors = (doors, enabled) => {
    doorsList.innerHTML = '';
    if (!enabled || !doors || doors.length === 0) {
      doorsList.classList.add('hidden');
      return;
    }
    doorsList.classList.remove('hidden');
    doors.forEach((door) => {
      const chip = document.createElement('span');
      chip.className = 'door-chip';
      chip.textContent = doorLabels[door] || door;
      doorsList.appendChild(chip);
    });
  };

  const setLocation = (location) => {
    if (!location) {
      locationEl.classList.add('hidden');
      locationEl.textContent = '';
      return;
    }
    const parts = [];
    if (location.zone) parts.push(location.zone);
    if (location.street) parts.push(location.street);
    if (location.direction) parts.push(location.direction);
    if (parts.length === 0) {
      locationEl.classList.add('hidden');
      return;
    }
    locationEl.textContent = parts.join(' · ');
    locationEl.classList.remove('hidden');
  };

  const applyPosition = (position) => {
    if (!position) return;
    root.style.left = `${position.x}%`;
    root.style.bottom = `${100 - position.y}%`;
    root.style.transform = 'translateX(-50%)';
  };

  const show = (data = {}) => {
    animations = data.animations !== false;
    padDigits = data.padDigits || 3;
    if (data.speedUnit) speedUnitEl.textContent = data.speedUnit;
    applyPosition(data.position);
    root.classList.remove('no-anim', 'hidden', 'leaving');
    if (animations) {
      root.classList.add('entering');
      root.addEventListener('animationend', () => root.classList.remove('entering'), { once: true });
    }
    root.classList.add('visible');
    root.setAttribute('aria-hidden', 'false');
    visible = true;
  };

  const hide = () => {
    if (!visible) return;
    root.classList.remove('entering', 'visible');
    if (animations) {
      root.classList.add('leaving');
      root.addEventListener('animationend', () => {
        root.classList.add('hidden');
        root.classList.remove('leaving');
      }, { once: true });
    } else {
      root.classList.add('hidden');
    }
    root.setAttribute('aria-hidden', 'true');
    visible = false;
    lastSpeed = null;
    lastGear = null;
  };

  const update = (data = {}) => {
    if (!visible) return;
    const features = data.features || {};

    setRpm(features.rpm === false ? 0 : data.rpm);
    setSpeed(features.speed === false ? 0 : data.speed);
    setGear(features.gear === false ? null : data.gear);
    setFuel(data.fuel, data.fuelLow, data.fuelCritical, features.fuel !== false);
    setEngine(data.engine, data.engineWarning, data.engineCritical, features.engine !== false);
    setIndicators(data.indicators, features.indicators !== false);
    setLights(data.lights, features.lights !== false);
    setSeatbelt(data.seatbelt, features.seatbelt !== false);
    setBrake(data.braking, features.brake !== false);
    setDoors(data.doors, features.doors !== false);
    setLocation(data.location);
  };

  return { show, hide, update, setAnimations: (state) => { animations = state; root.classList.toggle('no-anim', !state); } };
})();

window.VehicleHud = VehicleHud;
