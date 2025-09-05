local textViewer = require("/FrOS/sys/textViewer")
local running = true
if tonumber(textViewer.getVer()) < 0.3 then
    textViewer.eout("Erreur : Veuillez mettre � jour FrOS avec 'maj'.")
    running = false
    return
end
local httpViewer = require("/FrOS/sys/httpViewer")
local statusBar = require("/FrOS/sys/statusBar")
local dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
local appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/appList.txt"
local driversListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/driversList.txt"

local function installGithub(filename)
    print("T�l�charge " .. filename .. " depuis Github.")
    downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/" .. filename)
    if downloader then
        input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
        textViewer.cprint("T�l�chargement de ".. filename .. " r�ussi", colors.green)
        return true
    else
        textViewer.eout("Erreur lors du t�l�chargement du fichier : " .. filename)
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
        textViewer.eout("Erreur : Fichier illisible.")
        dfpwmPlayer.playErrorSound()
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
        local f = fs.open("/FrOS/appList.txt", "r")
        local ftexte = f.readAll()
        f.close()
        if not installGithub("apps/" .. app) then
            if not installGithub("apps/" .. app .. ".lua") then
                textViewer.eout("Erreur : L'application " .. app .. " ne peut pas �tre install�e.")
            end
        end
        if string.find(ftexte, app) then
            textViewer.cprint(app .. " a bien �t� mis � jour.", colors.green)
        else
            f = fs.open("/FrOS/appList.txt", "a")
            f.write(app .. "\n")
            f.close()
            textViewer.cprint(app .. " a bien �t� install�.", colors.green)
        end
    else
        textViewer.eout("Erreur : Application introuvable en ligne.")
    end
end

local function checkAndInstallDriver(driver)
    local texte = httpViewer.httpBrain(driversListUrl)
    if string.find(texte, driver) then
        local f = fs.open("/FrOS/driversList.txt", "r")
        local ftexte = f.readAll()
        f.close()
        if not installGithub("FrOS/drivers/" .. driver) then
            if not installGithub("FrOS/drivers/" .. driver .. ".lua") then
                textViewer.eout("Erreur : Le driver " .. driver .. " ne peut pas �tre install�.")
            end
        end
        if string.find(ftexte, driver) then
            textViewer.cprint(driver .. " a bien �t� mis � jour.", colors.green)
        else
            f = fs.open("/FrOS/driversList.txt", "a")
            f.write(driver .. "\n")
            f.close()
            textViewer.cprint(driver .. " a bien �t� install�.", colors.green)
        end
    else
        textViewer.eout("Erreur : Driver introuvable en ligne.")
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
            "liste OU list <napps OU apps OU ndrivers OU drivers> - Liste les applications disponibles OU install�e OU les drivers disponibles OU les drivers install�s",
            "installer OU get <app> - Installe la derni�re version d'une application",
            "driver <driver> - Installe la derni�re version d'un driver"
        }
        textViewer.lineViewer(aides)
    elseif command == "liste" or command == "list" then
        if param == "napps" then
            refreshApp()
        elseif param == "apps" then
            readAllText("/FrOS/appList.txt")
        elseif param == "ndrivers" then
            refreshDrivers()
        elseif param == "drivers" then
            readAllText("/FrOS/driversList.txt")
        else
            textViewer.eout("Erreur : Aucune liste selectionn�e.")
        end
    elseif command == "installer" or command == "get" then
        checkAndInstallApp(param)
    elseif command == "driver" then
        checkAndInstallDriver(param)
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