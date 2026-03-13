local MassaLib = require('MassaMainLib')

local args = { ... }

if not peripheral.isPresent("drive") then error("No Disk Drive attached.", 0) end
local drive = peripheral.wrap("drive")
if drive.getDiskID() == nil then error("No floppy disk in drive.", 0) end

local price, currency
if not pcall(function ()
    if MassaLib.tlength(args) ~= 2 then error() end
    price = tonumber(args[1])
    currency = args[2]
end) then error("Program requires 2 arguments: 'shop <price: number> <currency: string>'.", 0) end

