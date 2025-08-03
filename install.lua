term.clear()
term.setCursorPos(1,1)

local speaker = peripheral.find("speaker")
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

local maj = false

print("Ce programme va bien télécharger et installer les fichiers pour FrOS.")
print("Veuillez ne pas éteindre votre ordinateur lors du téléchargement.")
if fs.exists("/startup.lua") then
    print("Voulez-vous mettre à jour ou installer à nouveau ? (maj/install)")
    write("? ")
    local choix = read()
    if choix == "maj" then
        maj = true
    end
end
sleep(1)
textutils.slowPrint("-------------------------------------------------")

local function installGithub(filename)
    print("Télécharge " .. filename .. " depuis Github.")
    downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/" .. filename)
    if downloader then
        input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
		print("Téléchargement de ".. filename .. " réussi")
        return true
    else
        print("Erreur lors du téléchargement du fichier : " .. filename)
    end
end

term.setBackgroundColor(colors.blue)
term.clear()
term.setCursorPos(1,1)

fs.makeDir("media")
print("Dossier media créé avec succès.")
installGithub("media/startup.dfpwm")
if speaker ~= nil then
    for chunk in io.lines("media/startup.dfpwm", 16 * 1024) do
        local buffer = decoder(chunk)
    
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end 
end
installGithub("main.lua")
fs.makeDir("sys")
print("Dossier sys créé avec succès.")
installGithub("sys/textViewer.lua")
installGithub("sys/update.lua")
installGithub("sys/repair.lua")
installGithub("sys/statusBar.lua")
installGithub("sys/httpViewer.lua")
fs.makeDir("drivers")
print("Dossier drivers créé avec succès.")
installGithub("drivers/init.lua")
fs.makeDir("apps")
print("Dossier apps créé avec succès.")
installGithub("apps/appStore.lua")
if not maj then
    local f = fs.open("appList.txt", "w")
    if f then
        f.write("appStore.lua\n")
        f.close()
        print("Fichier appList.txt créé avec succès.")
    else
        print("Erreur : Impossible de créer le fichier appList.txt.")
    end
    local f = fs.open("driversList.txt", "w")
    if f then
        f.close()
        print("Fichier driversList.txt créé avec succès.")
    else
        print("Erreur : Impossible de créer le fichier driversList.txt.")
    end
    print("Voulez-vous installer des drivers ? (oui/non)")
    write("? ")
    local choix = read()
    if choix == "oui" then
        shell.run("/apps/appStore.lua")
    end
end
fs.makeDir("temp")
print("Dossier temp créé avec succès.")
installGithub("startup.lua")
print("Installation de FrOS version OS_HDD_2 terminée. Votre ordinateur va redémarrer.")
sleep(5)
os.reboot()