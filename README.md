# Serveur-fivem

Ressources FiveM pour serveur Qbox.

## Ressources

- [`qbx_concessionnaire`](./qbx_concessionnaire) — Concessionnaire véhicules (ox_lib)
- [`qbx_garage`](./qbx_garage) — Garage / fourrière véhicules (ox_lib)

## SQL Qbox

Importer une seule fois :

```bash
mysql -u USER -p DATABASE < sql/qbox_vehicles.sql
```

Crée la table `player_vehicles` utilisée par le concessionnaire et le garage.
