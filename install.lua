term.clear()
term.setCursorPos(1,1)

local maj = false
local exBootloader = false
local step = 0

updateList = {
    "u071",
    "u072"
}

print("Ce programme va bien t�l�charger et installer les fichiers pour FrOS.")
print("Veuillez ne pas �teindre votre ordinateur lors du t�l�chargement.")
if fs.exists("/FrOS/boot.lua") then
    while step == 0 do
        print("Voulez-vous mettre � jour ou installer � nouveau ? (maj/install)")
        write("? ")
        local choix = read()
        if choix == "maj" then
            step = step + 3
            maj = true
            exBootloader = false
        elseif choix == "install" then
            step = step + 1
            maj = false
        end
    end
else
    step = step + 1
end
while step == 1 do
    print("Utilisez-vous un bootloader ? (oui/non)")
    write("? ")
    choix = read()
    if choix == "oui" then
        step = step + 1
        exBootloader = true
    elseif choix == "non" then
        step = step + 1
        exBootloader = false
    end
end
textutils.slowPrint("-------------------------------------------------")

local function installGithub(filename)
    print("T�l�charge " .. filename .. " depuis Github.")
    local downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/" .. filename)
    if downloader then
        local input = io.open(filename, "w")
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
installGithub("FrOS/media/shutdown.dfpwm")
installGithub("FrOS/media/error.dfpwm")
installGithub("FrOS/media/ask.dfpwm")
fs.makeDir("FrOS/sys")
print("Dossier FrOS/sys cr�� avec succ�s.")
installGithub("FrOS/sys/textViewer.lua")
installGithub("FrOS/sys/update.lua")
installGithub("FrOS/sys/repair.lua")
installGithub("FrOS/sys/statusBar.lua")
installGithub("FrOS/sys/httpViewer.lua")
installGithub("FrOS/sys/dfpwmPlayer.lua")
installGithub("FrOS/sys/progressBar.lua")
installGithub("FrOS/sys/utf8.lua")
installGithub("FrOS/sys/loc.lua")
installGithub("FrOS/sys/FZIP.lua")
installGithub("FrOS/sys/script.lua")
installGithub("FrOS/sys/gfrx.lua")
installGithub("FrOS/sys/offline-installer.lua")
fs.makeDir("FrOS/localization")
print("Dossier FrOS/localization cr�� avec succ�s.")
installGithub("FrOS/localization/main.loc")
installGithub("FrOS/localization/error.loc")
installGithub("FrOS/localization/sys.loc")
installGithub("FrOS/localization/update.loc")
fs.makeDir("FrOS/drivers")
print("Dossier FrOS/drivers cr�� avec succ�s.")
installGithub("FrOS/drivers/init.lua")
fs.makeDir("apps")
print("Dossier apps cr�� avec succ�s.")
installGithub("apps/appStore.lua")
installGithub("apps/manuel.lua")
local f = fs.open("FrOS/updateList.txt", "w")
if f then
    for k, v in pairs(updateList) do
        f.writeLine(v)
    end
    f.close()
    print("Fichier FrOS/updateList.txt cr�� avec succ�s.")
else
    print("Erreur : Impossible de cr�er le fichier FrOS/updateList.txt.")
end
if not maj then
    local f = fs.open("FrOS/appList.txt", "w")
    if f then
        f.write("apps/appStore.lua\napps/manuel.lua\n")
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
    if not exBootloader then
        local f = fs.open("boot.txt", "w")
        if f then
            f.write("CraftOS|rom/startup.lua\nFrOS|FrOS/boot.lua\n")
            f.close()
            print("Fichier boot.txt cr�� avec succ�s.")
        else
            print("Erreur : Impossible de cr�er le fichier boot.txt.")
        end
    end
    print("Voulez-vous installer des drivers ? (oui/non)")
    write("? ")
    local choix = read()
    if choix == "oui" then
        print("Pour regarder la liste des drivers, faites 'liste ndrivers' et installez les avec 'driver <nom du driver>'.")
        shell.run("/apps/appStore.lua -install")
    end
end
fs.makeDir("temp")
print("Dossier temp cr�� avec succ�s.")
installGithub("FrOS/boot.lua")
if not exBootloader then
    installGithub("startup.lua")
end
print("Installation de FrOS version " .. getVer() .. " termin�e. Votre ordinateur va red�marrer.")
os.reboot()