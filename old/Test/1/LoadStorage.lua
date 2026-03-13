local MassaLib = require('MassaLib')

local storages = {}
local function getStorages()
    storages = {}
    for key, value in pairs(MassaLib.getPeripheralTypes()) do
        if value == "meBridge"
        or value == "toms_storage:ts.inventory_cable_connector.tile"
        or value == "inventory"
        then
            table.insert(storages, peripheral.find(value))
        end
    end
    if MassaLib.tlength(storages) == 0 then error("No storage attached.", 0) end
end
getStorages()

local function getStorageDataFromInventory(inventory)
    local totalSlots = inventory.size() or 0
    local allItems = inventory.list() or {}
    local slotsUsed = MassaLib.tlength(allItems)
    local slotsLeft = (totalSlots - slotsUsed) or totalSlots

    local totalStorage = totalSlots * 64
    local storageLeft = slotsLeft * 64

    for index, value in pairs(allItems) do
        local slotLimitTotal = inventory.getItemLimit(index)
        local slotLimitLeft = slotLimitTotal - value.count
        storageLeft = storageLeft + (slotLimitLeft * (64 / slotLimitTotal))
    end

    local percentLeft =  (math.floor(storageLeft / totalStorage * 10000)) / 100

    return { [1] = slotsLeft, [2] = totalStorage - storageLeft, [3] = percentLeft }
end

local function getStorageDataFromMESystem(meBridge)
    local storageData = {}
    local totalItemStorage = meBridge.getTotalItemStorage() or 0
    MassaLib.tprint(meBridge.listItems())
    if not totalItemStorage == 0 then
        storageData["totalItemStorage"] = totalItemStorage
        storageData["usedItemStorage"] = meBridge.getUsedItemStorage() or 0
        storageData["availableItemStorage"] = meBridge.getAvailableItemStorage() or 0
        storageData["itemPercentLeft"] = (math.floor(storageData.availableItemStorage / totalItemStorage * 10000)) / 100
    end

    local totalFluidStorage = meBridge.getTotalFluidStorage() or 0
    if not totalFluidStorage == 0 then
        storageData["totalFluidStorage"] = totalFluidStorage
        storageData["usedFluidStorage"] = meBridge.getUsedFluidStorage() or 0
        storageData["availableFluidStorage"] = meBridge.getAvailableFluidStorage() or 0
        storageData["fluidPercentLeft"] = (math.floor(storageData.availableFluidStorage / totalFluidStorage * 10000)) / 100
    end

    return storageData
end

local function getLineData(title, lines)
    local longest = #title + 1
    for i, line in pairs(lines) do
        local length = #line
        if length > longest then longest = length end
    end

    local lineCount = #lines
    return longest, lineCount
end

local function writeStorageData(monitor, title, lines)
    local longest, lineCount = getLineData(title, lines)

    monitor.setBackgroundColor(colors.yellow)
    for i = 0, lineCount, 1 do
        local x, y = monitor.getCursorPos()
        monitor.setCursorPos(x, y + i + 1)
        monitor.write(string.rep(" ", longest))
        monitor.setCursorPos(x, y)
    end

    monitor.setBackgroundColor(colors.orange)
    for i = 0, lineCount + 2, 1 do
        local x, y = monitor.getCursorPos()
        monitor.setCursorPos(x, y+i)
        if i == 0 then monitor.write(string.rep(" ", longest + 1)) end
        if i == lineCount + 2 then monitor.write(string.rep(" ", longest + 1)) end
        monitor.setCursorPos(x, y+i)
        monitor.write(" ")
        monitor.setCursorPos(x + longest, y+i)
        monitor.write(" ")
        monitor.setCursorPos(x, y)
    end
    monitor.write(" ") -- Moves cursor once to the right
    monitor.setBackgroundColor(colors.yellow)

    monitor.setTextColor(colors.purple)
    local x, y = monitor.getCursorPos()
    y = y + 1
    monitor.setCursorPos(x, y)
    monitor.write(title)
    for i, line in pairs(lines) do
        monitor.setCursorPos(x, y+i)
        local segments = MassaLib.split(line, "|")
        monitor.setTextColor(colors.lightGray)
        monitor.write(segments[1])
        monitor.setTextColor(colors.red)
        monitor.write(segments[2])
    end

    return longest+2, lineCount
end

local function displayStorageData(storage, monitor)
    local storageType = peripheral.getType(storage) or error("Invalid storage provided.", 0)
    local title = ""
    local lines = {}

    local switch = function (argument)
        argument = argument and tonumber(argument) or argument
        local case =
        {
            inventory = function ()
                local storageData = getStorageDataFromInventory(storage)
                title = "inventory"
                lines = {
                    "Empty Slots: ".."|"..tostring(storageData[1] or 0),
                    "Item Count: ".."|"..tostring(storageData[2] or 0),
                    "Storage Left: ".."|"..tostring(storageData[3]).."%",
                }
            end,
            meBridge = function ()
                local storageData = getStorageDataFromMESystem(storage)
                title = "ME System"
                lines = {}
                if storageData.usedItemStorage then
                    table.insert(lines, "Used Storage (Item): ".."|"..tostring(storageData["usedItemStorage"] or 0))
                    table.insert(lines, "Available Storage (Item): ".."|"..tostring(storageData["availableItemStorage"] or 0))
                    table.insert(lines, "Storage Left (Item): ".."|"..tostring(storageData["itemPercentLeft"] or 0).."%")
                end
                if storageData.usedFluidSTorage then
                    table.insert(lines, "Used Storage (Fluid): ".."|"..tostring(storageData["usedFluidStorage"] or 0))
                    table.insert(lines, "Available Storage (Fluid): ".."|"..tostring(storageData["availableFluidStorage"] or 0))
                    table.insert(lines, "Storage Left (Fluid): ".."|"..tostring(storageData["fluidPercentLeft"] or 0).."%")
                end
            end,
            ["toms_storage:ts.inventory_cable_connector.tile"] = function ()
                local storageData = getStorageDataFromInventory(storage)
                title = "Tom's Simple Storage"
                lines = {
                    "Empty Slots: ".."|"..tostring(storageData[1] or 0),
                    "Item Count: ".."|"..tostring(storageData[2] or 0),
                    "Storage Left: ".."|"..tostring(storageData[3]).."%",
                }
            end,
            default = function ()
                error("Unrecognized storage.", 0)
            end
        }

        if case[argument] then
            case[argument]()
        else
            case["default"]()
        end
    end

    switch(storageType)

    return writeStorageData(monitor, title, lines)
end

local function startStorageDisplay(screen)
    getStorages()
    local monitor = screen.monitor
    monitor.setCursorPos(2, 2)
    for key, value in pairs(storages) do
        local x, y = monitor.getCursorPos()
        monitor.setCursorPos(x, y-1)
        monitor.setTextColor(colors.white)
        monitor.setBackgroundColor(colors.lightBlue)
        monitor.write("Calculating Storage...")
        monitor.setCursorPos(x, y)
        local width, height = displayStorageData(value, monitor)
        monitor.setCursorPos(x, y-1)
        monitor.setBackgroundColor(screen.backgroundColor)
        monitor.write("                      ")
        monitor.setCursorPos(x + width, y)
    end
end

return { startStorageDisplay = startStorageDisplay }
