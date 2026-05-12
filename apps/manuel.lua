local textViewer = require("/FrOS/sys/textViewer")
local update = require("/FrOS/sys/update")
local running = update.appCheck(0.73)
local statusBar = require("/FrOS/sys/statusBar")
local httpViewer = require("/FrOS/sys/httpViewer")
if not fs.exists("FrOS/localization/neofetch.loc") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/manuel.loc")
end
local locLua = require("/FrOS/sys/loc")
local stg = _G.FrOS.stg
local language = "FR"
language = stg["language"]
local loc = locLua.load("FrOS/localization/manuel.loc", language)
local manuelsLoc = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/apps/manuels/"

local function lire(nom)
    if httpViewer.httpBrain(manuelsLoc .. nom .. ".txt") ~= false then
        local lignes = httpViewer.getLines(manuelsLoc .. nom .. ".txt")
        textViewer.lineViewer(lignes)
    end
end

local function main()
    local dossier = "manuel.lua"
    write(dossier .. "? ")
    statusBar.draw(dossier)
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