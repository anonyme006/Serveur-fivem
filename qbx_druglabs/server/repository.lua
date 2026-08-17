Repository = {}

local LabsCache = {}
local MembersCache = {} ---@type table<number, table[]>
local RentalsCache = {} ---@type table<number, table|nil>
local PlantsCache = {} ---@type table<number, table[]>

local function decodeJson(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return fallback or {} end
    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then return decoded end
    return fallback or {}
end

local function hydrateLab(row)
    if not row then return nil end
    row.entrance = decodeJson(row.entrance)
    row.interior_data = decodeJson(row.interior_data)
    row.stash_data = decodeJson(row.stash_data)
    row.stations_data = decodeJson(row.stations_data)
    row.blip_data = decodeJson(row.blip_data)
    row.locked = row.locked == true or row.locked == 1
    row.sealed = row.sealed == true or row.sealed == 1
    row.enabled = row.enabled == true or row.enabled == 1
    row.purchase_price = tonumber(row.purchase_price) or 0
    row.rent_price = tonumber(row.rent_price) or 0
    row.sell_percentage = tonumber(row.sell_percentage) or Config.Sell.sellPercentage
    row.hasCode = row.access_code_hash ~= nil and row.access_code_hash ~= ''
    -- never expose hash to clients
    row.access_code_hash = nil
    return row
end

local function hydrateMember(row)
    row.permissions = decodeJson(row.permissions, DrugLabs.DefaultMemberPermissions)
    return row
end

function Repository.GetAll()
    return LabsCache
end

function Repository.Get(labId)
    return LabsCache[labId]
end

function Repository.GetByIdentifier(identifier)
    for _, lab in pairs(LabsCache) do
        if lab.identifier == identifier then
            return lab
        end
    end
end

function Repository.GetMembers(labId)
    return MembersCache[labId] or {}
end

function Repository.GetMember(labId, citizenid)
    local members = MembersCache[labId] or {}
    for i = 1, #members do
        if members[i].citizenid == citizenid then
            return members[i]
        end
    end
end

function Repository.GetRental(labId)
    return RentalsCache[labId]
end

function Repository.GetPlants(labId)
    return PlantsCache[labId] or {}
end

function Repository.GetPlant(plantId)
    for labId, plants in pairs(PlantsCache) do
        for i = 1, #plants do
            if plants[i].id == plantId then
                return plants[i], labId
            end
        end
    end
end

function Repository.CountOwnedByCitizen(citizenid)
    local count = 0
    for _, lab in pairs(LabsCache) do
        if lab.ownership_type == 'player' and lab.owner_identifier == citizenid then
            count += 1
        end
        local rental = RentalsCache[lab.id]
        if rental and rental.renter == citizenid and (rental.status == 'active' or rental.status == 'grace') then
            count += 1
        end
    end
    return count
end

local function loadMembers()
    MembersCache = {}
    local rows = MySQL.query.await('SELECT * FROM drug_lab_members') or {}
    for i = 1, #rows do
        local row = hydrateMember(rows[i])
        MembersCache[row.lab_id] = MembersCache[row.lab_id] or {}
        MembersCache[row.lab_id][#MembersCache[row.lab_id] + 1] = row
    end
end

local function loadRentals()
    RentalsCache = {}
    local rows = MySQL.query.await([[
        SELECT * FROM drug_lab_rentals
        WHERE status IN ('active', 'grace')
        ORDER BY id DESC
    ]]) or {}
    for i = 1, #rows do
        local row = rows[i]
        if not RentalsCache[row.lab_id] then
            RentalsCache[row.lab_id] = row
        end
    end
end

local function loadPlants()
    PlantsCache = {}
    local rows = MySQL.query.await('SELECT * FROM drug_lab_plants WHERE harvested = 0') or {}
    for i = 1, #rows do
        local row = rows[i]
        row.growth = tonumber(row.growth) or 0
        row.water = tonumber(row.water) or 0
        row.nutrients = tonumber(row.nutrients) or 0
        row.health = tonumber(row.health) or 0
        row.quality = tonumber(row.quality) or 50
        PlantsCache[row.lab_id] = PlantsCache[row.lab_id] or {}
        PlantsCache[row.lab_id][#PlantsCache[row.lab_id] + 1] = row
    end
end

function Repository.LoadAll()
    LabsCache = {}
    local rows = MySQL.query.await('SELECT * FROM drug_labs WHERE enabled = 1') or {}
    for i = 1, #rows do
        local lab = hydrateLab(rows[i])
        -- keep hash internally for access checks
        local raw = rows[i]
        lab._codeHash = raw.access_code_hash
        LabsCache[lab.id] = lab
    end
    loadMembers()
    loadRentals()
    loadPlants()
    DrugLabs.Debug(('Loaded %s labs'):format(#rows))
end

function Repository.ReloadLab(labId)
    local row = MySQL.single.await('SELECT * FROM drug_labs WHERE id = ?', { labId })
    if not row then
        LabsCache[labId] = nil
        MembersCache[labId] = nil
        RentalsCache[labId] = nil
        PlantsCache[labId] = nil
        return nil
    end
    local hash = row.access_code_hash
    local lab = hydrateLab(row)
    lab._codeHash = hash
    LabsCache[lab.id] = lab

    local members = MySQL.query.await('SELECT * FROM drug_lab_members WHERE lab_id = ?', { labId }) or {}
    MembersCache[labId] = {}
    for i = 1, #members do
        MembersCache[labId][i] = hydrateMember(members[i])
    end

    RentalsCache[labId] = MySQL.single.await([[
        SELECT * FROM drug_lab_rentals
        WHERE lab_id = ? AND status IN ('active', 'grace')
        ORDER BY id DESC LIMIT 1
    ]], { labId })

    local plants = MySQL.query.await('SELECT * FROM drug_lab_plants WHERE lab_id = ? AND harvested = 0', { labId }) or {}
    PlantsCache[labId] = plants
    return lab
end

---@param data table
---@return number|nil insertId
function Repository.CreateLab(data)
    local insertId = MySQL.insert.await([[
        INSERT INTO drug_labs
        (identifier, type, label, ownership_type, purchase_mode, purchase_price, rent_price, sell_percentage,
         locked, access_code_hash, sealed, entrance, interior_data, stash_data, stations_data, blip_data, enabled)
        VALUES (?, ?, ?, 'none', ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, 1)
    ]], {
        data.identifier,
        data.type,
        data.label,
        data.purchaseMode or 'purchase',
        data.purchasePrice or 0,
        data.rentPrice or 0,
        data.sellPercentage or Config.Sell.sellPercentage,
        data.locked and 1 or 0,
        data.codeHash,
        json.encode(data.entrance),
        json.encode(data.interior),
        json.encode(data.stash),
        json.encode(data.stations or {}),
        json.encode(data.blip or {}),
    })
    if insertId then
        Repository.ReloadLab(insertId)
    end
    return insertId
end

function Repository.UpdateLabFields(labId, fields)
    local sets, params = {}, {}
    for column, value in pairs(fields) do
        sets[#sets + 1] = ('`%s` = ?'):format(column)
        if type(value) == 'table' then
            params[#params + 1] = json.encode(value)
        elseif type(value) == 'boolean' then
            params[#params + 1] = value and 1 or 0
        else
            params[#params + 1] = value
        end
    end
    if #sets == 0 then return false end
    params[#params + 1] = labId
    MySQL.update.await(('UPDATE drug_labs SET %s WHERE id = ?'):format(table.concat(sets, ', ')), params)
    return Repository.ReloadLab(labId)
end

function Repository.DeleteLab(labId)
    MySQL.update.await('DELETE FROM drug_labs WHERE id = ?', { labId })
    LabsCache[labId] = nil
    MembersCache[labId] = nil
    RentalsCache[labId] = nil
    PlantsCache[labId] = nil
end

function Repository.SetCodeHash(labId, hash)
    MySQL.update.await('UPDATE drug_labs SET access_code_hash = ? WHERE id = ?', { hash, labId })
    local lab = LabsCache[labId]
    if lab then
        lab._codeHash = hash
        lab.hasCode = hash ~= nil and hash ~= ''
    end
end

function Repository.GetCodeHash(labId)
    local lab = LabsCache[labId]
    return lab and lab._codeHash or nil
end

function Repository.UpsertMember(labId, citizenid, permissions, addedBy)
    local existing = Repository.GetMember(labId, citizenid)
    local encoded = json.encode(permissions or DrugLabs.DefaultMemberPermissions)
    if existing then
        MySQL.update.await('UPDATE drug_lab_members SET permissions = ? WHERE id = ?', { encoded, existing.id })
    else
        MySQL.insert.await(
            'INSERT INTO drug_lab_members (lab_id, citizenid, permissions, added_by) VALUES (?, ?, ?, ?)',
            { labId, citizenid, encoded, addedBy }
        )
    end
    Repository.ReloadLab(labId)
end

function Repository.RemoveMember(labId, citizenid)
    MySQL.update.await('DELETE FROM drug_lab_members WHERE lab_id = ? AND citizenid = ?', { labId, citizenid })
    Repository.ReloadLab(labId)
end

function Repository.CreateRental(labId, renter, expiresAt, graceUntil, autoRenew)
    MySQL.update.await(
        'UPDATE drug_lab_rentals SET status = ? WHERE lab_id = ? AND status IN (?, ?)',
        { 'cancelled', labId, 'active', 'grace' }
    )
    local id = MySQL.insert.await([[
        INSERT INTO drug_lab_rentals (lab_id, renter, expires_at, grace_until, status, auto_renew)
        VALUES (?, ?, FROM_UNIXTIME(?), FROM_UNIXTIME(?), 'active', ?)
    ]], { labId, renter, expiresAt, graceUntil, autoRenew and 1 or 0 })
    Repository.ReloadLab(labId)
    return id
end

function Repository.UpdateRentalStatus(rentalId, status)
    MySQL.update.await('UPDATE drug_lab_rentals SET status = ? WHERE id = ?', { status, rentalId })
end

function Repository.CreatePlant(data)
    local id = MySQL.insert.await([[
        INSERT INTO drug_lab_plants
        (lab_id, station_id, planted_by, growth, water, nutrients, health, quality, planted_at)
        VALUES (?, ?, ?, 0, 70, 60, 100, ?, NOW())
    ]], { data.labId, data.stationId, data.plantedBy, data.quality or 50 })
    Repository.ReloadLab(data.labId)
    return id
end

function Repository.UpdatePlant(plantId, fields)
    local sets, params = {}, {}
    for column, value in pairs(fields) do
        sets[#sets + 1] = ('`%s` = ?'):format(column)
        params[#params + 1] = value
    end
    if #sets == 0 then return end
    params[#params + 1] = plantId
    MySQL.update.await(('UPDATE drug_lab_plants SET %s WHERE id = ?'):format(table.concat(sets, ', ')), params)
    local plant, labId = Repository.GetPlant(plantId)
    if labId then Repository.ReloadLab(labId) end
end

function Repository.CreateBatch(data)
    return MySQL.insert.await([[
        INSERT INTO drug_lab_batches (batch_code, lab_id, producer, item_name, quality, recipe_id, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.batchCode,
        data.labId,
        data.producer,
        data.itemName,
        data.quality,
        data.recipeId,
        json.encode(data.metadata or {}),
    })
end

--- Public client-safe lab payload
function Repository.SerializeLabPublic(lab, includeSensitive)
    if not lab then return nil end
    local rental = RentalsCache[lab.id]
    local payload = {
        id = lab.id,
        identifier = lab.identifier,
        type = lab.type,
        label = lab.label,
        ownershipType = lab.ownership_type,
        ownerIdentifier = lab.owner_identifier,
        ownerGang = lab.owner_gang,
        purchaseMode = lab.purchase_mode,
        purchasePrice = lab.purchase_price,
        rentPrice = lab.rent_price,
        sellPercentage = lab.sell_percentage,
        locked = lab.locked,
        sealed = lab.sealed,
        hasCode = lab.hasCode,
        entrance = lab.entrance,
        interior = lab.interior_data,
        stash = lab.stash_data,
        stations = lab.stations_data,
        blip = lab.blip_data,
        enabled = lab.enabled,
        available = lab.ownership_type == 'none',
        rental = rental and {
            renter = rental.renter,
            status = rental.status,
            expiresAt = rental.expires_at,
            graceUntil = rental.grace_until,
            autoRenew = rental.auto_renew == 1 or rental.auto_renew == true,
        } or nil,
    }
    if includeSensitive then
        payload.members = Repository.GetMembers(lab.id)
        payload.plants = Repository.GetPlants(lab.id)
    end
    return payload
end

function Repository.SerializeAllPublic()
    local list = {}
    for id, lab in pairs(LabsCache) do
        list[#list + 1] = Repository.SerializeLabPublic(lab, false)
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end
