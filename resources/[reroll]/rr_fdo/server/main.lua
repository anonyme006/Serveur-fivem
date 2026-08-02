local cuffed = {}
local escorting = {}

local function assertPolice(src)
    return exports.rr_api:HasPoliceJob(src, true)
end

RegisterNetEvent('rr_fdo:server:cuff', function(target)
    local src = source
    if not assertPolice(src) then return end
    if not GetPlayerPed(target) or GetPlayerPed(target) == 0 then return end
    cuffed[target] = not cuffed[target]
    TriggerClientEvent('rr_fdo:client:setCuffed', target, cuffed[target])
    exports.rr_api:Notify(src, 'FDO', cuffed[target] and 'Individu menotté.' or 'Menottes retirées.', 'inform')
end)

RegisterNetEvent('rr_fdo:server:escort', function(target)
    local src = source
    if not assertPolice(src) then return end
    if escorting[src] == target then
        escorting[src] = nil
        TriggerClientEvent('rr_fdo:client:escort', target, nil)
        exports.rr_api:Notify(src, 'FDO', 'Escorte arrêtée.', 'inform')
        return
    end
    if not cuffed[target] then
        exports.rr_api:Notify(src, 'FDO', 'L\'individu doit être menotté.', 'error')
        return
    end
    escorting[src] = target
    TriggerClientEvent('rr_fdo:client:escort', target, src)
end)

RegisterNetEvent('rr_fdo:server:search', function(target)
    local src = source
    if not assertPolice(src) then return end
    TriggerClientEvent('rr_fdo:client:openSearch', src, target)
end)

RegisterNetEvent('rr_fdo:server:jail', function(target, minutes, reason)
    local src = source
    if not assertPolice(src) then return end
    minutes = math.min(120, math.max(1, math.floor(tonumber(minutes) or 1)))
    TriggerClientEvent('rr_fdo:client:jail', target, minutes)
    exports.rr_api:Notify(src, 'FDO', 'Joueur incarcéré.', 'success')
    exports.rr_api:Notify(target, 'Prison', tostring(reason or ''), 'error')
    if GetResourceState('rr_dispatch') == 'started' then
        TriggerEvent('rr_dispatch:server:log', 'jail', {
            officer = exports.rr_api:GetCharName(src),
            target = exports.rr_api:GetCharName(target),
            minutes = minutes,
            reason = reason,
        })
    end
end)

RegisterNetEvent('rr_fdo:server:release', function()
    local src = source
    cuffed[src] = nil
    TriggerClientEvent('rr_fdo:client:setCuffed', src, false)
end)

AddEventHandler('playerDropped', function()
    local src = source
    cuffed[src] = nil
    escorting[src] = nil
end)
