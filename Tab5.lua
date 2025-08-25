-- Tab5.lua — WORLD TAB (Full Features, ohne: Fullbright / FreezeTime / NoFog / WaterTransparency)
-- Rückgabe: Frame (Tab-Container), kompatibel mit deinem Main-Script
-- Erwartet: settings = { Theme = { TabButton, TabButtonHover, TabButtonActive, TabText }, Font, TextSize, [ControlWidth?] }

return function(parent, settings)
    ----------------------------------------------------------------
    -- Services & Locals
    ----------------------------------------------------------------
    local Players        = game:GetService("Players")
    local RunService     = game:GetService("RunService")
    local TweenService   = game:GetService("TweenService")
    local Lighting       = game:GetService("Lighting")
    local Replicated     = game:GetService("ReplicatedStorage")
    local Workspace      = game:GetService("Workspace")
    local Terrain        = Workspace:FindFirstChildOfClass("Terrain")
    local LocalPlayer    = Players.LocalPlayer
    local Camera         = Workspace.CurrentCamera

    ----------------------------------------------------------------
    -- UI — Container (Tab-Look wie Tab1/4)
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
        task.defer(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(list.AbsoluteContentSize.Y + 20, scroll.AbsoluteSize.Y))
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvas)
    scroll.ChildAdded:Connect(autoCanvas)
    scroll.ChildRemoved:Connect(autoCanvas)

    ----------------------------------------------------------------
    -- UI — Helpers (Sections, Wide Toggles, TextBoxes)
    ----------------------------------------------------------------
    local CONTROL_WIDTH  = settings.ControlWidth or 404 -- breiter als Tab4
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
        pill.Size = UDim2.new(0, 70, 0, 28)
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
                BackgroundColor3 = enabled and Color3.fromRGB(235, 255, 245) or Color3.fromRGB(180,180,180)
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

    local function makeRow(labelLeft: string, defaultText: string, placeholder: string?, onApply: (string)->())
        -- TextBox + Apply Button row (z.B. für Asset IDs / Farbeingabe)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, CONTROL_WIDTH, 0, 44)
        container.BackgroundTransparency = 0.1
        container.BackgroundColor3 = settings.Theme.TabButton
        container.Parent = scroll
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = container

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = labelLeft
        lbl.TextColor3 = settings.Theme.TabText
        lbl.Font = settings.Font
        lbl.TextSize = settings.TextSize
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(0, math.floor(CONTROL_WIDTH*0.33), 1, 0)
        lbl.Parent = container

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, math.floor(CONTROL_WIDTH*0.33), 0, 32)
        box.Position = UDim2.new(0, math.floor(CONTROL_WIDTH*0.34), 0.5, -16)
        box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        box.TextColor3 = Color3.fromRGB(230, 230, 230)
        box.PlaceholderText = placeholder or ""
        box.Text = defaultText or ""
        box.ClearTextOnFocus = false
        box.Font = settings.Font
        box.TextSize = 14
        box.Parent = container
        local bcorner = Instance.new("UICorner"); bcorner.CornerRadius = UDim.new(0, 8); bcorner.Parent = box

        local apply = Instance.new("TextButton")
        apply.Size = UDim2.new(0, math.floor(CONTROL_WIDTH*0.25), 0, 32)
        apply.Position = UDim2.new(1, -math.floor(CONTROL_WIDTH*0.27), 0.5, -16)
        apply.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
        apply.TextColor3 = Color3.fromRGB(15, 15, 15)
        apply.Text = "Apply"
        apply.AutoButtonColor = true
        apply.Font = settings.Font
        apply.TextSize = 14
        apply.Parent = container
        local acorner = Instance.new("UICorner"); acorner.CornerRadius = UDim.new(0, 8); acorner.Parent = apply

        apply.MouseButton1Click:Connect(function()
            if onApply then task.spawn(function() onApply(box.Text) end) end
        end)

        return container, box, apply
    end

    local function clamp01(x) return math.clamp(tonumber(x) or 0, 0, 1) end
    local function clamp255(x) return math.clamp(math.floor(tonumber(x) or 0), 0, 255) end

    ----------------------------------------------------------------
    -- State + Original Snapshots (für Restore)
    ----------------------------------------------------------------
    local State = {
        RemoveTextures       = false,
        RemoveParticles      = false,
        DisableShadows       = false,
        NoSkybox             = false,
        CustomSkybox         = false,
        NightVision          = false,
        RainbowLighting      = false,
        HighlightInteract    = false,
        MaterialSmooth       = false,
        LowGfxBooster        = false,
        RemoveSkyElements    = false,
        AmbientOverride      = false,
    }

    -- Saved lighting values
    local SavedLighting = {
        Ambient      = Lighting.Ambient,
        OutdoorAmbient = (Lighting.OutdoorAmbient or Color3.fromRGB(128,128,128)),
        Technology   = Lighting.Technology,
        GlobalShadows= Lighting.GlobalShadows,
        FogColor     = Lighting.FogColor,
        ClockTime    = Lighting.ClockTime,
        Brightness   = Lighting.Brightness,
        ShadowSoftness = Lighting.ShadowSoftness,
        ExposureCompensation = Lighting.ExposureCompensation,
    }

    -- Store original instances/properties to restore
    local Original = {
        -- Parts
        CastShadow = setmetatable({}, {__mode = "k"}),             -- [BasePart] = bool
        Materials  = setmetatable({}, {__mode = "k"}),             -- [BasePart] = Enum.Material
        -- Textures & Decals transparency
        Decals     = setmetatable({}, {__mode = "k"}),             -- [Decal/Texture] = number (Transparency)
        -- Particles enabled
        Particle   = setmetatable({}, {__mode = "k"}),             -- [Emitter/Trail/Beam] = bool/number state
        -- Sky / Atmosphere
        SkyRef     = nil,                                          -- original Sky (clone)
        Atmosphere = nil,                                          -- Atmosphere clone
        -- World Highlights for interactables
        Highlights = {},                                           -- {Highlight}
        -- Ambient override
        AmbientColor = nil,                                        -- Color3
    }

    local Connections = {}
    local function bind(conn) table.insert(Connections, conn) end

    ----------------------------------------------------------------
    -- Utilities: Safe Clone, Safe Destroy, Traversals
    ----------------------------------------------------------------
    local function safeDestroy(obj)
        if obj then pcall(function() obj:Destroy() end) end
    end

    local function deepIter(root, callback)
        -- Iteriert alle descendants des Wurzel-Objekts
        for _, d in ipairs(root:GetDescendants()) do
            local ok, err = pcall(callback, d)
            if not ok then warn("[WorldTab] callback error:", err) end
        end
    end

    local function markAndSet(tbl, inst, value)
        if tbl[inst] == nil then
            tbl[inst] = value
        end
    end

    ----------------------------------------------------------------
    -- Feature: Remove Textures (Decal/Texture → Transparency = 1)
    ----------------------------------------------------------------
    local function applyRemoveTextures(enable)
        if enable then
            deepIter(Workspace, function(d)
                if d:IsA("Decal") or d:IsA("Texture") then
                    markAndSet(Original.Decals, d, d.Transparency)
                    d.Transparency = 1
                end
            end)
        else
            -- restore transparencies
            for inst, old in pairs(Original.Decals) do
                if inst and inst.Parent then
                    pcall(function() inst.Transparency = old end)
                end
            end
            table.clear(Original.Decals)
        end
    end

    ----------------------------------------------------------------
    -- Feature: Remove Particles (ParticleEmitter/Trail/Beam → Enabled=false)
    ----------------------------------------------------------------
    local function applyRemoveParticles(enable)
        if enable then
            deepIter(Workspace, function(d)
                if d:IsA("ParticleEmitter") then
                    markAndSet(Original.Particle, d, d.Enabled)
                    d.Enabled = false
                elseif d:IsA("Trail") then
                    markAndSet(Original.Particle, d, d.Enabled)
                    d.Enabled = false
                elseif d:IsA("Beam") then
                    -- Beam hat kein Enabled; wir setzen Transparency auf 1 als Workaround
                    local seq = d.Transparency
                    if not Original.Particle[d] then
                        Original.Particle[d] = seq
                    end
                    d.Transparency = NumberSequence.new(1)
                end
            end)
        else
            for inst, old in pairs(Original.Particle) do
                if inst and inst.Parent then
                    if inst:IsA("ParticleEmitter") or inst:IsA("Trail") then
                        pcall(function() inst.Enabled = old end)
                    elseif inst:IsA("Beam") then
                        pcall(function() inst.Transparency = old end)
                    end
                end
            end
            table.clear(Original.Particle)
        end
    end

    ----------------------------------------------------------------
    -- Feature: Disable Shadows (BasePart.CastShadow=false)
    ----------------------------------------------------------------
    local function applyDisableShadows(enable)
        if enable then
            deepIter(Workspace, function(d)
                if d:IsA("BasePart") then
                    markAndSet(Original.CastShadow, d, d.CastShadow)
                    d.CastShadow = false
                end
            end)
            -- Lighting-weit
            markAndSet(Original.CastShadow, Lighting, Lighting.GlobalShadows)
            Lighting.GlobalShadows = false
        else
            -- restore
            for inst, old in pairs(Original.CastShadow) do
                if inst == Lighting then
                    pcall(function() Lighting.GlobalShadows = old end)
                elseif inst and inst.Parent and inst:IsA("BasePart") then
                    pcall(function() inst.CastShadow = old end)
                end
            end
            table.clear(Original.CastShadow)
        end
    end

    ----------------------------------------------------------------
    -- Feature: Material → SmoothPlastic (mit Restore)
    ----------------------------------------------------------------
    local function applyMaterialSmooth(enable)
        if enable then
            deepIter(Workspace, function(d)
                if d:IsA("BasePart") then
                    markAndSet(Original.Materials, d, d.Material)
                    d.Material = Enum.Material.SmoothPlastic
                    -- Glanz reduzieren
                    if d:IsA("Part") or d:IsA("MeshPart") then
                        -- optional: Reflectance runter
                        if d:IsA("Part") then pcall(function() d.Reflectance = 0 end) end
                    end
                end
            end)
        else
            for inst, old in pairs(Original.Materials) do
                if inst and inst.Parent and inst:IsA("BasePart") then
                    pcall(function() inst.Material = old end)
                end
            end
            table.clear(Original.Materials)
        end
    end

    ----------------------------------------------------------------
    -- Feature: Low Graphics Booster
    --  - GlobalShadows=false (handled in DisableShadows optional)
    --  - Terrain.Decoration=false (kein Gras)
    --  - Schatten weicher = 0
    --  - Exposure leicht runter
    --  - Partikel off (kann separat sein, wir togglen nicht RemoveParticles automatisch)
    ----------------------------------------------------------------
    local SavedLowGfx = {
        TerrainDecoration = Terrain and Terrain.Decoration,
        ShadowSoftness = Lighting.ShadowSoftness,
        GlobalShadows = Lighting.GlobalShadows,
        Technology = Lighting.Technology,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
    local function applyLowGfx(enable)
        if enable then
            if Terrain then Terrain.Decoration = false end
            Lighting.ShadowSoftness = 0
            Lighting.GlobalShadows  = false
            Lighting.ExposureCompensation = 0
            -- Optional: Rendering Technology auf Voxel belassen (nicht umstellen um kompatibel zu bleiben)
        else
            if Terrain and SavedLowGfx.TerrainDecoration ~= nil then Terrain.Decoration = SavedLowGfx.TerrainDecoration end
            Lighting.ShadowSoftness = SavedLowGfx.ShadowSoftness
            Lighting.GlobalShadows  = SavedLowGfx.GlobalShadows
            Lighting.ExposureCompensation = SavedLowGfx.ExposureCompensation
        end
    end

    ----------------------------------------------------------------
    -- Feature: No Skybox / Custom Skybox / Remove Sky Elements
    ----------------------------------------------------------------
    local function snapshotSky()
        if not Original.SkyRef then
            local sky = Lighting:FindFirstChildOfClass("Sky")
            if sky then
                Original.SkyRef = sky:Clone()
            end
        end
        if not Original.Atmosphere then
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then
                Original.Atmosphere = atmo:Clone()
            end
        end
    end

    local function restoreSky()
        -- remove current sky/atmo
        for _,child in ipairs(Lighting:GetChildren()) do
            if child:IsA("Sky") or child:IsA("Atmosphere") then
                safeDestroy(child)
            end
        end
        -- restore snapshot
        if Original.SkyRef then
            local s = Original.SkyRef:Clone()
            s.Parent = Lighting
        end
        if Original.Atmosphere then
            local a = Original.Atmosphere:Clone()
            a.Parent = Lighting
        end
    end

    local function applyNoSkybox(enable)
        snapshotSky()
        if enable then
            -- remove all sky & atmosphere
            for _,child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Sky") or child:IsA("Atmosphere") then
                    safeDestroy(child)
                end
            end
        else
            restoreSky()
        end
    end

    -- default simple skybox pack
    local DefaultSky = {
        SkyboxBk = "rbxassetid://5705576201",
        SkyboxDn = "rbxassetid://5705577276",
        SkyboxFt = "rbxassetid://5705575907",
        SkyboxLf = "rbxassetid://5705576674",
        SkyboxRt = "rbxassetid://5705576071",
        SkyboxUp = "rbxassetid://5705576862",
        SunTextureId  = "rbxassetid://6196665103",
        MoonTextureId = "rbxassetid://6196663864",
        StarCount = 2500,
    }

    local CurrentSkyValues = table.clone(DefaultSky)

    local function applyCustomSkybox(enable)
        snapshotSky()
        if enable then
            -- wipe existing
            for _,child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Sky") then safeDestroy(child) end
            end
            local sky = Instance.new("Sky")
            sky.SkyboxBk = CurrentSkyValues.SkyboxBk
            sky.SkyboxDn = CurrentSkyValues.SkyboxDn
            sky.SkyboxFt = CurrentSkyValues.SkyboxFt
            sky.SkyboxLf = CurrentSkyValues.SkyboxLf
            sky.SkyboxRt = CurrentSkyValues.SkyboxRt
            sky.SkyboxUp = CurrentSkyValues.SkyboxUp
            -- StarCount existiert ggf. nicht in jeder Version, pcall
            pcall(function()
                sky.SunTextureId = CurrentSkyValues.SunTextureId
                sky.MoonTextureId = CurrentSkyValues.MoonTextureId
                sky.StarCount = CurrentSkyValues.StarCount
            end)
            sky.Parent = Lighting
            -- Ensure an Atmosphere for nicer look (optional)
            if not Lighting:FindFirstChildOfClass("Atmosphere") then
                local atmo = Instance.new("Atmosphere")
                atmo.Density = 0.35
                atmo.Offset = 0
                atmo.Haze = 1
                atmo.Color = Color3.fromRGB(200, 210, 255)
                atmo.Decay = Color3.fromRGB(90, 100, 120)
                atmo.Parent = Lighting
            end
        else
            restoreSky()
        end
    end

    local SavedSkyElems = {}
    local function applyRemoveSkyElements(enable)
        snapshotSky()
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if enable then
            if sky then
                SavedSkyElems.SunTextureId  = sky.SunTextureId
                SavedSkyElems.MoonTextureId = sky.MoonTextureId
                SavedSkyElems.StarCount     = pcall(function() return sky.StarCount end) and sky.StarCount or nil
                sky.SunTextureId  = ""
                sky.MoonTextureId = ""
                pcall(function() sky.StarCount = 0 end)
            end
        else
            if sky and (SavedSkyElems.SunTextureId or SavedSkyElems.MoonTextureId) then
                sky.SunTextureId  = SavedSkyElems.SunTextureId or sky.SunTextureId
                sky.MoonTextureId = SavedSkyElems.MoonTextureId or sky.MoonTextureId
                if SavedSkyElems.StarCount ~= nil then
                    pcall(function() sky.StarCount = SavedSkyElems.StarCount end)
                end
            else
                -- falls sky fehlte, komplette Wiederherstellung
                restoreSky()
            end
            table.clear(SavedSkyElems)
        end
    end

    ----------------------------------------------------------------
    -- Feature: Night Vision (ColorCorrectionEffect)
    ----------------------------------------------------------------
    local NVFilter = Lighting:FindFirstChild("WORLD_NightVision")
    if not NVFilter then
        NVFilter = Instance.new("ColorCorrectionEffect")
        NVFilter.Name = "WORLD_NightVision"
        NVFilter.Parent = Lighting
        NVFilter.Enabled = false
        NVFilter.Brightness = 0.05
        NVFilter.Contrast = 0.4
        NVFilter.Saturation = -0.1
        NVFilter.TintColor = Color3.fromRGB(140, 255, 160)
    end

    local function applyNightVision(enable)
        NVFilter.Enabled = enable
    end

    ----------------------------------------------------------------
    -- Feature: Rainbow Lighting Mode (zyklische Ambient-Farbe)
    ----------------------------------------------------------------
    local RainbowConn : RBXScriptConnection? = nil
    local function hsv2rgb(h: number, s: number, v: number): Color3
        local i = math.floor(h*6)
        local f = h*6 - i
        local p = v*(1-s)
        local q = v*(1-f*s)
        local t = v*(1-(1-f)*s)
        i = i % 6
        local r,g,b =
            (i==0 and v or i==1 and q or i==2 and p or i==3 and p or i==4 and t or v),
            (i==0 and t or i==1 and v or i==2 and v or i==3 and q or i==4 and p or p),
            (i==0 and p or i==1 and p or i==2 and t or i==3 and v or i==4 and v or q)
        return Color3.new(r,g,b)
    end

    local function applyRainbowLighting(enable)
        if enable then
            local t0 = os.clock()
            if RainbowConn then RainbowConn:Disconnect(); RainbowConn=nil end
            RainbowConn = RunService.RenderStepped:Connect(function()
                local t = os.clock() - t0
                local h = (t * 0.05) % 1
                local c = hsv2rgb(h, 0.8, 1.0)
                Lighting.Ambient = c
                pcall(function() Lighting.OutdoorAmbient = c end)
            end)
            table.insert(Connections, RainbowConn)
        else
            if RainbowConn then RainbowConn:Disconnect(); RainbowConn=nil end
            Lighting.Ambient = SavedLighting.Ambient
            pcall(function() Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient end)
        end
    end

    ----------------------------------------------------------------
    -- Feature: Highlight Important Objects (Interactables)
    -- Erkennung: ProximityPrompt / ClickDetector / TouchTransmitter (optional)
    ----------------------------------------------------------------
    local function clearInteractHighlights()
        for _,hl in ipairs(Original.Highlights) do
            safeDestroy(hl)
        end
        table.clear(Original.Highlights)
    end

    local function applyHighlightInteract(enable)
        if enable then
            clearInteractHighlights()
            local function addHL(target: Instance)
                local adornee = target:IsA("BasePart") and target or target:FindFirstAncestorOfClass("BasePart")
                if not adornee then
                    local model = target:FindFirstAncestorOfClass("Model")
                    if model then adornee = model:FindFirstChildWhichIsA("BasePart") end
                end
                if adornee then
                    local hl = Instance.new("Highlight")
                    hl.Name = "WORLD_Highlight"
                    hl.Adornee = adornee:IsA("Model") and adornee or adornee.Parent
                    hl.Adornee = (adornee:IsA("Model") and adornee) or adornee
                    hl.FillColor = Color3.fromRGB(255, 225, 100)
                    hl.FillTransparency = 0.7
                    hl.OutlineColor = Color3.fromRGB(0,0,0)
                    hl.OutlineTransparency = 0.2
                    hl.Parent = adornee
                    table.insert(Original.Highlights, hl)
                end
            end

            -- Bestehende
            deepIter(Workspace, function(d)
                if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
                    addHL(d)
                end
            end)

            -- Live hinzu kommende
            bind(Workspace.DescendantAdded:Connect(function(d)
                if not State.HighlightInteract then return end
                if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
                    addHL(d)
                end
            end))
        else
            clearInteractHighlights()
        end
    end

    ----------------------------------------------------------------
    -- Feature: Ambient Override (RGB-Input)
    ----------------------------------------------------------------
    local function applyAmbientColor(enable, color: Color3?)
        if enable then
            if color then
                Original.AmbientColor = Original.AmbientColor or Lighting.Ambient
                Lighting.Ambient = color
                pcall(function() Lighting.OutdoorAmbient = color end)
            end
        else
            if Original.AmbientColor then
                Lighting.Ambient = SavedLighting.Ambient
                pcall(function() Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient end)
                Original.AmbientColor = nil
            end
        end
    end

    ----------------------------------------------------------------
    -- UI — Sections + Controls
    ----------------------------------------------------------------
    makeSection("World / Performance")

    makeToggle("Remove Textures (Decals/Textures → transparent)", false, function(v)
        State.RemoveTextures = v
        applyRemoveTextures(v)
    end)

    makeToggle("Remove Particles (Emitter/Trail/Beam)", false, function(v)
        State.RemoveParticles = v
        applyRemoveParticles(v)
    end)

    makeToggle("Disable Shadows (CastShadow & GlobalShadows)", false, function(v)
        State.DisableShadows = v
        applyDisableShadows(v)
    end)

    makeToggle("Material → SmoothPlastic (Restore möglich)", false, function(v)
        State.MaterialSmooth = v
        applyMaterialSmooth(v)
    end)

    makeToggle("Low Graphics Booster (ohne Wasser/NoFog)", false, function(v)
        State.LowGfxBooster = v
        applyLowGfx(v)
    end)

    makeSection("Sky / Atmosphere")

    local _, setNoSky = makeToggle("No Skybox (Atmosphere & Sky entfernen)", false, function(v)
        -- Konflikt-Schutz: CustomSkybox nicht gleichzeitig
        if v and State.CustomSkybox then
            State.CustomSkybox = false
            applyCustomSkybox(false)
        end
        State.NoSkybox = v
        applyNoSkybox(v)
    end)

    local _, setCustomSky = makeToggle("Custom Skybox (Asset-IDs unten)", false, function(v)
        -- Konflikt-Schutz: NoSkybox nicht gleichzeitig
        if v and State.NoSkybox then
            State.NoSkybox = false
            applyNoSkybox(false)
            setNoSky(false)
        end
        State.CustomSkybox = v
        applyCustomSkybox(v)
    end)

    local skyRowBk, skyBoxBk, skyApplyBk = makeRow("Skybox Bk", DefaultSky.SkyboxBk, "rbxassetid://...", function(text)
        CurrentSkyValues.SkyboxBk = text
        if State.CustomSkybox then applyCustomSkybox(true) end
    end)
    local _, skyBoxDn, _ = makeRow("Skybox Dn", DefaultSky.SkyboxDn, "rbxassetid://...", function(text)
        CurrentSkyValues.SkyboxDn = text
        if State.CustomSkybox then applyCustomSkybox(true) end
    end)
    local _, skyBoxFt, _ = makeRow("Skybox Ft", DefaultSky.SkyboxFt, "rbxassetid://...", function(text)
        CurrentSkyValues.SkyboxFt = text
        if State.CustomSkybox then applyCustomSkybox(true) end
    end)
    local _, skyBoxLf, _ = makeRow("Skybox Lf", DefaultSky.SkyboxLf, "rbxassetid://...", function(text)
        CurrentSkyValues.SkyboxLf = text
        if State.CustomSkybox then applyCustomSkybox(true) end
    end)
    local _, skyBoxRt, _ = makeRow("Skybox Rt", DefaultSky.SkyboxRt, "rbxassetid://...", function(text)
        CurrentSkyValues.SkyboxRt = text
        if State.CustomSkybox then applyCustomSkybox(true) end
    end)
    local _, skyBoxUp, _ = makeRow("Skybox Up", DefaultSky.SkyboxUp, "rbxassetid://...", function(text)
        CurrentSkyValues.SkyboxUp = text
        if State.CustomSkybox then applyCustomSkybox(true) end
    end)

    makeToggle("Remove Sky Elements (Sonne/Mond/Sterne)", false, function(v)
        State.RemoveSkyElements = v
        applyRemoveSkyElements(v)
    end)

    makeSection("Vision / Styling")

    makeToggle("Night Vision (ColorCorrection)", false, function(v)
        State.NightVision = v
        applyNightVision(v)
    end)

    makeToggle("Rainbow Lighting Mode (Ambient-HSV)", false, function(v)
        State.RainbowLighting = v
        applyRainbowLighting(v)
    end)

    local _, boxR, _ = makeRow("Ambient R (0-255)", "128", "0-255", function(txt) end)
    local _, boxG, _ = makeRow("Ambient G (0-255)", "128", "0-255", function(txt) end)
    local _, boxB, _ = makeRow("Ambient B (0-255)", "128", "0-255", function(txt) end)

    local ambApplyContainer, _, ambApplyBtn = makeRow("Ambient Apply", "", "click Apply", function(_)
        local r = clamp255(boxR.Text)
        local g = clamp255(boxG.Text)
        local b = clamp255(boxB.Text)
        State.AmbientOverride = true
        applyAmbientColor(true, Color3.fromRGB(r,g,b))
    end)

    local _, _, ambResetBtn = makeRow("Ambient Reset", "", "click Reset", function(_)
        State.AmbientOverride = false
        applyAmbientColor(false)
    end)

    makeSection("Interactables")

    makeToggle("Highlight Interactables (Proximity/Click)", false, function(v)
        State.HighlightInteract = v
        applyHighlightInteract(v)
    end)

    ----------------------------------------------------------------
    -- Live Updates (nur für Features, die per Frame laufen)
    ----------------------------------------------------------------
    -- (aktuell nur RainbowLighting braucht RenderStepped; NightVision & Ambient sind static)

    ----------------------------------------------------------------
    -- Cleanup on Tab Destroy (vollständiger Restore)
    ----------------------------------------------------------------
    frame.Destroying:Connect(function()
        -- Stop live conns
        for _,c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        table.clear(Connections)

        -- Features aus → Restore
        if State.RemoveTextures   then applyRemoveTextures(false) end
        if State.RemoveParticles  then applyRemoveParticles(false) end
        if State.DisableShadows   then applyDisableShadows(false) end
        if State.MaterialSmooth   then applyMaterialSmooth(false) end
        if State.LowGfxBooster    then applyLowGfx(false) end
        if State.CustomSkybox     then applyCustomSkybox(false) end
        if State.NoSkybox         then applyNoSkybox(false) end
        if State.RemoveSkyElements then applyRemoveSkyElements(false) end
        if State.NightVision      then applyNightVision(false) end
        if State.RainbowLighting  then applyRainbowLighting(false) end
        if State.HighlightInteract then applyHighlightInteract(false) end
        if State.AmbientOverride  then applyAmbientColor(false) end

        -- Lighting auf Original
        Lighting.Ambient = SavedLighting.Ambient
        pcall(function() Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient end)
        Lighting.Technology = SavedLighting.Technology
        Lighting.GlobalShadows = SavedLighting.GlobalShadows
        Lighting.FogColor = SavedLighting.FogColor
        Lighting.ClockTime = SavedLighting.ClockTime
        Lighting.Brightness = SavedLighting.Brightness
        Lighting.ShadowSoftness = SavedLighting.ShadowSoftness
        Lighting.ExposureCompensation = SavedLighting.ExposureCompensation

        -- Highlights löschen (falls noch da)
        for _,hl in ipairs(Original.Highlights) do safeDestroy(hl) end
        table.clear(Original.Highlights)
    end)

    ----------------------------------------------------------------
    -- Return
    ----------------------------------------------------------------
    return frame
end
