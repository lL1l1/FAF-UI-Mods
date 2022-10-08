do
    local OriginalOnSelectionChanged = OnSelectionChanged
    function OnSelectionChanged(oldSelection, newSelection, added, removed)
        if ignoreSelection then return end
        OriginalOnSelectionChanged(oldSelection, newSelection, added, removed)
    end
end
