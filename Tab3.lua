-- Tab3.lua (Teleport Tab Vollversion)
return function(parent, settings)
    local player = game.Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local mouse = player:GetMouse()

    -- GUI Basis
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = parent

    local scrolling = Instance.new("ScrollingFrame")
    scrolling.Size = UDim2.new(1, 0, 1, 0)
    scrolling.CanvasSize = UDim2.new(0, 0, 0, 1500)
    scrolling.ScrollBarThickness = 8
    scrolling.BackgroundTransparency = 1
    scrolling.Parent = tabFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrolling

    -- Variablen
    local lastPos = nil
    local savedLocations = {}
    local teleportHistory = {}
    local clickTPEnabled = false
    local clickTPKey = Enum.KeyCode.T
    local followTarget = nil
    local followConnection = nil
    local loopTeleporting = false

    -- Button Builder
    local function createButton(text, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 40)
        button.Text = text
        button.Font = settings.Font
        button.TextSize = settings.TextSize
        button.BackgroundColor3 = settings.Theme.TabButton
        button.TextColor3 = settings.Theme.TabText
        button.AutoButtonColor = false
        button.Parent = scrolling

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        button.MouseButton1Click:Connect(callback)
        button.MouseEnter:Connect(function() button.BackgroundColor3 = settings.Theme.TabButtonHover end)
        button.MouseLeave:Connect(function() button.BackgroundColor3 = settings.Theme.TabButton end)

        return button
    end

    -- Teleport Funktion
    local function teleportTo(pos)
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            lastPos = player.Character.HumanoidRootPart.Position
            table.insert(teleportHistory, lastPos)
            player.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end

    -- Standardpunkte
    local teleportPoints = {
        ["Spawn"] = Vector3.new(0, 5, 0),
        ["Berg"] = Vector3.new(100, 200, -50),
        ["Geheime Höhle"] = Vector3.new(-250, 20, 300)
    }

    for name, pos in pairs(teleportPoints) do
        createButton("Teleport zu: " .. name, function()
            teleportTo(pos)
        end)
    end

    createButton("Zurück zur letzten Position", function()
        if lastPos then teleportTo(lastPos) end
    end)

    -- Spieler Teleport
    local playerDropdown = Instance.new("TextBox")
    playerDropdown.Size = UDim2.new(1, -20, 0, 40)
    playerDropdown.PlaceholderText = "Spielername eingeben & Enter"
    playerDropdown.Font = settings.Font
    playerDropdown.TextSize = settings.TextSize
    playerDropdown.BackgroundColor3 = settings.Theme.TabButton
    playerDropdown.TextColor3 = settings.Theme.TabText
    playerDropdown.Parent = scrolling
    Instance.new("UICorner", playerDropdown).CornerRadius = UDim.new(0, 8)

    playerDropdown.FocusLost:Connect(function(enter)
        if enter and playerDropdown.Text ~= "" then
            local target = game.Players:FindFirstChild(playerDropdown.Text)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                teleportTo(target.Character.HumanoidRootPart.Position)
            end
        end
    end)

    -- Save Location
    local saveBox = Instance.new("TextBox")
    saveBox.Size = UDim2.new(1, -20, 0, 40)
    saveBox.PlaceholderText = "Name für Position speichern"
    saveBox.Font = settings.Font
    saveBox.TextSize = settings.TextSize
    saveBox.BackgroundColor3 = settings.Theme.TabButton
    saveBox.TextColor3 = settings.Theme.TabText
    saveBox.Parent = scrolling
    Instance.new("UICorner", saveBox).CornerRadius = UDim.new(0, 8)

    createButton("Position Speichern", function()
        if saveBox.Text ~= "" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedLocations[saveBox.Text] = player.Character.HumanoidRootPart.Position
        end
    end)

    createButton("Gespeicherte Orte anzeigen", function()
        for name, pos in pairs(savedLocations) do
            createButton("Teleport zu: " .. name, function()
                teleportTo(pos)
            end)
        end
    end)

    -- Random Teleport
    createButton("Zufälliger Teleport", function()
        teleportTo(Vector3.new(math.random(-500, 500), 50, math.random(-500, 500)))
    end)

    -- Auto-Follow
    createButton("Auto-Follow starten", function()
        if followConnection then followConnection:Disconnect() end
        local targetName = playerDropdown.Text
        local target = game.Players:FindFirstChild(targetName)
        if target then
            followConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and player.Character then
                    teleportTo(target.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0))
                end
            end)
        end
    end)

    createButton("Auto-Follow stoppen", function()
        if followConnection then followConnection:Disconnect() end
    end)

    -- Loop Teleport
    createButton("Loop Teleport (5 Sek.)", function()
        loopTeleporting = not loopTeleporting
        if loopTeleporting then
            spawn(function()
                while loopTeleporting do
                    teleportTo(Vector3.new(0, 10, 0))
                    task.wait(5)
                end
            end)
        end
    end)

    -- Click TP
    local clickTPButton = createButton("Click TP: Aus (Key: T)", function()
        clickTPEnabled = not clickTPEnabled
        clickTPButton.Text = clickTPEnabled and ("Click TP: An (Key: " .. clickTPKey.Name .. ")") or ("Click TP: Aus (Key: " .. clickTPKey.Name .. ")")
    end)

    local keybindBox = Instance.new("TextBox")
    keybindBox.Size = UDim2.new(1, -20, 0, 40)
    keybindBox.PlaceholderText = "Click TP Key ändern"
    keybindBox.Font = settings.Font
    keybindBox.TextSize = settings.TextSize
    keybindBox.BackgroundColor3 = settings.Theme.TabButton
    keybindBox.TextColor3 = settings.Theme.TabText
    keybindBox.Parent = scrolling
    Instance.new("UICorner", keybindBox).CornerRadius = UDim.new(0, 8)

    keybindBox.FocusLost:Connect(function(enter)
        if enter and keybindBox.Text ~= "" then
            local newKey = Enum.KeyCode[keybindBox.Text:upper()]
            if newKey then
                clickTPKey = newKey
                clickTPButton.Text = clickTPEnabled and ("Click TP: An (Key: " .. clickTPKey.Name .. ")") or ("Click TP: Aus (Key: " .. clickTPKey.Name .. ")")
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and clickTPEnabled and input.KeyCode == clickTPKey then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                teleportTo(mouse.Hit.Position)
            end
        end
    end)

    return tabFrame
end
