local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- State variables
local chestsCollected = 0
local webhookUrl = ""
local isTeleporting = false
local isCollecting = true
local cooldownSeconds = 15
local HOLD_DURATION = 1.5 -- 1.5-second hold as requested

-- Create Custom Venus Hub UI
local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VenusHubUI"
    ScreenGui.Parent = player.PlayerGui
    ScreenGui.ResetOnSpawn = false

    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 400, 0, 340)
    Frame.Position = UDim2.new(0.5, -200, 0.5, -170)
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 5)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    Frame.ClipsDescendants = true

    -- Rounded Corners
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame

    -- Cosmic Glow
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Thickness = 2
    UIStroke.Color = Color3.fromRGB(150, 0, 255)
    UIStroke.Transparency = 0.3
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Frame

    -- Cosmic Gradient
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 0, 80)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 20, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 80))
    }
    UIGradient.Rotation = 0
    UIGradient.Parent = Frame
    spawn(function()
        while true do
            local tween = TweenService:Create(UIGradient, TweenInfo.new(6, Enum.EasingStyle.Linear), {Rotation = 360})
            tween:Play()
            tween.Completed:Wait()
            UIGradient.Rotation = 0
        end
    end)

    -- Starry Speckles
    for i = 1, 10 do
        local Speckle = Instance.new("Frame")
        Speckle.Size = UDim2.new(0, 2, 0, 2)
        Speckle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        Speckle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Speckle.BorderSizePixel = 0
        Speckle.Parent = Frame
        local SpeckleCorner = Instance.new("UICorner")
        SpeckleCorner.CornerRadius = UDim.new(1, 0)
        SpeckleCorner.Parent = Speckle
        spawn(function()
            while true do
                local tween = TweenService:Create(Speckle, TweenInfo.new(1 + math.random(), Enum.EasingStyle.Sine), {BackgroundTransparency = 0.8})
                tween:Play()
                tween.Completed:Wait()
                tween = TweenService:Create(Speckle, TweenInfo.new(1 + math.random(), Enum.EasingStyle.Sine), {BackgroundTransparency = 0})
                tween:Play()
                tween.Completed:Wait()
            end
        end)
    end

    -- Title Label
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
    TitleLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Venus Hub - Chest Collector"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextScaled = true
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Parent = Frame
    local TitleStroke = Instance.new("UIStroke")
    TitleStroke.Thickness = 1
    TitleStroke.Color = Color3.fromRGB(200, 0, 255)
    TitleStroke.Parent = TitleLabel
    spawn(function()
        while true do
            local tween = TweenService:Create(TitleStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0.5})
            tween:Play()
            tween.Completed:Wait()
            tween = TweenService:Create(TitleStroke, TweenInfo.new(1, Enum.EasingStyle.Sine), {Transparency = 0})
            tween:Play()
            tween.Completed:Wait()
        end
    end)

    -- Chests Label
    local ChestsLabel = Instance.new("TextLabel")
    ChestsLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
    ChestsLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
    ChestsLabel.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
    ChestsLabel.Text = "Chests: 0"
    ChestsLabel.TextColor3 = Color3.fromRGB(150, 0, 255)
    ChestsLabel.TextScaled = true
    ChestsLabel.Font = Enum.Font.Gotham
    ChestsLabel.Parent = Frame
    local ChestsCorner = Instance.new("UICorner")
    ChestsCorner.CornerRadius = UDim.new(0, 8)
    ChestsCorner.Parent = ChestsLabel

    -- Webhook TextBox
    local WebhookBox = Instance.new("TextBox")
    WebhookBox.Size = UDim2.new(0.9, 0, 0.12, 0)
    WebhookBox.Position = UDim2.new(0.05, 0, 0.35, 0)
    WebhookBox.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
    WebhookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    WebhookBox.PlaceholderText = "Enter Discord Webhook URL"
    WebhookBox.Text = ""
    WebhookBox.TextScaled = true
    WebhookBox.Font = Enum.Font.Gotham
    WebhookBox.Parent = Frame
    local WebhookBoxCorner = Instance.new("UICorner")
    WebhookBoxCorner.CornerRadius = UDim.new(0, 8)
    WebhookBoxCorner.Parent = WebhookBox

    -- Save Webhook Button
    local SaveButton = Instance.new("TextButton")
    SaveButton.Size = UDim2.new(0.4, 0, 0.12, 0)
    SaveButton.Position = UDim2.new(0.3, 0, 0.5, 0)
    SaveButton.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
    SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveButton.Text = "Save Webhook"
    SaveButton.TextScaled = true
    SaveButton.Font = Enum.Font.GothamBold
    SaveButton.Parent = Frame
    local SaveButtonCorner = Instance.new("UICorner")
    SaveButtonCorner.CornerRadius = UDim.new(0, 8)
    SaveButtonCorner.Parent = SaveButton
    local SaveButtonStroke = Instance.new("UIStroke")
    SaveButtonStroke.Thickness = 1
    SaveButtonStroke.Color = Color3.fromRGB(200, 0, 255)
    SaveButtonStroke.Parent = SaveButton
    SaveButton.MouseEnter:Connect(function()
        local tween = TweenService:Create(SaveButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 0, 255)})
        tween:Play()
    end)
    SaveButton.MouseLeave:Connect(function()
        local tween = TweenService:Create(SaveButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150, 0, 255)})
        tween:Play()
    end)

    -- Warning Label for Slider
    local WarningLabel = Instance.new("TextLabel")
    WarningLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
    WarningLabel.Position = UDim2.new(0.05, 0, 0.65, 0)
    WarningLabel.BackgroundTransparency = 1
    WarningLabel.Text = ""
    WarningLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    WarningLabel.TextScaled = true
    WarningLabel.Font = Enum.Font.Gotham
    WarningLabel.Parent = Frame

    -- Cooldown Slider
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(0.9, 0, 0.1, 0)
    SliderFrame.Position = UDim2.new(0.05, 0, 0.8, 0)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
    SliderFrame.Parent = Frame
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(0, 8)
    SliderCorner.Parent = SliderFrame

    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(0.4, 0, 1, 0)
    SliderLabel.Position = UDim2.new(0, 0, 0, 0)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = "Cooldown: 15s"
    SliderLabel.TextColor3 = Color3.fromRGB(150, 0, 255)
    SliderLabel.TextScaled = true
    SliderLabel.Font = Enum.Font.Gotham
    SliderLabel.Parent = SliderFrame

    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(0.5, 0, 0.3, 0)
    SliderBar.Position = UDim2.new(0.45, 0, 0.35, 0)
    SliderBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    SliderBar.Parent = SliderFrame
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(0, 5)
    BarCorner.Parent = SliderBar

    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
    SliderFill.Parent = SliderBar
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 5)
    FillCorner.Parent = SliderFill

    local SliderKnob = Instance.new("Frame")
    SliderKnob.Size = UDim2.new(0.1, 0, 1.5, 0)
    SliderKnob.Position = UDim2.new(0.45, 0, -0.25, 0)
    SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderKnob.Parent = SliderBar
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(0, 5)
    KnobCorner.Parent = SliderKnob
    local KnobStroke = Instance.new("UIStroke")
    KnobStroke.Thickness = 1
    KnobStroke.Color = Color3.fromRGB(200, 0, 255)
    KnobStroke.Parent = SliderKnob

    -- Slider Logic with Warnings
    local draggingSlider = false
    SliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = (input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X
            relativeX = math.clamp(relativeX, 0, 1)
            SliderKnob.Position = UDim2.new(relativeX - 0.05, 0, -0.25, 0)
            SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            cooldownSeconds = math.floor(5 + (relativeX * 25)) -- 5 to 30 seconds
            SliderLabel.Text = "Cooldown: " .. cooldownSeconds .. "s"
            if cooldownSeconds < 10 then
                WarningLabel.Text = "WARNING: Cooldown < 10s increases anti-cheat detection risk!"
            else
                WarningLabel.Text = ""
            end
        end
    end)

    -- Collect Toggle
    local SwitchFrame = Instance.new("Frame")
    SwitchFrame.Size = UDim2.new(0.25, 0, 0.1, 0)
    SwitchFrame.Position = UDim2.new(0.68, 0, 0.92, 0)
    SwitchFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    SwitchFrame.Parent = Frame
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(0, 15)
    SwitchCorner.Parent = SwitchFrame

    local SwitchKnob = Instance.new("Frame")
    SwitchKnob.Size = UDim2.new(0.45, 0, 0.8, 0)
    SwitchKnob.Position = isCollecting and UDim2.new(0.5, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
    SwitchKnob.BackgroundColor3 = isCollecting and Color3.fromRGB(150, 0, 255) or Color3.fromRGB(100, 100, 100)
    SwitchKnob.Parent = SwitchFrame
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(0, 12)
    KnobCorner.Parent = SwitchKnob
    local KnobStroke = Instance.new("UIStroke")
    KnobStroke.Thickness = 1
    KnobStroke.Color = Color3.fromRGB(200, 0, 255)
    KnobStroke.Parent = SwitchKnob

    local SwitchLabel = Instance.new("TextLabel")
    SwitchLabel.Size = UDim2.new(0.4, 0, 1, 0)
    SwitchLabel.Position = UDim2.new(-0.45, 0, 0, 0)
    SwitchLabel.BackgroundTransparency = 1
    SwitchLabel.Text = "Collect"
    SwitchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SwitchLabel.TextScaled = true
    SwitchLabel.Font = Enum.Font.Gotham
    SwitchLabel.Parent = SwitchFrame

    SwitchFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isCollecting = not isCollecting
            local newPos = isCollecting and UDim2.new(0.5, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
            local newColor = isCollecting and Color3.fromRGB(150, 0, 255) or Color3.fromRGB(100, 100, 100)
            local tween = TweenService:Create(SwitchKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = newPos, BackgroundColor3 = newColor})
            tween:Play()
            ChestsLabel.Text = isCollecting and "Chests: " .. chestsCollected or "Collection paused. Toggle ON to resume."
        end
    end)

    -- Fade-In Animation
    Frame.BackgroundTransparency = 1
    UIStroke.Transparency = 1
    for _, child in pairs(Frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            child.BackgroundTransparency = 1
            child.TextTransparency = 1
        end
    end
    local fadeIn = TweenService:Create(Frame, TweenInfo.new(0.5), {BackgroundTransparency = 0})
    local strokeFade = TweenService:Create(UIStroke, TweenInfo.new(0.5), {Transparency = 0.3})
    fadeIn:Play()
    strokeFade:Play()
    for _, child in pairs(Frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            TweenService:Create(child, TweenInfo.new(0.5), {BackgroundTransparency = child.ClassName == "TextLabel" and 0 or child.BackgroundTransparency, TextTransparency = 0}):Play()
        end
    end)

    -- Update UI function
    local function updateUI()
        ChestsLabel.Text = isCollecting and "Chests: " .. chestsCollected or "Collection paused. Toggle ON to resume."
    end

    -- Save webhook URL
    SaveButton.MouseButton1Click:Connect(function()
        webhookUrl = WebhookBox.Text
        if webhookUrl ~= "" then
            local success, err = pcall(function()
                HttpService:PostAsync(webhookUrl, HttpService:JSONEncode({content = "Webhook test from Venus Hub!"}))
            end)
            if success then
                ChestsLabel.Text = "Webhook saved!"
                wait(1)
                updateUI()
            else
                ChestsLabel.Text = "Invalid webhook URL!"
                wait(2)
                updateUI()
            end
        end
    end)

    return ChestsLabel, updateUI, Frame, WarningLabel
end

-- Send webhook message
local function sendWebhook(chestName)
    if webhookUrl == "" then return end
    local data = {
        content = player.Name .. " collected a chest: " .. chestName .. " at " .. os.date("%Y-%m-%d %H:%M:%S")
    }
    local jsonData = HttpService:JSONEncode(data)
    local success, err = pcall(function()
        HttpService:PostAsync(webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
    end)
    if not success then
        warn("Webhook failed: " .. err)
    end
end

-- Collect chest function
local function collectChest(chest, updateUI, warningLabel)
    if isTeleporting or not chest.Parent or not humanoidRootPart.Parent or not isCollecting then
        warn("Cannot collect chest: Teleporting=" .. tostring(isTeleporting) .. ", ChestExists=" .. tostring(chest.Parent) .. ", PlayerAlive=" .. tostring(humanoidRootPart.Parent) .. ", Collecting=" .. tostring(isCollecting))
        return
    end
    isTeleporting = true

    local prompt
    if chest:IsA("BasePart") then
        prompt = chest:FindFirstChildOfClass("ProximityPrompt")
    elseif chest:IsA("Model") then
        prompt = chest:FindFirstChildOfClass("ProximityPrompt", true)
    end
    if not prompt then
        warn("No ProximityPrompt found on chest: " .. chest.Name)
        isTeleporting = false
        return
    end

    local partWithPrompt = prompt.Parent
    if not partWithPrompt:IsA("BasePart") then
        warn("ProximityPrompt is not parented to a BasePart: " .. partWithPrompt.Name)
        isTeleporting = false
        return
    end
    local chestPos = partWithPrompt.Position

    print("Teleporting to chest: " .. chest.Name .. " at " .. tostring(chestPos))

    humanoidRootPart.CFrame = CFrame.new(chestPos + Vector3.new(0, 3, 0))

    wait(0.1)

    local success, err = pcall(function()
        prompt:InputHoldBegin()
        wait(HOLD_DURATION) -- 1.5 seconds
        prompt:InputHoldEnd()
    end)
    if not success then
        warn("Failed to trigger ProximityPrompt: " .. err)
    end

    chestsCollected = chestsCollected + 1
    sendWebhook(chest.Name)
    updateUI()

    print("Cooldown: " .. cooldownSeconds .. " seconds")
    wait(cooldownSeconds)
    isTeleporting = false
end

-- Initialize UI
local ChestsLabel, updateUI, Frame, WarningLabel = createUI()

-- Start collecting
local function startCollecting()
    local chestContainer = workspace:FindFirstChild("ChestContainer")
    if not chestContainer then
        ChestsLabel.Text = "ChestContainer not found! Check path."
        warn("ChestContainer not found in workspace")
        return
    end
    print("Found ChestContainer: " .. chestContainer:GetFullName())

    while true do
        if not isCollecting then
            wait(1)
            continue
        end

        local chests = {}
        for _, chest in pairs(chestContainer:GetDescendants()) do
            if (chest:IsA("BasePart") or chest:IsA("Model")) and chest:FindFirstChildOfClass("ProximityPrompt") then
                table.insert(chests, chest)
                print("Found chest: " .. chest.Name)
            else
                print("Skipping non-chest object: " .. chest.Name .. " (" .. chest.ClassName .. ")")
            end
        end

        if #chests == 0 then
            ChestsLabel.Text = "No chests left! Waiting..."
            print("No chests found, waiting...")
            wait(5)
        else
            for _, chest in pairs(chests) do
                if chest.Parent and humanoidRootPart.Parent and isCollecting then
                    collectChest(chest, updateUI, WarningLabel)
                    wait(0.1)
                end
            end
        end
    end
end

-- Monitor new chests
local chestContainer = workspace:FindFirstChild("ChestContainer")
if chestContainer then
    chestContainer.DescendantAdded:Connect(function(chest)
        if (chest:IsA("BasePart") or chest:IsA("Model")) and chest:FindFirstChildOfClass("ProximityPrompt") and not isTeleporting and humanoidRootPart.Parent and isCollecting then
            print("New chest spawned: " .. chest.Name)
            collectChest(chest, updateUI, WarningLabel)
        end
    end)
else
    ChestsLabel.Text = "ChestContainer not found! Check path."
    warn("ChestContainer not found in workspace")
end

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    print("Character respawned, updated HumanoidRootPart")
end)

-- Make UI draggable
local dragging = false
local dragStart = nil
local startPos = nil

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

Frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Start collection
spawn(startCollecting)
