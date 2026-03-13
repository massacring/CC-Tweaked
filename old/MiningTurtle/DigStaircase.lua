local MiningLib = require('MassaMiningTurtleLib')

local function tutorial()
    print("How to use the DigStaircase script.")
    print("")
    print("[] means required.")
    print("<> means optional.")
    print("")
    print("DigStaircase [depth: number] <direction: up or down>")
    print("")
    print("Example command:")
    print("'DigStaircase 10'")
    print("This will dig a staircase downwards 10 blocks.")
end

local function staircase(direction, depth)
    for x = 1, depth, 1 do
        turtle.digDown()
        MiningLib.digAndMoveForward()
        if (direction == "up") then MiningLib.digAndMoveUp()
        else MiningLib.digAndMoveDown() end
    end
end

local function init()
    if arg[1] == "help" then return true end
    local depth = tonumber(arg[1]) or error("Requires number argument", 0)
    local direction = arg[2]

    staircase(direction, depth)
end

local guide = init()
if guide then tutorial() end