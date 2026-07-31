local open = false

local function setNui(state)
    open = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close', spawns = Config.Spawns })
end

local function teleportTo(spawn)
    local c = spawn.coords
    DoScreenFadeOut(400)
    Wait(450)
    SetEntityCoords(cache.ped, c.x, c.y, c.z, false, false, false, false)
    SetEntityHeading(cache.ped, c.w)
    DoScreenFadeIn(600)
end

RegisterNetEvent('vibe_spawnselector:client:open', function()
    setNui(true)
end)

RegisterNUICallback('selectSpawn', function(data, cb)
    local id = data and data.id
    for _, spawn in ipairs(Config.Spawns) do
        if spawn.id == id then
            setNui(false)
            teleportTo(spawn)
            TriggerServerEvent('vibe_spawnselector:server:selected', id)
            cb({ ok = true })
            return
        end
    end
    cb({ ok = false })
end)

RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb({ ok = true })
end)

-- Ouvre le sélecteur après chargement perso (à brancher sur ton flux Qbox)
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(1500)
    setNui(true)
end)
