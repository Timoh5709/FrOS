local files = fs.list("/drivers")

if not #files == 0 then
    for _, file in ipairs(files) do
        local path = fs.combine("/drivers/", file)
        shell.run(file)
        print(file .. " lance")
    end
end