local MassaLib = require('MassaMainLib')
local MiningLib = require('MassaMiningTurtleLib')

local tags = {}
local ids = {}
local inclusive

local function stripMine(direction, limit)
    print("test3.1")
    limit = limit or 0
    local count = 0
    repeat
        print("test3.2")
        MiningLib.checkForOres(inclusive, ids, tags)
        print("test3.3")
        local success = direction()
        print("test3.4")
        if success then count = count + 1 end
    until not success or count == limit
    print("test3.3")
    if count == 0 then return end
    MiningLib.broadcast("Finished a strip.")
    return count
end

local function spiralSequence(rotations)
    rotations = (rotations * 2) - 1
    MiningLib.broadcast("Commencing vertical strip mining...")
    sleep(0.2)
    MiningLib.broadcast("Rotations: " .. tostring(rotations))
    MiningLib.broadcast("Whitelist: " .. tostring(inclusive))
    MiningLib.broadcast("Tags: " .. MassaLib.tprint(tags))
    MiningLib.broadcast("IDs: " .. MassaLib.tprint(ids))
    local count = 1
    print("test1")
    for i = 1, rotations, 1 do
        local depth
        local jMax = math.floor((i+1) / 2)
        for j = 1, jMax, 1 do
            if (i == rotations) and (j == jMax) then goto continue end

            if count % 2 == 1 then
                print("test2.1")
                depth = stripMine(MiningLib.digAndMoveDown)
                print("test2.2")
                if type(depth) ~= "number" then return end
                print("test2.3")
                for k = 1, 3, 1 do
                    turtle.up()
                    print("test2.4")
                end
                depth = depth - 3
            end
            MiningLib.digAndMoveForward()
            MiningLib.digAndMoveForward()
            if count % 2 == 1 then
                local depth2 = stripMine(MiningLib.digAndMoveDown)
                if type(depth2) ~= "number" then return end
                depth = depth + depth2
                local depth3 = stripMine(MiningLib.digAndMoveUp, depth)
                if type(depth3) ~= "number" then return end
            end
            count = count + 1

            ::continue::
        end
        if not (i == rotations) then turtle.turnLeft() end
    end
end

local function tutorial()
    print("How to use the VerticalMining script.")
    print("")
    print("[] means required.")
    print("<> means optional.")
    print("bool means either true or false.")
    print("")
    print("VerticalMining [gridSize: number] [inclusive: bool] <id: text> <tag: text>")
    print("")
    print("You can enter as many tags and ids as you wish, so long as they are entered after the rotations.")
    print("Tags must always be affixed with '#'.")
    print("The minimum rotations is 2, for a 2x2 grid.")
    print("'inclusive' is whether the ids and tags should be a whitelist (true) or blacklist (false).")
    print("")
    print("Example command:")
    print("'VerticalMining 3 #forge:ores minecraft:clay'")
    print("This will mine a 3x3 grid and gather any ores and clay it can find.")
end

local function init()
    if arg[1] == "help" then return true end
    local rotations = tonumber(arg[1]) or error("Requires a number argument.", 0)
    if (arg[2] and string.lower(arg[2])) == "true" and true or false then
        inclusive = true
    elseif (arg[2] and string.lower(arg[2])) ~= "false" then error("Requires a boolean argument.", 0)
    else inclusive = false end
    for i,argument in ipairs(arg) do
        if i <= 2 then goto continue end

        if string.sub(argument, 1, 1) == "#" then
            tags[i-2] = argument
        else
            ids[i-2] = argument
        end

        ::continue::
    end
    spiralSequence(rotations)
end

local guide = init()
if guide then tutorial() end