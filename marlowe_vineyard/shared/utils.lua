Marlowe = Marlowe or {}

---@param coords vector3
---@param target vector3
---@param maxDistance number
---@return boolean
function Marlowe.IsNearCoords(coords, target, maxDistance)
    return #(coords - target) <= maxDistance
end

---@param grade number
---@param requiredGrade number
---@return boolean
function Marlowe.HasMinGrade(grade, requiredGrade)
    return grade >= requiredGrade
end

---@param seconds number
---@return string
function Marlowe.FormatDuration(seconds)
    local total = math.max(0, math.floor(seconds))
    local hours = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)
    return ('%02dh%02d'):format(hours, minutes)
end

---@param status string
---@return string
function Marlowe.GetOrderStatusLabel(status)
    local labels = {
        pending = 'En attente',
        accepted = 'Acceptée',
        preparing = 'En préparation',
        ready = 'Prête',
        assigned = 'Assignée',
        delivering = 'En livraison',
        completed = 'Terminée',
        cancelled = 'Annulée',
    }
    return labels[status] or status
end

---@param wineType string
---@return string
function Marlowe.GetWineTypeLabel(wineType)
    local labels = {
        red = 'Vin rouge',
        white = 'Vin blanc',
        rose = 'Vin rosé',
    }
    return labels[wineType] or wineType
end
