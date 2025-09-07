local monitorOut = {}
local monitor = peripheral.find("monitor")
local httpViewer = require("/FrOS/sys/httpViewer")

if not fs.exists("apps/redirect.lua") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/apps/", "redirect.lua")
end

if monitor then
    print("Moniteur prêt à l'emploi avec 'exec redirect -m'.")
end

function monitorOut.redirect()
    term.redirect(monitor)
end

function monitorOut.unRedirect()
    term.redirect(term.native())
end