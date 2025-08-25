-- Tab4.lua — Visuals (professionell, robust, identisch zu Tab1-Style)
-- Rückgabe: Frame (Container), vollständig kompatibel mit deinem Main-Script

return function(parent, settings)
    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local TweenService      = game:GetService("TweenService")
    local Lighting          = game:GetService("Lighting")
    local LocalPlayer       = Players.LocalPlayer

    ----------------------------------------------------------------
    -- UI: Tab-Container + Scrollbereich (gleiches Layout wie Tab1)
    ----------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = parent

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.fromScale(0, 0)
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
        -- passt CanvasSize an, sobald Content wächst
        task.defer(function()
            local contentHeight = 0
            for _,child in ipairs(scroll:GetChildren()) do
                if child:IsA("GuiObject") then
                    contentHeight += child.AbsoluteSize.Y + (list.Padding.Offset or 0)
                end
            end
            scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(contentHeight + 20, scroll.AbsoluteSize.Y))
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvas)
    scroll.ChildAdded:Connect(autoCanvas)
    scroll.ChildRemoved:Connect(autoCanvas)

    -------------------------------------------------------------
    -- UI: Button/Toggles (identisch zu Tab1, mit Hover-Tweens)
    -------------------------------------------------------------
    local function makeToggle(labelText, default, onToggle)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 260, 0, 42)
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Text = string.format("%s: %s", labelText, default and "ON" or "OFF")
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.AutoButtonColor = false
        btn.Parent = scroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local enabled = default

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButtonHover
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = string.format("%s: %s", labelText, enabled and "ON" or "OFF")
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
            if onToggle then
                task.spawn(function()
                    onToggle(enabled)
                end)
            end
        end)

        return btn, function(state) -- external setter (für Abhängigkeiten)
            enabled = state
            btn.Text = string.format("%s: %s", labelText, enabled and "ON" or "OFF")
            btn.BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
        end
    end

    local function makeSection(title)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 260, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(200,200,200)
        lbl.Font = settings.Font
        lbl.TextSize = settings.TextSize
        lbl.Parent = scroll
        return lbl
    end

    -------------------------------------------------------------
    -- VISUALS IMPLEMENTATION (sauber, modular, mit Cleanup)
    -------------------------------------------------------------
    local connections = {}
    local tracerUpdateConn : RBXScriptConnection? = nil
    local cameraProxy: Part? = nil

    -- State
    local State = {
        TeamCheck    = false,
        NameESP      = false,
        BoxESP       = false,       -- via Highlight outlines
        HealthESP    = false,       -- Billboard health bar
        DistanceESP  = false,
        Tracers      = false,       -- Beam-basiert
        Chams        = false,       -- Highlight fill
        Fullbright   = false,
        NightVision  = false,
        Crosshair    = false,
    }

    -- Per-Player Visual Objects we create when toggles are on
    local PerPlayer = {}  -- [Player] = { highlight=Highlight, billboard=BillboardGui, tracerBeam=Beam, tracerAttachment=Attachment }

    local function isEnemy(p)
        if not State.TeamCheck then return true end
        local myTeam = LocalPlayer.Team
        return (p.Team ~= myTeam)
    end

    -- Ensure container for BillboardGui
    local function ensureBillboard(p, adornee)
        local pack = PerPlayer[p] or {}
        if not pack.billboard then
            local bb = Instance.new("BillboardGui")
            bb.Name = "VIS_BB"
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 120, 0, 42)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.Adornee = adornee
            bb.Parent = frame -- GUI lebt im Tab, verschwindet mit Tab

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

            pack.billboard = bb
            PerPlayer[p] = pack
        end
        return pack.billboard
    end

    local function ensureHighlight(p, adornee)
        local pack = PerPlayer[p] or {}
        if not pack.highlight then
            local hl = Instance.new("Highlight")
            hl.Name = "VIS_HL"
            hl.Adornee = adornee
            hl.FillTransparency = 1          -- nur Outline für Box/ESP
            hl.OutlineTransparency = 0
            hl.OutlineColor = Color3.fromRGB(0, 255, 120)
            hl.Parent = adornee
            pack.highlight = hl
            PerPlayer[p] = pack
        end
        return pack.highlight
    end

    local function clearPlayerVisuals(p)
        local pack = PerPlayer[p]
        if not pack then return end
        if pack.billboard then pcall(function() pack.billboard:Destroy() end) end
        if pack.highlight then pcall(function() pack.highlight:Destroy() end) end
        if pack.tracerBeam then pcall(function() pack.tracerBeam:Destroy() end) end
        if pack.tracerAttachment then pcall(function() pack.tracerAttachment:Destroy() end) end
        PerPlayer[p] = nil
    end

    local function applyToCharacter(p, char)
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if not isEnemy(p) then
            clearPlayerVisuals(p)
            return
        end

        -- Name/Distance/Health billboard
        if State.NameESP or State.DistanceESP or State.HealthESP then
            local bb = ensureBillboard(p, hrp)
            bb.Enabled = State.NameESP or State.DistanceESP or State.HealthESP
            local nameLbl = bb:FindFirstChild("Name")
            local distLbl = bb:FindFirstChild("Dist")
            local hpFrame = bb:FindFirstChild("HPBar")
            local hpFill = hpFrame and hpFrame:FindFirstChild("Fill")

            if nameLbl then
                nameLbl.Visible = State.NameESP
                nameLbl.Text = p.DisplayName or p.Name
            end

            if distLbl then
                distLbl.Visible = State.DistanceESP
                if State.DistanceESP then
                    local cam = workspace.CurrentCamera
                    local dist = (cam.CFrame.Position - hrp.Position).Magnitude
                    distLbl.Text = string.format("%.0f studs", dist)
                end
            end

            if hpFrame and hpFill then
                hpFrame.Visible = State.HealthESP
                if State.HealthESP then
                    local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    hpFill.Size = UDim2.new(ratio, 0, 1, 0)
                    hpFill.BackgroundColor3 = Color3.fromRGB(255 - math.floor(ratio*255), math.floor(ratio*255), 30)
                end
            end
        else
            -- falls komplett aus: billboard löschen
            local pack = PerPlayer[p]
            if pack and pack.billboard then pcall(function() pack.billboard:Destroy() end); pack.billboard = nil end
        end

        -- Box/Outline ESP + Chams via Highlight
        if State.BoxESP or State.Chams then
            local hl = ensureHighlight(p, char)
            hl.Enabled = true
            hl.FillTransparency = State.Chams and 0.7 or 1
            hl.FillColor = Color3.fromRGB(0, 255, 120)
            hl.OutlineTransparency = 0
            hl.OutlineColor = Color3.fromRGB(0, 255, 120)
        else
            local pack = PerPlayer[p]
            if pack and pack.highlight then pcall(function() pack.highlight:Destroy() end); pack.highlight = nil end
        end

        -- Tracer (Beam): von Kamera zu HRP
        if State.Tracers then
            local pack = PerPlayer[p] or {}
            if not cameraProxy then
                cameraProxy = Instance.new("Part")
                cameraProxy.Name = "VIS_CameraProxy"
                cameraProxy.Anchored = true
                cameraProxy.CanCollide = false
                cameraProxy.Transparency = 1
                cameraProxy.Size = Vector3.new(0.5,0.5,0.5)
                cameraProxy.Parent = workspace
            end
            if not tracerUpdateConn then
                tracerUpdateConn = RunService.RenderStepped:Connect(function()
                    if not cameraProxy then return end
                    local cam = workspace.CurrentCamera
                    cameraProxy.CFrame = cam.CFrame
                end)
                table.insert(connections, tracerUpdateConn)
            end

            if not pack.tracerAttachment then
                pack.tracerAttachment = Instance.new("Attachment")
                pack.tracerAttachment.Parent = hrp
            end
            if not pack.tracerBeam then
                local beam = Instance.new("Beam")
                beam.Name = "VIS_Beam"
                beam.Color = ColorSequence.new(Color3.fromRGB(0,255,120))
                beam.Width0 = 0.05
                beam.Width1 = 0.05
                beam.FaceCamera = true
                beam.LightInfluence = 0
                -- Attachment0 liegt auf CameraProxy
                local a0 = cameraProxy:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", cameraProxy)
                beam.Attachment0 = a0
                beam.Attachment1 = pack.tracerAttachment
                beam.Parent = hrp
                pack.tracerBeam = beam
            end
            PerPlayer[p] = pack
        else
            local pack = PerPlayer[p]
            if pack then
                if pack.tracerBeam then pcall(function() pack.tracerBeam:Destroy() end); pack.tracerBeam = nil end
                if pack.tracerAttachment then pcall(function() pack.tracerAttachment:Destroy() end); pack.tracerAttachment = nil end
            end
        end
    end

    local function refreshAllPlayers()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                applyToCharacter(plr, char)
            end
        end
    end

    -- Character/Player listener
    local function hookPlayer(plr)
        if plr == LocalPlayer then return end
        table.insert(connections, plr.CharacterAdded:Connect(function(char)
            -- leichte Verzögerung bis HRP/Humanoid existiert
            char:WaitForChild("HumanoidRootPart", 5)
            char:WaitForChild("Humanoid", 5)
            applyToCharacter(plr, char)
        end))
        if plr.Character then
            applyToCharacter(plr, plr.Character)
        end
    end

    for _,plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
    table.insert(connections, Players.PlayerAdded:Connect(hookPlayer))
    table.insert(connections, Players.PlayerRemoving:Connect(function(plr)
        clearPlayerVisuals(plr)
    end))

    -- regelmäßiges Update (Distance/HP)
    local heartbeatConn = RunService.Heartbeat:Connect(function()
        for p, pack in pairs(PerPlayer) do
            local char = p.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                clearPlayerVisuals(p)
            else
                applyToCharacter(p, char)
            end
        end
    end)
    table.insert(connections, heartbeatConn)

    -------------------------------------------------------------
    -- Lighting / Crosshair
    -------------------------------------------------------------
    local savedLighting = {
        Brightness = Lighting.Brightness,
        ClockTime  = Lighting.ClockTime,
        Ambient    = Lighting.Ambient
    }

    local nvFilter = Lighting:FindFirstChild("VIS_NVFilter")
    if not nvFilter then
        nvFilter = Instance.new("ColorCorrectionEffect")
        nvFilter.Name = "VIS_NVFilter"
        nvFilter.Parent = Lighting
        nvFilter.Enabled = false
    end

    local crosshairGui : ScreenGui? = nil
    local function setCrosshair(enabled)
        if enabled then
            if not crosshairGui then
                crosshairGui = Instance.new("ScreenGui")
                crosshairGui.Name = "VIS_Crosshair"
                crosshairGui.ResetOnSpawn = false
                crosshairGui.IgnoreGuiInset = true
                crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

                local center = Instance.new("Frame")
                center.Name = "Dot"
                center.Size = UDim2.new(0, 4, 0, 4)
                center.Position = UDim2.new(0.5, -2, 0.5, -2)
                center.BackgroundColor3 = Color3.fromRGB(0,255,120)
                center.BorderSizePixel = 0
                center.Parent = crosshairGui
            end
        else
            if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
        end
    end

    -------------------------------------------------------------
    -- Toggles (UI)
    -------------------------------------------------------------
    makeSection("ESP / Overlays")

    local _, setNameESP   = makeToggle("Name ESP", false, function(v) 
        State.NameESP = v
        refreshAllPlayers()
    end)

    local _, setBoxESP    = makeToggle("Box ESP", false, function(v) 
        State.BoxESP = v
        refreshAllPlayers()
    end)

    local _, setHealthESP = makeToggle("Health ESP", false, function(v) 
        State.HealthESP = v
        refreshAllPlayers()
    end)

    local _, setDistESP   = makeToggle("Distance ESP", false, function(v) 
        State.DistanceESP = v
        refreshAllPlayers()
    end)

    local _, setChams     = makeToggle("Chams", false, function(v) 
        State.Chams = v
        refreshAllPlayers()
    end)

    local _, setTracers   = makeToggle("Tracers", false, function(v)
        State.Tracers = v
        if not v and tracerUpdateConn then 
            tracerUpdateConn:Disconnect()
            tracerUpdateConn = nil 
        end
        if not v and cameraProxy then 
            cameraProxy:Destroy()
            cameraProxy = nil 
        end
        refreshAllPlayers()
    end)

    local _, setTeamCheck = makeToggle("Team Check", false, function(v) 
        State.TeamCheck = v
        refreshAllPlayers()
    end)

    -------------------------------------------------------------
    -- Lighting / HUD
    -------------------------------------------------------------
    makeSection("Lighting / HUD")

    makeToggle("Fullbright", false, function(v)
        State.Fullbright = v
        if v then
            game.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            game.Lighting.Brightness = 2
        else
            game.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
            game.Lighting.Brightness = 1
        end
    end)

    makeToggle("No Fog", false, function(v)
        State.NoFog = v
        game.Lighting.FogEnd = v and 1e6 or 1000
    end)

    makeToggle("Crosshair", false, function(v)
        State.Crosshair = v
        if v then
            enableCrosshair()
        else
            disableCrosshair()
        end
    end)

    -------------------------------------------------------------
    -- Return Frame
    -------------------------------------------------------------
    return frame
end

