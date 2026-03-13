local MiningLib = require('MassaMiningTurtleLib')

local distance = tonumber(arg[1]) or 1
local direction = arg[2]
local force = false

if (arg[3] and string.lower(arg[3])) == "force" then force = true end

local move = (force) and MiningLib.digAndMoveForward or turtle.forward;
if direction == "back" or direction == "b" then
    if force then print("Cannot forcibly move backwards.") end
    move = turtle.back;
elseif direction == "up" or direction == "u" then
    move = (force) and MiningLib.digAndMoveUp or turtle.up;
elseif direction == "down" or direction == "d" then
    move = (force) and MiningLib.digAndMoveDown or turtle.down;
end

local fuel = turtle.getFuelLevel()
local requiredFuel = distance
if fuel < requiredFuel then
    error(string.format("[%d/%d] - Turtle requires %d more fuel.", fuel, requiredFuel, (requiredFuel-fuel)), 0)
end

for _ = 1, distance, 1 do
    move()
end