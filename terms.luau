local promptRet = {}

local runService = game:GetService("RunService")
local coreGui = game:GetService("CoreGui")
local textService = game:GetService("TextService")
local tweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local useStudio
if runService:IsStudio() then
	useStudio = true
end

local debounce = false
local NexusPath = "Nexus/accepted_prompts.json"

local function ensureFolderExists()
	if not isfolder("Nexus") then
		makefolder("Nexus")
	end
end

local function loadAcceptedPrompts()
	ensureFolderExists()
	if isfile(NexusPath) then
		local content = readfile(NexusPath)
		local ok, data = pcall(HttpService.JSONDecode, HttpService, content)
		if ok and type(data) == "table" then
			return data
		end
	end
	return {}
end

local function saveAcceptedPrompts(data)
	ensureFolderExists()
	writefile(NexusPath, HttpService:JSONEncode(data))
end

local acceptedPrompts = loadAcceptedPrompts()
local activePrompt = nil

local function calculateDynamicSize(titleText, descriptionText)
	local maxWidth = 520
	local minWidth = 450
	local baseHeight = 150
	
	local titleBounds = textService:GetTextSize(titleText, 18, Enum.Font.SourceSansBold, Vector2.new(maxWidth - 40, math.huge))
	local descBounds = textService:GetTextSize(descriptionText, 14, Enum.Font.SourceSans, Vector2.new(maxWidth - 40, math.huge))
	
	local titleHeight = titleBounds.Y
	local descHeight = descBounds.Y
	
	local contentHeight = titleHeight + descHeight + 80
	local finalHeight = math.max(baseHeight, contentHeight)
	local finalWidth = math.max(minWidth, math.min(maxWidth, math.max(titleBounds.X + 40, descBounds.X + 40)))
	
	return UDim2.new(0, finalWidth, 0, finalHeight)
end

local function open(prompt, finalSize)
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
	tweenService:Create(prompt.Policy, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = finalSize}):Play()
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

local function close(prompt, accepted, promptId)
	debounce = true
	if accepted and promptId then
		acceptedPrompts[promptId] = true
		saveAcceptedPrompts(acceptedPrompts)
	end

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
	task.wait(0.5)
	activePrompt = nil
	prompt:Destroy()
end

function promptRet.create(title, description, primary, secondary, callback, promptId)
	if not promptId then promptId = title end

	if acceptedPrompts[promptId] then
		if callback then callback(true) end
		return
	end

	if activePrompt then
		return
	end

	activePrompt = true

	local prompt = useStudio and script.Parent:FindFirstChild('Prompt') or game:GetObjects("rbxassetid://97206084643256")[1]
	prompt.Enabled = false

	if gethui then
		prompt.Parent = gethui()
	elseif syn and syn.protect_gui then 
		syn.protect_gui(prompt)
		prompt.Parent = coreGui
	elseif not useStudio and coreGui:FindFirstChild("RobloxGui") then
		prompt.Parent = coreGui:FindFirstChild("RobloxGui")
	else
		prompt.Parent = coreGui
	end

	prompt.Policy.Title.Text = title
	prompt.Policy.Notice.Text = description
	prompt.Policy.Actions.Primary.Title.Text = primary
	prompt.Policy.Title.TextWrapped = true
	prompt.Policy.Notice.TextWrapped = true

	local finalSize = calculateDynamicSize(title, description)

	if secondary == "" or secondary == nil then
		if prompt.Policy.Actions:FindFirstChild("Secondary") then
			prompt.Policy.Actions.Secondary:Destroy()
		end
	else
		prompt.Policy.Actions.Secondary.Title.Text = secondary
	end

	prompt.Policy.Actions.Primary.Interact.MouseButton1Click:Connect(function()
		if debounce then return end
		close(prompt, true, promptId)
		if callback then callback(true) end
	end)

	if prompt.Policy.Actions:FindFirstChild("Secondary") then
		prompt.Policy.Actions.Secondary.Interact.MouseButton1Click:Connect(function()
			if debounce then return end
			close(prompt, false, promptId)
			if callback then callback(false) end
		end)
	end
	
	task.wait(0.5)
	task.spawn(open, prompt, finalSize)
end

function promptRet.isAccepted(promptId)
	if not promptId then return false end
	return acceptedPrompts[promptId] == true
end

function promptRet.clearAcceptance(promptId)
	if acceptedPrompts[promptId] then
		acceptedPrompts[promptId] = nil
		saveAcceptedPrompts(acceptedPrompts)
	end
end

return promptRet
