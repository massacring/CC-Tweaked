local MPL = require('MassaPeripheralLib')

local reactorStatus = false

local modem = MPL.getOnePeripheral("modem", function(name, peripheral)
    return peripheral.isWireless()
end)

local adapter = peripheral.find("fissionReactorLogicAdapter")
if not adapter then error("No Logic Adapter connected.", 0) end

local channel = 4201

modem.open(channel)

local function activate()
    if reactorStatus then return end
    adapter.activate()
    reactorStatus = true
end

local function SCRAM()
    adapter.scram()
    reactorStatus = false
end

local function hasWaste()
    if adapter.getWasteFilledPercentage() < 0.1 then return end
    SCRAM()
end

local function errorHandler(err)
    SCRAM()
    error(string.format("ERROR: %s", err), 0)
end

local function requestHandler()
    local eventData = {os.pullEvent()}
    local event = eventData[1]

    if event == 'modem_message' then
        local senderChannel, replyChannel, message = eventData[3], eventData[4], eventData[5]
        if senderChannel == channel then
            print(string.format("Received message '%s' from channel %d", tostring(message), replyChannel))

            local switch = function (argument)
                argument = argument and tonumber(argument) or argument

                local case =
                {
                    activate = activate,
                    SCRAM = SCRAM,
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

while true do
    xpcall(hasWaste, errorHandler)
    sleep(1)
    xpcall(requestHandler, errorHandler)
end