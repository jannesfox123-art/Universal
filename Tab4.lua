return function(container, settings)
    -- Scrollbarer Bereich
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 1000)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1
    scroll.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = scroll

    -- Hilfsfunktion: Toggle-Button erstellen
    local function createToggle(name, state, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 300, 0, 40)
        btn.Text = name .. ": " .. (state and "ON" or "OFF")
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
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = name .. ": " .. (state and "ON" or "OFF")
            callback(state)
        end)
    end

    -- ESP Variables
    local espEnabled = false
    local boxESPEnabled = false
    local nameESPEnabled = false

    -- ESP Functions
    local function toggleESP(state)
        espEnabled = state
        -- Dein ESP-Code hier aktivieren/deaktivieren
        print("ESP:", state)
    end

    local function toggleBoxESP(state)
        boxESPEnabled = state
        -- Boxen um Spieler zeichnen
        print("Box ESP:", state)
    end

    local function toggleNameESP(state)
        nameESPEnabled = state
        -- Namensanzeige aktivieren
        print("Name ESP:", state)
    end

    -- Features
    createToggle("ESP", espEnabled, toggleESP)
    createToggle("Box ESP", boxESPEnabled, toggleBoxESP)
    createToggle("Name ESP", nameESPEnabled, toggleNameESP)

    createToggle("Fullbright", false, function(state)
        if state then
            game.Lighting.Brightness = 2
            game.Lighting.Ambient = Color3.new(1, 1, 1)
        else
            game.Lighting.Brightness = 1
            game.Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        end
    end)

    createToggle("Night Vision", false, function(state)
        if state then
            game.Lighting.Brightness = 0.3
            game.Lighting.Ambient = Color3.new(0, 1, 0)
        else
            game.Lighting.Brightness = 1
            game.Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        end
    end)

    createToggle("Tracers", false, function(state)
        -- Linie vom Bildschirm zum Spieler
        print("Tracers:", state)
    end)

    createToggle("Chams", false, function(state)
        -- Spieler durch Wände sichtbar machen (requires Highlight API)
        print("Chams:", state)
    end)
end
