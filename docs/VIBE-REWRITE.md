# Réécriture des scripts `vibe_*`

Réécritures originales Qbox + Ox (pas de dump). Lien dépôt : voir `LIEN-COMPLET.md`.

## Core
| Ressource | Rôle | Usage |
|-----------|------|-------|
| `vibe_api` | Helpers money/jobs/meta | exports |
| `vibe_blips` | Blips carte | auto |
| `vibe_loadscreen` | Chargement | auto |
| `vibe_spawnselector` | Spawn NUI | auto login |
| `vibe_discord` | Webhooks | export `Log` |
| `vibe_npc` | PNJ infos | ox_target |
| `vibe_teleport` | Admin TP | `/tpm` `/tp` |
| `vibe_playerstats` | Faim / soif | auto |
| `vibe_inventory_restrictions` | Limites items | hook |
| `vibe_vehicle_restrictions` | Véhicules urgence | auto |
| `vibe_sleep` | Repos | `/dormir` |
| `vibe_panelv2` | Panel admin | `/panel` |
| `vibe_race` | Course checkpoints | `/course` |

## Civil / économie
| Ressource | Usage |
|-----------|-------|
| `vibe_garages` | ox_target |
| `vibe_concess` | ox_target |
| `vibe_factures` | `/facture` `/mesfactures` |
| `vibe_amende` | `/amende` |
| `vibe_duty` | `/duty` + target |
| `vibe_permits` | `/permis` `/montrerpermis` |
| `vibe_driving_school` | ox_target |
| `vibe_farm` / `vibe_hunt` / `vibe_sellfish` | ox_target |
| `vibe_gruppe6` | tournées fourgon |
| `vibe_mechanic` | `/mecano` |

## FDO / EMS
| Ressource | Usage |
|-----------|-------|
| `vibe_fdo` | `F6` menottes/escorte/fouille/prison |
| `vibe_medicextract` | `F7` revive/heal/extract |
| `vibe_dispatch` | `/911` |
| `vibe_lspdradar` | `/radar` |
| `vibe_roadblock` | `/barrage` |
| `vibe_evidence` | casiers |
| `vibe_bracelet` | `/bracelet` |

## Illégal
| Ressource | Rôle |
|-----------|------|
| `vibe_crimi_weed` | récolte → process → vente |
| `vibe_crimi_methkitchen` | cuisine meth |
| `vibe_crimi_pickpocket` | vol PNJ |
| `vibe_crimi_deal` | deals PNJ |
| `vibe_crimi_blackmarket` | marché noir |
| `vibe_crimi_carjack` | crochetage |
| `vibe_crimi_dismantler` | casse auto |
| `vibe_crimi_whitening` | blanchiment |
| `vibe_crimi_bankrobbery` | Fleeca |
| `vibe_crimi_jewelry` | Vangelico |
| `vibe_crimi_nitro` | nitro `LSHIFT` |
| `vibe_gangs` | territoires `/capture` |

## Items

Fusionner `config/items_vibe.lua` dans `ox_inventory/data/items.lua`.

## Prod

- Mettre `MinCops = 2` sur braquages
- Remplir webhooks `vibe_discord`
- Étendre le catalogue `vibe_concess`
