return function(parent, settings)
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollingFrame

    ---------------------------------------------------------
    -- Modern Toggle Button
    ---------------------------------------------------------
    local function createToggle(name, default, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 40)
        container.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        container.Parent = scrollingFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = settings.Font
        label.TextSize = settings.TextSize
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = name
        label.Parent = container

        -- Toggle Switch
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0.2, 0, 0.6, 0)
        toggleBtn.Position = UDim2.new(0.75, 0, 0.2, 0)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        toggleBtn.Text = ""
        toggleBtn.Parent = container

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(1, 0)
        toggleCorner.Parent = toggleBtn

        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0.5, 0, 1, 0)
        circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        circle.Parent = toggleBtn

        local circleCorner = Instance.new("UICorner")
        circleCorner.CornerRadius = UDim.new(1, 0)
        circleCorner.Parent = circle

        local state = default

        local function updateToggle()
            if state then
                TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 200, 100)}):Play()
                TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0, 0)}):Play()
            else
                TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
                TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 0, 0, 0)}):Play()
            end
            callback(state)
        end

        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            updateToggle()
        end)

        updateToggle()
    end

    ---------------------------------------------------------
    -- Features
    ---------------------------------------------------------

    createToggle("Ultra FPS Boost", false, function(enabled)
        if enabled then
            -- Alles reduzieren
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e6
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Part") or obj:IsA("UnionOperation") then
                    obj.Material = Enum.Material.SmoothPlastic
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                end
            end
            if Terrain then Terrain.WaterTransparency = 1 end
        else
            -- Reset only basics
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 1000
        end
    end)

    createToggle("Low Graphics", false, function(enabled)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Part") then
                obj.Material = enabled and Enum.Material.SmoothPlastic or Enum.Material.Plastic
            end
        end
    end)

    createToggle("No Textures", false, function(enabled)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = enabled and 1 or 0
            end
        end
    end)

    createToggle("Remove Skybox", false, function(enabled)
        if enabled then
            for _, sky in ipairs(Lighting:GetChildren()) do
                if sky:IsA("Sky") then
                    sky.Parent = nil
                end
            end
        else
            local sky = Instance.new("Sky")
            sky.SkyboxBk = "rbxassetid://insert_default"
            sky.SkyboxDn = "rbxassetid://insert_default"
            sky.SkyboxFt = "rbxassetid://insert_default"
            sky.SkyboxLf = "rbxassetid://insert_default"
            sky.SkyboxRt = "rbxassetid://insert_default"
            sky.SkyboxUp = "rbxassetid://insert_default"
            sky.Parent = Lighting
        end
    end)

    createToggle("Disable Shadows", false, function(enabled)
        Lighting.GlobalShadows = not enabled
    end)

    createToggle("Disable Fog", false, function(enabled)
        Lighting.FogEnd = enabled and 1e6 or 1000
    end)

    createToggle("Remove Particles", false, function(enabled)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = not enabled
            end
        end
    end)

    createToggle("Disable Post Processing", false, function(enabled)
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("BlurEffect") or effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = not enabled
            end
        end
    end)

    return scrollingFrame
end
