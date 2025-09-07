local httpViewer = {}
local textViewer = require("/FrOS/sys/textViewer")

function httpViewer.installGithub(url, filename)
    print("Télécharge " .. filename .. " depuis Github.")
    downloader = http.get(url .. filename)
    if downloader then
        input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
        textViewer.cprint("Téléchargement de ".. filename .. " réussi", colors.green)
        return true
    else
        textViewer.eout("Erreur lors du téléchargement du fichier : " .. filename)
    end
end

function httpViewer.httpBrain(url)
    local request = http.get(url)
    if request == nil then
        term.setTextColor(colors.red)
        textViewer.eout("Erreur 404")
        term.setTextColor(colors.white)
        return false
    else
        return request.readAll()
    end
end

function httpViewer.readUrl(url)
    print(httpViewer.httpBrain(url))
end

function httpViewer.getLines(url)
    local text = httpViewer.httpBrain(url)
    local lignes = {}
    for ligne in string.gmatch(text, "([^\n]*)\n?") do
        table.insert(lignes, ligne)
    end
    return lignes
end

return httpViewer