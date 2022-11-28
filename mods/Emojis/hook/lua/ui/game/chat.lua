local UiUtilsS = import('/lua/UiUtilsSorian.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local EffectHelpers = import('/lua/maui/effecthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/ui/controls/checkbox.lua').Checkbox
local Button = import('/lua/maui/button.lua').Button
local Text = import('/lua/maui/text.lua').Text
local Edit = import('/lua/maui/edit.lua').Edit
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Window = import('/lua/maui/window.lua').Window
local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local Prefs = import('/lua/user/prefs.lua')
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Tooltip = import('/lua/ui/game/tooltip.lua')
local UIMain = import('/lua/ui/uimain.lua')
--this one from lobby mod manager
local CheckBox = import('/lua/maui/checkbox.lua').Checkbox
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText

--[[ LOC Strings
<LOC chat_win_0001>To %s:
<LOC chat_win_0002>Chat (%d - %d of %d lines)
--]]
local emojis_textures = '/mods/Emojis/Packs/'

--TODO:
--trash vars remove them
local Packages = {} -- emojis' packages data
-- local countPacks = 0
--local MaxElements = 10
local lineHeight = 30







local chatColors = {'ffffffff', 'ffff4242', 'ffefff42','ff4fff42', 'ff42fff8', 'ff424fff', 'ffff42eb', 'ffff9f42'}



function ScanPackages()
    --LOG(type(function()return  end))
    -- local infoFiles = DiskFindFiles('/mods/Emojis/Packs/','*_info\.lua')
    -- LOG(repr(infoFiles))
    
    local data = DiskFindFiles('/mods/Emojis/Packs/','*\.dds')
    --LOG(repr(data))
    for _,pathdata in data do
        --LOG('|')
        local SepPath = {}
        for v in string.gfind(pathdata,'[^/\.]+') do -- separating path
            table.insert(SepPath,v)
            --LOG(v)
        end

        local package = SepPath[table.getn(SepPath)-2]--package name
        local emoji = SepPath[table.getn(SepPath)-1]--filename

        if not Packages[package] then
            Packages[package] = {}
            --countPacks = countPacks  + 1
            Packages[package].emojis = {}
            if DiskGetFileInfo('/mods/Emojis/Packs/'..package..'/_info.lua') then
                Packages[package].info = import('/mods/Emojis/Packs/'..package..'/_info.lua').info or
                 {
                    name = package,
                    description = "NONE",
                    author = "NONE",
                }
            end
        end
        table.insert(Packages[package].emojis, emoji)
       
           
        --LOG(repr(string.gfind(pathdata,'/[^/]+.dds')))
    end
    
    --LOG(repr(Packages))
    --Prefs.SetToCurrentProfile("emojipacks", ChatOptions)
    local packsStates = Prefs.GetFromCurrentProfile('emojipacks') or {}
    for packname,pack in Packages do
        if packsStates[packname] ~= nil then
            pack.info.isEnabled = packsStates[packname]
        else
            packsStates[packname] = true
            pack.info.isEnabled = true
        end
    end
    -- LOG(repr(Packages))
    -- LOG(repr(packsStates))
    Prefs.SetToCurrentProfile("emojipacks", packsStates)
    -- LOG(table.getsize(Packages))
    -- LOG(repr(Packages))
    -- LOG(countPacks)
end


local oldCreateChatBackground = CreateChatBackground
function CreateChatBackground()
    ScanPackages()
    return oldCreateChatBackground()
end

function CreateChat()
    if GUI.bg then
        GUI.bg.OnClose()
    end
    GUI.bg = CreateChatBackground()
    GUI.chatEdit = CreateChatEdit()
    GUI.bg.OnResize = function(self, x, y, firstFrame)
        if firstFrame then
            self:SetNeedsFrameUpdate(false)
        end
        CreateChatLines()
        GUI.chatContainer:CalcVisible()
    end
    GUI.bg.OnResizeSet = function(self)
        if not self:IsPinned() then
            self:SetNeedsFrameUpdate(true)
        end
        RewrapLog()
        CreateChatLines()
        GUI.chatContainer:CalcVisible()
        GUI.chatEdit.edit:AcquireFocus()
        UpdateEmojiSelector()
        
    end
    GUI.bg.OnMove = function(self, x, y, firstFrame)
        if firstFrame then
            self:SetNeedsFrameUpdate(false)
        end
    end
    GUI.bg.OnMoveSet = function(self)
        GUI.chatEdit.edit:AcquireFocus()
        if not self:IsPinned() then
            self:SetNeedsFrameUpdate(true)
        end
    end
    GUI.bg.OnMouseWheel = function(self, rotation)
        local newTop = GUI.chatContainer.top - math.floor(rotation / 100)
        GUI.chatContainer:ScrollSetTop(nil, newTop)
    end
    GUI.bg.OnClose = function(self)
        ToggleChat()
    end
    GUI.bg.OnOptionsSet = function(self)
        GUI.chatContainer:Destroy()
        GUI.chatContainer = false
        for i, v in GUI.chatLines do
            v:Destroy()
        end
        GUI.bg:SetAlpha(ChatOptions.win_alpha, true)
        GUI.chatLines = {}
        CreateChatLines()
        RewrapLog()
        GUI.chatContainer:CalcVisible()
        GUI.chatEdit.edit:AcquireFocus()
        if not GUI.bg.pinned then
            GUI.bg.curTime = 0
            GUI.bg:SetNeedsFrameUpdate(true)
        end
    end
    GUI.bg.OnHideWindow = function(self, hidden)
        if not hidden then
            for i, v in GUI.chatLines do
                v:SetNeedsFrameUpdate(false)
            end
        end
    end
    GUI.bg.curTime = 0
    GUI.bg.pinned = false
    GUI.bg.OnFrame = function(self, delta)
        self.curTime = self.curTime + delta
        if self.curTime > ChatOptions.fade_time then
            ToggleChat()
        end
    end
    GUI.bg.OnPinCheck = function(self, checked)
        GUI.bg.pinned = checked
        GUI.bg:SetNeedsFrameUpdate(not checked)
        GUI.bg.curTime = 0
        GUI.chatEdit.edit:AcquireFocus()
        if checked then
            Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pinned')
        else
            Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pin')
        end
    end
    GUI.bg.OnConfigClick = function(self, checked)
        if GUI.config then GUI.config:Destroy() GUI.config = false return end
        CreateConfigWindow()
        GUI.bg:SetNeedsFrameUpdate(false)

    end
    for i, v in GetArmiesTable().armiesTable do
        if not v.civilian then
            ChatOptions[i] = true
        end
    end
    GUI.bg:SetAlpha(ChatOptions.win_alpha, true)
    Tooltip.AddButtonTooltip(GUI.bg._closeBtn, 'chat_close')
    GUI.bg.OldHandleEvent = GUI.bg.HandleEvent
    GUI.bg.HandleEvent = function(self, event)
        if event.Type == "WheelRotation" and self:IsHidden() then
            import('/lua/ui/game/worldview.lua').ForwardMouseWheelInput(event)
            return true
        else
            return GUI.bg.OldHandleEvent(self, event)
        end
    end

    Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pin')
    Tooltip.AddControlTooltip(GUI.bg._configBtn, 'chat_config')
    Tooltip.AddControlTooltip(GUI.bg._closeBtn, 'chat_close')
    Tooltip.AddCheckboxTooltip(GUI.chatEdit.camData, 'chat_camera')

    ChatOptions['links'] = ChatOptions.links or true
    CreateChatLines()
    RewrapLog()
    GUI.chatContainer:CalcVisible()
    ToggleChat()
end

function CreateChatLines()    
    local function CreateChatLine()
        local line = Group(GUI.chatContainer)

        -- Draw the faction icon with a colour representing the team behind it.
        line.teamColor = Bitmap(line)
        line.teamColor:SetSolidColor('00000000')
        --LayoutHelpers.SetDimensions(line.teamColor,line.Height(),line.Height())
        -- LayoutHelpers need to be updated btw
        line.teamColor.Height:Set(line.Height)
        line.teamColor.Width:Set(line.Height)
        LayoutHelpers.AtLeftTopIn(line.teamColor, line)

        line.factionIcon = Bitmap(line.teamColor)
        line.factionIcon:SetSolidColor('00000000')
        LayoutHelpers.FillParent(line.factionIcon, line.teamColor)

        -- Player name
        line.name = UIUtil.CreateText(line, '', ChatOptions.font_size, "Arial Bold",true)
        LayoutHelpers.CenteredRightOf(line.name, line.teamColor, 4)
        LayoutHelpers.DepthOverParent(line.name,line,10)
        --line.name.Depth:Set(function() return line.Depth() + 10 end)
        line.name:SetColor('ffffffff')
        line.name:DisableHitTest()
       -- line.name:SetDropShadow(true)

        line.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' then
                if  event.KeyCode == 3 and self.camera then
                    GetCamera('WorldCamera'):RestoreSettings(self.camera)
                end
            end
        end
        line.name.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' then
                if  event.KeyCode == 1 then
                    if self.chatID then
                        if GUI.bg:IsHidden() then GUI.bg:Show() end
                        ChatTo:Set(self.chatID)
                        if GUI.chatEdit.edit then
                            GUI.chatEdit.edit:AcquireFocus()
                        end
                        if GUI.chatEdit.private then
                            GUI.chatEdit.private:SetCheck(true)
                        end
                    end
                -- elseif  event.KeyCode == 3 and self.camera then
                --     GetCamera('WorldCamera'):RestoreSettings(self.camera)
                end
            end
        end

        -- line.text = UIUtil.CreateText(line, '', ChatOptions.font_size, "Arial")
        -- line.text.Depth:Set(function() return line.Depth() + 10 end)
        -- line.text.Left:Set(function() return line.name.Right() + 2 end)
        -- line.text.Right:Set(line.Right)
        -- line.text:SetClipToWidth(true)
        -- line.text:DisableHitTest()
        -- line.text:SetColor('ffc2f6ff')
        -- line.text:SetDropShadow(true)
        -- LayoutHelpers.AtVerticalCenterIn(line.text, line.teamColor)
        -- line.text.HandleEvent = function(self, event)
        --     if event.Type == 'ButtonPress' then
        --         if line.cameraData then
        --             GetCamera('WorldCamera'):RestoreSettings(line.cameraData)
        --         end
        --     end
        -- end

        -- A background for the line that persists after the chat panel is closed (to help with
        -- readability against the simulation)
        line.lineStickybg = Bitmap(line)
        line.lineStickybg:DisableHitTest()
        line.lineStickybg:SetSolidColor('aa000000')
        LayoutHelpers.FillParent(line.lineStickybg, line)
        LayoutHelpers.DepthUnderParent(line.lineStickybg, line)
        line.lineStickybg:Hide()
        line.contents = nil
        line.renderChatLine = function(self,entry,id)
            local Wcontents = entry.wrappedtext[id]
            --(repr(Wcontents))
            if self.contents then
                self.contents:Destroy()
                self.contents = nil
            end
           -- LOG("naming")
            if id == 1 then
                self.name.chatID = entry.armyID
                if self.name.chatID == GetFocusArmy() then 
                    self.name:Disable()
                else
                    self.name:Enable()
                end
                self.name:SetText(entry.name)
                self.camera = entry.camera
                if self.camera then
                    --self.name:Enable()
                    self.name:SetColor(chatColors[ChatOptions.link_color] )
                else
                    self.name:SetColor('ffffffff')
                end
                self.teamColor:SetSolidColor(entry.color)
                self.factionIcon:SetTexture(UIUtil.UIFile(FactionsIcon[entry.faction]))
            else
                self.name:Disable()
                self.name:SetText("")
                self.teamColor:SetSolidColor('00000000')
                self.factionIcon:SetSolidColor('00000000')
            end
            --LOG("onBegin loop")
            local parent = nil
            for _,content in Wcontents do
                if content.text then --TEXT
                    if parent then
                        parent.child = UIUtil.CreateText(parent, '', ChatOptions.font_size, "Arial",true)
                        LayoutHelpers.DepthOverParent(parent.child,self,10)
                        -- parent.child.Depth:Set(function()
                        --     return self.Depth() + 10
                        -- end)
                        -- parent.child.Left:Set(function()
                        --     return parent.Right() + 2
                        -- end)
                        LayoutHelpers.RightOf(parent.child, parent,2)
                        
                        parent.child:DisableHitTest()
                        parent.child:SetColor(chatColors[ChatOptions[entry.tokey]])
                        --parent.child:SetDropShadow(true)
                        LayoutHelpers.AtVerticalCenterIn(parent.child, self.teamColor)
                        parent.child:SetText(content.text)
                        parent.child:SetClipToWidth()
                        parent = parent.child
                    else    
                        self.contents = UIUtil.CreateText(self, '', ChatOptions.font_size, "Arial",true)
                        LayoutHelpers.DepthOverParent(self.contents,self,10)
                        -- self.contents.Depth:Set(function()
                        --     return self.Depth() + 10
                        -- end)
                        
                        LayoutHelpers.RightOf(self.contents, self.name,2)
                        
                        self.contents:DisableHitTest()
                        self.contents:SetColor(chatColors[ChatOptions[entry.tokey]])
                        --self.contents:SetDropShadow(true)
                        LayoutHelpers.AtVerticalCenterIn(self.contents, self.teamColor)
                        self.contents:SetText(content.text)
                        self.contents:SetClipToWidth()
                        parent = self.contents
                    end

                elseif content.emoji then--EMOJIS
                    if parent then
                       
                        parent.child = Bitmap(parent,UIUtil.UIFile(emojis_textures .. content.emoji .. '.dds'))
                        LayoutHelpers.DepthOverParent(parent.child,self.name,0)
                        -- parent.child.Depth:Set(function()
                        --     return self.name.Depth()
                        -- end)
                        
                        LayoutHelpers.CenteredRightOf(parent.child, parent,2)
                        --LayoutHelpers.AtVerticalCenterIn(parent.child, parent)
                        --LayoutHelpers.SetDimensions(parent.child,self.Height,self.Height)
                        parent.child.Height:Set(self.Height)
                        parent.child.Width:Set(self.Height)

                        parent = parent.child
                       
                    else
                        self.contents = Bitmap(self,UIUtil.UIFile(emojis_textures .. content.emoji .. '.dds'))
                        LayoutHelpers.DepthOverParent(self.contents,self.name,0)
                        -- self.contents.Depth:Set(function()
                        --     return self.name.Depth()
                        -- end)
                        LayoutHelpers.CenteredRightOf(self.contents, self.name,2)
                        --LayoutHelpers.AtVerticalCenterIn(self.contents, self.name)
                        --LayoutHelpers.SetDimensions(self.contents,self.Height,self.Height)
                        self.contents.Height:Set(self.Height)
                        self.contents.Width:Set(self.Height)
                        parent = self.contents
                    end
                end
            end
        end
        return line
    end
    
    if GUI.chatContainer then
        local curEntries = table.getsize(GUI.chatLines)
        local neededEntries = math.floor(GUI.chatContainer.Height() / (GUI.chatLines[1].Height() + 2))
        if curEntries - neededEntries == 0 then
            return
        elseif curEntries - neededEntries < 0 then
            for i = curEntries + 1, neededEntries do
                local index = i
                GUI.chatLines[index] = CreateChatLine()
                LayoutHelpers.Below(GUI.chatLines[index], GUI.chatLines[index-1], 2)
                GUI.chatLines[index].Height:Set(function() return GUI.chatLines[index].name.Height() + 4 end)
                GUI.chatLines[index].Right:Set(GUI.chatContainer.Right)
            end
        elseif curEntries - neededEntries > 0 then
            for i = neededEntries + 1, curEntries do
                if GUI.chatLines[i] then
                    GUI.chatLines[i]:Destroy()
                    GUI.chatLines[i] = nil
                end
            end
        end
    else
        local clientArea = GUI.bg:GetClientGroup()
        GUI.chatContainer = Group(clientArea)
        LayoutHelpers.AtLeftIn(GUI.chatContainer, clientArea, 10)
        LayoutHelpers.AtTopIn(GUI.chatContainer, clientArea, 2)
        LayoutHelpers.AtRightIn(GUI.chatContainer, clientArea, 38)
        LayoutHelpers.AnchorToTop(GUI.chatContainer, GUI.chatEdit, 10)

        SetupChatScroll()

        if not GUI.chatLines[1] then
            GUI.chatLines[1] = CreateChatLine()
            LayoutHelpers.AtLeftTopIn(GUI.chatLines[1], GUI.chatContainer, 0, 0)
            GUI.chatLines[1].Height:Set(function() return GUI.chatLines[1].name.Height() + 4 end)
            GUI.chatLines[1].Right:Set(GUI.chatContainer.Right)
        end
        local index = 1
        while GUI.chatLines[index].Bottom() + GUI.chatLines[1].Height() < GUI.chatContainer.Bottom() do
            index = index + 1
            if not GUI.chatLines[index] then
                GUI.chatLines[index] = CreateChatLine()
                LayoutHelpers.Below(GUI.chatLines[index], GUI.chatLines[index-1], 2)
                GUI.chatLines[index].Height:Set(function() return GUI.chatLines[index].name.Height() + 4 end)
                GUI.chatLines[index].Right:Set(GUI.chatContainer.Right)
            end
        end
    end
end



function SetupChatScroll()
    GUI.chatContainer.top = 1
    GUI.chatContainer.scroll = UIUtil.CreateVertScrollbarFor(GUI.chatContainer)

    local numLines = function() return table.getsize(GUI.chatLines) end
    GUI.chatContainer.prevtabsize = 0
    GUI.chatContainer.prevsize = 0

    local function IsValidEntry(entryData)
        if entryData.camera then
            return ChatOptions.links and ChatOptions[entryData.armyID]
        end

        return ChatOptions[entryData.armyID]
    end

    local function DataSize()
        if GUI.chatContainer.prevtabsize ~= table.getn(chatHistory) then
            local size = 0
            for i, v in chatHistory do
                if IsValidEntry(v) then
                    size = size + table.getn(v.wrappedtext)
                end
            end
            GUI.chatContainer.prevtabsize = table.getn(chatHistory)
            GUI.chatContainer.prevsize = size
        end
        return GUI.chatContainer.prevsize
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.chatContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines(), size))
        return 1, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.chatContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.chatContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.chatContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines()+1, top), 1)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.chatContainer.IsScrollable = function(self, axis)
        return true
    end

    GUI.chatContainer.ScrollToBottom = function(self)
        --LOG(DataSize())
        GUI.chatContainer:ScrollSetTop(nil, DataSize())
    end

    -- determines what controls should be visible or not
    GUI.chatContainer.CalcVisible = function(self)
        GUI.bg.curTime = 0
        local index = 1
        local tempTop = self.top
        local curEntry = 1
        local curTop = 1
        local tempsize = 0

        if GUI.bg:IsHidden() then
            tempTop = math.max(DataSize() - numLines()+1, 1)
        end

        for i, v in chatHistory do
            if IsValidEntry(v) then
                if tempsize + table.getsize(v.wrappedtext) < tempTop then
                    tempsize = tempsize + table.getsize(v.wrappedtext)
                else
                    curEntry = i
                    for h, x in v.wrappedtext do
                        if h + tempsize == tempTop then
                            curTop = h
                            break
                        end
                    end
                    break
                end
            end
        end
        while GUI.chatLines[index] do
            local line = GUI.chatLines[index]

            if not chatHistory[curEntry].wrappedtext[curTop] then
                if chatHistory[curEntry].new then chatHistory[curEntry].new = nil end
                curTop = 1
                curEntry = curEntry + 1
                while chatHistory[curEntry] and not IsValidEntry(chatHistory[curEntry]) do
                    curEntry = curEntry + 1
                end
            end
            if chatHistory[curEntry] then
                local Index = index
                
                line:renderChatLine(chatHistory[curEntry], curTop)

                
                    
                
                -- if chatHistory[curEntry].camera then
                --     line.cameraData = chatHistory[curEntry].camera
                --     -- line.text:Enable()
                --     -- line.text:SetColor(chatColors[ChatOptions.link_color])
                -- else
                --     --line.text:Disable()
                --     --line.text:SetColor('ffc2f6ff')
                --     --line.text:SetColor(chatColors[ChatOptions[chatHistory[curEntry].tokey]])
                -- end

                line.EntryID = curEntry

                if GUI.bg:IsHidden() then

                    line.curHistory = chatHistory[curEntry]
                    if line.curHistory.new or line.curHistory.time == nil then
                        line.curHistory.time = 0
                    end

                    if line.curHistory.time < ChatOptions.fade_time then
                        line:Show()

                        UIUtil.setVisible(line.lineStickybg, ChatOptions.feed_background)

                        if line.name:GetText() == '' then
                            line.teamColor:Hide()
                        end
                        if line.curHistory.wrappedtext[curTop+1] == nil then
                            line.OnFrame = function(self, delta)
                                self.curHistory.time = self.curHistory.time + delta
                                if self.curHistory.time > ChatOptions.fade_time then
                                    if GUI.bg:IsHidden() then
                                        self:Hide()
                                    end
                                    self:SetNeedsFrameUpdate(false)
                                end
                            end
                        -- Don't increment time on lines with wrapped text
                        else
                            line.OnFrame = function(self, delta)
                                if self.curHistory.time > ChatOptions.fade_time then
                                    if GUI.bg:IsHidden() then
                                        self:Hide()
                                    end
                                    self:SetNeedsFrameUpdate(false)
                                end
                            end
                        end
                        line:SetNeedsFrameUpdate(true)
                    end

                end
            else
                line.name:Disable()
                line.name:SetText('')
                --line.text:SetText('')
                line.teamColor:SetSolidColor('00000000')
                if line.contents then
                    line.contents:Destroy()
                    line.contents = nil
                end
            end
            line:SetAlpha(ChatOptions.win_alpha, true)
            curTop = curTop + 1
            index = index + 1
        end
        if chatHistory[curEntry].new then chatHistory[curEntry].new = nil end
    end
