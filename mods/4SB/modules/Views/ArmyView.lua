local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutFor = LayoutHelpers.ReusedLayoutFor
local LazyVar = import('/lua/lazyvar.lua').Create


---@module "Animations/Animator"
local Animator = import("../Animations/Animator.lua")
local alphaAnimator = Animator.Animator(GetFrame(0))


---@class BaseAnimationFactory
local animationFactory = import("../Animations/AnimationFactory.lua").GetAnimationFactory()


local alphaAnimationFactory = import("../Animations/AnimationFactory.lua").GetAlphaAnimationFactory()
local appearAnimation = alphaAnimationFactory
    :ToAppear()
    :For(0.2)
    :EndWith(1)
    :Create(alphaAnimator)

local fadeAnimation = alphaAnimationFactory
    :ToFade()
    :For(0.2)
    :EndWith(0)
    :Create(alphaAnimator)

---@module "4SBUtils"
local Utils = import("../Utils.lua")
local FormatRatioNumber = Utils.FormatRatioNumber
local TextWidth = Utils.TextWidth
local Border = import("Border.lua").Border
local ShareManager = import("../ShareManager.lua")

local checkboxes = import("../DataPanelConfig.lua").checkboxes

local bgColor = UIUtil.disabledColor
local bgColor = 'ff000000'

local armyViewTextPointSize = 12

local armyViewTextFont = "Zeroes Three"
local focusArmyTextFont = 'Arial Bold'

local nameWidth = LazyVar(20)


local armyViewWidth = 250
local allyViewWidth = 350



local armyViewHeight = 20

local animationSpeed = 250

local outOfGameColor = "ffa0a0a0"

local slideForward = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        if control.Right() <= control.parent.Right() then
            return true
        end
        control.Right:Set(control.Right() - delta * animationSpeed)
    end)
    :OnFinish(function(control)
        control.Right:Set(control.parent.Right)
    end)
    :Create()

local slideBackWards = animationFactory
    :OnStart()
    :OnFrame(function(control, delta)
        if control.parent.Right() < control._energyBtn.Left() then
            return true
        end
        control.Right:Set(control.Right() + delta * animationSpeed)
    end)
    :OnFinish(function(control)
        local offset = math.floor(control.Right() - control._massBtn.Left())
        control.Right:Set(function() return control.parent.Right() + offset end)
    end)
    :Create()


ArmyView = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self.parent = parent

        self.id = -1
        self.isOutOfGame = false

        self._bg = Bitmap(self)


        self._color = Bitmap(self)
        self._faction = Bitmap(self)
        self._rating = Text(self)
        self._name = Text(self)
    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)

        LayoutFor(self._bg)
            :Fill(self)
            :Color(bgColor)
            :Alpha(0.4)
            :DisableHitTest()

        LayoutFor(self._name)
            :AtVerticalCenterIn(self)
            :AtRightIn(self, 20)
            :DisableHitTest()
            :DropShadow(true)

        LayoutFor(self._rating)
            :AtVerticalCenterIn(self)
            :LeftOf(self._name, 7)
            :DisableHitTest()
            :DropShadow(true)

        LayoutFor(self._faction)
            :AtVerticalCenterIn(self)
            :AtRightIn(self._rating, 30)
            :Over(self, 5)
            :DisableHitTest()

        LayoutFor(self._color)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Right(self.Left)
            --:Alpha(0.9)
            :Width(3)
            :DisableHitTest()

        LayoutFor(self)
            :AtLeftIn(self._faction, -5)
            :Height(armyViewHeight)

    end,

    SetStaticData = function(self, armyId, name, rating, faction, armyColor, teamColor)
        self.id = armyId

        self._color:SetSolidColor(teamColor)

        self._rating:SetColor(armyColor)
        self._rating:SetText(rating)
        self._rating:SetFont(armyViewTextFont, armyViewTextPointSize)

        self._name:SetText(name)
        self._name:SetClipToWidth(true)
        self._name.Width:Set(nameWidth)
        nameWidth:Set(math.max(nameWidth(), TextWidth(name, armyViewTextFont, armyViewTextPointSize)))
        self._name:SetFont(armyViewTextFont, armyViewTextPointSize)

        self._faction:SetTexture(UIUtil.UIFile(Utils.GetSmallFactionIcon(faction)), 0)
    end,

    Update = function(self, data)
        if not self.isOutOfGame and data.Defeated then
            self.isOutOfGame = true
            self._name:SetColor(outOfGameColor)
        end
    end
}


