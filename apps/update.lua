local update = {}

function update.install()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clear()
    print("Telecharge temp/install.lua depuis Pastebin.")
    downloader = http.get("https://pastebin.com/raw/Nur35FnH")
    if downloader then
        input = io.open("temp/install.lua", "w")
        input:write(downloader.readAll())
        input:close()
        print("Telechargement de temp/install.lua depuis https://pastebin.com/raw/Nur35FnH reussi")
        print("Le systeme d'installation autonome a ete installe. Votre ordinateur va redemarrer.")
        sleep(5)
        input2 = io.open("startup.lua", "w")
        input2:write("shell.run('temp/install.lua')")
        input2:close()
        os.reboot()
        return true
    else
        print("Erreur lors du telechargement du fichier : temp/install.lua depuis https://pastebin.com/raw/Nur35FnH le système va redemarrer.")
        sleep(5)
        os.reboot()
    end
end

return update