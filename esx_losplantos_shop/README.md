# esx_losplantos_shop

Menu **magasin** list-style Los Plantos pour ESX (même design que l’inventaire : bandeau synthwave, barre violette `MAGASIN`, liste, prix verts).

## Installation

```cfg
ensure es_extended
ensure esx_losplantos_shop
```

## Utilisation

- Approchez un magasin (marker violet) → **E** pour ouvrir
- **↑↓** naviguer · **Entrée** / double-clic acheter · **ESC** fermer

## Magasins inclus

| ID | Contenu |
|----|---------|
| `ammunation_melee` | Armes de mêlée (Poing américain, batte, machette…) |
| `superette` | Pain, eau, burger, téléphone |

Coords et catalogue dans `config.lua`.

## Config

- `Config.PayAccount` — `'money'` ou `'bank'`
- `Config.Shops` — magasins, items (`type = 'weapon' | 'item'`), prix, blips

## Exports

```lua
exports['esx_losplantos_shop']:OpenShop('ammunation_melee')
exports['esx_losplantos_shop']:CloseShop()
```

## Aperçu NUI

Ouvrir `html/index.html` dans un navigateur.
