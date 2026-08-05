--[[
    Client boss menu
]]

function OpenBossMenu()
    local finance = lib.callback.await('core_wholesaler:bossFinance', false)
    if not finance then
        return Client.NotifyErr('no_permission')
    end

    lib.registerContext({
        id = 'wholesaler_boss',
        title = _('boss_title'),
        options = {
            {
                title = _('boss_revenue', Wholesaler.FormatMoney(finance.revenue)),
                description = _('boss_profit', Wholesaler.FormatMoney(finance.profit)),
                icon = 'chart-line',
                readOnly = true,
            },
            {
                title = _('boss_orders'),
                icon = 'clipboard-list',
                onSelect = BossOrders,
            },
            {
                title = _('boss_companies'),
                icon = 'building',
                onSelect = BossCompanies,
            },
            {
                title = _('boss_employees'),
                icon = 'users',
                onSelect = BossEmployees,
            },
            {
                title = _('boss_add_stock'),
                icon = 'plus',
                onSelect = AdminAddStock,
            },
            {
                title = _('boss_remove_stock'),
                icon = 'minus',
                onSelect = AdminRemoveStock,
            },
            {
                title = _('boss_edit_price'),
                icon = 'dollar-sign',
                onSelect = AdminEditPrice,
            },
            {
                title = _('boss_import'),
                icon = 'truck-ramp-box',
                onSelect = AdminImport,
            },
            {
                title = _('boss_hire'),
                icon = 'user-plus',
                onSelect = BossHire,
            },
            {
                title = _('boss_manage'),
                icon = 'user-gear',
                onSelect = BossEmployees,
            },
        },
    })
    lib.showContext('wholesaler_boss')
end

function BossOrders()
    local rows = lib.callback.await('core_wholesaler:bossOrders', false)
    if not rows or #rows == 0 then
        return Client.Notify(_('orders_empty'), 'inform')
    end

    local options = {}
    for _, row in ipairs(rows) do
        options[#options + 1] = {
            title = ('#%s — %s — %s'):format(row.id, row.company, row.statusLabel or row.status),
            description = _('order_total', Wholesaler.FormatMoney(row.total)),
            icon = 'file-invoice-dollar',
            metadata = {
                { label = 'Entreprise', value = row.company },
                { label = 'Statut', value = row.statusLabel or row.status },
                { label = 'Total', value = '$' .. Wholesaler.FormatMoney(row.total) },
                { label = 'Paiement', value = row.payment_method },
                { label = 'Mode', value = row.fulfillment },
            },
            readOnly = true,
        }
    end

    lib.registerContext({
        id = 'wholesaler_boss_orders',
        title = _('boss_orders'),
        menu = 'wholesaler_boss',
        options = options,
    })
    lib.showContext('wholesaler_boss_orders')
end

function BossCompanies()
    local rows = lib.callback.await('core_wholesaler:bossCompanies', false)
    if not rows or #rows == 0 then
        return Client.Notify(_('companies_empty'), 'inform')
    end

    local options = {}
    for _, row in ipairs(rows) do
        options[#options + 1] = {
            title = row.label or row.job,
            description = ('Dépensé: $%s  •  Commandes: %s'):format(
                Wholesaler.FormatMoney(row.total_spent),
                row.order_count
            ),
            icon = 'building',
            readOnly = true,
        }
    end

    lib.registerContext({
        id = 'wholesaler_boss_companies',
        title = _('boss_companies'),
        menu = 'wholesaler_boss',
        options = options,
    })
    lib.showContext('wholesaler_boss_companies')
end

function BossEmployees()
    local rows = lib.callback.await('core_wholesaler:bossEmployees', false)
    if not rows or #rows == 0 then
        return Client.Notify(_('employees_empty'), 'inform')
    end

    local options = {}
    for _, row in ipairs(rows) do
        local gradeLabel = Config.Job.grades[row.grade] and Config.Job.grades[row.grade].label or tostring(row.grade)
        options[#options + 1] = {
            title = row.name,
            description = gradeLabel,
            icon = 'user',
            arrow = true,
            onSelect = function()
                BossEmployeeActions(row)
            end,
        }
    end

    lib.registerContext({
        id = 'wholesaler_boss_employees',
        title = _('boss_employees'),
        menu = 'wholesaler_boss',
        options = options,
    })
    lib.showContext('wholesaler_boss_employees')
end

---@param emp table
function BossEmployeeActions(emp)
    local gradeOpts = {}
    for g, data in pairs(Config.Job.grades) do
        gradeOpts[#gradeOpts + 1] = { value = g, label = data.label }
    end
    table.sort(gradeOpts, function(a, b) return a.value < b.value end)

    lib.registerContext({
        id = 'wholesaler_emp_actions',
        title = emp.name,
        menu = 'wholesaler_boss_employees',
        options = {
            {
                title = 'Changer le grade',
                icon = 'arrow-up-right-dots',
                onSelect = function()
                    local input = lib.inputDialog('Grade', {
                        { type = 'select', label = 'Grade', options = gradeOpts, required = true, default = emp.grade },
                    })
                    if not input then return end
                    local result = lib.callback.await('core_wholesaler:setGrade', false, emp.citizenid, input[1])
                    if not result or not result.ok then
                        Client.NotifyErr(result and result.err)
                    else
                        Client.Notify(_('success'), 'success')
                        BossEmployees()
                    end
                end,
            },
            {
                title = _('boss_fire'),
                icon = 'user-minus',
                iconColor = 'red',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = _('boss_fire'),
                        content = emp.name,
                        centered = true,
                        cancel = true,
                    })
                    if confirm ~= 'confirm' then return end
                    local result = lib.callback.await('core_wholesaler:fire', false, emp.citizenid)
                    if not result or not result.ok then
                        Client.NotifyErr(result and result.err)
                    else
                        BossEmployees()
                    end
                end,
            },
        },
    })
    lib.showContext('wholesaler_emp_actions')
end

function BossHire()
    local nearby = lib.callback.await('core_wholesaler:getNearbyPlayers', false)
    if not nearby or #nearby == 0 then
        return Client.Notify(_('no_nearby_player'), 'inform')
    end

    local opts = {}
    for _, p in ipairs(nearby) do
        opts[#opts + 1] = { value = p.id, label = p.name }
    end

    local gradeOpts = {}
    for g, data in pairs(Config.Job.grades) do
        gradeOpts[#gradeOpts + 1] = { value = g, label = data.label }
    end
    table.sort(gradeOpts, function(a, b) return a.value < b.value end)

    local input = lib.inputDialog(_('boss_hire'), {
        { type = 'select', label = 'Joueur', options = opts, required = true },
        { type = 'select', label = 'Grade', options = gradeOpts, required = true, default = 0 },
    })
    if not input then return end

    local result = lib.callback.await('core_wholesaler:hire', false, input[1], input[2])
    if not result or not result.ok then
        Client.NotifyErr(result and result.err)
    end
end
