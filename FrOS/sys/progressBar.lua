local progressBar = {}
local textViewer = require("/FrOS/sys/textViewer")
local bars = {}
local nextId = 1

function progressBar.create(max, width, y)
    if type(max) ~= "number" or max < 0 then
        textViewer.eout("Erreur : max doit être un nombre >= 0.")
    end

    local id = nextId
    nextId = nextId + 1

    bars[id] = {
        value = 0,
        max = max,
        width = width,
        y = y
    }

    return id
end

function progressBar.inc(id)
    local bar = bars[id]
    if not bar then return end
    if bar.value < bar.max then
        bar.value = bar.value + 1
    end
    progressBar.render(id, bar.width, bar.y)
end

function progressBar.dec(id)
    local bar = bars[id]
    if not bar then return end
    if bar.value > 0 then
        bar.value = bar.value - 1
    end
    progressBar.render(id, bar.width, bar.y)
end

function progressBar.reset(id, newMax)
    local bar = bars[id]
    if not bar then return end
    bar.value = 0
    if newMax and type(newMax) == "number" and newMax >= 0 then
        bar.max = newMax
    end
    progressBar.render(id, bar.width, bar.y)
end

function progressBar.remove(id)
    bars[id] = nil
end

function progressBar.get(id)
    local bar = bars[id]
    if not bar then return nil end
    return bar.value, bar.max, bar.width, bar.y
end

function progressBar.render(id, width, y)
    local bar = bars[id]
    if not bar then return "" end

    local value, max = progressBar.get(id)
    local percent = (max > 0) and (value / max) or 0
    local filled = math.floor(percent * width)
    local empty = width - filled

    term.setCursorPos(1, y)
    term.clearLine()
    write("[")
    term.setTextColor(colors.green)
    write(string.rep(">", filled) .. string.rep(" ", empty))
    term.setTextColor(colors.white)
    write("] " .. math.floor(percent * 100) .. "%")
    if value >= max then
        term.setCursorPos(1, y + 1)
        term.clearLine()
        textViewer.cprint("Terminé", colors.green)
    end
end

return progressBar