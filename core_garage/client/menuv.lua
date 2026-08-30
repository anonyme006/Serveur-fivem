--[[--------------------------------------------------------------------------
    core_garage — MenuV (style Marlowe Vineyard)
---------------------------------------------------------------------------]]

CoreGarageMenu = CoreGarageMenu or {}

local menus = {}
local selectedGarage = nil
local currentGarageName = nil

local function menuCfg()
    return Config.MenuV or {}
end

local function createMenu(title, subtitle, menuPosition)
    local cfg = menuCfg()
    local colors = cfg.Colors or { Red = 56, Green = 189, Blue = 248 }
    return MenuV:CreateMenu(
        title,
        subtitle,
        menuPosition or cfg.Position or 'bottomright',
        colors.Red,
        colors.Green,
        colors.Blue,
        cfg.Size or 'size-125',
        false,
        'menuv',
        cfg.Namespace or 'core_garage',
        cfg.Theme or 'native'
    )
end

local function statusIcon(status)
    if status == 'impound' then return '🚨' end
    if status == 'out' then return '🛣️' end
    return '🅿️'
end

local function vehicleIcon(vType)
    if vType == 'boat' then return '⛵' end
    if vType == 'plane' then return '✈️' end
    if vType == 'heli' or vType == 'helicopter' then return '🚁' end
    return '🚗'
end

local function statusText(status)
    if status == 'stored' then return _('nui_status_stored') end
    if status == 'out' then return _('nui_status_out') end
    if status == 'impound' then return _('nui_status_impound') end
    return status or '?'
end

function CoreGarageMenu.PopulateVehicleList(menu)
    menu:ClearItems()

    if not currentGarageName then
        menu:AddButton({
            icon = '❌',
            label = _('error'),
            description = _('admin_no_garage'),
            disabled = true,
        })
        return
    end

    local result = lib.callback.await('core_garage:openGarage', false, currentGarageName)
    if not result or not result.ok then
        menu:AddButton({
            icon = '❌',
            label = _('error'),
            description = _(result and result.error or 'error'),
            disabled = true,
        })
        return
    end

    local garage = result.data.garage or {}
    local vehicles = result.data.vehicles or {}
    local isImpound = garage.type == 'impound'

    if #vehicles == 0 then
        menu:AddButton({
            icon = '📭',
            label = isImpound and _('impound_empty') or _('no_vehicles'),
            disabled = true,
        })
        return
    end

    for _, vehicle in ipairs(vehicles) do
        local name = vehicle.nickname
        if not name or name == '' then
            name = CoreGarage.GetModelLabel(vehicle.model)
        end

        local desc = ('%s · %s · %s%% moteur · %s%% carrosserie'):format(
            vehicle.plate or '?',
            statusText(vehicle.status),
            vehicle.engine or 0,
            vehicle.body or 0
        )

        if vehicle.status == 'impound' and vehicle.impoundFee then
            desc = desc .. (' · $%s'):format(vehicle.impoundFee)
        end

        local canUse = vehicle.status == 'stored' or vehicle.status == 'impound'
        local btn = menu:AddButton({
            icon = vehicleIcon(vehicle.type),
            label = name,
            description = desc,
            disabled = not canUse,
        })

        btn:On('select', function()
            if MenuV.CloseAll then MenuV:CloseAll() end
            CoreGarage.currentGarage = currentGarageName
            CoreGarage.TakeOutVehicle(vehicle.plate, isImpound or vehicle.status == 'impound')
        end)
    end
end

