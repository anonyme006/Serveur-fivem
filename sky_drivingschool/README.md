# sky_drivingschool

American DMV Driving School for **Qbox** (`qbx_core`), with optional **QBCore** / **ESX** compatibility.

Fully working theory tablet, practical road tests, license issuance, points system, admin/police tools, oxmysql persistence, and NUI license card.

## Features

- Multiple configurable DMV schools (Los Santos + Paleto by default)
- License categories: Class C, Class M, Class A, CDL, Boat, Pilot
- Theory exam on a DMV-style tablet (answers graded **server-side only**)
- Practical exams with checkpoints, scoring, zone / speed / collision checks
- Vehicle-type rules for cars, bikes, trucks, boats, and aircraft
- Payment (bank / cash) via framework money APIs
- License adapters: Qbox metadata, QBCore, `esx_license`, `qbx_licenses`, or custom SQL
- Points per category on the license card (valid / suspended / revoked)
- Police & instructor console (lookup, remove/restore points, revoke, cancel stuck exams)
- Anti-cheat: rate limits, identity checks, no client-trusted pass/price/grant
- Locales: English (default) and French

## Dependencies

| Resource | Required |
|----------|----------|
| `ox_lib` | Yes |
| `oxmysql` | Yes |
| `qbx_core` (or `qb-core` / ESX) | Yes (auto-detected) |
| `ox_target` | Optional (markers fallback) |
| `ox_inventory` | Optional (license items) |
| `qbx_licenses` | Optional (preferred if started) |

## Installation

1. Copy `sky_drivingschool` into your resources folder (e.g. `resources/[standalone]/sky_drivingschool`).
2. Import SQL **or** let the resource auto-create tables on start:
   ```
   sql/install.sql
   ```
3. Add to `server.cfg`:
   ```
   ensure oxmysql
   ensure ox_lib
   ensure qbx_core
   ensure ox_target          # optional
   ensure ox_inventory       # optional
   ensure sky_drivingschool
   ```
4. (Optional) Merge items from `install/ox_items.lua` into your ox_inventory items file.
5. Edit `config.lua` for schools, prices, routes, points, and permissions.
6. Restart the server.

### ACE permissions

```
add_ace group.admin sky_drivingschool.admin allow
```

Instructor jobs / police jobs are configured in `Config.InstructorJobs` and `Config.PoliceJobs`.

## Commands

| Command | Description |
|---------|-------------|
| `/dmvcard` | Open your license card NUI |
| `/dmvadmin` | Open instructor/police console (if permitted) |

## Exports (server)

```lua
exports.sky_drivingschool:HasLicense(source, 'class_c')
exports.sky_drivingschool:GrantLicense(source, 'class_c')
exports.sky_drivingschool:RevokeLicense(source, 'class_c', 'reason', actorSource)
exports.sky_drivingschool:RemovePoints(source, 'class_c', 2, 'Speeding', actorSource)
exports.sky_drivingschool:RestorePoints(source, 'class_c', 1, 'Court order', actorSource)
exports.sky_drivingschool:ApplyInfraction(source, 'speeding', 'Radar 75 in 45', actorSource, 'class_c')
exports.sky_drivingschool:GetLicenseCard(source)
exports.sky_drivingschool:IsExamActive(source)
```

## Architecture

```
sky_drivingschool/
  config.lua              # schools, categories, scoring, points, permissions
  shared/utils.lua        # helpers + locale shim
  locales/en.lua|fr.lua
  client/                 # interactions, NUI, theory/practical, card, admin
  server/
    bridge.lua            # qbox / qbcore / esx player & money
    license_adapter.lua   # licence backends
    theory.lua|practical.lua|points.lua|payment.lua|admin.lua|anticheat.lua
  data/*.json             # theory question banks (correct answers never sent pre-grade)
  web/                    # DMV tablet NUI
  sql/install.sql
```

### Security model

- Prices, pass/fail, and license grants are decided on the server.
- Theory answer keys stay in server memory until grading.
- Practical score is accumulated from validated infractions; client cannot force a pass.
- Active exam + citizenid checks block spoofed finishes.
- Disconnect / death / destroyed vehicle fail the practical safely.

## Configuration tips

- Move `Config.Schools[*].reception`, `spawn`, and `routes` to fit your map.
- Disable a category with `enabled = false`.
- Tune `Config.PracticalScoring.deductions` and `Config.Points.infractions`.
- Set `Config.LicenseSystem = 'auto'` unless you need a forced backend.
- Theory questions live in `data/questions_*.json` — add more freely.

## Compatibility notes

- **Qbox**: writes `metadata.licences` (boolean for stock `driver`, table for extra classes) and maintains `sky_ds_licenses` for points/status.
- **qbx_licenses**: if started, grant/revoke/points also call its exports when available.
- **QBCore**: same metadata pattern via `qb-core`.
- **ESX**: uses `esx_license` events when present; points still stored in SQL.
- If a dependency is missing, the resource falls back to SQL + notifications and logs clearly.

## Testing checklist

- [ ] Theory pass / fail / timeout / quit
- [ ] Practical pass / fail / out of zone / leave vehicle / death
- [ ] Insufficient funds
- [ ] Trigger finish with forged `passed=true` (server must reject)
- [ ] Grant without theory when required (blocked)
- [ ] Disconnect mid-exam
- [ ] Resource restart cleans vehicles
- [ ] License appears in metadata / SQL without duplicates
- [ ] Points remove → suspend/revoke → restore
- [ ] NUI Esc close / reopen
- [ ] Admin cancel active exam

## Locale

Default language: American English (`Config.Locale = 'en'`).  
Set `Config.Locale = 'fr'` for French UI strings (NUI chrome stays English DMV-themed; notifications use locale files).
