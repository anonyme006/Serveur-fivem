--- Carte de permis : lecture live des points (pas de metadata figée)

RegisterNetEvent('qbx_licenses:server:showCard', function(targetViewer)
    local src = source
    targetViewer = tonumber(targetViewer) or src

    -- Le joueur montre sa carte au plus proche (client envoie viewer) ou à lui-même
    TriggerClientEvent('qbx_licenses:client:openCard', targetViewer, src)
end)

--- Donner un item permis au joueur (si ox_inventory)
---@param src number
---@param licenseType string
local function giveLicenseItem(src, licenseType)
    local def = Config.Licenses[licenseType]
    if not def or not def.item then return end
    if GetResourceState('ox_inventory') ~= 'started' then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local charinfo = player.PlayerData.charinfo or {}
    local entry = Licenses.Normalize(
        (player.PlayerData.metadata.licences or {})[licenseType],
        licenseType
    )

    exports.ox_inventory:AddItem(src, def.item, 1, {
        firstname = charinfo.firstname,
        lastname = charinfo.lastname,
        birthdate = charinfo.birthdate,
        citizenid = player.PlayerData.citizenid,
        licenseType = licenseType,
        points = entry.points,
        maxPoints = Licenses.MaxPoints(licenseType),
        owned = entry.owned,
        status = Licenses.IsValid(entry) and 'Valide' or 'Invalide',
        description = ('%s — %s/%s pts'):format(def.label, entry.points, Licenses.MaxPoints(licenseType)),
    })
end

exports('GiveLicenseItem', giveLicenseItem)
