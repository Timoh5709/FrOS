term.clear()
term.setCursorPos(1,1)

local toRepair = {}
local repair
local function check(path)
    if not fs.exists(path) then 
        term.setTextColor(colors.red)
        print("Erreur : le fichier '" .. path .. "' est introuvable. Le système peut être instable et endommagé.")
        table.insert(toRepair, path)
        sleep(0.1)
        term.setTextColor(colors.white)
        return false
    else
        term.setTextColor(colors.green)
        print("'" .. path .. "' présent.")
        sleep(0.1)
        term.setTextColor(colors.white)
        return true
    end
end

print("Bienvenue sur FrOS")
print("Tapez 'aide' pour voir les commandes disponibles.")

if check("drivers/init.lua") then
    shell.run("drivers/init.lua")
end

local speaker = peripheral.find("speaker")
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

if fs.exists("main.lua") then
    term.setTextColor(colors.green)
    print("'main.lua' present.")
    sleep(0.1)
    term.setTextColor(colors.white)
    check("sys/textViewer.lua")
    check("sys/update.lua")
    check("sys/statusBar.lua")
    check("sys/httpViewer.lua")
    if speaker ~= nil then
        if fs.exists("media/startup.dfpwm") then
            term.setTextColor(colors.green)
            print("'media/startup.dfpwm' present.")
            sleep(0.1)
            term.setTextColor(colors.white)
            for chunk in io.lines("media/startup.dfpwm", 16 * 1024) do
                local buffer = decoder(chunk)
            
                while not speaker.playAudio(buffer) do
                    os.pullEvent("speaker_audio_empty")
                end
            end 
        else
            term.setTextColor(colors.red)
            print("Erreur : le fichier 'media/startup.dfpwm' est introuvable. Le système peut être endommagé.")
            table.insert(toRepair, "media/startup.dfpwm")
            sleep(0.1)
            term.setTextColor(colors.white)
        end
    else   
        sleep(1)
    end  
    if fs.exists("temp/install.lua") then
        term.setTextColor(colors.orange)
        print("'temp/install.lua' present, suppression.")
        sleep(0.1)
        fs.delete("/temp/install.lua")
        print("Le système d'installation autonome a été désinstallé.")
        sleep(0.1)
        term.setTextColor(colors.white)
    end
    if not fs.exists("sys/repair.lua") then 
        term.setTextColor(colors.red)
        print("Erreur : le fichier 'sys/repair.lua' est introuvable. Le système peut être instable et endommagé.")
        sleep(0.1)
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.green)
        print("'sys/repair.lua' present.")
        sleep(0.1)
        term.setTextColor(colors.white)
        repair = require("sys/repair")
        if #toRepair > 0 then
            print("Il y a un ou plusieurs fichiers manquants, voulez-vous les réparer ? (oui/non)")
            write("? ")
            local confirmation = read()
            if confirmation == "oui" then
                for i = 1, #toRepair do
                    repair.file(toRepair[i])
                end
                term.setBackgroundColor(colors.black)
                term.clear()
            else
              print("Réparation annulée. Le système peut être instable.")
            end
        end
    end
    textutils.slowPrint("-------------------------------------------------")
    shell.run("main.lua")
else
    term.setTextColor(colors.red)
    print("Erreur : le fichier 'main.lua' est introuvable. Veuillez réinstaller le système en exécutant 'wget run https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/install.lua' sur CraftOS.")
    table.insert(toRepair, "main.lua")
    sleep(0.1)
    term.setTextColor(colors.white)
end