end



local RunChatCommand = import('/lua/ui/notify/commands.lua').RunChatCommand
function CreateChatEdit()
    local parent = GUI.bg:GetClientGroup()
    local group = Group(parent)

    group.Bottom:Set(parent.Bottom)
    group.Right:Set(parent.Right)
    group.Left:Set(parent.Left)
    group.Top:Set(function() return group.Bottom() - group.Height() end)

    local toText = UIUtil.CreateText(group, '', 14, 'Arial')
    LayoutHelpers.AtBottomIn(toText, group, 1)
    LayoutHelpers.AtLeftIn(toText, group, 35)

    ChatTo.OnDirty = function(self)
        if ToStrings[self()] then
            toText:SetText(LOC(ToStrings[self()].caps))
        else
            toText:SetText(LOCF('%s %s:', ToStrings['to'].caps, GetArmyData(self()).nickname))
        end
    end

    group.edit = Edit(group)
    LayoutHelpers.AnchorToRight(group.edit, toText, 5)
    LayoutHelpers.AtRightIn(group.edit, group, 38)
    group.edit.Depth:Set(function() return GUI.bg:GetClientGroup().Depth() + 200 end)
    LayoutHelpers.AtBottomIn(group.edit, group, 1)
    group.edit.Height:Set(function() return group.edit:GetFontHeight() end)
    UIUtil.SetupEditStd(group.edit, "ff00ff00", nil, "ffffffff", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
    group.edit:SetDropShadow(true)
    group.edit:ShowBackground(false)

    group.edit:SetText('')

    group.Height:Set(function() return group.edit.Height() end)

    local function CreateTestBtn(text)
        local btn = UIUtil.CreateCheckbox(group, '/dialogs/toggle_btn/toggle')
        btn.Depth:Set(function() return group.Depth() + 10 end)
        btn.OnClick = function(self, modifiers)
            if self._checkState == "unchecked" then
                self:ToggleCheck()
            end
        end
        btn.txt = UIUtil.CreateText(btn, text, 12, UIUtil.bodyFont)
        LayoutHelpers.AtCenterIn(btn.txt, btn)
        btn.txt:SetColor('ffffffff')
        btn.txt:DisableHitTest()
        return btn
    end

    group.camData = Checkbox(group,
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_up.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_down.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'))

    LayoutHelpers.AtRightIn(group.camData, group, 5)
    LayoutHelpers.AtVerticalCenterIn(group.camData, group.edit, -1)

    group.chatBubble = Button(group,
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_up.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_down.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_over.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_dis.dds'))
    group.chatBubble.OnClick = function(self, modifiers)
        if not self.list then
            self.list = CreateChatList(self)
            LayoutHelpers.Above(self.list, self, 15)
            LayoutHelpers.AtLeftIn(self.list, self, 15)
        else
            self.list:Destroy()
            self.list = nil
        end
    end

    toText.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            group.chatBubble:OnClick(event.Modifiers)
        end
    end

    LayoutHelpers.AtLeftIn(group.chatBubble, group, 3)
    LayoutHelpers.AtVerticalCenterIn(group.chatBubble, group.edit)

    group.edit.OnNonTextKeyPressed = function(self, charcode, event)
        if AddUnicodeCharToEditText(self, charcode) then
            return
        end
        GUI.bg.curTime = 0
        local function RecallCommand(entryNumber)
            self:SetText(commandHistory[self.recallEntry].text)
            if commandHistory[self.recallEntry].camera then
                self.tempCam = commandHistory[self.recallEntry].camera
                group.camData:Disable()
                group.camData:SetCheck(true)
            else
                self.tempCam = nil
                group.camData:Enable()
                group.camData:SetCheck(false)
            end
        end
        if charcode == UIUtil.VK_NEXT then
            local mod = 10
            if event.Modifiers.Shift then
                mod = 1
            end
            ChatPageDown(mod)
            return true
        elseif charcode == UIUtil.VK_PRIOR then
            local mod = 10
            if event.Modifiers.Shift then
                mod = 1
            end
            ChatPageUp(mod)
            return true
        elseif charcode == UIUtil.VK_UP then
            if GUI.EmojiSelector then
                GUI.EmojiSelector:Highlight(true)
            elseif table.getsize(commandHistory) > 0 then
                if self.recallEntry then
                    self.recallEntry = math.max(self.recallEntry-1, 1)
                else
                    self.recallEntry = table.getsize(commandHistory)
                end
                RecallCommand(self.recallEntry)
            end
        elseif charcode == UIUtil.VK_DOWN then
            if GUI.EmojiSelector then
                GUI.EmojiSelector:Highlight(false)
            elseif table.getsize(commandHistory) > 0 then
                if self.recallEntry then
                    self.recallEntry = math.min(self.recallEntry+1, table.getsize(commandHistory))
                    RecallCommand(self.recallEntry)
                    if self.recallEntry == table.getsize(commandHistory) then
                        self.recallEntry = nil
                    end
                else
                    self:SetText('')
                end
            end
        else
            return true
        end
    end
    group.edit.OnTextChanged = function(self, newText, oldText)
        if  GUI.EmojiSelector and GUI.EmojiSelector.BeginPos then
            if  GUI.EmojiSelector.BeginPos > self:GetCaretPosition() then
                GUI.EmojiSelector:Destroy()
                GUI.EmojiSelector = nil
                return
            end
            local EmojiText = ''
            if GUI.EmojiSelector.BeginPos < self:GetCaretPosition() then
                EmojiText = STR_Utf8SubString(newText, GUI.EmojiSelector.BeginPos + 1, self:GetCaretPosition() - GUI.EmojiSelector.BeginPos)
            end
            -- LOG(GUI.EmojiSelector.BeginPos +1)
            -- LOG(self:GetCaretPosition())
            -- LOG(EmojiText)
            UpdateEmojiSelector(EmojiText)
        end
    end
    --here input
    group.edit.OnCharPressed = function(self, charcode)
        -- 58 is ':' code
        LOG(charcode)
        if charcode == 58 and ChatOptions.chat_emojis then
            if GUI.EmojiSelector  then
                GUI.EmojiSelector:Destroy()
                GUI.EmojiSelector = nil
            else
                CreateEmojiSelector()
                GUI.EmojiSelector.BeginPos = self:GetCaretPosition() + 1
            end
        end
        --

        local charLim = self:GetMaxChars()
        if charcode == 9 then--tab code
            if table.empty(GUI.EmojiSelector.FoundEmojis) then return true end
            local text =        self:GetText() 
            local CaretPos =    self:GetCaretPosition()
            
            local emojiname =  GUI.EmojiSelector.FoundEmojis[GUI.EmojiSelector.selectionIndex].pack..'/'.. GUI.EmojiSelector.FoundEmojis[GUI.EmojiSelector.selectionIndex].emoji

            self:SetText(STR_Utf8SubString(text, 1, GUI.EmojiSelector.BeginPos)..emojiname..':'..STR_Utf8SubString(text,CaretPos + 1, string.len(text)))
            self:SetCaretPosition(string.len(emojiname) + GUI.EmojiSelector.BeginPos + 1)
            GUI.EmojiSelector:Destroy()
            GUI.EmojiSelector = nil
            
            return true
        end
        GUI.bg.curTime = 0
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end

    group.edit.OnEnterPressed = function(self, text)
        if GUI.EmojiSelector then
            GUI.EmojiSelector:Destroy()
            GUI.EmojiSelector = nil
        end
        -- Analyse for any commands entered for Notify toggling
        if string.len(text) > 1 and string.sub(text, 1, 1) == "/" then
            local args = {}

            for word in string.gfind(string.sub(text, 2), "%S+") do
                table.insert(args, string.lower(word))
            end

            -- We've done the command, exit without sending the message to other players
            if RunChatCommand(args) then
                return
            end
        end

        GUI.bg.curTime = 0
        if group.camData:IsDisabled() then
            group.camData:Enable()
        end
        if text == "" then
            ToggleChat()
        else
            local gnBegin, gnEnd = string.find(text, "%s+")
            if gnBegin and (gnBegin == 1 and gnEnd == string.len(text)) then
                return
            end
            if import('/lua/ui/game/taunt.lua').CheckForAndHandleTaunt(text) then
                return
            end

            msg = { to = ChatTo(), Chat = true }
            if self.tempCam then
                msg.camera = self.tempCam
            elseif group.camData:IsChecked() then
                msg.camera = GetCamera('WorldCamera'):SaveSettings()
            end
            msg.text = text
            if ChatTo() == 'allies' then
                if GetFocusArmy() ~= -1 then
                    SessionSendChatMessage(FindClients(), msg)
                else
                    msg.Observer = true
                    SessionSendChatMessage(FindClients(), msg)
                end
            elseif type(ChatTo()) == 'number' then
                if GetFocusArmy() ~= -1 then
                    SessionSendChatMessage(FindClients(ChatTo()), msg)
                    msg.echo = true
                    msg.from = GetArmyData(GetFocusArmy()).nickname
                    ReceiveChat(GetArmyData(ChatTo()).nickname, msg)
                end
            else
                if GetFocusArmy() == -1 then
                    msg.Observer = true
                    SessionSendChatMessage(FindClients(), msg)
                else
                    SessionSendChatMessage(msg)
                end
            end
            table.insert(commandHistory, msg)
            self.recallEntry = nil
            self.tempCam = nil
        end
    end

    ChatTo:Set('all')
    group.edit:AcquireFocus()

    return group
end






function ReceiveChatFromSim(sender, msg)
    sender = sender or "nil sender"
    if msg.ConsoleOutput then
        print(LOCF("%s %s", sender, msg.ConsoleOutput))
        return
    end

    if not msg.Chat then
        return
    end
    
    if msg.to == 'notify' and not import('/lua/ui/notify/notify.lua').processIncomingMessage(sender, msg) then
        return
    end

    if type(msg) == 'string' then
        msg = { text = msg }
    elseif type(msg) ~= 'table' then
        msg = { text = repr(msg) }
    end

    local armyData = GetArmyData(sender)
    if not armyData and GetFocusArmy() ~= -1 and not SessionIsReplay() then
        return
    end

    local towho = LOC(ToStrings[msg.to].text) or LOC(ToStrings['private'].text)
    local tokey = ToStrings[msg.to].colorkey or ToStrings['private'].colorkey
    if msg.Observer then
        towho = LOC("<LOC lobui_0692>to observers:")
        tokey = "link_color"
        if armyData.faction then
            armyData.faction = table.getn(FactionsIcon) - 1
        end
    end

    if type(msg.to) == 'number' and SessionIsReplay() then
        towho = string.format("%s %s:", LOC(ToStrings.to.text), GetArmyData(msg.to).nickname)
    end
    local name = sender .. ' ' .. towho

    if msg.echo then
        if msg.from and SessionIsReplay() then
            name = string.format("%s %s %s:", msg.from, LOC(ToStrings.to.text), GetArmyData(msg.to).nickname)
        else
            name = string.format("%s %s:", LOC(ToStrings.to.caps), sender)
        end
    end
    local tempText = WrapContents({contents = CheckEmojis(msg.text,ChatOptions.chat_emojis),name = name})
    --LOG(repr(tempText))
    -- if text wrap produces no lines (ie text is all white space) then add a blank line
    
    local entry = {
        name = name,
        tokey = tokey,
        color = (armyData.color or "ffffffff"),
        armyID = (armyData.ArmyID or 1),
        faction = (armyData.faction or (table.getn(FactionsIcon)-1))+1,
        text = msg.text,
        wrappedtext = tempText,
        new = true,
        camera = msg.camera
    }

    table.insert(chatHistory, entry)
    if ChatOptions[entry.armyID] then
        if table.getsize(chatHistory) == 1 then
            GUI.chatContainer:CalcVisible()
        else
            GUI.chatContainer:ScrollToBottom()
        end
    end
    if SessionIsReplay() then
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Diplomacy_Close'}))
    end
end


function RewrapLog()
    local tempSize = 0
    for i, v in chatHistory do
        v.wrappedtext = WrapContents({contents = CheckEmojis(v.text,ChatOptions.chat_emojis),name = v.name})
        
        --v.wrappedtext = WrapText(v)
        tempSize = tempSize + table.getsize(v.wrappedtext)
    end
    GUI.chatContainer.prevtabsize = 0
    GUI.chatContainer.prevsize = 0
    GUI.chatContainer:ScrollSetTop(nil, tempSize)
end


function CreatePackageManagerWindow()
    local windowTextures = {
        tl = UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'),
        tr = UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'),
        tm = UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'),
        ml = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'),
        m = UIUtil.SkinnableFile('/game/panel/panel_brd_m.dds'),
        mr = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'),
        bl = UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'),
        bm = UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'),
        br = UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'),
        borderColor = 'ff415055',
    }
    GUI.PackageManager = Window(GetFrame(0), 'Package Manager', nil, nil, nil, true, true, 'package_manager', nil, windowTextures)
    GUI.PackageManager.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    Tooltip.AddButtonTooltip(GUI.PackageManager._closeBtn, 'chat_close')


    --LayoutHelpers.AnchorToBottom(GUI.PackageManager, GetFrame(0), -700)
    LayoutHelpers.SetDimensions(GUI.PackageManager,500,500)
    -- LayoutHelpers.SetWidth(GUI.PackageManager, 500)
    -- LayoutHelpers.SetHeight(GUI.PackageManager, 500)
    LayoutHelpers.AtCenterIn(GUI.PackageManager, GetFrame(0))
    -- LayoutHelpers.AtHorizontalCenterIn(GUI.PackageManager, GetFrame(0))
    -- LayoutHelpers.ResetRight(GUI.PackageManager)
    LayoutHelpers.AtHorizontalCenterIn(GUI.PackageManager._title, GUI.PackageManager)

    GUI.PackageManager.DragTL = Bitmap(GUI.PackageManager, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    GUI.PackageManager.DragTR = Bitmap(GUI.PackageManager, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    GUI.PackageManager.DragBL = Bitmap(GUI.PackageManager, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    GUI.PackageManager.DragBR = Bitmap(GUI.PackageManager, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))


    LayoutHelpers.AtLeftTopIn(GUI.PackageManager.DragTL, GUI.PackageManager, -24, -8)

    LayoutHelpers.AtRightTopIn(GUI.PackageManager.DragTR, GUI.PackageManager, -22, -8)

    LayoutHelpers.AtLeftBottomIn(GUI.PackageManager.DragBL, GUI.PackageManager, -24,-8)
    --LayoutHelpers.AtBottomIn(GUI.PackageManager.DragBL, GUI.PackageManager, -8)

    LayoutHelpers.AtRightBottomIn(GUI.PackageManager.DragBR, GUI.PackageManager, -22,-8)
    --LayoutHelpers.AtBottomIn(GUI.PackageManager.DragBR, GUI.PackageManager, -8)

    LayoutHelpers.DepthOverParent(GUI.PackageManager.DragTL, GUI.PackageManager, 10)
    LayoutHelpers.DepthOverParent(GUI.PackageManager.DragTR, GUI.PackageManager, 10)
    LayoutHelpers.DepthOverParent(GUI.PackageManager.DragBL, GUI.PackageManager, 10)
    LayoutHelpers.DepthOverParent(GUI.PackageManager.DragBR, GUI.PackageManager, 10)

    GUI.PackageManager.DragTL:DisableHitTest()
    GUI.PackageManager.DragTR:DisableHitTest()
    GUI.PackageManager.DragBL:DisableHitTest()
    GUI.PackageManager.DragBR:DisableHitTest()

    GUI.PackageManager.TopLine = 1
    GUI.PackageManager.SizeLine = table.getsize(Packages)
    --TODO:attach to client group
    GUI.PackageManager.scroll = UIUtil.CreateVertScrollbarFor(GUI.PackageManager, -43,nil,10,25) -- scroller
    LayoutHelpers.DepthOverParent(GUI.PackageManager.scroll , GUI.PackageManager, 10)
    --LayoutHelpers.AtRightTopIn( GUI.PackageManager.scroll,GUI.PackageManager)

    GUI.PackageManager.OnClose = function(self) -- close button
        GUI.PackageManager:Destroy()
        GUI.PackageManager = nil
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.PackageManager.GetScrollValues = function(self, axis)
        --LOG( 1 ..' '.. self.SizeLine..' '..self.TopLine.. ' '.. math.min(self.TopLine + self.numLines, self.SizeLine))
        return 1, self.SizeLine ,self.TopLine , math.min(self.TopLine + self.numLines, self.SizeLine)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.PackageManager.ScrollLines = function(self, axis, delta)
        -- LOG(delta)
        -- LOG(self.TopLine)
        self:ScrollSetTop(axis, self.TopLine + delta)
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.PackageManager.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.TopLine + math.floor(delta) * self.numLines )
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.PackageManager.ScrollSetTop = function(self, axis, top)
        --top = math.floor(top)
        if top == self.TopLine then return end
        self.TopLine = math.max(math.min(self.SizeLine - self.numLines + 1, top), 1)
        self:CalcVisible()
    end

  
    

    GUI.PackageManager.ScrollToBottom = function(self)
        GUI.chatContainer:ScrollSetTop(nil, self.numLines)
    end

    -- determines what controls should be visible or not
    GUI.PackageManager.CalcVisible = function(self)
        local packIndex = 1
        local lineIndex = 1
        local dorender = false
        for id,pack in Packages do
            if packIndex == self.TopLine then  dorender = true end
            if dorender then
                self.LineGroup.Lines[lineIndex]:render(pack.info,id)
                if self.numLines == lineIndex then return end
                lineIndex = lineIndex + 1
            end
            packIndex = packIndex + 1
        end
        for ind = lineIndex, self.numLines do self.LineGroup.Lines[ind]:render() end
    end
    
      -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.PackageManager.IsScrollable = function(self, axis)
        return true
    end
    
    --scrlling
    GUI.PackageManager.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            if event.WheelRotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
            return true
        end
        return false
    end

    GUI.PackageManager.LineGroup = Group(GUI.PackageManager) --group that contains PM data lines
    LayoutHelpers.AtLeftIn(GUI.PackageManager.LineGroup, GUI.PackageManager.ClientGroup, 5)
    LayoutHelpers.LeftOf(GUI.PackageManager.LineGroup, GUI.PackageManager.scroll, 5)
    LayoutHelpers.AtTopIn(GUI.PackageManager.LineGroup, GUI.PackageManager.ClientGroup, 5)
    LayoutHelpers.AtBottomIn(GUI.PackageManager.LineGroup, GUI.PackageManager.ClientGroup, 5)
    --GUI.PackageManager.Lines:SetSolidColor('ffff0000')
    LayoutHelpers.DepthOverParent(GUI.PackageManager.LineGroup,GUI.PackageManager,10)
    GUI.PackageManager.LineGroup.Lines = {}



    

    local function CreatePackageManagerLines()
        local function CreatePackageManagerLine()
            local line = Group(GUI.PackageManager.LineGroup)
            LayoutHelpers.DepthOverParent(line,GUI.PackageManager.LineGroup,1)
            line.bg = CheckBox(line,
                        UIUtil.SkinnableFile('/MODS/blank.dds'),
                        UIUtil.SkinnableFile('/MODS/single.dds'),
                        UIUtil.SkinnableFile('/MODS/single.dds'),
                        UIUtil.SkinnableFile('/MODS/double.dds'),
                        UIUtil.SkinnableFile('/MODS/disabled.dds'),
                        UIUtil.SkinnableFile('/MODS/disabled.dds'),
                            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
            LayoutHelpers.SetDimensions(line,80,80)
            -- LayoutHelpers.SetHeight(line,80)
            -- LayoutHelpers.SetWidth(line,80)
            -- LayoutHelpers.SetHeight(line.bg,80)
            -- LayoutHelpers.SetWidth(line.bg,80)
            LayoutHelpers.FillParent(line.bg, line)
            LayoutHelpers.DepthOverParent(line.bg,line,1)
            line.bg:Disable()
    
    
            line.name = UIUtil.CreateText(line, '', 14, UIUtil.bodyFont,true)
            line.name:SetColor('FFE9ECE9') -- #FFE9ECE9
            line.name:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(line.name, line, 5, 5)
    
            line.author = UIUtil.CreateText(line, '', 14, UIUtil.bodyFont,true)
            line.author:DisableHitTest()
            line.author:SetColor('FFE9ECE9') -- #FFE9ECE9
            LayoutHelpers.Below(line.author, line.name,5)
    
            line.desc = MultiLineText(line, UIUtil.bodyFont, 12, 'FFA2A5A2')
            line.desc:SetDropShadow(true)
            line.desc:DisableHitTest()
            LayoutHelpers.Below(line.desc, line.author,5)
            line.desc.Width:Set(line.Width() - 10)
            --line.desc:SetText(' ')
           
            --data:
            -- name --package name
            -- description -- its description
            -- author -- its author
            -- isEnabled -- is pack active
    
            line.render = function(self, data, id)
                if data then
                    self.bg.id = id    
                    self.name:SetText(data.name)
                    self.author:SetText(data.author)
                    self.desc:SetText(data.description)
                    self.bg:Enable()
                    self.bg:SetCheck(data.isEnabled,true)
                else
                    self.name:SetText('')
                    self.author:SetText('')
                    self.desc:Clear()
                    self.bg:Disable()
                end
                
            end
        
            -- line.disable = function (self)
            --     self.name:SetText('')
            --     self.author:SetText('')
            --     self.desc:SetText('')
            --     self.bg:Disable()
            -- end
    
            -- line.HandleEvent = function(self, event)
            --     if event.Type == 'ButtonPress' then
                    
            --     end
            -- end
    
            line.bg.OnCheck = function(self, checked)
                LOG('set '..repr(checked)..' on '..repr(self.id))
                UpdatePacks(self.id, checked)
            end
    
            return line
        end
        local index = 1
        GUI.PackageManager.LineGroup.Lines[index]  = CreatePackageManagerLine()
        local parent = GUI.PackageManager.LineGroup.Lines[index] 
        LayoutHelpers.AtLeftTopIn( parent,GUI.PackageManager.LineGroup,5,5)
        LayoutHelpers.AtRightIn(parent,GUI.PackageManager.LineGroup,5)
        while GUI.PackageManager.LineGroup.Bottom() -  parent.Bottom() > 85 do
            index = index + 1 
            GUI.PackageManager.LineGroup.Lines[index] = CreatePackageManagerLine()
            LayoutHelpers.Below(GUI.PackageManager.LineGroup.Lines[index] ,parent ,5)
            LayoutHelpers.AtRightIn(GUI.PackageManager.LineGroup.Lines[index],parent)
            parent = GUI.PackageManager.LineGroup.Lines[index] 
        end
        GUI.PackageManager.numLines = index
    end
    CreatePackageManagerLines()
    GUI.PackageManager:CalcVisible()
 

end

function UpdatePacks(id, state)
    Packages[id].info.isEnabled = state
    local packsStates = Prefs.GetFromCurrentProfile('emojipacks') 
    packsStates[id] = state
    Prefs.SetToCurrentProfile("emojipacks", packsStates)
end

function CreateConfigWindow()
    if GUI.PackageManager then
        GUI.PackageManager:Destroy()
        GUI.PackageManager = nil
    end
    import('/lua/ui/game/multifunction.lua').CloseMapDialog()
    local windowTextures = {
        tl = UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'),
        tr = UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'),
        tm = UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'),
        ml = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'),
        m = UIUtil.SkinnableFile('/game/panel/panel_brd_m.dds'),
        mr = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'),
        bl = UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'),
        bm = UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'),
        br = UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'),
        borderColor = 'ff415055',
    }
    GUI.config = Window(GetFrame(0), '<LOC chat_0008>Chat Options', nil, nil, nil, true, true, 'chat_config', nil, windowTextures)
    GUI.config.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    Tooltip.AddButtonTooltip(GUI.config._closeBtn, 'chat_close')

    LayoutHelpers.AtTopIn(GUI.config, GetFrame(0), 100)
    --LayoutHelpers.AtTopIn(GUI.config, GetFrame(0))
    LayoutHelpers.SetWidth(GUI.config, 300)
    --LayoutHelpers.SetHeight(GUI.config, 300)
    LayoutHelpers.AtHorizontalCenterIn(GUI.config, GetFrame(0))
    --LayoutHelpers.AtCenterIn(GUI.config, GetFrame(0))
    LayoutHelpers.ResetRight(GUI.config)
   

    GUI.config.DragTL = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    GUI.config.DragTR = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    GUI.config.DragBL = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    GUI.config.DragBR = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

    LayoutHelpers.AtLeftTopIn(GUI.config.DragTL, GUI.config, -24, -8)

    LayoutHelpers.AtRightTopIn(GUI.config.DragTR, GUI.config, -22, -8)

    

    LayoutHelpers.AtLeftBottomIn(GUI.config.DragBL, GUI.config, -24, -8)
    --LayoutHelpers.AtBottomIn(GUI.config.DragBL, GUI.config, -8)

    LayoutHelpers.AtRightBottomIn(GUI.config.DragBR, GUI.config, -22, -8)
    --LayoutHelpers.AtBottomIn(GUI.config.DragBR, GUI.config, -8)

    GUI.config.DragTL.Depth:Set(function() return GUI.config.Depth() + 10 end)
    GUI.config.DragTR.Depth:Set(GUI.config.DragTL.Depth)
    GUI.config.DragBL.Depth:Set(GUI.config.DragTL.Depth)
    GUI.config.DragBR.Depth:Set(GUI.config.DragTL.Depth)

    GUI.config.DragTL:DisableHitTest()
    GUI.config.DragTR:DisableHitTest()
    GUI.config.DragBL:DisableHitTest()
    GUI.config.DragBR:DisableHitTest()

    GUI.config.OnClose = function(self)
        GUI.config:Destroy()
        GUI.config = false
    end

    local options = {
        filters = {{type = 'filter', name = '<LOC _Links>Links', key = 'links', tooltip = 'chat_filter'}},
        winOptions = {
                {type = 'color', name = '<LOC _All>', key = 'all_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Allies>', key = 'allies_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Private>', key = 'priv_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Links>', key = 'link_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC notify_0033>', key = 'notify_color', tooltip = 'chat_color'},
                {type = 'splitter'},
                {type = 'slider', name = '<LOC chat_0009>Chat Font Size', key = 'font_size', tooltip = 'chat_fontsize', min = 12, max = 18, inc = 2},
                {type = 'slider', name = '<LOC chat_0010>Window Fade Time', key = 'fade_time', tooltip = 'chat_fadetime', min = 5, max = 30, inc = 1},
                {type = 'slider', name = '<LOC chat_0011>Window Alpha', key = 'win_alpha', tooltip = 'chat_alpha', min = 20, max = 100, inc = 1},
                {type = 'splitter'},
                {type = 'filter', name = '<LOC chat_0014>Show Feed Background', key = 'feed_background', tooltip = 'chat_feed_background'},
                {type = 'filter', name = '<LOC chat_0015>Persist Feed Timeout', key = 'feed_persist', tooltip = 'chat_feed_persist'},
                {type = 'filter', name = 'Chat emojis', key = 'chat_emojis', tooltip = 'chat_emojis'},
        },
    }

    local optionGroup = Group(GUI.config:GetClientGroup())
    LayoutHelpers.FillParent(optionGroup, GUI.config:GetClientGroup())
    optionGroup.options = {}
    local tempOptions = {}

    local function UpdateOption(key, value)
        if key == 'win_alpha' then
            value = value / 100
        end
        tempOptions[key] = value
    end

    local function CreateSplitter()
        local splitter = Bitmap(optionGroup)
        splitter:SetSolidColor('ff000000')
        splitter.Left:Set(optionGroup.Left)
        splitter.Right:Set(optionGroup.Right)
        splitter.Height:Set(2)
        return splitter
    end

    local function CreateEntry(data)
        local group = Group(optionGroup)
        if data.type == 'filter' then
            group.check = UIUtil.CreateCheckbox(group, '/dialogs/check-box_btn/', data.name, true)
            LayoutHelpers.AtLeftTopIn(group.check, group)
            group.check.key = data.key
            group.Height:Set(group.check.Height)
            group.Width:Set(group.check.Width)
            group.check.OnCheck = function(self, checked)
                UpdateOption(self.key, checked)
            end
            if ChatOptions[data.key] then
                group.check:SetCheck(ChatOptions[data.key], true)
            end
        elseif data.type == 'color' then
            group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
            local defValue = ChatOptions[data.key] or 1
            group.color = BitmapCombo(group, chatColors, defValue, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
            LayoutHelpers.AtLeftTopIn(group.color, group)
            LayoutHelpers.RightOf(group.name, group.color, 5)
            LayoutHelpers.AtVerticalCenterIn(group.name, group.color)
            LayoutHelpers.SetWidth(group.color, 55)
            group.color.key = data.key
            group.Height:Set(group.color.Height)
            group.Width:Set(group.color.Width)
            group.color.OnClick = function(self, index)
                UpdateOption(self.key, index)
            end
        elseif data.type == 'slider' then
            group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
            LayoutHelpers.AtLeftTopIn(group.name, group)
            group.slider = IntegerSlider(group, false,
                data.min, data.max,
                data.inc, UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
                UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
                UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
            LayoutHelpers.Below(group.slider, group.name)
            group.slider.key = data.key
            group.Height:Set(function() return group.name.Height() + group.slider.Height() end)
            group.slider.OnValueSet = function(self, newValue)
                UpdateOption(self.key, newValue)
            end
            group.value = UIUtil.CreateText(group, '', 14, "Arial")
            LayoutHelpers.RightOf(group.value, group.slider)
            group.slider.OnValueChanged = function(self, newValue)
                group.value:SetText(string.format('%3d', newValue))
            end
            local defValue = ChatOptions[data.key] or 1
            if data.key == 'win_alpha' then
                defValue = defValue * 100
            end
            group.slider:SetValue(defValue)
            LayoutHelpers.SetWidth(group, 200)
        elseif data.type == 'splitter' then
            group.split = CreateSplitter()
            LayoutHelpers.AtTopIn(group.split, group)
            group.Width:Set(group.split.Width)
            group.Height:Set(group.split.Height)
        end
        if data.type ~= 'splitter' then
            Tooltip.AddControlTooltip(group, data.tooltip or 'chat_filter')
        end
        return group
    end

    local armyData = GetArmiesTable()
    for i, v in armyData.armiesTable do
        if not v.civilian then
            table.insert(options.filters, {type = 'filter', name = v.nickname, key = i})
        end
    end

    local filterTitle = UIUtil.CreateText(optionGroup, '<LOC chat_0012>Message Filters', 14, "Arial Bold")
    LayoutHelpers.AtLeftTopIn(filterTitle, optionGroup, 5, 5)
    Tooltip.AddControlTooltip(filterTitle, 'chat_filter')
    local index = 1
    for i, v in options.filters do
        optionGroup.options[index] = CreateEntry(v)
        optionGroup.options[index].Left:Set(filterTitle.Left)
        optionGroup.options[index].Right:Set(optionGroup.Right)
        if index == 1 then
            LayoutHelpers.Below(optionGroup.options[index], filterTitle, 5)
        else
            LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-1], -2)
        end
        index = index + 1
    end
    local splitIndex = index
    local splitter = CreateSplitter()
    splitter.Top:Set(function() return optionGroup.options[splitIndex-1].Bottom() + 5 end)

    local WindowTitle = UIUtil.CreateText(optionGroup, '<LOC chat_0013>Message Colors', 14, "Arial Bold")
    LayoutHelpers.Below(WindowTitle, splitter, 5)
    WindowTitle.Left:Set(filterTitle.Left)
    Tooltip.AddControlTooltip(WindowTitle, 'chat_color')

    local firstOption = true
    local optionIndex = 1
    for i, v in options.winOptions do
        optionGroup.options[index] = CreateEntry(v)
        optionGroup.options[index].Data = v
        if firstOption then
            LayoutHelpers.Below(optionGroup.options[index], WindowTitle, 5)
            optionGroup.options[index].Right:Set(function() return filterTitle.Left() + (optionGroup.Width() / 2) end)
            firstOption = false
        elseif v.type == 'color' then
            optionGroup.options[index].Right:Set(function() return filterTitle.Left() + (optionGroup.Width() / 2) end)
            if math.mod(optionIndex, 2) == 1 then
                LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-2], 2)
            else
                LayoutHelpers.RightOf(optionGroup.options[index], optionGroup.options[index-1])
            end
        elseif v.type == 'filter' then
            LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-1], 4)
            LayoutHelpers.AtLeftIn(optionGroup.options[index], WindowTitle)
        else
            LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-1], 4)
            LayoutHelpers.AtHorizontalCenterIn(optionGroup.options[index], optionGroup)
        end
        optionIndex = optionIndex + 1
        index = index + 1
    end

    local resetBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Reset>', 16)
    LayoutHelpers.Below(resetBtn, optionGroup.options[index-1], 4)
    LayoutHelpers.AtLeftIn(resetBtn, optionGroup)
    resetBtn.OnClick = function(self)
        for option, value in defOptions do
            for i, control in optionGroup.options do
                if control.Data.key == option then
                    if control.Data.type == 'slider' then
                        if control.Data.key == 'win_alpha' then
                            value = value * 100
                        end
                        control.slider:SetValue(value)
                    elseif control.Data.type == 'color' then
                        control.color:SetItem(value)
                    elseif control.Data.type == 'filter' then
                        control.check:SetCheck(value, true)
                    end
                    UpdateOption(option, value)
                    break
                end
            end
        end
    end

    local packageBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', 'Package Manager', 12)
    LayoutHelpers.Below(packageBtn, optionGroup.options[index-1], 4)
    LayoutHelpers.AtRightIn(packageBtn, optionGroup)
    LayoutHelpers.ResetLeft(packageBtn)
    packageBtn.OnClick = function(self)
        CreatePackageManagerWindow()
        GUI.config:Destroy()
        GUI.config = false
    end

    local okBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Ok>', 16)
    LayoutHelpers.Below(okBtn, resetBtn, 4)
    LayoutHelpers.AtLeftIn(okBtn, optionGroup)
    okBtn.OnClick = function(self)
        ChatOptions = table.merged(ChatOptions, tempOptions)
        Prefs.SetToCurrentProfile("chatoptions", ChatOptions)
        GUI.bg:OnOptionsSet()
        GUI.config:Destroy()
        GUI.config = false
    end

    local cancelBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Cancel>', 16)
    LayoutHelpers.Below(cancelBtn, resetBtn, 4)
    LayoutHelpers.AtRightIn(cancelBtn, optionGroup)
    LayoutHelpers.ResetLeft(cancelBtn)
    cancelBtn.OnClick = function(self)
        GUI.config:Destroy()
        GUI.config = false
    end


    GUI.config.Bottom:Set(function() return okBtn.Bottom() + 5 end)
    --LayoutHelpers.AtCenterIn(GUI.config, GetFrame(0))
