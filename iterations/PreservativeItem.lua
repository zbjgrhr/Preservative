require "Preservative/PreservativeCore"

PreservativeItem = PreservativeItem or {}

function PreservativeItem.Normalize(item)
    if not Preservative.isBottle(item) then
        return
    end

    -- Older alpha bottles stored very large spoilage thresholds and therefore
    -- kept the misleading “Fresh” suffix after an update. OffAge 0 suppresses
    -- that suffix; the effectively infinite rotten threshold prevents aging.
    if item.setOffAge then
        item:setOffAge(0)
    end
    if item.setOffAgeMax then
        item:setOffAgeMax(1000000000)
    end
    if item.setAge then
        item:setAge(0)
    end
end

function PreservativeItem.OnCreate(item)
    if not item then
        return
    end
    PreservativeItem.Normalize(item)
    local data = item:getModData()
    if data[Preservative.DATA.charges] == nil then
        data[Preservative.DATA.charges] = Preservative.getBottleLifetimeDays()
        data[Preservative.DATA.activeHours] = 0
    end
end

local function normalizeInventory(playerNum, player)
    local character = player or (getSpecificPlayer and getSpecificPlayer(playerNum or 0))
    if not character or not character:getInventory() then
        return
    end
    local items = character:getInventory():getAllTypeRecurse(Preservative.ID)
    if not items then
        return
    end
    for i = 0, items:size() - 1 do
        PreservativeItem.Normalize(items:get(i))
    end
end

local function normalizeFilledContainer(roomName, containerType, container)
    if not container or not container.getAllTypeRecurse then
        return
    end
    local items = container:getAllTypeRecurse(Preservative.ID)
    if not items then
        return
    end
    for i = 0, items:size() - 1 do
        PreservativeItem.Normalize(items:get(i))
    end
end

Events.OnGameStart.Add(function()
    normalizeInventory(0, getSpecificPlayer and getSpecificPlayer(0) or nil)
end)
Events.OnCreatePlayer.Add(normalizeInventory)
Events.OnFillContainer.Add(normalizeFilledContainer)
