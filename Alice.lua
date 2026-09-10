-- AliceHUB v3.0.3 · Register-Safe TEST · jumpanimals.lua
-- Register audit: this payload is already well below the chunk-scope local-register limit; source kept unchanged.

--[[
    AliceHUB · Jump for Animals!
    UI THEME: exact AliceHUB Steal An Egg / Grow A Chicken Fighter neon-violet skin
    Background 8,6,18 · Main 18,12,36 · Accent 168,85,247 · Outline 96,55,180
]]

-- ============================================================================
-- AliceHUB · Jump for Animals — Clean Deobfuscated Reconstruction + SAE UI
-- Original protection: Luast v1.0.1
-- Constant-pool permutation, opaque predicates, VM/state dispatchers, and
-- unreachable obfuscation branches removed. Live client behavior reconstructed.
-- AliceHUB build · Jump for Animals
-- ============================================================================


local function bootstrap()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local CoreGui = game:GetService("CoreGui")
    local GuiService = game:GetService("GuiService")
    local Lighting = game:GetService("Lighting")
    local Stats = game:GetService("Stats")
    local VirtualUser = game:GetService("VirtualUser")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer
    local env = (getgenv and getgenv()) or _G
    -- Optional AliceHUB-hosted URL used only by Auto Execute.
    -- Example: getgenv().AliceHUBJumpForAnimalsSourceURL = "https://raw.githubusercontent.com/..."
    local sourceUrl = tostring(env.AliceHUBJumpForAnimalsSourceURL or "")
    local obsidianBase = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"

    -- Executor compatibility shim recovered from pooled functions #799/#773.
    local function fallbackGetHui()
        return CoreGui
    end
    if type(gethui) ~= "function" then
        gethui = fallbackGetHui
    end

    -- AliceHUB checks the previous library and its Unload member before
    -- starting the previous-instance cleanup helper.
    local previous = env.__AliceHUBJumpForAnimalsLib
    if previous and type(previous.Unload) == "function" then
        task.spawn(function()
            previous:Unload()
        end)
    end

    local SettingsFolder = ReplicatedStorage:WaitForChild("Settings")
    local AreasConfig = require(SettingsFolder:WaitForChild("Areas"))
    local JumpLevels = require(SettingsFolder:WaitForChild("JumpLevels"))
    local AnimalsConfig = require(SettingsFolder:WaitForChild("Animals"))
    local EggsConfig = require(SettingsFolder:WaitForChild("Eggs"))
    local RaritiesConfig = require(SettingsFolder:WaitForChild("Rarities"))
    local TrailsConfig = require(SettingsFolder:WaitForChild("Trails"))
    local SpeedUpgrades = require(SettingsFolder:WaitForChild("SpeedUpgrades"))

    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local PlaceEggRequest = Remotes:WaitForChild("PlaceEggRequest")
    local PetInventory = Remotes:WaitForChild("PetInventory")
    local SellRemote = Remotes:WaitForChild("Sell")
    local TrailsRemote = Remotes:WaitForChild("Trails")
    local CoilsRemote = Remotes:WaitForChild("Coils")
    local ClaimAnimalIndexReward = Remotes:WaitForChild("ClaimAnimalIndexReward")
    local SquatTrainingRequest = Remotes:WaitForChild("SquatTrainingRequest")
    local SquatBonusRequest = Remotes:WaitForChild("SquatBonusRequest")

    local Map = Workspace:WaitForChild("Map")
    local AreasFolder = Map:WaitForChild("Stages")
    local SellArea = Map:WaitForChild("Sell")

    local rarityNames = {}
    local rarityRanks = {}
    for rank, rarityName in ipairs(RaritiesConfig.List or {}) do
        table.insert(rarityNames, rarityName)
        rarityRanks[rarityName] = rank
    end

    local eggNames = {}
    for eggName in pairs(EggsConfig.List or {}) do
        table.insert(eggNames, eggName)
    end
    table.sort(eggNames)

    local animalNames = {}
    local orderedAnimals = type(AnimalsConfig.GetOrdered) == "function" and AnimalsConfig.GetOrdered() or {}
    for _, animal in ipairs(orderedAnimals or {}) do
        if animal and animal.Name then
            table.insert(animalNames, animal.Name)
        end
    end

    local areaDropdownValues = { "Best" }
    local areaByName = {}
    for index, area in pairs(AreasConfig.List or {}) do
        local name = area.Name
        if name then
            table.insert(areaDropdownValues, name)
            local requirement = JumpLevels.FirstWorldAreaRequirements
                and JumpLevels.FirstWorldAreaRequirements[index]
            areaByName[name] = {
                Index = index,
                Name = name,
                Rarity = area.Rarity,
                JumpPower = requirement and tonumber(requirement.JumpPower) or 0,
            }
        end
    end

    local TrailNames = {}
    local orderedTrails = type(TrailsConfig.GetOrdered) == "function" and TrailsConfig.GetOrdered() or {}
    for _, item in ipairs(orderedTrails or {}) do
        if item and item.Name then
            table.insert(TrailNames, item.Name)
        end
    end

    local CoilNames = {}
    local orderedCoils = type(SpeedUpgrades.GetOrdered) == "function" and SpeedUpgrades.GetOrdered() or {}
    for _, item in ipairs(orderedCoils or {}) do
        if item and item.Name then
            table.insert(CoilNames, item.Name)
        end
    end

    local rarityColors = {
        Common = 10265519,
        Uncommon = 2278750,
        Rare = 3900150,
        Epic = 11032055,
        Legendary = 16096779,
        Mythic = 15680580,
        Divine = 15485081,
        Celestial = 440020,
        Eternal = 15381256,
        Ascended = 16347926,
    }

    local discordUrl = "https://discord.gg/ehKVq7pf7v"
    local aliceHubRepoUrl = "https://github.com/ShiroKanaeru/AliceHub"
    local aliceHubCommunityUrl = discordUrl
    local GameName = "Jump for Animals!"

    -- Request resolver order:
    -- syn.request -> http.request -> http_request -> request
    local requestFn = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request

    local colors = {
        blue = "#6ec1ff",
        green = "#7fd47f",
        yellow = "#e8a34d",
        gray = "#8b93a3",
        red = "#ca374f",
        violet = "#b53053",
        violetSoft = "#d64d70",
    }

    local Library = loadstring(game:HttpGet(obsidianBase .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(obsidianBase .. "addons/ThemeManager.lua"))()
    local SaveManager = loadstring(game:HttpGet(obsidianBase .. "addons/SaveManager.lua"))()
    local Toggles = Library.Toggles
    local Options = Library.Options
    local AliceWindow
    local aliceThemeDescendantConnection

    -- AliceHUB gothic skin shared with the current Steal An Egg build.
    Library.ForceCheckbox = false
    Library.ShowToggleFrameInKeybinds = true
    Library.NotifySide = "Right"
    Library.ShowCustomCursor = false
    if type(Library.Scheme) == "table" then
        Library.Scheme.BackgroundColor = Color3.fromRGB(11, 9, 11)
        Library.Scheme.MainColor = Color3.fromRGB(24, 15, 19)
        Library.Scheme.AccentColor = Color3.fromRGB(181, 48, 83)
        Library.Scheme.OutlineColor = Color3.fromRGB(63, 34, 44)
        Library.Scheme.FontColor = Color3.fromRGB(242, 236, 239)
        Library.Scheme.Font = Font.fromEnum(Enum.Font.Code)
        Library.Scheme.RedColor = Color3.fromRGB(202, 55, 79)
        Library.Scheme.DestructiveColor = Color3.fromRGB(132, 30, 49)
        Library.Scheme.DarkColor = Color3.fromRGB(7, 6, 7)
        Library.Scheme.WhiteColor = Color3.fromRGB(242, 236, 239)
    end

    
local function applyAliceGothicTheme()
    if type(Library.Scheme) ~= "table" then
        return
    end

    -- AliceHUB gothic palette shared with the current Steal An Egg build.
    -- Re-apply after builders/autoload so saved themes cannot leave pink behind.
    Library.Scheme.BackgroundColor = Color3.fromRGB(11, 9, 11)
    Library.Scheme.MainColor = Color3.fromRGB(24, 15, 19)
    Library.Scheme.AccentColor = Color3.fromRGB(181, 48, 83)
    Library.Scheme.OutlineColor = Color3.fromRGB(63, 34, 44)
    Library.Scheme.FontColor = Color3.fromRGB(242, 236, 239)
    Library.Scheme.Font = Font.fromEnum(Enum.Font.Code)
    Library.Scheme.RedColor = Color3.fromRGB(202, 55, 79)
    Library.Scheme.DestructiveColor = Color3.fromRGB(132, 30, 49)
    Library.Scheme.DarkColor = Color3.fromRGB(7, 6, 7)
    Library.Scheme.WhiteColor = Color3.fromRGB(242, 236, 239)

    if type(Library.SetFont) == "function" then
        pcall(function()
            Library:SetFont(Enum.Font.Code)
        end)
    end

    if type(Library.UpdateColorsUsingRegistry) == "function" then
        pcall(function()
            Library:UpdateColorsUsingRegistry()
        end)
    end
end


local function aliceNormalizeColor(color)
    if typeof(color) ~= "Color3" then
        return color
    end

    -- Convert leftover legacy violet/pink brand accents into the current
    -- charcoal/burgundy/ruby AliceHUB palette without repainting normal
    -- gameplay status colors such as green, yellow, or blue.
    local h, s, v = color:ToHSV()
    local r, g, b = color.R, color.G, color.B
    local looksLegacyViolet = s >= 0.40 and b > g * 1.25 and r > g * 1.05
    local looksLegacyPink = s >= 0.48 and r > g * 1.30 and b > g * 0.90

    if not looksLegacyViolet and not looksLegacyPink then
        return color
    end

    if v < 0.20 then
        return Color3.fromRGB(11, 9, 11)
    elseif v < 0.38 then
        return Color3.fromRGB(24, 15, 19)
    elseif v < 0.58 then
        return Color3.fromRGB(63, 34, 44)
    elseif v < 0.82 then
        return Color3.fromRGB(181, 48, 83)
    else
        return Color3.fromRGB(214, 77, 112)
    end
end

local function repaintAliceObject(object)
    pcall(function()
        if object:IsA("GuiObject") then
            object.BackgroundColor3 = aliceNormalizeColor(object.BackgroundColor3)
        end

        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            object.TextColor3 = aliceNormalizeColor(object.TextColor3)
        end

        if object:IsA("ImageLabel") or object:IsA("ImageButton") then
            object.ImageColor3 = aliceNormalizeColor(object.ImageColor3)
        end

        if object:IsA("UIStroke") then
            object.Color = aliceNormalizeColor(object.Color)
        end

        if object:IsA("UIGradient") then
            local keypoints = {}
            for _, keypoint in ipairs(object.Color.Keypoints) do
                keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(
                    keypoint.Time,
                    aliceNormalizeColor(keypoint.Value)
                )
            end
            object.Color = ColorSequence.new(keypoints)
        end
    end)
end

local function hardRepaintAliceUI()
    applyAliceGothicTheme()

    local root = AliceWindow and AliceWindow.MainFrame
    if not root then
        root = Library.MainFrame or (Library.Window and Library.Window.MainFrame)
    end
    if not root or type(root.GetDescendants) ~= "function" then
        return
    end

    repaintAliceObject(root)
    for _, object in ipairs(root:GetDescendants()) do
        repaintAliceObject(object)
    end
end

applyAliceGothicTheme()


local function applyAliceHubHeader(window, gameSubtitle)
    task.defer(function()
        pcall(function()
            if not window or not window.MainFrame then
                return
            end

            if type(window.ChangeTitle) == "function" then
                window:ChangeTitle("AliceHUB")
            end
            if type(window.SetFooter) == "function" then
                window:SetFooter({ "AliceHUB", "|", tostring(gameSubtitle or "") })
            end

            local root = window.MainFrame
            local titleLabel
            for _, object in ipairs(root:GetDescendants()) do
                if object:IsA("TextLabel")
                    and object.Text == "AliceHUB"
                    and tonumber(object.TextSize)
                    and object.TextSize >= 18
                then
                    titleLabel = object
                    break
                end
            end
            if not titleLabel or not titleLabel.Parent then
                return
            end

            local holder = titleLabel.Parent
            local oldStack = holder:FindFirstChild("AliceHUBTitleStack")
            if oldStack then oldStack:Destroy() end

            titleLabel.Visible = false

            local stack = Instance.new("Frame")
            stack.Name = "AliceHUBTitleStack"
            stack.BackgroundTransparency = 1
            stack.Size = UDim2.fromOffset(190, 40)
            stack.LayoutOrder = titleLabel.LayoutOrder
            stack.Parent = holder

            local mainTitle = Instance.new("TextLabel")
            mainTitle.Name = "MainTitle"
            mainTitle.BackgroundTransparency = 1
            mainTitle.Position = UDim2.fromOffset(0, 1)
            mainTitle.Size = UDim2.new(1, 0, 0, 22)
            mainTitle.Font = Enum.Font.Code
            mainTitle.Text = "AliceHUB"
            mainTitle.TextColor3 = (Library.Scheme and Library.Scheme.FontColor) or Color3.fromRGB(242, 236, 239)
            mainTitle.TextSize = 18
            mainTitle.TextXAlignment = Enum.TextXAlignment.Left
            mainTitle.TextYAlignment = Enum.TextYAlignment.Center
            mainTitle.Parent = stack

            local subtitle = Instance.new("TextLabel")
            subtitle.Name = "Subtitle"
            subtitle.BackgroundTransparency = 1
            subtitle.Position = UDim2.fromOffset(0, 21)
            subtitle.Size = UDim2.new(1, 0, 0, 16)
            subtitle.Font = Enum.Font.Code
            subtitle.Text = tostring(gameSubtitle or "")
            subtitle.TextColor3 = Color3.fromRGB(180, 126, 143)
            subtitle.TextTransparency = 0.12
            subtitle.TextSize = 11
            subtitle.TextXAlignment = Enum.TextXAlignment.Left
            subtitle.TextYAlignment = Enum.TextYAlignment.Center
            subtitle.Parent = stack
        end)
    end)
end

-- ============================================================
-- AliceHUB versioned logo cache
-- Pattern: version endpoint -> versioned local PNG -> getcustomasset.
-- Refresh is background-only so the main UI/game payload never waits for the logo.
local ALICE_LOGO_API = "https://alicehub-api.shirokanaerus.workers.dev"
local ALICE_LOGO_ROOT = "AliceHUB/assets"
local ALICE_LOGO_VERSION_FILE = ALICE_LOGO_ROOT .. "/logo.ver"
local ALICE_LOGO_ASSET = nil
local ALICE_LOGO_FILE = nil
local __aliceLogoTargets = {}

local function __aliceGetCustomAsset()
    return getcustomasset
        or getsynasset
        or (syn and syn.getcustomasset)
        or getcustomassetfunc
end

local function __aliceCleanLogoVersion(value)
    local version = tostring(value or ""):gsub("%s+", "")
    if version == "" or #version > 64 then return nil end
    if not version:match("^[%w%._%-]+$") then return nil end
    return version
end

local function __aliceEnsureFolder(path)
    if type(makefolder) ~= "function" then return end
    local exists = false
    if type(isfolder) == "function" then
        pcall(function() exists = isfolder(path) end)
    end
    if not exists then pcall(makefolder, path) end
end

local function __aliceFileExists(path)
    if type(isfile) ~= "function" then return false end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

local function __aliceReadFile(path)
    if type(readfile) ~= "function" or not __aliceFileExists(path) then return nil end
    local ok, value = pcall(readfile, path)
    return ok and value or nil
end

local function __aliceLogoPath(version)
    return ALICE_LOGO_ROOT .. "/" .. tostring(version) .. "/logo.png"
end

local function __aliceResolveLocalAsset(path)
    local getAsset = __aliceGetCustomAsset()
    if type(getAsset) ~= "function" or not __aliceFileExists(path) then return nil end
    local ok, asset = pcall(getAsset, path)
    if ok and type(asset) == "string" and asset ~= "" then return asset end
    return nil
end

local function __aliceApplyLogoTarget(imageObject, fallbackObject)
    local asset = ALICE_LOGO_ASSET
    if imageObject and imageObject.Parent then
        pcall(function()
            imageObject.Image = asset or ""
            imageObject.ImageTransparency = asset and 0 or 1
        end)
    end
    if fallbackObject and fallbackObject.Parent then
        pcall(function()
            fallbackObject.Visible = not (asset ~= nil)
        end)
    end
end

local function __aliceRegisterLogoTarget(imageObject, fallbackObject)
    __aliceLogoTargets[#__aliceLogoTargets + 1] = {
        image = imageObject,
        fallback = fallbackObject,
    }
    __aliceApplyLogoTarget(imageObject, fallbackObject)
end

local function __alicePublishLogo(asset, path, version)
    if type(asset) ~= "string" or asset == "" then return end
    ALICE_LOGO_ASSET = asset
    ALICE_LOGO_FILE = path

    local env = (getgenv and getgenv()) or _G
    env.AliceHUBLogoAsset = asset
    env.AliceHUBBrandLogoAsset = asset
    env.AliceHUBLogoPath = path
    env.AliceHUBLogoVersion = version

    for index = #__aliceLogoTargets, 1, -1 do
        local target = __aliceLogoTargets[index]
        if not target.image or not target.image.Parent then
            table.remove(__aliceLogoTargets, index)
        else
            __aliceApplyLogoTarget(target.image, target.fallback)
        end
    end
end

-- Last cached version loads instantly; no HTTP is performed on the startup path.
do
    local localVersion = __aliceCleanLogoVersion(__aliceReadFile(ALICE_LOGO_VERSION_FILE))
    if localVersion then
        local path = __aliceLogoPath(localVersion)
        local asset = __aliceResolveLocalAsset(path)
        if asset then __alicePublishLogo(asset, path, localVersion) end
    end
end

-- Server refresh runs independently. First run uses "A" until the PNG is ready.
task.spawn(function()
    local getAsset = __aliceGetCustomAsset()
    if type(getAsset) ~= "function" or type(writefile) ~= "function" then return end

    __aliceEnsureFolder("AliceHUB")
    __aliceEnsureFolder(ALICE_LOGO_ROOT)

    local okVersion, versionBody = pcall(function()
        return game:HttpGet(ALICE_LOGO_API .. "/alicehub-logo.version?t=" .. tostring(os.time()))
    end)
    if not okVersion then return end

    local version = __aliceCleanLogoVersion(versionBody)
    if not version then return end

    local versionFolder = ALICE_LOGO_ROOT .. "/" .. version
    local logoPath = __aliceLogoPath(version)
    __aliceEnsureFolder(versionFolder)

    if not __aliceFileExists(logoPath) then
        local okLogo, png = pcall(function()
            return game:HttpGet(ALICE_LOGO_API .. "/alicehub-logo.png?v=" .. version)
        end)
        if not okLogo or type(png) ~= "string" or #png < 512 then return end
        if png:sub(1, 4) ~= "\137PNG" then return end
        if not pcall(writefile, logoPath, png) then return end
    end

    local asset = __aliceResolveLocalAsset(logoPath)
    if not asset then return end

    pcall(writefile, ALICE_LOGO_VERSION_FILE, version)
    __alicePublishLogo(asset, logoPath, version)
end)

local ALICEHUB_LOGO_ASSET = ALICE_LOGO_ASSET

local function installAliceFloatingLogo(window)
    local PlayersService = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local player = PlayersService.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")

    for _, root in ipairs({CoreGui, playerGui}) do
        if root then
            for _, guiName in ipairs({"AliceHUBLogoButton", "AliceHUBToggleButton"}) do
                local stale = root:FindFirstChild(guiName)
                if stale then pcall(function() stale:Destroy() end) end
            end
        end
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "AliceHUBLogoButton"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 2147483646
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() screen.Parent = CoreGui end)
    if not screen.Parent and playerGui then
        screen.Parent = playerGui
    end

    local button = Instance.new("ImageButton")
    button.Name = "AliceHUBLogo"
    button.Size = UDim2.fromOffset(72, 72)
    button.Position = UDim2.new(0, 10, 0.5, -36)
    button.BackgroundColor3 = Color3.fromRGB(20, 12, 16)
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Image = ALICEHUB_LOGO_ASSET
    button.ImageColor3 = Color3.fromRGB(255, 255, 255)
    button.ScaleType = Enum.ScaleType.Crop
    button.Parent = screen
    local logoFallback = Instance.new("TextLabel")
    logoFallback.Name = "Fallback"
    logoFallback.BackgroundTransparency = 1
    logoFallback.Size = UDim2.fromScale(1, 1)
    logoFallback.Font = Enum.Font.Code
    logoFallback.Text = "A"
    logoFallback.TextColor3 = Color3.fromRGB(214, 77, 112)
    logoFallback.TextSize = 30
    logoFallback.TextXAlignment = Enum.TextXAlignment.Center
    logoFallback.TextYAlignment = Enum.TextYAlignment.Center
    logoFallback.ZIndex = button.ZIndex + 1
    logoFallback.Parent = button
    __aliceRegisterLogoTarget(button, logoFallback)


    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Name = "RubyOutline"
    stroke.Color = Color3.fromRGB(181, 48, 83)
    stroke.Thickness = 2
    stroke.Transparency = 0.12
    stroke.Parent = button

    task.delay(3, function()
        if button and button.Parent then
            local loaded = false
            pcall(function() loaded = button.IsLoaded end)
            if not loaded then
                button.Image = ""
            end
        end
    end)

    local uiVisible = true
    local function setVisible(value)
        uiVisible = value and true or false
        local changed = false
        if type(Library.Toggle) == "function" then
            changed = pcall(function() Library:Toggle(uiVisible) end)
        end
        if not changed and window and window.MainFrame then
            pcall(function() window.MainFrame.Visible = uiVisible end)
        end
    end

    local dragging = false
    local dragInput
    local dragStart
    local startPosition
    local dragged = false

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            dragged = false
            dragStart = input.Position
            startPosition = button.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and dragStart and startPosition then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                dragged = true
            end
            button.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    button.MouseButton1Click:Connect(function()
        if dragged then
            dragged = false
            return
        end
        TweenService:Create(button, TweenInfo.new(0.08), {Size = UDim2.fromOffset(66, 66)}):Play()
        task.wait(0.08)
        TweenService:Create(button, TweenInfo.new(0.08), {Size = UDim2.fromOffset(72, 72)}):Play()
        setVisible(not uiVisible)
    end)

    return screen
