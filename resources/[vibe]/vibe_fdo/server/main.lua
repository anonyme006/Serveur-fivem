local cuffed = {}
local escorting = {}

local function assertPolice(src)
    return exports.vibe_api:HasPoliceJob(src, true)
end

RegisterNetEvent('vibe_fdo:server:cuff', function(target)
    local src = source
    if not assertPolice(src) then return end
    if not GetPlayerPed(target) or GetPlayerPed(target) == 0 then return end
    cuffed[target] = not cuffed[target]
    TriggerClientEvent('vibe_fdo:client:setCuffed', target, cuffed[target])
    exports.vibe_api:Notify(src, 'FDO', cuffed[target] and 'Individu menotté.' or 'Menottes retirées.', 'inform')
end)

RegisterNetEvent('vibe_fdo:server:escort', function(target)
    local src = source
    if not assertPolice(src) then return end
    if escorting[src] == target then
        escorting[src] = nil
        TriggerClientEvent('vibe_fdo:client:escort', target, nil)
        exports.vibe_api:Notify(src, 'FDO', 'Escorte arrêtée.', 'inform')
        return
    end
    if not cuffed[target] then
        exports.vibe_api:Notify(src, 'FDO', 'L\'individu doit être menotté.', 'error')
        return
    end
    escorting[src] = target
    TriggerClientEvent('vibe_fdo:client:escort', target, src)
end)

RegisterNetEvent('vibe_fdo:server:search', function(target)
    local src = source
    if not assertPolice(src) then return end
    TriggerClientEvent('vibe_fdo:client:openSearch', src, target)
end)

RegisterNetEvent('vibe_fdo:server:jail', function(target, minutes, reason)
    local src = source
    if not assertPolice(src) then return end
    minutes = math.min(120, math.max(1, math.floor(tonumber(minutes) or 1)))
    TriggerClientEvent('vibe_fdo:client:jail', target, minutes)
    exports.vibe_api:Notify(src, 'FDO', 'Joueur incarcéré.', 'success')
    exports.vibe_api:Notify(target, 'Prison', tostring(reason or ''), 'error')
    if GetResourceState('vibe_dispatch') == 'started' then
        TriggerEvent('vibe_dispatch:server:log', 'jail', {
            officer = exports.vibe_api:GetCharName(src),
            target = exports.vibe_api:GetCharName(target),
            minutes = minutes,
            reason = reason,
        })
    end
end)

RegisterNetEvent('vibe_fdo:server:release', function()
    local src = source
    cuffed[src] = nil
    TriggerClientEvent('vibe_fdo:client:setCuffed', src, false)
end)

AddEventHandler('playerDropped', function()
    local src = source
    cuffed[src] = nil
    escorting[src] = nil
end)
