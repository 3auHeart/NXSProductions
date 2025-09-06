local promptRet = {}

local useStudio

local runService = game:GetService("RunService")
local coreGui = game:GetService('CoreGui')
local fin
local tweenService = game:GetService('TweenService')
local dataStoreService = game:GetService('DataStoreService')
local players = game:GetService('Players')

if runService:IsStudio() then
	useStudio = true
end

local debounce = false
local promptDataStore = dataStoreService:GetDataStore("PromptAccepted")

local function saveAcceptance(userId, promptId)
	pcall(function()
		promptDataStore:SetAsync(userId .. "_" .. promptId, true)
	end)
end

local function hasAccepted(userId, promptId)
	local success, result = pcall(function()
		return promptDataStore:GetAsync(userId .. "_" .. promptId)
	end)
	return success and result == true
end

local function calculateDynamicSize(titleText, descriptionText)
	local textService = game:GetService("TextService")
	local baseWidth = 520
	local baseHeight = 150
	local maxWidth = 800
	local maxHeight = 400
	
	local titleParams = {
		Text = titleText,
		Size = 20,
		Font = Enum.Font.GothamBold,
		Parent = workspace
	}
	
	local descParams = {
		Text = descriptionText,
		Size = 14,
		Font = Enum.Font.Gotham,
		Parent = workspace
	}
	
	local titleSize = textService:GetTextSize(titleText, 20, Enum.Font.GothamBold, Vector2.new(baseWidth - 60, math.huge))
	local descSize = textService:GetTextSize(descriptionText, 14, Enum.Font.Gotham, Vector2.new(baseWidth - 60, math.huge))
	
	local neededWidth = math.max(titleSize.X + 60, descSize.X + 60, baseWidth)
	local neededHeight = titleSize.Y + descSize.Y + 80
	
	neededWidth = math.min(neededWidth, maxWidth)
	neededHeight = math.max(neededHeight, baseHeight)
	neededHeight = math.min(neededHeight, maxHeight)
	
	return UDim2.new(0, neededWidth, 0, neededHeight)
end

local function open(prompt, dynamicSize)
	debounce = true
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
	tweenService:Create(prompt.Policy, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = dynamicSize}):Play()
	task.wait(0.15)
	tweenService:Create(prompt.Policy.Title, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	task.wait(0.03)
	tweenService:Create(prompt.Policy.Notice, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0.5}):Play()
	task.wait(0.15)
	tweenService:Create(prompt.Policy.Actions.Primary, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 0.3}):Play()
	tweenService:Create(prompt.Policy.Actions.Primary.Title, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0.2}):Play()
	tweenService:Create(prompt.Policy.Actions.Primary.Shadow, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageTransparency = 0.7}):Play()
	
	if prompt.Policy.Actions:FindFirstChild("Secondary") and not fin then
		tweenService:Create(prompt.Policy.Actions.Secondary.Title, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0.6}):Play()
		debounce = false
	end
end

local function close(prompt)
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
	prompt:Destroy()
	fin = true
end

function promptRet.create(title, description, primary, secondary, callback, promptId)
	local userId = players.LocalPlayer.UserId
	promptId = promptId or title:gsub("%s+", "_")
	
	if hasAccepted(userId, promptId) then
		if callback then callback(true) end
		return
	end

	local prompt = useStudio and script.Parent:FindFirstChild('Prompt') or game:GetObjects("rbxassetid://97206084643256")[1]
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

	prompt.Policy.Title.Text = title
	prompt.Policy.Notice.Text = description
	prompt.Policy.Actions.Primary.Title.Text = primary
	
	local dynamicSize = calculateDynamicSize(title, description)
	
	if secondary == "" then
		prompt.Policy.Actions.Secondary:Destroy()
	else
		prompt.Policy.Actions.Secondary.Title.Text = secondary
	end

	prompt.Policy.Actions.Primary.Interact.MouseButton1Click:Connect(function()
		saveAcceptance(userId, promptId)
		close(prompt)
		if callback then callback(true) end
	end)

	if prompt.Policy.Actions:FindFirstChild("Secondary") then
		prompt.Policy.Actions.Secondary.Interact.MouseButton1Click:Connect(function()
			close(prompt)
			if callback then callback(false) end
		end)
	end
	task.wait(0.5)
	task.spawn(open, prompt, dynamicSize)
end

return promptRet
