--// Tab2.lua - Combat (Aimbot Mouse/CFrame + Keybind, FOV, Smooth, Prediction, Triggerbot, Hitbox, Reach, AutoClicker, Anti-Knockback)
--// Modul-API: return function(parent: Instance, settings: table) -> ScrollingFrame
return function(parent, settings)
    -- Services
    local Players            = game:GetService("Players")
    local RunService         = game:GetService("RunService")
    local UserInputService   = game:GetService("UserInputService")
    local TweenService       = game:GetService("TweenService")
    local VirtualUser        = game:GetService("VirtualUser")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    -- ====== UI: Scroll-Container (übernimmt Theme/Font/TextSize) ======
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "CombatTab"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0, 0, 0, 1500)
    scroll.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    local function recolor(btn, active)
        TweenService:Create(btn, TweenInfo.new(0.18), {
            BackgroundColor3 = active and settings.Theme.TabButtonActive or settings.Theme.TabButton
        }):Play()
    end

    local function makeToggle(label, default, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, math.max(44, settings.TextSize + 16))
        b.BackgroundColor3 = settings.Theme.TabButton
        b.TextColor3 = settings.Theme.TabText
        b.Font = settings.Font
        b.TextSize = settings.TextSize
        b.Text = string.format("%s: %s", label, default and "ON" or "OFF")
        b.Parent = scroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        recolor(b, default)
        local state = default
        b.MouseButton1Click:Connect(function()
            state = not state
            b.Text = string.format("%s: %s", label, state and "ON" or "OFF")
            recolor(b, state)
            cb(state)
        end)
        return b
    end

    local function makeSlider(label, min, max, default, cb)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, math.max(64, settings.TextSize + 32))
        frame.BackgroundTransparency = 1
        frame.Parent = scroll

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.TextColor3 = settings.Theme.TabText
        title.Font = settings.Font
        title.TextSize = settings.TextSize
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = string.format("%s: %d", label, default)
        title.Size = UDim2.new(1, 0, 0, settings.TextSize + 6)
        title.Parent = frame

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 10)
        bar.Position = UDim2.new(0, 0, 0, settings.TextSize + 18)
        bar.BackgroundColor3 = settings.Theme.TabButton
        bar.Parent = frame
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = settings.Theme.TabButtonActive
        fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function setFromX(x)
            local r = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
            local v = math.floor(min + (max - min) * r + 0.5)
            fill.Size = UDim2.new(r, 0, 1, 0)
            title.Text = string.format("%s: %d", label, v)
            cb(v)
        end
        bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging = true setFromX(i.Position.X) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging = false end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end end)
        return frame
    end

    local function makeModeSwitch(label, modes, default, cb)
        local idx = table.find(modes, default) or 1
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, math.max(44, settings.TextSize + 16))
        b.BackgroundColor3 = settings.Theme.TabButton
        b.TextColor3 = settings.Theme.TabText
        b.Font = settings.Font
        b.TextSize = settings.TextSize
        b.Text = string.format("%s: %s", label, modes[idx])
        b.Parent = scroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        b.MouseButton1Click:Connect(function()
            idx = (idx % #modes) + 1
            local v = modes[idx]
            b.Text = string.format("%s: %s", label, v)
            cb(v)
        end)
        return b
    end

    local function makeKeybind(label, defaultEnum, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, math.max(44, settings.TextSize + 16))
        b.BackgroundColor3 = settings.Theme.TabButton
        b.TextColor3 = settings.Theme.TabText
        b.Font = settings.Font
        b.TextSize = settings.TextSize
        b.Text = string.format("%s: %s", label, defaultEnum.Name)
        b.Parent = scroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        b.MouseButton1Click:Connect(function()
            b.Text = string.format("%s: [Taste drücken]", label)
            local conn; conn = UserInputService.InputBegan:Connect(function(i, gp)
                if gp then return end
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 then
                    b.Text = string.format("%s: %s", label, i.UserInputType.Name)
                    conn:Disconnect()
                    cb(i.UserInputType)
                end
            end)
        end)
        return b
    end

    -- ====== Env / Executor Funktionen (best effort) ======
    local function getFn(names)
        local env = (getgenv and getgenv()) or {}
        for _, n in ipairs(names) do
            local f = rawget(env, n)
            if typeof(f) == "function" then return f end
        end
        return nil
    end
    local mouseMoveAbs = getFn({"mousemoveabs","syn_mousemoveabs"})
    local mouseMoveRel = getFn({"mousemoverel","syn_mousemoverel"})
    local mouse1click  = getFn({"mouse1click"})
    local mouse1press  = getFn({"mouse1press"})
    local mouse1release= getFn({"mouse1release"})

    local VIM = nil
    pcall(function() VIM = game:GetService("VirtualInputManager") end)

    local function moveMouseTo(x, y)
        if mouseMoveAbs then
            mouseMoveAbs(x, y)
        elseif mouseMoveRel then
            local cur = UserInputService:GetMouseLocation()
            mouseMoveRel(x - cur.X, y - cur.Y)
        elseif VIM and VIM.SendMouseMoveEvent then
            VIM:SendMouseMoveEvent(x, y, false)
        end
    end

    local function clickOnce()
        if mouse1click then
            mouse1click()
        elseif mouse1press and mouse1release then
            mouse1press(); task.wait(0.016); mouse1release()
        else
            pcall(function()
                VirtualUser:Button1Down(Vector2.new(), camera.CFrame)
                task.wait(0.02)
                VirtualUser:Button1Up(Vector2.new(), camera.CFrame)
            end)
        end
    end

    -- ====== State ======
    local ignoreTeam           = true

    local aimEnabled           = false
    local aimMode              = "Mouse" -- "Mouse" | "CFrame"
    local aimKey               = Enum.UserInputType.MouseButton2 -- RMB
    local aimHeld              = false
    local aimFOV               = 160
    local aimSmoothPct         = 30   -- 0..100 (höher = weicher/langsamer)
    local aimPredictionMs      = 60   -- 0..300
    local stickyMs             = 450

    local triggerEnabled       = false
    local triggerDelayMs       = 80

    local hitboxEnabled        = false
    local hitboxScale          = 3
    local hitboxTarget         = "Both" -- Head/HRP/Both
    local originalSizes        = {}     -- plr -> {Head=Vector3, HRP=Vector3}

    local reachEnabled         = false
    local reachStuds           = 14
    local mouseDown            = false

    local autoClickEnabled     = false
    local autoCPS              = 12

    local antiKBEnabled        = false
    local reduceKBPercent      = 0

    -- ====== FOV-Visual (Drawing oder UI-Fallback) ======
    local useDrawing = pcall(function() return Drawing and Drawing.new end)
    local fovCircle, fovUI
    if useDrawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Color = settings.Theme.TabButtonActive
        fovCircle.Thickness = 2
        fovCircle.Filled = false
        fovCircle.NumSides = 100
        fovCircle.Radius = aimFOV
        fovCircle.Visible = false
    else
        fovUI = Instance.new("Frame")
        fovUI.Size = UDim2.new(0, aimFOV*2, 0, aimFOV*2)
        fovUI.AnchorPoint = Vector2.new(.5,.5)
        fovUI.Position = UDim2.new(0, camera.ViewportSize.X/2, 0, camera.ViewportSize.Y/2)
        fovUI.BackgroundTransparency = 1
        fovUI.Visible = false
        fovUI.Parent = scroll
        local stroke = Instance.new("UIStroke", fovUI)
        stroke.Thickness = 2
        stroke.Color = settings.Theme.TabButtonActive
        local corner = Instance.new("UICorner", fovUI)
        corner.CornerRadius = UDim.new(1, 0)
    end
    local function setFOVVisible(v) if fovCircle then fovCircle.Visible = v end if fovUI then fovUI.Visible = v end end
    local function setFOVRadius(r) if fovCircle then fovCircle.Radius = r end if fovUI then fovUI.Size = UDim2.new(0, r*2, 0, r*2) end end
    RunService.RenderStepped:Connect(function()
        local m = UserInputService:GetMouseLocation()
        if fovCircle then fovCircle.Position = m end
        if fovUI then fovUI.Position = UDim2.new(0, m.X, 0, m.Y) end
    end)

    -- ====== Helpers ======
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

    -- ====== UI Controls ======
    makeToggle("Ignore Teammates", true, function(v) ignoreTeam = v end)

    makeToggle("Aimbot", false, function(v) aimEnabled = v setFOVVisible(v) end)
    makeModeSwitch("Aimbot Modus", {"Mouse","CFrame"}, "Mouse", function(m) aimMode = m end)
    makeKeybind("Aim Key", aimKey, function(k) aimKey = k end)
    makeSlider("Aimbot FOV", 30, 400, aimFOV, function(v) aimFOV = v setFOVRadius(v) end)
    makeSlider("Smoothness %", 0, 100, aimSmoothPct, function(v) aimSmoothPct = v end)
    makeSlider("Prediction ms", 0, 300, aimPredictionMs, function(v) aimPredictionMs = v end)
    makeSlider("Sticky (ms)", 0, 1000, stickyMs, function(v) stickyMs = v end)

    makeToggle("Triggerbot", false, function(v) triggerEnabled = v end)
    makeSlider("Trigger Delay (ms)", 0, 300, triggerDelayMs, function(v) triggerDelayMs = v end)

    makeToggle("Hitbox Expander", false, function(v)
        hitboxEnabled = v
        if not v then
            for plr, data in pairs(originalSizes) do
                if plr.Character then
                    local h = plr.Character:FindFirstChild("Head")
                    local r = plr.Character:FindFirstChild("HumanoidRootPart")
                    if h and data.Head then h.Size = data.Head end
                    if r and data.HRP  then r.Size = data.HRP  end
                end
            end
        end
    end)
    makeModeSwitch("Hitbox Ziel", {"Head","HRP","Both"}, "Both", function(m) hitboxTarget = m end)
    makeSlider("Hitbox Scale", 1, 6, hitboxScale, function(v) hitboxScale = v end)

    makeToggle("Reach", false, function(v) reachEnabled = v end)
    makeSlider("Reach (studs)", 6, 30, reachStuds, function(v) reachStuds = v end)

    makeToggle("Auto Clicker", false, function(v) autoClickEnabled = v end)
    makeSlider("CPS", 1, 25, autoCPS, function(v) autoCPS = v end)

    makeToggle("Anti-Knockback", false, function(v) antiKBEnabled = v end)
    makeSlider("Knockback Reduce %", 0, 100, reduceKBPercent, function(v) reduceKBPercent = v end)

    -- ====== Input (Aim Key hold) ======
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.UserInputType == aimKey then aimHeld = true end
        if i.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = true end
    end)
    UserInputService.InputEnded:Connect(function(i, gp)
        if gp then return end
        if i.UserInputType == aimKey then aimHeld = false end
        if i.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = false end
    end)

    -- ====== Targeting ======
    local lockedPart, lockedChar, stickyUntil = nil, nil, 0

    local function validTarget(plr)
        if not plr or plr == player then return false end
        if ignoreTeam and teammate(plr) then return false end
        return plr.Character and plr.Character.Parent ~= nil and plr.Character:FindFirstChild("Humanoid")
    end

    local function pickTarget()
        local mpos = UserInputService:GetMouseLocation()
        local best, bestChar, bestMag = nil, nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if validTarget(plr) then
                local ap = aimPart(plr.Character)
                if ap then
                    local sp, on = toScreen(ap.Position)
                    if on then
                        local d = (sp - mpos).Magnitude
                        if d < bestMag and d <= aimFOV then
                            best, bestChar, bestMag = ap, plr.Character, d
                        end
                    end
                end
            end
        end
        return best, bestChar
    end

    local function stillValid(ap, ch)
        if not ap or not ch or not ch.Parent then return false end
        local mpos = UserInputService:GetMouseLocation()
        local sp, on = toScreen(ap.Position)
        if not on then return false end
        if (sp - mpos).Magnitude > aimFOV then return false end
        return true
    end

    -- ====== AIMBOT LOOP ======
    local lastCamCF = camera.CFrame
    RunService.RenderStepped:Connect(function()
        -- FOV pos wird oben separat aktualisiert

        if not (aimEnabled and aimHeld) then return end

        -- Ziel halten, ggf. neu wählen
        if lockedPart and lockedChar and stillValid(lockedPart, lockedChar) and os.clock() < stickyUntil then
            -- keep
        else
            lockedPart, lockedChar = pickTarget()
            stickyUntil = os.clock() + (stickyMs/1000)
        end
        if not lockedPart then return end

        local lead = aimPredictionMs / 1000
        local vel  = lockedPart.AssemblyLinearVelocity or Vector3.zero
        local predicted = lockedPart.Position + vel * lead

        if aimMode == "CFrame" then
            local targetCF = CFrame.new(camera.CFrame.Position, predicted)
            local alpha = math.clamp(aimSmoothPct/100, 0, 1)
            camera.CFrame = lastCamCF:Lerp(targetCF, alpha > 0 and alpha or 1)
            lastCamCF = camera.CFrame
        else
            local sp, on = toScreen(predicted)
            if on then
                local cur = UserInputService:GetMouseLocation()
                -- Smoothness: höher => weniger Schritt => weicher
                local stepFactor = math.clamp(1 - (aimSmoothPct/100), 0.02, 1)
                moveMouseTo(cur.X + (sp.X - cur.X)*stepFactor, cur.Y + (sp.Y - cur.Y)*stepFactor)
            end
        end
    end)

    -- ====== TRIGGERBOT LOOP ======
    task.spawn(function()
        while scroll.Parent do
            if triggerEnabled and aimHeld then
                local m = UserInputService:GetMouseLocation()
                local ray = camera:ViewportPointToRay(m.X, m.Y)
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {player.Character}
                params.FilterType = Enum.RaycastFilterType.Blacklist
                local rc = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
                local shoot = false
                if rc and rc.Instance then
                    local mdl = rc.Instance:FindFirstAncestorOfClass("Model")
                    if mdl and mdl:FindFirstChildOfClass("Humanoid") then
                        local plr = Players:GetPlayerFromCharacter(mdl)
                        if validTarget(plr) then shoot = true end
                    end
                end
                if shoot then
                    task.wait(triggerDelayMs/1000)
                    clickOnce()
                end
            end
            task.wait(0.01)
        end
    end)

    -- ====== HITBOX EXPANDER ======
    RunService.Heartbeat:Connect(function()
        if not hitboxEnabled then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if validTarget(plr) then
                originalSizes[plr] = originalSizes[plr] or {}
                local h = plr.Character:FindFirstChild("Head")
                local r = plr.Character:FindFirstChild("HumanoidRootPart")
                if h then originalSizes[plr].Head = originalSizes[plr].Head or h.Size end
                if r then originalSizes[plr].HRP  = originalSizes[plr].HRP  or r.Size end
                if hitboxTarget == "Head" or hitboxTarget == "Both" then
                    if h then
                        h.Size = Vector3.new(2,2,2) * hitboxScale
                        h.Massless = true
                        h.CanCollide = false
                    end
                end
                if hitboxTarget == "HRP" or hitboxTarget == "Both" then
                    if r then
                        r.Size = Vector3.new(2,2,1) * hitboxScale
                        r.Massless = true
                        r.CanCollide = false
                    end
                end
            end
        end
    end)

    -- ====== REACH (generischer Assist bei M1 gehalten) ======
    task.spawn(function()
        while scroll.Parent do
            if reachEnabled and mouseDown then
                local origin = camera.CFrame.Position
                local dir = camera.CFrame.LookVector * reachStuds
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {player.Character}
                params.FilterType = Enum.RaycastFilterType.Blacklist
                local rc = workspace:Raycast(origin, dir, params)
                if rc then
                    clickOnce() -- generischer „Hit“-Impuls
                end
            end
            task.wait(0.03)
        end
    end)

    -- ====== AUTO CLICKER ======
    task.spawn(function()
        while scroll.Parent do
            if autoClickEnabled and autoCPS > 0 then
                clickOnce()
                task.wait(1 / math.clamp(autoCPS, 1, 50))
            else
                task.wait(0.08)
            end
        end
    end)

    -- ====== KNOCKBACK CONTROL ======
    local function hookChar(c)
        local hrp = c:WaitForChild("HumanoidRootPart", 6)
        if not hrp then return end
        local function onVel()
            if antiKBEnabled then
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                hrp.AssemblyAngularVelocity = Vector3.zero
            elseif reduceKBPercent > 0 then
                local f = 1 - (reduceKBPercent/100)
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X * f,
                    hrp.AssemblyLinearVelocity.Y,
                    hrp.AssemblyLinearVelocity.Z * f
                )
                hrp.AssemblyAngularVelocity *= f
            end
        end
        hrp:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(onVel)
        hrp:GetPropertyChangedSignal("AssemblyAngularVelocity"):Connect(onVel)
    end
    if player.Character then hookChar(player.Character) end
    player.CharacterAdded:Connect(hookChar)

    -- ====== Cleanup ======
    scroll.Destroying:Connect(function()
        if fovCircle then pcall(function() fovCircle.Visible = false fovCircle:Remove() end) end
        for plr, data in pairs(originalSizes) do
            if plr.Character then
                local h = plr.Character:FindFirstChild("Head")
                local r = plr.Character:FindFirstChild("HumanoidRootPart")
                if h and data.Head then h.Size = data.Head end
                if r and data.HRP  then r.Size = data.HRP  end
            end
        end
    end)

    return scroll
end
