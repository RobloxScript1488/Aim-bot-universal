-- Universal Script with Rayfield Library (v3 Complete Update)
-- Optimized for Delta Executor (PC / Mobile)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

-- Global Configurations & State Management
local Connections = {}
local Config = {
    Language = "EN", -- "EN" or "RU"
    ChinaHat = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), RGB = false, RotationSpeed = 100 },
    Aimbot = { Enabled = false, ShowFOV = false, FOVRadius = 120, Smoothness = 0.2, Priority = "Crosshair", WallCheck = false, TeamCheck = true, AliveCheck = true },
    Hitbox = { Enabled = false, Size = 10, Transparency = 0.5, Color = Color3.fromRGB(255, 0, 0), AlwaysOnTop = false, TeamCheck = true },
    Movement = {
        Speed = { Enabled = false, Value = 16, Default = 16 },
        Gravity = { Enabled = false, Value = 196.2, Default = 196.2 },
        Jump = { Enabled = false, Value = 50, DefaultPower = 50, DefaultHeight = 7.2 },
        WallHop = { Enabled = false, Level = 1 },
        Noclip = { Enabled = false },
        Fly = { Enabled = false, Speed = 50 },
        Fling = { Enabled = false }
    },
    KillSound = { Enabled = false, SoundId = "132059151263428" },
    HUD = { FPSPing = false }
}

--------------------------------------------------------------------------------
-- DRAWING FOV CIRCLE (STRICTLY ROUND)
--------------------------------------------------------------------------------
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64 -- High num sides ensures perfectly round shape
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

Connections["HUD_Loop"] = RunService.RenderStepped:Connect(function(dt)
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
-- WINDOW CREATION
--------------------------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Universal Script | Delta Edition",
    LoadingTitle = "Initializing System...",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

--------------------------------------------------------------------------------
-- TABS CREATION
--------------------------------------------------------------------------------
local HatTab = Window:CreateTab("China Hat", 4483362458)
local AimTab = Window:CreateTab("FOV Aimbot", 4483362458)
local HitboxTab = Window:CreateTab("Hitbox Expander", 4483362458)
local MoveTab = Window:CreateTab("Movement / Physics", 4483362458)
local MiscTab = Window:CreateTab("Misc / Combat", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

--------------------------------------------------------------------------------
-- MODULE 1: CHINA HAT
--------------------------------------------------------------------------------
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

HatTab:CreateToggle({
    Name = "Enable China Hat", CurrentValue = false,
    Callback = function(V) Config.ChinaHat.Enabled = V if not V then RemoveHat() end end
})
HatTab:CreateColorPicker({
    Name = "Hat Color", Color = Color3.fromRGB(255, 0, 0),
    Callback = function(V) Config.ChinaHat.Color = V if HatPart then HatPart.Color = V end end
})
HatTab:CreateToggle({
    Name = "RGB Rainbow Mode", CurrentValue = false,
    Callback = function(V) Config.ChinaHat.RGB = V end
})

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

--------------------------------------------------------------------------------
-- MODULE 2: FOV AIMBOT
--------------------------------------------------------------------------------
AimTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(V) Config.Aimbot.Enabled = V end })
AimTab:CreateToggle({ Name = "Draw FOV Circle", CurrentValue = false, Callback = function(V) Config.Aimbot.ShowFOV = V end })
AimTab:CreateSlider({ Name = "FOV Radius", Range = {30, 500}, Increment = 5, CurrentValue = 120, Callback = function(V) Config.Aimbot.FOVRadius = V end })
AimTab:CreateSlider({ Name = "Smoothness", Range = {0.01, 1}, Increment = 0.01, CurrentValue = 0.2, Callback = function(V) Config.Aimbot.Smoothness = V end })
AimTab:CreateDropdown({ Name = "Priority Mode", Options = {"Crosshair", "Distance", "Lowest Health"}, CurrentOption = "Crosshair", Callback = function(V) Config.Aimbot.Priority = typeof(V) == "table" and V[1] or V end })
AimTab:CreateToggle({ Name = "Wall Check", CurrentValue = false, Callback = function(V) Config.Aimbot.WallCheck = V end })
AimTab:CreateToggle({ Name = "Team Check", CurrentValue = true, Callback = function(V) Config.Aimbot.TeamCheck = V end })
AimTab:CreateToggle({ Name = "Alive Check", CurrentValue = true, Callback = function(V) Config.Aimbot.AliveCheck = V end })

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

