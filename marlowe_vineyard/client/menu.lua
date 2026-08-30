MarloweMenu = MarloweMenu or {}

local menus = {}
local playerInfo = {
    grade = 0,
    onDuty = false,
    dutySeconds = 0,
    stats = {},
}

local colors = Config.Colors
local position = Config.Menu.Position
local theme = Config.Menu.Theme
local size = Config.Menu.Size

local function notify(message, nType)
    lib.notify({
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end

local function refreshPlayerInfo()
    local info = lib.callback.await('marlowe:server:getPlayerInfo', false)
    if info then
        playerInfo = info
    end
    return playerInfo
end

local function hasGrade(requiredGrade)
    return playerInfo.grade >= requiredGrade
end

local function createMenu(title, subtitle, menuPosition)
    return MenuV:CreateMenu(
        title,
        subtitle,
        menuPosition or position,
        colors.Red,
        colors.Green,
        colors.Blue,
        size,
        false,
        'menuv',
        'marlowe_vineyard',
        theme
    )
end

local function openStash(stashKey)
    local ok, stashIdOrError = lib.callback.await('marlowe:server:openStash', false, stashKey)
    if not ok then
        notify(stashIdOrError or Config.Notifications.Failed, 'error')
        return
    end
    exports.ox_inventory:openInventory('stash', stashIdOrError)
end

function MarloweMenu.Init()
    menus.main = createMenu(Config.Label, 'Gestion du domaine viticole')
    menus.production = createMenu('Production', 'Chaîne de production viticole', 'topright')
    menus.harvest = createMenu('Récolte', 'Récolter le raisin dans les vignes', 'topright')
    menus.transform = createMenu('Transformation', 'Transformer le raisin en jus', 'topright')
    menus.fermentation = createMenu('Vinification', 'Fermentation et types de vin', 'topright')
    menus.bottling = createMenu('Embouteillage', 'Mettre le vin en bouteille', 'topright')
    menus.labeling = createMenu('Étiquetage', 'Étiqueter les bouteilles', 'topright')
    menus.stock = createMenu('Stock du domaine', 'Inventaires du vignoble', 'bottomright')
    menus.deliveries = createMenu('Livraisons', 'Gestion des livraisons', 'bottomright')
    menus.deliveryOrders = createMenu('Commandes', 'Liste des commandes clients', 'bottomright')
    menus.deliveryNew = createMenu('Nouvelle livraison', 'Créer une commande', 'bottomright')
    menus.deliveryReady = createMenu('Commandes prêtes', 'Commandes prêtes à livrer', 'bottomright')
    menus.deliveryDone = createMenu('Livraisons terminées', 'Historique des livraisons', 'bottomright')
    menus.employees = createMenu('Gestion des employés', 'Personnel du domaine', 'topright')
    menus.employeeList = createMenu('Liste des employés', 'Employés Marlowe Vineyard', 'topright')
    menus.society = createMenu('Marlowe Vineyard — Société', 'Finances du domaine', 'topright')
    menus.orders = createMenu('Commandes', 'Gestion des commandes', 'bottomright')
    menus.garage = createMenu('Marlowe Vineyard — Garage', 'Véhicules du domaine', 'bottomright')
    menus.wardrobe = createMenu('Vestiaire', 'Tenues de travail', 'bottomright')
    menus.duty = createMenu('Service', 'Prise de service', 'centerright')
    menus.stats = createMenu('Statistiques', 'Performances personnelles', 'centerright')
    menus.director = createMenu('Marlowe Vineyard — Direction', 'Menu directeur', 'centerright')
    menus.domain = createMenu('Gestion du domaine', 'Vue d\'ensemble du vignoble', 'topright')

    menus.main:AddButton({
        icon = '🍇',
        label = 'Production',
        description = 'Récolte, vinification et embouteillage',
        value = menus.production,
    })

    menus.main:AddButton({
        icon = '📦',
        label = 'Stock',
        description = 'Matières premières et produits finis',
        value = menus.stock,
    })

    menus.main:AddButton({
        icon = '🚚',
        label = 'Livraisons',
        description = 'Commandes et livraisons clients',
        value = menus.deliveries,
    })

    menus.main:AddButton({
        icon = '👕',
        label = 'Vestiaire',
        description = 'Tenue de travail ou civile',
        value = menus.wardrobe,
    })

    menus.main:AddButton({
        icon = '🚗',
        label = 'Garage',
        description = 'Sortir ou ranger un véhicule',
        value = menus.garage,
    })

    menus.main:AddButton({
        icon = '⏱️',
        label = 'Prise de service',
        description = 'Prendre ou quitter son service',
        value = menus.duty,
    })

    menus.main:AddButton({
        icon = '📊',
        label = 'Statistiques',
        description = 'Vos performances au domaine',
        value = menus.stats,
    })

    menus.managerEmployees = menus.main:AddButton({
        icon = '👥',
        label = 'Gestion employés',
        description = 'Recruter, promouvoir, licencier',
        value = menus.employees,
    })

    menus.managerSociety = menus.main:AddButton({
        icon = '💰',
        label = 'Société',
        description = 'Solde et finances du domaine',
        value = menus.society,
    })

    menus.managerOrders = menus.main:AddButton({
        icon = '📋',
        label = 'Commandes',
        description = 'Gérer les commandes clients',
        value = menus.orders,
    })

    menus.managerDomain = menus.main:AddButton({
        icon = '📈',
        label = 'Gestion du domaine',
        description = 'Statistiques globales du vignoble',
        value = menus.domain,
    })

    menus.production:AddButton({
        icon = '🍇',
        label = 'Récolter le raisin',
        description = 'Récolter les raisins dans les vignes',
        value = menus.harvest,
    })

    menus.production:AddButton({
        icon = '🪣',
        label = 'Transformer le raisin',
        description = '10 raisins → 1 jus de raisin',
        value = menus.transform,
    })

    menus.production:AddButton({
        icon = '🍷',
        label = 'Vinification',
        description = 'Choisir le type de vin à produire',
        value = menus.fermentation,
    })

    menus.production:AddButton({
        icon = '🍾',
        label = 'Embouteillage',
        description = 'Mettre le vin en bouteille',
        value = menus.bottling,
    })

    menus.production:AddButton({
        icon = '🏷️',
        label = 'Étiquetage',
        description = 'Étiqueter les bouteilles',
        value = menus.labeling,
    })

    menus.harvest:AddButton({
        icon = '🍇',
        label = 'Récolter le raisin',
        description = 'Utilisez les vignes marquées sur la carte',
    }):On('select', function()
        notify('Approchez-vous d\'une vigne et utilisez ox_target pour récolter.', 'inform')
    end)

    local transformBtn = menus.transform:AddButton({
        icon = '🪣',
        label = 'Transformer le raisin',
        description = '10 grape → 1 grape_juice',
    })

    transformBtn:On('select', function()
        MarloweProduction.TransformGrapes()
    end)

    menus.fermentationWineType = menus.fermentation:AddSlider({
        icon = '🍷',
        label = 'Type de vin',
        description = 'Sélectionnez le type de vinification',
        value = 'red',
        values = {
            { label = 'Vin rouge', value = 'red', description = 'Vin rouge de Marlowe' },
            { label = 'Vin blanc', value = 'white', description = 'Vin blanc de Marlowe' },
            { label = 'Vin rosé', value = 'rose', description = 'Vin rosé de Marlowe' },
        },
    })

    menus.fermentation:AddButton({
        icon = '🍷',
        label = 'Commencer la vinification',
        description = 'Lancer le processus de fermentation',
    }):On('select', function()
        local wineType = menus.fermentationWineType.Value or 'red'
        MarloweProduction.StartFermentation(wineType)
    end)

    menus.bottling:AddButton({
        icon = '🍾',
        label = 'Embouteiller',
        description = 'Mettre le vin en bouteille',
    }):On('select', function()
        MarloweProduction.BottleWine()
    end)

    menus.labeling:AddButton({
        icon = '🏷️',
        label = 'Étiqueter les bouteilles',
        description = 'wine_bottle_filled → wine_bottle_labeled',
    }):On('select', function()
        MarloweProduction.LabelBottles()
    end)

    menus.stock:AddButton({
        icon = '📦',
        label = 'Matières premières',
        description = 'Ouvrir le stock de matières premières',
    }):On('select', function()
        openStash('RawMaterials')
    end)

    menus.stock:AddButton({
        icon = '🍷',
        label = 'Produits finis',
        description = 'Ouvrir le stock de produits finis',
    }):On('select', function()
        openStash('FinishedProducts')
    end)

    menus.stock:AddButton({
        icon = '🚚',
        label = 'Stock livraison',
        description = 'Ouvrir le stock de livraison',
    }):On('select', function()
        openStash('DeliveryStock')
    end)

    menus.deliveries:AddButton({
        icon = '📋',
        label = 'Voir les commandes',
        description = 'Afficher toutes les commandes',
        value = menus.deliveryOrders,
    })

    menus.deliveries:AddButton({
        icon = '🚚',
        label = 'Nouvelle livraison',
        description = 'Créer une nouvelle commande',
        value = menus.deliveryNew,
    })

    menus.deliveries:AddButton({
        icon = '📦',
        label = 'Commandes prêtes',
        description = 'Commandes prêtes à livrer',
        value = menus.deliveryReady,
    })

    menus.deliveries:AddButton({
        icon = '✅',
        label = 'Livraisons terminées',
        description = 'Historique des livraisons',
        value = menus.deliveryDone,
    })

    menus.deliveryNewProduct = menus.deliveryNew:AddSlider({
        icon = '🍷',
        label = 'Produit',
        value = 1,
        values = (function()
            local values = {}
            for i, product in ipairs(Config.Deliveries.Products) do
                values[#values + 1] = {
                    label = product.label,
                    value = i,
                    description = ('$%s / unité'):format(product.price),
                }
            end
            return values
        end)(),
    })

    menus.deliveryNewDestination = menus.deliveryNew:AddSlider({
        icon = '📍',
        label = 'Destination',
        value = 1,
        values = (function()
            local values = {}
            for i, point in ipairs(Config.Deliveries.DeliveryPoints) do
                values[#values + 1] = {
                    label = point.label,
                    value = i,
                    description = 'Point de livraison',
                }
            end
            return values
        end)(),
    })

    menus.deliveryNewQuantity = menus.deliveryNew:AddRange({
        icon = '📦',
        label = 'Quantité',
        min = 1,
        max = 20,
        value = 1,
        saveOnUpdate = true,
    })

    menus.deliveryNew:AddButton({
        icon = '✅',
        label = 'Créer la commande',
        description = 'Enregistrer la nouvelle livraison',
    }):On('select', function()
        MarloweDeliveries.CreateOrder(
            menus.deliveryNewProduct.Value,
            menus.deliveryNewQuantity.Value,
            menus.deliveryNewDestination.Value
        )
    end)

    menus.employees:AddButton({
        icon = '👥',
        label = 'Liste des employés',
        description = 'Voir tous les employés',
        value = menus.employeeList,
    })

    menus.employees:AddButton({
        icon = '➕',
        label = 'Recruter',
        description = 'Recruter le joueur le plus proche',
    }):On('select', function()
        MarloweBoss.RecruitNearest()
    end)

    menus.garage:AddButton({
        icon = '🚐',
        label = 'Sortir un véhicule',
        description = 'Choisir un véhicule du garage',
    }):On('select', function()
        MarloweGarage.OpenSpawnMenu()
    end)

    menus.garage:AddButton({
        icon = '🚗',
        label = 'Ranger le véhicule',
        description = 'Ranger le véhicule actuel',
    }):On('select', function()
        MarloweGarage.StoreVehicle()
    end)

    menus.wardrobe:AddButton({
        icon = '👔',
        label = 'Tenue de travail',
        description = 'Enfiler la tenue du domaine',
    }):On('select', function()
        MarloweClothing.WearWorkOutfit()
    end)

    menus.wardrobe:AddButton({
        icon = '👕',
        label = 'Tenue civile',
        description = 'Reprendre sa tenue civile',
    }):On('select', function()
        MarloweClothing.WearCivilOutfit()
    end)

    menus.director:AddButton({ icon = '👥', label = 'Employés', value = menus.employees })
    menus.director:AddButton({ icon = '💰', label = 'Société', value = menus.society })
    menus.director:AddButton({ icon = '📦', label = 'Stock', value = menus.stock })
    menus.director:AddButton({ icon = '📋', label = 'Commandes', value = menus.orders })
    menus.director:AddButton({ icon = '🚚', label = 'Livraisons', value = menus.deliveries })
    menus.director:AddButton({ icon = '📊', label = 'Statistiques', value = menus.stats })
    menus.director:AddButton({ icon = '⚙️', label = 'Configuration', value = menus.domain })

    menus.deliveryOrders:On('open', function(menu)
        MarloweDeliveries.PopulateOrdersMenu(menu, nil)
    end)

    menus.deliveryReady:On('open', function(menu)
        MarloweDeliveries.PopulateOrdersMenu(menu, 'ready')
    end)

    menus.deliveryDone:On('open', function(menu)
        MarloweDeliveries.PopulateOrdersMenu(menu, 'completed')
    end)

    menus.orders:On('open', function(menu)
        MarloweDeliveries.PopulateOrdersMenu(menu, nil, true)
    end)

    menus.employeeList:On('open', function(menu)
        MarloweBoss.PopulateEmployeeList(menu)
    end)

    menus.society:On('open', function(menu)
        MarloweBoss.PopulateSocietyMenu(menu)
    end)

    menus.stats:On('open', function(menu)
        MarloweMenu.PopulateStatsMenu(menu)
    end)

    menus.domain:On('open', function(menu)
        MarloweBoss.PopulateDomainMenu(menu)
    end)

    menus.duty:On('open', function(menu)
        MarloweMenu.PopulateDutyMenu(menu)
    end)

    menus.main:On('open', function()
        refreshPlayerInfo()
        local isManager = hasGrade(Config.Permissions.Employees)
        local isDirector = hasGrade(Config.Permissions.Director)

        menus.managerEmployees:Enabled(isManager)
        menus.managerSociety:Enabled(isManager)
        menus.managerOrders:Enabled(hasGrade(Config.Permissions.Orders))
        menus.managerDomain:Enabled(isManager)
    end)
end

function MarloweMenu.PopulateDutyMenu(menu)
    menu:ClearItems()
    refreshPlayerInfo()

    local dutyLabel = playerInfo.onDuty and '🔴 Quitter son service' or '🟢 Prendre son service'
    local dutyDescription = playerInfo.onDuty and 'Terminer votre service' or 'Commencer votre service'

    menu:AddButton({
        icon = playerInfo.onDuty and '🔴' or '🟢',
        label = dutyLabel,
        description = dutyDescription,
    }):On('select', function()
        local ok, newDuty = lib.callback.await('marlowe:server:toggleDuty', false)
        if ok then
            notify(newDuty and 'Vous êtes en service.' or 'Vous avez quitté votre service.', 'success')
            MarloweMenu.PopulateDutyMenu(menu)
        end
    end)

    local totalSeconds = playerInfo.dutySeconds or 0
    if playerInfo.onDuty and playerInfo.stats and playerInfo.stats.duty_started_at then
        totalSeconds = os.time() - playerInfo.stats.duty_started_at
    end

    menu:AddButton({
        icon = '⏱️',
        label = 'Temps de service',
        description = Marlowe.FormatDuration(totalSeconds),
        disabled = true,
    })
end

function MarloweMenu.PopulateStatsMenu(menu)
    menu:ClearItems()
    local stats = lib.callback.await('marlowe:server:getStatistics', false)
    if not stats then return end

    menu:AddButton({ icon = '🍇', label = 'Raisins récoltés', description = tostring(stats.grapes_harvested or 0), disabled = true })
    menu:AddButton({ icon = '🍷', label = 'Bouteilles produites', description = tostring(stats.bottles_produced or 0), disabled = true })
    menu:AddButton({ icon = '🚚', label = 'Livraisons effectuées', description = tostring(stats.deliveries_completed or 0), disabled = true })
    menu:AddButton({ icon = '💰', label = 'Revenus générés', description = ('$%s'):format(stats.revenue_generated or 0), disabled = true })
    menu:AddButton({ icon = '⏱️', label = 'Heures travaillées', description = Marlowe.FormatDuration(stats.hours_worked or 0), disabled = true })
end

function MarloweMenu.OpenMain()
    local canOpen = lib.callback.await('marlowe:server:canOpenMenu', false)
    if not canOpen then
        notify(Config.Notifications.NoJob, 'error')
        return
    end

    refreshPlayerInfo()

    if hasGrade(Config.Permissions.Director) then
        MenuV:OpenMenu(menus.director)
        return
    end

    MenuV:OpenMenu(menus.main)
end

function MarloweMenu.OpenProduction()
    MenuV:OpenMenu(menus.production)
end

function MarloweMenu.OpenStock()
    MenuV:OpenMenu(menus.stock)
end

function MarloweMenu.OpenGarage()
    MenuV:OpenMenu(menus.garage)
end

function MarloweMenu.OpenWardrobe()
    MenuV:OpenMenu(menus.wardrobe)
end

function MarloweMenu.OpenBoss()
    refreshPlayerInfo()
    if hasGrade(Config.Permissions.Director) then
        MenuV:OpenMenu(menus.director)
    elseif hasGrade(Config.Permissions.Employees) then
        MenuV:OpenMenu(menus.main)
    else
        notify(Config.Notifications.NoGrade, 'error')
    end
end

CreateThread(function()
    MarloweMenu.Init()
end)
