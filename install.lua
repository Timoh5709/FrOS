term.clear()
term.setCursorPos(1,1)

print("Ce programme va bien telecharger et installer les fichiers pour FrOS.")
print("Veuillez ne pas eteindre votre ordinateur lors du telechargement.")
sleep(1)
textutils.slowPrint("-------------------------------------------------")

local function installGithub(filename)
    print("Telecharge " .. filename .. " depuis Github.")
    downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/" .. filename)
    if downloader then
        input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
		print("Telechargement de ".. filename .. " reussi")
        return true
    else
        print("Erreur lors du telechargement du fichier : " .. filename)
    end
end

term.setBackgroundColor(colors.blue)
term.clear()
term.setCursorPos(1,1)

installGithub("startup.lua")
installGithub("main.lua")
fs.makeDir("sys")
print("Dossier sys cree avec succes.")
installGithub("sys/textViewer.lua")
installGithub("sys/update.lua")
installGithub("sys/repair.lua")
fs.makeDir("media")
print("Dossier media cree avec succes.")
installGithub("media/startup.dfpwm")
fs.makeDir("temp")
print("Dossier temp cree avec succes.")
print("Installation de FrOS version OS_HDD_2 termine. Votre ordinateur va redemarrer.")
sleep(5)
os.reboot()