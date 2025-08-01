local files = fs.list("/drivers")
local lance = {"init.lua"}

local function tableContains(table, value)
  for i = 1,#table do
    if (table[i] == value) then
      return true
    end
  end
  return false
end

if #files > 0 then
    for _, file in ipairs(files) do
        if tableContains(lance, file) then
            table.insert(lance, file)
            local path = fs.combine("/drivers/", file)
            shell.run(path)
            print(file .. " lance")
        end
    end
end