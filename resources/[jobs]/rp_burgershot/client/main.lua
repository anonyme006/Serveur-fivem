local function onDuty()
    local pd = exports.qbx_core:GetPlayerData()
    return pd and pd.job and pd.job.name == Config.Job and (not Config.RequireDuty or pd.job.onduty)
end

local function progress(label, duration, anim)
    return lib.progressCircle({
        duration = duration,
        label = label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = anim and { dict = anim.dict, clip = anim.clip } or nil,
    })
end

local function stationOption(id, station)
    return {
        name = 'bs_station_' .. id,
        icon = 'fa-solid fa-fire-burner',
        label = station.label,
        canInteract = onDuty,
        onSelect = function()
            local ok = lib.callback.await('rp_burgershot:canCraft', false, id)
            if not ok then
                lib.notify({ description = 'Ingrédients manquants.', type = 'error' })
                return
            end
            if progress(station.label .. '…', station.duration, station.anim) then
                TriggerServerEvent('rp_burgershot:server:craft', id)
            end
        end,
    }
end

CreateThread(function()
    Wait(1500)
    if GetResourceState('ox_target') ~= 'started' then
        print('[rp_burgershot] ERROR: ox_target is missing.')
        return
    end

    exports.ox_target:addSphereZone({
        coords = Config.Duty,
        radius = 1.4,
        options = {
            {
                name = 'bs_duty',
                icon = 'fa-solid fa-briefcase',
                label = 'Service — ' .. Config.Label,
                canInteract = function()
                    local pd = exports.qbx_core:GetPlayerData()
                    return pd and pd.job and pd.job.name == Config.Job
                end,
                onSelect = function()
                    lib.callback.await('rp_jobs:toggleDuty', false)
                end,
            },
            {
                name = 'bs_stash',
                icon = 'fa-solid fa-box',
                label = 'Stock — ' .. Config.Label,
                canInteract = onDuty,
                onSelect = function()
                    exports.ox_inventory:openInventory('stash', Config.Stash)
                end,
            },
        }
    })

    for id, station in pairs(Config.Stations) do
        exports.ox_target:addSphereZone({
            coords = station.coords,
            radius = 1.1,
            options = { stationOption(id, station) }
        })
    end

    exports.ox_target:addSphereZone({
        coords = Config.Counter.coords,
        radius = Config.Counter.radius,
        options = {
            {
                name = 'bs_sell',
                icon = 'fa-solid fa-cash-register',
                label = 'Encaisser un client',
                canInteract = onDuty,
                onSelect = function()
                    local options = {}
                    for _, meal in ipairs(Config.Menu) do
                        options[#options + 1] = {
                            title = meal.label,
                            description = meal.price .. ' $',
                            onSelect = function()
                                local input = lib.inputDialog('Client', {
                                    { type = 'number', label = 'ID serveur du client', required = true },
                                })
                                if not input then return end
                                TriggerServerEvent('rp_burgershot:server:sell', meal.id, tonumber(input[1]))
                            end,
                        }
                    end
                    lib.registerContext({ id = 'bs_menu_sell', title = 'Caisse Burger Shot', options = options })
                    lib.showContext('bs_menu_sell')
                end,
            },
            {
                name = 'bs_order_board',
                icon = 'fa-solid fa-clipboard-list',
                label = 'Voir le menu (client)',
                onSelect = function()
                    local options = {}
                    for _, meal in ipairs(Config.Menu) do
                        options[#options + 1] = {
                            title = meal.label,
                            description = meal.price .. ' $',
                        }
                    end
                    lib.registerContext({ id = 'bs_menu_view', title = 'Menu Burger Shot', options = options })
                    lib.showContext('bs_menu_view')
                end,
            },
        }
    })
end)
