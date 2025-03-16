-- No skid pls
local speedFactor = 1
local defaultShowTime = 4

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function showMessage(text, primaryColor, secondaryColor)
    primaryColor = primaryColor or Color3.fromRGB(111, 76, 255)
    secondaryColor = secondaryColor or Color3.fromRGB(66, 135, 245)

    local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationSystem"
    screenGui.IgnoreGuiInset = true

    local frame = Instance.new("Frame")
    local textLabel = Instance.new("TextLabel")
    local uiCorner = Instance.new("UICorner")
    local uiStroke = Instance.new("UIStroke")
    local uiGradient = Instance.new("UIGradient")
    local uiStrokeGradient = Instance.new("UIGradient")
    local glow = Instance.new("ImageLabel")

    screenGui.Parent = playerGui
    frame.Parent = screenGui
    textLabel.Parent = frame
    uiCorner.Parent = frame
    uiStroke.Parent = frame
    uiGradient.Parent = frame
    uiStrokeGradient.Parent = uiStroke
    glow.Parent = frame

    frame.Size = UDim2.new(0, 420, 0, 80)
    frame.Position = UDim2.new(1.1, 0, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BackgroundTransparency = 0.4
    frame.ClipsDescendants = true
    uiCorner.CornerRadius = UDim.new(0, 16)
    uiStroke.Thickness = 2.2
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Color = primaryColor
    uiStroke.Transparency = 1
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 30, 55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
    })
    uiGradient.Rotation = 35
    uiStrokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, primaryColor),
        ColorSequenceKeypoint.new(0.3, secondaryColor),
        ColorSequenceKeypoint.new(0.7, primaryColor),
        ColorSequenceKeypoint.new(1, secondaryColor)
    })
    textLabel.Size = UDim2.new(0.96, 0, 0.9, 0)
    textLabel.Position = UDim2.new(0.02, 0, 0.05, 0)
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(250, 250, 255)
    textLabel.TextTransparency = 1
    textLabel.TextScaled = true
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://6947150722"
    glow.ImageColor3 = primaryColor
    glow.ImageTransparency = 1
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Size = UDim2.new(1.2, 0, 1.5, 0)
    glow.ZIndex = -1

    local slideIn = TweenService:Create(frame, TweenInfo.new(1 / speedFactor, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -210, 0.4, 0)})
    local fadeInFrame = TweenService:Create(frame, TweenInfo.new(0.7 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundTransparency = 0.08})
    local fadeInStroke = TweenService:Create(uiStroke, TweenInfo.new(1 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Transparency = 0.15})
    local fadeInText = TweenService:Create(textLabel, TweenInfo.new(0.8 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0})
    local fadeInGlow = TweenService:Create(glow, TweenInfo.new(1.2 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {ImageTransparency = 0.85})

    local skip = false
    local hasSkipped = false
    local skipConnection = nil
    
    local function cleanup()
        if skipConnection then
            skipConnection:Disconnect()
            skipConnection = nil
        end
    end
    
    local function destroyNotification()
        cleanup()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end
    
    local function skipAnimation()
        if hasSkipped then return end
        hasSkipped = true
        skip = true
        
        slideIn:Cancel()
        fadeInFrame:Cancel()
        fadeInStroke:Cancel()
        fadeInText:Cancel()
        fadeInGlow:Cancel()

        frame.Position = UDim2.new(0.5, -210, 0.4, 0)
        frame.BackgroundTransparency = 0.08
        uiStroke.Transparency = 0.15
        textLabel.TextTransparency = 0
        glow.ImageTransparency = 0.85
        
        local fadeOutText = TweenService:Create(textLabel, TweenInfo.new(0.6 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {TextTransparency = 1})
        local fadeOutFrame = TweenService:Create(frame, TweenInfo.new(0.7 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        local fadeOutStroke = TweenService:Create(uiStroke, TweenInfo.new(0.6 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Transparency = 1})
        local fadeOutGlow = TweenService:Create(glow, TweenInfo.new(0.6 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {ImageTransparency = 1})
        local slideOut = TweenService:Create(frame, TweenInfo.new(0.9 / speedFactor, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0.4, 0)})

        fadeOutText:Play()
        task.wait(0.15 / speedFactor)
        fadeOutStroke:Play()
        fadeOutGlow:Play()
        task.wait(0.15 / speedFactor)
        fadeOutFrame:Play()
        slideOut:Play()

        task.wait(0.9 / speedFactor)
        destroyNotification()
    end

    skipConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.G then
            skipAnimation()
        end
    end)

    local success, error = pcall(function()
        slideIn:Play()
        fadeInFrame:Play()
        fadeInStroke:Play()
        fadeInText:Play()
        fadeInGlow:Play()

        task.spawn(function()
            if not skip then
                task.wait(defaultShowTime / speedFactor)
            end
            
            if hasSkipped then return end
            hasSkipped = true

            local fadeOutText = TweenService:Create(textLabel, TweenInfo.new(0.6 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {TextTransparency = 1})
            local fadeOutFrame = TweenService:Create(frame, TweenInfo.new(0.7 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            local fadeOutStroke = TweenService:Create(uiStroke, TweenInfo.new(0.6 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Transparency = 1})
            local fadeOutGlow = TweenService:Create(glow, TweenInfo.new(0.6 / speedFactor, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {ImageTransparency = 1})
            local slideOut = TweenService:Create(frame, TweenInfo.new(0.9 / speedFactor, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0.4, 0)})

            fadeOutText:Play()
            task.wait(0.15 / speedFactor)
            fadeOutStroke:Play()
            fadeOutGlow:Play()
            task.wait(0.15 / speedFactor)
            fadeOutFrame:Play()
            slideOut:Play()

            task.wait(0.9 / speedFactor)
            destroyNotification()
        end)
    end)
    
    if not success then
        warn("Error in notification system: " .. tostring(error))
        destroyNotification()
        return nil
    end
    
    return skipConnection
end

local connection = showMessage("Nexus Productions  .gg/nexusx", Color3.fromRGB(111, 76, 255), Color3.fromRGB(66, 135, 245))

task.delay(5.5, function()
    if connection then
        connection:Disconnect()
    end
end)
