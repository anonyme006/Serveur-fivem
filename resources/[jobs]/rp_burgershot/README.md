# Burger Shot — job légal profond

Boucle de jeu style serveur cinéma / streamer :

1. Prise de service  
2. Craft aux stations (grill, friteuse, boissons, assemblage)  
3. Encaissement client à la caisse  
4. Argent société + tip employé  

## Items à ajouter dans `ox_inventory/data/items.lua`

```lua
['bs_raw_patty'] = { label = 'Steak cru', weight = 120, stack = true },
['bs_patty'] = { label = 'Steak cuit', weight = 120, stack = true },
['bs_potato'] = { label = 'Pomme de terre', weight = 100, stack = true },
['bs_fries'] = { label = 'Frites', weight = 110, stack = true },
['bs_bun'] = { label = 'Pain burger', weight = 80, stack = true },
['bs_burger'] = { label = 'Burger Shot', weight = 220, stack = true },
['bs_drink'] = { label = 'Boisson BS', weight = 150, stack = true },
```

## Config

Ajustez les `coords` dans `config.lua` selon votre MLO Burger Shot.

## Dépendances

ox_lib, ox_target, ox_inventory, qbx_core, rp_core, rp_jobs  
Recommandé : rp_business (compte entreprise)
