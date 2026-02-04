-- ============================================================================
-- PROMPT SYSTEM MODULE
-- Professional OOP Implementation with Versioning
-- ============================================================================

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local PROMPT_CONFIG = {
    Storage = {
        FolderName = "Nexus",
        FileName = "accepted_prompts.json",
        SchemaVersion = 2,
    },
    Sizes = {
        MaxWidth = 520,
        MinWidth = 450,
        BaseHeight = 150,
        ClosedWidth = 430,
        ClosedHeight = 110,
        InitialWidth = 450,
        InitialHeight = 120,
        Padding = 40,
        ContentPadding = 80,
    },
    Typography = {
        TitleFont = Enum.Font.SourceSansBold,
        TitleSize = 18,
        DescriptionFont = Enum.Font.SourceSans,
        DescriptionSize = 14,
    },
    Colors = {
        PrimaryButton = Color3.fromRGB(129, 31, 255),
        PrimaryButtonHover = Color3.fromRGB(145, 50, 255),
    },
    Animation = {
        OpenDuration = 0.4,
        CloseDuration = 0.3,
        FadeDuration = 0.25,
        SizeEasing = Enum.EasingStyle.Quint,
        FadeEasing = Enum.EasingStyle.Exponential,
        EasingDirection = Enum.EasingDirection.Out,
    },
    Transparency = {
        ShadowVisible = 0.6,
        ShadowHidden = 1,
        DescriptionVisible = 0.5,
        PrimaryButtonVisible = 0.3,
        PrimaryTitleVisible = 0.2,
        PrimaryShadowVisible = 0.7,
        SecondaryTitleVisible = 0.6,
    },
    AssetId = "rbxassetid://97206084643256",
    MarkerName = "NexusPromptMarker",
    PromptName = "Prompt",
}

-- ============================================================================
-- STORAGE MANAGER CLASS
-- ============================================================================

local StorageManager = {}
StorageManager.__index = StorageManager

function StorageManager.New()
    local self = setmetatable({}, StorageManager)
    self.FolderPath = PROMPT_CONFIG.Storage.FolderName
    self.FilePath = self.FolderPath .. "/" .. PROMPT_CONFIG.Storage.FileName
    self.SchemaVersion = PROMPT_CONFIG.Storage.SchemaVersion
    self.Cache = nil
    return self
end

function StorageManager:EnsureFolderExists()
    if not isfolder(self.FolderPath) then
        makefolder(self.FolderPath)
    end
end

function StorageManager:Load()
    if self.Cache then
        return self.Cache
    end
    
    self:EnsureFolderExists()
    
    if not isfile(self.FilePath) then
        self.Cache = self:CreateDefaultData()
        return self.Cache
    end
    
    local Content = readfile(self.FilePath)
    local Success, Data = pcall(HttpService.JSONDecode, HttpService, Content)
    
    if not Success or type(Data) ~= "table" then
        self.Cache = self:CreateDefaultData()
        return self.Cache
    end
    
    self.Cache = self:MigrateData(Data)
    return self.Cache
end

function StorageManager:CreateDefaultData()
    return {
        SchemaVersion = self.SchemaVersion,
        Prompts = {},
    }
end

function StorageManager:MigrateData(Data)
    if not Data.SchemaVersion then
        local MigratedData = self:CreateDefaultData()
        for PromptId, Accepted in pairs(Data) do
            if type(Accepted) == "boolean" and Accepted then
                MigratedData.Prompts[PromptId] = {
                    AcceptedAt = os.time(),
                    Version = 1,
                }
            end
        end
        self:Save(MigratedData)
        return MigratedData
    end
    
    if Data.SchemaVersion < self.SchemaVersion then
        Data.SchemaVersion = self.SchemaVersion
        self:Save(Data)
    end
    
    return Data
end

function StorageManager:Save(Data)
    self:EnsureFolderExists()
    self.Cache = Data
    writefile(self.FilePath, HttpService:JSONEncode(Data))
end

function StorageManager:GetPromptData(PromptId)
    local Data = self:Load()
    return Data.Prompts[PromptId]
end

