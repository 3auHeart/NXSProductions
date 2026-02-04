-- ============================================================================
-- PROMPT INTERFACE MODULE
-- Made by the Nexus Team
-- Do NOT redistribute.
-- ============================================================================

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local PROMPT_CONFIG = {
    Sizing = {
        MaxWidth = 520,
        MinWidth = 450,
        BaseHeight = 150,
        Padding = 40,
        ButtonMinHeight = 44,
        MobileButtonMinHeight = 52,
    },
    Animation = {
        OpenDuration = 0.4,
        CloseDuration = 0.3,
        EasingStyle = Enum.EasingStyle.Exponential,
        EasingDirection = Enum.EasingDirection.Out,
    },
    Colors = {
        PrimaryButton = Color3.fromRGB(129, 31, 255),
        PrimaryButtonHover = Color3.fromRGB(145, 50, 255),
    },
    Storage = {
        FolderName = "Nexus",
        FileName = "accepted_prompts.json",
    },
}

-- ============================================================================
-- STORAGE MANAGER CLASS
-- ============================================================================

local StorageManager = {}
StorageManager.__index = StorageManager

function StorageManager.New()
    local self = setmetatable({}, StorageManager)
    self.FilePath = PROMPT_CONFIG.Storage.FolderName .. "/" .. PROMPT_CONFIG.Storage.FileName
    self.Cache = {}
    self:Load()
    return self
end

function StorageManager:EnsureFolderExists()
    if not isfolder(PROMPT_CONFIG.Storage.FolderName) then
        makefolder(PROMPT_CONFIG.Storage.FolderName)
    end
end

function StorageManager:Load()
    self:EnsureFolderExists()
    if isfile(self.FilePath) then
        local Content = readfile(self.FilePath)
        local Success, Data = pcall(HttpService.JSONDecode, HttpService, Content)
        if Success and type(Data) == "table" then
            self.Cache = Data
            return
        end
    end
    self.Cache = {}
end

function StorageManager:Save()
    self:EnsureFolderExists()
    local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, self.Cache)
    if Success then
        writefile(self.FilePath, Encoded)
    end
end

function StorageManager:GetAcceptedVersion(PromptId)
    local Entry = self.Cache[PromptId]
    if Entry and type(Entry) == "table" then
        return Entry.Version, Entry.AcceptedAt
    elseif Entry == true then
        return "1.0.0", nil
    end
    return nil, nil
end

function StorageManager:SetAccepted(PromptId, Version)
    self.Cache[PromptId] = {
        Version = Version,
        AcceptedAt = os.time(),
    }
    self:Save()
end

function StorageManager:ClearAcceptance(PromptId)
    if self.Cache[PromptId] then
        self.Cache[PromptId] = nil
        self:Save()
    end
end

function StorageManager:ClearAll()
    self.Cache = {}
    self:Save()
end

function StorageManager:IsVersionAccepted(PromptId, RequiredVersion)
    local AcceptedVersion = self:GetAcceptedVersion(PromptId)
    if not AcceptedVersion then
        return false
    end
    return self:CompareVersions(AcceptedVersion, RequiredVersion) >= 0
end

function StorageManager:CompareVersions(VersionA, VersionB)
    local function ParseVersion(VersionString)
        local Major, Minor, Patch = VersionString:match("^(%d+)%.?(%d*)%.?(%d*)$")
        return {
            Major = tonumber(Major) or 0,
            Minor = tonumber(Minor) or 0,
            Patch = tonumber(Patch) or 0,
        }
    end
    
    local A = ParseVersion(tostring(VersionA))
    local B = ParseVersion(tostring(VersionB))
    
    if A.Major ~= B.Major then
        return A.Major - B.Major
    elseif A.Minor ~= B.Minor then
        return A.Minor - B.Minor
    else
        return A.Patch - B.Patch
    end
end

-- ============================================================================
-- PROMPT BUILDER CLASS
-- ============================================================================

local PromptBuilder = {}
PromptBuilder.__index = PromptBuilder

function PromptBuilder.New()
    local self = setmetatable({}, PromptBuilder)
    self.UseStudio = RunService:IsStudio()
    return self
end

function PromptBuilder:CalculateDynamicSize(TitleText, DescriptionText)
    local Config = PROMPT_CONFIG.Sizing
    
    local TitleBounds = TextService:GetTextSize(
        TitleText,
        18,
        Enum.Font.SourceSansBold,
        Vector2.new(Config.MaxWidth - Config.Padding, math.huge)
    )
    
    local DescBounds = TextService:GetTextSize(
        DescriptionText,
        14,
        Enum.Font.SourceSans,
        Vector2.new(Config.MaxWidth - Config.Padding, math.huge)
    )
    
    local ContentHeight = TitleBounds.Y + DescBounds.Y + 80
    local FinalHeight = math.max(Config.BaseHeight, ContentHeight)
    local FinalWidth = math.max(
        Config.MinWidth,
        math.min(Config.MaxWidth, math.max(TitleBounds.X + Config.Padding, DescBounds.X + Config.Padding))
    )
    
    return UDim2.new(0, FinalWidth, 0, FinalHeight)
