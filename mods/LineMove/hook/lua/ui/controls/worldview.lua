do
    local oldWorldView = WorldView
    --local Dragger = import("/lua/maui/dragger.lua").Dragger
    WorldView = Class(oldWorldView) {
        ---@param self WorldView
        ---@param event KeyEvent
        HandleEvent = function(self, event)
            import("/mods/LineMove/modules/Main.lua").HandleEvent(self, event)
            return oldWorldView.HandleEvent(self, event)
        end

    }
end
