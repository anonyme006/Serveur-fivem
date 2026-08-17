PlantsClient = {
    Cache = {},
}

function PlantsClient.OpenStation(labId, stationId)
    local inspect = lib.callback.await('qbx_druglabs:server:plantAction', false, labId, stationId, 'inspect')
    local plant = inspect and inspect.ok and inspect.data and inspect.data.plant or nil

    local options = {}
    if not plant then
        options[#options + 1] = {
            title = 'Plant seed',
            icon = 'seedling',
            onSelect = function()
                PlantsClient.DoAction(labId, stationId, 'plant', 'Planting...')
            end,
        }
    else
        options[#options + 1] = {
            title = 'Inspect',
            description = ('Growth %s%% | Water %s | Nutrients %s | Health %s | Quality %s%s'):format(
                plant.growth or 0,
                plant.water or 0,
                plant.nutrients or 0,
                plant.health or 0,
                plant.quality or 0,
                plant.ready and ' | READY' or ''
            ),
            icon = 'eye',
            readOnly = true,
        }
        options[#options + 1] = {
            title = 'Water',
            icon = 'droplet',
            onSelect = function()
                PlantsClient.DoAction(labId, stationId, 'water', 'Watering...')
            end,
        }
        options[#options + 1] = {
            title = 'Add nutrients',
            icon = 'flask',
            onSelect = function()
                PlantsClient.DoAction(labId, stationId, 'nutrients', 'Adding nutrients...')
            end,
        }
        options[#options + 1] = {
            title = 'Spray',
            icon = 'spray-can',
            onSelect = function()
                PlantsClient.DoAction(labId, stationId, 'spray', 'Spraying...')
            end,
        }
        options[#options + 1] = {
            title = 'Harvest',
            icon = 'scissors',
            disabled = not plant.ready,
            onSelect = function()
                PlantsClient.DoAction(labId, stationId, 'harvest', 'Harvesting...')
            end,
        }
    end

    lib.registerContext({
        id = 'druglab_plant_' .. stationId,
        title = 'Plant Station',
        options = options,
    })
    lib.showContext('druglab_plant_' .. stationId)
end

function PlantsClient.DoAction(labId, stationId, action, label)
    local anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' }
    if action == 'water' or action == 'nutrients' then
        anim = { dict = 'weapon@w_sp_jerrycan', clip = 'fire' }
    end

    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped or PlayerPedId(), anim.dict, anim.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)

    local ok = lib.progressCircle({
        duration = action == 'harvest' and 10000 or 5000,
        label = label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })
    ClearPedTasks(cache.ped or PlayerPedId())
    if not ok then return end

    local result = lib.callback.await('qbx_druglabs:server:plantAction', false, labId, stationId, action)
    if not result or not result.ok then
        Bridge.Notify(nil, { description = result and result.error or 'Failed', type = 'error' })
        return
    end

    if result.data and result.data.plants then
        PlantsClient.Cache = result.data.plants
    end

    if action == 'harvest' then
        Bridge.Notify(nil, {
            description = ('Harvested %sx weed_bud (quality %s)'):format(result.data.amount, result.data.quality),
            type = 'success',
        })
    else
        Bridge.Notify(nil, { description = 'Done', type = 'success' })
    end
end
