local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local function findRPG()
    local t = char:FindFirstChild("RPG")
    if not t then
        local bp = plr:FindFirstChild("Backpack")
        if bp then t = bp:FindFirstChild("RPG") end
    end
    return t
end

local tool = findRPG()

local ev = game.ReplicatedStorage.RocketSystem.Events
local fx = ev.RocketReloadedFX
local fire = ev.FireRocketReplicated
local hit = ev.RocketHit
local cnt = 0

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local gradientTime = 0
local currentGradientColor = Color3.fromRGB(100, 120, 200)

-- ═══════════════════════════════════════
-- ЦВЕТА
-- ═══════════════════════════════════════
local C = {
    Bg       = Color3.fromRGB(8, 10, 18),
    Sec      = Color3.fromRGB(12, 15, 28),
    Ter      = Color3.fromRGB(20, 24, 40),
    Card     = Color3.fromRGB(14, 17, 32),
    Sel      = Color3.fromRGB(28, 45, 75),
    Ok       = Color3.fromRGB(40, 100, 75),
    Bad      = Color3.fromRGB(120, 40, 50),
    Txt      = Color3.fromRGB(230, 232, 245),
    Dim      = Color3.fromRGB(130, 135, 165),
    Mute     = Color3.fromRGB(80, 85, 110),
    Brd      = Color3.fromRGB(45, 52, 85),
    Check    = Color3.fromRGB(45, 115, 95),
    Glow     = Color3.fromRGB(100, 80, 220),
    Air      = Color3.fromRGB(60, 90, 160),
    Ground   = Color3.fromRGB(160, 120, 50),
}

-- ═══════════════════════════════════════
-- ПАПКИ ТРАНСПОРТА
-- ═══════════════════════════════════════
local targetFolders = {
    Helicopter = workspace["Game Systems"]["Helicopter Workspace"],
    Plane      = workspace["Game Systems"]["Plane Workspace"],
    Gunship    = workspace["Game Systems"]["Gunship Workspace"],
    Boat       = workspace["Game Systems"]["Boat Workspace"],
    Tank       = workspace["Game Systems"]["Tank Workspace"],
    Hovercraft = workspace["Game Systems"]["Hovercraft Workspace"],
}

local vIcons = {
    Helicopter = "🚁", Plane = "✈️", Gunship = "💥",
    Boat = "🚤", Tank = "🏗️", Hovercraft = "🛥️",
}

local vColors = {
    Helicopter = Color3.fromRGB(70, 130, 200),
    Plane      = Color3.fromRGB(100, 160, 220),
    Gunship    = Color3.fromRGB(200, 80, 80),
    Boat       = Color3.fromRGB(60, 150, 130),
    Tank       = Color3.fromRGB(160, 140, 60),
    Hovercraft = Color3.fromRGB(130, 100, 180),
}

local selectedTargets = {}
local targetInstances = {}
local vehicleElements = {}
local syncedButtons = {}

-- ═══════════════════════════════════════
-- УТИЛИТЫ
-- ═══════════════════════════════════════
local function lerp3(a, b, t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 12); c.Parent = p; return c
end

local function stroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or C.Brd; s.Thickness = th or 1.5; s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

local function shadow(p)
    local s = Instance.new("ImageLabel")
    s.Name="Shadow"; s.BackgroundTransparency=1; s.Image="rbxassetid://6014261993"
    s.ImageColor3=Color3.new(0,0,0); s.ImageTransparency=0.2
    s.ScaleType=Enum.ScaleType.Slice; s.SliceCenter=Rect.new(49,49,450,450)
    s.Size=UDim2.new(1,80,1,80); s.Position=UDim2.new(0,-40,0,-40)
    s.ZIndex=p.ZIndex-1; s.Parent=p
end

local function innerGlow(p, col)
    local g = Instance.new("Frame")
    g.Size=UDim2.new(1,0,1,0); g.BackgroundTransparency=1; g.ZIndex=p.ZIndex; g.Parent=p
    local gs = Instance.new("UIStroke")
    gs.Color=col or C.Glow; gs.Thickness=1.5; gs.Transparency=0.6
    gs.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; gs.Parent=g
    corner(g,20); return g, gs
end

local function hoverFx(btn, base)
    local d = {button=btn, baseColor=base, isHovered=false}
    table.insert(syncedButtons, d)
    btn.MouseEnter:Connect(function()
        d.isHovered = true
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundTransparency=0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        d.isHovered = false
        TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=base,BackgroundTransparency=0}):Play()
    end)
    return d
end

