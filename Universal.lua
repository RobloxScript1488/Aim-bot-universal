-- Universal Script for Delta Executor (Full Version - Part 1)
-- Library: Orion Library

local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Global Connections & Config Table
local Connections = {}
local Config = {
    Language = "EN",
    ChinaHat = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), RGB = false, RotationSpeed = 100 },
    Aimbot = { Enabled = false, ShowFOV = false, FOVRadius = 120, Smoothness = 0.2, Priority = "Crosshair", WallCheck = false, TeamCheck = true, AliveCheck = true },
    Hitbox = { Enabled = false, Size = 10, Transparency = 0.5, Color = Color3.fromRGB(255, 0, 0), AlwaysOnTop = false, TeamCheck = true },
    Movement = {
        Speed = { Enabled = false, Value = 16, Default = 16 },
        Gravity = { Enabled = false, Value = 196.2, Default = 196.2 },
        Jump = { Enabled = false, Value = 50, DefaultPower = 50, DefaultHeight = 7.2 },
        WallHop = { Enabled = false, Level = 1 },
        Noclip = false,
        Fly = false,
        FlySpeed = 50,
        Fling = false
    },
    KillSound = { Enabled = false, SoundId = "4817809188" },
    HUD = { FPSPing = false }
}

--------------------------------------------------------------------------------
-- DRAWING FOV CIRCLE (STRICTLY ROUND)
--------------------------------------------------------------------------------
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = false

--------------------------------------------------------------------------------
-- HUD OVERLAY (FPS & PING)
--------------------------------------------------------------------------------
local HUDGui = Instance.new("ScreenGui")
HUDGui.Name = "UniversalHUDOverlay"
HUDGui.ResetOnSpawn = false
HUDGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

local HUDLabel = Instance.new("TextLabel")
HUDLabel.Size = UDim2.new(0, 160, 0, 30)
HUDLabel.Position = UDim2.new(0, 10, 0, 10)
HUDLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
HUDLabel.BackgroundTransparency = 0.3
HUDLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
HUDLabel.TextSize = 14
HUDLabel.Font = Enum.Font.SourceSansBold
HUDLabel.Text = "FPS: 0 | Ping: 0 ms"
HUDLabel.Visible = false
HUDLabel.Parent = HUDGui

local HUDCorner = Instance.new("UICorner")
HUDCorner.CornerRadius = UDim.new(0, 6)
HUDCorner.Parent = HUDLabel

local frameCount = 0
local lastCheck = tick()
local currentFPS = 0

Connections["HUD_Loop"] = RunService.RenderStepped:Connect(function()
    if Config.HUD.FPSPing then
        frameCount = frameCount + 1
        if tick() - lastCheck >= 1 then
            currentFPS = frameCount
            frameCount = 0
            lastCheck = tick()
        end
        
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        
        HUDLabel.Text = string.format("FPS: %d | Ping: %d ms", currentFPS, ping)
    end
end)

--------------------------------------------------------------------------------
-- WINDOW & TABS CREATION
--------------------------------------------------------------------------------
local Window = OrionLib:MakeWindow({Name = "Universal Script | Delta Edition", HidePremium = true, SaveConfig = false, IntroEnabled = false})

local MoveTab = Window:MakeTab({Name = "Movement & Physics", Icon = "rbxassetid://4483362458"})
local CombatTab = Window:MakeTab({Name = "Combat & Visuals", Icon = "rbxassetid://4483362458"})
local SettingsTab = Window:MakeTab({Name = "Settings & HUD", Icon = "rbxassetid://4483362458"})

--------------------------------------------------------------------------------
-- MODULE 1: MOVEMENT & PHYSICS
--------------------------------------------------------------------------------
local SpeedSlider, GravitySlider, JumpSlider

-- WalkSpeed
MoveTab:AddToggle({
    Name = "Enable Speedhack", Default = false,
    Callback = function(Value)
        Config.Movement.Speed.Enabled = Value
        if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Config.Movement.Speed.Default
        end
    end
})
SpeedSlider = MoveTab:AddSlider({
    Name = "WalkSpeed Slider", Min = 16, Max = 50, Default = 16, Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value) Config.Movement.Speed.Value = Value end
})
MoveTab:AddTextbox({
    Name = "Exact WalkSpeed (Input)", Default = "16", TextDisappear = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then Config.Movement.Speed.Value = num; pcall(function() SpeedSlider:Set(num) end) end
    end
})

