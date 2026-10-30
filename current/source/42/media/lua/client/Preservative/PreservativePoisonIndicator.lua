require "ISUI/ISPanel"
require "Preservative/PreservativeCore"

PreservativePoisonIndicator = ISPanel:derive("PreservativePoisonIndicator")

local RIGHT_MARGIN = 10

local function getMoodleSize()
    local moodles = MoodlesUI and MoodlesUI.getInstance and MoodlesUI.getInstance() or nil
    local size = moodles and tonumber(moodles:getWidth()) or 64
    local supported = { 32, 48, 64, 80, 96, 128 }
    local closest = supported[1]
    for _, candidate in ipairs(supported) do
        if math.abs(candidate - size) < math.abs(closest - size) then closest = candidate end
    end
    return closest
end

local function worldHours()
    return getGameTime() and getGameTime():getWorldAgeHours() or 0
end

local function readStat(character, stat)
    if not character or not stat or not character.getStats then return 0 end
    local stats = character:getStats()
    if not stats or not stats.get then return 0 end
    return tonumber(stats:get(stat)) or 0
end

function PreservativePoisonIndicator:new()
    local screenWidth = getCore():getScreenWidth()
    local size = getMoodleSize()
    local panel = ISPanel:new(screenWidth + size, 0, size, size)
    setmetatable(panel, self)
    self.__index = self
    panel.background = false
    panel.border = false
    panel.skull = getTexture("media/ui/Skull1.png")
    panel.moodleSize = size
    panel.circle = getTexture("media/ui/Moodles/" .. tostring(size) .. "/_Moodles_BGsolid.png")
    panel.outline = getTexture("media/ui/Moodles/" .. tostring(size) .. "/_Moodles_BGoutline.png")
    panel.wasActive = false
    panel.animationX = screenWidth + size
    panel.activationTime = 0
    return panel
end

function PreservativePoisonIndicator:getPoisonState()
    if not Preservative.showPoisonIndicator() then return nil end
    local character = getSpecificPlayer(0)
    if not character or character:isDead() then return nil end

    local preservative = Preservative.isPoisoned(character)
    local poison = CharacterStat and readStat(character, CharacterStat.POISON) or 0
    local foodSickness = CharacterStat and readStat(character, CharacterStat.FOOD_SICKNESS) or 0
    local bodyDamage = character:getBodyDamage()
    if bodyDamage then
        if bodyDamage.getPoisonLevel then
            poison = math.max(poison, tonumber(bodyDamage:getPoisonLevel()) or 0)
        end
        if bodyDamage.getFoodSicknessLevel then
            foodSickness = math.max(foodSickness, tonumber(bodyDamage:getFoodSicknessLevel()) or 0)
        end
    end
    if not preservative and poison <= 0.01 and foodSickness <= 0.01 then return nil end
    return {
        character = character,
        preservative = preservative,
        poison = poison,
        foodSickness = foodSickness,
        severity = math.max(poison, foodSickness)
    }
end

function PreservativePoisonIndicator:getRemainingText(character)
    local deadline = tonumber(character:getModData()[Preservative.DATA.poisonDeadline])
    if not deadline then return "" end
    local minutes = math.max(0, math.ceil((deadline - worldHours()) * 60))
    return getText("UI_Preservative_PoisonTimeRemaining", tostring(math.floor(minutes / 60)), tostring(minutes % 60))
end

function PreservativePoisonIndicator:getTooltipLines(state)
    if state.preservative then
        return {
            getText("UI_Preservative_PoisonIndicatorTitle"),
            self:getRemainingText(state.character),
            getText("UI_Preservative_PoisonAntidote"),
            getText("UI_Preservative_PoisonAftercare")
        }
    end
    if state.foodSickness > 0.01 then
        return {
            getText("UI_Preservative_FoodPoisonTitle"),
            getText("UI_Preservative_FoodPoisonCause"),
            getText("UI_Preservative_GeneralPoisonAdvice")
        }
    end
    return {
        getText("UI_Preservative_GeneralPoisonTitle"),
        getText("UI_Preservative_PoisonSourceUnknown"),
        getText("UI_Preservative_GeneralPoisonAdvice")
    }
end

