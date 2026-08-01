---@diagnostic disable: undefined-global

Utils = {}

--- Convertit m/s en km/h
---@param ms number
---@return number
function Utils.MsToKmh(ms)
    return ms * 3.6
end

--- Arrondi à l'entier le plus proche
---@param n number
---@return integer
function Utils.Round(n)
    return math.floor(n + 0.5)
end

--- Distance 2D entre deux vecteurs
---@param a vector3|vector4|{x:number,y:number,z:number}
---@param b vector3|vector4|{x:number,y:number,z:number}
---@return number
function Utils.Dist2D(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

--- Distance 3D
---@param a vector3|vector4|{x:number,y:number,z:number}
---@param b vector3|vector4|{x:number,y:number,z:number}
---@return number
function Utils.Dist3D(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Différence d'angle normalisée [-180, 180]
---@param a number
---@param b number
---@return number
function Utils.AngleDiff(a, b)
    local d = (a - b + 180.0) % 360.0 - 180.0
    return d
end

--- Calcule la vitesse retenue (réelle - tolérance, min 0)
---@param speed number
---@param tolerance number
---@return integer
function Utils.GetRetainedSpeed(speed, tolerance)
    return math.max(0, Utils.Round(speed) - Utils.Round(tolerance))
end

--- Seuil de flash = limite + tolérance (flash à partir de seuil + 1)
---@param limit number
---@param tolerance number
---@return integer
function Utils.GetFlashThreshold(limit, tolerance)
    return Utils.Round(limit) + Utils.Round(tolerance)
end

--- Montant d'amende selon le barème Config.Fines
--- Règles : < 20 → tier1 | 20–50 → tier2 | > 50 → tier3
---@param excess number Excès en km/h (vitesse retenue - limitation)
---@return integer
function Utils.GetFineAmount(excess)
    if excess <= 0 then
        return 0
    end

    local tiers = Config.Fines
    if not tiers or #tiers == 0 then
        return Config.DefaultFine or 150
    end

    -- Inferieur a maxExcess du 1er palier (ex: < 20)
    if excess < tiers[1].maxExcess then
        return tiers[1].amount
    end

    -- Paliers intermediaires : maxExcess inclus (ex: 20 a 50)
    for i = 2, #tiers - 1 do
        if excess <= tiers[i].maxExcess then
            return tiers[i].amount
        end
    end

    return tiers[#tiers].amount
end

--- Vérifie si un job est dans la liste des métiers autorisés
---@param job string|nil
---@return boolean
function Utils.IsAllowedJob(job)
    if not job or job == '' then
        return false
    end

    local name = string.lower(job)
    for i = 1, #Config.AllowedJobs do
        if string.lower(Config.AllowedJobs[i]) == name then
            return true
        end
    end

    return false
end

--- Label du sens pour l'affichage
---@param direction string
---@return string
function Utils.DirectionLabel(direction)
    for i = 1, #Config.Directions do
        if Config.Directions[i].value == direction then
            return Config.Directions[i].label
        end
    end
    return direction or 'Les deux sens'
end

--- Vérifie si le véhicule circule dans le sens configuré du radar
--- heading radar = orientation enregistrée à la pose
--- heading véhicule = direction de déplacement
---@param radarHeading number
---@param vehicleHeading number
---@param direction string both|forward|backward
---@return boolean
function Utils.IsCorrectDirection(radarHeading, vehicleHeading, direction)
    if not direction or direction == 'both' then
        return true
    end

    local diff = math.abs(Utils.AngleDiff(vehicleHeading, radarHeading))

    if direction == 'forward' then
        -- Même sens que l'orientation du radar
        return diff <= 90.0
    end

    if direction == 'backward' then
        -- Sens opposé
        return diff > 90.0
    end

    return true
end

--- Vérifie que le véhicule est devant le radar (pas derrière)
---@param radarCoords vector3|{x:number,y:number,z:number}
---@param radarHeading number
---@param vehicleCoords vector3|{x:number,y:number,z:number}
---@param frontAngle number|nil
---@return boolean
function Utils.IsInFrontOfRadar(radarCoords, radarHeading, vehicleCoords, frontAngle)
    frontAngle = frontAngle or Config.FrontAngle or 55.0

    -- Vecteur "devant" GTA : heading 0 = Nord (+Y)
    local rad = math.rad(radarHeading)
    local fx = -math.sin(rad)
    local fy = math.cos(rad)

    local dx = vehicleCoords.x - radarCoords.x
    local dy = vehicleCoords.y - radarCoords.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.01 then
        return true
    end

    local ndx, ndy = dx / len, dy / len
    local dot = fx * ndx + fy * ndy
    -- cos(angle) : ex. 55° → ~0.573
    local minDot = math.cos(math.rad(frontAngle))

    return dot >= minDot
end

--- Sérialise les coords pour la BDD
---@param coords vector3|vector4|{x:number,y:number,z:number}
---@return string
function Utils.CoordsToString(coords)
    return ('%.4f, %.4f, %.4f'):format(coords.x, coords.y, coords.z or 0.0)
end

--- Parse une plaque (trim)
---@param plate string|nil
---@return string
function Utils.NormalizePlate(plate)
    if not plate then
        return 'INCONNU'
    end
    return (string.gsub(plate, '^%s*(.-)%s*$', '%1'))
end
