--[[
    Pulse Phone — Joueurs / identité serveur
]]

Pulse = Pulse or {}
Pulse.Players = {}

---@param src number
---@return table|nil job data
function Pulse.Players.GetJob(src)
    local player = Pulse.Server.GetPlayer(src)
    if not player then return nil end
    return player.PlayerData.job
end

---@param src number
---@param jobName string
---@param minGrade number|nil
---@return boolean
function Pulse.Players.HasJob(src, jobName, minGrade)
    local job = Pulse.Players.GetJob(src)
    if not job or job.name ~= jobName then return false end
    local grade = job.grade and job.grade.level or 0
    return grade >= (minGrade or 0)
end

---@param src number
---@return string
function Pulse.Players.GetFullName(src)
    local player = Pulse.Server.GetPlayer(src)
    if not player then return 'Unknown' end
    local c = player.PlayerData.charinfo or {}
    return (('%s %s'):format(c.firstname or '', c.lastname or '')):gsub('%s+$', '')
end

---@param number string
---@return number|nil source
function Pulse.Players.GetSourceByNumber(number)
    number = Pulse.Utils.NormalizeNumber(number)
    if not number then return nil end
    return Pulse.Cache.playersByNumber[number]
end
