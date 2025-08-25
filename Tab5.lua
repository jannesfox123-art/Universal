return function(container)
    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local State = {
        LowGraphics = false,
        NoTextures = false,
        CustomSkybox = false,
        RemoveSky = false,
        AmbientBoost = false
    }

    local function createSkybox()
        local sky = Instance.new("Sky")
        sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
        sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
        sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
        sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
        sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
        sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
        sky.Parent = Lighting
    end

    local function removeSkybox()
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                obj:Destroy()
            end
        end
    end

    local function setLowGraphics(enabled)
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                obj.Material = enabled and Enum.Material.SmoothPlastic or Enum.Material.Plastic
            end
        end
        Lighting.GlobalShadows = not enabled
    end

    local function removeTextures(enabled)
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = enabled and 1 or 0
            end
        end
    end

    local function boostAmbient(enabled)
        if enabled then
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
        else
            Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
            Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
            Lighting.Brightness = 1
        end
    end

    -- UI Generator
    local function makeToggle(name, default, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 40)
        button.Position = UDim2.new(0, 5, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        button.TextColor3 = Color3.new(1,1,1)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 16
        button.Text = name .. ": " .. (default and "ON" or "OFF")
        button.AutoButtonColor = false
        button.Parent = container

        local state = default

        button.MouseButton1Click:Connect(function()
            state = not state
            button.Text = name .. ": " .. (state and "ON" or "OFF")
            callback(state)
        end)
    end

    -- Scrollable Area
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.Parent = container

    -- Toggles
    makeToggle("Low Graphics", false, function(v)
        State.LowGraphics = v
        setLowGraphics(v)
    end)

    makeToggle("No Textures", false, function(v)
        State.NoTextures = v
        removeTextures(v)
    end)

    makeToggle("Custom Skybox", false, function(v)
        State.CustomSkybox = v
        if v then createSkybox() else removeSkybox() end
    end)

    makeToggle("Remove Skybox", false, function(v)
        State.RemoveSky = v
        if v then removeSkybox() end
    end)

    makeToggle("Bright Ambient", false, function(v)
        State.AmbientBoost = v
        boostAmbient(v)
    end)
end
