-- https://stackoverflow.com/a/41943392/22091473
local function tprint(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2 
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  "= "   
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\r\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\r\n"
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return(toprint)
end

-- https://stackoverflow.com/a/2705804/22091473
local function tlength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- https://stackoverflow.com/a/7615129/22091473
local function split(str, separator)
    if separator == nil then
        separator = "%s"
    end
    local t={}
    for str in string.gmatch(str, "([^"..separator.."]+)") do
        table.insert(t, str)
    end
    return t
end

return { tprint = tprint, tlength = tlength, split = split }