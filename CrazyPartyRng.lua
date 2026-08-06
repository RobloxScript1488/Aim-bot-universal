--[[ 
   Crazy Party RPG V3.7.0 (Rayfield UI Integration)
   ==========================================================
   New Features:
   - Advanced bounding box ESP (box + HP bar + name/distance).
   - Targeting mode by distance or health.
   - Fully integrated Rayfield Library interface.
]]--

-- Services
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace       = game:GetService("Workspace")
local Camera          = Workspace.CurrentCamera
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer     = Players.LocalPlayer

-- Global cleanup check (ensuring a single instance)
if _G.KillAuraCleanup then
    _G.KillAuraCleanup()
end

-- Config and State
local Config = {
    MAX_RANGE         = 20,    -- Range for target detection
    COOLDOWN          = 0.2,   -- Time between attacks
    TRACK_LERP_SPEED  = 0.1,   -- Camera tracking lerp speed
    DEBUG_MODE        = false,
    TargetingMode     = "distance", -- "distance" or "health"
}
local ESPConfig = {
    Enabled     = false,       -- Toggle for ESP
    MaxDistance = 500,         -- Default max distance for ESP (slider range 100–1000)
}
local State = {
    Enabled         = false,
    TrackEnabled    = false,
    Weapon          = "Unarmed",
    HumanoidRootPart= nil,
    LastAttack      = 0,
    DebugLog        = {},
}

local DamageEvent = ReplicatedStorage:WaitForChild("GameContents"):WaitForChild("Remotes"):WaitForChild("DamageEvent")
local Connections = {}  -- Holds all event connections

-- Debug logger (if enabled)
local function debugLog(msg)
    if Config.DEBUG_MODE then
        print("[KillAura DEBUG]: " .. msg)
        table.insert(State.DebugLog, msg)
    end
end

------------------------------------------
-- Target Acquisition & Damage Processing
------------------------------------------
local function getSortedTargets()
    local targets = {}
    if not State.HumanoidRootPart then return targets end
    local playerPos = State.HumanoidRootPart.Position

    for _, mob in ipairs(Workspace.Mobs:GetChildren()) do
        local targetPart = mob:FindFirstChild("HumanoidRootPart")
                        or mob:FindFirstChild("Head")
                        or mob:FindFirstChild("Torso")
        if targetPart then
            local distance = (playerPos - targetPart.Position).Magnitude
            if distance <= Config.MAX_RANGE then
                table.insert(targets, { mob = mob, part = targetPart, distance = distance })
            end
        end
    end

    if Config.TargetingMode == "health" then
        table.sort(targets, function(a, b)
            local humanoidA = a.mob:FindFirstChildOfClass("Humanoid")
            local humanoidB = b.mob:FindFirstChildOfClass("Humanoid")
            if humanoidA and humanoidB then
                return humanoidA.Health < humanoidB.Health
            else
                return a.distance < b.distance
            end
        end)
    else
        table.sort(targets, function(a, b) return a.distance < b.distance end)
    end

    debugLog("Found " .. #targets .. " valid targets using " .. Config.TargetingMode .. " mode.")
    return targets
end

local function processDamage()
    if not State.Enabled or not State.HumanoidRootPart then return end
    local now = os.clock()
    if now - State.LastAttack < Config.COOLDOWN then return end

    local targets = getSortedTargets()
    if #targets > 0 then
        local nearest = targets[1]
        DamageEvent:FireServer(nearest.part, State.Weapon)
        State.LastAttack = now
        debugLog("Attacked target: " .. nearest.mob.Name)
    end
end

-- Update the currently equipped weapon
local function updateWeapon(character)
    local tool = character:FindFirstChildOfClass("Tool")
    State.Weapon = tool and tool.Name or "Unarmed"
    debugLog("Updated weapon: " .. State.Weapon)
end

-- Character handling: sets up HRP reference and weapon updates
local function onCharacterAdded(character)
    State.HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    debugLog("Character added; HRP acquired.")
    
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then updateWeapon(character) end
    end)
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then updateWeapon(character) end
    end)
    updateWeapon(character)
end

if LocalPlayer.Character then
    task.spawn(onCharacterAdded, LocalPlayer.Character)
