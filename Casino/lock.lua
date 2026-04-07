os.pullEvent = os.pullEventRaw

local direction = "back"

redstone.setOutput(direction, true)

local lock = false

local timerTime = 15 * 60
local timerID

local function runTimer()
    local _, id = os.pullEvent("timer")
    if id == timerID then
        os.reboot()
    end
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
        redstone.setOutput(direction, not lock)
    end
end

parallel.waitForAll(runTimer, runCommands)
