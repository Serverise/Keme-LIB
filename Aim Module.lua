local AimModule = {}

local pcall, next, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel = pcall, next, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper, mousemoverel or (Input and Input.MouseMove)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}, nil, nil
local LockedPlayer = nil

local FOVCircle = Drawingnew("Circle")
FOVCircle.Visible = false

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
    FOVColor = Color3fromRGB(255, 255, 255),
    FOVLockColor = Color3fromRGB(255, 70, 70),
    FOVTransparency = 0.5,
    FOVThickness = 1,
    FOVSides = 60,
    FOVFilled = false
}

local function ConvertVector(Vector)
    return Vector2new(Vector.X, Vector.Y)
end

local function CancelLock()
    LockedPlayer = nil
    FOVCircle.Color = AimModule.Settings.FOVColor
    UserInputService.MouseDeltaSensitivity = OriginalSensitivity

    if Animation then
        Animation:Cancel()
    end
end

local function GetClosestPlayer()
    if not LockedPlayer then
        RequiredDistance = AimModule.Settings.FOVSize

        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(AimModule.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
                if AimModule.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
                if AimModule.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
                if AimModule.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[AimModule.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end

                local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[AimModule.Settings.LockPart].Position)
                Vector = ConvertVector(Vector)
                local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude

                if Distance < RequiredDistance and OnScreen then
                    RequiredDistance = Distance
                    LockedPlayer = v
                end
            end
        end
    elseif LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild(AimModule.Settings.LockPart) then
        local Distance = (UserInputService:GetMouseLocation() - ConvertVector(Camera:WorldToViewportPoint(LockedPlayer.Character[AimModule.Settings.LockPart].Position))).Magnitude
        if Distance > RequiredDistance then
            CancelLock()
        end
    else
        CancelLock()
    end
end

local function OnInputBegan(Input)
    if Typing or not AimModule.Settings.Enabled or not AimModule.Settings.TriggerKey then return end
    
    pcall(function()
        local isCorrectInput = false
        
        if AimModule.Settings.TriggerKey == Enum.UserInputType.MouseButton2 then
            if Input.UserInputType == Enum.UserInputType.MouseButton2 then
                isCorrectInput = true
            end
        elseif type(AimModule.Settings.TriggerKey) == "EnumItem" and Input.KeyCode == AimModule.Settings.TriggerKey then
            isCorrectInput = true
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
    end)
end

local function OnInputEnded(Input)
    if Typing or not AimModule.Settings.TriggerKey or AimModule.Settings.Toggle then return end
    
    pcall(function()
        local isCorrectInput = false
        
        if AimModule.Settings.TriggerKey == Enum.UserInputType.MouseButton2 then
            if Input.UserInputType == Enum.UserInputType.MouseButton2 then
                isCorrectInput = true
            end
        elseif type(AimModule.Settings.TriggerKey) == "EnumItem" and Input.KeyCode == AimModule.Settings.TriggerKey then
            isCorrectInput = true
        end
        
        if isCorrectInput then
            Running = false
            CancelLock()
        end
    end)
end

function AimModule:Start()
    if ServiceConnections.RenderSteppedConnection then return end
    
    OriginalSensitivity = UserInputService.MouseDeltaSensitivity
    
    ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
        if AimModule.Settings.FOVVisible and AimModule.Settings.Enabled then
            FOVCircle.Radius = AimModule.Settings.FOVSize
            FOVCircle.Thickness = AimModule.Settings.FOVThickness
            FOVCircle.Filled = AimModule.Settings.FOVFilled
            FOVCircle.NumSides = AimModule.Settings.FOVSides
            FOVCircle.Color = AimModule.Settings.FOVColor
            FOVCircle.Transparency = AimModule.Settings.FOVTransparency
            FOVCircle.Visible = true
            FOVCircle.Position = Vector2new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        else
            FOVCircle.Visible = false
        end

        if Running and AimModule.Settings.Enabled then
            GetClosestPlayer()

            if LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild(AimModule.Settings.LockPart) then
                if AimModule.Settings.ThirdPerson then
                    local Vector = Camera:WorldToViewportPoint(LockedPlayer.Character[AimModule.Settings.LockPart].Position)
                    mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * AimModule.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * AimModule.Settings.ThirdPersonSensitivity)
                else
                    if AimModule.Settings.Sensitivity > 0 then
                        Animation = TweenService:Create(Camera, TweenInfonew(AimModule.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, LockedPlayer.Character[AimModule.Settings.LockPart].Position)})
                        Animation:Play()
                    else
                        Camera.CFrame = CFramenew(Camera.CFrame.Position, LockedPlayer.Character[AimModule.Settings.LockPart].Position)
                    end

                    UserInputService.MouseDeltaSensitivity = 0
                end

                FOVCircle.Color = AimModule.Settings.FOVLockColor
            end
        end
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
    for _, v in next, ServiceConnections do
        v:Disconnect()
    end
    
    ServiceConnections = {}
    
    FOVCircle.Visible = false
    Running = false
    CancelLock()
end

return AimModule
