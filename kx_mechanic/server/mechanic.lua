local S = KXMechanicServer

local function applyServiceEffects(data, serviceId, options)
    options = options or {}
    data = Utils.MergeDefaults(data)

    if serviceId == 'repair_engine' then
        data.engine_health = 1000.0
        data.engine_temp = 90.0
    elseif serviceId == 'repair_body' then
        data.body_health = 1000.0
    elseif serviceId == 'repair_brakes' then
        data.brakes_health = 100.0
    elseif serviceId == 'repair_transmission' then
        data.transmission_health = 100.0
    elseif serviceId == 'repair_suspension' then
        data.suspension_health = 100.0
    elseif serviceId == 'repair_clutch' then
        data.clutch_health = 100.0
    elseif serviceId == 'repair_radiator' then
        data.radiator_level = 100.0
        data.engine_temp = 90.0
    elseif serviceId == 'oil_change' then
        data.oil_level = 100.0
        data.last_service = os.date('%Y-%m-%d %H:%M:%S')
    elseif serviceId == 'battery_change' then
        data.battery_level = 100.0
    elseif serviceId == 'spark_plugs' then
        data.spark_plugs = 100.0
    elseif serviceId == 'repair_tire' or serviceId == 'replace_tire' then
        local wheel = options.wheel or 'all'
        if wheel == 'fl' or wheel == 'all' then data.tire_fl = 100.0 end
        if wheel == 'fr' or wheel == 'all' then data.tire_fr = 100.0 end
        if wheel == 'rl' or wheel == 'all' then data.tire_rl = 100.0 end
        if wheel == 'rr' or wheel == 'all' then data.tire_rr = 100.0 end
    elseif serviceId == 'tire_sport' then
        data.tire_type = 'sport'
        data.tire_fl, data.tire_fr, data.tire_rl, data.tire_rr = 100.0, 100.0, 100.0, 100.0
    elseif serviceId == 'tire_drift' then
        data.tire_type = 'drift'
        data.tire_fl, data.tire_fr, data.tire_rl, data.tire_rr = 100.0, 100.0, 100.0, 100.0
    elseif serviceId == 'tire_offroad' then
        data.tire_type = 'offroad'
        data.tire_fl, data.tire_fr, data.tire_rl, data.tire_rr = 100.0, 100.0, 100.0, 100.0
    elseif serviceId == 'tire_race' then
        data.tire_type = 'race'
        data.tire_fl, data.tire_fr, data.tire_rl, data.tire_rr = 100.0, 100.0, 100.0, 100.0
    elseif serviceId == 'engine_1' or serviceId == 'engine_2' or serviceId == 'engine_3' or serviceId == 'engine_4' then
        data.performance.engine = serviceId
    elseif serviceId == 'brakes_sport' or serviceId == 'brakes_race' then
        data.performance.brakes = serviceId
    elseif serviceId == 'transmission_sport' or serviceId == 'transmission_race' then
        data.performance.transmission = serviceId
    elseif serviceId == 'suspension_sport' or serviceId == 'suspension_race' then
        data.performance.suspension = serviceId
    elseif serviceId == 'turbo' then
        data.performance.turbo = 'on'
    elseif serviceId == 'armor_1' or serviceId == 'armor_2' or serviceId == 'armor_3' then
        data.performance.armor = serviceId
    elseif serviceId == 'paint_primary' and options.color ~= nil then
        data.cosmetics.primary = options.color
    elseif serviceId == 'paint_secondary' and options.color ~= nil then
        data.cosmetics.secondary = options.color
    elseif serviceId == 'wheels' and options.wheelType ~= nil then
        data.cosmetics.wheels = options.wheelType
    end

    return data
end

