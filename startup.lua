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

    print("\n-- Select your OS/lua script --")

    return
  end
end

local function addBoot(name, loc)
    if not name then
        print("Error : No OS name was specified.")
        print("Use : add <nom> <fichier boot>")
        return
    elseif not loc then
        print("Error : No lua file was specified.")
        print("Use : add <nom> <fichier boot>")
        return
    elseif not fs.exists(loc) then
        print("Error : The file '" .. loc .. "' doesn't exist.")
        print("Example : add FrOS FrOS/boot.lua")
        return
    end
    if not fs.exists("boot.txt") then
        local f = fs.open("boot.txt", "w")
        if f then
            f.write(name .. "|" .. loc .. "\n")
            f.close()
            print(name .. " was added to the list, reboot to apply with 'reboot'.")
        else
            print("Error : The file 'boot.txt' can't be created.")
        end
    else
        local f = fs.open("boot.txt", "a")
        if f then
            f.write(name .. "|" .. loc .. "\n")
            f.close()
            print(name .. " was added to the list, reboot to apply with 'reboot'.")
        else
            print("Error : The boot can't be added to 'boot.txt'.")
        end
    end
end

local function removeBoot(name)
    if not name then
        print("Error : No OS/lua script was specified.")
        print("Use : remove <nom>")
        return
    end
    if fs.exists("boot.txt") then
        local lignes = {}
        local handle = fs.open("boot.txt", "r")
        if not handle then
            print("Error : Unreadable file.")
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
            print(name .. " was removed to the list, reboot to apply with 'reboot'.")
        else
            print("Error : You can't remove " .. name .. " because it's not accessible.")
        end
    else
        print("Error : You can't remove " .. name .. " because it's not accessible.")
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
        print("Error : The file 'boot.txt' is missing, add OS/lua script with the 'add' command.")
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

print("Bootloader FrOS :")

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
        write("Starting " .. names[idx])
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
        print("Error : Unknown OS/lua file : " .. input)
    end
end