Plants = {}

local function hoursSince(ts)
    if not ts then return 0 end
    local unix
    if type(ts) == 'number' then
        unix = ts
    else
        unix = MySQL.scalar.await('SELECT UNIX_TIMESTAMP(?)', { ts })
    end
    unix = tonumber(unix) or os.time()
    return math.max(0, (os.time() - unix) / 3600.0)
end

--- Compute plant state from timestamps (no per-second loops)
function Plants.Compute(plant)
    if not plant or plant.harvested == 1 or plant.harvested == true then
        return plant
    end

    local growthHours = hoursSince(plant.planted_at)
    local durationHours = Config.Weed.growthDurationSeconds / 3600.0
    local growth = math.min(100.0, (growthHours / math.max(durationHours, 0.01)) * 100.0)

    local water = tonumber(plant.water) or 50
    local nutrients = tonumber(plant.nutrients) or 50
    local health = tonumber(plant.health) or 100
    local quality = tonumber(plant.quality) or 50

    -- Decay based on time since last care, approximated from planted time if no care
    local careRef = plant.last_watered_at or plant.planted_at
    local hours = hoursSince(careRef)
    water = math.max(0, water - (Config.Weed.waterDecayPerHour * hours))
    nutrients = math.max(0, nutrients - (Config.Weed.nutrientDecayPerHour * hours))

    if water < 15 or nutrients < 10 then
        health = math.max(0, health - (Config.Weed.healthDecayIfDry * hours * 0.25))
        quality = math.max(Config.Quality.min, quality - (hours * 2))
    elseif water > 40 and nutrients > 40 then
        quality = math.min(Config.Quality.max, quality + (hours * 0.5))
        growth = math.min(100.0, growth * 1.05)
    end

    plant.growth = math.floor(growth * 100) / 100
    plant.water = math.floor(water * 100) / 100
    plant.nutrients = math.floor(nutrients * 100) / 100
    plant.health = math.floor(health * 100) / 100
    plant.quality = DrugLabs.ClampQuality(quality)
    plant.ready = plant.growth >= Config.Weed.harvestMinGrowth and plant.health > 10
    return plant
end

function Plants.GetForLab(labId)
    local plants = Repository.GetPlants(labId)
    local result = {}
    for i = 1, #plants do
        result[i] = Plants.Compute(DrugLabs.DeepCopy(plants[i]))
    end
    return result
end

function Plants.GetAtStation(labId, stationId)
    local plants = Plants.GetForLab(labId)
    for i = 1, #plants do
        if plants[i].station_id == stationId and plants[i].harvested ~= 1 then
            return plants[i]
        end
    end
end

