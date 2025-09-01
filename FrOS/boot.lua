term.clear()
term.setCursorPos(1,1)

local repair = require("/FrOS/sys/repair")

print("Bienvenue sur FrOS")
print("Tapez 'aide' pour voir les commandes disponibles.")

if repair.check("FrOS/drivers/init.lua") then
    shell.run("FrOS/drivers/init.lua")
end

local speaker = peripheral.find("speaker")

if repair.check("FrOS/main.lua") then
    repair.check("FrOS/sys/textViewer.lua")
    repair.check("FrOS/sys/update.lua")
    repair.check("FrOS/sys/statusBar.lua")
    repair.check("FrOS/sys/httpViewer.lua")
    local canPlay = false
    if repair.check("FrOS/sys/dfpwmPlayer.lua") then
        local dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
        canPlay = true
    end
    if speaker ~= nil then
        if repair.check("FrOS/media/startup.dfpwm") then
            if canPlay then
                dfpwmPlayer.play("FrOS/media/startup.dfpwm")
            end
        end
    else
    end  
    if fs.exists("temp/install.lua") then
        term.setTextColor(colors.orange)
        print("'temp/install.lua' present, suppression.")
        fs.delete("temp/install.lua")
        print("Le système d'installation autonome a été désinstallé.")
        term.setTextColor(colors.white)
    end
    textutils.slowPrint("-------------------------------------------------")
    shell.run("FrOS/main.lua")
end