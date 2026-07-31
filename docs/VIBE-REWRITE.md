# Réécriture des scripts `vibe_*`

Tous les modules ci-dessous sont des **réécritures originales** Qbox + Ox, inspirées des mécaniques du serveur de référence — pas des dumps.

## Modules livrés

### Core
| Ressource | Rôle | Commandes / usage |
|-----------|------|-------------------|
| `vibe_api` | Helpers joueur, money, jobs, meta SQL | exports serveur/client |
| `vibe_blips` | Blips carte | auto |
| `vibe_loadscreen` | Écran de chargement | auto |
| `vibe_spawnselector` | Choix de spawn NUI | auto au login |
| `vibe_discord` | Logs webhook | exports `Log` |
| `vibe_npc` | PNJ infos | ox_target |
| `vibe_teleport` | TPM / points admin | `/tpm`, `/tp` |
| `vibe_playerstats` | Faim / soif | sync auto |
| `vibe_inventory_restrictions` | Limites armes / items job | hook ox_inventory |
| `vibe_vehicle_restrictions` | Véhicules d’urgence | auto |

### Civil / économie
| Ressource | Rôle | Commandes |
|-----------|------|-----------|
| `vibe_garages` | Sortie véhicules | ox_target |
| `vibe_concess` | Achat véhicules | ox_target |
| `vibe_factures` | Factures joueur | `/facture`, `/mesfactures` |
| `vibe_amende` | Amendes FDO | `/amende` |
| `vibe_duty` | Prise de service | ox_target, `/duty` |
| `vibe_permits` | Affichage permis | `/permis`, `/montrerpermis` |
| `vibe_driving_school` | Code + permis | ox_target |
| `vibe_farm` | Récolte / vente | ox_target |
| `vibe_hunt` | Dépeçage | ox_target |
| `vibe_sellfish` | Vente poisson | ox_target |
| `vibe_gruppe6` | Tournées fourgon | ox_target |

### FDO
| Ressource | Rôle | Commandes |
|-----------|------|-----------|
| `vibe_fdo` | Menottes, escorte, fouille, prison | `F6` / `/fdo` |
| `vibe_dispatch` | Alertes 911 + exports | `/911` |
| `vibe_lspdradar` | Radar vitesse | `/radar` |
| `vibe_roadblock` | Cones / barrières / herses | `/barrage`, `/clearbarrage` |
| `vibe_evidence` | Casiers preuves | ox_target |

### Illégal
| Ressource | Rôle |
|-----------|------|
| `vibe_crimi_weed` | Recolte → process → vente |
| `vibe_crimi_pickpocket` | Vol PNJ |
| `vibe_crimi_blackmarket` | Achat / revente illégale |
| `vibe_crimi_carjack` | Crochetage véhicules |
| `vibe_crimi_whitening` | Blanchiment |
| `vibe_crimi_bankrobbery` | Fleeca (hack + coffre) |
| `vibe_crimi_jewelry` | Vangelico |
| `vibe_gangs` | Territoires + `/capture` |

## Items à ajouter

Fusionne `config/items_vibe.lua` dans `ox_inventory/data/items.lua`.

## Équilibrage prod recommandé

- `vibe_crimi_bankrobbery` / `jewelry` : `MinCops = 2`
- Cooldowns braquages déjà présents
- Webhooks dans `vibe_discord/config.lua`
- Catalogue `vibe_concess` : ajoute tes véhicules custom
- Jobs police/EMS dans `vibe_api/config.lua`

## Non réécrit (volontairement plus tard)

Activités très spécifiques du serveur d’origine : casino UI, F1, lasergame, meth van complète, elections, billboards, etc. La base RP (légal + FDO + crimi principal) est couverte pour démarrer un serveur jouable.
