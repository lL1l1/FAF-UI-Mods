do
    local GlobalOptions = import("/mods/UMT/modules/GlobalOptions.lua")
    local OptionsUtils = import("/mods/UMT/modules/OptionsWindow.lua")
    local OptionVarCreate = import("/mods/UMT/modules/OptionVar.lua").Create

    local modName = "IEL"

    engineersOption = OptionVarCreate(modName, "engineersOverlay", true)
    factoriesOption = OptionVarCreate(modName, "factoriesOverlay", true)
    supportCommanderOption = OptionVarCreate(modName, "supportCommanderOverlay", true)
    tacticalNukesOption = OptionVarCreate(modName, "tacticalNukesOverlay", true)
    massExtractorsOption = OptionVarCreate(modName, "massExtractorsOverlay", true)


    function Main(isReplay)
        GlobalOptions.AddOptions(modName, "Idle Engineers Light",
            { OptionsUtils.Filter("Show engineers ovelays", engineersOption),
                OptionsUtils.Filter("Show factories ovelays", factoriesOption),
                OptionsUtils.Filter("Show Nukes and TMLs ovelays", tacticalNukesOption),
                OptionsUtils.Filter("Show Mex ovelays", massExtractorsOption) })
    end
end