local function buildDiagnostic(data, native)
    data = Utils.MergeDefaults(data)
    local enginePct = Utils.Percent(native and native.engine or data.engine_health, 1000)
    local bodyPct = Utils.Percent(native and native.body or data.body_health, 1000)

    return {
        plate = data.plate,
        mileage = Utils.Round(data.mileage or 0, 1),
        last_service = data.last_service,
        tire_type = data.tire_type,
        performance = data.performance,
        components = {
            { id = 'engine', label = 'MOTEUR', percent = enginePct, bar = Utils.HealthBar(enginePct) },
            { id = 'body', label = 'CARROSSERIE', percent = bodyPct, bar = Utils.HealthBar(bodyPct) },
            { id = 'transmission', label = 'TRANSMISSION', percent = Utils.Percent(data.transmission_health), bar = Utils.HealthBar(data.transmission_health) },
            { id = 'brakes', label = 'FREINS', percent = Utils.Percent(data.brakes_health), bar = Utils.HealthBar(data.brakes_health) },
            { id = 'suspension', label = 'SUSPENSION', percent = Utils.Percent(data.suspension_health), bar = Utils.HealthBar(data.suspension_health) },
            { id = 'clutch', label = 'EMBRAYAGE', percent = Utils.Percent(data.clutch_health), bar = Utils.HealthBar(data.clutch_health) },
            { id = 'oil', label = 'HUILE', percent = Utils.Percent(data.oil_level), bar = Utils.HealthBar(data.oil_level) },
            { id = 'battery', label = 'BATTERIE', percent = Utils.Percent(data.battery_level), bar = Utils.HealthBar(data.battery_level) },
            { id = 'radiator', label = 'RADIATEUR', percent = Utils.Percent(data.radiator_level), bar = Utils.HealthBar(data.radiator_level) },
            { id = 'spark_plugs', label = 'BOUGIES', percent = Utils.Percent(data.spark_plugs), bar = Utils.HealthBar(data.spark_plugs) },
            { id = 'fuel', label = 'CARBURANT', percent = Utils.Percent(native and native.fuel or data.fuel), bar = Utils.HealthBar(native and native.fuel or data.fuel) },
            { id = 'temp', label = 'TEMPÉRATURE', percent = Utils.Clamp(Utils.Round(((native and native.temp or data.engine_temp) / 130) * 100, 0), 0, 100), raw = native and native.temp or data.engine_temp },
        },
        tires = {
            { id = 'fl', label = 'Avant gauche', percent = Utils.Percent(data.tire_fl) },
            { id = 'fr', label = 'Avant droit', percent = Utils.Percent(data.tire_fr) },
            { id = 'rl', label = 'Arrière gauche', percent = Utils.Percent(data.tire_rl) },
            { id = 'rr', label = 'Arrière droit', percent = Utils.Percent(data.tire_rr) },
        },
    }
end

lib.callback.register('kx_mechanic:server:getVehicleData', function(source, plate, nativeSnapshot)
    local ok = HasMechanicPermission(source, 'diagnose')
    if not ok and not IsMechanic(source) then
        -- owners can still load their own vehicle data for wear sync
    end

    plate = Utils.NormalizePlate(plate)
    if not plate then return nil end

    local data = Database.GetVehicle(plate)
    if not data then
        data = Utils.MergeDefaults({ plate = plate })
        if nativeSnapshot then
            data.engine_health = nativeSnapshot.engine or data.engine_health
            data.body_health = nativeSnapshot.body or data.body_health
            data.fuel = nativeSnapshot.fuel or data.fuel
        end
        Database.UpsertVehicle(plate, data)
        data = Database.GetVehicle(plate)
    end

    data.plate = plate
    return data
end)

lib.callback.register('kx_mechanic:server:diagnose', function(source, plate, nativeSnapshot)
    if not S.checkCooldown(source, 'diagnose') then
        return { ok = false, message = 'Veuillez patienter.' }
    end

    local allowed = HasMechanicPermission(source, 'diagnose')
    if not allowed then
        return { ok = false, message = 'Vous devez être mécanicien.' }
    end

    plate = Utils.NormalizePlate(plate)
    if not plate then
        return { ok = false, message = 'Véhicule invalide.' }
    end

    local data = Database.GetVehicle(plate) or Utils.MergeDefaults({ plate = plate })
    if nativeSnapshot then
        data.engine_health = nativeSnapshot.engine or data.engine_health
        data.body_health = nativeSnapshot.body or data.body_health
        data.fuel = nativeSnapshot.fuel or data.fuel
        data.engine_temp = nativeSnapshot.temp or data.engine_temp
    end
    data.plate = plate
    Database.UpsertVehicle(plate, data)

    return {
        ok = true,
        message = 'Diagnostic terminé.',
        report = buildDiagnostic(data, nativeSnapshot),
        price = Config.Prices.diagnose,
    }
end)

