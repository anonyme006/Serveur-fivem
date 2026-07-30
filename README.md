# Serveur-fivem

Ressources FiveM pour serveur ESX.

## Ressources

| Dossier | Description |
|---------|-------------|
| [`esx_progressbar`](./esx_progressbar) | Barre de progression capsule orange (NUI) |
| [`pa_garage`](./pa_garage) | Garage ox_lib / ox_target — progress au rangement / sortie / fourrière |
| [`ox_inventory`](./ox_inventory) | Inventaire — progress à l’utilisation (manger, boire, craft…) |

## server.cfg (ordre conseillé)

```cfg
ensure es_extended
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure esx_progressbar
ensure ox_inventory
ensure pa_garage
```