end
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
table.insert(Connections, RunService.Heartbeat:Connect(processDamage))

---------------------
-- Camera Tracking
---------------------
local function trackTarget()
    if not State.TrackEnabled or not State.HumanoidRootPart then return end
    local targets = getSortedTargets()
    if #targets > 0 then
        local nearest = targets[1]
        local camPos = Camera.CFrame.Position
        local desiredCFrame = CFrame.new(camPos, nearest.part.Position)
        Camera.CFrame = Camera.CFrame:Lerp(desiredCFrame, Config.TRACK_LERP_SPEED)
    end
end
table.insert(Connections, RunService.RenderStepped:Connect(trackTarget))

--------------------------------------------------------------------------------
-- BOUNDING BOX ESP (2D lines + text + HP bar)
--------------------------------------------------------------------------------

local MobESPBoxes = {}

local function worldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    if onScreen then
        return Vector2.new(screenPos.X, screenPos.Y)
    end
    return nil
end

local function getModelCorners(model)
    if not model.PrimaryPart then
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
        if not root then return {} end
        local size = root.Size * 1.25
        local cframe = root.CFrame
        local half = size / 2
        local corners = {}
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local offset = Vector3.new(half.X * x, half.Y * y, half.Z * z)
                    table.insert(corners, (cframe * CFrame.new(offset)).Position)
                end
            end
        end
        return corners
    else
        local cframe, size = model:GetBoundingBox()
        local half = size / 2
        local corners = {}
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local offset = Vector3.new(half.X * x, half.Y * y, half.Z * z)
                    table.insert(corners, (cframe * CFrame.new(offset)).Position)
                end
            end
        end
        return corners
    end
end

local function createBox(mob)
    local boxData = {}

    boxData.OutlineTop    = Drawing.new("Line")
    boxData.OutlineBottom = Drawing.new("Line")
    boxData.OutlineLeft   = Drawing.new("Line")
    boxData.OutlineRight  = Drawing.new("Line")

    for _, line in ipairs({boxData.OutlineTop, boxData.OutlineBottom, boxData.OutlineLeft, boxData.OutlineRight}) do
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 2
        line.Transparency = 1
        line.Visible = false
    end

    boxData.HPBar = Drawing.new("Line")
    boxData.HPBar.Thickness = 3
    boxData.HPBar.Color = Color3.fromRGB(0, 255, 0)
    boxData.HPBar.Transparency = 1
    boxData.HPBar.Visible = false

    boxData.Label = Drawing.new("Text")
    boxData.Label.Center = true
    boxData.Label.Outline = true
    boxData.Label.Font = 2
    boxData.Label.Size = 13
    boxData.Label.Color = Color3.fromRGB(255, 255, 255)
    boxData.Label.Text = ""
    boxData.Label.Visible = false

    MobESPBoxes[mob] = boxData
end

local function removeBox(mob)
    local boxData = MobESPBoxes[mob]
    if boxData then
        for _, obj in pairs(boxData) do
            obj:Remove()
        end
        MobESPBoxes[mob] = nil
    end
end