-- ═══════════════════════════════════════
-- СКАНИРОВАНИЕ ТРАНСПОРТА
-- ═══════════════════════════════════════
local function scanVehicles()
    targetInstances = {}
    for typ, folder in pairs(targetFolders) do
        if folder then
            for _, mdl in ipairs(folder:GetChildren()) do
                if mdl:IsA("Model") then
                    local part = mdl:FindFirstChild("HumanoidRootPart")
                        or mdl:FindFirstChild("Main")
                        or mdl:FindFirstChild("RootPart")
                        or mdl:FindFirstChild("Head")
                        or mdl.PrimaryPart
                    if part then
                        table.insert(targetInstances, {
                            Name = mdl.Name,
                            Type = typ,
                            Model = mdl,
                            HRP = part,
                        })
                    end
                end
            end
        end
    end
    return #targetInstances
end

-- ═══════════════════════════════════════
-- ОСНОВНОЙ GUI
-- ═══════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "RPGVehicleGUI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 380, 0, 560)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -280)
mainFrame.BackgroundColor3 = C.Bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Parent = gui
corner(mainFrame, 20)
shadow(mainFrame)

local glow, glowStroke = innerGlow(mainFrame, C.Glow)

-- ═══════════════════════════════════════
-- АНИМИРОВАННЫЙ ФОН
-- ═══════════════════════════════════════
local gc = Instance.new("Frame")
gc.Size=UDim2.new(1,0,1,0); gc.BackgroundTransparency=1; gc.ClipsDescendants=true
gc.ZIndex=0; gc.Parent=mainFrame; corner(gc,20)

local bf1 = Instance.new("Frame")
bf1.Size=UDim2.new(2.5,0,2.5,0); bf1.Position=UDim2.new(-0.75,0,-0.75,0)
bf1.BackgroundColor3=Color3.new(1,1,1); bf1.BackgroundTransparency=0.65
bf1.BorderSizePixel=0; bf1.ZIndex=0; bf1.Parent=gc

local ug1 = Instance.new("UIGradient")
ug1.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(100,60,180)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(60,110,200)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80,160,200)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(150,90,200)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200,80,150)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(100,60,180)),
})
ug1.Parent = bf1

local bf2 = Instance.new("Frame")
bf2.Size=UDim2.new(2.5,0,2.5,0); bf2.Position=UDim2.new(-0.75,0,-0.75,0)
bf2.BackgroundColor3=Color3.new(1,1,1); bf2.BackgroundTransparency=0.7
bf2.BorderSizePixel=0; bf2.ZIndex=0; bf2.Parent=gc

local ug2 = Instance.new("UIGradient")
ug2.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(200,100,160)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(100,180,200)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(160,120,200)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(90,150,200)),
})
ug2.Rotation=60; ug2.Parent=bf2

local bf3 = Instance.new("Frame")
bf3.Size=UDim2.new(1.2,0,0.7,0); bf3.Position=UDim2.new(-0.1,0,-0.1,0)
bf3.BackgroundColor3=Color3.fromRGB(120,140,200); bf3.BackgroundTransparency=0.55
bf3.BorderSizePixel=0; bf3.ZIndex=0; bf3.Parent=gc; corner(bf3,20)

local ug3 = Instance.new("UIGradient")
ug3.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(0.3,0.4),
    NumberSequenceKeypoint.new(0.7,0.8), NumberSequenceKeypoint.new(1,1),
})
ug3.Rotation=90; ug3.Parent=bf3

local dots = {}
for i=1,6 do
    local d = Instance.new("Frame")
    d.Size=UDim2.new(0,math.random(25,60),0,math.random(25,60))
    d.Position=UDim2.new(math.random()*0.8,0,math.random()*0.8,0)
    d.BackgroundColor3=Color3.fromRGB(150,130,200); d.BackgroundTransparency=0.75
    d.BorderSizePixel=0; d.ZIndex=0; d.Parent=gc; corner(d,50)
    table.insert(dots,{f=d, sx=(math.random()-0.5)*0.25, sy=(math.random()-0.5)*0.25, ph=math.random()*math.pi*2})
end

local animConn = RunService.RenderStepped:Connect(function(dt)
    gradientTime = gradientTime + dt*1.8
    ug1.Rotation = gradientTime*25
    ug1.Offset = Vector2.new(math.sin(gradientTime*0.9)*0.35, math.cos(gradientTime*0.7)*0.35)
    ug2.Rotation = -gradientTime*18+60
    ug2.Offset = Vector2.new(math.cos(gradientTime*0.8)*0.4, math.sin(gradientTime*1.1)*0.4)
    ug3.Offset = Vector2.new(math.sin(gradientTime*1.5)*0.25, 0)
    bf3.BackgroundTransparency = 0.5+math.sin(gradientTime)*0.15

    local hue = (gradientTime*0.06)%1
    bf3.BackgroundColor3 = Color3.fromHSV(hue*0.35+0.55, 0.55, 0.85)
    currentGradientColor = Color3.fromHSV(hue*0.35+0.55, 0.65, 0.95)
    glowStroke.Color = Color3.fromHSV((hue*0.35+0.6)%1, 0.45, 0.9)
    glowStroke.Transparency = 0.55+math.sin(gradientTime*2.5)*0.15

    for _,p in ipairs(dots) do
        local x = 0.5+math.sin(gradientTime*p.sx+p.ph)*0.45
        local y = 0.5+math.cos(gradientTime*p.sy+p.ph)*0.45
        p.f.Position = UDim2.new(x,-p.f.Size.X.Offset/2, y,-p.f.Size.Y.Offset/2)
        p.f.BackgroundTransparency = 0.7+math.sin(gradientTime*2+p.ph)*0.2
        p.f.BackgroundColor3 = Color3.fromHSV((hue+p.ph/10)%1*0.3+0.55, 0.4, 0.85)
    end

    for _,d in ipairs(syncedButtons) do
        if d.isHovered and d.button and d.button.Parent then
            d.button.BackgroundColor3 = lerp3(d.baseColor, currentGradientColor, 0.55)
        end
    end
end)