function PreservativePoisonIndicator:prerender()
    local size = getMoodleSize()
    if size ~= self.moodleSize then
        self.moodleSize = size
        self:setWidth(size)
        self:setHeight(size)
        self.circle = getTexture("media/ui/Moodles/" .. tostring(size) .. "/_Moodles_BGsolid.png")
        self.outline = getTexture("media/ui/Moodles/" .. tostring(size) .. "/_Moodles_BGoutline.png")
    end
    local state = self:getPoisonState()
    local active = state ~= nil
    local screenWidth = getCore():getScreenWidth()
    local targetX = active and (screenWidth - self.width - RIGHT_MARGIN) or (screenWidth + self.width)
    if active and not self.wasActive then self.activationTime = getTimestampMs() end
    self.wasActive = active
    self.animationX = self.animationX + (targetX - self.animationX) * 0.22

    local wiggle = 0
    if active then
        local age = getTimestampMs() - self.activationTime
        local intensity = math.min(5, 1 + state.severity / 25)
        if age < 900 or state.severity >= 50 then
            wiggle = math.sin(getTimestampMs() / 55) * intensity
        end
    end
    self:setX(self.animationX + wiggle)
    self:setY((getCore():getScreenHeight() - self.height) / 2 + wiggle * 0.35)
    if not active then return end

    if self.circle then
        self:drawTextureScaled(self.circle, 0, 0, self.width, self.height, 1.0, 0.72, 0.08, 0.08)
    end
    if self.skull then
        local inset = math.floor(self.width * 0.20)
        self:drawTextureScaled(self.skull, inset, inset, self.width - inset * 2, self.height - inset * 2, 1.0, 1.0, 0.16, 0.16)
    end
    if self.outline then
        self:drawTextureScaled(self.outline, 0, 0, self.width, self.height, 1.0, 0.95, 0.95, 0.95)
    end
end

function PreservativePoisonIndicator:render()
    local state = self:getPoisonState()
    if not state or not self:isMouseOver() then return end
    local sourceLines = self:getTooltipLines(state)
    local textManager = getTextManager()
    local padding = 9
    local lineHeight = textManager:getFontHeight(UIFont.Small) + 3
    local maxTextWidth = math.min(420, math.floor(getCore():getScreenWidth() * 0.42))
    local lines = {}
    for _, source in ipairs(sourceLines) do
        local current = ""
        for word in string.gmatch(source, "%S+") do
            local candidate = current == "" and word or (current .. " " .. word)
            if current ~= "" and textManager:MeasureStringX(UIFont.Small, candidate) > maxTextWidth then
                table.insert(lines, current)
                current = word
            else
                current = candidate
            end
        end
        table.insert(lines, current ~= "" and current or source)
    end
    local tooltipWidth = 0
    for _, line in ipairs(lines) do
        tooltipWidth = math.max(tooltipWidth, textManager:MeasureStringX(UIFont.Small, line))
    end
    tooltipWidth = math.min(maxTextWidth + padding * 2, tooltipWidth + padding * 2)
    local tooltipHeight = padding * 2 + lineHeight * #lines
    local tooltipX = -tooltipWidth - 8
    local tooltipY = math.floor((self.height - tooltipHeight) / 2)
    self:drawRect(tooltipX, tooltipY, tooltipWidth, tooltipHeight, 0.94, 0.03, 0.03, 0.03)
    self:drawRectBorder(tooltipX, tooltipY, tooltipWidth, tooltipHeight, 1.0, 0.80, 0.12, 0.12)
    for i, line in ipairs(lines) do
        local title = i == 1
        self:drawText(line, tooltipX + padding, tooltipY + padding + (i - 1) * lineHeight,
            1.0, title and 0.35 or 1.0, title and 0.35 or 1.0, 1.0, UIFont.Small)
    end
end

local function createIndicator()
    if Preservative.poisonIndicator then return end
    local indicator = PreservativePoisonIndicator:new()
    indicator:initialise()
    indicator:addToUIManager()
    indicator:setAlwaysOnTop(true)
    Preservative.poisonIndicator = indicator
end

Events.OnGameStart.Add(createIndicator)
Events.OnCreatePlayer.Add(createIndicator)
