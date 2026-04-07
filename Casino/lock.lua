os.pullEvent = os.pullEventRaw

local outputDirection = "back"
local inputDirection = "top"

redstone.setOutput(outputDirection, true)

local lock = false

local timerTime = 15 * 60
local timerID

local function runRedstone()
    while true do
        os.pullEvent("redstone")
        if redstone.getInput(inputDirection) then
            lock = not lock
            if timerID ~= nil then
                os.cancelTimer(timerID)
            end
            if lock then
                timerID = os.startTimer(timerTime)
            end
            redstone.setOutput(outputDirection, not lock)
            sleep(1)
        end
    end
end

local function runTimer()
    local _, id = os.pullEvent("timer")
    if id == timerID then
        os.reboot()
    end
end

local function runEvents()
    parallel.waitForAll(runRedstone, runTimer)
end

local function runCommands()
    while true do
        term.clear()
        term.setCursorPos(1,1)

        write("Commands:\n")
        write(" - lock (lasts 15 minutes)\n")
        write(" - unlock\n")
        write("> ")

        local input = read()

        if input == "lock" then
            lock = true
            if timerID ~= nil then
                os.cancelTimer(timerID)
            end
            timerID = os.startTimer(timerTime)
        elseif input == "unlock" then
            lock = false
            if timerID ~= nil then
                os.cancelTimer(timerID)
            end
        end
        redstone.setOutput(outputDirection, not lock)
    end
end

parallel.waitForAll(runEvents, runCommands)

