# Analyse du serveur de référence

Ce document résume ce que montrent les captures : une base **Qbox + Ox** très customisée, orientée RP français, avec une grosse couche privée `rr_*`.

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
| Custom serveur | `rr_*`, `vice_*` | **Privé** — non redistribuable |

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

## Ce qui est privé (`rr_*` / `vice_*`)

Ces scripts appartiennent au serveur / à son équipe de dev. Tu **ne peux pas** les copier depuis une dump. Il faut :

1. les **réécrire** (stubs fournis dans `resources/[reroll]/`), ou
2. les **remplacer** par des scripts publics/payants équivalents (voir `docs/EQUIVALENTS.md`).

Fonctionnalités `rr_*` identifiées :

### Core / UI
- `rr_api`, `rr_panelv2`, `rr_playerstats`, `rr_loadscreen`
- `rr_spawnselector`, `rr_spawn_exits`, `rr_blips`, `rr_discord`
- `rr_inventory_restrictions`, `rr_vehicle_restrictions`

### Économie / civil
- `rr_concess`, `rr_contratvente`, `rr_garages`, `rr_factures`, `rr_amende`
- `rr_tva`, `rr_permits`, `rr_duty`, `rr_elections`, `vote_borne`

### Légal / jobs
- `rr_fdo`, `rr_police_aca`, `rr_dispatch`, `rr_lspdradar`
- `rr_doj`, `rr_gouv`, `rr_gruppe6`, `rr_medicextract`
- `rr_driving_school`, `rr_qcm_drivingschool`
- `rr_weaselnews`, `rr_farm`, `rr_hunt`, `rr_sellfish`, `rr_sellblood`
- `vice_mechanicjob`, `vice_tow`, `vice_mecafarm`

### Illégal (`rr_crimi_*`)
- Drogues : `weed`, `acid`, `methkitchen`, `methvan`, `methwaste`, `methburglary`, `farm`
- Braquages : `bankrobbery`, `jewelry`, `carstheft`, `carjack`, `pickpocket`
- Économie noire : `blackmarket`, `whitening`, `deal`, `retailer`, `dismantler`
- Divers : `bunker`, `container`, `dynamite`, `powerstation`, `nitro`, `saw`, `sneakyammunition`, `transportation`, `motels`, `groceries`, `brawl`, `addressbook`, `props`

### Monde / fun
- `rr_race`, `rr_f1qualif`, `rr_openwheel1`, `rr_lasergame`
- `rr_poker_holdem`, `rr_treasurehunt`, `rr_cinemascope`
- `rr_davis`, `rr_davistrain`, `rr_ron`, `rr_engrais`

## Architecture recommandée pour la refonte

```
1. FXServer + artifacts stables
2. MariaDB + oxmysql
3. ox_lib → ox_target → ox_inventory → ox_doorlock
4. qbx_core + modules qbx_*
5. pma-voice
6. Scripts open-source (housing, jobs de base)
7. Achats légaux (phone, HUD, MLOs, véhicules)
8. Réécriture progressive des rr_* (priorité: spawn, garages, fdo, crimi de base)
```

Priorise le **core jouable** avant les 200+ maps/véhicules : un serveur qui démarre proprement avec inventaire, jobs et voice vaut mieux qu’un dump illisible.
