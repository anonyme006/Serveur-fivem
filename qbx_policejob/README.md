# qbx_policejob

Ressource Police all-in-one pour **Qbox / qbx_core**.

Stack : `ox_lib` · `ox_target` · `ox_inventory` · `oxmysql`

## Phase actuelle

**PHASE 1** — Architecture, configuration, bridge Qbox, sécurité de base, schéma SQL.

## Démarrage

Dans `server.cfg` (après ox / qbx) :

```
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_target
ensure ox_inventory
ensure qbx_policejob
```

Optionnel (manuel) :

```
mysql < resources/qbx_policejob/sql/install.sql
```

Les tables sont aussi créées au `onResourceStart`.

## Jobs requis (qbx_core)

Configurer les jobs `police`, `sheriff`, `statepolice` (et `fib` si activé) dans `qbx_core` avec `type = 'leo'`.

## Intégrations

Voir `config/config.lua` → `Config.Integrations` (duty externe, garage, appearance, téléphone). Aucun système existant n'est remplacé automatiquement.
