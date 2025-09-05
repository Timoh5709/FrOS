term.clear()
term.setCursorPos(1,1)

local repair = require("/FrOS/sys/repair")

print("Bienvenue sur FrOS")
print("Tapez 'aide' pour voir les commandes disponibles.")

if repair.check("FrOS/drivers/init.lua") then
    shell.run("FrOS/drivers/init.lua")
end

if repair.check("FrOS/main.lua") then
    repair.check("FrOS/sys/textViewer.lua")
    repair.check("FrOS/sys/update.lua")
    repair.check("FrOS/sys/statusBar.lua")
    repair.check("FrOS/sys/httpViewer.lua")
    local canPlay = false
    local dfpwmPlayer
    if repair.check("FrOS/sys/dfpwmPlayer.lua") then
        dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
        canPlay = true
    end
    if repair.check("FrOS/media/startup.dfpwm") then
        if canPlay then
            local co = coroutine.create(function ()
                dfpwmPlayer.play("FrOS/media/startup.dfpwm")
            end)
            coroutine.resume(co)
        end
    end
    if fs.exists("temp/install.lua") then
        textViewer.cprint("'temp/install.lua' present, suppression.", colors.orange)
        fs.delete("temp/install.lua")
        textViewer.cprint("Le système d'installation autonome a été désinstallé.", colors.orange)
    end
    textutils.slowPrint("-------------------------------------------------")
    shell.run("FrOS/main.lua")
end