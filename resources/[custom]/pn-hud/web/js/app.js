const hudRoot = document.getElementById('hud-root');
const voiceIndicator = document.getElementById('voice-indicator');

window.addEventListener('message', (event) => {
  const msg = event.data || {};

  switch (msg.action) {
    case 'hud:toggle':
      hudRoot.classList.toggle('hidden', !msg.show);
      break;

    case 'hud:update': {
      const data = msg.data || {};
      voiceIndicator.classList.toggle('active', !!data.talking);
      break;
    }

    case 'vehicle:show':
      VehicleHud.show(msg.data || {});
      break;

    case 'vehicle:hide':
      VehicleHud.hide();
      break;

    case 'vehicle:update':
      VehicleHud.update(msg.data || {});
      break;

    default:
      break;
  }
});
