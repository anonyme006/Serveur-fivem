if not Config.Wallet.enabled then return end

local nuiOpen = false

local function closeWallet()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openWallet()
    if nuiOpen then
        closeWallet()
        return
    end

    local wallet = lib.callback.await('qbx_rp_core:wallet:get', false)
    if not wallet then return end

    local keys = {}
    if Config.Keys.enabled then
        keys = lib.callback.await('qbx_rp_core:keys:list', false) or {}
    end

    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        title = Core.Locale('wallet_title'),
        name = wallet.name,
        accounts = {
            { id = 'cash', label = Core.Locale('wallet_cash'), amount = wallet.accounts.cash or wallet.accounts.money or 0 },
            { id = 'bank', label = Core.Locale('wallet_bank'), amount = wallet.accounts.bank or 0 },
        },
        keysTitle = Core.Locale('wallet_keys'),
        noKeys = Core.Locale('wallet_no_keys'),
        keys = keys,
        labels = {
            give = Core.Locale('wallet_give_key'),
            remove = Core.Locale('wallet_remove_key'),
            vehicle = Core.Locale('wallet_key_vehicle', '%s'),
            house = Core.Locale('wallet_key_house', '%s'),
        },
    })
end

RegisterCommand(Config.Wallet.command or 'portefeuille', function()
    openWallet()
end, false)

RegisterKeyMapping(
    Config.Wallet.command or 'portefeuille',
    'Ouvrir le portefeuille / trousseau',
    'keyboard',
    Config.Wallet.key or 'F4'
)

RegisterNUICallback('close', function(_, cb)
    closeWallet()
    cb(1)
end)

RegisterNUICallback('giveKey', function(data, cb)
    local keyType = data and data.type
    local keyRef = data and data.ref
    if not keyType or not keyRef then
        cb(0)
        return
    end

    local input = lib.inputDialog(Core.Locale('wallet_give_key'), {
        { type = 'number', label = 'ID joueur', required = true, min = 1 },
        { type = 'checkbox', label = 'Temporaire' },
        { type = 'number', label = 'Minutes (si temporaire)', default = 60, min = 1 },
    })

    if not input then
        cb(0)
        return
    end

    TriggerServerEvent('qbx_rp_core:keys:give', input[1], keyType, keyRef, input[2] and true or false, input[3])
    cb(1)
end)

RegisterNUICallback('removeKey', function(data, cb)
    if data and data.id then
        TriggerServerEvent('qbx_rp_core:keys:remove', data.id)
    end
    cb(1)
end)

-- Fallback menu ox_lib si NUI indisponible
RegisterCommand('trousseau', function()
    local keys = lib.callback.await('qbx_rp_core:keys:list', false) or {}
    local options = {}

    if #keys == 0 then
        options[#options + 1] = { title = Core.Locale('wallet_no_keys'), disabled = true }
    else
        for _, key in ipairs(keys) do
            local title = key.type == 'house'
                and Core.Locale('wallet_key_house', key.label or key.ref)
                or Core.Locale('wallet_key_vehicle', key.label or key.ref)

            options[#options + 1] = {
                title = title,
                description = key.temporary and 'Temporaire' or (key.isOwner and 'Propriétaire' or 'Détenteur'),
                icon = key.type == 'house' and 'house' or 'key',
                onSelect = function()
                    lib.registerContext({
                        id = 'qbx_rp_core_key_actions',
                        title = title,
                        menu = 'qbx_rp_core_keychain',
                        options = {
                            {
                                title = Core.Locale('wallet_give_key'),
                                icon = 'hand-holding',
                                onSelect = function()
                                    local input = lib.inputDialog(Core.Locale('wallet_give_key'), {
                                        { type = 'number', label = 'ID joueur', required = true, min = 1 },
                                        { type = 'checkbox', label = 'Temporaire' },
                                        { type = 'number', label = 'Minutes', default = 60 },
                                    })
                                    if input then
                                        TriggerServerEvent('qbx_rp_core:keys:give', input[1], key.type, key.ref, input[2], input[3])
                                    end
                                end,
                            },
                            {
                                title = Core.Locale('wallet_remove_key'),
                                icon = 'trash',
                                disabled = key.implicit or not key.id,
                                onSelect = function()
                                    if key.id then
                                        TriggerServerEvent('qbx_rp_core:keys:remove', key.id)
                                    end
                                end,
                            },
                        },
                    })
                    lib.showContext('qbx_rp_core_key_actions')
                end,
            }
        end
    end

    lib.registerContext({
        id = 'qbx_rp_core_keychain',
        title = Core.Locale('wallet_keys'),
        options = options,
    })
    lib.showContext('qbx_rp_core_keychain')
end, false)
