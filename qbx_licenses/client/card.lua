local cardOpen = false
local cardOwner = nil

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    cardOpen = state
    if not state then
        cardOwner = nil
    end
end

---@param ownerSrc number
local function openCard(ownerSrc)
    if not Config.Card or Config.Card.enabled == false then return end

    ownerSrc = tonumber(ownerSrc) or cache.serverId
    local data = lib.callback.await('qbx_licenses:getCardData', false, ownerSrc)
    if not data then
        return lib.notify({ title = 'Permis', description = L('no_player'), type = 'error' })
    end

    cardOwner = ownerSrc
    setFocus(true)
    SendNUIMessage({
        action = 'open',
        card = data,
        closeKey = Config.Card.closeKey or 'Backspace',
        autoCloseMs = Config.Card.autoCloseMs or 0,
    })
end

local function closeCard()
    if not cardOpen then return end
    setFocus(false)
    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('qbx_licenses:client:openCard', openCard)

RegisterNetEvent('qbx_licenses:client:refreshCard', function(ownerSrc)
    if not cardOpen then return end
    ownerSrc = tonumber(ownerSrc) or cardOwner
    if not ownerSrc then return end

    local data = lib.callback.await('qbx_licenses:getCardData', false, ownerSrc)
    if not data then return end

    SendNUIMessage({
        action = 'update',
        card = data,
    })
end)

RegisterNUICallback('closeCard', function(_, cb)
    closeCard()
    cb(1)
end)

-- Fermeture clavier côté NUI ; fallback
CreateThread(function()
    while true do
        if cardOpen then
            if IsControlJustReleased(0, 177) or IsControlJustReleased(0, 200) then -- Backspace / Pause
                closeCard()
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)

exports('ShowLicenseCard', openCard)

--- Export ox_inventory (client.export = 'qbx_licenses.useLicenseCard')
exports('useLicenseCard', function(data, slot)
    openCard(cache.serverId)
end)
