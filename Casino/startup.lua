local run = require("run")
local Score = require("CasinoCommons").Score
local Credits = require("CasinoCommons").Credits
local countScore = require("CasinoCommons").countScore

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
local printerType = "printer"
local outputType = "turtle"

local storage = peripheral.find(storageType)
if not storage then
    error(("No Storage Peripheral of type %s connected to turtle."):format(storageType))
end

local intermediaryStorage = peripheral.find(intermediaryStorageType)
if not intermediaryStorage then
    error(("No Storage Peripheral of type %s connected to turtle."):format(intermediaryStorageType))
end

local printer = peripheral.find(printerType)
if not printer then
    error(("No Printer Peripheral of type %s connected to turtle."):format(printerType))
end

local output = peripheral.find(outputType)
if not output then
    error(("No Output Peripheral of type %s connected to turtle."):format(outputType))
end

Credits.selectedCredit = Credits.credits["iron"]
Score:updateScore(1000)
countScore(turtleName, storage, intermediaryStorage, printer, output)
