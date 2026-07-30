# Thème visuel ox_inventory

Remplace **uniquement l’UI** d’ox_inventory (pas une nouvelle ressource).

## Couleurs

| Bouton | Couleur |
|--------|---------|
| Information | Bleu |
| **Utiliser** | **Vert** |
| Échanger | Teal |
| **Fermer** | **Rouge** |

## Installation (2 minutes)

1. **Sauvegarde** ton dossier actuel :
   ```
   resources/[ox]/ox_inventory/web/build
   ```
2. **Remplace** tout le contenu de `ox_inventory/web/build/` par celui de :
   ```
   ox_inventory_ui/web/build/
   ```
3. (FR) Copie aussi la locale :
   ```
   ox_inventory_ui/locales/fr.json  →  ox_inventory/locales/fr.json
   ```
   (Utiliser / Échanger / Fermer / Information)
4. Redémarre la ressource :
   ```
   ensure ox_inventory
   ```
   ou `restart ox_inventory`

Aucune autre ressource à `ensure`. C’est toujours **ox_inventory** normal, avec le nouveau look.

## Contenu du dossier

```
ox_inventory_ui/
├── web/build/          ← à coller dans ox_inventory/web/build/
├── locales/fr.json     ← labels FR
├── src/patches/        ← sources (si tu rebuild l’UI plus tard)
└── README.md
```

## Rebuild (optionnel)

Si tu modifies le thème plus tard :

1. Clone ox_inventory, copie `src/patches/*` aux bons endroits dans `web/`
2. Dans `web/` : `bun install && bun run build`
3. Recopie `web/build/` dans ta ressource ox_inventory
