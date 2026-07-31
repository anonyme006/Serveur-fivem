# Équivalents open-source / payants des scripts `vibe_*`

Le serveur de référence repose massivement sur du code privé. Voici des remplacements réalistes pour reconstruire les mêmes mécaniques sur Qbox + Ox.

| Besoin (vibe) | Remplacement suggéré | Type |
|---------------|----------------------|------|
| Inventaire | `ox_inventory` | OSS |
| Target / interactions | `ox_target` | OSS |
| Portes | `ox_doorlock` | OSS |
| Core RP | `qbx_core` | OSS |
| Menu radial | `qbx_radialmenu` | OSS |
| Radio | `qbx_radio` + pma-voice | OSS |
| Voice | `pma-voice` | OSS |
| Téléphone | `lb-phone` | Payant |
| HUD | `jg-hud` ou HUD Qbox custom | Payant / custom |
| Garages | `qbx_garages` / `jg-advancedgarages` | OSS / payant |
| Concess | `qbx_vehicleshop` ou script custom | OSS / custom |
| Housing | `ps-housing` + `ps-realtor` | OSS |
| Banking | `Renewed-Banking` | OSS |
| Météo | `Renewed-Weathersync` | OSS |
| Admin | `ps-adminmenu` / txAdmin | OSS |
| EMS | `ars_ambulancejob` / `qbx_ambulancejob` | OSS / payant |
| Police | `qbx_policejob` + scripts radar custom | OSS / custom |
| Fuel | `mnr_fuel` / `ox_fuel` | OSS |
| Clés véhicules | `mk_vehiclekeys` / `qbx_vehiclekeys` | OSS / payant |
| Braquages / drugs | scripts rcore / custom / community Qbox | Mixte |
| Casino / sports | `rcore_casino`, `rcore_golf`, … | Payant |
| Pêche | `wasabi_fishing` | Payant |
| Sons 3D | `xsound` | OSS |
| Loadscreen | custom NUI (stub fourni) | Custom |
| Spawn selector | custom (stub fourni) | Custom |
| Factures / amendes | `Renewed-Banking` billing ou custom | Mixte |
| Gangs | `qbx_gangs` / custom | Mixte |
| Dispatch | `cd_dispatch` / `ps-dispatch` | Payant / OSS |

## Priorité de développement custom

Si tu dois réécrire du `vibe_*`, commence par cet ordre :

1. `vibe_spawnselector` + `vibe_loadscreen`
2. `vibe_garages` + `vibe_concess`
3. `vibe_fdo` / `vibe_dispatch` / `vibe_duty`
4. `vibe_factures` / `vibe_amende`
5. Un premier circuit crimi (`vibe_crimi_weed` ou `vibe_crimi_pickpocket`)
6. Le reste progressivement

Les stubs dans `resources/[vibe]/` sont des squelettes Lua Qbox/Ox prêts à étendre — pas des clones fonctionnels du serveur original.
