local KeyMapper = import("/lua/keymap/keymapper.lua")

---@class CategoryMatcher
CategoryMatcher = Class()
{
    __init = function(self, description)

    end,

    __call = function(self, actions)

    end,
    Process = function(self, selection)

    end
}

---@alias Action string|fun(selection:UserUnit[])

---@class CategoryAction
---@field _actions Action[]
---@field _category EntityCategory
CategoryAction = Class()
{
    ---@param self any
    ---@param category any
    __init = function(self, category)
        self._actions = {}
        self._category = category
    end,

    ---comment
    ---@param self CategoryAction
    ---@param action any
    Action = function(self, action)
        table.insert(self._actions, action)
    end,

    ---comment
    ---@param self CategoryAction
    Match = function(self, selection)

        return false
    end,

    ---comment
    ---@param self CategoryAction
    Process = function(self, selection)
        if self:Match(selection) then
            self:Execute(selection)
            return true
        end
        return false
    end,

    ---comment
    ---@param self CategoryAction
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



local actions =
{
    ["some_fany_name"] = CategoryMatcher("Fancy Description")
    {
        CategoryAction(), -- do nothing if no selection
        CategoryAction(categories.TRANSPORTATION)
            :Action "StartCommandMode order RULEUCC_Transport",
        CategoryAction(categories.COMMAND + categories.SUBCOMMANDER)
            :Action "UI_Lua import('/lua/ui/game/orders.lua').EnterOverchargeMode()",
    },
}


function Main()


end
