--[[
    LTD Grove Street — Client
    Interactions ox_target, menus ox_lib, mission livraison.
    Aucune boucle active au repos — tout est événementiel.
]]

local isEmployee = false
local employeeGrade = 0
local deliveryBlip = nil
local deliveryVehicle = nil

-- =============================================================================
-- UTILITAIRES
-- =============================================================================
local function Notify(msg, nType)
    lib.notify({
        title = 'LTD Grove Street',
        description = msg,
        type = nType or 'inform',
    })
end

local function RefreshEmployeeStatus()
    local result = lib.callback.await('ltd:server:isEmployee', false)
    if type(result) == 'table' then
        isEmployee = result.isEmployee
        employeeGrade = result.grade or 0
    else
        isEmployee = result == true
    end
end

-- Rafraîchir le statut employé à la connexion et changement de job
RegisterNetEvent('esx:playerLoaded', function()
    Wait(2000)
    RefreshEmployeeStatus()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    RefreshEmployeeStatus()
end)

RegisterNetEvent('esx:setJob', function()
    RefreshEmployeeStatus()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    RefreshEmployeeStatus()
end)

-- =============================================================================
-- BLIP
-- =============================================================================
CreateThread(function()
    if not Config.Blip.enabled then return end
    local blip = AddBlipForCoord(Config.Blip.coords.x, Config.Blip.coords.y, Config.Blip.coords.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(blip)
end)

-- =============================================================================
-- PED DÉCORATIF (optionnel)
-- =============================================================================
CreateThread(function()
    if not Config.Ped.enabled then return end
    local model = joaat(Config.Ped.model)
    lib.requestModel(model)
    local ped = CreatePed(4, model, Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z - 1.0, Config.Ped.coords.w, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if Config.Ped.scenario then
        TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)
end)

-- =============================================================================
-- MENU RAYON (achat client)
-- =============================================================================
local function OpenShelfMenu(shelfId)
    local shelf = Config.Shelves[shelfId]
    if not shelf then return end

    local stock = lib.callback.await('ltd:server:getShelfStock', false, shelfId)
    if not stock then
        Notify(Config.Notifications.tooFar, 'error')
        return
    end

    local options = {}
    for _, entry in ipairs(shelf.items) do
        local available = stock[entry.item] or 0
        options[#options + 1] = {
            title = entry.label,
            description = string.format('$%d — Disponible : %d', entry.price, available),
            icon = shelf.icon,
            disabled = available <= 0,
            onSelect = function()
                if available <= 0 then return end

                local input = lib.inputDialog('Acheter ' .. entry.label, {
                    { type = 'number', label = 'Quantité', default = 1, min = 1, max = math.min(available, 20) },
                    {
                        type = 'select',
                        label = 'Mode de paiement',
                        options = {
                            { value = 'cash',  label = 'Liquide' },
                            { value = 'bank',  label = 'Banque' },
                        },
                        default = 'cash',
                    },
                })

                if not input then return end

                local success = lib.callback.await('ltd:server:buyFromShelf', false, shelfId, entry.item, input[1], input[2])
                if success then
                    OpenShelfMenu(shelfId)
                end
            end,
        }
    end

    lib.registerContext({
        id = 'ltd_shelf_' .. shelfId,
        title = shelf.label,
        options = options,
    })
    lib.showContext('ltd_shelf_' .. shelfId)
end

-- =============================================================================
-- MENU REMPLISSAGE RAYON (employé)
-- =============================================================================
local function OpenFillShelfMenu(shelfId)
    local shelf = Config.Shelves[shelfId]
    if not shelf then return end

    local storeStock = lib.callback.await('ltd:server:getStoreStock', false)
    if not storeStock then
        Notify(Config.Notifications.noJob, 'error')
        return
    end

    local options = {}
    for _, entry in ipairs(shelf.items) do
        local reserve = storeStock[entry.item] or 0
        options[#options + 1] = {
            title = entry.label,
            description = string.format('Réserve : %d', reserve),
            icon = 'fas fa-box-open',
            disabled = reserve <= 0,
            onSelect = function()
                if reserve <= 0 then return end

                local input = lib.inputDialog('Remplir rayon — ' .. entry.label, {
                    { type = 'number', label = 'Quantité', default = 1, min = 1, max = math.min(reserve, 50) },
                })

                if not input then return end

                lib.callback.await('ltd:server:fillShelf', false, shelfId, entry.item, input[1])
            end,
        }
    end

    lib.registerContext({
        id = 'ltd_fill_' .. shelfId,
        title = 'Remplir — ' .. shelf.label,
        options = options,
    })
    lib.showContext('ltd_fill_' .. shelfId)
end

-- =============================================================================
-- MENU CAISSE
-- =============================================================================
local function OpenRegisterMenu()
    local nearby = lib.callback.await('ltd:server:getNearbyPlayers', false)
    if not nearby or #nearby == 0 then
        Notify('Aucun client à proximité.', 'error')
        return
    end

    local playerOptions = {}
    for _, p in ipairs(nearby) do
        playerOptions[#playerOptions + 1] = { value = p.id, label = p.name .. ' (ID: ' .. p.id .. ')' }
    end

    local input = lib.inputDialog('Encaisser un client', {
        { type = 'select', label = 'Client', options = playerOptions, required = true },
        { type = 'number', label = 'Montant ($)', min = 1, max = 100000, required = true },
        {
            type = 'select',
            label = 'Mode de paiement',
            options = {
                { value = 'cash', label = 'Liquide' },
                { value = 'bank', label = 'Banque' },
            },
            default = 'cash',
        },
    })

    if not input then return end

    lib.callback.await('ltd:server:chargeCustomer', false, input[1], input[2], input[3])
end

-- =============================================================================
-- MENU HISTORIQUE VENTES
-- =============================================================================
local function OpenSalesHistoryMenu()
    local history = lib.callback.await('ltd:server:getSalesHistory', false)
    if not history then return end

    local options = {}
    for _, sale in ipairs(history) do
        local label = sale.sale_type == 'register'
            and string.format('Caisse — $%d (%s)', sale.amount, sale.payment_type)
            or string.format('%s x%d — $%d', sale.item or '?', sale.quantity, sale.amount)

        options[#options + 1] = {
            title = label,
            description = sale.created_at or '',
            icon = 'fas fa-receipt',
            readOnly = true,
        }
    end

    if #options == 0 then
        options[1] = { title = 'Aucune vente enregistrée', readOnly = true }
    end

    lib.registerContext({
        id = 'ltd_sales_history',
        title = 'Historique des ventes',
        menu = 'ltd_register_menu',
        options = options,
    })
    lib.showContext('ltd_sales_history')
end

local function OpenRegisterMainMenu()
    lib.registerContext({
        id = 'ltd_register_menu',
        title = 'Caisse enregistreuse',
        options = {
            {
                title = 'Encaisser un client',
                description = 'Facturer un joueur proche',
                icon = 'fas fa-cash-register',
                onSelect = OpenRegisterMenu,
            },
            {
                title = 'Historique des ventes',
                description = 'Consulter les dernières transactions',
                icon = 'fas fa-history',
                onSelect = OpenSalesHistoryMenu,
            },
        },
    })
    lib.showContext('ltd_register_menu')
end

-- =============================================================================
-- MENU RÉSERVE (stock arrière)
-- =============================================================================
local function OpenStockroomMenu()
    local storeStock = lib.callback.await('ltd:server:getStoreStock', false)
    if not storeStock then
        Notify(Config.Notifications.noJob, 'error')
        return
    end

    local options = {}
    for item, count in pairs(storeStock) do
        options[#options + 1] = {
            title = item,
            description = string.format('Quantité en réserve : %d', count),
            icon = 'fas fa-boxes-stacked',
            readOnly = true,
        }
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = 'ltd_stockroom',
        title = 'Réserve du magasin',
        options = options,
    })
    lib.showContext('ltd_stockroom')