end

function PromptBuilder:GetPromptTemplate()
    if self.UseStudio then
        local Template = script.Parent:FindFirstChild("Prompt")
        if Template then
            return Template:Clone()
        end
    end
    
    local Objects = game:GetObjects("rbxassetid://97206084643256")
    if Objects and Objects[1] then
        return Objects[1]
    end
    
    return nil
end

function PromptBuilder:EnhanceButtonForMobile(Button)
    if Button:FindFirstChild("Interact") then
        local Interact = Button.Interact
        Interact.Size = UDim2.new(1, 20, 1, 20)
        Interact.Position = UDim2.new(0, -10, 0, -10)
        Interact.ZIndex = Interact.ZIndex + 10
        Interact.Active = true
        Interact.Selectable = true
        Interact.BackgroundTransparency = 1
    end
end

function PromptBuilder:Build(Options)
    local Template = self:GetPromptTemplate()
    if not Template then
        warn("[PromptInterface] Failed to load prompt template")
        return nil
    end
    
    Template.Enabled = false
    Template.Name = "Prompt_" .. HttpService:GenerateGUID(false):sub(1, 8)
    
    local Policy = Template.Policy
    Policy.Title.Text = Options.Title
    Policy.Title.TextWrapped = true
    Policy.Notice.Text = Options.Description
    Policy.Notice.TextWrapped = true
    
    local PrimaryButton = Policy.Actions.Primary
    PrimaryButton.Title.Text = Options.PrimaryText
    self:EnhanceButtonForMobile(PrimaryButton)
    
    local SecondaryButton = Policy.Actions:FindFirstChild("Secondary")
    if Options.SecondaryText and Options.SecondaryText ~= "" then
        if SecondaryButton then
            SecondaryButton.Title.Text = Options.SecondaryText
            self:EnhanceButtonForMobile(SecondaryButton)
        end
    else
        if SecondaryButton then
            SecondaryButton:Destroy()
        end
    end
    
    local FinalSize = self:CalculateDynamicSize(Options.Title, Options.Description)
    
    return Template, FinalSize
end

-- ============================================================================
-- PROMPT ANIMATOR CLASS
-- ============================================================================

local PromptAnimator = {}
PromptAnimator.__index = PromptAnimator

function PromptAnimator.New(PromptInstance)
    local self = setmetatable({}, PromptAnimator)
    self.Prompt = PromptInstance
    self.Policy = PromptInstance.Policy
    self.IsAnimating = false
    return self
end

function PromptAnimator:PlayOpen(FinalSize)
    if self.IsAnimating then return end
    self.IsAnimating = true
    
    local Policy = self.Policy
    local Config = PROMPT_CONFIG.Animation
    
    Policy.Size = UDim2.new(0, 450, 0, 120)
    Policy.BackgroundTransparency = 1
    Policy.Shadow.Image.ImageTransparency = 1
    Policy.Title.TextTransparency = 1
    Policy.Notice.TextTransparency = 1
    Policy.Actions.Primary.BackgroundTransparency = 1
    Policy.Actions.Primary.Shadow.ImageTransparency = 1
    Policy.Actions.Primary.Title.TextTransparency = 1
    
    local SecondaryButton = Policy.Actions:FindFirstChild("Secondary")
    if SecondaryButton then
        SecondaryButton.Title.TextTransparency = 1
    end
    
    Policy.Actions.Primary.BackgroundColor3 = PROMPT_CONFIG.Colors.PrimaryButton
    Policy.Visible = true
    self.Prompt.Enabled = true
    
    TweenService:Create(Policy, TweenInfo.new(Config.OpenDuration, Config.EasingStyle, Config.EasingDirection), {
        BackgroundTransparency = 0
    }):Play()
    
    TweenService:Create(Policy.Shadow.Image, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
        ImageTransparency = 0.6
    }):Play()
    
    TweenService:Create(Policy, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Config.EasingDirection), {
        Size = FinalSize
    }):Play()
    
    task.wait(0.15)
    
    TweenService:Create(Policy.Title, TweenInfo.new(0.35, Config.EasingStyle, Config.EasingDirection), {
        TextTransparency = 0
    }):Play()
    
    task.wait(0.03)
    
    TweenService:Create(Policy.Notice, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
        TextTransparency = 0.5
    }):Play()
    
    task.wait(0.15)
    
    TweenService:Create(Policy.Actions.Primary, TweenInfo.new(0.6, Config.EasingStyle, Config.EasingDirection), {
        BackgroundTransparency = 0.3
    }):Play()
    
    TweenService:Create(Policy.Actions.Primary.Title, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
        TextTransparency = 0.2
    }):Play()
    
    TweenService:Create(Policy.Actions.Primary.Shadow, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
        ImageTransparency = 0.7
    }):Play()
    
    if SecondaryButton then
        TweenService:Create(SecondaryButton.Title, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
            TextTransparency = 0.6
        }):Play()
    end
    
    self.IsAnimating = false
