local textViewer = require("/sys/textViewer")
local httpViewer = require("/sys/httpViewer")
local statusBar = require("/sys/statusBar")
local appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/appList.txt"
local running = true
term.clear()

function playErrorSound()
  if speaker ~= nil then
    speaker.playNote("bit")
  end
end

function playConfirmationSound()
  if speaker ~= nil then
    speaker.playNote("chime")
  end
end

local function installGithub(filename)
    print("Telecharge " .. filename .. " depuis Github.")
    downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/" .. filename)
    if downloader then
        input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
        print("Telechargement de ".. filename .. " reussi")
        return true
    else
        print("Erreur lors du telechargement du fichier : " .. filename)
    end
end

local function refresh()
    local lignes = httpViewer.getLines(appListUrl)
    textViewer.lineViewer(lignes)
end

local function readAllText(path)
    local lignes = {}
    local file = fs.combine(shell.dir(), path)
    local handle = fs.open(file, "r")
    if not handle then
        print("Erreur : Fichier illisible.")
        playErrorSound()
        return
    end
    while true do
       local ligne = handle.readLine()
       if not ligne then break end
       lignes[#lignes+1] = ligne
    end
    handle.close()
    textViewer.lineViewer(lignes)
end

local function checkAndInstallApp(app)
    local texte = httpViewer.httpBrain(appListUrl)
    if string.find(texte, app) then
        local f = fs.open("/appList.txt", "r")
        local ftexte = f.readAll()
        f.close()
        installGithub("apps/" .. app)
        if string.find(ftexte, app) then
            print(app .. " a bien ete mis a jour.")
        else
            f = fs.open("/appList.txt", "a")
            f.write(app .. "\n")
            f.close()
            print(app .. " a bien ete installe.")
        end
    else
        print("Erreur : Application introuvable en ligne.")
    end
end

local function main()
    dossier = "appStore.lua"
    write(dossier .. "$ ")
    statusBar.draw(dossier)
    local input = read()

    local args = {}
    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end

    local command = args[1]
    local param = args[2]

    if command == "quit" then
        print("Fermeture de appStore.lua...")
        running = false
        return
    elseif command == "aide" then
        aides = {
            "Commandes disponibles :",
            "aide - Affiche cet aide",
            "quit - Quitte l'application",
            "liste OU list <nv OU pr> - Liste les applications disponibles OU installee"
            "installer OU get <app> - Installe la derniere version d'une application"
        }
        textViewer.lineViewer(aides)
    elseif command == "liste" or command == "list" then
        if param == "nv"
            refresh()
        elseif param == "pr"
            readAllText("/appList.txt")
        end
    elseif command == "installer" or command == "get" then

    elseif command ~= nil then
        print("Commande inconnue : " .. command)
        playErrorSound()
    else
        print("Veuillez rentrer une commande.")
        playErrorSound()
    end
end

while running do
    main()
end