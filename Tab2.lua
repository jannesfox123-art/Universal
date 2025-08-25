return function(parent, settings)
    --// Services & Locals
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local Vim = game:GetService("VirtualInputManager")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local UserGameSettings = UserSettings():GetService("UserGameSettings")

    --// Connection Manager (alles sauber trennen beim Destroy)
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

    --// UI: ScrollingFrame
    local root = Instance.new("ScrollingFrame")
    root.Name = "CombatTab"
    root.Size = UDim2.new(1, 0, 1, 0)
    root.CanvasSize = UDim2.new(0, 0, 0, 1100)
    root.ScrollBarThickness = 6
    root.BackgroundTransparency = 1
    root.Parent = parent

    local list = Instance.new("UIListLayout")
    list.Parent = root
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    local function addSection(titleText)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.92, 0, 0, 28)
        title.BackgroundTransparency = 1
        title.Text = titleText
        title.Font = settings.Font
        title.TextSize = settings.TextSize + 2
        title.TextColor3 = settings.Theme.TabText
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = root
        return title
    end

    local function makeToggle(label, default, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.92, 0, 0, 40)
        btn.AutoButtonColor = false
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.Text = label .. ": " .. (default and "ON" or "OFF")
        btn.Parent = root

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local state = default
        bind(btn.MouseEnter, function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = settings.Theme.TabButtonHover or settings.Theme.TabButton}):Play()
        end)
        bind(btn.MouseLeave, function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = settings.Theme.TabButton}):Play()
        end)
        bind(btn.MouseButton1Click, function()
            state = not state
            btn.Text = label .. ": " .. (state and "ON" or "OFF")
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = state and (settings.Theme.TabButtonActive or settings.Theme.TabButton) or settings.Theme.TabButton
            }):Play()
            callback(state)
        end)
        return function(newState)
            state = newState
            btn.Text = label .. ": " .. (state and "ON" or "OFF")
            callback(state)
        end
    end

    local function makeSlider(label, minV, maxV, defaultV, callback)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(0.92, 0, 0, 56)
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
        bind(RunService.RenderStepped, function()
            if not dragging then return end
            local mX = UIS:GetMouseLocation().X
            local x0 = bar.AbsolutePosition.X
            local w = bar.AbsoluteSize.X
            local ratio = math.clamp((mX - x0)/w, 0, 1)
            val = math.floor(minV + (maxV-minV)*ratio + 0.5)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            txt.Text = ("%s: %s"):format(label, tostring(val))
            callback(val)
        end)

        -- init callback
        callback(defaultV)
        return function(newVal)
            local ratio = math.clamp((newVal-minV)/(maxV-minV), 0, 1)
            val = newVal
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            txt.Text = ("%s: %s"):format(label, tostring(val))
            callback(val)
        end
    end

    ----------------------------------------------------------------
    -- Combat Settings (States)
    ----------------------------------------------------------------
    local AimbotEnabled = false
    local AimbotFOV = 120
    local AimbotPrediction = 0.10 -- seconds factor (0..3 via slider/100)
    local AimbotSmooth = 6        -- base smooth, scaled by MouseSensitivity
    local AimbotKey = Enum.UserInputType.MouseButton2
    local AimingHeld = false

    local TriggerbotEnabled = false
    local TriggerDelayMS = 80

    local AutoClickEnabled = false
    local AutoClickCPS = 8

    local HitboxEnabled = false
    local HitboxSize = 5
    local HitboxTargets = {} -- track applied chars

    local ReachEnabled = false
    local ReachDistance = 18

    local AntiKBEnabled = false

    ----------------------------------------------------------------
    -- Helpers
    ----------------------------------------------------------------
    local function screenPos(v3)
        local v2, on = Camera:WorldToViewportPoint(v3)
        return Vector2.new(v2.X, v2.Y), on
    end

    local function getClosestHeadInFOV()
        local mousePos = UIS:GetMouseLocation()
        local best, bestMag, bestPart = nil, math.huge, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                local head = plr.Character.Head
                local v2, on = screenPos(head.Position)
                if on then
                    local mag = (v2 - mousePos).Magnitude
                    if mag < bestMag and mag <= AimbotFOV then
                        best, bestMag, bestPart = plr, mag, head
                    end
                end
            end
        end
        return best, bestPart
    end

    local function smoothAimTo(targetPos, dt)
        -- Sensitivity-aware smoothing
        local sens = UserGameSettings.MouseSensitivity
        local current = Camera.CFrame
        local target = CFrame.new(current.Position, targetPos)
        local alpha = math.clamp(dt * (AimbotSmooth * sens), 0, 1)
        Camera.CFrame = current:Lerp(target, alpha)
    end

    ----------------------------------------------------------------
    -- FOV Circle (Drawing API; falls nicht vorhanden -> ignorieren)
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
    -- INPUT: Aimbot Key (RMB hold)
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
        local predicted = head.Position + (head.Velocity * AimbotPrediction)
        smoothAimTo(predicted, dt)
    end)

    -- Triggerbot Loop (ray vom Bildschirmzentrum/Maus)
    local lastTrigger = 0
    bind(RunService.RenderStepped, function()
        if not (TriggerbotEnabled and AimingHeld) then return end
        local now = time()
        if (now - lastTrigger) * 1000 < TriggerDelayMS then return end

        local mousePos = UIS:GetMouseLocation()
        local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 10000)

        if rayResult and rayResult.Instance then
            local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChildOfClass("Humanoid") and model ~= LocalPlayer.Character then
                -- Klick simulieren (VirtualInputManager)
                Vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                Vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                lastTrigger = now
            end
        end
    end)

    -- Auto Clicker Loop
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

    -- Anti-Knockback Loop (reduziert horizontale Velocity & disabled Knockback States)
    local function applyAntiKB()
        local char = LocalPlayer.Character
        if not (char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid")) then return end
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        -- leichte Dämpfung horizontal (behält Y für Sprünge)
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
        -- unterdrücke ausgewählte Humanoid States
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        end)
    end

    bind(RunService.Heartbeat, function()
        if AntiKBEnabled then applyAntiKB() end
    end)

    -- Hitbox Expander (apply/remove)
    local function applyHitbox(plr)
        if not (plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")) then return end
        local hrp = plr.Character.HumanoidRootPart
        if not HitboxTargets[plr] then
            HitboxTargets[plr] = hrp.Size
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
        local orig = HitboxTargets[plr]
        pcall(function()
            hrp.Transparency = 1
            hrp.Size = orig or Vector3.new(2, 2, 1)
            hrp.CanCollide = false
        end)
        HitboxTargets[plr] = nil
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

    -- Reach (Tool Handle größer & Raycast Reichweite)
    local function applyReach()
        if not ReachEnabled then return end
        local char = LocalPlayer.Character
        if not (char and char:FindFirstChildOfClass("Tool")) then return end
        local tool = char:FindFirstChildOfClass("Tool")
        local handle = tool:FindFirstChild("Handle")
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
    -- UI CONTROLS
    ----------------------------------------------------------------
    addSection("Aimbot")

    makeToggle("Aimbot", false, function(b) AimbotEnabled = b end)

    makeSlider("FOV", 30, 300, AimbotFOV, function(v) AimbotFOV = v end)

    makeSlider("Smooth (base)", 1, 20, AimbotSmooth, function(v) AimbotSmooth = v end)

    makeSlider("Prediction (x100)", 0, 300, math.floor(AimbotPrediction*100), function(v)
        AimbotPrediction = v/100
    end)

    addSection("Triggerbot")
    makeToggle("Triggerbot", false, function(b) TriggerbotEnabled = b end)
    makeSlider("Delay (ms)", 0, 400, TriggerDelayMS, function(v) TriggerDelayMS = v end)

    addSection("Click/Reach")
    makeToggle("Auto Clicker", false, function(b) AutoClickEnabled = b end)
    makeSlider("AutoClick CPS", 1, 30, AutoClickCPS, function(v) AutoClickCPS = v end)

    makeToggle("Reach", false, function(b)
        ReachEnabled = b
    end)
    makeSlider("Reach Distance", 10, 30, ReachDistance, function(v) ReachDistance = v end)

    addSection("Hitbox & Knockback")
    makeToggle("Hitbox Expander", false, function(b)
        HitboxEnabled = b
        refreshHitboxes()
    end)
    makeSlider("Hitbox Size", 2, 12, HitboxSize, function(v)
        HitboxSize = v
        if HitboxEnabled then refreshHitboxes() end
    end)

    makeToggle("Anti-Knockback", false, function(b)
        AntiKBEnabled = b
    end)

    ----------------------------------------------------------------
    -- Tab Lifecycle: wenn der Tab zerstört wird, alles trennen & zurücksetzen
    ----------------------------------------------------------------
    bind(root.AncestryChanged, function(_, parentNow)
        if parentNow == nil then
            cleanup()
            -- FOV Circle löschen
            pcall(function() if fovCircle then fovCircle.Visible = false; fovCircle:Remove() end end)
            -- Hitboxes resetten
            for plr, _ in pairs(HitboxTargets) do
                pcall(function() revertHitbox(plr) end)
            end
        end
    end)

    return root
end
