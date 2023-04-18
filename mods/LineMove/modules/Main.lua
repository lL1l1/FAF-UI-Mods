local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Group = import('/lua/maui/group.lua').Group
local CommandMode = import("/lua/ui/game/commandmode.lua")



local toCommandType = {
    ["RULEUCC_Move"] = "Move",
    ["RULEUCC_Attack"] = "Attack",
    ["RULEUCC_Guard"] = "Guard",
    ["RULEUCC_Patrol"] = "Patrol",
    ["RULEUCC_Repair"] = "Repair",
    ["RULEUCC_Capture"] = "Capture",
    ["RULEUCC_Nuke"] = "Nuke",
    ["RULEUCC_Tactical"] = "Tactical",
    ["RULEUCC_Teleport"] = "Teleport",
}


local function GiveOrder(unit, position, orderType)
    ForkThread(
        function()
            SimCallback({
                Func = "GiveOrders",
                Args = {
                    unit_orders = { { CommandType = orderType, Position = position } },
                    unit_id     = unit:GetEntityId(),
                    From        = GetFocusArmy()
                }
            }, false)
        end
    )
end

Point = Class(Bitmap)
{
    __init = function(self, parent, view, position)
        Bitmap.__init(self, parent)
        LayoutFor(self)
            :Color("red")
            :Left(0)
            :Top(0)
            :Width(2)
            :Height(2)
            :DisableHitTest()
            :NeedsFrameUpdate(true)
        self.position = { position[1], position[2], position[3] }
        self.view = view
    end,

    OnFrame = function(self, delta)
        local view = self.view
        local proj = view:Project(self.position)
        self.Left:SetValue(proj.x - 0.5 * self.Width())
        self.Top:SetValue(proj.y - 0.5 * self.Height())
    end
}


---@class MouseMonitor : Group
MouseMonitor = Class(Group)
{

    __init = function(self, parent)
        Group.__init(self, parent)
        self.pressed       = false
        self.points        = TrashBag()
        self.unitPositions = TrashBag()
        self.selection     = false
        self.prevPosition  = false
    end,

    ---@param MouseMonitor WorldView
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        --if not event.Modifiers.Right then return end

        if event.Type == "ButtonPress" and event.Modifiers.Right then
            self.pressed = true
            self:InitPositions(GetMouseWorldPos())
            self:AddPoint(GetMouseWorldPos())
        elseif event.Type == "MouseMotion" and self.pressed then
            self:AddPoint(GetMouseWorldPos())
        elseif event.Type == "ButtonRelease" and self.pressed and not event.Modifiers.Right then
            self.pressed = false
            self.prevPosition = false
            self:GiveOrders()
            self.selection = false
            self:DestroyPoints()
        end

    end,

    InitPositions = function(self, position)
        self.selection = GetSelectedUnits()
        for i = 1, table.getn(self.selection) do
            local point = Point(self, self:GetParent(), position)
            LayoutFor(point)
                :Color("white")
            self.unitPositions:Add(point)
        end
    end,

    AddPoint = function(self, position)
        if self.prevPosition and VDist3(self.prevPosition, position) < 1 then
            return
        end

        self.points:Add(Point(self, self:GetParent(), position))
        self.prevPosition = position
        self:UpdatePositions()
    end,


    GetLineLength = function(self)
        local l = 0
        local prev = nil
        for _, point in self.points do
            if prev then
                l = l + VDist3(prev, point.position)
            end
            prev = point.position
        end
        return l
    end,


    DestroyPoints = function(self)
        self.points:Destroy()
        self.unitPositions:Destroy()
    end,

    UpdatePositions = function(self)
        local len = self:GetLineLength()

        if len == 0 then return end

        local unitCount = table.getn(self.unitPositions)
        local distBetween = len / (unitCount + 1)
        local currentSegmentLength = distBetween
        local curUnitPosition = 1

        
        for i = 1, table.getn(self.points) - 1 do
            local p1 = self.points[i].position
            local p2 = self.points[i + 1].position
            local dist = VDist3(p1, p2)
            if dist > currentSegmentLength then
                local s = currentSegmentLength / dist
                self.unitPositions[curUnitPosition].position = {
                    MATH_Lerp(s, 0, p2[1] - p1[1]) + p1[1],
                    MATH_Lerp(s, 0, p2[2] - p1[2]) + p1[2],
                    MATH_Lerp(s, 0, p2[3] - p1[3]) + p1[3],
                }
                curUnitPosition = curUnitPosition + 1
                currentSegmentLength = distBetween - (dist - currentSegmentLength)
                if curUnitPosition > unitCount then
                    break
                end
            else
                currentSegmentLength = currentSegmentLength - dist
            end
        end
    end,


    GiveOrders = function(self)
        if table.getn(self.points) <= 1 then return end

        local orderType = CommandMode.GetCommandMode()[2].name and toCommandType[CommandMode.GetCommandMode()[2].name] or
            'Move'

        local curPos = 1
        for _, unit in self.selection do
            if unit:IsDead() then continue end

            GiveOrder(unit, self.unitPositions[curPos].position, orderType)

            curPos = curPos + 1
        end

    end




}
