local update = require("/FrOS/sys/update")
local running = update.appCheck(0.73)
if not running then
    return
end
local httpViewer = require("/FrOS/sys/httpViewer")
if not fs.exists("FrOS/localization/neofetch.loc") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/neofetch.loc")
end
local locLua = require("/FrOS/sys/loc")
local stg = _G.FrOS.stg
local language = "FR"
language = stg["language"]
local loc = locLua.load("FrOS/localization/neofetch.loc", language)
local gfrx = require("/FrOS/sys/gfrx")
local textViewer = require("/FrOS/sys/textViewer")
local gfx = gfrx(nil, {buffered = true, oldColorSystem = true})
print()
local _, y = term.getCursorPos()
local _, h = term.getSize()
y = (y - 1) * 3
h = (h - 1) * 3
if y + 40 > h then
    y = h - 39
end

for i=1,13 do print() end

local buf1 = gfx:addBuffer(colors.green, colors.black)
local buf2 = gfx:addBuffer(colors.red, colors.black)
gfx:unmarkAllDirty()

gfx:useBuffer(buf1)
gfx:drawCircle(26, y + 25, 10, true, true)

gfx:useBuffer(buf2)
gfx:drawTriangle(1,y, 51,y, 26,y + 25, true, true)
gfx:flush()

y = y / 3 + 1
term.setCursorPos(27, y)
term.setTextColor(colors.blue)
write(loc["neofetch.os"])
term.setTextColor(colors.white)
write("FrOS " .. textViewer.getVer())
term.setCursorPos(27, y + 1)
term.setTextColor(colors.blue)
write(loc["neofetch.name"])
term.setTextColor(colors.white)
local name = os.getComputerLabel()
if name then
    write(name)
else
    write("FrOS-" .. os.getComputerID())
end
term.setCursorPos(27, y + 2)
term.setTextColor(colors.blue)
write(loc["neofetch.freeSpace"])
term.setTextColor(colors.white)
local freeSpace = fs.getFreeSpace(shell.dir()) or 0
if math.floor(freeSpace / 1024) < 10000 then
        write((math.floor(freeSpace / 1024 * 100) / 100) .. " Ko")
    else
        write((math.floor(freeSpace / 1048576 * 100) / 100) .. " Mo")
end
term.setCursorPos(27, y + 3)
term.setTextColor(colors.blue)
write(loc["neofetch.clock"])
term.setTextColor(colors.white)
write(textutils.formatTime(os.time("local"), true))
term.setCursorPos(1, y + 12)