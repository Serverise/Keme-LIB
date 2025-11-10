local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local AimbotModule = {}
AimbotModule.Settings = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    Sensitivity = 0,
    ThirdPerson = false,
    ThirdPersonSensitivity = 3,
    TriggerKey = "MouseButton2",
    Toggle = false,
    LockPart = "Head"
}
AimbotModule.FOVSettings = {
    Enabled = true,
    Visible = true,
    Amount = 90,
    Color = Color3.fromRGB(255, 255, 255),
    LockedColor = Color3.fromRGB(255, 70, 70),
    Transparency = 0.5,
    Sides = 60,
    Thickness = 1,
    Filled = false
}
AimbotModule.Locked = nil
local FOVCircle = Drawing.new("Circle")
local RequiredDistance = 2000
local Typing = false
local Running = false
local ServiceConnections = {}
local Animation = nil
local OriginalSensitivity = UserInputService.MouseDeltaSensitivity
local function ConvertVector(Vector)
    return Vector2.new(Vector.X, Vector.Y)
end
local function CancelLock()
    AimbotModule.Locked = nil
    FOVCircle.Color = AimbotModule.FOVSettings.Color
    UserInputService.MouseDeltaSensitivity = OriginalSensitivity
    if Animation then
        Animation:Cancel()
    end
end
local function GetClosestPlayer()
    if not AimbotModule.Locked then
        RequiredDistance = (AimbotModule.FOVSettings.Enabled and AimbotModule.FOVSettings.Amount or 2000)
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(AimbotModule.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
                if AimbotModule.Settings.TeamCheck and v.TeamColor == LocalPlayer.TeamColor then continue end
                if AimbotModule.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
                if AimbotModule.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[AimbotModule.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end
                local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[AimbotModule.Settings.LockPart].Position)
                Vector = ConvertVector(Vector)
                local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude
                if Distance < RequiredDistance and OnScreen then
                    RequiredDistance = Distance
                    AimbotModule.Locked = v
                end
            end
        end
    elseif (UserInputService:GetMouseLocation() - ConvertVector(Camera:WorldToViewportPoint(AimbotModule.Locked.Character[AimbotModule.Settings.LockPart].Position))).Magnitude > RequiredDistance then
        CancelLock()
    end
end
local function Update()
    if AimbotModule.FOVSettings.Enabled and AimbotModule.Settings.Enabled then
        FOVCircle.Radius = AimbotModule.FOVSettings.Amount
        FOVCircle.Thickness = AimbotModule.FOVSettings.Thickness
        FOVCircle.Filled = AimbotModule.FOVSettings.Filled
        FOVCircle.NumSides = AimbotModule.FOVSettings.Sides
        FOVCircle.Color = AimbotModule.FOVSettings.Color
        FOVCircle.Transparency = AimbotModule.FOVSettings.Transparency
        FOVCircle.Visible = AimbotModule.FOVSettings.Visible
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    else
        FOVCircle.Visible = false
    end
    if Running and AimbotModule.Settings.Enabled then
        GetClosestPlayer()
        if AimbotModule.Locked then
            if AimbotModule.Settings.ThirdPerson then
                local Vector = Camera:WorldToViewportPoint(AimbotModule.Locked.Character[AimbotModule.Settings.LockPart].Position)
                if mousemoverel then
                    mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * AimbotModule.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * AimbotModule.Settings.ThirdPersonSensitivity)
                end
            else
                if AimbotModule.Settings.Sensitivity > 0 then
                    Animation = TweenService:Create(Camera, TweenInfo.new(AimbotModule.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, AimbotModule.Locked.Character[AimbotModule.Settings.LockPart].Position)})
                    Animation:Play()
                else
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, AimbotModule.Locked.Character[AimbotModule.Settings.LockPart].Position)
                end
                UserInputService.MouseDeltaSensitivity = 0
            end
            FOVCircle.Color = AimbotModule.FOVSettings.LockedColor
        end
    end
end
local function OnInputBegan(input)
    if not Typing then
        pcall(function()
            local inputType = input.UserInputType
            local keyCode = input.KeyCode
            local triggerKey = AimbotModule.Settings.TriggerKey
            local isKeyMatch = (inputType == Enum.UserInputType.Keyboard and keyCode == Enum.KeyCode[triggerKey]) or inputType == Enum.UserInputType[triggerKey]
            if isKeyMatch then
                if AimbotModule.Settings.Toggle then
                    Running = not Running
                    if not Running then
                        CancelLock()
                    end
                else
                    Running = true
                end
            end
        end)
    end
end
local function OnInputEnded(input)
    if not Typing then
        if not AimbotModule.Settings.Toggle then
            pcall(function()
                local inputType = input.UserInputType
                local keyCode = input.KeyCode
                local triggerKey = AimbotModule.Settings.TriggerKey
                local isKeyMatch = (inputType == Enum.UserInputType.Keyboard and keyCode == Enum.KeyCode[triggerKey]) or inputType == Enum.UserInputType[triggerKey]
                if isKeyMatch then
                    Running = false
                    CancelLock()
                end
            end)
        end
    end
end
function AimbotModule:Start()
    if ServiceConnections.UpdateConnection then return end
    ServiceConnections.UpdateConnection = RunService.RenderStepped:Connect(Update)
    ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(OnInputBegan)
    ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(OnInputEnded)
    ServiceConnections.TextBoxFocusedConnection = UserInputService.TextBoxFocused:Connect(function()
        Typing = true
    end)
    ServiceConnections.TextBoxFocusReleasedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
        Typing = false
    end)
end
function AimbotModule:Stop()
    if ServiceConnections.UpdateConnection then
        ServiceConnections.UpdateConnection:Disconnect()
        ServiceConnections.InputBeganConnection:Disconnect()
        ServiceConnections.InputEndedConnection:Disconnect()
        ServiceConnections.TextBoxFocusedConnection:Disconnect()
        ServiceConnections.TextBoxFocusReleasedConnection:Disconnect()
        ServiceConnections = {}
    end
    if Animation then
        Animation:Cancel()
        Animation = nil
    end
    FOVCircle.Visible = false
    Running = false
    CancelLock()
end
return AimbotModule
