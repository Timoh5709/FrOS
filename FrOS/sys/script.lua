local script = {}
local textViewer = require("/FrOS/sys/textViewer")
local dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")
local update = require("/FrOS/sys/update")

local loc = FrOS.sysLoc
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end

function script.read(path)
    if not path or not fs.exists(path) then
        textViewer.eout(loc["error.unknownUnreadableFile"])
        return nil
    end

    local file = fs.open(path, "r")
    local lines = {}

    while true do
        local line = file.readLine()
        if not line then break end
        table.insert(lines, line)
    end

    file.close()
    return lines
end

function script.pause()
    textViewer.cprint(loc["script.pause"], colors.orange)
    dfpwmPlayer.playConfirmationSound()
    write("")
    local _ = read()
end

function script.confirmation()
    textViewer.cprint(loc["script.confirmation"], colors.orange)
    dfpwmPlayer.playConfirmationSound()
    while true do
        write("? ")
        local confirmation = read()
        if confirmation == loc["script.yes"] then
            return true
        elseif confirmation == loc["script.no"] then
            return false
        end
    end
end

function script.parse(commands)
    local parsed = {}

    for _, command in ipairs(commands) do
        if command ~= "" and not command:match("^#") then
            if command:match("^@") then
                local directive, args = command:match("^@(%S+)%s*(.*)$")

                table.insert(parsed, {
                    type = "directive",
                    name = directive,
                    args = args
                })
            else
                table.insert(parsed, {
                    type = "command",
                    value = command
                })
            end
        end
    end

    return parsed
end

local function table_contains(tbl, x)
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

local function tokenize(expr)
    local tokens = {}
    local i = 1

    while i <= #expr do
        local c = expr:sub(i, i)

        if c:match("[%+%-%*/%%]") then
            table.insert(tokens, c)
            i = i + 1
        elseif c:match("[%d%.]") then
            local num = c
            i = i + 1

            while i <= #expr and expr:sub(i, i):match("[%d%.]") do
                num = num .. expr:sub(i, i)
                i = i + 1
            end

            table.insert(tokens, num)
        else
            i = i + 1
        end
    end

    return tokens
end

local function calculate(tokens)
    local working = {}

    for i = 1, #tokens do
        working[i] = tokens[i]
    end

    local function applyOperators(operators)
        local i = 1

        while i <= #working do
            local token = working[i]

            if table_contains(operators, token) then
                local left = tonumber(working[i - 1])
                local right = tonumber(working[i + 1])

                if not left or not right then
                    textViewer.eout(loc["error.invalidExpression"])
                    return
                end

                local result

                if token == "*" then
                    result = left * right
                elseif token == "/" then
                    result = left / right
                elseif token == "+" then
                    result = left + right
                elseif token == "-" then
                    result = left - right
                elseif token == "%" then
                    result = left % right
                end

                table.remove(working, i + 1)
                table.remove(working, i)
                working[i - 1] = tostring(result)

                i = 1
            else
                i = i + 1
            end
        end
    end

    applyOperators({"*", "/", "%"})
    applyOperators({"+", "-"})

    if #working ~= 1 then
        textViewer.eout(loc["error.invalidExpression"])
        return
    end

    return tonumber(working[1])
end

