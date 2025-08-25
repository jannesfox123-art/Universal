-- Tab2.lua (Combat) – Reworked, focuses on reliable Silent Aim + Aimbot, mutual exclusion, FOV, Triggerbot, etc.
-- Drop this file at: Universal/Tab2.lua and load via your Main (loadstring(... )()(contentFrame, settings))

return function(parent, settings)
    ----------------------------------------------------------------
    -- Services / Locals
    ----------------------------------------------------------------
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local VIM = game:GetService("VirtualInputManager")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local UserGameSettings = UserSettings():GetService("UserGameSettings")

    -- executor feature detection
    local HAS_MOUSE_REL = typeof(mousemoverel) == "function"
    local HAS_HOOK = typeof(hookmetamethod) == "function"
    local HAS_GETNAMECALL = typeof(getnamecallmethod) == "function"
    local HAS_SETREADONLY = typeof(setreadonly) == "function" and typeof(getrawmetatable) == "function"

    ----------------------------------------------------------------
    -- Connections / Cleanup
    ----------------------------------------------------------------
    local conns = {}
    local function bind(sig, fn)
        local c = sig:Connect(fn)
        table.insert(conns, c)
        return c
    end
    local usedMtFallback = false
    local mt, oldIndex, oldNamecall

    local function cleanup()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        if fovCircle then pcall(function() fovCircle.Visible = false fovCircle:Remove() end) end
        if usedMtFallback and mt then
            pcall(function()
                setreadonly(mt, false)
                if oldIndex then mt.__index = oldIndex end
                if oldNamecall then mt.__namecall = oldNamecall end
                setreadonly(mt, true)
            end)
        end
    end

    ----------------------------------------------------------------
    -- UI Root (scrollable)
    ----------------------------------------------------------------
    local root = Instance.new("ScrollingFrame")
    root.Name = "CombatTab"
    root.Size = UDim2.new(1, 0, 1, 0)
    root.CanvasSize = UDim2.new(0, 0, 0, 1100)
    root.ScrollBarThickness = 6
    root.BackgroundTransparency = 1
    root.Parent = parent

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = root

    local function section(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.94, 0, 0, 26)
        lbl.BackgroundTransparency = 1
        lbl.Font = settings.Font
        lbl.TextSize = settings.TextSize + 2
        lbl.TextColor3 = settings.Theme.TabText
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.Parent = root
        return lbl
    end

    local function baseButton(txt)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.94, 0, 0, 40)
        b.BackgroundColor3 = settings.Theme.TabButton
        b.AutoButtonColor = false
        b.Text = txt
        b.Font = settings.Font
        b.TextSize = settings.TextSize
        b.TextColor3 = settings.Theme.TabText
        b.Parent = root
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
        bind(b.MouseEnter, function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = settings.Theme.TabButtonHover or settings.Theme.TabButton}):Play()
        end)
        bind(b.MouseLeave, function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = settings.Theme.TabButton}):Play()
        end)
        return b
    end

    local function makeToggle(label, default, cb)
        local btn = baseButton(("%s: %s"):format(label, default and "ON" or "OFF"))
        if default then btn.BackgroundColor3 = settings.Theme.TabButtonActive or settings.Theme.TabButton end
        local state = default
        bind(btn.MouseButton1Click, function()
            state = not state
            btn.Text = ("%s: %s"):format(label, state and "ON" or "OFF")
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = state and (settings.Theme.TabButtonActive or settings.Theme.TabButton) or settings.Theme.TabButton
            }):Play()
            cb(state)
        end)
        return function(v)
            state = v
            btn.Text = ("%s: %s"):format(label, state and "ON" or "OFF")
            cb(state)
        end
    end

    local function makeSlider(label, minV, maxV, defaultV, step, onChange)
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
        txt.TextColor3 = settings.Theme.TabText
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.Text = ("%s: %s"):format(label, tostring(defaultV))
        txt.Parent = holder

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 18)
        bar.Position = UDim2.new(0, 0, 0, 30)
        bar.BackgroundColor3 = settings.Theme.TabButton
        bar.Parent = holder
        local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0,8); c1.Parent = bar

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = settings.Theme.TabButtonActive or settings.Theme.TabButton
        fill.Size = UDim2.new((defaultV-minV)/(maxV-minV), 0, 1, 0)
        fill.Parent = bar
        local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,8); c2.Parent = fill

        local dragging = false
        bind(bar.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
        bind(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

        local function apply(v)
            v = math.clamp(v, minV, maxV)
            local ratio = (v - minV)/(maxV-minV)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            local shown = math.floor(v/step + 0.5)*step
            txt.Text = ("%s: %s"):format(label, tostring(shown))
            onChange(v)
        end

        bind(RunService.RenderStepped, function()
            if not dragging then return end
            local mx = UIS:GetMouseLocation().X
            local x0, w = bar.AbsolutePosition.X, bar.AbsoluteSize.X
            local r = math.clamp((mx - x0)/w, 0, 1)
            local raw = minV + (maxV - minV) * r
            local snapped = math.floor(raw/step + 0.5)*step
            apply(snapped)
        end)

        apply(defaultV)
        return apply
    end

    local function makeChooser(label, options, defaultIdx, onChange)
        local idx = defaultIdx
        local btn = baseButton(label .. ": " .. options[idx])
        bind(btn.MouseButton1Click, function()
            idx = (idx % #options) + 1
            btn.Text = label .. ": " .. options[idx]
            onChange(options[idx], idx)
        end)
        onChange(options[idx], idx)
        return function(newIdx)
            idx = math.clamp(newIdx, 1, #options)
            btn.Text = label .. ": " .. options[idx]
            onChange(options[idx], idx)
        end
    end

    ----------------------------------------------------------------
    -- State
    ----------------------------------------------------------------
    local AimbotEnabled = false
    local SilentAimEnabled = false
    local SilentHitMode = "Head"          -- "Head"|"Random"
    local AimbotMode = "CFrame"           -- "CFrame"|"Mouse"
    local AimbotKey = Enum.UserInputType.MouseButton2
    local AimingHeld = false

    local AimbotFOV = 120
    local AimbotSmooth = 50               -- 0=instant lock, 100=very slow
    local AimbotPrediction = 0.15         -- seconds

    local TriggerbotEnabled = false
    local TriggerDelayMS = 120

    local AutoClickEnabled = false
    local AutoClickCPS = 8

    local HitboxEnabled = false
    local HitboxSize = 5
    local HitboxOriginal = {}

    local ReachEnabled = false
    local ReachDistance = 18

    local AntiKBEnabled = false

    ----------------------------------------------------------------
    -- Targeting Helpers
    ----------------------------------------------------------------
    local function isAlive(plr)
        local char = plr.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    local function screen2D(v3)
        local v2, on = Camera:WorldToViewportPoint(v3)
        return Vector2.new(v2.X, v2.Y), on
    end

    local function getClosestInFOV()
        local mouse = UIS:GetMouseLocation()
        local bestPlr, bestPart, bestMag = nil, nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and isAlive(plr) and plr.Character then
                local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                if head then
                    local p2, on = screen2D(head.Position)
                    if on then
                        local mag = (p2 - mouse).Magnitude
                        if mag < bestMag and mag <= AimbotFOV then
                            bestPlr, bestPart, bestMag = plr, head, mag
                        end
                    end
                end
            end
        end
        return bestPlr, bestPart
    end

    local function pickSilentPart(char)
        if SilentHitMode == "Head" then
            return char:FindFirstChild("Head") or char:FindChild("HumanoidRootPart")
        end
        local pool = {}
        for _, n in ipairs({"Head","UpperTorso","LowerTorso","HumanoidRootPart","Torso"}) do
            if char:FindFirstChild(n) then table.insert(pool, char[n]) end
        end
        if #pool == 0 then return char:FindFirstChild("HumanoidRootPart") end
        return pool[math.random(1, #pool)]
    end

    ----------------------------------------------------------------
    -- Aim Implementations
    ----------------------------------------------------------------
    local function cframeAim(targetPos)
        local cur = Camera.CFrame
        local dst = CFrame.new(cur.Position, targetPos)
        if AimbotSmooth <= 0 then
            Camera.CFrame = dst
        else
            local alpha = math.clamp((100 - AimbotSmooth)/100, 0.01, 1)
            Camera.CFrame = cur:Lerp(dst, alpha)
        end
    end

    local function mouseAim(targetPos)
        local mpos = UIS:GetMouseLocation()
        local v2, on = screen2D(targetPos)
        if not on then return end
        local dx, dy = v2.X - mpos.X, v2.Y - mpos.Y
        if AimbotSmooth <= 0 then
            if HAS_MOUSE_REL then mousemoverel(dx, dy) else Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos) end
            return
        end
        local sens = UserGameSettings.MouseSensitivity
        local factor = math.clamp((100 - AimbotSmooth)/100, 0.01, 1)
        local moveX = dx * factor * math.max(sens, 0.1) * 0.9
        local moveY = dy * factor * math.max(sens, 0.1) * 0.9
        if HAS_MOUSE_REL then mousemoverel(moveX, moveY) else cframeAim(targetPos) end
    end

    ----------------------------------------------------------------
    -- FOV Circle
    ----------------------------------------------------------------
    local fovCircle
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Visible = false
        fovCircle.Radius = AimbotFOV
        fovCircle.Thickness = 2
        fovCircle.Filled = false
        fovCircle.NumSides = 64
        fovCircle.Color = settings.Theme.Highlight or Color3.fromRGB(255,255,255)
    end)
    bind(RunService.RenderStepped, function()
        if not fovCircle then return end
        local show = (AimbotEnabled or SilentAimEnabled)
        fovCircle.Visible = show
        if show then
            fovCircle.Radius = AimbotFOV
            fovCircle.Position = UIS:GetMouseLocation()
        end
    end)

    ----------------------------------------------------------------
    -- Input: hold to aim
    ----------------------------------------------------------------
    bind(UIS.InputBegan, function(i, gp)
        if gp then return end
        if i.UserInputType == AimbotKey then AimingHeld = true end
    end)
    bind(UIS.InputEnded, function(i)
        if i.UserInputType == AimbotKey then AimingHeld = false end
    end)

    ----------------------------------------------------------------
    -- Silent Aim Hooks (robust, reworked)
    ----------------------------------------------------------------
    local function getSilentCF()
        if not (SilentAimEnabled and AimingHeld) then return nil end
        local plr, _ = getClosestInFOV()
        if not (plr and plr.Character) then return nil end
        local part = pickSilentPart(plr.Character)
        if not part then return nil end
        local predict = part.Position + (part.Velocity * AimbotPrediction)
        return CFrame.new(predict), part
    end

    if HAS_HOOK and HAS_GETNAMECALL then
        local origNamecall
        origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if SilentAimEnabled and AimingHeld then
                if typeof(self) == "Instance" and (self == workspace or self:IsDescendantOf(workspace)) then
                    if method == "Raycast" then
                        local args = {...}
                        local origin, direction = args[1], args[2]
                        local cf = getSilentCF()
                        if cf then
                            local mag = direction.Magnitude
                            args[2] = (cf.Position - origin).Unit * mag
                            return origNamecall(self, unpack(args))
                        end
                    elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                        local args = {...}
                        local R = args[1]
                        if typeof(R) == "Ray" then
                            local cf = getSilentCF()
                            if cf then
                                args[1] = Ray.new(R.Origin, (cf.Position - R.Origin).Unit * R.Direction.Magnitude)
                                return origNamecall(self, unpack(args))
                            end
                        end
                    end
                end
            end
            return origNamecall(self, ...)
        end)

        local origIndex
        origIndex = hookmetamethod(game, "__index", function(t, k)
            if SilentAimEnabled and AimingHeld and (k == "Hit" or k == "Target") then
                local cf, part = getSilentCF()
                if cf and part then
                    if k == "Hit" then return cf end
                    if k == "Target" then return part end
                end
            end
            return origIndex(t, k)
        end)
    elseif HAS_SETREADONLY then
        mt = getrawmetatable(game)
        if mt then
            setreadonly(mt, false)
            oldIndex = mt.__index
            oldNamecall = mt.__namecall
            mt.__namecall = function(self, ...)
                local method = (HAS_GETNAMECALL and getnamecallmethod()) or ""
                if SilentAimEnabled and AimingHeld then
                    if typeof(self) == "Instance" and (self == workspace or self:IsDescendantOf(workspace)) then
                        if method == "Raycast" then
                            local args = {...}
                            local origin, direction = args[1], args[2]
                            local cf = getSilentCF()
                            if cf then
                                args[2] = (cf.Position - origin).Unit * direction.Magnitude
                                return oldNamecall(self, unpack(args))
                            end
                        elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                            local args = {...}
                            local R = args[1]
                            if typeof(R) == "Ray" then
                                local cf = getSilentCF()
                                if cf then
                                    args[1] = Ray.new(R.Origin, (cf.Position - R.Origin).Unit * R.Direction.Magnitude)
                                    return oldNamecall(self, unpack(args))
                                end
                            end
                        end
                    end
                end
                return oldNamecall(self, ...)
            end
            mt.__index = function(t, k)
                if SilentAimEnabled and AimingHeld and (k == "Hit" or k == "Target") then
                    local cf, part = getSilentCF()
                    if cf and part then
                        if k == "Hit" then return cf end
                        if k == "Target" then return part end
                    end
                end
                return oldIndex(t, k)
            end
            setreadonly(mt, true)
            usedMtFallback = true
        else
            warn("[Combat] Silent Aim: kein metatable Zugriff (Executor).")
        end
    else
        warn("[Combat] Silent Aim: dein Executor unterstützt keine Hooks (hookmetamethod / setreadonly).")
    end

    ----------------------------------------------------------------
    -- CORE Loops
    ----------------------------------------------------------------
    -- Aimbot (CFrame / Mouse)
    bind(RunService.RenderStepped, function()
        if not (AimbotEnabled and AimingHeld) then return end
        local plr, head = getClosestInFOV()
        if not head then return end
        local pos = head.Position + (head.Velocity * AimbotPrediction)
        if AimbotMode == "CFrame" then
            cframeAim(pos)
        else
            mouseAim(pos)
        end
    end)

    -- Triggerbot
    local lastTrig = 0
    bind(RunService.RenderStepped, function()
        if not (TriggerbotEnabled and AimingHeld) then return end
        local now = time()
        if (now - lastTrig)*1000 < TriggerDelayMS then return end
        local m = UIS:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(m.X, m.Y)
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 10000)
        if hit and hit.Instance then
            local mdl = hit.Instance:FindFirstAncestorOfClass("Model")
            if mdl and mdl ~= LocalPlayer.Character and mdl:FindFirstChildOfClass("Humanoid") then
                VIM:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
                VIM:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0)
                lastTrig = now
            end
        end
    end)

    -- Auto Clicker
    local clickAcc = 0
    bind(RunService.RenderStepped, function(dt)
        if not AutoClickEnabled then return end
        local cps = math.clamp(AutoClickCPS, 1, 30)
        clickAcc += dt
        local step = 1/cps
        while clickAcc >= step do
            clickAcc -= step
            local m = UIS:GetMouseLocation()
            VIM:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
            VIM:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0)
        end
    end)

    -- Anti Knockback (basic)
    local function applyAntiKB()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum) then return end
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
        if plr == LocalPlayer then return end
        local char = plr.Character
        if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
        local hrp = char.HumanoidRootPart
        if not HitboxOriginal[plr] then HitboxOriginal[plr] = hrp.Size end
        pcall(function()
            hrp.CanCollide = false
            hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
        end)
    end
    local function revertHitbox(plr)
        local char = plr.Character
        if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
        local hrp = char.HumanoidRootPart
        local orig = HitboxOriginal[plr] or Vector3.new(2,2,1)
        pcall(function()
            hrp.Size = orig
            hrp.CanCollide = false
        end)
        HitboxOriginal[plr] = nil
    end
    local function refreshHitboxes()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if HitboxEnabled then applyHitbox(p) else revertHitbox(p) end
            end
        end
    end
    bind(Players.PlayerAdded, function(p)
        if HitboxEnabled then
            bind(p.CharacterAdded, function()
                task.wait(0.25)
                applyHitbox(p)
            end)
        end
    end)

    -- Reach (simple tool handle scaling)
    local function applyReach()
        if not ReachEnabled then return end
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
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
    section("Aimbot & Silent Aim")

    local setAimbot, setSilent

    setAimbot = makeToggle("Aimbot", false, function(v)
        AimbotEnabled = v
        if v then
            SilentAimEnabled = false
            if setSilent then setSilent(false) end
        end
    end)

    setSilent = makeToggle("Silent Aim", false, function(v)
        SilentAimEnabled = v
        if v then
            AimbotEnabled = false
            if setAimbot then setAimbot(false) end
        end
    end)

    makeChooser("Silent Target", {"Head","Random"}, 1, function(opt) SilentHitMode = opt end)
    makeChooser("Aimbot Mode", {"CFrame","Mouse"}, 1, function(opt) AimbotMode = opt end)
    makeChooser("Aimbot Key", {"Right Mouse","Left Mouse"}, 1, function(_, idx)
        AimingHeld = false
        AimbotKey = (idx == 1) and Enum.UserInputType.MouseButton2 or Enum.UserInputType.MouseButton1
    end)

    makeSlider("FOV", 30, 300, AimbotFOV, 1, function(v) AimbotFOV = v end)
    makeSlider("Smooth", 0, 100, AimbotSmooth, 1, function(v) AimbotSmooth = v end)
    makeSlider("Prediction (ms)", 0, 300, math.floor(AimbotPrediction*1000), 5, function(v) AimbotPrediction = v/1000 end)

    section("Triggerbot")
    makeToggle("Triggerbot", false, function(v) TriggerbotEnabled = v end)
    makeSlider("Trigger Delay (ms)", 0, 400, TriggerDelayMS, 5, function(v) TriggerDelayMS = v end)

    section("Auto Clicker & Reach")
    makeToggle("Auto Clicker", false, function(v) AutoClickEnabled = v end)
    makeSlider("AutoClick CPS", 1, 30, AutoClickCPS, 1, function(v) AutoClickCPS = v end)
    makeToggle("Reach", false, function(v) ReachEnabled = v end)
    makeSlider("Reach Distance", 10, 30, ReachDistance, 1, function(v) ReachDistance = v end)

    section("Hitbox & Anti-Knockback")
    makeToggle("Hitbox Expander", false, function(v)
        HitboxEnabled = v
        refreshHitboxes()
    end)
    makeSlider("Hitbox Size", 2, 12, HitboxSize, 1, function(v)
        HitboxSize = v
        if HitboxEnabled then refreshHitboxes() end
    end)
    makeToggle("Anti-Knockback", false, function(v) AntiKBEnabled = v end)

    ----------------------------------------------------------------
    -- Cleanup with tab removal
    ----------------------------------------------------------------
    bind(root.AncestryChanged, function(_, p)
        if p == nil then cleanup() end
    end)

    return root
end
