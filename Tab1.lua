return function(parent, settings)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    -- TAB FRAME
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Name = "LocalPlayerTab"
    frame.Parent = parent

    local y = 20
    local elements = {}

    -- UTILITY: Create Toggle Button
    local function createToggle(text, default, callback)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 200, 0, 40)
        toggle.Position = UDim2.new(0, 20, 0, y)
        toggle.BackgroundColor3 = settings.Theme.TabButton
        toggle.Font = settings.Font
        toggle.TextSize = settings.TextSize
        toggle.TextColor3 = settings.Theme.TabText
        toggle.Text = text .. ": " .. (default and "ON" or "OFF")
        toggle.Parent = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = toggle

        local state = default

        toggle.MouseButton1Click:Connect(function()
            state = not state
            toggle.Text = text .. ": " .. (state and "ON" or "OFF")

            -- Animation
            TweenService:Create(toggle, TweenInfo.new(0.25), {
                BackgroundColor3 = state and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()

            callback(state)
        end)

        y = y + 50
        table.insert(elements, toggle)
        return toggle
    end

    -- UTILITY: Create Slider
    local function createSlider(text, min, max, default, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 200, 0, 40)
        container.Position = UDim2.new(0, 20, 0, y)
        container.BackgroundTransparency = 1
        container.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = settings.Font
        label.TextSize = settings.TextSize
        label.TextColor3 = settings.Theme.TabText
        label.Text = text .. ": " .. tostring(default)
        label.Parent = container

        local slider = Instance.new("TextButton")
        slider.Size = UDim2.new(1, 0, 0, 6)
        slider.Position = UDim2.new(0, 0, 1, -6)
        slider.BackgroundColor3 = settings.Theme.TabButton
        slider.Text = ""
        slider.Parent = container

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = settings.Theme.TabButtonActive
        fill.Parent = slider

        local dragging = false
        slider.MouseButton1Down:Connect(function()
            dragging = true
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local relativeX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * relativeX)
                fill.Size = UDim2.new(relativeX, 0, 1, 0)
                label.Text = text .. ": " .. tostring(value)
                callback(value)
            end
        end)

        y = y + 60
        table.insert(elements, container)
        return container
    end

    -- ========== TOGGLES ==========
    -- Fly
    local flyConnection
    createToggle("Fly", false, function(enabled)
        if enabled then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            bodyVelocity.Parent = character:WaitForChild("HumanoidRootPart")
            flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local moveDir = player:GetMouse().KeyDown and player:GetMouse().KeyDown.W and Vector3.new(0, 1, 0) or Vector3.new()
                bodyVelocity.Velocity = (workspace.CurrentCamera.CFrame.LookVector * 50) * (player:GetMouse().KeyDown and 1 or 0)
            end)
        else
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            if character:FindFirstChild("HumanoidRootPart"):FindFirstChild("BodyVelocity") then
                character.HumanoidRootPart.BodyVelocity:Destroy()
            end
        end
    end)

    -- Noclip
    local noclipConnection
    createToggle("Noclip", false, function(enabled)
        if enabled then
            noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)

    -- Infinite Jump
    local infiniteJumpEnabled = false
    createToggle("Infinite Jump", false, function(state)
        infiniteJumpEnabled = state
    end)
    UserInputService.JumpRequest:Connect(function()
        if infiniteJumpEnabled and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    -- ========== SLIDERS ==========
    createSlider("WalkSpeed", 16, 200, humanoid.WalkSpeed, function(val)
        humanoid.WalkSpeed = val
    end)

    createSlider("JumpPower", 50, 300, humanoid.JumpPower, function(val)
        humanoid.JumpPower = val
    end)

    createSlider("Gravity", 0, 196, workspace.Gravity, function(val)
        workspace.Gravity = val
    end)

    createSlider("FOV", 70, 120, workspace.CurrentCamera.FieldOfView, function(val)
        workspace.CurrentCamera.FieldOfView = val
    end)

    -- Sit / Stand
    createToggle("Sit/Stand", false, function(state)
        humanoid.Sit = state
    end)

    -- Reset Character
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0, 200, 0, 40)
    resetBtn.Position = UDim2.new(0, 20, 0, y)
    resetBtn.BackgroundColor3 = settings.Theme.TabButton
    resetBtn.Font = settings.Font
    resetBtn.TextSize = settings.TextSize
    resetBtn.TextColor3 = settings.Theme.TabText
    resetBtn.Text = "Reset Character"
    resetBtn.Parent = frame
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 8)
    resetCorner.Parent = resetBtn
    resetBtn.MouseButton1Click:Connect(function()
        character:BreakJoints()
    end)

    return frame
end
