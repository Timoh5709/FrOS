-- @fullscreen
local textViewer = require("/FrOS/sys/textViewer")
local update = require("/FrOS/sys/update")
local running = update.appCheck(0.81)
local httpViewer = require("/FrOS/sys/httpViewer")
if not fs.exists("FrOS/localization/manuel.loc") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/manuel.loc")
end
local locLua = require("/FrOS/sys/loc")
local stg = _G.FrOS.stg
local language = "FR"
language = stg["language"]
local loc = locLua.load("FrOS/localization/manuel.loc", language)
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end
local manuelsLoc = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/apps/manuels/"

local function lire(nom)
    if not nom then
        textViewer.eout(loc["error.unspecifiedURL"])
        return
    end

    textViewer.lineViewer(httpViewer.getLines(manuelsLoc .. nom .. ".txt"))
end

local function main()
    local dossier = "manuel.lua"
    FrOS.statusBar.updateDossier(dossier)
    write(dossier .. "? ")
    local input = read()

    local args = {}
    for word in string.gmatch(input, "%S+") do
      table.insert(args, word)
    end

    local command = args[1]
    local param = args[2]

    if command == "quit" then
        print(loc["main.quit"])
        running = false
        return
    elseif command == "aide" then
        local aides = {
            loc["main.aideCommand"],
            loc["main.aideAide"],
            loc["main.aideQuit"],
            loc["main.aideLire"]
        }
        textViewer.lineViewer(aides)
    elseif command == "lire" then
        lire(param)
    elseif command ~= nil then
        textViewer.eout(loc["main.unknownCommand"] .. command)
    else
        textViewer.eout(loc["main.noCommand"])
    end
end

while running do
    main()
end