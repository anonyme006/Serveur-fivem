--[[
    Zones & PNJ — ox_target (0.00 ms au repos)
]]

local function setupWarehouse()
    local wh = Config.Warehouse

    -- Blip
    if wh.blip and wh.blip.enabled then
        Client.CreateBlip({
            coords = wh.blip.coords,
            sprite = wh.blip.sprite,
            color = wh.blip.color,
            scale = wh.blip.scale,
            label = wh.blip.label,
        })
    end

    -- PNJ Accueil
    local receptionPed = Client.SpawnPed(
        wh.reception.ped.model,
        wh.reception.coords,
        wh.reception.ped.scenario
    )
    exports.ox_target:addLocalEntity(receptionPed, {
        {
            name = 'wholesaler_reception',
            icon = wh.reception.targetIcon,
            label = _('target_reception'),
            distance = 2.5,
            onSelect = function()
                Client.npcMode = false
                OpenWholesalerMenu('main')
            end,
        },
    })

    -- PNJ vendeur hors service (entreprises)
    local npcCfg = Config.NpcVendor
    if npcCfg and npcCfg.enabled then
        local vendorPed = Client.SpawnPed(
            npcCfg.ped.model,
            npcCfg.coords,
            npcCfg.ped.scenario
        )
        exports.ox_target:addLocalEntity(vendorPed, {
            {
                name = 'wholesaler_npc_vendor',
                icon = npcCfg.targetIcon or 'fas fa-store',
                label = _('target_npc_vendor'),
                distance = 2.5,
                canInteract = function()
                    local access = Client.access or Client.RefreshAccess()
                    return access and access.isBuyer == true
                end,
                onSelect = function()
                    OpenNpcVendorMenu()
                end,
            },
        })
    end

    -- Zone commande
    exports.ox_target:addBoxZone({
        name = 'wholesaler_order',
        coords = wh.orderZone.coords,
        size = wh.orderZone.size,
        rotation = wh.orderZone.rotation,
        debug = Config.Debug,
        options = {
            {
                name = 'wholesaler_order_opt',
                icon = wh.orderZone.targetIcon,
                label = _('target_order'),
                distance = 2.0,
                onSelect = function()
                    Client.npcMode = false
                    OpenWholesalerMenu('buy')
                end,
            },
        },
    })

    -- Zone retrait
    exports.ox_target:addBoxZone({
        name = 'wholesaler_pickup',
        coords = wh.pickupZone.coords,
        size = wh.pickupZone.size,
        rotation = wh.pickupZone.rotation,
        debug = Config.Debug,
        options = {
            {
                name = 'wholesaler_pickup_opt',
                icon = wh.pickupZone.targetIcon,
                label = _('target_pickup'),
                distance = 2.0,
                onSelect = function()
                    OpenPickupMenu()
                end,
            },
        },
    })

    -- Quai de chargement
    exports.ox_target:addBoxZone({
        name = 'wholesaler_dock',
        coords = wh.loadingDock.coords,
        size = wh.loadingDock.size,
        rotation = wh.loadingDock.rotation,
        debug = Config.Debug,
        options = {
            {
                name = 'wholesaler_dock_load',
                icon = wh.loadingDock.targetIcon,
                label = _('target_dock'),
                distance = 3.0,
                onSelect = function()
                    OpenDockMenu()
                end,
            },
            {
                name = 'wholesaler_dock_export',
                icon = 'fas fa-ship',
                label = _('menu_export'),
                distance = 3.0,
                canInteract = function()
                    local a = Client.access or Client.RefreshAccess()
                    return a and (a.isWholesaler or a.isAdmin)
                end,
                onSelect = function()
                    OpenExportMenu()
                end,
            },
        },
    })

    -- Bureau responsable
    local bossPed = Client.SpawnPed(
        wh.bossOffice.ped.model,
        wh.bossOffice.coords,
        wh.bossOffice.ped.scenario
    )
    exports.ox_target:addLocalEntity(bossPed, {
        {
            name = 'wholesaler_boss',
            icon = wh.bossOffice.targetIcon,
            label = _('target_boss'),
            distance = 2.5,
            canInteract = function()
                local a = Client.access or Client.RefreshAccess()
                return a and (a.isBoss or a.isAdmin)
            end,
            onSelect = function()
                OpenBossMenu()
            end,
        },
    })
end

CreateThread(function()
    setupWarehouse()
end)
