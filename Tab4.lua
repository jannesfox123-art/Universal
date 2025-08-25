-- Tab4.lua — Visuals (professionell, robust, identisch zu Tab1-Style)
-- Rückgabe: Frame (Container), vollständig kompatibel mit deinem Main-Script

return function(parent, settings)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer

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
        task.defer(function()
            local contentHeight = list.AbsoluteContentSize.Y
            scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(contentHeight + 20, scroll.AbsoluteSize.Y))
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvas)

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

        local function updateColor()
            btn.BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
        end

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButtonHover
            }):Play()
        end)

        btn.MouseLeave:Connect(function()
            updateColor()
        end)

        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = string.format("%s: %s", labelText, enabled and "ON" or "OFF")
            updateColor()
            if onToggle then
                task.spawn(function() onToggle(enabled) end)
            end
        end)

        return btn, function(state)
            enabled = state
            btn.Text = string.format("%s: %s", labelText, enabled and "ON" or "OFF")
            updateColor()
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
    -- VISUALS IMPLEMENTATION
    -------------------------------------------------------------
    local connections = {}
    local tracerUpdateConn : RBXScriptConnection? = nil
    local cameraProxy: Part? = nil

    local State = {
        TeamCheck = false,
        NameESP = false,
        BoxESP = false,
        HealthESP = false,
        DistanceESP = false,
        Tracers = false,
        Chams = false,
        Fullbright = false,
        Crosshair = false,
        NoFog = false
    }

    local PerPlayer = {}

    local crosshairGui : ScreenGui? = nil
    local function setCrosshair(enabled)
        if enabled then
            if not crosshairGui then
                crosshairGui = Instance.new("ScreenGui")
                crosshairGui.Name = "VIS_Crosshair"
                crosshairGui.ResetOnSpawn = false
                crosshairGui.IgnoreGuiInset = true
                crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 4, 0, 4)
                dot.Position = UDim2.new(0.5, -2, 0.5, -2)
                dot.BackgroundColor3 = Color3.fromRGB(0,255,120)
                dot.BorderSizePixel = 0
                dot.Parent = crosshairGui
            end
        elseif crosshairGui then
            crosshairGui:Destroy()
            crosshairGui = nil
        end
    end

    -------------------------------------------------------------
    -- Toggles (UI)
    -------------------------------------------------------------
    makeSection("ESP / Overlays")
    makeToggle("Name ESP", false, function(v) State.NameESP = v end)
    makeToggle("Box ESP", false, function(v) State.BoxESP = v end)
    makeToggle("Health ESP", false, function(v) State.HealthESP = v end)
    makeToggle("Distance ESP", false, function(v) State.DistanceESP = v end)
    makeToggle("Chams", false, function(v) State.Chams = v end)
    makeToggle("Tracers", false, function(v)
        State.Tracers = v
        if not v and tracerUpdateConn then tracerUpdateConn:Disconnect(); tracerUpdateConn = nil end
        if not v and cameraProxy then cameraProxy:Destroy(); cameraProxy = nil end
    end)
    makeToggle("Team Check", false, function(v) State.TeamCheck = v end)

    makeSection("Lighting / HUD")
    makeToggle("Fullbright", false, function(v)
        State.Fullbright = v
        Lighting.Ambient = v and Color3.new(1,1,1) or Color3.fromRGB(128,128,128)
        Lighting.Brightness = v and 2 or 1
    end)
    makeToggle("No Fog", false, function(v)
        State.NoFog = v
        Lighting.FogEnd = v and 1e6 or 1000
    end)
    makeToggle("Crosshair", false, function(v)
        State.Crosshair = v
        setCrosshair(v)
    end)

    -------------------------------------------------------------
    -- Return Frame
    -------------------------------------------------------------
    return frame
end