-- Gravity
MoveTab:AddToggle({
    Name = "Enable Custom Gravity", Default = false,
    Callback = function(Value)
        Config.Movement.Gravity.Enabled = Value
        if not Value then Workspace.Gravity = Config.Movement.Gravity.Default end
    end
})
GravitySlider = MoveTab:AddSlider({
    Name = "Gravity Slider", Min = 0, Max = 100, Default = 100, Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value) Config.Movement.Gravity.Value = Value end
})
MoveTab:AddTextbox({
    Name = "Exact Gravity (Input)", Default = "196.2", TextDisappear = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then Config.Movement.Gravity.Value = num; pcall(function() GravitySlider:Set(num) end) end
    end
})

-- Jump Power
MoveTab:AddToggle({
    Name = "Enable Custom Jump", Default = false,
    Callback = function(Value)
        Config.Movement.Jump.Enabled = Value
        if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            hum.JumpPower = Config.Movement.Jump.DefaultPower
            hum.JumpHeight = Config.Movement.Jump.DefaultHeight
        end
    end
})
JumpSlider = MoveTab:AddSlider({
    Name = "Jump Slider", Min = 50, Max = 250, Default = 50, Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value) Config.Movement.Jump.Value = Value end
})
MoveTab:AddTextbox({
    Name = "Exact Jump (Input)", Default = "50", TextDisappear = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then Config.Movement.Jump.Value = num; pcall(function() JumpSlider:Set(num) end) end
    end
})

-- Wall Hop
MoveTab:AddToggle({
    Name = "Enable Wall Hop", Default = false,
    Callback = function(Value) Config.Movement.WallHop.Enabled = Value end
})
MoveTab:AddSlider({
    Name = "Wall Hop Level", Min = 1, Max = 5, Default = 1, Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value) Config.Movement.WallHop.Level = Value end
})

Connections["WallHop_Hook"] = UserInputService.JumpRequest:Connect(function()
    if Config.Movement.WallHop.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local boost = Config.Movement.WallHop.Level * 12
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y + boost, hrp.AssemblyLinearVelocity.Z)
    end
end)

-- Fly & Noclip
MoveTab:AddToggle({
    Name = "Enable Noclip", Default = false,
    Callback = function(Value) Config.Movement.Noclip = Value end
})

Connections["Noclip_Loop"] = RunService.Stepped:Connect(function()
    if Config.Movement.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

local flyBodyVel, flyBodyGyro
MoveTab:AddToggle({
    Name = "Enable Fly", Default = false,
    Callback = function(Value)
        Config.Movement.Fly = Value
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            if Value then
                flyBodyVel = Instance.new("BodyVelocity")
                flyBodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyBodyVel.Velocity = Vector3.zero
                flyBodyVel.Parent = hrp

                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                flyBodyGyro.CFrame = hrp.CFrame
                flyBodyGyro.Parent = hrp
            else
                if flyBodyVel then flyBodyVel:Destroy() end
                if flyBodyGyro then flyBodyGyro:Destroy() end
            end
        end
    end
})

MoveTab:AddSlider({
    Name = "Fly Speed", Min = 10, Max = 200, Default = 50, Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value) Config.Movement.FlySpeed = Value end
})

Connections["Fly_Loop"] = RunService.RenderStepped:Connect(function()
    if Config.Movement.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if flyBodyVel and flyBodyGyro then
            flyBodyGyro.CFrame = Camera.CFrame
            local moveVec = hum and hum.MoveDirection or Vector3.zero
            if moveVec.Magnitude > 0 then
                flyBodyVel.Velocity = (Camera.CFrame.Rotation * moveVec).Unit * Config.Movement.FlySpeed
            else
                flyBodyVel.Velocity = Vector3.zero
            end
        end
    end
end)

-- Fling
MoveTab:AddToggle({
    Name = "Enable Fling", Default = false,
    Callback = function(Value) Config.Movement.Fling = Value end
})

Connections["Fling_Loop"] = RunService.Heartbeat:Connect(function()
    if Config.Movement.Fling and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.AssemblyAngularVelocity = Vector3.new(0, 99999, 0)
    end
end)

-- Jerk Script
MoveTab:AddButton({
    Name = "Jerk (Item Script)",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))()
    end
})
-- Universal Script for Delta Executor (Full Version - Part 2)

