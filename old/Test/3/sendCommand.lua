local modem = peripheral.find("modem") or error("No modem attached", 0)
local channel = 4242
modem.open(channel)

local command = arg[1]

local switch = function (argument)
    argument = argument and tonumber(argument) or argument

    local case =
    {
        reboot = function ()
            modem.transmit(4243, 4242, "reboot")
        end,
        rainbow = function ()
            modem.transmit(4243, 4242, string.format("rainbow-%s", arg[2]))
        end,
        default = function ()
            error("Invalid command", 0)
        end
    }

    if case[argument] then
        case[argument]()
    else
        case["default"]()
    end
end

switch(command)

local event, side, senderChannel, replyChannel, message, distance
repeat
  event, side, senderChannel, replyChannel, message, distance = os.pullEvent("modem_message")
until senderChannel == channel

term.clear()
term.setCursorPos(1, 1)

print(tostring(message))