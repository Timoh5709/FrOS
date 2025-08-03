local textViewer = require("/sys/textViewer")
local httpViewer = require("/sys/httpViewer")
local statusBar = require("/sys/statusBar")
local appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/appList.txt"
local driversListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/driversList.txt"
local running = true

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
        return false
    end
end

local function refreshApp()
    local lignes = httpViewer.getLines(appListUrl)
    textViewer.lineViewer(lignes)
end

local function refreshDrivers()
    local lignes = httpViewer.getLines(driversListUrl)
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
        if not installGithub("apps/" .. app) then
            if not installGithub("apps/" .. app .. ".lua") then
                print("Erreur : L'application " .. app .. " ne peut pas etre installee.")
            end
        end
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

local function checkAndInstallDriver(driver)
    local texte = httpViewer.httpBrain(driversListUrl)
    if string.find(texte, driver) then
        local f = fs.open("/driversList.txt", "r")
        local ftexte = f.readAll()
        f.close()
        if not installGithub("drivers/" .. driver) then
            if not installGithub("drivers/" .. driver .. ".lua") then
                print("Erreur : Le driver " .. driver .. " ne peut pas etre installe.")
            end
        end
        if string.find(ftexte, driver) then
            print(driver .. " a bien ete mis a jour.")
        else
            f = fs.open("/driversList.txt", "a")
            f.write(driver .. "\n")
            f.close()
            print(driver .. " a bien ete installe.")
        end
    else
        print("Erreur : Driver introuvable en ligne.")
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
            "liste OU list <napps OU apps OU ndrivers OU drivers> - Liste les applications disponibles OU installee OU les drivers disponibles OU les drivers installes",
            "installer OU get <app> - Installe la derniere version d'une application",
            "driver <driver> - Installe la derniere version d'un driver"
        }
        textViewer.lineViewer(aides)
    elseif command == "liste" or command == "list" then
        if param == "napps" then
            refreshApp()
        elseif param == "apps" then
            readAllText("/appList.txt")
        elseif param == "ndrivers" then
            refreshDrivers()
        elseif param == "drivers" then
            readAllText("/driversList.txt")
        else
            print("Erreur : Aucune liste selectionnee.")
        end
    elseif command == "installer" or command == "get" then
        checkAndInstallApp(param)
    elseif command == "driver" then
        checkAndInstallDriver(param)
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