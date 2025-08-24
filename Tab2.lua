return function(parent, settings)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local HttpService = game:GetService("HttpService")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    -- ===================== UI BASE =====================
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Name = "CombatTab"
    frame.Parent = parent

    local y = 20
    local function pad(step) y = y + (step or 50) end

    -- ------- Fancy Toggle -------
    local function createToggle(label, default, callback)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(0, 270, 0, 40)
        holder.Position = UDim2.new(0, 20, 0, y)
        holder.BackgroundTransparency = 1
        holder.Parent = frame

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Text = label
        title.Font = settings.Font
        title.TextSize = settings.TextSize
        title.TextColor3 = settings.Theme.TabText
        title.Size = UDim2.new(1, -70, 1, 0)
        title.Parent = holder

        local switch = Instance.new("Frame")
        switch.Size = UDim2.new(0, 54, 0, 24)
        switch.Position = UDim2.new(1, -54, .5, -12)
        switch.BackgroundColor3 = default and settings.Theme.TabButtonActive or settings.Theme.TabButton
        switch.Parent = holder
        local swCorner = Instance.new("UICorner", switch) swCorner.CornerRadius = UDim.new(1,0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = default and UDim2.new(1, -22, .5, -10) or UDim2.new(0, 2, .5, -10)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.Parent = switch
        local kbCorner = Instance.new("UICorner", knob) kbCorner.CornerRadius = UDim.new(1,0)

        local state = default
        local function animate(to)
            TweenService:Create(switch, TweenInfo.new(0.2), {
                BackgroundColor3 = to and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = to and UDim2.new(1, -22, .5, -10) or UDim2.new(0, 2, .5, -10)
            }):Play()
        end
        switch.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                state = not state
                animate(state)
                callback(state)
            end
        end)

        pad()
        return holder
    end

    -- ------- Fancy Slider (value shown) -------
    local function createSlider(label, min, max, default, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 270, 0, 46)
        container.Position = UDim2.new(0, 20, 0, y)
        container.BackgroundTransparency = 1
        container.Parent = frame

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Font = settings.Font
        text.TextSize = settings.TextSize
        text.TextColor3 = settings.Theme.TabText
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.Size = UDim2.new(1, 0, 0, 20)
        text.Text = ("%s: %s"):format(label, tostring(default))
        text.Parent = container

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 8)
        bar.Position = UDim2.new(0, 0, 0, 30)
        bar.BackgroundColor3 = settings.Theme.TabButton
        bar.Parent = container
        local barCorner = Instance.new("UICorner", bar) barCorner.CornerRadius = UDim.new(1,0)

        local fill = Instance.new("Frame")
        local function ratioFromValue(v) return (v - min) / (max - min) end
        fill.Size = UDim2.new(ratioFromValue(default), 0, 1, 0)
        fill.BackgroundColor3 = settings.Theme.TabButtonActive
        fill.Parent = bar
        local fillCorner = Instance.new("UICorner", fill) fillCorner.CornerRadius = UDim.new(1,0)

        local dragging = false
        local function setFromMouse(x)
            local r = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
            local val = math.floor(min + (max - min) * r + 0.5)
            fill.Size = UDim2.new(r, 0, 1, 0)
            text.Text = ("%s: %s"):format(label, tostring(val))
            callback(val)
        end

        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                setFromMouse(i.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                setFromMouse(i.Position.X)
            end
        end)

        pad(56)
        return container
    end

    -- ------- Mode Switch (button cycles) -------
    local function createModeSwitch(label, modes, default, callback)
        local idx = table.find(modes, default) or 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 270, 0, 40)
        btn.Position = UDim2.new(0, 20, 0, y)
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.Text = ("%s: %s"):format(label, modes[idx])
        btn.Parent = frame
        local c = Instance.new("UICorner", btn) c.CornerRadius = UDim.new(0,8)
        btn.MouseButton1Click:Connect(function()
            idx = (idx % #modes) + 1
            btn.Text = ("%s: %s"):format(label, modes[idx])
            callback(modes[idx])
        end)
        pad()
        return btn
    end

    -- ===================== HELPERS =====================
    local function isTeammate(targetPlayer)
        if player.Team and targetPlayer.Team then
            return player.Team == targetPlayer.Team
        end
        return false
    end

    local function getAimPart(char)
        return (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
    end

    -- best available mouse move (exploit), fallback: none
    local function getMouseMoveFunc()
        local fns = {
            rawget(getgenv and getgenv() or {}, "mousemoveabs"),
            rawget(getgenv and getgenv() or {}, "mousemoverel"),
            rawget(getgenv and getgenv() or {}, "syn_mousemoveabs"),
            rawget(getgenv and getgenv() or {}, "syn_mousemoverel"),
        }
        for _, f in ipairs(fns) do if typeof(f) == "function" then return f end end
        return nil
    end
    local mouseMove = getMouseMoveFunc()

    local function screenPoint(v3)
        local v2, on = camera:WorldToViewportPoint(v3)
        return Vector2.new(v2.X, v2.Y), on
    end

    -- ===================== STATE =====================
    local ignoreTeam = true

    -- Aimbot
    local aimbotEnabled = false
    local aimbotFOV = 140
    local aimbotSmoothPct = 25      -- 0..100
    local aimbotPredictionMs = 0    -- 0..300
    local aimbotMode = "CFrame"     -- "CFrame" | "Mouse"

    -- Triggerbot
    local triggerEnabled = false
    local triggerDelayMs = 80

    -- Hitbox
    local hitboxEnabled = false
    local hitboxSize = 2
    local hitboxTarget = "Both"     -- Head/HRP/Both
    local originalSizes = {}

    -- Reach
    local reachEnabled = false
    local reachStuds = 10

    -- Auto Clicker
    local autoClickEnabled = false
    local autoCPS = 12
    local VirtualUser = game:GetService("VirtualUser")

    -- Knockback
    local reduceKBPercent = 0       -- 0..100
    local antiKBEnabled = false

    -- ===================== FOV CIRCLE =====================
    local useDrawing = pcall(function() return Drawing and Drawing.new end)
    local fovCircle, fovUI
    if useDrawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Color = settings.Theme.TabButtonActive
        fovCircle.Thickness = 2
        fovCircle.NumSides = 100
        fovCircle.Radius = aimbotFOV
        fovCircle.Filled = false
        fovCircle.Visible = false
    else
        -- UI fallback
        fovUI = Instance.new("Frame")
        fovUI.Size = UDim2.new(0, aimbotFOV*2, 0, aimbotFOV*2)
        fovUI.AnchorPoint = Vector2.new(.5,.5)
        fovUI.Position = UDim2.new(0, camera.ViewportSize.X/2, 0, camera.ViewportSize.Y/2)
        fovUI.BackgroundTransparency = 1
        fovUI.Visible = false
        fovUI.Parent = frame
        local round = Instance.new("UICorner", fovUI) round.CornerRadius = UDim.new(1,0)
        local stroke = Instance.new("UIStroke", fovUI)
        stroke.Thickness = 2
        stroke.Color = settings.Theme.TabButtonActive
    end
    local function setFovVisible(v)
        if fovCircle then fovCircle.Visible = v end
        if fovUI then fovUI.Visible = v end
    end
    local function setFovRadius(r)
        if fovCircle then fovCircle.Radius = r end
        if fovUI then fovUI.Size = UDim2.new(0, r*2, 0, r*2) end
    end
    RunService.RenderStepped:Connect(function()
        local m = UserInputService:GetMouseLocation()
        if fovCircle then fovCircle.Position = m end
        if fovUI then fovUI.Position = UDim2.new(0, m.X, 0, m.Y) end
    end)

    -- ===================== UI CONTROLS =====================
    createToggle("Ignore Teammates", true, function(s) ignoreTeam = s end)

    createToggle("Aimbot", false, function(s)
        aimbotEnabled = s
        setFovVisible(s)
    end)
    createModeSwitch("Aimbot Mode", {"CFrame","Mouse"}, "CFrame", function(m) aimbotMode = m end)
    createSlider("Aimbot FOV", 30, 400, aimbotFOV, function(v) aimbotFOV = v setFovRadius(v) end)
    createSlider("Smoothness %", 0, 100, aimbotSmoothPct, function(v) aimbotSmoothPct = v end)
    createSlider("Prediction ms", 0, 300, aimbotPredictionMs, function(v) aimbotPredictionMs = v end)

    createToggle("Triggerbot", false, function(s) triggerEnabled = s end)
    createSlider("Trigger Delay ms", 0, 300, triggerDelayMs, function(v) triggerDelayMs = v end)

    createToggle("Hitbox Expander", false, function(s)
        hitboxEnabled = s
        if not s then
            -- restore sizes
            for plr, data in pairs(originalSizes) do
                if plr.Character and plr.Character.Parent then
                    local h = plr.Character:FindFirstChild("Head")
                    local r = plr.Character:FindFirstChild("HumanoidRootPart")
                    if h and data.Head then h.Size = data.Head end
                    if r and data.HRP then r.Size = data.HRP end
                end
            end
        end
    end)
    createModeSwitch("Hitbox Target", {"Head","HRP","Both"}, "Both", function(m) hitboxTarget = m end)
    createSlider("Hitbox Scale", 1, 6, hitboxSize, function(v) hitboxSize = v end)

    createToggle("Reach Extender", false, function(s) reachEnabled = s end)
    createSlider("Reach (studs)", 5, 30, reachStuds, function(v) reachStuds = v end)

    createToggle("Auto Clicker", false, function(s) autoClickEnabled = s end)
    createSlider("CPS", 1, 25, autoCPS, function(v) autoCPS = v end)

    createSlider("Knockback Reduce %", 0, 100, reduceKBPercent, function(v) reduceKBPercent = v end)
    createToggle("Anti-Knockback", false, function(s) antiKBEnabled = s end)

    -- ===================== AIMBOT LOOP =====================
    local function getClosestTarget()
        local mousePos = UserInputService:GetMouseLocation()
        local bestChar, bestPart, bestMag = nil, nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                if not (ignoreTeam and isTeammate(plr)) then
                    local part = getAimPart(plr.Character)
                    if part then
                        local sp, on = screenPoint(part.Position)
                        if on then
                            local d = (sp - mousePos).Magnitude
                            if d < bestMag and d <= aimbotFOV then
                                bestChar, bestPart, bestMag = plr.Character, part, d
                            end
                        end
                    end
                end
            end
        end
        return bestChar, bestPart
    end

    local lastCF = camera.CFrame
    RunService.RenderStepped:Connect(function(dt)
        -- Aimbot (CFrame / Mouse)
        if aimbotEnabled then
            local char, part = getClosestTarget()
            if char and part then
                -- prediction (basic: use AssemblyLinearVelocity)
                local predSec = aimbotPredictionMs / 1000
                local vel = part.AssemblyLinearVelocity or Vector3.zero
                local predicted = part.Position + vel * predSec

                if aimbotMode == "CFrame" then
                    local targetCF = CFrame.new(camera.CFrame.Position, predicted)
                    local alpha = math.clamp(aimbotSmoothPct / 100, 0, 1)
                    -- smooth lerp
                    camera.CFrame = lastCF:Lerp(targetCF, alpha > 0 and alpha or 1)
                    lastCF = camera.CFrame
                else
                    -- Mouse mode (requires exploit), try best-effort
                    if mouseMove then
                        local sp, on = screenPoint(predicted)
                        if on then
                            -- move absolute if available, else relative
                            if tostring(debug.getinfo(mouseMove).nparams or ""):find("2") then
                                -- assume absolute
                                mouseMove(sp.X, sp.Y)
                            else
                                -- relative approximation
                                local cur = UserInputService:GetMouseLocation()
                                mouseMove(sp.X - cur.X, sp.Y - cur.Y)
                            end
                        end
                    end
                end
            end
        end

        -- Hitbox Expander (continuous ensure)
        if hitboxEnabled then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    if ignoreTeam and isTeammate(plr) then
                        -- restore teammate if needed
                        if originalSizes[plr] then
                            local h = plr.Character:FindFirstChild("Head")
                            local r = plr.Character:FindFirstChild("HumanoidRootPart")
                            if h and originalSizes[plr].Head then h.Size = originalSizes[plr].Head end
                            if r and originalSizes[plr].HRP then r.Size = originalSizes[plr].HRP end
                        end
                    else
                        originalSizes[plr] = originalSizes[plr] or {}
                        local h = plr.Character:FindFirstChild("Head")
                        local r = plr.Character:FindFirstChild("HumanoidRootPart")
                        if h then
                            originalSizes[plr].Head = originalSizes[plr].Head or h.Size
                            if hitboxTarget == "Head" or hitboxTarget == "Both" then
                                h.Size = Vector3.new(2,2,2) * hitboxSize
                                h.Massless = true
                                h.CanCollide = false
                                h.Transparency = 0.5 -- visuelle Hilfe; falls du es nicht willst, auskommentieren
                            end
                        end
                        if r then
                            originalSizes[plr].HRP = originalSizes[plr].HRP or r.Size
                            if hitboxTarget == "HRP" or hitboxTarget == "Both" then
                                r.Size = Vector3.new(2,2,1) * hitboxSize
                                r.Massless = true
                                r.CanCollide = false
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ===================== TRIGGERBOT LOOP =====================
    task.spawn(function()
        while frame.Parent do
            if triggerEnabled then
                local targetChar, targetPart = getClosestTarget()
                if targetPart then
                    task.wait(triggerDelayMs/1000)
                    -- Click: try exploit first, else VirtualUser
                    local ok = false
                    for _, fnName in ipairs({"mouse1click","mouse1press"}) do
                        local f = rawget(getgenv and getgenv() or {}, fnName)
                        if typeof(f) == "function" then
                            if fnName == "mouse1press" then
                                f() task.wait(0.02)
                                local r = rawget(getgenv() or {}, "mouse1release")
                                if typeof(r) == "function" then r() end
                            else f() end
                            ok = true break
                        end
                    end
                    if not ok then
                        pcall(function()
                            VirtualUser:Button1Down(Vector2.new(), camera.CFrame)
                            task.wait(0.02)
                            VirtualUser:Button1Up(Vector2.new(), camera.CFrame)
                        end)
                    end
                end
            end
            task.wait(0.01)
        end
    end)

    -- ===================== AUTO CLICKER LOOP =====================
    task.spawn(function()
        while frame.Parent do
            if autoClickEnabled and autoCPS > 0 then
                local interval = 1 / autoCPS
                local ok = false
                local m1 = rawget(getgenv() or {}, "mouse1click")
                if typeof(m1) == "function" then m1(); ok = true end
                if not ok then
                    pcall(function()
                        VirtualUser:Button1Down(Vector2.new(), camera.CFrame)
                        task.wait(0.015)
                        VirtualUser:Button1Up(Vector2.new(), camera.CFrame)
                    end)
                end
                task.wait(interval)
            else
                task.wait(0.05)
            end
        end
    end)

    -- ===================== REACH EXTENDER =====================
    -- generischer Raycast-Reach (funktioniert für einige Nahkampf-Spiele, universal nicht garantiert)
    local mouseDown = false
    UserInputService.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = false end
    end)

    task.spawn(function()
        while frame.Parent do
            if reachEnabled and mouseDown then
                local origin = camera.CFrame.Position
                local dir = camera.CFrame.LookVector * reachStuds
                local ray = Ray.new(origin, dir)
                local part, pos = workspace:FindPartOnRay(ray, player.Character, false, true)
                -- Hier könntest du spiel-spezifische Remotes/Hit-Funktionen anstoßen,
                -- falls ein gegnerischer Charakter getroffen wurde.
            end
            task.wait(0.02)
        end
    end)

    -- ===================== KNOCKBACK CONTROL =====================
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local function onVelocityChanged()
        if not hrp then return end
        if antiKBEnabled then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        elseif reduceKBPercent > 0 then
            local factor = 1 - (reduceKBPercent / 100)
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity * factor
            hrp.AssemblyAngularVelocity = hrp.AssemblyAngularVelocity * factor
        end
    end
    hrp:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(onVelocityChanged)
    hrp:GetPropertyChangedSignal("AssemblyAngularVelocity"):Connect(onVelocityChanged)

    player.CharacterAdded:Connect(function(nc)
        char = nc
        hrp = char:WaitForChild("HumanoidRootPart")
        hrp:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(onVelocityChanged)
        hrp:GetPropertyChangedSignal("AssemblyAngularVelocity"):Connect(onVelocityChanged)
    end)

    -- ===================== CLEANUP =====================
    frame.Destroying:Connect(function()
        if fovCircle then pcall(function() fovCircle.Visible = false fovCircle:Remove() end) end
        -- restore hitboxes
        for plr, data in pairs(originalSizes) do
            if plr.Character then
                local h = plr.Character:FindFirstChild("Head")
                local r = plr.Character:FindFirstChild("HumanoidRootPart")
                if h and data.Head then h.Size = data.Head h.Transparency = 0 end
                if r and data.HRP then r.Size = data.HRP end
            end
        end
    end)

    return frame
end
