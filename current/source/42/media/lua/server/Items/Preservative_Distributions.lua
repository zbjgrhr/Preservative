require "Items/ProceduralDistributions"
require "Preservative/PreservativeCore"

local itemType = "Preservative.PreservativeBottle"

local targets = {
    -- Residential kitchens: high relative chance.
    KitchenCannedFood = 4.00,
    KitchenDryFood = 3.00,
    KitchenBottles = 3.00,

    -- Supermarkets, canning supplies and food/farm warehouses: medium.
    CrateCanning = 2.50,
    CrateCannedFood = 2.00,
    GigamartCannedFood = 2.50,
    GigamartDryGoods = 2.00,
    GroceryStorageCrate1 = 2.00,
    GroceryStorageCrate2 = 2.00,
    GroceryStorageCrate3 = 2.00,

    -- Restaurant and commercial kitchens: medium.
    RestaurantKitchenFridge = 2.00,
    BakeryKitchenStorage = 2.00,
    CafeKitchenSupplies = 2.00,
    StoreKitchenCleaning = 1.50,

    -- Cleaning cupboards and garages: extremely low.
    JanitorChemicals = 0.08,
    JanitorCleaning = 0.05,
    GarageTools = 0.04,
}

local multiplier = Preservative.getSpawnMultiplier()
for distributionName, weight in pairs(targets) do
    local distribution = ProceduralDistributions.list[distributionName]
    if multiplier > 0 and distribution and distribution.items then
        table.insert(distribution.items, itemType)
        table.insert(distribution.items, weight * multiplier)
    end
end
