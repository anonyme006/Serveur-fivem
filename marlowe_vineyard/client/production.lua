MarloweProduction = MarloweProduction or {}

local function notify(message, nType)
    lib.notify({
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end

local function runProductionProgress(label, duration, callback)
    local success = lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    })

    if not success then return end
    callback()
end

function MarloweProduction.TransformGrapes()
    runProductionProgress('Transformation du raisin...', Config.Production.Transform.duration, function()
        local ok, err = lib.callback.await('marlowe:server:transformGrapes', false)
        if ok then
            notify('Raisin transformé en jus.', 'success')
        else
            notify(err or Config.Notifications.Failed, 'error')
        end
    end)
end

function MarloweProduction.StartFermentation(wineType)
    local label = Marlowe.GetWineTypeLabel(wineType)
    runProductionProgress(('Vinification — %s...'):format(label), Config.Production.Fermentation.duration, function()
        local ok, err = lib.callback.await('marlowe:server:startFermentation', false, wineType)
        if ok then
            notify(('Vinification terminée : %s.'):format(label), 'success')
        else
            notify(err or Config.Notifications.Failed, 'error')
        end
    end)
end

function MarloweProduction.BottleWine()
    runProductionProgress('Embouteillage en cours...', Config.Production.Bottling.duration, function()
        local ok, err = lib.callback.await('marlowe:server:bottleWine', false)
        if ok then
            notify('Vin embouteillé avec succès.', 'success')
        else
            notify(err or Config.Notifications.Failed, 'error')
        end
    end)
end

function MarloweProduction.LabelBottles()
    runProductionProgress('Étiquetage des bouteilles...', Config.Production.Labeling.duration, function()
        local ok, err = lib.callback.await('marlowe:server:labelBottles', false)
        if ok then
            notify('Bouteilles étiquetées.', 'success')
        else
            notify(err or Config.Notifications.Failed, 'error')
        end
    end)
end