end

-- =============================================================================
-- MENU PATRON
-- =============================================================================
local function OpenEmployeeManagement()
    local employees = lib.callback.await('ltd:server:getEmployees', false)
    if not employees then return end

    local options = {}
    for _, emp in ipairs(employees) do
        local gradeLabel = Config.Grades[emp.job_grade] and Config.Grades[emp.job_grade].label or ('Grade ' .. emp.job_grade)
        options[#options + 1] = {
            title = emp.firstname .. ' ' .. emp.lastname,
            description = gradeLabel,
            icon = 'fas fa-user',
            onSelect = function()
                local gradeOptions = {}
                for gradeId, gradeData in pairs(Config.Grades) do
                    gradeOptions[#gradeOptions + 1] = { value = gradeId, label = gradeData.label }
                end
                table.sort(gradeOptions, function(a, b) return a.value < b.value end)

                lib.registerContext({
                    id = 'ltd_emp_actions_' .. emp.identifier,
                    title = emp.firstname .. ' ' .. emp.lastname,
                    menu = 'ltd_employees',
                    options = {
                        {
                            title = 'Changer le grade',
                            icon = 'fas fa-arrow-up',
                            onSelect = function()
                                local input = lib.inputDialog('Nouveau grade', {
                                    { type = 'select', label = 'Grade', options = gradeOptions, required = true },
                                })
                                if input then
                                    lib.callback.await('ltd:server:setEmployeeGrade', false, emp.identifier, input[1])
                                end
                            end,
                        },
                        {
                            title = 'Licencier',
                            icon = 'fas fa-user-slash',
                            onSelect = function()
                                local confirm = lib.alertDialog({
                                    header = 'Licencier ' .. emp.firstname,
                                    content = 'Confirmer le licenciement ?',
                                    centered = true,
                                    cancel = true,
                                })
                                if confirm == 'confirm' then
                                    lib.callback.await('ltd:server:fireEmployee', false, emp.identifier)
                                end
                            end,
                        },
                    },
                })
                lib.showContext('ltd_emp_actions_' .. emp.identifier)
            end,
        }
    end

    -- Recruter un joueur proche
    options[#options + 1] = {
        title = 'Recruter un joueur proche',
        icon = 'fas fa-user-plus',
        onSelect = function()
            local nearby = lib.callback.await('ltd:server:getNearbyPlayers', false)
            if not nearby or #nearby == 0 then
                Notify('Aucun joueur à proximité.', 'error')
                return
            end
            local playerOptions = {}
            for _, p in ipairs(nearby) do
                playerOptions[#playerOptions + 1] = { value = p.id, label = p.name }
            end
            local input = lib.inputDialog('Recruter', {
                { type = 'select', label = 'Joueur', options = playerOptions, required = true },
            })
            if input then
                lib.callback.await('ltd:server:hireEmployee', false, input[1])
            end
        end,
    }

    lib.registerContext({
        id = 'ltd_employees',
        title = 'Gestion des employés',
        menu = 'ltd_boss_menu',
        options = options,
    })
    lib.showContext('ltd_employees')
end

local function OpenStatisticsMenu()
    local stats = lib.callback.await('ltd:server:getStatistics', false)
    if not stats then return end

    local topItemsText = ''
    for _, item in ipairs(stats.topItems) do
        topItemsText = topItemsText .. string.format('\n%s : %d vendus ($%d)', item.item, item.total_qty, item.total_amount)
    end

    lib.registerContext({
        id = 'ltd_statistics',
        title = 'Statistiques',
        menu = 'ltd_boss_menu',
        options = {
            { title = 'Chiffre d\'affaires total', description = '$' .. stats.totalRevenue, readOnly = true },
            { title = 'Nombre de ventes', description = tostring(stats.totalSales), readOnly = true },
            { title = 'Solde société', description = '$' .. stats.societyBalance, readOnly = true },
            { title = 'Top articles', description = topItemsText ~= '' and topItemsText or 'Aucune donnée', readOnly = true },
        },
    })
    lib.showContext('ltd_statistics')
end

local function OpenBossMenu()
    local balance = lib.callback.await('ltd:server:getSocietyBalance', false)
    if balance == nil then
        Notify(Config.Notifications.noGrade, 'error')
        return
    end

    lib.registerContext({
        id = 'ltd_boss_menu',
        title = 'Menu Patron — LTD Grove',
        options = {
            {
                title = 'Compte société',
                description = string.format('Solde actuel : $%d', balance),
                icon = 'fas fa-building',
                readOnly = true,
            },
            {
                title = 'Déposer de l\'argent',
                icon = 'fas fa-arrow-down',
                onSelect = function()
                    local input = lib.inputDialog('Dépôt société', {
                        { type = 'number', label = 'Montant ($)', min = 1, required = true },
                    })
                    if input then
                        lib.callback.await('ltd:server:depositSociety', false, input[1])
                    end
                end,
            },
            {
                title = 'Retirer de l\'argent',
                icon = 'fas fa-arrow-up',
                onSelect = function()
                    local input = lib.inputDialog('Retrait société', {
                        { type = 'number', label = 'Montant ($)', min = 1, required = true },
                    })
                    if input then
                        lib.callback.await('ltd:server:withdrawSociety', false, input[1])
                    end
                end,
            },
            {
                title = 'Gérer les employés',
                icon = 'fas fa-users',
                onSelect = OpenEmployeeManagement,
            },
            {
                title = 'Statistiques',
                icon = 'fas fa-chart-bar',
                onSelect = OpenStatisticsMenu,
            },
        },
    })
    lib.showContext('ltd_boss_menu')
end

-- =============================================================================
-- MENU COMMANDE LIVRAISON
-- =============================================================================
local function OpenDeliveryOrderMenu()
    local options = {}
    for i, entry in ipairs(Config.Delivery.catalog) do
        options[#options + 1] = {
            title = entry.label,
            description = string.format('Coût : $%d', entry.cost),
            icon = 'fas fa-truck',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Confirmer la commande',
                    content = string.format('Commander %s pour $%d ?\nLe camion sera disponible au dépôt.', entry.label, entry.cost),
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then
                    lib.callback.await('ltd:server:orderDelivery', false, i)
                end
            end,
        }
    end

    lib.registerContext({
        id = 'ltd_delivery_order',
        title = 'Commander des marchandises',
        options = options,
    })
    lib.showContext('ltd_delivery_order')
end

-- =============================================================================
-- MISSION LIVRAISON
-- =============================================================================
RegisterNetEvent('ltd:client:startDeliveryMission', function(deliveryData)
    local spawn = Config.Delivery.spawnPoint

    -- Blip vers le dépôt
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(spawn.x, spawn.y, spawn.z)
    SetBlipSprite(deliveryBlip, 477)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Camion de livraison')
    EndTextCommandSetBlipName(deliveryBlip)

    Notify('Rendez-vous au dépôt pour récupérer le camion de livraison.', 'inform')

    -- Spawn du véhicule quand le joueur arrive
    CreateThread(function()
        local spawned = false
        while not spawned do
            local playerCoords = GetEntityCoords(cache.ped)
            if #(playerCoords - vector3(spawn.x, spawn.y, spawn.z)) < 50.0 then
                local model = joaat(Config.Delivery.vehicle)
                lib.requestModel(model)

                deliveryVehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
                SetEntityAsMissionEntity(deliveryVehicle, true, true)
                SetVehicleOnGroundProperly(deliveryVehicle)
                SetModelAsNoLongerNeeded(model)

                -- Mettre le joueur dans le véhicule
                TaskWarpPedIntoVehicle(cache.ped, deliveryVehicle, -1)

                -- Nouveau blip vers le magasin
                RemoveBlip(deliveryBlip)
                local validateCoords = Config.Locations.deliveryValidate.coords
                deliveryBlip = AddBlipForCoord(validateCoords.x, validateCoords.y, validateCoords.z)
                SetBlipSprite(deliveryBlip, 478)
                SetBlipColour(deliveryBlip, 2)
                SetBlipRoute(deliveryBlip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString('Point de livraison LTD')
                EndTextCommandSetBlipName(deliveryBlip)

                Notify('Camion récupéré — livrez au magasin LTD Grove Street.', 'success')
                spawned = true
            end
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('ltd:client:deliveryComplete', function()
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
        DeleteEntity(deliveryVehicle)
        deliveryVehicle = nil
    end
end)

-- =============================================================================
-- OX_TARGET — ZONES D'INTERACTION
-- =============================================================================
CreateThread(function()
    Wait(1000)
    RefreshEmployeeStatus()

    -- Caisse enregistreuse
    local reg = Config.Locations.register
    exports.ox_target:addBoxZone({
        coords = reg.coords,
        size = reg.size,
        rotation = reg.rotation,
        debug = false,
        options = {
            {
                name = 'ltd_register',
                icon = reg.icon,
                label = reg.label,
                groups = Config.JobName,
                onSelect = OpenRegisterMainMenu,
            },
        },
    })

    -- Menu patron
    local boss = Config.Locations.boss
    exports.ox_target:addBoxZone({
        coords = boss.coords,
        size = boss.size,
        rotation = boss.rotation,
        debug = false,
        options = {
            {
                name = 'ltd_boss',
                icon = boss.icon,
                label = boss.label,
                groups = { [Config.JobName] = Config.BossMinGrade },
                onSelect = OpenBossMenu,
            },
        },
    })

    -- Coffre employés
    local stash = Config.Locations.stash
    exports.ox_target:addBoxZone({
        coords = stash.coords,
        size = stash.size,
        rotation = stash.rotation,
        debug = false,
        options = {
            {
                name = 'ltd_stash',
                icon = stash.icon,
                label = stash.label,
                groups = Config.JobName,
                onSelect = function()
                    exports.ox_inventory:openInventory('stash', stash.stashId)
                end,
            },
        },
    })

    -- Réserve (stock arrière)
    local stockroom = Config.Locations.stockroom
    exports.ox_target:addBoxZone({
        coords = stockroom.coords,
        size = stockroom.size,
        rotation = stockroom.rotation,
        debug = false,
        options = {
            {
                name = 'ltd_stockroom',
                icon = stockroom.icon,
                label = stockroom.label,
                groups = Config.JobName,
                onSelect = OpenStockroomMenu,
            },
        },
    })

    -- Commande livraison
    local deliveryOrder = Config.Locations.deliveryOrder
    exports.ox_target:addBoxZone({
        coords = deliveryOrder.coords,
        size = deliveryOrder.size,
        rotation = deliveryOrder.rotation,
        debug = false,
        options = {
            {
                name = 'ltd_delivery_order',
                icon = deliveryOrder.icon,
                label = deliveryOrder.label,
                groups = Config.JobName,
                onSelect = OpenDeliveryOrderMenu,
            },
        },
    })

    -- Validation livraison
    local deliveryVal = Config.Locations.deliveryValidate
    exports.ox_target:addBoxZone({
        coords = deliveryVal.coords,
        size = deliveryVal.size,
        rotation = deliveryVal.rotation,
        debug = false,
        options = {
            {
                name = 'ltd_delivery_validate',
                icon = deliveryVal.icon,
                label = deliveryVal.label,
                groups = Config.JobName,
                onSelect = function()
                    lib.callback.await('ltd:server:validateDelivery', false)
                end,
            },
        },
    })

    -- Rayons (achat + remplissage)
    for shelfId, shelf in pairs(Config.Shelves) do
        exports.ox_target:addBoxZone({
            coords = shelf.coords,
            size = shelf.size,
            rotation = shelf.rotation,
            debug = false,
            options = {
                {
                    name = 'ltd_shelf_buy_' .. shelfId,
                    icon = shelf.icon,
                    label = 'Acheter — ' .. shelf.label,
                    onSelect = function()
                        OpenShelfMenu(shelfId)
                    end,
                },
                {
                    name = 'ltd_shelf_fill_' .. shelfId,
                    icon = 'fas fa-box-open',
                    label = 'Remplir — ' .. shelf.label,
                    groups = Config.JobName,
                    onSelect = function()
                        OpenFillShelfMenu(shelfId)
                    end,
                },
            },
        })
    end
end)

-- Rafraîchissement initial au chargement
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(3000)
    RefreshEmployeeStatus()
end)
