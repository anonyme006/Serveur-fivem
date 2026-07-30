# esx_concessionnaire

Concessionnaire véhicules **ESX** (FiveM) avec NUI style **Voiture / VIBE** — catégories, recherche, prévisualisation 3D et achat.

## Installation

1. Copiez le dossier `esx_concessionnaire` dans `resources/[esx]/` (ou votre dossier resources).
2. Assurez-vous d’avoir :
   - `es_extended` (ESX Legacy recommandé)
   - `oxmysql`
3. Ajoutez dans `server.cfg` :

```cfg
ensure es_extended
ensure oxmysql
ensure esx_concessionnaire
```

4. La table `owned_vehicles` ESX doit exister (standard ESX).

## Utilisation

- Allez au **concessionnaire** (blip carte près de Pillbox / Premium Deluxe Motorsport par défaut).
- Appuyez sur **E** pour ouvrir le menu.
- Filtrez par catégorie, recherchez, sélectionnez un véhicule (préview), puis **Acheter**.
- Commande test : `/concessionnaire`

## Configuration

Fichier `config.lua` :

| Option | Description |
|--------|-------------|
| `Config.Zones` | Position, marker, blip |
| `Config.Preview` | Spawn + caméra de prévisualisation |
| `Config.PurchaseSpawn` | Spawn du véhicule acheté |
| `Config.PaymentAccount` | `'bank'`, `'money'` ou `'both'` |
| `Config.Vehicles` | Catalogue (model, name, category, price) |
| `Config.Categories` | Onglets affichés dans l’UI |

## Exports (client)

```lua
exports['esx_concessionnaire']:OpenDealership()
exports['esx_concessionnaire']:CloseDealership()
```

## Structure

```
esx_concessionnaire/
├── fxmanifest.lua
├── config.lua
├── client/main.lua
├── server/main.lua
├── locales/fr.lua
└── html/
    ├── index.html
    ├── css/style.css
    ├── js/app.js
    └── img/logo.svg
```

## Notes

- Compatible ESX Legacy via `@es_extended/imports.lua`.
- Tentative de remise de clés pour scripts courants (`vehiclekeys`, `wasabi_carlock`, `qs-vehiclekeys`) — adaptez `server/main.lua` à votre système de clés.
- Ajoutez vos véhicules addon dans `Config.Vehicles` avec le spawn name exact.
