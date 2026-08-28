# ox_inventory — Interface Qbox + rcore_clothing

Modification **drop-in** de l'UI ox_inventory pour serveurs **Qbox** avec **rcore_clothing**.

Conserve **100 %** du fonctionnement natif d'ox_inventory (slots, drag & drop, callbacks NUI, exports, events).

## Analyse & architecture

### Fichiers ox_inventory concernés

| Fichier | Action |
|---------|--------|
| `web/build/*` | **Remplacé** par notre build React |
| `modules/qbox_ui/*` | **Ajouté** (config + client Lua) |
| `client.lua` | **1 ligne** : `require 'modules.qbox_ui.client'` |
| `locales/fr.json` | Optionnel (labels FR) |

### Ce qui n'est PAS modifié

- `server.lua`, callbacks inventaire, hooks items
- Bridge Qbox existant (`modules/bridge/qbx/`)
- Système de slots, poids, métadonnées, armes
- Exports et events publics d'ox_inventory

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  NUI React (web/build)                                       │
│  ├─ PlayerStatus (faim/soif/santé/armure)                   │
│  ├─ ClothingSlots (gauche/droite)                           │
│  ├─ CharacterPreview (zone transparente + souris)           │
│  ├─ LeftInventory / RightInventory (ox_inventory natif)     │
│  └─ InventoryControl (Utiliser, Échanger, Fermer…)           │
├─────────────────────────────────────────────────────────────┤
│  modules/qbox_ui/client.lua                                  │
│  ├─ StateBag invOpen → ouverture/fermeture                  │
│  ├─ ClonePed + GivePedToPauseMenu (personnage 3D réel)      │
│  ├─ StateBags hunger/thirst (qbx_core)                      │
│  ├─ Santé/armure (GetEntityHealth / GetPedArmour)           │
│  └─ rcore_clothing (getPlayerSkin, saveCurrentSkin, CR)     │
└─────────────────────────────────────────────────────────────┘
```

### Faim / soif (Qbox)

Les valeurs sont lues depuis :

1. **State bags** `LocalPlayer.state.hunger` / `thirst` (sync qbx_core)
2. Fallback `QBX.PlayerData.metadata.hunger/thirst`

Mise à jour **événementielle** (state bags + metadata) — pas de boucle permanente.

### Vêtements (rcore_clothing)

- Affichage : lecture des **components/props** du PED actuel
- Clic sur slot équipé → retrait + `rcore_clothing:saveCurrentSkin`
- Clic sur slot vide → `rcore_clothing:openChangingRoom`
- Preview 3D : clone du PED + `exports.rcore_clothing:setPedSkin`

### Performance

- Pas de `Wait(0)` global — uniquement pendant l'aperçu 3D (requis par le frontend pause menu)
- Santé/armure : intervalle configurable (`StatusUpdateInterval`, défaut 500 ms) **uniquement inventaire ouvert**
- Faim/soif : state bag handlers uniquement

---

## Installation

### Prérequis

- ox_inventory (version récente, UI React buildée)
- ox_lib, oxmysql
- qbx_core (`setr inventory:framework "qbx"`)
- rcore_clothing (recommandé pour vêtements)

### Étapes

1. **Sauvegarde** votre `ox_inventory` actuel.

2. Copiez le module Lua :
   ```
   ox_inventory_ui/modules/qbox_ui/  →  ox_inventory/modules/qbox_ui/
   ```

3. Remplacez l'UI :
   ```
   ox_inventory_ui/web/build/*  →  ox_inventory/web/build/
   ```

4. Ajoutez dans `ox_inventory/client.lua` (après les `require` existants) :
   ```lua
   require 'modules.qbox_ui.client'
   ```

5. (Optionnel) Locale FR :
   ```
   ox_inventory_ui/locales/fr.json  →  ox_inventory/locales/fr.json
   ```

6. Redémarrez :
   ```
   ensure ox_inventory
   ```

---

## Configuration

Éditez `ox_inventory/modules/qbox_ui/config.lua` :

```lua
Config = {
    AccentColor = '#d946ef',
    ShowHunger = true,
    ShowThirst = true,
    ShowHealth = true,
    ShowArmor = true,
    ShowCharacter = true,
    EnableClothingSlots = true,
    EnableCharacterRotation = true,
    EnableCharacterZoom = true,
    CharacterBackground = 'dark',      -- 'dark' | 'transparent'
    CharacterPedSlot = 2,
    StatusUpdateInterval = 500,
}
```

---

## Contrôles personnage 3D

| Action | Contrôle |
|--------|----------|
| Rotation | Glisser la souris sur la zone personnage |
| Zoom | Molette sur la zone personnage |

---

## Rebuild UI (développeurs)

```bash
cd ox_inventory_ui/src/web
npm install --legacy-peer-deps
npm run build
cp -r build/* ../web/build/
```

Sources modifiées dans `src/web/src/` :

- `components/inventory/index.tsx` — layout
- `components/qbox/*` — stats, vêtements, preview
- `store/qboxUi.ts` — état NUI
- `index.scss` — thème glassmorphism

---

## Vérifications

- [ ] Inventaire s'ouvre / se ferme normalement
- [ ] Drag & drop, utiliser, donner, jeter
- [ ] Poids et durabilité affichés
- [ ] Faim/soif synchronisées (manger/boire)
- [ ] Santé/armure mises à jour
- [ ] Personnage 3D = apparence actuelle
- [ ] Slots vêtements + rcore_clothing
- [ ] Shops, coffres, inventaire secondaire

---

## Compatibilité mises à jour ox_inventory

- Le module Lua est **isolé** dans `modules/qbox_ui/`
- Seul `web/build` et **1 ligne** dans `client.lua` sont touchés
- En cas de MAJ ox_inventory : recopier `web/build`, vérifier que le `require` est toujours présent
