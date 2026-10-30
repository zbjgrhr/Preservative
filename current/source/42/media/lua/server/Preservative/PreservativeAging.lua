require "Preservative/PreservativeCore"
require "Preservative/PreservativeItem"

local GROUND_RADIUS = 3

local function worldHours()
    return getGameTime() and getGameTime():getWorldAgeHours() or 0
end

local function resolveContainerDomain(container)
    if not container then return nil end
    local current = container
    for _ = 1, 16 do
        if current.getCharacter then
            local character = current:getCharacter()
            if character then return character, current end
        end
        if current.getVehicle then
            local vehicle = current:getVehicle()
            if vehicle then return vehicle, current end
        end
        local containingItem = current.getContainingItem and current:getContainingItem() or nil
        local parentContainer = containingItem and containingItem:getContainer() or nil
        if not parentContainer or parentContainer == current then
            return current, current
        end
        current = parentContainer
    end
    return current, current
end

local function groundSquare(item)
    local worldItem = item and item.getWorldItem and item:getWorldItem() or nil
    return worldItem and worldItem:getSquare() or nil
end

local function buildProtectionStates(items)
    local domains = {}
    local ground = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if Preservative.isBottle(item) and Preservative.getCharges(item) > 0 then
            PreservativeItem.Normalize(item)
            local container = item:getContainer()
            if container then
                local key, root = resolveContainerDomain(container)
                if key and not domains[key] then
                    domains[key] = {
                        bottle = item,
                        root = root,
                        cold = Preservative.isColdStorage(root),
                        hasFood = false,
                    }
                end
            else
                local square = groundSquare(item)
                if square then
                    table.insert(ground, {
                        bottle = item,
                        square = square,
                        hasFood = false,
                        cold = false,
                    })
                end
            end
        end
    end
    return domains, ground
end

local function nearestGroundState(food, states)
    local square = groundSquare(food)
    if not square then return nil end
    local best, bestDistance
    for _, state in ipairs(states) do
        local bottleSquare = state.square
        if bottleSquare:getZ() == square:getZ() then
            local dx = math.abs(bottleSquare:getX() - square:getX())
            local dy = math.abs(bottleSquare:getY() - square:getY())
            if dx <= GROUND_RADIUS and dy <= GROUND_RADIUS then
                local distance = dx * dx + dy * dy
                if not bestDistance or distance < bestDistance then
                    best = state
                    bestDistance = distance
                end
            end
        end
    end
    return best
end

local function getProtectionState(food, domains, ground)
    local container = food:getContainer()
    if container then
        local key = resolveContainerDomain(container)
        return key and domains[key] or nil
    end
    return nearestGroundState(food, ground)
end

local function adjustFoodAge(food, protected)
    local data = food:getModData()
    local currentAge = food:getAge()
    local previousAge = tonumber(data[Preservative.DATA.lastFoodAge])
    local globalFactor = Preservative.getGlobalAgingFactor()

    if globalFactor == nil then
        local rottenAge = food:getOffAgeMax()
        if rottenAge and rottenAge > 0 then
            food:setAge(rottenAge)
            data[Preservative.DATA.lastFoodAge] = rottenAge
        end
        return
    end
    if previousAge == nil or currentAge < previousAge then
        data[Preservative.DATA.lastFoodAge] = currentAge
        return
    end
    local naturalDelta = currentAge - previousAge
    if naturalDelta <= 0 then return end

    local factor = globalFactor
    if protected then
        factor = factor * (1 - Preservative.getPreservationStrength())
    end
    local adjustedAge = previousAge + naturalDelta * factor
    food:setAge(math.max(0, adjustedAge))
    data[Preservative.DATA.lastFoodAge] = adjustedAge
end

local function consumeBottle(state, now, removals)
    local noGlobalAging = Preservative.getGlobalAgingFactor() == nil
        or Preservative.getGlobalAgingFactor() == 0
    local disabledByCold = state.cold and not Preservative.worksInColdStorage()
    local inactive = noGlobalAging or Preservative.getPreservationStrength() <= 0
        or not state.hasFood or disabledByCold
    local data = state.bottle:getModData()
    local previousHour = tonumber(data[Preservative.DATA.lastChargeHour])
    data[Preservative.DATA.lastChargeHour] = now
    if inactive or previousHour == nil or now <= previousHour then return end

    local elapsed = math.min(24, now - previousHour)
    local accumulated = (tonumber(data[Preservative.DATA.activeHours]) or 0) + elapsed
    local spent = math.floor(accumulated / 24)
    data[Preservative.DATA.activeHours] = accumulated - spent * 24
    if spent <= 0 then return end
    local remaining = Preservative.getCharges(state.bottle) - spent
    Preservative.setCharges(state.bottle, remaining)
    if remaining <= 0 then table.insert(removals, state.bottle) end
end

local function removeBottle(bottle)
    local container = bottle:getContainer()
    if container then
        container:Remove(bottle)
        return
    end
    local worldItem = bottle.getWorldItem and bottle:getWorldItem() or nil
    if worldItem then
        worldItem:removeFromWorld()
        worldItem:removeFromSquare()
    end
end

local function updateFoodAndPreservative()
    local cell = getCell and getCell() or nil
    if not cell then return end
    local items = cell:getProcessItems()
    if not items then return end
    local domains, ground = buildProtectionStates(items)

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if Preservative.isPerishableFood(item) then
            local state = getProtectionState(item, domains, ground)
            local protected = state ~= nil
                and (not state.cold or Preservative.worksInColdStorage())
                and Preservative.getPreservationStrength() > 0
            if protected then state.hasFood = true end
            adjustFoodAge(item, protected)
        end
    end

    local removals = {}
    local now = worldHours()
    for _, state in pairs(domains) do consumeBottle(state, now, removals) end
    for _, state in ipairs(ground) do consumeBottle(state, now, removals) end
    for _, bottle in ipairs(removals) do removeBottle(bottle) end
end

Events.EveryTenMinutes.Add(updateFoodAndPreservative)
