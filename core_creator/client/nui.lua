local function nuiMessage(action, data)
    SendNUIMessage({ action = action, data = data })
end

function ClientCore.OpenUI()
    ClientCore.Callback('core_creator:getBootstrap', {}, function(result)
        if not result or not result.ok then
            Bridge.Notify(_('error.permission'), 'error')
            return
        end
        ClientCore.UiOpen = true
        SetNuiFocus(true, true)
        nuiMessage('open', result.data)
        Bridge.Notify(_('notify.opened'), 'success')
    end)
end

function ClientCore.CloseUI()
    ClientCore.UiOpen = false
    SetNuiFocus(false, false)
    nuiMessage('close', {})
end

AddEventHandler('core_creator:client:open', function()
    ClientCore.OpenUI()
end)

RegisterNUICallback('close', function(_, cb)
    ClientCore.CloseUI()
    cb({ ok = true })
end)

RegisterNUICallback('notify', function(data, cb)
    Bridge.Notify(data.message or '', data.type or 'inform', data.duration)
    cb({ ok = true })
end)

RegisterNUICallback('list', function(data, cb)
    ClientCore.Callback('core_creator:list', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('get', function(data, cb)
    ClientCore.Callback('core_creator:get', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('create', function(data, cb)
    ClientCore.Callback('core_creator:create', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('update', function(data, cb)
    ClientCore.Callback('core_creator:update', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('delete', function(data, cb)
    ClientCore.Callback('core_creator:delete', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('toggle', function(data, cb)
    ClientCore.Callback('core_creator:toggle', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('duplicate', function(data, cb)
    ClientCore.Callback('core_creator:duplicate', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('exportOne', function(data, cb)
    ClientCore.Callback('core_creator:exportOne', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('importOne', function(data, cb)
    ClientCore.Callback('core_creator:importOne', data, function(result)
        cb(result or { ok = false })
    end)
end)

RegisterNUICallback('getPlayerCoords', function(_, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    cb({
        ok = true,
        data = { x = CoreUtils.Round(c.x, 4), y = CoreUtils.Round(c.y, 4), z = CoreUtils.Round(c.z, 4), w = CoreUtils.Round(h, 2) },
    })
end)

RegisterNUICallback('startPlacement', function(data, cb)
    ClientCore.CloseUI()
    TriggerEvent('core_creator:placement:start', data or {}, function(result)
        ClientCore.OpenUI()
        if result and result.ok then
            nuiMessage('placementResult', result.data)
        end
    end)
    cb({ ok = true })
end)

RegisterNUICallback('previewEntity', function(data, cb)
    TriggerEvent('core_creator:preview:show', data)
    cb({ ok = true })
end)

RegisterNUICallback('clearPreview', function(_, cb)
    TriggerEvent('core_creator:preview:clear')
    cb({ ok = true })
end)

RegisterNUICallback('vehicleAction', function(data, cb)
    if not data or not data.action then
        cb({ ok = false })
        return
    end
    if data.action == 'create' then
        TriggerServerEvent('core_creator:vehicles:create', data.payload or {})
    elseif data.action == 'giveKey' then
        TriggerServerEvent('core_creator:vehicles:giveKey', data.plate, data.target, data.temporary, data.minutes)
    elseif data.action == 'removeKey' then
        TriggerServerEvent('core_creator:vehicles:removeKey', data.plate, data.holder)
    elseif data.action == 'transferKey' then
        TriggerServerEvent('core_creator:vehicles:transferKey', data.plate, data.fromHolder, data.toTarget)
    end
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if ClientCore.UiOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 257, true)
            Wait(0)
        else
            Wait(400)
        end
    end
end)