function CoreGarageMenu.Init()
    if not menuCfg().enabled then return end

    menus.garage = createMenu(_('garage'), _('menuv_garage_subtitle'))
    menus.vehicles = createMenu(_('menuv_my_vehicles'), _('menuv_vehicle_list'), 'bottomright')
    menus.admin = createMenu(_('admin_menu'), _('menuv_admin_subtitle'), 'centerright')
    menus.adminList = createMenu(_('menuv_admin_list'), _('menuv_admin_list_sub'), 'centerright')
    menus.adminActions = createMenu(_('menuv_admin_actions'), _('menuv_admin_actions_sub'), 'centerright')

    menus.garage:AddButton({
        icon = '🚗',
        label = _('menuv_my_vehicles'),
        description = _('menuv_my_vehicles_desc'),
        value = menus.vehicles,
    })

    menus.garage:AddButton({
        icon = '🏠',
        label = _('store_target'),
        description = _('menuv_store_desc'),
    }):On('select', function()
        if MenuV.CloseAll then MenuV:CloseAll() end
        local ped = PlayerPedId()
        local vehicle = lib.getClosestVehicle(GetEntityCoords(ped), Config.General.storeTargetDistance + 2.0, false)
        if vehicle and vehicle ~= 0 then
            exports[GetCurrentResourceName()]:StoreVehicle(vehicle)
        else
            CoreGarage.Notify(_('vehicle_not_found'), 'error')
        end
    end)

    menus.vehicles:On('open', function(menu)
        CoreGarageMenu.PopulateVehicleList(menu)
    end)

    menus.admin:AddButton({
        icon = '📋',
        label = _('menuv_admin_list'),
        description = _('menuv_admin_list_desc'),
        value = menus.adminList,
    })

    menus.admin:AddButton({
        icon = '➕',
        label = _('menuv_admin_create'),
        description = _('menuv_admin_create_desc'),
    }):On('select', function()
        if CoreGarageAdmin then CoreGarageAdmin.CreateGarage() end
    end)

    menus.admin:AddButton({
        icon = '🚨',
        label = _('menuv_admin_create_impound'),
        description = _('menuv_admin_create_impound_desc'),
    }):On('select', function()
        if CoreGarageAdmin then CoreGarageAdmin.CreateImpound() end
    end)

    menus.admin:AddButton({
        icon = '🏢',
        label = _('menuv_admin_create_company'),
        description = _('menuv_admin_create_company_desc'),
    }):On('select', function()
        if CoreGarageAdmin then CoreGarageAdmin.CreateCompanyGarage() end
    end)

    menus.adminList:On('open', function(menu)
        menu:ClearItems()
        local list = lib.callback.await('core_garage:admin:list', false) or {}

        if #list == 0 then
            menu:AddButton({ icon = '📭', label = _('admin_no_garage'), disabled = true })
            return
        end

        for _, g in ipairs(list) do
            menu:AddButton({
                icon = g.type == 'impound' and '🚨' or '🏠',
                label = g.label or g.name,
                description = ('%s · %s · %s'):format(g.name, g.type, g.enabled and 'ON' or 'OFF'),
                value = menus.adminActions,
            }):On('select', function()
                selectedGarage = {
                    name = g.name,
                    label = g.label,
                    type = g.type,
                    job = g.job,
                    gang = g.gang,
                    minGrade = g.min_grade,
                    impoundPrice = g.impound_price,
                    impoundTime = g.impound_time,
                    enabled = g.enabled,
                }
            end)
        end
    end)

    menus.adminActions:On('open', function(menu)
        menu:ClearItems()
        local garage = selectedGarage
        if not garage then
            menu:AddButton({ icon = '❌', label = _('admin_no_garage'), disabled = true })
            return
        end

        menu:AddButton({
            icon = '📍',
            label = _('menuv_admin_move'),
            description = garage.label,
        }):On('select', function()
            lib.callback.await('core_garage:admin:setCoords', false, garage.name, 'coords')
        end)

        menu:AddButton({
            icon = '🚗',
            label = _('menuv_admin_spawn'),
        }):On('select', function()
            lib.callback.await('core_garage:admin:setCoords', false, garage.name, 'spawn')
        end)

        menu:AddButton({
            icon = '🏠',
            label = _('menuv_admin_store'),
        }):On('select', function()
            lib.callback.await('core_garage:admin:setCoords', false, garage.name, 'store')
        end)

        menu:AddButton({
            icon = '🗺️',
            label = _('menuv_admin_blip'),
        }):On('select', function()
            if CoreGarageAdmin then CoreGarageAdmin.ConfigureBlip(garage) end
        end)

        menu:AddButton({
            icon = '✏️',
            label = _('menuv_admin_edit'),
        }):On('select', function()
            if CoreGarageAdmin then CoreGarageAdmin.EditGarage(garage) end
        end)

        menu:AddButton({
            icon = garage.enabled and '🔴' or '🟢',
            label = garage.enabled and _('menuv_admin_disable') or _('menuv_admin_enable'),
        }):On('select', function()
            lib.callback.await('core_garage:admin:toggle', false, garage.name, not garage.enabled)
            garage.enabled = not garage.enabled
            selectedGarage = garage
        end)

        menu:AddButton({
            icon = '🗑️',
            label = _('menuv_admin_delete'),
            description = garage.name,
        }):On('select', function()
            if CoreGarageAdmin then CoreGarageAdmin.DeleteGarage(garage) end
        end)
    end)
end

function CoreGarageMenu.OpenGarage(garageName)
    if not menuCfg().enabled then return false end

    local garage = CoreGarage.GetGarage(garageName)
    if not garage then return false end
    if not CoreGarage.CanAccess(garage) then
        CoreGarage.Notify(_('no_permission'), 'error')
        return false
    end

    currentGarageName = garageName
    CoreGarage.currentGarage = garageName
    MenuV:OpenMenu(menus.garage)
    return true
end

function CoreGarageMenu.OpenAdmin()
    if not menuCfg().enabled then return false end
    MenuV:OpenMenu(menus.admin)
    return true
end

CreateThread(function()
    if not menuCfg().enabled then return end
    while not MenuV do Wait(100) end
    CoreGarageMenu.Init()
end)

function CoreGarageMenu.UseForGarage()
    local cfg = menuCfg()
    return cfg.enabled and cfg.garageInterface == 'menuv'
end

function CoreGarageMenu.UseForAdmin()
    local cfg = menuCfg()
    return cfg.enabled and cfg.adminInterface == 'menuv'
end
