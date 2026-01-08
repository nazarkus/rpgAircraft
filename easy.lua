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
    Boat = workspace["Game Systems"]["Boat Workspace"],
    Tank = workspace["Game Systems"]["Tank Workspace"],
    Hovercraft = workspace["Game Systems"]["Hovercraft Workspace"]
}

local selectedTargets = {}
local targetInstances = {}

-- Основной GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RPGSpammerGUI"
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false

-- Переменные для перемещения
local dragging
local dragInput
local dragStart
local startPos

-- Функция для перемещения
local function updateInput(input)
    local delta = input.Position - dragStart
    dragging.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

-- Кнопка для разворачивания/сворачивания
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleGUI"
toggleBtn.Text = "RPG Spammer v7.0"
toggleBtn.Size = UDim2.new(0, 150, 0, 40)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.BorderSizePixel = 2
toggleBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 14
toggleBtn.Parent = screenGui
toggleBtn.Active = true

-- Включаем перемещение для toggleBtn
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = toggleBtn
        dragStart = input.Position
        startPos = toggleBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = nil
            end
        end)
    end
end)

toggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- Основное окно (изначально скрыто)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 550)  -- Уменьшил высоту
mainFrame.Position = UDim2.new(0, 10, 0, 60)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
mainFrame.Visible = false
mainFrame.Parent = screenGui
mainFrame.Active = true

-- Включаем перемещение для mainFrame
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = mainFrame
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = nil
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        dragInput = input
    end
end)

-- Заголовок основного окна
local title = Instance.new("TextLabel")
title.Text = "RPG Spammer v7.0"
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = mainFrame

-- Кнопка закрытия основного окна
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✖"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 20
closeBtn.Parent = mainFrame

-- Список целей
local targetsFrame = Instance.new("ScrollingFrame")
targetsFrame.Size = UDim2.new(1, -10, 0, 300)  -- Увеличил высоту
targetsFrame.Position = UDim2.new(0, 5, 0, 45)
targetsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
targetsFrame.ScrollBarThickness = 5
targetsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
targetsFrame.Parent = mainFrame

-- Панель управления (упрощенная)
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, -10, 0, 100)  -- Уменьшил высоту
controlFrame.Position = UDim2.new(0, 5, 0, 350)
controlFrame.BackgroundTransparency = 1
controlFrame.Parent = mainFrame

-- Статус
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 25)
statusLabel.Position = UDim2.new(0, 5, 0, 455)
statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.Parent = mainFrame

-- Кнопка запуска спама
local spamBtn = Instance.new("TextButton")
spamBtn.Text = "▶️ START SPAM"
spamBtn.Size = UDim2.new(1, -10, 0, 40)
spamBtn.Position = UDim2.new(0, 5, 0, 485)
spamBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
spamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spamBtn.Font = Enum.Font.SourceSansBold
spamBtn.TextSize = 18
spamBtn.Parent = mainFrame

-- Переменные состояния
local spamActive = false
local spamThread
local updateThread
local isGUIOpen = false

-- Функция для сворачивания/разворачивания GUI
local function toggleGUI()
    isGUIOpen = not isGUIOpen
    mainFrame.Visible = isGUIOpen
    
    if isGUIOpen then
        toggleBtn.Text = "▼ RPG Spammer v7.0"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    else
        toggleBtn.Text = "▲ RPG Spammer v7.0"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end

-- Обработчики кнопок
toggleBtn.MouseButton1Click:Connect(toggleGUI)

closeBtn.MouseButton1Click:Connect(function()
    toggleGUI()
end)