function script.run(parsed, dossier)
    local computerName = os.getComputerLabel()
    if not computerName then
        computerName = os.getComputerID()
    end
    local variables = {
        ["_OSVERSION"] = textViewer.getVer(),
        ["_EXECDATE"] = textutils.formatTime(os.time("local"), true),
        ["_CURDIR"] = dossier,
        ["_COMPUTERNAME"] = computerName,
        ["_COMPUTERID"] = os.getComputerID()
    }
    local silent = false
    local lineCounter = 0

    for _, instruction in ipairs(parsed) do
        if instruction.type == "directive" then
            if instruction.name == "silent" then
                silent = true
            elseif instruction.name == "loud" then
                silent = false
            elseif instruction.name == "stop" then
                return
            elseif instruction.name == "pause" then
                script.pause()
            elseif instruction.name == "confirm" then
                if not script.confirmation() then
                    return
                end
            elseif instruction.name == "set" then
                local name, type_, value = instruction.args:match("^(%S+):(%S+)=(.+)$")
                if type_ == "int" then
                    variables[name] = tonumber(value)
                elseif type_ == "str" then
                    variables[name] = value
                else
                    textViewer.eout(loc["error.unspecified"] .. " Line:" .. lineCounter .. " Syntax:@set VARNAME:VARTYPE=VARVALUE")
                end
            elseif instruction.name == "calc" then
                local name, type_, expression = instruction.args:match("^(%S+):(%S+)=(.+)$")
                expression = expression:gsub("%%([%w_]+)%%", function(var)
                        return variables[var] or ("%" .. var .. "%")
                    end
                )
                if type_ == "int" then
                    local tokens = tokenize(expression)
                    variables[name] = calculate(tokens)
                else
                    textViewer.eout(loc["error.unspecified"] .. " Line:" .. lineCounter .. " Syntax:@calc VARNAME:int=EXPRESSION")
                end
            elseif instruction.name == "input" then
                local name, type_ = instruction.args:match("^(%S+):(%S+)$")
                write("> ")
                if type_ == "int" then
                    variables[name] = tonumber(read())
                elseif type_ == "str" then
                    variables[name] = read()
                else
                    textViewer.eout(loc["error.unspecified"] .. " Line:" .. lineCounter .. " Syntax:@input VARNAME:VARTYPE")
                end
            elseif instruction.name == "minver" then
                local version = instruction.args
                if not update.appCheck(version) then
                    return
                end
            end
        elseif instruction.type == "command" then
            local cmd = instruction.value:gsub("%%([%w_]+)%%", function(var)
                    return tostring(
                        variables[var] or ("%" .. var .. "%")
                    )
                end
            )

            if not silent then
                print("> " .. cmd)
            end

            FrOS.executeLine(cmd)
        end
        lineCounter = lineCounter + 1
    end
end

-- function script.preExecute(commands)
--     local silentScript = false
--     local messages = {}
--     local actions = {}
--     local variables = {}
--     local idx = 1
--     local lineCounter = 0

--     if not commands then
--       return actions, messages
--     end

--     for i = 1, #commands do
--         local command = commands[i]

--         if command ~= "" and not command:match("^#") then
--             if command:match("^@") then
--                 local directive, args = command:match("^@(%S+)%s*(.*)$")
--                 if directive == "silent" then
--                     silentScript = true
--                 elseif directive == "loud" then
--                     silentScript = false
--                 elseif directive == "stop" then
--                     return actions, messages
--                 elseif directive == "pause" then
--                     script.pause()
--                 elseif directive == "confirm" then
--                     script.confirmation()
--                 elseif directive == "set" then
--                     if not args then
--                         textViewer.eout(loc["error.unspecified"] .. " Line:" .. lineCounter .. " Syntax:@set VARNAME:VARTYPE=VARVALUE")
--                         return
--                     end

--                     local varName, varType, varValue = args:match("^(%S+):(%S+)=(.+)$")
--                     if not varName or not varType or not varValue then
--                         textViewer.eout(loc["error.unspecified"] .. " Line:" .. lineCounter .. " Syntax:@set VARNAME:VARTYPE=VARVALUE")
--                         return
--                     end

--                     local varTypes = {
--                         ["int"] = "int",
--                         ["str"] = "string",
--                     }
--                     if table_contains_key(varTypes, varType) then
--                         if varTypes[varType] == "int" then
--                             variables[varName] = int(varValue)
--                         elseif varTypes[varType] == "string" then
--                             variables[varName] = varValue
--                         end
--                     else
--                         textViewer.eout(loc["error.unspecified"] .. " Line:" .. lineCounter .. " Syntax:@set VARNAME:VARTYPE=VARVALUE")
--                         return
--                     end
--                 end -- https://chatgpt.com/c/69ff2309-0bcc-832a-a721-7807fb7a3398
--             else
--                 if not silentScript then
--                     table.insert(messages, idx, "> " .. command)
--                 end
--                 local command = command:gsub("%%(.-)%%", function(var)
--                     return tostring(variables[var] or ("%" .. var .. "%"))
--                 end)
--                 table.insert(actions, idx, command)
--                 idx = idx + 1
--             end
--         end
--         lineCounter = lineCounter + 1
--     end

--     return actions, messages
-- end

return script