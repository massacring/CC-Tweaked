local Commons = require('Commons')
local storage = peripheral.find("minecraft:chest")
local modem = peripheral.wrap("bottom")
local printer = peripheral.find("printer")
local barrel = peripheral.find("minecraft:barrel")

local IOUActive = false

local function getItemIndex(id)
    for i = 1, storage.size(), 1 do
        local item = storage.getItemDetail(i)
        if item then
            if item.name == id then return i end
        end
    end
    print("Item '" .. id .. "' not found.")
    return 0
end

local function clearTurtle()
    for i = 1, 16, 1 do
        storage.pullItems(modem.getNameLocal(), i)
    end
end

local function getKey()
    local characters = "12345678901234567890!#%&/=?+@$!#%&/=?+@$!#%&/=?+@$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local ranSeq = ""
    for _ = 1, 16, 1 do
        local random = math.random(1, #characters)
        ranSeq = ranSeq .. characters:sub(random,random)
    end
    return ranSeq
end

local function writeReceipt(key)
    local file = fs.open("receipts", "a")
    file.write("[\"" .. key .. "\"]:\n")
    file.write("    \"type\": \"" .. Commons.Credits.selectedCredit .. "\"\n")
    file.write("    \"score\": " .. tostring(Commons.Score.getScore()) .. "\n")
    file.close()
end

local function generateIOU(key)
    IOUActive = true
    clearTurtle()
    printer.newPage()
    printer.setPageTitle("I.O.U -Mass")
    printer.write("The machine ran out of")
    printer.setCursorPos(1,2)
    printer.write("some resource.")
    printer.setCursorPos(1,3)
    printer.write("This receipt will hold")
    printer.setCursorPos(1,4)
    printer.write("yor earnings.")
    printer.setCursorPos(1,6)
    printer.write("Credit Type: " .. Commons.Credits.selectedCredit)
    printer.setCursorPos(1,7)
    printer.write("Credit Score: " .. Commons.Score.getScore())
    printer.setCursorPos(1,8)
    printer.write("Key: " .. key .. "-")
    printer.setCursorPos(1,9)
    printer.write("Please do not show this")
    printer.setCursorPos(1,10)
    printer.write("key to another player.")
    printer.endPage()
end

local function getIndex(id)
    local index = getItemIndex(id)
    local success = index ~= 0
    if not success then
    local key = getKey()
        generateIOU(key)
        writeReceipt(key)
        barrel.pullItems(peripheral.getName(printer), 8)
        barrel.pushItems(modem.getNameLocal(), 1)
        return 0
    end
    return index
end

local function countCoins()
    local largeValue = Commons.Credits.getValueBySize(Commons.Credits.LARGE) or math.maxinteger
    local mediumValue = Commons.Credits.getValueBySize(Commons.Credits.MEDIUM)
    while Commons.Score.getScore() >= largeValue do
        local largeIndex = getIndex(Commons.Credits.getCurrentId(Commons.Credits.LARGE))
        if IOUActive then goto skip end
        storage.pushItems(modem.getNameLocal(), largeIndex, 1)
        Commons.Score.updateScore(Commons.Score.getScore() - largeValue)
    end
    while Commons.Score.getScore() >= mediumValue do
        local mediumIndex = getIndex(Commons.Credits.getCurrentId(Commons.Credits.MEDIUM))
        if IOUActive then goto skip end
        storage.pushItems(modem.getNameLocal(), mediumIndex, 1)
        Commons.Score.updateScore(Commons.Score.getScore() - mediumValue)
    end
    while Commons.Score.getScore() > 0 do
        local smallIndex = getIndex(Commons.Credits.getCurrentId(Commons.Credits.SMALL))
        if IOUActive then goto skip end
        storage.pushItems(modem.getNameLocal(), smallIndex, 1)
        Commons.Score.updateScore(Commons.Score.getScore() - 1)
    end
    ::skip::
    for i = 1,16,1 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(1)
end

return countCoins