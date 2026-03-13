local Screen = require('Screen')
local MassaLib = require('MassaLib')
local Storage

local function loadStorage()
    Storage = require('LoadStorage')
end
local function catchStorage(err)
    printError("ERROR: ".. err)
end
local StorageStatus = xpcall(loadStorage, catchStorage)

local modem = MassaLib.getOnePeripheral("modem", function(name, peripheral)
    return peripheral.isWireless()
end)
local channel = 4243
modem.open(channel)

local _monitor = MassaLib.getOnePeripheral("monitor", function(name, peripheral)
    return peripheral.isColor()
end)

local mainScreen = Screen:new(nil, "main", _monitor, colors.gray)
local storageScreen
if StorageStatus then storageScreen = Screen:new(nil, "storage", _monitor, colors.gray) end
local currentScreen = mainScreen

local function loadStorageScreen()
    local homeButton = storageScreen:createButton("Home", function (button)
        currentScreen = mainScreen
        mainScreen:loadScreen()
    end, 2, storageScreen.height - 5, 1, 1, colors.lightBlue, colors.yellow, colors.blue, colors.orange, colors.white, colors.lightGray, false)

    local refreshButton = storageScreen:createButton("Refresh", function (button)
        storageScreen:loadScreen()
    end, 11, storageScreen.height - 5, 1, 1, colors.lightBlue, colors.yellow, colors.blue, colors.orange, colors.white, colors.lightGray, false)

    function storageScreen:loadScreen()
        self:clearWindow(self.backgroundColor)
        self:placeButtons()
        Storage.startStorageDisplay(self)
    end
end
if StorageStatus then loadStorageScreen() end

local function loadMainScreen()
    if StorageStatus then
        local storage = mainScreen:createButton("Storage", function (button)
            currentScreen = storageScreen
            storageScreen:loadScreen()
        end, 0, 0, 1, 1, colors.lightBlue, colors.yellow, colors.blue, colors.orange, colors.white, colors.lightGray, true)
    end

    local rainbow = mainScreen:createButton("Rainbow", function (button)
        mainScreen:loadRainbow()
        mainScreen:loadScreen()
    end, mainScreen.width - 9, mainScreen.height - 3, 1, 1, nil, nil, nil, nil, nil, nil, false)
end
loadMainScreen()

currentScreen:loadScreen()

while true do
    local eventData = {os.pullEvent()}
    local event = eventData[1]

    if event == 'monitor_touch' then
        local x, y = eventData[3], eventData[4]
        for index, button in pairs(currentScreen.buttonsRegistry) do
            if not button.isActive then goto continue end
            if ((x >= button.x) and (x < (button.x + button.width))) and ((y >= button.y) and (y < (button.y + button.height))) then
                button.clickEvent(button)
                break
            end
            ::continue::
        end
    elseif event == 'modem_message' then
        local senderChannel, replyChannel, message = eventData[3], eventData[4], eventData[5]
        if senderChannel == channel then
            print("Received a message:", tostring(message))

            local switch = function (argument)
                argument = argument and tonumber(argument) or argument

                local case =
                {
                    reboot = function ()
                        modem.transmit(replyChannel, senderChannel, "Rebooting...")
                        os.reboot()
                    end,
                    rainbow = function ()
                        modem.transmit(replyChannel, senderChannel, "How tasteful!")
                        currentScreen:loadRainbow()
                        currentScreen:loadScreen()
                    end,
                    default = function ()
                        print("Invalid command")
                    end
                }

                if case[argument] then
                    case[argument]()
                else
                    case["default"]()
                end
            end

            switch(message)
        end
    end
end
