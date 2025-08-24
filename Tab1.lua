return function(parent, settings)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    -- Flags
    local flyEnabled = false
    local noclipEnabled = false
    local infiniteJumpEnabled = false
    local flySpeed = 50
    local walkSpeed = 16
    local jumpPower = 50

    -- Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Name = "LocalPlayerTab"
    frame.Parent = parent

    -- Container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -30, 1, -30)
    container.Position = UDim2.new(0, 15, 0, 15)
    container.BackgroundTransparency = 1
    container.Parent = frame

    -- UIListLayout für automatische Anordnung
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = container

    -- Helper: Button
    local function createToggle(name, default, callback)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 220, 0, 40)
        toggle.BackgroundColor3 = settings.Theme.TabButton
        toggle.TextColor3 = settings.Theme.TabText
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 16
        toggle.Text = name .. ": " .. (default and "ON" or "OFF")
        toggle.AutoButtonColor = false
        toggle.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = toggle

        local state = default

        local function updateVisual()
            toggle.Text = name .. ": " .. (state and "ON" or "OFF")
            TweenService:Create(toggle, TweenInfo.new(0.15), {
                BackgroundColor3 = state and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
        end

        toggle.MouseButton1Click:Connect(function()
            state = not state
            updateVisual()
            callback(state)
        end)

        updateVisual()
    end

    -- Helper: Slider
    local function createSlider(name, min, max, default, callback)
        local frameSlider = Instance.new("Frame")
        frameSlider.Size = UDim2.new(0, 220, 0, 50)
        frameSlider.BackgroundTransparency = 1
        frameSlider.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = name .. ": " .. default
        label.TextColor3 = settings.Theme.TabText
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.Parent = frameSlider

        local sliderBar = Instance.new("Frame")
        sliderBar.Size = UDim2.new(1, 0, 0, 8)
        sliderBar.Position = UDim2.new(0, 0, 0, 30)
        sliderBar.BackgroundColor3 = settings.Theme.TabButton
        sliderBar.BorderSizePixel = 0
        sliderBar.Parent = frameSlider

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
        knob.BackgroundColor3 = settings.Theme.TabButtonActive
        knob.BorderSizePixel = 0
        knob.Parent = sliderBar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = knob

        local dragging = false
        local value = default

        knob.InputBegan:Connect(function(input)
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
                local relativeX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * relativeX)
                knob.Position = UDim2.new(relativeX, -8, 0.5, -8)
                label.Text = name .. ": " .. value
                callback(value)
            end
        end)

        callback(default)
    end

    -- Toggles
    createToggle("Fly", false, function(state)
        flyEnabled = state
        if flyEnabled then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            bodyVelocity.Velocity = Vector3.zero
            bodyVelocity.Parent = humanoid.RootPart

            RunService.RenderStepped:Connect(function()
                if not flyEnabled then return end
                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= workspace.CurrentCamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= workspace.CurrentCamera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += workspace.CurrentCamera.CFrame.RightVector end
                bodyVelocity.Velocity = moveDir * flySpeed
            end)
        else
            if humanoid.RootPart:FindFirstChildOfClass("BodyVelocity") then
                humanoid.RootPart:FindFirstChildOfClass("BodyVelocity"):Destroy()
            end
        end
    end)

    createToggle("Noclip", false, function(state)
        noclipEnabled = state
        RunService.Stepped:Connect(function()
            if noclipEnabled and player.Character then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end)

    createToggle("Infinite Jump", false, function(state)
        infiniteJumpEnabled = state
        if infiniteJumpEnabled then
            UserInputService.JumpRequest:Connect(function()
                if infiniteJumpEnabled and humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end)

    -- Sliders
    createSlider("WalkSpeed", 16, 300, 16, function(value)
        humanoid.WalkSpeed = value
    end)

    createSlider("JumpPower", 50, 300, 50, function(value)
        humanoid.JumpPower = value
    end)

    createSlider("Fly Speed", 20, 200, 50, function(value)
        flySpeed = value
    end)

    return frame
end
