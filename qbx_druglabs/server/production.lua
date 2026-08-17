Production = {}

local active = {} ---@type table<number, table> source -> session
local stationLocks = {} ---@type table<string, {source:number, expires:number}>

local function stationKey(labId, stationId)
    return ('%s:%s'):format(labId, stationId)
end

local function clearSession(source, refund)
    local session = active[source]
    if not session then return end
    if refund and session.removedItems and not session.itemsConsumedFinal then
        for item, count in pairs(session.removedItems) do
            Bridge.AddItem(source, item, count)
        end
    end
    if session.stationId then
        local key = stationKey(session.labId, session.stationId)
        local lock = stationLocks[key]
        if lock and lock.source == source then
            stationLocks[key] = nil
        end
    end
    active[source] = nil
end

function Production.GetActive(source)
    return active[source]
end

---@param source number
---@param labId number
---@param stationId string
---@param recipeId string
---@return boolean, string|table
function Production.Start(source, labId, stationId, recipeId)
    if not RateLimit.Check(source, 'production') then return false, 'rate_limited' end
    if active[source] then return false, 'already_producing' end
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end
    if type(stationId) ~= 'string' or type(recipeId) ~= 'string' then return false, 'invalid_args' end

    local lab = Repository.Get(labId)
    if not lab then return false, 'invalid_lab' end
    if lab.sealed then return false, 'sealed' end
    if Buckets.GetPlayerLab(source) ~= labId then return false, 'not_inside' end
    if not Access.Can(source, lab, DrugLabs.Permissions.START_PRODUCTION) then
        return false, 'no_permission'
    end

    local rental = Repository.GetRental(labId)
    if rental and rental.status == 'grace' then
        return false, 'rental_grace'
    end

    local recipe = DrugLabs.GetRecipe(lab.type, recipeId)
    if not recipe then return false, 'invalid_recipe' end

    -- Validate station exists and matches recipe group
    local stations = lab.stations_data or {}
    local station = stations[stationId]
    if not station then return false, 'invalid_station' end

    local group = station.recipeGroup or stationId
    if recipe.station ~= group and recipe.station ~= stationId and not stationId:find(recipe.station, 1, true) then
        -- allow packing group match
        if not (group == recipe.station or recipe.station == 'pack' and group == 'pack') then
            return false, 'wrong_station'
        end
    end

    if recipe.plantAction then
        return false, 'use_plant_action'
    end

    local key = stationKey(labId, stationId)
    local lock = stationLocks[key]
    local now = os.time()
    if lock and lock.expires > now and lock.source ~= source then
        return false, 'station_busy'
    end

    local has, missing = Bridge.HasItems(source, recipe.requiredItems)
    if not has then return false, 'missing_item:' .. tostring(missing) end

    if recipe.requireMask or (Config.Meth.requireMaskForSteps and Config.Meth.requireMaskForSteps[recipeId]) then
        local maskItem = Config.Meth.maskItem
        if Bridge.GetItemCount(source, maskItem) < 1 then
            TriggerClientEvent(DrugLabs.Events.client.maskEffect, source, true)
            -- allow continue but flag session
        else
            TriggerClientEvent(DrugLabs.Events.client.maskEffect, source, false)
        end
    end

    -- Validate reward items exist
    for item in pairs(recipe.rewards or {}) do
        if not Bridge.ItemExists(item) then
            return false, 'invalid_reward_item'
        end
    end

    if not Bridge.CanCarryItems(source, recipe.rewards or {}) then
        return false, 'inventory_full'
    end

    local inputMeta = nil
    if recipe.metadataFromInput then
        for item in pairs(recipe.requiredItems or {}) do
            local slot = Bridge.GetItemWithMetadata(source, item)
            if slot and slot.metadata then
                inputMeta = slot.metadata
                break
            end
        end
    end

    local removedItems = nil
    if Config.Production.removeItemsOnStart then
        if not Bridge.RemoveItems(source, recipe.requiredItems) then
            return false, 'remove_failed'
        end
        removedItems = DrugLabs.DeepCopy(recipe.requiredItems)
    end

    local token = ('%s-%s-%s'):format(source, labId, math.random(100000, 999999))
    stationLocks[key] = { source = source, expires = now + Config.Production.stationLockSeconds }
    active[source] = {
        token = token,
        labId = labId,
        stationId = stationId,
        recipeId = recipeId,
        recipe = recipe,
        startedAt = now,
        expiresAt = now + Config.Server.productionTokenTtl + math.floor((recipe.duration or 10000) / 1000) + 30,
        removedItems = removedItems,
        itemsConsumedFinal = Config.Production.removeItemsOnStart,
        inputMeta = inputMeta,
        hasMask = Bridge.GetItemCount(source, Config.Meth.maskItem) > 0,
        quality = DrugLabs.ClampQuality((inputMeta and inputMeta.quality) or recipe.baseQuality or Config.Quality.default),
    }

    LogAction('production_start', {
        labId = labId,
        actor = Bridge.GetCitizenId(source),
        recipeId = recipeId,
        stationId = stationId,
    })

    return true, {
        token = token,
        duration = recipe.duration or 10000,
        animation = recipe.animation,
        scenario = recipe.scenario,
        skillCheck = recipe.skillCheck,
        temperatureGame = recipe.temperatureGame == true,
        requireMask = recipe.requireMask == true,
        label = recipe.label,
    }
