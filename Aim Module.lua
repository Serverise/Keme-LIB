local AimModule = {}

local pcall, next, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, mousemoverel = pcall, next, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, mousemoverel or (Input and Input.MouseMove)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Typing, Running, ServiceConnections, Animation, OriginalSensitivity = false, false, {}, nil, nil
local LockedPlayer = nil

local FOVCircle = Drawingnew("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Thickness = 1
FOVCircle.Color = Color3fromRGB(255, 255, 255)
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
    if OriginalSensitivity then
        UserInputService.MouseDeltaSensitivity = OriginalSensitivity
    end

    if Animation then
        Animation:Cancel()
        Animation = nil
    end
end

local function GetClosestPlayer()
    if not LockedPlayer then
        local RequiredDistance = AimModule.Settings.FOVSize
        local ClosestPlayer = nil

        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(AimModule.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
                if AimModule.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
                if AimModule.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
                if AimModule.Settings.WallCheck then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, v.Character}
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local origin = Camera.CFrame.Position
                    local direction = (v.Character[AimModule.Settings.LockPart].Position - origin).Unit * 1000
                    local rayResult = workspace:Raycast(origin, direction, rayParams)
                    if rayResult then continue end
                end

                local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[AimModule.Settings.LockPart].Position)
                Vector = ConvertVector(Vector)
                local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude

                if Distance < RequiredDistance and OnScreen then
                    RequiredDistance = Distance
                    ClosestPlayer = v
                end
            end
        end
        
        LockedPlayer = ClosestPlayer
    elseif LockedPlayer then
        if not LockedPlayer.Character or not LockedPlayer.Character:FindFirstChild(AimModule.Settings.LockPart) or not LockedPlayer.Character:FindFirstChildOfClass("Humanoid") or LockedPlayer.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            CancelLock()
            return
        end
        
        local Vector, OnScreen = Camera:WorldToViewportPoint(LockedPlayer.Character[AimModule.Settings.LockPart].Position)
        if not OnScreen then
            CancelLock()
            return
        end
        
        local Distance = (UserInputService:GetMouseLocation() - ConvertVector(Vector)).Magnitude
        if Distance > AimModule.Settings.FOVSize then
            CancelLock()
        end
    end
end

local function OnInputBegan(Input, GameProcessed)
    if GameProcessed or Typing or not AimModule.Settings.Enabled or not AimModule.Settings.TriggerKey then return end
    
    local isCorrectInput = false
    
    if typeof(AimModule.Settings.TriggerKey) == "EnumItem" then
        if AimModule.Settings.TriggerKey.EnumType == Enum.KeyCode then
            if Input.KeyCode == AimModule.Settings.TriggerKey then
                isCorrectInput = true
            end
        elseif AimModule.Settings.TriggerKey.EnumType == Enum.UserInputType then
            if Input.UserInputType == AimModule.Settings.TriggerKey then
                isCorrectInput = true
            end
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

local function OnInputEnded(Input, GameProcessed)
    if GameProcessed or Typing or not AimModule.Settings.TriggerKey or AimModule.Settings.Toggle then return end
    
    local isCorrectInput = false
    
    if typeof(AimModule.Settings.TriggerKey) == "EnumItem" then
        if AimModule.Settings.TriggerKey.EnumType == Enum.KeyCode then
            if Input.KeyCode == AimModule.Settings.TriggerKey then
                isCorrectInput = true
            end
        elseif AimModule.Settings.TriggerKey.EnumType == Enum.UserInputType then
            if Input.UserInputType == AimModule.Settings.TriggerKey then
                isCorrectInput = true
            end
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
        if AimModule.Settings.FOVVisible and AimModule.Settings.Enabled then
            FOVCircle.Radius = AimModule.Settings.FOVSize
            FOVCircle.Thickness = AimModule.Settings.FOVThickness
            FOVCircle.Filled = AimModule.Settings.FOVFilled
            FOVCircle.NumSides = AimModule.Settings.FOVSides
            FOVCircle.Transparency = AimModule.Settings.FOVTransparency
            FOVCircle.Visible = true
            FOVCircle.Position = Vector2new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
            
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

            if LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild(AimModule.Settings.LockPart) then
                if AimModule.Settings.ThirdPerson then
                    local Vector = Camera:WorldToViewportPoint(LockedPlayer.Character[AimModule.Settings.LockPart].Position)
                    if mousemoverel then
                        mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * AimModule.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * AimModule.Settings.ThirdPersonSensitivity)
                    end
                else
                    if AimModule.Settings.Sensitivity > 0 then
                        if Animation then
                            Animation:Cancel()
                        end
                        Animation = TweenService:Create(Camera, TweenInfonew(AimModule.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, LockedPlayer.Character[AimModule.Settings.LockPart].Position)})
                        Animation:Play()
                    else
                        Camera.CFrame = CFramenew(Camera.CFrame.Position, LockedPlayer.Character[AimModule.Settings.LockPart].Position)
                    end

                    UserInputService.MouseDeltaSensitivity = 0
                end
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
