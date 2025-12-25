term.clear()
term.setCursorPos(1,1)
local running = true

local function lineViewer(lines)
  local _, height = term.getSize()
  local currentIndex = 1
  local maxIndex = #lines
  local pageSize = height - 5

  while true do
    term.setCursorPos(1, 3)

    for i = currentIndex, math.min(currentIndex + pageSize - 1, maxIndex) do
      print(lines[i])
    end

    print("\n-- Veuillez sélectionner un OS --")

    return
  end
end

local function addBoot(name, loc)
    if not name then
        print("Erreur : Aucun nom d'OS spécifié.")
        print("Utilisation : add <nom> <fichier boot>")
        return
    elseif not loc then
        print("Erreur : Aucun fichier lua spécifié.")
        print("Utilisation : add <nom> <fichier boot>")
        return
    elseif not fs.exists(loc) then
        print("Erreur : Le fichier '" .. loc .. "' n'existe pas.")
        print("Exemple : add FrOS FrOS/boot.lua")
        return
    -- TODO : Ajouter si name existe
    end
    if not fs.exists("boot.txt") then
        local f = fs.open("boot.txt", "w")
        if f then
            f.write(name .. "|" .. loc .. "\n")
            f.close()
            print(name .. " a bien été ajouté à la liste, veuillez redémarrer pour appliquer les changements 'reboot'.")
        else
            print("Erreur : Impossible de créer le fichier 'boot.txt'.")
        end
    else
        local f = fs.open("boot.txt", "a")
        if f then
            f.write(name .. "|" .. loc .. "\n")
            f.close()
            print(name .. " a bien été ajouté à la liste, veuillez redémarrer pour appliquer les changements 'reboot'.")
        else
            print("Erreur : Impossible d'ajouter au fichier 'boot.txt'.")
        end
    end
end

local function removeBoot(name)
    if not name then
        print("Erreur : Aucun nom d'OS spécifié.")
        print("Utilisation : remove <nom>")
        return
    end
    if fs.exists("boot.txt") then
        local lignes = {}
        local handle = fs.open("boot.txt", "r")
        if not handle then
            print("Erreur : Fichier illisible.")
            return
        end
        
        local fnd = false
        while true do
            local ligne = handle.readLine()
            if not ligne then break end

            local key, loc = ligne:match("([%w%.]+)|([^\n]+)")
            
            if key ~= name then
                table.insert(lignes, ligne)
            else
                fnd = true
            end
        end
        handle.close()
        
        handle = fs.open("boot.txt", "w")
        for _, ligne in ipairs(lignes) do
            handle.writeLine(ligne)
        end
        handle.close()

        if fnd then
            print(name .. " a bien été supprimé de la liste, veuillez redémarrer pour appliquer les changements 'reboot'.")
        else
            print("Erreur : Vous ne pouvez pas supprimer " .. name .. " car il n'est pas accessible.")
        end
    else
        print("Erreur : Vous ne pouvez pas supprimer " .. name .. " car il n'est pas accessible.")
    end
end

local boots = fs.find("/*/boot.lua")
local install = fs.find("/*/install.lua")
local startup = fs.find("/*/startup.lua")
local allFiles

local names = {}
local files = {}

local function readBoot()
    allFiles = {}

    for _, f in ipairs(boots) do table.insert(allFiles, f) end
    for _, f in ipairs(install) do table.insert(allFiles, f) end
    for _, f in ipairs(startup) do table.insert(allFiles, f) end

    for _, f in ipairs(allFiles) do
        files[f] = f
    end

    if fs.exists("boot.txt") then
        local f = fs.open("boot.txt", "r")
        while true do
            local ligne = f.readLine()
            if not ligne then break end

            local name, path = ligne:match("([^|]+)|(.+)")
            if name and path then
                if table_contains(allFiles, path) then
                    files[path] = name
                else
                    table.insert(allFiles, path)
                    files[path] = name
                end
            end
        end
        f.close()
    else
        print("Erreur : Fichier boot.txt manquant, veuillez ajoutez les boots avec la commande 'add'.")
    end

    for idx, f in ipairs(allFiles) do
        table.insert(names, idx .. " : " .. files[f] .. " (" .. f .. ")")
    end
    
    lineViewer(names)
end

function table_contains(tbl, x)
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

print("Bienvenue sur le bootloader FrOS.")

readBoot()

while running do
    write("? ")
    local input = read()
    if input == nil or input == "" then
        input = "nil"
    end

    local args = {}
    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end

    local command = args[1]
    local param  = args[2]

    local idx = tonumber(input)

    if idx and idx >= 1 and idx <= #allFiles then
        local _, height = term.getSize()
        term.setCursorPos(1, height)
        write("Lancement de " .. names[idx])
        if files[allFiles[idx]] == "CraftOS" then
            term.clear()
            term.setCursorPos(1,1)
            return
        end
        running = false
        shell.run(allFiles[idx])
    elseif command == "add" then
        addBoot(param, args[3])
    elseif command == "remove" then
        removeBoot(param)
    elseif command == "reboot" then
        os.reboot()
    else
        print("Erreur : OS introuvable : " .. input)
    end
end