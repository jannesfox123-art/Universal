return function(parent, settings)
    -- // Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local Vim = game:GetService("VirtualInputManager")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local UserGameSettings = UserSettings():GetService("UserGameSettings")

    -- // Connection manager (für sauberes Cleanup)
    local connections = {}
    local function bind(signal, fn)
        local c = signal:Connect(fn)
        table.insert(connections, c)
        return c
    end
    local function cleanup()
        for _, c in ipairs(connections) do
            pcall(function() c:Disconnect() end)
        end
    end

    -- // UI: ScrollingFrame (übernimmt Theme)
    local root = Instance.new("ScrollingFrame")
    root.Name = "CombatTab"
    root.Size = UDim2.new(1, 0, 1, 0)
    root.CanvasSize = UDim2.new(0, 0, 0, 1200)
    root.ScrollBarThickness = 6
    root.BackgroundTransparency = 1
    root.Parent = parent

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = root

    local function addSection(titleText)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.94, 0, 0, 28)
        title.BackgroundTransparency = 1
        title.Text = titleText
        title.Font = settings.Font
        title.TextSize = settings.TextSize + 2
        title.TextColor3 = settings.Theme.TabText
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = root
        return title
    end

    local function makeButtonBase(text)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.94, 0, 0, 40)
        btn.AutoButtonColor = false
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.Text = text
        btn.Parent = root
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        bind(btn.MouseEnter, function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = settings.Theme.TabButtonHover or settings.Theme.TabButton}):Play()
        end)
        bind(btn.MouseLeave, function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = settings.Theme.TabButton}):Play()
        end)
        return btn
    end

    local function makeToggle(label, default, callback)
        local btn = makeButtonBase(label .. ": " .. (default and "ON" or "OFF"))
        local state = default
        bind(btn.MouseButton1Click, function()
            state = not state
            btn.Text = label .. ": " .. (state and "ON" or "OFF")
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = state and (settings.Theme.TabButtonActive or settings.Theme.TabButton) or settings.Theme.TabButton
            }):Play()
            callback(state)
        end)
        -- init color
        if state then
            btn.BackgroundColor3 = settings.Theme.TabButtonActive or settings.Theme.TabButton
        end
        return function(newState)
            state = newState
            btn.Text = label .. ": " .. (state and "ON" or "OFF")
            callback(state)
        end
    end

    local function makeSlider(label, minV, maxV, defaultV, step, callback)
        step = step or 1
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(0.94, 0, 0, 62)
        holder.BackgroundTransparency = 1
        holder.Parent = root

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 0, 22)
        txt.BackgroundTransparency = 1
        txt.Font = settings.Font
        txt.TextSize = settings.TextSize
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.TextColor3 = settings.Theme.TabText
        txt.Text = ("%s: %s"):format(label, tostring(defaultV))
        txt.Parent = holder

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 18)
        bar.Position = UDim2.new(0, 0, 0, 30)
        bar.BackgroundColor3 = settings.Theme.TabButton
        bar.Parent = holder
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = bar

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = settings.Theme.TabButtonActive or settings.Theme.TabButton
        fill.Size = UDim2.new((defaultV-minV)/(maxV-minV), 0, 1, 0)
        fill.Parent = bar
        local fcorner = Instance.new("UICorner"); fcorner.CornerRadius = UDim.new(0, 8); fcorner.Parent = fill

        local dragging = false
        bind(bar.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        bind(UIS.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        local val = defaultV
        local function apply(v)
            val = math.clamp(v, minV, maxV)
            local ratio = (val - minV)/(maxV-minV)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            local show = (math.floor(val/step+0.5)*step)
            txt.Text = ("%s: %s"):format(label, tostring(show))
            callback(val)
        end

        bind(RunService.RenderStepped, function()
            if not dragging then return end
            local mX = UIS:GetMouseLocation().X
            local x0 = bar.AbsolutePosition.X
            local w = bar.AbsoluteSize.X
            local ratio = math.clamp((mX - x0)/w, 0, 1)
            local raw = minV + (maxV-minV)*ratio
            local snapped = math.floor(raw/step+0.5)*step
            apply(snapped)
        end)

        apply(defaultV)
        return apply
    end

    local function makeChooser(label, options, defaultIdx, onChange)
        local idx = defaultIdx
        local btn = makeButtonBase(label .. ": " .. options[idx])
        bind(btn.MouseButton1Click, function()
            idx = (idx % #options) + 1
            btn.Text = label .. ": " .. options[idx]
            onChange(options[idx], idx)
        end)
        -- init callback
        onChange(options[idx], idx)
        return function(newIdx)
            idx = math.clamp(newIdx, 1, #options)
            btn.Text = label .. ": " .. options[idx]
            onChange(options[idx], idx)
        end
    end

    ----------------------------------------------------------------
    -- Combat States & Helpers
    ----------------------------------------------------------------
    local AimbotEnabled = false
    local AimbotMode = "CFrame"         -- "CFrame" | "Mouse"
    local AimbotKey = Enum.UserInputType.MouseButton2
    local AimingHeld = false

    local AimbotFOV = 120
    local AimbotSmoothBase = 6          -- wird mit MouseSensitivity skaliert
    local AimbotPrediction = 0.10       -- Sekunden * Velocity

    local TriggerbotEnabled = false
    local TriggerDelayMS = 80

    local AutoClickEnabled = false
    local AutoClickCPS = 8

    local HitboxEnabled = false
    local HitboxSize = 5
    local HitboxOriginal = {} -- plr -> Vector3 size

    local ReachEnabled = false
    local ReachDistance = 18

    local AntiKBEnabled = false

    local function isAlive(plr)
        if not plr.Character then return false end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    local function screen2D(v3)
        local v2, on = Camera:WorldToViewportPoint(v3)
        return Vector2.new(v2.X, v2.Y), on
    end

    local function getClosestHeadInFOV()
        local mousePos = UIS:GetMouseLocation()
        local best, bestMag, bestHead = nil, math.huge, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and isAlive(plr) and plr.Character:FindChild("Head") then
                local head = plr.Character.Head
                local pos2D, on = screen2D(head.Position)
                if on then
                    local mag = (pos2D - mousePos).Magnitude
                    if mag < bestMag and mag <= AimbotFOV then
                        best, bestMag, bestHead = plr, mag, head
                    end
                end
            end
        end
        return best, bestHead
    end

    -- Sensitivity-aware smoothing (CFrame)
    local function smoothAimTo(targetPos, dt)
        local sens = UserGameSettings.MouseSensitivity
        local current = Camera.CFrame
        local target = CFrame.new(current.Position, targetPos)
        local alpha = math.clamp(dt * (AimbotSmoothBase * sens), 0, 1)
        Camera.CFrame = current:Lerp(target, alpha)
    end

    -- Maus-Aim per relativer Bewegung (mousemoverel bevorzugt; Fallback über kleine CFrame-Schritte)
    local hasMouseMoveRel = (typeof(mousemoverel) == "function")
    local function mouseAimToward(worldPos, dt)
        local mousePos = UIS:GetMouseLocation()
        local v2, on = screen2D(worldPos)
        if not on then return end
        local dx = (v2.X - mousePos.X)
        local dy = (v2.Y - mousePos.Y)
        -- Skaliere mit Sensitivität & Smooth
        local sens = UserGameSettings.MouseSensitivity
        local factor = math.clamp((AimbotSmoothBase * sens) * dt * 6, 0.05, 2.5)
        local moveX = dx * factor
        local moveY = dy * factor

        if hasMouseMoveRel then
            mousemoverel(moveX, moveY)
        else
            -- Fallback: Kamera sanft drehen (falls Executor keine Mausbewegung unterstützt)
            smoothAimTo(worldPos, dt)
        end
    end

    ----------------------------------------------------------------
    -- FOV Circle (Drawing API)
    ----------------------------------------------------------------
    local fovCircle
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Radius = AimbotFOV
        fovCircle.Thickness = 2
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Color = settings.Theme.Highlight or Color3.fromRGB(255,255,255)
    end)

    bind(RunService.RenderStepped, function()
        if fovCircle then
            if AimbotEnabled then
                fovCircle.Visible = true
                fovCircle.Radius = AimbotFOV
                fovCircle.Position = UIS:GetMouseLocation()
            else
                fovCircle.Visible = false
            end
        end
    end)

    ----------------------------------------------------------------
    -- INPUT: Aimbot Key (umschaltbar RMB/LMB)
    ----------------------------------------------------------------
    bind(UIS.InputBegan, function(input, gp)
        if gp then return end
        if input.UserInputType == AimbotKey then
            AimingHeld = true
        end
    end)
    bind(UIS.InputEnded, function(input)
        if input.UserInputType == AimbotKey then
            AimingHeld = false
        end
    end)

    ----------------------------------------------------------------
    -- CORE LOOPS
    ----------------------------------------------------------------
    -- Aimbot Loop
    bind(RunService.RenderStepped, function(dt)
        if not (AimbotEnabled and AimingHeld) then return end
        local plr, head = getClosestHeadInFOV()
        if not head then return end
        local targetPos = head.Position + (head.Velocity * AimbotPrediction)
        if AimbotMode == "CFrame" then
            smoothAimTo(targetPos, dt)
        else -- "Mouse"
            mouseAimToward(targetPos, dt)
        end
    end)

    -- Triggerbot Loop
    local lastTrigger = 0
    bind(RunService.RenderStepped, function()
        if not (TriggerbotEnabled and AimingHeld) then return end
        local now = tick()
        if (now - lastTrigger) * 1000 < TriggerDelayMS then return end
        local m = UIS:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(m.X, m.Y)
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 10000)
        if hit and hit.Instance then
            local model = hit.Instance:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChildOfClass("Humanoid") and model ~= LocalPlayer.Character then
                Vim:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
                Vim:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0)
                lastTrigger = now
            end
        end
    end)

    -- Auto Clicker Loop (CPS)
    local clickAccumulator = 0
    bind(RunService.RenderStepped, function(dt)
        if not AutoClickEnabled then return end
        local cps = math.clamp(AutoClickCPS, 1, 30)
        clickAccumulator = clickAccumulator + dt
        local interval = 1 / cps
        while clickAccumulator >= interval do
            clickAccumulator = clickAccumulator - interval
            local m = UIS:GetMouseLocation()
            Vim:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
            Vim:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0)
        end
    end)

    -- Anti-Knockback (dämpft horizontale Velocity & blockt Ragdoll/FallingDown)
    local function applyAntiKB()
        local char = LocalPlayer.Character
        if not (char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid")) then return end
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        end)
    end
    bind(RunService.Heartbeat, function()
        if AntiKBEnabled then applyAntiKB() end
    end)

    -- Hitbox Expander
    local function applyHitbox(plr)
        if not (plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")) then return end
        local hrp = plr.Character.HumanoidRootPart
        if not HitboxOriginal[plr] then
            HitboxOriginal[plr] = hrp.Size
        end
        pcall(function()
            hrp.CanCollide = false
            hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
            hrp.Transparency = 0.7
        end)
    end
    local function revertHitbox(plr)
        if not (plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")) then return end
        local hrp = plr.Character.HumanoidRootPart
        local orig = HitboxOriginal[plr] or Vector3.new(2,2,1)
        pcall(function()
            hrp.Transparency = 1
            hrp.Size = orig
            hrp.CanCollide = false
        end)
        HitboxOriginal[plr] = nil
    end
    local function refreshHitboxes()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if HitboxEnabled then applyHitbox(plr) else revertHitbox(plr) end
            end
        end
    end
    bind(Players.PlayerAdded, function(plr)
        if HitboxEnabled then
            bind(plr.CharacterAdded, function()
                task.wait(0.2)
                applyHitbox(plr)
            end)
        end
    end)

    -- Reach (Tool Handle vergrößern)
    local function applyReach()
        if not ReachEnabled then return end
        local char = LocalPlayer.Character
        if not (char and char:FindFirstChildOfClass("Tool")) then return end
        local tool = char:FindFirstChildOfClass("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            pcall(function()
                handle.Size = Vector3.new(ReachDistance/3, handle.Size.Y, ReachDistance/3)
                handle.Massless = true
                handle.CanCollide = false
                handle.Transparency = 0.5
            end)
        end
    end
    bind(RunService.RenderStepped, function()
        if ReachEnabled then applyReach() end
    end)

    ----------------------------------------------------------------
    -- UI Controls
    ----------------------------------------------------------------
    addSection("Aimbot")

    makeToggle("Aimbot", false, function(b) AimbotEnabled = b end)

    makeChooser("Aimbot Mode", {"CFrame","Mouse"}, 1, function(opt)
        AimbotMode = opt
    end)

    makeChooser("Aimbot Key", {"Right Mouse","Left Mouse"}, 1, function(opt, idx)
        -- Disconnect alte Held-States sauber
        AimingHeld = false
        AimbotKey = (idx == 1) and Enum.UserInputType.MouseButton2 or Enum.UserInputType.MouseButton1
    end)

    makeSlider("FOV", 30, 300, AimbotFOV, 1, function(v) AimbotFOV = v end)

    makeSlider("Smooth (Base)", 1, 20, AimbotSmoothBase, 1, function(v) AimbotSmoothBase = v end)

    makeSlider("Prediction (x100)", 0, 300, math.floor(AimbotPrediction*100), 1, function(v)
        AimbotPrediction = v/100
    end)

    addSection("Triggerbot")
    makeToggle("Triggerbot", false, function(b) TriggerbotEnabled = b end)
    makeSlider("Delay (ms)", 0, 400, TriggerDelayMS, 5, function(v) TriggerDelayMS = v end)

    addSection("Auto Clicker & Reach")
    makeToggle("Auto Clicker", false, function(b) AutoClickEnabled = b end)
    makeSlider("AutoClick CPS", 1, 30, AutoClickCPS, 1, function(v) AutoClickCPS = v end)

    makeToggle("Reach", false, function(b) ReachEnabled = b end)
    makeSlider("Reach Distance", 10, 30, ReachDistance, 1, function(v) ReachDistance = v end)

    addSection("Hitbox & Anti-Knockback")
    makeToggle("Hitbox Expander", false, function(b)
        HitboxEnabled = b
        refreshHitboxes()
    end)
    makeSlider("Hitbox Size", 2, 12, HitboxSize, 1, function(v)
        HitboxSize = v
        if HitboxEnabled then refreshHitboxes() end
    end)
    makeToggle("Anti-Knockback", false, function(b) AntiKBEnabled = b end)

    ----------------------------------------------------------------
    -- Lifecycle & Cleanup
    ----------------------------------------------------------------
    bind(root.AncestryChanged, function(_, parentNow)
        if parentNow == nil then
            cleanup()
            -- FOV Circle entfernen
            pcall(function() if fovCircle then fovCircle.Visible = false; fovCircle:Remove() end end)
            -- Hitboxes zurücksetzen
            for plr, _ in pairs(HitboxOriginal) do
                pcall(function() revertHitbox(plr) end)
            end
        end
    end)

    return root
end
