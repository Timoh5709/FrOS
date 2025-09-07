local statusBar = {}
local clock
local lines = 0

local function getLinesUsed()
    local _, y = term.getCursorPos()
    return y
end

function statusBar.draw(dossier)
    clock = textutils.formatTime(os.time("local"), true)
    lines = getLinesUsed()
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clearLine()
    local _, ending = string.find(dossier, ".lua")
    if ending == #dossier then
        term.write("> " .. dossier)
    else
        term.write("/" .. dossier)
    end
    local w, _ = term.getSize()
    term.setCursorPos(w - #clock + 1, 1)
    term.write(clock)
    term.setBackgroundColor(colors.black)
    term.setCursorPos(string.len(dossier) + 3, lines)
end

return statusBar