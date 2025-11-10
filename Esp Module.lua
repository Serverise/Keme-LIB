local ESPModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
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

local function CreateDrawing(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if Drawings.ESP[player] then return end
    
    local box = {}
    for _, name in ipairs({"TopLeft", "TopRight", "BottomLeft", "BottomRight", "Left", "Right", "Top", "Bottom"}) do
        box[name] = CreateDrawing("Line", {
            Visible = false,
            Color = Colors.Enemy,
            Thickness = 1,
            ZIndex = 2
        })
    end
    
    local tracer = CreateDrawing("Line", {
        Visible = false,
        Color = Colors.Enemy,
        Thickness = 1,
        ZIndex = 1
    })
    
    local healthBar = {
        Outline = CreateDrawing("Square", {
            Visible = false,
            Filled = false,
            Thickness = 1,
            Color = Color3.fromRGB(0, 0, 0),
            ZIndex = 1
        }),
        Fill = CreateDrawing("Square", {
            Visible = false,
            Filled = true,
            Color = Colors.Health,
            ZIndex = 2
        }),
        Text = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Size = 13,
            Color = Color3.fromRGB(255, 255, 255),
            Font = 2,
            Outline = true,
            ZIndex = 3
        })
    }
    
    local info = {
        Name = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Size = 13,
            Color = Colors.Enemy,
            Font = 2,
            Outline = true,
            ZIndex = 3
        }),
        Distance = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Size = 13,
            Color = Colors.Enemy,
            Font = 2,
            Outline = true,
            ZIndex = 3
        })
    }
    
    local snapline = CreateDrawing("Line", {
        Visible = false,
        Color = Colors.Enemy,
        Thickness = 1,
        ZIndex = 1
    })
    
    local invisibleHighlight = Instance.new("Highlight")
    invisibleHighlight.Name = "InvisibleChams"
    invisibleHighlight.FillColor = ESPModule.Settings.InvisibleChamsColor
    invisibleHighlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    invisibleHighlight.FillTransparency = ESPModule.Settings.ChamsTransparency
    invisibleHighlight.OutlineTransparency = 1
    invisibleHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
    invisibleHighlight.Enabled = false
    
    local visibleHighlight = Instance.new("Highlight")
    visibleHighlight.Name = "VisibleChams"
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
        "Head", "Neck", "Torso", "LeftShoulder", "LeftUpperArm", "LeftLowerArm",
        "RightShoulder", "RightUpperArm", "RightLowerArm", "Pelvis",
        "LeftHip", "LeftUpperLeg", "LeftLowerLeg", "RightHip", "RightUpperLeg", "RightLowerLeg"
    }
    
    for _, boneName in ipairs(boneNames) do
        skeleton[boneName] = CreateDrawing("Line", {
            Visible = false,
            Color = ESPModule.Settings.SkeletonColor,
            Thickness = ESPModule.Settings.SkeletonThickness,
            Transparency = ESPModule.Settings.SkeletonTransparency,
            ZIndex = 2
        })
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
    pcall(function()
        local esp = Drawings.ESP[player]
        if esp then
            for _, obj in pairs(esp.Box) do obj:Remove() end
            esp.Tracer:Remove()
            for _, obj in pairs(esp.HealthBar) do obj:Remove() end
            for _, obj in pairs(esp.Info) do obj:Remove() end
            esp.Snapline:Remove()
            Drawings.ESP[player] = nil
        end
        
        local highlights = Highlights[player]
        if highlights then
            highlights.Invisible:Destroy()
            highlights.Visible:Destroy()
            Highlights[player] = nil
        end
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do line:Remove() end
            Drawings.Skeleton[player] = nil
        end
    end)
end

local function GetPlayerColor(player)
    if ESPModule.Settings.RainbowEnabled then
        if ESPModule.Settings.RainbowBoxes or ESPModule.Settings.RainbowTracers or ESPModule.Settings.RainbowText then
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
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    elseif origin == "Top" then
        return Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif origin == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end

local function ShouldShowPlayer(player)
    if not player or player == LocalPlayer then return false end
    
    if ESPModule.Settings.TeamCheck then
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            if not ESPModule.Settings.ShowTeam then
                return false
            end
        end
    end
    
    return true
end

local function HideESP(player)
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
        for _, line in pairs(skeleton) do line.Visible = false end
    end
    
    local highlights = Highlights[player]
    if highlights then
        highlights.Invisible.Enabled = false
        highlights.Visible.Enabled = false
    end
end

