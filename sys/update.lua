local update = {}

function update.install()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clear()
    print("Telecharge temp/install.lua depuis Github.")
    downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/install.lua")
    if downloader then
        input = io.open("temp/install.lua", "w")
        input:write(downloader.readAll())
        input:close()
        print("Telechargement de temp/install.lua reussi")
        print("Le systeme d'installation autonome a ete installe. Votre ordinateur va redemarrer.")
        sleep(5)
        input2 = io.open("startup.lua", "w")
        input2:write("shell.run('temp/install.lua')")
        input2:close()
        os.reboot()
        return true
    else
        print("Erreur lors du telechargement du fichier : temp/install.lua depuis Github le systeme va redemarrer.")
        sleep(5)
        os.reboot()
    end
end

return update