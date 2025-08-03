local function readAll(path)
  local file = fs.open(path, "r")
  if not file then error("Erreur : Ne peut pas ouvrir : " .. path) end
  local data = file.readAll()
  file.close()
  return data
end

local function writeAll(path, data)
  local file = fs.open(path, "w")
  if not file then error("Erreur : Ne peut pas ouvrir : " .. path) end
  file.write(data)
  file.close()
end

local function intToBytes(code)
  local b1 = math.floor(code / (256^3)) % 256
  local b2 = math.floor(code / (256^2)) % 256
  local b3 = math.floor(code / 256) % 256
  local b4 = code % 256
  return string.char(b1, b2, b3, b4)
end

local function bytesToInt(b1, b2, b3, b4)
  return ((b1 * 256 + b2) * 256 + b3) * 256 + b4
end

local function compress(input)
  local dict = {}
  for i = 0, 255 do dict[string.char(i)] = i end

  local nextCode = 256
  local w = ""
  local outputCodes = {}

  for i = 1, #input do
    local c = input:sub(i, i)
    local wc = w .. c
    if dict[wc] then
      w = wc
    else
      table.insert(outputCodes, dict[w])
      dict[wc] = nextCode
      nextCode = nextCode + 1
      w = c
    end
  end
  if #w > 0 then table.insert(outputCodes, dict[w]) end

  local out = {}
  for _, code in ipairs(outputCodes) do
    out[#out+1] = intToBytes(code)
  end
  return table.concat(out)
end

local function decompress(data)
  local dict = {}
  for i = 0, 255 do dict[i] = string.char(i) end

  local nextCode = 256
  local codes = {}
  for i = 1, #data, 4 do
    local b1, b2, b3, b4 = data:byte(i, i+3)
    codes[#codes+1] = bytesToInt(b1, b2, b3, b4)
  end

  local result = {}
  local prev = dict[codes[1]]
  result[#result+1] = prev

  for i = 2, #codes do
    local currCode = codes[i]
    local entry = dict[currCode]
    if not entry then
      entry = prev .. prev:sub(1,1)
    end
    result[#result+1] = entry

    dict[nextCode] = prev .. entry:sub(1,1)
    nextCode = nextCode + 1

    prev = entry
  end
  return table.concat(result)
end

local args = {...}
if #args < 3 then
  print("Utilisation : -c OU -d input output")
  return
end

local mode, inPath, outPath = args[1], args[2], args[3]
if mode == "-c" then
  print("Compresse " .. inPath .. " -> " .. outPath)
  local input = readAll(inPath)
  local compressed = compress(input)
  writeAll(outPath, compressed)
  print("Fait.")
elseif mode == "-d" then
  print("Décompresse " .. inPath .. " -> " .. outPath)
  local input = readAll(inPath)
  local decompressed = decompress(input)
  writeAll(outPath, decompressed)
  print("Fait.")
else
  error("Erreur : Mode inconnu " .. mode)
end