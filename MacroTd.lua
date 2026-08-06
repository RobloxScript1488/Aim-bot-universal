--[========================================================]--
--             ADVANCED MACRO SYSTEM FOR ROBLOX             --
--                Powered by Rayfield Library               --
--[========================================================]--

-- Проверка доступности окружения эксплойта
if not writefile or not readfile or not isfile then
    warn("Ваш эксплойт не поддерживает функции работы с файловой системой (writefile/readfile).")
    return
end

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Загрузка Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Состояние макроса
local MacroState = {
    IsRecording = false,
    IsPlaying = false,
    RecordedActions = {},
    StartTime = 0,
    ActionCount = 0,
    CurrentLoop = 0,
    MaxLoops = 1,
    CurrentActionIndex = 0,
    TotalActionsInCurrentLoop = 0,
}

-- Настраиваемые бинды (клавиши ПК)
local Binds = {
    Record = Enum.KeyCode.J,
    Stop = Enum.KeyCode.H,
    PlayToggle = Enum.KeyCode.X,
}

-- Настройки по умолчанию
local Settings = {
    FileName = "default_macro.json",
    LoopInput = "1",
}

-- Создание кастомного GUI для плавающих элементов и мини-режима
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("RayfieldMacroOverlay") then
    CoreGui.RayfieldMacroOverlay:Destroy()
end

local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "RayfieldMacroOverlay"
OverlayGui.ResetOnSpawn = false
OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OverlayGui.Parent = CoreGui

-- 1. Плавающая кнопка записи (для мобильных / визуализации)
local RecordWidget = Instance.new("Frame")
RecordWidget.Name = "RecordWidget"
RecordWidget.Size = UDim2.new(0, 220, 0, 70)
RecordWidget.Position = UDim2.new(0.5, -110, 0, 15)
RecordWidget.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
RecordWidget.BorderSizePixel = 0
RecordWidget.Visible = false
RecordWidget.Parent = OverlayGui

local UICornerRec = Instance.new("UICorner", RecordWidget)
UICornerRec.CornerRadius = UDim.new(0, 8)

local UIStrokeRec = Instance.new("UIStroke", RecordWidget)
UIStrokeRec.Color = Color3.fromRGB(255, 50, 50)
UIStrokeRec.Thickness = 2

local RecordStatusLabel = Instance.new("TextLabel", RecordWidget)
RecordStatusLabel.Size = UDim2.new(1, 0, 0, 30)
RecordStatusLabel.Position = UDim2.new(0, 0, 0, 5)
RecordStatusLabel.BackgroundTransparency = 1
RecordStatusLabel.Font = Enum.Font.GothamBold
RecordStatusLabel.Text = "🔴 ИДЕТ ЗАПИСЬ"
RecordStatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
RecordStatusLabel.TextSize = 14

local RecordStatsLabel = Instance.new("TextLabel", RecordWidget)
RecordStatsLabel.Size = UDim2.new(1, 0, 0, 30)
RecordStatsLabel.Position = UDim2.new(0, 0, 0, 35)
RecordStatsLabel.BackgroundTransparency = 1
RecordStatsLabel.Font = Enum.Font.Gotham
RecordStatsLabel.Text = "Время: 0.0с | Действий: 0"
RecordStatsLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
RecordStatsLabel.TextSize = 12

-- 2. Мини-режим виджет (статистика при воспроизведении)
local MiniWidget = Instance.new("Frame")
MiniWidget.Name = "MiniWidget"
MiniWidget.Size = UDim2.new(0, 240, 0, 80)
MiniWidget.Position = UDim2.new(0.5, -120, 0, 15)
MiniWidget.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MiniWidget.BorderSizePixel = 0
MiniWidget.Visible = false
MiniWidget.Parent = OverlayGui

local UICornerMini = Instance.new("UICorner", MiniWidget)
UICornerMini.CornerRadius = UDim.new(0, 8)

local UIStrokeMini = Instance.new("UIStroke", MiniWidget)
UIStrokeMini.Color = Color3.fromRGB(50, 150, 255)
UIStrokeMini.Thickness = 2

local MiniTitleLabel = Instance.new("TextLabel", MiniWidget)
MiniTitleLabel.Size = UDim2.new(1, 0, 0, 25)
MiniTitleLabel.Position = UDim2.new(0, 0, 0, 5)
MiniTitleLabel.BackgroundTransparency = 1
MiniTitleLabel.Font = Enum.Font.GothamBold
MiniTitleLabel.Text = "▶ ВОСПРОИЗВЕДЕНИЕ МАКРОСА"
MiniTitleLabel.TextColor3 = Color3.fromRGB(50, 150, 255)
MiniTitleLabel.TextSize = 13

local MiniCycleLabel = Instance.new("TextLabel", MiniWidget)
MiniCycleLabel.Size = UDim2.new(1, 0, 0, 22)
MiniCycleLabel.Position = UDim2.new(0, 0, 0, 30)
MiniCycleLabel.BackgroundTransparency = 1
MiniCycleLabel.Font = Enum.Font.Gotham
MiniCycleLabel.Text = "Цикл: 0 / 1"
MiniCycleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
MiniCycleLabel.TextSize = 12

