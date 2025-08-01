textViewer = require("/sys/textViewer")
httpViewer = require("/sys/httpViewer")
local appListUrl = "https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/appList.txt"
local lignes = httpViewer.getLines(appListUrl)
local running = true
term.clear()

local function main()
    textViewer.lineViewer(lignes)
end

while running do
    main()
end