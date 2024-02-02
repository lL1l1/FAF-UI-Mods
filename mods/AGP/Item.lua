local Bitmap = UMT.Controls.Bitmap
local IComponentable = import("IComponentable.lua").IComponentable

---@class Item : UMT.Bitmap, IComponentable
Item = UMT.Class(Bitmap, IComponentable)
{

    ---@param self Item
    __init = function(self, parent)
        Bitmap.__init(self, parent)

    end,

    

    ---@param self Item
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)

    end,
}