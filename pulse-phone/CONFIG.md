# Configuration — Pulse Phone

Fichier principal : `shared/config.lua`.

## Touches & commandes

```lua
Config.OpenKey = 'F1'
Config.OpenCommand = 'phone'
Config.RequireItem = true
Config.PhoneItem = 'phone'
```

## Langue

```lua
Config.Locale = 'fr' -- fr | en | es
```

## Apps

```lua
Config.Apps = {
    phone = true,
    contacts = true,
    messages = true,
    services = true,
    -- ...
}
```

## Entreprises

```lua
Config.Companies = {
    mechanic = {
        id = 'mechanic',
        label = 'LS Customs',
        job = 'mechanic',
        minGrade = 0,
        manageGrade = 2,
        category = 'service',
        description = 'Réparation et dépannage.',
        number = '5551001',
        autoStatus = true,
    },
}
```

Le statut auto dépend de `Config.CompanyAutoStatus` et des employés **on duty** Qbox.

## UI

- `Config.Colors` — accent teal par défaut (identité Pulse)
- `Config.Wallpapers` — ocean / dusk / forest / grit
- `Config.Sounds.enabled` — couper tous les sons

## Sécurité

Ne jamais ajouter de validation job/grade/money côté NUI uniquement.  
Toute action sensible passe par `lib.callback` serveur.
