local barrelName = "sophisticatedstorage:barrel_"

local chatBox = peripheral.find("chatBox")
if (chatBox == nil) then
    error("No Chat Box peripheral connected.", 0)
end

local storage = peripheral.wrap(barrelName .. 0)
local input = peripheral.wrap(barrelName .. 1)
local output = peripheral.wrap(barrelName .. 2)

local inputItem

local gold_nugget_slot
local gold_slot, diamond_slot
local small_coin_slot, medium_coin_slot
local gold_block_slot, diamond_block_slot
local small_coin_block_slot, medium_coin_block_slot

local function OutOfPrizes(message)
    chatBox.sendMessage(message, "&cMassaWish Inc", "[]", "&8", 30)
    input.pushItems(peripheral.getName(output), 1)
    sleep(15)
    os.reboot()
end

local function getItemSlot(inventory, name)
    for i = 1,inventory.size(),1 do
        local item = inventory.getItemDetail(i)
        if item == nil then goto continue end
        if (item.name == name) then return i end
        ::continue::
    end
    OutOfPrizes("Out of prizes. Contact massacring.")
end

local function generateSlot(slot, name)
    if (slot == nil) or (slot < 1) or (storage.getItemDetail(slot).name ~= name) then
        return getItemSlot(storage, name)
    end
end

local function generateSlots()
    gold_nugget_slot = generateSlot(gold_nugget_slot, "minecraft:gold_nugget")
    gold_slot = generateSlot(gold_slot, "minecraft:gold_ingot")
    diamond_slot = generateSlot(diamond_slot, "minecraft:diamond")
    small_coin_slot = generateSlot(small_coin_slot, "kubejs:small_coin")
    medium_coin_slot = generateSlot(medium_coin_slot, "kubejs:medium_coin")
    gold_block_slot = generateSlot(gold_block_slot, "minecraft:gold_block")
    diamond_block_slot = generateSlot(diamond_block_slot, "minecraft:diamond_block")
    small_coin_block_slot = generateSlot(small_coin_block_slot, "kubejs:small_coin_block")
    medium_coin_block_slot = generateSlot(medium_coin_block_slot, "kubejs:medium_coin_block")
end

local function sendItem(storageSlot, amount)
    storage.pushItems(peripheral.getName(output), storageSlot, amount)
    if (storage.getItemDetail(storageSlot) == nil) then
        OutOfPrizes("Ran out of prizes. Contact massacring.")
    end
end

local function getRewardSlot(tier)
    local inputName = inputItem.name
    if tier == 0 then
        return getItemSlot(storage, inputName)
    elseif tier == 1 then
        if inputName == "kubejs:small_coin" then return small_coin_block_slot
        elseif inputName == "minecraft:diamond" then return diamond_block_slot
        elseif inputName == "minecraft:gold_ingot" then return gold_block_slot
        elseif inputName == "kubejs:medium_coin" then return medium_coin_block_slot end
    elseif tier == -1 then
        if inputName == "kubejs:small_coin" then return gold_slot
        elseif inputName == "minecraft:diamond" then return gold_slot
        elseif inputName == "minecraft:gold_ingot" then return gold_nugget_slot
        elseif inputName == "kubejs:medium_coin" then return small_coin_slot end
    end
end

local function MakeAWish()
    input.pushItems(peripheral.getName(storage), 1, 1)
    local rng = math.random(0, 99)
    if rng < 40 then
        redstone.setAnalogOutput("back", 1)
    elseif rng < 60 then
        redstone.setAnalogOutput("back", 2)
        sendItem(getRewardSlot(-1), 1)
    elseif rng < 75 then
        redstone.setAnalogOutput("back", 3)
        sendItem(getRewardSlot(0), 1)
    elseif rng < 90 then
        redstone.setAnalogOutput("back", 4)
        sendItem(getRewardSlot(0), 2)
    elseif rng < 98 then
        redstone.setAnalogOutput("back", 5)
        sendItem(getRewardSlot(0), 3)
    else
        redstone.setAnalogOutput("back", 6)
        sendItem(getRewardSlot(1), 1)
        chatBox.sendMessage("JACKPOT! Congratulations!", "&aMassaWish Inc", "[]", "&8", 30)
    end
end

while true do
    redstone.setAnalogOutput("back", 0)
    inputItem = input.getItemDetail(1)
    generateSlots()
    if (inputItem ~= nil) then MakeAWish() end
    sleep(0.05)
end
