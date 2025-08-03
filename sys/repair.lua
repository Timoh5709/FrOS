local repair = {}

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

function repair.file(filename)
    term.setBackgroundColor(colors.red)
    term.clear()
    installGithub(filename)
    sleep(1)
end

return repair