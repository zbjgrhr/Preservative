require "Preservative/PreservativeCore"

PreservativePoison = PreservativePoison or {}

local function worldHours()
    return getGameTime() and getGameTime():getWorldAgeHours() or 0
end

function PreservativePoison.OnEat(item, character, percentage)
    if not character or not percentage or percentage <= 0 then
        return
    end
    if not Preservative.eatingCausesPoisoning() then
        return
    end

    local bodyDamage = character:getBodyDamage()
    if bodyDamage then
        bodyDamage:ReduceGeneralHealth(math.max(8, 20 * percentage))
        if bodyDamage.getFoodSicknessLevel and bodyDamage.setFoodSicknessLevel then
            bodyDamage:setFoodSicknessLevel(math.min(70, bodyDamage:getFoodSicknessLevel() + 35 * percentage))
        end
    end

    -- Build 42 stores poisoning values in CharacterStat. The BodyDamage
    -- branch above remains as a compatibility fallback for older mod APIs.
    local stats = character.getStats and character:getStats() or nil
    if stats and stats.add and CharacterStat then
        stats:add(CharacterStat.FOOD_SICKNESS, 35 * percentage)
        stats:add(CharacterStat.POISON, 20 * percentage)
    end

    local now = worldHours()
    local data = character:getModData()
    local newDeadline = now + Preservative.getLethalDelayHours()
    local existingDeadline = tonumber(data[Preservative.DATA.poisonDeadline])
    if not existingDeadline or newDeadline < existingDeadline then
        data[Preservative.DATA.poisonStart] = now
        data[Preservative.DATA.poisonDeadline] = newDeadline
    end
    Preservative.log("A character consumed preservative; lethal timer started")
end

local function updateCharacter(character)
    if not character or character:isDead() then
        return
    end
    local data = character:getModData()
    local started = tonumber(data[Preservative.DATA.poisonStart])
    local deadline = tonumber(data[Preservative.DATA.poisonDeadline])
    if not started or not deadline then
        return
    end

    local now = worldHours()
    local bodyDamage = character:getBodyDamage()
    if not bodyDamage then
        return
    end

    if now >= deadline then
        bodyDamage:setOverallBodyHealth(0)
        Preservative.clearPoison(character)
        return
    end

    local duration = math.max(0.01, deadline - started)
    local progress = math.max(0, math.min(1, (now - started) / duration))
    local healthCeiling = math.max(1, 92 * (1 - progress))
    if bodyDamage:getOverallBodyHealth() > healthCeiling then
        bodyDamage:setOverallBodyHealth(healthCeiling)
    end
end

local function updatePoisonedPlayers()
    if isClient and isClient() then
        local localPlayer = getSpecificPlayer(0)
        updateCharacter(localPlayer)
        return
    end

    if getOnlinePlayers then
        local players = getOnlinePlayers()
        if players and players:size() > 0 then
            for i = 0, players:size() - 1 do
                updateCharacter(players:get(i))
            end
            return
        end
    end

    updateCharacter(getSpecificPlayer and getSpecificPlayer(0) or nil)
end

Events.EveryOneMinute.Add(updatePoisonedPlayers)
