local running = true
term.clear()
local history = {}
local textViewer
local update
local httpViewer
local dfpwmPlayer
local fzip
local script
local stg
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
if fs.exists("FrOS/sys/FZIP.lua") then
  fzip = require("/FrOS/sys/fzip")
end
if fs.exists("FrOS/sys/script.lua") then
  script = require("/FrOS/sys/script")
end
if fs.exists("FrOS/sys/stg.lua") then
  stg = require("/FrOS/sys/stg")
end
local dossier = (shell.dir() == "" or shell.dir() == "/") and "root" or shell.dir()
shell.setPath(shell.path() .. ":/apps")

local loc = FrOS.mainLoc
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end

local function listFilesRecursive(basePath)
  local results = {}
  local allSizes = 0

  local function scan(path, rel)
    for _, item in ipairs(fs.list(path)) do
      local fullPath = fs.combine(path, item)
      local relPath = rel and fs.combine(rel, item) or item
      local size = fs.isDir(fullPath) and 0 or fs.getSize(fullPath)

      if fs.isDir(fullPath) then
        scan(fullPath, relPath)
      else
        table.insert(results, {abs = fullPath, rel = relPath})
        allSizes = allSizes + size
      end
    end
  end

  scan(basePath, nil)
  return results, allSizes
end

