return function(parent, settings)
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")

    -- Scroll Frame für Inhalte
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

    local function createButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 45)
        btn.Text = text
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.TextColor3 = settings.Theme.TabText
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.AutoButtonColor = false
        btn.Parent = scrollingFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = settings.Theme.TabButtonHover
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = settings.Theme.TabButton
            }):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -----------------------------------------------------------------
    -- Features
    -----------------------------------------------------------------
    -- Gravity Control
    createButton("Toggle Low Gravity", function()
        Workspace.Gravity = (Workspace.Gravity == 196.2) and 50 or 196.2
    end)

    -- Time of Day
    createButton("Set Time: Midnight", function()
        Lighting.ClockTime = 0
    end)
    createButton("Set Time: Noon", function()
        Lighting.ClockTime = 12
    end)
    createButton("Set Time: Sunset", function()
        Lighting.ClockTime = 18
    end)

    -- Ambient Color Cycle
    createButton("Toggle Neon Ambient", function()
        if Lighting.Ambient == Color3.fromRGB(0, 0, 0) then
            Lighting.Ambient = Color3.fromRGB(255, 0, 150)
        else
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        end
    end)

    -- WalkSpeed / JumpPower Override
    createButton("Boost WalkSpeed", function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            hum.WalkSpeed = (hum.WalkSpeed == 16) and 50 or 16
        end
    end)
    createButton("Boost JumpPower", function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            hum.JumpPower = (hum.JumpPower == 50) and 150 or 50
        end
    end)

    -- NoClip
    local noclipEnabled = false
    createButton("Toggle NoClip", function()
        noclipEnabled = not noclipEnabled
    end)

    game:GetService("RunService").Stepped:Connect(function()
        if noclipEnabled and game.Players.LocalPlayer.Character then
            for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)

    -- Anchor World
    createButton("Anchor All Parts", function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Anchored then
                v.Anchored = true
            end
        end
    end)

    -- Reset World
    createButton("Reset Lighting & Gravity", function()
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.ClockTime = 14
        Workspace.Gravity = 196.2
    end)

    return scrollingFrame
end
