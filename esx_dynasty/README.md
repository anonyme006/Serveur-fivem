# esx_dynasty — Dynasty 8

Entreprise immobilière complète pour ESX Legacy : panel entreprise (style Vibe Panel) + panel logements avec **création de biens**.

## Dépendances

- `es_extended` (ESX Legacy)
- `oxmysql`
- `ox_lib`
- `esx_addonaccount` (compte société, optionnel mais recommandé)

## Installation

1. Copier le dossier `esx_dynasty` dans `resources/[jobs]/` (ou équivalent).
2. Importer `sql/dynasty.sql` dans votre base.
3. Ajouter dans `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure esx_dynasty
```

4. Redémarrer le serveur. Assigner le job `realestateagent` à un joueur (grade 3 = patron).

## Commandes

| Commande | Description |
|----------|-------------|
| `/dynasty` | Ouvre le panel entreprise (agents) |
| `/housing` | Ouvre le panel logements |
| `/cleslogement [id]` | Donne les clés du bien au joueur le plus proche |

Aussi accessible via le marker à l’agence Dynasty 8 (Rockford Hills) — touche **E**.

## Fonctionnalités

### Panel entreprise
- Tableau de bord + actualités (Normal / Urgent / Info)
- Panneau d’affichage
- Gestion des employés (recruter proche, promouvoir, rétrograder, licencier)
- Flotte de véhicules société
- Accès rapide au panel logements

### Panel logements
- Grille de biens (statut, prix, adresse, propriétaire, clés)
- Stats, recherche, tris prix / statut
- **Création de logement** : nom, adresse, intérieur, type, prix vente/loyer, position actuelle
- Modification / suppression
- Vente ou location au joueur proche
- Gestion des clés
- Entrée / sortie d’intérieur (shells configurés)

## Grades

| Grade | Nom | Droits clés |
|------:|-----|-------------|
| 0 | Recrue | Panel, logements |
| 1 | Agent | Création, vente, location, actualités |
| 2 | Agent senior | Suppression, véhicules, affichage |
| 3 | Patron | Employés |

## Configuration

Voir `config.lua` : bureau, garage, intérieurs, permissions, commissions.

## Notes RP

- Les intérieurs sont des shells / IPLs GTA listés dans `Config.Interiors`.
- Type `mlo` = pas de téléport (porte locale au point d’entrée).
- Commission société configurable (`Config.Commission`).
