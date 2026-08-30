function Rest.OpenHireDialog()
    if not Rest.Can('employees') then
        Rest.Notify('Employés', 'Permission refusée.', 'error')
        return
    end
    local players = lib.callback.await('qbox_restaurants:getNearbyPlayers', false) or {}
    if #players == 0 then
        Rest.Notify('Employés', 'Aucun joueur proche.', 'error')
        return
    end
    local playerOpts, gradeOpts = {}, {}
    for i = 1, #players do
        playerOpts[#playerOpts + 1] = {
            value = players[i].id,
            label = ('ID %s — %s'):format(players[i].id, players[i].name),
        }
    end
    for grade, label in pairs(Config.GradeLabels) do
        if grade < 4 then
            gradeOpts[#gradeOpts + 1] = { value = grade, label = ('%s (%s)'):format(label, grade) }
        end
    end
    table.sort(gradeOpts, function(a, b) return a.value < b.value end)

    local input = lib.inputDialog('Recruter', {
        { type = 'select', label = 'Joueur', options = playerOpts, required = true },
        { type = 'select', label = 'Grade', options = gradeOpts, required = true, default = 0 },
    })
    if not input then return end
    local result = lib.callback.await('qbox_restaurants:hireEmployee', false, {
        targetId = input[1], grade = input[2],
    })
    Rest.Notify('Employés', result and result.message or 'Erreur', result and result.ok and 'success' or 'error')
end
