# qbx_licenses

Système de **permis à points** QBox pour :

| Type | Clé | Points max |
|------|-----|------------|
| Voiture | `driver` | 12 |
| Moto | `motorcycle` | 12 |
| Bateau | `boat` | 12 |
| Avion | `aircraft` | 12 |

La police peut **retirer des points** ; le solde se met à jour **en direct sur la carte**.

## Installation

1. Place `qbx_licenses` dans tes resources
2. Ajoute les items de `install/ox_items.lua` dans `ox_inventory/data/items.lua`
3. Dans `server.cfg` :

```cfg
ensure qbx_core
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure qbx_licenses
```

4. (Optionnel) Applique `install/PATCH_qbx_idcard.md` pour afficher les points sur `qbx_idcard`

La table SQL `qbx_license_history` est créée automatiquement au démarrage.

## Police

- **ox_target** sur un joueur → « Gérer les permis »
- Commande `/permispolice` (joueur le plus proche)
- Actions : retirer des points, délivrer, révoquer, voir la carte

Config jobs dans `config.lua` :

```lua
Config.PoliceJobs = {
    police = 0,
    sheriff = 0,
    fib = 2,
}
```

À 0 point → permis **suspendu** (`Config.RevokeAtZero = true`).

## Joueurs

- `/mespermis` — ouvre ta carte (4 permis + points)
- Utiliser un item permis (`driver_license`, etc.) — même carte
- Montrer la carte au joueur proche automatiquement

Quand la police retire des points **pendant que la carte est ouverte**, les points se rafraîchissent immédiatement (surbrillance orange).

## Exports serveur

```lua
exports.qbx_licenses:HasLicense(source, 'driver')
exports.qbx_licenses:GetLicenses(source)
exports.qbx_licenses:GrantLicense(target, 'motorcycle', issuer)
exports.qbx_licenses:RevokeLicense(target, 'boat', issuer, 'motif')
exports.qbx_licenses:RemovePoints(target, 'driver', 3, issuer, 'excès')
exports.qbx_licenses:SetPoints(target, 'aircraft', 8, issuer)
exports.qbx_licenses:EnrichCardData(source, data) -- pour qbx_idcard
```

## Stockage

`PlayerData.metadata.licences` :

```lua
{
    driver = { owned = true, points = 9 },
    motorcycle = { owned = false, points = 0 },
    boat = { owned = true, points = 12 },
    aircraft = { owned = true, points = 12 },
}
```

Compatibilité : un ancien `driver = true` (booléen) est migré automatiquement en `{ owned = true, points = 12 }`.

## Commandes

| Commande | Description |
|----------|-------------|
| `/mespermis` | Ouvrir sa carte |
| `/permispolice` | Menu police (proche) |
| `/grantlicense [id] [type]` | Délivrer |
| `/revokelicense [id] [type]` | Révoquer |
| `/setlicensepoints [id] [type] [pts]` | Définir les points |
