# qbx_policejob

Ressource Police all-in-one pour **Qbox / qbx_core**.

Stack : `ox_lib` · `ox_target` · `ox_inventory` · `oxmysql`

## Phase actuelle

**PHASE 1** — Architecture, configuration, bridge Qbox, sécurité de base, schéma SQL.  
**+ Bridge permis à points** (`qbx_licenses` / PATCH_qbx_idcard).

## Démarrage

Dans `server.cfg` (après ox / qbx) :

```
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_target
ensure ox_inventory
ensure qbx_licenses
ensure qbx_idcard
ensure qbx_policejob
```

Optionnel (manuel) :

```
mysql < resources/qbx_policejob/sql/install.sql
```

Les tables sont aussi créées au `onResourceStart`.

## Jobs requis (qbx_core)

Configurer les jobs `police`, `sheriff`, `statepolice` (et `fib` si activé) dans `qbx_core` avec `type = 'leo'`.

## Permis à points (qbx_licenses)

Intégration active via `Config.Integrations.licenses` :

- Commande `/permis` → menu natif `qbx_licenses` (joueur proche)
- Infos joueur enrichies avec `licenses` / `driverLicense`
- Amendes `config/fines.lua` : champs `licenseType` + `licensePoints` (appliqués à l’émission d’amende)
- Patch carte ID : `install/PATCH_qbx_idcard.md`

Aucun code de `qbx_licenses` / `qbx_idcard` n’est copié — uniquement des exports.

## Intégrations

Voir `config/config.lua` → `Config.Integrations` (duty, garage, appearance, téléphone, **licenses**). Aucun système existant n’est remplacé automatiquement.
