--[[
    Client export — Port / Gare / Aéroport
]]

local exportBlip
local exportVehicle

local function clearExport()
    if exportBlip and DoesBlipExist(exportBlip) then
        RemoveBlip(exportBlip)
        exportBlip = nil
    end
    if exportVehicle and DoesEntityExist(exportVehicle) then
        DeleteEntity(exportVehicle)
        exportVehicle = nil
    end
end

function OpenExportMenu()
    if not Config.Export.enabled then return end

    local destinations = lib.callback.await('core_wholesaler:getExportDestinations', false)
    if not destinations or #destinations == 0 then
        return Client.NotifyErr('no_permission')
    end

    local options = {}
    for _, dest in ipairs(destinations) do
        options[#options + 1] = {
            title = dest.label,
            icon = 'location-dot',
            onSelect = function()
                OpenExportItems(dest)
            end,
        }
    end

    lib.registerContext({
        id = 'wholesaler_export',
        title = _('export_title'),
        options = options,
    })
    lib.showContext('wholesaler_export')
end

---@param dest table
function OpenExportItems(dest)
    local stock = lib.callback.await('core_wholesaler:getStock', false)
    if not stock or #stock == 0 then
        return Client.Notify(_('stock_empty'), 'inform')
    end

    -- Sélection multi via dialogs successifs (ox_lib)
    local opts = {}
    for _, p in ipairs(stock) do
        if p.quantity > 0 then
            opts[#opts + 1] = {
                value = p.item,
                label = ('%s (stock: %s, $%s)'):format(p.label, p.quantity, p.price),
            }
        end
    end

    if #opts == 0 then
        return Client.NotifyErr('export_no_stock')
    end

    local input = lib.inputDialog(_('export_select_items'), {
        { type = 'select', label = 'Produit', options = opts, required = true },
        { type = 'number', label = _('product_qty'), min = 1, required = true, default = 10 },
    })
    if not input then return end

    local cart = { { item = input[1], qty = input[2] } }

    local result = lib.callback.await('core_wholesaler:startExport', false, {
        destination = dest.id,
        cart = cart,
    })

    if not result or not result.ok then
        return Client.NotifyErr(result and result.err)
    end

    StartExportMission(result)
end

---@param data table
function StartExportMission(data)
    clearExport()

    Client.activeExport = {
        id = data.id,
        reward = data.reward,
        destination = data.destination,
    }

    -- Spawn véhicule au quai
    local spawn = data.spawn
    local model = joaat(data.vehicle or Config.Export.vehicle)
    lib.requestModel(model)

    exportVehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetVehicleOnGroundProperly(exportVehicle)
    SetEntityAsMissionEntity(exportVehicle, true, true)
    SetModelAsNoLongerNeeded(model)

    local plate = GetVehicleNumberPlateText(exportVehicle)
    TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
    -- Qbox keys (si présent)
    pcall(function()
        exports.qbx_vehiclekeys:GiveKeys(exportVehicle)
    end)

    local dest = data.destination
    exportBlip = AddBlipForCoord(dest.x, dest.y, dest.z)
    SetBlipSprite(exportBlip, dest.blip and dest.blip.sprite or 1)
    SetBlipColour(exportBlip, dest.blip and dest.blip.color or 3)
    SetBlipRoute(exportBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(dest.label)
    EndTextCommandSetBlipName(exportBlip)

    Client.Notify(_('export_started', dest.label), 'success')

    -- Thread livraison
    CreateThread(function()
        local exportId = data.id
        while Client.activeExport and Client.activeExport.id == exportId do
            local sleep = 1000
            local ped = cache.ped
            local coords = GetEntityCoords(ped)
            local target = vec3(dest.x, dest.y, dest.z)
            local dist = #(coords - target)

            if dist < 40.0 then
                sleep = 0
                DrawMarker(1, dest.x, dest.y, dest.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0, 1.2, 50, 120, 220, 140, false, false, 2, false, nil, nil, false)
                if dist < 8.0 then
                    lib.showTextUI('[E] ' .. _('confirm'))
                    if IsControlJustReleased(0, 38) then
                        lib.hideTextUI()
                        local result = lib.callback.await('core_wholesaler:completeExport', false, exportId)
                        if result and result.ok then
                            clearExport()
                            Client.activeExport = nil
                            break
                        else
                            Client.NotifyErr(result and result.err)
                        end
                    end
                else
                    lib.hideTextUI()
                end
            end
            Wait(sleep)
        end
        lib.hideTextUI()
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearExport()
end)