function StorageManager:SetPromptAccepted(PromptId, Version)
    local Data = self:Load()
    Data.Prompts[PromptId] = {
        AcceptedAt = os.time(),
        Version = Version or 1,
    }
    self:Save(Data)
end

function StorageManager:ClearPromptAcceptance(PromptId)
    local Data = self:Load()
    Data.Prompts[PromptId] = nil
    self:Save(Data)
end

function StorageManager:IsPromptAccepted(PromptId, RequiredVersion)
    local PromptData = self:GetPromptData(PromptId)
    
    if not PromptData then
        return false
    end
    
    if RequiredVersion and PromptData.Version < RequiredVersion then
        return false
    end
    
    return true
end

function StorageManager:ClearAll()
    self.Cache = self:CreateDefaultData()
    self:Save(self.Cache)
end

-- ============================================================================
-- PROMPT ANIMATOR CLASS
-- ============================================================================

local PromptAnimator = {}
PromptAnimator.__index = PromptAnimator

function PromptAnimator.New(PromptGui)
    local self = setmetatable({}, PromptAnimator)
    self.PromptGui = PromptGui
    self.Policy = PromptGui.Policy
    self.IsAnimating = false
    return self
end

function PromptAnimator:CreateTween(Instance, Duration, Properties, EasingStyle, EasingDirection)
    EasingStyle = EasingStyle or PROMPT_CONFIG.Animation.FadeEasing
    EasingDirection = EasingDirection or PROMPT_CONFIG.Animation.EasingDirection
    
    local TweenInformation = TweenInfo.new(Duration, EasingStyle, EasingDirection)
    return TweenService:Create(Instance, TweenInformation, Properties)
end

function PromptAnimator:SetInitialState()
    local Sizes = PROMPT_CONFIG.Sizes
    
    self.Policy.Size = UDim2.new(0, Sizes.InitialWidth, 0, Sizes.InitialHeight)
    self.Policy.BackgroundTransparency = 1
    self.Policy.Shadow.Image.ImageTransparency = 1
    self.Policy.Title.TextTransparency = 1
    self.Policy.Notice.TextTransparency = 1
    self.Policy.Actions.Primary.BackgroundTransparency = 1
    self.Policy.Actions.Primary.Shadow.ImageTransparency = 1
    self.Policy.Actions.Primary.Title.TextTransparency = 1
    
    local SecondaryButton = self.Policy.Actions:FindFirstChild("Secondary")
    if SecondaryButton then
        SecondaryButton.Title.TextTransparency = 1
    end
    
    self.Policy.Actions.Primary.BackgroundColor3 = PROMPT_CONFIG.Colors.PrimaryButton
end

function PromptAnimator:AnimateOpen(FinalSize)
    if self.IsAnimating then return end
    self.IsAnimating = true
    
    local AnimConfig = PROMPT_CONFIG.Animation
    local TransConfig = PROMPT_CONFIG.Transparency
    
    self:SetInitialState()
    self.Policy.Visible = true
    self.PromptGui.Enabled = true
    
    self:CreateTween(self.Policy, AnimConfig.OpenDuration, {BackgroundTransparency = 0}):Play()
    self:CreateTween(self.Policy.Shadow.Image, AnimConfig.FadeDuration, {ImageTransparency = TransConfig.ShadowVisible}):Play()
    self:CreateTween(self.Policy, 0.6, {Size = FinalSize}, AnimConfig.SizeEasing):Play()
    
    task.wait(0.15)
    self:CreateTween(self.Policy.Title, 0.35, {TextTransparency = 0}):Play()
    
    task.wait(0.03)
    self:CreateTween(self.Policy.Notice, AnimConfig.FadeDuration, {TextTransparency = TransConfig.DescriptionVisible}):Play()
    
    task.wait(0.15)
    self:CreateTween(self.Policy.Actions.Primary, 0.6, {BackgroundTransparency = TransConfig.PrimaryButtonVisible}):Play()
    self:CreateTween(self.Policy.Actions.Primary.Title, AnimConfig.FadeDuration, {TextTransparency = TransConfig.PrimaryTitleVisible}):Play()
    self:CreateTween(self.Policy.Actions.Primary.Shadow, AnimConfig.FadeDuration, {ImageTransparency = TransConfig.PrimaryShadowVisible}):Play()
    
    local SecondaryButton = self.Policy.Actions:FindFirstChild("Secondary")
    if SecondaryButton then
        self:CreateTween(SecondaryButton.Title, AnimConfig.FadeDuration, {TextTransparency = TransConfig.SecondaryTitleVisible}):Play()
    end
    
    self.IsAnimating = false
