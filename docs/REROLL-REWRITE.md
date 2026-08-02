# Réécriture des scripts `rr_*`

Scripts originaux Qbox + Ox pour un serveur type **RE ROLL** (pas de dump). Voir `LIEN-COMPLET.md`.

## Core / UI
| Ressource | Rôle | Usage |
|-----------|------|-------|
| `rr_api` | Helpers money/jobs/meta | exports |
| `rr_blips` | Blips carte | auto |
| `rr_loadscreen` | Chargement thème RE ROLL | auto |
| `rr_spawnselector` | Spawn NUI | auto login |
| `rr_deathscreen` | Overlay mort + appel EMS | auto |
| `rr_discord` | Webhooks | export `Log` |
| `rr_npc` | PNJ infos | ox_target |
| `rr_teleport` | Admin TP | `/tpm` `/tp` |
| `rr_playerstats` | Faim / soif | auto |
| `rr_inventory_restrictions` | Limites items | hook |
| `rr_vehicle_restrictions` | Véhicules urgence | auto |
| `rr_sleep` | Repos | `/dormir` |
| `rr_panelv2` | Panel admin | `/panel` |
| `rr_race` | Course checkpoints | `/course` |

## Civil / économie
| Ressource | Usage |
|-----------|-------|
| `rr_garages` | ox_target |
| `rr_concess` | ox_target |
| `rr_factures` | `/facture` `/mesfactures` |
| `rr_amende` | `/amende` |
| `rr_duty` | `/duty` + target |
| `rr_permits` | `/permis` `/montrerpermis` |
| `rr_driving_school` | ox_target |
| `rr_farm` / `rr_hunt` / `rr_sellfish` | ox_target |
| `rr_gruppe6` | tournées fourgon |
| `rr_mechanic` | `/mecano` |

## FDO / EMS
| Ressource | Usage |
|-----------|-------|
| `rr_fdo` | `F6` menottes/escorte/fouille/prison |
| `rr_medicextract` | `F7` revive/heal/extract |
| `rr_dispatch` | `/911` |
| `rr_lspdradar` | `/radar` |
| `rr_roadblock` | `/barrage` |
| `rr_evidence` | casiers |
| `rr_bracelet` | `/bracelet` |

## Illégal
| Ressource | Rôle |
|-----------|------|
| `rr_crimi_weed` | récolte → process → vente |
| `rr_crimi_methkitchen` | cuisine meth |
| `rr_crimi_pickpocket` | vol PNJ |
| `rr_crimi_deal` | deals PNJ |
| `rr_crimi_blackmarket` | marché noir |
| `rr_crimi_carjack` | crochetage |
| `rr_crimi_dismantler` | casse auto |
| `rr_crimi_whitening` | blanchiment |
| `rr_crimi_bankrobbery` | Fleeca |
| `rr_crimi_jewelry` | Vangelico |
| `rr_crimi_nitro` | nitro `LSHIFT` |
| `rr_gangs` | territoires `/capture` |

## Items

Fusionner `config/items_reroll.lua` dans `ox_inventory/data/items.lua`.

## Prod

- Mettre `MinCops = 2` sur braquages
- Remplir webhooks `rr_discord`
- Étendre le catalogue `rr_concess`
- Brancher le site panel (branche `cursor/gta-rp-reroll-site-f7e3`) sur Discord OAuth