end

function PromptAnimator:PlayClose()
    if self.IsAnimating then return end
    self.IsAnimating = true
    
    local Policy = self.Policy
    local Config = PROMPT_CONFIG.Animation
    
    TweenService:Create(Policy, TweenInfo.new(Config.CloseDuration, Config.EasingStyle, Config.EasingDirection), {
        Size = UDim2.new(0, 430, 0, 110)
    }):Play()
    
    TweenService:Create(Policy.Title, TweenInfo.new(0.35, Config.EasingStyle, Config.EasingDirection), {
        TextTransparency = 1
    }):Play()
    
    TweenService:Create(Policy.Notice, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
        TextTransparency = 1
    }):Play()
    
    local SecondaryButton = Policy.Actions:FindFirstChild("Secondary")
    if SecondaryButton then
        TweenService:Create(SecondaryButton.Title, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
            TextTransparency = 1
        }):Play()
    end
    
    TweenService:Create(Policy.Actions.Primary, TweenInfo.new(0.4, Config.EasingStyle, Config.EasingDirection), {
        BackgroundTransparency = 1
    }):Play()
    
    TweenService:Create(Policy.Actions.Primary.Title, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
        TextTransparency = 1
    }):Play()
    
    TweenService:Create(Policy.Actions.Primary.Shadow, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
        ImageTransparency = 1
    }):Play()
    
    TweenService:Create(Policy, TweenInfo.new(0.2, Config.EasingStyle, Config.EasingDirection), {
        BackgroundTransparency = 1
    }):Play()
    
    TweenService:Create(Policy.Shadow.Image, TweenInfo.new(0.25, Config.EasingStyle, Config.EasingDirection), {
        ImageTransparency = 1
    }):Play()
    
    task.wait(0.5)
    self.IsAnimating = false
end

-- ============================================================================
-- PROMPT INSTANCE CLASS
-- ============================================================================

local Prompt = {}
Prompt.__index = Prompt

function Prompt.New(Options, Storage)
    local self = setmetatable({}, Prompt)
    
    self.Id = Options.Id or Options.Title
    self.Version = Options.Version or "1.0.0"
    self.Title = Options.Title
    self.Description = Options.Description
    self.PrimaryText = Options.PrimaryText or "Accept"
    self.SecondaryText = Options.SecondaryText
    self.Callback = Options.Callback
    self.ForceShow = Options.ForceShow or false
    
    self.Storage = Storage
    self.GuiInstance = nil
    self.Animator = nil
    self.Connections = {}
    self.IsDestroyed = false
    
    return self
end

function Prompt:ShouldShow()
    if self.ForceShow then
        return true
    end
    return not self.Storage:IsVersionAccepted(self.Id, self.Version)
end

function Prompt:SetupButtonConnections()
    local Policy = self.GuiInstance.Policy
    local PrimaryButton = Policy.Actions.Primary
    local SecondaryButton = Policy.Actions:FindFirstChild("Secondary")
    
    local PrimaryInteract = PrimaryButton:FindFirstChild("Interact")
    if PrimaryInteract then
        local Connection = PrimaryInteract.MouseButton1Click:Connect(function()
            if self.Animator and self.Animator.IsAnimating then return end
            self:Close(true)
        end)
        table.insert(self.Connections, Connection)
        
        if PrimaryInteract:IsA("TextButton") or PrimaryInteract:IsA("ImageButton") then
            local TouchConnection = PrimaryInteract.TouchTap:Connect(function()
                if self.Animator and self.Animator.IsAnimating then return end
                self:Close(true)
            end)
            table.insert(self.Connections, TouchConnection)
        end
    end
    
    if SecondaryButton then
        local SecondaryInteract = SecondaryButton:FindFirstChild("Interact")
        if SecondaryInteract then
            local Connection = SecondaryInteract.MouseButton1Click:Connect(function()
                if self.Animator and self.Animator.IsAnimating then return end
                self:Close(false)
            end)
            table.insert(self.Connections, Connection)
            
            if SecondaryInteract:IsA("TextButton") or SecondaryInteract:IsA("ImageButton") then
                local TouchConnection = SecondaryInteract.TouchTap:Connect(function()
                    if self.Animator and self.Animator.IsAnimating then return end
                    self:Close(false)
                end)
                table.insert(self.Connections, TouchConnection)
            end
        end
    end
