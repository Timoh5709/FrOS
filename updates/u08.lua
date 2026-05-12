term.clear()
term.setCursorPos(1,1)
local updateCode = "u08"
local locLua = require("/FrOS/sys/loc")
local httpV = require("/FrOS/sys/httpViewer")

print("This update needs a loc update.")

httpV.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/update.loc")
local language = "EN"
if FrOS.stg then
    language = FrOS.stg["language"]
end
FrOS.updateLoc = locLua.load("FrOS/localization/update.loc", language)

local loc = FrOS.sysLoc
for k,v in pairs(FrOS.updateLoc) do loc[k] = v end
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end

print(loc["welcome"])
print(loc["code"] .. updateCode)
print(loc["warning"])

local exBootloader = false
while true do
    print(loc["confirmBootloader"])
    write("? ")
    local choix = read()
    if choix == loc["yes"] then
        exBootloader = false
        break
    elseif choix == loc["no"] then
        exBootloader = true
        break
    end
end

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

textutils.slowPrint("-------------------------------------------------")

term.setBackgroundColor(colors.blue)
term.clear()
term.setCursorPos(1,1)

if not exBootloader then
    installGithub("startup.lua")
end
installGithub("FrOS/boot.lua")
installGithub("FrOS/main.lua")
installGithub("FrOS/sys/update.lua")
installGithub("FrOS/sys/httpViewer.lua")
installGithub("FrOS/sys/offline-installer.lua")
installGithub("FrOS/sys/script.lua")
installGithub("FrOS/localization/main.loc")
installGithub("FrOS/localization/error.loc")
installGithub("FrOS/localization/sys.loc")
installGithub("FrOS/localization/appStore.loc")
installGithub("FrOS/localization/manuel.loc")
installGithub("apps/appStore.lua")
installGithub("apps/manuel.lua")
installGithub("FrOS/version.txt")

local updateList = fs.open("FrOS/updateList.txt", "a")
if updateList then
    updateList.writeLine(updateCode)
else
    print(loc["error.unknownUnreadableFile"])
end
print(loc["success1"] .. updateCode .. loc["success2"])
sleep(1)