AllyView = Class(ArmyView)
{
    __init = function(self, parent)
        ArmyView.__init(self, parent)

        self._mass = Text(self)
        self._energy = Text(self)

        self._massBtn = Bitmap(self)
        self._energyBtn = Bitmap(self)

        self._unitsBtn = Bitmap(self)

        self._mass:SetText("0")
        self._energy:SetText("0")


        self._massBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    ShareManager.GiveMassToPlayer(self.id)
                elseif event.Modifiers.Right then
                    ShareManager.RequestMassFromPlayer(self.id)
                else

                end
                return true
            end
        end
        self._energyBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    ShareManager.GiveEnergyToPlayer(self.id)
                elseif event.Modifiers.Right then
                    ShareManager.RequestEnergyFromPlayer(self.id)
                else
                end
                return true
            end
        end
        self._unitsBtn.HandleEvent = function(control, event)
            if event.Type == "ButtonPress" then
                if event.Modifiers.Left then
                    ShareManager.GiveUnitsToPlayer(self.id)
                elseif event.Modifiers.Right then
                    ShareManager.RequestUnitFromPlayer(self.id)
                else
                end
                return true
            end

        end
    end,

    _Layout = function(self)
        ArmyView._Layout(self)

        LayoutFor(self._unitsBtn)
            :AtRightIn(self, 5)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile('/textures/ui/icons_strategic/commander_generic.dds'))
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()

        LayoutFor(self._energyBtn)
            :LeftOf(self._unitsBtn, 5)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile('/game/build-ui/icon-energy_bmp.dds'))
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()


        LayoutFor(self._massBtn)
            :LeftOf(self._energyBtn, 5)
            :AtVerticalCenterIn(self)
            :Texture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            :Width(14)
            :Height(14)
            :Over(self, 5)
            :EnableHitTest()

        LayoutFor(self._energy)
            :LeftOf(self._massBtn, 10)
            :AtVerticalCenterIn(self)
            :Color('fff7c70f')
            :DisableHitTest()
        self._energy:SetFont(armyViewTextFont, armyViewTextPointSize)



        LayoutFor(self._mass)
            :LeftOf(self._massBtn, 45)
            :AtVerticalCenterIn(self)
            :Color('ffb7e75f')
            :DisableHitTest()
        self._mass:SetFont(armyViewTextFont, armyViewTextPointSize)

        LayoutFor(self._name)
            :LeftOf(self._massBtn, 75)



    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            slideBackWards:Apply(self)
            return true
        elseif event.Type == 'MouseEnter' then
            slideForward:Apply(self)
            return true
        end

        return false
    end,

    Update = function(self, data)
        if self.id == GetFocusArmy() then
            -- self._energy:Hide()
            -- self._mass:Hide()

        else
        end


        ArmyView.Update(self, data)
        if not self.isOutOfGame then
            local resources = data.resources
            if resources then
                self._energy:SetText(FormatNumber(resources.energyin.rate * 10))
                self._mass:SetText(FormatNumber(resources.massin.rate * 10))
            else
                self._energy:SetText("")
                self._mass:SetText("")
            end
        end
    end



}

local dataTextOffSet = 40

local dataTextOffSetScaled = LayoutHelpers.ScaleNumber(dataTextOffSet)

local dataAnimationSpeed = 150

local contractDataAnimation = animationFactory
    :OnStart(function(control, state, nextControl)
        fadeAnimation:Apply(control)
        control._contracted = true
        return state or { nextControl = nextControl }
    end)
    :OnFrame(function(control, delta, state)
        if control.Right() >= state.nextControl.Right() then
            return true
        end
        control.Right:Set(control.Right() + delta * dataAnimationSpeed)
    end)
    :OnFinish(function(control, state)
        control.Right:Set(state.nextControl.Right)
    end)
    :Create()

local expandDataAnimation = animationFactory
    :OnStart(function(control, state, nextControl)
        appearAnimation:Apply(control)
        control._contracted = false
        return state or { nextControl = nextControl }
    end)
    :OnFrame(function(control, delta, state)
        if control.Right() <= state.nextControl.Right() - dataTextOffSetScaled then
            return true
        end
        control.Right:Set(control.Right() - delta * dataAnimationSpeed)
    end)
    :OnFinish(function(control, state)
        LayoutHelpers.AtRightIn(control, state.nextControl, dataTextOffSet)
    end)
    :Create()

ReplayArmyView = Class(ArmyView)
{
    __init = function(self, parent)
        ArmyView.__init(self, parent)

        self._data = {}
        for i = 1, table.getn(checkboxes) do
            self._data[i] = Text(self)
        end
    end,

    _Layout = function(self)
        ArmyView._Layout(self)


        local dataSize = table.getn(self._data)
        for i = 1, dataSize do
            if i == 1 then
                LayoutFor(self._name)
                    :AtRightIn(self._data[i], dataTextOffSet)
                LayoutFor(self._data[i])
                    :AtRightIn(self._data[i + 1], dataTextOffSet)
                    :AtVerticalCenterIn(self)
                    :DisableHitTest()
            elseif i == dataSize then
                LayoutFor(self._data[i])
                    :AtRightIn(self, dataTextOffSet)
                    :AtVerticalCenterIn(self)
                    :DisableHitTest()
            else
                LayoutFor(self._data[i])
                    :AtRightIn(self._data[i + 1], dataTextOffSet)
                    :AtVerticalCenterIn(self)
                    :DisableHitTest()
            end
            self._data[i]:SetFont(armyViewTextFont, armyViewTextPointSize)
            self._data[i]:SetText("0")
            self._data[i]._contracted = false
        end

    end,


    Update = function(self, data, setup)
        ArmyView.Update(self, data)
        for i, dataText in self._data do
            local checkboxData = checkboxes[i][ setup[i] ]
            local color = checkboxData.nc
            local text = FormatRatioNumber(checkboxData.GetData(data))
            dataText:SetText(text)
            dataText:SetColor(color)
        end
    end,

    HandleEvent = function(self, event)

        if event.Type == 'ButtonPress' and event.Modifiers.Left and not event.Modifiers.Shift and
            not event.Modifiers.Ctrl then
            ConExecute('SetFocusArmy ' .. tostring(self.id - 1))
        end

    end,

    ContractData = function(self, id)
        assert(table.getn(self._data) >= id, "pain")

        if table.getn(self._data) == id then
            local nextControl = self
            local control = self._data[id]

            contractDataAnimation:Apply(control, nextControl)
        else
            local nextControl = self._data[id + 1]
            local control = self._data[id]

            contractDataAnimation:Apply(control, nextControl)
        end

    end,

    ExpandData = function(self, id)
        assert(table.getn(self._data) >= id, "pain")

        if table.getn(self._data) == id then
            local nextControl = self
            local control = self._data[id]

            expandDataAnimation:Apply(control, nextControl)
        else
            local nextControl = self._data[id + 1]
            local control = self._data[id]

            expandDataAnimation:Apply(control, nextControl)
        end

    end,
}
