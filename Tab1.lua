-- Modernes Multi-Tab GUI mit 6 Tabs und verbessertem Design
-- Lege dieses Script in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-------------------------------------------------------
-- EINSTELLUNGEN
-------------------------------------------------------
local settings = {
    Title = "Universal Control Panel",
    Size = UDim2.new(0, 600, 0, 380),
    Theme = {
        Background = Color3.fromRGB(28, 28, 28),
        Header = Color3.fromRGB(45, 45, 45),
        TabsPanel = Color3.fromRGB(38, 38, 38),
        Content = Color3.fromRGB(22, 22, 22),
        TabButton = Color3.fromRGB(55, 55, 55),
        TabButtonHover = Color3.fromRGB(75, 75, 75),
        TabText = Color3.fromRGB(255, 255, 255),
        CloseButton = Color3.fromRGB(170, 40, 40),
        CloseButtonHover = Color3.fromRGB(200, 60, 60)
    },
    Tabs = {
        {name = "Tab 1", url = "https://raw.githubusercontent.com/jannesfox123-art/Universal/refs/heads/main/Tab1.lua"},
        {name = "Tab 2", url = "https://raw.githubusercontent.com/jannesfox123-art/Universal/refs/heads/main/Tab2.lua"},
        {name = "Tab 3", url = "https://raw.githubusercontent.com/jannesfox123-art/Universal/refs/heads/main/Tab3.lua"},
        {name = "Tab 4", url = "https://raw.githubusercontent.com/jannesfox123-art/Universal/refs/heads/main/Tab4.lua"},
        {name = "Tab 5", url = "https://raw.githubusercontent.com/jannesfox123-art/Universal/refs/heads/main/Tab5.lua"},
        {name = "Tab 6", url = "https://raw.githubusercontent.com/jannesfox123-art/Universal/refs/heads/main/Tab6.lua"}
    }
}

-------------------------------------------------------
-- GUI ERSTELLEN
-------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = settings.Size
mainFrame.Position = UDim2.new(0.25, 0, 0.25, 0)
mainFrame.BackgroundColor3 = settings.Theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

-- Rundungen & Schatten
local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(60, 60, 60)
mainStroke.Thickness = 2

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = settings.Theme.Header
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = settings.Title
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = settings.Theme.TabText
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 45, 1, 0)
closeBtn.Position = UDim2.new(1, -45, 0, 0)
closeBtn.BackgroundColor3 = settings.Theme.CloseButton
closeBtn.Text = "✖"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 12)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = settings.Theme.CloseButtonHover}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = settings.Theme.CloseButton}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-------------------------------------------------------
-- TABS & CONTENT
-------------------------------------------------------
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(0, 150, 1, -45)
tabsFrame.Position = UDim2.new(0, 0, 0, 45)
tabsFrame.BackgroundColor3 = settings.Theme.TabsPanel
tabsFrame.BorderSizePixel = 0
tabsFrame.Parent = mainFrame
Instance.new("UICorner", tabsFrame).CornerRadius = UDim.new(0, 12)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -150, 1, -45)
contentFrame.Position = UDim2.new(0, 150, 0, 45)
contentFrame.BackgroundColor3 = settings.Theme.Content
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame
Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 12)

-------------------------------------------------------
-- TABS LADEN
-------------------------------------------------------
for i, tab in ipairs(settings.Tabs) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 35)
    button.Position = UDim2.new(0, 0, 0, (i-1) * 40 + 5)
    button.Text = tab.name
    button.BackgroundColor3 = settings.Theme.TabButton
    button.TextColor3 = settings.Theme.TabText
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.Parent = tabsFrame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = settings.Theme.TabButtonHover}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = settings.Theme.TabButton}):Play()
    end)

    button.MouseButton1Click:Connect(function()
        for _, child in ipairs(contentFrame:GetChildren()) do
            if child:IsA("Frame") then
                child.Visible = false
            end
        end

        local existing = contentFrame:FindFirstChild(tab.name)
        if existing then
            existing.Visible = true
        else
            local success, result = pcall(function()
                return loadstring(game:HttpGet(tab.url))()
            end)

            if success and typeof(result) == "Instance" and result:IsA("Frame") then
                result.Name = tab.name
                result.Parent = contentFrame
                result.Visible = true
            else
                warn("Fehler beim Laden des Tabs: "..tab.name)
            end
        end
    end)
end

-------------------------------------------------------
-- DRAG & DROP
-------------------------------------------------------
local dragging = false
local dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        update(input)
    end
end)

print("[MainScript] Modernes GUI mit 6 Tabs geladen.")
