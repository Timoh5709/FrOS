local theme = {}
local couleurs = {
    ["white"]=colors.white,
    ["orange"]=colors.orange,
    ["magenta"]=colors.magenta,
    ["lightBlue"]=colors.lightBlue,
    ["yellow"]=colors.yellow,
    ["lime"]=colors.lime,
    ["pink"]=colors.pink,
    ["gray"]=colors.gray,
    ["lightGray"]=colors.lightGray,
    ["cyan"]=colors.cyan,
    ["purple"]=colors.purple,
    ["blue"]=colors.blue,
    ["brown"]=colors.brown,
    ["green"]=colors.green,
    ["red"]=colors.red,
    ["black"]=colors.black
}

function theme.refresh()
    local stg = FrOS.stg
    local bgColor, fgColor = colors.black, colors.white

    if couleurs[stg["bg"]] then
        bgColor = couleurs[stg["bg"]]
    end
    
    if couleurs[stg["fg"]] then
        fgColor = couleurs[stg["fg"]]
    end

    term.setBackgroundColor(bgColor)
    term.setTextColor(fgColor)

    return bgColor, fgColor
end

function theme.refreshBar()
    local stg = FrOS.stg
    local bgBarColor, fgBarColor = colors.gray, colors.white

    if couleurs[stg["bgBar"]] then
        bgBarColor = couleurs[stg["bgBar"]]
    end
    
    if couleurs[stg["fgBar"]] then
        fgBarColor = couleurs[stg["fgBar"]]
    end

    return bgBarColor, fgBarColor
end

return theme