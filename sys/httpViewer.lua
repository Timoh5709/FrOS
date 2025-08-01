local httpViewer = {}

local function httpBrain(url)
    local request = http.get(url)
    if request == nil then
        term.setTextColor(colors.red)
        print("Erreur 404")
        sleep(0.1)
        term.setTextColor(colors.white)
    else
        return request.readAll()
    end
end

function httpViewer.readUrl(url)
    print(httpBrain(url))
end

function httpViewer.getLines(url)
    local text = httpBrain(url)
    local lignes = {}
    for ligne in text:gmatch("([^\n]*)\n?") do
        table.insert(lignes, ligne)
    end
    return lignes
end

return httpViewer