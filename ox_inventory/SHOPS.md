# Shops via ox_inventory

Les magasins passent **uniquement** par ce `ox_inventory` (pas de script shop externe).  
Config : [`data/shops.lua`](data/shops.lua)

## Activation (server.cfg)

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_target
ensure qbx_core
ensure ox_inventory

# Obligatoire pour ouvrir les shops avec ox_target (zones / PED / modèles)
setr inventory:target 1
```

Sans `inventory:target 1`, ox_inventory utilise les `locations` (markers) à la place des `targets`.

## Magasins configurés

| Clé | Nom | Accès |
|-----|-----|--------|
| `General` | Supérette 24/7 | Public |
| `Liquor` | Magasin d'alcool | Public |
| `YouTool` | YouTool | Public |
| `Ammunation` | Ammunation | Public (+ licence arme pour pistolet) |
| `Pharmacy` | Pharmacie | Public |
| `PoliceArmoury` | Armurerie police | Job police |
| `Medicine` | Armoire médicale | Job ambulance |
| `BlackMarketArms` | Marché noir | Public (paie en `black_money`) |
| `VendingMachineDrinks` | Distributeur | Props soda / eau |

## Modifier un shop

Éditez `data/shops.lua` puis `ensure ox_inventory` (ou restart).

```lua
General = {
    name = 'Supérette 24/7',
    blip = { id = 59, colour = 69, scale = 0.8 },
    inventory = {
        { name = 'burger', price = 10 },
        { name = 'water', price = 8 },
        -- currency optionnel : 'money' (défaut) ou 'black_money'
        -- license = 'weapon' pour exiger une licence
        -- grade = 3 pour un grade job minimum
    },
    locations = { vec3(25.7, -1347.3, 29.49) },
    targets = {
        { loc = vec3(25.06, -1347.32, 29.5), length = 0.7, width = 0.5, heading = 0.0, minZ = 29.5, maxZ = 29.9, distance = 1.5 },
    }
},
```

Les items doivent exister dans `data/items.lua` (ou `data/weapons.lua`).

## Ouvrir un shop depuis un autre script

```lua
-- Client
exports.ox_inventory:openInventory('shop', { type = 'General' })
-- Avec plusieurs emplacements :
exports.ox_inventory:openInventory('shop', { type = 'General', id = 1 })
```

## Enregistrer un shop à la volée (serveur)

```lua
exports.ox_inventory:RegisterShop('MonShop', {
    name = 'Boutique custom',
    inventory = {
        { name = 'water', price = 5 },
        { name = 'burger', price = 10 },
    },
    locations = {
        vec3(0.0, 0.0, 72.0),
    },
    targets = {
        { loc = vec3(0.0, 0.0, 72.0), length = 1.0, width = 1.0, heading = 0.0, minZ = 71.5, maxZ = 72.5, distance = 2.0 },
    },
})
```

## Paiement

- Par défaut : item **`money`** (synchro cash Qbox via le bridge)
- Marché noir : **`black_money`**
- Le joueur achete en glissant l’item du shop (droite) vers son inventaire (gauche)
