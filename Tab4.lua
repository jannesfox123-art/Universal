-- Tab4.lua — Visuals Full Featured
return function(parent, settings)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local Lighting = game:GetService("Lighting")

    ----------------------------------------------------------------
    -- UI Setup
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

    local function makeToggle(text, default, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 340, 0, 42)
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

        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = settings.Theme.TabButtonHover end)
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
        lbl.Size = UDim2.new(0, 340, 0, 24)
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

    local activeESP = {}

    local function clearPlayerESP(plr)
        if activeESP[plr] then
            for _, d in ipairs(activeESP[plr]) do
                d:Remove()
            end
            activeESP[plr] = nil
        end
    end

    local function createDrawing(type, props)
        local obj = Drawing.new(type)
        for k, v in pairs(props) do
            obj[k] = v
        end
        return obj
    end

    local function updatePlayerESP(plr)
        clearPlayerESP(plr)
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
        if ESPEnabled.TeamCheck and plr.Team == LocalPlayer.Team then return end

        activeESP[plr] = {}
        local hrp = plr.Character.HumanoidRootPart
        local humanoid = plr.Character:FindFirstChild("Humanoid")
        local head = plr.Character:FindFirstChild("Head")

        local function step()
            if not plr.Character or not hrp or not Camera then return end
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if not onScreen then return end
            local footPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

            local objs = {}

            -- Name ESP (bei Füßen)
            if ESPEnabled.Name then
                table.insert(objs, createDrawing("Text", {
                    Text = plr.Name,
                    Position = Vector2.new(footPos.X, footPos.Y + 15),
                    Color = Color3.fromRGB(255, 255, 255),
                    Size = 14,
                    Center = true,
                    Outline = true,
                    Visible = true
                }))
            end

            -- Health ESP (Text)
            if ESPEnabled.Health and humanoid then
                table.insert(objs, createDrawing("Text", {
                    Text = "HP: " .. math.floor(humanoid.Health),
                    Position = Vector2.new(screenPos.X, screenPos.Y - 30),
                    Color = Color3.fromRGB(0, 255, 0),
                    Size = 14,
                    Center = true,
                    Outline = true,
                    Visible = true
                }))
            end

            -- Distance ESP
            if ESPEnabled.Distance then
                local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                table.insert(objs, createDrawing("Text", {
                    Text = string.format("%.1f m", dist),
                    Position = Vector2.new(screenPos.X, screenPos.Y - 45),
                    Color = Color3.fromRGB(0, 200, 255),
                    Size = 14,
                    Center = true,
                    Outline = true,
                    Visible = true
                }))
            end

            -- Box ESP (feste Größe)
            if ESPEnabled.Box and head then
                local height = 100
                local width = 50
                table.insert(objs, createDrawing("Square", {
                    Size = Vector2.new(width, height),
                    Position = Vector2.new(screenPos.X - width/2, screenPos.Y - height/2),
                    Color = Color3.fromRGB(255, 0, 0),
                    Thickness = 2,
                    Filled = false,
                    Visible = true
                }))
            end

            -- Tracers
            if ESPEnabled.Tracers then
                table.insert(objs, createDrawing("Line", {
                    From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y),
                    To = Vector2.new(footPos.X, footPos.Y),
                    Color = Color3.fromRGB(255, 255, 0),
                    Thickness = 1.5,
                    Visible = true
                }))
            end

            activeESP[plr] = objs
        end

        step()
    end

    local function updateAllESP()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                updatePlayerESP(plr)
            end
        end
    end

    Players.PlayerRemoving:Connect(clearPlayerESP)
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            updatePlayerESP(plr)
        end)
    end)

    RunService.RenderStepped:Connect(function()
        for plr, _ in pairs(activeESP) do
            updatePlayerESP(plr)
        end
    end)

    ----------------------------------------------------------------
    -- UI Toggles
    ----------------------------------------------------------------
    makeSection("ESP & Visuals")
    makeToggle("Name ESP", false, function(v) ESPEnabled.Name = v; updateAllESP() end)
    makeToggle("Box ESP", false, function(v) ESPEnabled.Box = v; updateAllESP() end)
    makeToggle("Health ESP (Text)", false, function(v) ESPEnabled.Health = v; updateAllESP() end)
    makeToggle("Distance ESP", false, function(v) ESPEnabled.Distance = v; updateAllESP() end)
    makeToggle("Tracers", false, function(v) ESPEnabled.Tracers = v; updateAllESP() end)
    makeToggle("Team Check", false, function(v) ESPEnabled.TeamCheck = v; updateAllESP() end)

    -- Optional: Chams, Fullbright, NoFog, Crosshair (Dummy-Implementierung)
    makeToggle("Chams", false, function(v) ESPEnabled.Chams = v end)
    makeToggle("Fullbright", false, function(v)
        ESPEnabled.Fullbright = v
        if v then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1,1,1)
        else
            Lighting.Brightness = 1
            Lighting.Ambient = Color3.new(0,0,0)
        end
    end)
    makeToggle("No Fog", false, function(v)
        ESPEnabled.NoFog = v
        if v then
            Lighting.FogEnd = 100000
        else
            Lighting.FogEnd = 1000
        end
    end)
    makeToggle("Crosshair", false, function(v) ESPEnabled.Crosshair = v end)

    return frame
end
