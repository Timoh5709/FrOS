-- @fullscreen
--
-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe & 2026 FrOS' team
--
-- SPDX-License-Identifier: LicenseRef-CCPL

local textViewer = require("/FrOS/sys/textViewer")
local update = require("/FrOS/sys/update")
local running = update.appCheck(0.82)
if running == false then
    return
end
local httpViewer = require("/FrOS/sys/httpViewer")
if not fs.exists("FrOS/localization/notes.loc") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/notes.loc")
end
local locLua = require("/FrOS/sys/loc")
local theme = require("/FrOS/sys/theme")
local stg = _G.FrOS.stg
local language = "FR"
language = stg["language"]
local loc = locLua.load("FrOS/localization/notes.loc", language)
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end

local args = { ... }
local filename
local isNoFN = #args == 0
if isNoFN then
    filename = loc["untitled.name"]
else
    filename = args[1]
end

local path = shell.resolve(filename)
local isROnly = fs.isReadOnly(path)
if fs.exists(path) and fs.isDir(path) then
    print("Cannot edit a directory.")
    return
end

if not fs.exists(path) and not string.find(path, "%.") then
    local extension = stg["defaultTextExt"]
    if extension ~= "" and type(extension) == "string" then
        path = path .. "." .. extension
    end
end

local x, y = 1, 1
local w, h = term.getSize()
local scrollX, scrollY = 0, 0

local lines = {}

local bgcolor, textcolor = theme.refresh()
local highlightcolor, errorcolor = colors.yellow, colors.red

local isMenu = false
local idMenuItem = 1
local menuItems = {}
local function refreshMenuItems()
    menuItems = {}
    table.insert(menuItems, loc["menuItems.new"])
    table.insert(menuItems, loc["menuItems.open"])
    if not isROnly then
        table.insert(menuItems, loc["menuItems.save"])
    end
    if peripheral.find("printer") then
        table.insert(menuItems, loc["menuItems.print"])
    end
    table.insert(menuItems, loc["menuItems.exit"])
    
    if idMenuItem > #menuItems then
        idMenuItem = 1
    end
end

refreshMenuItems()

local function promptUser(promptText, defaultText)
    term.setCursorPos(1, h)
    term.clearLine()
    term.setTextColor(highlightcolor)
    term.write(promptText)
    term.setTextColor(textcolor)
    
    term.setCursorBlink(true)
    
    local input = read(nil, nil, nil, defaultText)
    
    term.setCursorBlink(false)
    return input
end

local status_ok, status_text
local function set_status(text, ok)
    status_ok = ok ~= false
    status_text = text
end

if not isROnly and fs.getFreeSpace(path) < 1024 then
    set_status(loc["error.lowSpace"], false)
else
    local message
    if term.isColor() then
        message = loc["status.clickable"]
    else
        message = loc["status.normal"]
    end

    if #message > w - 5 then
        message = loc["status.short"]
    end

    set_status(message)
end

local function load(_path)
    lines = {}
    if fs.exists(_path) then
        local file = io.open(_path, "r")
        local ligne = file:read()
        while ligne do
            table.insert(lines, ligne)
            ligne = file:read()
        end
        file:close()
    end

    if #lines == 0 then
        table.insert(lines, "")
    end
end

local function save(_path, _write)
    local dir = _path:sub(1, _path:len() - fs.getName(_path):len())
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end

    local file, fileerr
    local function innerSave()
        file, fileerr = fs.open(_path, "w")
        if file then
            if file then
                _write(file)
            end
        else
            textViewer.eout(loc["error.unknownUnreadableFile"] .. " (" .. _path .. ")")
        end
    end

    local ok, err = pcall(innerSave)
    if file then
        file.close()
    end
    return ok, err, fileerr
end

local function redrawText()
    for y = 1, h - 1 do
        term.setCursorPos(1 - scrollX, y)
        term.clearLine()

        local ligne = lines[y + scrollY]
        if ligne ~= nil then
            print(ligne)
        end
    end
    term.setCursorPos(x - scrollX, y - scrollY)
end

local function redrawLine(_y)
    local ligne = lines[_y]
    if ligne then
        term.setCursorPos(1 - scrollX, _y - scrollY)
        term.clearLine()
        print(ligne)
        term.setCursorPos(x - scrollX, _y - scrollY)
    end
end

