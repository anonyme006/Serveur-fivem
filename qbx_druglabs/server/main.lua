local function seedDefaultLabs()
    if not Config.SeedLabsOnStart then return end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM drug_labs') or 0
    if count > 0 then return end

    print('[qbx_druglabs] Seeding default laboratories...')
    for identifier, def in pairs(Config.DefaultLabs) do
        Repository.CreateLab({
            identifier = identifier,
            type = def.type,
            label = def.label,
            purchaseMode = def.purchaseMode or 'purchase',
            purchasePrice = def.purchasePrice or 0,
            rentPrice = def.rentPrice or 0,
            sellPercentage = Config.Sell.sellPercentage,
            locked = Config.Security.defaultLocked,
            entrance = DrugLabs.SerializeCoords(def.entrance),
            interior = {
                entrance = DrugLabs.SerializeCoords(def.interior.entrance),
                exit = DrugLabs.SerializeCoords(def.interior.exit),
            },
            stash = {
                coords = DrugLabs.SerializeCoords(def.stash.coords),
                slots = def.stash.slots,
                weight = def.stash.weight,
            },
            stations = (function()
                local out = {}
                for key, station in pairs(def.stations or {}) do
                    out[key] = {
                        coords = DrugLabs.SerializeCoords(station.coords),
                        heading = station.heading or 0.0,
                        recipeGroup = station.recipeGroup,
                    }
                end
                return out
            end)(),
            blip = def.blip or {},
        })
    end
end

local function syncAll(target)
    local payload = Repository.SerializeAllPublic()
    if target then
        TriggerClientEvent(DrugLabs.Events.client.syncLabs, target, payload)
    else
        TriggerClientEvent(DrugLabs.Events.client.syncLabs, -1, payload)
    end
end

CreateThread(function()
    Wait(500)
    MySQL.query.await([[
        SELECT 1 FROM drug_labs LIMIT 1
    ]]) -- verify table exists; install.sql must be imported

    local ok, err = pcall(function()
        seedDefaultLabs()
        Repository.LoadAll()
        Stash.EnsureAll()
        syncAll()
    end)

    if not ok then
        print('[qbx_druglabs] Startup failed. Did you import sql/install.sql?')
        print(err)
        return
    end

    print(('[qbx_druglabs] Ready — %s laboratories loaded.'):format(
        (function()
            local n = 0
            for _ in pairs(Repository.GetAll()) do n += 1 end
            return n
        end)()
    ))
end)

AddEventHandler('playerJoining', function()
    -- delayed sync after player loads character via callback
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    SetTimeout(1500, function()
        if GetPlayerPing(src) > 0 then
            syncAll(src)
            -- safety: ensure not stuck in lab bucket
            if GetPlayerRoutingBucket(src) >= Config.Labs.bucketBase then
                local stateLab = Player(src).state.druglabId
                if not stateLab then
                    Buckets.Leave(src)
                end
            end
        end
    end)
end)

RegisterNetEvent('qbx_core:server:playerLoggedOut', function()
    local src = source
    if Production.GetActive(src) then
        Production.Cancel(src)
    end
    if Buckets.GetPlayerLab(src) then
        Buckets.Leave(src)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Buckets.GetPlayerLab(src) then
        Buckets.Leave(src)
    end
end)

-- Export helpers for other resources
exports('GetLab', function(labId)
    return Repository.SerializeLabPublic(Repository.Get(labId), false)
end)

exports('GetPlayerLab', function(source)
    return Buckets.GetPlayerLab(source)
end)

exports('IsLabSealed', function(labId)
    local lab = Repository.Get(labId)
    return lab and lab.sealed or false
end)
