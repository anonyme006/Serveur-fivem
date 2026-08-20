# Installation — Pulse Phone

## Dépendances

- `qbx_core`
- `ox_lib`
- `ox_inventory`
- `oxmysql`
- `pma-voice`

## Étapes

1. Placez le dossier `pulse-phone` dans `resources/[phone]/` (ou équivalent).
2. Importez `sql/install.sql` dans votre base MariaDB/MySQL.
3. Ajoutez l’item téléphone dans `ox_inventory` si besoin :

```lua
['phone'] = {
    label = 'Téléphone',
    weight = 190,
    stack = false,
    close = true,
    description = 'Pulse Phone'
}
```

4. Build NUI :

```bash
cd resources/[phone]/pulse-phone/web
npm install
npm run build
```

5. `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure qbx_core
ensure pma-voice
ensure pulse-phone
```

6. Redémarrez le serveur. Touche par défaut : **F1** (configurable).

## Vérification

- `/phone` ou F1 ouvre le téléphone
- Écran de verrouillage → déverrouillage → home
- App **Services** liste les entreprises de `Config.Companies`
