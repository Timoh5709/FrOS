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

function textViewer.eout(text)
  textViewer.cprint(text, colors.red)
end

function textViewer.lineViewer(lines)
  local _, height = term.getSize()
  local currentIndex = 1
  local maxIndex = #lines
  local pageSize = height - 5

  while true do
    term.clear()
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