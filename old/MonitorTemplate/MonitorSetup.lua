local function DownloadLFL()
    write("Connecting to pastebin.com... ")
    local cacheBuster = ("%x"):format(math.random(0, 2 ^ 30))
    local response, err = http.get(
        "https://pastebin.com/raw/" .. textutils.urlEncode("Be7wcbNK") .. "?cb=" .. cacheBuster
    )
    if response then
        local headers = response.getResponseHeaders()
        if not headers["Content-Type"] or not headers["Content-Type"]:find("^text/plain") then
            io.stderr:write("Failed.\n")
            print("Pastebin blocked the download due to spam protection. Please complete the captcha in a web browser: https://pastebin.com/" .. textutils.urlEncode(paste))
            return
        end
        print("Success.")
        local res = response.readAll()
        response.close()
        local name = "LoadFilesLib.lua"
        local sPath = shell.resolve(name)
        if res then
            local file = fs.open(sPath, "w")
            file.write(res)
            file.close()

            print("Downloaded as " .. name)
        end
    else
        io.stderr:write("Failed.\n")
        print(err)
    end
end
DownloadLFL()

local LFL = require('LoadFilesLib')

LFL.loadFile("NDpakMXp", "Button.lua")
LFL.loadFile("WF62hK0z", "Screen.lua")
LFL.loadFile("d9hFNFHZ", "MassaPeripheralLib.lua")
LFL.loadFile("V82gasfw", "MassaMainLib.lua")
LFL.loadFile("rb49e4uJ", "startup.lua")

shell.run("set motd.enable false")
print("Rebooting...")
sleep(3)
os.reboot()