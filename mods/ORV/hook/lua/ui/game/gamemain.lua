if import("/lua/version.lua").GetVersion() >= 3745 then
    local OldCreateUI = CreateUI
    function CreateUI(isReplay)
        OldCreateUI(isReplay)
        --import('/mods/ORV/modules/Main.lua').Main(isReplay)
        import("/lua/ui/game/reclaim.lua").SetMapSize()
    end
end
