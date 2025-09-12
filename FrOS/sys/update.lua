local update = {}
local textViewer = require("/FrOS/sys/textViewer")
local httpViewer = require("/FrOS/sys/httpViewer")

function update.install()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clear()
    print("Télécharge temp/install.lua depuis Github.")
    downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/install.lua")
    if downloader then
        input = io.open("temp/install.lua", "w")
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

function update.check()
  local ver = textViewer.getVer()
  local oVer = httpViewer.httpBrain("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/version.txt")
  return ver ~= oVer, oVer
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