local MiniProgressLabel = Instance.new("TextLabel", MiniWidget)
MiniProgressLabel.Size = UDim2.new(1, 0, 0, 22)
MiniProgressLabel.Position = UDim2.new(0, 0, 0, 52)
MiniProgressLabel.BackgroundTransparency = 1
MiniProgressLabel.Font = Enum.Font.Gotham
MiniProgressLabel.Text = "Прогресс: 0 / 0"
MiniProgressLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
MiniProgressLabel.TextSize = 12

-- Создание окна Rayfield
local Window = Rayfield:CreateWindow({
   Name = "Система Макросов | Rayfield",
   LoadingTitle = "Загрузка макро-системы...",
   LoadingSubtitle = "by Luau Developer",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "RayfieldMacros",
      FileName = "MacroConfig"
   },
   KeySystem = false,
})

-- Вкладки
local TabMain = Window:CreateTab("Макрос", 4483362458)
local TabSettings = Window:CreateTab("Настройки", 4483345998)

-- Переменные для элементов интерфейса, чтобы обновлять их динамически
local RecordButtonRef, PlayToggleRef

-- Логика записи
local recordConnection, renderConnection

local function StartRecording()
    if MacroState.IsPlaying or MacroState.IsRecording then return end
    MacroState.IsRecording = true
    MacroState.RecordedActions = {}
    MacroState.StartTime = os.clock()
    MacroState.ActionCount = 0

    RecordWidget.Visible = true
    if RecordButtonRef then
        RecordButtonRef:Set("Остановить запись")
    end

    -- Запись движения камеры и кликов
    local lastCameraCFrame = Camera.CFrame

    renderConnection = RunService.RenderStepped:ประจำ(function()
        if not MacroState.IsRecording then return end
        local currentTime = os.clock() - MacroState.StartTime
        
        -- Фиксация изменения камеры
        if Camera.CFrame ~= lastCameraCFrame then
            lastCameraCFrame = Camera.CFrame
            MacroState.ActionCount = MacroState.ActionCount + 1
            table.insert(MacroState.RecordedActions, {
                t = currentTime,
                type = "Camera",
                cf = {Camera.CFrame:GetComponents()}
            })
        end

        RecordStatsLabel.Text = string.Format("Время: %.1fs | Действий: %d", currentTime, MacroState.ActionCount)
    end)

    recordConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not MacroState.IsRecording then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local currentTime = os.clock() - MacroState.StartTime
            MacroState.ActionCount = MacroState.ActionCount + 1
            table.insert(MacroState.RecordedActions, {
                t = currentTime,
                type = "Input",
                inputType = input.UserInputType.Name,
                state = "Began",
                pos = {input.Position.X, input.Position.Y}
            })
        end
    end)
end

local function StopRecording()
    if not MacroState.IsRecording then return end
    MacroState.IsRecording = false

    if renderConnection then renderConnection:Disconnect() end
    if recordConnection then recordConnection:Disconnect() end

    RecordWidget.Visible = false
    if RecordButtonRef then
        RecordButtonRef:Set("Начать запись")
    end

    -- Сериализация и сохранение в файл
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(MacroState.RecordedActions)
    end)

    if success then
        writefile(Settings.FileName, encoded)
        Rayfield:Notify({
            Title = "Макрос сохранен",
            Content = "Файл успешно записан: " .. Settings.FileName,
            Duration = 3,
            Image = 4483362458,
        })
    else
        Rayfield:Notify({
            Title = "Ошибка",
            Content = "Не удалось сериализовать макрос.",
            Duration = 3,
            Image = 4483335205,
        })
    end
end

-- Логика воспроизведения
local playbackThread

local function StartPlayback()
    if MacroState.IsPlaying or MacroState.IsRecording then return end
    
    if not isfile(Settings.FileName) then
        Rayfield:Notify({Title = "Ошибка", Content = "Файл макроса не найден!", Duration = 3})
        if PlayToggleRef then PlayToggleRef:Set(false) end
        return
    end

    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(Settings.FileName))
    end)

    if not success or #decoded == 0 then
        Rayfield:Notify({Title = "Ошибка", Content = "Макрос пуст или поврежден.", Duration = 3})
        if PlayToggleRef then PlayToggleRef:Set(false) end
        return
    end

    MacroState.IsPlaying = true
    MacroState.TotalActionsInCurrentLoop = #decoded
    
    -- Парсинг количества повторений
    if string.lower(Settings.LoopInput) == "inf" then
        MacroState.MaxLoops = math.huge
    else
        MacroState.MaxLoops = tonumber(Settings.LoopInput) or 1
    end

    -- Сворачивание интерфейса Rayfield в мини-виджет
    Rayfield:Hide()
    MiniWidget.Visible = true

    playbackThread = task.spawn(function()
        MacroState.CurrentLoop = 0
        while MacroState.IsPlaying and MacroState.CurrentLoop < MacroState.MaxLoops do
            MacroState.CurrentLoop = MacroState.CurrentLoop + 1
            local loopStr = MacroState.MaxLoops == math.huge and "inf" or tostring(MacroState.MaxLoops)
            MiniCycleLabel.Text = string.Format("Цикл: %d / %s", MacroState.CurrentLoop, loopStr)

            local startTime = os.clock()
            local actionIndex = 1
            local total = #decoded

            while MacroState.IsPlaying and actionIndex <= total do
                local action = decoded[actionIndex]
                local elapsed = os.clock() - startTime

                if elapsed >= action.t then
                    MacroState.CurrentActionIndex = actionIndex
                    MiniProgressLabel.Text = string.Format("Прогресс: %d / %d", actionIndex, total)

                    if action.type == "Camera" then
                        Camera.CFrame = CFrame.new(unpack(action.cf))
                    elseif action.type == "Input" then
                        -- Эмуляция клика/тапа (при необходимости можно расширить VirtualInputManager)
                    end

                    actionIndex = actionIndex + 1
                else
                    task.wait()
                end
            end
        end

        -- Завершение воспроизведения
        StopPlayback()
    end)
