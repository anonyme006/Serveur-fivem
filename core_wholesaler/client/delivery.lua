--[[
    Client delivery — transporteurs
]]

local deliveryBlip

local function clearDeliveryBlip()
    if deliveryBlip and DoesBlipExist(deliveryBlip) then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
end

function OpenDeliveryMenu()
    local rows = lib.callback.await('core_wholesaler:getDeliveries', false)
    if not rows or #rows == 0 then
        return Client.Notify(_('delivery_empty'), 'inform')
    end

    local options = {}
    for _, row in ipairs(rows) do
        options[#options + 1] = {
            title = _('delivery_take', row.id),
            description = ('%s  •  %s'):format(
                _('delivery_client', row.company),
                _('delivery_reward', Wholesaler.FormatMoney(row.delivery_reward or 0))
            ),
            icon = 'truck',
            metadata = {
                { label = 'Client', value = row.company },
                { label = 'Récompense', value = '$' .. Wholesaler.FormatMoney(row.delivery_reward or 0) },
                { label = 'Total commande', value = '$' .. Wholesaler.FormatMoney(row.total) },
            },
            onSelect = function()
                StartDelivery(row.id)
            end,
        }
    end

    lib.registerContext({
        id = 'wholesaler_deliveries',
        title = _('delivery_title'),
        menu = 'wholesaler_main',
        options = options,
    })
    lib.showContext('wholesaler_deliveries')
end

---@param orderId integer
function StartDelivery(orderId)
    local result = lib.callback.await('core_wholesaler:takeDelivery', false, orderId)
    if not result or not result.ok then
        return Client.NotifyErr(result and result.err)
    end

    Client.activeDelivery = {
        orderId = result.orderId,
        reward = result.reward,
        company = result.company,
        items = result.items,
        dropoff = result.dropoff,
        dock = result.dock,
        loaded = false,
    }

    clearDeliveryBlip()
    if result.dock then
        deliveryBlip = AddBlipForCoord(result.dock.x, result.dock.y, result.dock.z)
        SetBlipSprite(deliveryBlip, 477)
        SetBlipColour(deliveryBlip, 5)
        SetBlipRoute(deliveryBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(_('delivery_pickup_point'))
        EndTextCommandSetBlipName(deliveryBlip)
    end

    Client.Notify(_('delivery_started', orderId), 'success')
end

--- Menu quai (chargement livraison active)
function OpenDockMenu()
    if Client.activeDelivery and not Client.activeDelivery.loaded then
        local confirm = lib.alertDialog({
            header = _('target_dock'),
            content = _('delivery_take', Client.activeDelivery.orderId),
            centered = true,
            cancel = true,
        })
        if confirm == 'confirm' then
            local result = lib.callback.await('core_wholesaler:loadDelivery', false, Client.activeDelivery.orderId)
            if result and result.ok then
                Client.activeDelivery.loaded = true
                clearDeliveryBlip()

                local drop = Client.activeDelivery.dropoff
                if drop then
                    deliveryBlip = AddBlipForCoord(drop.x, drop.y, drop.z)
                    SetBlipSprite(deliveryBlip, 1)
                    SetBlipColour(deliveryBlip, 2)
                    SetBlipRoute(deliveryBlip, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName(_('delivery_client', Client.activeDelivery.company))
                    EndTextCommandSetBlipName(deliveryBlip)
                end
            else
                Client.NotifyErr(result and result.err)
            end
        end
        return
    end

    -- Sinon ouvrir livraisons ou menu export selon accès
    local access = Client.access or Client.RefreshAccess()
    if access and access.isTransporter then
        OpenDeliveryMenu()
    elseif access and (access.isWholesaler or access.isAdmin) then
        OpenExportMenu()
    else
        Client.Notify(_('delivery_empty'), 'inform')
    end
end

-- Thread léger : dépôt livraison (uniquement si active)
CreateThread(function()
    while true do
        local sleep = 1000
        local del = Client.activeDelivery
        if del and del.loaded and del.dropoff then
            local ped = cache.ped
            local coords = GetEntityCoords(ped)
            local dist = #(coords - vec3(del.dropoff.x, del.dropoff.y, del.dropoff.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1, del.dropoff.x, del.dropoff.y, del.dropoff.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, 50, 200, 50, 120, false, false, 2, false, nil, nil, false)
                if dist < Config.Delivery.dropoffDistance then
                    lib.showTextUI('[E] ' .. _('confirm'))
                    if IsControlJustReleased(0, 38) then
                        lib.hideTextUI()
                        local result = lib.callback.await('core_wholesaler:completeDelivery', false, del.orderId)
                        if result and result.ok then
                            clearDeliveryBlip()
                            Client.activeDelivery = nil
                        else
                            Client.NotifyErr(result and result.err)
                        end
                    end
                else
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearDeliveryBlip()
    lib.hideTextUI()
end)
