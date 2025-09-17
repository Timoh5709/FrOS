local textViewer = require("/FrOS/sys/textViewer")
local update = require("/FrOS/sys/update")
local running = update.appCheck(0.43)
local statusBar = require("/FrOS/sys/statusBar")
local httpViewer = require("/FrOS/sys/httpViewer")
local dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
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
        print("Fermeture de manuel.lua...")
        running = false
        return
    elseif command == "aide" then
        local aides = {
            "Commandes disponibles :",
            "aide - Affiche cet aide",
            "quit - Quitte l'application",
            "lire <nom d'un fichier lua> - Affiche la documentation en ligne d'un programme ou d'une librairie"
        }
        textViewer.lineViewer(aides)
    elseif command == "lire" then
        lire(param)
    elseif command ~= nil then
        textViewer.eout("Commande inconnue : " .. command)
        dfpwmPlayer.playErrorSound()
    else
        textViewer.eout("Veuillez rentrer une commande.")
        dfpwmPlayer.playErrorSound()
    end
end

while running do
    main()
end