local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Universal Script Hub",
    LoadingTitle = "Hub",
    LoadingSubtitle = "by Script Hub",
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
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RobloxScript1488/Aim-bot-universal/main/CrazyPartyRpg.lua"))()
    end,
})

local AimTab = Window:CreateTab("Aim Assist", "crosshair")
AimTab:CreateSection("Функции")

AimTab:CreateButton({
    Name = "Aim Assist + Hub",
    Callback = function()
        Rayfield:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RobloxScript1488/Aim-bot-universal/main/Universa.lua"))()
    end,
})