local function updateBox(mob, dist)
    local boxData = MobESPBoxes[mob]
    if not boxData then
        createBox(mob)
        boxData = MobESPBoxes[mob]
    end

    local hrp = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
    local humanoid = mob:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then
        removeBox(mob)
        return
    end

    local corners = getModelCorners(mob)
    if #corners == 0 then
        removeBox(mob)
        return
    end

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    local onScreen = false
    for _, corner in ipairs(corners) do
        local screenPos = worldToViewport(corner)
        if screenPos then
            onScreen = true
            local x, y = screenPos.X, screenPos.Y
            if x < minX then minX = x end
            if y < minY then minY = y end
            if x > maxX then maxX = x end
            if y > maxY then maxY = y end
        end
    end

    if not onScreen then
        for _, obj in pairs(boxData) do
            obj.Visible = false
        end
        return
    end

    local boxWidth = maxX - minX
    local boxHeight = maxY - minY

    if boxWidth < 2 or boxHeight < 2 then
        for _, obj in pairs(boxData) do
            obj.Visible = false
        end
        return
    end

    boxData.OutlineTop.Visible = true
    boxData.OutlineTop.From = Vector2.new(minX, minY)
    boxData.OutlineTop.To   = Vector2.new(maxX, minY)

    boxData.OutlineBottom.Visible = true
    boxData.OutlineBottom.From = Vector2.new(minX, maxY)
    boxData.OutlineBottom.To   = Vector2.new(maxX, maxY)

    boxData.OutlineLeft.Visible = true
    boxData.OutlineLeft.From = Vector2.new(minX, minY)
    boxData.OutlineLeft.To   = Vector2.new(minX, maxY)

    boxData.OutlineRight.Visible = true
    boxData.OutlineRight.From = Vector2.new(maxX, minY)
    boxData.OutlineRight.To   = Vector2.new(maxX, maxY)

    local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local barHeight = boxHeight * hpPercent
    boxData.HPBar.Visible = true
    boxData.HPBar.From = Vector2.new(minX - 4, maxY)
    boxData.HPBar.To   = Vector2.new(minX - 4, maxY - barHeight)
    boxData.HPBar.Color = Color3.fromRGB(0, 255, 0)

    boxData.Label.Visible = true
    boxData.Label.Text = string.format("%s  %.0fm", mob.Name, dist)
    boxData.Label.Position = Vector2.new((minX + maxX)/2, minY - 16)
end

local function updateBoundingBoxes()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for mob, boxData in pairs(MobESPBoxes) do
            for _, obj in pairs(boxData) do
                obj.Visible = false
            end
        end
        return
    end

    local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
    local validMobs = {}

    for _, mob in ipairs(Workspace.Mobs:GetChildren()) do
        local hrp = mob:FindFirstChild("HumanoidRootPart")
                    or mob:FindFirstChild("Head")
                    or mob:FindFirstChild("Torso")
        if hrp then
            local dist = (playerPos - hrp.Position).Magnitude
            if ESPConfig.Enabled and dist <= ESPConfig.MaxDistance then
                validMobs[mob] = dist
            end
        end
    end

    for mob, dist in pairs(validMobs) do
        updateBox(mob, dist)
    end

    for mob, _ in pairs(MobESPBoxes) do
        if not validMobs[mob] then
            removeBox(mob)
        end
    end
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if ESPConfig.Enabled then
        updateBoundingBoxes()
    else
        for mob, _ in pairs(MobESPBoxes) do
            removeBox(mob)
        end
    end
end))

--------------------------------------------------------------------------------
-- RAYFIELD UI INITIALIZATION
--------------------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Crazy Party RPG V3.7.0",
    LoadingTitle = "Crazy Party RPG",
    LoadingSubtitle = "by Rayfield Library",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CrazyPartyRPG",
        FileName = "Config"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = State.Enabled,
    Flag = "KillAuraToggle",
    Callback = function(Value)
        State.Enabled = Value
        if not Value then State.LastAttack = 0 end
    end,
})

MainTab:CreateToggle({
    Name = "ESP",
    CurrentValue = ESPConfig.Enabled,
    Flag = "ESPToggle",
    Callback = function(Value)
        ESPConfig.Enabled = Value
    end,
})

MainTab:CreateDropdown({
    Name = "Target Mode",
    Options = {"distance", "health"},
    CurrentOption = {Config.TargetingMode},
    MultipleOptions = false,
    Flag = "TargetMode",
    Callback = function(Options)
        Config.TargetingMode = Options[1]
    end,
})

MainTab:CreateSlider({
    Name = "ESP Max Distance",
    Range = {100, 1000},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = ESPConfig.MaxDistance,
    Flag = "DistanceSlider",
    Callback = function(Value)
        ESPConfig.MaxDistance = Value
    end,
})

---------------------
-- Cleanup Routine
---------------------
_G.KillAuraCleanup = function()
    for _, conn in ipairs(Connections) do
        conn:Disconnect()
    end
    for mob, _ in pairs(MobESPBoxes) do
        removeBox(mob)
    end
    pcall(function()
        Rayfield:Destroy()
    end)
    local rayfieldGui = CoreGui:FindFirstChild("Rayfield")
    if rayfieldGui then 
        rayfieldGui:Destroy() 
    end
end