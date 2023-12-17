local TableGetN = table.getn
local EntityCategoryFilterDown = EntityCategoryFilterDown

---@class CategoryMatcher
---@field description string
---@field _actions CategoryAction[]
CategoryMatcher = Class()
{
    __init = function(self, description)
        self.description = description
    end,

    __call = function(self, actions)
        self._actions = actions
        return self
    end,

    ---@param self CategoryMatcher
    ---@param selection UserUnit[]?
    Process = function(self, selection)
        for _, action in ipairs(self._actions) do
            if action:Process(selection) then
                break
            end
        end
    end,
}

---@alias Action string | fun(selection:UserUnit[])

---@class CategoryAction
---@field _actions Action[]
---@field _category? EntityCategory
---@field _matcher false|fun(selection:UserUnit[]?):boolean
CategoryAction = Class()
{
    ---@param self CategoryAction
    ---@param category? EntityCategory
    __init = function(self, category)
        self._actions = {}
        self._category = category
        self._matcher = false
    end,

    ---Add action into list
    ---@param self CategoryAction
    ---@param action Action
    Action = function(self, action)
        table.insert(self._actions, action)
        return self
    end,

    ---Match category and selected units
    ---@param self CategoryAction
    ---@param selection UserUnit[]?
    Matches = function(self, selection)
        if self._matcher then
            return self._matcher(selection)
        end
        return (not self._category and not selection)
            or
            (self._category and selection and
                TableGetN(EntityCategoryFilterDown(self._category, selection)) == TableGetN(selection))
    end,

    ---Set custom category matcher
    ---@param self CategoryAction
    ---@param matcher fun(selection:UserUnit[]?):boolean
    Match = function(self, matcher)
        self._matcher = matcher
        return self
    end,

    ---Process the action
    ---@param self CategoryAction
    ---@param selection UserUnit[]?
    ---@return boolean
    Process = function(self, selection)
        if self:Matches(selection) then
            self:Execute(selection)
            return true
        end
        return false
    end,

    ---@param self CategoryAction
    ---@param selection UserUnit[]?
    Execute = function(self, selection)
        for _, action in self._actions do
            if type(action) == "string" then
                ConExecute(action)
            elseif type(action) == "function" then
                action(selection)
            else
                error()
            end
        end
    end
}

local LuaQ = UMT.LuaQ

local customActions =
{
    ["some_fany_name"] = CategoryMatcher("Fancy Description")
    {
        CategoryAction(), -- do nothing if no selection
        CategoryAction(categories.TRANSPORTATION)
            :Action "StartCommandMode order RULEUCC_Transport",
        CategoryAction(categories.COMMAND + categories.SUBCOMMANDER)
            :Action "UI_Lua import('/lua/ui/game/orders.lua').EnterOverchargeMode()",
        CategoryAction(categories.FACTORY * categories.STRUCTURE)
            :Action(function(selection)
                local isRepeatBuild = selection
                    | LuaQ.any(function(_, unit) return unit:IsRepeatQueue() end)
                    and 'false'
                    or 'true'
                for _, unit in selection do
                    unit:ProcessInfo('SetRepeatQueue', isRepeatBuild)
                end
            end)
    },
}

---@type table<string, CategoryMatcher>
local categotyActions = {}
function ProcessAction(name)
    if not categotyActions[name] then
        WARN("Huh?")
        return
    end
    categotyActions[name]:Process(GetSelectedUnits())
end

---@param actions table<string, CategoryMatcher>
function RegisterActions(actions)
    for name, action in actions do
        categotyActions[name] = action
        import("/lua/keymap/keymapper.lua").SetUserKeyAction(name,
            {
                action = "UI_Lua import('/mods/AKA/Main.lua').ProcessAction('" .. name .. "')",
                category = "AKA"
            })
        import("/lua/keymap/keydescriptions.lua").keyDescriptions[name] = action.description
    end
end

function Main()
    RegisterActions(customActions)
end
