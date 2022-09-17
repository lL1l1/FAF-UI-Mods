
table.insert(options.ui.items, {
    -- tip     = "",
    title = "TPaint: point lifetime in seconds",
    key = 'TPaint_lifetime',
    type = 'slider',
    default = 10,
    custom = {
        min = 1,
        max = 30,
        inc = 1
    },
})

table.insert(options.ui.items, {
    -- tip     = "",
    title = "TPaint: point max count",
    key = 'TPaint_maxcount',
    type = 'slider',
    default = 1000,
    custom = {
        min = 100,
        max = 10000,
        inc = 100
    },
})

table.insert(options.ui.items, {
    title = "TPaint: Observer paint tool color",
    key = 'TPaintobs_color',
    type = 'toggle',
    default = 'ffffffff',
    custom = {
        states = { 
            
           {text = "new blue1",key = "ff436eee",},     -- new blue1
           {text = "Cybran red",key = "FFe80a0a",},     -- Cybran red
           {text = "grey",key = "ff616d7e",},     -- grey
           {text = "new yellow",key = "fffafa00",},     -- new yellow
           {text = "Nomads orange",key = "FFFF873E",},     -- Nomads orange
           {text = "white",key = "ffffffff",},     -- white
           {text = "purple",key = "ff9161ff",},     -- purple
           {text = "white",key = "ffff88ff",},     -- pink
           {text = "new green",key = "ff2e8b57",},     -- new green
           {text = "UEF blue",key = "FF2929e1",},     -- UEF blue
           {text = "dark purple",key = "FF5F01A7",},     -- dark purple
           {text = "new fuschia",key = "ffff32ff",},     -- new fuschia
           {text = "Sera golden",key = "ffa79602",},     -- Sera golden
           {text = "new brown",key = "ffb76518",},     -- new brown
           {text = "dark red",key = "ff901427",},     -- dark red
           {text = "olive (dark green)",key = "FF2F4F4F",},     -- olive (dark green)
           {text = "mid green",key = "ff40bf40",},     -- mid green
           {text = "aqua",key = "ff66ffcc",},     -- aqua
           {text = "Order Green",key = "ff9fd802",},     -- Order Green
    }
    }
})