end


    env.__AliceHUBJumpForAnimalsLib = Library

    local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
    local compact = viewport.X <= 1700 and viewport.Y <= 900
    local targetWidth = compact and 760 or 900
    local targetHeight = compact and 540 or 620
    targetWidth = math.min(targetWidth, math.max(620, viewport.X - 120))
    targetHeight = math.min(targetHeight, math.max(460, viewport.Y - 100))

    local Window = Library:CreateWindow({
        Title = "AliceHUB",
        Icon = ALICEHUB_LOGO_ASSET or "",
        IconSize = UDim2.fromOffset(28, 28),
        Font = Enum.Font.Code,
        Footer = { "AliceHUB", "|", GameName },
        NotifySide = "Right",
        ShowMobileButtons = false,
        ShowCustomCursor = false,
        CornerRadius = 4,
        Size = UDim2.fromOffset(targetWidth, targetHeight),
    })
    AliceWindow = Window
    applyAliceHubHeader(Window, GameName)
    hardRepaintAliceUI()
    local aliceLogoGui = installAliceFloatingLogo(Window)


    if Window.MainFrame and Window.MainFrame.DescendantAdded then
        aliceThemeDescendantConnection = Window.MainFrame.DescendantAdded:Connect(function(object)
            task.defer(function()
                if Library.Unloaded then return end
                repaintAliceObject(object)
            end)
        end)
    end

    -- AliceHUB SAE-style navigation: one clean flat sidebar, no nested arrows/icons.
    -- Keep the old table keys as compatibility aliases so the feature installers do not change.
    local Tabs = {
        Steal = Window:AddTab("Farm"),
        Pets = Window:AddTab("Pets"),
        Shop = Window:AddTab("Shop"),
        Esp = Window:AddTab("Visuals"),
        Movement = Window:AddTab("Movement"),
        Priority = Window:AddTab("Priority"),
        Webhook = Window:AddTab("Webhook"),
        Settings = Window:AddTab("Settings"),
        Info = Window:AddTab("Info"),
    }

    -- Compatibility aliases for the decoded feature installers.
    Tabs.Webhooks = Tabs.Webhook
    Tabs.Player = Tabs.Movement

    local collectBusy = false
    local placingBusy = false
    local hatchingBusy = false
    local sellingBusy = false
    local actionStatus = "Idle"

    local function isOn(name)
        if Library.Unloaded then
            return false
        end
        local toggle = Toggles[name]
        return toggle ~= nil and toggle.Value == true
    end

    local function optionValue(name, fallback)
        local option = Options[name]
        if option == nil then
            return fallback
        end
        return option.Value
    end

    local function normalizeMultiSelection(name)
        local value = optionValue(name, {})
        if typeof(value) ~= "table" then
            return {}
        end
        local selected = {}
        for key, item in pairs(value) do
            if typeof(key) == "number" and typeof(item) == "string" then
                selected[item] = true
            elseif item == true then
                selected[key] = true
            end
        end
        return selected
    end

    local function optionHasAnySelection(name)
        return next(normalizeMultiSelection(name)) ~= nil
    end

    local function getHumanoid()
        local character = LocalPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid") or nil
    end

    local function getHumanoidRootPart()
        local character = LocalPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart") or nil
    end

    local function getJumpPower()
        local object = LocalPlayer:FindFirstChild("JumpPower")
        if not object then
            return 0
        end
        return tonumber(object.Value) or 0
    end


    local AliceWhiteScreen = {
        enabled = false,
        generation = 0,
        gui = nil,
        startAt = os.clock(),
        savedQuality = nil,
        savedUserQuality = nil,
    }

    local function cleanupAliceWhiteScreenGui()
        for _, root in ipairs({
            CoreGui,
            LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"),
        }) do
            if root then
                local old = root:FindFirstChild("AliceHUB_JFA_WhiteScreen")
                if old then pcall(function() old:Destroy() end) end
            end
        end
        pcall(function()
            if typeof(gethui) == "function" then
                local hui = gethui()
                local old = hui and hui:FindFirstChild("AliceHUB_JFA_WhiteScreen")
                if old then old:Destroy() end
            end
        end)
    end

    local function stopAliceWhiteScreen()
        AliceWhiteScreen.enabled = false
        AliceWhiteScreen.generation += 1
        cleanupAliceWhiteScreenGui()
        AliceWhiteScreen.gui = nil
        pcall(function()
            if AliceWhiteScreen.savedQuality ~= nil then
                settings().Rendering.QualityLevel = AliceWhiteScreen.savedQuality
            end
        end)
        pcall(function()
            if AliceWhiteScreen.savedUserQuality ~= nil then
                UserSettings():GetService("UserGameSettings").SavedQualityLevel = AliceWhiteScreen.savedUserQuality
            end
        end)
        AliceWhiteScreen.savedQuality = nil
        AliceWhiteScreen.savedUserQuality = nil
    end

    local function getAlicePing()
        local value = 0
        pcall(function()
            value = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        return value
    end

    local function getAliceCash()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local cash = leaderstats and leaderstats:FindFirstChild("Cash")
        return cash and cash.Value or 0
    end

    local function startAliceWhiteScreen()
        if AliceWhiteScreen.enabled then return end
        stopAliceWhiteScreen()
        AliceWhiteScreen.enabled = true
        AliceWhiteScreen.startAt = os.clock()
        AliceWhiteScreen.generation += 1
        local generation = AliceWhiteScreen.generation

        pcall(function()
            AliceWhiteScreen.savedQuality = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function()
            local userSettings = UserSettings():GetService("UserGameSettings")
            AliceWhiteScreen.savedUserQuality = userSettings.SavedQualityLevel
            userSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end)

        cleanupAliceWhiteScreenGui()

        local screen = Instance.new("ScreenGui")
        screen.Name = "AliceHUB_JFA_WhiteScreen"
        screen.ResetOnSpawn = false
        screen.IgnoreGuiInset = true
        screen.DisplayOrder = 2147483647
        screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        pcall(function() screen.Parent = CoreGui end)
        if not screen.Parent then
            pcall(function()
                if typeof(gethui) == "function" then screen.Parent = gethui() end
            end)
        end
        if not screen.Parent then
            screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
        AliceWhiteScreen.gui = screen

        local background = Instance.new("Frame")
        background.Size = UDim2.fromScale(1, 1)
        background.BackgroundColor3 = Color3.new(0, 0, 0)
        background.BorderSizePixel = 0
        background.Parent = screen

        local viewport = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 600)
        local closeSize = math.clamp(math.floor(math.min(viewport.X, viewport.Y) * 0.075), 26, 54)
        local margin = math.floor(closeSize * 0.3 + 0.5)

        local close = Instance.new("TextButton")
        close.Name = "WSCloseButton"
        close.AnchorPoint = Vector2.new(1, 0)
        close.Position = UDim2.new(1, -margin, 0, margin)
        close.Size = UDim2.fromOffset(closeSize, closeSize)
        close.BackgroundColor3 = Color3.fromRGB(132, 30, 49)
        close.BorderSizePixel = 0
        close.Text = "X"
        close.Font = Enum.Font.GothamBold
        close.TextColor3 = Color3.fromRGB(255, 255, 255)
        close.TextSize = math.floor(closeSize * 0.54 + 0.5)
        close.ZIndex = 10
        close.Parent = screen
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 10)
        closeCorner.Parent = close

        close.Activated:Connect(function()
            local toggle = Toggles.AliceWhiteScreen
            if toggle and type(toggle.SetValue) == "function" then
                toggle:SetValue(false)
            else
                stopAliceWhiteScreen()
            end
        end)

        local holder = Instance.new("Frame")
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.Position = UDim2.fromScale(0.5, 0.5)
        holder.Size = UDim2.new(0.92, 0, 0.86, 0)
        holder.BackgroundTransparency = 1
        holder.Parent = background

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.Parent = holder

        local baseSize = math.clamp(math.floor(math.min(viewport.X, viewport.Y) * 0.045), 14, 34)
        local labels = {}
        for index = 1, 8 do
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 0, math.floor(baseSize * 1.5))
            label.Font = Enum.Font.GothamBold
            label.TextSize = index == 1 and math.floor(baseSize * 1.35) or baseSize
            label.TextColor3 = index == 1 and Color3.fromRGB(214, 77, 112) or Color3.fromRGB(240, 240, 240)
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.LayoutOrder = index
            label.Parent = holder
            labels[index] = label
        end

        task.spawn(function()
            while AliceWhiteScreen.enabled
                and AliceWhiteScreen.generation == generation
                and screen.Parent
            do
                local fps = 0
                pcall(function() fps = math.floor(1 / RunService.RenderStepped:Wait()) end)
                local uptime = math.max(0, math.floor(os.clock() - AliceWhiteScreen.startAt))
                local hours = math.floor(uptime / 3600)
                local minutes = math.floor((uptime % 3600) / 60)
                local seconds = uptime % 60
                local rows = {
                    "ALICEHUB",
                    GameName,
                    "Username : " .. tostring(LocalPlayer.Name),
                    "Status : Active",
                    string.format("Uptime : %02d:%02d:%02d", hours, minutes, seconds),
                    string.format("FPS: %d   Ping: %dms   Players: %d", fps, getAlicePing(), #Players:GetPlayers()),
                    "Cash: $" .. tostring(getAliceCash()),
                    "Jump Power: " .. tostring(getJumpPower()),
                }
                for index, value in ipairs(rows) do
                    if labels[index] then labels[index].Text = value end
                end
                task.wait(0.45)
            end
        end)
    end

    local function installAliceWhiteScreen(group)
        if not group or Toggles.AliceWhiteScreen then return end
        group:AddToggle("AliceWhiteScreen", {
            Text = "White Screen",
            Default = false,
        })
        Toggles.AliceWhiteScreen:OnChanged(function()
            if Toggles.AliceWhiteScreen.Value == true then
                startAliceWhiteScreen()
            else
                stopAliceWhiteScreen()
            end
        end)
    end

    local function getLocalPlot()
        local plot = LocalPlayer:FindFirstChild("Plot")
        if not plot then
            return nil
        end
        if plot:IsA("Model") then
            return plot
        end
        return plot.Value
    end

    local function moveCharacterTo(target)
        local root = getHumanoidRootPart()
        if not root then
            return false
        end
        if typeof(target) == "CFrame" then
            root.CFrame = target
        else
            root.CFrame = CFrame.new(target + Vector3.new(0, 3, 0))
        end
        return true
    end

    local function moveToPlotDetector()
        local plot = getLocalPlot()
        local detector = plot and plot:FindFirstChild("Detector")
        if detector then
            moveCharacterTo(detector.Position)
        end
    end

    local function getAreaModelByName(name)
        return AreasFolder:FindFirstChild(name)
    end

    local function getEggTools()
        local result = {}
        local function scan(container)
            if not container then
                return
            end
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("IsEggTool") == true then
                    table.insert(result, item)
                end
            end
        end
        scan(LocalPlayer:FindFirstChild("Backpack"))
        scan(LocalPlayer.Character)
        return result
    end

    local function isCarryingEgg()
        local count = tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0
        if count > 0 then
            return true
        end
        return LocalPlayer:GetAttribute("EggCarryRestricted") == true
    end

    local function firePromptSafe(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then
            return false
        end
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration)
            prompt:InputHoldEnd()
        end
        return true
    end

    local function colored(text, color)
        return string.format('<font color="%s">%s</font>', color, text)
    end

    local function field(label, value, labelColor, valueColor)
        labelColor = labelColor or colors.violet
        valueColor = valueColor or colors.violetSoft
        return string.format(
            "<b>%s</b> %s %s",
            colored(label, labelColor),
            colored("-", colors.violetSoft),
            colored(tostring(value), valueColor)
        )
    end

    -- Main status uses the same At(...) formatter for single fields.
    local function formatSingleStatus(label, value, labelColor, valueColor)
        return field(label, value, labelColor, valueColor)
    end

    -- Runtime pool #417: At(a,b) .. "  " .. At(c,d,Ce,Ci).
    local function formatDualStatus(labelA, valueA, labelB, valueB)
        return field(labelA, valueA) .. "  " .. field(labelB, valueB, colors.violetSoft, colors.violet)
    end

    local function copy(text, message)
        local clipboard = setclipboard or toclipboard
        if clipboard then
            pcall(clipboard, tostring(text))
        end
        if message then
            Library:Notify(message)
        end
    end

    local function discordAction()
        if setclipboard or toclipboard then
            copy(discordUrl, "Copied Discord invite")
        else
            Library:Notify(discordUrl)
        end
    end

    -- AliceHUB / SAE-aligned feature layout -------------------------------
    local farmGroup = Tabs.Steal:AddLeftGroupbox("Farm Eggs")
    farmGroup:AddDropdown("FarmZone", {
        AllowEmpty = true,
        Text = "Zone",
        Values = areaDropdownValues,
        Multi = true,
        Default = { Best = true },
        Searchable = true,
    })
    farmGroup:AddDropdown("FarmEggRarity", {
        AllowEmpty = true,
        Multi = true,
        Text = "Egg Rarity",
        Default = {},
        Values = rarityNames,
        Searchable = true,
    })
    farmGroup:AddDropdown("FarmEggNames", {
        Values = eggNames,
        Default = {},
        Multi = true,
        AllowEmpty = true,
        Text = "Egg Names",
        Searchable = true,
    })
    farmGroup:AddToggle("AutoCollectSelected", { Text = "Auto Collect Selected", Default = false })
    farmGroup:AddToggle("AutoCollectAll", { Text = "Auto Collect All", Default = false })

    local priorityGroup = Tabs.Priority:AddLeftGroupbox("Task Order")
    priorityGroup:AddDropdown("CollectLogic", {
        Text = "Target Priority",
        Values = { "Nearest", "Furthest", "Random", "Highest Rarity" },
        Default = 1,
    })

    local lifecycleGroup = Tabs.Steal:AddRightGroupbox("Egg Handling")
    lifecycleGroup:AddToggle("AutoPlaceEggs", { Text = "Auto Place Eggs", Default = false })
    lifecycleGroup:AddToggle("AutoHatchEggs", { Text = "Auto Hatch Eggs", Default = false })

    local serverHopGroup = Tabs.Steal:AddRightGroupbox("Server Hop")
    serverHopGroup:AddToggle("ServerhopIfNoRarity", { Text = "Serverhop if No Rarity", Default = false })
    serverHopGroup:AddDropdown("ServerhopRarities", {
        Text = "Rarity",
        Values = rarityNames,
        Default = {},
        Multi = true,
        AllowEmpty = true,
        Searchable = true,
    })
    serverHopGroup:AddSlider("ServerhopWait", {
        Text = "Wait Before Hop",
        Default = 15,
        Min = 1,
        Max = 180,
        Rounding = 0,
    })
    serverHopGroup:AddDropdown("ServerhopScope", {
        Text = "Check Zone",
        Values = { "Farm Zone", "All Zones" },
        Default = 1,
    })
    serverHopGroup:AddSlider("ServerhopMinPlayers", {
        Text = "Min Players",
        Default = 1,
        Min = 0,
        Max = 30,
        Rounding = 0,
    })
    serverHopGroup:AddDropdown("ServerhopMode", {
        Text = "Target Server",
        Values = { "Random", "Least Populated", "Most Populated" },
        Default = 1,
    })

    local statusGroup = Tabs.Steal:AddLeftGroupbox("Status")
    local ActionLabel = statusGroup:AddLabel(formatSingleStatus("Action", "Idle"), true)
    local ZoneLabel = statusGroup:AddLabel(formatDualStatus("Zone", "-", "Jump", "0"), true)
    local CashLabel = statusGroup:AddLabel(formatDualStatus("Cash", "$0", "Carry", "No"), true)
    local EggsLabel = statusGroup:AddLabel(formatSingleStatus("Eggs", "bag 0 | placed 0 | ready 0 | world 0", colors.violetSoft, colors.violet), true)
    local PetsLabel = statusGroup:AddLabel(formatSingleStatus("Pets", "0"), true)

    local petsGroup = Tabs.Pets:AddLeftGroupbox("Pets")
    petsGroup:AddToggle("AutoEquipBest", { Text = "Auto Equip Best Pets", Default = false })

    local sellGroup = Tabs.Pets:AddRightGroupbox("Auto Sell Pets")
    sellGroup:AddToggle("AutoSell", { Text = "Auto Sell Pets", Default = false })
    sellGroup:AddDropdown("SellRarity", {
        Text = "Sell Rarity",
        Values = rarityNames,
        Default = { Common = true, Uncommon = true },
        Multi = true,
        AllowEmpty = true,
        Searchable = true,
    })
    sellGroup:AddDropdown("SellAnimals", {
        Text = "Sell Animals",
        Values = animalNames,
        Default = {},
        Multi = true,
        AllowEmpty = true,
        Searchable = true,
    })

    local upgradeGroup = Tabs.Shop:AddLeftGroupbox("Upgrades")
    upgradeGroup:AddToggle("AutoUpgradePlot", { Text = "Auto Upgrade Plot", Default = false })

    local indexGroup = Tabs.Shop:AddLeftGroupbox("Index")
    indexGroup:AddToggle("AutoClaimIndex", { Text = "Auto Claim Index", Default = false })

    local trailGroup = Tabs.Shop:AddRightGroupbox("Trails")
    trailGroup:AddToggle("AutoBuyTrails", { Text = "Auto Buy Trails", Default = false })

    local gearGroup = Tabs.Shop:AddRightGroupbox("Gear")
    gearGroup:AddToggle("AutoBuyCoil", { Text = "Auto Buy Coil", Default = false })

    local trainingGroup = Tabs.Shop:AddLeftGroupbox("Training")
    trainingGroup:AddToggle("AutoGoTrain", { Text = "Auto Go Train", Default = false })
    trainingGroup:AddToggle("Auto2x", { Text = "Auto 2x", Default = false })

    local visualGroup = Tabs.Esp:AddLeftGroupbox("ESP")
    visualGroup:AddToggle("HideAvatar", { Text = "Hide Avatar", Default = false })
    visualGroup:AddToggle("DeleteOtherPets", { Text = "Delete Other Pets", Default = false })
    visualGroup:AddToggle("DeleteOwnPets", { Text = "Delete Own Pets", Default = false })

    local movementGroup = Tabs.Movement:AddLeftGroupbox("Movement")
    movementGroup:AddToggle("WalkSpeedEnabled", { Text = "Walk Speed Override", Default = false })
    movementGroup:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 32,
        Min = 16,
        Max = 250,
        Rounding = 0,
    })
    movementGroup:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
    movementGroup:AddToggle("NoClip", { Text = "NoClip", Default = false })

    local flyGroup = Tabs.Movement:AddRightGroupbox("Fly")
    flyGroup:AddToggle("Fly", { Text = "Fly", Default = false })
    flyGroup:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 60,
        Min = 10,
        Max = 400,
        Rounding = 0,
    })

    -- Settings controls needed by movement/performance installers are created
    -- up front, matching SAE's Menu + Performance split.
    local settingsMenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
    settingsMenuGroup:AddToggle("AntiGameplayPause", { Text = "No Gameplay Paused", Default = true })
    local performanceGroup = Tabs.Settings:AddRightGroupbox("Performance")
    performanceGroup:AddToggle("BoostFPS", { Text = "FPS Boost", Default = false })
    performanceGroup:AddToggle("InstantProximityPrompt", { Text = "Instant ProximityPrompt", Default = false })

    local function addDiscordButton(tab)
        local groupBox = tab:AddLeftGroupbox("Discord", nil, nil, nil, true)
        groupBox:AddButton({ Text = "Join AliceHUB Discord", Func = discordAction })
    end
    for _, tab in ipairs({ Tabs.Info, Tabs.Priority, Tabs.Webhooks, Tabs.Settings, Tabs.Steal, Tabs.Pets, Tabs.Shop, Tabs.Esp, Tabs.Movement }) do
        addDiscordButton(tab)
    end

    local ctx = {
        Players = Players,
        ReplicatedStorage = ReplicatedStorage,
        RunService = RunService,
        UserInputService = UserInputService,
        HttpService = HttpService,
        TeleportService = TeleportService,
        CoreGui = CoreGui,
        GuiService = GuiService,
        Lighting = Lighting,
        Stats = Stats,
        VirtualUser = VirtualUser,
        Workspace = Workspace,
        DateTime = DateTime,
        LocalPlayer = LocalPlayer,

        AreasConfig = AreasConfig,
        JumpLevels = JumpLevels,
        AnimalsConfig = AnimalsConfig,
        EggsConfig = EggsConfig,
        RaritiesConfig = RaritiesConfig,
        TrailsConfig = TrailsConfig,
        SpeedUpgrades = SpeedUpgrades,
        AreasFolder = AreasFolder,
        SellArea = SellArea,

        PlaceEggRequest = PlaceEggRequest,
        PetInventory = PetInventory,
        SellRemote = SellRemote,
        TrailsRemote = TrailsRemote,
        CoilsRemote = CoilsRemote,
        ClaimAnimalIndexReward = ClaimAnimalIndexReward,
        SquatTrainingRequest = SquatTrainingRequest,
        SquatBonusRequest = SquatBonusRequest,

        Library = Library,
        ThemeManager = ThemeManager,
        SaveManager = SaveManager,
        Window = Window,
        Tabs = Tabs,
        SettingsMenuGroup = settingsMenuGroup,
        PerformanceGroup = performanceGroup,
        Toggles = Toggles,
        Options = Options,

        GameName = GameName,
        sourceUrl = sourceUrl,
        requestFn = requestFn,
        discordUrl = discordUrl,
        aliceHubRepoUrl = aliceHubRepoUrl,
        aliceHubCommunityUrl = aliceHubCommunityUrl,
        applyAliceGothicTheme = applyAliceGothicTheme,
        hardRepaintAliceUI = hardRepaintAliceUI,
        colors = colors,
        rarityNames = rarityNames,
        rarityRanks = rarityRanks,
        rarityColors = rarityColors,
        eggNames = eggNames,
        animalNames = animalNames,
        areaDropdownValues = areaDropdownValues,
        areaByName = areaByName,
        TrailNames = TrailNames,
        CoilNames = CoilNames,

        isOn = isOn,
        optionValue = optionValue,
        normalizeMultiSelection = normalizeMultiSelection,
        optionHasAnySelection = optionHasAnySelection,
        multiSelected = normalizeMultiSelection,
        multiHasAny = optionHasAnySelection,
        getHumanoid = getHumanoid,
        getHumanoidRootPart = getHumanoidRootPart,
        getJumpPower = getJumpPower,
        installAliceWhiteScreen = installAliceWhiteScreen,
        stopAliceWhiteScreen = stopAliceWhiteScreen,
        aliceLogoGui = aliceLogoGui,
        getLocalPlot = getLocalPlot,
        moveCharacterTo = moveCharacterTo,
        moveToPlotDetector = moveToPlotDetector,
        getAreaModelByName = getAreaModelByName,
        getEggTools = getEggTools,
        isCarryingEgg = isCarryingEgg,
        firePromptSafe = firePromptSafe,
        colored = colored,
        field = field,
        formatSingleStatus = formatSingleStatus,
        formatDualStatus = formatDualStatus,
        copy = copy,
        discordAction = discordAction,

        ActionLabel = ActionLabel,
        ZoneLabel = ZoneLabel,
        CashLabel = CashLabel,
        EggsLabel = EggsLabel,
        PetsLabel = PetsLabel,
        ServerHopGroup = serverHopGroup,
        eggAccentA = colors.violetSoft,
        eggAccentB = colors.violet,

        isCollectBusy = function() return collectBusy end,
        setCollectBusy = function(value) collectBusy = value == true end,
        isPlacingBusy = function() return placingBusy end,
        setPlacingBusy = function(value) placingBusy = value == true end,
        isHatchingBusy = function() return hatchingBusy end,
        setHatchingBusy = function(value) hatchingBusy = value == true end,
        isSellingBusy = function() return sellingBusy end,
        setSellingBusy = function(value) sellingBusy = value == true end,
        getActionStatus = function() return actionStatus end,
        setActionStatus = function(value) actionStatus = value or "Idle" end,
        setStatus = function(value) actionStatus = value or "Idle" end,
    }

    Library:OnUnload(function()
        if aliceThemeDescendantConnection then
            aliceThemeDescendantConnection:Disconnect()
            aliceThemeDescendantConnection = nil
        end
        if env.__AliceHUBJumpForAnimalsLib == Library then
            env.__AliceHUBJumpForAnimalsLib = nil
        end
    end)

    return ctx, serverHopGroup
