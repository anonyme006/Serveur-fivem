# PHASES — suivi

| Phase | Statut | Notes |
|-------|--------|-------|
| 1 Analyse | OK | Dépôt vide → architecture Qbox + couche `rp_*` |
| 2 Dépendances | OK | `scripts/install-dependencies.sh` + configs |
| 3 Core joueur | OK | Délégué à `qbx_core` + bridge `rp_core` |
| 4 Jobs / entreprises | OK | `rp_jobs` + `rp_business` + jobs FR |
| 5 Banque | OK | Bridge Renewed-Banking via `rp_core` |
| 6 Inventaire | OK | `ox_inventory` (non dupliqué) + stashes business |
| 7 Véhicules / garages | OK | `rp_garages` optionnel + tables qbx |
| 8 Immobilier | OK | Architecture sur `qbx_properties` |
| 9 Téléphone | OK | `rp_phone_bridge` |
| 10 Admin | OK | `rp_admin` ACE |
| 11 HUD / UI | OK | `rp_hud` + `rp_menu` + NUI garages |
| 12 Sécurité | OK | Rate-limit, ACE, prepared SQL |
| 13 Tests | Doc | Voir `docs/TESTS.md` — à valider en runtime FXServer |
