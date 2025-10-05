term.clear()
term.setCursorPos(1,1)

local repair = require("/FrOS/sys/repair")

print("Bienvenue sur FrOS")
print("Tapez 'aide' pour voir les commandes disponibles.")

_G.FrOS = _G.FrOS or {}

if repair.check("FrOS/drivers/init.lua") then
    shell.run("FrOS/drivers/init.lua")
end

if repair.check("FrOS/main.lua") then
    repair.check("FrOS/sys/textViewer.lua")
    repair.check("FrOS/sys/update.lua")
    repair.check("FrOS/sys/offline-installer.lua")
    repair.check("FrOS/sys/statusBar.lua")
    repair.check("FrOS/sys/httpViewer.lua")
    repair.check("FrOS/sys/progressBar.lua")
    repair.check("FrOS/sys/utf8.lua")
    repair.check("FrOS/sys/FZIP.lua")
    if repair.check("FrOS/sys/loc.lua") then
        local locLua = require("/FrOS/sys/loc")
        _G.FrOS.mainLoc = locLua.load("FrOS/localization/main.loc", "FR")
        if FrOS.mainLoc then
            term.setTextColor(colors.green)
            print(FrOS.mainLoc[".locLoaded"])
            term.setTextColor(colors.white)
        else
            term.setTextColor(colors.red)
            print("Error : The localization file for the shell wasn't loaded properly, please contact FrOS' developer team.")
            term.setTextColor(colors.white)
        end
    end
    local canPlay = false
    local dfpwmPlayer
    if repair.check("FrOS/sys/dfpwmPlayer.lua") then
        dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
        canPlay = true
    end
    if repair.check("FrOS/media/startup.dfpwm") then
        if canPlay then
            dfpwmPlayer.playStartupSound()
        end
    end
    repair.check("FrOS/media/error.dfpwm")
    repair.check("FrOS/media/ask.dfpwm")
    repair.check("FrOS/media/shutdown.dfpwm")

    fs.delete("temp")
    fs.makeDir("temp")
    textutils.slowPrint("-------------------------------------------------")
    shell.run("FrOS/main.lua")
end