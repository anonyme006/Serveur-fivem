local runs = {}

RegisterNetEvent('rr_gruppe6:server:start', function()
    local src = source
    if runs[src] then
        exports.rr_api:Notify(src, 'Gruppe6', 'Tournée déjà en cours.', 'error')
        return
    end
    if Config.Job then
        local job = exports.rr_api:GetJob(src)
        if not job or job.name ~= Config.Job then
            exports.rr_api:Notify(src, 'Gruppe6', 'Métier Gruppe6 requis (ou retire Config.Job).', 'error')
            return
        end
    end
    local drop = Config.Drops[math.random(1, #Config.Drops)]
    runs[src] = drop
    TriggerClientEvent('rr_gruppe6:client:begin', src, drop)
end)

RegisterNetEvent('rr_gruppe6:server:complete', function()
    local src = source
    local drop = runs[src]
    if not drop then return end
    if not exports.rr_api:DistCheck(src, drop, 8.0) then return end
    runs[src] = nil
    local pay = math.random(Config.Pay.min, Config.Pay.max)
    exports.rr_api:AddMoney(src, 'bank', pay, 'gruppe6')
    exports.rr_api:Notify(src, 'Gruppe6', ('Livraison OK — $%s'):format(pay), 'success')
end)
