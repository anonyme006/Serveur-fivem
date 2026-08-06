--[[
    Duty helpers — employés grossiste en service
]]

Duty = {}

--- Compte les joueurs du job wholesaler actuellement onduty
---@return integer count, table[] players
function Duty.GetOnDutyEmployees()
    local list = {}
    local players = exports.qbx_core:GetQBPlayers()
    if not players then return 0, list end

    local jobName = Config.Job.name
    for src, ply in pairs(players) do
        local job = ply.PlayerData and ply.PlayerData.job
        if job and job.name == jobName then
            -- Qbox : job.onduty ; fallback true si absent
            local onduty = job.onduty
            if onduty == nil then onduty = true end
            if onduty then
                list[#list + 1] = {
                    source = src,
                    citizenid = ply.PlayerData.citizenid,
                    name = Payment.GetName(ply),
                    grade = job.grade and job.grade.level or 0,
                }
            end
        end
    end

    return #list, list
end

--- Au moins un employé en service ?
---@return boolean
function Duty.HasStaffOnDuty()
    local count = Duty.GetOnDutyEmployees()
    return count > 0
end

--- Le PNJ vendeur peut-il vendre maintenant ?
---@return boolean
function Duty.CanNpcSell()
    if not Config.NpcVendor or not Config.NpcVendor.enabled then
        return false
    end
    return not Duty.HasStaffOnDuty()
end