-- ═══════════════════════════════════════
-- ЗАГОЛОВОК
-- ═══════════════════════════════════════
local titleBar = Instance.new("Frame")
titleBar.Size=UDim2.new(1,0,0,55); titleBar.BackgroundTransparency=1
titleBar.ZIndex=2; titleBar.Parent=mainFrame

local _drag, _dragIn, _dragSt, _dragPos

titleBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        _drag=true; _dragSt=i.Position; _dragPos=mainFrame.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then _drag=false end end)
    end
end)
titleBar.InputChanged:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseMovement then _dragIn=i end
end)
UserInputService.InputChanged:Connect(function(i)
    if i==_dragIn and _drag then
        local d=i.Position-_dragSt
        TweenService:Create(mainFrame,TweenInfo.new(0.06),{
            Position=UDim2.new(_dragPos.X.Scale, _dragPos.X.Offset+d.X, _dragPos.Y.Scale, _dragPos.Y.Offset+d.Y)
        }):Play()
    end
end)

local iBg = Instance.new("Frame")
iBg.Size=UDim2.new(0,38,0,38); iBg.Position=UDim2.new(0,14,0,10)
iBg.BackgroundColor3=C.Ter; iBg.BackgroundTransparency=0.2; iBg.ZIndex=2; iBg.Parent=titleBar
corner(iBg,12)

local iLbl = Instance.new("TextLabel")
iLbl.Text="🚀"; iLbl.Size=UDim2.new(1,0,1,0); iLbl.BackgroundTransparency=1
iLbl.TextSize=20; iLbl.Font=Enum.Font.SourceSans; iLbl.ZIndex=3; iLbl.Parent=iBg

local tLbl = Instance.new("TextLabel")
tLbl.Text="RPG Vehicle Spammer"; tLbl.Size=UDim2.new(1,-130,0,24); tLbl.Position=UDim2.new(0,60,0,10)
tLbl.BackgroundTransparency=1; tLbl.TextColor3=C.Txt; tLbl.Font=Enum.Font.GothamBlack
tLbl.TextSize=16; tLbl.TextXAlignment=Enum.TextXAlignment.Left; tLbl.ZIndex=2; tLbl.Parent=titleBar

local vBg = Instance.new("Frame")
vBg.Size=UDim2.new(0,45,0,18); vBg.Position=UDim2.new(0,60,0,35)
vBg.BackgroundColor3=C.Check; vBg.BackgroundTransparency=0.2; vBg.ZIndex=2; vBg.Parent=titleBar
corner(vBg,9)

local vLbl = Instance.new("TextLabel")
vLbl.Text="v7.0"; vLbl.Size=UDim2.new(1,0,1,0); vLbl.BackgroundTransparency=1
vLbl.TextColor3=C.Txt; vLbl.Font=Enum.Font.GothamBold; vLbl.TextSize=10; vLbl.ZIndex=3; vLbl.Parent=vBg

local bCont = Instance.new("Frame")
bCont.Size=UDim2.new(0,70,0,34); bCont.Position=UDim2.new(1,-84,0,12)
bCont.BackgroundColor3=C.Sec; bCont.BackgroundTransparency=0.2; bCont.ZIndex=2; bCont.Parent=titleBar
corner(bCont,10)

local closeBtn = Instance.new("TextButton")
closeBtn.Text="×"; closeBtn.Size=UDim2.new(0,30,0,28); closeBtn.Position=UDim2.new(1,-33,0.5,-14)
closeBtn.BackgroundColor3=C.Bad; closeBtn.BackgroundTransparency=0.3; closeBtn.TextColor3=C.Txt
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=18; closeBtn.ZIndex=3; closeBtn.Parent=bCont
corner(closeBtn,8); hoverFx(closeBtn,C.Bad)

local minBtn = Instance.new("TextButton")
minBtn.Text="−"; minBtn.Size=UDim2.new(0,30,0,28); minBtn.Position=UDim2.new(0,3,0.5,-14)
minBtn.BackgroundColor3=C.Ter; minBtn.BackgroundTransparency=0.2; minBtn.TextColor3=C.Txt
minBtn.Font=Enum.Font.GothamBold; minBtn.TextSize=18; minBtn.ZIndex=3; minBtn.Parent=bCont
corner(minBtn,8); hoverFx(minBtn,C.Ter)

