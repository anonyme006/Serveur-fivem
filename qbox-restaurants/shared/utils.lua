Rest = Rest or {}

function Rest.Debug(...)
    if Config.Debug then
        print('[qbox-restaurants]', ...)
    end
end

---@param jobName string|nil
---@return string|nil, table|nil
function Rest.GetRestaurantByJob(jobName)
    if not jobName then return nil, nil end
    for key, restaurant in pairs(Config.Restaurants) do
        if restaurant.job == jobName then
            return key, restaurant
        end
    end
    return nil, nil
end

---@param key string
---@return table|nil
function Rest.GetRestaurant(key)
    return Config.Restaurants[key]
end

---@param grade number
---@param permission string
---@return boolean
function Rest.HasPermission(grade, permission)
    local perms = Config.Permissions[grade] or Config.Permissions[0]
    return perms and perms[permission] == true
end

---@param grade number
---@return number
function Rest.GetCommissionRate(grade)
    return Config.Commission[grade] or Config.Commission[0] or 0.10
end

---@param grade number
---@return string
function Rest.GetGradeLabel(grade)
    return Config.GradeLabels[grade] or ('Grade %s'):format(grade)
end

---@param amount number
---@return string
function Rest.FormatMoney(amount)
    amount = math.floor(tonumber(amount) or 0)
    local formatted = tostring(amount):reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '')
    return ('%s %s'):format(formatted, Config.Currency or '$')
end

---@param seconds number
---@return string
function Rest.FormatDuration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    return ('%02dh%02d'):format(h, m)
end

StockItems = {
    meat         = { label = 'Viande',           icon = '🥩', max = 200, min = 20, orderPrice = 25 },
    bread        = { label = 'Pain',             icon = '🍞', max = 200, min = 30, orderPrice = 8 },
    cheese       = { label = 'Fromage',          icon = '🧀', max = 150, min = 20, orderPrice = 12 },
    lettuce      = { label = 'Salade',           icon = '🥬', max = 150, min = 20, orderPrice = 6 },
    tomato       = { label = 'Tomate',           icon = '🍅', max = 150, min = 20, orderPrice = 5 },
    potato       = { label = 'Pommes de terre',  icon = '🥔', max = 250, min = 40, orderPrice = 4 },
    oil          = { label = 'Huile',            icon = '🫒', max = 100, min = 15, orderPrice = 10 },
    flour        = { label = 'Farine',           icon = '🌾', max = 120, min = 20, orderPrice = 5 },
    sugar        = { label = 'Sucre',            icon = '🍬', max = 120, min = 15, orderPrice = 4 },
    milk         = { label = 'Lait',             icon = '🥛', max = 100, min = 15, orderPrice = 7 },
    coffee_bean  = { label = 'Café (grain)',     icon = '☕', max = 100, min = 10, orderPrice = 9 },
    cola_syrup   = { label = 'Sirop cola',       icon = '🥤', max = 100, min = 10, orderPrice = 8 },
    water        = { label = 'Eau',              icon = '💧', max = 200, min = 30, orderPrice = 2 },
    egg          = { label = 'Œuf',              icon = '🥚', max = 150, min = 20, orderPrice = 5 },
    bacon        = { label = 'Bacon',            icon = '🥓', max = 120, min = 15, orderPrice = 10 },
    ice          = { label = 'Glaçons',          icon = '🧊', max = 100, min = 15, orderPrice = 3 },
    syrup        = { label = 'Sirop',            icon = '🍯', max = 80,  min = 10, orderPrice = 6 },
    orange       = { label = 'Orange',           icon = '🍊', max = 120, min = 15, orderPrice = 4 },
}

Config.StockItems = StockItems

IngredientLabels = {}
for item, data in pairs(StockItems) do
    IngredientLabels[item] = data.label
end
