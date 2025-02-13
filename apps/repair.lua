local repair = {}

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

function repair.file(filename)
    term.setBackgroundColor(colors.red)
    term.clear()
    installGithub(filename)
end

return repair