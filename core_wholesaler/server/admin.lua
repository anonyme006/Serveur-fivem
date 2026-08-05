--[[
    Admin helpers — ACE + grade
]]

Admin = {}

--- Permission admin (ACE ou grade stock)
---@param source number
---@param minGrade integer|nil
---@return boolean
function Admin.HasPermission(source, minGrade)
    if Config.Permissions.adminBypass and IsPlayerAceAllowed(source, 'core_wholesaler.admin') then
        return true
    end

    local player = Payment.GetPlayer(source)
    if not player then return false end

    local job = player.PlayerData.job
    if job.name ~= Config.Job.name then return false end

    local grade = job.grade and job.grade.level or 0
    return grade >= (minGrade or Config.Permissions.manageStock)
end

--- Permission boss menu
---@param source number
---@return boolean
function Admin.CanBoss(source)
    if Config.Permissions.adminBypass and IsPlayerAceAllowed(source, 'core_wholesaler.admin') then
        return true
    end
    local player = Payment.GetPlayer(source)
    if not player then return false end
    return Boss.IsBoss(player)
end

--- Permission préparation
---@param source number
---@return boolean
function Admin.CanPrepare(source)
    return Admin.HasPermission(source, Config.Permissions.prepareOrders)
end

--- Permission prix
---@param source number
---@return boolean
function Admin.CanManagePrices(source)
    return Admin.HasPermission(source, Config.Permissions.managePrices)
end
