term.clear()
term.setCursorPos(1,1)
local updateCode = "u082"
local stg = require("/FrOS/sys/stg")

local loc = FrOS.sysLoc
for k,v in pairs(FrOS.updateLoc) do loc[k] = v end
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end

print(loc["welcome"])
print(loc["code"] .. updateCode)
print(loc["warning"])
textutils.slowPrint("-------------------------------------------------")

local function installGithub(filename)
    print(loc[".installGithub.download1"] .. filename .. loc[".installGithub.download2"])
    local downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/" .. filename)
    if downloader then
        local input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
		print(loc[".installGithub.success1"] .. filename .. loc[".installGithub.success2"])
        return true
    else
        print(loc[".installGithub.error"] .. filename)
    end
end

term.setBackgroundColor(colors.blue)
term.clear()
term.setCursorPos(1,1)

installGithub("FrOS/boot.lua")
installGithub("FrOS/main.lua")
installGithub("FrOS/sys/theme.lua")
installGithub("FrOS/sys/statusBar.lua")
installGithub("FrOS/sys/textViewer.lua")
installGithub("FrOS/sys/stg.lua")
installGithub("FrOS/sys/3dgfrx.lua")
installGithub("FrOS/sys/script.lua")
installGithub("FrOS/sys/update.lua")
installGithub("FrOS/sys/offline-installer.lua")
installGithub("FrOS/localization/main.loc")
installGithub("FrOS/localization/error.loc")
installGithub("FrOS/localization/notes.loc")
installGithub("FrOS/media/FrOS_b.obj")
installGithub("FrOS/media/FrOS_t.obj")
installGithub("apps/appStore.lua")
installGithub("apps/manuel.lua")
installGithub("apps/notes.lua")
installGithub("apps/render.lua")
installGithub("FrOS/version.txt")

stg.set("FrOS/config.stg", "oobe", "1")

local updateList = fs.open("FrOS/updateList.txt", "a")
if updateList then
    updateList.writeLine(updateCode)
else
    print(loc["error.unknownUnreadableFile"])
end
print(loc["success1"] .. updateCode .. loc["success2"])
sleep(1)