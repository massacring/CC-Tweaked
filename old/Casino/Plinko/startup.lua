local Button = require('Button')
local Commons = require('Commons')
local Plinko = require('plinko')
local cashout = require('cashout')
local monitor = peripheral.find("monitor")
local input = peripheral.find("minecraft:hopper")
local storage = peripheral.find("minecraft:chest")
local modem = peripheral.wrap("bottom")
local printer = peripheral.find("printer")

if (monitor == nil) then
    error("No monitor connected.")
end

if (input == nil) then
    error("No input hopper connected.")
end

if (storage == nil) then
    error("No storage chest connected.")
end

if (modem == nil) then
    error("No modem found.")
end

if (printer == nil) then
    error("No printer connected.")
end

monitor.setBackgroundColor(colors.black)
monitor.clear()
monitor.setTextScale(1)

if printer.getInkLevel() == 0 and printer.getPaperLevel() == 0 then
    error("Cannot start a new page. Do you have ink and paper?")
end

local window = window.create(monitor, 1, 1, 40, 19)
local width, height = window.getSize()
local startButton, resetButton
local gameStarted = false

local defaultBackgroundColor = colors.lightGray
local defaultTextColor = colors.white

local function drawSquare(x, y, span, length, color)
    window.setCursorPos(x,y)
    window.setBackgroundColor(color)
    for row = 1, length, 1 do
        window.setCursorPos(x,y+row-1)
        window.write(string.rep(" ", span))
    end
end

local function write(text, x, y, textColor, backGroundColor)
    backGroundColor = backGroundColor or defaultBackgroundColor
    textColor = textColor or defaultTextColor
    window.setCursorPos(x,y)
    window.setBackgroundColor(backGroundColor)
    window.setTextColor(textColor)
    window.write(text)
end

local function clear()
    window.setBackgroundColor(defaultBackgroundColor)
    window.setTextColor(defaultTextColor)
    window.clear()
    window.setCursorPos(1,1)
end

local function getCenter()
    return math.floor(width/2), math.floor(height/2)
end

local function drawScoreboard()
    local scoreTitle = "Score:"
    local scoreText = tostring(Commons.Score:getScore())
    local scoreTextLen = string.len(scoreText) + 2
    if scoreTextLen < 9 then scoreTextLen = 9 end
    local x, y = getCenter()
    x = x - math.floor(scoreTextLen/2)
    y = y - 2

    window.setTextColor(colors.white)
    drawSquare(x, y, scoreTextLen+1, 3, colors.purple, true)
    window.setCursorPos(x+1, y+1)
    window.write(scoreText)
    drawSquare(x+1, y-1, 6, 1, colors.gray, true)
    window.setCursorPos(x+1, y-1)
    window.write(scoreTitle)
end

local function startGame()
    if (Commons.Score:getScore() < Commons.Score.min) then
        return
    end
    gameStarted = true
    Plinko.init()
    Plinko.drawScreen()
    Plinko.runGame()
end

local function createStartButton()
    local label = "Start!"
    local labelLength = string.len(label)
    local x, y = getCenter()
    x = x - math.floor(labelLength/2)
    y = y + 2
    if y > height - 5 then y = height - 5 end
    local span = labelLength
    local length = 1
    local labelPad = 0
    local backgroundColorNormal = colors.yellow
    local borderColorNormal = colors.orange
    local textColorNormal = colors.gray
    startButton = Button.new(label, startGame, x, y, span, length, labelPad, backgroundColorNormal, borderColorNormal, textColorNormal)
end

local function reset()
    if (Commons.Credits.selectedCredit == nil) then return end
    clear()
    cashout()
    os.reboot()
end

local function createResetButton()
    local label = "Reset "
    local labelLength = string.len(label)
    local x, y = getCenter()
    x = x - math.floor(labelLength/2)
    y = y + 6
    local span = labelLength
    local length = 1
    local labelPad = 0
    local backgroundColorNormal = colors.blue
    local borderColorNormal = colors.blue
    local textColorNormal = colors.black
    resetButton = Button.new(label, reset, x, y, span, length, labelPad, backgroundColorNormal, borderColorNormal, textColorNormal)
end

local function drawCredit()
    local label = "Credit Type: " .. Commons.Credits.selectedCredit
    local x, y = 2, 2

    write(label, x, y, colors.white, colors.red)
end

local function drawScreen()
    clear()
    drawScoreboard()
    createStartButton()
    createResetButton()
    startButton:displayOnScreen(drawSquare, write)
    resetButton:displayOnScreen(drawSquare, write)
end

local function countCoins()
    local shouldThrow = false
    for i = 1,input.size(),1 do
        local item = input.getItemDetail(i)
        if item ~= nil
            and Commons.Credits:validCurrency(item.name)
            and (Commons.Credits.selectedCredit == nil or Commons.Credits.selectedCredit == Commons.Credits:getName(item.name))
        then
            if Commons.Credits.selectedCredit == nil then
                Commons.Credits.selectedCredit = Commons.Credits:getName(item.name)
                drawCredit()
            end
            local count = item.count
            local value = Commons.Credits:getValueByName(item.name)
            for _ = 1, count, 1 do
                local newValue = Commons.Score:getScore() + value
                if (newValue > Commons.Score.max) then
                    input.pushItems(modem.getNameLocal(), i, 1)
                    shouldThrow = true
                else
                    Commons.Score:updateScore(newValue)
                    drawScoreboard()
                    input.pushItems(peripheral.getName(storage), i, 1)
                end
            end
        elseif item ~= nil then
            input.pushItems(modem.getNameLocal(), i)
            shouldThrow = true
        end
    end
    if shouldThrow then
        for i = 1,16,1 do
            turtle.select(i)
            turtle.drop()
        end
        turtle.select(1)
    end
end

local function tick()
    while true do
        if (not gameStarted) then countCoins() end
        sleep(0.05)
    end
end

local function events()
    while true do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        if event == "key_up" and eventData[2] == keys.q then
            return
        elseif event == "monitor_touch" then
            local x, y = eventData[3], eventData[4]
            if startButton:collides(x, y) then
                startButton.clickEvent()
            elseif resetButton:collides(x, y) then
                resetButton.clickEvent()
            end
        end
    end
end

drawScreen()
parallel.waitForAny(tick, events)
