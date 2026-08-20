# Pulse Phone — Architecture

Ressource FiveM originale pour Qbox. Aucun code, asset ou UI issu d’un autre téléphone commercial.

## Objectif

Téléphone RP commercial, extensible, sécurisé côté serveur, optimisé, avec priorité sur le module **Services / Entreprises**.

## Stack

| Couche | Techno |
|--------|--------|
| Framework | Qbox (`qbx_core`) |
| Lib | `ox_lib` |
| Inventaire | `ox_inventory` |
| BDD | `oxmysql` |
| Voix | `pma-voice` |
| NUI | React + TypeScript + Vite |

## Arborescence

```
pulse-phone/
├── fxmanifest.lua
├── client/          # NUI bridge, téléphone, appels, notifs, exports
├── server/          # BDD, joueurs, contacts, messages, appels, companies, services
├── shared/          # config + utils
├── locales/         # fr (défaut), en, es
├── sql/             # install.sql
├── web/             # React/Vite source
├── html/            # build NUI (généré)
└── docs/            # architecture, install, config, API
```

## Flux de données (sécurité)

```
React (NUI)
  → fetch NUI callback (client Lua)
    → TriggerServerEvent / lib.callback (server)
      → validation source + citizenid + job/grade/money
        → oxmysql / qbx_core / pma-voice
          → résultat → client → SendNUIMessage
```

**Règle d’or :** la NUI ne décide jamais des permissions, de l’argent, du job ou de l’identité. Tout est vérifié serveur.

## Modules (ordre de livraison)

1. Shell téléphone (open/close, lock, home, status bar)
2. Contacts
3. Appels (pma-voice)
4. Messages
5. Services / Entreprises (priorité produit)
6. Banque / Wallet
7. Garage (API pluggable)
8. Marketplace
9. GPS
10. Settings + sons + i18n

## Extensibilité

- Apps enregistrées via `Config.Apps` + registre React
- Entreprises via `Config.Companies` + `exports['pulse-phone']:RegisterCompany`
- Garage via adaptateur `server/garage_adapter.lua`
- Exports documentés dans `docs/API.md`

## Performance

- Pas de boucle 0 ms
- Cache serveur pour companies / online employees
- Cooldowns anti-spam sur events sensibles
- NUI messages ciblés (pas de spam SendNUIMessage)