lib.callback.register('kx_mechanic:server:startService', function(source, payload)
    if type(payload) ~= 'table' then
        return { ok = false, message = 'Requête invalide.' }
    end

    if not S.checkCooldown(source, 'service') then
        return { ok = false, message = 'Veuillez patienter.' }
    end

    if S.isBusy(source) then
        return { ok = false, message = 'Une intervention est déjà en cours.' }
    end

    local serviceId = payload.serviceId
    local service = Utils.GetService(serviceId)
    if not service then
        return { ok = false, message = 'Service inconnu.' }
    end

    local permissionMap = {
        diagnostic = 'diagnose',
        repair = 'repair',
        body = 'body',
        tires = 'tires',
        maintenance = 'maintenance',
        performance = 'performance',
    }

    local requiredPerm = permissionMap[service.category] or 'repair'
    local allowed, player, job = HasMechanicPermission(source, requiredPerm)
    if not allowed then
        return { ok = false, message = 'Permission insuffisante.' }
    end

    if service.category == 'performance' and not Config.EnablePerformance then
        return { ok = false, message = 'Les performances sont désactivées.' }
    end

    if service.category == 'maintenance' and not Config.EnableMaintenance then
        return { ok = false, message = 'L\'entretien est désactivé.' }
    end

    local plate = Utils.NormalizePlate(payload.plate)
    if not plate then
        return { ok = false, message = 'Véhicule invalide.' }
    end

    local required = Utils.GetRequiredItems(serviceId)
    if #required > 0 then
        for i = 1, #required do
            local entry = required[i]
            local count = exports.ox_inventory:GetItemCount(source, entry.item) or 0
            if count < entry.count then
                return {
                    ok = false,
                    message = ('Vous n\'avez pas les pièces nécessaires. (%s)'):format(Utils.GetItemLabel(entry.item)),
                }
            end
        end
    end

    S.setBusy(source, true)

    return {
        ok = true,
        token = ('%s:%s:%s'):format(source, serviceId, GetGameTimer()),
        duration = Utils.GetServiceDuration(serviceId),
        label = service.label,
        animation = Config.Animations[serviceId] or Config.Animations.default,
        price = Utils.GetServicePrice(serviceId),
        materials = required,
    }
end)

lib.callback.register('kx_mechanic:server:completeService', function(source, payload)
    S.setBusy(source, false)

    if type(payload) ~= 'table' or not payload.completed then
        return { ok = false, message = 'Intervention annulée.' }
    end

    if not S.checkCooldown(source, 'complete') then
        return { ok = false, message = 'Veuillez patienter.' }
    end

    local serviceId = payload.serviceId
    local service = Utils.GetService(serviceId)
    if not service then
        return { ok = false, message = 'Service inconnu.' }
    end

    local allowed, player = HasMechanicPermission(source, 'repair')
    if not allowed and service.category ~= 'diagnostic' then
        local map = {
            diagnostic = 'diagnose',
            body = 'body',
            tires = 'tires',
            maintenance = 'maintenance',
            performance = 'performance',
        }
        allowed, player = HasMechanicPermission(source, map[service.category] or 'repair')
    end

    if not allowed then
        return { ok = false, message = 'Vous devez être mécanicien.' }
    end

    local plate = Utils.NormalizePlate(payload.plate)
    if not plate then
        return { ok = false, message = 'Véhicule invalide.' }
    end

    local parts = Utils.GetRequiredItems(serviceId)
    if #parts > 0 then
        local removed, missing = S.removeItems(source, parts)
        if not removed then
            return {
                ok = false,
                message = ('Vous n\'avez pas les pièces nécessaires. (%s)'):format(Utils.GetItemLabel(missing)),
            }
        end

        for i = 1, #parts do
            Database.LogStock('consume', parts[i].item, parts[i].count, player.PlayerData.citizenid, S.getPlayerName(player), serviceId)
        end
    end

    local data = Database.GetVehicle(plate) or Utils.MergeDefaults({ plate = plate })
    if payload.native then
        data.engine_health = payload.native.engine or data.engine_health
        data.body_health = payload.native.body or data.body_health
        data.fuel = payload.native.fuel or data.fuel
    end

    data = applyServiceEffects(data, serviceId, payload.options or {})
    data.plate = plate
    Database.UpsertVehicle(plate, data)

    if serviceId == 'oil_change' or service.category == 'maintenance' then
        Database.MarkServiced(plate)
    end

    local price = Utils.GetServicePrice(serviceId)
    local partsCount = 0
    for i = 1, #parts do partsCount = partsCount + parts[i].count end

    Database.LogRepair({
        plate = plate,
        vehicle_model = payload.model or 'unknown',
        customer_citizenid = payload.customerCitizenId,
        customer_name = payload.customerName,
        mechanic_citizenid = player.PlayerData.citizenid,
        mechanic_name = S.getPlayerName(player),
        repair_type = serviceId,
        repair_label = service.label,
        price = price,
        parts_used = parts,
    })

    Database.RecordStats(player.PlayerData.citizenid, S.getPlayerName(player), price, 1, 1, partsCount)

    return {
        ok = true,
        message = 'Réparation terminée.',
        vehicle = data,
        service = Utils.BuildServicePayload(serviceId),
        apply = {
            serviceId = serviceId,
            options = payload.options or {},
            performance = data.performance,
            cosmetics = data.cosmetics,
            tire_type = data.tire_type,
        },
    }
end)

