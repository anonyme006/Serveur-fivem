# API / Exports — Pulse Phone

## Client

```lua
exports['pulse-phone']:OpenPhone()
exports['pulse-phone']:ClosePhone()
exports['pulse-phone']:TogglePhone()
exports['pulse-phone']:IsPhoneOpen() -- boolean
exports['pulse-phone']:SendNotification({
    type = 'info',
    title = 'Titre',
    body = 'Message',
    sound = 'notification', -- optionnel
})
exports['pulse-phone']:StartCall('5551001')
```

## Server

```lua
exports['pulse-phone']:RegisterCompany('tow', {
    label = 'Dépanneurs',
    job = 'tow',
    minGrade = 0,
    manageGrade = 2,
    category = 'service',
    description = 'Remorquage 24/7',
    number = '5551003',
    autoStatus = true,
})

exports['pulse-phone']:GetCompany('tow')

exports['pulse-phone']:CreateServiceRequest(source, {
    companyId = 'mechanic',
    serviceType = 'tow',
    description = 'Véhicule en panne',
    locationLabel = 'Vespucci',
})
```

## Events client utiles

- `pulse-phone:client:notify`
- `pulse-phone:client:callIncoming`
- `pulse-phone:client:callUpdate`
- `pulse-phone:client:serviceRequest`
- `pulse-phone:client:serviceUpdate`
- `pulse-phone:client:messageNew`

## Callbacks serveur (internes)

| Callback | Rôle |
|----------|------|
| `pulse-phone:server:getBootstrap` | Profil + numéro |
| `pulse-phone:server:getCompanies` | Liste publique |
| `pulse-phone:server:createServiceRequest` | Nouvelle demande |
| `pulse-phone:server:acceptServiceRequest` | Acceptation atomique |
| `pulse-phone:server:startCall` / `acceptCall` / `endCall` | Appels pma-voice |

## Ajouter une application NUI

1. Activer dans `Config.Apps`
2. Créer `web/src/apps/MonApp.tsx`
3. Brancher dans `AppHost`
4. Ajouter callbacks NUI client → server si données sensibles
