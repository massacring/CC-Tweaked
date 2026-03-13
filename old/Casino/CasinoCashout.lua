local Commons = require('CasinoCommons')

if (turtle == nil) then
    error("Program must run on a turtle.")
end

if (
    (turtle.getEquippedLeft() ~= nil and turtle.getEquippedLeft().name ~= "minecraft:crafting_table") and
    (turtle.getEquippedRight() ~= nil and turtle.getEquippedRight().name ~= "minecraft:crafting_table")
) then
    error("Turtle must hold a crafting table.")
end

local modem = peripheral.wrap("bottom")

if (modem == nil or modem.isWireless()) then
    error("No Wired Modem Block found below computer.")
end

local turtleName = modem.getNameLocal()

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
    file.write("    \"type\": \"" .. Commons.Credits.selectedCredit.name .. "\"\n")
    file.write("    \"score\": " .. tostring(Commons.Score:getScore()) .. "\n")
    file.close()
end

local function generateIOU(printer, key)
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
    printer.write("Credit Type: " .. Commons.Credits.selectedCredit.name)
    printer.setCursorPos(1,7)
    printer.write("Credit Score: " .. Commons.Score:getScore())
    printer.setCursorPos(1,8)
    printer.write("Key: #" .. key .. "-")
    printer.setCursorPos(1,9)
    printer.write("Please do not show this")
    printer.setCursorPos(1,10)
    printer.write("key to another player.")
    printer.endPage()
end

local function countScore(storage, intermediaryStorage, printerName)
    if Commons.Credits.selectedCredit == nil then
        warn("Tried to count score with nil selected credit.", 1)
        return
    end

    local maxSize = Commons.Credits.selectedCredit:getMax() or 0

    if maxSize == 0 then
        warn("Could not get max size of selected credit.", 1)
        return
    end

    for size=maxSize,1,-1 do
        local multiplier = Commons.Credits.selectedCredit:getMultiplierBySize(size)
        local id = Commons.Credits.selectedCredit:getIdBySize(size)
        local index = Commons.getIndex(storage, id)
        if (index <= 0) then
            local success = Commons.Credits.selectedCredit:attemptCraft(size, turtleName, turtle, storage, intermediaryStorage) or false
            if success then
                goto continue
            end

            local key = getKey()
            Commons.clearTurtle(storage, turtleName)
            generateIOU(key)
            writeReceipt(key)
            intermediaryStorage.pullItems(printerName, 8)
            intermediaryStorage.pushItems(turtleName, 1)

            break
        end
        storage.pushItems(turtleName, index, 1)
        Commons.Score:updateScore(Commons.Score:getScore() - multiplier)
        ::continue::
    end

    for i = 1,16,1 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(1)
end

return countScore