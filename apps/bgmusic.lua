-- @background
local update = require("/FrOS/sys/update")
local running = update.appCheck(0.81)
if not running then
    return
end
local dfpwmPlayer = require("/FrOS/sys/dfpwmPlayer")

function string:endswith(suffix)
    return self:sub(-#suffix) == suffix
end

local args = {...}
if #args < 1 then
    return
end

local musicPath = fs.combine(shell.dir(), args[1])
if fs.exists(musicPath) and musicPath:endswith(".dfpwm") then
    dfpwmPlayer.play(musicPath)
end