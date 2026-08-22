if not Config.UsedParking.enabled then return end

local listings = {}
local slotVehicles = {} -- slot -> entity
local blip

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function clearSlot(slot)
    local ent = slotVehicles[slot]
    if ent and DoesEntityExist(ent) then
        SetEntityAsMissionEntity(ent, true, true)
        DeleteVehicle(ent)
    end
    slotVehicles[slot] = nil
end

local function spawnListing(entry)
    local slot = entry.slot
    local pos = Config.UsedParking.slots[slot]
    if not pos then return end

    clearSlot(slot)

    local props = entry.vehicle or {}
    local model = props.model
    if not model then return end

    local hash = type(model) == 'string' and joaat(model) or tonumber(model)
    if not hash or not loadModel(hash) then return end

    local veh = CreateVehicle(hash, pos.x, pos.y, pos.z, pos.w or 0.0, false, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNumberPlateText(veh, entry.plate)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleDoorsLockedForAllPlayers(veh, true)
    FreezeEntityPosition(veh, true)
    SetEntityInvincible(veh, true)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleUndriveable(veh, true)

    if props.engineHealth then SetVehicleEngineHealth(veh, props.engineHealth + 0.0) end
    if props.bodyHealth then SetVehicleBodyHealth(veh, props.bodyHealth + 0.0) end
    if props.color1 and props.color2 then
        SetVehicleColours(veh, props.color1, props.color2)
    end

    SetModelAsNoLongerNeeded(hash)
    slotVehicles[slot] = veh
end

local function syncListings(data)
    listings = data or {}
    local usedSlots = {}
    for _, entry in pairs(listings) do
        usedSlots[entry.slot] = true
        spawnListing(entry)
    end
    for slot in pairs(slotVehicles) do
        if not usedSlots[slot] then clearSlot(slot) end
    end
end

RegisterNetEvent('qbx_rp_core:used:sync', function(data)
    syncListings(data)
end)

CreateThread(function()
    Wait(2500)
    local data = lib.callback.await('qbx_rp_core:used:get', false)
    if data then syncListings(data) end

    if Config.UsedParking.blip and Config.UsedParking.blip.enabled then
        local z = Config.UsedParking.zone
        blip = AddBlipForCoord(z.coords.x, z.coords.y, z.coords.z)
        SetBlipSprite(blip, Config.UsedParking.blip.sprite or 225)
        SetBlipColour(blip, Config.UsedParking.blip.color or 46)
        SetBlipScale(blip, Config.UsedParking.blip.scale or 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.UsedParking.blip.label or 'Parking Occasions')
        EndTextCommandSetBlipName(blip)
    end
end)

local function formatMoney(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local k
    while true do
        s, k = s:gsub('^(-?%d+)(%d%d%d)', '%1 %2')
        if k == 0 then break end
    end
    return s
end

local function openListingMenu(entry)
    local myId = lib.callback.await('qbx_rp_core:getIdentifier', false)
    local isSeller = myId and entry.seller == myId
    local options = {
        {
            title = ('%s — %s$'):format(entry.plate, formatMoney(entry.price)),
            description = Core.Locale('used_commission', Config.UsedParking.commission or 0),
            icon = 'car',
            disabled = true,
        },
    }

    if isSeller then
        options[#options + 1] = {
            title = Core.Locale('used_remove'),
            icon = 'xmark',
            onSelect = function()
                local ok, msg = lib.callback.await('qbx_rp_core:used:remove', false, entry.id)
                Core.Notify(Core.Locale(msg or (ok and 'used_removed' or 'cover_busy')), ok and 'success' or 'error')
            end,
        }
    else
        options[#options + 1] = {
            title = Core.Locale('used_buy', formatMoney(entry.price)),
            icon = 'cart-shopping',
            onSelect = function()
                local ok, msg, plate, price = lib.callback.await('qbx_rp_core:used:buy', false, entry.id)
                if ok then
                    Core.Notify(Core.Locale('used_bought', plate or entry.plate, formatMoney(price or entry.price)), 'success')
                else
                    local text = msg
                    if msg == 'used_invalid_price' then
                        text = Core.Locale(msg, plate, price)
                    else
                        text = Core.Locale(msg or 'cover_busy')
                    end
                    Core.Notify(text, 'error')
                end
            end,
        }
    end

    lib.registerContext({
        id = 'qbx_rp_core_used_detail',
        title = Core.Locale('used_title'),
        options = options,
    })
    lib.showContext('qbx_rp_core_used_detail')
end

local function listNearbyVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return Core.Notify(Core.Locale('used_in_vehicle'), 'error')
    end

    local coords = GetEntityCoords(ped)
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
    if veh == 0 then
        return Core.Notify(Core.Locale('key_no_vehicle'), 'error')
    end

    local plate = Core.NormalizePlate(GetVehicleNumberPlateText(veh))
    local input = lib.inputDialog(Core.Locale('used_list'), {
        {
            type = 'number',
            label = ('Prix (%s — %s)'):format(Config.UsedParking.minPrice, Config.UsedParking.maxPrice),
            required = true,
            min = Config.UsedParking.minPrice,
            max = Config.UsedParking.maxPrice,
        },
    })
    if not input then return end

    local props = {
        model = GetEntityModel(veh),
        plate = plate,
        engineHealth = GetVehicleEngineHealth(veh),
        bodyHealth = GetVehicleBodyHealth(veh),
        fuelLevel = Core.GetFuelLevel(veh),
    }
    local c1, c2 = GetVehicleColours(veh)
    props.color1, props.color2 = c1, c2

    local ok, msg, a, b = lib.callback.await('qbx_rp_core:used:list', false, plate, input[1], props)
    if ok then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        Core.Notify(Core.Locale('used_listed', formatMoney(a or input[1])), 'success')
    else
        if msg == 'used_invalid_price' then
            Core.Notify(Core.Locale(msg, a, b), 'error')
        else
            Core.Notify(Core.Locale(msg or 'cover_busy'), 'error')
        end
    end
end

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local zone = Config.UsedParking.zone
        local inZone = #(pcoords - zone.coords) <= (zone.radius or 35.0)

        if inZone then
            sleep = 0
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Occasions  |  ~INPUT_DETONATE~ Mettre en vente')
            EndTextCommandDisplayHelp(0, false, true, -1)

            if IsControlJustReleased(0, 47) then -- G
                listNearbyVehicle()
            end

            if IsControlJustReleased(0, 38) then -- E
                local closest, dist = nil, 3.5
                for _, entry in pairs(listings) do
                    local pos = Config.UsedParking.slots[entry.slot]
                    if pos then
                        local d = #(pcoords - vec3(pos.x, pos.y, pos.z))
                        if d < dist then
                            dist = d
                            closest = entry
                        end
                    end
                end
                if closest then
                    openListingMenu(closest)
                else
                    Core.Notify(Core.Locale('used_empty'), 'inform')
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for slot in pairs(slotVehicles) do clearSlot(slot) end
    if blip then RemoveBlip(blip) end
end)
