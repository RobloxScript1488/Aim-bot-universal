-- Universal Script for Roblox (Delta Executor & Mobile/PC Supported)
-- Library: Orion Library

local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()

local Window = OrionLib:MakeWindow({
    Name = "Universal Script | Delta Edition",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "UniversalScriptConfig",
    IntroEnabled = true,
    IntroText = "Universal Script",
    IntroIcon = "rbxassetid://4483362458"
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local StatsService = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Tracking Connections for Unload
local Connections = {}

-- Global Configurations
local Config = {
    Movement = {
        WallHop = false,
        WallHopLevel = 3,
        Noclip = false,
        Fly = false,
        FlySpeed = 50,
        Speed = 16,
        Gravity = 196.2,
        Jump = 50,
        SpeedEnabled = false,
        GravityEnabled = false,
        JumpEnabled = false
    },
    Combat = {
        Aimbot = false,
        ShowFOV = false,
        FOVRadius = 120,
        Smoothness = 0.2,
        Priority = "Crosshair",
        WallCheck = false,
        TeamCheck = true,
        KillSound = false,
        KillSoundID = "4817809188"
    },
    HUD = {
        FPSPing = false
    },
    Language = "English"
}

--------------------------------------------------------------------------------
-- DRAWING FOV CIRCLE (PERFECTLY ROUND: NumSides = 64)
--------------------------------------------------------------------------------
local FOVCircle = Drawing.new("Circle")
FOVCircle.NumSides = 64
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = false

--------------------------------------------------------------------------------
-- TABS
--------------------------------------------------------------------------------
local MoveTab = Window:MakeTab({ Name = "Movement & Physics", Icon = "rbxassetid://4483362458", PremiumOnly = false })
local CombatTab = Window:MakeTab({ Name = "Combat & Visuals", Icon = "rbxassetid://4483362458", PremiumOnly = false })
local HUDTab = Window:MakeTab({ Name = "HUD & Display", Icon = "rbxassetid://4483362458", PremiumOnly = false })
local SettingsTab = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483362458", PremiumOnly = false })

--------------------------------------------------------------------------------
-- TAB 1: MOVEMENT & PHYSICS
--------------------------------------------------------------------------------
MoveTab:AddSection({ Name = "Wall Hop" })

MoveTab:AddToggle({
    Name = "Enable Wall Hop",
    Default = false,
    Callback = function(Value)
        Config.Movement.WallHop = Value
    end
})

MoveTab:AddSlider({
    Name = "Wall Hop Level",
    Min = 1,
    Max = 5,
    Default = 3,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Level",
    Callback = function(Value)
        Config.Movement.WallHopLevel = Value
    end
})

Connections.JumpRequest = UserInputService.JumpRequest:Connect(function()
    if Config.Movement.WallHop then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local boost = Config.Movement.WallHopLevel * 12
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X * 1.05,
                boost + 25,
                hrp.AssemblyLinearVelocity.Z * 1.05
            )
        end
    end
end)

MoveTab:AddSection({ Name = "Fly & Noclip" })

MoveTab:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(Value)
        Config.Movement.Noclip = Value
    end
})

Connections.NoclipLoop = RunService.Stepped:Connect(function()
    if Config.Movement.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

local flyBV, flyBG
local function StopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

MoveTab:AddToggle({
    Name = "Enable Fly",
    Default = false,
    Callback = function(Value)
        Config.Movement.Fly = Value
        if not Value then
            StopFly()
        end
    end
})

MoveTab:AddSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    ValueName = "Speed",
    Callback = function(Value)
        Config.Movement.FlySpeed = Value
    end
})

Connections.FlyLoop = RunService.RenderStepped:Connect(function()
    if Config.Movement.Fly then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")
            hum.PlatformStand = true

            if not flyBV then
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                flyBV.Parent = hrp
            end

            if not flyBG then
                flyBG = Instance.new("BodyGyro")
                flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                flyBG.P = 9e4
                flyBG.Parent = hrp
            end

            flyBG.CFrame = Camera.CFrame
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                flyBV.Velocity = Camera.CFrame:VectorToWorldSpace(Vector3.new(moveDir.X, 0, moveDir.Z).Unit) * Config.Movement.FlySpeed
            else
                flyBV.Velocity = Vector3.new(0, 0, 0)
            end
        end
    else
        StopFly()
    end
end)

MoveTab:AddSection({ Name = "Speed, Gravity & Jump" })

local SpeedSlider, GravitySlider, JumpSlider

MoveTab:AddToggle({
    Name = "Enable Custom Speed",
    Default = false,
    Callback = function(Value)
        Config.Movement.SpeedEnabled = Value
        if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
})

SpeedSlider = MoveTab:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        Config.Movement.Speed = Value
    end
})

MoveTab:AddTextbox({
    Name = "Exact Speed",
    Default = "16",
    TextDisappear = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then
            Config.Movement.Speed = val
            SpeedSlider:Set(val)
        end
    end
})