end

---@param quality number
---@param furnaceResult table|nil
---@return number, boolean exploded
local function applyFurnaceQuality(quality, furnaceResult)
    if type(furnaceResult) ~= 'table' then
        return math.max(Config.Quality.min, quality - 10), false
    end

    local temp = tonumber(furnaceResult.temperature)
    if not temp then return math.max(Config.Quality.min, quality - 10), false end

    local minT, maxT = Config.Meth.furnaceTargetMin, Config.Meth.furnaceTargetMax
    local exploded = false

    if temp >= Config.Meth.furnaceOverheat then
        quality = math.max(Config.Quality.min, quality - 40)
        exploded = math.random(1, 100) <= Config.Meth.explosionChanceOnOverheat
    elseif temp < Config.Meth.furnaceUnderheat then
        quality = math.max(Config.Quality.min, quality - 25)
    elseif temp >= minT and temp <= maxT then
        quality = math.min(Config.Quality.max, quality + 15)
    else
        local mid = (minT + maxT) / 2
        local dist = math.abs(temp - mid)
        quality = math.max(Config.Quality.min, quality - math.floor(dist / 2))
    end

    return DrugLabs.ClampQuality(quality), exploded
end

---@param source number
---@param token string
---@param clientResult table|nil
---@return boolean, string|table
function Production.Finish(source, token, clientResult)
    local session = active[source]
    if not session then return false, 'no_session' end
    if session.token ~= token then
        clearSession(source, false)
        LogAction('production_token_mismatch', { actor = Bridge.GetCitizenId(source), source = source })
        return false, 'invalid_token'
    end
    if os.time() > session.expiresAt then
        clearSession(source, true)
        return false, 'expired'
    end

    local lab = Repository.Get(session.labId)
    local recipe = session.recipe
    if not lab or not recipe then
        clearSession(source, true)
        return false, 'invalid_lab'
    end

    if Buckets.GetPlayerLab(source) ~= session.labId then
        clearSession(source, true)
        return false, 'not_inside'
    end

    -- Skill check result is advisory; server may penalize quality but never trusts rewards
    local skillOk = true
    if recipe.skillCheck then
        if type(clientResult) ~= 'table' or clientResult.skillSuccess ~= true then
            skillOk = false
        end
    end

    local quality = session.quality
    local exploded = false

    if recipe.temperatureGame then
        quality, exploded = applyFurnaceQuality(quality, clientResult and clientResult.furnace)
        if exploded then
            clearSession(source, false)
            TriggerClientEvent(DrugLabs.Events.client.productionResult, source, {
                success = false,
                exploded = true,
            })
            Bridge.SendPoliceAlert({
                title = 'Chemical Explosion',
                message = 'Explosion reported near a suspected laboratory.',
                coords = lab.entrance,
                code = '10-31',
                priority = 1,
            })
            LogAction('production_explosion', {
                labId = lab.id,
                actor = Bridge.GetCitizenId(source),
                recipeId = recipe.id,
            })
            return false, 'exploded'
        end
    elseif not skillOk then
        quality = DrugLabs.ClampQuality(quality - (recipe.qualityPenaltyOnFail or 15))
        if math.random(1, 100) <= (recipe.failDispatchChance or Config.Meth.dispatchChanceOnFail or 20) then
            Bridge.SendPoliceAlert({
                title = 'Suspicious Odors',
                message = 'Strange chemical smells reported in the area.',
                coords = lab.entrance,
                code = '10-66',
            })
        end
        -- Failed skill on non-furnace: lose ingredients (already removed), no reward
        if recipe.skillCheck then
            clearSession(source, false)
            LogAction('production_fail', {
                labId = lab.id,
                actor = Bridge.GetCitizenId(source),
                recipeId = recipe.id,
                reason = 'skill',
            })
            return false, 'skill_failed'
        end
    else
        quality = DrugLabs.ClampQuality(quality + (recipe.qualityBonusOnSuccess or 0))
    end

    if not Config.Production.removeItemsOnStart then
        if not Bridge.RemoveItems(source, recipe.requiredItems) then
            clearSession(source, false)
            return false, 'remove_failed'
        end
        session.itemsConsumedFinal = true
    end

    local citizenid = Bridge.GetCitizenId(source)
    local batchCode = nil
    local metadata = {
        quality = quality,
        lab = lab.id,
        producer = citizenid,
    }
    if session.inputMeta then
        metadata.batch = session.inputMeta.batch
        if session.inputMeta.quality then
            -- blend previous quality lightly
            metadata.quality = DrugLabs.ClampQuality(math.floor((session.inputMeta.quality + quality) / 2))
            quality = metadata.quality
        end
    end

    if recipe.createBatch then
        batchCode = DrugLabs.GenerateBatchCode(lab.type)
        metadata.batch = batchCode
        Repository.CreateBatch({
            batchCode = batchCode,
            labId = lab.id,
            producer = citizenid,
            itemName = next(recipe.rewards),
            quality = quality,
            recipeId = recipe.id,
            metadata = metadata,
        })
    end

    -- Give rewards
    local given = {}
    for item, amount in pairs(recipe.rewards or {}) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            local meta = DrugLabs.DeepCopy(metadata)
            if recipe.transformSameItem then
                meta.cooked = true
            end
            if not Bridge.AddItem(source, item, amount, meta) then
                -- rollback given rewards
                for i = 1, #given do
                    Bridge.RemoveItem(source, given[i].item, given[i].count)
                end
                clearSession(source, false)
                return false, 'reward_failed'
            end
            given[#given + 1] = { item = item, count = amount }
        end
    end

    local chance = recipe.dispatchChance or 0
    if not skillOk then
        chance = math.max(chance, recipe.failDispatchChance or chance)
    end
    if chance > 0 and math.random(1, 100) <= chance then
        Bridge.SendPoliceAlert({
            title = 'Drug Activity',
            message = ('Possible %s laboratory activity detected.'):format(lab.type),
            coords = lab.entrance,
            code = '10-66',
        })
    end

    clearSession(source, false)
    LogAction('production_complete', {
        labId = lab.id,
        actor = citizenid,
        recipeId = recipe.id,
        quality = quality,
        batch = batchCode,
    })

    return true, { quality = quality, batch = batchCode, rewards = recipe.rewards }
end

function Production.Cancel(source, token)
    local session = active[source]
    if not session then return false, 'no_session' end
    if token and session.token ~= token then return false, 'invalid_token' end

    -- Ingredients already removed on start are lost on cancel to prevent dupe exploits
    clearSession(source, false)
    LogAction('production_cancel', {
        labId = session.labId,
        actor = Bridge.GetCitizenId(source),
        recipeId = session.recipeId,
    })
    return true
end

AddEventHandler('playerDropped', function()
    local src = source
    if active[src] then
        -- no refund on disconnect (anti-dupe)
        clearSession(src, false)
        LogAction('production_disconnect', { source = src, actor = Bridge.GetCitizenId(src) })
    end
end)
