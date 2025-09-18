local textViewer = require("/FrOS/sys/textViewer")
local update = require("/FrOS/sys/update")
local running = update.appCheck(0.51)
local httpViewer = require("/FrOS/sys/httpViewer")
local statusBar = require("/FrOS/sys/statusBar")
local dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
local appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/appList.txt"
local appsUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/"
local isFrOSList = true
local driversListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/driversList.txt"
local driversUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/"

local function setList(url)
    if url ~= nil then
        if httpViewer.httpBrain(url) ~= false then
            local f = fs.open("apps/appListUrl.txt", "w")
            if f then
                f.write(url)
                f.close()
                appListUrl = url
                appsUrl = string.sub(appListUrl, 1, #appListUrl - 11)
                isFrOSList = false
                textViewer.cprint(url .. "a bien été défini comme liste par défaut.")
            else
                print("Erreur : Impossible de créer le fichier 'boot.txt'.")
            end
        else
            textViewer.eout("Erreur : Le lien " .. url .. " est incorrect.")
        end
    else
        textViewer.eout("Erreur : Aucun lien Github spécifié")
    end
end

local function resetList()
    if fs.exists("apps/appListUrl.txt") then
        fs.delete("apps/appListUrl.txt")
        appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/appList.txt"
        appsUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/"
        isFrOSList = true
        textViewer.cprint("Liste officielle de FrOS sélectionnée par défaut")
    else
        textViewer.eout("Erreur : Liste déjà par défaut.")
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
        if isFrOSList then
            app = "apps/" .. app
        end
        if not httpViewer.installGithub(appsUrl, app) then
            if not httpViewer.installGithub(appsUrl, app .. ".lua") then
                textViewer.eout("Erreur : L'application " .. appfilename .. " ne peut pas être installée.")
            else
                appfilename = app .. ".lua"
                isInstalled = true
            end
        else
            isInstalled = true
        end
        if isInstalled then
            if string.find(ftexte, appfilename) then
                textViewer.cprint(appfilename .. " a bien été mis à jour.", colors.green)
            else
                f = fs.open("/FrOS/appList.txt", "a")
                f.write(appfilename .. "\n")
                f.close()
                textViewer.cprint(appfilename .. " a bien été installé.", colors.green)
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
        if not httpViewer.installGithub(driversUrl, "FrOS/drivers/" .. driver) then
            if not httpViewer.installGithub(driversUrl, "FrOS/drivers/" .. driver .. ".lua") then
                textViewer.eout("Erreur : Le driver " .. driverfilename .. " ne peut pas être installé.")
            else
                driverfilename = driver .. ".lua"
            end
        end
        if string.find(ftexte, driverfilename) then
            textViewer.cprint(driverfilename .. " a bien été mis à jour.", colors.green)
        else
            f = fs.open("/FrOS/driversList.txt", "a")
            f.write(driverfilename .. "\n")
            f.close()
            textViewer.cprint(driverfilename .. " a bien été installé.", colors.green)
        end
    else
        textViewer.eout("Erreur : Driver introuvable en ligne.")
    end
end

local function main()
    local dossier = "appStore.lua"
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
        local aides = {
            "Commandes disponibles :",
            "aide - Affiche cet aide",
            "quit - Quitte l'application",
            "liste OU list <napps OU apps OU ndrivers OU drivers> - Liste les applications disponibles OU installée OU les drivers disponibles OU les drivers installés",
            "set <url du fichier raw de 'appList.txt' sur Github> - Définit la liste 'napps' sur une nouvelle url, les applications devront être dans le même dossier du repo Github",
            "reset - Réinitialise la liste",
            "installer OU get <app> - Installe la dernière version d'une application",
            "driver <driver> - Installe la dernière version d'un driver"
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
            textViewer.eout("Erreur : Aucune liste selectionnée.")
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
    else
        textViewer.eout("Veuillez rentrer une commande.")
    end
end

if fs.exists("apps/appListUrl.txt") then
    local f = fs.open("apps/appListUrl.txt", "r")
    appListUrl = f.readAll()
    appsUrl = string.sub(appListUrl, 1, #appListUrl - 11)
    isFrOSList = false
end

while running do
    main()
end