-- ═══════════════════════════════════════
-- КОНТЕНТ
-- ═══════════════════════════════════════
local content = Instance.new("Frame")
content.Name="Content"; content.Size=UDim2.new(1,-28,1,-65); content.Position=UDim2.new(0,14,0,60)
content.BackgroundTransparency=1; content.ZIndex=2; content.Parent=mainFrame

-- Секция списка
local listSec = Instance.new("Frame")
listSec.Size=UDim2.new(1,0,0,260); listSec.BackgroundColor3=C.Card; listSec.BackgroundTransparency=0.15
listSec.BorderSizePixel=0; listSec.ZIndex=2; listSec.Parent=content
corner(listSec,14); stroke(listSec,C.Brd,1,0.4)

local hdr = Instance.new("Frame")
hdr.Size=UDim2.new(1,0,0,36); hdr.BackgroundTransparency=1; hdr.ZIndex=3; hdr.Parent=listSec

local hdrLbl = Instance.new("TextLabel")
hdrLbl.Text="🎯 VEHICLES"; hdrLbl.Size=UDim2.new(0.5,0,1,0); hdrLbl.Position=UDim2.new(0,14,0,0)
hdrLbl.BackgroundTransparency=1; hdrLbl.TextColor3=C.Dim; hdrLbl.Font=Enum.Font.GothamBold
hdrLbl.TextSize=11; hdrLbl.TextXAlignment=Enum.TextXAlignment.Left; hdrLbl.ZIndex=3; hdrLbl.Parent=hdr

local cntLbl = Instance.new("TextLabel")
cntLbl.Name="Cnt"; cntLbl.Size=UDim2.new(0.5,-14,1,0); cntLbl.Position=UDim2.new(0.5,0,0,0)
cntLbl.BackgroundTransparency=1; cntLbl.TextColor3=C.Mute; cntLbl.Font=Enum.Font.GothamMedium
cntLbl.TextSize=10; cntLbl.TextXAlignment=Enum.TextXAlignment.Right; cntLbl.ZIndex=3; cntLbl.Parent=hdr

local scroll = Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,-16,1,-44); scroll.Position=UDim2.new(0,8,0,38)
scroll.BackgroundTransparency=1; scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=C.Glow
scroll.ScrollBarImageTransparency=0.3; scroll.BorderSizePixel=0
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.ZIndex=3; scroll.Parent=listSec

local lay = Instance.new("UIListLayout"); lay.Padding=UDim.new(0,6); lay.Parent=scroll
local pad = Instance.new("UIPadding")
pad.PaddingTop=UDim.new(0,2); pad.PaddingBottom=UDim.new(0,2)
pad.PaddingLeft=UDim.new(0,2); pad.PaddingRight=UDim.new(0,2); pad.Parent=scroll

-- Статус
local statBar = Instance.new("Frame")
statBar.Size=UDim2.new(1,0,0,32); statBar.Position=UDim2.new(0,0,0,268)
statBar.BackgroundColor3=C.Card; statBar.BackgroundTransparency=0.15; statBar.ZIndex=2; statBar.Parent=content
corner(statBar,10); stroke(statBar,C.Brd,1,0.4)

local statLbl = Instance.new("TextLabel")
statLbl.Size=UDim2.new(1,0,1,0); statLbl.BackgroundTransparency=1; statLbl.TextColor3=C.Dim
statLbl.Font=Enum.Font.GothamMedium; statLbl.TextSize=12; statLbl.ZIndex=3; statLbl.Parent=statBar

local function updStatus()
    local n = 0
    for _ in pairs(selectedTargets) do n=n+1 end
    if n==0 then
        statLbl.Text="✨ No targets selected"; statLbl.TextColor3=C.Dim
    else
        statLbl.Text="✅ "..n.." target"..(n>1 and "s" or "").." selected"; statLbl.TextColor3=C.Check
    end
end