MoveTab:AddToggle({
    Name = "Enable Custom Gravity",
    Default = false,
    Callback = function(Value)
        Config.Movement.GravityEnabled = Value
        if not Value then
            Workspace.Gravity = 196.2
        end
    end
})

GravitySlider = MoveTab:AddSlider({
    Name = "Gravity",
    Min = 0,
    Max = 196.2,
    Default = 196.2,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Gravity",
    Callback = function(Value)
        Config.Movement.Gravity = Value
    end
})

MoveTab:AddTextbox({
    Name = "Exact Gravity",
    Default = "196.2",
    TextDisappear = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then
            Config.Movement.Gravity = val
            GravitySlider:Set(val)
        end
    end
})

MoveTab:AddToggle({
    Name = "Enable Custom Jump",
    Default = false,
    Callback = function(Value)
        Config.Movement.JumpEnabled = Value
        if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            hum.JumpPower = 50
            hum.JumpHeight = 7.2
        end
    end
})

JumpSlider = MoveTab:AddSlider({
    Name = "Jump Power / Height",
    Min = 7,
    Max = 250,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Jump",
    Callback = function(Value)
        Config.Movement.Jump = Value
    end
})

MoveTab:AddTextbox({
    Name = "Exact Jump",
    Default = "50",
    TextDisappear = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then
            Config.Movement.Jump = val
            JumpSlider:Set(val)
        end
    end
})

Connections.PhysicsLoop = RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.Movement.SpeedEnabled then
                hum.WalkSpeed = Config.Movement.Speed
            end
            if Config.Movement.JumpEnabled then
                if hum.UseJumpPower then
                    hum.JumpPower = Config.Movement.Jump
                else
                    hum.JumpHeight = Config.Movement.Jump
                end
            end
        end
    end
    if Config.Movement.GravityEnabled then
        Workspace.Gravity = Config.Movement.Gravity
    end
end)

--------------------------------------------------------------------------------
-- TAB 2: COMBAT & VISUALS
--------------------------------------------------------------------------------
CombatTab:AddSection({ Name = "FOV Aimbot" })

CombatTab:AddToggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(Value)
        Config.Combat.Aimbot = Value
    end
})

CombatTab:AddToggle({
    Name = "Show FOV Circle",
    Default = false,
    Callback = function(Value)
        Config.Combat.ShowFOV = Value
    end
})

CombatTab:AddSlider({
    Name = "FOV Radius",
    Min = 30,
    Max = 500,
    Default = 120,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    ValueName = "Radius",
    Callback = function(Value)
        Config.Combat.FOVRadius = Value
    end
})

CombatTab:AddSlider({
    Name = "Smoothness",
    Min = 0.01,
    Max = 1,
    Default = 0.2,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 0.01,
    ValueName = "Smooth",
    Callback = function(Value)
        Config.Combat.Smoothness = Value
    end
})

CombatTab:AddDropdown({
    Name = "Priority Mode",
    Default = "Crosshair",
    Options = {"Crosshair", "Distance", "Lowest Health"},
    Callback = function(Value)
        Config.Combat.Priority = Value
    end
})

CombatTab:AddToggle({
    Name = "Wall Check",
    Default = false,
    Callback = function(Value)
        Config.Combat.WallCheck = Value
    end
})

CombatTab:AddToggle({
    Name = "Team Check",
    Default = true,
    Callback = function(Value)
        Config.Combat.TeamCheck = Value
    end
})

local function IsTargetVisible(targetHead, targetChar)
    if not Config.Combat.WallCheck then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    local result = Workspace:Raycast(Camera.CFrame.Position, targetHead.Position - Camera.CFrame.Position, rayParams)
    return result == nil
end

local function GetAimbotTarget()
    local bestTarget = nil
    local bestMetric = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not Config.Combat.TeamCheck or player.Team ~= LocalPlayer.Team then
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") then
                    local hum = char.Humanoid
                    if hum.Health > 0 then
                        local head = char.Head
                        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local screenVec = Vector2.new(screenPos.X, screenPos.Y)
                            local distFromMouse = (screenVec - mousePos).Magnitude

                            if distFromMouse <= Config.Combat.FOVRadius then
                                if IsTargetVisible(head, char) then
                                    local metric = distFromMouse
                                    if Config.Combat.Priority == "Distance" then
                                        local myChar = LocalPlayer.Character
                                        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                                            metric = (myChar.HumanoidRootPart.Position - head.Position).Magnitude
                                        end
                                    elseif Config.Combat.Priority == "Lowest Health" then
                                        metric = hum.Health
                                    end

                                    if metric < bestMetric then
                                        bestMetric = metric
                                        bestTarget = head
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

Connections.AimbotLoop = RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = Config.Combat.FOVRadius
    FOVCircle.Visible = Config.Combat.ShowFOV

    if Config.Combat.Aimbot then
        local targetHead = GetAimbotTarget()
        if targetHead then
            local currentCF = Camera.CFrame
            local targetCF = CFrame.lookAt(currentCF.Position, targetHead.Position)
            Camera.CFrame = currentCF:Lerp(targetCF, 1 - Config.Combat.Smoothness)
        end
    end
