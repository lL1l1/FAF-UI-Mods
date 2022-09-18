local MathFloor = math.floor
local LayoutFor = LayoutHelpers.ReusedLayoutFor
local LazyVar = import("/lua/lazyvar.lua")
local MathMax = math.max
local MathMin = math.min

local function ComputeLabelProperties(mass)
    if mass < 10 then
        return nil, nil
    end
    -- change color according to mass value
    if mass < 100 then
        return 'ffc7ff8f', 10
    end

    if mass < 300 then
        return 'ffd7ff05', 12
    end

    if mass < 600 then
        return 'ffffeb23', 17
    end

    if mass < 1000 then
        return 'ffff9d23', 20
    end

    if mass < 2000 then
        return 'ffff7212', 22
    end

    -- > 2000
    return 'fffb0303', 25
end

ReclaimLabel = Class(WorldLabel)
{
    __init = function(self, parent)
        WorldLabel.__init(self, parent, Vector(0, 0, 0))

        self._mass = Bitmap(self)
        self._text = UIUtil.CreateText(self, "", 10, UIUtil.bodyFont, true)

        self._oldMass = 0

        self.PosX = LazyVar.Create()
        self.PosY = LazyVar.Create()
    end,

    __post_init = function(self)
        self:_Layout()
        self:Update()
    end,

    _Layout = function(self)
        self._mass.Height:Set(10)
        self._mass.Width:Set(10)

        LayoutFor(self._mass)
            :Texture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            :AtCenterIn(self)

        LayoutFor(self._text)
            :Color('ffc7ff8f')
            :Above(self._mass, 2)
            :AtHorizontalCenterIn(self)

        local view = self.parent.view
        LayoutFor(self)
            :Left(function()
                return view.Left() + self.PosX() - self.Width() / 2
            end)
            :Top(function()
                return view.Top() + self.PosY() - self.Height() / 2
            end)
            :DisableHitTest(true)
    end,

    OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end,


    Update = function(self)
        local proj = self.parent.view:Project(self.position)
        self.PosX:Set(proj.x)
        self.PosY:Set(proj.y)
        if self._isTextHidden then
            self._text:Hide()
        end
    end,

    SetValue = function(self, value)

    end,

    DisplayReclaim = function(self, reclaim)

    end

}

local function CreateReclaimLabel(view, recl)
    local label = WorldLabel(view, Vector(0, 0, 0))

    label.mass = Bitmap(label)
    label.oldMass = 0 -- fix compare bug
    label.mass:SetTexture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
    label.mass.Height:Set(10)
    label.mass.Width:Set(10)
    LayoutHelpers.AtCenterIn(label.mass, label)


    label.text = UIUtil.CreateText(label, "", 10, UIUtil.bodyFont)
    label.text:SetColor('ffc7ff8f')
    label.text:SetDropShadow(true)
    LayoutHelpers.Above(label.text, label.mass, 2)
    LayoutHelpers.AtHorizontalCenterIn(label.text, label)


    label:DisableHitTest(true)
    label.OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end


    label.PosX = LazyVar.Create()
    label.PosY = LazyVar.Create()
    label.Left:Set(function()
        return view.Left() + label.PosX() - label.Width() / 2
    end)
    label.Top:Set(function()
        return view.Top() + label.PosY() - label.Height() / 2 + 1
    end)
    label.Update = function(self)
        local proj = self.parent.view:Project(self.position)
        self.PosX:Set(proj.x)
        self.PosY:Set(proj.y)
        if self.istexthidden then
            self.text:Hide()
        end
    end

    label.SetText = function(self, value)

        local color, size = ComputeLabelProperties(value)
        if color then
            self.text:SetFont(UIUtil.bodyFont, size) -- r.mass > 2000
            self.text:SetColor(color)
            self.text:Show()
            self.istexthidden = false
        else
            self.text:Hide()
            self.istexthidden = true
        end
    end

    label.DisplayReclaim = function(self, r)
        if self:IsHidden() then
            self:Show()
        end
        self:SetPosition(r.position)
        if r.mass ~= self.oldMass then
            -- local avgMass = math.floor(r.mass / r.count)
            local maxMass = r.max or (r.mass + 0.5)
            local massStr = tostring(math.floor(0.5 + r.mass))
            local measure = maxMass
            self:SetText(measure)
            self.text:SetText(massStr)
            self.oldMass = r.mass
        end
    end

    label:Update()

    return label
end

local function SumReclaim(r1, r2)
    local massSum = r1.mass + r2.mass
    r1.count = r1.count + (r2.count or 1)
    r1.position[1] = (r1.mass * r1.position[1] + r2.mass * r2.position[1]) / massSum
    r1.position[3] = (r1.mass * r1.position[3] + r2.mass * r2.position[3]) / massSum
    r1.max = MathMax(r1.max or r1.mass, r2.mass)
    r1.mass = massSum
    return r1
