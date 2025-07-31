local running = true
local sbTimer = true
term.clear()
local history = {}
local speaker = peripheral.find("speaker")
local textViewer
local update
local statusBar = require("sys/statusBar")
if fs.exists("sys/textViewer.lua") then
    textViewer = require("sys/textViewer")
end
if fs.exists("sys/update.lua") then
    update = require("sys/update")
end
local dossier = (shell.dir() == "" or shell.dir() == "/") and "root" or shell.dir()
shell.setPath(shell.path() .. ":/apps")

local criticalFiles = {
  ["startup.lua"] = true,
  ["main.lua"] = true,
  ["sys"] = true,
  ["textViewer.lua"] = true,
  ["update.lua"] = true,
  ["media"] = true,
  ["startup.dfpwm"] = true,
  ["disk"] = true,
  ["rom"] = true
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
    print("Le repertoire est vide.")
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
    print("Erreur : Dossier introuvable.")
    playErrorSound()
  end
end

local function makeDir(dir)
  local newDir = fs.combine(shell.dir(), dir)
  if not fs.exists(newDir) then
    fs.makeDir(newDir)
    print("Dossier cree : " .. newDir)
  else
    print("Erreur : Ce dossier existe deja.")
    playErrorSound()
  end
end

local function removeFileOrDir(target)
  local path = fs.combine(shell.dir(), target)

  if fs.exists(path) then
    if criticalFiles[target] or containsCriticalFiles(path) then
      print("Avertissement : Vous tentez de supprimer un fichier ou un dossier critique.")
      print("Cela pourrait affecter le fonctionnement du systeme. Voulez-vous continuer ? (oui/non)")
      playConfirmationSound()
      write("? ")
      local confirmation1 = read()
      if confirmation1 ~= "oui" then
        print("Suppression annulee.")
        return
      end
    end

    print("Etes-vous sur de vouloir supprimer " .. target .. " ? (oui/non)")
    playConfirmationSound()
    write("? ")
    local confirmation2 = read()
    if confirmation2 == "oui" then
      fs.delete(path)
      print("Supprime : " .. path)
    else
      print("Suppression annulee.")
    end
  else
    print("Erreur : Fichier ou dossier introuvable.")
    playErrorSound()
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
        print("Erreur : Fichier illisible.")
        playErrorSound()
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
    print("Erreur : Aucun nom de fichier spécifie.")
    return
  end

  local path = fs.combine(shell.dir(), filename)
  if fs.exists(path) then
    print("Erreur : Le fichier '" .. filename .. "' existe deja.")
    return
  end

  local file = fs.open(path, "w")
  if file then
    file.close()
    print("Fichier cree : " .. filename)
  else
    print("Erreur : Impossible de creer le fichier.")
  end
end

local function exec(filename)
  if not filename then
    print("Erreur : Aucun fichier specifie.")
    return
  end

  local path = fs.combine(shell.dir(), filename)
  local path2 = shell.resolveProgram(filename)
  if fs.exists(path) and not fs.isDir(path) then
    shell.run(path)
  elseif fs.exists(path2) then
    shell.run(path2)
  else
    print("Erreur : Fichier introuvable ou non valide.")
  end
end

local function renommer(value)
  os.setComputerLabel(value)
  print("Nom de l'ordinateur defini sur : " .. value)
end

function playErrorSound()
  if speaker ~= nil then
    speaker.playNote("bit")
  end
end

function playConfirmationSound()
  if speaker ~= nil then
    speaker.playNote("chime")
  end
end

local function main()
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

  if command == "quit" then
    print("Fermeture de FrOS...")
    sleep(1)
    os.shutdown()
  elseif command == "reboot" then
    print("Redemarrage de FrOS...")
    sleep(1)
    os.reboot()
  elseif command == "infosys" then
    print("Informations systeme : ")
    print("Version de FrOS : OS_HDD_2")
    if os.getComputerLabel() then
      print("Nom de l'ordinateur : " .. os.getComputerLabel())
    end

    local freeSpace = fs.getFreeSpace(shell.dir()) or 0
    print("Espace libre dans le repertoire actuel : " .. (math.floor(freeSpace / 1024 * 100) / 100) .. " Ko")

    print("Heure actuelle : " .. textutils.formatTime(os.time(), true))    
  elseif command == "aide" then
    aides = {
      "Commandes disponibles :",
      "aide - Afficher cette aide",
      "quit - Quitter FrOS",
      "ls OU dir - Lister les fichiers",
      "go OU cd <dossier> - Changer de dossier",
      "mkdir <nom> - Creer un dossier",
      "del OU rm <nom> - Supprimer un fichier ou un dossier",
      "history - Afficher l'historique des commandes",
      "infosys - Aficher des informations sur le systeme",
      "lire <nom> - Lire le fichier",
      "cls - Nettoyer le terminal",
      "maj - Mettre a jour",
      "mkfile <nom> - Creer un fichier",
      "exec <nom> - Executer un fichier lua",
      "nom <nom> - Renommer l'ordinateur"
    }
    textViewer.lineViewer(aides)
  elseif command == "ls" or command == "dir" then
    listFiles()
  elseif command == "go" or command == "cd" then
    if param then
      changeDir(param)
    else
      print("Erreur : Aucun dossier specifie.")
      playErrorSound()
    end
  elseif command == "mkdir" then
    if param then
      makeDir(param)
    else
      print("Erreur : Aucun nom de dossier specifie.")
      playErrorSound()
    end
  elseif command == "del" or command == "rm" then
    if param then
      removeFileOrDir(param)
    else
      print("Erreur : Aucun nom specifie.")
      playErrorSound()
    end
  elseif command == "history" then
    showHistory()
  elseif command == "lire" then
    if param then
      readAllText(param)
    else
      print("Erreur : Aucun fichier specifie.")
      playErrorSound()
    end
  elseif command == "cls" then
    term.clear()
  elseif command == "maj" then
    update.install()
  elseif command == "mkfile" then
    mkfile(param)
  elseif command == "exec" then
    exec(param)
  elseif command == "nom" then
    renommer(param)
  elseif command ~= nil then
    print("Commande inconnue : " .. command)
    playErrorSound()
  else
    print("Veuillez rentrer une commande.")
    playErrorSound()
  end
end

while running do
  main()
end