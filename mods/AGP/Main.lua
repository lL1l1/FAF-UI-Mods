local ActionsGridPanel = import("ActionsGridPanel.lua").ActionsGridPanel

local LuaQ = UMT.LuaQ

---@class Panel : ActionsGridPanel
---@field _selectionHandlers table<string, SelectionHandler>
---@field _order table<string, number>
Panel = UMT.Class(ActionsGridPanel)
{
    ---@param self Panel
    LoadExtensions = function(self)
        self._selectionHandlers = {}
        self._order = {}


    end,





    ---@param self Panel
    ---@param selection UserUnit[]
    OnSelectionChanged = function(self, selection)
        local order           = self._order
        local handlersActions = {}
        for name, handler in pairs(self._selectionHandlers) do
            handlersActions[name] = handler:OnSelectionChange(selection)
        end
        handlersActions = {
            ["my ext"] = { "a", "b", "c" },
            ["not my ext"] = { "d", "g", "f" },
        }
        order = {
            ["my ext"] = 2,
            ["not my ext"] = 7,
        }
        local actions = handlersActions
            | LuaQ.select.keyvalue(function(name, actions)
                return actions
                    | LuaQ.select.keyvalue(function(i, action) return { handler = name, action = action, id = i } end)
            end)
            | LuaQ.values
            | LuaQ.concat
            | LuaQ.sort(function(a, b)
                local oa = order[a.handler]
                local ob = order[b.handler]
                if oa == ob then
                    return a.id < b.id
                end
                return oa < ob
            end)
        reprsl(actions)
    end,




}



function Main(isReplay)

    local LayoutFor = UMT.Layouter.ReusedLayoutFor

    ForkThread(function()
        WaitSeconds(1)
        local constructionPanelControls = import("/lua/ui/game/construction.lua").controls
        local parent = constructionPanelControls.constructionGroup
        ---@type Panel
        local agp = Panel(parent)

        agp:LoadExtensions()
        agp:OnSelectionChanged({})

        LayoutFor(agp)
            :AtRightBottomIn(GetFrame(0), 10, 10)

        LayoutFor(constructionPanelControls.constructionGroup)
            :AnchorToLeft(agp, 20)
    end)
end
