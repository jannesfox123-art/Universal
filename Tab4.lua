--// Tab4.lua — VISUALS (Full Features, Advanced, Clean)
--// Rückgabe: Frame (Tab-Container), vollständig kompatibel mit deinem Main-Script
--// Erfordert: settings = { Theme = { TabButton, TabButtonHover, TabButtonActive, TabText }, Font, TextSize, [ControlWidth?] }

return function(parent, settings)
    ----------------------------------------------------------------
    -- Services & Locals
    ----------------------------------------------------------------
    local Players        = game:GetService("Players")
    local RunService     = game:GetService("RunService")
    local TweenService   = game:GetService("TweenService")
    local Lighting       = game:GetService("Lighting")
    local LocalPlayer    = Players.LocalPlayer
    local Camera         = workspace.CurrentCamera

    ----------------------------------------------------------------
    -- UI — Container
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
            local y = list.AbsoluteContentSize.Y
            scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y + 20, scroll.AbsoluteSize.Y))
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvas)
    scroll.ChildAdded:Connect(autoCanvas)
    scroll.ChildRemoved:Connect(autoCanvas)

    ----------------------------------------------------------------
    -- UI — Helpers (Section & breite Toggles)
    ----------------------------------------------------------------
    local CONTROL_WIDTH  = settings.ControlWidth or 392 -- schön breit „wie Tab 1, etwas breiter“
    local CONTROL_HEIGHT = 44

    local function makeSection(title: string)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, CONTROL_WIDTH, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(200,200,200)
        lbl.Font = settings.Font
        lbl.TextSize = settings.TextSize
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = scroll
        return lbl
    end

    local function makeToggle(labelText: string, default: boolean, onToggle: (boolean)->())
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, CONTROL_WIDTH, 0, CONTROL_HEIGHT)
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Text = labelText
        btn.AutoButtonColor = false
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = scroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn

        -- Toggle pill (rechts)
        local pill = Instance.new("Frame")
        pill.AnchorPoint = Vector2.new(1, 0.5)
        pill.Position = UDim2.new(1, -10, 0.5, 0)
        pill.Size = UDim2.new(0, 64, 0, 28)
        pill.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
        pill.BorderSizePixel = 0
        pill.Parent = btn
        local pillCorner = Instance.new("UICorner"); pillCorner.CornerRadius = UDim.new(1, 0); pillCorner.Parent = pill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 24, 0, 24)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        knob.BorderSizePixel = 0
        knob.Parent = pill
        local knobCorner = Instance.new("UICorner"); knobCorner.CornerRadius = UDim.new(1, 0); knobCorner.Parent = knob

        local enabled = default or false
        local function applyVisual()
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
            TweenService:Create(pill, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(65, 65, 65)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.12), {
                Position = enabled and UDim2.new(1, -26, 0, 2) or UDim2.new(0, 2, 0, 2),
                BackgroundColor3 = enabled and Color3.fromRGB(235, 255, 245) or Color3.fromRGB(180, 180, 180)
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

        applyVisual()
        return btn, function(state: boolean) enabled = state; applyVisual(); if onToggle then onToggle(enabled) end end
    end

    ----------------------------------------------------------------
    -- Visual State & Pack-Management
    ----------------------------------------------------------------
    local State = {
        TeamCheck   = false,
        NameESP     = false,
        BoxESP      = false,        -- 2D Box via Model:GetBoundingBox()
        HealthESP   = false,        -- text
        DistanceESP = false,
        Tracers     = false,        -- bottom center → feet
        Chams       = false,        -- Highlight
        Fullbright  = false,
        NoFog       = false,
        Crosshair   = false,
    }

    -- Save lighting to restore later
    local SavedLighting = {
        Ambient    = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        FogEnd     = Lighting.FogEnd,
        FogStart   = Lighting.FogStart,
        ClockTime  = Lighting.ClockTime,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ExposureCompensation = Lighting.ExposureCompensation,
    }

    -- One pack per player: Drawing objects + Highlight
    type DrawPack = {
        NameText:any?, HPText:any?, DistText:any?, Box:any?, BoxOutline:any?, Tracer:any?, ChamsHL:Highlight?
    }
    local Packs : {[Player]:DrawPack} = {}

    -- Keep connections for clean teardown
    local Connections : {RBXScriptConnection} = {}
    local function bind(conn: RBXScriptConnection) table.insert(Connections, conn) end

    ----------------------------------------------------------------
    -- Utilities: Drawing new / safeRemove / team check
    ----------------------------------------------------------------
    local function newDrawing(kind: string, props: table?)
        local ok, obj = pcall(function() return Drawing.new(kind) end)
        if not ok or not obj then return nil end
        if props then
            for k,v in pairs(props) do
                pcall(function() obj[k] = v end)
            end
        end
        return obj
    end

    local function safeRemove(obj)
        if not obj then return end
        pcall(function()
            if typeof(obj) == "Instance" then
                obj:Destroy()
            elseif obj.Remove then
                obj:Remove()
            elseif obj.Destroy then
                obj:Destroy()
            end
        end)
    end

    local function isEnemy(plr: Player)
        if not State.TeamCheck then return true end
        return plr.Team ~= LocalPlayer.Team
    end

    ----------------------------------------------------------------
    -- BoundingBox → 2D-Rectangle (min/max der 8 Eckpunkte)
    ----------------------------------------------------------------
    local function getScreenRectFromModel(model: Model)
        local cf, size = model:GetBoundingBox()
        local sx, sy, sz = size.X/2, size.Y/2, size.Z/2

        local corners = {
            Vector3.new(-sx, -sy, -sz), Vector3.new(-sx, -sy,  sz),
            Vector3.new(-sx,  sy, -sz), Vector3.new(-sx,  sy,  sz),
            Vector3.new( sx, -sy, -sz), Vector3.new( sx, -sy,  sz),
            Vector3.new( sx,  sy, -sz), Vector3.new( sx,  sy,  sz),
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local anyOnScreen = false

        for _, localOffset in ipairs(corners) do
            local worldPoint = cf:PointToWorldSpace(localOffset)
            local v2, on = Camera:WorldToViewportPoint(worldPoint)
            if on then anyOnScreen = true end
            if v2.X < minX then minX = v2.X end
            if v2.Y < minY then minY = v2.Y end
            if v2.X > maxX then maxX = v2.X end
            if v2.Y > maxY then maxY = v2.Y end
        end

        if not anyOnScreen then return nil end

        local w = math.max(1, maxX - minX)
        local h = math.max(1, maxY - minY)
        return minX, minY, w, h
    end

    ----------------------------------------------------------------
    -- Chams (Highlight) helper
    ----------------------------------------------------------------
    local function ensureChams(plr: Player, char: Model)
        local pack = Packs[plr] or {}
        if pack.ChamsHL and pack.ChamsHL.Parent then
            return pack.ChamsHL
        end
        local hl = Instance.new("Highlight")
        hl.Name = "VIS_Highlight"
        hl.Adornee = char
        hl.FillTransparency = 0.75
        hl.OutlineTransparency = 0.15
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.Parent = char
        pack.ChamsHL = hl
        Packs[plr] = pack
        return hl
    end

    ----------------------------------------------------------------
    -- Pack lifecycle
    ----------------------------------------------------------------
    local function ensurePack(plr: Player)
        local pack = Packs[plr]
        if pack then return pack end
        pack = { NameText=nil, HPText=nil, DistText=nil, Box=nil, BoxOutline=nil, Tracer=nil, ChamsHL=nil }
        Packs[plr] = pack
        return pack
    end

    local function clearPack(plr: Player)
        local p = Packs[plr]; if not p then return end
        safeRemove(p.NameText);   p.NameText = nil
        safeRemove(p.HPText);     p.HPText   = nil
        safeRemove(p.DistText);   p.DistText = nil
        safeRemove(p.Box);        p.Box      = nil
        safeRemove(p.BoxOutline); p.BoxOutline = nil
        safeRemove(p.Tracer);     p.Tracer   = nil
        safeRemove(p.ChamsHL);    p.ChamsHL  = nil
        Packs[plr] = nil
    end

    local function destroyFeatureForAll(featureKey: string)
        for plr, p in pairs(Packs) do
            if featureKey == "NameESP" and p.NameText then safeRemove(p.NameText); p.NameText=nil end
            if featureKey == "HealthESP" and p.HPText then safeRemove(p.HPText); p.HPText=nil end
            if featureKey == "DistanceESP" and p.DistText then safeRemove(p.DistText); p.DistText=nil end
            if featureKey == "BoxESP" then
                if p.Box then safeRemove(p.Box); p.Box=nil end
                if p.BoxOutline then safeRemove(p.BoxOutline); p.BoxOutline=nil end
            end
            if featureKey == "Tracers" and p.Tracer then safeRemove(p.Tracer); p.Tracer=nil end
            if featureKey == "Chams" and p.ChamsHL then p.ChamsHL.Enabled=false; safeRemove(p.ChamsHL); p.ChamsHL=nil end
        end
    end

    ----------------------------------------------------------------
    -- Main per-player update (called every frame when features active)
    ----------------------------------------------------------------
    local FOOT_OFFSET = Vector3.new(0, 3, 0) -- HRP -> Fußhöhe (robust genug)

    local function updatePlayer(plr: Player)
        if plr == LocalPlayer then return end
        local char = plr.Character
        if not char then clearPack(plr); return end
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then clearPack(plr); return end
        if not isEnemy(plr) then clearPack(plr); return end

        local root2d, on = Camera:WorldToViewportPoint(hrp.Position)
        if not on then clearPack(plr); return end

        local pack = ensurePack(plr)

        -- Name ESP (unten am Fuß)
        if State.NameESP then
            if not pack.NameText then
                pack.NameText = newDrawing("Text", { Center=true, Outline=true, Size=14, Color=Color3.fromRGB(255,255,255), Visible=true })
            end
            local foot2d = Camera:WorldToViewportPoint(hrp.Position - FOOT_OFFSET)
            pack.NameText.Text     = plr.Name
            pack.NameText.Position = Vector2.new(foot2d.X, foot2d.Y + 14)
            pack.NameText.Visible  = true
        else
            if pack.NameText then safeRemove(pack.NameText); pack.NameText=nil end
        end

        -- Health ESP (Text)
        if State.HealthESP then
            if not pack.HPText then
                pack.HPText = newDrawing("Text", { Center=true, Outline=true, Size=14, Color=Color3.fromRGB(0,255,0), Visible=true })
            end
            pack.HPText.Text     = ("HP: %d"):format(math.max(0, math.floor(hum.Health + 0.5)))
            pack.HPText.Position = Vector2.new(root2d.X, root2d.Y - 30)
            pack.HPText.Visible  = true
        else
            if pack.HPText then safeRemove(pack.HPText); pack.HPText=nil end
        end

        -- Distance ESP
        if State.DistanceESP then
            if not pack.DistText then
                pack.DistText = newDrawing("Text", { Center=true, Outline=true, Size=14, Color=Color3.fromRGB(0, 200, 255), Visible=true })
            end
            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
            pack.DistText.Text     = string.format("%.1f studs", dist)
            pack.DistText.Position = Vector2.new(root2d.X, root2d.Y - 46)
            pack.DistText.Visible  = true
        else
            if pack.DistText then safeRemove(pack.DistText); pack.DistText=nil end
        end

        -- Box ESP (exakte Hitbox via GetBoundingBox)
        if State.BoxESP then
            local x,y,w,h = getScreenRectFromModel(char)
            if x then
                if not pack.BoxOutline then
                    pack.BoxOutline = newDrawing("Square", { Thickness=3, Filled=false, Color=Color3.fromRGB(0,0,0), Visible=true })
                end
                if not pack.Box then
                    pack.Box = newDrawing("Square", { Thickness=1.5, Filled=false, Color=Color3.fromRGB(255,0,0), Visible=true })
                end
                pack.BoxOutline.Size     = Vector2.new(w, h)
                pack.BoxOutline.Position = Vector2.new(x, y)
                pack.BoxOutline.Visible  = true

                pack.Box.Size     = Vector2.new(w, h)
                pack.Box.Position = Vector2.new(x, y)
                pack.Box.Visible  = true
            else
                if pack.Box then safeRemove(pack.Box); pack.Box=nil end
                if pack.BoxOutline then safeRemove(pack.BoxOutline); pack.BoxOutline=nil end
            end
        else
            if pack.Box then safeRemove(pack.Box); pack.Box=nil end
            if pack.BoxOutline then safeRemove(pack.BoxOutline); pack.BoxOutline=nil end
        end

        -- Tracers (von Screen bottom center → Fuß)
        if State.Tracers then
            if not pack.Tracer then
                pack.Tracer = newDrawing("Line", { Thickness=1.5, Color=Color3.fromRGB(255,255,0), Visible=true })
            end
            local vp = Camera.ViewportSize
            local foot2d = Camera:WorldToViewportPoint(hrp.Position - FOOT_OFFSET)
            pack.Tracer.From    = Vector2.new(vp.X/2, vp.Y)
            pack.Tracer.To      = Vector2.new(foot2d.X, foot2d.Y)
            pack.Tracer.Visible = true
        else
            if pack.Tracer then safeRemove(pack.Tracer); pack.Tracer=nil end
        end

        -- Chams (Highlight)
        if State.Chams then
            local hl = ensureChams(plr, char)
            hl.Enabled = true
            hl.Adornee = char
            hl.FillColor = (plr.Team == LocalPlayer.Team) and Color3.fromRGB(60,200,120) or Color3.fromRGB(255,80,80)
            hl.FillTransparency = 0.75
            hl.OutlineColor = Color3.fromRGB(0,0,0)
            hl.OutlineTransparency = 0.15
        else
            local p = Packs[plr]
            if p and p.ChamsHL then p.ChamsHL.Enabled=false; safeRemove(p.ChamsHL); p.ChamsHL=nil end
        end
    end

    ----------------------------------------------------------------
    -- Global update loop
    ----------------------------------------------------------------
    local function anyFeatureActive()
        return State.NameESP or State.BoxESP or State.HealthESP or State.DistanceESP or State.Tracers or State.Chams or State.Crosshair
    end

    local RSConn = RunService.RenderStepped:Connect(function()
        if anyFeatureActive() then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    updatePlayer(plr)
                end
            end
        end
    end)
    table.insert(Connections, RSConn)

    ----------------------------------------------------------------
    -- Crosshair (Drawing, 2 Linien)
    ----------------------------------------------------------------
    local Crosshair = { H=nil, V=nil }
    local function updateCrosshair()
        if State.Crosshair then
            if not Crosshair.H then Crosshair.H = newDrawing("Line", {Thickness=1.5, Color=Color3.fromRGB(255,255,255), Visible=true}) end
            if not Crosshair.V then Crosshair.V = newDrawing("Line", {Thickness=1.5, Color=Color3.fromRGB(255,255,255), Visible=true}) end
            local vp = Camera.ViewportSize
            local cx, cy = vp.X/2, vp.Y/2
            Crosshair.H.From, Crosshair.H.To = Vector2.new(cx-10, cy), Vector2.new(cx+10, cy)
            Crosshair.V.From, Crosshair.V.To = Vector2.new(cx, cy-10), Vector2.new(cx, cy+10)
            Crosshair.H.Visible = true
            Crosshair.V.Visible = true
        else
            if Crosshair.H then Crosshair.H.Visible=false; safeRemove(Crosshair.H); Crosshair.H=nil end
            if Crosshair.V then Crosshair.V.Visible=false; safeRemove(Crosshair.V); Crosshair.V=nil end
        end
    end
    local CHConn = RunService.RenderStepped:Connect(updateCrosshair)
    table.insert(Connections, CHConn)

    ----------------------------------------------------------------
    -- Lighting / Fog (apply + restore)
    ----------------------------------------------------------------
    local function applyLighting()
        if State.Fullbright then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.ClockTime = 14
            Lighting.ExposureCompensation = 0.1
        else
            Lighting.Ambient = SavedLighting.Ambient
            Lighting.Brightness = SavedLighting.Brightness
            Lighting.ClockTime = SavedLighting.ClockTime
            Lighting.ExposureCompensation = SavedLighting.ExposureCompensation
        end

        if State.NoFog then
            Lighting.FogStart = 1e5
            Lighting.FogEnd   = 1e6
        else
            Lighting.FogStart = SavedLighting.FogStart
            Lighting.FogEnd   = SavedLighting.FogEnd
        end
    end

    ----------------------------------------------------------------
    -- Player Join/Leave — sofortiges Hinzufügen/Entfernen
    ----------------------------------------------------------------
    local function hookPlayer(plr: Player)
        if plr == LocalPlayer then return end
        table.insert(Connections, plr.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart", 5)
            char:WaitForChild("Humanoid", 5)
            task.defer(function()
                if anyFeatureActive() then updatePlayer(plr) end
            end)
        end))
        if plr.Character then
            task.defer(function()
                if anyFeatureActive() then updatePlayer(plr) end
            end)
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
    table.insert(Connections, Players.PlayerAdded:Connect(hookPlayer))
    table.insert(Connections, Players.PlayerRemoving:Connect(function(plr)
        clearPack(plr) -- ALLES löschen, sobald er leavt
    end))

    ----------------------------------------------------------------
    -- UI — Toggles (mit sofortigem globalem Cleanup bei „OFF“)
    ----------------------------------------------------------------
    makeSection("ESP / Overlays")

    makeToggle("Name ESP (unten)", false, function(v)
        State.NameESP = v
        if not v then destroyFeatureForAll("NameESP") end
    end)

    makeToggle("Box ESP (Hitbox genau)", false, function(v)
        State.BoxESP = v
        if not v then destroyFeatureForAll("BoxESP") end
    end)

    makeToggle("Health ESP (Text)", false, function(v)
        State.HealthESP = v
        if not v then destroyFeatureForAll("HealthESP") end
    end)

    makeToggle("Distance ESP", false, function(v)
        State.DistanceESP = v
        if not v then destroyFeatureForAll("DistanceESP") end
    end)

    makeToggle("Tracers (Bottom → Fuß)", false, function(v)
        State.Tracers = v
        if not v then destroyFeatureForAll("Tracers") end
    end)

    makeToggle("Team Check", false, function(v)
        State.TeamCheck = v
        -- sofort neu anwenden (Spieler, die vorher gefiltert wurden, könnten jetzt sichtbar sein)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if v then
                    -- im Zweifel neu zeichnen (wird in RenderStepped ohnehin aktualisiert)
                    updatePlayer(plr)
                else
                    updatePlayer(plr)
                end
            end
        end
    end)

    makeToggle("Chams (Highlight)", false, function(v)
        State.Chams = v
        if not v then destroyFeatureForAll("Chams") end
    end)

    makeSection("Lighting / HUD")

    makeToggle("Fullbright", false, function(v)
        State.Fullbright = v
        applyLighting()
    end)

    makeToggle("No Fog", false, function(v)
        State.NoFog = v
        applyLighting()
    end)

    makeToggle("Crosshair", false, function(v)
        State.Crosshair = v
        if not v then updateCrosshair() end
    end)

    ----------------------------------------------------------------
    -- Cleanup on Tab destroy (alles restoren/löschen)
    ----------------------------------------------------------------
    frame.Destroying:Connect(function()
        -- Drawings pro Spieler
        for plr,_ in pairs(Packs) do
            clearPack(plr)
        end

        -- Crosshair
        if Crosshair.H then safeRemove(Crosshair.H); Crosshair.H=nil end
        if Crosshair.V then safeRemove(Crosshair.V); Crosshair.V=nil end

        -- Connections
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        table.clear(Connections)

        -- Lighting restore
        Lighting.Ambient = SavedLighting.Ambient
        Lighting.Brightness = SavedLighting.Brightness
        Lighting.FogEnd = SavedLighting.FogEnd
        Lighting.FogStart = SavedLighting.FogStart
        Lighting.ClockTime = SavedLighting.ClockTime
        Lighting.ColorShift_Top = SavedLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = SavedLighting.ColorShift_Bottom
        Lighting.ExposureCompensation = SavedLighting.ExposureCompensation
    end)

    ----------------------------------------------------------------
    -- Return
    ----------------------------------------------------------------
    return frame
end
