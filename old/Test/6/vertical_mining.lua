local MassaLib = require('MassaTurtleLib')

local Directions = {
    FRONT = 1,
    RIGHT = 2,
    BACK = 3,
    LEFT = 4
}
local facing = Directions.FRONT

local function face(direction)
    if facing == direction then return end
    local difference = facing - direction
    if difference < 0 then difference = difference * -1 end
    if difference == 1 then
        if facing < direction then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
    end
    if difference == 2 then
        turtle.turnRight()
        turtle.turnRight()
    end
    if difference == 3 then
        if facing > direction then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
    end
    facing = direction
end

local function checkFuel()
    if turtle.getFuelLevel() > 100 then return end

    turtle.digUp()
    turtle.select(MassaLib.getItemIndex("enderchests:ender_chest"))
    turtle.placeUp()

    local count = 0
    repeat
        turtle.dropUp()
        turtle.suckUp()
        local item = turtle.getItemDetail(turtle.getSelectedSlot())
        count = count + 1
    until item.name == "minecraft:lava_bucket" or count > 20
    if count > 20 then
        turtle.dropUp()
        error("Could not refuel.", 1)
    end

    turtle.refuel()
    turtle.dropUp()
    turtle.digUp()
    checkFuel()
end

local function checkStorage()
    turtle.place()
    sleep(0.1)
    local s, data = turtle.inspect()
    print(textutils.serialise(data.state))
    turtle.dig()
end

local function digAndMove(direction)
    checkFuel()
    local count = 0
    repeat
        count = count + 1
        local success = direction()
    until success or count > 20
    return count <= 20
end

local function digAndMoveForward()
    return digAndMove(function ()
        turtle.dig()
        return turtle.forward()
    end)
end

local function digAndMoveUp()
    return digAndMove(function ()
        turtle.digUp()
        return turtle.up()
    end)
end

local function digAndMoveDown()
    return digAndMove(function ()
        turtle.digDown()
        return turtle.down()
    end)
end

local function checkForOres()
    do
        local has_block, data = turtle.inspectUp()
        if not has_block then goto continue end
        if not data.tags["forge:ores"] then goto continue end

        local success = digAndMoveUp()
        checkForOres()
        if success then digAndMoveDown() end

        ::continue::
    end
    do
        local has_block, data = turtle.inspectDown()
        if not has_block then goto continue end
        if not data.tags["forge:ores"] then goto continue end

        local success = digAndMoveDown()
        checkForOres()
        if success then digAndMoveUp() end

        ::continue::
    end
    for i = 1, 4, 1 do
        face(facing+1)
        local has_block, data = turtle.inspect()
        if not has_block then goto continue end
        if not data.tags["forge:ores"] then goto continue end

        local success = digAndMoveForward()
        checkForOres()
        if success then
            face(facing+2)
            digAndMoveForward()
            face(facing+2)
        end

        ::continue::
    end
end

local function stripMine(direction, limit)
    limit = limit or 0
    local count = 0
    repeat
        checkForOres()
        local success = direction()
        if success then count = count + 1 end
    until not success or count == limit
    return count
end

local function spiralSequence(rotations)
    rotations = (rotations * 2) - 1
    local count = 1
    for i = 1, rotations, 1 do
        local depth = 0
        local jMax = math.floor((i+1) / 2)
        for j = 1, jMax, 1 do
            if (i == rotations) and (j == jMax) then goto continue end

            if count % 2 == 1 then depth = stripMine(digAndMoveDown) end
            digAndMoveForward()
            digAndMoveForward()
            if count % 2 == 1 then stripMine(digAndMoveUp, depth) end
            count = count + 1

            ::continue::
        end
        if not (i == rotations) then turtle.turnLeft() end
    end
end

checkStorage()

--[[
do
    checkFuel()
    local rotations = tonumber(arg[1]) or error("Requires a number argument.", 0)
    spiralSequence(rotations)
end
--]]