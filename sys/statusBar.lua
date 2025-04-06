local statusBar = {}

function statusBar.draw(dossier)
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(string.format("%-45s %5s","Dossier actuel : " .. dossier, textutils.formatTime(os.time(), true)))
    term.setBackgroundColor(colors.black)
end

return statusBar