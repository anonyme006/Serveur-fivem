# Serveur-fivem

Ressources FiveM pour serveur ESX / ox_lib.

## Ressources

| Dossier | Description |
|---------|-------------|
| [`ox_notify`](./ox_notify) | Notifications ox_lib — barre gauche + progress bas (style photo) |

## server.cfg (ordre conseillé)

```cfg
ensure ox_lib
ensure ox_notify
```

Après installation, remplace aussi `ox_lib/resource/interface/client/notify.lua` par le fichier fourni dans `ox_notify/ox_lib_patch/notify.lua` (voir le README de la ressource).
