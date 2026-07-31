# PA Benny's — ESX

Système mécano **Benny's Original** pour serveurs ESX : réparations réalistes, custom véhicule, bipeur et missions de dépannage.

## Fonctionnalités

- **Atelier** : diagnostic et réparations par pièce (moteur, carrosserie, réservoir, pneus, nettoyage, révision)
- **Custom shop** (point séparé) : néons, couleurs, vitres, jantes
- **Réparations sur route** : `ox_target` sur tous les véhicules
- **Bipeur NUI** : `/bipeur` ou **F6**
- **Missions dépannage** : revenus société + bonus employé
- **Garage entreprise** : flatbed, dépanneuse, van

## Installation

1. Copier `pa_bennys` dans `resources/`
2. Importer `sql/install.sql`
3. Ajouter dans `server.cfg` :

```cfg
ensure es_extended
ensure esx_addonaccount
ensure pa_bennys
```

## Jobs

- `bennys` (principal)
- `mechanic` (compatible)

## Commandes

| Commande | Action |
|----------|--------|
| `/bennys` | Menu principal |
| `/mecano` | Alias |
| `/bennys duty` | Prise/fin de service |
| `/bipeur` ou **F6** | Bipeur |

## Compte société

`society_bennys` — 70 % missions → société, 15 % réparations → employé

## Exports

```lua
-- Client
exports['pa_bennys']:OpenMenu()
exports['pa_bennys']:OpenBipeur()

-- Serveur
exports['pa_bennys']:CreateMission()
```
