local update = require("/FrOS/sys/update")
local running = update.appCheck(0.6)
if not running then
    return
end
local fzip = require("/FrOS/sys/FZIP")
local textViewer = require("/FrOS/sys/textViewer")

function string:endswith(suffix)
    return self:sub(-#suffix) == suffix
end

local args = {...}
if #args < 3 then
    print("Utilisation : -c OU -d input output")
    return
end

local mode, inPath, outPath = args[1], args[2], args[3]
inPath, outPath = fs.combine(shell.dir(), inPath), fs.combine(shell.dir(), outPath)
if mode == "-c" then
    if not outPath:endswith(".fzip") then
        textViewer.eout("Erreur : Extension invalide.")
    end
    print("Compresse " .. inPath .. " -> " .. outPath)
    fzip.create(outPath, inPath)
elseif mode == "-d" then
    if not inPath:endswith(".fzip") then
        textViewer.eout("Erreur : Extension invalide.")
    end
    print("Décompresse " .. inPath .. " -> " .. outPath)
    fzip.extract(inPath, outPath)
else
    textViewer.eout("Erreur : Mode inconnu " .. mode)
end