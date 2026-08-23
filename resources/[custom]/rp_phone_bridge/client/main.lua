--- Hooks clients optionnels selon téléphone
RegisterNetEvent('sd-phone:client:notify', function(data)
    if lib and data then
        lib.notify({ title = data.title, description = data.message, type = 'inform' })
    end
end)
