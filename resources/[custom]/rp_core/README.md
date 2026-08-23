# rp_core

Noyau de la couche custom française.

## Dépendances

- oxmysql, ox_lib, qbx_core, ox_inventory, ox_target

## Exports

### Client
- `exports.rp_core:Notify(message, type?, duration?)`
- `exports.rp_core:IsPlayerLoaded()`
- `exports.rp_core:GetPlayerData()`

### Serveur
- `exports.rp_core:Notify(source, message, type?, duration?)`
- `exports.rp_core:AddMoney / RemoveMoney / GetMoney`
- `exports.rp_core:AddSocietyMoney / RemoveSocietyMoney`
- `exports.rp_core:AddItem / RemoveItem`
- `exports.rp_core:GetPlayer / GetPlayerByCitizenId`
- `exports.rp_core:HasAce / HasJob / RateLimit`

## Events

- `rp_core:server:playerLoaded`
- `rp_core:server:playerUnloaded`
- `rp_core:server:jobUpdate`
- `rp_core:server:moneyUpdate`
- `rp_core:client:playerLoaded`
- `rp_core:client:playerUnloaded`
