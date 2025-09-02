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

local function getVer()
    local file = "FrOS/version.txt"
    local handle = fs.open(file, "r")
    if not handle then
        print("Erreur : Fichier 'FrOS/version.txt' illisible.")
        return
    end
    local ver = handle.readAll()
    handle.close()
    return ver
end

term.setBackgroundColor(colors.blue)
term.clear()
term.setCursorPos(1,1)

fs.makeDir("FrOS")
print("Dossier FrOS cr�� avec succ�s.")
installGithub("FrOS/main.lua")
installGithub("FrOS/version.txt")
fs.makeDir("FrOS/media")
print("Dossier FrOS/media cr�� avec succ�s.")
installGithub("FrOS/media/startup.dfpwm")
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
installGithub("apps/manuel.lua")
if not maj then
    local f = fs.open("FrOS/appList.txt", "w")
    if f then
        f.write("appStore.lua\nmanuel.lua\n")
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
print("Installation de FrOS version " .. getVer() .. " termin�e. Votre ordinateur va red�marrer.")
os.reboot()