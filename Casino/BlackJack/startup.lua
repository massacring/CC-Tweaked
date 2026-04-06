local run = require("run")
local Commons = require("CasinoCommons")
local BlackJack = require("BlackJack")

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
monitor.setTextScale(0.5)
local window = window.create(monitor, 1, 1, 80, 38)
local width, height = window.getSize()

local playerHand = BlackJack.Hand.new(false)
local dealerHand = BlackJack.Hand.new(false)

local startButton = {}
local gameButtons = {}
local gameStarted = false
local multiplier = 2

-- Declares my own colors
local m_colors = {
    white = colors.white,
    black = colors.orange,
    gray = colors.magenta,
    lightGray = colors.lightBlue,
    darkRed = colors.yellow,
    red = colors.lime,
    lightRed = colors.pink,
    green = colors.gray,
    lightGreen = colors.lightGray,
    darkYellow = colors.cyan,
    yellow = colors.purple,
}

local primaryBackgroundColor = m_colors.green
local secondaryBackgroundColor = m_colors.lightGreen
local defaultTextColor = m_colors.white

-- Changes the default palette
do
    window.setPaletteColor(colors.orange, 0x191919) -- Black
    window.setPaletteColor(colors.magenta, 0x262626) -- Gray
    window.setPaletteColor(colors.lightBlue, 0x565656) -- Light Gray
    window.setPaletteColor(colors.yellow, 0xDD2F00) -- Dark Red
    window.setPaletteColor(colors.lime, 0xEF4A21) -- Red
    window.setPaletteColor(colors.pink, 0xFFBAAA) -- Light Red
    window.setPaletteColor(colors.gray, 0x355E19) -- Green
    window.setPaletteColor(colors.lightGray, 0x356D19) -- Light Green
    window.setPaletteColor(colors.cyan, 0xEAB327) -- Dark Yellow
    window.setPaletteColor(colors.purple, 0xEDC125) -- Yellow
    window.setPaletteColor(colors.blue, 0xE8C958) -- 
    window.setPaletteColor(colors.brown, 0xE8C958) -- 
    window.setPaletteColor(colors.green, 0xE8C958) -- 
    window.setPaletteColor(colors.red, 0xE8C958) -- 
    window.setPaletteColor(colors.black, 0xE8C958) -- 
end

local function playCardDraw()
    speaker.playSound("entity.villager.work_librarian")
end

local function drawSquare(_window, x, y, span, length, color)
    local oldTerm = term.redirect(_window)
    term.setCursorPos(x,y)
    term.setBackgroundColor(color)
    for row = 1, length, 1 do
        term.setCursorPos(x,y+row-1)
        term.write(string.rep(" ", span))
    end
    term.redirect(oldTerm)
end

local function write(_window, text, x, y, textColor, backGroundColor)
    local oldTerm = term.redirect(_window)
    if backGroundColor == nil then
        if y % 2 == 1 then
            backGroundColor = primaryBackgroundColor
        else
            backGroundColor = secondaryBackgroundColor
        end
    end
    textColor = textColor or defaultTextColor
    term.setCursorPos(x,y)
    term.setBackgroundColor(backGroundColor)
    term.setTextColor(textColor)
    term.write(text)
    term.redirect(oldTerm)
end

local function clear()
    local oldTerm = term.redirect(window)
    for x=1,width,1 do
        for y=1,height,1 do
            if (y % 2 == 1) then
                term.setBackgroundColor(primaryBackgroundColor)
            else
                term.setBackgroundColor(secondaryBackgroundColor)
            end
            term.setCursorPos(x,y)
            term.write(" ")
        end
    end
    term.redirect(oldTerm)
end

local function clearSide(up)
    local oldTerm = term.redirect(window)
    local start,limit
    if up then
        start = 2
        limit = height/2-3
    else
        start = height/2+3
        limit = height
    end
    for x=1,width,1 do
        for y=start,limit,1 do
            if (y % 2 == 1) then
                term.setBackgroundColor(m_colors.green)
            else
                term.setBackgroundColor(m_colors.lightGreen)
            end
            term.setCursorPos(x,y)
            term.write(" ")
        end
    end
    term.redirect(oldTerm)
end

local function setupDealer(first)
    clearSide(true)
    dealerHand:draw(window, width, 2, first)
    playCardDraw()
end

local function setupPlayer()
    clearSide(false)

    playerHand:draw(window, width, height-16)
end

local function gameWin()
    BlackJack.Card.drawWin(window, math.floor(width/2), math.floor(height/2))
    Commons.Score:updateScore(Commons.Score:getScore() * multiplier)
    Commons.countScore(turtleName, storage, intermediaryStorage, printer, output)
    sleep(3)
    os.reboot()
end

local function gameLose()
    BlackJack.Card.drawBust(window, math.floor(width/2), math.floor(height/2))
    sleep(3)
    os.reboot()
end

local function gameDraw()
    BlackJack.Card.drawDraw(window, math.floor(width/2), math.floor(height/2))
    Commons.countScore(turtleName, storage, intermediaryStorage, printer, output)
    sleep(3)
    os.reboot()
end

local function compareHands()
    local playerValue = playerHand:evaluateHand()
    local dealerValue = dealerHand:evaluateHand()
    if playerValue > dealerValue then
        gameWin()
    elseif playerValue < dealerValue then
        gameLose()
    else
        gameDraw()
    end
end

