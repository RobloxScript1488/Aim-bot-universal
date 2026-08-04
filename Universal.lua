-- Universal Script with Rayfield Library (China Hat, FOV Aimbot, Hitboxes, Kill Say & Movement)
-- Optimized for Delta Executor (PC / Mobile)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Universal Script | Delta Edition",
    LoadingTitle = "Initializing All Modules...",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Global Configurations
local Config = {
    ChinaHat = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), RGB = false, RotationSpeed = 100 },
    Aimbot = { Enabled = false, ShowFOV = false, FOVRadius = 120, Smoothness = 0.2, Priority = "Crosshair", WallCheck = false, TeamCheck = true, AliveCheck = true },
    Hitbox = { Enabled = false, Size = 10, Transparency = 0.5, Color = Color3.fromRGB(255, 0, 0), AlwaysOnTop = false, TeamCheck = true },
    KillSay = { Enabled = false, Message = "ez" },
    Movement = {
        Speed = { Enabled = false, Value = 16, Default = 16 },
        Gravity = { Enabled = false, Value = 196.2, Default = 196.2 },
        Jump = { Enabled = false, Value = 50, DefaultPower = 50, DefaultHeight = 7.2 }
    }
}

--------------------------------------------------------------------------------
-- STABLE FOV GUI (ScreenGui for Delta/Mobile compatibility)
--------------------------------------------------------------------------------
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "UniversalFOVScreen"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

local FOVFrame = Instance.new("Frame")
FOVFrame.Size = UDim2.new(1, 0, 1, 0)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = false
FOVFrame.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1.5

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)

local FOVIndicator = Instance.new("Frame")
FOVIndicator.Name = "Circle"
FOVIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
FOVIndicator.BackgroundTransparency = 1
FOVIndicator.Parent = FOVFrame
FOVStroke.Parent = FOVIndicator
FOVCorner.Parent = FOVIndicator

--------------------------------------------------------------------------------
-- TABS
--------------------------------------------------------------------------------
local HatTab = Window:CreateTab("China Hat", 4483362458)
local AimTab = Window:CreateTab("FOV Aimbot", 4483362458)
local HitboxTab = Window:CreateTab("Hitbox Expander", 4483362458)
local MoveTab = Window:CreateTab("Movement / Physics", 4483362458)
local MiscTab = Window:CreateTab("Misc / KillSay", 4483362458)

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
RunService.RenderStepped:Connect(function(dt)
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
AimTab:CreateToggle({ Name = "Draw FOV Circle", CurrentValue = false, Callback = function(V) Config.Aimbot.ShowFOV = V; FOVFrame.Visible = V end })
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
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

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
                            local distFromCenter = (screenVec - screenCenter).Magnitude

                            if distFromCenter <= Config.Aimbot.FOVRadius then
                                if IsVisible(head, char) then
                                    local metric = distFromCenter
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

RunService.RenderStepped:Connect(function()
    local viewportSize = Camera.ViewportSize
    local centerPos = UDim2.new(0, viewportSize.X / 2, 0, viewportSize.Y / 2)
    FOVIndicator.Position = centerPos
    FOVIndicator.Size = UDim2.new(0, Config.Aimbot.FOVRadius * 2, 0, Config.Aimbot.FOVRadius * 2)

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

RunService.Heartbeat:Connect(function()
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
-- MODULE 4: MOVEMENT / PHYSICS
--------------------------------------------------------------------------------
local SpeedSlider, GravitySlider, JumpSlider

-- Speed Hack Controls
MoveTab:CreateToggle({
    Name = "Enable Speedhack",
    CurrentValue = false,
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
    Name = "WalkSpeed Slider",
    Range = {16, 50},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        Config.Movement.Speed.Value = Value
    end
})

MoveTab:CreateInput({
    Name = "Exact WalkSpeed (Input)",
    PlaceholderText = "16 - 50+",
    RemoveTextOnFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            Config.Movement.Speed.Value = num
            pcall(function() SpeedSlider:Set(num) end)
        end
    end
})

-- Gravity Controls
MoveTab:CreateToggle({
    Name = "Enable Custom Gravity",
    CurrentValue = false,
    Callback = function(Value)
        Config.Movement.Gravity.Enabled = Value
        if not Value then
            Workspace.Gravity = Config.Movement.Gravity.Default
        end
    end
})

GravitySlider = MoveTab:CreateSlider({
    Name = "Gravity Slider",
    Range = {0, 196.2},
    Increment = 1,
    CurrentValue = 196.2,
    Callback = function(Value)
        Config.Movement.Gravity.Value = Value
    end
})

MoveTab:CreateInput({
    Name = "Exact Gravity (Input)",
    PlaceholderText = "0 - 196.2",
    RemoveTextOnFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            Config.Movement.Gravity.Value = num
            pcall(function() GravitySlider:Set(num) end)
        end
    end
})

-- Jump Power / Height Controls
MoveTab:CreateToggle({
    Name = "Enable Custom Jump",
    CurrentValue = false,
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
    Name = "Jump Slider",
    Range = {7.2, 250},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(Value)
        Config.Movement.Jump.Value = Value
    end
})

MoveTab:CreateInput({
    Name = "Exact Jump (Input)",
    PlaceholderText = "7.2 - 250",
    RemoveTextOnFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            Config.Movement.Jump.Value = num
            pcall(function() JumpSlider:Set(num) end)
        end
    end
})

-- Bypass Loop (Prevents anti-cheat resets and animation overrides)
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if Config.Movement.Speed.Enabled then
                humanoid.WalkSpeed = Config.Movement.Speed.Value
            end

            if Config.Movement.Jump.Enabled then
                if humanoid.UseJumpPower then
                    humanoid.JumpPower = Config.Movement.Jump.Value
                else
                    humanoid.JumpHeight = Config.Movement.Jump.Value
                end
            end
        end
    end

    if Config.Movement.Gravity.Enabled then
        Workspace.Gravity = Config.Movement.Gravity.Value
    end
end)

--------------------------------------------------------------------------------
-- MODULE 5: AUTO-CHAT / KILL SAY
--------------------------------------------------------------------------------
MiscTab:CreateToggle({ Name = "Enable Kill Say", CurrentValue = false, Callback = function(V) Config.KillSay.Enabled = V end })
MiscTab:CreateInput({ Name = "Kill Say Text", PlaceholderText = "ez", RemoveTextOnFocusLost = false, Callback = function(Text) if Text and #Text > 0 then Config.KillSay.Message = Text end end })

local function SendChatMessage(msg)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then channel:SendAsync(msg) end
        else
            local sayEvent = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
            if sayEvent then sayEvent:FireServer(msg, "All") end
        end
    end)
end

local function HookPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function()
                if Config.KillSay.Enabled then
                    SendChatMessage(Config.KillSay.Message)
                end
            end)
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do HookPlayer(p) end
Players.PlayerAdded:Connect(HookPlayer)

--------------------------------------------------------------------------------
-- RESPAWN & RECOVERY LOGIC (CharacterAdded)
--------------------------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        if Config.Movement.Speed.Enabled then
            hum.WalkSpeed = Config.Movement.Speed.Value
        end
        if Config.Movement.Jump.Enabled then
            if hum.UseJumpPower then
                hum.JumpPower = Config.Movement.Jump.Value
            else
                hum.JumpHeight = Config.Movement.Jump.Value
            end
        end
    end
end)

Rayfield:Notify({ Title = "Full Script Loaded", Content = "Movement & Physics module successfully activated!", Duration = 4 })
