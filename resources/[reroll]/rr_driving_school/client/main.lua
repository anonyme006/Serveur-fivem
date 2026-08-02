local function startExam()
    local score = 0
    for _, item in ipairs(Config.Questions) do
        local opts = {}
        for i, label in ipairs(item.a) do opts[i] = { value = i, label = label } end
        local input = lib.inputDialog(item.q, {
            { type = 'select', label = 'Réponse', options = opts, required = true },
        })
        if not input then return end
        if tonumber(input[1]) == item.correct then score = score + 1 end
    end
    TriggerServerEvent('rr_driving_school:server:result', score)
end

CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.School,
        radius = 1.5,
        options = {{
            name = 'rr_driving_school',
            icon = 'fa-solid fa-car-side',
            label = ('Passer le code ($%s)'):format(Config.Price),
            onSelect = function()
                local ok = lib.callback.await('rr_driving_school:server:pay', false)
                if ok then startExam() end
            end,
        }},
    })
end)
