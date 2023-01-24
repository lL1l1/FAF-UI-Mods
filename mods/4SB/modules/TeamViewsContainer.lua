local Utils = import("Utils.lua")
local ArmyViewsContainer = import("ArmyViewsContainer.lua").ArmyViewsContainer
local ArmyViews = import("Views/ArmyView.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor
local LuaQ = UMT.LuaQ



TeamViewsContainer = Class(ArmyViewsContainer)
{

    _InitArmyViews = function(self)

        self._armyViews = {}

        local armiesData = Utils.GetArmiesFormattedTable()

        local teams = armiesData | LuaQ.select "teamId"
            | LuaQ.toSet
            | LuaQ.select.keyvalue(function(id)
                return armiesData
                    | LuaQ.where(function(armyData) return armyData.teamId == id end)
                    | LuaQ.select "id"
            end)
        self._teams = teams
        self._armyDataCache = armiesData
        if teams | LuaQ.count.keyvalue == armiesData | LuaQ.count then return end

        for team, armies in teams do
            local teamView = ArmyViews.ReplayTeamView(self)
            local teamColor = (armiesData | LuaQ.first(function(armyData) return armyData.teamId == team end)).teamColor
            local rating = armiesData |
                LuaQ.sum(function(armyData) return armyData.teamId == team and armyData.rating or 0 end)

            teamView:SetStaticData(
                team,
                ("Team %d"):format(team),
                rating,
                teamColor,
                armies
            )

            table.insert(self._lines, teamView)
            self._armyViews[team] = teamView
        end

    end,

    Update = function(self, data)
        if data then
            for i, armyView in self._armyViews do
                armyView:Update(data, self._dataSetup)
            end
        end
    end,
}