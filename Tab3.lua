-- Tab3.lua (Teleport – Full, Optimized, Scroll, Click-TP with keybind, Save/Load, Player TP, Follow, Loop TP, History, Random)
-- Drop as Tab3.lua and load via your main: loadstring(... )()(contentFrame, settings)

return function(parent, settings)
    ----------------------------------------------------------------
    -- Services / Locals
    ----------------------------------------------------------------
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()

    ----------------------------------------------------------------
    -- Utils
    ----------------------------------------------------------------
    local function getHRP(char)
        return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    end
    local function alive(plr)
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0 and getHRP(plr.Character)
    end

    local conns = {}
    local function bind(sig, fn)
        local c = sig:Connect(fn)
        table.insert(conns, c)
        return c
    end
    local function cleanup()
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end

    ----------------------------------------------------------------
    -- UI Root
    ----------------------------------------------------------------
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "TeleportTab"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = parent

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 1200)
    scroll.ScrollBarThickness = 8
    scroll.BackgroundTransparency = 1
    scroll.Parent = tabFrame

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll

    local function autosize()
        scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
    end
    bind(list:GetPropertyChangedSignal("AbsoluteContentSize"), autosize)

    local function section(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.94, 0, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Font = settings.Font
        lbl.TextSize = settings.TextSize + 2
        lbl.TextColor3 = settings.Theme.TabText
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.Parent = scroll
        return lbl
    end

    local function styleButton(btn)
        btn.Size = UDim2.new(0.94, 0, 0, 40)
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.AutoButtonColor = false
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = btn
        bind(btn.MouseEnter, function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = settings.Theme.TabButtonHover or settings.Theme.TabButton}):Play()
        end)
        bind(btn.MouseLeave, function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = settings.Theme.TabButton}):Play()
        end)
    end

    local function button(txt, cb)
        local b = Instance.new("TextButton")
        b.Text = txt
        styleButton(b)
        b.Parent = scroll
        bind(b.MouseButton1Click, cb)
        return b
    end

    local function toggle(txt, default, cb)
        local state = default and true or false
        local b = button(("%s: %s"):format(txt, state and "AN" or "AUS"), function()
            state = not state
            b.Text = ("%s: %s"):format(txt, state and "AN" or "AUS")
            TweenService:Create(b, TweenInfo.new(0.12), {
                BackgroundColor3 = state and (settings.Theme.TabButtonActive or settings.Theme.TabButton) or settings.Theme.TabButton
            }):Play()
            cb(state)
        end)
        if state then b.BackgroundColor3 = settings.Theme.TabButtonActive or settings.Theme.TabButton end
        return function(v)
            state = v
            b.Text = ("%s: %s"):format(txt, state and "AN" or "AUS")
            cb(state)
        end, function() return state end
    end

    local function textbox(placeholder, onCommit)
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(0.94, 0, 0, 40)
        tb.PlaceholderText = placeholder
        tb.Font = settings.Font
        tb.TextSize = settings.TextSize
        tb.BackgroundColor3 = settings.Theme.TabButton
        tb.TextColor3 = settings.Theme.TabText
        tb.ClearTextOnFocus = false
        tb.Parent = scroll
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0,8)
        bind(tb.FocusLost, function(enter) if enter then onCommit(tb.Text) end end)
        return tb
    end

    local function slider(label, minV, maxV, defaultV, step, onChange)
        step = step or 1
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(0.94, 0, 0, 62)
        holder.BackgroundTransparency = 1
        holder.Parent = scroll

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 0, 22)
        txt.BackgroundTransparency = 1
        txt.Font = settings.Font
        txt.TextSize = settings.TextSize
        txt.TextColor3 = settings.Theme.TabText
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.Text = ("%s: %s"):format(label, tostring(defaultV))
        txt.Parent = holder

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 18)
        bar.Position = UDim2.new(0, 0, 0, 30)
        bar.BackgroundColor3 = settings.Theme.TabButton
        bar.Parent = holder
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0,8)

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = settings.Theme.TabButtonActive or settings.Theme.TabButton
        fill.Size = UDim2.new((defaultV-minV)/(maxV-minV), 0, 1, 0)
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0,8)

        local dragging = false
        bind(bar.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
        bind(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

        local value = defaultV
        local function apply(v)
            v = math.clamp(v, minV, maxV)
            value = math.floor(v/step + 0.5)*step
            fill.Size = UDim2.new((value - minV)/(maxV-minV), 0, 1, 0)
            txt.Text = ("%s: %s"):format(label, tostring(value))
            onChange(value)
        end

        bind(RunService.RenderStepped, function()
            if not dragging then return end
            local mx = UIS:GetMouseLocation().X
            local x0, w = bar.AbsolutePosition.X, bar.AbsoluteSize.X
            local r = math.clamp((mx - x0)/w, 0, 1)
            local raw = minV + (maxV - minV) * r
            apply(raw)
        end)

        apply(defaultV)
        return apply, function() return value end
    end

    local function spacer(h)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.94, 0, 0, h or 8)
        f.BackgroundTransparency = 1
        f.Parent = scroll
    end

    ----------------------------------------------------------------
    -- Teleport Core
    ----------------------------------------------------------------
    local lastPos = nil
    local history = {}
    local saved = {}
    local followConn = nil
    local followName = nil
    local loopTeleporting = false
    local loopTargetVec3 = nil
    local loopInterval = 5

    local function tpTo(pos)
        local char = LocalPlayer.Character
        local hrp = getHRP(char)
        if not hrp then return end
        lastPos = hrp.Position
        table.insert(history, lastPos)
        hrp.CFrame = CFrame.new(pos)
    end

    local function tpToPlayer(plr)
        if alive(plr) then
            tpTo(getHRP(plr.Character).Position + Vector3.new(0, 3, 0))
        end
    end

    ----------------------------------------------------------------
    -- UI: Presets
    ----------------------------------------------------------------
    section("Schnell-Teleports")
    local presets = {
        ["Spawn"] = Vector3.new(0, 5, 0),
        ["Berg"] = Vector3.new(100, 200, -50),
        ["Geheime Höhle"] = Vector3.new(-250, 20, 300),
    }
    for name, pos in pairs(presets) do
        button("Teleport zu: "..name, function() tpTo(pos) end)
    end

    button("Zurück (letzte Position)", function()
        if lastPos then tpTo(lastPos) end
    end)

    spacer(6)

    ----------------------------------------------------------------
    -- UI: Koordinaten
    ----------------------------------------------------------------
    section("Koordinaten Teleport")
    local coordX, coordY, coordZ = 0, 10, 0
    textbox("x,y,z eingeben (Enter)", function(txt)
        local parts = string.split(txt, ",")
        if #parts == 3 then
            local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
            if x and y and z then
                coordX, coordY, coordZ = x, y, z
                tpTo(Vector3.new(x, y, z))
            end
        end
    end)
    button("Teleport zu gespeicherten Koordinaten", function()
        tpTo(Vector3.new(coordX, coordY, coordZ))
    end)

    spacer(6)

    ----------------------------------------------------------------
    -- UI: Spieler Teleport & Suche
    ----------------------------------------------------------------
    section("Spieler Teleport")
    local searchBox = textbox("Spieler suchen (Enter = aktualisieren)", function() end)

    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(0.94, 0, 0, 180)
    playerListFrame.BackgroundColor3 = settings.Theme.TabButton
    playerListFrame.Parent = scroll
    Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0,8)

    local innerScroll = Instance.new("ScrollingFrame")
    innerScroll.Size = UDim2.new(1, -10, 1, -10)
    innerScroll.Position = UDim2.new(0, 5, 0, 5)
    innerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    innerScroll.ScrollBarThickness = 6
    innerScroll.BackgroundTransparency = 1
    innerScroll.Parent = playerListFrame

    local innerList = Instance.new("UIListLayout")
    innerList.Padding = UDim.new(0, 6)
    innerList.Parent = innerScroll
    bind(innerList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        innerScroll.CanvasSize = UDim2.new(0, 0, 0, innerList.AbsoluteContentSize.Y + 10)
    end)

    local function rebuildPlayerList()
        innerScroll:ClearAllChildren()
        innerList.Parent = innerScroll
        local filter = string.lower(searchBox.Text or "")
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local ok = (filter == "") or string.find(string.lower(p.Name), filter, 1, true)
                if ok then
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, -6, 0, 32)
                    b.Text = "TP zu: " .. p.Name
                    b.Font = settings.Font
                    b.TextSize = settings.TextSize
                    b.BackgroundColor3 = settings.Theme.TabButtonHover or settings.Theme.TabButton
                    b.TextColor3 = settings.Theme.TabText
                    b.AutoButtonColor = false
                    b.Parent = innerScroll
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
                    bind(b.MouseButton1Click, function() tpToPlayer(p) end)
                end
            end
        end
    end
    rebuildPlayerList()
    bind(searchBox.FocusLost, function(enter) if enter then rebuildPlayerList() end end)
    bind(Players.PlayerAdded, rebuildPlayerList)
    bind(Players.PlayerRemoving, rebuildPlayerList)

    spacer(6)

    ----------------------------------------------------------------
    -- UI: Follow Mode
    ----------------------------------------------------------------
    section("Follow Mode")
    local followBtn = nil
    local function stopFollow()
        if followConn then followConn:Disconnect() end
        followConn = nil
        followName = nil
        if followBtn then followBtn.Text = "Follow: AUS" end
    end
    local function startFollow(name)
        stopFollow()
        followName = name
        followConn = RunService.Heartbeat:Connect(function()
            local tgt = Players:FindFirstChild(followName)
            if tgt and alive(tgt) then
                local pos = getHRP(tgt.Character).Position + Vector3.new(0, 3, 0)
                tpTo(pos)
            else
                stopFollow()
            end
        end)
        if followBtn then followBtn.Text = "Follow: AN ("..name..")" end
    end

    followBtn = button("Follow: AUS", function()
        if followConn then
            stopFollow()
        else
            local targetName = (searchBox.Text ~= "" and searchBox.Text) or (Players:GetPlayers()[2] and Players:GetPlayers()[2].Name)
            if targetName then
                startFollow(targetName)
            end
        end
    end)
    button("Follow stoppen", stopFollow)

    spacer(6)

    ----------------------------------------------------------------
    -- UI: Loop Teleport
    ----------------------------------------------------------------
    section("Loop Teleport")
    local setInterval, getInterval = slider("Intervall (Sek.)", 1, 30, loopInterval, 1, function(v) loopInterval = v end)

    textbox("Loop Ziel x,y,z (Enter zum Setzen)", function(txt)
        local parts = string.split(txt, ",")
        if #parts == 3 then
            local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
            if x and y and z then
                loopTargetVec3 = Vector3.new(x, y, z)
            end
        end
    end)

    local function loopTask()
        while loopTeleporting do
            if loopTargetVec3 then tpTo(loopTargetVec3) end
            for i=1, getInterval() do
                if not loopTeleporting then break end
                task.wait(1)
            end
        end
    end

    local setLoop, getLoop = toggle("Loop Teleport", false, function(on)
        loopTeleporting = on
        if on then task.spawn(loopTask) end
    end)

    spacer(6)

    ----------------------------------------------------------------
    -- UI: Save / Load / History
    ----------------------------------------------------------------
    section("Speicherplätze & History")
    local nameBox = textbox("Speichername (Enter speichert aktuelle Position)", function(_)
        local hrp = getHRP(LocalPlayer.Character)
        if hrp and nameBox.Text ~= "" then
            saved[nameBox.Text] = hrp.Position
        end
    end)

    button("Gespeicherte Orte auflisten", function()
        -- Liste neu rendern direkt darunter
        local listHolder = Instance.new("Frame")
        listHolder.Size = UDim2.new(0.94, 0, 0, 0)
        listHolder.BackgroundTransparency = 1
        listHolder.Parent = scroll

        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, 180, 0, 36)
        grid.CellPadding = UDim2.new(0, 8, 0, 8)
        grid.Parent = listHolder

        -- dynamische Höhe
        local count = 0
        for n,_ in pairs(saved) do count += 1 end
        local rows = math.max(1, math.ceil(count / math.max(1, math.floor((listHolder.AbsoluteSize.X-8)/188))))
        listHolder.Size = UDim2.new(0.94, 0, 0, rows * (36+8) + 8)

        for name, pos in pairs(saved) do
            local b = Instance.new("TextButton")
            b.Text = name
            b.Font = settings.Font
            b.TextSize = settings.TextSize
            b.BackgroundColor3 = settings.Theme.TabButton
            b.TextColor3 = settings.Theme.TabText
            b.AutoButtonColor = false
            b.Parent = listHolder
            Instance.new("UICor
