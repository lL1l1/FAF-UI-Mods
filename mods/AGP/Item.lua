local Bitmap = UMT.Controls.Bitmap
local IComponentable = import("IComponentable.lua").IComponentable

---@class Item : UMT.Bitmap, IComponentable
---@field _activeComponent string
Item = UMT.Class(Bitmap, IComponentable)
{

    ---@param self Item
    __init = function(self, parent)
        Bitmap.__init(self, parent)
        self._activeComponent = nil
    end,

    ---@param self Item
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)

    end,

    ---@param self Item
    ---@param name string
    ---@param action string
    EnableComponent = function(self, name, action)
        if self._activeComponent ~= name then
            self:DisableComponents()
            self:SetActiveComponent(name)
            local component = self:GetActiveComponent()
            component:Enable(self)
            component:SetAction(action)
        else
            local component = self:GetActiveComponent()
            component:SetAction(action)
        end
    end,

    ---@param self Item
    DisableComponents = function(self)
        for _, component in self:GetComponents() do
            component:Disable(self)
        end
    end,

    ---@param self Item
    OnDisable = function(self)
        self:DisableComponents()
    end,

    ---@param self Item
    ---@return IItemComponent
    GetActiveComponent = function(self)
        return self:GetComponent(self._activeComponent)
    end,

    ---@param self Item
    ---@param name string
    SetActiveComponent = function(self, name)
        self._activeComponent = name
    end,

    ---@param self Item
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        local component = self:GetActiveComponent()
        component:HandleEvent(self, event)
    end,

    ---@param self Item
    OnDestroy = function(self)
        Bitmap.OnDestroy(self)
        self:DestroyComponents()
    end
}