local function UpdateESP(player)
    if not ESPModule.Settings.Enabled then return end
    if not player or not player.Parent then return end
    
    local esp = Drawings.ESP[player]
    if not esp then 
        CreateESP(player)
        return
    end
    
    local character = player.Character
    if not character then
        HideESP(player)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        HideESP(player)
        return
    end
    
    local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not onScreen or rootPos.Z <= 0 or distance > ESPModule.Settings.MaxDistance then
        HideESP(player)
        return
    end
    
    if not ShouldShowPlayer(player) then
        HideESP(player)
        return
    end
    
    local color = GetPlayerColor(player)
    local size = character:GetExtentsSize()
    local hrpCFrame = rootPart.CFrame
    
    local topPos = Camera:WorldToViewportPoint((hrpCFrame * CFrame.new(0, size.Y / 2, 0)).Position)
    local bottomPos = Camera:WorldToViewportPoint((hrpCFrame * CFrame.new(0, -size.Y / 2, 0)).Position)
    
    if topPos.Z <= 0 or bottomPos.Z <= 0 then
        HideESP(player)
        return
    end
    
    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height * 0.6
    local boxX = topPos.X - width / 2
    local boxY = math.min(topPos.Y, bottomPos.Y)
    
    if ESPModule.Settings.BoxESP then
        if ESPModule.Settings.BoxStyle == "Corner" then
            local cornerLength = width / 4
            
            esp.Box.TopLeft.From = Vector2.new(boxX, boxY)
            esp.Box.TopLeft.To = Vector2.new(boxX + cornerLength, boxY)
            esp.Box.TopLeft.Color = color
            esp.Box.TopLeft.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.TopLeft.Visible = true
            
            esp.Box.TopRight.From = Vector2.new(boxX + width, boxY)
            esp.Box.TopRight.To = Vector2.new(boxX + width - cornerLength, boxY)
            esp.Box.TopRight.Color = color
            esp.Box.TopRight.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.TopRight.Visible = true
            
            esp.Box.BottomLeft.From = Vector2.new(boxX, boxY + height)
            esp.Box.BottomLeft.To = Vector2.new(boxX + cornerLength, boxY + height)
            esp.Box.BottomLeft.Color = color
            esp.Box.BottomLeft.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.BottomLeft.Visible = true
            
            esp.Box.BottomRight.From = Vector2.new(boxX + width, boxY + height)
            esp.Box.BottomRight.To = Vector2.new(boxX + width - cornerLength, boxY + height)
            esp.Box.BottomRight.Color = color
            esp.Box.BottomRight.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.BottomRight.Visible = true
            
            esp.Box.Left.From = Vector2.new(boxX, boxY)
            esp.Box.Left.To = Vector2.new(boxX, boxY + cornerLength)
            esp.Box.Left.Color = color
            esp.Box.Left.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = Vector2.new(boxX + width, boxY)
            esp.Box.Right.To = Vector2.new(boxX + width, boxY + cornerLength)
            esp.Box.Right.Color = color
            esp.Box.Right.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = Vector2.new(boxX, boxY + height)
            esp.Box.Top.To = Vector2.new(boxX, boxY + height - cornerLength)
            esp.Box.Top.Color = color
            esp.Box.Top.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = Vector2.new(boxX + width, boxY + height)
            esp.Box.Bottom.To = Vector2.new(boxX + width, boxY + height - cornerLength)
            esp.Box.Bottom.Color = color
            esp.Box.Bottom.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.Bottom.Visible = true
            
        else
            esp.Box.Left.From = Vector2.new(boxX, boxY)
            esp.Box.Left.To = Vector2.new(boxX, boxY + height)
            esp.Box.Left.Color = color
            esp.Box.Left.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = Vector2.new(boxX + width, boxY)
            esp.Box.Right.To = Vector2.new(boxX + width, boxY + height)
            esp.Box.Right.Color = color
            esp.Box.Right.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = Vector2.new(boxX, boxY)
            esp.Box.Top.To = Vector2.new(boxX + width, boxY)
            esp.Box.Top.Color = color
            esp.Box.Top.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = Vector2.new(boxX, boxY + height)
            esp.Box.Bottom.To = Vector2.new(boxX + width, boxY + height)
            esp.Box.Bottom.Color = color
            esp.Box.Bottom.Thickness = ESPModule.Settings.BoxThickness
            esp.Box.Bottom.Visible = true
            
            esp.Box.TopLeft.Visible = false
            esp.Box.TopRight.Visible = false
            esp.Box.BottomLeft.Visible = false
            esp.Box.BottomRight.Visible = false
        end
    else
        for _, line in pairs(esp.Box) do
            line.Visible = false
        end
    end
    
    if ESPModule.Settings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Thickness = ESPModule.Settings.TracerThickness
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end
    
    if ESPModule.Settings.HealthESP then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = math.clamp(health / maxHealth, 0, 1)
        
        local barWidth = 3
        local barHeight = height
        local barX = boxX - barWidth - 3
        local barY = boxY
        
        esp.HealthBar.Outline.Size = Vector2.new(barWidth + 2, barHeight + 2)
        esp.HealthBar.Outline.Position = Vector2.new(barX - 1, barY - 1)
        esp.HealthBar.Outline.Visible = true
        
        local fillHeight = math.max(barHeight * healthPercent, 1)
        esp.HealthBar.Fill.Size = Vector2.new(barWidth, fillHeight)
        esp.HealthBar.Fill.Position = Vector2.new(barX, barY + barHeight - fillHeight)
        esp.HealthBar.Fill.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        esp.HealthBar.Fill.Visible = true
        
        if ESPModule.Settings.HealthStyle == "Text" or ESPModule.Settings.HealthStyle == "Both" then
            esp.HealthBar.Text.Text = tostring(math.floor(health)) .. " " .. ESPModule.Settings.HealthTextSuffix
            esp.HealthBar.Text.Position = Vector2.new(barX + barWidth / 2, barY - 15)
            esp.HealthBar.Text.Size = ESPModule.Settings.TextSize
            esp.HealthBar.Text.Visible = true
        else
            esp.HealthBar.Text.Visible = false
        end
    else
        esp.HealthBar.Outline.Visible = false
        esp.HealthBar.Fill.Visible = false
        esp.HealthBar.Text.Visible = false
    end
    
    if ESPModule.Settings.NameESP then
        local displayName = player.DisplayName or player.Name
        esp.Info.Name.Text = displayName
        esp.Info.Name.Position = Vector2.new(boxX + width / 2, boxY - 18)
        esp.Info.Name.Color = color
        esp.Info.Name.Size = ESPModule.Settings.TextSize
        esp.Info.Name.Font = ESPModule.Settings.TextFont
        esp.Info.Name.Visible = true
    else
        esp.Info.Name.Visible = false
    end
    
    if ESPModule.Settings.Snaplines then
        esp.Snapline.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        esp.Snapline.To = Vector2.new(rootPos.X, rootPos.Y)
        esp.Snapline.Color = color
        esp.Snapline.Visible = true
    else
        esp.Snapline.Visible = false
    end
    
    local highlights = Highlights[player]
    if highlights then
        if ESPModule.Settings.InvisibleChamsEnabled then
            if highlights.Invisible.Parent ~= character then
                highlights.Invisible.Parent = character
            end
            highlights.Invisible.FillColor = ESPModule.Settings.InvisibleChamsColor
            highlights.Invisible.FillTransparency = ESPModule.Settings.ChamsTransparency
            highlights.Invisible.Enabled = true
        else
            highlights.Invisible.Enabled = false
        end
        
        if ESPModule.Settings.VisibleChamsEnabled then
            if highlights.Visible.Parent ~= character then
                highlights.Visible.Parent = character
            end
            highlights.Visible.FillColor = ESPModule.Settings.VisibleChamsColor
            highlights.Visible.FillTransparency = ESPModule.Settings.ChamsTransparency
            highlights.Visible.Enabled = true
        else
            highlights.Visible.Enabled = false
        end
    end
    
    if ESPModule.Settings.SkeletonESP then
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
                
                local fromScreen, fromVis = Camera:WorldToViewportPoint(from.Position)
                local toScreen, toVis = Camera:WorldToViewportPoint(to.Position)
                
                if fromVis and toVis and fromScreen.Z > 0 and toScreen.Z > 0 then
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
            end
            
            if upperTorso and lowerTorso and upperTorso ~= lowerTorso then
                drawBone(upperTorso, lowerTorso, skeleton.Torso)
            end
            
            if upperTorso and leftUpperArm then
                drawBone(upperTorso, leftUpperArm, skeleton.LeftShoulder)
                if leftLowerArm then
                    drawBone(leftUpperArm, leftLowerArm, skeleton.LeftUpperArm)
                    if leftHand then
                        drawBone(leftLowerArm, leftHand, skeleton.LeftLowerArm)
                    end
                end
            end
            
            if upperTorso and rightUpperArm then
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
        HideESP(player)
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
    
    local lastUpdate = tick()
    UpdateConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        
        if now - lastUpdate >= ESPModule.Settings.RefreshRate then
            if ESPModule.Settings.Enabled then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        pcall(UpdateESP, player)
                    end
                end
            else
                DisableESP()
            end
            
            lastUpdate = now
        end
    end)
    
    RainbowConnection = task.spawn(function()
        while true do
            task.wait(0.01)
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
