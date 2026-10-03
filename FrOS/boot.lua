term.clear()
term.setCursorPos(1,1)

local repair = require("/FrOS/sys/repair")
_G.FrOS = _G.FrOS or {}
OOBE = false
local gfx

local function transformChoixToBool(choix)
    local choixB = "1"
    if choix == "N" then
        choixB = "0"
    end
    return choixB
end

local function table_contains(tbl, x)
    local found = false
    local idx = 1
    for _, v in pairs(tbl) do
        if v == x then 
            found = true 
            break
        end
        idx = idx + 1
    end
    return found, idx
end

if repair.check("FrOS/sys/stg.lua") then
    local stgLua = require("/FrOS/sys/stg")
    _G.FrOS.stg = stgLua.read("FrOS/config.stg")
    if FrOS.stg["oobe"] == "1" then
        OOBE = true
    end
end

if repair.check("FrOS/sys/3dgfrx.lua") then
    local gfrx = require("/FrOS/sys/3dgfrx")
    gfx = gfrx(nil, {buffered = true})
    local _, y = term.getCursorPos()
    y = (y - 1) * 3

    gfx:setPalette(gfx.PALETTES.classic)
    gfx:unmarkAllDirty()
    gfx:drawCircle(21, y + 23, 7, 0x57A64E, true)
    gfx:drawTriangle(1,y + 3, 41,y + 3, 21,y + 23, 0xCC4C4C, true)
    gfx:flush()
    term.setCursorPos(1, y/3+13)
end

local function getVer()
    local file = "FrOS/version.txt"
    local handle = fs.open(file, "r")
    if not handle then
        return "ERROR"
    end
    local ver = handle.readAll()
    handle.close()
    return ver
end

term.setTextColor(colors.white)
print("FrOS " .. getVer())
if OOBE then
    print("You will be redirected to the OOBE")
end
print("Use 'aide' to show available commands.")
print()

