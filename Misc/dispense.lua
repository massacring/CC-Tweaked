os.pullEvent = os.pullEventRaw

local modem = peripheral.find("modem")

if modem == nil then
    error("No modem connected.")
end

local dispense = false
local function checkEvent()
    while true do
        local id, msg = rednet.receive()
        print("Rednet received.")
        if id == nil then return end
        print("ID: " .. id)
        print("Msg: " .. msg)
        if type(msg) ~= "string" then return end
        if msg ~= "dispense" then return end
        dispense = true
        sleep(0.1)
    end
end

local function emptyInventory()
    for i = 1,16,1 do
        turtle.select(i)
        turtle.drop()
    end
    turtle.select(1)
end

local function mainLoop()
    while true do
        if dispense then
            dispense = false
            emptyInventory()
        end
        sleep(0.1)
    end
end

rednet.open(peripheral.getName(modem))

while true do
    parallel.waitForAny(checkEvent, mainLoop)
    sleep(0.1)
end