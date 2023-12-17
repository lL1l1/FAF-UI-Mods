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

---@class CategoryAction
CategoryAction = Class()
{
    __init = function(self, category)

    end,

    Action = function(self, action)

    end,

    Match = function(self, selection)
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
    }
}


function Main()


end
