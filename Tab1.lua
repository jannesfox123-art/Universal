return function(parent, settings)
    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    -- Character refs (werden bei Respawn aktualisiert)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    -- ==== UI ROOT ====
    local frame = Instance.new("Frame")
    frame.Name = "LocalPlayerTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    -- Scrollbarer Container
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -40, 1, -40)
    scroll.Position = UDim2.new(0, 20, 0, 20)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 6
    scroll.Parent = frame

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll

    local function updateCanvas()
        scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
    end
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

    -- ==== THEME HELPERS ====
    local THEME = settings.Theme or {
        TabButton = Color3.fromRGB(50,50,50),
        TabButtonHover = Color3.fromRGB(70,70,70),
        TabButtonActive = Color3.fromRGB(100,100,100),
        TabText = Color3.fromRGB(255,255,255),
        Content = Color3.fromRGB(22,22,22)
    }
    local FONT = settings.Font or Enum.Font.GothamBold
    local TEXT_SIZE = settings.TextSize or 16

    -- ==== COMPONENTS ====
    local function makeLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = FONT
        lbl.TextSize = TEXT_SIZE
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextColor3 = THEME.TabText
        lbl.Parent = scroll
        return lbl
    end

    local function makeToggle(title, default, onChange)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 40)
        row.BackgroundColor3 = THEME.TabButton
        row.BorderSizePixel = 0
        row.Parent = scroll
        local rowCorner = Instance.new("UICorner", row); rowCorner.CornerRadius = UDim.new(0, 8)

        row.MouseEnter:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = THEME.TabButtonHover}):Play()
        end)
        row.MouseLeave:Connect(function()
            local target = (row:GetAttribute("state") and THEME.TabButtonActive) or THEME.TabButton
            TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = target}):Play()
        end)

        local lbl = Instance.new("TextLabel")
        lbl.AnchorPoint = Vector2.new(0, 0.5)
        lbl.Position = UDim2.new(0, 12, 0.5, 0)
        lbl.Size = UDim2.new(1, -140, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.Font = FONT
        lbl.TextSize = TEXT_SIZE
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextColor3 = THEME.TabText
        lbl.Parent = row

        local switch = Instance.new("Frame")
        switch.AnchorPoint = Vector2.new(1, 0.5)
        switch.Position = UDim2.new(1, -12, 0.5, 0)
        switch.Size = UDim2.new(0, 56, 0, 26)
        switch.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        switch.Parent = row
        local swCorner = Instance.new("UICorner", switch); swCorner.CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 22, 0, 22)
        knob.Position = UDim2.new(0, 2, 0.5, -11)
        knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        knob.Parent = switch
        local knobCorner = Instance.new("UICorner", knob); knobCorner.CornerRadius = UDim.new(1, 0)

        local state = false
        local function setState(v, animate)
            state = v
            row:SetAttribute("state", v)
            local bg = v and THEME.TabButtonActive or THEME.TabButton
            local swColor = v and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(90, 90, 90)
            local x = v and (56 - 24) or 2
            if animate then
                TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = bg}):Play()
                TweenService:Create(switch, TweenInfo.new(0.15), {BackgroundColor3 = swColor}):Play()
                TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, x, 0.5, -11)}):Play()
            else
                row.BackgroundColor3 = bg
                switch.BackgroundColor3 = swColor
                knob.Position = UDim2.new(0, x, 0.5, -11)
            end
            if onChange then
                task.spawn(onChange, v)
            end
        end

        local function hookClickable(gui)
            gui.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setState(not state, true)
                end
            end)
        end
        hookClickable(row); hookClickable(switch); hookClickable(knob)

        setState(default, false)
        return {
            Set = function(v) setState(v, true) end,
            Get = function() return state end,
            Row = row
        }
    end

    local function makeSlider(title, min, max, default, onChange)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -10, 0, 58)
        container.BackgroundColor3 = THEME.TabButton
        container.BorderSizePixel = 0
        container.Parent = scroll
        local cCorner = Instance.new("UICorner", container); cCorner.CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -16, 0, 24)
        lbl.Position = UDim2.new(0, 8, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text = string.format("%s: %s", title, tostring(default))
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = FONT
        lbl.TextSize = TEXT_SIZE
        lbl.TextColor3 = THEME.TabText
        lbl.Parent = container

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -16, 0, 10)
        bar.Position = UDim2.new(0, 8, 0, 36)
        bar.BackgroundColor3 = THEME.TabButtonHover
        bar.BorderSizePixel = 0
        bar.Parent = container
        local bCorner = Instance.new("UICorner", bar); bCorner.CornerRadius = UDim.new(0, 6)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = THEME.TabButtonActive
        fill.BorderSizePixel = 0
        fill.Parent = bar
        local fCorner = Instance.new("UICorner", fill); fCorner.CornerRadius = UDim.new(0, 6)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(240,240,240)
        knob.BorderSizePixel = 0
        knob.Parent = bar
        local kCorner = Instance.new("UICorner", knob); kCorner.CornerRadius = UDim.new(1, 0)

        local value = default
        local dragging = false

        local function setValueFromAlpha(alpha)
            alpha = math.clamp(alpha, 0, 1)
            value = math.floor(min + (max - min) * alpha + 0.5)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, -8, 0.5, -8)
            lbl.Text = string.format("%s: %s", title, tostring(value))
            if onChange then onChange(value) end
        end

        local function getAlphaFromMouse(x)
            return (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                setValueFromAlpha(getAlphaFromMouse(input.Position.X))
            end
        end)
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                setValueFromAlpha(getAlphaFromMouse(input.Position.X))
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                setValueFromAlpha(getAlphaFromMouse(input.Position.X))
            end
        end)

        return {
            Set = function(v)
                local alpha = (v - min) / (max - min)
                setValueFromAlpha(alpha)
            end,
            Get = function() return value end,
            Row = container
        }
    end

    local conns = {}
    local function bind(event, fn)
        local c = event:Connect(fn)
        table.insert(conns, c)
        return c
    end
    local function clearConnections()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        table.clear(conns)
    end

    local originalCollision = {}
    local function setCharacter(collRestore)
        character = player.Character or player.CharacterAdded:Wait()
        humanoid = character:WaitForChild("Humanoid")
        rootPart = character:WaitForChild("HumanoidRootPart")
        originalCollision = {}
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        setCharacter(true)
        if toggles.Fly and toggles.Fly.Get() then startFly() end
        if toggles.Noclip and toggles.Noclip.Get() then enableNoclip(true) end
        if toggles.InfiniteJump and toggles.InfiniteJump.Get() then enableInfiniteJump(true) end
        if sliders.WalkSpeed then humanoid.WalkSpeed = sliders.WalkSpeed.Get() end
        if sliders.JumpPower then humanoid.JumpPower = sliders.JumpPower.Get() end
    end)

    -- ==== FEATURES ====
    local toggles = {}
    local sliders = {}

    local flyConn
    local bodyGyro, bodyVel
    local flySpeed = 50
    local function startFly()
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if bodyGyro then bodyGyro:Destroy() end
        if bodyVel then bodyVel:Destroy() end
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.P = 9e4
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.CFrame = camera.CFrame
        bodyGyro.Parent = rootPart

        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVel.Velocity = Vector3.zero
        bodyVel.Parent = rootPart

        flyConn = bind(RunService.RenderStepped, function()
            if not rootPart then return end
            bodyGyro.CFrame = camera.CFrame

            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                dir -= Vector3.new(0,1,0)
            end

            bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        end)
    end
    local function stopFly()
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
        if bodyVel then bodyVel:Destroy(); bodyVel = nil end
    end

    local noclipConn
    local function enableNoclip(enable)
        if enable then
            originalCollision = {}
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    originalCollision[part] = part.CanCollide
                end
            end
            if not noclipConn then
                noclipConn = bind(RunService.Stepped, function()
                    if character then
                        for part, _ in pairs(originalCollision) do
                            if part and part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            end
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
            for part, can in pairs(originalCollision) do
                if part and part:IsA("BasePart") then
                    part.CanCollide = can
                end
            end
            originalCollision = {}
        end
    end

    local ijConn
    local function enableInfiniteJump(enable)
        if enable then
            if not ijConn then
                ijConn = bind(UserInputService.JumpRequest, function()
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end
        else
            if ijConn then ijConn:Disconnect(); ijConn = nil end
        end
    end

    -- ==== UI ====
    makeLabel("Local Player — Movement & Utils")

    toggles.Fly = makeToggle("Fly (WASD + Space/Shift)", false, function(on)
        if on then startFly() else stopFly() end
    end)

    toggles.Noclip = makeToggle("Noclip (no collisions)", false, function(on)
        enableNoclip(on)
    end)

    toggles.InfiniteJump = makeToggle("Infinite Jump", false, function(on)
        enableInfiniteJump(on)
    end)

    sliders.WalkSpeed = makeSlider("WalkSpeed", 16, 300, humanoid.WalkSpeed, function(v)
        humanoid.WalkSpeed = v
    end)

    sliders.JumpPower = makeSlider("JumpPower", 25, 300, humanoid.JumpPower, function(v)
        humanoid.JumpPower = v
    end)

    sliders.FlySpeed = makeSlider("Fly Speed", 10, 300, flySpeed, function(v)
        flySpeed = v
    end)

    sliders.Gravity = makeSlider("Gravity", 10, 196, math.floor(workspace.Gravity + 0.5), function(v)
        workspace.Gravity = v
    end)

    sliders.FOV = makeSlider("Camera FOV", 50, 120, math.floor(camera.FieldOfView + 0.5), function(v)
        camera.FieldOfView = v
    end)

    local function makeBtn(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 40)
        btn.BackgroundColor3 = THEME.TabButton
        btn.Text = text
        btn.Font = FONT
        btn.TextSize = TEXT_SIZE
        btn.TextColor3 = THEME.TabText
        btn.AutoButtonColor = false
        btn.Parent = scroll
        local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 8)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.TabButtonHover}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.TabButton}):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            callback()
        end)
        return btn
    end

    makeBtn("Sit / Stand", function()
        if humanoid then humanoid.Sit = not humanoid.Sit end
    end)

    makeBtn("Instant Stop (zero velocity)", function()
        if rootPart then rootPart.AssemblyLinearVelocity = Vector3.zero end
    end)

    makeBtn("Respawn", function()
        player:LoadCharacter()
    end)

    makeBtn("Reset All (safe defaults)", function()
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        camera.FieldOfView = 70
        workspace.Gravity = 196.2
        toggles.Fly.Set(false)
        toggles.Noclip.Set(false)
        toggles.InfiniteJump.Set(false)
        stopFly()
        enableNoclip(false)
        enableInfiniteJump(false)
    end)

    updateCanvas()

    frame.AncestryChanged:Connect(function(_, parentNow)
        if not parentNow then
            clearConnections()
            stopFly()
            enableNoclip(false)
            enableInfiniteJump(false)
        end
    end)

    return frame
end
