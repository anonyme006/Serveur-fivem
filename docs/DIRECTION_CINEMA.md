# Direction produit — niveau Reroll / 21 Jump Click

## Choix validés

| Point | Décision |
|-------|----------|
| Univers | **1A — RP cinéma / streamer** (immersion, lore, scènes, peu de HUD invasif) |
| Priorité | **2A + 2C — HUD/menus** puis **jobs légaux** en profondeur |
| Budget | **3B — scripts payants premium OK** |

## Ce qu’on arrête

- Previews marketing génériques
- Jobs = simple point duty + coffre
- Empilement de stubs `rp_*` sans boucle de jeu
- UI “template IA” (violet, cards partout, HUD surchargé)

## Ce qu’on vise

- Identité visuelle **unique** (configurable), HUD **cinéma** (discret)
- Menu joueur **NUI soigné** (pas seulement context ox_lib)
- Jobs légaux avec **vraie boucle** : service, craft, clients, caisse, salaire, animations
- Stack premium **curatée** (pas 300 scripts)

## Stack premium recommandée (à acheter / installer sur HelloServ)

| Besoin | Choix recommandé | Notes |
|--------|------------------|-------|
| Framework | **Qbox** + ox_* | Gardé |
| Téléphone | **LB Phone** | Remplace NPWD côté immersion streamer |
| Banque | **Renewed-Banking** | Déjà dans recette Qbox |
| Apparence | **illenium-appearance** | Déjà |
| Voice | **pma-voice** | Déjà |
| Emotes | **scully_emotemenu** ou RPEmotes | Immersion |
| Housing | **qs-housing** ou `qbx_properties` + polish | Selon budget |
| Tuning / mécano | Wasabi / JG / custom | Plus tard |
| Anti-cheat | FiveGuard / WG | Prod |

Les scripts `rp_*` restent la **couche identité + jobs custom** du serveur, branchés sur cette stack.

## Marque temporaire

Nom de travail : **Cinéma LS** (modifiable dans `rp_core/config.lua` → `Config.Brand`).

## Roadmap immédiate

1. Design system + HUD cinéma  
2. Menu joueur NUI  
3. Burgershot deep (modèle pour UwU / autres jobs légaux)  
4. Intégration LB Phone via `rp_phone_bridge`  
5. Ensuite : UwU, Taxi deep, Mécano polish  

## Critères qualité (definition of done)

- Idle client job/HUD ≈ 0.00–0.02 ms hors interaction  
- Aucune boucle inutile  
- Validation 100 % serveur  
- UI cohérente (mêmes fonts, couleurs, motion)  
- Job jouable 15–20 min sans “vide RP”  
