Bridge = Bridge or {}

---@param source number
---@return string|nil, number
function Bridge.GetGang(source)
    local player = Bridge.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.gang then
        return nil, 0
    end
    local gang = player.PlayerData.gang
    if not gang.name or gang.name == 'none' then
        return nil, 0
    end
    return gang.name, gang.grade and gang.grade.level or 0
end

---@param source number
---@param gangName string
---@param minGrade number|nil
---@return boolean
function Bridge.IsInGang(source, gangName, minGrade)
    if not gangName then return false end
    local name, grade = Bridge.GetGang(source)
    if name ~= gangName then return false end
    minGrade = minGrade or 0
    return grade >= minGrade
end

--- Optional grade-based permission map for gang-owned labs.
--- Override in config if your gang grades differ.
Config.GangGradePermissions = Config.GangGradePermissions or {
    [0] = { ENTER = true, USE_STASH = false, START_PRODUCTION = false, COLLECT_PRODUCTION = false, MANAGE_MEMBERS = false, CHANGE_CODE = false, LOCK_LAB = false, SELL_LAB = false },
    [1] = { ENTER = true, USE_STASH = true, START_PRODUCTION = true, COLLECT_PRODUCTION = true, MANAGE_MEMBERS = false, CHANGE_CODE = false, LOCK_LAB = false, SELL_LAB = false },
    [2] = { ENTER = true, USE_STASH = true, START_PRODUCTION = true, COLLECT_PRODUCTION = true, MANAGE_MEMBERS = false, CHANGE_CODE = false, LOCK_LAB = true, SELL_LAB = false },
    [3] = DrugLabs.OwnerPermissions,
}

---@param grade number
---@return table
function Bridge.GetGangPermissions(grade)
    grade = tonumber(grade) or 0
    local map = Config.GangGradePermissions
    local best = map[0] or DrugLabs.DefaultMemberPermissions
    for g, perms in pairs(map) do
        if grade >= g then
            best = perms
        end
    end
    return DrugLabs.DeepCopy(best)
end