end

function PromptAnimator:AnimateClose()
    if self.IsAnimating then return end
    self.IsAnimating = true
    
    local AnimConfig = PROMPT_CONFIG.Animation
    local Sizes = PROMPT_CONFIG.Sizes
    
    self:CreateTween(self.Policy, AnimConfig.CloseDuration, {Size = UDim2.new(0, Sizes.ClosedWidth, 0, Sizes.ClosedHeight)}):Play()
    self:CreateTween(self.Policy.Title, 0.35, {TextTransparency = 1}):Play()
    self:CreateTween(self.Policy.Notice, AnimConfig.FadeDuration, {TextTransparency = 1}):Play()
    
    local SecondaryButton = self.Policy.Actions:FindFirstChild("Secondary")
    if SecondaryButton then
        self:CreateTween(SecondaryButton.Title, AnimConfig.FadeDuration, {TextTransparency = 1}):Play()
    end
    
    self:CreateTween(self.Policy.Actions.Primary, AnimConfig.OpenDuration, {BackgroundTransparency = 1}):Play()
    self:CreateTween(self.Policy.Actions.Primary.Title, AnimConfig.FadeDuration, {TextTransparency = 1}):Play()
    self:CreateTween(self.Policy.Actions.Primary.Shadow, AnimConfig.FadeDuration, {ImageTransparency = 1}):Play()
    self:CreateTween(self.Policy, 0.2, {BackgroundTransparency = 1}):Play()
    self:CreateTween(self.Policy.Shadow.Image, AnimConfig.FadeDuration, {ImageTransparency = 1}):Play()
    
    task.wait(0.5)
    self.IsAnimating = false
end

-- ============================================================================
-- PROMPT CLASS
-- ============================================================================

local Prompt = {}
Prompt.__index = Prompt

function Prompt.New(Options)
    local self = setmetatable({}, Prompt)
    
    self.Title = Options.Title or "Prompt"
    self.Description = Options.Description or ""
    self.PrimaryText = Options.PrimaryText or "Accept"
    self.SecondaryText = Options.SecondaryText
    self.Callback = Options.Callback
    self.PromptId = Options.PromptId or self.Title
    self.Version = Options.Version or 1
    
    self.PromptGui = nil
    self.Animator = nil
    self.Connections = {}
    self.IsDestroyed = false
    
    return self
end

function Prompt:CalculateDynamicSize()
    local Sizes = PROMPT_CONFIG.Sizes
    local Typography = PROMPT_CONFIG.Typography
    
    local TitleBounds = TextService:GetTextSize(
        self.Title,
        Typography.TitleSize,
        Typography.TitleFont,
        Vector2.new(Sizes.MaxWidth - Sizes.Padding, math.huge)
    )
    
    local DescriptionBounds = TextService:GetTextSize(
        self.Description,
        Typography.DescriptionSize,
        Typography.DescriptionFont,
        Vector2.new(Sizes.MaxWidth - Sizes.Padding, math.huge)
    )
    
    local ContentHeight = TitleBounds.Y + DescriptionBounds.Y + Sizes.ContentPadding
    local FinalHeight = math.max(Sizes.BaseHeight, ContentHeight)
    local FinalWidth = math.max(Sizes.MinWidth, math.min(Sizes.MaxWidth, math.max(TitleBounds.X + Sizes.Padding, DescriptionBounds.X + Sizes.Padding)))
    
    return UDim2.new(0, FinalWidth, 0, FinalHeight)
end

