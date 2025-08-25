return function(parent, settings)
    -- Container für Visuals Tab
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = parent

    -- Scrollbar
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollingFrame

    -- Helper für Toggle Switch
    local function createToggle(name, default, callback)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 250, 0, 40)
        toggle.BackgroundColor3 = settings.Theme.TabButton
        toggle.TextColor3 = settings.Theme.TabText
        toggle.Text = name .. ": OFF"
        toggle.Font = settings.Font
        toggle.TextSize = settings.TextSize
        toggle.AutoButtonColor = false
        toggle.LayoutOrder = 1

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = toggle

        local enabled = default
        toggle.Text = name .. (enabled and ": ON" or ": OFF")

        toggle.MouseButton1Click:Connect(function()
            enabled = not enabled
            toggle.Text = name .. (enabled and ": ON" or ": OFF")
            TweenService:Create(toggle, TweenInfo.new(0.2), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
            if callback then callback(enabled) end
        end)

        return toggle
    end

    -- Funktionen: ESP, Tracers, Box, Chams, Crosshair, FOV
    local espEnabled = false
    local tracersEnabled = false
    local boxEnabled = false
    local chamsEnabled = false
    local crosshairEnabled = false
    local fovCircleEnabled = false
    local fovCircle = nil

    local function toggleESP(state)
        espEnabled = state
        -- Hier käme dein ESP Script oder Integration
    end

    local function toggleTracers(state)
        tracersEnabled = state
        -- Tracer Lines
    end

    local function toggleBox(state)
        boxEnabled = state
        -- Box Drawing
    end

    local function toggleChams(state)
        chamsEnabled = state
        -- Chams Material
    end

    local function toggleCrosshair(state)
        crosshairEnabled = state
        if state then
            if not fovCircle then
                fovCircle = Drawing.new("Circle")
                fovCircle.Thickness = 2
                fovCircle.NumSides = 64
                fovCircle.Radius = 50
                fovCircle.Color = Color3.fromRGB(0, 255, 0)
                fovCircle.Filled = false
                fovCircle.Visible = true
            end
        else
            if fovCircle then
                fovCircle:Remove()
                fovCircle = nil
            end
        end
    end

    local function toggleFOVCircle(state)
        fovCircleEnabled = state
        -- Ähnliche Logik wie beim Crosshair
    end

    -- Toggles hinzufügen
    local t1 = createToggle("ESP", false, toggleESP)
    t1.Parent = scrollingFrame

    local t2 = createToggle("Tracers", false, toggleTracers)
    t2.Parent = scrollingFrame

    local t3 = createToggle("Box", false, toggleBox)
    t3.Parent = scrollingFrame

    local t4 = createToggle("Chams", false, toggleChams)
    t4.Parent = scrollingFrame

    local t5 = createToggle("Crosshair", false, toggleCrosshair)
    t5.Parent = scrollingFrame

    local t6 = createToggle("FOV Circle", false, toggleFOVCircle)
    t6.Parent = scrollingFrame

    return frame
end