function string:endswith(suffix)
  return self:sub(-#suffix) == suffix
end

local function listFiles()
  local files = fs.list(shell.dir())
  
  if #files == 0 then
    print(loc["listFiles.emptyDir"])
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
        local _, usedSpace = listFilesRecursive(path)
        local space
        if math.floor(usedSpace / 1024) < 10000 then
          space = (math.floor(usedSpace / 1024 * 100) / 100) .. " Ko"
        else
          space = (math.floor(usedSpace / 1048576 * 100) / 100) .. " Mo"
        end
        table.insert(dirFiles, string.format("%-30s %-20s", file .. "/", space))
      end
    else
      local size = fs.getSize(path)
      local space
      if math.floor(size / 1024) < 10000 then
        space = (math.floor(size / 1024 * 100) / 100) .. " Ko"
      else
        space = (math.floor(size / 1048576 * 100) / 100) .. " Mo"
      end
      table.insert(regularFiles, string.format("%-30s  %-10s", file, space))
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
  elseif fs.exists(newDir) and newDir:endswith(".fzip") then
    local tempDir = fs.combine("temp", dir:sub(1, -6))
    fzip.extract(newDir, tempDir)
    shell.setDir(tempDir)
  else
    textViewer.eout(loc["error.unknownDir"])
  end
end

local function makeDir(dir)
  local newDir = fs.combine(shell.dir(), dir)
  if not fs.exists(newDir) then
    fs.makeDir(newDir)
    textViewer.cprint(loc["makeDir.success"] .. newDir, colors.green)
  else
    textViewer.eout(loc["error.alreadyExistingDir"] .. dir)
  end
end

local function removeFileOrDir(target)
  local path = fs.combine(shell.dir(), target)

  if fs.exists(path) then
    if script.confirmation() then
      fs.delete(path)
      textViewer.cprint(loc["removeFileOrDir.success"] .. path, colors.green)
    else
      print(loc["removeFileOrDir.canceled"])
    end
  else
    textViewer.eout(loc["error.unknown"])
  end
end

local function showHistory()
  print(loc["showHistory.command"])
  local lignes = {}
  for i = 1, #history do
    table.insert(lignes, i .. ": " .. history[i])
  end
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

local function mkfile(filename)
  if not filename then
    textViewer.eout(loc["error.unspecifiedFile"])
    return
  end

  local path = fs.combine(shell.dir(), filename)
  if fs.exists(path) then
    textViewer.eout(loc["error.alreadyExistingFile"] .. filename)
    return
  end

  local file = fs.open(path, "w")
  if file then
    file.close()
    textViewer.cprint(loc["mkfile.success"] .. filename, colors.green)
  else
    textViewer.eout("Erreur : Impossible de cr�er le fichier.")
  end
end

local function exec(filename, param)
  local resolved = shell.resolveProgram(filename)
  if not resolved then
    textViewer.eout(loc["error.unknownFile"])
    return
  end
  local path2 = "/" .. resolved

  if path2 == nil then
    path2 = "nil"
    textViewer.eout(loc["error.unknownUnreadableFile"])
    return
  end
  if fs.exists(path2) then
    if param then
      shell.run(path2 .. param)
    else
      shell.run(path2)
    end
  else
    textViewer.eout(loc["error.unknownUnreadableFile"])
  end
end

local function rename(value)
  if not value then
    textViewer.eout(loc["error.unspecified"])
    return
  end
  os.setComputerLabel(value)
  textViewer.cprint(loc["rename.success"] .. value, colors.green)
end

local function http(url)
  if not url then
    textViewer.eout(loc["error.unspecifiedURL"])
    return
  end

  textViewer.lineViewer(httpViewer.getLines(url))
end

local function stg_set(key, value)
  if not key or not value then
    textViewer.eout(loc["error.unspecified"])
    return
  end
  stg.set("FrOS/config.stg", key, value)
  print(loc["stg_set.success1"] .. key .. loc["stg_set.success2"] .. value)
end

function FrOS.executeLine(input)
  if not input or input == "" then
    textViewer.eout(loc["main.noCommand"])
    return
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
    print(loc["main.quitCommand"])
    dfpwmPlayer.playShutdownSound()
    os.shutdown()

  elseif command == "reboot" then
    print(loc["main.rebootCommand"])
    dfpwmPlayer.playShutdownSound()
    os.reboot()

  elseif command == "infosys" then
    print(loc["main.infosysCommand"])
    print(loc["main.versionInfosys"] .. textViewer.getVer())

    if os.getComputerLabel() then
      print(loc["main.nameInfosys"] .. os.getComputerLabel())
    end

    local freeSpace = fs.getFreeSpace(shell.dir()) or 0
    if math.floor(freeSpace / 1024) < 10000 then
      print(loc["main.freeSpaceInfosys"] .. (math.floor(freeSpace / 1024 * 100) / 100) .. " Ko")
    else
      print(loc["main.freeSpaceInfosys"] .. (math.floor(freeSpace / 1048576 * 100) / 100) .. " Mo")
    end

    print(loc["main.clockInfosys"] .. textutils.formatTime(os.time("local"), true))    

  elseif command == "aide" then
    local aides = {
      loc["main.aideCommand"],
      loc["main.aideAide"],
      loc["main.quitAide"],
      loc["main.rebootAide"],
      loc["main.lsAide"],
      loc["main.goAide"],
      loc["main.mkdirAide"],
      loc["main.delAide"],
      loc["main.historyAide"],
      loc["main.infosysAide"],
      loc["main.lireAide"],
      loc["main.clsAide"],
      loc["main.majAide"],
      loc["main.mkfileAide"],
      loc["main.execAide"],
      loc["main.nomAide"],
      loc["main.httpAide"],
      loc["main.scriptAide"],
      loc["main.sleepAide"],
      loc["main.echoAide"],
      loc["main.stgAide"]
    }

    textViewer.lineViewer(aides)

  elseif command == "ls" or command == "dir" then
    listFiles()

  elseif command == "go" or command == "cd" then
    if param then
      changeDir(param)
    else
      textViewer.eout(loc["error.unspecifiedDir"])
    end

  elseif command == "mkdir" then
    if param then
      makeDir(param)
    else
      textViewer.eout(loc["error.unspecifiedDir"])
    end

  elseif command == "del" or command == "rm" then
    if param then
      removeFileOrDir(param)
    else
      textViewer.eout(loc["error.unspecified"])
    end

  elseif command == "history" then
    if param == "remove" then
      if script.confirmation() then
        history = {}
        fs.delete("/FrOS/history.txt")
        textViewer.cprint(loc["removeFileOrDir.success"] .. "/FrOS/history.txt", colors.green)
      else
        print(loc["removeFileOrDir.canceled"])
      end
    else
      showHistory()
    end

  elseif command == "lire" then
    if param then
      readAllText(param)
    else
      textViewer.eout(loc["error.unspecifiedFile"])
    end

  elseif command == "cls" then
    term.clear()
    term.setCursorPos(1, 2)

  elseif command == "maj" then
    if param == "create" then
      update.createInstallationDisk()
    elseif param == "old" then
      update.oldInstall()
    else
      update.install()
      local commands = script.read("temp/update.fsc")
      local parsed = script.parse(commands)
      script.run(parsed, dossier)
    end

  elseif command == "mkfile" then
    mkfile(param)

  elseif command == "exec" then
    if not param then
      textViewer.eout(loc["error.unspecifiedFile"])
      return
    end
    exec(param, string.sub(paramexec, string.len(param) + 1))

  elseif command == "nom" then
    rename(param)

  elseif command == "http" then
    http(param)

  elseif command == "script" then
    local commands = script.read(param)
    local parsed = script.parse(commands)
    script.run(parsed, dossier)

  elseif command == "sleep" then
    sleep(tonumber(param))
  
  elseif command == "echo" then
    print(paramexec)

  elseif command == "stg" then
    stg_set(param, args[3])

  elseif command ~= nil then
    textViewer.eout(loc["main.unknownCommand"] .. command)

  else
    textViewer.eout(loc["main.noCommand"])
  end
end

local function main()
  dossier = (shell.dir() == "" or shell.dir() == "/") and "root" or shell.dir()
  write(dossier .. "> ")
  statusBar.draw(dossier)

  local input = read(nil, history)

  if input and input ~= "" then
    table.insert(history, input)
    
    if #history > (2 ^ 16) then
      table.remove(history, 1)
    end

    if not fs.exists("/FrOS/history.txt") then
      local f = fs.open("/FrOS/history.txt", "w")
      if f then
        f.write(input .. "\n")
        f.close()
      else
        textViewer.eout(loc["error.historyCreate"])
      end
    else
      local f = fs.open("/FrOS/history.txt", "a")
      if f then
        f.write(input .. "\n")
        f.close()
      else
        textViewer.eout(loc["error.historyUpdate"])
      end
    end

    FrOS.executeLine(input)
  end
end

local needUpdate, oVer = update.check()
if needUpdate then
  print(loc[".newVersion1"] .. oVer .. loc[".newVersion2"])
end

if fs.exists("/FrOS/history.txt") then
  local f = fs.open("/FrOS/history.txt", "r")
  while true do
    local ligne = f.readLine()
    if not ligne then break end
    table.insert(history, ligne)
  end
end

while running do
  main()
end