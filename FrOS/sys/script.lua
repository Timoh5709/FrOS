local script = {}
local textViewer = require("/FrOS/sys/textViewer")

function script.read(path)
    if not path or not fs.exists(path) then
        textViewer.eout("Erreur : Le fichier script fsc n'existe pas.")
        return nil
    end

    local file = fs.open(path, "r")
    local lines = {}

    while true do
        local line = file.readLine()
        if not line then break end
        table.insert(lines, line)
    end

    file.close()
    return lines
end

return script