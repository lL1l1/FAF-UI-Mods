function Main(isReplay)

    local ActionsGridPanel = import("ActionsGridPanel.lua").ActionsGridPanel
    local LayoutFor = UMT.Layouter.ReusedLayoutFor

    ForkThread(function()
        WaitSeconds(1)
        local constructionPanelControls = import("/lua/ui/game/construction.lua").controls
        local parent = constructionPanelControls.constructionGroup
        ---@type ActionsGridPanel
        local agp = ActionsGridPanel(parent)

        LayoutFor(agp)
            :AtRightBottomIn(GetFrame(0))

        LayoutFor(constructionPanelControls.constructionGroup)
            :Right(agp.Left)
    end)
end
