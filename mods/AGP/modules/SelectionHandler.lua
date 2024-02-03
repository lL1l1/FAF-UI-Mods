local IItemComponent = import("IItemComponent.lua").IItemComponent

---@class SelectionHandler
SelectionHandler = Class()
{
    ---@param self SelectionHandler
    ---@param selection UserUnit[]
    ---@return string[]?
    OnSelectionChanged = function(self, selection)
    end,

    ---@type IItemComponent
    ComponentClass = IItemComponent,
}
