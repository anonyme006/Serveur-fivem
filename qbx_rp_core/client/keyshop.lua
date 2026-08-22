if not Config.KeyShop or not Config.KeyShop.enabled then return end

local peds = {}
local blips = {}

local function openShop()
    local vehicles = lib.callback.await('qbx_rp_core:keyshop:list', false) or {}
    local price = tonumber(Config.KeyShop.price) or 100
    local options = {}

    if #vehicles == 0 then
        options[#options + 1] = {
            title = Core.Locale('keyshop_no_vehicles'),
            disabled = true,
        }
    else
        for _, v in ipairs(vehicles) do
            options[#options + 1] = {
                title = Core.Locale('wallet_key_vehicle', v.plate),
                description = Core.Locale('keyshop_option', price, v.keys or 0, Config.KeyShop.maxKeysPerPlate or 3),
                icon = 'key',
                onSelect = function()
                    local ok, msg, a, b = lib.callback.await('qbx_rp_core:keyshop:buy', false, v.plate)
                    if ok then
                        Core.Notify(Core.Locale('keyshop_bought', a or v.plate, b or price), 'success')
                    else
                        if msg == 'keyshop_max' then
                            Core.Notify(Core.Locale('keyshop_max', a or Config.KeyShop.maxKeysPerPlate), 'error')
                        elseif msg == 'keyshop_inventory_full' then
                            Core.Notify(Core.Locale('keyshop_inventory_full'), 'error')
                        else
                            Core.Notify(Core.Locale(msg or 'cover_busy'), 'error')
                        end
                    end
                end,
            }
        end
    end

    lib.registerContext({
        id = 'qbx_rp_core_keyshop',
        title = Config.KeyShop.label or Core.Locale('keyshop_title'),
        options = options,
    })
    lib.showContext('qbx_rp_core_keyshop')
end

local function spawnPed(loc, index)
    if not loc.ped or loc.ped == '' then return end
    local hash = type(loc.ped) == 'number' and loc.ped or joaat(loc.ped)
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(hash) then return end

    local ped = CreatePed(0, hash, loc.coords.x, loc.coords.y, loc.coords.z - 1.0, loc.heading or 0.0, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(hash)
    peds[index] = ped
end

CreateThread(function()
    for i, loc in ipairs(Config.KeyShop.locations or {}) do
        if Config.KeyShop.blip and Config.KeyShop.blip.enabled then
            local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, Config.KeyShop.blip.sprite or 186)
            SetBlipColour(blip, Config.KeyShop.blip.color or 5)
            SetBlipScale(blip, Config.KeyShop.blip.scale or 0.75)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(Config.KeyShop.label or 'Serrurier')
            EndTextCommandSetBlipName(blip)
            blips[i] = blip
        end
        spawnPed(loc, i)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        for _, loc in ipairs(Config.KeyShop.locations or {}) do
            local dist = #(pcoords - loc.coords)
            if dist < 20.0 then
                sleep = 0
                DrawMarker(2, loc.coords.x, loc.coords.y, loc.coords.z + 0.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.25, 0.25, 0.25, 212, 163, 92, 180, false, true, 2, false, nil, nil, false)
                if dist < 2.2 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(Core.Locale('keyshop_help'))
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then
                        openShop()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterCommand('serrurier', function()
    openShop()
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in pairs(peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, blip in pairs(blips) do
        if blip then RemoveBlip(blip) end
    end
end)
