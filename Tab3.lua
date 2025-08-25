return function(container, settings)
    -- Scrollbarer Bereich
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1
    scroll.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = scroll

    -- Hilfsfunktion: Button erstellen
    local function createButton(name, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 300, 0, 40)
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

    -- Beispiel-Features für Teleport
    createButton("Spawn", function()
        game.Players.LocalPlayer.Character:MoveTo(Vector3.new(0, 5, 0))
    end)

    createButton("Random High Point", function()
        game.Players.LocalPlayer.Character:MoveTo(Vector3.new(math.random(-200, 200), 200, math.random(-200, 200)))
    end)

    createButton("Teleport to Mouse", function()
        local mouse = game.Players.LocalPlayer:GetMouse()
        game.Players.LocalPlayer.Character:MoveTo(mouse.Hit.p)
    end)

    createButton("Bring to Friend", function()
        local target = game.Players:FindFirstChild("FriendName") -- ändern!
        if target and target.Character then
            game.Players.LocalPlayer.Character:MoveTo(target.Character.HumanoidRootPart.Position)
        end
    end)
end
