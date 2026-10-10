# Serveur FiveM — ox_inventory Qbox

Intégration **ox_inventory** (fork [Samuels-Development](https://github.com/Samuels-Development/ox_inventory)) pour serveurs **Qbox** + **rcore_clothing**.

## Ressources

| Dossier | Description |
|---------|-------------|
| [`ox_inventory/`](ox_inventory/) | Fork Samuel complet avec stats Qbox, thème or, rcore_clothing |
| [`ox_inventory_ui/`](ox_inventory_ui/) | Package drop-in pour ox_inventory standard (legacy) |

## Installation recommandée

Utilisez le dossier **`ox_inventory/`** :

1. Copiez `ox_inventory/` dans vos resources FiveM
2. Dans `server.cfg` :

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_target
ensure qbx_core
ensure ox_inventory
setr inventory:target 1
```

3. Shops : [ox_inventory/SHOPS.md](ox_inventory/SHOPS.md)  
4. UI / stats : [ox_inventory/README_QBOX.md](ox_inventory/README_QBOX.md)

## Documentation drop-in (legacy)

Pour ox_inventory standard : [ox_inventory_ui/README.md](ox_inventory_ui/README.md)
