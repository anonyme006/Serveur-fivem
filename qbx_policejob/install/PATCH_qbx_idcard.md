# Patch qbx_idcard — points permis (qbx_licenses)

Ce document reprend le patch optionnel de `qbx_licenses/install/PATCH_qbx_idcard.md`.

`qbx_policejob` délègue la gestion des points à **`qbx_licenses`**. Pour afficher les points sur la carte `qbx_idcard`, applique ce patch.

## Prérequis

```cfg
ensure qbx_licenses
ensure qbx_idcard
ensure qbx_policejob
```

## 1. Serveur — `qbx_idcard/main/server.lua`

Dans l'event `um-idcard:server:sendData`, après construction de `data` :

```lua
local data = exports.qbx_core:GetPlayer(source).PlayerData.charinfo
data.sex = data.gender == 0 and 'Male' or 'Female'
data.cardtype = item or "id_card"
data.mugShot = metadata.mugShot

-- >>> AJOUTER :
if GetResourceState('qbx_licenses') == 'started' then
    data = exports.qbx_licenses:EnrichCardData(source, data)
end
-- <<<

TriggerClientEvent('um-idcard:client:sendData', src, data)
```

## 2. NUI — `qbx_idcard/web/index.html`

Sous la nationalité :

```html
<li>
    <span>Points permis</span>
    <span id="driverPoints" class="info"></span>
</li>
```

## 3. NUI — `qbx_idcard/web/js/main.js`

Dans `openIdCard` :

```js
if (playerData.driverPoints != null) {
  getElementById('driverPoints').textContent =
    `${playerData.driverPoints}/${playerData.driverMaxPoints} (${playerData.driverStatus})`;
}
```

## Lien avec qbx_policejob

| Action police | Mécanisme |
|---|---|
| `/permis` ou menu police | Ouvre `exports.qbx_licenses:OpenPlayerLicenseMenu` |
| Amende avec `licensePoints` | Event `qbx_policejob:server:fineIssued` → `RemovePoints` |
| Infos joueur | Snapshot enrichi (`driverLicense`, `licenses`) |
| ox_target | Laissé à `qbx_licenses` si démarré (pas de doublon) |

Configurer dans `config/config.lua` :

```lua
Config.Integrations.licenses = {
    enabled = true,
    resource = 'qbx_licenses',
    useNativeMenu = true,
    showInPlayerInfo = true,
    autoRemoveOnFine = true,
    defaultLicenseType = 'driver',
}
```

Amendes (`config/fines.lua`) :

```lua
speeding = { label = 'Excès de vitesse', amount = 500, licenseType = 'driver', licensePoints = 2 },
```

## Jobs dans qbx_licenses

Ajouter `statepolice` si besoin dans `qbx_licenses/config.lua` :

```lua
Config.PoliceJobs = {
    police = 0,
    sheriff = 0,
    statepolice = 0,
    fib = 2,
}
```
