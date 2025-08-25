return function(parent, settings)
    -- Grundframe
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = parent

    -- Scrollbereich
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 800) -- Mehr Platz für viele Features
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scroll

    -- Utility Button-Funktion
    local function createButton(name, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 40)
        btn.Position = UDim2.new(0.05, 0, 0, 0)
        btn.Text = name
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.AutoButtonColor = false
        btn.Parent = scroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = settings.Theme.TabButtonHover
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = settings.Theme.TabButton
        end)
        btn.MouseButton1Click:Connect(callback)
    end

    -------------------------------------------------------------------
    -- TELEPORT FUNKTIONEN
    -------------------------------------------------------------------

    -- 1. Klick-Teleport mit Keybind
    local clickTPEnabled = false
    local clickTPKey = Enum.KeyCode.T
    createButton("Klick-Teleport (Toggle)", function()
        clickTPEnabled = not clickTPEnabled
    end)

    createButton("Keybind ändern (Standard: T)", function()
        clickTPKey = Enum.KeyCode.G -- Beispiel, später Keybind-System einbauen
    end)

    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and clickTPEnabled and input.KeyCode == clickTPKey then
            local mouse = game.Players.LocalPlayer:GetMouse()
            if mouse.Hit then
                game.Players.LocalPlayer.Character:MoveTo(mouse.Hit.p)
            end
        end
    end)

    -- 2. Save/Load Position
    local savedPosition
    createButton("Position speichern", function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            savedPosition = char.HumanoidRootPart.Position
        end
    end)

    createButton("Zu gespeicherter Position teleportieren", function()
        if savedPosition then
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(savedPosition)
            end
        end
    end)

    -- 3. Vorwärts-Teleport
    createButton("10 Meter nach vorne", function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)
        end
    end)

    -- 4. Random-Teleport in der Nähe
    createButton("Random-Teleport (10-30m)", function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local offset = Vector3.new(
                math.random(-30, 30),
                0,
                math.random(-30, 30)
            )
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + offset
        end
    end)

    -- 5. Waypoint-System
    local waypoints = {}
    createButton("Waypoint setzen", function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            table.insert(waypoints, char.HumanoidRootPart.Position)
        end
    end)

    createButton("Zu letztem Waypoint teleportieren", function()
        if #waypoints > 0 then
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(waypoints[#waypoints])
            end
        end
    end)

    return frame
end
