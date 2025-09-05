local update = {}
local textViewer = require("/FrOS/sys/textViewer")

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

return update