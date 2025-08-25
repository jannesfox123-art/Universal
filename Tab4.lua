-- Tab4.lua — VISUALS (vollständig, stabil, Tab1-Style)
-- Rückgabe: Frame (Tab-Container), kompatibel mit deinem Main-Script

return function(parent, settings)
    local Players        = game:GetService("Players")
    local RunService     = game:GetService("RunService")
    local TweenService   = game:GetService("TweenService")
    local Lighting       = game:GetService("Lighting")
    local LocalPlayer    = Players.LocalPlayer
    local Camera         = workspace.CurrentCamera

    ----------------------------------------------------------------
    -- UI: Tab-Container + Scrollbereich
    ----------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = parent

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1
    scroll.Parent = frame

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll

    local function autoCanvas()
        task.defer(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(list.AbsoluteContentSize.Y + 20, scroll.AbsoluteSize.Y))
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvas)

    ----------------------------------------------------------------
    -- UI: Sections + breite Toggle-Buttons (Tab1-Style)
    ----------------------------------------------------------------
    local CONTROL_WIDTH = settings.ControlWidth or 420  -- breit wie in Tab1/Screenshot
    local CONTROL_HEIGHT = 44

    local function makeSection(title)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, CONTROL_WIDTH, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = settings.Font
        lbl.TextSize = settings.TextSize
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = scroll
        return lbl
    end

    local function makeToggle(labelText, default, onToggle)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, CONTROL_WIDTH, 0, CONTROL_HEIGHT)
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Text = string.format("%s", labelText)
        btn.AutoButtonColor = false
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = scroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn

        -- ON/OFF-Pill rechts
        local pill = Instance.new("Frame")
        pill.AnchorPoint = Vector2.new(1, 0.5)
        pill.Position = UDim2.new(1, -10, 0.5, 0)
        pill.Size = UDim2.new(0, 56, 0, 26)
        pill.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
        pill.BorderSizePixel = 0
        pill.Parent = btn

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(1, 0)
        pillCorner.Parent = pill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 24, 0, 24)
        knob.Position = UDim2.new(0, 1, 0, 1)
        knob.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        knob.BorderSizePixel = 0
        knob.Parent = pill

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local enabled = default or false
        local function applyVisual()
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
            TweenService:Create(pill, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(65, 65, 65)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.12), {
                Position = enabled and UDim2.new(1, -25, 0, 1) or UDim2.new(0, 1, 0, 1),
                BackgroundColor3 = enabled and Color3.fromRGB(230, 255, 240) or Color3.fromRGB(180, 180, 180)
            }):Play()
        end

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButtonHover
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            applyVisual()
            if onToggle then task.spawn(function() onToggle(enabled) end) end
        end)

        -- init
        applyVisual()
        return btn, function(state) enabled = state; applyVisual(); if onToggle then onToggle(enabled) end end
    end

    ----------------------------------------------------------------
    -- VISUALS: State + Runtimes
    ----------------------------------------------------------------
    local State = {
        TeamCheck   = false,
        NameESP     = false,
        BoxESP      = false,
        HealthESP   = false,
        DistanceESP = false,
        Chams       = false,
        Tracers     = false,
        Fullbright  = false,
        NoFog       = false,
        Crosshair   = false,
    }

    -- Pro-Player-Objekte
    local PerPlayer = {} -- [Player] = { BB=BillboardGui, HL=Highlight, Tracer=Beam, Attach=Attachment }
    local cameraProxy: Part? = nil
    local camAttachment: Attachment? = nil
    local tracerUpdateConn: RBXScriptConnection? = nil

    -- Crosshair HUD
    local crosshairGui: ScreenGui? = nil
    local function setCrosshair(enabled: boolean)
        if enabled then
            if not crosshairGui then
                crosshairGui = Instance.new("ScreenGui")
                crosshairGui.Name = "VIS_Crosshair"
                crosshairGui.ResetOnSpawn = false
                crosshairGui.IgnoreGuiInset = true
                crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

                local dot = Instance.new("Frame")
                dot.Name = "Dot"
                dot.Size = UDim2.new(0, 4, 0, 4)
                dot.Position = UDim2.new(0.5, -2, 0.5, -2)
                dot.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
                dot.BorderSizePixel = 0
                dot.Parent = crosshairGui

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = dot
            end
        else
            if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
        end
    end

    -- Lighting Save/Restore
    local SavedLighting = {
        Ambient   = Lighting.Ambient,
        Brightness= Lighting.Brightness,
        FogEnd    = Lighting.FogEnd,
    }

    local function applyLighting()
        if State.Fullbright then
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.Brightness = 2
        else
            Lighting.Ambient = SavedLighting.Ambient
            Lighting.Brightness = SavedLighting.Brightness
        end
        Lighting.FogEnd = State.NoFog and 1e6 or (SavedLighting.FogEnd or 1000)
    end

    local function isEnemy(plr: Player)
        if not State.TeamCheck then return true end
        return (plr.Team ~= LocalPlayer.Team)
    end

    -- Helpers zum Erstellen/Entfernen
    local function ensureBillboard(p: Player, adornee: Instance)
        local pack = PerPlayer[p] or {}
        if not pack.BB then
            local bb = Instance.new("BillboardGui")
            bb.Name = "VIS_BB"
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 140, 0, 44)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.Adornee = adornee
            bb.Parent = frame -- wird mit Tab verborgen

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Name = "Name"
            nameLbl.BackgroundTransparency = 1
            nameLbl.Size = UDim2.new(1, 0, 0, 18)
            nameLbl.Position = UDim2.new(0, 0, 0, 0)
            nameLbl.Font = settings.Font
            nameLbl.TextSize = 14
            nameLbl.TextColor3 = Color3.new(1,1,1)
            nameLbl.TextStrokeTransparency = 0.5
            nameLbl.Parent = bb

            local distLbl = Instance.new("TextLabel")
            distLbl.Name = "Dist"
            distLbl.BackgroundTransparency = 1
            distLbl.Size = UDim2.new(1, 0, 0, 16)
            distLbl.Position = UDim2.new(0, 0, 0, 18)
            distLbl.Font = settings.Font
            distLbl.TextSize = 12
            distLbl.TextColor3 = Color3.fromRGB(200,200,200)
            distLbl.TextStrokeTransparency = 0.6
            distLbl.Parent = bb

            local hpFrame = Instance.new("Frame")
            hpFrame.Name = "HPBar"
            hpFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
            hpFrame.BorderSizePixel = 0
            hpFrame.Size = UDim2.new(1, -4, 0, 6)
            hpFrame.Position = UDim2.new(0, 2, 1, -8)
            hpFrame.Parent = bb

            local hpFill = Instance.new("Frame")
            hpFill.Name = "Fill"
            hpFill.BackgroundColor3 = Color3.fromRGB(0, 200, 90)
            hpFill.BorderSizePixel = 0
            hpFill.Size = UDim2.new(1, 0, 1, 0)
            hpFill.Parent = hpFrame

            pack.BB = bb
            PerPlayer[p] = pack
        end
        return PerPlayer[p].BB
    end

    local function ensureHighlight(p: Player, char: Model)
        local pack = PerPlayer[p] or {}
        if not pack.HL then
            local hl = Instance.new("Highlight")
            hl.Name = "VIS_HL"
            hl.Adornee = char
            hl.Parent = char
            pack.HL = hl
            PerPlayer[p] = pack
        end
        return PerPlayer[p].HL
    end

    local function ensureTracer(p: Player, hrp: BasePart)
        local pack = PerPlayer[p] or {}
        if not cameraProxy then
            cameraProxy = Instance.new("Part")
            cameraProxy.Name = "VIS_CameraProxy"
            cameraProxy.Anchored = true
            cameraProxy.CanCollide = false
            cameraProxy.Transparency = 1
            cameraProxy.Size = Vector3.new(0.5,0.5,0.5)
            cameraProxy.Parent = workspace
            camAttachment = Instance.new("Attachment")
            camAttachment.Parent = cameraProxy

            tracerUpdateConn = RunService.RenderStepped:Connect(function()
                if cameraProxy then
                    cameraProxy.CFrame = Camera.CFrame
                end
            end)
        end

        if not pack.Attach then
            local a1 = Instance.new("Attachment")
            a1.Parent = hrp
            pack.Attach = a1
        end

        if not pack.Tracer then
            local beam = Instance.new("Beam")
            beam.Name = "VIS_Beam"
            beam.Color = ColorSequence.new(Color3.fromRGB(0,255,120))
            beam.Width0 = 0.05
            beam.Width1 = 0.05
            beam.FaceCamera = true
            beam.LightInfluence = 0
            beam.Attachment0 = camAttachment
            beam.Attachment1 = pack.Attach
            beam.Parent = hrp
            pack.Tracer = beam
        end

        PerPlayer[p] = pack
        return pack.Tracer
    end

    local function clearPlayerVisuals(p: Player)
        local pack = PerPlayer[p]
        if not pack then return end
        if pack.BB then pcall(function() pack.BB:Destroy() end) end
        if pack.HL then pcall(function() pack.HL:Destroy() end) end
        if pack.Tracer then pcall(function() pack.Tracer:Destroy() end) end
        if pack.Attach then pcall(function() pack.Attach:Destroy() end) end
        PerPlayer[p] = nil
    end

    -- Hauptanwendung der Visuals auf Charakter
    local function applyToCharacter(p: Player, char: Model)
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        if not isEnemy(p) then
            clearPlayerVisuals(p)
            return
        end

        -- Billboard-Infos
        if State.NameESP or State.DistanceESP or State.HealthESP then
            local bb = ensureBillboard(p, hrp)
            bb.Enabled = true
            local nameLbl = bb:FindFirstChild("Name")
            local distLbl = bb:FindFirstChild("Dist")
            local hpBar = bb:FindFirstChild("HPBar")
            local hpFill = hpBar and hpBar:FindFirstChild("Fill")

            if nameLbl then
                nameLbl.Visible = State.NameESP
                if State.NameESP then
                    nameLbl.Text = p.DisplayName or p.Name
                end
            end

            if distLbl then
                distLbl.Visible = State.DistanceESP
                if State.DistanceESP then
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    distLbl.Text = string.format("%.0f studs", dist)
                end
            end

            if hpBar and hpFill then
                hpBar.Visible = State.HealthESP
                if State.HealthESP then
                    local ratio = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                    hpFill.Size = UDim2.new(ratio, 0, 1, 0)
                    hpFill.BackgroundColor3 = Color3.fromRGB(255 - math.floor(ratio*255), math.floor(ratio*255), 30)
                end
            end
        else
            local pack = PerPlayer[p]
            if pack and pack.BB then pcall(function() pack.BB:Destroy() end); pack.BB = nil end
        end

        -- Highlight: Box / Chams
        if State.BoxESP or State.Chams then
            local hl = ensureHighlight(p, char)
            hl.Enabled = true
            hl.FillTransparency = State.Chams and 0.7 or 1
            hl.FillColor = Color3.fromRGB(0, 255, 120)
            hl.OutlineTransparency = 0
            hl.OutlineColor = Color3.fromRGB(0, 255, 120)
        else
            local pack = PerPlayer[p]
            if pack and pack.HL then pcall(function() pack.HL:Destroy() end); pack.HL = nil end
        end

        -- Tracers
        if State.Tracers then
            ensureTracer(p, hrp)
        else
            local pack = PerPlayer[p]
            if pack and pack.Tracer then pcall(function() pack.Tracer:Destroy() end); pack.Tracer = nil end
            if pack and pack.Attach then pcall(function() pack.Attach:Destroy() end); pack.Attach = nil end
        end
    end

    local function refreshAllPlayers()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                applyToCharacter(plr, plr.Character)
            end
        end
    end

    ----------------------------------------------------------------
    -- Listeners & Update Loop
    ----------------------------------------------------------------
    Players.PlayerAdded:Connect(function(plr)
        if plr == LocalPlayer then return end
        plr.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart", 5)
            char:WaitForChild("Humanoid", 5)
            applyToCharacter(plr, char)
        end)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        clearPlayerVisuals(plr)
    end)

    -- Regelmäßiges Update (HP, Dist, Respawn, Cleanup)
    local heartbeatConn = RunService.Heartbeat:Connect(function()
        for p, _ in pairs(PerPlayer) do
            local char = p.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                clearPlayerVisuals(p)
            else
                applyToCharacter(p, char)
            end
        end
    end)

    ----------------------------------------------------------------
    -- UI: Sections & Toggles
    ----------------------------------------------------------------
    makeSection("ESP / Overlays")
    makeToggle("Name ESP", false, function(v) State.NameESP = v; refreshAllPlayers() end)
    makeToggle("Box ESP", false, function(v) State.BoxESP = v; refreshAllPlayers() end)
    makeToggle("Health ESP", false, function(v) State.HealthESP = v; refreshAllPlayers() end)
    makeToggle("Distance ESP", false, function(v) State.DistanceESP = v; refreshAllPlayers() end)
    makeToggle("Chams", false, function(v) State.Chams = v; refreshAllPlayers() end)
    makeToggle("Tracers", false, function(v)
        State.Tracers = v
        if not v then
            if tracerUpdateConn then tracerUpdateConn:Disconnect(); tracerUpdateConn = nil end
            if cameraProxy then pcall(function() cameraProxy:Destroy() end); cameraProxy = nil; camAttachment = nil end
        end
        refreshAllPlayers()
    end)
    makeToggle("Team Check", false, function(v) State.TeamCheck = v; refreshAllPlayers() end)

    makeSection("Lighting / HUD")
    makeToggle("Fullbright", false, function(v) State.Fullbright = v; applyLighting() end)
    makeToggle("No Fog", false, function(v) State.NoFog = v; applyLighting() end)
    makeToggle("Crosshair", false, function(v) State.Crosshair = v; setCrosshair(v) end)

    ----------------------------------------------------------------
    -- Cleanup wenn Tab zerstört wird
    ----------------------------------------------------------------
    frame.Destroying:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            clearPlayerVisuals(plr)
        end
        if tracerUpdateConn then tracerUpdateConn:Disconnect() end
        if cameraProxy then pcall(function() cameraProxy:Destroy() end) end
        if crosshairGui then pcall(function() crosshairGui:Destroy() end) end
        if heartbeatConn then heartbeatConn:Disconnect() end
        -- Lighting zurücksetzen
        Lighting.Ambient = SavedLighting.Ambient
        Lighting.Brightness = SavedLighting.Brightness
        Lighting.FogEnd = SavedLighting.FogEnd
    end)

    ----------------------------------------------------------------
    return frame
end