end



function WrapContents(data)
    return FitContentsInLine(data.contents,GUI.chatLines[1].Height(), 
    function(line)
        local firstLine = GUI.chatLines[1]
        if line == 1 then
            return firstLine.Right() - (firstLine.name.Left() + firstLine.name:GetStringAdvance(data.name) + 4)
        else
            return firstLine.Right() - (firstLine.name.Left() + 4)
        end
    end, 
    function(text)
        return GUI.chatLines[1].name:GetStringAdvance(text)
    end)
end


--the most complicated thing here that fits in line elements
function FitContentsInLine(contents, lineHeight, lineWidth, GetStringAdvance)
    local result_lines = {}
    local result_line = {}
    local lineIndex = 1
    local CurShift = 0
    for _,content in contents do
        if content.text then
            local textWidth = GetStringAdvance(content.text)
            if CurShift + textWidth + 2 < lineWidth(lineIndex) then
                table.insert(result_line, content)
                CurShift = CurShift + textWidth + 2
                continue 
            else
                local fittedText = import('/lua/maui/text.lua').WrapText(content.text,
                                                    function(line)
                                                        if line == 1 then
                                                            return lineWidth(lineIndex) - CurShift - 2
                                                        else
                                                            return lineWidth(lineIndex + 1)
                                                        end
                                                    end,
                                                GetStringAdvance)
                --LOG(repr(fittedText))
                local fitTextNum = table.getn(fittedText)
                table.insert(result_line, {text = fittedText[1]})
                table.insert(result_lines, result_line)
                lineIndex = 2
                for i = 2,fitTextNum-1 do
                    table.insert(result_lines, {{text = fittedText[i]}})
                end
                CurShift = GetStringAdvance(fittedText[fitTextNum]) + 2
                result_line = {{text = fittedText[fitTextNum]}}
                continue
            end
        elseif content.emoji then
            if CurShift + lineHeight + 2 < lineWidth(lineIndex) then
                table.insert(result_line, content)
                CurShift = CurShift + lineHeight + 2
                continue
            else
                table.insert(result_lines, result_line)
                result_line = {content}
                CurShift =  lineHeight + 2
                lineIndex = 2
            end
        end
    end
    table.insert(result_lines, result_line)
    return result_lines