end


local function installFarm(ctx)
    local Library = ctx.Library
    local LocalPlayer = ctx.LocalPlayer

    local function normalizeMultiSelection(name)
        local value = ctx.optionValue(name, {})
        if typeof(value) ~= "table" then
            return {}
        end

        local selected = {}
        for key, item in pairs(value) do
            if typeof(key) == "number" and typeof(item) == "string" then
                selected[item] = true
            elseif item == true then
                selected[key] = true
            end
        end
        return selected
    end

    local function optionHasAnySelection(name)
        return next(normalizeMultiSelection(name)) ~= nil
    end

    local function farmEggPassesFilters(egg)
        if optionHasAnySelection("FarmEggRarity") then
            local selected = normalizeMultiSelection("FarmEggRarity")
            local rarity = tostring(egg:GetAttribute("Rarity"))
            if not selected[rarity] then
                return false
            end
        end

        if optionHasAnySelection("FarmEggNames") then
            local selected = normalizeMultiSelection("FarmEggNames")
            if not selected[egg.Name] then
                return false
            end
        end

        return true
    end

    local function getCollectLogic()
        local value = ctx.optionValue("CollectLogic", "Nearest")
        if type(value) == "table" then
            value = value[1]
        end
        return value or "Nearest"
    end

    local function canReachArea(area)
        if not area then
            return false
        end

        local requiredJump = tonumber(area.JumpPower)
        if not requiredJump then
            return false
        end

        local grace = 25
        local eggStealConfig = ctx.JumpLevels and ctx.JumpLevels.EggSteal
        if eggStealConfig then
            grace = tonumber(eggStealConfig.NaturalSpawnJumpPowerGrace) or 25
        end

        return ctx.getJumpPower() + grace >= requiredJump
    end

    -- Static pool #622, moved to runtime #1391 by the post-load permutation.
    local function getBestReachableArea()
        for _, areaName in ipairs(ctx.areaDropdownValues) do
            if areaName ~= "Best" then
                local area = ctx.areaByName[areaName]
                if area and canReachArea(area) then
                    return area
                end
            end
        end
        return nil
    end

    local function getFarmZoneNames()
        local selected = normalizeMultiSelection("FarmZone")
        local names = {}
        for areaName in pairs(selected) do
            if areaName ~= "Best" and ctx.areaByName[areaName] then
                names[#names + 1] = areaName
            end
        end

        if #names > 0 then
            return names
        end

        local best = getBestReachableArea()
        return best and { best.Name } or {}
    end

    local function getHighestSelectedFarmArea()
        local best
        for _, areaName in ipairs(getFarmZoneNames()) do
            local area = ctx.areaByName[areaName]
            if area and (not best or area.Index > best.Index) then
                best = area
            end
        end
        return best
    end

    local function pickEggTarget(candidates)
        if #candidates == 0 then
            return nil
        end

        local logic = getCollectLogic()
        local root = ctx.getHumanoidRootPart()
        local origin = root and root.Position or Vector3.zero

        if logic == "Random" then
            return candidates[math.random(1, #candidates)]
        end

        if logic == "Highest Rarity" then
            local bestEgg, bestRank, bestDistance
            for _, egg in ipairs(candidates) do
                local rank = ctx.rarityRanks[tostring(egg:GetAttribute("Rarity"))] or 0
                local distance = (egg:GetPivot().Position - origin).Magnitude
                if not bestEgg
                    or rank > bestRank
                    or (rank == bestRank and distance < bestDistance)
                then
                    bestEgg = egg
                    bestRank = rank
                    bestDistance = distance
                end
            end
            return bestEgg
        end

        local furthest = logic == "Furthest"
        local bestEgg, bestDistance
        for _, egg in ipairs(candidates) do
            local distance = (egg:GetPivot().Position - origin).Magnitude
            if bestDistance == nil
                or (furthest and distance > bestDistance)
                or (not furthest and distance < bestDistance)
            then
                bestEgg = egg
                bestDistance = distance
            end
        end
        return bestEgg
    end

    -- Live inline dispatcher helper AR(zones, applyFilters).
    local function scanAndPickEgg(zones, applyFilters)
        if type(zones) == "string" then
            zones = { zones }
        end

        local candidates = {}
        local function scanFolder(spawnedEggs)
            if not spawnedEggs then
                return
            end

            for _, egg in ipairs(spawnedEggs:GetChildren()) do
                if egg:IsA("Model") and (not applyFilters or farmEggPassesFilters(egg)) then
                    local prompt = egg:FindFirstChild("CollectPrompt", true)
                    if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        candidates[#candidates + 1] = egg
                    end
                end
            end
        end

        if zones == nil then
            for _, areaModel in ipairs(ctx.AreasFolder:GetChildren()) do
                scanFolder(areaModel:FindFirstChild("SpawnedEggs"))
            end
        else
            for _, areaName in ipairs(zones) do
                local areaModel = ctx.getAreaModelByName(areaName)
                if areaModel then
                    scanFolder(areaModel:FindFirstChild("SpawnedEggs"))
                end
            end
        end

        return pickEggTarget(candidates)
    end

    local function collectOneEgg(egg)
        local prompt = egg:FindFirstChild("CollectPrompt", true)
        if not prompt then
            return false
        end

        ctx.setStatus("Collecting " .. egg.Name)
        ctx.moveCharacterTo(egg:GetPivot().Position)
        task.wait(0.12)

        for _ = 1, 3 do
            ctx.firePromptSafe(prompt)
            task.wait(0.15)
            if ctx.isCarryingEgg() then
                ctx.setStatus("Registering egg")
                ctx.moveToPlotDetector()
                task.wait(0.15)
                return true
            end
        end

        ctx.setStatus("Missed " .. egg.Name)
        return false
    end

    local function autoCollectSelected()
        if ctx.isCollectBusy() or ctx.isSellingBusy() then
            return
        end

        ctx.setCollectBusy(true)
        local ok, err = pcall(function()
            if ctx.isCarryingEgg() then
                ctx.setStatus("Registering egg")
                ctx.moveToPlotDetector()
                task.wait(0.15)
                return
            end

            local selectedZones = getFarmZoneNames()
            local reachableZones = {}
            for _, areaName in ipairs(selectedZones) do
                local area = ctx.areaByName[areaName]
                if area and canReachArea(area) then
                    reachableZones[#reachableZones + 1] = areaName
                end
            end

            if #reachableZones == 0 then
                ctx.setStatus(#selectedZones == 0 and "No zone" or "Need more jump")
                return
            end

            local target = scanAndPickEgg(reachableZones, true)
            if target then
                collectOneEgg(target)
            else
                ctx.setStatus("Scanning " .. table.concat(reachableZones, ", "))
            end
        end)
        ctx.setCollectBusy(false)

        if not ok then
            warn("[AliceHUB] Auto Collect Selected:", err)
        end
    end

    local function autoCollectAll()
        if ctx.isCollectBusy() or ctx.isSellingBusy() then
            return
        end

        ctx.setCollectBusy(true)
        local ok, err = pcall(function()
            if ctx.isCarryingEgg() then
                ctx.setStatus("Registering egg")
                ctx.moveToPlotDetector()
                task.wait(0.15)
                return
            end

            ctx.setStatus("Scanning all zones")
            local target = scanAndPickEgg(nil, false)
            if target then
                collectOneEgg(target)
            end
        end)
        ctx.setCollectBusy(false)

        if not ok then
            warn("[AliceHUB] Auto Collect All:", err)
        end
    end

    local function scheduler()
        while not Library.Unloaded do
            if ctx.isOn("AutoCollectAll") then
                pcall(autoCollectAll)
                task.wait(0.05)
            elseif ctx.isOn("AutoCollectSelected") then
                pcall(autoCollectSelected)
                task.wait(0.05)
            else
                task.wait(0.35)
            end
        end
    end

    return {
        normalizeMultiSelection = normalizeMultiSelection,
        optionHasAnySelection = optionHasAnySelection,
        farmEggPassesFilters = farmEggPassesFilters,
        getCollectLogic = getCollectLogic,
        canReachArea = canReachArea,
        getBestReachableArea = getBestReachableArea,
        getFarmZoneNames = getFarmZoneNames,
        getHighestSelectedFarmArea = getHighestSelectedFarmArea,
        pickEggTarget = pickEggTarget,
        scanAndPickEgg = scanAndPickEgg,
        collectOneEgg = collectOneEgg,
        autoCollectSelected = autoCollectSelected,
        autoCollectAll = autoCollectAll,
        scheduler = scheduler,
    }
end


local function installLifecycle(ctx)
    local Library = ctx.Library
    local LocalPlayer = ctx.LocalPlayer

    local function getMaximumIncubatingEggs()
        local placement = ctx.EggsConfig and ctx.EggsConfig.Placement
        local value = placement and tonumber(placement.MaximumIncubatingEggs)
        return value or 8
    end

    local function getPlacedEggCount()
        local plot = ctx.getLocalPlot()
        local placed = plot and plot:FindFirstChild("PlacedEggs")
        return placed and #placed:GetChildren() or 0
    end

    local function areEggSlotsFull()
        return getPlacedEggCount() >= getMaximumIncubatingEggs()
    end

    local function getEggPlacementPosition(plot, slotIndex)
        local detector = plot:FindFirstChild("Detector")
        local origin = detector and detector.Position or plot:GetPivot().Position
        local column = (slotIndex - 1) % 5
        local row = math.floor((slotIndex - 1) / 5)
        return Vector3.new(
            origin.X + (column - 2) * 4,
            origin.Y,
            origin.Z + 6 + row * 4
        )
    end

    local function isHatchReady(egg)
        if not egg or not egg.Parent then
            return false
        end

        if egg:GetAttribute("HatchReady") == true then
            return true
        end

        local hatchAt = tonumber(egg:GetAttribute("HatchAt"))
        if hatchAt and hatchAt <= workspace:GetServerTimeNow() then
            return true
        end

        local prompt = egg:FindFirstChild("HatchPrompt", true)
        return prompt ~= nil
            and prompt:IsA("ProximityPrompt")
            and prompt.ActionText == "Open"
    end

    local function autoPlaceEggs()
        if ctx.isPlacingBusy() or ctx.isSellingBusy() then
            return
        end

        if areEggSlotsFull() then
            ctx.setStatus("Egg spots full")
            return
        end

        local plot = ctx.getLocalPlot()
        if not plot then
            return
        end

        local placedFolder = plot:FindFirstChild("PlacedEggs")
        local placedCount = placedFolder and #placedFolder:GetChildren() or 0
        local maxSlots = getMaximumIncubatingEggs()
        local eggTools = ctx.getEggTools()

        if #eggTools == 0 or placedCount >= maxSlots then
            return
        end

        ctx.setPlacingBusy(true)
        ctx.setStatus("Placing eggs")

        local placedThisRun = 0
        for _, eggTool in ipairs(eggTools) do
            if Library.Unloaded or not ctx.isOn("AutoPlaceEggs") or ctx.isSellingBusy() then
                break
            end

            if placedCount + placedThisRun >= maxSlots then
                ctx.setStatus("Egg spots full")
                break
            end

            local eggId = eggTool:GetAttribute("EggId")
            if eggId then
                ctx.setStatus("Placing " .. eggTool.Name)
                local humanoid = ctx.getHumanoid()
                if humanoid and eggTool.Parent == LocalPlayer.Backpack then
                    humanoid:EquipTool(eggTool)
                    task.wait(0.1)
                end

                placedThisRun += 1
                local position = getEggPlacementPosition(plot, placedCount + placedThisRun)
                ctx.PlaceEggRequest:FireServer(eggId, position)
                task.wait(0.25)
            end
        end

        ctx.setPlacingBusy(false)
    end

    local function hatchOneEgg(egg)
        local prompt = egg:FindFirstChild("HatchPrompt", true)
        if not prompt or not prompt:IsA("ProximityPrompt") then
            return false
        end

        ctx.setStatus("Hatching " .. egg.Name)
        if not ctx.moveCharacterTo(egg:GetPivot().Position) then
            return false
        end

        task.wait()
        local attempts = 1
        while attempts <= 3 do
            if not egg.Parent then
                return true
            end

            ctx.firePromptSafe(prompt)
            task.wait(0.2)

            if not egg.Parent or egg:GetAttribute("HatchOpening") == true then
                return true
            end
            attempts += 1
        end

        return not egg.Parent
    end

    local function autoHatchEggs()
        if ctx.isHatchingBusy() or ctx.isSellingBusy() then
            return
        end

        ctx.setHatchingBusy(true)
        local ok, err = pcall(function()
            local plot = ctx.getLocalPlot()
            if not plot then
                return
            end

            local placedEggs = plot:FindFirstChild("PlacedEggs")
            if not placedEggs then
                return
            end

            for _, egg in ipairs(placedEggs:GetChildren()) do
                if Library.Unloaded or not ctx.isOn("AutoHatchEggs") or ctx.isSellingBusy() then
                    break
                end

                if egg:IsA("Model") and isHatchReady(egg) then
                    hatchOneEgg(egg)
                    task.wait(0.15)
                end
            end
        end)
        ctx.setHatchingBusy(false)

        if not ok then
            warn("[AliceHUB] Auto Hatch:", err)
        end
    end

    local function getSquatDetector()
        local plot = ctx.getLocalPlot()
        if not plot then
            return nil
        end

        local squatZone = plot:FindFirstChild("SquatZone")
        if not squatZone then
            return nil
        end

        local floor = squatZone:FindFirstChild("Floor")
        if not floor then
            return nil
        end

        return floor:FindFirstChild("Detector")
    end

    local function autoGoTrain()
        local detector = getSquatDetector()
        if not detector then
            return
        end
        if LocalPlayer:GetAttribute("IsSquatting") == true then
            return
        end

        ctx.setStatus("Going to train")
        ctx.moveCharacterTo(detector.Position)
        ctx.SquatTrainingRequest:FireServer(detector)
    end

    local function auto2x()
        if LocalPlayer:GetAttribute("IsSquatting") ~= true then
            return
        end
        if LocalPlayer:GetAttribute("SquatBonusAvailable") ~= true then
            return
        end

        local version = tonumber(LocalPlayer:GetAttribute("SquatBonusVersion")) or 0
        ctx.setStatus("Claiming 2x")
        ctx.SquatBonusRequest:FireServer(math.floor(version))
    end

    local function onSquatBonusAvailable()
        if ctx.isOn("Auto2x") then
            pcall(auto2x)
        end
    end

    local function placementHatchScheduler()
        while not Library.Unloaded do
            if ctx.isOn("AutoPlaceEggs") then
                pcall(autoPlaceEggs)
            end
            if ctx.isOn("AutoHatchEggs") then
                pcall(autoHatchEggs)
            end
            task.wait(0.25)
        end
    end

    local function trainingScheduler()
        while not Library.Unloaded do
            if ctx.isOn("AutoGoTrain") then
                pcall(autoGoTrain)
            end
            if ctx.isOn("Auto2x") then
                pcall(auto2x)
            end
            task.wait(0.2)
        end
    end

    return {
        getMaximumIncubatingEggs = getMaximumIncubatingEggs,
        getPlacedEggCount = getPlacedEggCount,
        areEggSlotsFull = areEggSlotsFull,
        getEggPlacementPosition = getEggPlacementPosition,
        isHatchReady = isHatchReady,
        autoPlaceEggs = autoPlaceEggs,
        hatchOneEgg = hatchOneEgg,
        autoHatchEggs = autoHatchEggs,
        getSquatDetector = getSquatDetector,
        autoGoTrain = autoGoTrain,
        auto2x = auto2x,
        onSquatBonusAvailable = onSquatBonusAvailable,
        placementHatchScheduler = placementHatchScheduler,
        trainingScheduler = trainingScheduler,
    }
end


local function installShopSell(ctx)
    local Library = ctx.Library
    local LocalPlayer = ctx.LocalPlayer
    local cachedPetSnapshot = nil

    local function parseCompactNumber(value)
        if type(value) == "number" then
            return value
        end

        local suffixes = {
            K = 1e3,
            M = 1e6,
            B = 1e9,
            T = 1e12,
            QA = 1e15,
            QI = 1e18,
            SX = 1e21,
            SP = 1e24,
            OC = 1e27,
            NO = 1e30,
            DC = 1e33,
        }

        local text = tostring(value or "")
            :gsub("%$", "")
            :gsub(",", "")
            :gsub("%s", "")
        local numberText, suffix = text:match("^([%d%.]+)([%a]*)$")
        local number = tonumber(numberText)
        if not number then
            return 0
        end

        suffix = string.upper(suffix or "")
        return number * (suffixes[suffix] or 1)
    end

    local function getCashNumber()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local cash = leaderstats and leaderstats:FindFirstChild("Cash")
        return parseCompactNumber(cash and cash.Value or nil)
    end

    local function ownsTrail(name)
        local data = LocalPlayer:FindFirstChild("TrailData")
        local owned = data and data:FindFirstChild("Owned")
        local item = owned and owned:FindFirstChild(name)
        return item and item.Value == true or false
    end

    local function ownsCoil(name)
        local data = LocalPlayer:FindFirstChild("CoilData")
        local owned = data and data:FindFirstChild("Owned")
        local item = owned and owned:FindFirstChild(name)
        return item and item.Value == true or false
    end

    local function autoBuyTrails()
        local cash = getCashNumber()
        for _, name in ipairs(ctx.TrailNames) do
            if Library.Unloaded or not ctx.isOn("AutoBuyTrails") then
                return
            end

            if not ownsTrail(name) then
                local item = ctx.TrailsConfig.Get(name)
                local cost = item and tonumber(item.Cost) or math.huge
                if cash >= cost then
                    ctx.setStatus("Buying " .. name)
                    ctx.TrailsRemote:FireServer("Select", name)
                    task.wait(0.2)
                    cash = getCashNumber()
                end
            end
        end
    end

    local function autoBuyCoil()
        local cash = getCashNumber()
        for _, name in ipairs(ctx.CoilNames) do
            if Library.Unloaded or not ctx.isOn("AutoBuyCoil") then
                return
            end

            if not ownsCoil(name) then
                local item = ctx.SpeedUpgrades.Get(name)
                local cost = item and tonumber(item.Cost) or math.huge
                if cash >= cost then
                    ctx.setStatus("Buying " .. name)
                    ctx.CoilsRemote:FireServer("Select", name)
                    task.wait(0.2)
                    cash = getCashNumber()
                end
            end
        end
    end

    local function autoEquipBestPets()
        if ctx.isSellingBusy() then
            return
        end
        ctx.setStatus("Equip best")
        ctx.PetInventory:FireServer("EquipBest")
    end

    local function autoUpgradePlot()
        ctx.setStatus("Upgrading plot")
        ctx.PetInventory:FireServer("BuyEquipSlot")
    end

    local function autoClaimIndex()
        ctx.setStatus("Claiming index")
        ctx.ClaimAnimalIndexReward:FireServer("__ALL__")
    end

    local function petPassesSellFilters(pet)
        if type(pet) ~= "table" or pet.Kind ~= "Pet" then
            return false
        end

        if ctx.optionHasAnySelection("SellAnimals") then
            local selected = ctx.normalizeMultiSelection("SellAnimals")
            if not selected[tostring(pet.Name)] then
                return false
            end
        end

        if ctx.optionHasAnySelection("SellRarity") then
            local selected = ctx.normalizeMultiSelection("SellRarity")
            if not selected[tostring(pet.Rarity)] then
                return false
            end
        end

        return true
    end

    local function getPetInventorySnapshot()
        local snapshot = nil
        local connection
        connection = ctx.PetInventory.OnClientEvent:Connect(function(kind, payload)
            if kind == "Snapshot" and type(payload) == "table" then
                snapshot = payload
            end
        end)

        ctx.PetInventory:FireServer("Get")
        local deadline = os.clock() + 2
        while snapshot == nil and os.clock() < deadline do
            task.wait(0.05)
        end

        connection:Disconnect()
        if snapshot then
            cachedPetSnapshot = snapshot
        end
        return cachedPetSnapshot
    end

    local function getPetInventoryTools()
        local tools = {}
        local function scan(container)
            if not container then
                return
            end
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") and child:GetAttribute("IsPetInventoryTool") == true then
                    tools[#tools + 1] = child
                end
            end
        end
        scan(LocalPlayer:FindFirstChild("Backpack"))
        scan(LocalPlayer.Character)
        return tools
    end

    local function equipPetToolForSell(tool)
        local character = LocalPlayer.Character
        local humanoid = ctx.getHumanoid()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not character or not humanoid or not backpack or not tool then
            return false
        end

        humanoid:UnequipTools()
        task.wait(0.05)

        -- The original also reparents any tool still left in Character back to Backpack.
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                child.Parent = backpack
            end
        end

        if tool.Parent ~= character then
            tool.Parent = character
        end
        task.wait(0.1)

        local equipped = character:FindFirstChildOfClass("Tool")
        if not equipped then
            return false
        end
        return equipped:GetAttribute("PetId") == tool:GetAttribute("PetId")
    end

    local function sellAtDetector()
        local detector = ctx.SellArea and ctx.SellArea:FindFirstChild("Detector")
        local prompt = detector and detector:FindFirstChild("SellAnimalPrompt", true)

        if detector then
            ctx.moveCharacterTo(detector.Position)
            task.wait(0.15)
            if prompt then
                ctx.firePromptSafe(prompt)
                task.wait(0.2)
            end
        end

        -- Exact original fallback: the Sell remote is fired even when the detector/prompt
        -- is missing; movement/prompt interaction is best-effort only.
        ctx.SellRemote:FireServer()
    end

    local function autoSellPets()
        if ctx.isSellingBusy() then
            return
        end

        ctx.setSellingBusy(true)
        ctx.setStatus("Selling pets")
        local ok, err = pcall(function()
            local snapshot = getPetInventorySnapshot()
            local sellable = {}
            if snapshot then
                for _, pet in pairs(snapshot) do
                    if petPassesSellFilters(pet) and pet.Id then
                        sellable[#sellable + 1] = pet
                    end
                end
            end

            table.sort(sellable, function(a, b)
                return (tonumber(a.CashPerSecond) or 0) < (tonumber(b.CashPerSecond) or 0)
            end)

            for _, pet in ipairs(sellable) do
                if Library.Unloaded or not ctx.isOn("AutoSell") then
                    break
                end

                ctx.setStatus("Selling " .. tostring(pet.Name))
                ctx.PetInventory:FireServer("SetEquipped", pet.Id, false)
                task.wait(0.2)

                local targetTool
                for _, tool in ipairs(getPetInventoryTools()) do
                    if tool:GetAttribute("PetId") == pet.Id then
                        targetTool = tool
                        break
                    end
                end

                if targetTool and equipPetToolForSell(targetTool) then
                    sellAtDetector()
                    task.wait(0.25)
                end
            end

            local humanoid = ctx.getHumanoid()
            if humanoid then
                humanoid:UnequipTools()
            end
        end)
        ctx.setSellingBusy(false)

        if not ok then
            warn("[AliceHUB] Auto Sell:", err)
        end
    end

    local function scheduler()
        while not Library.Unloaded do
            if ctx.isOn("AutoBuyTrails") then
                pcall(autoBuyTrails)
            end
            if ctx.isOn("AutoBuyCoil") then
                pcall(autoBuyCoil)
            end
            if ctx.isOn("AutoEquipBest") then
                pcall(autoEquipBestPets)
            end
            if ctx.isOn("AutoUpgradePlot") then
                pcall(autoUpgradePlot)
            end
            if ctx.isOn("AutoClaimIndex") then
                pcall(autoClaimIndex)
            end
            if ctx.isOn("AutoSell") then
                pcall(autoSellPets)
            end
            task.wait(1.25)
        end
    end

    return {
        parseCompactNumber = parseCompactNumber,
        getCashNumber = getCashNumber,
        ownsTrail = ownsTrail,
        ownsCoil = ownsCoil,
        autoBuyTrails = autoBuyTrails,
        autoBuyCoil = autoBuyCoil,
        autoEquipBestPets = autoEquipBestPets,
        autoUpgradePlot = autoUpgradePlot,
        autoClaimIndex = autoClaimIndex,
        petPassesSellFilters = petPassesSellFilters,
        getPetInventorySnapshot = getPetInventorySnapshot,
        getPetInventoryTools = getPetInventoryTools,
        equipPetToolForSell = equipPetToolForSell,
        sellAtDetector = sellAtDetector,
        autoSellPets = autoSellPets,
        scheduler = scheduler,
    }
end


local function asSingle(value, fallback)
    if type(value) == "table" then
        return value[1] or fallback
    end
    if value == nil then
        return fallback
    end
    return value
end

local function installServerHop(ctx)
    local Library = ctx.Library
    local LocalPlayer = ctx.LocalPlayer
    local AreasFolder = ctx.AreasFolder
    local TeleportService = ctx.TeleportService
    local HttpService = ctx.HttpService

    local nextHopAllowedAt = 0
    local noMatchSince = 0
    local hopBusy = false

    local function selectedHopRarities()
        return ctx.normalizeMultiSelection("ServerhopRarities")
    end

    local function rarityAllowed(egg)
        if not ctx.optionHasAnySelection("ServerhopRarities") then
            return true
        end
        return selectedHopRarities()[tostring(egg:GetAttribute("Rarity"))] == true
    end

    local function folderHasMatchingEgg(spawnedEggs)
        if not spawnedEggs then
            return false
        end

        for _, egg in spawnedEggs:GetChildren() do
            if egg:IsA("Model") and rarityAllowed(egg) then
                local prompt = egg:FindFirstChild("CollectPrompt", true)
                if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    return true
                end
            end
        end
        return false
    end

    local function hasMatchingTargetEgg()
        local scope = asSingle(ctx.optionValue("ServerhopScope", "Farm Zone"), "Farm Zone")

        if scope == "All Zones" then
            for _, areaModel in AreasFolder:GetChildren() do
                if folderHasMatchingEgg(areaModel:FindFirstChild("SpawnedEggs")) then
                    return true
                end
            end
            return false
        end

        -- Original Farm Zone path uses the highest selected/reachable farm area.
        local area = ctx.getHighestSelectedFarmArea()
        if not area then
            return false
        end

        local areaModel = ctx.getAreaModelByName(area.Name)
        if not areaModel then
            return false
        end
        return folderHasMatchingEgg(areaModel:FindFirstChild("SpawnedEggs"))
    end

    local function fetchCandidateServers()
        local candidates = {}
        local cursor = nil
        local minPlayers = math.max(tonumber(ctx.optionValue("ServerhopMinPlayers", 1)) or 1, 0)

        for _ = 1, 4 do
            if #candidates >= 40 then
                break
            end

            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                game.PlaceId
            )
            if cursor then
                url ..= "&cursor=" .. cursor
            end

            local okGet, body = pcall(function()
                return game:HttpGet(url)
            end)
            if not okGet then
                task.wait(0.2)
                break
            end

            local okDecode, page = pcall(function()
                return HttpService:JSONDecode(body)
            end)
            if not okDecode or type(page) ~= "table" or type(page.data) ~= "table" then
                break
            end

            for _, server in ipairs(page.data) do
                if type(server) == "table"
                    and type(server.id) == "string"
                    and type(server.playing) == "number"
                    and type(server.maxPlayers) == "number"
                    and server.id ~= game.JobId
                    and server.playing < server.maxPlayers
                    and server.playing >= minPlayers
                then
                    candidates[#candidates + 1] = server
                    if #candidates >= 40 then
                        break
                    end
                end
            end

            cursor = page.nextPageCursor
            if type(cursor) ~= "string" then
                break
            end
        end

        return candidates
    end

    local function chooseServer(candidates)
        if #candidates == 0 then
            return nil
        end

        local mode = asSingle(ctx.optionValue("ServerhopMode", "Random"), "Random")
        if mode == "Least Populated" then
            table.sort(candidates, function(a, b)
                return a.playing < b.playing
            end)
            return candidates[1]
        elseif mode == "Most Populated" then
            table.sort(candidates, function(a, b)
                return a.playing > b.playing
            end)
            return candidates[1]
        end

        return candidates[math.random(1, #candidates)]
    end

    local function hop(reason)
        if Library.Unloaded or hopBusy or os.clock() < nextHopAllowedAt then
            return false
        end

        hopBusy = true
        local displayReason = reason or "Server hopping"
        ctx.setStatus("Server hopping")
        Library:Notify(tostring(displayReason))

        local target = chooseServer(fetchCandidateServers())
        if not target then
            nextHopAllowedAt = os.clock() + 20
            hopBusy = false
            Library:Notify("No servers available to hop")
            return false
        end

        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer)
        end)
        if not ok then
            nextHopAllowedAt = os.clock() + 10
            hopBusy = false
            Library:Notify("Server hop failed")
            return false
        end

        -- If teleport does not complete, release the lock later and add a short cooldown.
        task.delay(15, function()
            hopBusy = false
            nextHopAllowedAt = os.clock() + 5
        end)
        return true
    end

    local function manualHop()
        nextHopAllowedAt = 0
        task.spawn(function()
            hop("Manual hop")
        end)
    end

    local function monitorLoop()
        while not Library.Unloaded do
            task.wait(1)

            local enabled = ctx.isOn("ServerhopIfNoRarity")
            local blocked = hopBusy or ctx.isSellingBusy() or ctx.isCarryingEgg()

            -- Original resets the timer while disabled, busy/carrying, or a target exists again.
            if not enabled or blocked or hasMatchingTargetEgg() then
                noMatchSince = 0
            else
                local now = os.clock()
                if noMatchSince == 0 then
                    noMatchSince = now
                else
                    local waitSeconds = math.max(tonumber(ctx.optionValue("ServerhopWait", 15)) or 15, 1)
                    if now - noMatchSince >= waitSeconds then
                        noMatchSince = 0
                        pcall(hop, "No matching rarity eggs")
                    end
                end
            end
        end
    end

    return {
        rarityAllowed = rarityAllowed,
        hasMatchingTargetEgg = hasMatchingTargetEgg,
        fetchCandidateServers = fetchCandidateServers,
        chooseServer = chooseServer,
        hop = hop,
        manualHop = manualHop,
        monitorLoop = monitorLoop,
        isBusy = function() return hopBusy end,
    }
end


local function installMovement(ctx)
    local Library = ctx.Library
    local LocalPlayer = ctx.LocalPlayer
    local RunService = ctx.RunService
    local UserInputService = ctx.UserInputService
    local Workspace = ctx.Workspace
    local GuiService = ctx.GuiService
    local CoreGui = ctx.CoreGui

    local promptConnection = nil

    local function applyAntiGameplayPause(enabled)
        pcall(function()
            GuiService:SetGameplayPausedNotificationEnabled(not enabled)
        end)

        pcall(function()
            local notification = CoreGui:FindFirstChild("RobloxNetworkPauseNotification")
            if notification then
                notification.Enabled = not enabled
            end
        end)

        if enabled then
            pcall(function()
                if sethiddenproperty then
                    sethiddenproperty(LocalPlayer, "GameplayPaused", false)
                else
                    LocalPlayer.GameplayPaused = false
                end
            end)
        end
    end

    local function makePromptInstant(prompt)
        if not prompt:IsA("ProximityPrompt") then
            return
        end
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 50
        prompt.RequiresLineOfSight = false
    end

    -- Exact original behavior: this connection stays alive for the Library lifetime.
    RunService.Stepped:Connect(function()
        if Library.Unloaded or not ctx.isOn("NoClip") then
            return
        end

        local character = LocalPlayer.Character
        if not character then
            return
        end

        for _, object in ipairs(character:GetDescendants()) do
            if object:IsA("BasePart") and object.CanCollide then
                object.CanCollide = false
            end
        end
    end)

    UserInputService.JumpRequest:Connect(function()
        if Library.Unloaded or not ctx.isOn("InfJump") then
            return
        end
        local humanoid = ctx.getHumanoid()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if Library.Unloaded then
            return
        end

        if ctx.isOn("WalkSpeedEnabled") then
            local humanoid = ctx.getHumanoid()
            local option = ctx.Options.WalkSpeed
            if humanoid and option then
                humanoid.WalkSpeed = option.Value
            end
        end

        if not ctx.isOn("Fly") then
            return
        end

        local root = ctx.getHumanoidRootPart()
        local humanoid = ctx.getHumanoid()
        local speedOption = ctx.Options.FlySpeed
        local camera = Workspace.CurrentCamera
        if not root or not humanoid or not speedOption or not camera then
            return
        end

        humanoid.PlatformStand = true
        local direction = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction += camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction -= camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction -= camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction += camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.new(0, 1, 0)
        end

        root.AssemblyLinearVelocity = Vector3.zero
        if direction.Magnitude > 0 then
            root.CFrame += direction.Unit * speedOption.Value * dt
        end
    end)

    ctx.Toggles.Fly:OnChanged(function()
        if not ctx.Toggles.Fly.Value then
            local humanoid = ctx.getHumanoid()
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end)

    ctx.Toggles.WalkSpeedEnabled:OnChanged(function()
        if not ctx.Toggles.WalkSpeedEnabled.Value then
            local humanoid = ctx.getHumanoid()
            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end
    end)

    ctx.Toggles.AntiGameplayPause:OnChanged(function()
        applyAntiGameplayPause(ctx.Toggles.AntiGameplayPause.Value)
    end)

    task.spawn(function()
        while not Library.Unloaded do
            task.wait(1)
            if ctx.Toggles.AntiGameplayPause.Value then
                applyAntiGameplayPause(true)
            end
        end
    end)

    ctx.Toggles.InstantProximityPrompt:OnChanged(function()
        if ctx.Toggles.InstantProximityPrompt.Value then
            for _, object in ipairs(Workspace:GetDescendants()) do
                pcall(makePromptInstant, object)
            end

            promptConnection = Workspace.DescendantAdded:Connect(function(object)
                if ctx.Toggles.InstantProximityPrompt.Value then
                    pcall(makePromptInstant, object)
                end
            end)
        elseif promptConnection then
            promptConnection:Disconnect()
            promptConnection = nil
        end
    end)

    Library:OnUnload(function()
        if promptConnection then
            promptConnection:Disconnect()
            promptConnection = nil
        end
        applyAntiGameplayPause(false)

        local humanoid = ctx.getHumanoid()
        if humanoid then
            humanoid.PlatformStand = false
        end
    end)

    return {
        applyAntiGameplayPause = applyAntiGameplayPause,
        makePromptInstant = makePromptInstant,
    }
end


local function installVisual(ctx)
    local Library = ctx.Library
    local LocalPlayer = ctx.LocalPlayer
    local Workspace = ctx.Workspace
    local Lighting = ctx.Lighting

    local boostSnapshot = nil
    local boostDescendantConnection = nil
    local effectClasses = {
        ParticleEmitter = true,
        Trail = true,
        Smoke = true,
        Fire = true,
        Sparkles = true,
    }

    local function applyHiddenObject(object, hidden)
        -- This reproduces the original class routing. Calls are protected by pcall
        -- at the traversal layer, including the Decal/Texture LTM attempt.
        if object:IsA("BasePart") or object:IsA("Decal") or object:IsA("Texture") then
            object.LocalTransparencyModifier = hidden and 1 or 0
            return
        end

        if object:IsA("ParticleEmitter")
            or object:IsA("Trail")
            or object:IsA("Smoke")
            or object:IsA("Fire")
            or object:IsA("Sparkles")
            or object:IsA("BillboardGui")
            or object:IsA("SurfaceGui")
        then
            object.Enabled = not hidden
        end
    end

    local function applyModelHidden(model, hidden)
        if not model or not model:IsA("Model") then
            return
        end
        for _, object in model:GetDescendants() do
            pcall(applyHiddenObject, object, hidden)
        end
    end

    local function applyAvatarHidden(hidden)
        local character = LocalPlayer.Character
        if character then
            applyModelHidden(character, hidden)
        end
    end

    local function getPlotsFolder()
        local map = Workspace:FindFirstChild("Map")
        return map and map:FindFirstChild("Plots") or nil
    end

    local function applyPetVisibility()
        local plots = getPlotsFolder()
        if not plots then
            return
        end

        local ownPlot = ctx.getLocalPlot()
        local hideOwn = ctx.isOn("DeleteOwnPets")
        local hideOther = ctx.isOn("DeleteOtherPets")

        for _, plot in plots:GetChildren() do
            local placedAnimals = plot:FindFirstChild("PlacedAnimals")
            if placedAnimals then
                local hidden = plot == ownPlot and hideOwn or plot ~= ownPlot and hideOther
                for _, animal in placedAnimals:GetChildren() do
                    if animal:IsA("Model") then
                        applyModelHidden(animal, hidden)
                    end
                end
            end
        end
    end

    local function refreshVisuals()
        applyAvatarHidden(ctx.isOn("HideAvatar"))
        applyPetVisibility()
    end

    ctx.Toggles.HideAvatar:OnChanged(function()
        applyAvatarHidden(ctx.isOn("HideAvatar"))
    end)
    ctx.Toggles.DeleteOtherPets:OnChanged(refreshVisuals)
    ctx.Toggles.DeleteOwnPets:OnChanged(refreshVisuals)

    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.35)
        if not Library.Unloaded and ctx.isOn("HideAvatar") then
            applyModelHidden(character, true)
        end
    end)

    local plots = getPlotsFolder()
    if plots then
        plots.DescendantAdded:Connect(function()
            if Library.Unloaded then
                return
            end
            if ctx.isOn("DeleteOwnPets") or ctx.isOn("DeleteOtherPets") then
                task.defer(refreshVisuals)
            end
        end)
    end

    task.spawn(function()
        while not Library.Unloaded do
            task.wait(0.5)
            if ctx.isOn("HideAvatar") or ctx.isOn("DeleteOwnPets") or ctx.isOn("DeleteOtherPets") then
                refreshVisuals()
            end
        end
    end)

    local function safeSetEffectEnabled(object, enabled)
        pcall(function()
            object.Enabled = enabled
        end)
    end

    local function enableBoostFPS()
        if boostSnapshot then
            return
        end

        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        local qualityLevel = nil
        pcall(function()
            qualityLevel = settings().Rendering.QualityLevel
        end)

        boostSnapshot = {
            QualityLevel = qualityLevel,
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            Terrain = terrain,
            WaterWaveSize = terrain and terrain.WaterWaveSize or nil,
            WaterReflectance = terrain and terrain.WaterReflectance or nil,
            Effects = {},
        }

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000

        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterReflectance = 0
        end

        for _, object in Workspace:GetDescendants() do
            if effectClasses[object.ClassName] and object.Enabled then
                boostSnapshot.Effects[#boostSnapshot.Effects + 1] = object
                safeSetEffectEnabled(object, false)
            end
        end

        boostDescendantConnection = Workspace.DescendantAdded:Connect(function(object)
            if ctx.isOn("BoostFPS") and effectClasses[object.ClassName] then
                -- Exact quirk: newly-added effects are disabled but NOT added to the restore snapshot.
                safeSetEffectEnabled(object, false)
            end
        end)
    end

    local function disableBoostFPS()
        local snapshot = boostSnapshot
        if not snapshot then
            return
        end

        Lighting.GlobalShadows = snapshot.GlobalShadows
        Lighting.FogEnd = snapshot.FogEnd

        local terrain = snapshot.Terrain
        if terrain and terrain.Parent then
            terrain.WaterWaveSize = snapshot.WaterWaveSize
            terrain.WaterReflectance = snapshot.WaterReflectance
        end

        if snapshot.QualityLevel then
            pcall(function()
                settings().Rendering.QualityLevel = snapshot.QualityLevel
            end)
        end

        if boostDescendantConnection then
            boostDescendantConnection:Disconnect()
            boostDescendantConnection = nil
        end

        for _, object in snapshot.Effects do
            safeSetEffectEnabled(object, true)
        end

        boostSnapshot = nil
    end

    local function setBoostFPS(enabled)
        if enabled then
            enableBoostFPS()
        else
            disableBoostFPS()
        end
    end

    ctx.Toggles.BoostFPS:OnChanged(function()
        setBoostFPS(ctx.isOn("BoostFPS"))
    end)
    if ctx.isOn("BoostFPS") then
        setBoostFPS(true)
    end

    Library:OnUnload(function()
        applyAvatarHidden(false)

        local currentPlots = getPlotsFolder()
        if currentPlots then
            for _, plot in currentPlots:GetChildren() do
                local placedAnimals = plot:FindFirstChild("PlacedAnimals")
                if placedAnimals then
                    for _, animal in placedAnimals:GetChildren() do
                        if animal:IsA("Model") then
                            applyModelHidden(animal, false)
                        end
                    end
                end
            end
        end

        setBoostFPS(false)
    end)

    return {
        applyHiddenObject = applyHiddenObject,
        applyAvatarHidden = applyAvatarHidden,
        applyPetVisibility = applyPetVisibility,
        setBoostFPS = setBoostFPS,
    }
end


local function installInfo(ctx)
    local Library = ctx.Library
    local LocalPlayer = ctx.LocalPlayer
    local Players = ctx.Players
    local TeleportService = ctx.TeleportService

    local sessionStartedAt = os.clock()

    local function supportBadge()
        local requestFn = request or http_request
        local dbg = debug
        local capabilities = {
            hookfunction ~= nil,
            hookmetamethod ~= nil,
            getrawmetatable ~= nil,
            setrawmetatable ~= nil,
            getgc ~= nil,
            getgenv ~= nil,
            getreg ~= nil,
            getconnections ~= nil,
            firesignal ~= nil,
            getcallbackvalue ~= nil,
            setclipboard ~= nil,
            getcustomasset ~= nil,
            getnamecallmethod ~= nil,
            isexecutorclosure ~= nil,
            fireproximityprompt ~= nil,
            firetouchinterest ~= nil,
            WebSocket ~= nil,
            readfile ~= nil,
            writefile ~= nil,
            requestFn ~= nil,
            dbg and dbg.getupvalues ~= nil or false,
            dbg and dbg.setupvalue ~= nil or false,
        }

        local supported = 0
        for _, value in ipairs(capabilities) do
            if value then
                supported += 1
            end
        end

        local ratio = supported / #capabilities
        if ratio >= 0.9 then
            return ctx.colored("Full Support", ctx.colors.green)
        elseif ratio >= 0.6 then
            return ctx.colored("Half Support", ctx.colors.yellow)
        end
        return ctx.colored("Low Support", ctx.colors.red)
    end

    local function executorName()
        local name = "Unknown"
        pcall(function()
            if identifyexecutor then
                local executor, version = identifyexecutor()
                if type(executor) == "string" and executor ~= "" then
                    if type(version) == "string" and version ~= "" then
                        name = executor .. " " .. version
                    else
                        name = executor
                    end
                end
            end
        end)
        return name
    end

    local function sessionText()
        local elapsed = math.floor(os.clock() - sessionStartedAt)
        if elapsed < 60 then
            return elapsed .. "s"
        elseif elapsed < 3600 then
            return string.format("%dm %ds", elapsed // 60, elapsed % 60)
        end
        return string.format("%dh %dm", elapsed // 3600, elapsed % 3600 // 60)
    end

    local accountGroup = ctx.Tabs.Info:AddLeftGroupbox("Account")
    accountGroup:AddLabel(ctx.field("User", LocalPlayer.Name, ctx.colors.green), true)

    local function getAliceHubAccessData()
        local env = (getgenv and getgenv()) or _G
        local data = env.AliceHUBAccess or env.AliceHubAccess or env.AliceHUBLicense or env.AliceHubLicense or {}
        if typeof(data) ~= "table" then
            data = {}
        end

        local status = data.status or data.Status or data.plan or data.Plan or data.duration or data.Duration
        local expiresAt = data.expiresAt or data.ExpiresAt or data.expires_at or data.expiry or data.Expiry or data.expiredAt
        local permanent = data.permanent == true or data.Permanent == true

        if not status then
            status = env.AliceHUBStatus or env.AliceHubStatus or env.AliceHUBPlan or env.AliceHubPlan
        end
        if not expiresAt then
            expiresAt = env.AliceHUBExpiresAt or env.AliceHubExpiresAt
        end

        status = tostring(status or "Loading")
        if string.find(string.lower(status), "perma", 1, true) then
            permanent = true
        end
        return status, expiresAt, permanent
    end

    local function toUnixTimestamp(value)
        if typeof(value) == "number" then
            return value
        end
        if typeof(value) ~= "string" or value == "" then
            return nil
        end
        local numeric = tonumber(value)
        if numeric then
            return numeric
        end
        local ok, dateTime = pcall(DateTime.fromIsoDate, value)
        if ok and dateTime then
            return dateTime.UnixTimestamp
        end
        return nil
    end

    local function formatAccessRemaining(expiresAt, permanent)
        if permanent then
            return "Permanent"
        end
        local expiresUnix = toUnixTimestamp(expiresAt)
        if not expiresUnix then
            return "--"
        end
        local remaining = math.max(0, math.floor(expiresUnix - DateTime.now().UnixTimestamp))
        if remaining <= 0 then
            return "Expired"
        end
        local days = remaining // 86400
        local hours = (remaining % 86400) // 3600
        local minutes = (remaining % 3600) // 60
        local seconds = remaining % 60
        if days > 0 then
            return string.format("%dd %dh %dm", days, hours, minutes)
        elseif hours > 0 then
            return string.format("%dh %dm %ds", hours, minutes, seconds)
        end
        return string.format("%dm %ds", minutes, seconds)
    end

    local initialStatus, initialExpiry, initialPermanent = getAliceHubAccessData()
    local accessStatusLabel = accountGroup:AddLabel(ctx.field("Status", initialStatus, ctx.colors.green), true)
    local accessRemainingLabel = accountGroup:AddLabel(ctx.field("Remaining", formatAccessRemaining(initialExpiry, initialPermanent), ctx.colors.yellow), true)
    accountGroup:AddLabel(ctx.field("Executor", executorName() .. "  " .. supportBadge(), ctx.colors.green), true)

    task.spawn(function()
        while not Library.Unloaded do
            task.wait(1)
            local status, expiresAt, permanent = getAliceHubAccessData()
            accessStatusLabel:SetText(ctx.field("Status", status, ctx.colors.green))
            accessRemainingLabel:SetText(ctx.field("Remaining", formatAccessRemaining(expiresAt, permanent), ctx.colors.yellow))
        end
    end)

    local gameGroup = ctx.Tabs.Info:AddLeftGroupbox("Game Info")
    gameGroup:AddLabel(ctx.colored(ctx.GameName .. " [" .. tostring(game.PlaceId) .. "]", ctx.colors.blue), true)
    gameGroup:AddLabel(ctx.field("Place ID", tostring(game.PlaceId), ctx.colors.blue), true)
    local sessionLabel = gameGroup:AddLabel(ctx.field("Session time", sessionText(), ctx.colors.yellow), true)
    gameGroup:AddLabel(ctx.field("Server", tostring(game.JobId), ctx.colors.gray), true)
    gameGroup:AddButton({
        Text = "Copy join script (Job ID)",
        Func = function()
            local scriptText = ('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)')
                :format(game.PlaceId, tostring(game.JobId))
            ctx.copy(scriptText, "Copied join script")
        end,
    })

    local scriptsGroup = ctx.Tabs.Info:AddRightGroupbox("Scripts")
    local playersLabel = scriptsGroup:AddLabel(ctx.field("Players", "0/0", ctx.colors.green), true)
    local pingLabel = scriptsGroup:AddLabel(ctx.field("Ping", "0 ms", ctx.colors.yellow), true)
    scriptsGroup:AddButton({
        Text = "Rejoin Server",
        Func = function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end,
    })
    scriptsGroup:AddButton({
        Text = "Copy Job ID",
        Func = function()
            ctx.copy(tostring(game.JobId), "Copied Job ID")
        end,
    })
    scriptsGroup:AddButton({ Text = "Copy Username", Func = function() ctx.copy(LocalPlayer.Name, "Copied username") end })
    scriptsGroup:AddButton({
        Text = "Copy Profile Link",
        Func = function()
            ctx.copy("https://www.roblox.com/users/" .. tostring(LocalPlayer.UserId) .. "/profile", "Copied profile link")
        end,
    })

    local adGroup = ctx.Tabs.Info:AddLeftGroupbox("AliceHUB")
    adGroup:AddLabel("The Discord has ready made configs, methods, giveaways, and early access to new scripts.", true)
    adGroup:AddLabel("Requests get taken seriously. A lot of what is in AliceHUB started as a Discord message.", true)
    adGroup:AddButton({ Text = "Copy Discord Invite", Func = ctx.discordAction })
    adGroup:AddButton({ Text = "AliceHUB GitHub", Func = function() ctx.copy(ctx.aliceHubRepoUrl, "Copied AliceHUB GitHub") end })
    adGroup:AddButton({ Text = "AliceHUB Community", Func = function() ctx.copy(ctx.aliceHubCommunityUrl, "Copied AliceHUB community link") end })

    task.spawn(function()
        while not Library.Unloaded do
            sessionLabel:SetText(ctx.field("Session time", sessionText(), ctx.colors.yellow))
            playersLabel:SetText(ctx.field("Players", #Players:GetPlayers() .. "/" .. tostring(Players.MaxPlayers), ctx.colors.green))

            local ok, value = pcall(function()
                return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            local ping = ok and (value .. " ms") or "n/a"
            pingLabel:SetText(ctx.field("Ping", ping, ctx.colors.yellow))

            task.wait(1)
        end
    end)

    return {
        supportBadge = supportBadge,
        executorName = executorName,
        sessionText = sessionText,
    }
end


-- AliceHUB / Jump for Animals

local function installWebhook(ctx)
    local Library = ctx.Library
    local Options = ctx.Options
    local Tabs = ctx.Tabs
    local LocalPlayer = ctx.LocalPlayer
    local AreasFolder = ctx.AreasFolder
    local HttpService = ctx.HttpService
    local DateTime = ctx.DateTime or DateTime
    local rarityNames = ctx.rarityNames
    local rarityRanks = ctx.rarityRanks
    local rarityColors = ctx.rarityColors
    local eggNames = ctx.eggNames

    local isOn = ctx.isOn
    local optionValue = ctx.optionValue
    local multiSelected = ctx.multiSelected
    local multiHasAny = ctx.multiHasAny
    local getLocalPlot = ctx.getLocalPlot
    local getJumpPower = ctx.getJumpPower
    local getEggTools = ctx.getEggTools
    local getFarmZone = ctx.getHighestSelectedFarmArea
    local isCarryingEgg = ctx.isCarryingEgg

    local requestFn = ctx.requestFn
    if type(requestFn) ~= "function" then
        -- Same order used by the original flattened resolver.
        requestFn = (syn and syn.request)
            or (http and http.request)
            or http_request
            or request
    end

    local sessionStartedAt = os.clock()
    local lastSummaryAt = os.clock()
    local trackingInitialized = false
    local resetBatch = {}
    local resetBatchGeneration = 0
    local knownEggs = {}

    -- Original RA slots:
    -- [1] resets, [2] eggs logged, [3] bag gained, [4] previous bag count.
    local stats = {
        Resets = 0,
        EggsLogged = 0,
        BagGained = 0,
        LastBagCount = 0,
    }

    local function embedField(name, value, inline)
        return {
            name = name,
            value = value,
            inline = inline ~= false,
        }
    end

    local function formatDuration(seconds)
        local total = math.max(0, math.floor(seconds))
        local hours = total // 3600
        local minutes = (total % 3600) // 60
        local secs = total % 60

        if hours > 0 then
            return string.format("%dh %dm", hours, minutes)
        elseif minutes > 0 then
            return string.format("%dm %ds", minutes, secs)
        end
        return string.format("%ds", secs)
    end

    local function resolvePingContent()
        if isOn("WebhookPingEveryone") then
            return "@everyone"
        end

        local option = Options.WebhookPingId
        local raw = option and option.Value or ""
        local digits = tostring(raw):gsub("%D", "")
        if digits ~= "" then
            return "<@" .. digits .. ">"
        end
        return nil
    end

    local function postWebhook(payload)
        local option = Options.WebhookUrl
        local url = option and option.Value or ""
        url = tostring(url or "")
        if url == "" or type(requestFn) ~= "function" then
            return false
        end

        local validDiscordWebhook = string.find(url, "discord.com/api/webhooks/", 1, true)
            or string.find(url, "discordapp.com/api/webhooks/", 1, true)
        if not validDiscordWebhook then
            return false
        end

        local ok, response = pcall(function()
            return requestFn({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload),
            })
        end)
        if not ok or response == nil then
            return false
        end

        local statusCode
        if type(response) == "table" then
            statusCode = tonumber(response.StatusCode or response.Status)
        end
        return statusCode ~= nil and statusCode >= 200 and statusCode < 300
    end

    local function sendEmbed(embed, allowPing)
        if not isOn("WebhookEnabled") then
            return false
        end

        local content = nil
        if allowPing then
            content = resolvePingContent()
        end

        return postWebhook({
            username = "AliceHUB",
            content = content,
            embeds = { embed },
        })
    end

    local function eggPassesWebhookFilters(egg)
        local raritySelected = multiSelected("WebhookRarities")
        local eggSelected = multiSelected("WebhookEggs")

        if multiHasAny("WebhookRarities") then
            local rarity = tostring(egg:GetAttribute("Rarity"))
            if raritySelected[rarity] ~= true then
                return false
            end
        end

        if multiHasAny("WebhookEggs") and eggSelected[egg.Name] ~= true then
            return false
        end

        return true
    end

    local function describeEgg(egg)
        local rarity = egg:GetAttribute("Rarity")
        rarity = rarity and tostring(rarity) or "?"

        local area = egg:GetAttribute("AreaName")
        area = area and tostring(area) or "?"

        local rank = rarityRanks[rarity] or 0
        local parts = {
            string.format("**%s** `%s`", egg.Name, rarity),
            area,
        }

        local sizeMultiplier = tonumber(egg:GetAttribute("SizeMultiplier"))
        if sizeMultiplier and math.abs(sizeMultiplier - 1) > 0.01 then
            parts[#parts + 1] = string.format("x%.2f", sizeMultiplier)
        end

        local growthMultiplier = tonumber(egg:GetAttribute("GrowthMultiplier"))
        if growthMultiplier and math.abs(growthMultiplier - 1) > 0.01 then
            parts[#parts + 1] = string.format("g%.2f", growthMultiplier)
        end

        return {
            Name = egg.Name,
            Rarity = rarity,
            Area = area,
            Rank = rank,
            Text = table.concat(parts, " · "),
        }
    end

    local function colorForEggEntries(entries)
        local highestRank = 0
        local color = 8141549
        for _, entry in ipairs(entries) do
            if entry.Rank > highestRank then
                highestRank = entry.Rank
                color = rarityColors[entry.Rarity] or color
            end
        end
        return color
    end

    local function groupedEggLines(entries, maxLines)
        table.sort(entries, function(a, b)
            if a.Rank == b.Rank then
                return a.Name < b.Name
            end
            return a.Rank > b.Rank
        end)

        local grouped = {}
        local rarityOrder = {}
        for _, entry in ipairs(entries) do
            local bucket = grouped[entry.Rarity]
            if not bucket then
                bucket = {}
                grouped[entry.Rarity] = bucket
                rarityOrder[#rarityOrder + 1] = entry.Rarity
            end
            bucket[#bucket + 1] = entry.Name
        end

        table.sort(rarityOrder, function(a, b)
            return (rarityRanks[a] or 0) > (rarityRanks[b] or 0)
        end)

        local limit = maxLines or 12
        local lines = {}
        local represented = 0

        for _, rarity in ipairs(rarityOrder) do
            if #lines >= limit then
                break
            end

            local names = grouped[rarity]
            local uniqueNames = {}
            local seenNames = {}
            for _, name in ipairs(names) do
                if not seenNames[name] then
                    seenNames[name] = true
                    uniqueNames[#uniqueNames + 1] = name
                end
            end

            lines[#lines + 1] = string.format(
                "`%s` **x%d** · %s",
                rarity,
                #names,
                table.concat(uniqueNames, ", ")
            )
            represented += #names
        end

        if represented < #entries then
            lines[#lines + 1] = string.format("... +%d more", #entries - represented)
        end

        return lines, represented
    end

    local function scanWorldEggs(onlyMatching)
        local result = {}
        for _, areaModel in ipairs(AreasFolder:GetChildren()) do
            local spawned = areaModel:FindFirstChild("SpawnedEggs")
            if spawned then
                for _, child in ipairs(spawned:GetChildren()) do
                    if child:IsA("Model") and (not onlyMatching or eggPassesWebhookFilters(child)) then
                        result[#result + 1] = child
                    end
                end
            end
        end
        return result
    end

    local function summarizeWorldRarities(eggs)
        local counts = {}
        for _, egg in ipairs(eggs) do
            local rarity = egg:GetAttribute("Rarity")
            rarity = rarity and tostring(rarity) or "?"
            counts[rarity] = (counts[rarity] or 0) + 1
        end

        local parts = {}
        for _, rarity in ipairs(rarityNames) do
            local count = counts[rarity]
            if count and count > 0 then
                parts[#parts + 1] = string.format("%s %d", rarity, count)
            end
        end

        for rarity, count in pairs(counts) do
            if rarityRanks[rarity] == nil then
                parts[#parts + 1] = string.format("%s %d", rarity, count)
            end
        end

        if #parts == 0 then
            return "none"
        end
        return table.concat(parts, " · ")
    end

    local function getProgressSnapshot()
        local plot = getLocalPlot()
        local placedEggs = plot and plot:FindFirstChild("PlacedEggs")
        local placedAnimals = plot and plot:FindFirstChild("PlacedAnimals")

        local bagCount = #getEggTools()
        if bagCount > stats.LastBagCount then
            stats.BagGained += bagCount - stats.LastBagCount
        end
        stats.LastBagCount = bagCount

        local cashValue = 0
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local cash = leaderstats and leaderstats:FindFirstChild("Cash")
        if cash then
            cashValue = cash.Value
        end
        local cashText = tostring(cashValue)
        if string.sub(cashText, 1, 1) ~= "$" then
            cashText = "$" .. cashText
        end

        return {
            Cash = cashText,
            Jump = getJumpPower(),
            Bag = bagCount,
            Placed = placedEggs and #placedEggs:GetChildren() or 0,
            Pets = placedAnimals and #placedAnimals:GetChildren() or 0,
            Carry = isCarryingEgg() and "Yes" or "No",
            Matching = scanWorldEggs(true),
            Zone = getFarmZone(),
        }
    end

    local function buildProgressEmbed()
        local snapshot = getProgressSnapshot()
        local described = {}
        for _, egg in ipairs(snapshot.Matching) do
            described[#described + 1] = describeEgg(egg)
        end
        local topLines = groupedEggLines(described, 10)

        local zoneName = "-"
        if snapshot.Zone then
            zoneName = snapshot.Zone.Name
        end

        local fields = {
            embedField("Cash", "`" .. snapshot.Cash .. "`"),
            embedField("Jump", "`" .. tostring(snapshot.Jump) .. "`"),
            embedField("Session", "`" .. formatDuration(os.clock() - sessionStartedAt) .. "`"),
            embedField("Bag / Placed", string.format("`%d` / `%d`", snapshot.Bag, snapshot.Placed)),
            embedField("Pets / Carry", string.format("`%d` / `%s`", snapshot.Pets, snapshot.Carry)),
            embedField("Farm Zone", "`" .. zoneName .. "`"),
            embedField(
                "Session Stats",
                string.format(
                    "Resets **%d** · Logged **%d** · Bag gained **%d**",
                    stats.Resets,
                    stats.EggsLogged,
                    stats.BagGained
                ),
                false
            ),
            embedField("World Matches", summarizeWorldRarities(snapshot.Matching), false),
        }

        if #topLines > 0 then
            fields[#fields + 1] = embedField(
                string.format("Top Matches (%d)", #snapshot.Matching),
                table.concat(topLines, "\n"),
                false
            )
        end

        return {
            author = { name = LocalPlayer.DisplayName .. " · " .. ctx.GameName },
            title = "Progress",
            color = 8141549,
            fields = fields,
            footer = { text = "AliceHUB" },
            timestamp = DateTime.now():ToIsoDate(),
        }
    end

    local function buildAndSendReset(entries)
        if #entries == 0 then
            return false
        end

        stats.Resets += 1
        stats.EggsLogged += #entries

        local topLines = groupedEggLines(entries, 14)
        local areaCounts = {}
        for _, entry in ipairs(entries) do
            areaCounts[entry.Area] = (areaCounts[entry.Area] or 0) + 1
        end

        local areaParts = {}
        for area, count in pairs(areaCounts) do
            areaParts[#areaParts + 1] = string.format("%s %d", area, count)
        end
        table.sort(areaParts)
        local areasText = #areaParts > 0 and table.concat(areaParts, " · ") or "-"

        local snapshot = getProgressSnapshot()
        local legendaryRank = rarityRanks.Legendary or 5
        local allowPing = false
        for _, entry in ipairs(entries) do
            if (entry.Rank or 0) >= legendaryRank then
                allowPing = true
                break
            end
        end

        return sendEmbed({
            author = { name = LocalPlayer.DisplayName .. " · " .. ctx.GameName },
            title = string.format("Egg Reset · %d matched", #entries),
            color = colorForEggEntries(entries),
            description = table.concat(topLines, "\n"),
            fields = {
                embedField("Areas", areasText, false),
                embedField("Cash", "`" .. snapshot.Cash .. "`"),
                embedField("Jump", "`" .. tostring(snapshot.Jump) .. "`"),
                embedField("Session", "`" .. formatDuration(os.clock() - sessionStartedAt) .. "`"),
            },
            footer = { text = "AliceHUB · egg reset" },
            timestamp = DateTime.now():ToIsoDate(),
        }, allowPing)
    end

    local function flushResetBatch()
        if #resetBatch == 0 then
            return
        end

        local batch = resetBatch
        resetBatch = {}

        if isOn("WebhookOnEggReset") and isOn("WebhookEnabled") then
            buildAndSendReset(batch)
        else
            stats.EggsLogged += #batch
        end
    end

    local function queueResetEgg(egg)
        if not isOn("WebhookEnabled") or not eggPassesWebhookFilters(egg) then
            return
        end

        resetBatch[#resetBatch + 1] = describeEgg(egg)
        resetBatchGeneration += 1
        local generation = resetBatchGeneration

        task.delay(1.75, function()
            if Library.Unloaded or generation ~= resetBatchGeneration then
                return
            end
            flushResetBatch()
        end)
    end

    local function initializeTracking()
        table.clear(knownEggs)
        for _, egg in ipairs(scanWorldEggs(false)) do
            knownEggs[egg] = true
        end
        stats.LastBagCount = #getEggTools()
        trackingInitialized = true
    end

    local function pollTracking()
        if not trackingInitialized then
            initializeTracking()
            return
        end

        local current = {}
        for _, egg in ipairs(scanWorldEggs(false)) do
            current[egg] = true
            if knownEggs[egg] == nil then
                knownEggs[egg] = true
                queueResetEgg(egg)
            end
        end

        for egg in pairs(knownEggs) do
            if not current[egg] then
                knownEggs[egg] = nil
            end
        end

        local bagCount = #getEggTools()
        if bagCount > stats.LastBagCount then
            stats.BagGained += bagCount - stats.LastBagCount
        end
        stats.LastBagCount = bagCount
    end

    local group = Tabs.Webhook:AddLeftGroupbox("Webhook")
    group:AddToggle("WebhookEnabled", { Text = "Enable Webhooks", Default = false })
    group:AddInput("WebhookUrl", {
        Text = "Webhook URL",
        Default = "",
        Finished = true,
        AllowEmpty = true,
        Placeholder = "https://discord.com/api/webhooks/...",
    })
    group:AddInput("WebhookPingId", {
        Text = "Ping User ID",
        Default = "",
        Finished = true,
        AllowEmpty = true,
        Placeholder = "Discord user id",
    })
    group:AddToggle("WebhookPingEveryone", { Text = "Ping @everyone", Default = false })
    group:AddToggle("WebhookOnEggReset", { Text = "Send on Egg Reset", Default = true })
    group:AddSlider("WebhookInterval", {
        Text = "Summary Interval",
        Default = 15,
        Min = 1,
        Max = 180,
        Rounding = 0,
        Suffix = " min",
    })

    group:AddButton({
        Text = "Send Summary Now",
        Func = function()
            task.spawn(function()
                if not isOn("WebhookEnabled") then
                    Library:Notify("Enable webhook first")
                    return
                end
                local ok = sendEmbed(buildProgressEmbed(), true)
                lastSummaryAt = os.clock()
                Library:Notify(ok and "Summary sent" or "Webhook send failed")
            end)
        end,
    })

    group:AddButton({
        Text = "Test Webhook",
        Func = function()
            local url = Options.WebhookUrl and Options.WebhookUrl.Value or ""
            if tostring(url or "") == "" then
                Library:Notify("Set a webhook URL first")
                return
            end

            local ok = postWebhook({
                username = "AliceHUB",
                content = resolvePingContent(),
                embeds = {
                    {
                        title = "Webhook Connected",
                        description = "Egg reset + progress webhooks are ready.",
                        color = 8141549,
                        fields = {
                            embedField("Player", LocalPlayer.Name),
                            embedField("Game", ctx.GameName),
                        },
                        footer = { text = "AliceHUB" },
                        timestamp = DateTime.now():ToIsoDate(),
                    },
                },
            })
            Library:Notify(ok and "Webhook test sent" or "Webhook test failed")
        end,
    })

    local filters = Tabs.Webhook:AddRightGroupbox("Filters")
    filters:AddDropdown("WebhookRarities", {
        Text = "Log Rarities",
        Values = rarityNames,
        Default = {},
        Multi = true,
        AllowEmpty = true,
    })
    filters:AddDropdown("WebhookEggs", {
        Text = "Log Specific Eggs",
        Values = eggNames,
        Default = {},
        Multi = true,
        AllowEmpty = true,
        Searchable = true,
    })

    for _, areaModel in ipairs(AreasFolder:GetChildren()) do
        local spawned = areaModel:FindFirstChild("SpawnedEggs")
        if spawned then
            spawned.ChildAdded:Connect(function(child)
                if Library.Unloaded or not child:IsA("Model") then
                    return
                end
                task.defer(function()
                    if not trackingInitialized then
                        return
                    end
                    if knownEggs[child] == nil then
                        knownEggs[child] = true
                        queueResetEgg(child)
                    end
                end)
            end)
        end
    end

    task.spawn(function()
        while not Library.Unloaded do
            task.spawn(pollTracking)

            if isOn("WebhookEnabled") then
                local minutes = tonumber(optionValue("WebhookInterval", 15)) or 15
                local intervalSeconds = math.max(minutes, 1) * 60
                if os.clock() - lastSummaryAt >= intervalSeconds then
                    lastSummaryAt = os.clock()
                    pcall(function()
                        sendEmbed(buildProgressEmbed(), false)
                    end)
                end
            end

            task.wait(1)
        end
    end)

    return {
        stats = stats,
        buildProgressEmbed = buildProgressEmbed,
        flushResetBatch = flushResetBatch,
        pollTracking = pollTracking,
    }
end


local function installSettings(ctx)
    local Library = ctx.Library
    local LocalPlayer = ctx.LocalPlayer
    local CoreGui = ctx.CoreGui
    local Workspace = ctx.Workspace
    local TeleportService = ctx.TeleportService
    local HttpService = ctx.HttpService
    local VirtualUser = ctx.VirtualUser
    local ThemeManager = ctx.ThemeManager
    local SaveManager = ctx.SaveManager
    local Toggles = ctx.Toggles
    local Options = ctx.Options

    local menu = ctx.SettingsMenuGroup or ctx.Tabs.Settings:AddLeftGroupbox("Menu")
    local performance = ctx.PerformanceGroup or ctx.Tabs.Settings:AddRightGroupbox("Performance")
    menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu keybind",
    })
    Library.ToggleKeybind = Options.MenuKeybind

    menu:AddToggle("AutoReconnect", { Text = "Auto Reconnect", Default = false })
    menu:AddToggle("AutoExecute", { Text = "Auto Execute", Default = false })

    -- The original installs these three feature blocks from the Settings builder.
    if ctx.installBoostFPS then
        ctx.installBoostFPS()
    end

    if ctx.installAliceWhiteScreen then ctx.installAliceWhiteScreen(performance) end

    -- Auto reconnect --------------------------------------------------------
    local reconnectTriggered = false

    local function performReconnect()
        local sameServerOk = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        if not sameServerOk then
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
        end
    end

    local function triggerReconnect()
        if Library.Unloaded or reconnectTriggered or not ctx.isOn("AutoReconnect") then
            return
        end
        reconnectTriggered = true
        task.delay(2, performReconnect)
    end

    task.spawn(function()
        while not Library.Unloaded do
            if ctx.isOn("AutoReconnect") then
                local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
                local overlay = promptGui and promptGui:FindFirstChild("promptOverlay")
                if overlay then
                    for _, child in ipairs(overlay:GetChildren()) do
                        if child.Name:find("ErrorPrompt") and child.Visible then
                            triggerReconnect()
                            break
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)

    -- Auto execute ----------------------------------------------------------
    local sourceUrl = tostring(ctx.sourceUrl or "")

    local queueFn = queue_on_teleport
    if not queueFn and syn then
        queueFn = syn.queue_on_teleport
    end
    if not queueFn and fluxus then
        queueFn = fluxus.queue_on_teleport
    end
    if not queueFn then
        queueFn = queueonteleport
    end

    local autoExecuteQueued = false
    local function queueAutoExecute()
        if type(queueFn) ~= "function" then
            return false
        end
        if sourceUrl == "" then
            return false
        end

        local payload = ('if not game:IsLoaded() then game.Loaded:Wait() end local env = (getgenv and getgenv()) or _G if env.AliceHUBAutoExecuted == game.JobId then return end env.AliceHUBAutoExecuted = game.JobId task.wait(3) loadstring(game:HttpGet("%s"))()')
            :format(sourceUrl)

        autoExecuteQueued = pcall(queueFn, payload)
        return autoExecuteQueued
    end

    Toggles.AutoExecute:OnChanged(function()
        if not ctx.isOn("AutoExecute") then
            return
        end
        if not queueAutoExecute() then
            Library:Notify(sourceUrl == "" and "Set AliceHUBJumpForAnimalsSourceURL for Auto Execute" or "queue_on_teleport is not supported by your executor")
        end
    end)

    LocalPlayer.OnTeleport:Connect(function(state)
        if Library.Unloaded or not ctx.isOn("AutoExecute") then
            return
        end
        if state ~= Enum.TeleportState.Started then
            return
        end
        autoExecuteQueued = false
        queueAutoExecute()
    end)

    if ctx.isOn("AutoExecute") then
        queueAutoExecute()
    end

    -- Anti-AFK --------------------------------------------------------------
    local afkTriggers = 0
    local lastAfkAction = tick()
    local afkLabel

    local function antiAfkAction()
        local camera = Workspace.CurrentCamera
        if not camera then
            return
        end

        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0), camera.CFrame)
        afkTriggers += 1
        lastAfkAction = tick()

        if afkLabel then
            task.spawn(function()
                afkLabel:SetText("AFK triggers: " .. afkTriggers)
            end)
        end
    end

    local idledConnection = LocalPlayer.Idled:Connect(function()
        if ctx.isOn("AntiAfk") then
            task.spawn(antiAfkAction)
        end
    end)

    menu:AddToggle("AntiAfk", { Text = "Anti-AFK", Default = true })
    afkLabel = menu:AddLabel("AFK triggers: 0")
    menu:AddButton({
        Text = "Unload UI",
        Func = function()
            Library:Unload()
        end,
    })

    task.spawn(function()
        while not Library.Unloaded do
            if ctx.isOn("AntiAfk") and tick() - lastAfkAction >= 60 then
                task.spawn(antiAfkAction)
            end
            task.wait(2)
        end
    end)

    Library:OnUnload(function()
        if idledConnection then
            idledConnection:Disconnect()
        end
        if getgenv then
            getgenv().__AliceHUBJumpForAnimalsLib = nil
        end
    end)

    -- Theme / SaveManager ---------------------------------------------------
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder("AliceHub")
    -- AliceHUB uses a fixed brand theme. Do not expose/apply legacy theme presets.
    ctx.applyAliceGothicTheme()

    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind", "SaveManager_ImportSource" })
    SaveManager:SetFolder("AliceHub/JumpForAnimals")

    local configBox = SaveManager:BuildConfigSection(ctx.Tabs.Settings)

    local function configElement(expectedType, index)
        local toggle = Toggles[index]
        if type(toggle) == "table" and toggle.Type == expectedType then
            return toggle
        end

        local option = Options[index]
        if type(option) == "table" and option.Type == expectedType then
            return option
        end

        return nil
    end

    local function encodeConfigObject(index, element)
        local kind = element.Type
        if kind == "Toggle" then
            return { idx = index, type = "Toggle", value = element.Value == true }
        elseif kind == "Slider" then
            return { idx = index, type = "Slider", value = tostring(element.Value) }
        elseif kind == "Dropdown" then
            return { idx = index, type = "Dropdown", multi = element.Multi == true, value = element.Value }
        elseif kind == "Input" then
            return { idx = index, type = "Input", text = tostring(element.Value or "") }
        elseif kind == "ColorPicker" then
            return {
                idx = index,
                type = "ColorPicker",
                value = element.Value:ToHex(),
                transparency = element.Transparency,
            }
        elseif kind == "KeyPicker" then
            return {
                idx = index,
                type = "KeyPicker",
                mode = element.Mode,
                key = element.Value,
                modifiers = element.Modifiers,
                toggled = element.Toggled,
            }
        end
        return nil
    end

    local function buildConfigPayload()
        local objects = {}

        for _, registry in ipairs({ Toggles, Options }) do
            for index, element in pairs(registry) do
                if type(element) == "table"
                    and type(element.Type) == "string"
                    and not SaveManager.Ignore[index]
                then
                    local object = encodeConfigObject(index, element)
                    if object then
                        objects[#objects + 1] = object
                    end
                end
            end
        end

        table.sort(objects, function(a, b)
            if a.type ~= b.type then
                return a.type < b.type
            end
            return a.idx < b.idx
        end)

        return { objects = objects }
    end

    local function applyConfigObject(object)
        if type(object) ~= "table"
            or type(object.idx) ~= "string"
            or type(object.type) ~= "string"
            or SaveManager.Ignore[object.idx]
        then
            return false
        end

        local element = configElement(object.type, object.idx)
        if not element then
            return false
        end

        return pcall(function()
            if object.type == "Input" then
                if type(object.text) ~= "string" then
                    return
                end
                element:SetValue(object.text)
            elseif object.type == "ColorPicker" then
                element:SetValueRGB(Color3.fromHex(object.value), object.transparency)
            elseif object.type == "KeyPicker" then
                element:SetValue({ object.key, object.mode, object.modifiers })
                if object.mode == "Toggle" and object.toggled ~= nil then
                    element.Toggled = object.toggled
                    element:Update()
                end
            else
                element:SetValue(object.value)
            end
        end)
    end

    configBox:AddDivider()
    configBox:AddInput("SaveManager_ImportSource", {
        Text = "Paste exported config here",
        Finished = true,
        AllowEmpty = true,
    })

    configBox:AddButton({
        Text = "Export Config to Clipboard",
        Func = function()
            local ok, encoded = pcall(HttpService.JSONEncode, HttpService, buildConfigPayload())
            if not ok then
                Library:Notify("Failed to encode the config")
                return
            end

            local copyFn = setclipboard or toclipboard
            if type(copyFn) ~= "function" then
                Library:Notify("Your executor does not support copying to the clipboard")
                return
            end

            if not pcall(copyFn, encoded) then
                Library:Notify("Your executor does not support copying to the clipboard")
                return
            end

            Library:Notify("Config copied to clipboard", 6)
        end,
    })

    configBox:AddButton({
        Text = "Import Config from Clipboard Text",
        Func = function()
            local raw = Options.SaveManager_ImportSource and Options.SaveManager_ImportSource.Value
            local trimmed = tostring(raw or ""):match("^%s*(.-)%s*$")
            if trimmed == "" then
                Library:Notify("Paste an exported config into the box first")
                return
            end

            local ok, decoded = pcall(HttpService.JSONDecode, HttpService, trimmed)
            if not ok or type(decoded) ~= "table" or type(decoded.objects) ~= "table" then
                Library:Notify("That is not a valid exported config")
                return
            end

            local imported = 0
            for _, object in ipairs(decoded.objects) do
                if applyConfigObject(object) then
                    imported += 1
                end
            end

            if imported == 0 then
                Library:Notify("No settings in that config matched this script")
                return
            end

            Options.SaveManager_ImportSource:SetValue("")
            Library:Notify(("Imported %d setting%s"):format(imported, imported == 1 and "" or "s"), 6)
        end,
    })

    return {
        performReconnect = performReconnect,
        triggerReconnect = triggerReconnect,
        queueAutoExecute = queueAutoExecute,
        antiAfkAction = antiAfkAction,
        configElement = configElement,
        encodeConfigObject = encodeConfigObject,
        buildConfigPayload = buildConfigPayload,
        applyConfigObject = applyConfigObject,
    }
end


-- Source: pooled worker #244

local function mainStatusLoop(ctx)
    local Library = assert(ctx.Library)
    local LocalPlayer = assert(ctx.LocalPlayer)

    local function isOn(name)
        return ctx.isOn(name)
    end

    local function anyAutomationEnabled()
        return isOn("AutoCollectSelected")
            or isOn("AutoCollectAll")
            or isOn("AutoPlaceEggs")
            or isOn("AutoHatchEggs")
            or isOn("AutoSell")
            or isOn("AutoBuyTrails")
            or isOn("AutoBuyCoil")
            or isOn("AutoEquipBest")
            or isOn("AutoUpgradePlot")
            or isOn("AutoClaimIndex")
            or isOn("AutoGoTrain")
            or isOn("Auto2x")
    end

    while not Library.Unloaded do
        local selectedArea = ctx.getHighestSelectedFarmArea()
        local plot = ctx.getLocalPlot()

        local placedEggs = plot and plot:FindFirstChild("PlacedEggs")
        local placedAnimals = plot and plot:FindFirstChild("PlacedAnimals")

        local placedCount = placedEggs and #placedEggs:GetChildren() or 0
        local petCount = placedAnimals and #placedAnimals:GetChildren() or 0

        local readyCount = 0
        if placedEggs then
            for _, child in ipairs(placedEggs:GetChildren()) do
                if child:IsA("Model") and ctx.isHatchReady(child) then
                    readyCount += 1
                end
            end
        end

        local worldCount = 0
        if selectedArea then
            local areaModel = ctx.getAreaModelByName(selectedArea.Name)
            local spawnedEggs = areaModel and areaModel:FindFirstChild("SpawnedEggs")
            worldCount = spawnedEggs and #spawnedEggs:GetChildren() or 0
        end

        -- Busy workers preserve the worker-written status even if its toggle was
        -- switched off while the worker is finishing. Otherwise, if no automation
        -- is enabled, the original forces the shared status back to Idle.
        local busy = ctx.isCollectBusy() or ctx.isPlacingBusy() or ctx.isHatchingBusy() or ctx.isSellingBusy()
        local action
        if busy or anyAutomationEnabled() then
            action = ctx.getActionStatus()
        else
            ctx.setActionStatus("Idle")
            action = "Idle"
        end

        local cash = 0
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local cashObject = leaderstats and leaderstats:FindFirstChild("Cash")
        if cashObject then
            cash = cashObject.Value
        end
        local cashText = tostring(cash)
        if cashText:sub(1, 1) ~= "$" then
            cashText = "$" .. cashText
        end

        local maxSlots = ctx.getMaximumIncubatingEggs()
        local eggStatus = string.format(
            "bag %d | %d/%d spots | ready %d | world %d",
            #ctx.getEggTools(),
            placedCount,
            maxSlots,
            readyCount,
            worldCount
        )
        if placedCount >= maxSlots then
            eggStatus ..= " | FULL"
        end

        local zoneName = selectedArea and selectedArea.Name or "-"
        local carryingText = ctx.isCarryingEgg() and "Yes" or "No"

        ctx.ActionLabel:SetText(ctx.formatSingleStatus("Action", action))
        ctx.ZoneLabel:SetText(ctx.formatDualStatus("Zone", zoneName, "Jump", tostring(ctx.getJumpPower())))
        ctx.CashLabel:SetText(ctx.formatDualStatus("Cash", cashText, "Carry", carryingText))
        ctx.EggsLabel:SetText(ctx.formatSingleStatus("Eggs", eggStatus, ctx.eggAccentA, ctx.eggAccentB))
        ctx.PetsLabel:SetText(ctx.formatSingleStatus("Pets", tostring(petCount)))

        task.wait(0.25)
    end
end


local ctx = bootstrap()
local function expose(module)
    for key, value in pairs(module or {}) do
        if ctx[key] == nil then ctx[key] = value end
    end
end
local farm = installFarm(ctx); expose(farm)
local lifecycle = installLifecycle(ctx); expose(lifecycle)
local shopSell = installShopSell(ctx); expose(shopSell)
local serverHop = installServerHop(ctx); expose(serverHop)
ctx.ServerHopGroup:AddButton({ Text = "Hop Now", Func = serverHop.manualHop })
local movement = installMovement(ctx); expose(movement)
local info = installInfo(ctx); expose(info)
local webhook = installWebhook(ctx); expose(webhook)
local settingsModule = installSettings(ctx); expose(settingsModule)
local visual = installVisual(ctx); expose(visual)
-- AliceHUB automatic config persistence.
-- Create/select a dedicated autoload config first, then load it immediately.
local function getOrCreateJumpAutoloadConfig()
    local SaveManager = ctx.SaveManager
    if type(SaveManager) ~= "table" then return nil end

    local defaultName = "AliceHUB_Auto"
    local name = nil
    local ok = false

    if type(SaveManager.GetAutoloadConfig) == "function" then
        pcall(function()
            local current, success = SaveManager:GetAutoloadConfig()
            if success and type(current) == "string" and current ~= "" and current ~= "none" then
                name = current
                ok = true
            end
        end)
    end

    if ok and name then return name end

    name = defaultName
    pcall(function()
        SaveManager:Save(name)
        if type(SaveManager.SaveAutoloadConfig) == "function" then
            SaveManager:SaveAutoloadConfig(name)
        end
    end)
    return name
end

local function installAliceAutoSave()
    local SaveManager = ctx.SaveManager
    local Library = ctx.Library
    if type(SaveManager) ~= "table" or type(SaveManager.Save) ~= "function" then
        return
    end

    local generation = 0
    local function scheduleAutoSave()
        if Library.Unloaded then return end
        generation += 1
        local ticket = generation
        task.delay(0.60, function()
            if Library.Unloaded or ticket ~= generation then return end
            local name = getOrCreateJumpAutoloadConfig()
            if name then
                pcall(function() SaveManager:Save(name) end)
            end
        end)
    end

    local function hookRegistry(registry)
        for index, element in pairs(registry or {}) do
            if not SaveManager.Ignore[index]
                and not tostring(index):find("^SaveManager_")
                and type(element) == "table"
                and type(element.OnChanged) == "function"
            then
                pcall(function() element:OnChanged(scheduleAutoSave) end)
            end
        end
    end

    hookRegistry(ctx.Toggles)
    hookRegistry(ctx.Options)
end

getOrCreateJumpAutoloadConfig()
task.wait(0.20)
pcall(function() ctx.SaveManager:LoadAutoloadConfig() end)
task.wait(0.15)
installAliceAutoSave()

-- Final AliceHUB gothic color lock. Theme/config builders may register UI objects
-- after the initial scheme assignment, so repaint once everything exists.
ctx.hardRepaintAliceUI()
task.spawn(function()
    local deadlines = { 0.05, 0.15, 0.35, 0.75, 1.5, 3.0 }
    local previousTime = 0
    for _, targetTime in ipairs(deadlines) do
        task.wait(targetTime - previousTime)
        previousTime = targetTime
        if ctx.Library.Unloaded then return end
        ctx.hardRepaintAliceUI()
    end
end)
local squatConnection = ctx.LocalPlayer:GetAttributeChangedSignal("SquatBonusAvailable"):Connect(lifecycle.onSquatBonusAvailable)
ctx.Library:OnUnload(function()
    if squatConnection then squatConnection:Disconnect(); squatConnection = nil end
    if ctx.stopAliceWhiteScreen then pcall(ctx.stopAliceWhiteScreen) end
    pcall(function()
        if ctx.aliceLogoGui then ctx.aliceLogoGui:Destroy() end
    end)
end)
task.spawn(farm.scheduler)
task.spawn(lifecycle.placementHatchScheduler)
task.spawn(lifecycle.trainingScheduler)
task.spawn(shopSell.scheduler)
task.spawn(serverHop.monitorLoop)
task.spawn(function() mainStatusLoop(ctx) end)
