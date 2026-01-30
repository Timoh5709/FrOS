local update = {}
local textViewer = require("/FrOS/sys/textViewer")
local httpViewer = require("/FrOS/sys/httpViewer")
local fzip = require("/FrOS/sys/FZIP")

local loc = FrOS.sysLoc
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end

function update.install()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.blue)
    term.clear()
    print(loc["update.install.download"])
    local downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/install.lua")
    if downloader then
        local input = io.open("temp/install.lua", "w")
        input:write(downloader.readAll())
        input:close()
        print(loc["update.install.success1"])
        print(loc["update.install.success2"])
        os.reboot()
        return true
    else
        textViewer.eout(loc["update.install.error"])
        os.reboot()
    end
end

local function installGithub(oFilename, filename)
    local url = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/"
    print(loc[".installGithub.download2"] .. oFilename .. loc[".installGithub.download1"])
    local downloader = http.get(url .. oFilename)
    if downloader then
        local input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
        textViewer.cprint(loc[".installGithub.success1"] .. oFilename .. loc[".installGithub.success2"], colors.green)
        return true
    else
        textViewer.eout(loc[".installGithub.error"] .. oFilename)
    end
end

function update.createInstallationDisk()
    local disks = { peripheral.find("drive") }
    local emptyDisksLoc = {}
    for _, disk in pairs(disks) do
        if disk.isDiskPresent() then
            table.insert(emptyDisksLoc, disk.getMountPath())
        end
    end
    if #emptyDisksLoc == 0 then
        textViewer.eout(loc["error.noDisk"])
    elseif #emptyDisksLoc > 1 then
        textViewer.eout(loc["error.tooManyDisks"])
    else
        fs.makeDir("temp/install")
        print(loc["update.createInstallationDisk.directory1"] .. "temp/install" .. loc["update.createInstallationDisk.directory2"])
        fs.makeDir("temp/install/FrOS")
        print(loc["update.createInstallationDisk.directory1"] .. "temp/install/FrOS" .. loc["update.createInstallationDisk.directory2"])
        installGithub("FrOS/main.lua", "temp/install/FrOS/main.lua")
        installGithub("FrOS/version.txt", "temp/install/FrOS/version.txt")
        fs.makeDir("temp/install/FrOS/media")
        print(loc["update.createInstallationDisk.directory1"] .. "temp/install/FrOS/media" .. loc["update.createInstallationDisk.directory2"])
        installGithub("FrOS/media/startup.dfpwm", "temp/install/FrOS/media/startup.dfpwm")
        installGithub("FrOS/media/shutdown.dfpwm", "temp/install/FrOS/media/shutdown.dfpwm")
        installGithub("FrOS/media/error.dfpwm", "temp/install/FrOS/media/error.dfpwm")
        installGithub("FrOS/media/ask.dfpwm", "temp/install/FrOS/media/ask.dfpwm")
        fs.makeDir("temp/install/FrOS/sys")
        print(loc["update.createInstallationDisk.directory1"] .. "temp/install/FrOS/sys" .. loc["update.createInstallationDisk.directory2"])
        installGithub("FrOS/sys/textViewer.lua", "temp/install/FrOS/sys/textViewer.lua")
        installGithub("FrOS/sys/update.lua", "temp/install/FrOS/sys/update.lua")
        installGithub("FrOS/sys/repair.lua", "temp/install/FrOS/sys/repair.lua")
        installGithub("FrOS/sys/statusBar.lua", "temp/install/FrOS/sys/statusBar.lua")
        installGithub("FrOS/sys/httpViewer.lua", "temp/install/FrOS/sys/httpViewer.lua")
        installGithub("FrOS/sys/dfpwmPlayer.lua", "temp/install/FrOS/sys/dfpwmPlayer.lua")
        installGithub("FrOS/sys/progressBar.lua", "temp/install/FrOS/sys/progressBar.lua")
        installGithub("FrOS/sys/utf8.lua", "temp/install/FrOS/sys/utf8.lua")
        installGithub("FrOS/sys/loc.lua", "temp/install/FrOS/sys/loc.lua")
        installGithub("FrOS/sys/FZIP.lua", "temp/install/FrOS/sys/FZIP.lua")
        installGithub("FrOS/sys/script.lua", "temp/install/FrOS/sys/script.lua")
        installGithub("FrOS/sys/gfrx.lua", "temp/install/FrOS/sys/gfrx.lua")
        installGithub("FrOS/sys/offline-installer.lua", "temp/install/FrOS/sys/offline-installer.lua")
        fs.makeDir("temp/install/FrOS/localization")
        print(loc["update.createInstallationDisk.directory1"] .. "temp/install/FrOS/localization" .. loc["update.createInstallationDisk.directory2"])
        installGithub("FrOS/localization/main.loc", "temp/install/FrOS/localization/main.loc")
        installGithub("FrOS/localization/error.loc", "temp/install/FrOS/localization/error.loc")
        installGithub("FrOS/localization/sys.loc", "temp/install/FrOS/localization/sys.loc")
        fs.makeDir("temp/install/FrOS/drivers")
        print(loc["update.createInstallationDisk.directory1"] .. "temp/install/FrOS/drivers" .. loc["update.createInstallationDisk.directory2"])
        installGithub("FrOS/drivers/init.lua", "temp/install/FrOS/drivers/init.lua")
        fs.makeDir("temp/install/apps")
        print(loc["update.createInstallationDisk.directory1"] .. "temp/install/apps" .. loc["update.createInstallationDisk.directory2"])
        installGithub("apps/appStore.lua", "temp/install/apps/appStore.lua")
        installGithub("apps/manuel.lua", "temp/install/apps/manuel.lua")
        fs.makeDir("temp/install/temp")
        print(loc["update.createInstallationDisk.directory1"] .. "temp/install/temp" .. loc["update.createInstallationDisk.directory2"])
        installGithub("FrOS/boot.lua", "temp/install/FrOS/boot.lua")
        installGithub("startup.lua", "temp/install/startup.lua")
        fzip.create("disk/fros-offline.fzip", { "temp/install" })
        fs.copy("FrOS/sys/offline-installer.lua", "disk/startup.lua")
        textViewer.cprint(loc["update.createInstallationDisk.success"], colors.green)
    end
end

function update.check()
    if http.checkURL("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/version.txt") == true then
        local ver = textViewer.getVer()
        local oVer = httpViewer.httpBrain("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/FrOS/version.txt")
        if oVer == false then
            oVer = "4.0.4"
        end
        return ver ~= oVer, oVer
    end
    return false, 1
end

function update.appCheck(ver)
    if tonumber(textViewer.getVer()) < ver then
        textViewer.eout(loc["error.needUpdate"])
        return false
    else
        return true
    end
end

return update