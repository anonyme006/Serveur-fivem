# Audit environnement — Portail joueur Qbox (Serenity V)

Date : 2026-10-10  
Branche de référence : `main` (vide) + branches agents `cursor/qbox-reroll-server-f159`, `cursor/qbox-base-complete-dd4d`

## Constat d’environnement

| Élément | État |
|---------|------|
| Repo `main` | Quasi vide (`README.md` uniquement) |
| Serveur FiveM local | Absent de ce workspace |
| Base MySQL `serenityv` | **Non accessible** depuis cet environnement (pas de credentials, pas de MariaDB local) |
| Stack cible documentée | Qbox + Ox + Renewed-Banking (branches reroll / scaffold) |

**Règle appliquée** : aucune table Qbox existante n’est remplacée. Les migrations du portail ne créent que des tables `portal_*`. Un adaptateur découvre au runtime les tables/colonnes réellement présentes.

## Ressources Qbox / Ox identifiées (branches serveur)

- `qbx_core`, `qbx_vehicles`, `qbx_spawn` (cible)
- `oxmysql`, `ox_lib`, `ox_inventory`, `ox_target`
- `rcore_clothing` (payant, non embarqué)
- Banque autorité : **Renewed-Banking** (`bank_accounts_new`, `player_transactions`)
- Factures custom éventuelles : `rp_invoices` (branche `qbox-base-complete`)

## Schéma Qbox attendu (à valider sur `serenityv`)

### `players` (qbx_core) — personnages

| Colonne | Usage portail |
|---------|---------------|
| `citizenid` | Identifiant stable personnage |
| `cid` | Slot personnage |
| `license` | Compte FiveM (liaison multi-persos) |
| `userId` | Compte Qbox users (si présent) |
| `name` | Nom Steam/affichage |
| `money` | JSON `{ cash, bank, crypto }` |
| `charinfo` | JSON `{ firstname, lastname, ... }` |
| `job` / `gang` | JSON |
| `metadata` | JSON (playtime éventuel, licences…) |
| `last_logged_out` / `last_updated` | Activité |

### `users` (qbx_core récent, optionnel)

Liaison `discord` ↔ `license` côté framework. Utilisée si présente, jamais requise.

### `player_vehicles` (qbx_vehicles)

| Colonne | Usage |
|---------|-------|
| `citizenid`, `plate`, `vehicle`, `hash` | Identité véhicule |
| `garage`, `state` | Localisation / statut (0 sorti, 1 rangé, 2 fourrière — convention Qbox) |
| `fuel`, `engine`, `body` | État |
| `mods`, `status`, `coords` | Détail |

**Non utilisé sans vérification** : `owned_vehicles` (ESX).

### Banque — Renewed-Banking

| Table | Rôle |
|-------|------|
| `players.money` JSON | Solde cash/bank personnel (autorité Qbox) |
| `player_transactions` | Historique JSON par `citizenid` — **peut être absente** |
| `bank_accounts_new` | Comptes société / partagés |

Si `player_transactions` est absente ou corrompue : le portail affiche les soldes depuis `players.money` et un message clair ; **aucune table concurrente de transactions n’est inventée**.

### Factures (optionnel)

- `rp_invoices` si détectée
- Sinon section factures masquée / « non disponible »

## Tables portail uniquement (`portal_*`)

Créées par `sql/00_portal_tables.sql` :

- sessions, comptes Discord, liaisons license, codes de liaison
- playtime sessions (anti double-comptage)
- sync logs, notifications, activités
- tickets, dossiers admin, audit log, rôles

## Risques / manques à valider sur la vraie DB

1. Confirmer existence et colonnes de `players`, `player_vehicles`
2. Confirmer présence de Renewed-Banking vs autre banque custom
3. Confirmer si `player_transactions` est utilisable
4. Confirmer où le playtime est stocké (`metadata.playtime` vs tracking portail)
5. Credentials MySQL `serenityv` uniquement côté serveur web (jamais client / jamais Internet)

## Décisions d’architecture

1. Site Next.js lit MySQL en serveur uniquement
2. Ressource `qbx_player_portal` pousse sync HTTPS authentifiée (HMAC + timestamp anti-rejeu)
3. Liaison Discord ↔ personnage via **code OTP in-game** (jamais saisie libre de `citizenid` tiers)
4. Isolation stricte par `citizenid` sélectionné + ownership via `license` liée au Discord
