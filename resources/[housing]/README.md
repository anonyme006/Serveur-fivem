# Architecture immobilier

Qbox fournit déjà **`qbx_properties`** (appartements / maisons / coffres / clés).

## Stratégie

| Besoin | Solution |
|--------|----------|
| Propriétés de base | `qbx_properties` (ne pas dupliquer) |
| Extensions FR | Ajouter configs locales + ponts `rp_*` |
| Garages liés | `qbx_garages` ou `rp_garages` |

## Emplacement

Placez vos overlays / configs custom dans :

```text
resources/[housing]/
```

Exemple d’extension future `rp_housing` :

- locations FR supplémentaires
- contrats de location
- colocataires via metadata
- intégration factures `rp_billing`

## SQL

Les tables propriétés sont gérées par `qbx_properties` après installation de la recette Qbox.
Ne créez pas de tables concurrentes sans migration.
