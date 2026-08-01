# esx_radar

Radar automatique pour **FiveM** — compatible **ESX Legacy 1.12.x**, **ox_lib**, **oxmysql** et **ox_target**.

Optimisé (≈ **0.00 ms** au repos), sécurisé côté serveur, entièrement configurable.

---

## Dépendances

| Resource       | Rôle                          |
|----------------|-------------------------------|
| `es_extended`  | Framework ESX Legacy 1.12.x   |
| `ox_lib`       | Menus, contextes, notify, callbacks |
| `oxmysql`      | Base de données MySQL         |
| `ox_target`    | Interaction admin sur les props |

---

## Installation

1. Copier le dossier `esx_radar` dans `resources/[esx]/` (ou votre dossier resources).
2. Importer `sql.sql` dans votre base MySQL **ou** laisser le script créer les tables au démarrage.
3. Ajouter dans `server.cfg` :

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure es_extended
ensure esx_radar
```

4. Redémarrer le serveur (ou `ensure esx_radar`).

---

## Commandes (admin)

| Commande        | Description                                      |
|-----------------|--------------------------------------------------|
| `/createradar`  | Menu ox_lib → configure et place un radar        |
| `/deleteradar`  | Supprime le radar le plus proche (confirmation)  |
| `/radars`       | Menu admin : TP, modifier, activer, désactiver, supprimer |

Groupes autorisés par défaut : `admin`, `superadmin` (voir `Config.AdminGroups`).

---

## Fonctionnement

### Création

`/createradar` ouvre un formulaire :

- Nom du radar
- Nom de la route
- Limitation (30 / 50 / 70 / 80 / 90 / 110 / 130 / 160 km/h)
- Tolérance
- Distance de détection
- Sens : les deux / aller / retour

Le radar est placé à la **position et orientation exactes** du joueur, puis sauvegardé en MySQL. Rechargement automatique après restart.

### Détection

- Uniquement le **conducteur**
- Uniquement les véhicules **devant** le radar
- Respect du **sens** configuré
- Flash à partir de `limite + tolérance + 1`

**Exemple :** limite 110, tolérance 5 → flash dès **116 km/h**.  
Vitesse retenue = vitesse réelle − tolérance (ex. 126 → **121**).

### Métiers autorisés

Aucune amende pour :

- `police`, `sheriff`, `fib`, `ambulance`, `government`

Notification : **Véhicule autorisé** (vert).

### Amendes (compte banque ESX)

| Excès (km/h) | Montant |
|--------------|---------|
| < 20         | 150 $   |
| 20 – 50      | 350 $   |
| > 50         | 750 $   |

### Effets

- Flash blanc
- Son appareil photo
- Léger shake caméra
- Notification style 911 (titre rouge, route jaune, plaque bleue, vitesse retenue rose, autorisé vert)

---

## Configuration (`config.lua`)

```lua
Config.ShowBlips = false
Config.Tolerance = 5
Config.CameraFlash = true
Config.CameraSound = true
Config.DefaultFine = 150

Config.AllowedJobs = {
    'police',
    'ambulance',
    'sheriff',
    'fib',
    'government',
}
```

Autres options utiles : `Config.Fines`, `Config.SpeedLimits`, `Config.RadarProp`, `Config.AdminGroups`, `Config.IdleWait`, etc.

---

## Tables SQL

### `radar_list`

Tous les radars (position, heading, limite, tolérance, sens, enabled…).

### `radar_flashes`

Chaque flash : identifier, nom, plaque, modèle, position, radar, route, vitesses, limitation, amende, date/heure.

---

## Performance

| Situation                         | Comportement        |
|-----------------------------------|---------------------|
| Hors véhicule / loin des radars   | `Wait(1500)` ≈ 0.00 ms |
| Radar à proximité                 | `Wait(100)`         |
| Dans la zone de détection         | `Wait(50)` ≤ 0.02 ms |

Seul le véhicule du joueur local est testé (pas de scan global d’entités).

---

## Sécurité

- Permissions admin vérifiées **serveur**
- Montant d’amende recalculé **serveur**
- Validation distance joueur ↔ radar
- Rate-limit anti-spam flash
- Payload création validé (limites, sens, coords)

---

## Structure

```
esx_radar/
├── fxmanifest.lua
├── config.lua
├── sql.sql
├── README.md
├── shared/
│   └── utils.lua
├── client/
│   ├── main.lua
│   ├── menu.lua
│   └── effects.lua
└── server/
    ├── main.lua
    └── database.lua
```

---

## Licence

Libre d’utilisation sur votre serveur FiveM.
