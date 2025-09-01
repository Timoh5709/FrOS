term.clear()
term.setCursorPos(1,1)

local speaker = peripheral.find("speaker")
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

local maj = false

print("Ce programme va bien t�l�charger et installer les fichiers pour FrOS.")
print("Veuillez ne pas �teindre votre ordinateur lors du t�l�chargement.")
if fs.exists("/FrOS/boot.lua") then
    print("Voulez-vous mettre � jour ou installer � nouveau ? (maj/install)")
    write("? ")
    local choix = read()
    if choix == "maj" then
        maj = true
    end
end
textutils.slowPrint("-------------------------------------------------")

local function installGithub(filename)
    print("T�l�charge " .. filename .. " depuis Github.")
    downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/" .. filename)
    if downloader then
        input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
		print("T�l�chargement de ".. filename .. " r�ussi")
        return true
    else
        print("Erreur lors du t�l�chargement du fichier : " .. filename)
    end
end

term.setBackgroundColor(colors.blue)
term.clear()
term.setCursorPos(1,1)

fs.makeDir("FrOS")
print("Dossier FrOS cr�� avec succ�s.")
fs.makeDir("FrOS/media")
print("Dossier FrOS/media cr�� avec succ�s.")
installGithub("FrOS/media/startup.dfpwm")
if speaker ~= nil then
    for chunk in io.lines("FrOS/media/startup.dfpwm", 16 * 1024) do
        local buffer = decoder(chunk)
    
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end 
end
installGithub("FrOS/main.lua")
fs.makeDir("FrOS/sys")
print("Dossier FrOS/sys cr�� avec succ�s.")
installGithub("FrOS/sys/textViewer.lua")
installGithub("FrOS/sys/update.lua")
installGithub("FrOS/sys/repair.lua")
installGithub("FrOS/sys/statusBar.lua")
installGithub("FrOS/sys/httpViewer.lua")
installGithub("FrOS/sys/dfpwmPlayer.lua")
fs.makeDir("FrOS/drivers")
print("Dossier FrOS/drivers cr�� avec succ�s.")
installGithub("FrOS/drivers/init.lua")
fs.makeDir("apps")
print("Dossier apps cr�� avec succ�s.")
installGithub("apps/appStore.lua")
if not maj then
    local f = fs.open("FrOS/appList.txt", "w")
    if f then
        f.write("appStore.lua\n")
        f.close()
        print("Fichier FrOS/appList.txt cr�� avec succ�s.")
    else
        print("Erreur : Impossible de cr�er le fichier FrOS/appList.txt.")
    end
    local f = fs.open("FrOS/driversList.txt", "w")
    if f then
        f.close()
        print("Fichier FrOS/driversList.txt cr�� avec succ�s.")
    else
        print("Erreur : Impossible de cr�er le fichier FrOS/driversList.txt.")
    end
    print("Voulez-vous installer des drivers ? (oui/non)")
    write("? ")
    local choix = read()
    if choix == "oui" then
        shell.run("/apps/appStore.lua")
    end
end
fs.makeDir("temp")
print("Dossier temp cr�� avec succ�s.")
installGithub("FrOS/boot.lua")
installGithub("startup.lua")
print("Installation de FrOS version OS_HDD_3 termin�e. Votre ordinateur va red�marrer.")
os.reboot()