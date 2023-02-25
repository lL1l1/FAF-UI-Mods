function IsIgnoredSelection()
    return ignoreSelection
end

do
    local OldOnCommandIssued = OnCommandIssued
    function OnCommandIssued(command)
        OldOnCommandIssued(command)

        if not command.Clear then return end

        import('/mods/GS/modules/Main.lua').OnCommandIssued(commandMode, modeData, command)
    end
end
