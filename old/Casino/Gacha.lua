local chatBox = peripheral.find("chatBox")
if (chatBox == nil) then
    error("No Chat Box peripheral connected.", 0)
end

local storage = peripheral.wrap("top")
local input = peripheral.wrap("left")
local output = peripheral.wrap("right")

local inputSlot, inputItem

local winnings = {}
local values = {
    ["minecraft:gold_nugget"]=1,
    ["minecraft:coal"]=2,
    ["minecraft:redstone"]=3,
    ["minecraft:glowstone_dust"]=3,
    ["minecraft:amethyst_shard"]=4,
    ["minecraft:copper_ingot"]=4,
    ["minecraft:iron_ingot"]=6,
    ["minecraft:quartz"]=7,
    ["minecraft:gold_ingot"]=9,
    ["kubejs:small_coin"]=9,
    ["minecraft:experience_bottle"]=18,
    ["minecraft:copper_block"]=36,
    ["kubejs:medium_coin"]=36,
    ["minecraft:diamond"]=45,
    ["minecraft:iron_block"]=54,
    ["minecraft:gold_block"]=81,
    ["kubejs:small_coin_block"]=81,
    ["kubejs:big_coin"]=144,
    ["kubejs:medium_coin_block"]=324,
    ["minecraft:diamond_block"]=405,
}

local function GetValuesBelow(num)
    local availableValues = {}
    for name, value in pairs(values) do
        if value <= num then availableValues[name] = value end
    end
    return availableValues
end

local function GetRandomValue(randomTable)
    local valueNames = {}
    for name in pairs(randomTable) do
        table.insert(valueNames, name)
    end

    ::retry::
    local randomName = valueNames[math.random(#valueNames)]
    local randomValue = randomTable[randomName]
    if math.random(#valueNames) > randomValue
    or math.random(#valueNames) > randomValue
    or math.random(#valueNames) > randomValue
    then goto retry end

    return randomName, randomValue
end

--[[
local function GetHighestValue(num)
    local maxValue = 0

    local HighestValues = {}

    for _, value in pairs(values) do
        if value > num then goto continue end
        if value <= maxValue then goto continue end

        maxValue = value

        ::continue::
    end

    for name, value in pairs(values) do
        if value == maxValue then HighestValues[name] = value end
    end

    local randomMaxName, randomMaxValue = GetRandomValue(HighestValues)

    return randomMaxName, randomMaxValue
end
--]]

local function GetRandomValueBelow(num)
    local availableValues = GetValuesBelow(num)
    local next = next

    if next(availableValues) == nil then return end

    local randomName, randomValue = GetRandomValue(availableValues)

    return randomName, randomValue
end

local function GetItemSlot(inventory, name)
    for i = 1,inventory.size(),1 do
        local item = inventory.getItemDetail(i)
        if item == nil then goto continue end
        if (item.name == name) then return i end
        ::continue::
    end
end

local function GrantRewards()
    for name, data in pairs(winnings) do
        if data.slot ~= nil then storage.pushItems(peripheral.getName(output), data.slot, data.amount) end
    end

    winnings = {}
end

local function OutOfCommission(message)
    chatBox.sendMessage(message, "&cMassaWish Inc", "[]", "&8", 30)

    for i = 1, input.size(), 1 do
        input.pushItems(peripheral.getName(output), i)
    end
    storage.pushItems(peripheral.getName(output), GetItemSlot(storage, inputItem.name), 1)

    GrantRewards()

    sleep(15)
    os.reboot()
end

local function CheckWinning(name)
    local slot = GetItemSlot(storage, name)
    if slot == nil then
        print("Out of " .. name)
        return false
    end
    local item = storage.getItemDetail(slot)
    if item == nil or item.count < winnings[name].amount then
        print("Out of " .. name)
        -- Out of item
        -- If possible, craft more
        return false
    end
    winnings[name].slot = slot
    return true
end

local function AddWinning(name, amount)
    amount = amount or 1
    if winnings[name] == nil then
        winnings[name] = { amount = amount }
    else
        winnings[name].amount = winnings[name].amount + amount
    end

    if not CheckWinning(name) then OutOfCommission("The magic has run dry. Contact massacring.") end
end

local function GenerateWinnings(num)
    local availableValue = num

    while availableValue > 0 do
        local randomName, randomValue = GetRandomValueBelow(availableValue)
        if randomName == nil then break end

        AddWinning(randomName)
        availableValue = availableValue - randomValue
    end
end

local function ToggleRedstone(side, power)
    redstone.setAnalogOutput(side, power)
    sleep(0.05)
    redstone.setAnalogOutput(side, 0)
end

local function MakeAWish()
    local lot = math.random(100)
    local value = values[inputItem.name]
    if lot < 40 then
        -- 40% Chance to lose
        parallel.waitForAll(
            function() ToggleRedstone("front", 1) end,
            function() print("Lost :(") end
        )
    elseif lot < 60 then
        -- 20% Chance to cut Losses
        parallel.waitForAll(
            function() ToggleRedstone("front", 2) end,
            function()
                print("Cut Losses")
                GenerateWinnings(math.floor(value/2))
            end
        )
    elseif lot < 75 then
        -- 15% Chance to get item back
        parallel.waitForAll(
            function() ToggleRedstone("front", 3) end,
            function()
                print("Item Back")
                AddWinning(inputItem.name)
            end
        )
    elseif lot < 90 then
        -- 15% Chance to get 2x value
        parallel.waitForAll(
            function() ToggleRedstone("front", 4) end,
            function()
                print("2x Value")
                GenerateWinnings(value*2)
            end
        )
    elseif lot < 98 then
        -- 8% Chance to get 3x value
        parallel.waitForAll(
            function() ToggleRedstone("front", 5) end,
            function()
                print("3x Value")
                GenerateWinnings(value*3)
            end
        )
    else
        -- 2% Chance to get 7x value
        parallel.waitForAll(
            function() ToggleRedstone("front", 6) end,
            function()
                print("7x Value")
                chatBox.sendMessage("JACKPOT! Congratulations!", "&aMassaWish Inc", "[]", "&8", 30)
                GenerateWinnings(value*7)
            end
        )
    end
end

local function GetInput()
    inputSlot, inputItem = nil, nil
    local next = next
    local items = input.list()
    while next(items) ~= nil and inputItem == nil do
        inputSlot = next(items)
        inputItem = input.getItemDetail(inputSlot)

        if values[inputItem.name] == nil then
            input.pushItems(peripheral.getName(output), inputSlot)
            inputSlot, inputItem = nil, nil
            items = input.list()
        end
    end
end

while true do
    for i = 1, 10, 1 do
        GetInput()
        if inputItem == nil then break end

        input.pushItems(peripheral.getName(storage), inputSlot, 1)
        MakeAWish()
        sleep(0.05)
    end
    GrantRewards()
    sleep(2)
end
