# Serveur-fivem

Ressources FiveM pour serveur **ESX Legacy**.

## Ressources

| Dossier | Description |
|---------|-------------|
| [`esx_core`](./esx_core) | Core RP — persistance véhicules, fourrière reboot, clés, portefeuille, bâche, occasions, alertes |

## server.cfg (ordre conseillé)

```cfg
ensure es_extended
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure esx_status
ensure esx_core
ensure pa_garage
```

Voir [`esx_core/README.md`](./esx_core/README.md) pour le détail des modules.