end

function  isInEmojis(str)
    str = string.lower(str)
    for id, pack in Packages do
        if not pack.info.isEnabled then continue end
        local packprefix = id..'/'
        for _, emoji in pack.emojis do
            if packprefix..emoji == str then
                return true
            end
        end
    end
    return false
end

function CheckEmojis(text, dosearch)
    if not dosearch then
        return {{text = text}}
    end
   -- local continue_flag
    local wasEmoji = true
    local result_table = {}
    for v in string.gfind(text, "[^:]+") do
        --continue_flag = false
        -- for _, name in emojis do
        --     if name == string.lower(v) then
        --         table.insert(result_table, {
        --             emoji = name
        --         })
        --         wasEmoji = true
        --         continue_flag = true
        --         break
        --     end
        -- end
        if isInEmojis(v) then
            table.insert(result_table, {
                emoji = v
            })
            wasEmoji = true

        else
            if wasEmoji  then
                table.insert(result_table, {
                    text = v
                })
                wasEmoji = false
            else
                local len = table.getn(result_table)
                result_table[len].text = result_table[len].text .. ':' .. v
            end
        end
    end
    return result_table
end





--window that appears on input ':'
function CreateEmojiSelector()
    GUI.EmojiSelector = Bitmap(GUI.bg)
    GUI.EmojiSelector:SetSolidColor('ff000000')
    
    --GUI.EmojiSelector.Height:Set(MaxElements*(lineHeight+2))
    --GUI.EmojiSelector.Top:Set(function()return GUI.chatContainer.Top() end)
    --GUI.EmojiSelector.Width:Set(function()return GUI.chatEdit.edit.Right() - GUI.chatEdit.edit.Left() end)
    
    
    LayoutHelpers.Above(GUI.EmojiSelector, GUI.chatEdit.edit, 2)
    LayoutHelpers.AtLeftIn(GUI.EmojiSelector,GUI.chatContainer)
    LayoutHelpers.AtTopIn(GUI.EmojiSelector,GUI.chatContainer)
    LayoutHelpers.AtRightIn(GUI.EmojiSelector,GUI.chatContainer)
    --GUI.EmojiSelector:DisableHitTest()
    LayoutHelpers.DepthOverParent(GUI.EmojiSelector,GUI.chatContainer,100)
    --GUI.EmojiSelector.Depth:Set(function() return GUI.chatContainer.Depth() + 100 end)
    GUI.EmojiSelector.curIndex = 1
    GUI.EmojiSelector.MaxSize = 0
    GUI.EmojiSelector.selectionIndex = 1
    GUI.EmojiSelector.Highlight = function (self,up)
        
        self.emojiLines.lines[self.selectionIndex].bg:SetSolidColor('ff000000')
        if up == true then
            if self.selectionIndex ~= table.getn(self.FoundEmojis) then
                if self.selectionIndex - self.curIndex == self.MaxSize - 1  then
                    self.curIndex = self.curIndex + 1
                    UpdateEmojiSelector()
                end
                self.selectionIndex = self.selectionIndex + 1
            end
        elseif up == false then
            if self.selectionIndex > 1 then
                if self.selectionIndex == self.curIndex then
                    self.curIndex = self.curIndex - 1
                    UpdateEmojiSelector()
                end
                self.selectionIndex = self.selectionIndex - 1
            end   
        end
        self.emojiLines.lines[self.selectionIndex].bg:SetSolidColor('ff202020')
    end
    GUI.EmojiSelector.HandleEvent = function(self,event)
        if event.WheelRotation ~= 0 then
            if event.WheelRotation > 0 then
                if GUI.EmojiSelector.MaxSize + GUI.EmojiSelector.curIndex <= table.getn(self.FoundEmojis) then
                    GUI.EmojiSelector.curIndex = GUI.EmojiSelector.curIndex + 1
                    GUI.EmojiSelector.selectionIndex = GUI.EmojiSelector.curIndex
                    GUI.bg.curTime = 0
                    UpdateEmojiSelector()
                end
            else
                if GUI.EmojiSelector.curIndex ~= 1 then
                    GUI.EmojiSelector.curIndex = GUI.EmojiSelector.curIndex - 1
                    GUI.EmojiSelector.selectionIndex = GUI.EmojiSelector.curIndex
                    GUI.bg.curTime = 0
                    UpdateEmojiSelector()
                end
            end

        end
    end
   