lib.callback.register('kx_mechanic:server:cancelService', function(source)
    S.setBusy(source, false)
    return true
end)

lib.callback.register('kx_mechanic:server:saveVehicleState', function(source, plate, state)
    plate = Utils.NormalizePlate(plate)
    if not plate or type(state) ~= 'table' then return false end

    local existing = Database.GetVehicle(plate) or Utils.MergeDefaults({ plate = plate })
    for key, value in pairs(state) do
        if key ~= 'performance' and key ~= 'cosmetics' and key ~= 'plate' then
            existing[key] = value
        end
    end
    if type(state.performance) == 'table' then
        for k, v in pairs(state.performance) do existing.performance[k] = v end
    end
    if type(state.cosmetics) == 'table' then
        for k, v in pairs(state.cosmetics) do existing.cosmetics[k] = v end
    end

    Database.UpsertVehicle(plate, existing)
    return true
end)

-- Lifts
lib.callback.register('kx_mechanic:server:liftAction', function(source, liftId, action, netId, plate)
    local allowed = HasMechanicPermission(source, 'lift')
    if not allowed then
        return { ok = false, message = 'Vous devez être mécanicien.' }
    end

    if not Config.EnableLifts then
        return { ok = false, message = 'Les ponts sont désactivés.' }
    end

    if not S.checkCooldown(source, 'lift') then
        return { ok = false, message = 'Veuillez patienter.' }
    end

    local state = S.liftStates[liftId]
    if not state then
        return { ok = false, message = 'Pont introuvable.' }
    end

    if action == 'attach' then
        if state.netId then
            return { ok = false, message = 'Un véhicule est déjà sur ce pont.' }
        end
        state.netId = netId
        state.plate = Utils.NormalizePlate(plate)
        state.locked = true
        state.raised = false
    elseif action == 'raise' then
        if not state.netId then
            return { ok = false, message = 'Aucun véhicule sur le pont.' }
        end
        state.raised = true
        state.locked = true
    elseif action == 'lower' then
        if not state.netId then
            return { ok = false, message = 'Aucun véhicule sur le pont.' }
        end
        state.raised = false
    elseif action == 'detach' then
        if state.raised then
            return { ok = false, message = 'Descendez d\'abord le véhicule.' }
        end
        state.netId = nil
        state.plate = nil
        state.locked = false
        state.raised = false
    else
        return { ok = false, message = 'Action invalide.' }
    end

    GlobalState.kx_mechanic_lifts = S.liftStates
    TriggerClientEvent('kx_mechanic:client:syncLift', -1, liftId, state)

    return { ok = true, state = state }
end)

