# pn-hud

HUD Qbox léger avec HUD véhicule moderne (compteur central, RPM, rapport, essence, moteur, ceinture, clignotants, feux).

## Installation

1. Placez la ressource dans `resources/[custom]/pn-hud`
2. Dans `server.cfg` :

```cfg
ensure ox_lib
ensure qbx_core
ensure ox_fuel          # ou votre système carburant
ensure qbx_seatbelt     # recommandé — ceinture gérée par Qbox
ensure pn-hud

stop qbx_hud            # évite le doublon HUD véhicule
```

3. Redémarrez le serveur

## Configuration

Tout est dans `config.lua` : unités KM/H ou MPH, modules activables, seuils essence/moteur, position du HUD, types de véhicules.

## Carburant

`Config.Fuel.system = 'auto'` détecte automatiquement :

- `ox_fuel` (statebag `Entity(vehicle).state.fuel`)
- `LegacyFuel`
- `mnr_fuel`
- fallback natif `GetVehicleFuelLevel`

## Ceinture

Si `qbx_seatbelt` est démarré, pn-hud **lit uniquement** `LocalPlayer.state.seatbelt`.

Sinon, un toggle interne (touche `B` par défaut) est créé dans pn-hud.

## Compatibilité

- qbx_core, ox_lib, ox_inventory (sans modification)
- Faim / soif / santé / armure : gérés par ox_inventory, pas par pn-hud
