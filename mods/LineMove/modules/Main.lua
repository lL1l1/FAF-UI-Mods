local VDist3, MATH_Lerp = VDist3, MATH_Lerp
local TableGetN = table.getn

local Prefs = import('/lua/user/prefs.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor
local Group = import('/lua/maui/group.lua').Group
local CommandMode = import("/lua/ui/game/commandmode.lua")

local toCommandType = {
    ["RULEUCC_Move"] = "Move",
    ["RULEUCC_Attack"] = "Attack",
    ["RULEUCC_Guard"] = "Guard",
    ["RULEUCC_Tactical"] = "Tactical",
    ["RULEUCC_Nuke"] = "Nuke",
    ["AttackMove"] = "AttackMove",
}



local MathSqrt = math.sqrt
local function perpendicularDistance(point, lineStart, lineEnd)
    local dx = lineEnd.x - lineStart.x
    local dy = lineEnd.z - lineStart.z

    local mag = MathSqrt(dx * dx + dy * dy)
    if mag > 0.0 then
        dx = dx / mag
        dy = dy / mag
    end

    local pvx = point.x - lineStart.x
    local pvy = point.z - lineStart.z

    local pvDot = dx * pvx + dy * pvy

    local ax = pvDot * dx
    local ay = pvDot * dy

    local pdx = pvx - ax
    local pdy = pvy - ay

    return MathSqrt(pdx * pdx + pdy * pdy)
end

local function TableSub(tbl, starti, endi)
    local result = {}
    for i = starti, endi do
        table.insert(result, tbl[i])
    end
    return result
end

---@param points Vector[]
---@param epsilon number
local function ReducePoints(points, epsilon)
    local dmax = 0
    local index = 0
    local totalPoints = TableGetN(points)

    for i = 2, totalPoints - 1 do
        local d = perpendicularDistance(points[i], points[1], points[totalPoints])
        if d > dmax then
            index = i
            dmax = d
        end
    end



    if dmax > epsilon then
        local result1 = ReducePoints(TableSub(points, 1, index), epsilon)
        local result2 = ReducePoints(TableSub(points, index, totalPoints), epsilon)

        local result = {}
        for i = 1, TableGetN(result1) - 1 do
            table.insert(result, result1[i])
        end
        for i = 1, TableGetN(result2) do
            table.insert(result, result2[i])
        end

        return result
    else
        return { points[1], points[totalPoints] }
    end
end

local function GiveOrders(curve, orderType, clear)

    local eps = 1
    while TableGetN(curve) > 100 do
        curve = ReducePoints(curve, eps)
        eps = eps + 0.5
    end
    ForkThread(SimCallback, {
        Func = "LineMove",
        Args = {
            Curve = curve,
            Order = orderType,
            Clear = clear,
            Army = GetFocusArmy()
        }
    }, true)
end

local DEBUG = false

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
            :NeedsFrameUpdate(DEBUG)
        self.position = Vector(position[1], position[2], position[3])
        self.view = view
        if not DEBUG then
            self:Hide()
        end
    end,

    OnFrame = function(self, delta)
        local view = self.view
        local proj = view:Project(self.position)
        self.Left:SetValue(proj.x - 0.5 * self.Width())
        self.Top:SetValue(proj.y - 0.5 * self.Height())
    end
}

local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh

---@class UnitMesh : WorldMesh
---@field position Vector
---@field unit UserUnit
UnitMesh = Class(WorldMesh)
{
    ---@param self UnitMesh
    ---@param unit UserUnit
    ---@param position Vector
    __init = function(self, unit, position)
        WorldMesh.__init(self)
        local bp = unit:GetBlueprint()
        local bpId = bp.BlueprintId
        local scale = bp.Display.UniformScale or 0.1
        if bpId:find("_") then
            bpId = bpId:sub(1, bpId:find("_") - 1)
        end
        if not exists("/units/" .. bpId .. "/" .. bpId .. "_lod0.scm") or
            not exists("/units/" .. bpId .. "/" .. bpId .. "_albedo.dds") then
            WARN("Cant find blueprint mesh " .. bpId)
            self:SetHidden(true)
            return
        end
        self:SetMesh(
            {
                MeshName = "/units/" .. bpId .. "/" .. bpId .. "_lod0.scm",
                TextureName = "/units/" .. bpId .. "/" .. bpId .. "_albedo.dds",
                ShaderName = 'UnitFormationPreview',
                UniformScale = scale
            })
        self:SetHidden(false)
        self.unit = unit
        self:SetPosition(Vector(position[1], position[2], position[3]))
    end,

    SetPosition = function(self, position)
        self.position = position
        local unitPos = self.unit:GetPosition()
        local dir = VDiff(position, unitPos)
        local orient = OrientFromDir(dir)
        self:SetStance(position, orient)
    end
}

