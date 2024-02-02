local Bitmap = UMT.Controls.Bitmap
---@class ActionsGridPanel : UMT.Bitmap
ActionsGridPanel = UMT.Class(Bitmap)
{

    ---@param self ActionsGridPanel
    __init = function(self, parent)
        Bitmap.__init(self, parent)


    end,

    ---@param self ActionsGridPanel
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)
        layouter(self)
            :Width(100)
            :Height(100)
            :DisableHitTest()
    end,
}
