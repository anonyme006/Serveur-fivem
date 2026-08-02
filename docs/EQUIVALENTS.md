# Équivalents open-source / payants des scripts `rr_*`

Le serveur de référence repose massivement sur du code privé. Voici des remplacements réalistes pour reconstruire les mêmes mécaniques sur Qbox + Ox.

| Besoin (reroll) | Remplacement suggéré | Type |
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

Si tu dois réécrire du `rr_*`, commence par cet ordre :

1. `rr_spawnselector` + `rr_loadscreen`
2. `rr_garages` + `rr_concess`
3. `rr_fdo` / `rr_dispatch` / `rr_duty`
4. `rr_factures` / `rr_amende`
5. Un premier circuit crimi (`rr_crimi_weed` ou `rr_crimi_pickpocket`)
6. Le reste progressivement

Les modules dans `resources/[reroll]/` sont maintenant des **réécritures jouables**. Détail : `docs/REROLL-REWRITE.md`.