---@class MouseMonitor : Group
---@field
MouseMonitor = Class(Group)
{
    MinFrameTime = 0.15,

    ---@param self MouseMonitor
    ---@param parent any
    __init = function(self, parent)
        Group.__init(self, parent)
        self.pressed       = false
        self.points        = TrashBag()
        self.unitPositions = TrashBag()
        self.selection     = false
        self.prevPosition  = false
        self._frameCount   = 0
        self._preview      = false
        self:SetNeedsFrameUpdate(true)
    end,

    IsStartEvent = function(self, event)
        return event.Type == "ButtonPress" and event.Modifiers.Right and not event.Modifiers.Shift
    end,

    IsMoveEvent = function(self, event)
        return event.Type == "MouseMotion" and self.pressed
    end,

    IsEndEvent = function(self, event)
        return event.Type == "ButtonRelease" and self.pressed and not event.Modifiers.Right
    end,

    StartLineMove = function(self)
        self._frameCount = 0
        self:EnableHitTest()
        self.selection = GetSelectedUnits()
        if not self.selection then
            return
        end
        self.pressed = true

        self:AddPoint(GetMouseWorldPos())
    end,

    CreatePreview = function(self)
        self._preview = true
        self:InitPositions(GetMouseWorldPos())
        -- self:AcquireKeyboardFocus(true)
    end,

    ---@param self any
    ---@param mods EventModifiers
    EndLineMove = function(self, mods)
        self._frameCount = 0
        self:DisableHitTest()
        self.pressed = false
        self.prevPosition = false
        if self._preview then
            self:GiveOrders(mods)
        end
        self.selection = false
        self:DestroyPoints()
        self._preview = false
        self:AbandonKeyboardFocus()
    end,


    IsCancelEvent = function(self, event)
        if not self.pressed then return false end

        if event.Type == "ButtonPress" then
            return true
        elseif event.Type == 'KeyUp' then
            -- local bind = GetKeyBind()
            -- LOG(bind)
            -- LOG(event.KeyCode)
            -- return event.KeyCode == bind
        end
        return false
    end,
    OnFrame = function(self, delta)
        self._frameCount = self._frameCount + delta
    end,
    ---@param self MouseMonitor
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        --if not event.Modifiers.Right then return end
        --LOG(event.Type)
        if self:IsStartEvent(event) then
            self:StartLineMove()
        elseif self:IsMoveEvent(event) then
            if not self._preview and self._frameCount > self.MinFrameTime then
                self:CreatePreview()
            end
            -- LOG "Move"
            self:AddPoint(GetMouseWorldPos())
        elseif self:IsEndEvent(event) then
            self:EndLineMove(event.Modifiers)
        elseif self:IsCancelEvent(event) then
            self:EndLineMove(event.Modifiers)
        end
        return false
    end,

    InitPositions = function(self, position)
        for _, unit in self.selection do
            local point = UnitMesh(unit, position)
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
        if not self._preview then return end

        local len = self:GetLineLength()

        if len == 0 then return end

        local unitPositions = self.unitPositions
        local points = self.points

        local unitCount = TableGetN(unitPositions)
        local pointsCount = TableGetN(points)

        local distBetween = len / (unitCount + 1)
        local currentSegmentLength = distBetween
        local curUnitPosition = 1

        local prevPoint = nil
        local i         = 1
        while i < pointsCount do
            local p1 = prevPoint or points[i].position
            local p2 = points[i + 1].position
            local dist = VDist3(p1, p2)
            if dist > currentSegmentLength then
                local s = currentSegmentLength / dist
                prevPoint = unitPositions[curUnitPosition].position

                prevPoint[1] = MATH_Lerp(s, p1[1], p2[1])
                prevPoint[2] = MATH_Lerp(s, p1[2], p2[2])
                prevPoint[3] = MATH_Lerp(s, p1[3], p2[3])

                unitPositions[curUnitPosition]:SetPosition(prevPoint)

                curUnitPosition = curUnitPosition + 1
                currentSegmentLength = distBetween
                if curUnitPosition > unitCount then
                    break
                end
            else
                currentSegmentLength = currentSegmentLength - dist
                prevPoint = p2
                i = i + 1
            end
        end
    end,

    ---comment
    ---@param self MouseMonitor
    ---@param mods EventModifiers
    GiveOrders = function(self, mods)
        if TableGetN(self.points) <= 1 then return end

        local cmodeData = CommandMode.GetCommandMode()[2]
        local orderType = cmodeData.name and toCommandType[cmodeData.name] or 'Move'

        if mods.Alt then
            orderType = "AttackMove"
        end

        local curve = {}
        for i, point in self.points do
            curve[i] = point.position
        end
        GiveOrders(curve, orderType, true)
    end
}
