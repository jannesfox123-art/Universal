return function(parent, settings)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = parent

    -- ScrollFrame
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.Parent = frame

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 220, 0, 50)
    layout.CellPadding = UDim2.new(0, 15, 0, 15)
    layout.FillDirectionMaxCells = 2
    layout.Parent = scrollingFrame

    -- Funktion: Toggle Switch
    local function createSwitch(name, default, callback)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(0, 220, 0, 50)
        holder.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        holder.BorderSizePixel = 0

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = holder

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0.05, 0, 0, 0)
        label.Text = name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = settings.Font
        label.TextSize = settings.TextSize
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = holder

        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(0, 40, 0, 20)
        toggle.Position = UDim2.new(0.75, 0, 0.5, -10)
        toggle.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(80, 80, 80)
        toggle.BorderSizePixel = 0
        toggle.Parent = holder

        local corner2 = Instance.new("UICorner")
        corner2.CornerRadius = UDim.new(1, 0)
        corner2.Parent = toggle

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = default and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = toggle

        local corner3 = Instance.new("UICorner")
        corner3.CornerRadius = UDim.new(1, 0)
        corner3.Parent = knob

        local enabled = default
        holder.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                enabled = not enabled
                toggle.BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(80, 80, 80)
                knob:TweenPosition(enabled and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9), "Out", "Quad", 0.2, true)
                if callback then callback(enabled) end
            end
        end)

        return holder
    end

    -- Visual Features
    local toggles = {
        {"ESP", false, function(v) print("ESP:", v) end},
        {"Box ESP", false, function(v) print("Box ESP:", v) end},
        {"Name ESP", false, function(v) print("Name ESP:", v) end},
        {"Fullbright", false, function(v) print("Fullbright:", v) end},
        {"Night Vision", false, function(v) print("Night Vision:", v) end},
        {"Tracers", false, function(v) print("Tracers:", v) end},
        {"Chams", false, function(v) print("Chams:", v) end}
    }

    for _, data in ipairs(toggles) do
        createSwitch(data[1], data[2], data[3]).Parent = scrollingFrame
    end

    return frame
end
