# vibe_neon_mecano

**Neon Mechanic** — système complet mécano pour serveur Qbox / Vibe RP.

## Fonctionnalités

- **Réparations réalistes** : diagnostic moteur / carrosserie / réservoir / pneus, interventions ciblées ou révision complète
- **Custom séparé** : point dédié (Benny's) pour néons, couleurs, vitres teintées et jantes
- **Bipeur** : alertes visuelles + sonores (`F6` ou `/bipeur`) pour les appels de dépannage
- **Missions dépannage** : pannes générées automatiquement, véhicule NPC sur place, gains pour la société + bonus employé
- **Garage de service** : flatbed, dépanneuse, van d'intervention

## Commandes

| Commande | Description |
|----------|-------------|
| `/neonmecano` ou `/mecano` | Menu principal mécano |
| `/bipeur` ou `F6` | Ouvrir le bipeur |

## Jobs requis

- `mechanic` (Neon Mechanic)
- `bennys`

Les mécanos doivent être **en service** (`/duty`) pour recevoir les missions.

## Économie

- Réparations et custom : 85 % → compte société `mechanic` (Renewed-Banking), 15 % → employé
- Missions dépannage : 70 % société + bonus fixe employé (150–350 $)

## Dépendances

`ox_lib`, `ox_target`, `qbx_core`, `vibe_api`, `Renewed-Banking`

## Configuration

Tout est dans `config.lua` : zones atelier, point custom, tarifs, intervalle missions, véhicules de service.
