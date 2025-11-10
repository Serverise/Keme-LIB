local AimModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.NumSides = 64

local LockedPlayer = nil
local AimbotConnection = nil
local FOVUpdateConnection = nil
local ActivateConnection = nil

AimModule.Settings = {
    Enabled = false,
    ActivateBind = nil,
    AimPart = "Head",
    Smoothness = 1,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    FOVVisible = false,
    FOVSize = 100,
    FOVTransparency = 0.5,
    FOVThickness = 1,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVLockColor = Color3.fromRGB(255, 0, 0)
}

local function ConvertVector(vector)
    return Vector2.new(vector.X, vector.Y)
end

local function CancelLock()
    LockedPlayer = nil
    if AimModule.Settings.FOVVisible then
        FOVCircle.Color = AimModule.Settings.FOVColor
    end
end

local function GetClosestPlayer()
    if not LockedPlayer then
        local RequiredDistance = AimModule.Settings.FOVSize

        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(AimModule.Settings.AimPart) and v.Character:FindFirstChildOfClass("Humanoid") then
                if AimModule.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
                if AimModule.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
                if AimModule.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[AimModule.Settings.AimPart].Position}, v.Character:GetDescendants())) > 0 then continue end

                local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[AimModule.Settings.AimPart].Position)
                Vector = ConvertVector(Vector)
                local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude

                if Distance < RequiredDistance and OnScreen then
                    RequiredDistance = Distance
                    LockedPlayer = v
                end
            end
        end
        
        if LockedPlayer and AimModule.Settings.FOVVisible then
            FOVCircle.Color = AimModule.Settings.FOVLockColor
        end
    else
        if not LockedPlayer.Character or not LockedPlayer.Character:FindFirstChild(AimModule.Settings.AimPart) or not LockedPlayer.Character:FindFirstChildOfClass("Humanoid") or LockedPlayer.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            CancelLock()
            return
        end
        
        local Vector, OnScreen = Camera:WorldToViewportPoint(LockedPlayer.Character[AimModule.Settings.AimPart].Position)
        Vector = ConvertVector(Vector)
        local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude
        
        if Distance > AimModule.Settings.FOVSize or not OnScreen then
            CancelLock()
        end
    end
end

local function UpdateAimbot()
    if not AimModule.Settings.Enabled or not LockedPlayer then return end
    
    local character = LockedPlayer.Character
    if not character or not character:FindFirstChild(AimModule.Settings.AimPart) then
        CancelLock()
        return
    end
    
    local targetPart = character[AimModule.Settings.AimPart]
    local targetPosition = Camera:WorldToViewportPoint(targetPart.Position)
    
    if targetPosition.Z > 0 then
        local mouseLocation = UserInputService:GetMouseLocation()
        local targetVector = Vector2.new(targetPosition.X, targetPosition.Y)
        
        local smoothness = AimModule.Settings.Smoothness
        if smoothness == 0 then
            mousemoverel((targetVector.X - mouseLocation.X), (targetVector.Y - mouseLocation.Y))
        else
            mousemoverel((targetVector.X - mouseLocation.X) / smoothness, (targetVector.Y - mouseLocation.Y) / smoothness)
        end
    end
end

local function UpdateFOV()
    if not AimModule.Settings.FOVVisible then
        FOVCircle.Visible = false
        return
    end
    
    local mouseLocation = UserInputService:GetMouseLocation()
    FOVCircle.Position = mouseLocation
    FOVCircle.Radius = AimModule.Settings.FOVSize
    FOVCircle.Transparency = AimModule.Settings.FOVTransparency
    FOVCircle.Thickness = AimModule.Settings.FOVThickness
    FOVCircle.Visible = true
    
    if not LockedPlayer then
        FOVCircle.Color = AimModule.Settings.FOVColor
    else
        FOVCircle.Color = AimModule.Settings.FOVLockColor
    end
end

function AimModule:Start()
    if AimbotConnection then return end
    
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if AimModule.Settings.Enabled then
            GetClosestPlayer()
            UpdateAimbot()
        end
    end)
    
    FOVUpdateConnection = RunService.RenderStepped:Connect(function()
        UpdateFOV()
    end)
    
    if AimModule.Settings.ActivateBind then
        ActivateConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == AimModule.Settings.ActivateBind or input.UserInputType == AimModule.Settings.ActivateBind then
                if AimModule.Settings.Enabled then
                    GetClosestPlayer()
                end
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if input.KeyCode == AimModule.Settings.ActivateBind or input.UserInputType == AimModule.Settings.ActivateBind then
                CancelLock()
            end
        end)
    end
end

function AimModule:Stop()
    if AimbotConnection then
        AimbotConnection:Disconnect()
        AimbotConnection = nil
    end
    
    if FOVUpdateConnection then
        FOVUpdateConnection:Disconnect()
        FOVUpdateConnection = nil
    end
    
    if ActivateConnection then
        ActivateConnection:Disconnect()
        ActivateConnection = nil
    end
    
    CancelLock()
    FOVCircle.Visible = false
end

function AimModule:UpdateSettings(settings)
    for key, value in pairs(settings) do
        if AimModule.Settings[key] ~= nil then
            AimModule.Settings[key] = value
        end
    end
end

return AimModule