-- ═══════════════════════════════════════
-- ЭЛЕМЕНТ ТРАНСПОРТА
-- ═══════════════════════════════════════
local function makeVehicleRow(tgt)
    local mdl = tgt.Model

    local row = Instance.new("Frame")
    row.Name=tgt.Name; row.Size=UDim2.new(1,-4,0,44); row.BackgroundColor3=C.Sec
    row.BackgroundTransparency=0.2; row.BorderSizePixel=0; row.ZIndex=4; row.Parent=scroll
    corner(row,10)

    local cb = Instance.new("Frame")
    cb.Name="CB"; cb.Size=UDim2.new(0,22,0,22); cb.Position=UDim2.new(0,10,0.5,-11)
    cb.BackgroundColor3=C.Ter; cb.BorderSizePixel=0; cb.ZIndex=5; cb.Parent=row
    corner(cb,7); stroke(cb,C.Brd,1.5,0.2)

    local cm = Instance.new("TextLabel")
    cm.Text=""; cm.Size=UDim2.new(1,0,1,0); cm.BackgroundTransparency=1; cm.TextColor3=C.Txt
    cm.Font=Enum.Font.GothamBold; cm.TextSize=14; cm.ZIndex=6; cm.Parent=cb

    local badge = Instance.new("Frame")
    badge.Size=UDim2.new(0,30,0,30); badge.Position=UDim2.new(0,38,0.5,-15)
    badge.BackgroundColor3=vColors[tgt.Type] or C.Ter; badge.BackgroundTransparency=0.3
    badge.ZIndex=5; badge.Parent=row; corner(badge,10)

    local bIcon = Instance.new("TextLabel")
    bIcon.Text=vIcons[tgt.Type] or "🎯"; bIcon.Size=UDim2.new(1,0,1,0)
    bIcon.BackgroundTransparency=1; bIcon.TextSize=16; bIcon.Font=Enum.Font.SourceSans
    bIcon.ZIndex=6; bIcon.Parent=badge

    local nc = Instance.new("Frame")
    nc.Size=UDim2.new(1,-80,1,0); nc.Position=UDim2.new(0,76,0,0)
    nc.BackgroundTransparency=1; nc.ZIndex=5; nc.Parent=row

    local nl = Instance.new("TextLabel")
    nl.Text=tgt.Name; nl.Size=UDim2.new(1,0,0.55,0); nl.Position=UDim2.new(0,0,0,4)
    nl.BackgroundTransparency=1; nl.TextColor3=C.Txt; nl.Font=Enum.Font.GothamBold
    nl.TextSize=13; nl.TextXAlignment=Enum.TextXAlignment.Left
    nl.TextTruncate=Enum.TextTruncate.AtEnd; nl.ZIndex=6; nl.Parent=nc

    local tl = Instance.new("TextLabel")
    tl.Text=tgt.Type; tl.Size=UDim2.new(1,0,0.45,0); tl.Position=UDim2.new(0,0,0.5,2)
    tl.BackgroundTransparency=1; tl.TextColor3=vColors[tgt.Type] or C.Mute
    tl.Font=Enum.Font.Gotham; tl.TextSize=10; tl.TextXAlignment=Enum.TextXAlignment.Left
    tl.ZIndex=6; tl.Parent=nc

    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.ZIndex=7; btn.Parent=row

    local rd = {button=row, baseColor=C.Sec, isHovered=false}
    table.insert(syncedButtons, rd)

    local function vis()
        local s = selectedTargets[mdl] ~= nil
        if s then
            TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=C.Sel,BackgroundTransparency=0.1}):Play()
            TweenService:Create(cb,TweenInfo.new(0.15),{BackgroundColor3=C.Check}):Play()
            cb:FindFirstChildOfClass("UIStroke").Color=C.Check
            cb:FindFirstChildOfClass("UIStroke").Transparency=0
            cm.Text="✓"; rd.baseColor=C.Sel
        else
            TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=C.Sec,BackgroundTransparency=0.2}):Play()
            TweenService:Create(cb,TweenInfo.new(0.15),{BackgroundColor3=C.Ter}):Play()
            cb:FindFirstChildOfClass("UIStroke").Color=C.Brd
            cb:FindFirstChildOfClass("UIStroke").Transparency=0.2
            cm.Text=""; rd.baseColor=C.Sec
        end
    end

    btn.MouseButton1Click:Connect(function()
        if selectedTargets[mdl] then selectedTargets[mdl]=nil
        else selectedTargets[mdl]={Model=mdl, HRP=tgt.HRP, Type=tgt.Type, Name=tgt.Name} end
        vis(); updStatus()
    end)

    btn.MouseEnter:Connect(function() rd.isHovered=true end)
    btn.MouseLeave:Connect(function() rd.isHovered=false; vis() end)

    vehicleElements[mdl] = {row=row, rd=rd, vis=vis, tgt=tgt}
end

-- ═══════════════════════════════════════
-- ОБНОВЛЕНИЕ СПИСКА
-- ═══════════════════════════════════════
local function refreshList()
    for m, e in pairs(vehicleElements) do
        for i=#syncedButtons,1,-1 do
            if syncedButtons[i].button==e.row then table.remove(syncedButtons,i) end
        end
        e.row:Destroy()
    end
    vehicleElements = {}

    scanVehicles()

    local keep = {}
    for _,t in ipairs(targetInstances) do
        if selectedTargets[t.Model] then
            keep[t.Model] = {Model=t.Model, HRP=t.HRP, Type=t.Type, Name=t.Name}
        end
    end
    selectedTargets = keep

    for _,t in ipairs(targetInstances) do
        makeVehicleRow(t)
        if selectedTargets[t.Model] then vehicleElements[t.Model].vis() end
    end

    cntLbl.Text = "🚗 "..#targetInstances.." found"
    task.defer(function()
        scroll.CanvasSize = UDim2.new(0,0,0, lay.AbsoluteContentSize.Y+10)
    end)
    updStatus()
