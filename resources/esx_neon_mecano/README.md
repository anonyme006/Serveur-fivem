# Neon Mechanic — ESX

Système mécano complet pour serveurs **ESX** : réparations réalistes, custom véhicule, bipeur et missions de dépannage pour alimenter le compte entreprise.

## Fonctionnalités

- **Atelier** (LS Customs + Benny's) : diagnostic, réparations par pièce (moteur, carrosserie, réservoir, pneus, nettoyage, révision complète)
- **Custom shop** (point séparé Benny's) : néons, couleurs, vitres teintées, jantes
- **Réparations sur route** : cible `ox_target` sur tous les véhicules (diagnostic + réparation)
- **Bipeur** : alertes NUI style pager, commande `/bipeur`, touche **F6**
- **Missions dépannage** : panne moteur, crevaison, accident, batterie — gains société + bonus employé
- **Garage entreprise** : flatbed, dépanneuse, van intervention

## Dépendances

- [es_extended](https://github.com/esx-framework/esx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [esx_addonaccount](https://github.com/esx-framework/esx_addonaccount) (recommandé)
- Optionnel : [Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking) (compte société alternatif)

## Installation

1. Copier `esx_neon_mecano` dans `resources/`
2. Importer `sql/install.sql` dans ta base MySQL
3. Ajouter dans `server.cfg` **après** ESX :

```cfg
ensure es_extended
ensure esx_addonaccount
ensure ox_lib
ensure ox_target
ensure esx_neon_mecano
```

4. Redémarrer le serveur

## Jobs supportés

Par défaut : `mechanic` et `bennys` (modifiable dans `Config.Jobs`).

## Commandes

| Commande | Action |
|----------|--------|
| `/neonmecano` | Menu principal mécano |
| `/mecano` | Alias du menu |
| `/neonmecano duty` | Prise / fin de service (si `RequireDuty = true`) |
| `/bipeur` | Ouvrir le bipeur (F6) |

## Compte société

- Nom : `society_mechanic`
- 70 % des missions dépannage → société
- 15 % des réparations/custom → employé (reste → société)

## Configuration

Tout est dans `neon_mechanic.lua` (table `Config`) : zones, prix, types de missions, intervalle bipeur, etc.

## Export serveur

```lua
exports['esx_neon_mecano']:CreateMission() -- Force une mission dépannage
```
