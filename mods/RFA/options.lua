local Opt = UMT.Options.Opt
UMT.Options.Mods["RFA"] = {
    hoverPreviewKey = Opt "SHIFT",
    selectedPreviewKey = Opt "SHIFT",
    buildPreviewKey = Opt "SHIFT",
}

function Main()
    local Options = UMT.Options
    local options = UMT.Options.Mods["RFA"]
    Options.AddOptions("RFA", "Rings For All",
        {
            Options.Strings("Hover Preview key (restart required)",
                {
                    "SHIFT",
                    "CONTROL"
                },
                options.hoverPreviewKey),
            Options.Strings("Selected Preview key (restart required)",
                {
                    "SHIFT",
                    "CONTROL"
                },
                options.selectedPreviewKey),
            Options.Strings("Build Preview key (restart required)",
                {
                    "SHIFT",
                    "CONTROL"
                },
                options.buildPreviewKey),
        })
end