end

function Prompt:Show()
    if self.IsDestroyed then return false end
    
    local Builder = PromptBuilder.New()
    local GuiInstance, FinalSize = Builder:Build({
        Title = self.Title,
        Description = self.Description,
        PrimaryText = self.PrimaryText,
        SecondaryText = self.SecondaryText,
    })
    
    if not GuiInstance then
        return false
    end
    
    self.GuiInstance = GuiInstance
    self.GuiInstance.Parent = CoreGui
    
    self.Animator = PromptAnimator.New(self.GuiInstance)
    self:SetupButtonConnections()
    
    task.spawn(function()
        self.Animator:PlayOpen(FinalSize)
    end)
    
    return true
end

function Prompt:Close(Accepted)
    if self.IsDestroyed then return end
    
    if Accepted then
        self.Storage:SetAccepted(self.Id, self.Version)
    end
    
    if self.Animator then
        self.Animator:PlayClose()
    end
    
    local Marker = CoreGui:FindFirstChild("NexusPromptMarker")
    if Marker then
        Marker:Destroy()
    end
    
    if self.Callback then
        task.spawn(self.Callback, Accepted)
    end
    
    self:Destroy()
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
    
    if self.GuiInstance and self.GuiInstance.Parent then
        self.GuiInstance:Destroy()
    end
    
    self.GuiInstance = nil
    self.Animator = nil
end

-- ============================================================================
-- PROMPT INTERFACE (MAIN API)
-- ============================================================================

local PromptInterface = {}
PromptInterface.__index = PromptInterface

local SharedStorage = nil
local ActivePrompt = nil

function PromptInterface.Initialize()
    if not SharedStorage then
        SharedStorage = StorageManager.New()
    end
end

function PromptInterface.Create(Options)
    PromptInterface.Initialize()
    
    if type(Options) ~= "table" then
        warn("[PromptInterface] Options must be a table")
        return nil
    end
    
    if not Options.Title then
        warn("[PromptInterface] Title is required")
        return nil
    end
    
    local PromptInstance = Prompt.New(Options, SharedStorage)
    
    if not PromptInstance:ShouldShow() then
        if PromptInstance.Callback then
            task.spawn(PromptInstance.Callback, true)
        end
        return nil
    end
    
    if CoreGui:FindFirstChild("NexusPromptMarker") then
        return nil
    end
    
    local Marker = Instance.new("Folder")
    Marker.Name = "NexusPromptMarker"
    Marker.Parent = CoreGui
    
    ActivePrompt = PromptInstance
    
    task.wait(0.5)
    PromptInstance:Show()
    
    return PromptInstance
end

function PromptInterface.create(Title, Description, Primary, Secondary, Callback, PromptId)
    return PromptInterface.Create({
        Id = PromptId or Title,
        Version = "1.0.0",
        Title = Title,
        Description = Description,
        PrimaryText = Primary,
        SecondaryText = Secondary,
        Callback = Callback,
    })
end

function PromptInterface.IsAccepted(PromptId, Version)
    PromptInterface.Initialize()
    Version = Version or "1.0.0"
    return SharedStorage:IsVersionAccepted(PromptId, Version)
end

function PromptInterface.GetAcceptedVersion(PromptId)
    PromptInterface.Initialize()
    return SharedStorage:GetAcceptedVersion(PromptId)
end

function PromptInterface.ClearAcceptance(PromptId)
    PromptInterface.Initialize()
    SharedStorage:ClearAcceptance(PromptId)
end

function PromptInterface.ClearAllAcceptances()
    PromptInterface.Initialize()
    SharedStorage:ClearAll()
end

function PromptInterface.CloseActive()
    if ActivePrompt and not ActivePrompt.IsDestroyed then
        ActivePrompt:Close(false)
        ActivePrompt = nil
    end
end

function PromptInterface.GetConfig()
    return PROMPT_CONFIG
end

function PromptInterface.SetConfig(NewConfig)
    for Category, Settings in pairs(NewConfig) do
        if PROMPT_CONFIG[Category] then
            for Key, Value in pairs(Settings) do
                if PROMPT_CONFIG[Category][Key] ~= nil then
                    PROMPT_CONFIG[Category][Key] = Value
                end
            end
        end
    end
end

return PromptInterface
