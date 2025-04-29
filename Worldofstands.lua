local success, err = pcall(function()
    -- Load SenpaiLib
    local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Senpai%20Lib"))()

    -- Game Services
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)

    -- State Variables
    local chestsCollected = 0
    local webhookUrl = ""
    local isTeleporting = false
    local isCollecting = false -- Default OFF
    local cooldownSeconds = 15
    local HOLD_DURATION = 1.5 -- 1.5-second hold

    -- Create Venus Hub UI
    local Window = library:CreateWindow("Venus Hub - Chest Collector")

    -- Status Label (using Box as placeholder for text display)
    Window:Box("Status: Chests: 0 | Stopped", function() end) -- Read-only for status
    local statusBox = Window -- Store for updates

    -- Collect Toggle (using Buttons for ON/OFF)
    Window:Button("Start Collecting", function()
        isCollecting = true
        statusBox:Box("Status: Chests: " .. chestsCollected .. " | Collecting", function() end)
    end)
    Window:Button("Stop Collecting", function()
        isCollecting = false
        statusBox:Box("Status: Chests: " .. chestsCollected .. " | Stopped", function() end)
    end)

    -- Cooldown Slider
    Window:Slider("Cooldown (seconds)", 5, 30, 15, function(v)
        cooldownSeconds = v
        if v < 10 then
            statusBox:Box("Status: Chests: " .. chestsCollected .. " | WARNING: Low cooldown risks detection!", function() end)
            wait(2)
            statusBox:Box("Status: Chests: " .. chestsCollected .. " | " .. (isCollecting and "Collecting" or "Stopped"), function() end)
        end
    end)

    -- Webhook Textbox
    Window:Box("Webhook URL", function(v)
        webhookUrl = v
    end)

    -- Save Webhook Button
    Window:Button("Save Webhook", function()
        if webhookUrl ~= "" then
            local success, err = pcall(function()
                HttpService:PostAsync(webhookUrl, HttpService:JSONEncode({content = "Venus Hub: Webhook test!"}))
            end)
            statusBox:Box(success and "Status: Webhook saved!" or "Status: Invalid webhook URL!", function() end)
            wait(2)
            statusBox:Box("Status: Chests: " .. chestsCollected .. " | " .. (isCollecting and "Collecting" or "Stopped"), function() end)
        else
            statusBox:Box("Status: Enter a webhook URL!", function() end)
            wait(2)
            statusBox:Box("Status: Chests: " .. chestsCollected .. " | " .. (isCollecting and "Collecting" or "Stopped"), function() end)
        end
    end)

    -- Destroy UI Button
    Window:Button("Destroy GUI", function()
        library:Destroy() -- Assuming Destroy method exists
    end)

    -- Send Webhook
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

    -- Collect Chest
    local function collectChest(chest)
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
        statusBox:Box("Status: Chests: " .. chestsCollected .. " | Collecting", function() end)
        print("Cooldown: " .. cooldownSeconds .. "s")
        wait(cooldownSeconds)
        isTeleporting = false
    end

    -- Start Collecting
    local function startCollecting()
        local chestContainer = workspace:FindFirstChild("ChestContainer")
        if not chestContainer then
            statusBox:Box("Status: No ChestContainer found!", function() end)
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
                statusBox:Box("Status: No chests! Waiting...", function() end)
                print("No chests, waiting...")
                wait(5)
            else
                for _, chest in pairs(chests) do
                    if chest.Parent and humanoidRootPart.Parent and isCollecting then
                        collectChest(chest)
                        wait(0.1)
                    end
                end
            end
        end
    end

    -- Monitor New Chests
    local chestContainer = workspace:FindFirstChild("ChestContainer")
    if chestContainer then
        chestContainer.DescendantAdded:Connect(function(chest)
            if (chest:IsA("BasePart") or chest:IsA("Model")) and chest:FindFirstChildOfClass("ProximityPrompt") and not isTeleporting and humanoidRootPart.Parent and isCollecting then
                print("New chest: " .. chest.Name)
                collectChest(chest)
            end
        end)
    end

    -- Handle Respawn
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        print("Character respawned")
    end)

    -- Start Collection
    print("Starting Venus Hub")
    spawn(startCollecting)
end)

if not success then
    warn("Script failed to execute: " .. err)
end
