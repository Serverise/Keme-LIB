local ESPModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Drawings = {
    ESP = {},
    Skeleton = {}
}

local Colors = {
    Enemy = Color3.fromRGB(255, 25, 25),
    Ally = Color3.fromRGB(25, 255, 25),
    Health = Color3.fromRGB(0, 255, 0),
    Rainbow = Color3.fromRGB(255, 255, 255)
}

local Highlights = {}
local UpdateConnection = nil
local RainbowConnection = nil

ESPModule.Settings = {
    Enabled = false,
    TeamCheck = false,
    ShowTeam = false,
    BoxESP = false,
    BoxStyle = "Corner",
    BoxThickness = 1,
    TracerESP = false,
    TracerOrigin = "Bottom",
    TracerThickness = 1,
    HealthESP = false,
    HealthStyle = "Bar",
    HealthTextSuffix = "HP",
    NameESP = false,
    TextSize = 14,
    TextFont = 2,
    RainbowSpeed = 1,
    MaxDistance = 1000,
    RefreshRate = 1/60,
    Snaplines = false,
    RainbowEnabled = false,
    RainbowBoxes = false,
    RainbowTracers = false,
    RainbowText = false,
    InvisibleChamsEnabled = false,
    VisibleChamsEnabled = false,
    InvisibleChamsColor = Color3.fromRGB(255, 0, 0),
    VisibleChamsColor = Color3.fromRGB(0, 255, 0),
    ChamsTransparency = 0.5,
    ChamsOutlineTransparency = 0,
    SkeletonESP = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1.5,
    SkeletonTransparency = 1
}

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local box = {
        TopLeft = Drawing.new("Line"),
        TopRight = Drawing.new("Line"),
        BottomLeft = Drawing.new("Line"),
        BottomRight = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line")
    }
    
    for _, line in pairs(box) do
        line.Visible = false
        line.Color = Colors.Enemy
        line.Thickness = ESPModule.Settings.BoxThickness
        line.ZIndex = 1
    end
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Colors.Enemy
    tracer.Thickness = ESPModule.Settings.TracerThickness
    tracer.ZIndex = 1
    
    local healthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    
    healthBar.Outline.Visible = false
    healthBar.Outline.Filled = false
    healthBar.Outline.Thickness = 1
    healthBar.Outline.Color = Color3.fromRGB(0, 0, 0)
    healthBar.Outline.ZIndex = 1
    healthBar.Fill.Visible = false
    healthBar.Fill.Color = Colors.Health
    healthBar.Fill.Filled = true
    healthBar.Fill.ZIndex = 2
    healthBar.Text.Visible = false
    healthBar.Text.Center = true
    healthBar.Text.Size = ESPModule.Settings.TextSize
    healthBar.Text.Color = Colors.Health
    healthBar.Text.Font = ESPModule.Settings.TextFont
    healthBar.Text.Outline = true
    healthBar.Text.ZIndex = 3
    
    local info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    for _, text in pairs(info) do
        text.Visible = false
        text.Center = true
        text.Size = ESPModule.Settings.TextSize
        text.Color = Colors.Enemy
        text.Font = ESPModule.Settings.TextFont
        text.Outline = true
        text.ZIndex = 3
    end
    
    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Color = Colors.Enemy
    snapline.Thickness = 1
    snapline.ZIndex = 1
    
    local invisibleHighlight = Instance.new("Highlight")
    invisibleHighlight.Name = "InvisibleChams_" .. player.Name
    invisibleHighlight.FillColor = ESPModule.Settings.InvisibleChamsColor
    invisibleHighlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    invisibleHighlight.FillTransparency = ESPModule.Settings.ChamsTransparency
    invisibleHighlight.OutlineTransparency = 1
    invisibleHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
    invisibleHighlight.Enabled = false
    
    local visibleHighlight = Instance.new("Highlight")
    visibleHighlight.Name = "VisibleChams_" .. player.Name
    visibleHighlight.FillColor = ESPModule.Settings.VisibleChamsColor
    visibleHighlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    visibleHighlight.FillTransparency = ESPModule.Settings.ChamsTransparency
    visibleHighlight.OutlineTransparency = 1
    visibleHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    visibleHighlight.Enabled = false
    
    Highlights[player] = {
        Invisible = invisibleHighlight,
        Visible = visibleHighlight
    }
    
    local skeleton = {}
    local boneNames = {
        "Head", "Neck", "UpperSpine", "LowerSpine",
        "LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftHip", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightHip", "RightUpperLeg", "RightLowerLeg", "RightFoot"
    }
    
    for _, boneName in ipairs(boneNames) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = ESPModule.Settings.SkeletonColor
        line.Thickness = ESPModule.Settings.SkeletonThickness
        line.Transparency = ESPModule.Settings.SkeletonTransparency
        line.ZIndex = 1
        skeleton[boneName] = line
    end
    
    Drawings.Skeleton[player] = skeleton
    
    Drawings.ESP[player] = {
        Box = box,
        Tracer = tracer,
        HealthBar = healthBar,
        Info = info,
        Snapline = snapline
    }
