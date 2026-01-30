local gfrx = {}
local textViewer = require("/FrOS/sys/textViewer")
gfrx.__index = gfrx

local DEFAULT_FG = colors.white
local DEFAULT_BG = colors.black

local loc = FrOS.sysLoc

local function transformToChar(value)
    local inversed = false
    if value >= 32 then
        inversed = true
        value = 31 - (value % 32)
    end
    return value + 0x80, inversed
end

local function setDeviceColors(dev, isMonitor, fg, bg)
    if isMonitor then
        if dev.setTextColor then dev.setTextColor(fg) end
        if dev.setBackgroundColor then dev.setBackgroundColor(bg) end
    else
        term.setTextColor(fg or DEFAULT_FG)
        term.setBackgroundColor(bg or DEFAULT_BG)
    end
end

local function writeAt(dev, isMonitor, cx, cy, txt)
    if isMonitor then
        dev.setCursorPos(cx, cy)
        dev.write(txt)
    else
        term.setCursorPos(cx, cy)
        write(txt)
    end
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
            textViewer.eout(loc["gfrx.new.wrapError"]..tostring(target).."'", 2)
            return
        end
    end

    local cw, ch
    if self.isMonitor then
        cw, ch = self.device.getSize()
    else
        cw, ch = term.getSize()
    end

    self.charWidth = cw
    self.charHeight = ch
    self.width = cw * 2
    self.height = ch * 3

    self.buffers = {}
    self.activeBuffer = nil

    self.cells = {}
    for cx = 1, self.charWidth do
        self.cells[cx] = {}
        for cy = 1, self.charHeight do
            self.cells[cx][cy] = {char = nil, fg = nil, bg = nil}
        end
    end

    self.dirty = {}
    self.dirtyCount = 0

    self.buffered = (opts.buffered == nil) and true or opts.buffered

    self.defaultForeground = DEFAULT_FG
    self.defaultBackground = DEFAULT_BG

    return self
end

function gfrx:markDirty(cx, cy)
    if cx < 1 or cx > self.charWidth or cy < 1 or cy > self.charHeight then return end
    local row = self.dirty[cx]
    if not row then
        self.dirty[cx] = {}
        self.dirtyCount = self.dirtyCount + 1
    end
    if not self.dirty[cx][cy] then
        self.dirty[cx][cy] = true
    end
end

function gfrx:markAllDirty()
    for cx = 1, self.charWidth do
        for cy = 1, self.charHeight do
            self.markDirty = self.markDirty
            self.dirty[cx] = self.dirty[cx] or {}
            self.dirty[cx][cy] = true
        end
    end
    self.dirtyCount = self.charWidth * self.charHeight
end

function gfrx:addBuffer(colorOn, colorOff)
    local buf = {
        pixels = {},
        colorOn = colorOn or DEFAULT_FG,
        colorOff = colorOff or DEFAULT_BG,
    }
    table.insert(self.buffers, buf)
    local id = #self.buffers
    self.activeBuffer = id
    self:markAllDirty()
    return id
end

function gfrx:useBuffer(id)
    if not id or id < 1 or id > #self.buffers then textViewer.eout(loc["gfrx.useBuffer.error"]) return end
    self.activeBuffer = id
end

function gfrx:removeBuffer(id)
    if not id or id < 1 or id > #self.buffers then return false end
    table.remove(self.buffers, id)
    if self.activeBuffer and self.activeBuffer > #self.buffers then
        self.activeBuffer = #self.buffers
    end
    self:markAllDirty()
    return true
end

function gfrx:clearBuffer(id)
    local buf = self.buffers[id]
    if not buf then return false end
    buf.pixels = {}
    self:markAllDirty()
    return true
end

function gfrx:setDefaults(fg, bg)
    self.defaultForeground = fg or DEFAULT_FG
    self.defaultBackground = bg or DEFAULT_BG
    self:markAllDirty()
end

