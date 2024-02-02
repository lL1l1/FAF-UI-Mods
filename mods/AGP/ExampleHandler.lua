local SelectionHandler = import("SelectionHandler.lua").SelectionHandler
local ExampleComponent = import("ExampleComponent.lua").ExampleComponent

---@class ExampleHandler : SelectionHandler
ExampleHandler = Class(SelectionHandler)
{
    ---@param self SelectionHandler
    ---@param selection UserUnit[]
    ---@return string[]
    OnSelectionChange = function(self, selection)
        if table.empty(EntityCategoryFilterDown(categories.COMMAND, selection)) then
            return { 1, 2, 3 }
        end
        return { 4, 5, 6 }
    end,

    ---@type IItemComponent
    ComponentClass = ExampleComponent,
}
