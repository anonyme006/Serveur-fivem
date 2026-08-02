exports.ox_target:addGlobalPed({
    {
        name = 'rr_hunt_skin',
        icon = 'fa-solid fa-knife',
        label = 'Dépecer',
        canInteract = function(entity)
            if not IsEntityDead(entity) then return false end
            local model = GetEntityModel(entity)
            for _, a in ipairs(Config.Animals) do
                if model == a then return true end
            end
            return false
        end,
        onSelect = function(data)
            if lib.progressCircle({
                duration = Config.SkinDuration,
                label = 'Dépeçage...',
                position = 'bottom',
                canCancel = true,
                disable = { move = true, combat = true },
                anim = { dict = 'amb@medic@standing@kneel@base', clip = 'base' },
            }) then
                TriggerServerEvent('rr_hunt:server:skin', NetworkGetNetworkIdFromEntity(data.entity))
            end
        end,
    },
})
