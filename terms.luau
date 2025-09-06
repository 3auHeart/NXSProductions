local promptRet = {}

local useStudio

local runService = game:GetService("RunService")
local coreGui = game:GetService('CoreGui')
local fin
local tweenService = game:GetService('TweenService')

if runService:IsStudio() then
	useStudio = true
end

local debounce = false
local acceptedPrompts = {}

local function calculateTextSize(text, textSize)
	local baseWidth = string.len(text) * (textSize * 0.6)
	local baseHeight = textSize * 1.5
	return Vector2.new(baseWidth, baseHeight)
end

local function adjustUISize(prompt)
	local titleSize = calculateTextSize(prompt.Policy.Title.Text, prompt.Policy.Title.TextSize)
	local noticeSize = calculateTextSize(prompt.Policy.Notice.Text, prompt.Policy.Notice.TextSize)
	local primarySize = calculateTextSize(prompt.Policy.Actions.Primary.Title.Text, prompt.Policy.Actions.Primary.Title.TextSize)
	
	local minWidth = 520
	local minHeight = 150
	
	local requiredWidth = math.max(titleSize.X + 60, noticeSize.X + 60, primarySize.X + 100)
	local requiredHeight = math.max(titleSize.Y + noticeSize.Y + 100, minHeight)
	
	if prompt.Policy.Actions:FindFirstChild("Secondary") then
		local secondarySize = calculateTextSize(prompt.Policy.Actions.Secondary.Title.Text, prompt.Policy.Actions.Secondary.Title.TextSize)
		requiredWidth = math.max(requiredWidth, primarySize.X + secondarySize.X + 140)
	end
	
	local finalWidth = math.max(minWidth, math.min(requiredWidth, 800))
	local finalHeight = math.max(minHeight, math.min(requiredHeight, 400))
	
	return UDim2.new(0, finalWidth, 0, finalHeight)
end

local function saveAcceptance(promptId)
	acceptedPrompts[promptId] = true
end

local function hasAccepted(promptId)
	return acceptedPrompts[promptId] == true
end

local function open(prompt)
	if debounce then return end
	debounce = true
	
	local targetSize = adjustUISize(prompt)
	prompt.Policy.Size = UDim2.new(0, 450, 0, 120)

	prompt.Policy.BackgroundTransparency = 1
	prompt.Policy.Shadow.Image.ImageTransparency = 1
	prompt.Policy.Title.TextTransparency = 1
	prompt.Policy.Notice.TextTransparency = 1
	prompt.Policy.Actions.Primary.BackgroundTransparency = 1
	prompt.Policy.Actions.Primary.Shadow.ImageTransparency = 1
	prompt.Policy.Actions.Primary.Title.TextTransparency = 1

	if prompt.Policy.Actions:FindFirstChild("Secondary") then
		prompt.Policy.Actions.Secondary.Title.TextTransparency = 1
	end

	prompt.Policy.Actions.Primary.BackgroundColor3 = Color3.fromRGB(129, 31, 255)
	prompt.Policy.Visible = true
	prompt.Enabled = true
	
	tweenService:Create(prompt.Policy, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	tweenService:Create(prompt.Policy.Shadow.Image, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageTransparency = 0.6}):Play()
	tweenService:Create(prompt.Policy, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
	task.wait(0.15)
	tweenService:Create(prompt.Policy.Title, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	task.wait(0.03)
	tweenService:Create(prompt.Policy.Notice, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0.5}):Play()
	task.wait(0.15)
	tweenService:Create(prompt.Policy.Actions.Primary, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 0.3}):Play()
	tweenService:Create(prompt.Policy.Actions.Primary.Title, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0.2}):Play()
	tweenService:Create(prompt.Policy.Actions.Primary.Shadow, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageTransparency = 0.7}):Play()
	
	if prompt.Policy.Actions:FindFirstChild("Secondary") then
		tweenService:Create(prompt.Policy.Actions.Secondary.Title, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0.6}):Play()
	end
	
	debounce = false
end

local function close(prompt)
	if debounce then return end
	debounce = true
	
	tweenService:Create(prompt.Policy, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, 430, 0, 110)}):Play()
	tweenService:Create(prompt.Policy.Title, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	tweenService:Create(prompt.Policy.Notice, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()

	if prompt.Policy.Actions:FindFirstChild("Secondary") then
		tweenService:Create(prompt.Policy.Actions.Secondary.Title, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	end
	
	tweenService:Create(prompt.Policy.Actions.Primary, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	tweenService:Create(prompt.Policy.Actions.Primary.Title, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	tweenService:Create(prompt.Policy.Actions.Primary.Shadow, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
	tweenService:Create(prompt.Policy, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	tweenService:Create(prompt.Policy.Shadow.Image, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
	
	task.wait(1)
	if prompt and prompt.Parent then
		prompt:Destroy()
	end
	fin = true
	debounce = false
end

function promptRet.create(title, description, primary, secondary, callback, promptId)
	promptId = promptId or (title .. "_" .. description)
	
	if hasAccepted(promptId) then
		if callback then 
			task.spawn(callback, true)
		end
		return
	end
	
	local success, prompt = pcall(function()
		if useStudio then
			return script.Parent:FindFirstChild('Prompt')
		else
			return game:GetObjects("rbxassetid://97206084643256")[1]
		end
	end)
	
	if not success or not prompt then
		warn("Failed to load prompt UI")
		if callback then 
			task.spawn(callback, false)
		end
		return
	end
	
	prompt.Enabled = false

	if gethui then
		prompt.Parent = gethui()
	elseif syn and syn.protect_gui then 
		syn.protect_gui(prompt)
		prompt.Parent = coreGui
	elseif not useStudio and coreGui:FindFirstChild("RobloxGui") then
		prompt.Parent = coreGui:FindFirstChild("RobloxGui")
	elseif not useStudio then
		prompt.Parent = coreGui
	end

	prompt.Policy.Title.Text = title or ""
	prompt.Policy.Notice.Text = description or ""
	prompt.Policy.Actions.Primary.Title.Text = primary or "Accept"
	
	if not secondary or secondary == "" then
		if prompt.Policy.Actions:FindFirstChild("Secondary") then
			prompt.Policy.Actions.Secondary:Destroy()
		end
	else
		if prompt.Policy.Actions:FindFirstChild("Secondary") then
			prompt.Policy.Actions.Secondary.Title.Text = secondary
		end
	end

	local primaryConnection
	local secondaryConnection
	
	primaryConnection = prompt.Policy.Actions.Primary.Interact.MouseButton1Click:Connect(function()
		if primaryConnection then
			primaryConnection:Disconnect()
		end
		if secondaryConnection then
			secondaryConnection:Disconnect()
		end
		saveAcceptance(promptId)
		close(prompt)
		if callback then 
			task.spawn(callback, true)
		end
	end)

	if prompt.Policy.Actions:FindFirstChild("Secondary") then
		secondaryConnection = prompt.Policy.Actions.Secondary.Interact.MouseButton1Click:Connect(function()
			if primaryConnection then
				primaryConnection:Disconnect()
			end
			if secondaryConnection then
				secondaryConnection:Disconnect()
			end
			close(prompt)
			if callback then 
				task.spawn(callback, false)
			end
		end)
	end
	
	task.wait(0.5)
	task.spawn(open, prompt)
end

return promptRet
