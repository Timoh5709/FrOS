local ts = require("/FrOS/sys/taskScheduler")
local statusBar = {}
local dossier = "root"

statusBar.clickableAreas = {}

function statusBar.draw()
    local clock = textutils.formatTime(os.time("local"), true)
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clearLine()

    local _, ending = string.find(dossier, ".lua")
    if ending == #dossier then
        term.write("> " .. dossier)
    else
        term.write("/" .. dossier)
    end

    statusBar.clickableAreas = {}

    for _, t in ipairs(ts.list()) do
        term.setBackgroundColor(colors.gray)
        if t.status == "running" then
            term.setTextColor(colors.green)
        elseif t.status == "paused" then
            term.setTextColor(colors.orange)
        else
            term.setTextColor(colors.red)
        end
        term.write(" ")
        if ts.getFocused() == t.id then
            term.setBackgroundColor(colors.black)
        elseif t.background == true then
            term.setBackgroundColor(colors.lightGray)
        end

        local currentX, Y = term.getCursorPos()
        local idStr = tostring(t.id)

        term.write(t.id)

        table.insert(statusBar.clickableAreas, {
            id = t.id,
            xMin = currentX,
            xMax = currentX + #idStr - 1,
            task = t
        })
    end

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    local w, _ = term.getSize()
    term.setCursorPos(w - #clock + 1, 1)
    term.write(clock)
end

function statusBar.updateDossier(newDossier)
    dossier = newDossier
end

function statusBar.handleMouse(button, x, y)
    if y ~= 1 then return end

    for _, area in ipairs(statusBar.clickableAreas) do
        if x >= area.xMin and x <= area.xMax then
            if button == 1 then
                ts.focus(area.id)
                if area.task.status == "paused" then
                    ts.resume(area.id)
                end
            elseif button == 2 then
                if area.task.status == "paused" then
                    ts.resume(area.id)
                else
                    if area.id ~= ts.getId("FrOS/sys/statusBar.lua") then
                        ts.pause(area.id)
                    end
                end
            elseif button == 3 then
                if area.id ~= ts.getId("FrOS/sys/statusBar.lua") and area.id ~= ts.getId("FrOS/main.lua") then
                    ts.kill(area.id)
                end
            end

            break
        end
    end
end

return statusBar