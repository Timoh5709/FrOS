local httpViewer = {}
local textViewer = require("/FrOS/sys/textViewer")

local loc = FrOS.sysLoc
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end

function httpViewer.installGithub(url, filename)
    print(loc[".installGithub.download1"] .. filename .. loc[".installGithub.download2"])
    local downloader = http.get(url .. filename)
    if downloader then
        local input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
        textViewer.cprint(loc[".installGithub.success1"] .. filename .. loc[".installGithub.success2"], colors.green)
        return true
    else
        textViewer.eout(loc[".installGithub.error"] .. filename)
    end
end

function httpViewer.httpBrain(url)
    local request = http.get(url)
    if request == nil then
        term.setTextColor(colors.red)
        textViewer.eout(loc["error.error"] .. "404")
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