if repair.check("FrOS/main.lua") then
    repair.check("FrOS/sys/textViewer.lua")
    repair.check("FrOS/sys/update.lua")
    repair.check("FrOS/sys/offline-installer.lua")
    repair.check("FrOS/sys/statusBar.lua")
    repair.check("FrOS/sys/httpViewer.lua")
    repair.check("FrOS/sys/progressBar.lua")
    repair.check("FrOS/sys/utf8.lua")
    repair.check("FrOS/sys/FZIP.lua")
    repair.check("FrOS/sys/script.lua")
    repair.check("FrOS/sys/taskScheduler.lua")
    repair.check("FrOS/sys/theme.lua")
    repair.check("FrOS/sys/gfrx.lua")
    repair.check("FrOS/localization/main.loc")
    repair.check("FrOS/localization/error.loc")
    repair.check("FrOS/localization/sys.loc")
    repair.check("FrOS/localization/update.loc")
    if repair.check("FrOS/sys/loc.lua") then
        local locLua = require("/FrOS/sys/loc")
        local stg = _G.FrOS.stg
        local language = "FR"
        if stg then
            language = stg["language"]
        end
        _G.FrOS.mainLoc = locLua.load("FrOS/localization/main.loc", language)
        _G.FrOS.errorLoc = locLua.load("FrOS/localization/error.loc", language)
        _G.FrOS.sysLoc = locLua.load("FrOS/localization/sys.loc", language)
        _G.FrOS.updateLoc = locLua.load("FrOS/localization/update.loc", language)
        if FrOS.mainLoc then
            term.setTextColor(colors.green)
            print(FrOS.mainLoc[".locLoaded"])
            term.setTextColor(colors.white)
        else
            term.setTextColor(colors.red)
            print("Error : The localization file for the shell wasn't loaded properly, please contact FrOS' developer team.")
            term.setTextColor(colors.white)
        end
    end
    if repair.check("FrOS/drivers/init.lua") then
        shell.run("FrOS/drivers/init.lua")
    end
    local canPlay = false
    local dfpwmPlayer
    if repair.check("FrOS/sys/dfpwmPlayer.lua") then
        dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
        canPlay = true
    end
    if repair.check("FrOS/media/startup.dfpwm") then
        if canPlay then
            dfpwmPlayer.playStartupSound()
        end
    end
    repair.check("FrOS/media/error.dfpwm")
    repair.check("FrOS/media/ask.dfpwm")
    repair.check("FrOS/media/shutdown.dfpwm")

    fs.delete("temp")
    fs.makeDir("temp")
    textutils.slowPrint("-------------------------------------------------")
    if OOBE then
        local stgLua = require("/FrOS/sys/stg")
        local step = 0
        local colors = {"white", "orange", "magenta", "lightBlue", "yellow", "lime", "pink", "gray", "lightGray", "cyan", "purple", "blue", "brown", "green", "red", "black"}

        while step == 0 do
            print("Choisissez votre langue/Choose your language (FR/EN) (def : FR)")
            write("? ")
            local choix = read()
            if choix == "FR" or choix == "EN" then
                step = step + 1
                stgLua.set("FrOS/config.stg", "language", choix)
            elseif choix == "" then
                step = step + 1
                stgLua.set("FrOS/config.stg", "language", "FR")
            end
        end

        while step == 1 do
            print("Souhaitez-vous mettre automatiquement en pause en changeant d'application ?/Do you want to automatically pause while changing app? (O-Y/N) (def : O-Y)")
            write("? ")
            local choix = read()
            if choix == "O" or choix == "Y" or choix == "N" then
                step = step + 1
                stgLua.set("FrOS/config.stg", "autoPause", transformChoixToBool(choix))
            elseif choix == "" then
                step = step + 1
                stgLua.set("FrOS/config.stg", "autoPause", "1")
            end
        end

        while step == 2 do
            print("Choisissez couleur de fond d'écran/Choose your background color (noms en anglais états-unien/names in American English) (def : black)")
            write("? ")
            local choix = read()
            if table_contains(colors, choix) then
                step = step + 1
                stgLua.set("FrOS/config.stg", "bg", choix)
            elseif choix == "" then
                step = step + 1
                stgLua.set("FrOS/config.stg", "bg", "black")
            end
        end

        while step == 3 do
            print("Choisissez couleur de texte/Choose your text color (noms en anglais états-unien/names in American English) (def : white)")
            write("? ")
            local choix = read()
            if table_contains(colors, choix) then
                step = step + 1
                stgLua.set("FrOS/config.stg", "fg", choix)
            elseif choix == "" then
                step = step + 1
                stgLua.set("FrOS/config.stg", "fg", "white")
            end
        end

        while step == 4 do
            print("Choisissez couleur de fond de la StatusBar/Choose your StatusBar background (noms en anglais états-unien/names in American English) (def : gray)")
            write("? ")
            local choix = read()
            if table_contains(colors, choix) then
                step = step + 1
                stgLua.set("FrOS/config.stg", "bgBar", choix)
            elseif choix == "" then
                step = step + 1
                stgLua.set("FrOS/config.stg", "bgBar", "gray")
            end
        end

        while step == 5 do
            print("Choisissez couleur de texte/Choose your text color (noms en anglais états-unien/names in American English) (def : white)")
            write("? ")
            local choix = read()
            if table_contains(colors, choix) then
                step = step + 1
                stgLua.set("FrOS/config.stg", "fgBar", choix)
            elseif choix == "" then
                step = step + 1
                stgLua.set("FrOS/config.stg", "fgBar", "white")
            end
        end

        print("Voulez-vous installer des drivers ? (o/n)/Do you want to install drivers? (y/n)")
        write("? ")
        local choix = read()
        if choix == "o" or choix == "y" then
            print("Pour regarder la liste des drivers, faites 'liste ndrivers' et installez les avec 'driver <nom du driver>'.")
            print("To read the drivers list, use 'list ndrivers' and install them with 'driver <name of the driver>'.")
            shell.run("/apps/appStore.lua")
        end

        print("End of the OOBE, FrOS will reboot your computer.")
        stgLua.set("FrOS/config.stg", "oobe", "0")

        sleep(5)
        if gfx then
            gfx:resetColors()
        end
        os.reboot()
    else
        if gfx then
            gfx:resetColors()
        end
        shell.run("FrOS/main.lua")
    end
end