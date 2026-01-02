local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local function findRPG()
    local tool = char:FindFirstChild("RPG")
    if not tool then
        local backpack = plr:FindFirstChild("Backpack")
        if backpack then tool = backpack:FindFirstChild("RPG") end
    end
    return tool
end

local tool = findRPG()
local ev = game.ReplicatedStorage.RocketSystem.Events
local fx = ev.RocketReloadedFX
local hit = ev.RocketHit
local cnt = 0

local targetFolders = {
    Helicopter = workspace["Game Systems"]["Helicopter Workspace"],
    Plane = workspace["Game Systems"]["Plane Workspace"],
    Gunship = workspace["Game Systems"]["Gunship Workspace"],
    Boat = workspace["Game Systems"]["Boat Workspace"]
}

local selectedTargets = {}
local targetInstances = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RPGSpammerGUI"
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 580)
frame.Position = UDim2.new(0.5, -210, 0.5, -290)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(80, 80, 80)
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Text = "RPG Spammer v6.0"
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

local targetsFrame = Instance.new("ScrollingFrame")
targetsFrame.Size = UDim2.new(1, -10, 0, 250)
targetsFrame.Position = UDim2.new(0, 5, 0, 45)
targetsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
targetsFrame.ScrollBarThickness = 5
targetsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
targetsFrame.Parent = frame

local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, -10, 0, 200)
controlFrame.Position = UDim2.new(0, 5, 0, 300)
controlFrame.BackgroundTransparency = 1
controlFrame.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 25)
statusLabel.Position = UDim2.new(0, 5, 0, 505)
statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.Parent = frame

local spamActive = false
local spamThread
local updateThread

local function scanAllTargets()
    targetInstances = {}
    for targetType, folder in pairs(targetFolders) do
        if folder then
            for _, vehicle in ipairs(folder:GetChildren()) do
                if vehicle:IsA("Model") then
                    local vehicleHRP = vehicle:FindFirstChild("HumanoidRootPart") or 
                                       vehicle:FindFirstChild("Main") or
                                       vehicle:FindFirstChild("RootPart") or
                                       vehicle:FindFirstChild("Head") or
                                       vehicle.PrimaryPart
                    if vehicleHRP then
                        table.insert(targetInstances, {
                            Name = vehicle.Name,
                            Type = targetType,
                            Model = vehicle,
                            HRP = vehicleHRP
                        })
                    end
                end
            end
        end
    end
    return #targetInstances
end

