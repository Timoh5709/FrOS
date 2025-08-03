local statusBar = {}
local clock
local lines = 0

local function getLinesUsed()
    local _, y = term.getCursorPos()
    return y
end

function statusBar.draw(dossier)
    if textutils.formatTime(os.time("local"), true) ~= clock then
        lines = getLinesUsed()
        term.setCursorPos(1, 1)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.white)
        term.clearLine()
        term.write(string.format("%-45s %5s","Dossier actuel : " .. dossier, textutils.formatTime(os.time("local"), true)))
        term.setBackgroundColor(colors.black)
        term.setCursorPos(string.len(dossier) + 3, lines)
    end
end

return statusBar