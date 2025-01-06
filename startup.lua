term.clear()
term.setCursorPos(1,1)

local speaker = peripheral.find("speaker")
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

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
    textutils.slowPrint("-------------------------------------------------")
    shell.run("main.lua")
else
    term.setTextColor(colors.red)
    print("Erreur : le fichier 'main.lua' est introuvable. Veuillez reinstaller le systeme en executant 'pastebin run Nur35FnH' sur CraftOS.")
    sleep(0.1)
    term.setTextColor(colors.white)
end