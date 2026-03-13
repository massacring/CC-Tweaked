local TurtleLib = require('MassaTurtleLib')
local MiningLib = require('MassaMiningTurtleLib')

local tags = {}
local ids = {}
local inclusive = true

local function tutorial()
    print("How to use the StripMine script.")
    print("")
    print("[] means required.")
    print("<> means optional.")
    print("")
    print("StripMine [depth: number] [distance: number] <direction: left or right> <inclusive: bool> <id: text> <tag: #text>")
    print("")
    print("Example command:")
    print("'StripMine 10 3 left #forge:ores'")
    print("This will dig a 2x1 hole forwards for 10 blocks, then go to the left by 3 and dig back, mining all ores along the way.")
end

local function tunnel(depth)
    for _ = 1, depth, 1 do
        local has_block = turtle.detect()
        if has_block then
            MiningLib.digAndMoveForward()
            MiningLib.veinMine(inclusive, ids, tags)
        else turtle.forward() end

        local has_blockUp = turtle.detectUp()
        if has_blockUp then
            MiningLib.digAndMoveUp()
            MiningLib.veinMine(inclusive, ids, tags)
            turtle.down()
        end

        if not turtle.detectDown() then
            for i = 1, 16, 1 do
                local item = turtle.getItemDetail(i)
                if not item then goto continue end
        
                if item.name == "minecraft:cobblestone" or item.name == "minecraft:cobbled_deepslate" then
                    turtle.select(i)
                    turtle.placeDown()
                    break
                end
        
                ::continue::
            end
        end
    end
end

local function turn(direction)
    if (direction == "right") then turtle.turnRight()
    else turtle.turnLeft() end
end

local function strip(direction, depth, distance)
    tunnel(depth)

    turn(direction)

    tunnel(distance)

    turn(direction)

    tunnel(depth)

    turn(direction)

    tunnel(distance)
end

local function init()
    if arg[1] == "help" then return true end
    local depth = tonumber(arg[1]) or error("Requires number argument", 0)
    local distance = tonumber(arg[2]) or error("Requires number argument", 0)
    local direction
    local hasInclusive = true
    if (not arg[3]) or (arg[3] ~= "right" and arg[3] ~= "left" and arg[3] ~= "r" and arg[3] ~= "l") then direction = nil
    else direction = arg[3] end

    if (arg[3] and string.lower(arg[3])) == "false" then
        inclusive = false
    elseif (arg[4] and string.lower(arg[4])) == "false" then
        inclusive = false
    elseif (arg[3] and string.lower(arg[3])) ~= "true" and (arg[4] and string.lower(arg[4])) ~= "true" then hasInclusive = false
    end
    for i,argument in ipairs(arg) do
        if i <= 2 then goto continue end
        if (direction or hasInclusive) and i <= 3 then goto continue end
        if (direction and hasInclusive) and i <= 4 then goto continue end

        if string.sub(argument, 1, 1) == "#" then
            table.insert(tags, argument:sub(2))
        else
            table.insert(ids, argument)
        end

        ::continue::
    end

    local fuel = turtle.getFuelLevel()
    local requiredFuel = (depth + distance) * 2 * 3
    if fuel < requiredFuel then
        error(string.format("[%d/%d] - Turtle requires %d more fuel.", fuel, requiredFuel, (requiredFuel-fuel)), 0)
    end

    strip(direction, depth, distance)
end

local guide = init()
if guide then tutorial() end