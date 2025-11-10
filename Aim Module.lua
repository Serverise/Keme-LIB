local AimModule = {}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Typing = false
local Running = false
local ServiceConnections = {}
local Animation = nil
local OriginalSensitivity = nil
local LockedPlayer = nil

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.NumSides = 60

AimModule.Settings = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    Sensitivity = 0,
    ThirdPerson = false,
    ThirdPersonSensitivity = 3,
    TriggerKey = nil,
    Toggle = false,
    LockPart = "Head",
    FOVVisible = false,
    FOVSize = 90,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVLockColor = Color3.fromRGB(255, 70, 70),
    FOVTransparency = 0.5,
    FOVThickness = 1,
    FOVSides = 60,
    FOVFilled = false
}

local function CancelLock()
    LockedPlayer = nil
    FOVCircle.Color = AimModule.Settings.FOVColor
    
    if OriginalSensitivity then
        UserInputService.MouseDeltaSensitivity = OriginalSensitivity
    end

    if Animation then
        Animation:Cancel()
        Animation = nil
    end
end

local function IsPlayerValid(player)
    if not player or player == LocalPlayer then return false end
    if not player.Character then return false end
    
    local lockPart = player.Character:FindFirstChild(AimModule.Settings.LockPart)
    if not lockPart then return false end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    if AimModule.Settings.AliveCheck and humanoid.Health <= 0 then return false end
    
    if AimModule.Settings.TeamCheck then
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            return false
        end
    end
    
    return true
end

local function IsWallBetween(targetPos)
    if not AimModule.Settings.WallCheck then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPos - origin)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    if result then
        local hitPlayer = Players:GetPlayerFromCharacter(result.Instance.Parent)
        if not hitPlayer then
            return true
        end
    end
    
    return false
end

local function GetClosestPlayer()
    if LockedPlayer then
        if not IsPlayerValid(LockedPlayer) then
            CancelLock()
            return
        end
        
        local lockPart = LockedPlayer.Character[AimModule.Settings.LockPart]
        local screenPos, onScreen = Camera:WorldToViewportPoint(lockPart.Position)
        
        if not onScreen or screenPos.Z <= 0 then
            CancelLock()
            return
        end
        
        if IsWallBetween(lockPart.Position) then
            CancelLock()
            return
        end
        
        local mousePos = UserInputService:GetMouseLocation()
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if distance > AimModule.Settings.FOVSize * 2 then
            CancelLock()
        end
        
        return
    end
    
    local closestPlayer = nil
    local shortestDistance = AimModule.Settings.FOVSize
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsPlayerValid(player) then
            local lockPart = player.Character[AimModule.Settings.LockPart]
            
            if IsWallBetween(lockPart.Position) then
                continue
            end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(lockPart.Position)
            
            if onScreen and screenPos.Z > 0 then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    LockedPlayer = closestPlayer
end

local function OnInputBegan(input, gameProcessed)
    if gameProcessed or Typing or not AimModule.Settings.Enabled or not AimModule.Settings.TriggerKey then 
        return 
    end
    
    local isCorrectInput = false
    
    if typeof(AimModule.Settings.TriggerKey) == "EnumItem" then
        if AimModule.Settings.TriggerKey.EnumType == Enum.KeyCode then
            isCorrectInput = input.KeyCode == AimModule.Settings.TriggerKey
        elseif AimModule.Settings.TriggerKey.EnumType == Enum.UserInputType then
            isCorrectInput = input.UserInputType == AimModule.Settings.TriggerKey
        end
    end
    
    if isCorrectInput then
        if AimModule.Settings.Toggle then
            Running = not Running
            if not Running then
                CancelLock()
            end
        else
            Running = true
        end
    end
end

local function OnInputEnded(input, gameProcessed)
    if gameProcessed or Typing or not AimModule.Settings.TriggerKey or AimModule.Settings.Toggle then 
        return 
    end
    
    local isCorrectInput = false
    
    if typeof(AimModule.Settings.TriggerKey) == "EnumItem" then
        if AimModule.Settings.TriggerKey.EnumType == Enum.KeyCode then
            isCorrectInput = input.KeyCode == AimModule.Settings.TriggerKey
        elseif AimModule.Settings.TriggerKey.EnumType == Enum.UserInputType then
            isCorrectInput = input.UserInputType == AimModule.Settings.TriggerKey
        end
    end
    
    if isCorrectInput then
        Running = false
        CancelLock()
    end
end

function AimModule:Start()
    if ServiceConnections.RenderSteppedConnection then return end
    
    OriginalSensitivity = UserInputService.MouseDeltaSensitivity
    
    ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
        pcall(function()
            if AimModule.Settings.FOVVisible and AimModule.Settings.Enabled then
                FOVCircle.Radius = AimModule.Settings.FOVSize
                FOVCircle.Thickness = AimModule.Settings.FOVThickness
                FOVCircle.Filled = AimModule.Settings.FOVFilled
                FOVCircle.NumSides = AimModule.Settings.FOVSides
                FOVCircle.Transparency = AimModule.Settings.FOVTransparency
                FOVCircle.Visible = true
                
                local mousePos = UserInputService:GetMouseLocation()
                FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
                
                if LockedPlayer then
                    FOVCircle.Color = AimModule.Settings.FOVLockColor
                else
                    FOVCircle.Color = AimModule.Settings.FOVColor
                end
            else
                FOVCircle.Visible = false
            end

            if Running and AimModule.Settings.Enabled then
                GetClosestPlayer()

                if LockedPlayer and LockedPlayer.Character then
                    local lockPart = LockedPlayer.Character:FindFirstChild(AimModule.Settings.LockPart)
                    
                    if lockPart then
                        if AimModule.Settings.ThirdPerson then
                            local screenPos = Camera:WorldToViewportPoint(lockPart.Position)
                            local mousePos = UserInputService:GetMouseLocation()
                            
                            if mousemoverel then
                                local deltaX = (screenPos.X - mousePos.X) * AimModule.Settings.ThirdPersonSensitivity
                                local deltaY = (screenPos.Y - mousePos.Y) * AimModule.Settings.ThirdPersonSensitivity
                                mousemoverel(deltaX, deltaY)
                            end
                        else
                            local targetCFrame = CFrame.new(Camera.CFrame.Position, lockPart.Position)
                            
                            if AimModule.Settings.Sensitivity > 0 then
                                if Animation then
                                    Animation:Cancel()
                                end
                                
                                local tweenInfo = TweenInfo.new(
                                    AimModule.Settings.Sensitivity,
                                    Enum.EasingStyle.Sine,
                                    Enum.EasingDirection.Out
                                )
                                
                                Animation = TweenService:Create(Camera, tweenInfo, {CFrame = targetCFrame})
                                Animation:Play()
                            else
                                Camera.CFrame = targetCFrame
                            end

                            UserInputService.MouseDeltaSensitivity = 0
                        end
                    end
                end
            end
        end)
    end)

    ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(OnInputBegan)
    ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(OnInputEnded)
    
    ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
        Typing = true
    end)

    ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
        Typing = false
    end)
end

function AimModule:Stop()
    for _, connection in pairs(ServiceConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    
    ServiceConnections = {}
    
    FOVCircle.Visible = false
    Running = false
    CancelLock()
end

return AimModule
