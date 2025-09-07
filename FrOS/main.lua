local running = true
term.clear()
local history = {}
local speaker = peripheral.find("speaker")
local textViewer
local update
local statusBar = require("/FrOS/sys/statusBar")
if fs.exists("FrOS/sys/textViewer.lua") then
  textViewer = require("/FrOS/sys/textViewer")
end
if fs.exists("FrOS/sys/update.lua") then
  update = require("/FrOS/sys/update")
end
if fs.exists("FrOS/sys/httpViewer.lua") then
  httpViewer = require("/FrOS/sys/httpViewer")
end
if fs.exists("FrOS/sys/dfpwmPlayer.lua") then
  dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
end
local dossier = (shell.dir() == "" or shell.dir() == "/") and "root" or shell.dir()
shell.setPath(shell.path() .. ":/apps")

local criticalFiles = {
  ["FrOS"] = true,
  ["boot.lua"] = true,
  ["startup.lua"] = true,
  ["main.lua"] = true,
  ["sys"] = true,
  ["textViewer.lua"] = true,
  ["update.lua"] = true,
  ["media"] = true,
  ["startup.dfpwm"] = true,
  ["disk"] = true,
  ["rom"] = true,
  ["httpViewer.lua"] = true,
  ["drivers"] = true,
  ["init.lua"] = true
}

local function containsCriticalFiles(path)
  if not fs.isDir(path) then
    return false
  end

  local files = fs.list(path)
  for _, file in ipairs(files) do
    
    local fullPath = fs.combine(path, file)
    if criticalFiles[file] or (fs.isDir(fullPath) and containsCriticalFiles(fullPath)) then
      return true
    end
  end
  return false
end

local function listFiles()
  local files = fs.list(shell.dir())
  
  if #files == 0 then
    print("Le répertoire est vide.")
    return
  end
  
  local romFiles = {}
  local diskFiles = {}
  local dirFiles = {}
  local regularFiles = {}
  
  for _, file in ipairs(files) do
    local path = fs.combine(shell.dir(), file)
    
    if fs.isDir(path) then
      if string.match(file, "^disk%d*$") then
        local freeSpace = fs.getFreeSpace(path)
        local capacity = fs.getCapacity(path)
        local space = (math.floor(freeSpace / 1024 * 100) / 100) .. "/" .. (math.floor(capacity / 1024 * 100) / 100)
        local type = fs.getDrive(path)
        
        table.insert(diskFiles, string.format("%-20s %-10s %-20s", file .. "/", string.upper(type), space .. " Ko"))
      elseif file == "rom" then
        local type = fs.getDrive(path)
        
        table.insert(romFiles, string.format("%-20s %-10s", file .. "/", string.upper(type)))
      else
        table.insert(dirFiles, file .. "/")
      end
    else
      local size = fs.getSize(path)
      
      table.insert(regularFiles, string.format("%-20s  %-10s", file, (math.floor(size / 1024 * 100) / 100) .. " Ko"))
    end
  end

  local sortedFiles = {}
  for _, item in ipairs(romFiles) do
    table.insert(sortedFiles, item)
  end
  for _, item in ipairs(diskFiles) do
    table.insert(sortedFiles, item)
  end
  for _, item in ipairs(dirFiles) do
    table.insert(sortedFiles, item)
  end
  for _, item in ipairs(regularFiles) do
    table.insert(sortedFiles, item)
  end

  textViewer.lineViewer(sortedFiles)
end


local function changeDir(dir)
  local newDir = fs.combine(shell.dir(), dir)
  if fs.exists(newDir) and fs.isDir(newDir) then
    shell.setDir(newDir)
  else
    textViewer.eout("Erreur : Dossier introuvable.")
    dfpwmPlayer.playErrorSound()
  end
end

local function makeDir(dir)
  local newDir = fs.combine(shell.dir(), dir)
  if not fs.exists(newDir) then
    fs.makeDir(newDir)
    textViewer.cprint("Dossier créé : " .. newDir, colors.green)
  else
    textViewer.eout("Erreur : Ce dossier existe déjà.")
    dfpwmPlayer.playErrorSound()
  end
end

local function removeFileOrDir(target)
  local path = fs.combine(shell.dir(), target)

  if fs.exists(path) then
    if criticalFiles[target] or containsCriticalFiles(path) then
      textViewer.cprint("Avertissement : Vous tentez de supprimer un fichier ou un dossier critique.", colors.orange)
      textViewer.cprint("Cela pourrait affecter le fonctionnement du système. Voulez-vous continuer ? (oui/non)", colors.orange)
      dfpwmPlayer.playConfirmationSound()
      write("? ")
      local confirmation1 = read()
      if confirmation1 ~= "oui" then
        print("Suppression annulée.")
        return
      end
    end

    textViewer.cprint("Êtes-vous sur de vouloir supprimer " .. target .. " ? (oui/non)", colors.orange)
    dfpwmPlayer.playConfirmationSound()
    write("? ")
    local confirmation2 = read()
    if confirmation2 == "oui" then
      fs.delete(path)
      textViewer.cprint("Supprimé : " .. path, colors.green)
    else
      print("Suppression annulée.")
    end
  else
    textViewer.eout("Erreur : Fichier ou dossier introuvable.")
    dfpwmPlayer.playErrorSound()
  end
end

local function showHistory()
  print("Historique des commandes :")
  for i = 1, #history do
    print(i .. ": " .. history[i])
  end
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

