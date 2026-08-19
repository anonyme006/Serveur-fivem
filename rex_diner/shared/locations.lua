--- Mirror restaurant locations for docs / quick access
Locations = {}

for key, restaurant in pairs(Config.Restaurants) do
    Locations[key] = restaurant.locations
end

Config.Locations = Locations
