# esx_banque

Banque & Distributeur (DAB) pour ESX — comptes **personnels** et **entreprise**.

## Installation

1. Copier le dossier `esx_banque` dans `resources/[esx]/`
2. Ajouter `ensure esx_banque` dans `server.cfg`
3. (Optionnel) Importer `sql/banque.sql` — les tables sont aussi créées automatiquement au démarrage
4. Redémarrer le serveur

## Dépendances

- `es_extended`
- `oxmysql`
- `ox_lib`
- `esx_addonaccount` (recommandé pour les comptes société)

## Fonctionnalités

### Interface Banque
- Liste des comptes personnels et entreprise
- Historique des opérations
- Virement / Dépôt / Retrait
- Export relevé CSV
- Destinataires favoris

### Interface DAB
- Même layout (titre « Distributeur (DAB) »)
- Détection automatique des props ATM du monde
- Positions fixes configurables dans `config.lua`

### Comptes entreprise
- Affichés si le joueur a un job (hors `unemployed`)
- Solde lu depuis `addon_account_data` (`society_<job>`)
- Dépôt : tous les grades
- Retrait / virement : grades ≥ `Config.BusinessWithdrawMinGrade` / `BusinessTransferMinGrade`
- Historique avec le nom de l’employé qui a agi

## Configuration

Éditez `config.lua` :

- Positions des banques & blips
- Grades minimum entreprise
- Montants min/max
- Props DAB

## Preview UI

Ouvrir `html/index.html` dans un navigateur pour prévisualiser l’interface (données mock).