-- Billing
lib.callback.register('kx_mechanic:server:createInvoice', function(source, payload)
    if not Config.EnableBilling then
        return { ok = false, message = 'Facturation désactivée.' }
    end

    local allowed, player = HasMechanicPermission(source, 'billing')
    if not allowed then
        return { ok = false, message = 'Permission insuffisante.' }
    end

    if not S.checkCooldown(source, 'invoice') then
        return { ok = false, message = 'Veuillez patienter.' }
    end

    if type(payload) ~= 'table' or type(payload.items) ~= 'table' or #payload.items == 0 then
        return { ok = false, message = 'Facture invalide.' }
    end

    local targetId = tonumber(payload.targetId)
    local target = targetId and S.getPlayer(targetId) or nil
    if not target then
        return { ok = false, message = 'Client introuvable.' }
    end

    local items = {}
    local total = 0
    for i = 1, #payload.items do
        local serviceId = payload.items[i]
        local service = Utils.GetService(serviceId)
        if service then
            local price = Utils.GetServicePrice(serviceId)
            items[#items + 1] = { id = serviceId, label = service.label, price = price }
            total = total + price
        end
    end

    if total <= 0 then
        return { ok = false, message = 'Montant invalide.' }
    end

    local invoiceNumber = Utils.GenerateNumber('INV')
    local id = Database.CreateInvoice({
        invoice_number = invoiceNumber,
        mechanic_citizenid = player.PlayerData.citizenid,
        mechanic_name = S.getPlayerName(player),
        customer_citizenid = target.PlayerData.citizenid,
        customer_name = S.getPlayerName(target),
        customer_source = targetId,
        items = items,
        total = total,
    })

    S.pendingInvoices[id] = {
        mechanic = source,
        customer = targetId,
        total = total,
        expires = os.time() + Config.InvoiceTimeout,
    }

    TriggerClientEvent('kx_mechanic:client:receiveInvoice', targetId, {
        id = id,
        number = invoiceNumber,
        mechanic = S.getPlayerName(player),
        items = items,
        total = total,
    })

    return { ok = true, message = 'Facture envoyée.', id = id, number = invoiceNumber, total = total }
end)

lib.callback.register('kx_mechanic:server:respondInvoice', function(source, invoiceId, accept)
    invoiceId = tonumber(invoiceId)
    local invoice = invoiceId and Database.GetInvoice(invoiceId) or nil
    if not invoice or invoice.status ~= 'pending' then
        return { ok = false, message = 'Facture introuvable.' }
    end

    local player = S.getPlayer(source)
    if not player or player.PlayerData.citizenid ~= invoice.customer_citizenid then
        return { ok = false, message = 'Cette facture ne vous appartient pas.' }
    end

    if not accept then
        Database.UpdateInvoiceStatus(invoiceId, 'declined')
        local pending = S.pendingInvoices[invoiceId]
        if pending then
            Utils.Notify(pending.mechanic, 'Le client a refusé la facture.', 'error')
            S.pendingInvoices[invoiceId] = nil
        end
        return { ok = true, message = 'Facture refusée.' }
    end

    local cash = exports.qbx_core:GetMoney(source, 'cash') or 0
    local bank = exports.qbx_core:GetMoney(source, 'bank') or 0
    local account = cash >= invoice.total and 'cash' or (bank >= invoice.total and 'bank' or nil)
    if not account then
        return { ok = false, message = 'Fonds insuffisants.' }
    end

    local removed = exports.qbx_core:RemoveMoney(source, account, invoice.total, 'kx-mechanic-invoice')
    if not removed then
        return { ok = false, message = 'Paiement impossible.' }
    end

    Database.UpdateInvoiceStatus(invoiceId, 'paid')
    S.addSocietyMoney(invoice.total)

    local pending = S.pendingInvoices[invoiceId]
    if pending then
        Utils.Notify(pending.mechanic, ('Facture payée : %s'):format(Utils.FormatMoney(invoice.total)), 'success')
        local mech = S.getPlayer(pending.mechanic)
        if mech then
            Database.RecordStats(mech.PlayerData.citizenid, S.getPlayerName(mech), invoice.total, 0, 0, 0)
        end
        S.pendingInvoices[invoiceId] = nil
    end

    return { ok = true, message = 'Facture payée.' }
end)

-- Orders
lib.callback.register('kx_mechanic:server:getOrders', function(source)
    local allowed = HasMechanicPermission(source, 'orders')
    if not allowed then return { ok = false, orders = {} } end
    return { ok = true, orders = Database.GetOrders(50), catalog = Config.OrderCatalog, suppliers = Config.Suppliers }
end)

lib.callback.register('kx_mechanic:server:createOrder', function(source, product, quantity)
    local allowed, player = HasMechanicPermission(source, 'orders')
    if not allowed then
        return { ok = false, message = 'Permission insuffisante.' }
    end

    if not Config.EnableOrders then
        return { ok = false, message = 'Commandes désactivées.' }
    end

    if not S.checkCooldown(source, 'order') then
        return { ok = false, message = 'Veuillez patienter.' }
    end

    quantity = math.floor(tonumber(quantity) or 0)
    if quantity < 1 or quantity > 100 then
        return { ok = false, message = 'Quantité invalide.' }
    end

    local catalog = Utils.GetOrderProduct(product)
    if not catalog then
        return { ok = false, message = 'Produit inconnu.' }
    end

    local total = catalog.unitPrice * quantity
    S.removeSocietyMoney(total)

    local orderNumber = Utils.GenerateNumber('ORD')
    local id = Database.CreateOrder({
        order_number = orderNumber,
        supplier = catalog.supplier,
        product = catalog.item,
        product_label = catalog.label,
        quantity = quantity,
        unit_price = catalog.unitPrice,
        total_price = total,
        ordered_by = player.PlayerData.citizenid,
        ordered_by_name = S.getPlayerName(player),
    })

    local supplier = Utils.GetSupplier(catalog.supplier)
    local delayMin = supplier and supplier.deliveryMinutes.min or 2
    local delayMax = supplier and supplier.deliveryMinutes.max or 5
    local delay = math.random(delayMin, delayMax) * 60 * 1000

    CreateThread(function()
        Wait(math.floor(delay * 0.35))
        Database.UpdateOrderStatus(id, 'preparing')
        Wait(math.floor(delay * 0.35))
        Database.UpdateOrderStatus(id, 'shipping')
        Wait(math.floor(delay * 0.30))

        local order = Database.GetOrder(id)
        if not order or order.status == 'cancelled' then return end

        exports.ox_inventory:AddItem(Config.Locations.stash.id, catalog.item, quantity)
        Database.UpdateOrderStatus(id, 'delivered')
        Database.LogStock('order_delivery', catalog.item, quantity, player.PlayerData.citizenid, S.getPlayerName(player), orderNumber)

        local online = exports.qbx_core:GetPlayerByCitizenId(player.PlayerData.citizenid)
        if online then
            Utils.Notify(online.PlayerData.source, ('Commande %s livrée.'):format(orderNumber), 'success')
        end
    end)

    return {
        ok = true,
        message = 'Commande passée.',
        order = {
            id = id,
            number = orderNumber,
            product = catalog.label,
            quantity = quantity,
            total = total,
            status = 'pending',
        },
    }
end)

-- Employees
lib.callback.register('kx_mechanic:server:getEmployees', function(source)
    local allowed = HasMechanicPermission(source, 'employees')
    if not allowed then return { ok = false, employees = {} } end
    return { ok = true, employees = Database.GetEmployees(), grades = Config.Grades }
end)

lib.callback.register('kx_mechanic:server:hireEmployee', function(source, targetId)
    local allowed, boss = HasMechanicPermission(source, 'employees')
    if not allowed then
        return { ok = false, message = 'Permission insuffisante.' }
    end

    targetId = tonumber(targetId)
    local target = targetId and S.getPlayer(targetId) or nil
    if not target then
        return { ok = false, message = 'Joueur introuvable.' }
    end

    exports.qbx_core:SetJob(targetId, Config.Job, 0)
    Database.UpsertEmployee(target.PlayerData.citizenid, S.getPlayerName(target), 0, Config.Grades[0].salary, boss.PlayerData.citizenid)
    Utils.Notify(targetId, 'Vous avez été recruté chez Los Santos Customs.', 'success')

    return { ok = true, message = 'Employé recruté.' }
end)

lib.callback.register('kx_mechanic:server:fireEmployee', function(source, citizenid)
    local allowed = HasMechanicPermission(source, 'employees')
    if not allowed then
        return { ok = false, message = 'Permission insuffisante.' }
    end

    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then
        exports.qbx_core:SetJob(target.PlayerData.source, 'unemployed', 0)
        Utils.Notify(target.PlayerData.source, 'Vous avez été licencié.', 'error')
    end

    Database.SetEmployeeActive(citizenid, false)
    return { ok = true, message = 'Employé licencié.' }
end)

lib.callback.register('kx_mechanic:server:setEmployeeGrade', function(source, citizenid, grade)
    local allowed = HasMechanicPermission(source, 'employees')
    if not allowed then
        return { ok = false, message = 'Permission insuffisante.' }
    end

    grade = math.floor(tonumber(grade) or -1)
    if not Config.Grades[grade] then
        return { ok = false, message = 'Grade invalide.' }
    end

    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then
        exports.qbx_core:SetJob(target.PlayerData.source, Config.Job, grade)
        Utils.Notify(target.PlayerData.source, ('Nouveau grade : %s'):format(Config.Grades[grade].label), 'inform')
    end

    Database.UpdateEmployeeGrade(citizenid, grade, Config.Grades[grade].salary)
    return { ok = true, message = 'Grade mis à jour.' }
end)

-- Dashboard / history / stock
lib.callback.register('kx_mechanic:server:getDashboard', function(source)
    local allowed = HasMechanicPermission(source, 'dashboard')
    if not allowed then
        return { ok = false, message = 'Permission insuffisante.' }
    end

    local dash = Database.GetDashboard()
    local lowStock = {}

    for i = 1, #Config.StashItems do
        local item = Config.StashItems[i]
        local count = exports.ox_inventory:GetItemCount(Config.Locations.stash.id, item) or 0
        if count <= Config.LowStockThreshold then
            lowStock[#lowStock + 1] = {
                item = item,
                label = Utils.GetItemLabel(item),
                count = count,
            }
        end
    end

    dash.lowStock = lowStock
    return { ok = true, data = dash }
end)

lib.callback.register('kx_mechanic:server:getHistory', function(source, plate)
    local allowed = HasMechanicPermission(source, 'dashboard')
    if not allowed then return { ok = false, history = {} } end
    return { ok = true, history = Database.GetRepairHistory(75, plate) }
end)

lib.callback.register('kx_mechanic:server:getStockLog', function(source)
    local allowed = HasMechanicPermission(source, 'stock')
    if not allowed then return { ok = false, log = {} } end
    return { ok = true, log = Database.GetStockLog(50) }
end)

lib.callback.register('kx_mechanic:server:toggleDuty', function(source)
    local player = S.getPlayer(source)
    if not player then return false end
    local job = S.getJobData(player)
    if not job or job.name ~= Config.Job then
        Utils.Notify(source, 'Vous devez être mécanicien.', 'error')
        return false
    end

    local newDuty = not job.onduty
    exports.qbx_core:SetJobDuty(source, newDuty)
    Utils.Notify(source, newDuty and 'Vous êtes en service.' or 'Vous êtes hors service.', 'inform')
    return newDuty
end)

-- Wear sync from client driver tick
RegisterNetEvent('kx_mechanic:server:updateWear', function(plate, wearDelta)
    local src = source
    plate = Utils.NormalizePlate(plate)
    if not plate or type(wearDelta) ~= 'table' then return end
    if not S.checkCooldown(src, 'wear') then return end

    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return end

    local data = Database.GetVehicle(plate) or Utils.MergeDefaults({ plate = plate })
    for key, value in pairs(wearDelta) do
        if type(data[key]) == 'number' and type(value) == 'number' then
            if key == 'mileage' then
                data[key] = (data[key] or 0) + value
            elseif key == 'engine_temp' then
                data[key] = Utils.Clamp(value, 70.0, 130.0)
            else
                data[key] = Utils.Clamp((data[key] or 100) - value, Config.Wear.minComponentHealth, 100.0)
            end
        end
    end

    Database.UpsertVehicle(plate, data)
end)