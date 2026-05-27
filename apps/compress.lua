local update = require("/FrOS/sys/update")
local running = update.appCheck(0.73)
if not running then
    return
end
local httpViewer = require("/FrOS/sys/httpViewer")
if not fs.exists("FrOS/localization/compress.loc") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/compress.loc")
end
local locLua = require("/FrOS/sys/loc")
local stg = _G.FrOS.stg
local language = "FR"
language = stg["language"]
local loc = locLua.load("FrOS/localization/compress.loc", language)
local fzip = require("/FrOS/sys/FZIP")
local textViewer = require("/FrOS/sys/textViewer")

function string:endswith(suffix)
    return self:sub(-#suffix) == suffix
end

local args = {...}
if #args < 3 then
    print(loc["main.howToUse"])
    return
end

local mode, inPath, outPath = args[1], args[2], args[3]
inPath, outPath = fs.combine(shell.dir(), inPath), fs.combine(shell.dir(), outPath)
if mode == "-c" then
    if not outPath:endswith(".fzip") then
        textViewer.eout(loc["error.invalidExtension"])
    end
    print(loc["main.packing"] .. inPath .. " -> " .. outPath)
    fzip.create(outPath, { inPath })
elseif mode == "-d" then
    if not inPath:endswith(".fzip") then
        textViewer.eout(loc["error.invalidExtension"])
    end
    print(loc["main.unpacking"] .. inPath .. " -> " .. outPath)
    fzip.extract(inPath, outPath)
else
    textViewer.eout(loc["error.unknownMode"] .. mode)
end