function Prompt:CreateGui()
    local UseStudio = RunService:IsStudio()
    
    if UseStudio then
        local StudioPrompt = script.Parent:FindFirstChild("Prompt")
        if StudioPrompt then
            self.PromptGui = StudioPrompt:Clone()
        end
    end
    
    if not self.PromptGui then
        local Objects = game:GetObjects(PROMPT_CONFIG.AssetId)
        if Objects and Objects[1] then
            self.PromptGui = Objects[1]
        end
    end
    
    if not self.PromptGui then
        warn("[PromptSystem] Failed to load prompt asset")
        return false
    end
    
    self.PromptGui.Enabled = false
    self.PromptGui.Name = PROMPT_CONFIG.PromptName
    self.PromptGui.Parent = CoreGui
    
    self:ConfigureGui()
    self.Animator = PromptAnimator.New(self.PromptGui)
    
    return true
end

function Prompt:ConfigureGui()
    local Policy = self.PromptGui.Policy
    
    Policy.Title.Text = self.Title
    Policy.Notice.Text = self.Description
    Policy.Actions.Primary.Title.Text = self.PrimaryText
    Policy.Title.TextWrapped = true
    Policy.Notice.TextWrapped = true
    
    local SecondaryButton = Policy.Actions:FindFirstChild("Secondary")
    
    if not self.SecondaryText or self.SecondaryText == "" then
        if SecondaryButton then
            SecondaryButton:Destroy()
        end
    else
        if SecondaryButton then
            SecondaryButton.Title.Text = self.SecondaryText
        end
    end
end

function Prompt:ConnectEvents()
    local Policy = self.PromptGui.Policy
    
    local PrimaryConnection = Policy.Actions.Primary.Interact.MouseButton1Click:Connect(function()
        if self.Animator.IsAnimating then return end
        self:Close(true)
    end)
    table.insert(self.Connections, PrimaryConnection)
    
    local SecondaryButton = Policy.Actions:FindFirstChild("Secondary")
    if SecondaryButton then
        local SecondaryConnection = SecondaryButton.Interact.MouseButton1Click:Connect(function()
            if self.Animator.IsAnimating then return end
            self:Close(false)
        end)
        table.insert(self.Connections, SecondaryConnection)
    end
end

function Prompt:Show()
    if self.IsDestroyed then return end
    
    if not self:CreateGui() then
        return
    end
    
    self:ConnectEvents()
    
    local FinalSize = self:CalculateDynamicSize()
    
    task.wait(0.5)
    task.spawn(function()
        self.Animator:AnimateOpen(FinalSize)
    end)
end

function Prompt:Close(Accepted)
    if self.IsDestroyed then return end
    
    self.Animator:AnimateClose()
    
    local Marker = CoreGui:FindFirstChild(PROMPT_CONFIG.MarkerName)
    if Marker then
        Marker:Destroy()
    end
    
    self:Destroy()
    
    if self.Callback then
        task.spawn(self.Callback, Accepted, self.PromptId, self.Version)
    end
end

function Prompt:Destroy()
    if self.IsDestroyed then return end
    self.IsDestroyed = true
    
    for _, Connection in ipairs(self.Connections) do
        if Connection.Connected then
            Connection:Disconnect()
        end
    end
    self.Connections = {}
    
    if self.PromptGui then
        self.PromptGui:Destroy()
        self.PromptGui = nil
    end
    
    self.Animator = nil
end

-- ============================================================================
-- PROMPT MANAGER CLASS
-- ============================================================================

local PromptManager = {}
PromptManager.__index = PromptManager

function PromptManager.New()
    local self = setmetatable({}, PromptManager)
    self.Storage = StorageManager.New()
    self.ActivePrompt = nil
    self.Queue = {}
    self.IsProcessingQueue = false
    return self
end

function PromptManager:CreateMarker()
    if CoreGui:FindFirstChild(PROMPT_CONFIG.MarkerName) then
        return false
    end
    
    local Marker = Instance.new("Folder")
    Marker.Name = PROMPT_CONFIG.MarkerName
    Marker.Parent = CoreGui
    
    return true
end

function PromptManager:RemoveMarker()
    local Marker = CoreGui:FindFirstChild(PROMPT_CONFIG.MarkerName)
    if Marker then
        Marker:Destroy()
    end
end

