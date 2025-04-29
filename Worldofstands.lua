local success, err = pcall(function()
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)

    -- State variables
    local chestsCollected = 0
    local webhookUrl = ""
    local isTeleporting = false
    local isCollecting = true
    local cooldownSeconds = 15
    local HOLD_DURATION = 1.5 -- 1.5-second hold

    -- Create Simplified Venus Hub UI
    local function createUI()
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VenusHubUI"
        ScreenGui.Parent = player.PlayerGui
        ScreenGui.ResetOnSpawn = false

        -- Main Frame
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 350, 0, 300)
        Frame.Position = UDim2.new(0.5, -175, 0.5, -150)
        Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        Frame.BorderSizePixel = 0
        Frame.Parent = ScreenGui

        -- Rounded Corners
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 10)
        UICorner.Parent = Frame

        -- Title Label
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
        TitleLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = "Venus Hub"
        TitleLabel.TextColor3 = Color3.fromRGB(200, 0, 255)
        TitleLabel.TextScaled = true
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.Parent = Frame

        -- Chests Label
        local ChestsLabel = Instance.new("TextLabel")
        ChestsLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
        ChestsLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
        ChestsLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        ChestsLabel.Text = "Chests: 0"
        ChestsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ChestsLabel.TextScaled = true
        ChestsLabel.Font = Enum.Font.Gotham
        ChestsLabel.Parent = Frame
        local ChestsCorner = Instance.new("UICorner")
        ChestsCorner.CornerRadius = UDim.new(0, 6)
        ChestsCorner.Parent = ChestsLabel

        -- Webhook TextBox
        local WebhookBox = Instance.new("TextBox")
        WebhookBox.Size = UDim2.new(0.9, 0, 0.15, 0)
        WebhookBox.Position = UDim2.new(0.05, 0, 0.45, 0)
        WebhookBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        WebhookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        WebhookBox.PlaceholderText = "Discord Webhook URL"
        WebhookBox.Text = ""
        WebhookBox.TextScaled = true
        WebhookBox.Font = Enum.Font.Gotham
        WebhookBox.Parent = Frame
        local WebhookBoxCorner = Instance.new("UICorner")
        WebhookBoxCorner.CornerRadius = UDim.new(0, 6)
        WebhookBoxCorner.Parent = WebhookBox

        -- Save Webhook Button
        local SaveButton = Instance.new("TextButton")
        SaveButton.Size = UDim2.new(0.4, 0, 0.15, 0)
        SaveButton.Position = UDim2.new(0.3, 0, 0.65, 0)
        SaveButton.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
        SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        SaveButton.Text = "Save"
        SaveButton.TextScaled = true
        SaveButton.Font = Enum.Font.GothamBold
        SaveButton.Parent = Frame
        local SaveButtonCorner = Instance.new("UICorner")
        SaveButtonCorner.CornerRadius = UDim.new(0, 6)
        SaveButtonCorner.Parent = SaveButton

        -- Cooldown Slider
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Size = UDim2.new(0.9, 0, 0.1, 0)
        SliderFrame.Position = UDim2.new(0.05, 0, 0.85, 0)
        SliderFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        SliderFrame.Parent = Frame
        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 6)
        SliderCorner.Parent = SliderFrame

        local SliderLabel = Instance.new("TextLabel")
        SliderLabel.Size = UDim2.new(0.4, 0, 1, 0)
        SliderLabel.Position = UDim2.new(0, 0, 0, 0)
        SliderLabel.BackgroundTransparency = 1
        SliderLabel.Text = "Cooldown: 15s"
        SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        SliderLabel.TextScaled = true
        SliderLabel.Font = Enum.Font.Gotham
        SliderLabel.Parent = SliderFrame

        local SliderBar = Instance.new("Frame")
        SliderBar.Size = UDim2.new(0.5, 0, 0.3, 0)
        SliderBar.Position = UDim2.new(0.45, 0, 0.35, 0)
        SliderBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        SliderBar.Parent = SliderFrame
        local BarCorner = Instance.new("UICorner")
        BarCorner.CornerRadius = UDim.new(0, 4)
        BarCorner.Parent = SliderBar

        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
        SliderFill.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
        SliderFill.Parent = SliderBar
        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(0, 4)
        FillCorner.Parent = SliderFill

        local SliderKnob = Instance.new("Frame")
        SliderKnob.Size = UDim2.new(0.1, 0, 1.5, 0)
        SliderKnob.Position = UDim2.new(0.45, 0, -0.25, 0)
        SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SliderKnob.Parent = SliderBar
        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(0, 4)
        KnobCorner.Parent = SliderKnob

        -- Slider Logic
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
                cooldownSeconds = math.floor(5 + (relativeX * 25))
                SliderLabel.Text = "Cooldown: " .. cooldownSeconds .. "s"
                ChestsLabel.Text = cooldownSeconds < 10 and "WARNING: Low cooldown risks detection!" or ("Chests: " .. chestsCollected)
            end
        end)

        -- Collect Toggle
        local SwitchFrame = Instance.new("Frame")
        SwitchFrame.Size = UDim2.new(0.25, 0, 0.1, 0)
        SwitchFrame.Position = UDim2.new(0.05, 0, 0.85, 0)
        SwitchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
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
                local tween = TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = newPos, BackgroundColor3 = newColor})
                tween:Play()
                ChestsLabel.Text = isCollecting and ("Chests: " .. chestsCollected) or "Collection paused."
            end
        end)

        -- Save Webhook
        SaveButton.MouseButton1Click:Connect(function()
            webhookUrl = WebhookBox.Text
            if webhookUrl ~= "" then
                local success, err = pcall(function()
                    HttpService:PostAsync(webhookUrl, HttpService:JSONEncode({content = "Venus Hub: Webhook test!"}))
                end)
                ChestsLabel.Text = success and "Webhook saved!" or "Invalid webhook URL!"
                wait(2)
                ChestsLabel.Text = isCollecting and ("Chests: " .. chestsCollected) or "Collection paused."
            end
        end)

        -- Update UI
        local function updateUI()
            ChestsLabel.Text = isCollecting and ("Chests: " .. chestsCollected) or "Collection paused."
        end

        return ChestsLabel, updateUI, Frame
    end

    -- Send webhook
    local function sendWebhook(chestName)
        if webhookUrl == "" then return end
        local success, err = pcall(function()
            local data = { content = player.Name .. " collected " .. chestName .. " at " .. os.date("%H:%M:%S") }
            HttpService:PostAsync(webhookUrl, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
        end)
        if not success then
            warn("Webhook failed: " .. err)
        end
    end

    -- Collect chest
    local function collectChest(chest, updateUI)
        if isTeleporting or not chest.Parent or not humanoidRootPart.Parent or not isCollecting then
            print("Cannot collect: Teleporting=" .. tostring(isTeleporting) .. ", Chest=" .. tostring(chest.Parent) .. ", Player=" .. tostring(humanoidRootPart.Parent) .. ", Collecting=" .. tostring(isCollecting))
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
            warn("No ProximityPrompt on " .. chest.Name)
            isTeleporting = false
            return
        end

        local part = prompt.Parent
        if not part:IsA("BasePart") then
            warn("ProximityPrompt not in BasePart: " .. part.Name)
            isTeleporting = false
            return
        end

        print("Teleporting to " .. chest.Name .. " at " .. tostring(part.Position))
        humanoidRootPart.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
        wait(0.1)

        local success, err = pcall(function()
            prompt:InputHoldBegin()
            wait(HOLD_DURATION)
            prompt:InputHoldEnd()
        end)
        if not success then
            warn("Prompt failed: " .. err)
        end

        chestsCollected = chestsCollected + 1
        sendWebhook(chest.Name)
        updateUI()
        print("Cooldown: " .. cooldownSeconds .. "s")
        wait(cooldownSeconds)
        isTeleporting = false
    end

    -- Initialize UI
    local ChestsLabel, updateUI, Frame = createUI()
    print("UI initialized")

    -- Start collecting
    local function startCollecting()
        local chestContainer = workspace:FindFirstChild("ChestContainer")
        if not chestContainer then
            ChestsLabel.Text = "No ChestContainer!"
            warn("No ChestContainer in workspace")
            return
        end
        print("Found ChestContainer")

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
                end
            end

            if #chests == 0 then
                ChestsLabel.Text = "No chests! Waiting..."
                print("No chests, waiting...")
                wait(5)
            else
                for _, chest in pairs(chests) do
                    if chest.Parent and humanoidRootPart.Parent and isCollecting then
                        collectChest(chest, updateUI)
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
                print("New chest: " .. chest.Name)
                collectChest(chest, updateUI)
            end
        end)
    end

    -- Handle respawn
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        print("Character respawned")
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
    print("Starting collection")
    spawn(startCollecting)
end)

if not success then
    warn("Script failed to execute: " .. err)
end