function gfrx:setPixel(x, y, on)
    if x < 1 or x > self.width or y < 1 or y > self.height then return false end
    if not self.activeBuffer then textViewer.eout(loc["gfrx.setPixel.error"]) return end
    local buf = self.buffers[self.activeBuffer]
    buf.pixels[x] = buf.pixels[x] or {}
    if on then
        buf.pixels[x][y] = true
    else
        buf.pixels[x][y] = nil
    end
    local cx = math.floor((x-1)/2)+1
    local cy = math.floor((y-1)/3)+1
    self:markDirty(cx, cy)
    if not self.buffered then
        self:flushCell(cx, cy)
    end
    return true
end

function gfrx:getPixel(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then return nil end
    for id = #self.buffers, 1, -1 do
        local buf = self.buffers[id]
        if buf.pixels[x] and buf.pixels[x][y] then
            return id
        end
    end
    return nil
end

local function computeBitsForBuffer(buf, base_x, base_y, width, height)
    local bits = 0
    local function check(px, py, mask)
        if px >= 1 and px <= width and py >= 1 and py <= height then
            if buf.pixels[px] and buf.pixels[px][py] then
                bits = bits + mask
            end
        end
    end
    check(base_x + 1, base_y + 1, 1)
    check(base_x + 2, base_y + 1, 2)
    check(base_x + 1, base_y + 2, 4)
    check(base_x + 2, base_y + 2, 8)
    check(base_x + 1, base_y + 3, 16)
    check(base_x + 2, base_y + 3, 32)
    return bits
end

function gfrx:flushCell(cx, cy)
    if cx < 1 or cx > self.charWidth or cy < 1 or cy > self.charHeight then return end

    local base_x = (cx-1)*2
    local base_y = (cy-1)*3

    local chosenBits = 0
    local chosenBuf = nil
    local chosenId = nil

    for id = #self.buffers, 1, -1 do
        local buf = self.buffers[id]
        local bits = computeBitsForBuffer(buf, base_x, base_y, self.width, self.height)
        if bits ~= 0 then
            chosenBits = bits
            chosenBuf = buf
            chosenId = id
            break
        else
            chosenBuf = buf
            chosenId = id
        end
    end

    local fg, bg
    if chosenBuf then
        if chosenBits == 0 then
            fg = chosenBuf.colorOn or self.defaultForeground
            bg = chosenBuf.colorOff or self.defaultBackground
        else
            local code, inversed = transformToChar(chosenBits)
            fg = chosenBuf.colorOn or self.defaultForeground
            bg = chosenBuf.colorOff or self.defaultBackground
            if chosenId then
                for id = chosenId - 1, 1, -1 do
                    local buf = self.buffers[id]
                    local bitsBelow = computeBitsForBuffer(buf, base_x, base_y, self.width, self.height)
                    local countBelow = 0
                    local countOFF = 0
                    for _, mask in ipairs({1,2,4,8,16,32}) do
                        if bit.band(bitsBelow, mask) ~= 0 then countBelow = countBelow + 1 end
                        if bit.band(chosenBits, mask) == 0 then countOFF = countOFF + 1 end
                    end
                    if countBelow > countOFF then
                        bg = buf.colorOn or self.defaultForeground
                        break
                    end
                end
            end

            local ch = string.char(code)
            if inversed then fg, bg = bg, fg end

            local cell = self.cells[cx][cy]
            if cell.char ~= ch or cell.fg ~= fg or cell.bg ~= bg then
                setDeviceColors(self.device, self.isMonitor, fg, bg)
                writeAt(self.device, self.isMonitor, cx, cy, ch)
                self.cells[cx][cy] = {char = ch, fg = fg, bg = bg}
            end
            return
        end
    else
        fg = self.defaultForeground
        bg = self.defaultBackground
    end

    local ch = " "
    local cell = self.cells[cx][cy]
    if cell.char ~= ch or cell.fg ~= fg or cell.bg ~= bg then
        setDeviceColors(self.device, self.isMonitor, fg, bg)
        writeAt(self.device, self.isMonitor, cx, cy, ch)
        self.cells[cx][cy] = {char = ch, fg = fg, bg = bg}
    end
end

function gfrx:flush()
    if self.dirtyCount == 0 then return end
    for cx, col in pairs(self.dirty) do
        for cy, _ in pairs(col) do
            self:flushCell(cx, cy)
        end
    end
    self.dirty = {}
    self.dirtyCount = 0
end

function gfrx:drawLine(x0, y0, x1, y1, on)
    local dx = math.abs(x1 - x0)
    local sx = x0 < x1 and 1 or -1
    local dy = -math.abs(y1 - y0)
    local sy = y0 < y1 and 1 or -1
    local err = dx + dy
    while true do
        self:setPixel(x0, y0, on)
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

function gfrx:drawRect(x, y, w, h, on, filled)
    if filled then
        for yy = y, y + h - 1 do
            for xx = x, x + w - 1 do
                self:setPixel(xx, yy, on)
            end
        end
    else
        for xx = x, x + w - 1 do
            self:setPixel(xx, y, on)
            self:setPixel(xx, y + h - 1, on)
        end
        for yy = y, y + h - 1 do
            self:setPixel(x, yy, on)
            self:setPixel(x + w - 1, yy, on)
        end
    end
end

function gfrx:drawCircle(cx, cy, radius, on, filled)
    if radius < 0 then return end
    local x = radius
    local y = 0
    local err = 0
    local spans = {}
    while x >= y do
        local pts = {
            {cx + x, cy + y}, {cx - x, cy + y}, {cx + x, cy - y}, {cx - x, cy - y},
            {cx + y, cy + x}, {cx - y, cy + x}, {cx + y, cy - x}, {cx - y, cy - x},
        }
        if not filled then
            for _, p in ipairs(pts) do self:setPixel(p[1], p[2], on) end
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
                    self:setPixel(xx, yr, on)
                end
            end
        end
    end
end

function gfrx:drawTriangle(x1,y1,x2,y2,x3,y3,on,filled)
    self:drawLine(x1,y1,x2,y2,on)
    self:drawLine(x2,y2,x3,y3,on)
    self:drawLine(x3,y3,x1,y1,on)
    if not filled then return end

    local minY = math.min(y1,y2,y3)
    local maxY = math.max(y1,y2,y3)

    local function edgeIntersectY(ax,ay,bx,by,y)
        if ay == by then return nil end
        if (y < math.min(ay,by)) or (y > math.max(ay,by)) then return nil end
        local t = (y - ay) / (by - ay)
        return ax + t * (bx - ax)
    end

    for y = minY, maxY do
        local xs = {}
        local xi = edgeIntersectY(x1,y1,x2,y2,y)
        if xi then table.insert(xs, xi) end
        xi = edgeIntersectY(x2,y2,x3,y3,y)
        if xi then table.insert(xs, xi) end
        xi = edgeIntersectY(x3,y3,x1,y1,y)
        if xi then table.insert(xs, xi) end

        table.sort(xs)
        for i = 1, #xs, 2 do
            local xstart = math.floor(xs[i] + 0.5)
            local xend = math.floor((xs[i+1] or xs[i]) + 0.5)
            for x = xstart, xend do
                self:setPixel(x, y, on)
            end
        end
    end
end

function gfrx:clearAll()
    for i = 1, #self.buffers do self.buffers[i].pixels = {} end
    for cx = 1, self.charWidth do
        for cy = 1, self.charHeight do
            self.cells[cx][cy] = {char = nil, fg = nil, bg = nil}
        end
    end
    self:markAllDirty()
end

function gfrx:getResolution() return self.width, self.height end
function gfrx:getCharSize() return self.charWidth, self.charHeight end

return setmetatable({}, {
    __call = function(_, ...)
        return gfrx.new(...)
    end
})