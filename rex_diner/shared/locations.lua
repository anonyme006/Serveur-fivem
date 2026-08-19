--- Stock item definitions shared by client/server
StockItems = {
    meat = { label = 'Viande', icon = '🥩', max = 200, min = 20, orderPrice = 25 },
    bread = { label = 'Pain', icon = '🍞', max = 200, min = 30, orderPrice = 8 },
    cheese = { label = 'Fromage', icon = '🧀', max = 150, min = 20, orderPrice = 12 },
    lettuce = { label = 'Salade', icon = '🥬', max = 150, min = 20, orderPrice = 6 },
    tomato = { label = 'Tomate', icon = '🍅', max = 150, min = 20, orderPrice = 5 },
    potato = { label = 'Pommes de terre', icon = '🥔', max = 250, min = 40, orderPrice = 4 },
    oil = { label = 'Huile', icon = '🫒', max = 100, min = 15, orderPrice = 10 },
    flour = { label = 'Farine', icon = '🌾', max = 120, min = 20, orderPrice = 5 },
    sugar = { label = 'Sucre', icon = '🍬', max = 120, min = 15, orderPrice = 4 },
    milk = { label = 'Lait', icon = '🥛', max = 100, min = 15, orderPrice = 7 },
    coffee_bean = { label = 'Café (grain)', icon = '☕', max = 100, min = 10, orderPrice = 9 },
    cola_syrup = { label = 'Sirop cola', icon = '🥤', max = 100, min = 10, orderPrice = 8 },
    water = { label = 'Eau', icon = '💧', max = 200, min = 30, orderPrice = 2 },
}

Config.StockItems = StockItems

--- Resolve restaurant config from job name
---@param jobName string|nil
---@return string|nil restaurantKey
---@return table|nil restaurant
function GetRestaurantByJob(jobName)
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
function GetRestaurant(key)
    return Config.Restaurants[key]
end

---@param grade number
---@param permission string
---@return boolean
function HasPermission(grade, permission)
    local perms = Config.Permissions[grade]
    if not perms then
        perms = Config.Permissions[0]
    end
    return perms and perms[permission] == true
end

---@param grade number
---@return number
function GetCommissionRate(grade)
    return Config.Commission[grade] or Config.Commission[0] or 0.10
end

---@param grade number
---@return string
function GetGradeLabel(grade)
    return Config.GradeLabels[grade] or ('Grade %s'):format(grade)
end

--- Locations helper (mirrors Config.Restaurants[*].locations for docs/compat)
Locations = {}
for key, restaurant in pairs(Config.Restaurants) do
    Locations[key] = restaurant.locations
end

Config.Locations = Locations