end

-- ═══════════════════════════════════════
-- КНОПКИ УПРАВЛЕНИЯ — РЯД 1
-- ═══════════════════════════════════════
local r1 = Instance.new("Frame")
r1.Size=UDim2.new(1,0,0,34); r1.Position=UDim2.new(0,0,0,308)
r1.BackgroundTransparency=1; r1.ZIndex=2; r1.Parent=content

local sa = Instance.new("TextButton")
sa.Text="✅ Select All"; sa.Size=UDim2.new(0.48,0,1,0); sa.BackgroundColor3=C.Ter
sa.BackgroundTransparency=0.1; sa.TextColor3=C.Txt; sa.Font=Enum.Font.GothamBold
sa.TextSize=11; sa.ZIndex=2; sa.Parent=r1; corner(sa,10); stroke(sa,C.Brd,1,0.4); hoverFx(sa,C.Ter)

sa.MouseButton1Click:Connect(function()
    for m,e in pairs(vehicleElements) do
        selectedTargets[m]={Model=m, HRP=e.tgt.HRP, Type=e.tgt.Type, Name=e.tgt.Name}
        e.vis()
    end
    updStatus()
end)

local ca = Instance.new("TextButton")
ca.Text="🗑️ Clear All"; ca.Size=UDim2.new(0.48,0,1,0); ca.Position=UDim2.new(0.52,0,0,0)
ca.BackgroundColor3=C.Ter; ca.BackgroundTransparency=0.1; ca.TextColor3=C.Txt
ca.Font=Enum.Font.GothamBold; ca.TextSize=11; ca.ZIndex=2; ca.Parent=r1
corner(ca,10); stroke(ca,C.Brd,1,0.4); hoverFx(ca,C.Ter)

ca.MouseButton1Click:Connect(function()
    selectedTargets={}
    for _,e in pairs(vehicleElements) do e.vis() end
    updStatus()
end)

-- КНОПКИ — РЯД 2
local r2 = Instance.new("Frame")
r2.Size=UDim2.new(1,0,0,34); r2.Position=UDim2.new(0,0,0,348)
r2.BackgroundTransparency=1; r2.ZIndex=2; r2.Parent=content

local ab = Instance.new("TextButton")
ab.Text="🛩️ Air Only"; ab.Size=UDim2.new(0.48,0,1,0); ab.BackgroundColor3=C.Air
ab.BackgroundTransparency=0.15; ab.TextColor3=C.Txt; ab.Font=Enum.Font.GothamBold
ab.TextSize=11; ab.ZIndex=2; ab.Parent=r2; corner(ab,10); stroke(ab,C.Brd,1,0.4); hoverFx(ab,C.Air)

ab.MouseButton1Click:Connect(function()
    selectedTargets={}
    for m,e in pairs(vehicleElements) do
        local tp=e.tgt.Type
        if tp=="Helicopter" or tp=="Plane" or tp=="Gunship" then
            selectedTargets[m]={Model=m, HRP=e.tgt.HRP, Type=tp, Name=e.tgt.Name}
        end
        e.vis()
    end
    updStatus()
end)

local gb = Instance.new("TextButton")
gb.Text="🚤 Ground/Sea"; gb.Size=UDim2.new(0.48,0,1,0); gb.Position=UDim2.new(0.52,0,0,0)
gb.BackgroundColor3=C.Ground; gb.BackgroundTransparency=0.15; gb.TextColor3=C.Txt
gb.Font=Enum.Font.GothamBold; gb.TextSize=11; gb.ZIndex=2; gb.Parent=r2
corner(gb,10); stroke(gb,C.Brd,1,0.4); hoverFx(gb,C.Ground)

gb.MouseButton1Click:Connect(function()
    selectedTargets={}
    for m,e in pairs(vehicleElements) do
        local tp=e.tgt.Type
        if tp=="Boat" or tp=="Tank" or tp=="Hovercraft" then
            selectedTargets[m]={Model=m, HRP=e.tgt.HRP, Type=tp, Name=e.tgt.Name}
        end
        e.vis()
    end
    updStatus()
end)

-- ═══════════════════════════════════════
-- КНОПКА СТАРТ/СТОП
-- ═══════════════════════════════════════
local spamOn = false
local threads = {}

local goBtn = Instance.new("TextButton")
goBtn.Text="⚡️ START"; goBtn.Size=UDim2.new(1,0,0,52); goBtn.Position=UDim2.new(0,0,0,390)
goBtn.BackgroundColor3=C.Bad; goBtn.BackgroundTransparency=0.05; goBtn.TextColor3=C.Txt
goBtn.Font=Enum.Font.GothamBlack; goBtn.TextSize=16; goBtn.ZIndex=2; goBtn.Parent=content
corner(goBtn,14)

local goStroke = stroke(goBtn, C.Bad, 2, 0.2)

