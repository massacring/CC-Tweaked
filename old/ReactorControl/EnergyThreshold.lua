local MPL = require('MassaPeripheralLib')

local modem = MPL.getOnePeripheral("modem", function(name, peripheral)
    return peripheral.isWireless()
end)
local channel = 4200
local reciever = 4201
modem.open(channel)

function detectEnergyWanted()
    local port = peripheral.find("inductionPort")
    if not port then error("No induction port connected.", 0) end
    if port.getEnergyFilledPercentage() > 0.8 then return false end
    return true
end

while true do
    sleep(5)
    local message = ""
    if detectEnergyWanted() then
        message = "activate"
    else
        message = "SCRAM"
    end
    print(string.format("Transmitting '%s' to channel %d, from channel %d", message, reciever, channel))
    modem.transmit(reciever, channel, message)
end
