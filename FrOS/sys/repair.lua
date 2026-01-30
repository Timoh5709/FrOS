local repair = {}

local function installGithub(filename)
    print("Downloading " .. filename .. " from Github.")
    local downloader = http.get("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/" .. filename)
    if downloader then
        local input = io.open(filename, "w")
        input:write(downloader.readAll())
        input:close()
        print("The downloading of " .. filename .. " was a success.")
        return true
    else
        print("Error while downloading the file : " .. filename)
    end
end

function repair.file(filename)
    term.setTextColor(colors.red)
    installGithub(filename)
end

function repair.check(filename)
    if not fs.exists(filename) then 
        term.setTextColor(colors.red)
        print("Error : The file '" .. filename .. "' is unobtainable. The system can be unstable and damaged.")
        repair.file(filename)
        term.setTextColor(colors.white)
        return false
    else
        term.setTextColor(colors.green)
        print("'" .. filename .. "' found.")
        term.setTextColor(colors.white)
        return true
    end
end

return repair