local function mkfile(filename)
  if not filename then
    textViewer.eout("Erreur : Aucun nom de fichier spécifié.")
    return
  end

  local path = fs.combine(shell.dir(), filename)
  if fs.exists(path) then
    textViewer.eout("Erreur : Le fichier '" .. filename .. "' existe déjà.")
    return
  end

  local file = fs.open(path, "w")
  if file then
    file.close()
    textViewer.cprint("Fichier créé : " .. filename, colors.green)
  else
    textViewer.eout("Erreur : Impossible de créer le fichier.")
  end
end

local function exec(filename, param)
  if not filename then
    textViewer.eout("Erreur : Aucun fichier spécifié.")
    return
  end

  local path2 = "/" .. shell.resolveProgram(filename)
  if path2 == nil then
    path2 = "nil"
    textViewer.eout("Erreur : Fichier introuvable ou non valide.")
    return
  end
  if fs.exists(path2) then
    if param then
      shell.run(path2 .. param)
    else
      shell.run(path2)
    end
  else
    textViewer.eout("Erreur : Fichier introuvable ou non valide.")
  end
end

local function renommer(value)
  os.setComputerLabel(value)
  textViewer.cprint("Nom de l'ordinateur défini sur : " .. value, colors.green)
end

local function http(url)
  if not url then
    textViewer.eout("Erreur : Aucune URL spécifié")
    return
  end

  textViewer.lineViewer(httpViewer.readUrl(url))
end

local function main()
  dossier = (shell.dir() == "" or shell.dir() == "/") and "root" or shell.dir()
  write(dossier .. "> ")
  statusBar.draw(dossier)
  local input = read()

  if input ~= nil then
    table.insert(history, input)
  end

  if #history > 16 then
    table.remove(history, 1)
  end

  local args = {}
  for word in string.gmatch(input, "%S+") do
    table.insert(args, word)
  end

  local command = args[1]
  local param = args[2]
  local paramexec = ""
  if string.len(input) > 5 then
    paramexec = string.sub(input, 6)
  end

  if command == "quit" then
    print("Fermeture de FrOS...")
    os.shutdown()
  elseif command == "reboot" then
    print("Redémarrage de FrOS...")
    os.reboot()
  elseif command == "infosys" then
    print("Informations système : ")
    print("Version de FrOS : " .. textViewer.getVer())
    if os.getComputerLabel() then
      print("Nom de l'ordinateur : " .. os.getComputerLabel())
    end

    local freeSpace = fs.getFreeSpace(shell.dir()) or 0
    if math.floor(freeSpace / 1024) < 10000 then
      print("Espace libre dans le répertoire actuel : " .. (math.floor(freeSpace / 1024 * 100) / 100) .. " Ko")
    else
      print("Espace libre dans le répertoire actuel : " .. (math.floor(freeSpace / 1048576 * 100) / 100) .. " Mo")
    end

    print("Heure actuelle : " .. textutils.formatTime(os.time("local"), true))    
  elseif command == "aide" then
    aides = {
      "Commandes disponibles :",
      "aide - Affiche cette aide",
      "quit - Quitte FrOS",
      "reboot - Redémarre FrOS",
      "ls OU dir - Liste les fichiers",
      "go OU cd <dossier> - Change de dossier",
      "mkdir <nom> - Crée un dossier",
      "del OU rm <nom> - Supprime un fichier ou un dossier",
      "history - Affiche l'historique des commandes",
      "infosys - Affiche des informations sur le système",
      "lire <nom> - Lit le fichier",
      "cls - Nettoie le terminal",
      "maj - Met à jour",
      "mkfile <nom> - Crée un fichier",
      "exec <nom> - Exécute un fichier lua",
      "nom <nom> - Renomme l'ordinateur",
      "http <url> - Affiche le contenu d'une page http"
    }
    textViewer.lineViewer(aides)
  elseif command == "ls" or command == "dir" then
    listFiles()
  elseif command == "go" or command == "cd" then
    if param then
      changeDir(param)
    else
      textViewer.eout("Erreur : Aucun dossier spécifié.")
      dfpwmPlayer.playErrorSound()
    end
  elseif command == "mkdir" then
    if param then
      makeDir(param)
    else
      textViewer.eout("Erreur : Aucun nom de dossier spécifié.")
      dfpwmPlayer.playErrorSound()
    end
  elseif command == "del" or command == "rm" then
    if param then
      removeFileOrDir(param)
    else
      textViewer.eout("Erreur : Aucun nom spécifié.")
      dfpwmPlayer.playErrorSound()
    end
  elseif command == "history" then
    showHistory()
  elseif command == "lire" then
    if param then
      readAllText(param)
    else
      textViewer.eout("Erreur : Aucun fichier spécifié.")
      dfpwmPlayer.playErrorSound()
    end
  elseif command == "cls" then
    term.clear()
  elseif command == "maj" then
    update.install()
  elseif command == "mkfile" then
    mkfile(param)
  elseif command == "exec" then
    exec(param, string.sub(paramexec, string.len(param) + 1))
  elseif command == "nom" then
    renommer(param)
  elseif command == "http" then
    http(param)
  elseif command ~= nil then
    textViewer.eout("Commande inconnue : " .. command)
    dfpwmPlayer.playErrorSound()
  else
    textViewer.eout("Veuillez rentrer une commande.")
    dfpwmPlayer.playErrorSound()
  end
end

needUpdate, oVer = update.check()
if needUpdate then
  print("La version " .. oVer .. " est disponible, faites 'maj' pour l'installer !")
end

while running do
  main()
end