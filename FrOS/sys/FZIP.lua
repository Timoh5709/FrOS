local fzip = {}
local textViewer = require("/FrOS/sys/textViewer")
local progressBar = require("/FrOS/sys/progressBar")
local bit32 = bit32 or require("bit32")

local loc = FrOS.sysLoc
for k,v in pairs(FrOS.errorLoc) do loc[k] = v end

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

local function listFilesRecursive(basePath)
    local results = {}

    local function scan(path, rel)
        for _, item in ipairs(fs.list(path)) do
            local fullPath = fs.combine(path, item)
            local relPath = rel and fs.combine(rel, item) or item

            if fs.isDir(fullPath) then
                scan(fullPath, relPath)
            else
                table.insert(results, {abs = fullPath, rel = relPath})
            end
        end
    end

    scan(basePath, nil)
    return results
end

local CODE_BITS = 12
local MAX_CODES = 2 ^ CODE_BITS
local INITIAL_DICT_SIZE = 256
local FIRST_AVAILABLE = INITIAL_DICT_SIZE

local function makeBitWriter()
    local buffer = 0
    local bufLen = 0
    local parts = {}

    local function writeBits(n, value)
        value = value % (2 ^ n)
        buffer = buffer * (2 ^ n) + value
        bufLen = bufLen + n
        while bufLen >= 8 do
            local shift = bufLen - 8
            local byte = math.floor(buffer / (2 ^ shift)) % 256
            parts[#parts+1] = string.char(byte)
            buffer = buffer - byte * (2 ^ shift)
            bufLen = bufLen - 8
        end
    end

    local function finish()
        if bufLen > 0 then
            local byte = math.floor(buffer * (2 ^ (8 - bufLen))) % 256
            parts[#parts+1] = string.char(byte)
            buffer = 0
            bufLen = 0
        end
        return table.concat(parts)
    end

    return writeBits, finish
end

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

local function lzw_compress(input)
    if not input or #input == 0 then return "" end

    local writeBits, finish = makeBitWriter()

    local dict = {}
    for i = 0, 255 do dict[string.char(i)] = i end
    local dictSize = FIRST_AVAILABLE

    local w = input:sub(1,1)
    for i = 2, #input do
        local c = input:sub(i,i)
        local wc = w .. c
        if dict[wc] then
            w = wc
        else
            local codeW = dict[w]
            writeBits(CODE_BITS, codeW)
            if dictSize < MAX_CODES then
                dict[wc] = dictSize
                dictSize = dictSize + 1
            end
            w = c
        end
    end

    if w ~= "" then
        writeBits(CODE_BITS, dict[w])
    end

    return finish()
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
            textViewer.eout(string.format(loc["FZIP.lzw_decompress.error"], k, dictSize))
        end

        out[#out+1] = entry

        if dictSize < MAX_CODES then
            dict[dictSize] = w .. entry:sub(1,1)
            dictSize = dictSize + 1
        end

        w = entry
    end

    local result = table.concat(out)
    return result
end

local function create_co(archivePath, inputs)
    local _, y = term.getCursorPos()
    local pb = progressBar.create(2, 20, y)
    local f = fs.open(archivePath, "wb")
    f.write("FZIP\2")

    local allFiles = {}
    for _, input in ipairs(inputs) do
        if fs.isDir(input) then
            for _, file in ipairs(listFilesRecursive(input)) do
                table.insert(allFiles, file)
            end
        elseif fs.exists(input) then
            table.insert(allFiles, {abs = input, rel = fs.getName(input)})
        end
    end
    
    progressBar.reset(pb, #allFiles + 1)
    progressBar.inc(pb)

    f.write(string.char(#allFiles))

    for _, file in ipairs(allFiles) do
        local handle = fs.open(file.abs, "rb")
        local data = handle.readAll()
        handle.close()

        local lzw_compressed = lzw_compress(data)
        local useLzwCompressed = #lzw_compressed < #data

        local finalData = useLzwCompressed and lzw_compressed or data
        local flag = useLzwCompressed and 1 or 0
        local crc = crc32(data)

        f.write(string.pack(">I2", #file.rel))
        f.write(file.rel)
        f.write(string.char(flag))
        f.write(string.pack(">I4", #finalData))
        f.write(string.pack(">I4", crc))
        f.write(finalData)
        progressBar.inc(pb)
    end

    f.close()
end

local function extract_co(archivePath, outDir)
    local f = fs.open(archivePath, "rb")
    local header = f.read(4)
    if header ~= "FZIP" then
        textViewer.eout(loc["FZIP.extract.archiveInvalid"])
        return
    end

    local version = f.read(1)
    local fileCount = string.byte(f.read(1))

    local _, y = term.getCursorPos()
    local pb = progressBar.create(fileCount + 1, 20, y)
    progressBar.inc(pb)

    for i = 1, fileCount do
        local nameLen = string.unpack(">I2", f.read(2))
        local relPath = f.read(nameLen)

        local flag = string.byte(f.read(1))
        local size = string.unpack(">I4", f.read(4))

        local crc = string.unpack(">I4", f.read(4))
        local data = f.read(size)

        local finalData = (flag == 1) and lzw_decompress(data) or data

        if crc ~= crc32(finalData) then
            textViewer.eout(loc["error.corruptedFile"] .. relPath)
        end

        local outPath = fs.combine(outDir, relPath)
        local parentDir = fs.getDir(outPath)
        if not fs.exists(parentDir) then
            fs.makeDir(parentDir)
        end

        local outFile = fs.open(outPath, "wb")
        outFile.write(finalData)
        outFile.close()
        progressBar.inc(pb)
    end

    f.close()
end

function fzip.create(archivePath, inputs)
    local co = coroutine.create(function (archivePath, inputs)
        create_co(archivePath, inputs)
    end)
    coroutine.resume(co, archivePath, inputs)
end

function fzip.extract(archivePath, outDir)
    local co = coroutine.create(function (archivePath, outDir)
        extract_co(archivePath, outDir)
    end)
    coroutine.resume(co, archivePath, outDir)
end

return fzip