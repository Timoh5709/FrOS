local update = {}
local textViewer = require("/FrOS/sys/textViewer")
local httpViewer = require("/FrOS/sys/httpViewer")
local fzip = require("/FrOS/sys/FZIP")

function update.install()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clear()
    print("Télécharge temp/install.lua depuis Github.")
    local downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/install.lua")
    if downloader then
        local input = io.open("temp/install.lua", "w")
        input:write(downloader.readAll())
        input:close()
        print("Téléchargement de temp/install.lua réussi")
        print("Le système d'installation autonome a été installé. Votre ordinateur va redémarrer.")
        os.reboot()
        return true
    else
        textViewer.eout("Erreur lors du téléchargement du fichier : temp/install.lua depuis Github le système va redémarrer.")
        os.reboot()
    end
end

local function installGithub(oFilename, filename)
    local url = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/"
    print("Télécharge " .. oFilename .. " depuis Github.")
    local downloader = http.get(url .. oFilename)
    if downloader then
        local input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
        textViewer.cprint("Téléchargement de ".. oFilename .. " réussi", colors.green)
        return true
    else
        textViewer.eout("Erreur lors du téléchargement du fichier : " .. oFilename)
    end
end

function update.createInstallationDisk()
    local disks = { peripheral.find("drive") }
    local emptyDisksLoc = {}
    for _, disk in pairs(disks) do
        if disk.isDiskPresent() then
            table.insert(emptyDisksLoc, disk.getMountPath())
        end
    end
    if #emptyDisksLoc == 0 then
        textViewer.eout("Erreur : Aucun disque n'a été détecté.")
    elseif #emptyDisksLoc > 1 then
        textViewer.eout("Erreur : Trop de disques sont insérés.")
    else
        fs.makeDir("temp/install")
        print("Dossier temp/install créé avec succès.")
        fs.makeDir("temp/install/FrOS")
        print("Dossier temp/install/FrOS créé avec succès.")
        installGithub("FrOS/main.lua", "temp/install/FrOS/main.lua")
        installGithub("FrOS/version.txt", "temp/install/FrOS/version.txt")
        fs.makeDir("temp/install/FrOS/media")
        print("Dossier temp/install/FrOS/media créé avec succès.")
        installGithub("FrOS/media/startup.dfpwm", "temp/install/FrOS/media/startup.dfpwm")
        installGithub("FrOS/media/shutdown.dfpwm", "temp/install/FrOS/media/shutdown.dfpwm")
        installGithub("FrOS/media/error.dfpwm", "temp/install/FrOS/media/error.dfpwm")
        installGithub("FrOS/media/ask.dfpwm", "temp/install/FrOS/media/ask.dfpwm")
        fs.makeDir("temp/install/FrOS/sys")
        print("Dossier temp/install/FrOS/sys créé avec succès.")
        installGithub("FrOS/sys/textViewer.lua", "temp/install/FrOS/sys/textViewer.lua")
        installGithub("FrOS/sys/update.lua", "temp/install/FrOS/sys/update.lua")
        installGithub("FrOS/sys/repair.lua", "temp/install/FrOS/sys/repair.lua")
        installGithub("FrOS/sys/statusBar.lua", "temp/install/FrOS/sys/statusBar.lua")
        installGithub("FrOS/sys/httpViewer.lua", "temp/install/FrOS/sys/httpViewer.lua")
        installGithub("FrOS/sys/dfpwmPlayer.lua", "temp/install/FrOS/sys/dfpwmPlayer.lua")
        installGithub("FrOS/sys/progressBar.lua", "temp/install/FrOS/sys/progressBar.lua")
        installGithub("FrOS/sys/utf8.lua", "temp/install/FrOS/sys/utf8.lua")
        installGithub("FrOS/sys/loc.lua", "temp/install/FrOS/sys/loc.lua")
        installGithub("FrOS/sys/FZIP.lua", "temp/install/FrOS/sys/FZIP.lua")
        installGithub("FrOS/sys/script.lua", "temp/install/FrOS/sys/script.lua")
        installGithub("FrOS/sys/offline-installer.lua", "temp/install/FrOS/sys/offline-installer.lua")
        fs.makeDir("temp/install/FrOS/localization")
        print("Dossier temp/install/FrOS/localization créé avec succès.")
        installGithub("FrOS/localization/main.loc", "temp/install/FrOS/localization/main.loc")
        fs.makeDir("temp/install/FrOS/drivers")
        print("Dossier temp/install/FrOS/drivers créé avec succès.")
        installGithub("FrOS/drivers/init.lua", "temp/install/FrOS/drivers/init.lua")
        fs.makeDir("temp/install/apps")
        print("Dossier temp/install/apps créé avec succès.")
        installGithub("apps/appStore.lua", "temp/install/apps/appStore.lua")
        installGithub("apps/manuel.lua", "temp/install/apps/manuel.lua")
        fs.makeDir("temp/install/temp")
        print("Dossier temp/install/temp créé avec succès.")
        installGithub("FrOS/boot.lua", "temp/install/FrOS/boot.lua")
        installGithub("startup.lua", "temp/install/startup.lua")
        fzip.create("disk/fros-offline.fzip", { "temp/install" })
        fs.copy("FrOS/sys/offline-installer.lua", "disk/startup.lua")
        textViewer.cprint("Disque d'installation hors-ligne créé avec succès.", colors.green)
    end
end

function update.check()
    if http.checkURL("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/version.txt") == true then
        local ver = textViewer.getVer()
        local oVer = httpViewer.httpBrain("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/version.txt")
        if oVer == false then
            oVer = "4.0.4"
        end
        return ver ~= oVer, oVer
    end
    return false, 1
end

function update.appCheck(ver)
    if tonumber(textViewer.getVer()) < ver then
        textViewer.eout("Erreur : Veuillez mettre à jour FrOS avec 'maj'.")
        return false
    else
        return true
    end
end

return update