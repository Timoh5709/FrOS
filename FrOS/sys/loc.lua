local loc = {}
local textViewer = require("/FrOS/sys/textViewer")
local utf8 = require("/FrOS/sys/utf8")

-- /main.erreurFichier:FR Erreur...
-- bla bla
-- /main.erreurFichier:EN Error...
-- bla bla
function loc.decode(path, language)
    if not fs.exists(path) then
        textViewer.eout("Error : The localization file doesn't exist.")
        return {}
    end

    local f = fs.open(path, "r")
    local trad = {}

    for line in f.readLine do
        local key, lang, value = line:match("/([^:]+):(%u%u)%s(.*)$")
        if key and lang and value then
            if lang == language then
                trad[key] = value
            end
        end
    end

    f.close()
    return trad
end

function loc.load(path, language)
    local locUtf8 = loc.decode(path, language)
    local locs = {}
    
    for key, txt in pairs(locUtf8) do
        locs[key] = utf8.tocp1252(txt)
    end
    return locs
end

return loc