end

local function RemoveESP(player)
    local esp = Drawings.ESP[player]
    if esp then
        for _, obj in pairs(esp.Box) do 
            pcall(function() obj:Remove() end)
        end
        pcall(function() esp.Tracer:Remove() end)
        for _, obj in pairs(esp.HealthBar) do 
            pcall(function() obj:Remove() end)
        end
        for _, obj in pairs(esp.Info) do 
            pcall(function() obj:Remove() end)
        end
        pcall(function() esp.Snapline:Remove() end)
        Drawings.ESP[player] = nil
    end
    
    local highlights = Highlights[player]
    if highlights then
        pcall(function() highlights.Invisible:Destroy() end)
        pcall(function() highlights.Visible:Destroy() end)
        Highlights[player] = nil
    end
    
    local skeleton = Drawings.Skeleton[player]
    if skeleton then
        for _, line in pairs(skeleton) do
            pcall(function() line:Remove() end)
        end
        Drawings.Skeleton[player] = nil
    end
end

local function GetPlayerColor(player)
    if ESPModule.Settings.RainbowEnabled then
        if (ESPModule.Settings.RainbowBoxes and ESPModule.Settings.BoxESP) or 
           (ESPModule.Settings.RainbowTracers and ESPModule.Settings.TracerESP) or 
           (ESPModule.Settings.RainbowText and ESPModule.Settings.NameESP) then 
            return Colors.Rainbow 
        end
    end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return Colors.Ally
    end
    return Colors.Enemy
end

local function GetTracerOrigin()
    local origin = ESPModule.Settings.TracerOrigin
    if origin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif origin == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif origin == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

local function ShouldShowPlayer(player)
    if not player or player == LocalPlayer then return false end
    if ESPModule.Settings.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team and not ESPModule.Settings.ShowTeam then
        return false
    end
    return true
end

