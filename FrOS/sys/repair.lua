local repair = {}

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

function repair.file(filename)
    term.setBackgroundColor(colors.red)
    term.clear()
    installGithub(filename)
    sleep(1)
end

return repair