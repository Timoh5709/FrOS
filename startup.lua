term.clear()
term.setCursorPos(1,1)
local running = true

function lineViewer(lines)
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

function addBoot(name, loc)
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
    -- Ajouter si name existe
    end
    if not fs.exists("boot.txt") then
        local f = fs.open("boot.txt", "w")
        if f then
            f.write(name .. "|" .. loc .. "\n")
            f.close()
            print(name .. "a bien été ajouté à la liste, veuillez redémarrer pour appliquer les changements.")
        else
            print("Erreur : Impossible de créer le fichier 'boot.txt'.")
        end
    else
        local f = fs.open("boot.txt", "a")
        if f then
            f.write(name .. "|" .. loc .. "\n")
            f.close()
            print(name .. "a bien été ajouté à la liste, veuillez redémarrer pour appliquer les changements.")
        else
            print("Erreur : Impossible d'ajouter au fichier 'boot.txt'.")
        end
    end
end

function readBoot()
    local boots = fs.find("/*/boot.lua")
    local install = fs.find("/*/install.lua")
    local startup = fs.find("/*/startup.lua")
    local names = {}
    for i=1,#boots do
        startup[#startup+1] = boots[i]
    end
    for i=1,#install do
        startup[#startup+1] = install[i]
    end
    for i=1,#startup do
        if startup[i] == "rom/startup.lua" then
            table.insert(names, "CraftOS")
        elseif startup[i] == "FrOS/boot.lua" then
            table.insert(names, "FrOS")
        elseif startup[i] == "temp/install.lua" then
            table.insert(names, "Maj FrOS")
        else
            table.insert(names, startup[i])
        end
    end
    if fs.exists("boot.txt") then
        local f = fs.open("boot.txt", "r")
        while true do
            local ligne = f.readLine()
            if not ligne then break end
            local idx = 1
            for i in string.gmatch(ligne, "|") do
                if idx == 1 then
                    table.insert(names, i)
                else
                    table.insert(startup, i)
                end
                idx = idx + 1
            end
        end
    end
    lineViewer(names)
end

function table_contains(tbl, x)
    found = false
    idx = 1
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
    if input == nil then
        input = "nil"
    end

    local args = {}
    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end

    local command = args[1]
    local param = args[2]

    local fnd, idx = table_contains(names, input)
    if idx <= #names then
        local _, height = term.getSize()
        term.setCursorPos(1,height)
        write("Lancement de " .. names[idx])
        if input == "CraftOS" then
            term.clear()
            term.setCursorPos(1,1)
            return
        end
        running = false
        shell.run(startup[idx])
    elseif command == "add" then
        addBoot(param, args[3])
    else
        print("Erreur : OS introuvable : " .. input)
    end
end