local function UpdateESP(player)
    if not ESPModule.Settings.Enabled or not player then return end
    
    local esp = Drawings.ESP[player]
    if not esp then return end
    
    local character = player.Character
    if not character then 
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return 
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not rootPart then 
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return 
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return
    end
    
    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not onScreen or distance > ESPModule.Settings.MaxDistance or pos.Z <= 0 then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return
    end
    
    if not ShouldShowPlayer(player) then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return
    end
    
    local color = GetPlayerColor(player)
    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    
    local top, top_onscreen = Camera:WorldToViewportPoint((cf * CFrame.new(0, size.Y/2, 0)).Position)
    local bottom, bottom_onscreen = Camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y/2, 0)).Position)
    
    if not top_onscreen or not bottom_onscreen or top.Z <= 0 or bottom.Z <= 0 then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end
    
    local screenSize = math.abs(bottom.Y - top.Y)
    local boxWidth = screenSize * 0.65
    local boxPosition = Vector2.new(top.X - boxWidth/2, math.min(top.Y, bottom.Y))
    local boxSize = Vector2.new(boxWidth, screenSize)
    
    for _, obj in pairs(esp.Box) do
        obj.Visible = false
    end
    
    if ESPModule.Settings.BoxESP then
        if ESPModule.Settings.BoxStyle == "ThreeD" then
            local corners = {}
            local function addCorner(x, y, z)
                local point = Camera:WorldToViewportPoint((cf * CFrame.new(x * size.X/2, y * size.Y/2, z * size.Z/2)).Position)
                if point.Z > 0 then
                    table.insert(corners, {x = point.X, y = point.Y, visible = true})
                else
                    table.insert(corners, {visible = false})
                end
            end
            
            addCorner(-1, 1, -1)
            addCorner(1, 1, -1)
            addCorner(-1, -1, -1)
            addCorner(1, -1, -1)
            addCorner(-1, 1, 1)
            addCorner(1, 1, 1)
            addCorner(-1, -1, 1)
            addCorner(1, -1, 1)
            
            local allVisible = true
            for _, corner in ipairs(corners) do
                if not corner.visible then
                    allVisible = false
                    break
                end
            end
            
            if allVisible then
                local lines = {
                    {1, 2}, {3, 4}, {1, 3}, {2, 4},
                    {5, 6}, {7, 8}, {5, 7}, {6, 8},
                    {1, 5}, {2, 6}, {3, 7}, {4, 8}
                }
                
                local boxParts = {esp.Box.TopLeft, esp.Box.TopRight, esp.Box.BottomLeft, esp.Box.BottomRight,
                                  esp.Box.Left, esp.Box.Right, esp.Box.Top, esp.Box.Bottom}
                
                for i, line in ipairs(lines) do
                    if boxParts[i] and corners[line[1]].visible and corners[line[2]].visible then
                        boxParts[i].From = Vector2.new(corners[line[1]].x, corners[line[1]].y)
                        boxParts[i].To = Vector2.new(corners[line[2]].x, corners[line[2]].y)
                        boxParts[i].Color = color
                        boxParts[i].Thickness = ESPModule.Settings.BoxThickness
                        boxParts[i].Visible = true
                    end
                end
            end
            
        elseif ESPModule.Settings.BoxStyle == "Corner" then
            local cornerSize = boxWidth * 0.25
            
            esp.Box.TopLeft.From = boxPosition
            esp.Box.TopLeft.To = boxPosition + Vector2.new(cornerSize, 0)
            esp.Box.TopLeft.Visible = true
            
            esp.Box.TopRight.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.TopRight.To = boxPosition + Vector2.new(boxSize.X - cornerSize, 0)
            esp.Box.TopRight.Visible = true
            
            esp.Box.BottomLeft.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.BottomLeft.To = boxPosition + Vector2.new(cornerSize, boxSize.Y)
            esp.Box.BottomLeft.Visible = true
            
            esp.Box.BottomRight.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.BottomRight.To = boxPosition + Vector2.new(boxSize.X - cornerSize, boxSize.Y)
            esp.Box.BottomRight.Visible = true
            
            esp.Box.Left.From = boxPosition
            esp.Box.Left.To = boxPosition + Vector2.new(0, cornerSize)
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, cornerSize)
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Top.To = boxPosition + Vector2.new(0, boxSize.Y - cornerSize)
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y - cornerSize)
            esp.Box.Bottom.Visible = true
            
        else
            esp.Box.Left.From = boxPosition
            esp.Box.Left.To = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = boxPosition
            esp.Box.Top.To = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Bottom.Visible = true
        end
        
        for _, obj in pairs(esp.Box) do
            if obj.Visible then
                obj.Color = color
                obj.Thickness = ESPModule.Settings.BoxThickness
            end
        end
    end
    
    if ESPModule.Settings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Thickness = ESPModule.Settings.TracerThickness
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end
    
    if ESPModule.Settings.HealthESP then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = math.clamp(health/maxHealth, 0, 1)
        
        local barHeight = screenSize
        local barWidth = 4
        local barPos = Vector2.new(
            boxPosition.X - barWidth - 2,
            boxPosition.Y
        )
        
        esp.HealthBar.Outline.Size = Vector2.new(barWidth + 2, barHeight + 2)
        esp.HealthBar.Outline.Position = Vector2.new(barPos.X - 1, barPos.Y - 1)
        esp.HealthBar.Outline.Visible = true
        
        local fillHeight = math.max(barHeight * healthPercent, 1)
        esp.HealthBar.Fill.Size = Vector2.new(barWidth, fillHeight)
        esp.HealthBar.Fill.Position = Vector2.new(barPos.X, barPos.Y + barHeight - fillHeight)
        esp.HealthBar.Fill.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        esp.HealthBar.Fill.Visible = true
        
        if ESPModule.Settings.HealthStyle == "Both" or ESPModule.Settings.HealthStyle == "Text" then
            esp.HealthBar.Text.Text = tostring(math.floor(health)) .. " " .. ESPModule.Settings.HealthTextSuffix
            esp.HealthBar.Text.Position = Vector2.new(barPos.X - 15, barPos.Y + barHeight/2)
            esp.HealthBar.Text.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
            esp.HealthBar.Text.Visible = true
        else
            esp.HealthBar.Text.Visible = false
        end
    else
        for _, obj in pairs(esp.HealthBar) do
            obj.Visible = false
        end
    end
    
    if ESPModule.Settings.NameESP then
        local displayName = player.DisplayName or player.Name
        esp.Info.Name.Text = displayName
        esp.Info.Name.Position = Vector2.new(
            boxPosition.X + boxWidth/2,
            boxPosition.Y - 18
        )
        esp.Info.Name.Color = color
        esp.Info.Name.Size = ESPModule.Settings.TextSize
        esp.Info.Name.Visible = true
    else
        esp.Info.Name.Visible = false
    end
    
    if ESPModule.Settings.Snaplines then
        esp.Snapline.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        esp.Snapline.To = Vector2.new(pos.X, pos.Y)
        esp.Snapline.Color = color
        esp.Snapline.Thickness = 1
        esp.Snapline.Visible = true
    else
        esp.Snapline.Visible = false
    end
    
    local highlights = Highlights[player]
    if highlights then
        local showChams = ShouldShowPlayer(player)
        
        if ESPModule.Settings.InvisibleChamsEnabled and character and showChams then
            if highlights.Invisible.Parent ~= character then
                highlights.Invisible.Parent = character
            end
            highlights.Invisible.FillColor = ESPModule.Settings.InvisibleChamsColor
            highlights.Invisible.FillTransparency = ESPModule.Settings.ChamsTransparency
            highlights.Invisible.OutlineTransparency = ESPModule.Settings.ChamsOutlineTransparency
            highlights.Invisible.Enabled = true
        else
            highlights.Invisible.Enabled = false
        end
        
        if ESPModule.Settings.VisibleChamsEnabled and character and showChams then
            if highlights.Visible.Parent ~= character then
                highlights.Visible.Parent = character
            end
            highlights.Visible.FillColor = ESPModule.Settings.VisibleChamsColor
            highlights.Visible.FillTransparency = ESPModule.Settings.ChamsTransparency
            highlights.Visible.OutlineTransparency = ESPModule.Settings.ChamsOutlineTransparency
            highlights.Visible.Enabled = true
        else
            highlights.Visible.Enabled = false
        end
    end
    
    if ESPModule.Settings.SkeletonESP and character then
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            local function getBone(name)
                return character:FindFirstChild(name)
            end
            
            local head = getBone("Head")
            local upperTorso = getBone("UpperTorso") or getBone("Torso")
            local lowerTorso = getBone("LowerTorso") or upperTorso
            
            local leftUpperArm = getBone("LeftUpperArm") or getBone("Left Arm")
            local leftLowerArm = getBone("LeftLowerArm") or leftUpperArm
            local leftHand = getBone("LeftHand") or leftLowerArm
            
            local rightUpperArm = getBone("RightUpperArm") or getBone("Right Arm")
            local rightLowerArm = getBone("RightLowerArm") or rightUpperArm
            local rightHand = getBone("RightHand") or rightLowerArm
            
            local leftUpperLeg = getBone("LeftUpperLeg") or getBone("Left Leg")
            local leftLowerLeg = getBone("LeftLowerLeg") or leftUpperLeg
            local leftFoot = getBone("LeftFoot") or leftLowerLeg
            
            local rightUpperLeg = getBone("RightUpperLeg") or getBone("Right Leg")
            local rightLowerLeg = getBone("RightLowerLeg") or rightUpperLeg
            local rightFoot = getBone("RightFoot") or rightLowerLeg
            
            local function drawBone(from, to, line)
                if not from or not to or not line then 
                    if line then line.Visible = false end
                    return 
                end
                
                local fromPos = from.Position
                local toPos = to.Position
                
                local fromScreen, fromVisible = Camera:WorldToViewportPoint(fromPos)
                local toScreen, toVisible = Camera:WorldToViewportPoint(toPos)
                
                if fromVisible and toVisible and fromScreen.Z > 0 and toScreen.Z > 0 then
                    line.From = Vector2.new(fromScreen.X, fromScreen.Y)
                    line.To = Vector2.new(toScreen.X, toScreen.Y)
                    line.Color = ESPModule.Settings.SkeletonColor
                    line.Thickness = ESPModule.Settings.SkeletonThickness
                    line.Transparency = ESPModule.Settings.SkeletonTransparency
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
            
            if head and upperTorso then
                drawBone(head, upperTorso, skeleton.Head)
                
                if lowerTorso then
                    drawBone(upperTorso, lowerTorso, skeleton.UpperSpine)
                end
                
                if leftUpperArm then
                    drawBone(upperTorso, leftUpperArm, skeleton.LeftShoulder)
                    if leftLowerArm then
                        drawBone(leftUpperArm, leftLowerArm, skeleton.LeftUpperArm)
                        if leftHand then
                            drawBone(leftLowerArm, leftHand, skeleton.LeftLowerArm)
                        end
                    end
                end
                
                if rightUpperArm then
                    drawBone(upperTorso, rightUpperArm, skeleton.RightShoulder)
                    if rightLowerArm then
                        drawBone(rightUpperArm, rightLowerArm, skeleton.RightUpperArm)
                        if rightHand then
                            drawBone(rightLowerArm, rightHand, skeleton.RightLowerArm)
                        end
                    end
                end
                
                if lowerTorso then
                    if leftUpperLeg then
                        drawBone(lowerTorso, leftUpperLeg, skeleton.LeftHip)
                        if leftLowerLeg then
                            drawBone(leftUpperLeg, leftLowerLeg, skeleton.LeftUpperLeg)
                            if leftFoot then
                                drawBone(leftLowerLeg, leftFoot, skeleton.LeftLowerLeg)
                            end
                        end
                    end
                    
                    if rightUpperLeg then
                        drawBone(lowerTorso, rightUpperLeg, skeleton.RightHip)
                        if rightLowerLeg then
                            drawBone(rightUpperLeg, rightLowerLeg, skeleton.RightUpperLeg)
                            if rightFoot then
                                drawBone(rightLowerLeg, rightFoot, skeleton.RightLowerLeg)
                            end
                        end
                    end
                end
            else
                for _, line in pairs(skeleton) do
                    line.Visible = false
                end
            end
        end
    else
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
    end
