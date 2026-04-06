-- Meant to be run with wget in a computer or turtle terminal, not installed.
-- Usage: wget run https://raw.githubusercontent.com/massacring/CC-Tweaked/main/Libraries/Installer.lua <args>

local args = arg
local arg = {}
local counter = 0
for k,v in pairs(args) do
    counter = counter + 1
    if counter > 2 and k ~= 0 then
        print(textutils.serialize(arg))
        table.insert(arg, v)
    end
end
