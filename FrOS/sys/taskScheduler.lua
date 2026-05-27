local taskScheduler = {}
local loc = FrOS.errorLoc
local tasks = {}
local nextId = 1
local running = false
local focusedTask = nil
local w, h = term.getSize()
local parent = term.current()

function taskScheduler.spawn(name, func, options, ...)
    options = options or {}
    local id = nextId
    local args = { ... }
    local win = window.create(parent, options.x or 1, options.y or 2, options.w or w, options.h or h - 1, true)

    local co = coroutine.create(function()
        func(table.unpack(args))
    end)

    if options.id then
        local useOptionId = true

        for k, t in pairs(tasks) do
            if options.id == k then
                useOptionId = false
            end
        end

        if useOptionId then
            id = options.id
        else
            nextId = nextId + 1
        end
    else
        nextId = nextId + 1
    end

    tasks[id] = {
        id = id,
        name = name or ("task-" .. id),
        co = co,
        window = (not (options.background or false)) and win,
        parentTerm = parent,
        status = "running",
        paused = false,
        background = options.background or false,
        receiveEvents = options.receiveEvents ~= false,
        filter = options.filter,
        created = os.clock()
    }

    if not options.background then
        focusedTask = id
    end

    return id
end

function taskScheduler.getTask(id)
    return tasks[id]
end

function taskScheduler.getId(name)
    for id, v in pairs(tasks) do
        if v.name == name then
            return id
        end
    end
    return nil
end

function taskScheduler.pause(id)
    if tasks[id] then
        tasks[id].paused = true
        tasks[id].status = "paused"

        return true
    end

    return false
end

function taskScheduler.resume(id)
    if tasks[id] then
        tasks[id].paused = false
        tasks[id].status = "running"

        return true
    end

    return false
end

function taskScheduler.focus(id)
    if not tasks[id] then
        return false
    end

    focusedTask = id

    for tid, task in pairs(tasks) do
        if task.window then
            task.window.setVisible(tid == id)
        end
    end
    
    if not tasks[id].background then
        tasks[id].window.redraw()
    end

    return true
end

function taskScheduler.getFocused()
    return focusedTask
end

function taskScheduler.kill(id)
    if tasks[id] then
        if focusedTask == id then
            focusedTask = nil
        end

        tasks[id] = nil
        return true
    end

    return false
end

function taskScheduler.list()
    local list = {}

    for id, task in pairs(tasks) do
        table.insert(list, {
            id = id,
            name = task.name,
            status = task.status,
            background = task.background
        })
    end

    return list
end

function taskScheduler.print()
    for _, t in ipairs(taskScheduler.list()) do
        local fg = t.background and "BG" or "FG"
        print(("[%d] (%s) %s - %s"):format(t.id, fg, t.name, t.status))
    end
end

function taskScheduler.run()
    running = true
    local timer = os.startTimer(0.05)

    while running do
        local event = { os.pullEventRaw() }

        if event[1] == "timer" and event[2] == timer then
            timer = os.startTimer(0.05)
        end

        local blockEvent = false
        if event[1] == "mouse_click" then
            local button, clickX, clickY = event[2], event[3], event[4]
            if clickY == 1 then
                FrOS.statusBar.handleMouse(button, clickX, clickY)
                blockEvent = true
            end
        end

        local active = false

        for id, task in pairs(tasks) do
            if coroutine.status(task.co) == "dead" then
                tasks[id] = nil
            elseif not task.paused then
                local shouldResume = true

                if (event[1] == "char" or event[1] == "key" or event[1] == "mouse_click" or event[1] == "mouse_drag" or event[1] == "mouse_scroll") then
                    if focusedTask ~= id or blockEvent then
                        shouldResume = false
                        if not task.background then
                            task.window.setVisible(false)
                        end
                    end
                end

                if task.filter then
                    if not task.filter(event) then
                        shouldResume = false
                    end
                end

                if shouldResume then
                    local previous = term.current()
                    if not task.background then
                        term.redirect(task.window)
                        task.window.setVisible(true)
                        task.window.redraw()
                    end
                    local ok, err = coroutine.resume(
                        task.co,
                        table.unpack(event)
                    )
                    term.redirect(previous)

                    if not ok then
                        print(loc["error.error"] .. task.name .. " => " .. tostring(err))
                        tasks[id] = nil
                    else
                        active = true
                    end
                end
            end
        end

        if not active and next(tasks) == nil then
            break
        end
    end
end

function taskScheduler.stop()
    running = false
end

return taskScheduler