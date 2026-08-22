# sd-company-announcements

Application **Annonces Entreprise** pour [SD-Phone](https://docs.samueldev.shop/resources/phone) (FiveM · ESX Legacy).

Les employés autorisés créent, modifient, publient et suppriment des annonces depuis le téléphone. Les données sont persistées en MySQL/MariaDB via oxmysql.

## Dépendances

| Resource        | Rôle                                      |
|-----------------|-------------------------------------------|
| `es_extended`   | ESX Legacy (jobs / grades / callbacks)    |
| `oxmysql`       | Requêtes SQL                              |
| `sd-phone`      | Shell téléphone + `addCustomApp` / notify |
| `ox_lib`        | Optionnel (non requis)                    |

**Non supporté :** QBCore / Qbox · RageUI

## Installation

1. Copier le dossier `sd-company-announcements` dans `resources/[phone]/` (ou équivalent).
2. (Optionnel) Importer `sql/announcements.sql` — la table est aussi créée automatiquement au démarrage.
3. Dans `server.cfg`, **après** `sd-phone` :

```cfg
ensure sd-phone
ensure sd-company-announcements
```

4. Configurer les entreprises / grades dans `config.lua` (`Config.Companies`).
5. Redémarrer le serveur (ou `ensure sd-company-announcements`).

### Ajout dans SD-Phone

Aucun patch de `sd-phone` n’est nécessaire. Au démarrage, le client appelle :

```lua
exports['sd-phone']:addCustomApp({ ... })
```

L’icône apparaît pour les jobs listés dans `Config.Companies` (champ `job` + export `canSeeApp`). L’app se réenregistre si `sd-phone` redémarre.

## Preview navigateur

Ouvrir :

- `preview/index.html` — mockup téléphone
- `web/index.html` — UI seule (données mock)

En jeu, `html/body` restent `visibility: hidden` jusqu’à `componentsLoaded` (contrat SD-Phone).

## Permissions

Chaque entreprise définit des permissions **par grade ESX** (`job.grade`) :

```lua
Config.Companies = {
    police = {
        enabled = true,
        label = 'LSPD',
        grades = {
            [0] = { create = true, edit = true, delete = false, publish = false },
            [4] = { create = true, edit = true, delete = true,  publish = true  },
        },
    },
}
```

| Clé       | Effet                                      |
|-----------|---------------------------------------------|
| `create`  | Créer une annonce (brouillon)               |
| `edit`    | Modifier (auteur aussi si `create`)         |
| `delete`  | Supprimer (confirmation)                    |
| `publish` | Publier / archiver + statut Publiée         |

Sécurité serveur : job, grade, entreprise et `id` d’annonce sont toujours revalidés. Un joueur ne peut jamais lire/modifier une annonce d’une autre entreprise.

## Notifications

À la publication d’une annonce **importante** ou **urgente**, les membres online du même job reçoivent une bannière SD-Phone :

```lua
exports['sd-phone']:notify(source, {
    app   = 'company-announcements',
    title = 'Nouvelle annonce',
    body  = '...',
    appId = 'company-announcements',
})
```

Réglages : `Config.Notifications`.

## Architecture

```
sd-company-announcements/
├── fxmanifest.lua
├── config.lua
├── client/client.lua      # addCustomApp + NUICallbacks
├── server/server.lua      # CRUD + permissions + SQL
├── sql/announcements.sql
├── web/                   # NUI (iframe SD-Phone)
│   ├── index.html
│   ├── style.css
│   ├── app.js
│   └── icon.svg
└── preview/index.html     # Preview navigateur
```

### Callbacks NUI → serveur

`getBootstrap` · `getAnnouncements` · `getAnnouncement` · `createAnnouncement` · `updateAnnouncement` · `deleteAnnouncement` · `publishAnnouncement` · `archiveAnnouncement`

## Configuration utile

- `Config.Debug` — logs
- `Config.RetentionDays` — purge des archives (0 = jamais)
- `Config.App.*` — identifiant / nom affiché sur l’écran d’accueil
- `Config.Types` / `Priorities` / `Statuses` — listes du formulaire

## Export serveur

```lua
exports['sd-company-announcements']:canSeeApp(source) -- true si job autorisé
```

Utilisé par SD-Phone (`requires.check`) pour masquer l’icône aux joueurs sans entreprise.