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
    term.setTextColor(colors.red)
    installGithub(filename)
end

function repair.check(filename)
    if not fs.exists(filename) then 
        term.setTextColor(colors.red)
        print("Erreur : le fichier '" .. filename .. "' est introuvable. Le syst�me peut �tre instable et endommag�.")
        repair.file(filename)
        term.setTextColor(colors.white)
        return false
    else
        term.setTextColor(colors.green)
        print("'" .. filename .. "' pr�sent.")
        term.setTextColor(colors.white)
        return true
    end
end

return repair