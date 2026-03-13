local monitor = peripheral.find("monitor")
local width, height

local function setup()
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setCursorPos(1, 1)
    width, height = monitor.getSize()
end

local function clean()
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.setTextScale(0.5)
    monitor.setCursorPos(1, 1)
end

local function split(str, separator)
    if separator == nil then
        separator = "%s"
    end
    local t={}
    for str in string.gmatch(str, "([^"..separator.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function drawTitle()
    local titleLength = string.len("MassaWish Inc")
    local xPos = (width - titleLength) / 2
    monitor.setCursorPos(1 + xPos, 2)
    monitor.setBackgroundColor(colors.gray)
    monitor.setTextColor(colors.purple)
    monitor.write("MassaWish Inc")

    clean()
end

local function drawDescription()
    local description = {
        "Accepted bets:",
        " - Gold Ingot",
        " - Diamond",
        " - Small Coin",
        " - Medium Coin",
        "",
        "Only 40% chance to LOSE!",
        "",
        "You WIN 6 out of 10 times!!",
        "",
        "Odds:",
        "40% : Lose",
        "20% : Small Win",
        "15% : Item Back",
        "15% : 2x Prize",
        "8%  : 3x Prize",
        "2%  : JACKPOT!"
    }

    monitor.setCursorPos(1, 4)
    for i = 1, #description do
        local row = description[i] -- You WIN 6 out of 10 times!!
        local words = split(row, " ")
        local CursorX, CursorY
        local xCount = 0
        for j = 1, #words do
            local word = words[j]
            if j ~= 1 and ((xCount + #word) > width) then
                CursorX, CursorY = monitor.getCursorPos()
                monitor.setCursorPos(1, CursorY+1)
                xCount = 1
            end
            xCount = xCount + #word + 1
            monitor.write(word .. " ")
        end
        CursorX, CursorY = monitor.getCursorPos()
        monitor.setCursorPos(1, CursorY+1)
    end

    clean()
end

local function drawInstructions()
    setup()
    drawTitle()
    drawDescription()
end

while true do
    drawInstructions()
    sleep(15)
end