end)

CombatTab:AddSection({ Name = "Kill Sound" })

CombatTab:AddToggle({
    Name = "Enable Kill Sound",
    Default = false,
    Callback = function(Value)
        Config.Combat.KillSound = Value
    end
})

CombatTab:AddTextbox({
    Name = "Sound Asset ID",
    Default = "4817809188",
    TextDisappear = false,
    Callback = function(Text)
        if Text and #Text > 0 then
            Config.Combat.KillSoundID = Text
        end
    end
})

local function PlayKillSound()
    if not Config.Combat.KillSound then return end
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(Config.Combat.KillSoundID)
    sound.Volume = 2
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local function TrackPlayerDeath(player)
    if player == LocalPlayer then return end
    local function OnChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function()
                if Config.Combat.KillSound then
                    PlayKillSound()
                end
            end)
        end
    end
    if player.Character then OnChar(player.Character) end
    player.CharacterAdded:Connect(OnChar)
end

for _, p in ipairs(Players:GetPlayers()) do TrackPlayerDeath(p) end
Connections.PlayerAddedKillSound = Players.PlayerAdded:Connect(TrackPlayerDeath)

--------------------------------------------------------------------------------
-- TAB 3: HUD & DISPLAY
--------------------------------------------------------------------------------
HUDTab:AddSection({ Name = "FPS & Ping Overlay" })

local HUDGui = Instance.new("ScreenGui")
HUDGui.Name = "UniversalHUD"
HUDGui.ResetOnSpawn = false
HUDGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local HUDLabel = Instance.new("TextLabel")
HUDLabel.Size = UDim2.new(0, 180, 0, 30)
HUDLabel.Position = UDim2.new(0, 15, 0, 15)
HUDLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
HUDLabel.BackgroundTransparency = 0.3
HUDLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
HUDLabel.TextSize = 14
HUDLabel.Font = Enum.Font.SourceSansBold
HUDLabel.Visible = false
HUDLabel.Parent = HUDGui

local HUDCorner = Instance.new("UICorner")
HUDCorner.CornerRadius = UDim.new(0, 6)
HUDCorner.Parent = HUDLabel

HUDTab:AddToggle({
    Name = "Show FPS & Ping",
    Default = false,
    Callback = function(Value)
        Config.HUD.FPSPing = Value
        HUDLabel.Visible = Value
    end
})

local lastFrameTime = tick()
local frameCount = 0
local currentFPS = 60

Connections.HUDLoop = RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFrameTime >= 1 then
        currentFPS = math.floor(frameCount / (now - lastFrameTime))
        frameCount = 0
        lastFrameTime = now
    end

    if Config.HUD.FPSPing then
        local ping = 0
        pcall(function()
            ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        HUDLabel.Text = string.format(" FPS: %d | Ping: %d ms ", currentFPS, ping)
    end
end)

--------------------------------------------------------------------------------
-- TAB 4: SETTINGS
--------------------------------------------------------------------------------
SettingsTab:AddSection({ Name = "Localization" })

SettingsTab:AddDropdown({
    Name = "Select Language",
    Default = "English",
    Options = {"English", "Русский"},
    Callback = function(Value)
        Config.Language = Value
        OrionLib:MakeNotification({
            Name = "Language / Язык",
            Content = Value == "Русский" and "Выбран Русский язык" or "English language selected",
            Image = "rbxassetid://4483362458",
            Time = 3
        })
    end
})

SettingsTab:AddSection({ Name = "Config System" })

local configNameInput = "DefaultConfig"
SettingsTab:AddTextbox({
    Name = "Config Name",
    Default = "DefaultConfig",
    TextDisappear = false,
    Callback = function(Text)
        configNameInput = Text
    end
})

SettingsTab:AddButton({
    Name = "Save Config",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Config System",
            Content = "Config '" .. configNameInput .. "' saved successfully!",
            Image = "rbxassetid://4483362458",
            Time = 3
        })
    end
})

SettingsTab:AddButton({
    Name = "Load Config",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Config System",
            Content = "Config '" .. configNameInput .. "' loaded!",
            Image = "rbxassetid://4483362458",
            Time = 3
        })
    end
})

SettingsTab:AddSection({ Name = "Customization" })

SettingsTab:AddColorpicker({
    Name = "UI Theme Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Color)
        -- Theme color customization hook
    end
})

SettingsTab:AddSection({ Name = "Utilities" })

SettingsTab:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalP
                SettingsTab:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

SettingsTab:AddButton({
    Name = "Unload Script",
    Callback = function()
        for _, conn in pairs(Connections) do
            if conn then conn:Disconnect() end
        end
        if FOVCircle then FOVCircle:Remove() end
        if HUDGui then HUDGui:Destroy() end
        StopFly()
        OrionLib:Destroy()
    end
})

OrionLib:Init()
                
