RegisterCommand(Config.Command, function()
    if IsPedInAnyVehicle(cache.ped, false) then return end
    if lib.progressCircle({
        duration = Config.Duration,
        label = 'Repos...',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = 'anim@mp_bedmid@left_var_02', clip = 'f_getin_l_bighouse' },
    }) then
        local health = GetEntityHealth(cache.ped)
        SetEntityHealth(cache.ped, math.min(GetEntityMaxHealth(cache.ped), health + Config.HealAmount))
        TriggerEvent('rr_playerstats:client:add', 'hunger', Config.HungerGain)
        TriggerEvent('rr_playerstats:client:add', 'thirst', Config.ThirstGain)
        exports.rr_api:Notify('Repos', 'Tu te sens un peu mieux.', 'success')
    end
end, false)
