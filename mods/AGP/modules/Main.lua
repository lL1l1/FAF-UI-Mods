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
        local l = __active_mods
            | LuaQ.where(function(v) return v.AGP and v.ui_only end)
            | LuaQ.select(function(modInfo)
                local modFolder = string.sub(modInfo.location, 7)
                local className = modInfo.AGP

                local files = DiskFindFiles("/mods/" .. modFolder .. "/", className .. '.lua')
                for _, file in files do
                    local class = import(file)[className]
                    LOG("AGP: added " .. modFolder .. " : " .. className)
                    return { ("%s.%s"):format(modFolder, className), class }
                end
                error(("Couldn't find class '%s' in folder '%s'"):format(className, modFolder))
            end)

        for i, info in l do
            local name    = info[1]
            local handler = info[2]

            self._selectionHandlers[name] = handler
            self._order[name]             = i
        end

        for name, handler in self._selectionHandlers do
            self:AddItemComponent(name, handler.ComponentClass)
        end

        reprsl(self._selectionHandlers)
        reprsl(self._order)
    end,

    ---@param self Panel
    ---@param selection UserUnit[]
    OnSelectionChanged = function(self, selection)
        local order           = self._order
        local handlersActions = {}
        for name, handler in pairs(self._selectionHandlers) do
            handlersActions[name] = handler:OnSelectionChange(selection)
        end

        ---@type table
        local actions = handlersActions
            | LuaQ.select.keyvalue(function(name, actions)
                return actions
                    | LuaQ.select.keyvalue(function(i, action)
                        return {
                            handler = name,
                            action = action,
                            id = i,
                        }
                    end)
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
        local next = next

        local index, actionInfo = next(actions, nil)

        self:IterateItems(function(grid, item, row, column)
            if index == nil then item:Disable() return end
            item:EnableComponent(actionInfo.handler, actionInfo.action)

            index, actionInfo = next(actions, index)
        end)
    end,
}

---@type Panel
local panel = nil

function OnSelectionChanged(info)
    if IsDestroyed(panel) then return end

    panel:OnSelectionChanged(info.newSelection)
end

function Main(isReplay)

    local LayoutFor = UMT.Layouter.ReusedLayoutFor

    local GM = import("/lua/ui/game/gamemain.lua")
    GM.ObserveSelection:AddObserver(OnSelectionChanged)

    ForkThread(function()
        WaitSeconds(1)
        local constructionPanelControls = import("/lua/ui/game/construction.lua").controls
        local parent = constructionPanelControls.constructionGroup

        panel = Panel(parent)

        panel:LoadExtensions()
        panel:OnSelectionChanged({})

        LayoutFor(panel)
            :AtRightBottomIn(GetFrame(0), 10, 10)

        LayoutFor(constructionPanelControls.constructionGroup)
            :AnchorToLeft(panel, 20)
    end)
end