end

function strcmp(str1,str2)
    local strlen
    if string.len(str1) > string.len(str2) then
        strlen = string.len(str2)
    else
        strlen = string.len(str1)
    end
    for ch = 1,strlen do
        if string.byte(str1,ch) > string.byte(str2,ch) then 
            return true
        elseif string.byte(str1,ch) < string.byte(str2,ch) then 
            return false
        end
    end
    if string.len(str1) > string.len(str2) then
        return true
    else
        return false
    end
end

function processInput(emojiText)
    local FoundEmojis = {}
    local isInserted = false
    local ind 
    for id, pack in Packages do
        if not pack.info.isEnabled then
            continue
        end
        --local packprefix = id..'/'
        for _, emoji in pack.emojis do
            isInserted = false
            if string.find(emoji, emojiText) then
                for i,FoundEmoji in FoundEmojis do
                    if strcmp(FoundEmoji.emoji,emoji) then
                        isInserted = true
                        ind = i
                        break
                    end
                end
                if isInserted then
                    table.insert(FoundEmojis, ind , {emoji = emoji,pack = id})
                else
                    table.insert(FoundEmojis,  {emoji = emoji,pack = id})
                end
            end
        end
    end
    return FoundEmojis
    --LOG(repr(FoundEmojis))
end



function UpdateEmojiSelector(emojiText)
    if GUI.EmojiSelector == nil then return end
    if emojiText then
        GUI.EmojiSelector.curIndex = 1
        GUI.EmojiSelector.emojiText = emojiText
        GUI.EmojiSelector.FoundEmojis = processInput(emojiText)
        GUI.EmojiSelector.selectionIndex = 1   
    end
    local FoundEmojis = GUI.EmojiSelector.FoundEmojis
    if GUI.EmojiSelector.emojiLines then
        GUI.EmojiSelector.emojiLines:Destroy()
    end
    GUI.EmojiSelector.emojiLines = Group(GUI.EmojiSelector)
    LayoutHelpers.FillParentFixedBorder(GUI.EmojiSelector.emojiLines, GUI.EmojiSelector)
    GUI.EmojiSelector.emojiLines.lines = {}
    LayoutHelpers.DepthOverParent(GUI.EmojiSelector.emojiLines,GUI.EmojiSelector,10)
    -- GUI.EmojiSelector.emojiLines.HandleEvent = function(self, event)

    --     if event.Type == 'MouseEnter' then
    --         --LOG('erasing')
    --         for _,line in self.lines do
    --             line.bg:SetSolidColor('ff000000') 
                
    --         end
    --     elseif event.Type == 'MouseExit' then
    --         --LOG('out')
    --         self.lines[GUI.EmojiSelector.curIndex].bg:SetSolidColor('ff202020')
    --     end
    -- end
    
   
    if not table.empty(FoundEmojis) then
        local index = GUI.EmojiSelector.curIndex
        while index <= table.getn(FoundEmojis) do
            local emojiname = FoundEmojis[index].pack .. '/' .. FoundEmojis[index].emoji
            local path = UIUtil.UIFile(emojis_textures .. emojiname .. '.dds')
            GUI.EmojiSelector.emojiLines.lines[index] = Group(GUI.EmojiSelector.emojiLines)
            local emojiLine = GUI.EmojiSelector.emojiLines.lines[index]
            
            emojiLine.HandleEvent = function(self, event)
                if event.Type == 'ButtonPress' then
                    local text =        GUI.chatEdit.edit:GetText() 
                    local CaretPos =    GUI.chatEdit.edit:GetCaretPosition()
                    
                    --LOG(GUI.EmojiSelector.emojiText)
                    local newtext = STR_Utf8SubString(text, 1, GUI.EmojiSelector.BeginPos - 1)..self.emoji..STR_Utf8SubString(text,CaretPos + 1, string.len(text))
                    local oldtext = GUI.EmojiSelector.emojiText or ''
                    GUI.EmojiSelector:Destroy()
                    GUI.EmojiSelector = nil
                    GUI.chatEdit.edit:SetText(newtext)
                    GUI.chatEdit.edit:SetCaretPosition(CaretPos + string.len(self.emoji) - 1 - string.len(oldtext))
                    GUI.chatEdit.edit:AcquireFocus()
                    
                elseif event.Type == 'MouseEnter' then
                    for _,line in GUI.EmojiSelector.emojiLines.lines do
                        line.bg:SetSolidColor('ff000000') 
                    end
                    self.bg:SetSolidColor('ff202020')
                elseif event.Type == 'MouseExit' then
                    self.bg:SetSolidColor('ff000000')
                    GUI.EmojiSelector:Highlight()
                    --GUI.EmojiSelector.emojiLines.lines[GUI.EmojiSelector.curIndex].bg:SetSolidColor('ff202020')
                end
            end
            
            LayoutHelpers.DepthOverParent(emojiLine,GUI.EmojiSelector.emojiLines)
            

            -- emojiLine.Depth:Set(function()
            --     return GUI.EmojiSelector.emojiLines.Depth() + 1
            -- end)
            
            LayoutHelpers.SetDimensions(emojiLine,lineHeight,lineHeight)
            -- emojiLine.Height:Set(lineHeight)
            -- emojiLine.Width:Set(lineHeight)
            
            
            if index == GUI.EmojiSelector.curIndex then
                LayoutHelpers.AtLeftBottomIn(emojiLine, GUI.EmojiSelector,2,2)
            else
                LayoutHelpers.Above(emojiLine, GUI.EmojiSelector.emojiLines.lines[index - 1], 2)
            end
            LayoutHelpers.AtRightIn(emojiLine,GUI.EmojiSelector.emojiLines,2)

            emojiLine.bg = Bitmap(emojiLine)
            emojiLine.bg:DisableHitTest()
            LayoutHelpers.FillParent( emojiLine.bg ,emojiLine)
            emojiLine.bg:SetSolidColor('ff000000')
            --emojiLine.icon:SetTexture(path)
            --LayoutHelpers.SetDimensions(line.teamColor,line.Height(),line.Height())


            emojiLine.icon = Bitmap(emojiLine,path)
            emojiLine.icon:DisableHitTest()
            --emojiLine.icon:SetTexture(path)
            --LayoutHelpers.SetDimensions(line.teamColor,line.Height(),line.Height())
            emojiLine.icon.Height:Set(emojiLine.Height)
            emojiLine.icon.Width:Set(emojiLine.Height)
            LayoutHelpers.AtLeftTopIn(emojiLine.icon, emojiLine)

            emojiLine.text = UIUtil.CreateText(emojiLine, '', 20, "Arial",true)
            emojiLine.text:DisableHitTest()
            --emojiLine.text:SetDropShadow(true)
            LayoutHelpers.RightOf(emojiLine.text, emojiLine.icon, 2)
            emojiLine.text:SetText(':'..FoundEmojis[index].emoji ..':')

            emojiLine.emoji =':'.. emojiname..':'

            emojiLine.pack = UIUtil.CreateText(emojiLine, '', 20, "Arial",true)
            emojiLine.pack:DisableHitTest()
            --emojiLine.pack:SetDropShadow(true)
            LayoutHelpers.AtRightIn(emojiLine.pack,GUI.EmojiSelector.emojiLines, 5)
            LayoutHelpers.AtTopIn(emojiLine.pack,emojiLine )
            emojiLine.pack:SetText(FoundEmojis[index].pack)
            emojiLine.pack:SetColor('FF808080')
            index = index + 1
            if  emojiLine:Top() - GUI.chatContainer.Top() < lineHeight then
                LayoutHelpers.AtTopIn(GUI.EmojiSelector,GUI.chatContainer)
                GUI.EmojiSelector.MaxSize = index - GUI.EmojiSelector.curIndex
                if emojiText then GUI.EmojiSelector:Highlight() end
                
                return
            end
        end
        GUI.EmojiSelector.Top:Set(function()return GUI.EmojiSelector.emojiLines.lines[index - 1].Top() - 2 end)
        GUI.EmojiSelector.MaxSize = index - GUI.EmojiSelector.curIndex
        if emojiText then GUI.EmojiSelector:Highlight() end
    else
        GUI.EmojiSelector.Top:Set(GUI.EmojiSelector.Bottom)
    end
    
end


