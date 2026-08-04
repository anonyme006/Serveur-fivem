# esx_interim — Pôle Emploi

Jobs intérim pour ESX Legacy + ox_lib + ox_target.

## Métiers

| ID | Label | Gameplay |
|----|--------|----------|
| `electricien` | Electricien | Réparation de boîtiers électriques |
| `eboueur` | Éboueur | Collecte d'ordures + décharge |
| `plombier` | Plombier | Interventions plomberie chez particuliers |
| `mineur` | Joaillier (Mineur) | Extraction puis vente à la joaillerie |
| `livreur` | Livreur de Journaux | Livraisons en scooter |

## Installation

1. Copier `esx_interim` dans vos `resources`
2. Importer `sql/jobs.sql` dans votre base ESX
3. Ajouter dans `server.cfg` :

```cfg
ensure ox_lib
ensure ox_target
ensure esx_interim
```

4. Redémarrer le serveur

## Utilisation

1. Aller au **Pôle Emploi** (blip carte)
2. Choisir un métier dans le menu
3. Suivre le GPS jusqu'au **dépôt**
4. Commencer une tournée (véhicule de service fourni)
5. Valider chaque point via ox_target
6. Quitter le métier depuis le dépôt quand vous voulez

## Configuration

Tout est dans `config.lua` :

- Position de l'agence / PED
- Véhicules, dépôts, points de mission
- Paiements min/max
- Jobs verrouillés (`locked = true` + `Config.Unlock`)

## Dépendances

- `es_extended` (ESX Legacy)
- `ox_lib`
- `ox_target`
