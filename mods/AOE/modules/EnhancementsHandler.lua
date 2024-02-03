local ISelectionHandler = import("/mods/AGP/modules/ISelectionHandler.lua").ISelectionHandler
local IItemComponent = import("/mods/AGP/modules/IItemComponent.lua").IItemComponent

local GetEnhancementTextures = import("/lua/ui/game/construction.lua").GetEnhancementTextures
local Enhancements = import("Enhancements.lua")
local Button = import('/lua/maui/button.lua').Button

---@class EnhancementIconInfo
---@field bpID string
---@field name string

---@class EnhancementsHandler : ISelectionHandler
EnhancementsHandler = Class(ISelectionHandler)
{
    ---@param self ExampleHandler
    ---@param selection UserUnit[]
    ---@return EnhancementIconInfo[]?
    OnSelectionChanged = function(self, selection)
        if table.empty(selection) then
            return
        end
        if table.getn(selection) ~= 1 or table.empty(EntityCategoryFilterDown(categories.COMMAND, selection)) then
            return
        end
        ---@type UserUnit
        local unit = selection[1]
        local bp = unit:GetBlueprint().BlueprintId

        return { {
            bpID = bp,
            name = "AdvancedEngineering",
        } }
    end,

    ---@class EnhComponent : IItemComponent
    ---@field btn Button
    ---@field bpID string
    ---@field name string
    ComponentClass = Class(IItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self EnhComponent
        ---@param item Item
        Create = function(self, item)
            self.btn = Button(item)
            self.bpID = nil
            self.name = nil
            item.Layouter(self.btn)
                :Fill(item)
                :Disable()
            self.btn.mClickCue = "UI_MFD_Click"
            self.btn.mRolloverCue = "UI_MFD_Rollover"
            self.btn.OnClick = function()
                Enhancements.OrderEnhancement(self.name)
            end
        end,

        ---Called when grid item receives an event
        ---@param self EnhComponent
        ---@param item Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
        end,

        ---Called when item is activated with this component event handling
        ---@param self EnhComponent
        ---@param item Item
        Enable = function(self, item)
            self.btn:Enable()
            self.btn:Show()
        end,

        ---@param self EnhComponent
        ---@param action EnhancementIconInfo
        SetAction = function(self, action)
            self.bpID = action.bpID
            self.name = action.name
            self.btn:SetNewTextures(GetEnhancementTextures(self.bpID,
                __blueprints[self.bpID].Enhancements[self.name].Icon))
            self.btn:ApplyTextures()
        end,

        ---Called when item is changing event handler
        ---@param self EnhComponent
        ---@param item Item
        Disable = function(self, item)
            self.btn:Disable()
            self.btn:Hide()
        end,

        ---Called when component is being destroyed
        ---@param self EnhComponent
        Destroy = function(self)
            self.btn:Destroy()
            self.btn = nil
        end,
    },
}
