function RexDiner.OpenHireDialog()
    if not RexDiner.HasLocalPermission('employees') then
        RexDiner.Notify('Employés', 'Permission refusée.', 'error')
        return
    end

    local players = lib.callback.await('rex_diner:getNearbyPlayers', false) or {}
    if #players == 0 then
        RexDiner.Notify('Employés', 'Aucun joueur proche à recruter.', 'error')
        return
    end

    local playerOptions = {}
    for i = 1, #players do
        playerOptions[#playerOptions + 1] = {
            value = players[i].id,
            label = ('ID %s — %s'):format(players[i].id, players[i].name),
        }
    end

    local gradeOptions = {}
    for grade, label in pairs(Config.GradeLabels) do
        if grade < 4 then
            gradeOptions[#gradeOptions + 1] = {
                value = grade,
                label = ('%s (%s)'):format(label, grade),
            }
        end
    end
    table.sort(gradeOptions, function(a, b) return a.value < b.value end)

    local input = lib.inputDialog('Recruter un employé', {
        { type = 'select', label = 'Joueur', options = playerOptions, required = true },
        { type = 'select', label = 'Grade', options = gradeOptions, required = true, default = 0 },
    })

    if not input then return end

    local result = lib.callback.await('rex_diner:hireEmployee', false, {
        targetId = input[1],
        grade = input[2],
    })

    if not result or not result.ok then
        RexDiner.Notify('Employés', result and result.message or 'Échec recrutement.', 'error')
        return
    end
    RexDiner.Notify('Employés', result.message or 'Recruté.', 'success')
end
