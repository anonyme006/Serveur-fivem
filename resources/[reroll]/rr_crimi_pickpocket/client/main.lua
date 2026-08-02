local last = 0

local function canPick(ped)
    if not DoesEntityExist(ped) or IsPedAPlayer(ped) or IsPedDeadOrDying(ped, true) then return false end
    if IsPedInAnyVehicle(ped, false) then return false end
    if Config.BlacklistedPeds[GetEntityModel(ped)] then return false end
    return true
end

CreateThread(function()
    exports.ox_target:addGlobalPed({
        {
            name = 'rr_pickpocket',
            icon = 'fa-solid fa-user-ninja',
            label = 'Pickpocket',
            distance = 1.5,
            canInteract = function(entity)
                return canPick(entity)
            end,
            onSelect = function(data)
                if GetGameTimer() - last < Config.Cooldown * 1000 then
                    exports.rr_api:Notify('Pickpocket', 'Trop tôt.', 'error')
                    return
                end
                if lib.progressCircle({
                    duration = Config.Duration,
                    label = 'Fouilles discrètes...',
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, combat = true },
                    anim = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search' },
                }) then
                    last = GetGameTimer()
                    local coords = GetEntityCoords(cache.ped)
                    TriggerServerEvent('rr_crimi_pickpocket:server:steal', { x = coords.x, y = coords.y, z = coords.z })
                end
            end,
        },
    })
end)
