--[[--------------------------------------------------------------------------
    core_garage — menu admin ox_lib
---------------------------------------------------------------------------]]

local function garageTypeOptions()
    return {
        { value = 'public', label = 'Public' },
        { value = 'personal', label = 'Personnel' },
        { value = 'company', label = 'Entreprise' },
        { value = 'job', label = 'Métier' },
        { value = 'impound', label = 'Fourrière' },
        { value = 'boat', label = 'Bateau' },
        { value = 'plane', label = 'Avion' },
        { value = 'helicopter', label = 'Hélicoptère' },
    }
end

local function openGarageActions(garage)
    lib.registerContext({
        id = 'core_garage_admin_actions',
        title = garage.label or garage.name,
        menu = 'core_garage_admin_list',
        options = {
            {
                title = 'Déplacer (position menu)',
                icon = 'location-dot',
                onSelect = function()
                    lib.callback.await('core_garage:admin:setCoords', false, garage.name, 'coords')
                end,
            },
            {
                title = 'Définir spawn véhicule',
                icon = 'car',
                onSelect = function()
                    lib.callback.await('core_garage:admin:setCoords', false, garage.name, 'spawn')
                end,
            },
            {
                title = 'Définir point de retour',
                icon = 'warehouse',
                onSelect = function()
                    lib.callback.await('core_garage:admin:setCoords', false, garage.name, 'store')
                end,
            },
            {
                title = 'Configurer blip',
                icon = 'map',
                onSelect = function()
                    local defaults = Config.DefaultBlips[garage.type] or Config.DefaultBlips.public
                    local input = lib.inputDialog('Blip — ' .. garage.name, {
                        { type = 'checkbox', label = 'Activé', checked = true },
                        { type = 'number', label = 'Sprite', default = defaults.sprite },
                        { type = 'number', label = 'Couleur', default = defaults.color },
                        { type = 'number', label = 'Scale', default = defaults.scale, precision = 2 },
                    })
                    if not input then return end
                    lib.callback.await('core_garage:admin:setBlip', false, garage.name, {
                        enabled = input[1],
                        sprite = input[2],
                        color = input[3],
                        scale = input[4],
                        shortRange = true,
                    })
                end,
            },
            {
                title = 'Modifier',
                icon = 'pen',
                onSelect = function()
                    local input = lib.inputDialog('Modifier — ' .. garage.name, {
                        { type = 'input', label = 'Label', default = garage.label, required = true },
                        { type = 'select', label = 'Type', options = garageTypeOptions(), default = garage.type },
                        { type = 'input', label = 'Job (optionnel)', default = garage.job or '' },
                        { type = 'input', label = 'Gang (optionnel)', default = garage.gang or '' },
                        { type = 'number', label = 'Grade min', default = garage.minGrade or 0 },
                        { type = 'number', label = 'Prix fourrière', default = garage.impoundPrice or 1500 },
                        { type = 'number', label = 'Délai fourrière (min)', default = garage.impoundTime or 0 },
                    })
                    if not input then return end
                    lib.callback.await('core_garage:admin:update', false, {
                        name = garage.name,
                        label = input[1],
                        type = input[2],
                        job = input[3] ~= '' and input[3] or nil,
                        gang = input[4] ~= '' and input[4] or nil,
                        minGrade = input[5],
                        impoundPrice = input[6],
                        impoundTime = input[7],
                        vehicleType = Config.GarageVehicleTypes[input[2]] or 'car',
                    })
                end,
            },
            {
                title = garage.enabled and 'Désactiver' or 'Activer',
                icon = garage.enabled and 'toggle-off' or 'toggle-on',
                onSelect = function()
                    lib.callback.await('core_garage:admin:toggle', false, garage.name, not garage.enabled)
                end,
            },
            {
                title = 'Supprimer',
                icon = 'trash',
                iconColor = '#f87171',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Supprimer le garage ?',
                        content = garage.label .. ' (' .. garage.name .. ')',
                        centered = true,
                        cancel = true,
                    })
                    if confirm == 'confirm' then
                        lib.callback.await('core_garage:admin:delete', false, garage.name)
                    end
                end,
            },
        },
    })
    lib.showContext('core_garage_admin_actions')
