local gfrx = {}
gfrx.__index = gfrx

gfrx.PALETTES = {
    grayscale = {0x000000, 0x111111, 0x222222, 0x333333, 0x444444, 0x555555, 0x666666, 0x777777, 0x888888, 0x999999, 0xAAAAAA, 0xBBBBBB, 0xCCCCCC, 0xDDDDDD, 0xEEEEEE, 0xFFFFFF},
    vibrant16 = {0x000000, 0xFFFFFF, 0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00, 0xFF00FF, 0x00FFFF, 0xFF8800, 0x88FF00, 0x00FF88, 0x0088FF, 0x8800FF, 0xFF0088, 0x884400, 0x444444},
    rgb_shades = {0x000000, 0xFFFFFF, 0x808080, 0x404040, 0xFF0000, 0x800000, 0x400000, 0x00FF00, 0x008000, 0x004000, 0x0000FF, 0x000080, 0x000040, 0xFFFF00, 0xFF00FF, 0x00FFFF},
    basic8 = {0xFF0000, 0x00FF00, 0x0000FF, 0xFF007F, 0xFFFF00, 0x800080, 0x8B4513, 0x000000, 0xFFFFFF, 0x222222, 0x444444, 0x666666, 0x888888, 0xAAAAAA, 0xCCCCCC, 0xEEEEEE},
    classic = {0xF0F0F0, 0xF2B233, 0xE57FD8, 0x99B2F2, 0xDEDE6C, 0x7FCC19, 0xF2B2CC, 0x4C4C4C, 0x999999, 0x4C99B2, 0xB266E5, 0x3366CC, 0x7F664C, 0x57A64E, 0xCC4C4C, 0x111111}
}

local loc = {}
pcall(function (...)
    loc = FrOS.sysLoc or {}
end)

local charMap = {}
local invertedMap = {}
for i = 0, 63 do
    local val = i
    local inv = false
    if val >= 32 then
        inv = true
        val = 31 - (val % 32)
    end
    charMap[i] = string.char(val + 128)
    invertedMap[i] = inv
end

local CC_COLORS = "0123456789abcdef"

local rgbCache = {}
local function getRGB(c)
    if rgbCache[c] then 
        local cache = rgbCache[c]
        return cache[1], cache[2], cache[3]
    end
    local r = math.floor(c / 65536) % 256
    local g = math.floor(c / 256) % 256
    local b = c % 256
    rgbCache[c] = {r, g, b}
    return r, g, b
end

local function colorDist(c1, c2)
    if c1 == c2 then return 0 end
    local r1, g1, b1 = getRGB(c1)
    local r2, g2, b2 = getRGB(c2)
    return (r1-r2)*(r1-r2) + (g1-g2)*(g1-g2) + (b1-b2)*(b1-b2)
end

function gfrx.new(target, opts)
    opts = opts or {}
    local self = setmetatable({}, gfrx)

    if target == nil then
        self.device = term
        self.isMonitor = false
    else
        local ok, p = pcall(peripheral.wrap, target)
        if ok and p then
            self.device = p
            self.isMonitor = true
        else
            print(loc["gfrx.new.wrapError"]..tostring(target).."'", 2)
            return
        end
    end

    local cw, ch = self.device.getSize()
    self.charWidth = cw
    self.charHeight = ch
    self.width = cw * 2
    self.height = ch * 3

    self.pixels = {}
    self.defaultBackground = 0x000000

    self.dirtyLines = {}
    for cy = 1, self.charHeight do
        self.dirtyLines[cy] = true
    end

    self.colorCache = {}
    self.currentPalette = {}
    self:setPalette(gfrx.PALETTES.grayscale)

    return self
end

function gfrx:markDirty(cy)
    if cy < 1 or cy > self.charHeight then return end
    self.dirtyLines[cy] = true
end

function gfrx:markAllDirty()
    for cy = 1, self.charHeight do
        self.dirtyLines[cy] = true
    end
end

function gfrx:unmarkDirty(cy)
    if cy < 1 or cy > self.charHeight then return end
    self.dirtyLines[cy] = false
end

function gfrx:isDirty(cy)
    if cy < 1 or cy > self.charHeight then return end
    return self.dirtyLines[cy] or false
end

function gfrx:unmarkAllDirty()
    self.dirtyLines = {}
end

function gfrx:setPalette(pal)
    self.currentPalette = {}
    for i = 1, 16 do
        local rgb = pal[i] or 0x000000
        self.currentPalette[i] = rgb
        local ccColor = 2^(i-1)
        if self.device.setPaletteColor then
            local r, g, b = getRGB(rgb)
            self.device.setPaletteColor(ccColor, r/255, g/255, b/255)
        end
    end
    self.colorCache = {}
    for cy = 1, self.charHeight do
        self.dirtyLines[cy] = true
    end
end

