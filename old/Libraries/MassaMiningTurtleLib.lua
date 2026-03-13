local MassaLib = require("MassaMainLib")

local modem
for i, name in ipairs(peripheral.getNames()) do
    modem = peripheral.wrap(name)
    if peripheral.getType(modem) == "modem" then
        if modem.isWireless() then break
        else modem = nil end
    else modem = nil end
end
local channel = 4200 -- Info Log channel, never replies
if modem then modem.open(channel) end

local DIRECTIONS = {
    FRONT = 1,
    RIGHT = 2,
    BACK = 3,
    LEFT = 4
}

local facing = DIRECTIONS.FRONT
local x,y,z = 0,0,0

local moves = {}

local broadcast, digAndMove

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

local function turn(direction)
    face(facing+direction)
end

local function digAndMoveForward(override)
    return digAndMove(function ()
        turtle.dig()
        local success = turtle.forward()
        if success then
            if facing == DIRECTIONS.FRONT then
                x = x + 1
            elseif facing == DIRECTIONS.RIGHT then
                z = z + 1
            elseif facing == DIRECTIONS.BACK then
                x = x - 1
            else
                z = z - 1
            end
            table.insert(moves, {x, y, z})
        end
        return success
    end, override)
end

local function digAndMoveUp(override)
    return digAndMove(function ()
        turtle.digUp()
        local success = turtle.up()
        if success then
            y = y + 1
            table.insert(moves, {x, y, z})
        end
        return success
    end, override)
end

local function digAndMoveDown(override)
    return digAndMove(function ()
        turtle.digDown()
        local success = turtle.down()
        if success then
            y = y - 1
            table.insert(moves, {x, y, z})
        end
        return success
    end, override)
end

local function checkRefuelOption()
    if turtle.getFuelLevel() > 100 then return -1 end
    if turtle.getFuelLevel() % 10 == 0 then broadcast("Low on fuel.") end
    if turtle.getFuelLevel() > 0 then
        if turtle.detect() then
            broadcast("No room to refuel, continuing mission.")
            return -1
        end
    else broadcast("Out of fuel. Forcefully refueling.") end
    broadcast("Attempting to refuel.")
    local tankSlot = 0
    for i = 1, 16, 1 do
        local data = turtle.getItemDetail(i)
        if not data then goto continue end
        local itemName = data["name"]
        local storageNames = { "dimstorage:dimensional_tank", "enderchests:ender_tank" }
        local result = false
        for _,name in ipairs(storageNames) do
            if name == itemName then
                result = true
                break
            end
        end
        if result then
            tankSlot = i
            break
        end
        ::continue::
    end
    if tankSlot == 0 then
        broadcast("Turtle has no fuel tank.")
    end
    return tankSlot
end

local function refuel(tankSlotId)
    local bucketSlot = 0
    for i = 1, 16, 1 do
        local data = turtle.getItemDetail(i)
        if not data then goto continue end
        local itemName = data["name"]
        local result = itemName == "minecraft:bucket"
        if result then
            bucketSlot = i
            break
        end
        ::continue::
    end
    if bucketSlot == 0 then
        broadcast("Turtle has no bucket.")
        return false
    end

    turtle.dig()
    turtle.select(tankSlotId)
    automataCore.useOnBlock()

    turtle.select(bucketSlot)
    turtle.place()
    local item = turtle.getItemDetail(turtle.getSelectedSlot())
    if item.name ~= "minecraft:lava_bucket" then
        turtle.place()
        turtle.dig()
        broadcast("Could not refuel.")
        return false
    end

    turtle.refuel()
    turtle.dig()
    return true
end

local function abortMission()
    if turtle.getFuelLevel() > 100 then return end
    broadcast("Low on fuel, returning to surface.")

    while y < 69 do
        local success = digAndMoveUp(true)
        if not success then goto continue end
        for i = 1, 4, 1 do
            if digAndMoveForward(true) then break end
            face(facing+1)
        end
        ::continue::
    end
    broadcast("Back on surface. Shutting down...")
    exit = true
end

local function checkInventory()
    local storageSlot = 0
    local count = 0
    for i = 1, 16, 1 do
        local data = turtle.getItemDetail(i)
        if data then count = count + 1
        else goto continue end
        local itemName = data["name"]
        local storageNames = { "dimstorage:dimensional_chest", "enderchests:ender_chest", "cyclic:crate", "minecraft:shulker_box" }
        local storageTypes = { "^sophisticatedstorage:%a+_shulker_box", "^furnish:%a+_crate" }
        local result = false
        for _,name in ipairs(storageNames) do
            if name == itemName then
                result = true
                break
            end
        end
        if not result then for _,type in ipairs(storageTypes) do
            if itemName:find(type) then
                result = true
                break
            end
        end end
        if result then
            storageSlot = i
            break
        end
        ::continue::
    end
    if storageSlot == 0 then return end
    if count < 8 then return end

    turtle.digUp()
    turtle.select(storageSlot)
    turtle.placeUp()
    for i = 1, 16, 1 do
        turtle.select(i)
        turtle.dropUp()
    end
    turtle.digUp()
end

local function checkData(inclusive, has_block, data, ids, tags)
    if inclusive == nil then inclusive = true end
    if not has_block then return false end
    local result = false
    for _,id in ipairs(ids) do
        if inclusive then
            if data.name == id then result = true end
        else
            if not data.name == id then result = true end
        end
    end
    for _,tag in ipairs(tags) do
        if inclusive then
            if data.tags[tag] then result = true end
        else
            if not data.tags[tag] then result = true end
        end
    end
    if not result then return false end
    return true
end

local function veinMine(inclusive, ids, tags)
    if (not ids) and (not tags) then return end
    do
        local has_block, data = turtle.inspectUp()
        if not checkData(inclusive, has_block, data, ids, tags) then goto continue end

        local success = digAndMoveUp()
        veinMine(inclusive, ids, tags)
        if success then digAndMoveDown() end

        ::continue::
    end
    do
        local has_block, data = turtle.inspectDown()
        if not checkData(inclusive, has_block, data, ids, tags) then goto continue end

        local success = digAndMoveDown()
        veinMine(inclusive, ids, tags)
        if success then digAndMoveUp() end

        ::continue::
    end
    for i = 1, 4, 1 do
        face(facing+1)
        local has_block, data = turtle.inspect()
        if not checkData(inclusive, has_block, data, ids, tags) then goto continue end

        local success = digAndMoveForward()
        veinMine(inclusive, ids, tags)
        if success then
            face(facing+2)
            digAndMoveForward()
            face(facing+2)
        end

        ::continue::
    end
end

function digAndMove(direction, override)
    local refuelOptions = -1 --checkRefuelOption()
    local refuelResult = refuelOptions < 0
    if refuelOptions > 0 then
        refuelResult = refuel(refuelOptions)
    end
    if not refuelResult or refuelOptions == 0 then
        broadcast("Refuel failed. Aborting mission.")
        --abortMission()
        error("Mission aborted.", 0)
        return
    end
    checkInventory()
    if exit then return end
    local count = 0
    repeat
        count = count + 1
        local success = direction()
    until success or count > 20
    return count <= 20
end

function broadcast(message)
    print(message)
    if not modem then return end
    modem.transmit(0, channel, message)
end

return { DIRECTIONS = DIRECTIONS, face = face, turn = turn, digAndMoveForward = digAndMoveForward, digAndMoveUp = digAndMoveUp, digAndMoveDown = digAndMoveDown, veinMine = veinMine, broadcast = broadcast }