end

local function StopPlayback()
    if not MacroState.IsPlaying then return end
    MacroState.IsPlaying = false

    if playbackThread then
        task.cancel(playbackThread)
        playbackThread = nil
    end

    MiniWidget.Visible = false
    Rayfield:Show()

    if PlayToggleRef then
        PlayToggleRef:Set(false)
    end

    Rayfield:Notify({
        Title = "Воспроизведение завершено",
        Content = "Макрос остановился.",
        Duration = 2,
    })
end

-- Элементы интерфейса Rayfield (Вкладка Макрос)
TabMain:CreateSection("Управление записью")

RecordButtonRef = TabMain:CreateButton({
   Name = "Начать запись",
   Callback = function()
      if not MacroState.IsRecording then
          StartRecording()
      else
          StopRecording()
      end
   end,
})

TabMain:CreateSection("Управление воспроизведением")

TabMain:CreateInput({
   Name = "Количество повторений",
   CurrentValue = "1",
   PlaceholderText = "Число или inf",
   RemoveTextAfterFocusLost = false,
   Flag = "LoopInputFlag",
   Callback = function(Value)
      Settings.LoopInput = Value
   end,
})

PlayToggleRef = TabMain:CreateToggle({
   Name = "Воспроизвести макрос",
   CurrentValue = false,
   Flag = "PlayToggleFlag",
   Callback = function(Value)
      if Value then
          StartPlayback()
      else
          StopPlayback()
      end
   end,
})

TabMain:CreateInput({
   Name = "Имя файла макроса",
   CurrentValue = "default_macro.json",
   PlaceholderText = "name.json",
   RemoveTextAfterFocusLost = false,
   Flag = "FileNameFlag",
   Callback = function(Value)
      Settings.FileName = Value ~= "" and Value or "default_macro.json"
   end,
})

-- Элементы интерфейса Rayfield (Вкладка Настройки / Бинды)
TabSettings:CreateSection("Горячие клавиши (ПК)")

TabSettings:CreateParagraph({Title = "Инструкция", Content = "Вы можете изменить клавиши управления макросом прямо здесь."})

-- Функция для конвертации строки в KeyCode
local function GetKeyCode(name)
    local success, code = pcall(function()
        return Enum.KeyCode[name]
    end)
    return success and code or nil
end

TabSettings:CreateInput({
   Name = "Бинд: Запуск записи",
   CurrentValue = "J",
   PlaceholderText = "KeyCode Name",
   RemoveTextAfterFocusLost = false,
   Callback = function(Value)
      local key = GetKeyCode(string.upper(Value))
      if key then Binds.Record = key end
   end,
})

TabSettings:CreateInput({
   Name = "Бинд: Остановка записи",
   CurrentValue = "H",
   PlaceholderText = "KeyCode Name",
   RemoveTextAfterFocusLost = false,
   Callback = function(Value)
      local key = GetKeyCode(string.upper(Value))
      if key then Binds.Stop = key end
   end,
})

TabSettings:CreateInput({
   Name = "Бинд: Старт/Стоп воспроизведения",
   CurrentValue = "X",
   PlaceholderText = "KeyCode Name",
   RemoveTextAfterFocusLost = false,
   Callback = function(Value)
      local key = GetKeyCode(string.upper(Value))
      if key then Binds.PlayToggle = key end
   end,
})

-- Глобальный обработчик клавиатурных биндов
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Binds.Record then
        if not MacroState.IsRecording then StartRecording() end
    elseif input.KeyCode == Binds.Stop then
        if MacroState.IsRecording then StopRecording() end
    elseif input.KeyCode == Binds.PlayToggle then
        if not MacroState.IsPlaying then
            if PlayToggleRef then PlayToggleRef:Set(true) end
        else
            if PlayToggleRef then PlayToggleRef:Set(false) end
        end
    end
end)

-- Очистка при выгрузке/смерти
Players.LocalPlayer.CharacterRemoving:Connect(function()
    if MacroState.IsRecording then StopRecording() end
    if MacroState.IsPlaying then StopPlayback() end
    OverlayGui:Destroy()
end)

Rayfield:LoadConfiguration()