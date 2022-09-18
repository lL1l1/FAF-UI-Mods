local OldCreateUI = CreateUI
function CreateUI(isReplay)
    OldCreateUI(isReplay)
    import('/mods/ORV/modules/Main.lua').Main(isReplay)
    import("/lua/ui/game/reclaim.lua").SetMapSize()
end