---@param source number
---@param labId number
---@param stationId string
---@param action string
---@return boolean, string|table
function Plants.Action(source, labId, stationId, action)
    if not RateLimit.Check(source, 'production') then return false, 'rate_limited' end
    if not DrugLabs.IsValidId(labId) or type(stationId) ~= 'string' or type(action) ~= 'string' then
        return false, 'invalid_args'
    end

    local lab = Repository.Get(labId)
    if not lab or lab.type ~= 'weed' then return false, 'invalid_lab' end
    if lab.sealed then return false, 'sealed' end
    if Buckets.GetPlayerLab(source) ~= labId then return false, 'not_inside' end

    local neededPerm = action == 'harvest' and DrugLabs.Permissions.COLLECT_PRODUCTION or DrugLabs.Permissions.START_PRODUCTION
    if not Access.Can(source, lab, neededPerm) then return false, 'no_permission' end

    local stations = lab.stations_data or {}
    if not stations[stationId] then return false, 'invalid_station' end

    local citizenid = Bridge.GetCitizenId(source)
    local existing = Plants.GetAtStation(labId, stationId)

    if action == 'inspect' then
        return true, { plant = existing }
    end

    if action == 'plant' then
        if existing then return false, 'slot_occupied' end
        if Bridge.GetItemCount(source, Config.Weed.seedItem) < 1 then
            return false, 'missing_seed'
        end
        if not Bridge.RemoveItem(source, Config.Weed.seedItem, 1) then
            return false, 'remove_failed'
        end
        local id = Repository.CreatePlant({
            labId = labId,
            stationId = stationId,
            plantedBy = citizenid,
            quality = Config.Quality.default,
        })
        LogAction('plant_planted', { labId = labId, actor = citizenid, stationId = stationId, plantId = id })
        return true, { plantId = id, plants = Plants.GetForLab(labId) }
    end

    if not existing then return false, 'no_plant' end
    local plant = Plants.Compute(existing)

    if action == 'water' then
        if Bridge.GetItemCount(source, Config.Weed.waterItem) < 1 then return false, 'missing_item' end
        if not Bridge.RemoveItem(source, Config.Weed.waterItem, 1) then return false, 'remove_failed' end
        Repository.UpdatePlant(plant.id, {
            water = math.min(100, (plant.water or 0) + 35),
            last_watered_at = os.date('%Y-%m-%d %H:%M:%S'),
        })
        LogAction('plant_watered', { labId = labId, actor = citizenid, plantId = plant.id })
        return true, { plants = Plants.GetForLab(labId) }
    end

    if action == 'nutrients' then
        if Bridge.GetItemCount(source, Config.Weed.nutrientItem) < 1 then return false, 'missing_item' end
        if not Bridge.RemoveItem(source, Config.Weed.nutrientItem, 1) then return false, 'remove_failed' end
        Repository.UpdatePlant(plant.id, {
            nutrients = math.min(100, (plant.nutrients or 0) + 35),
            quality = DrugLabs.ClampQuality((plant.quality or 50) + 3),
            last_fed_at = os.date('%Y-%m-%d %H:%M:%S'),
        })
        LogAction('plant_fed', { labId = labId, actor = citizenid, plantId = plant.id })
        return true, { plants = Plants.GetForLab(labId) }
    end

    if action == 'spray' then
        if Bridge.GetItemCount(source, Config.Weed.sprayItem) < 1 then return false, 'missing_item' end
        if not Bridge.RemoveItem(source, Config.Weed.sprayItem, 1) then return false, 'remove_failed' end
        Repository.UpdatePlant(plant.id, {
            health = math.min(100, (plant.health or 0) + 20),
            quality = DrugLabs.ClampQuality((plant.quality or 50) + 2),
        })
        LogAction('plant_sprayed', { labId = labId, actor = citizenid, plantId = plant.id })
        return true, { plants = Plants.GetForLab(labId) }
    end

    if action == 'harvest' then
        plant = Plants.Compute(Repository.GetPlant(plant.id))
        if not plant or not plant.ready then return false, 'not_ready' end

        -- Atomic harvest claim
        local affected = MySQL.update.await(
            'UPDATE drug_lab_plants SET harvested = 1 WHERE id = ? AND harvested = 0',
            { plant.id }
        )
        if not affected or affected < 1 then return false, 'already_harvested' end

        local amount = math.max(1, math.floor((plant.health / 100) * (plant.growth / 100) * 5))
        local quality = DrugLabs.ClampQuality(plant.quality)
        local batch = DrugLabs.GenerateBatchCode('WEED')
        local meta = { quality = quality, batch = batch, lab = labId, producer = citizenid }

        if not Bridge.CanCarryItems(source, { weed_bud = amount }) then
            MySQL.update.await('UPDATE drug_lab_plants SET harvested = 0 WHERE id = ?', { plant.id })
            Repository.ReloadLab(labId)
            return false, 'inventory_full'
        end

        if not Bridge.AddItem(source, 'weed_bud', amount, meta) then
            MySQL.update.await('UPDATE drug_lab_plants SET harvested = 0 WHERE id = ?', { plant.id })
            Repository.ReloadLab(labId)
            return false, 'reward_failed'
        end

        Repository.CreateBatch({
            batchCode = batch,
            labId = labId,
            producer = citizenid,
            itemName = 'weed_bud',
            quality = quality,
            recipeId = 'harvest',
            metadata = meta,
        })
        Repository.ReloadLab(labId)
        LogAction('plant_harvested', {
            labId = labId,
            actor = citizenid,
            plantId = plant.id,
            amount = amount,
            quality = quality,
            batch = batch,
        })
        return true, { amount = amount, quality = quality, batch = batch, plants = Plants.GetForLab(labId) }
    end

    return false, 'invalid_action'
end
