local function getIndex(storage, id)
    for i = 1, storage.size(), 1 do
        local item = storage.getItemDetail(i)
        if item and item.name == id then
            return i
        end
    end
    print("Item '" .. id .. "' not found.")
    return 0
end

local function clearTurtle(storage, turtleName)
    for i = 1, 16, 1 do
        storage.pullItems(turtleName, i)
    end
end

local function turtleDevour(storage, turtleName)
    for i = 1, 16, 1 do
        storage.pushItems(turtleName, i)
    end
end

local Credit = {}
Credit.__index = Credit
Credit.SMALL = 1
Credit.MEDIUM = 2
Credit.LARGE = 3

function Credit:getMax()
    if self.values == nil then return 0 end
    local maxSize = 0
    for _ in pairs(self.values) do
        maxSize = maxSize + 1
    end
    return maxSize
end

function Credit:attemptCraft(size, turtleName, turtle, storage, intermediaryStorage)
    local maxSize = self:getMax()
    if size < maxSize then
        local largerItemData = self:getDataBySize(size+1)
        if largerItemData == nil then goto skip end

        clearTurtle(intermediaryStorage, turtleName)

        local largerItemId = largerItemData["id"]
        local largerItemIndex = getIndex(storage, largerItemId)
        storage.pushItems(turtleName, largerItemIndex, 1)

        local success = turtle.craft()
        turtleDevour(intermediaryStorage, turtleName)
        return success
    end
    ::skip::
    local itemData = self:getDataBySize(size-1)
    if itemData == nil then return false end

    clearTurtle(intermediaryStorage, turtleName)

    local itemId = itemData["id"]
    local itemMultiplier = itemData["multiplier"]
    local row = 1
    for i=1,itemMultiplier,1 do
        local index = getIndex(storage, itemId)
        if index < 1 then
            turtleDevour(intermediaryStorage, turtleName)
            return false
        end
        local coord = index + (row * 4)

        storage.pushItems(turtleName, index, 1, coord)

        if i % 3 == 0 then row = row + 1 end
    end

    local success = turtle.craft()
    turtleDevour(intermediaryStorage, turtleName)
    return success
end

function Credit:getDataById(id)
    if self.values == nil then return nil end
    for size,data in pairs(self.values) do
        if (id == data["id"]) then return size, data end
    end
    return nil
end

function Credit:getDataBySize(size)
    if self.values == nil then return nil end
    return self.values[size]
end

function Credit:getMultiplierById(id)
    local size = self:getSizeById(id)
    if size == nil then return nil end
    return self:getMultiplierBySize(size)
end

function Credit:getMultiplierBySize(size)
    if self.values == nil then return nil end
    if type(size) ~= "number" then return nil end
    local totalMultiplier = 1
    for _=size,1,-1 do
        local multiplier = self.values[size]["multiplier"] or 1
        totalMultiplier = totalMultiplier * multiplier
    end
    return totalMultiplier
end

function Credit:getSizeById(id)
    if self.values == nil then return nil end
    local size, _ = self:getDataById(id)
    return size
end

function Credit:getIdBySize(size)
    if self.values == nil then return nil end
    if type(size) ~= "number" then return nil end
    local _, data = self:getDataBySize(size)
    if data == nil then return nil end
    return data["id"]
end

function Credit.new(name, values)
    local credit = setmetatable({}, Credit)

    credit.name = name
    credit.values = values or {
        [Credit.LARGE] = { ['id'] = 'minecraft:iron_block', ['multiplier'] = 9 },
        [Credit.MEDIUM] = { ['id'] = 'minecraft:iron_ingot', ['multiplier'] = 9 },
        [Credit.SMALL] = { ['id'] = 'minecraft:iron_nugget' },
    }

    return credit
end

local Credits = {}
Credits.credits = {
    --["emeralds"] = Credit.new("emeralds"),
    ["iron"] = Credit.new("iron", {
        [Credit.LARGE] = { ['id'] = 'minecraft:iron_block', ['multiplier'] = 9 },
        [Credit.MEDIUM] = { ['id'] = 'minecraft:iron_ingot', ['multiplier'] = 9 },
        [Credit.SMALL] = { ['id'] = 'minecraft:iron_nugget' },
    }),
}
Credits.selectedCredit = nil
Credits.__index = Credits

function Credits:selectCurrency(name)
    self.selectedCredit = self.credits[name]
end

function Credits:validCurrency(id)
    for _,credit in pairs(Credits.credits) do
        local size = credit:getDataById(id)
        if size ~= nil then return true end
    end
    return false
end

function Credits:getCreditType(id)
    for creditName,credit in pairs(Credits.credits) do
        local size = credit:getDataById(id)
        if size ~= nil then return creditName end
    end
end

local Score = {}
Score.__index = Score
Score.value = 0
Score.max = 10000
Score.min = 0

function Score:updateScore(num)
    if type(num) ~= "number" then return end
    print("Updating score: " .. tostring(num))
    Score.value = num
end

function Score:getScore()
    print("Score is: " .. tostring(Score.value))
    return Score.value
end

return { Credits = Credits, Score = Score, getIndex = getIndex, clearTurtle = clearTurtle }