# Analyse du serveur de référence

Ce document résume ce que montrent les captures : une base **Qbox + Ox** très customisée, orientée RP français, avec une grosse couche privée `vibe_*`.

## Stack technique détectée

| Couche | Ressources | Rôle |
|--------|------------|------|
| Framework | `qbx_core`, `qbx_*` | Qbox (successeur moderne de QB-Core) |
| Libs / inventaire | `ox_lib`, `ox_inventory`, `ox_target`, `ox_doorlock`, `oxmysql` | Suite Overextended |
| Voice | `pma-voice` | Voix proximity |
| Téléphone | `lb-phone` (+ props / uploads) | Téléphone premium |
| Housing | `ps-housing`, `ps-realtor` | Project Sloth logement |
| Admin | `ps-adminmenu` | Menu admin |
| Banque / météo | `Renewed-Banking`, `Renewed-Weathersync` | Écosystème Renewed |
| Activités | `rcore_casino`, `rcore_golf`, `rcore_darts`, `rcore_tennis`, `rcore_clothing`, `rcore_tattoos` | Pack rcore (payant) |
| HUD / UI | `jg-hud`, `jg-textui`, `jg-vehiclemileage`, `bl_ui` | UI premium |
| Custom serveur | `vibe_*`, `vice_*` | **Privé** — non redistribuable |

## Ce qui est libre / open-source

À installer légalement via le script `scripts/install-opensource.sh` :

- Qbox (recipe officielle)
- Ox (`ox_lib`, `ox_inventory`, `ox_target`, `ox_doorlock`, `oxmysql`)
- `pma-voice`
- `bob74_ipl`
- Une partie des `qbx_*` jobs/utils
- `chat`, `baseevents`, `spawnmanager`, etc.

## Ce qui est payant (à acheter)

| Ressource | Boutique typique |
|-----------|------------------|
| `lb-phone` | lbphone.com / Tebex |
| `jg-hud`, `jg-textui`, `jg-vehiclemileage` | jgscripts.com |
| `rcore_*` | rcore.cz |
| `kq_*` | KuzQuality |
| MLOs `cfx-fm-*`, `cfx-mxc-*`, `cfx-nteam-*`, `cfx-gn-*`, `rdzk_*`, `soloty-*`, `K4MB1-*`, `brofx_*`, `kiiya_*` | Tebex / Patreon créateurs |
| Packs véhicules custom | Tebex créateurs |
| EUP / ped packs (`000_dlc_eup`, …) | Licences dédiées |

**Ne pirate jamais ces assets.** Un serveur public avec du contenu volé = ban CFX + risques légaux.

## Ce qui est privé (`vibe_*` / `vice_*`)

Ces scripts appartiennent au serveur / à son équipe de dev. Tu **ne peux pas** les copier depuis une dump. Il faut :

1. les **réécrire** (stubs fournis dans `resources/[vibe]/`), ou
2. les **remplacer** par des scripts publics/payants équivalents (voir `docs/EQUIVALENTS.md`).

Fonctionnalités `vibe_*` identifiées :

### Core / UI
- `vibe_api`, `vibe_panelv2`, `vibe_playerstats`, `vibe_loadscreen`
- `vibe_spawnselector`, `vibe_spawn_exits`, `vibe_blips`, `vibe_discord`
- `vibe_inventory_restrictions`, `vibe_vehicle_restrictions`

### Économie / civil
- `vibe_concess`, `vibe_contratvente`, `vibe_garages`, `vibe_factures`, `vibe_amende`
- `vibe_tva`, `vibe_permits`, `vibe_duty`, `vibe_elections`, `vote_borne`

### Légal / jobs
- `vibe_fdo`, `vibe_police_aca`, `vibe_dispatch`, `vibe_lspdradar`
- `vibe_doj`, `vibe_gouv`, `vibe_gruppe6`, `vibe_medicextract`
- `vibe_driving_school`, `vibe_qcm_drivingschool`
- `vibe_weaselnews`, `vibe_farm`, `vibe_hunt`, `vibe_sellfish`, `vibe_sellblood`
- `vice_mechanicjob`, `vice_tow`, `vice_mecafarm`

### Illégal (`vibe_crimi_*`)
- Drogues : `weed`, `acid`, `methkitchen`, `methvan`, `methwaste`, `methburglary`, `farm`
- Braquages : `bankrobbery`, `jewelry`, `carstheft`, `carjack`, `pickpocket`
- Économie noire : `blackmarket`, `whitening`, `deal`, `retailer`, `dismantler`
- Divers : `bunker`, `container`, `dynamite`, `powerstation`, `nitro`, `saw`, `sneakyammunition`, `transportation`, `motels`, `groceries`, `brawl`, `addressbook`, `props`

### Monde / fun
- `vibe_race`, `vibe_f1qualif`, `vibe_openwheel1`, `vibe_lasergame`
- `vibe_poker_holdem`, `vibe_treasurehunt`, `vibe_cinemascope`
- `vibe_davis`, `vibe_davistrain`, `vibe_ron`, `vibe_engrais`

## Architecture recommandée pour la refonte

```
1. FXServer + artifacts stables
2. MariaDB + oxmysql
3. ox_lib → ox_target → ox_inventory → ox_doorlock
4. qbx_core + modules qbx_*
5. pma-voice
6. Scripts open-source (housing, jobs de base)
7. Achats légaux (phone, HUD, MLOs, véhicules)
8. Réécriture progressive des vibe_* (priorité: spawn, garages, fdo, crimi de base)
```

Priorise le **core jouable** avant les 200+ maps/véhicules : un serveur qui démarre proprement avec inventaire, jobs et voice vaut mieux qu’un dump illisible.
