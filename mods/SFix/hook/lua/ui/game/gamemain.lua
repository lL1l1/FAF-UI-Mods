local originalOnSelectionChanged = OnSelectionChanged

function OnSelectionChanged(oldSelection, newSelection, added, removed)
    if ignoreSelection then
        return
    end
    originalOnSelectionChanged(oldSelection, newSelection, added, removed)
end