local function redrawMenu()
    term.setCursorPos(1, h)
    term.clearLine()

    term.setCursorPos(w - #(x .. "/" .. y) + 1, h)
    term.setTextColor(textcolor)
    term.write(x .. "/" .. y)

    term.setCursorPos(1, h)
    if isMenu then
        term.setTextColor(textcolor)
        for idx, item in pairs(menuItems) do
            if idx == idMenuItem then
                term.setTextColor(highlightcolor)
                term.write("[")
                term.setTextColor(textcolor)
                term.write(item)
                term.setTextColor(highlightcolor)
                term.write("]")
                term.setTextColor(textcolor)
            else
                term.write(" " .. item .. " ")
            end
        end
    else
        term.setTextColor(status_ok and highlightcolor or errorcolor)
        term.write(status_text)
        term.setTextColor(textcolor)
    end

    term.setCursorPos(x - scrollX, y - scrollY)
end

local menuFunctions = {
    [loc["menuItems.save"]] = function()
        if isNoFN then
            local input = promptUser(loc["prompt.saveAs"], path)
            if input and input ~= "" then
                path = shell.resolve(input)
                isROnly = fs.isReadOnly(path)
                isNoFN = false
                refreshMenuItems()
            else
                set_status(loc["prompt.cancelled"], false)
                redrawText()
                redrawMenu()
                return
            end
        end
        if isROnly then
            set_status(loc["error.noAccess"], false)
        else
            local ok, _, fileerr  = save(path, function(file)
                for _, ligne in ipairs(lines) do
                    file.write(ligne .. "\n")
                end
            end)
            if ok then
                set_status(loc["menuFunctions.saved"] .. path)
            else
                if fileerr then
                    set_status(loc["error.error"] .. fileerr, false)
                else
                    set_status(loc["error.corruptedFile"] .. path, false)
                end
            end
        end
        redrawMenu()
    end,
    [loc["menuItems.new"]] = function()
        local input = promptUser(loc["prompt.newFile"], loc["untitled.name"])
        if not input or input == "" then
            set_status(loc["prompt.cancelled"])
            redrawText()
            redrawMenu()
            return
        end
        path = shell.resolve(input)
        isROnly = fs.isReadOnly(path)
        isNoFN = false
        lines = {""}
        x, y = 1, 1
        scrollX, scrollY = 0, 0

        refreshMenuItems()
        set_status(loc["menuFunctions.new"] .. fs.getName(path))
        redrawText()
        redrawMenu()
    end,
    [loc["menuItems.open"]] = function()
        local input = promptUser(loc["prompt.openFile"], "")
        if not input or input == "" then
            set_status(loc["prompt.cancelled"])
            redrawText()
            redrawMenu()
            return
        end
        local targetPath = shell.resolve(input)
        if fs.exists(targetPath) and fs.isDir(targetPath) then
            set_status(loc["error.isDirNotFile"], false)
            redrawMenu()
            return
        end
        path = targetPath
        isROnly = fs.isReadOnly(path)
        isNoFN = false

        load(path)
        x, y = 1, 1
        scrollX, scrollY = 0, 0

        refreshMenuItems()
        set_status(loc["menuFunctions.opened"] .. fs.getName(path))

        redrawText()
        redrawMenu()
    end,
    [loc["menuItems.print"]] = function()
        local printer = peripheral.find("printer")
        if not printer then
            set_status(loc["error.noPrinter"], false)
            return
        end

        local idPage = 0
        local name = fs.getName(path)
        if printer.getInkLevel() < 1 then
            set_status(loc["error.noInk"], false)
            return
        elseif printer.getPaperLevel() < 1 then
            set_status(loc["error.noPaper"], false)
            return
        end

        local screenTerminal = term.current()
        local printerTerminal = {
            getCursorPos = printer.getCursorPos,
            setCursorPos = printer.setCursorPos,
            getSize = printer.getPageSize,
            write = printer.write,
        }
        printerTerminal.scroll = function()
            if idPage == 1 then
                printer.setPageTitle(name .. loc["print.pageID"] .. idPage .. ")")
            end

            while not printer.newPage() do
                if printer.getInkLevel() < 1 then
                    set_status(loc["error.noInk"] .. loc["error.pleaseRefill"], false)
                elseif printer.getPaperLevel() < 1 then
                    set_status(loc["error.noPaper"] .. loc["error.pleaseRefill"], false)
                else
                    set_status(loc["error.outputFull"] .. loc["error.pleaseEmpty"], false)
                end

                term.redirect(screenTerminal)
                redrawMenu()
                term.redirect(printerTerminal)

                sleep(0.5)
            end

            idPage = idPage + 1
            if idPage == 1 then
                printer.setPageTitle(name)
            else
                printer.setPageTitle(name .. loc["print.pageID"] .. idPage .. ")")
            end
        end

        isMenu = false
        term.redirect(printerTerminal)
        local ok, error = pcall(function()
            term.scroll()
            for _, ligne in ipairs(lines) do
                print(ligne)
            end
        end)
        term.redirect(screenTerminal)
        if not ok then
            print(error)
        end

        while not printer.endPage() do
            set_status(loc["error.outputFull"] .. loc["error.pleaseEmpty"])
            redrawMenu()
            sleep(0.5)
        end
        isMenu = true

        if idPage > 1 then
            set_status(loc["print.printed1"] .. idPage .. loc["print.printed2a"])
        else
            set_status(loc["print.printed1"] .. idPage .. loc["print.printed2b"])
        end
        redrawMenu()
    end,
    [loc["menuItems.exit"]] = function()
        running = false
    end
}

local function doMenuItem(_n)
    menuFunctions[menuItems[_n]]()
    if isMenu then
        isMenu = false
        term.setCursorBlink(true)
    end
    redrawMenu()
end

local function setCursor(newX, newY)
    local _, oldY = x, y
    x, y = newX, newY
    local screenX = x - scrollX
    local screenY = y - scrollY

    local isRedrawNeeded = false
    if screenX < 1 then
        scrollX = x - 1
        screenX = 1
        isRedrawNeeded = true
    elseif screenX > w then
        scrollX = x - w
        screenX = w
        isRedrawNeeded = true
    end

    if screenY < 1 then
        scrollY = y - 1
        screenY = 1
        isRedrawNeeded = true
    elseif screenY > h - 1 then
        scrollY = y - (h - 1)
        screenY = h - 1
        isRedrawNeeded = true
    end

    if isRedrawNeeded then
        redrawText()
    elseif y ~= oldY then
        redrawLine(oldY)
        redrawLine(y)
    else
        redrawLine(y)
    end
    term.setCursorPos(screenX, screenY)

    redrawMenu()
end

load(path)

term.setBackgroundColor(bgcolor)
term.clear()
term.setCursorPos(x, y)
term.setCursorBlink(true)

redrawText()
redrawMenu()

while running do
    local event, param, param2, param3 = os.pullEvent()
    if event == "key" then
        if param == keys.up then
            if not isMenu then
                if y > 1 then
                    setCursor(math.min(x, #lines[y - 1] + 1), y - 1)
                end
            end

        elseif param == keys.down then
            if not isMenu then
                if y < #lines then
                    setCursor(math.min(x, #lines[y + 1] + 1), y + 1)
                end
            end

        elseif param == keys.tab then
            if not isMenu and not isROnly then
                local ligne = lines[y]
                lines[y] = string.sub(ligne, 1, x - 1) .. "    " .. string.sub(ligne, x)
                setCursor(x + 4, y)
            end

        elseif param == keys.pageUp then
            if not isMenu then
                local newY
                if y - (h - 1) >= 1 then
                    newY = y - (h - 1)
                else
                    newY = 1
                end
                setCursor(math.min(x, #lines[newY] + 1), newY)
            end

        elseif param == keys.pageDown then
            if not isMenu then
                local newY
                if y + (h - 1) <= #lines then
                    newY = y + (h - 1)
                else
                    newY = #lines
                end
                local newX = math.min(x, #lines[newY] + 1)
                setCursor(newX, newY)
            end

        elseif param == keys.home then
            if not isMenu then
                if x > 1 then
                    setCursor(1, y)
                end
            end

        elseif param == keys["end"] then
            if not isMenu then
                local nLimit = #lines[y] + 1
                if x < nLimit then
                    setCursor(nLimit, y)
                end
            end

        elseif param == keys.left then
            if not isMenu then
                if x > 1 then
                    setCursor(x - 1, y)
                elseif x == 1 and y > 1 then
                    setCursor(#lines[y - 1] + 1, y - 1)
                end
            else
                idMenuItem = idMenuItem - 1
                if idMenuItem < 1 then
                    idMenuItem = #menuItems
                end
                redrawMenu()
            end

        elseif param == keys.right then
            if not isMenu then
                local nLimit = #lines[y] + 1
                if x < nLimit then
                    setCursor(x + 1, y)
                elseif x == nLimit and y < #lines then
                    setCursor(1, y + 1)
                end
            else
                idMenuItem = idMenuItem + 1
                if idMenuItem > #menuItems then
                    idMenuItem = 1
                end
                redrawMenu()
            end

        elseif param == keys.delete then
            if not isMenu and not isROnly then
                local nLimit = #lines[y] + 1
                if x < nLimit then
                    local ligne = lines[y]
                    lines[y] = string.sub(ligne, 1, x - 1) .. string.sub(ligne, x + 1)
                    redrawLine(y)
                elseif y < #lines then
                    lines[y] = lines[y] .. lines[y + 1]
                    table.remove(lines, y + 1)
                    redrawText()
                end
            end

        elseif param == keys.backspace then
            if not isMenu and not isROnly then
                if x > 1 then
                    local ligne = lines[y]
                    if x > 4 and string.sub(ligne, x - 4, x - 1) == "    " and not string.sub(ligne, 1, x - 1):find("%S") then
                        lines[y] = string.sub(ligne, 1, x - 5) .. string.sub(ligne, x)
                        setCursor(x - 4, y)
                    else
                        lines[y] = string.sub(ligne, 1, x - 2) .. string.sub(ligne, x)
                        setCursor(x - 1, y)
                    end
                elseif y > 1 then
                    local sPrevLen = #lines[y - 1]
                    lines[y - 1] = lines[y - 1] .. lines[y]
                    table.remove(lines, y)
                    setCursor(sPrevLen + 1, y - 1)
                    redrawText()
                end
            end

        elseif param == keys.enter or param == keys.numPadEnter then
            if not isMenu and not isROnly then
                local ligne = lines[y]
                local _, spaces = string.find(ligne, "^[ ]+")
                if not spaces then
                    spaces = 0
                end
                lines[y] = string.sub(ligne, 1, x - 1)
                table.insert(lines, y + 1, string.rep(' ', spaces) .. string.sub(ligne, x))
                setCursor(spaces + 1, y + 1)
                redrawText()

            elseif isMenu then
                doMenuItem(idMenuItem)

            end

        elseif param == keys.leftCtrl or param == keys.rightCtrl then
            isMenu = not isMenu
            if isMenu then
                term.setCursorBlink(false)
            else
                term.setCursorBlink(true)
            end
            redrawMenu()
        elseif param == keys.rightAlt then
            if isMenu then
                isMenu = false
                term.setCursorBlink(true)
                redrawMenu()
            end
        end

    elseif event == "char" then
        if not isMenu and not isROnly then
            local ligne = lines[y]
            lines[y] = string.sub(ligne, 1, x - 1) .. param .. string.sub(ligne, x)
            setCursor(x + 1, y)

        elseif isMenu then
            for i, menuItem in ipairs(menuItems) do
                if string.lower(string.sub(menuItem, 1, 1)) == string.lower(param) then
                    doMenuItem(i)
                    break
                end
            end
        end

    elseif event == "paste" then
        if not isROnly then
            if isMenu then
                isMenu = false
                term.setCursorBlink(true)
                redrawMenu()
            end
            local ligne = lines[y]
            lines[y] = string.sub(ligne, 1, x - 1) .. param .. string.sub(ligne, x)
            setCursor(x + #param , y)
        end

    elseif event == "mouse_click" then
        local cx, cy = param2, param3
        if not isMenu then
            if param == 1 then
                if cy < h then
                    local newY = math.min(math.max(scrollY + cy - 1, 1), #lines)
                    local newX = math.min(math.max(scrollX + cx, 1), #lines[newY] + 1)
                    setCursor(newX, newY)
                else
                    isMenu = true
                    redrawMenu()
                end
            end
        else
            if cy == h then
                local endPosMenu = 1
                local startPosMenu = 1
                for i, menuItem in ipairs(menuItems) do
                    endPosMenu = endPosMenu + #menuItem + 1
                    if cx > startPosMenu and cx < endPosMenu then
                        doMenuItem(i)
                    end
                    endPosMenu = endPosMenu + 1
                    startPosMenu = endPosMenu
                end
            else
                isMenu = false
                term.setCursorBlink(true)
                redrawMenu()
            end
        end

    elseif event == "mouse_scroll" then
        if not isMenu then
            if param == -1 then
                if scrollY > 0 then
                    scrollY = scrollY - 1
                    redrawText()
                end

            elseif param == 1 then
                local nMaxScroll = #lines - (h - 1)
                if scrollY < nMaxScroll then
                    scrollY = scrollY + 1
                    redrawText()
                end

            end
        end

    elseif event == "term_resize" then
        w, h = term.getSize()
        setCursor(x, y)
        redrawMenu()
        redrawText()

    end
end

term.clear()
term.setCursorBlink(false)
term.setCursorPos(1, 1)