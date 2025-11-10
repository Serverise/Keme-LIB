local AimAssist = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local CurrentTarget = nil
local IsActive = false
local IsTyping = false
local Connections = {}
local ActiveTween = nil
local OriginalSensitivity = UserInputService.MouseDeltaSensitivity

local FOVRing = Drawing.new("Circle")
FOVRing.Thickness = 2
FOVRing.NumSides = 100
FOVRing.Radius = 150
FOVRing.Filled = false
FOVRing.Visible = false
FOVRing.ZIndex = 999
FOVRing.Transparency = 1
FOVRing.Color = Color3.fromRGB(255, 255, 255)

AimAssist.Settings = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    
    TargetPart = "Head",
    FOVRadius = 150,
    Smoothness = 0.15,
    
    TriggerKey = nil,
    ToggleMode = false,
    
    FirstPerson = true,
    ThirdPersonSensitivity = 0.5,
    
    VisibleCheck = true,
    MaxDistance = 1000,
    
    FOV = {
        Visible = false,
        Filled = false,
        Color = Color3.fromRGB(255, 255, 255),
        LockedColor = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5,
        Thickness = 2,
        Sides = 100
    },
    
    Prediction = {
        Enabled = false,
        Amount = 0.13
    }
}

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

local function GetTargetPart(character)
    if not character then return nil end
    
    local part = character:FindFirstChild(AimAssist.Settings.TargetPart)
    if part then return part end
    
    local fallbacks = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    for _, name in ipairs(fallbacks) do
        part = character:FindFirstChild(name)
        if part then return part end
    end
    
    return nil
end

local function IsWallBetween(origin, target)
    if not AimAssist.Settings.WallCheck then return false end
    
    local direction = (target - origin)
    local distance = direction.Magnitude
    
    local ray = Ray.new(origin, direction.Unit * distance)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local ignoreList = {Camera, LocalPlayer.Character}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            table.insert(ignoreList, player.Character)
        end
    end
    params.FilterDescendantsInstances = ignoreList
    
    local result = Workspace:Raycast(origin, direction, params)
    
    return result ~= nil
end

local function IsOnScreen(position)
    local _, onScreen = Camera:WorldToViewportPoint(position)
    return onScreen
end

