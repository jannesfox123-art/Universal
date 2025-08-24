local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
frame.Visible = false
frame.Parent = parent

local player = game.Players.LocalPlayer
local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid") or nil

-- Aktualisiere humanoid bei Respawn
player.CharacterAdded:Connect(function(char)
    humanoid = char:WaitForChild("Humanoid")
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Player Controls"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame

-- Speed Button
local speedBtn = Instance.new("TextButton")
speedBtn.Size = UDim2.new(0, 150, 0, 30)
speedBtn.Position = UDim2.new(0, 20, 0, 50)
speedBtn.Text = "Speed x2"
speedBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
speedBtn.TextColor3 = Color3.new(1,1,1)
speedBtn.Font = Enum.Font.SourceSansBold
speedBtn.TextSize = 18
speedBtn.Parent = frame

speedBtn.MouseButton1Click:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = humanoid.WalkSpeed * 2
    end
end)

-- Jump Button
local jumpBtn = Instance.new("TextButton")
jumpBtn.Size = UDim2.new(0, 150, 0, 30)
jumpBtn.Position = UDim2.new(0, 20, 0, 90)
jumpBtn.Text = "Jump x2"
jumpBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
jumpBtn.TextColor3 = Color3.new(1,1,1)
jumpBtn.Font = Enum.Font.SourceSansBold
jumpBtn.TextSize = 18
jumpBtn.Parent = frame

jumpBtn.MouseButton1Click:Connect(function()
    if humanoid then
        humanoid.JumpPower = humanoid.JumpPower * 2
    end
end)

-- Reset Button
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 150, 0, 30)
resetBtn.Position = UDim2.new(0, 20, 0, 130)
resetBtn.Text = "Reset Stats"
resetBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.Font = Enum.Font.SourceSansBold
resetBtn.TextSize = 18
resetBtn.Parent = frame

resetBtn.MouseButton1Click:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end)

return frame
