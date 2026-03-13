local Commons = require("Commons")
local Card = require("Card")
local Hand = require("Hand")
local Button = require("Button")
local cashout = require('cashout')
local monitor = peripheral.find("monitor")
local input = peripheral.find("minecraft:hopper")
local storage = peripheral.find("minecraft:chest")
local modem = peripheral.wrap("bottom")
local printer = peripheral.find("printer")
if printer.getInkLevel() == 0 and printer.getPaperLevel() == 0 then
  error("Cannot start a new page. Do you have ink and paper?")
end

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

local window = window.create(monitor, 1, 1, 80, 38)

-- Changes the default palette
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

monitor.setTextScale(0.5)

local width, height = window.getSize()

local playerHand = Hand.new(false)
local dealerHand = Hand.new(false)

local startButton = {}
local gameButtons = {}
local gameStarted = false
local multiplier = 2

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
end

local function setupPlayer()
    clearSide(false)

    playerHand:draw(window, width, height-16)
end

local function gameWin()
    Card.drawWin(window, math.floor(width/2), math.floor(height/2))
    Commons.Score.updateScore(Commons.Score.getScore() * multiplier)
    cashout()
    sleep(3)
    os.reboot()
end

local function gameLose()
    Card.drawBust(window, math.floor(width/2), math.floor(height/2))
    sleep(3)
    os.reboot()
end

local function gameDraw()
    Card.drawDraw(window, math.floor(width/2), math.floor(height/2))
    cashout()
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
    setupDealer()
    local eval = dealerHand:evaluateHand()
    sleep(0.5)
    if eval == 0 then
        gameWin()
    elseif eval >= 17 then
        compareHands()
    end
    sleep(0.5)
    while true do
        dealerHand:addCard(Card.newRandom(false))
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
    playerHand:addCard(Card.newRandom(false))
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
    Commons.Score.updateScore(math.floor(Commons.Score.getScore()/2))
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
        local button = Button.new(label, labelMap[label], x, y, #label, 1, 0, m_colors.red, m_colors.darkRed, m_colors.white)
        table.insert(gameButtons, button)
        x = x + #label + 3
    end
end

local function drawButtons()
    for _, button in ipairs(gameButtons) do
        button:displayOnScreen(window, Commons.Paint.drawSquare, Commons.Paint.write)
    end
end

local function start()
    if Commons.Credits.selectedCredit == nil then return end
    gameStarted = true
    startButton:disable()
    Commons.Paint.clear(window, width, height, m_colors.green, m_colors.lightGreen)
    Commons.Credits.drawCredit(window, 1, 1, m_colors.white, m_colors.red)
    Commons.Score.drawScore(window, 2, height/2 - 2, m_colors.white, m_colors.yellow, m_colors.white, m_colors.lightGray)
    setupDealer(true)
    setupPlayer()
    createButtons()
    drawButtons()
end

local function createStartButton()
    local label = "Start Game!"
    local x = math.floor(width / 2 - 1) - math.floor(#label / 2 + 1)
    local y = math.floor(height / 2 - 1) - 1
    startButton = Button.new(label, start, x, y, #label, 1, 1, m_colors.darkRed, m_colors.red, m_colors.white)
    startButton:displayOnScreen(window, Commons.Paint.drawSquare, Commons.Paint.write)
end

local function countCredits()
    local shouldThrow = false
    for i = 1,input.size(),1 do
        local item = input.getItemDetail(i)
        if item ~= nil
            and Commons.Credits.validCurrency(item.name)
            and (Commons.Credits.selectedCredit == nil or Commons.Credits.selectedCredit == Commons.Credits.getName(item.name))
        then
            if Commons.Credits.selectedCredit == nil then
                Commons.Credits.selectedCredit = Commons.Credits.getName(item.name)
                Commons.Credits.drawCredit(window, 1, 1, m_colors.white, m_colors.red)
            end
            local count = item.count
            local value = Commons.Credits.getValueByName(item.name)
            for _ = 1, count, 1 do
                local newValue = Commons.Score.getScore() + value
                if (newValue > Commons.Score.max) then
                    input.pushItems(modem.getNameLocal(), i, 1)
                    shouldThrow = true
                else
                    Commons.Score.updateScore(newValue)
                    Commons.Score.drawScore(window, width / 2, 3, m_colors.white, m_colors.yellow, m_colors.white, m_colors.lightGray, true)
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

local function drawScreen()
    Commons.Paint.clear(window, width, height, m_colors.green, m_colors.lightGreen)
    Commons.Score.drawScore(window, width / 2, 3, m_colors.white, m_colors.yellow, m_colors.white, m_colors.lightGray, true)
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