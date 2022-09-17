local acu
local commandmode = import('/lua/ui/game/commandmode.lua')
function Main()
    ForkThread(function()
        LOG("pauseAFK thread started")
        -- wait until acu appears
        WaitSeconds(5)
        GetACU()
        -- LOG("ACU FOUND:")
        -- LOG(repr(acu))
        if not CheckPlayerActive() then
            SessionRequestPause()
            local text = import("/mods/PausePlzAfk/Message.lua").message
            local msg = {
                to = 'all',
                Chat = true,
                text = text
            }
            SessionSendChatMessage(import('/lua/ui/game/chat.lua').FindClients(), msg)

            WaitSeconds(1)
            msg = {
                to = 'all',
                Chat = true,
                text = '<<message sent with "Pause plz AFK" mod>>'
            }
            SessionSendChatMessage(import('/lua/ui/game/chat.lua').FindClients(), msg)

        end
    end)
end
function GetACU()
    local current_command
    while true do
        --current_command = commandmode.GetCommandMode()
        --ConExecute('UI_SelectByCategory  COMMAND')
        acu = GetSelectedUnits()
        --SelectUnits(acu)
        --commandmode.StartCommandMode(current_command[1], current_command[2])
        if acu ~= nil then
            return
        end
        WaitSeconds(0.1)
    end
end

function WaitSimTicks(n)
    local currentTick = GameTick()
    while currentTick + n > GameTick() do
        WaitSeconds(0.1)
    end
end

local ticksToWait = 10
function CheckPlayerActive()

    for i = 1, ticksToWait do
        if not acu[1]:IsIdle() then
            return true
        end
        WaitSimTicks(1)
    end
    return false

end

