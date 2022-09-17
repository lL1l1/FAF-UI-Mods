

local KeyMapper = import('/lua/keymap/keymapper.lua')
KeyMapper.SetUserKeyAction('PaintTool', {action = "UI_Lua import('"..modpath.."/modules/paint.lua').TacticalPaint()", category = 'TacticalPaint', order = 359,})
-- KeyMapper.SetUserKeyAction('Add Smd Ring', {action = "UI_Lua import('"..modpath.."/modules/DrawRing.lua').DrawRing()", category = 'TacticalPaint', order = 360,})
-- KeyMapper.SetUserKeyAction('Delete nearers to cursor smd ring', {action = "UI_Lua import('"..modpath.."/modules/DrawRing.lua').DeleteRing()", category = 'TacticalPaint', order = 361,})
-- KeyMapper.SetUserKeyAction('Hide/show smd rings', {action = "UI_Lua import('"..modpath.."/modules/DrawRing.lua').ChangeShowState()", category = 'TacticalPaint', order = 362,})



local originalCreateUI = CreateUI

function CreateUI(isReplay)
    originalCreateUI(isReplay)
    
    import("/mods/TP/modules/paint.lua").init(isReplay)
    --import(modpath .. "/modules/DrawRing.lua").init(isReplay)
end