end

local function DisableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local esp = Drawings.ESP[player]
        if esp then
            for _, obj in pairs(esp.Box) do obj.Visible = false end
            esp.Tracer.Visible = false
            for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
            for _, obj in pairs(esp.Info) do obj.Visible = false end
            esp.Snapline.Visible = false
        end
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        
        local highlights = Highlights[player]
        if highlights then
            highlights.Invisible.Enabled = false
            highlights.Visible.Enabled = false
        end
    end
end

function ESPModule:Start()
    if UpdateConnection then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        task.wait(0.1)
        CreateESP(player)
    end)
    
    Players.PlayerRemoving:Connect(RemoveESP)
    
    local lastUpdate = 0
    UpdateConnection = RunService.Heartbeat:Connect(function()
        if not ESPModule.Settings.Enabled then 
            DisableESP()
            return 
        end
        
        local currentTime = tick()
        if currentTime - lastUpdate >= ESPModule.Settings.RefreshRate then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    if not Drawings.ESP[player] then
                        CreateESP(player)
                    end
                    pcall(UpdateESP, player)
                end
            end
            lastUpdate = currentTime
        end
    end)
    
    RainbowConnection = task.spawn(function()
        while task.wait(0.01) do
            Colors.Rainbow = Color3.fromHSV((tick() * ESPModule.Settings.RainbowSpeed) % 1, 1, 1)
        end
    end)
end

function ESPModule:Stop()
    if UpdateConnection then
        UpdateConnection:Disconnect()
        UpdateConnection = nil
    end
    
    if RainbowConnection then
        task.cancel(RainbowConnection)
        RainbowConnection = nil
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        RemoveESP(player)
    end
    
    Drawings.ESP = {}
    Drawings.Skeleton = {}
    Highlights = {}
end

function ESPModule:UpdateColors(enemyColor, allyColor, healthColor)
    if enemyColor then Colors.Enemy = enemyColor end
    if allyColor then Colors.Ally = allyColor end
    if healthColor then Colors.Health = healthColor end
end

return ESPModule
