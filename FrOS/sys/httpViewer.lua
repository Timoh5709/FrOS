local httpViewer = {}
local textViewer = require("/FrOS/sys/textViewer")

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