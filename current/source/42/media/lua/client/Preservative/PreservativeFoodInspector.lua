require "ISUI/ISToolTipInv"
require "Preservative/PreservativeCore"

local function unwrapItem(entry)
    if not entry then return nil end
    if instanceof(entry, "InventoryItem") then return entry end
    if entry.items and entry.items[1] then return entry.items[1] end
    return nil
end

local function isPoisonousWildFood(item)
    if not item or not item:IsFood() or not item.getPoisonPower or item:getPoisonPower() <= 0 then
        return false
    end
    local foodType = string.lower(tostring(item.getFoodType and item:getFoodType() or ""))
    local wildTypes = {
        berry = true, berries = true, fruit = true,
        vegetable = true, vegetables = true,
        mushroom = true, mushrooms = true,
        herb = true, herbs = true, insect = true,
        fish = true, game = true,
    }
    return wildTypes[foodType] == true
end

local function useAntidote(item, playerNum)
    local character = getSpecificPlayer(playerNum)
    if not character or not Preservative.isPoisoned(character) or not Preservative.isAntidote(item) then return end
    Preservative.clearPoison(character)
    item:Use()
    if HaloTextHelper then
        HaloTextHelper.addGoodText(character, getText("UI_Preservative_AntidoteSuccess"))
    end
end

local function onFillInventoryContextMenu(playerNum, context, items)
    if not items or #items ~= 1 then return end
    local item = unwrapItem(items[1])
    local character = getSpecificPlayer(playerNum)
    if item and character and Preservative.isPoisoned(character) and Preservative.isAntidote(item)
        and item.isInPlayerInventory and item:isInPlayerInventory() then
        context:addOption(getText("ContextMenu_Preservative_UseAntidote"), item, useAntidote, playerNum)
    end
end

local originalRender = ISToolTipInv.render

function ISToolTipInv:render()
    originalRender(self)
    local item = self.item
    if not item then return end

    local lines = {}
    local redFirstLine = false
    if Preservative.isBottle(item) then
        local hours = Preservative.getBottleHoursRemaining(item)
        table.insert(lines, getText("UI_Preservative_BottleHoverRemaining", string.format("%.1f", hours / 24)))
        table.insert(lines, getText("UI_Preservative_BottleHoverStrength", tostring(math.floor(Preservative.getPreservationStrength() * 100 + 0.5))))
        table.insert(lines, getText("UI_Preservative_BottleHoverWarning"))
        redFirstLine = false
    elseif isPoisonousWildFood(item) then
        table.insert(lines, getText("UI_Preservative_WildFoodPoisonWarning"))
        redFirstLine = true
    end
    if #lines == 0 then return end

    local font = UIFont.Small
    local textManager = getTextManager()
    local lineHeight = textManager:getFontHeight(font) + 3
    local padding = 6
    local oldHeight = self.height
    local extraHeight = padding * 2 + lineHeight * #lines
    local neededWidth = self.width
    for _, line in ipairs(lines) do
        neededWidth = math.max(neededWidth, textManager:MeasureStringX(font, line) + padding * 2)
    end
    self:drawRect(0, oldHeight, neededWidth, extraHeight, 0.86, 0, 0, 0)
    self:drawRectBorder(0, oldHeight, neededWidth, extraHeight, 1, 0.4, 0.4, 0.4)
    for index, line in ipairs(lines) do
        local warning = redFirstLine or (Preservative.isBottle(item) and index == #lines)
        self:drawText(line, padding, oldHeight + padding + (index - 1) * lineHeight,
            1, warning and 0.2 or 1, warning and 0.2 or 1, 1, font)
    end
    self:setWidth(neededWidth)
    self:setHeight(oldHeight + extraHeight)
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenu)
