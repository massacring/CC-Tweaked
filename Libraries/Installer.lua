-- Meant to be run with wget in a computer or turtle terminal, not installed.
-- Usage: wget run https://raw.githubusercontent.com/massacring/CC-Tweaked/main/Libraries/Installer.lua <args>

local args = {}
for k,v in pairs(arg) do
    print(k)
    args[k] = v
end
args[0] = nil

print(textutils.serialize(args))