function PromptManager:Create(Options)
    local PromptId = Options.PromptId or Options.Title
    local Version = Options.Version or 1
    local ForceShow = Options.ForceShow or false
    
    if not ForceShow and self.Storage:IsPromptAccepted(PromptId, Version) then
        if Options.Callback then
            task.spawn(Options.Callback, true, PromptId, Version)
        end
        return nil
    end
    
    local OriginalCallback = Options.Callback
    Options.Callback = function(Accepted, Id, Ver)
        if Accepted then
            self.Storage:SetPromptAccepted(Id, Ver)
        end
        self.ActivePrompt = nil
        self:ProcessQueue()
        if OriginalCallback then
            OriginalCallback(Accepted, Id, Ver)
        end
    end
    
    local NewPrompt = Prompt.New(Options)
    
    if not self:CreateMarker() then
        table.insert(self.Queue, NewPrompt)
        return NewPrompt
    end
    
    self.ActivePrompt = NewPrompt
    NewPrompt:Show()
    
    return NewPrompt
end

function PromptManager:ProcessQueue()
    if self.IsProcessingQueue or #self.Queue == 0 then
        return
    end
    
    self.IsProcessingQueue = true
    
    task.wait(0.3)
    
    if self:CreateMarker() then
        local NextPrompt = table.remove(self.Queue, 1)
        if NextPrompt and not NextPrompt.IsDestroyed then
            self.ActivePrompt = NextPrompt
            NextPrompt:Show()
        end
    end
    
    self.IsProcessingQueue = false
end

function PromptManager:IsAccepted(PromptId, RequiredVersion)
    return self.Storage:IsPromptAccepted(PromptId, RequiredVersion)
end

function PromptManager:ClearAcceptance(PromptId)
    self.Storage:ClearPromptAcceptance(PromptId)
end

function PromptManager:ClearAllAcceptance()
    self.Storage:ClearAll()
end

function PromptManager:GetPromptInfo(PromptId)
    return self.Storage:GetPromptData(PromptId)
end

function PromptManager:CloseActive()
    if self.ActivePrompt then
        self.ActivePrompt:Close(false)
    end
end

function PromptManager:ClearQueue()
    for _, QueuedPrompt in ipairs(self.Queue) do
        QueuedPrompt:Destroy()
    end
    self.Queue = {}
end

function PromptManager:Cleanup()
    self:CloseActive()
    self:ClearQueue()
    self:RemoveMarker()
end

-- ============================================================================
-- MODULE INTERFACE
-- ============================================================================

local PromptSystem = {}

local DefaultManager = nil

function PromptSystem.GetManager()
    if not DefaultManager then
        DefaultManager = PromptManager.New()
    end
    return DefaultManager
end

function PromptSystem.Create(Title, Description, Primary, Secondary, Callback, PromptId, Version)
    local Manager = PromptSystem.GetManager()
    
    return Manager:Create({
        Title = Title,
        Description = Description,
        PrimaryText = Primary,
        SecondaryText = Secondary,
        Callback = Callback,
        PromptId = PromptId,
        Version = Version,
    })
end

function PromptSystem.CreateAdvanced(Options)
    local Manager = PromptSystem.GetManager()
    return Manager:Create(Options)
end

function PromptSystem.IsAccepted(PromptId, RequiredVersion)
    local Manager = PromptSystem.GetManager()
    return Manager:IsAccepted(PromptId, RequiredVersion)
end

function PromptSystem.ClearAcceptance(PromptId)
    local Manager = PromptSystem.GetManager()
    Manager:ClearAcceptance(PromptId)
end

function PromptSystem.ClearAllAcceptance()
    local Manager = PromptSystem.GetManager()
    Manager:ClearAllAcceptance()
end

function PromptSystem.GetPromptInfo(PromptId)
    local Manager = PromptSystem.GetManager()
    return Manager:GetPromptInfo(PromptId)
end

function PromptSystem.CloseActive()
    local Manager = PromptSystem.GetManager()
    Manager:CloseActive()
end

function PromptSystem.Cleanup()
    local Manager = PromptSystem.GetManager()
    Manager:Cleanup()
end

PromptSystem.Config = PROMPT_CONFIG

PromptSystem.StorageManager = StorageManager
PromptSystem.PromptAnimator = PromptAnimator
PromptSystem.Prompt = Prompt
PromptSystem.PromptManager = PromptManager

return PromptSystem
