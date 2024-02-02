local Bitmap = UMT.Controls.Bitmap

---@class Item : UMT.Bitmap
Item = UMT.Class(Bitmap)
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
