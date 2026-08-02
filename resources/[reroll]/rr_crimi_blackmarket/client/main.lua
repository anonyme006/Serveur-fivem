local function openMarket()
    local options = {}
    for _, it in ipairs(Config.Items) do
        if not it.sell then
            options[#options+1] = {
                title = ('Acheter %s'):format(it.label),
                description = ('$%s'):format(it.price),
                onSelect = function()
                    TriggerServerEvent('rr_crimi_blackmarket:server:buy', it.item)
                end,
            }
        else
            options[#options+1] = {
                title = ('Vendre %s'):format(it.label),
                description = ('$%s /u'):format(it.sellPrice),
                onSelect = function()
                    TriggerServerEvent('rr_crimi_blackmarket:server:sell', it.item)
                end,
            }
        end
    end
    lib.registerContext({ id = 'rr_blackmarket', title = 'Marché noir', options = options })
    lib.showContext('rr_blackmarket')
end

CreateThread(function()
    local c = Config.Ped.coords
    lib.requestModel(Config.Ped.model)
    local ped = CreatePed(0, Config.Ped.model, c.x, c.y, c.z - 1.0, c.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'rr_blackmarket',
            icon = 'fa-solid fa-skull-crossbones',
            label = 'Parler',
            onSelect = openMarket,
        },
    })
end)