end

local function CompareMass(a, b)
    return a.mass > b.mass
end

local HEIGHT_RATIO = 0.012
local ZOOM_THRESHOLD = 100

local function CombineReclaim(reclaim)
    local zoom = GetCamera('WorldCamera'):SaveSettings().Zoom

    if zoom < ZOOM_THRESHOLD then
        return reclaim
    end

    local minDist = zoom * HEIGHT_RATIO
    local minDistSq = minDist * minDist
    local index = 1
    local combinedReclaim = {}

    local added

    local x1
    local x2
    local y1
    local y2
    local dx
    local dy

    for _, r in reclaim do
        added = false
        x1 = r.position[1]
        y1 = r.position[3]
        for _, cr in combinedReclaim do
            x2 = cr.position[1]
            y2 = cr.position[3]
            dx = x1 - x2
            dy = y1 - y2
            if dx * dx + dy * dy < minDistSq then
                added = true
                SumReclaim(cr, r)
                break
            end
        end
        if not added then
            combinedReclaim[index] = {
                mass = r.mass,
                position = r.position,
                count = 1
            }
            index = index + 1
        end
    end
    return combinedReclaim
end

local mapWidth = 0
local mapHeight = 0
function SetMapSize()
    mapWidth = SessionGetScenarioInfo().size[1]
    mapHeight = SessionGetScenarioInfo().size[2]
end

local function IsInMapArea(pos)
    if PlayableArea then
        return pos[1] > PlayableArea[1] and pos[1] < PlayableArea[3] or
            pos[3] > PlayableArea[2] and pos[3] < PlayableArea[4]
    else
        return pos[1] > 0 and pos[1] < mapWidth or pos[3] > 0 and pos[3] < mapHeight
    end
end

function UpdateLabels()
    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera
    local onScreenReclaimIndex = 1
    local onScreenReclaims = {}

    local tl = UnProject(view, Vector2(view.Left(), view.Top()))
    local tr = UnProject(view, Vector2(view.Right(), view.Top()))
    local br = UnProject(view, Vector2(view.Right(), view.Bottom()))
    local bl = UnProject(view, Vector2(view.Left(), view.Bottom()))


    local checkForContainment = IsInMapArea(tl) or IsInMapArea(tr) or IsInMapArea(bl) or IsInMapArea(br)


    local x0
    local y0
    local x1 = tl[1]
    local y1 = tl[3]
    local x2 = tr[1]
    local y2 = tr[3]
    local x3 = br[1]
    local y3 = br[3]
    local x4 = bl[1]
    local y4 = bl[3]

    local minX = MathMin(x1, x2, x3, x4)
    local maxX = MathMax(x1, x2, x3, x4)
    local minY = MathMin(y1, y2, y3, y4)
    local maxY = MathMax(y1, y2, y3, y4)


    local y21 = (y2 - y1)
    local y32 = (y3 - y2)
    local y43 = (y4 - y3)
    local y14 = (y1 - y4)
    local x21 = (x2 - x1)
    local x32 = (x3 - x2)
    local x43 = (x4 - x3)
    local x14 = (x1 - x4)

    local s1
    local s2
    local s3
    local s4

    local function Contains(point)
        x0 = point[1]
        y0 = point[3]
        if x0 < minX or x0 > maxX or y0 < minY or y0 > maxY then
            return false
        end
        s1 = (x1 - x0) * y21 - x21 * (y1 - y0)
        s2 = (x2 - x0) * y32 - x32 * (y2 - y0)
        s3 = (x3 - x0) * y43 - x43 * (y3 - y0)
        s4 = (x4 - x0) * y14 - x14 * (y4 - y0)
        return (s1 > 0 and s2 > 0 and s3 > 0 and s4 > 0)
    end

    for _, r in Reclaim do
        if r.mass >= MinAmount and (not checkForContainment or Contains(r.position)) then
            onScreenReclaims[onScreenReclaimIndex] = r
            onScreenReclaimIndex = onScreenReclaimIndex + 1
        end
    end


    onScreenReclaims = CombineReclaim(onScreenReclaims)


    table.sort(onScreenReclaims, CompareMass)

    local labelIndex = 1

    for _, recl in onScreenReclaims do
        if labelIndex > MaxLabels then
            break
        end
        local label = LabelPool[labelIndex]
        if label and IsDestroyed(label) then
            label = nil
        end
        if not label then
            label = CreateReclaimLabel(view.ReclaimGroup, recl)
            LabelPool[labelIndex] = label
        end

        label:DisplayReclaim(recl)
        labelIndex = labelIndex + 1
    end

    -- Hide labels we didn't use
    for index = labelIndex, MaxLabels do
        local label = LabelPool[index]
        if label then
            if IsDestroyed(label) then
                LabelPool[index] = nil
            elseif not label:IsHidden() then
                label:Hide()
            end
        end
    end
end