local goGlow = Instance.new("Frame")
goGlow.Size=UDim2.new(1,4,1,4); goGlow.Position=UDim2.new(0,-2,0,-2)
goGlow.BackgroundTransparency=1; goGlow.ZIndex=1; goGlow.Parent=goBtn

local goGS = Instance.new("UIStroke")
goGS.Color=C.Bad; goGS.Thickness=3; goGS.Transparency=0.6
goGS.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; goGS.Parent=goGlow
corner(goGlow,16)

local infoLbl = Instance.new("TextLabel")
infoLbl.Text="🔄 Auto-refresh 3s | Select vehicles then START"
infoLbl.Size=UDim2.new(1,0,0,22); infoLbl.Position=UDim2.new(0,0,0,448)
infoLbl.BackgroundTransparency=1; infoLbl.TextColor3=C.Mute; infoLbl.Font=Enum.Font.Gotham
infoLbl.TextSize=10; infoLbl.ZIndex=2; infoLbl.Parent=content

-- ═══════════════════════════════════════
-- АТАКА ПО ТРАНСПОРТУ
-- ═══════════════════════════════════════
local function attackVehicle(td)
    if not td or not td.Model or not td.Model.Parent then return false end
    local vH = td.HRP
    if not vH or not vH.Parent then return false end

    if not tool or not tool.Parent then
        tool = findRPG()
        if not tool then return false end
    end

    local pos = vH.Position
    local dir = (pos - hrp.Position).Unit

    -- Коррекция высоты
    if td.Type == "Boat" then
        pos = pos + Vector3.new(0, 3, 0)
    elseif td.Type == "Tank" then
        pos = pos + Vector3.new(0, 1.5, 0)
    elseif td.Type == "Hovercraft" then
        pos = pos + Vector3.new(0, 2, 0)
    elseif td.Type == "Plane" then
        pos = pos + Vector3.new(0, 1, 0)
    end

    -- 1) Перезарядка
    pcall(function() fx:FireServer(tool, false) end)

    -- 2) Выстрел ракеты
    pcall(function()
        fire:FireServer({
            ["Direction"] = dir,
            ["Settings"] = {
                ["expShake"] = {
                    ["fadeInTime"] = 0.05, ["magnitude"] = 3,
                    ["rotInfluence"] = Vector3.new(0.4, 0, 0.4),
                    ["fadeOutTime"] = 0.5,
                    ["posInfluence"] = Vector3.new(1, 1, 0),
                    ["roughness"] = 3,
                },
                ["gravity"] = Vector3.new(0, -20, 0),
                ["HelicopterDamage"] = 450,
                ["FireRate"] = 15,
                ["VehicleDamage"] = 350,
                ["ExpName"] = "RPG",
                ["RocketAmount"] = 1,
                ["ExpRadius"] = 12,
                ["BoatDamage"] = 300,
                ["TankDamage"] = 300,
                ["Acceleration"] = 8,
                ["ShieldDamage"] = 170,
                ["Distance"] = 4000,
                ["PlaneDamage"] = 500,
                ["GunshipDamage"] = 170,
                ["velocity"] = 200,
                ["ExplosionDamage"] = 120,
            },
            ["Origin"] = hrp.Position,
            ["PlrFired"] = plr,
            ["Vehicle"] = tool,
            ["RocketModel"] = game.ReplicatedStorage.RocketSystem.Rockets["RPG Rocket"],
            ["Weapon"] = tool,
        })
    end)

    -- 3) Удар по транспорту
    pcall(function()
        hit:FireServer({
            ["Normal"] = Vector3.new(0, 1, 0),
            ["HitPart"] = vH,
            ["Position"] = pos,
            ["Label"] = plr.Name .. "Rocket" .. cnt,
            ["Vehicle"] = tool,
            ["Player"] = plr,
            ["Weapon"] = tool,
        })
    end)

    cnt = cnt + 1
    return true
end

