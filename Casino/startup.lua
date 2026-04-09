local run = require("run")
local Commons = require("CasinoCommons")

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
if not monitor then
    error("No Monitor Peripheral connected to turtle.")
end

for i = 0, 15 do monitor.setPaletteColour(2^i, term.nativePaletteColour(2^i)) end
monitor.setBackgroundColour(colours.black)
monitor.clear()
monitor.setTextScale(0.5)
local screen = window.create(monitor, 1, 1, monitor.getSize())
local width, height = screen.getSize()

local Game
local gameStarted = false

local gameSelectButtons = {}

local Games = {
    "BlackJack",
    "Plinko"
}

local function drawButtons()
    for _, button in ipairs(gameSelectButtons) do
        button:displayOnScreen(screen)
    end
end

--- RUN GAME ---

local function tick()
    while true do
        if (not gameStarted) then
            Commons.STD.countCredits(screen, storage, input, output, Game.colours)
        elseif Game and Game.tick then
            Game.tick(screen, speaker)
        end
        sleep(0.05)
    end
end

local function events()
    while true do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        if event == "monitor_touch" then
            local x, y = eventData[3], eventData[4]
            for _, button in ipairs(Commons.Buttons.allButtons) do
                if button:collides(x, y) then
                    button.clickEvent()
                    sleep(0.05)
                    goto continue
                end
            end
            if Game and Game.monitorTouch then
                Game.monitorTouch(screen, x, y)
            end
            sleep(0.05)
        elseif event == "redstone" then
            repeat
                monitor = peripheral.find("monitor")
                sleep(0.5)
            until monitor
            for i = 0, 15 do monitor.setPaletteColour(2^i, term.nativePaletteColour(2^i)) end
            monitor.setBackgroundColour(colours.black)
            monitor.clear()
            monitor.setTextScale(0.5)
            screen = window.create(monitor, 1, 1, monitor.getSize())
            width, height = screen.getSize()

            if Game then
                Game.redraw(screen, gameStarted)
            else
                drawButtons()
            end
        end
        ::continue::
    end
end

local function StartGame()
    gameStarted = true
end

local function EndGame()
    Commons.STD.countScore(storage, intermediaryStorage, output, printer, turtleName)
    sleep(3)
    os.reboot()
end

local function RunGame(game)
    if not game or not game.run or type(game.run) ~= "function" or not game.redraw or type(game.redraw) ~= "function" then
        error("Tried to run invalid Game module.", 2)
    end
    Game = game
    while Game ~= nil do
        Game.run(screen, speaker, EndGame, StartGame)
        parallel.waitForAny(tick, events)
    end
end

--- GAME SELECT ---

local function createButtons()
    local buttons = {}
    local totalLength = 0
    for _, label in ipairs(Games) do
        totalLength = totalLength + #label + 5
    end
    local startX = math.floor(width / 2) - math.floor(totalLength / 2)
    local x = startX
    local y = math.floor(height / 2 - 1)
    for _, label in ipairs(Games) do
        local button = Commons.Buttons:addButton(label, function ()
            for _, button in pairs(gameSelectButtons) do
                button:disable()
            end
            RunGame(require(label))
        end, x, y, #label, 1, 1, colours.pink, colours.red, colours.white)
        table.insert(buttons, button)
        x = x + #label + 5
    end
    return buttons
end

gameSelectButtons = createButtons()
drawButtons()
events()
