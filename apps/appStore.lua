-- @fullscreen
local textViewer = require("/FrOS/sys/textViewer")
local update = require("/FrOS/sys/update")
local running = update.appCheck(0.81)
local httpViewer = require("/FrOS/sys/httpViewer")
if not fs.exists("FrOS/localization/appStore.loc") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/appStore.loc")
end
local locLua = require("/FrOS/sys/loc")
local stg = _G.FrOS.stg
local language = "FR"
language = stg["language"]
local loc = locLua.load("FrOS/localization/appStore.loc", language)
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end
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
                textViewer.cprint(url .. loc["setList.success"])
            else
                print(loc["error.createListFile"])
            end
        else
            textViewer.eout(loc["error.invalidURL1"] .. url .. loc["error.invalidURL2"])
        end
    else
        textViewer.eout(loc["error.noURL"])
    end
end

local function resetList()
    if fs.exists("apps/appListUrl.txt") then
        fs.delete("apps/appListUrl.txt")
        appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/appList.txt"
        appsUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/"
        isFrOSList = true
        textViewer.cprint(loc["resetList.success"])
    else
        textViewer.eout(loc["error.alreadySelected"])
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
        textViewer.eout(loc["error.unreadableFile"])
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
                textViewer.eout(loc["error.cantInstallApp"] .. appfilename .. loc["error.cantInstall2"])
            else
                appfilename = app .. ".lua"
                isInstalled = true
            end
        else
            isInstalled = true
        end
        if isInstalled then
            if string.find(ftexte, appfilename) then
                textViewer.cprint(appfilename .. loc["checkAndInstall.successU"], colors.green)
            else
                f = fs.open("/FrOS/appList.txt", "a")
                f.write(appfilename .. "\n")
                f.close()
                textViewer.cprint(appfilename .. loc["checkAndInstall.successI"], colors.green)
            end
        end
    else
        textViewer.eout(loc["error.cantInstallApp"] .. appfilename .. loc["error.unknownWebFile"])
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
                textViewer.eout(loc["error.cantInstallDriver"] .. driverfilename .. loc["error.cantInstall2"])
            else
                driverfilename = driver .. ".lua"
            end
        end
        if string.find(ftexte, driverfilename) then
            textViewer.cprint(driverfilename .. loc["checkAndInstall.successU"], colors.green)
        else
            f = fs.open("/FrOS/driversList.txt", "a")
            f.write(driverfilename .. "\n")
            f.close()
            textViewer.cprint(driverfilename .. loc["checkAndInstall.successI"], colors.green)
        end
    else
        textViewer.eout(loc["error.cantInstallDriver"] .. driverfilename .. loc["error.unknownWebFile"])
    end
end

local function main()
    local dossier = "appStore.lua"
    FrOS.statusBar.updateDossier(dossier)
    write(dossier .. "$ ")

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
            loc["main.aideList"],
            loc["main.aideSet"],
            loc["main.aideReset"],
            loc["main.aideGet"],
            loc["main.aideDriver"]
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
            textViewer.eout(loc["error.noList"])
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
        textViewer.eout(loc["main.unknownCommand"] .. command)
    else
        textViewer.eout(loc["main.noCommand"])
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