local function dealerPlay()
    do
        setupDealer()
        local eval = dealerHand:evaluateHand()
        sleep(0.5)
        if eval == 0 then
            gameWin()
        elseif eval >= 17 then
            compareHands()
        end
        sleep(0.5)
    end
    while true do
        dealerHand:addCard(BlackJack.Card.newRandom(false))
        setupDealer()
        local eval = dealerHand:evaluateHand()
        sleep(0.5)
        if eval == 0 then
            gameWin()
        elseif eval >= 17 then
            compareHands()
        end
        sleep(0.5)
    end
end

local function stand()
    dealerPlay()
end

local function hit()
    playerHand:addCard(BlackJack.Card.newRandom(false))
    playCardDraw()
    setupPlayer()
    local eval = playerHand:evaluateHand()
    sleep(0.5)
    if eval == 0 then
        gameLose()
    end
end

local function double()
    multiplier = multiplier * 2
    hit()
    stand()
end

local function surrender()
    Commons.Score:updateScore(math.floor(Commons.Score:getScore()/2))
    gameDraw()
end

local function createButtons()
    local labelMap = {
        ["Hit"] = hit,
        ["Stand"] = stand,
        --["Double Down"] = double,
        ["Surrender"] = surrender
    }
    local labels = {
        "Hit",
        "Stand",
        --"Double Down",
        "Surrender"
    }
    local totalLength = 0
    for _, label in ipairs(labels) do
        totalLength = totalLength + #label + 3
    end
    local startX = math.floor(width / 2) - math.floor(totalLength / 2)
    local x = startX
    local y = math.floor(height / 2 - 1)
    for _, label in ipairs(labels) do
        local button = BlackJack.Button.new(label, labelMap[label], x, y, #label, 1, 0, m_colors.red, m_colors.darkRed, m_colors.white)
        table.insert(gameButtons, button)
        x = x + #label + 3
    end
end

local function drawButtons()
    for _, button in ipairs(gameButtons) do
        button:displayOnScreen(window, drawSquare, write)
    end
end

local function drawCredit(x, y, textColor, backGroundColor)
    local label = "Credit Type: " .. Commons.Credits.selectedCredit.name

    write(window, label, x, y, textColor, backGroundColor)
end

local function drawScore(x, y, primaryTextColor, primaryBackgroundColor, secondaryTextColor, secondaryBackgroundColor, offset)
    local scoreTitle = "Score:"
    local scoreText = tostring(Commons.Score.value)
    local scoreTextLen = string.len(scoreText) + 2
    if scoreTextLen < 13 then scoreTextLen = 13 end
    if offset then x = x - math.floor(scoreTextLen / 2) end

    write(window, scoreTitle, x+1, y, secondaryTextColor, secondaryBackgroundColor)
    drawSquare(window, x, y+1, scoreTextLen, 3, primaryBackgroundColor)
    write(window, scoreText, x+1, y+2, primaryTextColor, primaryBackgroundColor)
end

local function start()
    if Commons.Credits.selectedCredit == nil then return end
    gameStarted = true
    startButton:disable()
    clear()
    drawCredit(1, 1, m_colors.white, m_colors.red)
    drawScore(2, height/2 - 2, m_colors.white, m_colors.yellow, m_colors.white, m_colors.lightGray)
    setupDealer(true)
    setupPlayer()
    createButtons()
    drawButtons()
end

local function createStartButton()
    local label = "Start Game!"
    local x = math.floor(width / 2 - 1) - math.floor(#label / 2 + 1)
    local y = math.floor(height / 2 - 1) - 1
    startButton = BlackJack.Button.new(label, start, x, y, #label, 1, 1, m_colors.darkRed, m_colors.red, m_colors.white)
    startButton:displayOnScreen(window, drawSquare, write)
end

local function countCredits()
    local shouldThrow = false
    for i = 1,input.size(),1 do
        local item = input.getItemDetail(i)
        if item ~= nil
            and Commons.Credits:validCurrency(item.name)
            and (Commons.Credits.selectedCredit == nil or Commons.Credits.selectedCredit.name == Commons.Credits:getCreditType(item.name))
        then
            if Commons.Credits.selectedCredit == nil then
                Commons.Credits.selectedCredit = Commons.Credits.credits[Commons.Credits:getCreditType(item.name)]
                drawCredit(1, 1, m_colors.white, m_colors.red)
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
                    drawScore(width / 2, 3, m_colors.white, m_colors.yellow, m_colors.white, m_colors.lightGray, true)
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

local function drawScreen()
    clear()
    drawScore(width / 2, 3, m_colors.white, m_colors.yellow, m_colors.white, m_colors.lightGray, true)
    createStartButton()
end

local function tick()
    while true do
        if (not gameStarted) then countCredits() end
        sleep(0.05)
    end
end

local function events()
    sleep(0.5)
    while true do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        if event == "key_up" and eventData[2] == keys.q then
            return
        elseif event == "monitor_touch" then
            local x, y = eventData[3], eventData[4]
            if not gameStarted and startButton:collides(x, y) then
                startButton.clickEvent()
            elseif gameStarted then
                for _, button in pairs(gameButtons) do
                    if button:collides(x, y) then
                        button.clickEvent()
                    end
                end
            end
            sleep(0.1)
        end
    end
end

local function runGame()
    while true do
        drawScreen()
        parallel.waitForAny(tick, events)
    end
end

runGame()