end

local function openAdminList()
    local list = lib.callback.await('core_garage:admin:list', false) or {}
    local options = {}

    for _, g in ipairs(list) do
        options[#options + 1] = {
            title = g.label or g.name,
            description = ('%s · %s · %s'):format(g.name, g.type, g.enabled and 'ON' or 'OFF'),
            icon = g.type == 'impound' and 'warehouse' or 'garage',
            onSelect = function()
                openGarageActions({
                    name = g.name,
                    label = g.label,
                    type = g.type,
                    job = g.job,
                    gang = g.gang,
                    minGrade = g.min_grade,
                    impoundPrice = g.impound_price,
                    impoundTime = g.impound_time,
                    enabled = g.enabled,
                })
            end,
        }
    end

    if #options == 0 then
        options[1] = { title = 'Aucun garage', disabled = true }
    end

    lib.registerContext({
        id = 'core_garage_admin_list',
        title = _('admin_menu'),
        menu = 'core_garage_admin_main',
        options = options,
    })
    lib.showContext('core_garage_admin_list')
end

local function createGarage()
    local input = lib.inputDialog('Créer un garage', {
        { type = 'input', label = 'Identifiant (unique)', placeholder = 'mon_garage', required = true },
        { type = 'input', label = 'Nom affiché', required = true },
        { type = 'select', label = 'Type', options = garageTypeOptions(), required = true },
        { type = 'input', label = 'Job (entreprise/métier)', placeholder = 'police' },
        { type = 'input', label = 'Gang (optionnel)' },
        { type = 'number', label = 'Grade minimum', default = 0 },
    })
    if not input then return end

    lib.callback.await('core_garage:admin:create', false, {
        name = input[1],
        label = input[2],
        type = input[3],
        job = input[4] ~= '' and input[4] or nil,
        gang = input[5] ~= '' and input[5] or nil,
        minGrade = input[6] or 0,
        vehicleType = Config.GarageVehicleTypes[input[3]] or 'car',
    })
end

local function openAdminMain()
    lib.registerContext({
        id = 'core_garage_admin_main',
        title = _('admin_menu'),
        options = {
            {
                title = 'Liste des garages',
                icon = 'list',
                onSelect = openAdminList,
            },
            {
                title = 'Créer un garage',
                icon = 'plus',
                onSelect = createGarage,
            },
            {
                title = 'Créer une fourrière',
                icon = 'warehouse',
                onSelect = function()
                    local input = lib.inputDialog('Créer fourrière', {
                        { type = 'input', label = 'Identifiant', required = true },
                        { type = 'input', label = 'Nom', required = true },
                        { type = 'number', label = 'Prix', default = Config.Impound.defaultPrice },
                        { type = 'number', label = 'Délai (minutes)', default = 0 },
                    })
                    if not input then return end
                    lib.callback.await('core_garage:admin:create', false, {
                        name = input[1],
                        label = input[2],
                        type = 'impound',
                        impoundPrice = input[3],
                        impoundTime = input[4],
                        vehicleType = 'car',
                    })
                end,
            },
            {
                title = 'Créer garage entreprise',
                icon = 'building',
                onSelect = function()
                    local input = lib.inputDialog('Garage entreprise', {
                        { type = 'input', label = 'Identifiant', required = true },
                        { type = 'input', label = 'Nom', required = true },
                        { type = 'input', label = 'Job', required = true },
                        { type = 'number', label = 'Grade min', default = 0 },
                    })
                    if not input then return end
                    lib.callback.await('core_garage:admin:create', false, {
                        name = input[1],
                        label = input[2],
                        type = 'company',
                        job = input[3],
                        minGrade = input[4],
                        vehicleType = 'car',
                    })
                end,
            },
        },
    })
    lib.showContext('core_garage_admin_main')
end

RegisterCommand(Config.Admin.command or 'garageadmin', function()
    local isAdmin = lib.callback.await('core_garage:admin:isAdmin', false)
    if not isAdmin then
        CoreGarage.Notify(_('no_permission'), 'error')
        return
    end
    openAdminMain()
end, false)
