-- upvalue for performance
local TableInsert = table.insert
local EntityCategoryFilterDown = EntityCategoryFilterDown
local categoryMASSEXTRACTION = categories.MASSEXTRACTION
local GetIsPaused = GetIsPaused

local AddBeatFunction = import('/lua/ui/game/gamemain.lua').AddBeatFunction
local GetUnits = import('/mods/common/units.lua').Get
local From = import('/mods/UMT/modules/linq.lua').From
local UpdateMexPanel = import('mexpanel.lua').Update

local mexCategories = import('mexcategories.lua').mexCategories
local mexData = {}

local function GetUpgradingMexes(mexes)
    return From(mexes):Map(function(k, mex)
        return mex:GetWorkProgress()
    end):Sort(function(a, b)
        return a > b
    end):ToArray()
end

function PauseWorst(id)
    local mexes = mexData[id].mexes
    SetPaused({mexes[table.getn(mexes)]}, true)
end

function UnPauseBest(id)
    local mexes = mexData[id].mexes
    SetPaused({mexes[1]}, false)
end

function SelectBest(id)
    local mexes = mexData[id].mexes
    SelectUnits({mexes[1]})
end

function SelectAll(id)
    local mexes = mexData[id].mexes
    SelectUnits(mexes)
end

function SetPausedAll(id, state)
    local mexes = mexData[id].mexes
    SetPaused(mexes, state)
end

local function MatchCategory(category, unit)
    local isUpgrading = unit:GetWorkProgress() > 0

    if unit.isUpgraded then
        return false
    end

    if not EntityCategoryContains(category.categories, unit) then
        return false
    end

    if isUpgrading ~= category.isUpgrading then
        return false
    end

    if category.isPaused ~= nil then
        if GetIsPaused({unit}) ~= category.isPaused then
            return false
        end
    end

    return true
end

local function UpdateUI()
    local mexes = GetUnits()
    mexes = EntityCategoryFilterDown(categoryMASSEXTRACTION, mexes)

    for id, category in mexCategories do
        mexData[id] = {
            mexes = {}

        }
    end

    for _, mex in mexes do
        mex.isUpgraded = false
    end
    for _, mex in mexes do
        local f = mex:GetFocus()
        if f ~= nil and f:IsInCategory("STRUCTURE") then
            f.isUpgraded = true
        end
    end

    for _, mex in mexes do
        for id, category in mexCategories do
            if MatchCategory(category, mex) then
                TableInsert(mexData[id].mexes, mex)
                break
            end
        end
    end

    for id, category in mexCategories do

        if category.isUpgrading and not table.empty(mexData[id].mexes) then
            local sortedMexes = From(mexData[id].mexes):Sort(function(a, b)
                return a:GetWorkProgress() > b:GetWorkProgress()
            end)

            local sorted = sortedMexes:Map(function(k, m)
                return m:GetWorkProgress()
            end):ToDictionary()

            mexData[id].progress = sorted

            mexData[id].mexes = sortedMexes:ToDictionary()
        end
    end

    UpdateMexPanel(mexData)

end

function init()
    AddBeatFunction(UpdateUI, true)
end

