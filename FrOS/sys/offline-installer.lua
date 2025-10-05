local bit32 = bit32 or require("bit32")

term.clear()
term.setCursorPos(1,1)

local maj = false
local exBootloader = false
local step = 0

print("Ce programme va bien installer les fichiers pour FrOS.")
print("Veuillez ne pas éteindre votre ordinateur lors de l'installation.")
if fs.exists("/FrOS/boot.lua") then
    while step == 0 do
        print("Voulez-vous mettre à jour ou installer à nouveau ? (maj/install)")
        write("? ")
        local choix = read()
        if choix == "maj" then
            step = step + 2
            maj = true
            exBootloader = false
        elseif choix == "install" then
            step = step + 1
            maj = false
        end
    end
else
    step = step + 1
end
while step == 1 do
    print("Utilisez-vous un bootloader ? (oui/non)")
    write("? ")
    local choix = read()
    if choix == "oui" then
        step = step + 1
        exBootloader = true
    elseif choix == "non" then
        step = step + 1
        exBootloader = false
    end
end
textutils.slowPrint("-------------------------------------------------")

local crc32_table = {}
for i = 0, 255 do
    local crc = i
    for _ = 1, 8 do
        if bit32.band(crc, 1) ~= 0 then
            crc = bit32.bxor(0xEDB88320, bit32.rshift(crc, 1))
        else
            crc = bit32.rshift(crc, 1)
        end
    end
    crc32_table[i] = crc
end

local function crc32(str)
    local crc = 0xFFFFFFFF
    for i = 1, #str do
        local byte = string.byte(str, i)
        local idx = bit32.band(bit32.bxor(crc, byte), 0xFF)
        crc = bit32.bxor(bit32.rshift(crc, 8), crc32_table[idx])
    end
    return bit32.bnot(crc)
end

local function rle_decompress(data)
    local out = {}
    for i = 1, #data, 2 do
        local count = string.byte(data, i) or 0
        local ch = data:sub(i+1, i+1) or ""
        if count > 0 and ch ~= "" then
            out[#out+1] = ch:rep(count)
        end
    end
    return table.concat(out)
end

local CODE_BITS = 12
local MAX_CODES = 2 ^ CODE_BITS
local INITIAL_DICT_SIZE = 256
local FIRST_AVAILABLE = INITIAL_DICT_SIZE

local function makeBitReader(data)
    local pos = 1
    local buffer = 0
    local bufLen = 0

    local function readBits(n)
        while bufLen < n do
            if pos > #data then return nil end
            local b = string.byte(data, pos)
            pos = pos + 1
            buffer = buffer * 256 + b
            bufLen = bufLen + 8
        end
        local shift = bufLen - n
        local value = math.floor(buffer / (2 ^ shift)) % (2 ^ n)
        buffer = buffer % (2 ^ shift)
        bufLen = shift
        return value
    end

    return readBits
end

local function lzw_decompress(data)
    if not data or #data == 0 then return "" end

    local readBits = makeBitReader(data)

    local dict = {}
    for i = 0, 255 do dict[i] = string.char(i) end
    local dictSize = FIRST_AVAILABLE

    local code = readBits(CODE_BITS)
    if not code then return "" end
    local w = dict[code] or ""
    local out = { w }

    while true do
        local k = readBits(CODE_BITS)
        if not k then break end

        local entry
        if dict[k] then
            entry = dict[k]
        elseif k == dictSize then
            entry = w .. w:sub(1,1)
        else
            print(string.format("LZW décompression : code invalide %d (dictSize=%d)", k, dictSize))
        end

        out[#out+1] = entry

        if dictSize < MAX_CODES then
            dict[dictSize] = w .. entry:sub(1,1)
            dictSize = dictSize + 1
        end

        w = entry
    end

    local result = table.concat(out)
    result = rle_decompress(result)
    return result
end

local function extract_co(archivePath, outDir)
    local f = fs.open(archivePath, "rb")
    local header = f.read(4)
    if header ~= "FZIP" then
        print("Erreur : Archive invalide.")
        return
    end

    local version = f.read(1)
    local fileCount = string.byte(f.read(1))

    for i = 1, fileCount do
        local nameLen = string.unpack(">I2", f.read(2))
        local relPath = f.read(nameLen)

        local flag = string.byte(f.read(1))
        local size = string.unpack(">I4", f.read(4))

        local crc = string.unpack(">I4", f.read(4))
        local data = f.read(size)

        local finalData = (flag == 1) and lzw_decompress(data) or data

        if crc ~= crc32(finalData) then
            print("Erreur : Fichier corrompu : " .. relPath)
        end

        local outPath = fs.combine(outDir, relPath)
        local parentDir = fs.getDir(outPath)
        if not fs.exists(parentDir) then
            fs.makeDir(parentDir)
        end

        local outFile = fs.open(outPath, "wb")
        outFile.write(finalData)
        outFile.close()
    end

    f.close()
    print("Extraction terminée.")
end

local function extract(archivePath, outDir)
    local co = coroutine.create(function (archivePath, outDir)
        extract_co(archivePath, outDir)
    end)
    coroutine.resume(co, archivePath, outDir)
end

local function getVer()
    local file = "FrOS/version.txt"
    local handle = fs.open(file, "r")
    if not handle then
        print("Erreur : Fichier 'FrOS/version.txt' illisible.")
        return
    end
    local ver = handle.readAll()
    handle.close()
    return ver
end

term.setBackgroundColor(colors.blue)
term.clear()
term.setCursorPos(1,1)

extract("disk/fros-offline.fzip", "temp/install")
fs.copy("temp/install/FrOS", "FrOS")
print("Dossier FrOS copié avec succès.")
fs.copy("temp/install/apps", "apps")
print("Dossier apps copié avec succès.")
if not maj then
    local f = fs.open("FrOS/appList.txt", "w")
    if f then
        f.write("apps/appStore.lua\napps/manuel.lua\n")
        f.close()
        print("Fichier FrOS/appList.txt créé avec succès.")
    else
        print("Erreur : Impossible de créer le fichier FrOS/appList.txt.")
    end
    local f = fs.open("FrOS/driversList.txt", "w")
    if f then
        f.close()
        print("Fichier FrOS/driversList.txt créé avec succès.")
    else
        print("Erreur : Impossible de créer le fichier FrOS/driversList.txt.")
    end
    if not exBootloader then
        local f = fs.open("boot.txt", "w")
        if f then
            f.write("CraftOS|rom/startup.lua\nFrOS|FrOS/boot.lua\n")
            f.close()
            print("Fichier boot.txt créé avec succès.")
        else
            print("Erreur : Impossible de créer le fichier boot.txt.")
        end
    end
end
if not exBootloader then
    fs.copy("temp/install/startup.lua", "startup.lua")
end
print("Installation de FrOS version " .. getVer() .. " terminée. Votre ordinateur va redémarrer. Veuillez enlever le disque.")
os.sleep(5)
os.reboot()