local function GetScreenPosition(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function GetMousePosition()
    return UserInputService:GetMouseLocation()
end

local function GetDistanceFromMouse(position)
    local screenPos, onScreen, depth = GetScreenPosition(position)
    if not onScreen or depth <= 0 then return math.huge end
    
    local mousePos = GetMousePosition()
    return (screenPos - mousePos).Magnitude
end

local function GetDistanceFromPlayer(position)
    return (position - Camera.CFrame.Position).Magnitude
end

local function IsValidTarget(player)
    if not player or player == LocalPlayer then return false end
    
    if not AimAssist.Settings.Enabled then return false end
    
    if AimAssist.Settings.AliveCheck and not IsAlive(player) then return false end
    
    if AimAssist.Settings.TeamCheck then
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            return false
        end
    end
    
    local character = player.Character
    if not character then return false end
    
    local targetPart = GetTargetPart(character)
    if not targetPart then return false end
    
    local distance = GetDistanceFromPlayer(targetPart.Position)
    if distance > AimAssist.Settings.MaxDistance then return false end
    
    if AimAssist.Settings.VisibleCheck and not IsOnScreen(targetPart.Position) then
        return false
    end
    
    local mouseDistance = GetDistanceFromMouse(targetPart.Position)
    if mouseDistance > AimAssist.Settings.FOVRadius then return false end
    
    if AimAssist.Settings.WallCheck then
        if IsWallBetween(Camera.CFrame.Position, targetPart.Position) then
            return false
        end
    end
    
    return true
end

local function FindBestTarget()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local targetPart = GetTargetPart(player.Character)
            if targetPart then
                local distance = GetDistanceFromMouse(targetPart.Position)
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

local function PredictPosition(targetPart)
    if not AimAssist.Settings.Prediction.Enabled then
        return targetPart.Position
    end
    
    local velocity = targetPart.AssemblyVelocity or targetPart.Velocity or Vector3.new()
    local prediction = targetPart.Position + (velocity * AimAssist.Settings.Prediction.Amount)
    
    return prediction
end

local function AimAtTarget(targetPart)
    if not targetPart then return end
    
    local targetPosition = PredictPosition(targetPart)
    local cameraPosition = Camera.CFrame.Position
    
    if AimAssist.Settings.FirstPerson then
        local targetCFrame = CFrame.new(cameraPosition, targetPosition)
        
        if AimAssist.Settings.Smoothness > 0 then
            if ActiveTween then
                ActiveTween:Cancel()
            end
            
            local tweenInfo = TweenInfo.new(
                AimAssist.Settings.Smoothness,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.Out
            )
            
            ActiveTween = TweenService:Create(Camera, tweenInfo, {CFrame = targetCFrame})
            ActiveTween:Play()
            
            ActiveTween.Completed:Connect(function()
                ActiveTween = nil
            end)
        else
            Camera.CFrame = targetCFrame
        end
        
        UserInputService.MouseDeltaSensitivity = 0
    else
        local screenPos, onScreen = GetScreenPosition(targetPosition)
        if onScreen then
            local mousePos = GetMousePosition()
            local delta = (screenPos - mousePos) * AimAssist.Settings.ThirdPersonSensitivity
            
            if mousemoverel then
                mousemoverel(delta.X, delta.Y)
            end
        end
    end
end

local function ReleaseTarget()
    CurrentTarget = nil
    
    if ActiveTween then
        ActiveTween:Cancel()
        ActiveTween = nil
    end
    
    if AimAssist.Settings.FirstPerson then
        UserInputService.MouseDeltaSensitivity = OriginalSensitivity
    end
end

local function UpdateFOV()
    if not AimAssist.Settings.FOV.Visible or not AimAssist.Settings.Enabled then
        FOVRing.Visible = false
        return
    end
    
    local mousePos = GetMousePosition()
    
    FOVRing.Position = mousePos
    FOVRing.Radius = AimAssist.Settings.FOVRadius
    FOVRing.Thickness = AimAssist.Settings.FOV.Thickness
    FOVRing.NumSides = AimAssist.Settings.FOV.Sides
    FOVRing.Filled = AimAssist.Settings.FOV.Filled
    FOVRing.Transparency = AimAssist.Settings.FOV.Transparency
    FOVRing.Visible = true
    
    if CurrentTarget then
        FOVRing.Color = AimAssist.Settings.FOV.LockedColor
    else
        FOVRing.Color = AimAssist.Settings.FOV.Color
    end
end

local function UpdateAim()
    if not IsActive or not AimAssist.Settings.Enabled then
        if CurrentTarget then
            ReleaseTarget()
        end
        return
    end
    
    if CurrentTarget then
        if not IsValidTarget(CurrentTarget) then
            ReleaseTarget()
            CurrentTarget = FindBestTarget()
        end
    else
        CurrentTarget = FindBestTarget()
    end
    
    if CurrentTarget then
        local targetPart = GetTargetPart(CurrentTarget.Character)
        if targetPart then
            AimAtTarget(targetPart)
        else
            ReleaseTarget()
        end
    end
end

local function OnKeyPress(input, gameProcessed)
    if gameProcessed or IsTyping then return end
    if not AimAssist.Settings.Enabled or not AimAssist.Settings.TriggerKey then return end
    
    local keyMatches = false
    
    if typeof(AimAssist.Settings.TriggerKey) == "EnumItem" then
        if AimAssist.Settings.TriggerKey.EnumType == Enum.KeyCode then
            keyMatches = input.KeyCode == AimAssist.Settings.TriggerKey
        elseif AimAssist.Settings.TriggerKey.EnumType == Enum.UserInputType then
            keyMatches = input.UserInputType == AimAssist.Settings.TriggerKey
        end
    end
    
    if not keyMatches then return end
    
    if AimAssist.Settings.ToggleMode then
        IsActive = not IsActive
        if not IsActive then
            ReleaseTarget()
        end
    else
        IsActive = true
    end
end

local function OnKeyRelease(input, gameProcessed)
    if AimAssist.Settings.ToggleMode then return end
    if IsTyping then return end
    if not AimAssist.Settings.TriggerKey then return end
    
    local keyMatches = false
    
    if typeof(AimAssist.Settings.TriggerKey) == "EnumItem" then
        if AimAssist.Settings.TriggerKey.EnumType == Enum.KeyCode then
            keyMatches = input.KeyCode == AimAssist.Settings.TriggerKey
        elseif AimAssist.Settings.TriggerKey.EnumType == Enum.UserInputType then
            keyMatches = input.UserInputType == AimAssist.Settings.TriggerKey
        end
    end
    
    if not keyMatches then return end
    
    IsActive = false
    ReleaseTarget()
end

local function OnTextBoxFocused()
    IsTyping = true
end

local function OnTextBoxUnfocused()
    IsTyping = false
end

function AimAssist:UpdateSettings(newSettings)
    for key, value in pairs(newSettings) do
        if AimAssist.Settings[key] ~= nil then
            AimAssist.Settings[key] = value
        end
    end
end

function AimAssist:SetFOVRadius(radius)
    AimAssist.Settings.FOVRadius = math.clamp(radius, 10, 1000)
end

function AimAssist:SetTargetPart(partName)
    AimAssist.Settings.TargetPart = partName
end

function AimAssist:SetSmoothness(smoothness)
    AimAssist.Settings.Smoothness = math.clamp(smoothness, 0, 5)
end

function AimAssist:GetCurrentTarget()
    return CurrentTarget
end

function AimAssist:IsLocked()
    return CurrentTarget ~= nil
end

function AimAssist:ForceRelease()
    ReleaseTarget()
    IsActive = false
end

function AimAssist:Start()
    if Connections.Update then
        return
    end
    
    OriginalSensitivity = UserInputService.MouseDeltaSensitivity
    
    Connections.Update = RunService.Heartbeat:Connect(function()
        pcall(function()
            UpdateFOV()
            UpdateAim()
        end)
    end)
    
    Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        pcall(OnKeyPress, input, processed)
    end)
    
    Connections.InputEnded = UserInputService.InputEnded:Connect(function(input, processed)
        pcall(OnKeyRelease, input, processed)
    end)
    
    Connections.TextBoxFocused = UserInputService.TextBoxFocused:Connect(OnTextBoxFocused)
    Connections.TextBoxFocusReleased = UserInputService.TextBoxFocusReleased:Connect(OnTextBoxUnfocused)
    
    Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        OriginalSensitivity = UserInputService.MouseDeltaSensitivity
        ReleaseTarget()
    end)
end

function AimAssist:Stop()
    for name, connection in pairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    
    Connections = {}
    
    ReleaseTarget()
    IsActive = false
    FOVRing.Visible = false
    
    UserInputService.MouseDeltaSensitivity = OriginalSensitivity
end

function AimAssist:Restart()
    self:Stop()
    task.wait(0.1)
    self:Start()
end

function AimAssist:Toggle(state)
    AimAssist.Settings.Enabled = state
    
    if not state then
        ReleaseTarget()
        IsActive = false
        FOVRing.Visible = false
    end
end

return AimAssist
