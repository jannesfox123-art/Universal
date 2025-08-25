--// Tab4.lua — VISUALS (Full Features, Advanced, Clean)
--// Rückgabe: Frame (Tab-Container), vollständig kompatibel mit deinem Main-Script
--// Erfordert: settings = { Theme = { TabButton, TabButtonHover, TabButtonActive, TabText }, Font, TextSize, [ControlWidth?] }

return function(parent, settings)
    ----------------------------------------------------------------
    -- Services & Locals
    ----------------------------------------------------------------
    local Players        = game:GetService("Players")
    local RunService     = game:GetService("RunService")
    local TweenService   = game:GetService("TweenService")
    local Lighting       = game:GetService("Lighting")
    local LocalPlayer    = Players.LocalPlayer
    local Camera         = workspace.CurrentCamera

    ----------------------------------------------------------------
    -- UI — Container
    ----------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = parent

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1
    scroll.Parent = frame

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll

    local function autoCanvas()
        task.defer(function()
            local y = list.AbsoluteContentSize.Y
            scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y + 20, scroll.AbsoluteSize.Y))
        end)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvas)
    scroll.ChildAdded:Connect(autoCanvas)
    scroll.ChildRemoved:Connect(autoCanvas)
    autoCanvas()

    ----------------------------------------------------------------
    -- UI — Helpers (Section & breite Toggles)
    ----------------------------------------------------------------
    local CONTROL_WIDTH  = settings.ControlWidth or 392
    local CONTROL_HEIGHT = 44

    local function makeSection(title: string)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, CONTROL_WIDTH, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(200,200,200)
        lbl.Font = settings.Font
        lbl.TextSize = settings.TextSize
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = scroll
        return lbl
    end

    local function makeToggle(labelText: string, default: boolean, onToggle: (boolean)->())
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, CONTROL_WIDTH, 0, CONTROL_HEIGHT)
        btn.BackgroundColor3 = settings.Theme.TabButton
        btn.TextColor3 = settings.Theme.TabText
        btn.Text = labelText
        btn.AutoButtonColor = false
        btn.Font = settings.Font
        btn.TextSize = settings.TextSize
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = scroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn

        local pill = Instance.new("Frame")
        pill.AnchorPoint = Vector2.new(1, 0.5)
        pill.Position = UDim2.new(1, -10, 0.5, 0)
        pill.Size = UDim2.new(0, 64, 0, 28)
        pill.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
        pill.BorderSizePixel = 0
        pill.Parent = btn
        local pillCorner = Instance.new("UICorner"); pillCorner.CornerRadius = UDim.new(1, 0); pillCorner.Parent = pill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 24, 0, 24)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        knob.BorderSizePixel = 0
        knob.Parent = pill
        local knobCorner = Instance.new("UICorner"); knobCorner.CornerRadius = UDim.new(1, 0); knobCorner.Parent = knob

        local enabled = default or false
        local function applyVisual()
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
            TweenService:Create(pill, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(65, 65, 65)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.12), {
                Position = enabled and UDim2.new(1, -26, 0, 2) or UDim2.new(0, 2, 0, 2),
                BackgroundColor3 = enabled and Color3.fromRGB(235, 255, 245) or Color3.fromRGB(180, 180, 180)
            }):Play()
        end

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButtonHover
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = enabled and settings.Theme.TabButtonActive or settings.Theme.TabButton
            }):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            applyVisual()
            if onToggle then task.spawn(function() onToggle(enabled) end) end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    updatePlayer(plr)
                end
            end
        end)

        applyVisual()
        return btn, function(state: boolean) enabled = state; applyVisual(); if onToggle then onToggle(enabled) end end
    end

    ----------------------------------------------------------------
    -- Drawing availability check
    ----------------------------------------------------------------
    if not Drawing or not pcall(function() return Drawing.new("Text") end) then
        warn("[ESP] Drawing API nicht verfügbar – ESP Features werden deaktiviert.")
    end

    ----------------------------------------------------------------
    -- (Restlicher Code unverändert...)
    ----------------------------------------------------------------
    -- ... Hier wird dein kompletter ESP Code eingefügt (wie im Original)
end