-- ═══════════════════════════════════════
-- СТАРТ / СТОП
-- ═══════════════════════════════════════
goBtn.MouseButton1Click:Connect(function()
    spamOn = not spamOn

    if spamOn then
        local n = 0
        for _ in pairs(selectedTargets) do n=n+1 end

        if n == 0 then
            statLbl.Text="❌ Select targets first!"; statLbl.TextColor3=C.Bad
            spamOn = false; return
        end

        if not tool then
            tool = findRPG()
            if not tool then
                statLbl.Text="❌ Need RPG!"; statLbl.TextColor3=C.Bad
                spamOn = false; return
            end
        end

        goBtn.Text="⏹️ STOP"
        TweenService:Create(goBtn,TweenInfo.new(0.25),{BackgroundColor3=C.Ok}):Play()
        TweenService:Create(goStroke,TweenInfo.new(0.25),{Color=C.Ok}):Play()
        TweenService:Create(goGS,TweenInfo.new(0.25),{Color=C.Ok,Transparency=0.4}):Play()
        statLbl.Text="🔥 Active — "..n.." target"..(n>1 and "s" or "")
        statLbl.TextColor3=C.Ok

        threads["main"] = task.spawn(function()
            while spamOn do
                for _, td in pairs(selectedTargets) do
                    if spamOn and td.Model and td.Model.Parent then
                        attackVehicle(td)
                        task.wait(0.05)
                    end
                end
                task.wait(0.1)
            end
        end)

        for i=1,3 do
            threads["t"..i] = task.spawn(function()
                while spamOn do
                    for _, td in pairs(selectedTargets) do
                        if spamOn and td.Model and td.Model.Parent then
                            task.spawn(attackVehicle, td)
                        end
                    end
                    task.wait(0.03)
                end
            end)
        end
    else
        goBtn.Text="⚡️ START"
        TweenService:Create(goBtn,TweenInfo.new(0.25),{BackgroundColor3=C.Bad}):Play()
        TweenService:Create(goStroke,TweenInfo.new(0.25),{Color=C.Bad}):Play()
        TweenService:Create(goGS,TweenInfo.new(0.25),{Color=C.Bad,Transparency=0.6}):Play()
        statLbl.Text="💤 Stopped"; statLbl.TextColor3=C.Dim

        for _,th in pairs(threads) do pcall(task.cancel,th) end
        threads = {}
    end
end)

-- ═══════════════════════════════════════
-- ЗАКРЫТЬ / СВЕРНУТЬ
-- ═══════════════════════════════════════
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

local minimized = false
local origSize = mainFrame.Size

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(mainFrame,TweenInfo.new(0.3,Enum.EasingStyle.Quart),{Size=UDim2.new(0,380,0,60)}):Play()
        minBtn.Text="+"; content.Visible=false
    else
        TweenService:Create(mainFrame,TweenInfo.new(0.3,Enum.EasingStyle.Quart),{Size=origSize}):Play()
        minBtn.Text="−"; task.wait(0.15); content.Visible=true
    end
end)

-- ═══════════════════════════════════════
-- ПЛАВАЮЩАЯ КНОПКА (TOGGLE GUI)
-- ═══════════════════════════════════════
local floatBtn = Instance.new("TextButton")
floatBtn.Name="Toggle"; floatBtn.Text="🚀"; floatBtn.Size=UDim2.new(0,50,0,50)
floatBtn.Position=UDim2.new(0,16,0.5,-25); floatBtn.BackgroundColor3=C.Bg
floatBtn.TextColor3=C.Txt; floatBtn.Font=Enum.Font.SourceSans; floatBtn.TextSize=24
floatBtn.ZIndex=10; floatBtn.Active=true; floatBtn.Parent=gui
corner(floatBtn,25); stroke(floatBtn,C.Glow,2,0.3)

local fSh = Instance.new("ImageLabel")
fSh.BackgroundTransparency=1; fSh.Image="rbxassetid://6014261993"
fSh.ImageColor3=Color3.new(0,0,0); fSh.ImageTransparency=0.4
fSh.ScaleType=Enum.ScaleType.Slice; fSh.SliceCenter=Rect.new(49,49,450,450)
fSh.Size=UDim2.new(1,40,1,40); fSh.Position=UDim2.new(0,-20,0,-20)
fSh.ZIndex=9; fSh.Parent=floatBtn

-- Drag для плавающей кнопки
local fd,fdi,fds,fsp
floatBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        fd=true; fds=i.Position; fsp=floatBtn.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then fd=false end end)
    end
end)
floatBtn.InputChanged:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseMovement then fdi=i end
end)
UserInputService.InputChanged:Connect(function(i)
    if i==fdi and fd then
        local d=i.Position-fds
        floatBtn.Position=UDim2.new(fsp.X.Scale,fsp.X.Offset+d.X, fsp.Y.Scale,fsp.Y.Offset+d.Y)
    end
end)

floatBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    if mainFrame.Visible then
        local s = floatBtn:FindFirstChildOfClass("UIStroke")
        if s then
            TweenService:Create(s,TweenInfo.new(0.3),{Color=C.Ok,Transparency=0}):Play()
            task.delay(0.3,function()
                if s and s.Parent then
                    TweenService:Create(s,TweenInfo.new(0.3),{Color=C.Glow,Transparency=0.3}):Play()
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- РЕСПАВН
-- ═══════════════════════════════════════
plr.CharacterAdded:Connect(function(nc)
    char = nc
    hrp = nc:WaitForChild("HumanoidRootPart")
    tool = nc:WaitForChild("RPG", 5)
    if not tool then
        local bp = plr:FindFirstChild("Backpack")
        if bp then tool = bp:FindFirstChild("RPG") end
    end
end)

-- ═══════════════════════════════════════
-- ИНИЦИАЛИЗАЦИЯ + АВТО-ОБНОВЛЕНИЕ
-- ═══════════════════════════════════════
refreshList()

task.spawn(function()
    while true do
        task.wait(3)
        refreshList()
    end
end)
