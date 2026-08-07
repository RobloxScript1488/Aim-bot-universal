local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Universal Script Hub",
    LoadingTitle = "script hub",
    LoadingSubtitle = "by Gubby",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "Hub"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvite",
        RememberJoins = true
    },
    KeySystem = false,
})

local GamesTab = Window:CreateTab("Игры", "gamepad")
GamesTab:CreateSection("Выбор игр")

GamesTab:CreateButton({
    Name = "Crazy Party Rpg",
    Callback = function()
        Rayfield:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RobloxScript1488/CrazyRpg/main/CrazyPartyRng.lua"))()
    end,
})

GamesTab:CreateButton({
    Name = "TBO (jjs)",
    Callback = function()
        Rayfield:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/cool5013/TBO/main/TBOscript"))()
    end,
})

local AimTab = Window:CreateTab("Aim Assist", "crosshair")
AimTab:CreateSection("Функции")

AimTab:CreateButton({
    Name = "Aim Assist + Hub",
    Callback = function()
        Rayfield:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RobloxScript1488/AimBot/main/Aimbot.lua"))()
    end,
})

AimTab:CreateButton({
    Name = "Infinity Yield",
    Callback = function()
        Rayfield:Destroy()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end,
})
