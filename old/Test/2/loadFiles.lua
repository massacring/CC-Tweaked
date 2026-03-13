local function extractId(paste)
    local patterns = {
        "^([%a%d]+)$",
        "^https?://pastebin.com/([%a%d]+)$",
        "^pastebin.com/([%a%d]+)$",
        "^https?://pastebin.com/raw/([%a%d]+)$",
        "^pastebin.com/raw/([%a%d]+)$",
    }

    for i = 1, #patterns do
        local code = paste:match(patterns[i])
        if code then return code end
    end

    return nil
end

local function getPastebin(url)
    local paste = extractId(url)
    if not paste then
        io.stderr:write("Invalid pastebin code.\n")
        io.write("The code is the ID at the end of the pastebin.com URL.\n")
        return
    end

    write("Connecting to pastebin.com... ")
    -- Add a cache buster so that spam protection is re-checked
    local cacheBuster = ("%x"):format(math.random(0, 2 ^ 30))
    local response, err = http.get(
        "https://pastebin.com/raw/" .. textutils.urlEncode(paste) .. "?cb=" .. cacheBuster
    )

    if response then
        -- If spam protection is activated, we get redirected to /paste with Content-Type: text/html
        local headers = response.getResponseHeaders()
        if not headers["Content-Type"] or not headers["Content-Type"]:find("^text/plain") then
            io.stderr:write("Failed.\n")
            print("Pastebin blocked the download due to spam protection. Please complete the captcha in a web browser: https://pastebin.com/" .. textutils.urlEncode(paste))
            return
        end

        print("Success.")

        local sResponse = response.readAll()
        response.close()
        return sResponse
    else
        io.stderr:write("Failed.\n")
        print(err)
    end
end

local function loadFile(id, name)
    local sPath = shell.resolve(name)
    local res = getPastebin(id)
    if res then
        local file = fs.open(sPath, "w")
        file.write(res)
        file.close()

        print("Downloaded as " .. name)
    end
end

loadFile("8YhNWRgW", "../MassaTurtleLib.lua")
loadFile("ScvYuRq2", "../vertical_mining.lua")
shell.run("set motd.enable false")
os.reboot()
