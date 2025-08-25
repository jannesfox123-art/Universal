-- Tab4.lua — VISUALS (Full • Advanced Hitbox Boxes • Clean)
-- Rückgabe: Frame (Tab-Container), kompatibel mit deinem Main-Script

return function(parent, settings)
    --// Services & Locals
    local Players        = game:GetService("Players")
    local RunService     = game:GetService("RunService")
    local TweenService   = game:GetService("TweenService")
    local Lighting       = game:GetService("Lighting")
    local LocalPlayer    = Players.LocalPlayer
    local Camera         = workspace.CurrentCamera

    --////////////////////////////////////////////////////////////////
    -- UI: Tab-Container + Scrollbereich (gleiches Layout wie Tab1)
    --////////////////////////////////////////////////////////////////
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
    scroll.ChildAdded:Connect(autoCanvas)
    scroll.ChildRemoved:Connect(autoCanvas)

    --////////////////////////////////////////////////////////////////
    -- UI: Sections + breite Toggle-Buttons (Tab1-Style)
    --////////////////////////////////////////////////////////////////
    local CONTROL_WIDTH  = settings.ControlWidth or 380  -- leicht breiter „damit es passt“
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

    local function makeToggle(labelText: string, default: boolean, onToggle: (boolean) -> ())
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

        -- Toggle-Pill rechts
        local pill = Instance.new("Frame")
        pill.AnchorPoint = Vector2.new(1, 0.5)
        pill.Position = UDim2.new(1, -10, 0.5, 0)
        pill.Size = UDim2.new(0, 58, 0, 26)
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
                BackgroundColor3 = enabled and Color3.fromRGB(230, 255, 240) or Color3.fromRGB(180,180,180)
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

    --////////////////////////////////////////////////////////////////
    -- VISUALS: State + Per-Player Packs
    --////////////////////////////////////////////////////////////////
    local State = {
        TeamCheck   = false,
        NameESP     = false,
        BoxESP      = false,        -- 2D-Box anhand 3D-BoundingBox
        HealthESP   = false,        -- Text
        DistanceESP = false,
        Tracers     = false,        -- Linie ScreenBottom -> Fuß
        Chams       = false,        -- Highlight fill/outline
        Fullbright  = false,
        NoFog       = false,
        Crosshair   = false,
    }

    -- Lighting speichern
    local SavedLighting = {
        Ambient    = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        FogEnd     = Lighting.FogEnd,
        FogStart   = Lighting.FogStart,
        ClockTime  = Lighting.ClockTime,
    }

    -- Per-Player: Drawings & Instances
    type DrawPack = {
        NameText: any?,
        HPText: any?,
        DistText: any?,
        Box: any?,            -- Square
        BoxOutline: any?,     -- optional Outline
        Tracer: any?,         -- Line
        ChamsHL: Highlight?,
    }
    local Packs: {[Player]: DrawPack} = {}

    -- Connections für Cleanup
    local Connections: {RBXScriptConnection} = {}
    local function bind(conn: RBXScriptConnection) table.insert(Connections, conn) end

    --////////////////////////////////////////////////////////////////
    -- Helpers: Drawing Factory & Safe Remove
    --////////////////////////////////////////////////////////////////
    local function newDrawing(kind: string, props: table)
        local ok, obj = pcall(function() return Drawing.new(kind) end)
        if not ok or not obj then return nil end
        for k,v in pairs(props or {}) do
            pcall(function() obj[k] = v end)
        end
        return obj
    end

    local function safeRemove(obj)
        if not obj then return end
        pcall(function()
            if typeof(obj) == "Instance" then
                obj:Destroy()
            elseif typeof(obj) == "table" or typeof(obj) == "userdata" then
                if obj.Remove then obj:Remove() end
                if obj.Destroy then obj:Destroy() end
            end
        end)
    end

    local function isEnemy(plr: Player)
        if not State.TeamCheck then return true end
        local myTeam = LocalPlayer.Team
        return plr.Team ~= myTeam
    end

    --////////////////////////////////////////////////////////////////
    -- Box-Projection: 3D BoundingBox -> 2D Rect (min/max)
    --////////////////////////////////////////////////////////////////
    local function getScreenRectFromModel(model: Model)
        -- Robust: nutzt GetBoundingBox (CFrame + Size) → 8 Ecken → projizieren
        local cf, size = model:GetBoundingBox()
        local sx, sy, sz = size.X/2, size.Y/2, size.Z/2

        local corners = {
            Vector3.new(-sx, -sy, -sz),
            Vector3.new(-sx, -sy,  sz),
            Vector3.new(-sx,  sy, -sz),
            Vector3.new(-sx,  sy,  sz),
            Vector3.new( sx, -sy, -sz),
            Vector3.new( sx, -sy,  sz),
            Vector3.new( sx,  sy, -sz),
            Vector3.new( sx,  sy,  sz),
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local anyOnScreen = false

        for _, offset in ipairs(corners) do
            local worldPoint = cf:PointToWorldSpace(offset)
            local v2, onScreen = Camera:WorldToViewportPoint(worldPoint)
            if onScreen then
                anyOnScreen = true
            end
            minX = math.min(minX, v2.X)
            minY = math.min(minY, v2.Y)
            maxX = math.max(maxX, v2.X)
            maxY = math.max(maxY, v2.Y)
        end

        if not anyOnScreen then
            return nil -- komplett außerhalb des Screens
        end

        -- clamp gegen Viewport (optional)
        local vp = Camera.ViewportSize
        minX = math.clamp(minX, -1e4, vp.X + 1e4)
        maxX = math.clamp(maxX, -1e4, vp.X + 1e4)
        minY = math.clamp(minY, -1e4, vp.Y + 1e4)
        maxY = math.clamp(maxY, -1e4, vp.Y + 1e4)

        local w = math.max(1, maxX - minX)
        local h = math.max(1, maxY - minY)
        return minX, minY, w, h
    end

    --////////////////////////////////////////////////////////////////
    -- Chams via Highlight (pro Charakter, Farbe nach Team)
    --////////////////////////////////////////////////////////////////
    local function ensureChams(plr: Player, char: Model)
        local pack = Packs[plr] or {}
        if pack.ChamsHL and pack.ChamsHL.Parent ~= nil then
            return pack.ChamsHL
        end
        local hl = Instance.new("Highlight")
        hl.Name = "VIS_HL"
        hl.Adornee = char
        hl.Parent = char
        hl.Enabled = true
        hl.FillColor = (plr.Team == LocalPlayer.Team) and Color3.fromRGB(60, 200, 120) or Color3.fromRGB(255, 80, 80)
        hl.OutlineColor = Color3.fromRGB(0, 0, 0)
        hl.FillTransparency = 0.75
        hl.OutlineTransparency = 0.2
        pack.ChamsHL = hl
        Packs[plr] = pack
        return hl
    end

    --////////////////////////////////////////////////////////////////
    -- Per-Player Drawing Lifecycle
    --////////////////////////////////////////////////////////////////
    local function clearPack(plr: Player)
        local pack = Packs[plr]
        if not pack then return end
        safeRemove(pack.NameText)
        safeRemove(pack.HPText)
        safeRemove(pack.DistText)
        safeRemove(pack.Box)
        safeRemove(pack.BoxOutline)
        safeRemove(pack.Tracer)
        safeRemove(pack.ChamsHL)
        Packs[plr] = nil
    end

    local function ensurePack(plr: Player)
        local pack = Packs[plr]
        if pack then return pack end
        pack = {
            NameText = nil,
            HPText = nil,
            DistText = nil,
            Box = nil,
            BoxOutline = nil,
            Tracer = nil,
            ChamsHL = nil,
        }
        Packs[plr] = pack
        return pack
    end

    --////////////////////////////////////////////////////////////////
    -- Main Update per Player (pro Frame)
    --////////////////////////////////////////////////////////////////
    local FOOT_OFFSET = Vector3.new(0, 3, 0) -- HRP->Fuß (etwa)
    local function updatePlayer(plr: Player)
        -- existence & team
        if plr == LocalPlayer then return end
        local char = plr.Character
        if not char then clearPack(plr); return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then clearPack(plr); return end
        if not isEnemy(plr) then clearPack(plr); return end

        -- Projection checks
        local root2d, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            -- trotzdem: Box kann offscreen sein; aber wenn root off, alles verstecken
            clearPack(plr)
            return
        end

        local pack = ensurePack(plr)

        --////////////////////////
        -- Name ESP (bei Füßen)
        --////////////////////////
        if State.NameESP then
            if not pack.NameText then
                pack.NameText = newDrawing("Text", {
                    Center = true, Outline = true, Size = 14,
                    Color = Color3.fromRGB(255,255,255), Visible = true
                })
            end
            local foot = Camera:WorldToViewportPoint(hrp.Position - FOOT_OFFSET)
            pack.NameText.Text     = plr.Name
            pack.NameText.Position = Vector2.new(foot.X, foot.Y + 14)
            pack.NameText.Visible  = true
        else
            safeRemove(pack.NameText); pack.NameText = nil
        end

        --////////////////////////
        -- Health ESP (Text)
        --////////////////////////
        if State.HealthESP then
            if not pack.HPText then
                pack.HPText = newDrawing("Text", {
                    Center = true, Outline = true, Size = 14,
                    Color = Color3.fromRGB(0,255,0), Visible = true
                })
            end
            local hp = math.max(0, math.floor(hum.Health + 0.5))
            pack.HPText.Text     = ("HP: %d"):format(hp)
            pack.HPText.Position = Vector2.new(root2d.X, root2d.Y - 30)
            pack.HPText.Visible  = true
        else
            safeRemove(pack.HPText); pack.HPText = nil
        end

        --////////////////////////
        -- Distance ESP (Text)
        --////////////////////////
        if State.DistanceESP then
            if not pack.DistText then
                pack.DistText = newDrawing("Text", {
                    Center = true, Outline = true, Size = 14,
                    Color = Color3.fromRGB(0,200,255), Visible = true
                })
            end
            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
            pack.DistText.Text     = string.format("%.1f studs", dist)
            pack.DistText.Position = Vector2.new(root2d.X, root2d.Y - 46)
            pack.DistText.Visible  = true
        else
            safeRemove(pack.DistText); pack.DistText = nil
        end

        --////////////////////////
        -- Box ESP (Hitbox-basiert)
        --////////////////////////
        if State.BoxESP then
            local x, y, w, h = getScreenRectFromModel(char)
            if x and y and w and h then
                -- Outline (dünn), Box (fett)
                if not pack.BoxOutline then
                    pack.BoxOutline = newDrawing("Square", {
                        Thickness = 3, Filled = false, Color = Color3.fromRGB(0,0,0), Visible = true
                    })
                end
                if not pack.Box then
                    pack.Box = newDrawing("Square", {
                        Thickness = 1.5, Filled = false, Color = Color3.fromRGB(255,0,0), Visible = true
                    })
                end
                pack.BoxOutline.Size     = Vector2.new(w, h)
                pack.BoxOutline.Position = Vector2.new(x, y)
                pack.BoxOutline.Visible  = true

                pack.Box.Size     = Vector2.new(w, h)
                pack.Box.Position = Vector2.new(x, y)
                pack.Box.Visible  = true
            else
                -- nichts sichtbar
                safeRemove(pack.Box); pack.Box = nil
                safeRemove(pack.BoxOutline); pack.BoxOutline = nil
            end
        else
            safeRemove(pack.Box); pack.Box = nil
            safeRemove(pack.BoxOutline); pack.BoxOutline = nil
        end

        --////////////////////////
        -- Tracers (ScreenBottom -> Fuß)
        --////////////////////////
        if State.Tracers then
            if not pack.Tracer then
                pack.Tracer = newDrawing("Line", {
                    Thickness = 1.5, Color = Color3.fromRGB(255,255,0), Visible = true
                })
            end
            local vp = Camera.ViewportSize
            local foot2d = Camera:WorldToViewportPoint(hrp.Position - FOOT_OFFSET)
            pack.Tracer.From    = Vector2.new(vp.X/2, vp.Y)    -- unten Mitte
            pack.Tracer.To      = Vector2.new(foot2d.X, foot2d.Y)
            pack.Tracer.Visible = true
        else
            safeRemove(pack.Tracer); pack.Tracer = nil
        end

        --////////////////////////
        -- Chams via Highlight
        --////////////////////////
        if State.Chams then
            local hl = ensureChams(plr, char)
            hl.Enabled = true
            hl.Adornee = char
            hl.FillColor = (plr.Team == LocalPlayer.Team) and Color3.fromRGB(60, 200, 120) or Color3.fromRGB(255, 80, 80)
            hl.FillTransparency = 0.75
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.OutlineTransparency = 0.2
        else
            if pack.ChamsHL then pack.ChamsHL.Enabled = false end
        end
    end

    --////////////////////////////////////////////////////////////////
    -- Global Update Loop
    --////////////////////////////////////////////////////////////////
    local function updateAll()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                updatePlayer(plr)
            end
        end
    end

    local RSConn = RunService.RenderStepped:Connect(function()
        -- Nur updaten, wenn etwas aktiv ist (spart Ressourcen)
        if State.NameESP or State.BoxESP or State.HealthESP or State.DistanceESP or State.Tracers or State.Chams or State.Crosshair then
            updateAll()
        else
            -- Alles aus → Packs hart leeren (nur einmal), sonst nix tun
            for plr,_ in pairs(Packs) do
                clearPack(plr)
            end
        end
    end)
    bind(RSConn)

    --////////////////////////////////////////////////////////////////
    -- Crosshair (Drawing)
    --////////////////////////////////////////////////////////////////
    local CrosshairLines = {H=nil, V=nil}
    local function updateCrosshair()
        local enable = State.Crosshair
        if enable then
            if not CrosshairLines.H then
                CrosshairLines.H = newDrawing("Line", {Thickness = 1.5, Color = Color3.fromRGB(255,255,255), Visible = true})
            end
            if not CrosshairLines.V then
                CrosshairLines.V = newDrawing("Line", {Thickness = 1.5, Color = Color3.fromRGB(255,255,255), Visible = true})
            end
            local vp = Camera.ViewportSize
            local cx, cy = vp.X/2, vp.Y/2
            CrosshairLines.H.From, CrosshairLines.H.To = Vector2.new(cx-10, cy), Vector2.new(cx+10, cy)
            CrosshairLines.V.From, CrosshairLines.V.To = Vector2.new(cx, cy-10), Vector2.new(cx, cy+10)
            CrosshairLines.H.Visible = true
            CrosshairLines.V.Visible = true
        else
            if CrosshairLines.H then CrosshairLines.H.Visible = false end
            if CrosshairLines.V then CrosshairLines.V.Visible = false end
        end
    end

    local CHConn = RunService.RenderStepped:Connect(updateCrosshair)
    bind(CHConn)

    --////////////////////////////////////////////////////////////////
    -- Lighting / Fog
    --////////////////////////////////////////////////////////////////
    local function applyLighting()
        if State.Fullbright then
            Lighting.Brightness = 2
            Lighting.Ambient    = Color3.new(1,1,1)
            Lighting.ClockTime  = 14
        else
            Lighting.Brightness = SavedLighting.Brightness
            Lighting.Ambient    = SavedLighting.Ambient
            Lighting.ClockTime  = SavedLighting.ClockTime
        end

        if State.NoFog then
            Lighting.FogStart = 1e5
            Lighting.FogEnd   = 1e6
        else
            Lighting.FogStart = SavedLighting.FogStart
            Lighting.FogEnd   = SavedLighting.FogEnd
        end
    end

    --////////////////////////////////////////////////////////////////
    -- Player Join/Leave Handling
    --////////////////////////////////////////////////////////////////
    local function hookPlayer(plr: Player)
        if plr == LocalPlayer then return end
        bind(plr.CharacterAdded:Connect(function(char)
            -- kurze Wartezeit bis HRP/Humanoid existieren
            char:WaitForChild("HumanoidRootPart", 5)
            char:WaitForChild("Humanoid", 5)
            -- sofort ESP anwenden, wenn toggles aktiv
            updatePlayer(plr)
        end))
        -- falls Charakter schon da
        if plr.Character then
            task.defer(function() updatePlayer(plr) end)
        end
    end

    for _,plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
    bind(Players.PlayerAdded:Connect(hookPlayer))
    bind(Players.PlayerRemoving:Connect(function(plr)
        clearPack(plr) -- ESP/Tracer/Box usw. sofort entfernen
    end))

    --////////////////////////////////////////////////////////////////
    -- UI: Toggles
    --////////////////////////////////////////////////////////////////
    makeSection("ESP / Overlays")

    makeToggle("Name ESP (unten)", false, function(v)
        State.NameESP = v
    end)

    makeToggle("Box ESP (Hitbox)", false, function(v)
        State.BoxESP = v
    end)

    makeToggle("Health ESP (Text)", false, function(v)
        State.HealthESP = v
    end)

    makeToggle("Distance ESP", false, function(v)
        State.DistanceESP = v
    end)

    makeToggle("Tracers (Bottom → Fuß)", false, function(v)
        State.Tracers = v
    end)

    makeToggle("Team Check", false, function(v)
        State.TeamCheck = v
        -- Bei Änderung sofort neu zuweisen
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                updatePlayer(plr)
            end
        end
    end)

    makeToggle("Chams (Highlight)", false, function(v)
        State.Chams = v
        if not v then
            for _, pack in pairs(Packs) do
                if pack.ChamsHL then pack.ChamsHL.Enabled = false end
            end
        end
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
    end)

    --////////////////////////////////////////////////////////////////
    -- Cleanup bei Tab-Destroy
    --////////////////////////////////////////////////////////////////
    frame.Destroying:Connect(function()
        -- Drawings/Kits löschen
        for plr,_ in pairs(Packs) do
            clearPack(plr)
        end

        if CrosshairLines.H then safeRemove(CrosshairLines.H); CrosshairLines.H=nil end
        if CrosshairLines.V then safeRemove(CrosshairLines.V); CrosshairLines.V=nil end

        for _,c in ipairs(Connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(Connections)

        -- Lighting zurücksetzen
        Lighting.Ambient    = SavedLighting.Ambient
        Lighting.Brightness = SavedLighting.Brightness
        Lighting.FogEnd     = SavedLighting.FogEnd
        Lighting.FogStart   = SavedLighting.FogStart
        Lighting.ClockTime  = SavedLighting.ClockTime
    end)

    --////////////////////////////////////////////////////////////////
    -- Return Frame (Tab-Container)
    --////////////////////////////////////////////////////////////////
    return frame
end
