local RefreshUI = import("/lua/ui/game/construction.lua").RefreshUI
function MoveLastItemAfterFirst()
    local selectedUnits = GetSelectedUnits()
    if selectedUnits and selectedUnits[1]:IsInCategory "FACTORY" then
        local currentCommandQueue = SetCurrentFactoryForQueueDisplay(selectedUnits[1])
        local n = table.getn(currentCommandQueue)
        if n > 2 then
            local lastItemBP = currentCommandQueue[n].id
            if lastItemBP == currentCommandQueue[1].id then
                IncreaseBuildCountInQueue(1, 1)
                DecreaseBuildCountInQueue(n, 1)
            elseif lastItemBP == currentCommandQueue[2].id then
                IncreaseBuildCountInQueue(2, 1)
                DecreaseBuildCountInQueue(n, 1)
            else
                for i = n, 2, -1 do
                    DecreaseBuildCountInQueue(i, currentCommandQueue[i].count)
                end
                currentCommandQueue[1].count = currentCommandQueue[1].count - 1
                currentCommandQueue[n].count = currentCommandQueue[n].count - 1
                DecreaseBuildCountInQueue(1, currentCommandQueue[1].count)    
                IssueBlueprintCommand("UNITCOMMAND_BuildFactory", lastItemBP, 1)
                for i, entry in currentCommandQueue do
                    local blueprint = __blueprints[entry.id]
                    if blueprint.General.UpgradesFrom == 'none' then
                        IssueBlueprintCommand("UNITCOMMAND_BuildFactory", entry.id, entry.count)
                    else
                        IssueBlueprintCommand("UNITCOMMAND_Upgrade", entry.id, 1, false)
                    end
                end
            end
            ClearCurrentFactoryForQueueDisplay()
            RefreshUI()
        end
    end
end

KeyMapper.SetUserKeyAction('MoveLastItemAfterFirst', {
    action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").MoveLastItemAfterFirst()',
    category = 'orders',
    order = 109
})
KeyMapper.SetUserKeyAction('Shift_MoveLastItemAfterFirst', {
    action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").MoveLastItemAfterFirst()',
    category = 'orders',
    order = 110
})
