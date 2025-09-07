local textViewer = require("/FrOS/sys/textViewer")
local running = true
if tonumber(textViewer.getVer()) < 0.4 then
    textViewer.eout("Erreur : Veuillez mettre � jour FrOS avec 'maj'.")
    running = false
    return
end
local httpViewer = require("/FrOS/sys/httpViewer")
local statusBar = require("/FrOS/sys/statusBar")
local dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
local appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/appList.txt"
local appsUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/apps/"
local driversListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/driversList.txt"
local driversUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/drivers/"

local function setList(url)
    if url ~= nil then
        if httpViewer.httpBrain(url) ~= false then
            local f = fs.open("apps/appListUrl.txt", "w")
            if f then
                f.write(url)
                f.close()
                appListUrl = url
                appsUrl = string.sub(appListUrl, 1, #appListUrl - 11)
                textViewer.cprint(url .. "a bien �t� d�fini comme liste par d�faut.")
            else
                print("Erreur : Impossible de cr�er le fichier 'boot.txt'.")
            end
        else
            textViewer.eout("Erreur : Le lien " .. url .. " est incorrect.")
        end
    else
        textViewer.eout("Erreur : Aucun lien Github sp�cifi�")
    end
end

local function resetList()
    if fs.exists("apps/appListUrl.txt") then
        fs.delete("apps/appListUrl.txt")
        appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/appList.txt"
        appsUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/apps/"
        textViewer.cprint("Liste officielle de FrOS s�lectionn�e par d�faut")
    else
        textViewer.eout("Erreur : Liste d�j� par d�faut.")
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
    local appfilename = app
    local isInstalled = false
    if string.find(texte, app) then
        local f = fs.open("/FrOS/appList.txt", "r")
        local ftexte = f.readAll()
        f.close()
        if not httpViewer.installGithub(appsUrl, app) then
            if not httpViewer.installGithub(appsUrl, app .. ".lua") then
                textViewer.eout("Erreur : L'application " .. appfilename .. " ne peut pas �tre install�e.")
            else
                appfilename = app .. ".lua"
                isInstalled = true
            end
        else
            isInstalled = true
        end
        if isInstalled then
            if string.find(ftexte, appfilename) then
                textViewer.cprint(appfilename .. " a bien �t� mis � jour.", colors.green)
            else
                f = fs.open("/FrOS/appList.txt", "a")
                f.write(appfilename .. "\n")
                f.close()
                textViewer.cprint(appfilename .. " a bien �t� install�.", colors.green)
            end
        end
    else
        textViewer.eout("Erreur : L'application " .. appfilename .. " est introuvable en ligne.")
    end
end

local function checkAndInstallDriver(driver)
    local texte = httpViewer.httpBrain(driversListUrl)
    local driverfilename = driver
    if string.find(texte, driver) then
        local f = fs.open("/FrOS/driversList.txt", "r")
        local ftexte = f.readAll()
        f.close()
        if not httpViewer.installGithub(driversUrl, driver) then
            if not httpViewer.installGithub(driversUrl, driver .. ".lua") then
                textViewer.eout("Erreur : Le driver " .. driverfilename .. " ne peut pas �tre install�.")
            else
                driverfilename = driver .. ".lua"
            end
        end
        if string.find(ftexte, driverfilename) then
            textViewer.cprint(driverfilename .. " a bien �t� mis � jour.", colors.green)
        else
            f = fs.open("/FrOS/driversList.txt", "a")
            f.write(driverfilename .. "\n")
            f.close()
            textViewer.cprint(driverfilename .. " a bien �t� install�.", colors.green)
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
            "set <url du fichier raw de 'appList.txt' sur Github> - D�finit la liste 'napps' sur une nouvelle url, les applications devront �tre dans le m�me dossier du repo Github",
            "reset - R�initialise la liste",
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
    elseif command == "set" then
        setList(param)
    elseif command == "reset" then
        resetList()
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

if fs.exists("apps/appListUrl.txt") then
    local f = fs.open("apps/appListUrl.txt", "r")
    appListUrl = f.readAll()
    appsUrl = string.sub(appListUrl, 1, #appListUrl - 11)
end

while running do
    main()
end