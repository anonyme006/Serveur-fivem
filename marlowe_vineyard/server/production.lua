local harvestConfig = Config.Production.Harvest

lib.callback.register('marlowe:server:harvestGrapes', function(source, zoneIndex)
    local player, err = Marlowe.ValidatePlayer(
        source,
        harvestConfig.minGrade,
        Config.RequireDuty.Harvest
    )
    if not player then return false, err end

    local zone = Config.Vineyard.HarvestZones[zoneIndex]
    if not zone then return false, 'Zone invalide.' end

    local coords = Marlowe.GetPlayerCoords(source)
    if not coords or not Marlowe.IsNearCoords(coords, zone.coords, zone.radius + 1.5) then
        return false, Config.Notifications.TooFar
    end

    local amount = math.random(harvestConfig.amount.min, harvestConfig.amount.max)
    if not exports.ox_inventory:CanCarryItem(source, harvestConfig.item, amount) then
        return false, 'Inventaire plein.'
    end

    exports.ox_inventory:AddItem(source, harvestConfig.item, amount)
    MarloweDB.IncrementStat(player.PlayerData.citizenid, 'grapes_harvested', amount)

    return true, amount
end)

lib.callback.register('marlowe:server:transformGrapes', function(source)
    local cfg = Config.Production.Transform
    local player, err = Marlowe.ValidatePlayer(
        source,
        cfg.minGrade,
        Config.RequireDuty.Production
    )
    if not player then return false, err end

    local coords = Marlowe.GetPlayerCoords(source)
    if not coords or not Marlowe.IsNearCoords(coords, Config.Vineyard.ProductionPoint.coords, 5.0) then
        return false, Config.Notifications.TooFar
    end

    if not Marlowe.HasItem(source, cfg.input.item, cfg.input.amount) then
        return false, Config.Notifications.MissingItems
    end

    if not exports.ox_inventory:CanCarryItem(source, cfg.output.item, cfg.output.amount) then
        return false, 'Inventaire plein.'
    end

    if not exports.ox_inventory:RemoveItem(source, cfg.input.item, cfg.input.amount) then
        return false, Config.Notifications.Failed
    end

    exports.ox_inventory:AddItem(source, cfg.output.item, cfg.output.amount)
    return true
end)

lib.callback.register('marlowe:server:startFermentation', function(source, wineType)
    local cfg = Config.Production.Fermentation
    local player, err = Marlowe.ValidatePlayer(
        source,
        cfg.minGrade,
        Config.RequireDuty.Production
    )
    if not player then return false, err end

    local coords = Marlowe.GetPlayerCoords(source)
    if not coords or not Marlowe.IsNearCoords(coords, Config.Vineyard.ProductionPoint.coords, 5.0) then
        return false, Config.Notifications.TooFar
    end

    local inputs = cfg.inputs[wineType]
    local output = cfg.outputs[wineType]
    if not inputs or not output then return false, 'Type de vin invalide.' end

    if not Marlowe.HasAllItems(source, inputs) then
        return false, Config.Notifications.MissingItems
    end

    if not exports.ox_inventory:CanCarryItem(source, output.item, output.amount) then
        return false, 'Inventaire plein.'
    end

    if not Marlowe.RemoveItems(source, inputs) then
        return false, Config.Notifications.Failed
    end

    exports.ox_inventory:AddItem(source, output.item, output.amount)
    return true
end)

lib.callback.register('marlowe:server:bottleWine', function(source)
    local cfg = Config.Production.Bottling
    local player, err = Marlowe.ValidatePlayer(
        source,
        cfg.minGrade,
        Config.RequireDuty.Production
    )
    if not player then return false, err end

    local coords = Marlowe.GetPlayerCoords(source)
    if not coords or not Marlowe.IsNearCoords(coords, Config.Vineyard.ProductionPoint.coords, 5.0) then
        return false, Config.Notifications.TooFar
    end

    if not Marlowe.HasAnyWineForBottling(source, cfg.inputs) then
        return false, Config.Notifications.MissingItems
    end

    local wineItem = Marlowe.GetBottlingWine(source, cfg.inputs)
    if not wineItem then return false, Config.Notifications.MissingItems end

    if not exports.ox_inventory:CanCarryItem(source, cfg.output.item, cfg.output.amount) then
        return false, 'Inventaire plein.'
    end

    if not exports.ox_inventory:RemoveItem(source, wineItem, 1) then
        return false, Config.Notifications.Failed
    end

    exports.ox_inventory:AddItem(source, cfg.output.item, cfg.output.amount)
    MarloweDB.IncrementStat(player.PlayerData.citizenid, 'bottles_produced', cfg.output.amount)

    return true
end)

lib.callback.register('marlowe:server:labelBottles', function(source)
    local cfg = Config.Production.Labeling
    local player, err = Marlowe.ValidatePlayer(
        source,
        cfg.minGrade,
        Config.RequireDuty.Production
    )
    if not player then return false, err end

    local coords = Marlowe.GetPlayerCoords(source)
    if not coords or not Marlowe.IsNearCoords(coords, Config.Vineyard.ProductionPoint.coords, 5.0) then
        return false, Config.Notifications.TooFar
    end

    if not Marlowe.HasItem(source, cfg.input.item, cfg.input.amount) then
        return false, Config.Notifications.MissingItems
    end

    if not exports.ox_inventory:CanCarryItem(source, cfg.output.item, cfg.output.amount) then
        return false, 'Inventaire plein.'
    end

    if not exports.ox_inventory:RemoveItem(source, cfg.input.item, cfg.input.amount) then
        return false, Config.Notifications.Failed
    end

    exports.ox_inventory:AddItem(source, cfg.output.item, cfg.output.amount)
    MarloweDB.IncrementStat(player.PlayerData.citizenid, 'bottles_produced', cfg.output.amount)

    return true
end)
