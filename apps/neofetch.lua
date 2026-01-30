local update = require("/FrOS/sys/update")
local running = update.appCheck(0.7)
if not running then
    return
end
local httpViewer = require("/FrOS/sys/httpViewer")
if not fs.exists("FrOS/localization/neofetch.loc") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/neofetch.loc")
end
local locLua = require("/FrOS/sys/loc")
loc = locLua.load("FrOS/localization/neofetch.loc", "FR")
local gfrx = require("/FrOS/sys/gfrx")
local textViewer = require("/FrOS/sys/textViewer")
local gfx = gfrx(nil, {buffered = true})

print()
local _, y = term.getCursorPos()
local _, h = term.getSize()
y = y * 3
h = h * 3
if y + 40 > h then
    y = h - 39
end

local buf1 = gfx:addBuffer(colors.green, colors.black)
gfx:useBuffer(buf1)
gfx:drawCircle(26, y + 25, 10, true, true)

local buf2 = gfx:addBuffer(colors.red, colors.black)
gfx:useBuffer(buf2)
gfx:drawTriangle(1,y, 51,y, 26,y + 25, true, true)
gfx:flush()

y = y / 3
term.setCursorPos(27, y + 1)
term.setTextColor(colors.blue)
write(loc["neofetch.os"])
term.setTextColor(colors.white)
write("FrOS " .. textViewer.getVer())
term.setCursorPos(27, y + 2)
term.setTextColor(colors.blue)
write(loc["neofetch.name"])
term.setTextColor(colors.white)
write(os.getComputerLabel())
term.setCursorPos(27, y + 3)
term.setTextColor(colors.blue)
write(loc["neofetch.freeSpace"])
term.setTextColor(colors.white)
local freeSpace = fs.getFreeSpace(shell.dir()) or 0
if math.floor(freeSpace / 1024) < 10000 then
        write((math.floor(freeSpace / 1024 * 100) / 100) .. " Ko")
    else
        write((math.floor(freeSpace / 1048576 * 100) / 100) .. " Mo")
end
term.setCursorPos(27, y + 4)
term.setTextColor(colors.blue)
write(loc["neofetch.clock"])
term.setTextColor(colors.white)
write(textutils.formatTime(os.time("local"), true))
term.setCursorPos(1, y + 13)