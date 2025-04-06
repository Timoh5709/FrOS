local statusBar = {}
local clock = textutils.formatTime(os.time("local"), true)

function statusBar.draw(dossier)
    if textutils.formatTime(os.time("local"), true) ~= clock then
        term.setCursorPos(1, 1)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.white)
        term.clearLine()
        term.write(string.format("%-45s %5s","Dossier actuel : " .. dossier, textutils.formatTime(os.time("local"), true)))
        term.setBackgroundColor(colors.black)
    end
end

return statusBar