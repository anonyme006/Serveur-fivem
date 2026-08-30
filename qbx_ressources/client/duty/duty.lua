if Config.Modules and Config.Modules.duty == false then return end

local myDuty = false
local myJob = nil

local function showUi(status, label)
    if not Config.UI or not Config.UI.enabled then return end
    SendNUIMessage({
        action = 'status',
        onDuty = status,
        label = label or '',
        duration = Config.UI.duration or 3500,
    })
end

local function refreshLocalState()
    local data = lib.callback.await('qbx_ressources:duty:server:getDuty', false)
    if data then
        myDuty = data.duty == true
        myJob = data.job
    end
    return data
end

RegisterNetEvent('qbx_ressources:duty:client:dutyDenied', function(reason)
    local messages = {
        too_far = 'Approche-toi du point de service.',
        job_not_configured = 'Ton métier n\'utilise pas le système de service.',
        no_player = 'Personnage introuvable.',
    }
    lib.notify({
        title = 'Service',
        description = messages[reason] or 'Action refusée.',
        type = 'error',
    })
end)

RegisterNetEvent('qbx_ressources:duty:client:onDuty', function(payload)
    myDuty = true
    myJob = payload and payload.job or myJob
    showUi(true, payload and payload.label)
    lib.notify({
        title = 'Service',
        description = ('🟢 Vous êtes en service (%s)'):format(payload and payload.label or myJob or ''),
        type = 'success',
    })
end)

RegisterNetEvent('qbx_ressources:duty:client:offDuty', function(payload)
    myDuty = false
    myJob = payload and payload.job or myJob
    showUi(false, payload and payload.label)
    lib.notify({
        title = 'Service',
        description = ('🔴 Vous êtes hors service (%s)'):format(payload and payload.label or myJob or ''),
        type = 'error',
    })
end)

RegisterNetEvent('qbx_ressources:duty:client:jobChanged', function(jobName)
    myJob = jobName
    local data = lib.callback.await('qbx_ressources:duty:server:getDuty', false)
    if data then
        myDuty = data.duty == true
        myJob = data.job
    end
end)

--- ox_target — points de service par job
CreateThread(function()
    Wait(1000)

    for jobName, points in pairs(Config.DutyPoints or {}) do
        if Duty.IsJobEnabled(jobName) and Duty.JobHasDuty(jobName) and type(points) == 'table' then
            for i = 1, #points do
                local coords = points[i]
                exports.ox_target:addSphereZone({
                    coords = coords,
                    radius = Config.DutyPointRadius or 3.0,
                    debug = false,
                    options = {
                        {
                            name = ('qbx_duty_%s_%s'):format(jobName, i),
                            icon = 'fa-solid fa-id-badge',
                            label = '🟢 Prendre son service',
                            distance = (Config.DutyPointRadius or 3.0) + 0.5,
                            canInteract = function()
                                local pd = exports.qbx_core:GetPlayerData()
                                if not pd or not pd.job or pd.job.name ~= jobName then return false end
                                return LocalPlayer.state.duty ~= true
                            end,
                            onSelect = function()
                                TriggerServerEvent('qbx_ressources:duty:server:setDuty', true)
                            end,
                        },
                        {
                            name = ('qbx_duty_off_%s_%s'):format(jobName, i),
                            icon = 'fa-solid fa-id-badge',
                            label = '🔴 Quitter son service',
                            distance = (Config.DutyPointRadius or 3.0) + 0.5,
                            canInteract = function()
                                local pd = exports.qbx_core:GetPlayerData()
                                if not pd or not pd.job or pd.job.name ~= jobName then return false end
                                return LocalPlayer.state.duty == true
                            end,
                            onSelect = function()
                                TriggerServerEvent('qbx_ressources:duty:server:setDuty', false)
                            end,
                        },
                    },
                })
            end
        end
    end
end)

if Config.Command and Config.Command.enabled and Config.Command.name then
    RegisterCommand(Config.Command.name, function()
        local ok, reason, data = lib.callback.await('qbx_ressources:duty:server:toggleDuty', false)
        if not ok and reason == 'too_far' then
            lib.notify({
                title = 'Service',
                description = 'Approche-toi d\'un point de service.',
                type = 'error',
            })
        elseif not ok and reason == 'job_not_configured' then
            lib.notify({
                title = 'Service',
                description = 'Ton métier n\'utilise pas le système de service.',
                type = 'error',
            })
        end
        if data then
            myDuty = data.duty == true
            myJob = data.job
        end
    end, false)
end

CreateThread(function()
    Wait(2000)
    refreshLocalState()
end)

AddStateBagChangeHandler('duty', nil, function(bagName, _, value)
    local serverId = tonumber(bagName:match('player:(%d+)'))
    if serverId == GetPlayerServerId(PlayerId()) then
        myDuty = value == true
    end
end)

AddStateBagChangeHandler('dutyJob', nil, function(bagName, _, value)
    local serverId = tonumber(bagName:match('player:(%d+)'))
    if serverId == GetPlayerServerId(PlayerId()) and value and value ~= '' then
        myJob = value
    end
end)

exports('IsOnDuty', function()
    if LocalPlayer.state.duty ~= nil then
        return LocalPlayer.state.duty == true
    end
    return myDuty
end)

exports('GetDuty', function()
    if LocalPlayer.state.duty ~= nil then
        return {
            duty = LocalPlayer.state.duty == true,
            job = LocalPlayer.state.dutyJob ~= '' and LocalPlayer.state.dutyJob or myJob,
        }
    end
    return refreshLocalState()
end)

exports('SetDuty', function(state)
    TriggerServerEvent('qbx_ressources:duty:server:setDuty', state == true)
end)

exports('GetOnDutyCount', function(jobName)
    return lib.callback.await('qbx_ressources:duty:server:getOnDutyCount', false, jobName)
end)

exports('GetEmployeesOnDuty', function(jobName)
    return lib.callback.await('qbx_ressources:duty:server:getEmployeesOnDuty', false, jobName)
end)

exports('IsJobOnDuty', function(jobName)
    return lib.callback.await('qbx_ressources:duty:server:getOnDutyCount', false, jobName) > 0
end)
