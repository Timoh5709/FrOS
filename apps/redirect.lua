local monitorOut = require("/FrOS/drivers/monitorOut")
local textViewer = require("/FrOS/sys/textViewer")

local args = {...}
if #args < 1 then
    textViewer.cprint("Utilisation : -m (moniteur) OU -t (terminal)", colors.orange)
    return
end

local to = args[1]
if to == "-m" then
    monitorOut.redirect()
    textViewer.cprint("Terminal redirig� avec succ�s, pour revenir en arri�re, faites 'exec redirect -t'.", colors.green)
elseif to == "-t" then
    monitorOut.unRedirect()
    textViewer.cprint("Terminal de retour avec succ�s, pour le rediriger � nouveau, faites 'exec redirect'.", colors.green)
else
    textViewer.eout("Erreur : Veuillez s�lectionner entre -m ou -t.")
end