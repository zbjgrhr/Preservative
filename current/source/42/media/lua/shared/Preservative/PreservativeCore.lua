Preservative = Preservative or {}

Preservative.ID = "Preservative.PreservativeBottle"
Preservative.VERSION = "0.3.0"
Preservative.DATA = {
    charges = "PSV_Charges",
    activeHours = "PSV_ActiveHours",
    lastChargeHour = "PSV_LastChargeHour",
    lastFoodAge = "PSV_LastFoodAge",
    poisonStart = "PSV_PoisonStart",
    poisonDeadline = "PSV_PoisonDeadline",
}

local function sandboxValue(key, fallback)
    if SandboxVars and SandboxVars.Preservative then
        local value = SandboxVars.Preservative[key]
        if value ~= nil then
            return value
        end
    end
    return fallback
end

function Preservative.getPreservationStrength()
    local value = tonumber(sandboxValue("PreservationStrength", 0.4)) or 0.4
    return math.max(0.0, math.min(1.0, value))
end

function Preservative.getGlobalPreservation()
    local value = tonumber(sandboxValue("GlobalPreservation", 0.5)) or 0.5
    return math.max(0.0, math.min(1.0, value))
end

function Preservative.getGlobalAgingFactor()
    local value = Preservative.getGlobalPreservation()
    if value <= 0 then
        return nil -- nil means immediately rotten
    end
    return math.max(0, 2 * (1 - value))
end

function Preservative.getBottleLifetimeDays()
    return math.max(1, math.min(9999999, math.floor((tonumber(sandboxValue("BottleLifetimeDays", 30)) or 30) + 0.5)))
end

function Preservative.getSpawnMultiplier()
    return math.max(0, math.min(100, tonumber(sandboxValue("SpawnMultiplier", 5.0)) or 5.0))
end

function Preservative.worksInColdStorage()
    return sandboxValue("WorksInColdStorage", true) == true
end

function Preservative.eatingCausesPoisoning()
    return sandboxValue("EatingCausesPoisoning", true) == true
end

function Preservative.getLethalDelayHours()
    return math.max(0.25, math.min(24, tonumber(sandboxValue("LethalDelayHours", 6.0)) or 6.0))
end

function Preservative.isPoisoned(character)
    if not character then
        return false
    end
    return tonumber(character:getModData()[Preservative.DATA.poisonDeadline]) ~= nil
end

function Preservative.clearPoison(character)
    if not character then
        return
    end
    local data = character:getModData()
    data[Preservative.DATA.poisonStart] = nil
    data[Preservative.DATA.poisonDeadline] = nil
end

function Preservative.isAntidote(item)
    if not item then
        return false
    end
    local fullType = item:getFullType()
    return fullType == "Base.LemonGrass" or fullType == "Base.Antibiotics"
end

function Preservative.showPoisonIndicator()
    return sandboxValue("ShowPoisonIndicator", true) == true
end

function Preservative.log(message)
    -- Intentionally quiet in release builds. Keep one helper for diagnostics.
end

function Preservative.isBottle(item)
    return item ~= nil and item:getFullType() == Preservative.ID
end

function Preservative.isPerishableFood(item)
    if not item or Preservative.isBottle(item) or not item:IsFood() then
        return false
    end
    if item.canAge and not item:canAge() then
        return false
    end
    local rottenDay = item:getOffAgeMax()
    return rottenDay ~= nil and rottenDay > 0 and rottenDay < 1000000
        and (item:getAge() or 0) < rottenDay
end

function Preservative.isFreezer(container)
    if not container then
        return false
    end
    local kind = string.lower(tostring(container:getType() or ""))
    if kind == "freezer" then
        return true
    end
    return container.getFreezerPosition and container:getFreezerPosition() ~= nil
        and container:getFreezerPosition() ~= ""
end

function Preservative.isColdStorage(container)
    if not container then
        return false
    end
    if container.isFridge and container:isFridge() then
        return true
    end
    if container.isFreezer and container:isFreezer() then
        return true
    end
    return Preservative.isFreezer(container)
end

function Preservative.isPlayerContainer(container)
    return container ~= nil and container.getCharacter and container:getCharacter() ~= nil
end

function Preservative.getCharges(item)
    if not item then
        return 0
    end
    local data = item:getModData()
    local charges = tonumber(data[Preservative.DATA.charges])
    if charges == nil then
        charges = Preservative.getBottleLifetimeDays()
        data[Preservative.DATA.charges] = charges
    end
    return math.max(0, math.floor(charges))
end

function Preservative.ensureBottleData(item)
    if not item then
        return
    end
    Preservative.getCharges(item)
    local data = item:getModData()
    if data[Preservative.DATA.activeHours] == nil then
        data[Preservative.DATA.activeHours] = 0
    end
end

function Preservative.getBottleHoursRemaining(item)
    if not item then
        return 0
    end
    Preservative.ensureBottleData(item)
    local data = item:getModData()
    local partialHours = tonumber(data[Preservative.DATA.activeHours]) or 0
    return math.max(0, Preservative.getCharges(item) * 24 - partialHours)
end

function Preservative.setCharges(item, charges)
    if item then
        item:getModData()[Preservative.DATA.charges] = math.max(0, math.floor(charges or 0))
    end
end
