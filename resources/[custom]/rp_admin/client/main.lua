local spectating = false
local frozen = false

RegisterNetEvent('rp_admin:client:freeze', function(state)
    frozen = state and true or false
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, frozen)
end)

RegisterNetEvent('rp_admin:client:revive', function(healOnly)
    local ped = PlayerPedId()
    if not healOnly then
        NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, false)
        SetEntityInvincible(ped, false)
        ClearPedBloodDamage(ped)
        if GetResourceState('qbx_medical') == 'started' then
            TriggerEvent('qbx_medical:client:playerRevived')
        end
    end
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
end)

RegisterNetEvent('rp_admin:client:spawnVehicle', function(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then return end
    lib.requestModel(hash)
    local coords = GetEntityCoords(cache.ped)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, GetEntityHeading(cache.ped), true, false)
    SetPedIntoVehicle(cache.ped, veh, -1)
    SetVehicleNumberPlateText(veh, 'ADMIN')
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('rp_admin:client:deleteVehicle', function()
    local veh = cache.vehicle or lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0)
    if veh and DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
end)

RegisterNetEvent('rp_admin:client:spectate', function(target)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
    if targetPed == 0 then return end
    spectating = not spectating
    local me = PlayerPedId()
    if spectating then
        NetworkSetInSpectatorMode(true, targetPed)
    else
        NetworkSetInSpectatorMode(false, me)
    end
end)

local function openAdmin()
    local allowed = lib.callback.await('rp_admin:isAdmin', false)
    if not allowed then
        lib.notify({ description = L('no_perm'), type = 'error' })
        return
    end
    local players = lib.callback.await('rp_admin:getPlayers', false) or {}
    local playerOpts = {}
    for _, p in ipairs(players) do
        playerOpts[#playerOpts + 1] = {
            title = ('[%s] %s'):format(p.id, p.name),
            description = p.citizenid,
            arrow = true,
            onSelect = function()
                lib.registerContext({
                    id = 'rp_admin_player',
                    title = p.name,
                    menu = 'rp_admin_main',
                    options = {
                        { title = 'Goto', onSelect = function() TriggerServerEvent('rp_admin:server:action', 'teleport', { target = p.id }) end },
                        { title = 'Bring', onSelect = function() TriggerServerEvent('rp_admin:server:action', 'bring', { target = p.id }) end },
                        { title = 'Revive', onSelect = function() TriggerServerEvent('rp_admin:server:action', 'revive', { target = p.id }) end },
                        { title = 'Heal', onSelect = function() TriggerServerEvent('rp_admin:server:action', 'heal', { target = p.id }) end },
                        { title = 'Freeze', onSelect = function() TriggerServerEvent('rp_admin:server:action', 'freeze', { target = p.id }) end },
                        { title = 'Spectate', onSelect = function() TriggerServerEvent('rp_admin:server:action', 'spectate', { target = p.id }) end },
                        {
                            title = 'Kick',
                            onSelect = function()
                                local input = lib.inputDialog('Kick', { { type = 'input', label = 'Raison', required = true } })
                                if input then TriggerServerEvent('rp_admin:server:action', 'kick', { target = p.id, reason = input[1] }) end
                            end
                        },
                        {
                            title = 'Ban',
                            onSelect = function()
                                local input = lib.inputDialog('Ban', { { type = 'input', label = 'Raison', required = true } })
                                if input then TriggerServerEvent('rp_admin:server:action', 'ban', { target = p.id, reason = input[1], expire = 0 }) end
                            end
                        },
                        {
                            title = 'Give money',
                            onSelect = function()
                                local input = lib.inputDialog('Argent', {
                                    { type = 'select', label = 'Type', options = { { value = 'cash', label = 'Cash' }, { value = 'bank', label = 'Banque' } } },
                                    { type = 'number', label = 'Montant', required = true },
                                })
                                if input then
                                    TriggerServerEvent('rp_admin:server:action', 'givemoney', {
                                        target = p.id, moneyType = input[1], amount = input[2]
                                    })
                                end
                            end
                        },
                        {
                            title = 'Give item',
                            onSelect = function()
                                local input = lib.inputDialog('Item', {
                                    { type = 'input', label = 'Nom item', required = true },
                                    { type = 'number', label = 'Quantité', default = 1 },
                                })
                                if input then
                                    TriggerServerEvent('rp_admin:server:action', 'giveitem', {
                                        target = p.id, item = input[1], count = input[2]
                                    })
                                end
                            end
                        },
                    }
                })
                lib.showContext('rp_admin_player')
            end,
        }
    end

    lib.registerContext({
        id = 'rp_admin_main',
        title = 'Administration',
        options = {
            { title = 'Joueurs', description = #players .. ' en ligne', arrow = true, onSelect = function()
                lib.registerContext({ id = 'rp_admin_players', title = 'Joueurs', menu = 'rp_admin_main', options = playerOpts })
                lib.showContext('rp_admin_players')
            end },
            {
                title = 'Spawn véhicule',
                onSelect = function()
                    local input = lib.inputDialog('Véhicule', { { type = 'input', label = 'Modèle', required = true } })
                    if input then TriggerServerEvent('rp_admin:server:action', 'spawnvehicle', { model = input[1] }) end
                end
            },
            {
                title = 'Supprimer véhicule',
                onSelect = function() TriggerServerEvent('rp_admin:server:action', 'deletevehicle', {}) end
            },
            {
                title = 'Self revive',
                onSelect = function() TriggerServerEvent('rp_admin:server:action', 'revive', { target = cache.serverId }) end
            },
        }
    })
    lib.showContext('rp_admin_main')
end

RegisterCommand(Config.OpenCommand, openAdmin, false)
