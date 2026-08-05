--[[
    esx_interim — Gameplay des métiers intérim
]]

local working = false
local runJobId = nil
local route = {}
local routeIndex = 1
local pointZoneId = nil
local routeBlip = nil
local carriedOres = 0
local trashCollected = 0
local sellZoneId = nil
local landfillZoneId = nil

local function L(key, ...)
    local str = (Locales['fr'] and Locales['fr'][key]) or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end

local function Notify(msg, nType)
    lib.notify({
        title = L('agency_title'),
        description = msg,
        type = nType or 'inform',
    })
end

local function GetJobConfig(id)
    for _, job in ipairs(Config.Jobs) do
        if job.id == id then return job end
    end
end

local function ClearPointZone()
    if pointZoneId then
        exports.ox_target:removeZone(pointZoneId)
        pointZoneId = nil
    end
end

local function ClearRouteBlip()
    if routeBlip then
        RemoveBlip(routeBlip)
        routeBlip = nil
    end
end

local function ClearExtraZones()
    if sellZoneId then
        exports.ox_target:removeZone(sellZoneId)
        sellZoneId = nil
    end
    if landfillZoneId then
        exports.ox_target:removeZone(landfillZoneId)
        landfillZoneId = nil
    end
end

local function SetRouteBlip(coords, label, sprite, color)
    ClearRouteBlip()
    routeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(routeBlip, sprite or 1)
    SetBlipColour(routeBlip, color or 3)
    SetBlipScale(routeBlip, 0.85)
    SetBlipRoute(routeBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or 'Mission')
    EndTextCommandSetBlipName(routeBlip)
end

