SkyDS = SkyDS or {}
SkyDS.Client = SkyDS.Client or {}

local nuiOpen = false
local currentSchoolId = nil

function SkyDS.Client.IsNuiOpen()
    return nuiOpen
end

function SkyDS.Client.OpenNui(view, data)
    nuiOpen = true
    currentSchoolId = data and data.school and data.school.id or currentSchoolId
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        view = view or 'home',
        data = data or {},
    })
end

function SkyDS.Client.CloseNui()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

function SkyDS.Client.SendNui(action, payload)
    SendNUIMessage({
        action = action,
        data = payload,
    })
end

RegisterNUICallback('close', function(_, cb)
    SkyDS.Client.CloseNui()
    cb({ ok = true })
end)

RegisterNUICallback('navigate', function(data, cb)
    cb({ ok = true, view = data and data.view })
end)

RegisterNUICallback('startTheory', function(data, cb)
    local schoolId = data and data.schoolId or currentSchoolId
    local category = data and data.category
    local result = lib.callback.await('sky_drivingschool:server:startTheory', false, schoolId, category)
    cb(result or { ok = false, error = 'unknown' })
end)

RegisterNUICallback('submitTheory', function(data, cb)
    local result = lib.callback.await('sky_drivingschool:server:submitTheory', false, data and data.answers or {})
    cb(result or { ok = false })
end)

RegisterNUICallback('cancelTheory', function(_, cb)
    local result = lib.callback.await('sky_drivingschool:server:cancelTheory', false)
    cb(result or { ok = true })
end)

RegisterNUICallback('startPractical', function(data, cb)
    local schoolId = data and data.schoolId or currentSchoolId
    local category = data and data.category
    local result = lib.callback.await('sky_drivingschool:server:startPractical', false, schoolId, category)
    if not result or not result.ok then
        cb(result or { ok = false, error = L('payment_failed') })
        return
    end
    SkyDS.Client.CloseNui()
    CreateThread(function()
        Wait(150)
        SkyDS.Client.BeginPractical(result.exam)
    end)
    cb({ ok = true })
end)

RegisterNUICallback('getHistory', function(_, cb)
    local result = lib.callback.await('sky_drivingschool:server:getHistory', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('getLicenseCard', function(data, cb)
    local result = lib.callback.await('sky_drivingschool:server:getLicenseCard', false, data and data.category)
    cb(result or { ok = false })
end)

RegisterNUICallback('refreshSchool', function(data, cb)
    local schoolId = data and data.schoolId or currentSchoolId
    local result = lib.callback.await('sky_drivingschool:server:openSchool', false, schoolId)
    cb(result or { ok = false })
end)

RegisterNUICallback('adminDashboard', function(_, cb)
    local result = lib.callback.await('sky_drivingschool:server:adminDashboard', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('adminCancelExam', function(data, cb)
    local result = lib.callback.await('sky_drivingschool:server:adminCancelExam', false, data and data.target)
    cb(result or { ok = false })
end)

RegisterNUICallback('adminLookup', function(data, cb)
    local result = lib.callback.await('sky_drivingschool:server:adminLookup', false, data and data.target)
    cb(result or { ok = false })
end)

RegisterNUICallback('adminRemovePoints', function(data, cb)
    local result = lib.callback.await('sky_drivingschool:server:adminRemovePoints', false, data)
    cb(result or { ok = false })
end)

RegisterNUICallback('adminRestorePoints', function(data, cb)
    local result = lib.callback.await('sky_drivingschool:server:adminRestorePoints', false, data)
    cb(result or { ok = false })
end)

RegisterNUICallback('adminRevoke', function(data, cb)
    local result = lib.callback.await('sky_drivingschool:server:adminRevoke', false, data)
    cb(result or { ok = false })
end)

RegisterNUICallback('adminSetPrice', function(data, cb)
    local result = lib.callback.await('sky_drivingschool:server:adminSetPrice', false, data)
    cb(result or { ok = false })
end)

-- Escape handled in NUI; also allow game escape if focus lost weirdly
CreateThread(function()
    while true do
        if nuiOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            Wait(0)
        else
            Wait(400)
        end
    end
end)