function gfrx:getClosestCCTermColor(rgb)
    if self.colorCache[rgb] then return self.colorCache[rgb] end
    local bestDist = math.huge
    local bestIdx = 1
    for i = 1, 16 do
        local d = colorDist(rgb, self.currentPalette[i])
        if d < bestDist then
            bestDist = d
            bestIdx = i
        end
    end
    local char = CC_COLORS:sub(bestIdx, bestIdx)
    self.colorCache[rgb] = char
    return char
end

function gfrx:clear(color)
    self.defaultBackground = color or 0x000000
    self.pixels = {}
    for cy = 1, self.charHeight do
        self.dirtyLines[cy] = true
    end
end

function gfrx:clearAll(color)
    self:clear(color)
end

function gfrx:setPixel(x, y, color)
    if x < 1 or x > self.width or y < 1 or y > self.height then return false end
    local idx = (y - 1) * self.width + x
    if self.pixels[idx] ~= color then
        self.pixels[idx] = color
        local cy = math.floor((y - 1) / 3) + 1
        self.dirtyLines[cy] = true
    end
    return true
end

function gfrx:getPixel(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then return nil end
    return self.pixels[(y - 1) * self.width + x] or self.defaultBackground
end

local function evalCell(p1, p2, p3, p4, p5, p6)
    if p1==p2 and p2==p3 and p3==p4 and p4==p5 and p5==p6 then
        return p1, p1
    end

    local u1, c1 = p1, 1
    local u2, c2, u3, c3, u4, c4, u5, c5, u6, c6

    local function add(p)
        if p == u1 then c1 = c1 + 1 return end
        if u2 == nil then u2 = p; c2 = 1 return end
        if p == u2 then c2 = c2 + 1 return end
        if u3 == nil then u3 = p; c3 = 1 return end
        if p == u3 then c3 = c3 + 1 return end
        if u4 == nil then u4 = p; c4 = 1 return end
        if p == u4 then c4 = c4 + 1 return end
        if u5 == nil then u5 = p; c5 = 1 return end
        if p == u5 then c5 = c5 + 1 return end
        if u6 == nil then u6 = p; c6 = 1 return end
        if p == u6 then c6 = c6 + 1 return end
    end
    add(p2); add(p3); add(p4); add(p5); add(p6)

    local d1, f1 = u1, c1
    local d2, f2 = u1, 0

    local function check(u, c)
        if not u then return end
        if c > f1 then
            d2, f2 = d1, f1
            d1, f1 = u, c
        elseif c > f2 then
            d2, f2 = u, c
        end
    end

    check(u2, c2); check(u3, c3); check(u4, c4); check(u5, c5); check(u6, c6)
    if not d2 then d2 = d1 end
    return d1, d2
end

function gfrx:renderCell(cx, cy)
    local base_x = (cx - 1) * 2
    local base_y = (cy - 1) * 3

    local w = self.width
    local pxs = self.pixels
    local def = self.defaultBackground

    local idx = base_y * w + base_x
    local p1 = pxs[idx + 1] or def
    local p2 = pxs[idx + 2] or def
    local p3 = pxs[idx + w + 1] or def
    local p4 = pxs[idx + w + 2] or def
    local p5 = pxs[idx + 2*w + 1] or def
    local p6 = pxs[idx + 2*w + 2] or def

    local dom1, dom2 = evalCell(p1, p2, p3, p4, p5, p6)

    local bits = 0
    if dom1 ~= dom2 then
        if colorDist(p1, dom2) < colorDist(p1, dom1) then bits = bits + 1 end
        if colorDist(p2, dom2) < colorDist(p2, dom1) then bits = bits + 2 end
        if colorDist(p3, dom2) < colorDist(p3, dom1) then bits = bits + 4 end
        if colorDist(p4, dom2) < colorDist(p4, dom1) then bits = bits + 8 end
        if colorDist(p5, dom2) < colorDist(p5, dom1) then bits = bits + 16 end
        if colorDist(p6, dom2) < colorDist(p6, dom1) then bits = bits + 32 end
    end

    local inv = invertedMap[bits]
    local char = charMap[bits]

    local fgHex = self:getClosestCCTermColor(dom2)
    local bgHex = self:getClosestCCTermColor(dom1)

    if inv then
        return char, bgHex, fgHex
    else
        return char, fgHex, bgHex
    end
end

function gfrx:flush()
    local dev = self.device

    for cy, dirty in pairs(self.dirtyLines) do
        if dirty then
            local chars, fgs, bgs = {}, {}, {}
            for cx = 1, self.charWidth do
                local char, fg, bg = self:renderCell(cx, cy)
                chars[cx] = char
                fgs[cx] = fg
                bgs[cx] = bg
            end
            dev.setCursorPos(1, cy)
            dev.blit(table.concat(chars), table.concat(fgs), table.concat(bgs))
            self.dirtyLines[cy] = false
        end
    end
end

function gfrx:drawLine(x0, y0, x1, y1, color)
    local dx = math.abs(x1 - x0)
    local sx = x0 < x1 and 1 or -1
    local dy = -math.abs(y1 - y0)
    local sy = y0 < y1 and 1 or -1
    local err = dx + dy
    while true do
        self:setPixel(x0, y0, color)
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 >= dy then
            err = err + dy
            x0 = x0 + sx
        end
        if e2 <= dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

function gfrx:drawRect(x, y, w, h, color, filled)
    if filled then
        for yy = y, y + h - 1 do
            for xx = x, x + w - 1 do
                self:setPixel(xx, yy, color)
            end
        end
    else
        for xx = x, x + w - 1 do
            self:setPixel(xx, y, color)
            self:setPixel(xx, y + h - 1, color)
        end
        for yy = y, y + h - 1 do
            self:setPixel(x, yy, color)
            self:setPixel(x + w - 1, color)
        end
    end
end

function gfrx:drawCircle(cx, cy, radius, color, filled)
    if radius < 0 then return end
    local x = radius
    local y = 0
    local err = 0
    local spans = {}
    while x >= y do
        local pts = {{cx + x, cy + y}, {cx - x, cy + y}, {cx + x, cy - y}, {cx - x, cy - y}, {cx + y, cy + x}, {cx - y, cy + x}, {cx + y, cy - x}, {cx - y, cy - x}}
        if not filled then
            for _, p in ipairs(pts) do self:setPixel(p[1], p[2], color) end
        else
            local function addSpan(yrow, x1, x2)
                spans[yrow] = spans[yrow] or {math.huge, -math.huge}
                if x1 < spans[yrow][1] then spans[yrow][1] = x1 end
                if x2 > spans[yrow][2] then spans[yrow][2] = x2 end
            end
            addSpan(cy + y, cx - x, cx + x)
            addSpan(cy - y, cx - x, cx + x)
            addSpan(cy + x, cx - y, cx + y)
            addSpan(cy - x, cx - y, cx + y)
        end

        y = y + 1
        err = err + 1 + 2*y
        if 2*(err - x) + 1 > 0 then
            x = x - 1
            err = err + 1 - 2*x
        end
    end

    if filled then
        for yr, span in pairs(spans) do
            if span[1] <= span[2] then
                for xx = span[1], span[2] do
                    self:setPixel(xx, yr, color)
                end
            end
        end
    end
end

function gfrx:drawTriangle(x1, y1, x2, y2, x3, y3, color, filled)
    if not filled then
        self:drawLine(x1, y1, x2, y2, color)
        self:drawLine(x2, y2, x3, y3, color)
        self:drawLine(x3, y3, x1, y1, color)
        return
    end

    local minY = math.min(y1, y2, y3)
    local maxY = math.max(y1, y2, y3)

    local function edgeIntersectY(ax, ay, bx, by, y)
        if ay == by then return nil end
        if (y < math.min(ay, by)) or (y > math.max(ay, by)) then return nil end
        local t = (y - ay) / (by - ay)
        return ax + t * (bx - ax)
    end

    for y = minY, maxY do
        local xs = {}
        local xi = edgeIntersectY(x1, y1, x2, y2, y)
        if xi then table.insert(xs, xi) end
        xi = edgeIntersectY(x2, y2, x3, y3, y)
        if xi then table.insert(xs, xi) end
        xi = edgeIntersectY(x3, y3, x1, y1, y)
        if xi then table.insert(xs, xi) end

        if #xs > 0 then
            table.sort(xs)
            local cleanXs = {}
            for i = 1, #xs do
                if i == 1 or math.abs(xs[i] - xs[i-1]) > 0.0001 then
                    table.insert(cleanXs, xs[i])
                end
            end

            if #cleanXs >= 2 then
                local xstart = math.floor(cleanXs[1] + 0.5)
                local xend = math.floor(cleanXs[#cleanXs] + 0.5)
                for x = xstart, xend do
                    self:setPixel(x, y, color)
                end
            elseif #cleanXs == 1 then
                self:setPixel(math.floor(cleanXs[1] + 0.5), y, color)
            end
        end
    end
end

function gfrx:resetColors()
    for i = 0, 15 do
        local ccColor = 2^i
        if self.device.setPaletteColor and term.nativePaletteColor then
            self.device.setPaletteColor(ccColor, term.nativePaletteColor(ccColor))
        end
    end
    self.device.setTextColor(colors.white)
    self.device.setBackgroundColor(colors.black)
end

function gfrx:getResolution() return self.width, self.height end
function gfrx:getCharSize() return self.charWidth, self.charHeight end

return setmetatable({}, {
    __call = function(_, ...)
        return gfrx.new(...)
    end
})