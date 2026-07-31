--[[
    esx_banque — Client
    Banque + DAB avec comptes personnels et entreprise
]]

local isOpen = false
local openMode = nil -- 'bank' | 'atm'
local nearbyATM = nil

local function notify(msg, nType)
    if lib and lib.notify then
        lib.notify({
            title = Translate('bank_title'),
            description = msg,
            type = nType or 'inform',
        })
        return
    end
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    end
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    openMode = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
end

local function openUI(mode)
    if isOpen then return end
    isOpen = true
    openMode = mode

    ESX.TriggerServerCallback('esx_banque:getData', function(data)
        if not data then
            isOpen = false
            openMode = nil
            notify(Translate('player_not_found'), 'error')
            return
        end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            mode = mode,
            data = data,
            currency = Config.Currency,
            locale = Locales[Config.Locale] or Locales['fr'],
        })
    end)
end

-- ─── NUI Callbacks ───────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('deposit', function(payload, cb)
    ESX.TriggerServerCallback('esx_banque:deposit', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(Translate('deposit_success', result.amount), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, payload)
end)

RegisterNUICallback('withdraw', function(payload, cb)
    ESX.TriggerServerCallback('esx_banque:withdraw', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(Translate('withdraw_success', result.amount), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, payload)
end)

RegisterNUICallback('transfer', function(payload, cb)
    ESX.TriggerServerCallback('esx_banque:transfer', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(Translate('transfer_success', result.amount), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, payload)
end)

RegisterNUICallback('addFavorite', function(payload, cb)
    ESX.TriggerServerCallback('esx_banque:addFavorite', function(result)
        cb(result or { ok = false })
        if result and result.ok then
            notify(Translate('recipient_added'), 'success')
        elseif result and result.error then
            notify(result.error, 'error')
        end
    end, payload)
end)

RegisterNUICallback('removeFavorite', function(payload, cb)
    ESX.TriggerServerCallback('esx_banque:removeFavorite', function(result)
        cb(result or { ok = false })
    end, payload)
end)

RegisterNUICallback('getHistory', function(payload, cb)
    ESX.TriggerServerCallback('esx_banque:getHistory', function(result)
        cb(result or { transactions = {} })
    end, payload)
end)

RegisterNUICallback('refresh', function(_, cb)
    ESX.TriggerServerCallback('esx_banque:getData', function(data)
        cb(data or {})
    end)
end)

RegisterNUICallback('exportCsv', function(payload, cb)
    ESX.TriggerServerCallback('esx_banque:getHistory', function(result)
        cb(result or { transactions = {} })
    end, payload)
end)

-- ─── Blips & Markers banque ──────────────────────────────────

CreateThread(function()
    for i = 1, #Config.Banks do
        local bank = Config.Banks[i]
        if bank.blip and bank.blip.enabled then
            local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
            SetBlipSprite(blip, bank.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, bank.blip.scale or 0.8)
            SetBlipColour(blip, bank.blip.colour)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(bank.blip.label or 'Banque')
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    local showing = false
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearBank = false

        for i = 1, #Config.Banks do
            local bank = Config.Banks[i]
            local dist = #(coords - bank.coords)

            if dist < bank.drawDistance then
                sleep = 0
                local m = bank.marker
                DrawMarker(
                    m.type, bank.coords.x, bank.coords.y, bank.coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    m.size.x, m.size.y, m.size.z,
                    m.color.r, m.color.g, m.color.b, m.color.a,
                    false, false, 2, false, nil, nil, false
                )

                if dist < bank.interactDistance then
                    nearBank = true
                    if not isOpen and not showing then
                        showing = true
                        if lib and lib.showTextUI then
                            lib.showTextUI(Translate('open_bank'))
                        end
                    end
                    if not isOpen and IsControlJustReleased(0, 38) then -- E
                        openUI('bank')
                    end
                end
            end
        end

        if showing and (isOpen or not nearBank) then
            showing = false
            if lib and lib.hideTextUI then
                lib.hideTextUI()
            end
        end

        Wait(sleep)
    end
end)

-- ─── DAB (props + positions fixes) ───────────────────────────

local function findNearbyATM(coords)
    for i = 1, #Config.ATMs do
        local atmCoords = Config.ATMs[i]
        if #(coords - atmCoords) < Config.ATMInteractDistance then
            return atmCoords
        end
    end

    for i = 1, #Config.ATMModels do
        local obj = GetClosestObjectOfType(
            coords.x, coords.y, coords.z,
            Config.ATMDrawDistance,
            Config.ATMModels[i],
            false, false, false
        )
        if obj and obj ~= 0 then
            local objCoords = GetEntityCoords(obj)
            if #(coords - objCoords) < Config.ATMInteractDistance then
                return objCoords
            end
        end
    end

    return nil
end

CreateThread(function()
    local showing = false
    while true do
        local sleep = 800
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        nearbyATM = findNearbyATM(coords)

        if nearbyATM and not isOpen then
            sleep = 0
            if not showing then
                showing = true
                if lib and lib.showTextUI then
                    lib.showTextUI(Translate('open_atm'))
                end
            end
            if IsControlJustReleased(0, 38) then
                openUI('atm')
            end
        elseif showing then
            showing = false
            if lib and lib.hideTextUI then
                lib.hideTextUI()
            end
        end

        Wait(sleep)
    end
end)

-- Esc
CreateThread(function()
    while true do
        if isOpen and Config.CloseWithEscape then
            DisableControlAction(0, 200, true)
            if IsDisabledControlJustReleased(0, 200) then
                closeUI()
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)

RegisterNetEvent('esx_banque:notify', function(msg, nType)
    notify(msg, nType)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isOpen then
        SetNuiFocus(false, false)
    end
end)
