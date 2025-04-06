local statusBar = {}

local clock

function statusBar.draw(dossier)
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(string.format("%-45s %5s","Dossier actuel : " .. dossier, clock))
    term.setBackgroundColor(colors.black)
end

function statusBar.clock()
    clock = textutils.formatTime(os.time(), true)
    return clock
end

return statusBar