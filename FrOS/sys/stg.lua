local stg = {}
local textViewer = require("/FrOS/sys/textViewer")

function stg.read(path)
    if not fs.exists(path) then
        textViewer.eout("Error : The setting file doesn't exist.")
        return {}
    end

    local f = fs.open(path, "r")
    local data = {}

    while true do
        local line = f.readLine()
        if not line then break end

        if line ~= "" and not line:match("^%s*#") then
            local key, value = line:match("^%s*([^=]+)%s*=%s*(.*)%s*$")
            if key and value then
                data[key] = value
            end
        end
    end

    f.close()
    return data
end

function stg.set(path, key, value)
    local lines = {}
    local found = false

    if fs.exists(path) then
        local f = fs.open(path, "r")
        while true do
            local line = f.readLine()
            if not line then break end

            local k = line:match("^%s*([^=]+)%s*=")
            if k == key then
                table.insert(lines, key .. "=" .. tostring(value))
                found = true
            else
                table.insert(lines, line)
            end
        end
        f.close()
    end

    if not found then
        table.insert(lines, key .. "=" .. tostring(value))
    end

    local f = fs.open(path, "w")
    for _, line in ipairs(lines) do
        f.writeLine(line)
    end
    f.close()
end

return stg