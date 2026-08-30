-- Intégration qbx-duty — Étape 3

TaxiDuty = TaxiDuty or {}

---@return boolean
function TaxiDuty.IsOnDuty()
    return false
end

exports('IsOnDuty', TaxiDuty.IsOnDuty)