--------------------------------------------------------------------------------
-- MODULE 2: COMBAT & VISUALS
--------------------------------------------------------------------------------
-- China Hat
CombatTab:AddToggle({
    Name = "Enable China Hat", Default = false,
    Callback = function(Value) Config.ChinaHat.Enabled = Value end
})
CombatTab:AddColorpicker({
    Name = "Hat Color", Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value) Config.ChinaHat.Color = Value end
})
CombatTab:AddToggle({
    Name = "RGB Rainbow Mode", Default = false,
    Callback = function(Value) Config.ChinaHat.RGB = Value end
})

local HatPart = nil
local function RemoveHat()
    if HatPart then HatPart:Destroy(); HatPart = nil end
end

local function CreateHat()
    RemoveHat()
    HatPart = Instance.new("Part")
    HatPart.Size = Vector3.new(3, 1, 3)
    HatPart.CanCollide = false
    HatPart.Anchored = true
    HatPart.CastShadow = false
    HatPart.Material = Enum.Material.SmoothPlastic
    HatPart.Transparency = 0.2
    HatPart.Color = Config.ChinaHat.Color

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1033714"
    mesh.Scale = Vector3.new(2.2, 1.2, 2.2)
    mesh.Parent = HatPart
    HatPart.Parent = Workspace
end

local hue = 0
Connections["Hat_Loop"] = RunService.RenderStepped:Connect(function(dt)
    if Config.ChinaHat.Enabled then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") then
            if not HatPart or not HatPart.Parent then CreateHat() end
            HatPart.CFrame = char.Head.CFrame * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.rad(tick() * Config.ChinaHat.RotationSpeed % 360), 0)
            if Config.ChinaHat.RGB then
                hue = (hue + dt * 0.5) % 1
                HatPart.Color = Color3.fromHSV(hue, 1, 1)
            else
                HatPart.Color = Config.ChinaHat.Color
            end
        else
            RemoveHat()
        end
    else
        RemoveHat()
    end
end)

-- FOV Aimbot
CombatTab:AddToggle({ Name = "Enable Aimbot", Default = false, Callback = function(V) Config.Aimbot.Enabled = V end })
CombatTab:AddToggle({ Name = "Draw FOV Circle", Default = false, Callback = function(V) Config.Aimbot.ShowFOV = V end })
CombatTab:AddSlider({ Name = "FOV Radius", Min = 30, Max = 500, Default = 120, Color = Color3.fromRGB(255, 255, 255), Callback = function(V) Config.Aimbot.FOVRadius = V end })
CombatTab:AddSlider({ Name = "Smoothness", Min = 1, Max = 10, Default = 2, Color = Color3.fromRGB(255, 255, 255), Callback = function(V) Config.Aimbot.Smoothness = V / 10 end })
CombatTab:AddDropdown({ Name = "Priority Mode", Options = {"Crosshair", "Distance", "Lowest Health"}, Default = "Crosshair", Callback = function(V) Config.Aimbot.Priority = V end })
CombatTab:AddToggle({ Name = "Wall Check", Default = false, Callback = function(V) Config.Aimbot.WallCheck = V end })
CombatTab:AddToggle({ Name = "Team Check", Default = true, Callback = function(V) Config.Aimbot.TeamCheck = V end })
CombatTab:AddToggle({ Name = "Alive Check", Default = true, Callback = function(V) Config.Aimbot.AliveCheck = V end })

local function IsVisible(targetPart, character)
    if not Config.Aimbot.WallCheck then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    local result = Workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, rayParams)
    return result == nil
end

local function GetClosestTarget()
    local bestTarget = nil
    local bestMetric = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not Config.Aimbot.TeamCheck or player.Team ~= LocalPlayer.Team then
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") then
                    local hum = char.Humanoid
                    if not Config.Aimbot.AliveCheck or hum.Health > 0 then
                        local head = char.Head
                        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local screenVec = Vector2.new(screenPos.X, screenPos.Y)
                            local distFromMouse = (screenVec - mousePos).Magnitude

                            if distFromMouse <= Config.Aimbot.FOVRadius then
                                if IsVisible(head, char) then
                                    local metric = distFromMouse
                                    if Config.Aimbot.Priority == "Distance" then
                                        local myChar = LocalPlayer.Character
                                        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                                            metric = (myChar.HumanoidRootPart.Position - head.Position).Magnitude
                                        end
                                    elseif Config.Aimbot.Priority == "Lowest Health" then
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

