MarloweBoss = MarloweBoss or {}

local function notify(message, nType)
    lib.notify({
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end

function MarloweBoss.PopulateEmployeeList(menu)
    menu:ClearItems()

    local employees = lib.callback.await('marlowe:server:getEmployees', false)
    if not employees or #employees == 0 then
        menu:AddButton({
            icon = 'ℹ️',
            label = 'Aucun employé',
            description = 'Aucun employé trouvé',
            disabled = true,
        })
        return
    end

    for i = 1, #employees do
        local employee = employees[i]
        local status = employee.onDuty and 'En service' or 'Hors service'
        local online = employee.online and 'En ligne' or 'Hors ligne'

        menu:AddButton({
            icon = '👤',
            label = employee.name,
            description = ('Grade: %s (%s) | %s | %s'):format(
                employee.gradeName,
                employee.grade,
                status,
                online
            ),
        }):On('select', function()
            MarloweBoss.OpenEmployeeActions(employee)
        end)
    end
end

function MarloweBoss.OpenEmployeeActions(employee)
    local actionMenu = MenuV:CreateMenu(
        employee.name,
        ('Grade %s — %s'):format(employee.grade, employee.gradeName),
        'topright',
        Config.Colors.Red,
        Config.Colors.Green,
        Config.Colors.Blue,
        Config.Menu.Size,
        false,
        'menuv',
        'marlowe_vineyard',
        Config.Menu.Theme
    )

    actionMenu:AddButton({
        icon = '⬆️',
        label = 'Promouvoir',
        description = 'Augmenter le grade',
    }):On('select', function()
        local ok, result = lib.callback.await('marlowe:server:manageEmployee', false, employee.citizenid, 'promote')
        if ok then
            notify('Employé promu.', 'success')
        else
            notify(result or Config.Notifications.Failed, 'error')
        end
        MenuV:CloseMenu(actionMenu)
    end)

    actionMenu:AddButton({
        icon = '⬇️',
        label = 'Rétrograder',
        description = 'Diminuer le grade',
    }):On('select', function()
        local ok, result = lib.callback.await('marlowe:server:manageEmployee', false, employee.citizenid, 'demote')
        if ok then
            notify('Employé rétrogradé.', 'success')
        else
            notify(result or Config.Notifications.Failed, 'error')
        end
        MenuV:CloseMenu(actionMenu)
    end)

    actionMenu:AddButton({
        icon = '❌',
        label = 'Licencier',
        description = 'Retirer du domaine',
    }):On('select', function()
        local ok, result = lib.callback.await('marlowe:server:manageEmployee', false, employee.citizenid, 'fire')
        if ok then
            notify('Employé licencié.', 'success')
        else
            notify(result or Config.Notifications.Failed, 'error')
        end
        MenuV:CloseMenu(actionMenu)
    end)

    MenuV:OpenMenu(actionMenu)
end

function MarloweBoss.RecruitNearest()
    local playerCoords = GetEntityCoords(cache.ped)
    local closestPlayer = nil
    local closestDistance = 3.0

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = GetPlayerServerId(playerId)
            end
        end
    end

    if not closestPlayer then
        notify('Aucun joueur à proximité.', 'error')
        return
    end

    local ok, err = lib.callback.await('marlowe:server:recruitPlayer', false, closestPlayer)
    if ok then
        notify('Joueur recruté au domaine.', 'success')
    else
        notify(err or Config.Notifications.Failed, 'error')
    end
end

function MarloweBoss.PopulateSocietyMenu(menu)
    menu:ClearItems()

    local data = lib.callback.await('marlowe:server:getSocietyData', false)
    if not data then return end

    menu:AddButton({
        icon = '💰',
        label = 'Solde',
        description = ('$%s'):format(data.balance or 0),
        disabled = true,
    })

    menu:AddButton({
        icon = '📈',
        label = 'Revenus',
        description = ('$%s'):format(data.income or 0),
        disabled = true,
    })

    menu:AddButton({
        icon = '📉',
        label = 'Dépenses',
        description = ('$%s'):format(data.expense or 0),
        disabled = true,
    })

    menu:AddButton({
        icon = '📊',
        label = 'Chiffre d\'affaires',
        description = ('$%s'):format(data.turnover or 0),
        disabled = true,
    })
end

function MarloweBoss.PopulateDomainMenu(menu)
    menu:ClearItems()

    local data = lib.callback.await('marlowe:server:getDomainStats', false)
    if not data then return end

    menu:AddButton({ icon = '🍇', label = 'Raisins récoltés (total)', description = tostring(data.grapes_harvested or 0), disabled = true })
    menu:AddButton({ icon = '🍷', label = 'Bouteilles produites (total)', description = tostring(data.bottles_produced or 0), disabled = true })
    menu:AddButton({ icon = '🚚', label = 'Livraisons (total)', description = tostring(data.deliveries_completed or 0), disabled = true })
    menu:AddButton({ icon = '💰', label = 'Solde société', description = ('$%s'):format(data.balance or 0), disabled = true })
    menu:AddButton({ icon = '📈', label = 'Revenus', description = ('$%s'):format(data.income or 0), disabled = true })
    menu:AddButton({ icon = '📉', label = 'Dépenses', description = ('$%s'):format(data.expense or 0), disabled = true })
    menu:AddButton({ icon = '⏱️', label = 'Heures travaillées (total)', description = Marlowe.FormatDuration(data.hours_worked or 0), disabled = true })
end
