



---@param worldview WorldView
---@param event KeyEvent
function HandleEvent(worldview, event)
    if not event.Modifiers.Right then return end

    if event.Type == "ButtonPress" then
        LOG("Press")
    elseif event.Type == "MouseMotion" then
        LOG("move")
    end

end
