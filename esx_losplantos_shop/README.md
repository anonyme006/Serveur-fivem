# esx_losplantos_shop

Menu **magasin** list-style Los Plantos pour ESX — style Twenty Four Seven :

- Bandeau synthwave Los Plantos  
- Barre violette `TWENTY FOUR SEVEN - MAGASIN`  
- Prix verts à côté du nom  
- Quantité à droite (`< 1 >` sur la ligne sélectionnée)

## Installation

```cfg
ensure es_extended
ensure esx_losplantos_shop
```

## Utilisation

| Action | Contrôle |
|--------|----------|
| Ouvrir | **E** près du magasin |
| Naviguer | ↑ ↓ |
| Quantité | ← → |
| Acheter | Entrée / double-clic |
| Fermer | ESC |

## Magasins

| ID | Contenu |
|----|---------|
| `twentyfourseven` | Téléphone, Parapluie, Eau, Sandwich, Pizza, Hot Dog, Cheeseburger, Bière, GPS |
| `ammunation_melee` | Armes de mêlée |

Catalogue / coords / prix dans `config.lua`.

## Items ESX à avoir

```
phone, umbrella, water, sandwich, pizza, hotdog, burger, beer, gps
```

(Adapte les `name` dans `config.lua` à tes items serveur.)

## Exports

```lua
exports['esx_losplantos_shop']:OpenShop('twentyfourseven')
```
