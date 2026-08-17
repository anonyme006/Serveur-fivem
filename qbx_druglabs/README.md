# qbx_druglabs

Possessable, multi-instance drug laboratory system built natively for **Qbox / QBX**.

Players can buy or rent labs, manage members and access codes, run multi-stage production (weed / cocaine / meth / acid), and police can raid or seal laboratories. All sensitive logic is server-authoritative.

## Dependencies

- [qbx_core](https://github.com/Qbox-Project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)
- OneSync

Optional:
- ps-dispatch / cd_dispatch / qs-dispatch / rcore_dispatch
- Qbox gangs (player gang ownership)

## Installation

1. Copy `qbx_druglabs` into your resources folder.
2. Import `sql/install.sql` into your database.
3. Merge item definitions from `install/items.lua` into `ox_inventory/data/items.lua`.
4. Add to `server.cfg`:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure qbx_core
ensure qbx_druglabs
```

5. Restart the server (or `ensure qbx_druglabs` after SQL + items).

### NUI rebuild (optional)

The furnace minigame is already built in `web/dist`.

```bash
cd qbx_druglabs/web
npm install
npm run build
```

## Configuration

Main files:

| File | Purpose |
|------|---------|
| `config/shared.lua` | Global settings (admin, rental, police, meth, weed, rate limits, logs) |
| `config/labs.lua` | Lab types + default seed labs |
| `config/recipes.lua` | Data-driven production recipes |
| `config/server.lua` | Server secrets (code hash pepper) |

Important options:

```lua
Config.Interaction = 'ox_target' -- or 'textui'
Config.Dispatch = 'none'         -- ps-dispatch | cd_dispatch | qs-dispatch | rcore_dispatch | custom | none
Config.Admin.command = 'druglabcreator'
Config.Admin.manageCommand = 'druglabs'
Config.Admin.permission = 'admin'
Config.Admin.ace = 'qbx_druglabs.admin'
Config.Labs.maxOwnedPerPlayer = 2
Config.Rental.duration = 7 * 24 * 60 * 60
Config.Sell.sellPercentage = 0.65
```

Grant admin access with ACE:

```cfg
add_ace group.admin qbx_druglabs.admin allow
```

Or via Qbox permission group `admin`.

## Commands

| Command | Access | Description |
|---------|--------|-------------|
| `/druglabcreator` | Admin | Create a lab in-game (positions from current coords) |
| `/druglabs` | Admin | List/manage all labs (teleport, lock, seal, reset, delete) |

## Features

### Ownership
- Purchase / rent / sell to server / transfer to player
- Player or gang ownership
- Max labs per player
- Rental expiry + grace period + optional auto-renew

### Access & security
- Lock / unlock
- Access codes (hashed server-side, never sent to clients)
- Code brute-force cooldown
- Police seal (blocks members + production)
- Routing buckets per lab (deterministic: `bucketBase + labId`)

### Production
- Data-driven recipes per lab type
- ox_lib progress + skillChecks
- Meth furnace NUI temperature minigame
- Respirator mask hazard (damage / FX without mask)
- Quality metadata + batch codes
- Anti-dupe production tokens / station locks
- Ingredients removed on start (no disconnect refund)

### Weed
- Timestamp-based growth (no per-plant Wait loops)
- Water / nutrients / spray / harvest
- Yield scales with health/growth

### Police
- Raid / force entry
- Seal / unseal
- Stash search when authorized
- Abstract dispatch bridge

### Admin
- Live create labs without restart
- Manage / delete / reset ownership
- All admin actions logged

## Adding a lab type

1. Add an entry in `Config.LabTypes`.
2. Add recipes in `Config.Recipes['your_type']`.
3. Create labs via `/druglabcreator` or SQL/seed config.

## Adding a recipe

Edit `config/recipes.lua`:

```lua
{
    id = 'cook',
    label = 'Cook mixture',
    station = 'mix',
    duration = 15000,
    requiredItems = { ammonia = 1 },
    rewards = { meth_mixture = 1 },
    skillCheck = { 'easy', 'medium' },
    dispatchChance = 10,
    createBatch = true,
}
```

Station `recipeGroup` on the lab must match `recipe.station`.

## Dispatch

Set `Config.Dispatch` and ensure the resource is started. The core never calls a dispatch resource directly — only `Bridge.SendPoliceAlert` / `SendPoliceAlert`.

For custom integrations:

```lua
Config.Dispatch = 'custom'
-- listen to event: qbx_druglabs:server:customDispatch
```

## Gang ownership

Admins can assign a lab to a gang (`ownership_type = 'gang'`). Permissions resolve from `Config.GangGradePermissions` by grade level.

## Exports

```lua
exports.qbx_druglabs:GetLab(labId)
exports.qbx_druglabs:GetPlayerLab(source)
exports.qbx_druglabs:IsLabSealed(labId)
```

## Security model

- Client never decides rewards, prices, ownership, or permissions
- Recipes are always read from server config
- Production uses one-time tokens
- Concurrent purchase uses SQL ownership claim
- Concurrent harvest uses atomic `harvested` update
- Rate limits on entry / purchase / production / codes / admin
- Central `LogAction` for Discord/DB/console

## Troubleshooting

| Issue | Check |
|-------|-------|
| Resource fails on start | Import `sql/install.sql` |
| Cannot craft items | Merge `install/items.lua` into ox_inventory |
| Admin command denied | ACE `qbx_druglabs.admin` or Qbox `admin` permission |
| Stuck in interior after crash | Rejoin — bucket is cleared on unload/drop; or restart resource |
| No police alert | Set `Config.Dispatch` and start the dispatch resource |
| Stash empty/shared | Stash id is `druglab_<id>_storage` — unique per lab |
| Furnace UI blank | Rebuild `web/` or ensure `web/dist` is present |

## Architecture

```
qbx_druglabs/
├── bridge/          # adapters (player, inventory, gangs, dispatch, interaction)
├── client/          # targets, interiors, production, plants, police, admin, nui
├── server/          # repository, access, ownership, production, rentals, police
├── config/          # shared + labs + recipes + server
├── shared/          # constants + utils
├── web/             # furnace minigame (React + Vite)
├── sql/install.sql
└── install/items.lua
```

Idle cost stays low: ox_target zones, event-driven sync, timestamp plant growth, no `Wait(0)` loops except focused NUI escape handling.
