# Serveur-fivem

Ressources FiveM pour serveur ESX.

## Ressources

| Dossier | Description |
|---------|-------------|
| [`esx_progressbar`](./esx_progressbar) | Barre de progression capsule orange (NUI) |
| [`ox_garage`](./ox_garage) | Garage ESX (ox_lib) — progress au rangement / sortie |
| [`esx_consumables`](./esx_consumables) | Manger / boire avec progressbar + esx_status |

## server.cfg (ordre conseillé)

```cfg
ensure es_extended
ensure oxmysql
ensure ox_lib
ensure esx_status
ensure esx_progressbar
ensure esx_consumables
ensure ox_garage
```
