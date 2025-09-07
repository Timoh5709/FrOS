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
    textViewer.cprint("Terminal redirigé avec succès, pour revenir en arrière, faites 'exec redirect -t'.", colors.green)
elseif to == "-t" then
    monitorOut.unRedirect()
    textViewer.cprint("Terminal de retour avec succès, pour le rediriger à nouveau, faites 'exec redirect'.", colors.green)
else
    textViewer.eout("Erreur : Veuillez sélectionner entre -m ou -t.")
end