Connections["Aimbot_Loop"] = RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = Config.Aimbot.FOVRadius
    FOVCircle.Visible = Config.Aimbot.ShowFOV

    if Config.Aimbot.Enabled then
        local targetHead = GetClosestTarget()
        if targetHead then
            local currentCF = Camera.CFrame
            local targetCF = CFrame.lookAt(currentCF.Position, targetHead.Position)
            Camera.CFrame = currentCF:Lerp(targetCF, 1 - Config.Aimbot.Smoothness)
        end
    end
end)

-- Hitbox Expander
CombatTab:AddToggle({ Name = "Enable Hitbox", Default = false, Callback = function(V) Config.Hitbox.Enabled = V end })
CombatTab:AddSlider({ Name = "Hitbox Size", Min = 2, Max = 60, Default = 10, Color = Color3.fromRGB(255, 255, 255), Callback = function(V) Config.Hitbox.Size = V end })
CombatTab:AddSlider({ Name = "Transparency", Min = 0, Max = 10, Default = 5, Color = Color3.fromRGB(255, 255, 255), Callback = function(V) Config.Hitbox.Transparency = V / 10 end })
CombatTab:AddColorpicker({ Name = "Hitbox Color", Default = Color3.fromRGB(255, 0, 0), Callback = function(V) Config.Hitbox.Color = V end })
CombatTab:AddToggle({ Name = "Always On Top", Default = false, Callback = function(V) Config.Hitbox.AlwaysOnTop = V end })
CombatTab:AddToggle({ Name = "Team Check", Default = true, Callback = function(V) Config.Hitbox.TeamCheck = V end })

Connections["Hitbox_Loop"] = RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isTeammate = Config.Hitbox.TeamCheck and (player.Team == LocalPlayer.Team)
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local hrp = char.HumanoidRootPart
                local hum = char.Humanoid
                if Config.Hitbox.Enabled and not isTeammate and hum.Health > 0 then
                    hrp.Size = Vector3.new(Config.Hitbox.Size, Config.Hitbox.Size, Config.Hitbox.Size)
                    hrp.Transparency = Config.Hitbox.Transparency
                    hrp.Color = Config.Hitbox.Color
                    hrp.Material = Config.Hitbox.AlwaysOnTop and Enum.Material.ForceField or Enum.Material.SmoothPlastic
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.Material = Enum.Material.SmoothPlastic
                end
            end
        end
    end
end)

-- Kill Sound
CombatTab:AddToggle({ Name = "Enable Kill Sound", Default = false, Callback = function(V) Config.KillSound.Enabled = V end })
CombatTab:AddTextbox({
    Name = "Sound Asset ID", Default = "4817809188", TextDisappear = false,
    Callback = function(Text) Config.KillSound.SoundId = Text end
})

local function HookKillSound(player)
    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function()
                if Config.KillSound.Enabled then
                    local sound = Instance.new("Sound", SoundService)
                    sound.SoundId = "rbxassetid://" .. Config.KillSound.SoundId
                    sound.Volume = 2
                    sound:Play()
                    game:GetService("Debris"):AddItem(sound, 3)
                end
            end)
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then HookKillSound(player) end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then HookKillSound(player) end
end)

--------------------------------------------------------------------------------
-- MODULE 3: SETTINGS & UTILITIES
--------------------------------------------------------------------------------
SettingsTab:AddToggle({
    Name = "Show FPS & Ping HUD", Default = false,
    Callback = function(Value)
        Config.HUD.FPSPing = Value
        HUDLabel.Visible = Value
    end
})

SettingsTab:AddButton({
    Name = "Rejoin Server",
    Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end
})

SettingsTab:AddButton({
    Name = "Unload Script",
    Callback = function()
        for _, conn in pairs(Connections) do conn:Disconnect() end
        FOVCircle:Remove()
        HUDGui:Destroy()
        RemoveHat()
        OrionLib:Destroy()
    end
})

-- Main Loop for Character Physics Overrides
Connections["MainMovement_Loop"] = RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Config.Movement.Speed.Enabled then hum.WalkSpeed = Config.Movement.Speed.Value end
        if Config.Movement.Gravity.Enabled then Workspace.Gravity = Config.Movement.Gravity.Value end
        if Config.Movement.Jump.Enabled then
            hum.JumpPower = Config.Movement.Jump.Value
            hum.JumpHeight = Config.Movement.Jump.Value
        end
    end
end)

OrionLib:Init()