local function ShuffleCopy(list)
    local copy = {}
    for i = 1, #list do copy[i] = list[i] end
    for i = #copy, 2, -1 do
        local j = math.random(i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    return copy
end

local function BuildRoute(job)
    local pool = ShuffleCopy(job.locations)
    local count = math.random(job.stopsPerRun.min, job.stopsPerRun.max)
    count = math.min(count, #pool)
    local selected = {}
    for i = 1, count do
        selected[i] = pool[i]
    end
    return selected
end

local function DoProgress(job)
    return lib.progressCircle({
        duration = job.workDuration,
        label = job.workLabel,
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = job.workAnim and {
            dict = job.workAnim.dict,
            clip = job.workAnim.clip,
        } or nil,
    })
end

local function FinishStop(job)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local target = route[routeIndex]
    if not target then return end

    if #(coords - target) > Config.InteractDistance + 1.0 then
        Notify(L('too_far'), 'error')
        return
    end

    if job.id == 'mineur' then
        local maxCarry = job.maxCarry or 8
        if carriedOres >= maxCarry then
            Notify(L('ore_collected', carriedOres, maxCarry), 'inform')
            ClearPointZone()
            SetRouteBlip(job.sellPoint, 'Joaillerie', 617, 46)
            return
        end
    end

    if not DoProgress(job) then
        Notify(L('cancelled'), 'inform')
        return
    end

    if job.id == 'mineur' then
        local maxCarry = job.maxCarry or 8
        carriedOres = carriedOres + 1
        Notify(L('ore_collected', carriedOres, maxCarry), 'success')
        routeIndex = routeIndex + 1
        if routeIndex > #route or carriedOres >= maxCarry then
            ClearPointZone()
            SetRouteBlip(job.sellPoint, 'Joaillerie', 617, 46)
            Notify(L('go_to_point'), 'inform')
            return
        end
        GoToStop(job)
        return
    end

    if job.id == 'eboueur' then
        trashCollected = trashCollected + 1
        local ok, pay = lib.callback.await('esx_interim:server:completeStop', false, job.id, routeIndex)
        if ok then
            Notify(L('mission_done', pay), 'success')
        end
        routeIndex = routeIndex + 1
        if routeIndex > #route then
            ClearPointZone()
            SetRouteBlip(job.landfill, 'Déchetterie', 318, 2)
            Notify(L('dump_trash'), 'inform')
            return
        end
        GoToStop(job)
        return
    end

    local ok, pay = lib.callback.await('esx_interim:server:completeStop', false, job.id, routeIndex)
    if ok then
        Notify(L('mission_done', pay), 'success')
    else
        Notify(pay or L('too_far'), 'error')
        return
    end

    routeIndex = routeIndex + 1
    if routeIndex > #route then
        ClearPointZone()
        ClearRouteBlip()
        working = false
        runJobId = nil
        TriggerServerEvent('esx_interim:server:endRun')
        Notify(L('run_complete'), 'success')
        return
    end
    GoToStop(job)
end

function GoToStop(job)
    ClearPointZone()
    local coords = route[routeIndex]
    if not coords then return end

    SetRouteBlip(coords, job.workLabel, job.blipSprite, job.blipColor)

    pointZoneId = exports.ox_target:addSphereZone({
        coords = coords,
        radius = 2.0,
        options = {{
            name = 'esx_interim_work_' .. job.id,
            icon = 'fas fa-hammer',
            label = job.workLabel,
            canInteract = function()
                return working and runJobId == job.id
            end,
            onSelect = function()
                FinishStop(job)
            end,
        }},
    })
end

local function SetupSellZone(job)
    if sellZoneId or not job.sellPoint then return end
    sellZoneId = exports.ox_target:addSphereZone({
        coords = job.sellPoint,
        radius = 2.2,
        options = {{
            name = 'esx_interim_sell_ores',
            icon = 'fas fa-gem',
            label = L('sell_ores'),
            canInteract = function()
                return working and runJobId == 'mineur' and carriedOres > 0
            end,
            onSelect = function()
                if carriedOres <= 0 then
                    Notify(L('need_ores'), 'error')
                    return
                end
                if lib.progressCircle({
                    duration = job.sellDuration or 5000,
                    label = job.sellLabel or L('sell_ores'),
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    local amount = carriedOres
                    local ok, pay = lib.callback.await('esx_interim:server:sellOres', false, amount)
                    if ok then
                        Notify(L('ore_sold', pay, amount), 'success')
                        carriedOres = 0
                        ClearPointZone()
                        ClearRouteBlip()
                        working = false
                        runJobId = nil
                        Notify(L('run_complete'), 'success')
                    else
                        Notify(pay or L('need_ores'), 'error')
                    end
                end
            end,
        }},
    })
end

local function SetupLandfillZone(job)
    if landfillZoneId or not job.landfill then return end
    landfillZoneId = exports.ox_target:addSphereZone({
        coords = job.landfill,
        radius = 4.0,
        options = {{
            name = 'esx_interim_dump',
            icon = 'fas fa-dumpster',
            label = L('dump_trash'),
            canInteract = function()
                return working and runJobId == 'eboueur' and trashCollected > 0 and routeIndex > #route
            end,
            onSelect = function()
                if lib.progressCircle({
                    duration = job.dumpDuration or 7000,
                    label = job.dumpLabel or L('dump_trash'),
                    position = 'bottom',
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }) then
                    local bonus = lib.callback.await('esx_interim:server:dumpTrash', false, trashCollected)
                    if bonus then
                        Notify(L('mission_done', bonus), 'success')
                    end
                    trashCollected = 0
                    ClearPointZone()
                    ClearRouteBlip()
                    working = false
                    runJobId = nil
                    Notify(L('run_complete'), 'success')
                end
            end,
        }},
    })
end

local function StartJobRun(jobId)
    if working then
        Notify(L('already_working'), 'error')
        return
    end

    local job = GetJobConfig(jobId)
    if not job then return end

    local ok, err = lib.callback.await('esx_interim:server:startRun', false, jobId)
    if not ok then
        Notify(err or L('no_job'), 'error')
        return
    end

    working = true
    runJobId = jobId
    routeIndex = 1
    carriedOres = 0
    trashCollected = 0
    route = BuildRoute(job)

    if job.id == 'mineur' then
        SetupSellZone(job)
    elseif job.id == 'eboueur' then
        SetupLandfillZone(job)
    end

    Notify(L('go_to_point'), 'inform')
    GoToStop(job)
end

local function CancelJobRun()
    if not working and not runJobId then
        ClearPointZone()
        ClearRouteBlip()
        return
    end
    working = false
    runJobId = nil
    route = {}
    routeIndex = 1
    carriedOres = 0
    trashCollected = 0
    ClearPointZone()
    ClearRouteBlip()
    TriggerServerEvent('esx_interim:server:cancelRun')
end

exports('IsWorking', function()
    return working
end)

exports('StartJobRun', StartJobRun)
exports('CancelJobRun', CancelJobRun)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    ClearPointZone()
    ClearRouteBlip()
    ClearExtraZones()
end)
