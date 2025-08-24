return function(parent, settings)
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local player = game.Players.LocalPlayer
    local camera = workspace.CurrentCamera
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    player.CharacterAdded:Connect(function(char)
        character = char
        humanoid = char:WaitForChild("Humanoid")
    end)

    -- Tab Container
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Name = "LocalPlayerTab"
    frame.Parent = parent

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -40, 1, -40)
    container.Position = UDim2.new(0, 20, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = frame

    -- Toggle Button
    local function createToggle(label, yPos, default, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 240, 0, 40)
        button.Position = UDim2.new(0, 0, 0, yPos)
        button.Text = label .. (default and " [ON]" or " [OFF]")
        button.BackgroundColor3 = settings.Theme.TabButton
        button.TextColor3 = settings.Theme.TabText
        button.Font = settings.Font
        button.TextSize = settings.TextSize
        button.AutoButtonColor = false
        button.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        local state = default

        button.MouseButton1Click:Connect(function()
            state = not state
            button.Text = label .. (state and " [ON]" or " [OFF]")
            callback(state)
        end)

        return button
    end

    -- Slider
    local function createSlider(label, yPos, min, max, default, callback)
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0, 220, 0, 20)
        textLabel.Position = UDim2.new(0, 0, 0, yPos)
        textLabel.Text = label..": "..tostring(default)
        textLabel.Font = settings.Font
        textLabel.TextSize = settings.TextSize - 2
        textLabel.TextColor3 = settings.Theme.TabText
        textLabel.BackgroundTransparency = 1
        textLabel.Parent = container

        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(0, 240, 0, 8)
        slider.Position = UDim2.new(0, 0, 0, yPos + 25)
        slider.BackgroundColor3 = settings.Theme.TabButton
        slider.Parent = container

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = settings.Theme.TabButtonActive
        fill.Parent = slider

        local dragging = false
        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                local value = math.floor(min + (max - min) * pos)
                textLabel.Text = label..": "..tostring(value)
                callback(value)
            end
        end)

        return slider
    end

    -- STATES
    local flyEnabled = false
    local noclipEnabled = false
    local infiniteJumpEnabled = false

    -- FUNCTIONS
    local function toggleFly(enabled)
        flyEnabled = enabled
        if flyEnabled then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
            bodyVel.Velocity = Vector3.new()
            bodyVel.Parent = character:WaitForChild("HumanoidRootPart")

            RunService.RenderStepped:Connect(function()
                if not flyEnabled then
                    bodyVel:Destroy()
                    return
                end
                bodyVel.Velocity = humanoid.MoveDirection * 50
            end)
        end
    end

    local function toggleNoclip(enabled)
        noclipEnabled = enabled
    end

    RunService.Stepped:Connect(function()
        if noclipEnabled and character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)

    UserInputService.JumpRequest:Connect(function()
        if infiniteJumpEnabled and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    -- BUTTONS & SLIDERS
    local y = 0
    createToggle("Fly", y, false, toggleFly) y = y + 50
    createToggle("Noclip", y, false, toggleNoclip) y = y + 50
    createToggle("Infinite Jump", y, false, function(state) infiniteJumpEnabled = state end) y = y + 50

    createSlider("Speed", y, 16, 200, humanoid.WalkSpeed, function(val)
        humanoid.WalkSpeed = val
    end) y = y + 60

    createSlider("Jump Power", y, 50, 300, humanoid.JumpPower, function(val)
        humanoid.JumpPower = val
    end) y = y + 60

    createSlider("Gravity", y, 10, 196.2, workspace.Gravity, function(val)
        workspace.Gravity = val
    end) y = y + 60

    createSlider("FOV", y, 50, 120, camera.FieldOfView, function(val)
        camera.FieldOfView = val
    end) y = y + 60

    createToggle("Sit/Stand", y, false, function()
        humanoid.Sit = not humanoid.Sit
    end) y = y + 50

    createToggle("Respawn", y, false, function()
        player:LoadCharacter()
    end) y = y + 50

    createToggle("Reset All", y, false, function()
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        workspace.Gravity = 196.2
        camera.FieldOfView = 70
        flyEnabled = false
        noclipEnabled = false
        infiniteJumpEnabled = false
    end)

    return frame
end
