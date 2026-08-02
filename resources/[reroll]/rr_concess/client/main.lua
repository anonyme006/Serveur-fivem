local function openShop()
    local options = {}
    for _, v in ipairs(Config.Vehicles) do
        options[#options+1] = {
            title = v.label,
            description = ('%s — $%s'):format(v.category, lib.math.groupdigits(v.price)),
            icon = 'car',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = v.label,
                    content = ('Acheter pour **$%s** ?'):format(lib.math.groupdigits(v.price)),
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('rr_concess:server:buy', v.model)
                end
            end,
        }
    end
    lib.registerContext({ id = 'rr_concess', title = Config.Shop.label, options = options })
    lib.showContext('rr_concess')
end

CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.Shop.coords,
        radius = 2.0,
        options = {
            {
                name = 'rr_concess_open',
                icon = 'fa-solid fa-car',
                label = 'Parcourir le catalogue',
                onSelect = openShop,
            },
        },
    })
end)

RegisterNetEvent('rr_concess:client:deliver', function(model, plate)
    local s = Config.Shop.spawn
    local hash = joaat(model)
    lib.requestModel(hash)
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w, true, false)
    SetVehicleNumberPlateText(veh, plate)
    SetPedIntoVehicle(cache.ped, veh, -1)
    SetVehicleOnGroundProperly(veh)
    SetModelAsNoLongerNeeded(hash)
    exports.rr_api:Notify('Concessionnaire', ('Voici ta %s'):format(model), 'success')
end)
