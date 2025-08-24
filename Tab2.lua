return function(parent, settings)
    -- Services & locals
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local HttpService = game:GetService("HttpService")
    local VirtualUser = game:GetService("VirtualUser")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    -- ========= UI: Scrolling container =========
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "CombatTab"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 1400)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1
    scroll.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    -- Auto expand CanvasSize
    local function updateCanvas()
        task.defer(function()
            local total = 0
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("GuiObject") and c ~= layout then
                    total += c.AbsoluteSize.Y + (layout.Padding.Offset or 0)
                end
            end
            scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(600, total + 40))
        end)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

    -- ========= UI helpers =========
    local function makeButtonLike(frame)
        frame.AutoButtonColor = false
        local s,e = settings.Theme.TabButton, settings.Theme.TabButtonActive
        local function pulse(focus)
            TweenService:Create(frame, TweenInfo.new(0.2), {
                BackgroundColor3 = focus and e or s
            }):Play()
        end
        frame.MouseEnter:Connect(function() pulse(true) end)
        frame.MouseLeave:Connect(function() pulse(false) end)
    end

    local function createToggle(label, default, callback)
        local holder = Instance.new("TextButton")
        holder.Size = UDim2.new(1, -20, 0, 44)
        holder.BackgroundColor3 = settings.Theme.TabButton
        holder.Text = ""
        holder.Parent = scroll
        makeButtonLike(holder)

        local corner = Instance.new("UICorner", holder)
        corner.CornerRadius = UDim.new(0, 10)

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Font = settings.Font
        title.TextSize = settings.TextSize
        title.TextColor3 = settings.Theme.TabText
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = label
        title.Size = UDim2.new(1, -80, 1, 0)
        title.Position = UDim2.new(0, 12, 0, 0)
        title.Parent = holder

        local switch = Instance.new("Frame")
        switch.Size = UDim2.new(0, 52, 0, 24)
        switch.Position = UDim2.new(1, -64, 0.5, -12)
        switch.BackgroundColor3 = default and settings.Theme.TabButtonActive or settings.Theme.TabButton
        switch.Parent = holder
        Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.Parent = switch
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = default
        holder.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(switch, TweenInfo.new(0.2), {
                BackgroundColor3 = state and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = state and UDim2.new(1, -22, .5, -10) or UDim2.new(0, 2, .5, -10)
            }):Play()
            callback(state)
        end)

        updateCanvas()
        return holder
    end

    local function createSlider(label, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 64)
        frame.BackgroundTransparency = 1
        frame.Parent = scroll

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Font = settings.Font
        title.TextSize = settings.TextSize
        title.TextColor3 = settings.Theme.TabText
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = ("%s: %s"):format(label, tostring(default))
        title.Size = UDim2.new(1, 0, 0, 24)
        title.Position = UDim2.new(0, 2, 0, 2)
        title.Parent = frame

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 10)
        bar.Position = UDim2.new(0, 0, 0, 40)
        bar.BackgroundColor3 = settings.Theme.TabButton
        bar.Parent = frame
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = settings.Theme.TabButtonActive
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function setFromX(x)
            local r = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
            local val = math.floor(min + (max - min) * r + 0.5)
            fill.Size = UDim2.new(r, 0, 1, 0)
            title.Text = ("%s: %s"):format(label, tostring(val))
            callback(val)
        end
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true setFromX(i.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end
        end)

        updateCanvas()
        return frame
    end

    local function createModeSwitch(label, modes, default, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 44)
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.Text = ("%s: %s"):format(label, default)
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        makeButtonLike(btn)

        local idx = table.find(modes, default) or 1
        btn.MouseButton1Click:Connect(function()
            idx = (idx % #modes) + 1
            local v = modes[idx]
            btn.Text = ("%s: %s"):format(label, v)
            callback(v)
        end)

        updateCanvas()
        return btn
    end

    -- ========= Helpers =========
    local function teammate(plr)
        if player.Team and plr.Team then return player.Team == plr.Team end
        return false
    end
    local function aimPart(char)
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    end
    local function toScreen(v3)
        local v2, on = camera:WorldToViewportPoint(v3)
        return Vector2.new(v2.X, v2.Y), on
    end
    local function getgenvfunc(names)
        local g = (getgenv and getgenv()) or {}
        for _, n in ipairs(names) do
            local f = rawget(g, n)
            if typeof(f) == "function" then return f end
        end
        return nil
    end
    local mouseMoveAbs = getgenvfunc({"mousemoveabs","syn_mousemoveabs"})
    local mouseMoveRel = getgenvfunc({"mousemoverel","syn_mousemoverel"})
    local mouseClick   = getgenvfunc({"mouse1click"})
    local mousePress   = getgenvfunc({"mouse1press"})
    local mouseRelease = getgenvfunc({"mouse1release"})

    -- ========= State =========
    local ignoreTeam = true

    -- Aimbot
    local aimbotEnabled = false
    local aimbotFOV = 140
    local aimbotSmoothPct = 25     -- 0..100
    local aimbotPredictionMs = 0   -- 0..300
    local aimbotMode = "CFrame"    -- "CFrame" | "Mouse"

    -- Triggerbot
    local triggerEnabled = false
    local triggerDelayMs = 80
    local triggerCooldown = 0

    -- Hitbox
    local hitboxEnabled = false
    local hitboxScale = 3
    local hitboxTarget = "Both"    -- Head/HRP/Both
    local originals = {}           -- per-player size backup

    -- Reach
    local reachEnabled = false
    local reachStuds = 12
    local isMouseDown = false

    -- Auto Clicker
    local autoClickEnabled = false
    local autoCPS = 12

    -- Knockback
    local reduceKBPercent = 0
    local antiKBEnabled = false

    -- ========= FOV Circle (Drawing fallback to UI) =========
    local hasDrawing = pcall(function() return Drawing and Drawing.new end)
    local fovCircle, fovUI
    if hasDrawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Color = settings.Theme.TabButtonActive
        fovCircle.Thickness = 2
        fovCircle.NumSides = 100
        fovCircle.Radius = aimbotFOV
        fovCircle.Filled = false
        fovCircle.Visible = false
    else
        fovUI = Instance.new("Frame")
        fovUI.Size = UDim2.new(0, aimbotFOV*2, 0, aimbotFOV*2)
        fovUI.AnchorPoint = Vector2.new(.5,.5)
        fovUI.Position = UDim2.new(0, camera.ViewportSize.X/2, 0, camera.ViewportSize.Y/2)
        fovUI.BackgroundTransparency = 1
        fovUI.Visible = false
        fovUI.Parent = scroll
        local stroke = Instance.new("UIStroke", fovUI)
        stroke.Thickness = 2
        stroke.Color = settings.Theme.TabButtonActive
        local corner = Instance.new("UICorner", fovUI)
        corner.CornerRadius = UDim.new(1,0)
    end
    local function setFOVVisible(v)
        if fovCircle then fovCircle.Visible = v end
        if fovUI then fovUI.Visible = v end
    end
    local function setFOVRadius(r)
        if fovCircle then fovCircle.Radius = r end
        if fovUI then fovUI.Size = UDim2.new(0, r*2, 0, r*2) end
    end
    RunService.RenderStepped:Connect(function()
        local m = UserInputService:GetMouseLocation()
        if fovCircle then fovCircle.Position = m end
        if fovUI then fovUI.Position = UDim2.new(0, m.X, 0, m.Y) end
    end)

    -- ========= UI Controls =========
    createToggle("Ignore Teammates", true, function(s) ignoreTeam = s end)

    createToggle("Aimbot", false, function(s) aimbotEnabled = s setFOVVisible(s) end)
    createModeSwitch("Aimbot Mode", {"CFrame","Mouse"}, "CFrame", function(v) aimbotMode = v end)
    createSlider("Aimbot FOV", 30, 400, aimbotFOV, function(v) aimbotFOV = v setFOVRadius(v) end)
    createSlider("Smoothness %", 0, 100, aimbotSmoothPct, function(v) aimbotSmoothPct = v end)
    createSlider("Prediction ms", 0, 300, aimbotPredictionMs, function(v) aimbotPredictionMs = v end)

    createToggle("Triggerbot", false, function(s) triggerEnabled = s end)
    createSlider("Trigger Delay (ms)", 0, 300, triggerDelayMs, function(v) triggerDelayMs = v end)

    createToggle("Hitbox Expander", false, function(s)
        hitboxEnabled = s
        if not s then
            for plr, data in pairs(originals) do
                if plr.Character then
                    local h = plr.Character:FindFirstChild("Head")
                    local r = plr.Character:FindFirstChild("HumanoidRootPart")
                    if h and data.Head then h.Size = data.Head end
                    if r and data.HRP then r.Size = data.HRP end
                end
            end
        end
    end)
    createModeSwitch("Hitbox Target", {"Head","HRP","Both"}, "Both", function(v) hitboxTarget = v end)
    createSlider("Hitbox Scale", 1, 6, hitboxScale, function(v) hitboxScale = v end)

    createToggle("Reach Extender", false, function(s) reachEnabled = s end)
    createSlider("Reach (studs)", 5, 30, reachStuds, function(v) reachStuds = v end)

    createToggle("Auto Clicker", false, function(s) autoClickEnabled = s end)
    createSlider("CPS", 1, 25, autoCPS, function(v) autoCPS = v end)

    createSlider("Knockback Reduce %", 0, 100, reduceKBPercent, function(v) reduceKBPercent = v end)
    createToggle("Anti-Knockback", false, function(s) antiKBEnabled = s end)

    updateCanvas()

    -- ========= Targeting helpers =========
    local function closestInFOV()
        local mousePos = UserInputService:GetMouseLocation()
        local bestChar, bestPart, bestMag = nil, nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character.Parent then
                if not (ignoreTeam and teammate(plr)) then
                    local part = aimPart(plr.Character)
                    if part then
                        local sp, on = toScreen(part.Position)
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

    -- ========= AIMBOT LOOP =========
    local lastCF = camera.CFrame
    RunService.RenderStepped:Connect(function()
        if not aimbotEnabled then return end
        local char, part = closestInFOV()
        if not part then return end

        local leadT = aimbotPredictionMs / 1000
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        local predicted = part.Position + vel * leadT

        if aimbotMode == "CFrame" then
            local target = CFrame.new(camera.CFrame.Position, predicted)
            local alpha = math.clamp(aimbotSmoothPct / 100, 0, 1)
            camera.CFrame = lastCF:Lerp(target, (alpha > 0 and alpha or 1))
            lastCF = camera.CFrame
        else
            -- Mouse mode (exploit APIs)
            local sp, on = toScreen(predicted)
            if on then
                local cur = UserInputService:GetMouseLocation()
                local dx, dy = sp.X - cur.X, sp.Y - cur.Y
                local alpha = math.clamp(aimbotSmoothPct / 100, 0, 1)
                dx, dy = dx * alpha, dy * alpha
                if mouseMoveAbs then
                    mouseMoveAbs(cur.X + dx, cur.Y + dy)
                elseif mouseMoveRel then
                    mouseMoveRel(dx, dy)
                end
            end
        end
    end)

    -- ========= TRIGGERBOT LOOP =========
    task.spawn(function()
        while scroll.Parent do
            local now = os.clock()
            if triggerEnabled and now >= triggerCooldown then
                local mousePos = UserInputService:GetMouseLocation()
                local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {player.Character}
                params.FilterType = Enum.RaycastFilterType.Blacklist
                local rc = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
                if rc and rc.Instance then
                    local model = rc.Instance:FindFirstAncestorOfClass("Model")
                    if model and model:FindFirstChild("Humanoid") then
                        local owner = Players:GetPlayerFromCharacter(model)
                        if owner and owner ~= player and not (ignoreTeam and teammate(owner)) then
                            -- wait delay and click
                            triggerCooldown = now + (triggerDelayMs/1000)
                            task.wait(triggerDelayMs/1000)
                            if mouseClick then mouseClick()
                            elseif mousePress and mouseRelease then mousePress(); task.wait(0.02); mouseRelease()
                            else
                                pcall(function()
                                    VirtualUser:Button1Down(Vector2.new(), camera.CFrame)
                                    task.wait(0.02)
                                    VirtualUser:Button1Up(Vector2.new(), camera.CFrame)
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.01)
        end
    end)

    -- ========= HITBOX EXPANDER (maintain) =========
    RunService.Heartbeat:Connect(function()
        if not hitboxEnabled then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character.Parent then
                if ignoreTeam and teammate(plr) then
                    -- restore teammate
                    local data = originals[plr]
                    if data and plr.Character then
                        local h = plr.Character:FindFirstChild("Head")
                        local r = plr.Character:FindFirstChild("HumanoidRootPart")
                        if h and data.Head then h.Size = data.Head end
                        if r and data.HRP then r.Size = data.HRP end
                    end
                else
                    originals[plr] = originals[plr] or {}
                    local h = plr.Character:FindFirstChild("Head")
                    local r = plr.Character:FindFirstChild("HumanoidRootPart")
                    if h then
                        originals[plr].Head = originals[plr].Head or h.Size
                        if hitboxTarget == "Head" or hitboxTarget == "Both" then
                            h.Size = Vector3.new(2,2,2) * hitboxScale
                            h.Massless = true
                            h.CanCollide = false
                        end
                    end
                    if r then
                        originals[plr].HRP = originals[plr].HRP or r.Size
                        if hitboxTarget == "HRP" or hitboxTarget == "Both" then
                            r.Size = Vector3.new(2,2,1) * hitboxScale
                            r.Massless = true
                            r.CanCollide = false
                        end
                    end
                end
            end
        end
    end)

    -- ========= REACH (generic raycast assist when clicking) =========
    UserInputService.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then isMouseDown = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then isMouseDown = false end
    end)
    task.spawn(function()
        while scroll.Parent do
            if reachEnabled and isMouseDown then
                local origin = camera.CFrame.Position
                local dir = camera.CFrame.LookVector * reachStuds
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {player.Character}
                params.FilterType = Enum.RaycastFilterType.Blacklist
                local rc = workspace:Raycast(origin, dir, params)
                -- Spiel-spezifisches „Hit“-Auslösen ist serverseitig;
                -- hier ggf. zusammen mit AutoClicker/Triggerbot kombinieren.
                -- Wir klicken einmal zusätzlich, falls etwas im Reach liegt:
                if rc then
                    if mouseClick then mouseClick()
                    elseif mousePress and mouseRelease then mousePress(); task.wait(0.02); mouseRelease()
                    else
                        pcall(function()
                            VirtualUser:Button1Down(Vector2.new(), camera.CFrame)
                            task.wait(0.02)
                            VirtualUser:Button1Up(Vector2.new(), camera.CFrame)
                        end)
                    end
                end
            end
            task.wait(0.03)
        end
    end)

    -- ========= AUTO CLICKER =========
    task.spawn(function()
        while scroll.Parent do
            if autoClickEnabled and autoCPS > 0 then
                local interval = 1 / autoCPS
                if mouseClick then mouseClick()
                elseif mousePress and mouseRelease then mousePress(); task.wait(0.02); mouseRelease()
                else
                    pcall(function()
                        VirtualUser:Button1Down(Vector2.new(), camera.CFrame)
                        task.wait(0.015)
                        VirtualUser:Button1Up(Vector2.new(), camera.CFrame)
                    end)
                end
                task.wait(interval)
            else
                task.wait(0.06)
            end
        end
    end)

    -- ========= KNOCKBACK CONTROL =========
    local function hookChar(c)
        local hrp = c:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        local function onVel()
            if antiKBEnabled then
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                hrp.AssemblyAngularVelocity = Vector3.zero
            elseif reduceKBPercent > 0 then
                local factor = 1 - (reduceKBPercent / 100)
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X * factor,
                    hrp.AssemblyLinearVelocity.Y,
                    hrp.AssemblyLinearVelocity.Z * factor
                )
                hrp.AssemblyAngularVelocity *= factor
            end
        end
        hrp:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(onVel)
        hrp:GetPropertyChangedSignal("AssemblyAngularVelocity"):Connect(onVel)
    end
    if player.Character then hookChar(player.Character) end
    player.CharacterAdded:Connect(hookChar)

    -- ========= CLEANUP =========
    scroll.Destroying:Connect(function()
        if fovCircle then pcall(function() fovCircle.Visible = false fovCircle:Remove() end) end
        for plr, data in pairs(originals) do
            if plr.Character then
                local h = plr.Character:FindFirstChild("Head")
                local r = plr.Character:FindFirstChild("HumanoidRootPart")
                if h and data.Head then h.Size = data.Head end
                if r and data.HRP then r.Size = data.HRP end
            end
        end
    end)

    return scroll
end
