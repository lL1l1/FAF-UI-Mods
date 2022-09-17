local origCreateUI = CreateUI
function CreateUI(isReplay)
    
    origCreateUI(isReplay)
    if not isReplay then
        import("/mods/PPA/modules/pauseAFK.lua").Main()
    end

end
