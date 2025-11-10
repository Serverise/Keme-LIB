local AimbotModule = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local FOV = Drawing.new("Circle")
local FOVLock = Drawing.new("Circle")
local Target = nil
local TargetConnection = nil
local Aiming = false
AimbotModule.Settings = {
    Enabled = false,
    TeamCheck = false,
    WallCheck = false,
    LockPart = "Head",
    Sensitivity = 0,
    TriggerKey = Enum.KeyCode.Q,
    FOVVisible = false,
    FOVSize = 90,
    FOVTransparency = 0.5,
    FOVThickness = 1,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVLockColor = Color3.fromRGB(255, 70, 70)
}
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mouseLocation = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if AimbotModule.Settings.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            local character = player.Character
            local part = character:FindFirstChild(AimbotModule.Settings.LockPart) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
            if part then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPoint.Z > 0 then
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mouseLocation).Magnitude
                    if distance <= AimbotModule.Settings.FOVSize and distance < shortestDistance then
                        if AimbotModule.Settings.WallCheck then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
                            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                            local rayResult = Workspace:Raycast(LocalPlayer.Character:FindFirstChild("Head").Position, (part.Position - LocalPlayer.Character:FindFirstChild("Head").Position).Unit * 999, rayParams)
                            if not rayResult then
                                closestPlayer = player
                                shortestDistance = distance
                            end
                        else
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end
local function UpdateTarget()
    if AimbotModule.Settings.Enabled and Aiming then
        Target = GetClosestPlayer()
    else
        Target = nil
    end
end
local function AimAtTarget()
    if not Target or not Target.Character or not Target.Character:FindFirstChild(AimbotModule.Settings.LockPart) then
        return
    end
    local targetPart = Target.Character[AimbotModule.Settings.LockPart]
    local targetPosition = Camera:WorldToViewportPoint(targetPart.Position)
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local targetScreenPosition = Vector2.new(targetPosition.X, targetPosition.Y)
    local difference = targetScreenPosition - screenCenter
    local smoothFactor = 1 - AimbotModule.Settings.Sensitivity
    local newPosition = screenCenter + difference * smoothFactor
    if UserInputService.TouchEnabled then
        return
    end
    game:GetService("UserInputService"):SetMousePosition(newPosition.X, newPosition.Y)
end
local function UpdateFOV()
    FOV.Position = UserInputService:GetMouseLocation()
    FOV.Radius = AimbotModule.Settings.FOVSize
    FOV.Color = AimbotModule.Settings.FOVColor
    FOV.Transparency = AimbotModule.Settings.FOVTransparency
    FOV.Thickness = AimbotModule.Settings.FOVThickness
    FOV.Visible = AimbotModule.Settings.FOVVisible
    if Target then
        FOVLock.Position = UserInputService:GetMouseLocation()
        FOVLock.Radius = AimbotModule.Settings.FOVSize
        FOVLock.Color = AimbotModule.Settings.FOVLockColor
        FOVLock.Transparency = AimbotModule.Settings.FOVTransparency
        FOVLock.Thickness = AimbotModule.Settings.FOVThickness
        FOVLock.Visible = true
    else
        FOVLock.Visible = false
    end
end
function AimbotModule:Start()
    if TargetConnection then return end
    FOV.Visible = true
    FOVLock.Visible = true
    TargetConnection = RunService.Heartbeat:Connect(function()
        UpdateTarget()
        if Target and AimbotModule.Settings.Enabled and Aiming then
            AimAtTarget()
        end
        UpdateFOV()
    end)
end
function AimbotModule:Stop()
    if TargetConnection then
        TargetConnection:Disconnect()
        TargetConnection = nil
    end
    FOV.Visible = false
    FOVLock.Visible = false
    Target = nil
    Aiming = false
end
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == AimbotModule.Settings.TriggerKey then
        Aiming = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == AimbotModule.Settings.TriggerKey then
        Aiming = false
    end
end)
return AimbotModule