--------------------------------------------------------------------------------
-- MODULE 3: HITBOX EXPANDER
--------------------------------------------------------------------------------
HitboxTab:CreateToggle({ Name = "Enable Hitbox", CurrentValue = false, Callback = function(V) Config.Hitbox.Enabled = V end })
HitboxTab:CreateSlider({ Name = "Size", Range = {2, 60}, Increment = 1, CurrentValue = 10, Callback = function(V) Config.Hitbox.Size = V end })
HitboxTab:CreateSlider({ Name = "Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.5, Callback = function(V) Config.Hitbox.Transparency = V end })
HitboxTab:CreateColorPicker({ Name = "Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(V) Config.Hitbox.Color = V end })
HitboxTab:CreateToggle({ Name = "Always On Top", CurrentValue = false, Callback = function(V) Config.Hitbox.AlwaysOnTop = V end })
HitboxTab:CreateToggle({ Name = "Team Check", CurrentValue = true, Callback = function(V) Config.Hitbox.TeamCheck = V end })

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

--------------------------------------------------------------------------------
-- MODULE 4: MOVEMENT & PHYSICS
--------------------------------------------------------------------------------
local SpeedSlider, GravitySlider, JumpSlider

-- WalkSpeed
MoveTab:CreateToggle({
    Name = "Enable Speedhack", CurrentValue = false,
    Callback = function(Value)
        Config.Movement.Speed.Enabled = Value
        if not Value then
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").WalkSpeed = Config.Movement.Speed.Default
            end
        end
    end
})
SpeedSlider = MoveTab:CreateSlider({
    Name = "WalkSpeed Slider", Range = {16, 50}, Increment = 1, CurrentValue = 16,
    Callback = function(Value) Config.Movement.Speed.Value = Value end
})
MoveTab:CreateInput({
    Name = "Exact WalkSpeed (Input)", PlaceholderText = "16 - 50+", RemoveTextOnFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then Config.Movement.Speed.Value = num; pcall(function() SpeedSlider:Set(num) end) end
    end
})

-- Gravity
MoveTab:CreateToggle({
    Name = "Enable Custom Gravity", CurrentValue = false,
    Callback = function(Value)
        Config.Movement.Gravity.Enabled = Value
        if not Value then Workspace.Gravity = Config.Movement.Gravity.Default end
    end
})
GravitySlider = MoveTab:CreateSlider({
    Name = "Gravity Slider", Range = {0, 196.2}, Increment = 1, CurrentValue = 196.2,
    Callback = function(Value) Config.Movement.Gravity.Value = Value end
})
MoveTab:CreateInput({
    Name = "Exact Gravity (Input)", PlaceholderText = "0 - 196.2", RemoveTextOnFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then Config.Movement.Gravity.Value = num; pcall(function() GravitySlider:Set(num) end) end
    end
})

-- Jump Power
MoveTab:CreateToggle({
    Name = "Enable Custom Jump", CurrentValue = false,
    Callback = function(Value)
        Config.Movement.Jump.Enabled = Value
        if not Value then
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                hum.JumpPower = Config.Movement.Jump.DefaultPower
                hum.JumpHeight = Config.Movement.Jump.DefaultHeight
            end
        end
    end
})
JumpSlider = MoveTab:CreateSlider({
    Name = "Jump Slider", Range = {7.2, 250}, Increment = 1, CurrentValue = 50,
    Callback = function(Value) Config.Movement.Jump.Value = Value end
})
MoveTab:CreateInput({
    Name = "Exact Jump (Input)", PlaceholderText = "7.2 - 250", RemoveTextOnFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then Config.Movement.Jump.Value = num; pcall(function() JumpSlider:Set(num) end) end
    end
})

-- Wall Hop
MoveTab:CreateToggle({
    Name = "Enable Wall Hop", CurrentValue = false,
    Callback = function(Value) Config.Movement.WallHop.Enabled = Value end
})
MoveTab:CreateSlider({
    Name = "Wall Hop Acceleration Level", Range = {1, 5}, Increment = 1, CurrentValue = 1,
    Callback = function(Value) Config.Movement.WallHop.Level = Value end
})

-- Jump Impulse Hook for Wall Hop
Connections["WallHop_Hook"] = UserInputService.JumpRequest:Connect(function()
    if Config.Movement.WallHop.Enabled then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local boost = Config.Movement.WallHop.Level * 15
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y + boost, hrp.AssemblyLinearVelocity.Z)
        end
    end
end)

-- Fly & Noclip
MoveTab:CreateToggle({
    Name = "Enable Noclip", CurrentValue = false,
    Callback = function(Value) Config.Movement.Noclip.Enabled = Value end
})

Connections["Noclip_Loop"] = RunService.Stepped:Connect(function()
    if Config.Movement.Noclip.Enabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

local flying = false
local flyBodyVel, flyBodyGyro
MoveTab:CreateToggle({
    Name = "Enable Fly", CurrentValue = false,
    Callback = function(Value)
        Config.Movement.Fly.Enabled = Value
        flying = Value
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            if flying then
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

MoveTab:CreateSlider({
    Name = "Fly Speed", Range = {10, 200}, Increment = 5, CurrentValue = 50,
    Callback = function(Value) Config.Movement.Fly.Speed = Value end
})

Connections["Fly_Loop"] = RunService.RenderStepped:Connect(function()
    if Config.Movement.Fly.Enabled and flying then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and flyBodyVel and flyBodyGyro then
            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")
            local moveVec = hum and hum.MoveDirection or Vector3.zero
            
            flyBodyGyro.CFrame = Camera.CFrame
            if moveVec.Magnitude > 0 then
                flyBodyVel.Velocity = (Camera.CFrame.Rotation * moveVec).Unit * Config.Movement.Fly.Speed
            else
                flyBodyVel.Velocity = Vector3.zero
            end
        end
    end
end)

-- Fling
MoveTab:CreateToggle({
    Name = "
