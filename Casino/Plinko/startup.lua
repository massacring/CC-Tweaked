local run = require("run")
local Commons = require("CasinoCommons")
local Plinko = require("Plinko")

-- Might not actually be facing north, but it won't matter for stationary casino machines.
local myNav = run({"-i", "--direction=north"})

if not myNav.isCrafting then
    error("Turtle must be a crafting turtle.")
end

local modem = peripheral.wrap("bottom")

if (modem == nil or modem.isWireless()) then
    error("No Wired Modem Block found below turtle.")
end

rednet.open(peripheral.getName(modem))

local turtleName = modem.getNameLocal()
local storageType = "minecraft:chest"
local intermediaryStorageType = "minecraft:barrel"
local outputType = "turtle"
local inputType = "minecraft:hopper"

local storage = peripheral.find(storageType)
if not storage then
    error(("No Storage Peripheral of type %s connected to turtle."):format(storageType))
end

local intermediaryStorage = peripheral.find(intermediaryStorageType)
if not intermediaryStorage then
    error(("No Storage Peripheral of type %s connected to turtle."):format(intermediaryStorageType))
end

local printer = peripheral.find("printer")
if not printer then
    error("No Printer Peripheral connected to turtle.")
end

if printer.getInkLevel() == 0 and printer.getPaperLevel() == 0 then
  error("Cannot start a new page. Do you have ink and paper?")
end

local speaker = peripheral.find("speaker")
if not speaker then
    error("No Speaker Peripheral connected to turtle.")
end

local output = peripheral.find(outputType)
if not output then
    error(("No Output Peripheral of type %s connected to turtle."):format(outputType))
end

local input = peripheral.find(inputType)
if not input then
    error(("No Input Peripheral of type %s connected to turtle."):format(inputType))
end

local monitor = peripheral.find("monitor")

monitor.setBackgroundColor(colors.black)
monitor.clear()
monitor.setTextScale(1)
local window = window.create(monitor, 1, 1, 40, 19)
local width, height = window.getSize()
local startButton, resetButton
local gameStarted = false

local defaultBackgroundColor = colors.lightGray
local defaultTextColor = colors.white

-- Credits.selectedCredit = Credits.credits["iron"]
-- Score:updateScore(1000)
-- countScore(turtleName, storage, intermediaryStorage, printer, output)

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
    drawSquare(x, y, scoreTextLen+1, 3, colors.purple)
    window.setCursorPos(x+1, y+1)
    window.write(scoreText)
    drawSquare(x+1, y-1, 6, 1, colors.gray)
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
    clear()
    Commons.countScore(turtleName, storage, intermediaryStorage, printer, output)
    os.reboot()
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
    startButton = Plinko.Button.new(label, startGame, x, y, span, length, labelPad, backgroundColorNormal, borderColorNormal, textColorNormal)
end

local function reset()
    if (Commons.Credits.selectedCredit == nil) then return end
    clear()
    Commons.countScore(turtleName, storage, intermediaryStorage, printer, output)
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
    resetButton = Plinko.Button.new(label, reset, x, y, span, length, labelPad, backgroundColorNormal, borderColorNormal, textColorNormal)
end

local function drawCredit()
    local label = "Credit Type: " .. Commons.Credits.selectedCredit.name
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
            and (Commons.Credits.selectedCredit == nil or Commons.Credits.selectedCredit.name == Commons.Credits:getCreditType(item.name))
        then
            if Commons.Credits.selectedCredit == nil then
                Commons.Credits.selectedCredit = Commons.Credits.credits[Commons.Credits:getCreditType(item.name)]
                drawCredit()
            end
            local count = item.count
            local value = Commons.Credits.selectedCredit:getMultiplierById(item.name)
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
            shouldThrow = true
        end
    end
    if shouldThrow then
        for i = 1,input.size(),1 do
            local item = input.getItemDetail(i)
            if item ~= nil then
                input.pushItems(peripheral.getName(output), i)
            end
        end
        rednet.send(output.getID(), "dispense")
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