local function updateTargetList()
    for _, child in ipairs(targetsFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    scanAllTargets()
    local yPos = 0
    
    for _, target in ipairs(targetInstances) do
        local targetButton = Instance.new("TextButton")
        targetButton.Name = target.Name
        targetButton.Size = UDim2.new(1, -10, 0, 45)
        targetButton.Position = UDim2.new(0, 5, 0, yPos)
        targetButton.BackgroundColor3 = selectedTargets[target.Name] and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(50, 50, 50)
        targetButton.Text = ""
        targetButton.AutoButtonColor = false
        targetButton.Parent = targetsFrame
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Text = "🎯"
        iconLabel.Size = UDim2.new(0, 30, 1, 0)
        iconLabel.Position = UDim2.new(0, 5, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextColor3 = selectedTargets[target.Name] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(200, 200, 200)
        iconLabel.Font = Enum.Font.SourceSansBold
        iconLabel.TextSize = 18
        iconLabel.Parent = targetButton
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = target.Name .. " [" .. target.Type .. "]"
        nameLabel.Size = UDim2.new(1, -40, 1, 0)
        nameLabel.Position = UDim2.new(0, 40, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = selectedTargets[target.Name] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = targetButton
        
        local checkBox = Instance.new("TextLabel")
        checkBox.Text = selectedTargets[target.Name] and "✓" or ""
        checkBox.Size = UDim2.new(0, 25, 0, 25)
        checkBox.Position = UDim2.new(1, -30, 0.5, -12.5)
        checkBox.BackgroundColor3 = selectedTargets[target.Name] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        checkBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkBox.Font = Enum.Font.SourceSansBold
        checkBox.TextSize = 16
        checkBox.Parent = targetButton
        
        -- Клик для выбора/снятия выбора цели
        targetButton.MouseButton1Click:Connect(function()
            if selectedTargets[target.Name] then
                -- Снимаем выбор с цели
                selectedTargets[target.Name] = nil
                targetButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                iconLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                checkBox.Text = ""
                checkBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            else
                -- Выбираем цель
                selectedTargets[target.Name] = {
                    Model = target.Model,
                    HRP = target.HRP,
                    Type = target.Type
                }
                targetButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                iconLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                checkBox.Text = "✓"
                checkBox.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            end
            
            -- Немедленное обновление статуса без полного рефреша
            local selectedCount = 0
            for _ in pairs(selectedTargets) do
                selectedCount = selectedCount + 1
            end
            statusLabel.Text = "Selected: " .. selectedCount
        end)
        
        yPos = yPos + 50
    end
    
    targetsFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

local function createControlButton(text, position, size, bgColor, callback)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = size
    btn.Position = position
    btn.BackgroundColor3 = bgColor
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = controlFrame
    btn.MouseButton1Click:Connect(callback)
end

createControlButton("✅ Select All", UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(50, 150, 50), function()
    selectedTargets = {}
    for _, target in ipairs(targetInstances) do
        selectedTargets[target.Name] = {
            Model = target.Model,
            HRP = target.HRP,
            Type = target.Type
        }
    end
    updateTargetList()
    statusLabel.Text = "Selected: " .. #targetInstances
end)

createControlButton("🗑️ Clear", UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(150, 50, 50), function()
    selectedTargets = {}
    updateTargetList()
    statusLabel.Text = "No targets selected"
end)

createControlButton("🚁 Helis", UDim2.new(0, 0, 0, 40), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(70, 150, 70), function()
    selectedTargets = {}
    for _, target in ipairs(targetInstances) do
        if target.Type == "Helicopter" then
            selectedTargets[target.Name] = {
                Model = target.Model,
                HRP = target.HRP,
                Type = target.Type
            }
        end
    end
    updateTargetList()
    
    local selectedCount = 0
    for _ in pairs(selectedTargets) do
        selectedCount = selectedCount + 1
    end
    statusLabel.Text = "Selected: " .. selectedCount
end)

createControlButton("✈️ Planes", UDim2.new(0.52, 0, 0, 40), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(70, 100, 200), function()
    selectedTargets = {}
    for _, target in ipairs(targetInstances) do
        if target.Type == "Plane" then
            selectedTargets[target.Name] = {
                Model = target.Model,
                HRP = target.HRP,
                Type = target.Type
            }
        end
    end
    updateTargetList()
    
    local selectedCount = 0
    for _ in pairs(selectedTargets) do
        selectedCount = selectedCount + 1
    end
    statusLabel.Text = "Selected: " .. selectedCount
end)

createControlButton("🛩️ Gunships", UDim2.new(0, 0, 0, 80), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(200, 70, 70), function()
    selectedTargets = {}
    for _, target in ipairs(targetInstances) do
        if target.Type == "Gunship" then
            selectedTargets[target.Name] = {
                Model = target.Model,
                HRP = target.HRP,
                Type = target.Type
            }
        end
    end
    updateTargetList()
    
    local selectedCount = 0
    for _ in pairs(selectedTargets) do
        selectedCount = selectedCount + 1
    end
    statusLabel.Text = "Selected: " .. selectedCount
end)

createControlButton("⛵ Boats", UDim2.new(0.52, 0, 0, 80), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(200, 150, 50), function()
    selectedTargets = {}
    for _, target in ipairs(targetInstances) do
        if target.Type == "Boat" then
            selectedTargets[target.Name] = {
                Model = target.Model,
                HRP = target.HRP,
                Type = target.Type
            }
        end
    end
    updateTargetList()
    
    local selectedCount = 0
    for _ in pairs(selectedTargets) do
        selectedCount = selectedCount + 1
    end
    statusLabel.Text = "Selected: " .. selectedCount
end)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Text = "▶️ START SPAM"
toggleBtn.Size = UDim2.new(1, -10, 0, 40)
toggleBtn.Position = UDim2.new(0, 5, 0, 535)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 18
toggleBtn.Parent = frame

local function attackVehicle(targetData)
    if not targetData or not targetData.Model then return false end
    local vehicleHRP = targetData.HRP
    if not vehicleHRP then return false end
    
    if not tool or not tool.Parent then
        tool = findRPG()
        if not tool then
            statusLabel.Text = "Need RPG!"
            return false
        end
    end
    
    local pos = vehicleHRP.Position
    local dir = (pos - hrp.Position).Unit
    
    if targetData.Type == "Boat" then
        pos = Vector3.new(pos.X, pos.Y + 3, pos.Z)
    end
    
    fx:FireServer(tool, true)
    
    local predictedPos = pos
    if vehicleHRP.Velocity.Magnitude > 10 then
        predictedPos = pos + vehicleHRP.Velocity * 0.5
    end
    
    hit:FireServer(
        Vector3.new(predictedPos.X, predictedPos.Y, predictedPos.Z),
        Vector3.new(dir.X, dir.Y, dir.Z),
        tool,
        tool,
        vehicleHRP,
        nil,
        plr.Name .. "Rocket" .. cnt
    )
    
    cnt = cnt + 1
    return true
end

toggleBtn.MouseButton1Click:Connect(function()
    spamActive = not spamActive
    
    if spamActive then
        local selectedCount = 0
        for _ in pairs(selectedTargets) do
            selectedCount = selectedCount + 1
        end
        
        if selectedCount == 0 then
            statusLabel.Text = "No targets selected!"
            spamActive = false
            return
        end
        
        if not tool then
            tool = findRPG()
            if not tool then
                statusLabel.Text = "Need RPG!"
                spamActive = false
                return
            end
        end
        
        toggleBtn.Text = "⏹️ STOP"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        statusLabel.Text = "SPAM ACTIVE: " .. selectedCount
        
        spamThread = task.spawn(function()
            while spamActive do
                for _, targetData in pairs(selectedTargets) do
                    if spamActive then
                        attackVehicle(targetData)
                        task.wait(0.05)
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        toggleBtn.Text = "▶️ START SPAM"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
        local selectedCount = 0
        for _ in pairs(selectedTargets) do
            selectedCount = selectedCount + 1
        end
        statusLabel.Text = "Selected: " .. selectedCount
        
        if spamThread then
            task.cancel(spamThread)
        end
    end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✖"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 20
closeBtn.Parent = frame

closeBtn.MouseButton1Click:Connect(function()
    spamActive = false
    if spamThread then task.cancel(spamThread) end
    if updateThread then task.cancel(updateThread) end
    screenGui:Destroy()
end)

plr.CharacterAdded:Connect(function()
    char = plr.Character or plr.CharacterAdded:Wait()
    hrp = char:WaitForChild("HumanoidRootPart")
    tool = findRPG()
    updateTargetList()
end)

updateTargetList()
statusLabel.Text = "Ready"

-- Автообновление списка каждые 3 секунды
updateThread = task.spawn(function()
    while true do
        task.wait(3)
        updateTargetList()
    end
end)

print("✅ RPG Spammer v6.0 loaded")
