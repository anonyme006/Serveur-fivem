ProductionClient = {}
MaskEffects = { active = false }

local function playAnim(anim)
    if not anim or not anim.dict or not anim.clip then return end
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped or PlayerPedId(), anim.dict, anim.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
end

local function stopAnim()
    ClearPedTasks(cache.ped or PlayerPedId())
end

function ProductionClient.OpenStation(labId, stationId, station)
    local lab = ClientLabs.Get(labId)
    if not lab then return end

    local recipes = Config.Recipes[lab.type] or {}
    local group = station.recipeGroup or stationId
    local options = {}

    for i = 1, #recipes do
        local recipe = recipes[i]
        if recipe.station == group or recipe.station == stationId or stationId:find(recipe.station, 1, true)
            or (group == 'pack' and recipe.station == 'packing')
            or (group == 'packing' and recipe.packaging)
        then
            if not recipe.plantAction then
                options[#options + 1] = {
                    title = recipe.label,
                    description = ProductionClient.DescribeRecipe(recipe),
                    icon = 'flask',
                    onSelect = function()
                        ProductionClient.Run(labId, stationId, recipe.id)
                    end,
                }
            end
        end
    end

    if #options == 0 then
        Bridge.Notify(nil, { description = 'No recipes at this station', type = 'inform' })
        return
    end

    lib.registerContext({
        id = 'druglab_station_' .. stationId,
        title = 'Production',
        options = options,
    })
    lib.showContext('druglab_station_' .. stationId)
end

function ProductionClient.DescribeRecipe(recipe)
    local parts = {}
    for item, amount in pairs(recipe.requiredItems or {}) do
        parts[#parts + 1] = ('%sx %s'):format(amount, item)
    end
    return table.concat(parts, ', ')
end

function ProductionClient.Run(labId, stationId, recipeId)
    local start = lib.callback.await('qbx_druglabs:server:startProduction', false, labId, stationId, recipeId)
    if not start or not start.ok then
        Bridge.Notify(nil, { description = start and start.error or 'Cannot start', type = 'error' })
        return
    end

    local data = start.data
    local clientResult = { skillSuccess = true }

    if data.requireMask then
        -- visual-only cue; server already tracks mask
    end

    if data.temperatureGame then
        local furnace = NuiTemp.Open()
        if not furnace then
            lib.callback.await('qbx_druglabs:server:cancelProduction', false, data.token)
            Bridge.Notify(nil, { description = 'Production cancelled', type = 'warning' })
            return
        end
        clientResult.furnace = furnace
    end

    if data.skillCheck then
        local success = lib.skillCheck(data.skillCheck, { 'w', 'a', 's', 'd' })
        clientResult.skillSuccess = success == true
        if not success then
            -- still report to server for quality/fail handling
        end
    end

    playAnim(data.animation)
    local progressOk = lib.progressCircle({
        duration = data.duration or 10000,
        label = data.label or 'Working...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = Config.Production.allowCancel,
        disable = { move = true, car = true, combat = true },
    })
    stopAnim()

    if not progressOk then
        lib.callback.await('qbx_druglabs:server:cancelProduction', false, data.token)
        Bridge.Notify(nil, { description = 'Cancelled', type = 'warning' })
        return
    end

    local finish = lib.callback.await('qbx_druglabs:server:finishProduction', false, data.token, clientResult)
    if not finish or not finish.ok then
        local err = finish and finish.error or 'Failed'
        if err == 'exploded' then
            ProductionClient.ExplosionFx()
            Bridge.Notify(nil, { description = 'The batch exploded!', type = 'error' })
        else
            Bridge.Notify(nil, { description = err, type = 'error' })
        end
        return
    end

    Bridge.Notify(nil, {
        description = ('Success — quality %s%s'):format(
            finish.data.quality or '?',
            finish.data.batch and (' | batch ' .. finish.data.batch) or ''
        ),
        type = 'success',
    })
end

function ProductionClient.ExplosionFx()
    local ped = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    AddExplosion(coords.x, coords.y, coords.z, 2, 0.2, true, false, 0.4)
    ApplyDamageToPed(ped, 15, false)
end

CreateThread(function()
    while true do
        if MaskEffects.active then
            local ped = cache.ped or PlayerPedId()
            ApplyDamageToPed(ped, Config.Meth.noMaskDamageAmount, false)
            if not IsEntityPlayingAnim(ped, 'timetable@gardener@smoking_joint', 'idle_cough', 3) then
                lib.requestAnimDict('timetable@gardener@smoking_joint')
                TaskPlayAnim(ped, 'timetable@gardener@smoking_joint', 'idle_cough', 8.0, -8.0, 2000, 48, 0.0, false, false, false)
            end
            SetTimecycleModifier('drug_wobbly')
            Wait(Config.Meth.noMaskDamageInterval)
        else
            Wait(1000)
        end
    end
end)

function MaskEffects.Start()
    MaskEffects.active = true
end

function MaskEffects.Stop()
    if not MaskEffects.active then return end
    MaskEffects.active = false
    ClearTimecycleModifier()
end

RegisterNetEvent(DrugLabs.Events.client.maskEffect, function(enabled)
    if enabled then MaskEffects.Start() else MaskEffects.Stop() end
end)

RegisterNetEvent(DrugLabs.Events.client.productionResult, function(payload)
    if payload and payload.exploded then
        ProductionClient.ExplosionFx()
    end
end)
