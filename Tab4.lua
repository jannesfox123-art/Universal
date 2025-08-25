-- Tab4.lua — Visuals
-- Wird in dein Main Script integriert: return function(parent, settings) ... end

return function(parent, settings)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    ----------------------------------------------------------------
    -- UI Container
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

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    ----------------------------------------------------------------
    -- UI Elements: Toggle
    ----------------------------------------------------------------
    local function makeToggle(text, default, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 300, 0, 42) -- Breiter wie in Tab1
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Text = text .. ": " .. (default and "ON" or "OFF")
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
            btn.BackgroundColor3 = settings.Theme.TabButtonHover
        end)
        btn.MouseLeave:Connect(updateColor)
        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
            updateColor()
            if callback then callback(enabled) end
        end)

        return btn
    end

    local function makeSection(title)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 300, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = settings.Font
        lbl.TextSize = settings.TextSize
        lbl.Parent = scroll
    end

    ----------------------------------------------------------------
    -- Visuals Logic
    ----------------------------------------------------------------
    local ESPEnabled = {
        Name = false, Box = false, Health = false, Distance = false,
        Tracers = false, Chams = false, TeamCheck = false,
        Fullbright = false, NoFog = false, Crosshair = false
    }

    local espFolder = Instance.new("Folder")
    espFolder.Name = "VisualsESP"
    espFolder.Parent = CoreGui or game:GetService("CoreGui")

    local crosshairGui
    local function setCrosshair(state)
        if state and not crosshairGui then
            crosshairGui = Instance.new("ScreenGui")
            crosshairGui.Name = "Crosshair"
            crosshairGui.IgnoreGuiInset = true
            crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 4, 0, 4)
            dot.Position = UDim2.new(0.5, -2, 0.5, -2)
            dot.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
            dot.BorderSizePixel = 0
            dot.Parent = crosshairGui
        elseif not state and crosshairGui then
            crosshairGui:Destroy()
            crosshairGui = nil
        end
    end

    local function updateLighting()
        if ESPEnabled.Fullbright then
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
        else
            Lighting.Ambient = Color3.fromRGB(128, 128, 128)
            Lighting.Brightness = 1
        end

        Lighting.FogEnd = ESPEnabled.NoFog and 1e6 or 1000
    end

    ----------------------------------------------------------------
    -- ESP Update Loop
    ----------------------------------------------------------------
    local function drawESP()
        for _, obj in ipairs(espFolder:GetChildren()) do obj:Destroy() end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if ESPEnabled.TeamCheck and plr.Team == LocalPlayer.Team then
                    continue
                end

                local hrp = plr.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    if ESPEnabled.Name then
                        local nameLabel = Drawing.new("Text")
                        nameLabel.Text = plr.Name
                        nameLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 15)
                        nameLabel.Color = Color3.fromRGB(255, 255, 255)
                        nameLabel.Size = 14
                        nameLabel.Center = true
                        nameLabel.Outline = true
                        nameLabel.Visible = true
                    end
                    -- Weitere ESPs (Box, Health, Tracers etc.) hier analog
                end
            end
        end
    end

    RunService.RenderStepped:Connect(function()
        if ESPEnabled.Name or ESPEnabled.Box or ESPEnabled.Health or ESPEnabled.Distance or ESPEnabled.Tracers then
            drawESP()
        end
    end)

    ----------------------------------------------------------------
    -- UI Toggles
    ----------------------------------------------------------------
    makeSection("ESP & Visuals")
    makeToggle("Name ESP", false, function(v) ESPEnabled.Name = v end)
    makeToggle("Box ESP", false, function(v) ESPEnabled.Box = v end)
    makeToggle("Health ESP", false, function(v) ESPEnabled.Health = v end)
    makeToggle("Distance ESP", false, function(v) ESPEnabled.Distance = v end)
    makeToggle("Chams", false, function(v) ESPEnabled.Chams = v end)
    makeToggle("Tracers", false, function(v) ESPEnabled.Tracers = v end)
    makeToggle("Team Check", false, function(v) ESPEnabled.TeamCheck = v end)

    makeSection("Lighting & Extras")
    makeToggle("Fullbright", false, function(v) ESPEnabled.Fullbright = v; updateLighting() end)
    makeToggle("No Fog", false, function(v) ESPEnabled.NoFog = v; updateLighting() end)
    makeToggle("Crosshair", false, function(v) ESPEnabled.Crosshair = v; setCrosshair(v) end)

    return frame
end
