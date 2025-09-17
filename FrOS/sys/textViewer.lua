local statusBar = require("/FrOS/sys/statusBar")
local textViewer = {}

function textViewer.cprint(text, color)
  if not color then
    print(text)
  else
    local prev = term.getTextColor()
    term.setTextColor(color)
    print(text)
    term.setTextColor(prev)
  end
end

function textViewer.eout(text)
  textViewer.cprint(text, colors.red)
end

local function wrapLine(line, width)
  local res, current = {}, ""

  for token in string.gmatch(line, "([%S]+[%s]*)") do
    if token:find("\n") then
      if current ~= "" then
        table.insert(res, current)
        current = ""
      end
      for _ in token:gmatch("\n") do
        table.insert(res, "")
      end
    else
      if #current + #token <= width then
        current = current .. token
      else
        table.insert(res, current)
        current = token
      end
    end
  end

  if current ~= "" then
    table.insert(res, current)
  end

  return res
end

function textViewer.lineViewer(lines)
  local width, height = term.getSize()
  local currentIndex = 1
  local pageSize = height - 5

  local wrapLines = {}
  for _, line in ipairs(lines) do
    local parts = wrapLine(line, width)
    for _, part in ipairs(parts) do
      table.insert(wrapLines, part)
    end
  end

  lines = wrapLines
  local maxIndex = #lines

  while true do
    term.clear()
    local dossier = "textViewer.lua"
    statusBar.draw(dossier)
    term.setCursorPos(1, 2)

    for i = currentIndex, math.min(currentIndex + pageSize - 1, maxIndex) do
      print(lines[i])
    end

    if currentIndex + pageSize <= maxIndex then
      print("\n-- [PG HAUT/BAS] | [Q]uitter --")
    else
      print("\n-- Fin du texte | [PG HAUT/BAS] | [Q]uitter --")
    end

    local event, key = os.pullEvent("key")
    if key == keys.pageDown then
      if currentIndex + pageSize <= maxIndex then
        currentIndex = currentIndex + pageSize
      end
    elseif key == keys.pageUp then
      if currentIndex - pageSize > 0 then
        currentIndex = currentIndex - pageSize
      else
        currentIndex = 1
      end
    elseif key == keys.q then
      break
    end
  end
end

function textViewer.getVer()
  local file = "FrOS/version.txt"
  local handle = fs.open(file, "r")
  if not handle then
    textViewer.eout("Erreur : Fichier 'FrOS/version.txt' illisible.")
    return
  end
  local ver = handle.readAll()
  handle.close()
  return ver
end

return textViewer