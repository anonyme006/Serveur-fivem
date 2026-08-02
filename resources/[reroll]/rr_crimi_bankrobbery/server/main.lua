local state = {}

local function copsOnline()
    local n = 0
    for _, id in pairs(GetPlayers()) do
        if exports.rr_api:HasPoliceJob(tonumber(id), true) then n = n + 1 end
    end
    return n
end

lib.callback.register('rr_crimi_bankrobbery:server:canStart', function(source, bankId)
    local bank
    for _, b in ipairs(Config.Banks) do if b.id == bankId then bank = b break end end
    if not bank then return false end
    if not exports.rr_api:DistCheck(source, bank.hack, 4.0) then return false end
    local st = state[bankId]
    if st and (os.time() - st.last) < Config.Cooldown then
        exports.rr_api:Notify(source, 'Braquage', 'Cette banque est en cooldown.', 'error')
        return false
    end
    if copsOnline() < Config.MinCops then
        exports.rr_api:Notify(source, 'Braquage', 'Pas assez de policiers.', 'error')
        return false
    end
    return true
end)

RegisterNetEvent('rr_crimi_bankrobbery:server:hacked', function(bankId)
    local src = source
    state[bankId] = state[bankId] or {}
    state[bankId].open = true
    state[bankId].last = os.time()
    state[bankId].looted = false
    exports.rr_api:Notify(src, 'Braquage', 'Panneau hacké — vide le coffre.', 'success')
    local bank
    for _, b in ipairs(Config.Banks) do if b.id == bankId then bank = b break end end
    if bank and GetResourceState('rr_dispatch') == 'started' then
        exports.rr_dispatch:Alert('10-90', 'Braquage de banque: ' .. bank.label, { x = bank.hack.x, y = bank.hack.y, z = bank.hack.z })
    end
end)

RegisterNetEvent('rr_crimi_bankrobbery:server:loot', function(bankId)
    local src = source
    local st = state[bankId]
    if not st or not st.open or st.looted then
        exports.rr_api:Notify(src, 'Braquage', 'Coffre indisponible.', 'error')
        return
    end
    local bank
    for _, b in ipairs(Config.Banks) do if b.id == bankId then bank = b break end end
    if not bank or not exports.rr_api:DistCheck(src, bank.vault, 4.0) then return end
    st.looted = true
    local reward = math.random(Config.RewardMin, Config.RewardMax)
    exports.ox_inventory:AddItem(src, Config.RewardItem, reward)
    exports.rr_api:Notify(src, 'Braquage', ('Tu récupères %s d\'argent sale.'):format(reward), 'success')
end)