-- Функции
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
        targetButton.Size = UDim2.new(1, -10, 0, 40)  -- Уменьшил высоту
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
        iconLabel.TextSize = 16
        iconLabel.Parent = targetButton
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = target.Name .. " [" .. target.Type .. "]"
        nameLabel.Size = UDim2.new(1, -40, 1, 0)
        nameLabel.Position = UDim2.new(0, 40, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = selectedTargets[target.Name] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = targetButton
        
        local checkBox = Instance.new("TextLabel")
        checkBox.Text = selectedTargets[target.Name] and "✓" or ""
        checkBox.Size = UDim2.new(0, 20, 0, 20)
        checkBox.Position = UDim2.new(1, -25, 0.5, -10)
        checkBox.BackgroundColor3 = selectedTargets[target.Name] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        checkBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkBox.Font = Enum.Font.SourceSansBold
        checkBox.TextSize = 14
        checkBox.Parent = targetButton
        
        targetButton.MouseButton1Click:Connect(function()
            if selectedTargets[target.Name] then
                selectedTargets[target.Name] = nil
                targetButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                iconLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                checkBox.Text = ""
                checkBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            else
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
            
            local selectedCount = 0
            for _ in pairs(selectedTargets) do
                selectedCount = selectedCount + 1
            end
            statusLabel.Text = "Selected: " .. selectedCount
        end)
        
        yPos = yPos + 45
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

-- Только две основные кнопки вместо 6
createControlButton("✅ Select All", UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 0, 40), Color3.fromRGB(50, 150, 50), function()
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

createControlButton("🗑️ Clear All", UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 0, 40), Color3.fromRGB(150, 50, 50), function()
    selectedTargets = {}
    updateTargetList()
    statusLabel.Text = "No targets selected"
end)

-- Кнопка для выбора воздушных целей
createControlButton("🛩️ Air Targets", UDim2.new(0, 0, 0, 45), UDim2.new(0.48, 0, 0, 40), Color3.fromRGB(70, 100, 200), function()
    selectedTargets = {}
    for _, target in ipairs(targetInstances) do
        if target.Type == "Helicopter" or target.Type == "Plane" or target.Type == "Gunship" then
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
    statusLabel.Text = "Selected Air: " .. selectedCount
end)

-- Кнопка для выбора наземных/водных целей
createControlButton("🚤 Ground/Sea", UDim2.new(0.52, 0, 0, 45), UDim2.new(0.48, 0, 0, 40), Color3.fromRGB(200, 150, 50), function()
    selectedTargets = {}
    for _, target in ipairs(targetInstances) do
        if target.Type == "Boat" or target.Type == "Tank" or target.Type == "Hovercraft" then
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
    statusLabel.Text = "Selected Ground/Sea: " .. selectedCount
end)

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
    
    -- Разная корректировка для разных типов целей
    if targetData.Type == "Boat" then
        pos = Vector3.new(pos.X, pos.Y + 3, pos.Z)
    elseif targetData.Type == "Tank" then
        pos = Vector3.new(pos.X, pos.Y + 1.5, pos.Z)
    elseif targetData.Type == "Hovercraft" then
        pos = Vector3.new(pos.X, pos.Y + 2, pos.Z)
    elseif targetData.Type == "Plane" then
        pos = Vector3.new(pos.X, pos.Y + 1, pos.Z)
    end
    
    fx:FireServer(tool, true)
    
    -- Предсказание движения
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

spamBtn.MouseButton1Click:Connect(function()
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
        
        spamBtn.Text = "⏹️ STOP SPAM"
        spamBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        statusLabel.Text = "SPAM ACTIVE: " .. selectedCount
        
        spamThread = task.spawn(function()
            while spamActive do
                for _, targetData in pairs(selectedTargets) do
                    if spamActive then
                        attackVehicle(targetData)
                        task.wait(0.05)  -- Задержка между выстрелами
                    end
                end
                task.wait(0.1)  -- Задержка между циклами
            end
        end)
    else
        spamBtn.Text = "▶️ START SPAM"
        spamBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
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

plr.CharacterAdded:Connect(function()
    char = plr.Character or plr.CharacterAdded:Wait()
    hrp = char:WaitForChild("HumanoidRootPart")
    tool = findRPG()
    updateTargetList()
end)

-- Инициализация
updateTargetList()
statusLabel.Text = "Ready - " .. #targetInstances .. " targets found"

-- Автообновление списка каждые 3 секунды
updateThread = task.spawn(function()
    while true do
        task.wait(3)
        if isGUIOpen then
            updateTargetList()
        end
    end
end)

print("✅ RPG Spammer v7.0 loaded (Press button to toggle GUI)")
