local update = require("/FrOS/sys/update")
local running = update.appCheck(0.82)
if not running then
    return
end
local gfrx = require("/FrOS/sys/3dgfrx")
local gfx = gfrx(nil, {buffered = true})
local theme = require("/FrOS/sys/theme")
local bgColor, fgColor = theme.refreshBar()

function string:endswith(suffix)
    return self:sub(-#suffix) == suffix
end

local args = {...}
local logoB, top, ball, obj, objPath = false, {}, {}, {}, ""
if #args < 1 then
    logoB = true

    gfx:setPalette(gfx.PALETTES.rgb_shades)
else
    objPath = fs.combine(shell.dir(), args[1])
    if not fs.exists(objPath) and not objPath:endswith(".obj") then
        return
    end

    gfx:setPalette(gfx.PALETTES.grayscale)
end

local lightDir = { x = -0.6, y = 0.3, z = 0.6 }
local angleX, angleY = math.pi + 0.2, 0
local speed = 0.05
local FOV = 60
local cameraDist = 100
local screenWidth, screenHeight = gfx:getResolution()
local FPS = 20

local size = 5
if #args == 2 then
    size = tonumber(args[2], 10)
elseif logoB == true then
    size = 15
end
local cx, cy = math.floor(screenWidth / 2), math.floor(screenHeight / 2)

local FPSs = {}

local function loadOBJ(filePath)
    local loadedMesh = {vertices = {}, faces = {}}
    local file = fs.open(filePath, "r")
    if not file then return nil end

    local line = file.readLine()
    while line do
        local prefix, rest = line:match("^(%S+)%s+(.-)$")
        if prefix == "v" then
            local x, y, z = rest:match("^(%S+)%s+(%S+)%s+(%S+)")
            if x and y and z then
                table.insert(loadedMesh.vertices, {x = tonumber(x) * size, y = tonumber(y) * size, z = tonumber(z) * size})
            end
        elseif prefix == "f" then
            local indices = {}
            for v in rest:gmatch("(%d+)/?%d*/?%d*") do
                table.insert(indices, tonumber(v))
            end
            for i = 2, #indices - 1 do
                table.insert(loadedMesh.faces, {indices[1], indices[i], indices[i + 1]})
            end
        end
        line = file.readLine()
    end
    file.close()
    return loadedMesh
end

if logoB == false then
    obj = loadOBJ(objPath)
else
    top = loadOBJ("/FrOS/media/FrOS_t.obj")
    ball = loadOBJ("/FrOS/media/FrOS_b.obj")
    cy = math.floor(screenHeight / 2 + screenHeight / 5)
end

local projected = {}
local transformedWorld = {}
local transformedZ = {}

local function updateMesh(mesh)
    local cosX, sinX = math.cos(angleX), math.sin(angleX)
    local cosY, sinY = math.cos(angleY), math.sin(angleY)

    for i, v in ipairs(mesh.vertices) do
        local x1 = v.x * cosY + v.z * sinY
        local z1 = v.z * cosY - v.x * sinY

        local y1 = v.y * cosX - z1 * sinX
        local z2 = z1 * cosX + v.y * sinX

        transformedWorld[i] = {x = x1, y = y1, z = z2}

        z2 = z2 + cameraDist
        transformedZ[i] = z2

        if z2 > 0 then
            projected[i] = {
                x = math.floor((x1 * FOV) / z2) + cx,
                y = math.floor((y1 * FOV) / z2) + cy,
           }
        else
            projected[i] = nil
        end
    end
end

local function drawMesh(mesh, baseR, baseG, baseB)
    local renderList = {}

    for _, face in ipairs(mesh.faces) do
        local p1, p2, p3 = projected[face[1]], projected[face[2]], projected[face[3]]

        if p1 and p2 and p3 then
            local crossProduct = (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)

            if crossProduct < 0 then
                local w1, w2, w3 = transformedWorld[face[1]], transformedWorld[face[2]], transformedWorld[face[3]]
                local ux, uy, uz = w2.x - w1.x, w2.y - w1.y, w2.z - w1.z
                local vx, vy, vz = w3.x - w1.x, w3.y - w1.y, w3.z - w1.z

                local nx = uy * vz - uz * vy
                local ny = uz * vx - ux * vz
                local nz = ux * vy - uy * vx

                local length = math.sqrt(nx * nx + ny * ny + nz * nz)
                if length > 0 then
                    nx, ny, nz = nx / length, ny / length, nz / length
                end

                local dot = nx * lightDir.x + ny * lightDir.y + nz * lightDir.z
                local intensity = math.max(0.3, math.min(1.0, -dot))

                local zAvg = (transformedZ[face[1]] + transformedZ[face[2]] + transformedZ[face[3]]) / 3

                local r = math.floor(baseR * intensity)
                local g = math.floor(baseG * intensity)
                local b = math.floor(baseB * intensity)
                local rgbColor = r * 0x10000 + g * 0x100 + b

                table.insert(renderList, {
                    p1 = p1, p2 = p2, p3 = p3,
                    z = zAvg,
                    color = rgbColor
                })
            end
        end
    end

    table.sort(renderList, function(a, b) return a.z > b.z end)

    for _, item in ipairs(renderList) do
        gfx:drawTriangle(item.p1.x, item.p1.y, item.p2.x, item.p2.y, item.p3.x, item.p3.y, item.color, true)
    end
end

for _=0, 4 * math.pi, speed * 0.7 do
    local tInit = os.epoch("utc")

    gfx:clear(0x000000)

    angleY = angleY + speed * 0.7
    if logoB == true then
        updateMesh(top)
        drawMesh(top, 255, 0, 0)
        updateMesh(ball)
        drawMesh(ball, 0, 255, 0)
    else
        updateMesh(obj)
        drawMesh(obj, 255, 255, 255)
    end

    gfx:flush()

    local tFinal = os.epoch("utc")
    local deltaT = tFinal - tInit
    FPS = 1000 / deltaT
    table.insert(FPSs, FPS)

    term.setCursorPos(1, 1)
    term.setBackgroundColor(bgColor)
    term.setTextColor(fgColor)
    print(math.floor(FPS) .. " FPS")

    sleep(0)
end

gfx:resetColors()
term.clear()
term.setCursorPos(1, 1)