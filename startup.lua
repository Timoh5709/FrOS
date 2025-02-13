term.clear()
term.setCursorPos(1,1)

local speaker = peripheral.find("speaker")
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local toRepair = {}
local repair

print("Bienvenue sur FrOS")
print("Tapez 'aide' pour voir les commandes disponibles.")

if fs.exists("main.lua") then
    term.setTextColor(colors.green)
    print("'main.lua' present.")
    sleep(0.1)
    term.setTextColor(colors.white)
    if not fs.exists("apps/textViewer.lua") then 
        term.setTextColor(colors.red)
        print("Erreur : le fichier 'apps/textViewer.lua' est introuvable. Le systeme peut etre instable et endommage.")
        table.insert(toRepair, "apps/textViewer.lua")
        sleep(0.1)
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.green)
        print("'apps/textViewer.lua' present.")
        sleep(0.1)
        term.setTextColor(colors.white)
    end
    if not fs.exists("apps/update.lua") then 
        term.setTextColor(colors.red)
        print("Erreur : le fichier 'apps/update.lua' est introuvable. Le systeme peut etre instable et endommage.")
        table.insert(toRepair, "apps/update.lua")
        sleep(0.1)
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.green)
        print("'apps/update.lua' present.")
        sleep(0.1)
        term.setTextColor(colors.white)
    end
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
            print("Erreur : le fichier 'media/startup.dfpwm' est introuvable. Le systeme peut être endommage.")
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
        print("Le systeme d'installation autonome a ete desinstalle.")
        sleep(0.1)
        term.setTextColor(colors.white)
    end
    if not fs.exists("apps/repair.lua") then 
        term.setTextColor(colors.red)
        print("Erreur : le fichier 'apps/repair.lua' est introuvable. Le systeme peut etre instable et endommage.")
        sleep(0.1)
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.green)
        print("'apps/repair.lua' present.")
        sleep(0.1)
        term.setTextColor(colors.white)
        repair = require("apps/repair")
        if #toRepair > 0 then
            print("Il y a un ou plusieurs fichiers manquants, voulez-vous les reparer ? (oui/non)")
            write("? ")
            local confirmation = read()
            if confirmation == "oui" then
                for i = 1, #toRepair do
                    repair.file(toRepair[i])
                end
                term.setBackgroundColor(colors.black)
                term.clear()
            else
              print("Reparation annulee. Le systeme peut etre instable.")
            end
        end
    end
    textutils.slowPrint("-------------------------------------------------")
    shell.run("main.lua")
else
    term.setTextColor(colors.red)
    print("Erreur : le fichier 'main.lua' est introuvable. Veuillez reinstaller le systeme en executant 'pastebin run Nur35FnH' sur CraftOS.")
    table.insert(toRepair, "main.lua")
    sleep(0.1)
    term.setTextColor(colors.white)
end