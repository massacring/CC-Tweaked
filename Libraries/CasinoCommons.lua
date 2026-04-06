--- VARIABLES ---
local Score = {}
local Credit = {}
local Credits = {}

--- COMMON METHODS ---

-- Gets a list of item data from any slot that matches "id" in the provided storage.
-- Also adds the slot index to that item data.
-- Retuns nil if no match was found.
local function getAllItemData(storage, id)
    local allItemData = {}
    if (storage == nil or id == nil) then
        print("Could not get item data because passed storage or id is nil.")
        return nil
    end
    for slot, itemData in pairs(storage.list()) do
        if itemData and itemData.name == id then
            itemData.index = slot
            allItemData[#allItemData+1] = itemData
        end
    end
    if #allItemData == 0 then
        print("Item '" .. id .. "' not found.")
        return nil
    end
    return allItemData
end

-- Gets the item data from the first slot that matches "id" in the provided storage.
-- Also adds the slot index to that item data.
-- Retuns nil if no match was found.
local function getItemData(storage, id)
    local allItemData = getAllItemData(storage, id)
    if allItemData == nil then return nil end
    return allItemData[1]
end

-- Gets the slot index from the first slot that matches "id" in the provided storage.
-- Also returns the number of items in that slot.
-- Returns 0 for both if no item was found.
local function getIndex(storage, id)
    local itemData = getItemData(storage, id)
    if itemData == nil or itemData.index == nil then
        return 0, 0
    end
    return itemData.index, itemData.count
end

-- Gets the total count of all items matching "id" in the provided storage.
-- Returns 0 if no items are found.
local function getTotalCount(storage, id)
    local allItemData = getAllItemData(storage, id)
    if allItemData == nil then return 0 end
    local totalCount = 0
    for _, itemData in pairs(allItemData) do
        totalCount = totalCount + itemData.count
    end
    return totalCount
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

--- CASHOUT ---

local function getKey()
    local characters = "12345678901234567890!#%&/=?+@$!#%&/=?+@$!#%&/=?+@$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local ranSeq = ""
    for _ = 1, 16, 1 do
        local random = math.random(1, #characters)
        ranSeq = ranSeq .. characters:sub(random,random)
    end
    return ranSeq
end

local function writeReceipt(key, creditType, score)
    local file = fs.open("receipts", "a")
    file.write("[\"" .. key .. "\"]:\n")
    file.write("    \"type\": \"" .. creditType .. "\"\n")
    file.write("    \"score\": " .. score .. "\n")
    file.close()
end

local function generateIOU(printer, key, creditType, score)
    printer.newPage()
    printer.setPageTitle("I.O.U -Mass")
    printer.write("The machine ran out of")
    printer.setCursorPos(1,2)
    printer.write("some resource.")
    printer.setCursorPos(1,3)
    printer.write("This receipt will hold")
    printer.setCursorPos(1,4)
    printer.write("your earnings.")
    printer.setCursorPos(1,6)
    printer.write("Credit Type: " .. creditType)
    printer.setCursorPos(1,7)
    printer.write("Credit Score: " .. score)
    printer.setCursorPos(1,8)
    printer.write("Key: #" .. key .. "-")
    printer.setCursorPos(1,9)
    printer.write("Please do not show this")
    printer.setCursorPos(1,10)
    printer.write("key to another player.")
    printer.endPage()
end

local function countScore(turtleName, storage, intermediaryStorage, printer, output)
    if Credits.selectedCredit == nil then
        print("Tried to count score with nil selected credit.", 1)
        return
    end

    local maxSize = Credits.selectedCredit:getMax() or 0

    if maxSize == 0 then
        print("Could not get max size of selected credit.", 1)
        return
    end

    local score = Score:getScore()
    for size=maxSize,1,-1 do
        local multiplier = Credits.selectedCredit:getMultiplierBySize(size)
        local id = Credits.selectedCredit:getIdBySize(size)
        local hasScore = score >= multiplier
        while hasScore do
            local index, count = getIndex(storage, id)
            local numToGet = math.floor(score / multiplier)
            if (index <= 0) then
                local success = Credits.selectedCredit:attemptCraft(size, numToGet, turtleName, turtle, storage, intermediaryStorage) or false
                if success then
                    goto continue
                end
                if size > 1 then
                    break
                end

                local key = getKey()
                --Commons.clearTurtle(storage, turtleName)
                generateIOU(printer, key, Credits.selectedCredit.name, score)
                writeReceipt(key, Credits.selectedCredit.name, score)
                intermediaryStorage.pullItems(peripheral.getName(printer), 8)
                intermediaryStorage.pushItems(peripheral.getName(output), 1)
                goto outerbreak
            end
            local numToPush = math.min(count, numToGet)
            storage.pushItems(peripheral.getName(output), index, numToPush)
            Score:updateScore(score - (multiplier * numToPush))
            score = Score:getScore()
            hasScore = score >= multiplier
            ::continue::
        end
    end
    ::outerbreak::
    rednet.send(output.getID(), "dispense")
end

--- CREDIT ---

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

function Credit:craftBig(size, num, turtleName, turtle, storage, intermediaryStorage)
    local itemData = self:getDataBySize(size+1)
    if itemData == nil then return false end

    local itemId = itemData.id
    local itemIndex, itemCount = getIndex(storage, itemId)
    local numToCraft = math.floor(num / itemData.multiplier)
    numToCraft = math.min(math.max(numToCraft, 1), itemCount)
    if (itemIndex < 1) then
        return false
    end

    clearTurtle(intermediaryStorage, turtleName)

    storage.pushItems(turtleName, itemIndex, numToCraft)

    local success = turtle.craft()

    clearTurtle(storage, turtleName)
    turtleDevour(intermediaryStorage, turtleName)

    return success
end

function Credit:craftSmall(size, num, turtleName, turtle, storage, intermediaryStorage)
    local itemData = self:getDataBySize(size-1)
    if itemData == nil then return false end

    local itemId = itemData.id
    local multiplier = self.values[size].multiplier
    if type(multiplier) ~= "number" then
        return false
    end
    local subSize = math.sqrt(multiplier)
    local totalCount = getTotalCount(storage, itemId)
    local maxCraft = math.floor(totalCount / multiplier)
    local totalNum = math.min(num, maxCraft)

    clearTurtle(intermediaryStorage, turtleName)

    local leftoverCount = 0
    local index, count = getIndex(storage, itemId)
    for row = 1, subSize do
        for col = 1, subSize do
            local countToPush = totalNum
            while countToPush > 0 do
                local currentNum = totalNum
                if leftoverCount > 0 then
                    currentNum = leftoverCount
                    leftoverCount = 0
                elseif (count < totalNum) then
                    leftoverCount = math.abs(count - totalNum)
                    currentNum = count
                end

                if index < 1 then
                    clearTurtle(storage, turtleName)
                    turtleDevour(intermediaryStorage, turtleName)
                    return false
                end

                local coord = (row - 1) * 4 + col

                storage.pushItems(turtleName, index, currentNum, coord)
                countToPush = countToPush - currentNum

                count = count - currentNum
                if leftoverCount > 0 then
                    index, count = getIndex(storage, itemId)
                end
            end
        end
    end

    local success = turtle.craft()
    clearTurtle(storage, turtleName)
    turtleDevour(intermediaryStorage, turtleName)
    print("Small sucess: " .. tostring(success))
    return success
end

function Credit:attemptCraft(size, num, turtleName, turtle, storage, intermediaryStorage)
    local maxSize = self:getMax()
    if size < maxSize then
        local result = self:craftBig(size, num, turtleName, turtle, storage, intermediaryStorage)
        if result then return true end
    end
    local result = self:craftSmall(size, num, turtleName, turtle, storage, intermediaryStorage)
    return result
end

function Credit:getDataById(id)
    if self.values == nil then return nil end
    for size,data in pairs(self.values) do
        if (id == data["id"]) then return size, data end
    end
    return nil
end

function Credit:getDataBySize(size)
    if self.values == nil then
        print("Credit has no values.")
        return nil
    end

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
    for _ = size - 1, 1, -1 do
        local multiplier = self.values[size].multiplier or 1
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
    if self.values == nil then
        print("Credit has no values.")
        return nil
    end
    if type(size) ~= "number" then
        print("Size is not a number.")
        return nil
    end
    local data = self:getDataBySize(size)
    if data == nil then
        print("Could not fetch data from credit.")
        return nil
    end
    return data.id
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

--- SCORE ---

Score.__index = Score
Score.value = 0
Score.max = 10000
Score.min = 0

function Score:updateScore(num)
    if type(num) ~= "number" then return end
    --print("Updating score: " .. tostring(num))
    Score.value = num
end

function Score:getScore()
    --print("Score is: " .. tostring(Score.value))
    return Score.value
end

return { Credits = Credits, Score = Score, countScore = countScore }
