term.clear()
term.setCursorPos(1,1)

local repair = require("/FrOS/sys/repair")
if repair.check("FrOS/sys/gfrx.lua") then
    local gfrx = require("/FrOS/sys/gfrx")
    local gfx = gfrx(nil, {buffered = true})
    local _, y = term.getCursorPos()
    y = y * 3

    local buf1 = gfx:addBuffer(colors.green, colors.black)
    gfx:useBuffer(buf1)
    gfx:drawCircle(21, 23, 7, true, true)

    local buf2 = gfx:addBuffer(colors.red, colors.black)
    gfx:useBuffer(buf2)
    gfx:drawTriangle(1,3, 41,3, 21,23, true, true)
    gfx:flush()
    term.setCursorPos(1, 13)
end

term.setTextColor(colors.white)
print("Bienvenue sur FrOS")
print("Tapez 'aide' pour voir les commandes disponibles.")
print()

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
    repair.check("FrOS/localization/main.loc")
    repair.check("FrOS/localization/error.loc")
    repair.check("FrOS/localization/sys.loc")
    repair.check("FrOS/sys/script.lua")
    if repair.check("FrOS/sys/loc.lua") then
        local locLua = require("/FrOS/sys/loc")
        _G.FrOS.mainLoc = locLua.load("FrOS/localization/main.loc", "FR")
        _G.FrOS.errorLoc = locLua.load("FrOS/localization/error.loc", "FR")
        _G.FrOS.sysLoc = locLua.load("FrOS/localization/sys.loc", "FR")
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