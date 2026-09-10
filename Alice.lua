-- AliceHUB v3.0.3 · Register-Safe TEST · stealachicken.lua
-- Late chunk-scope helpers moved into Runtime namespace for executor compiler compatibility.
-- Logic/UI behavior intentionally unchanged.

--[[
    AliceHUB · Steal a Chicken
    PlaceId: 76503495566299

    Native AliceHUB / SAE UI renderer.
    Backend reconstructed from the client dump supplied for Steal a Chicken.
    V1.7 · AUTO STORE HELD FIX]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local ENV = (getgenv and getgenv()) or _G
if type(ENV.AliceHUB_StealAChicken_Cleanup) == "function" then
    pcall(ENV.AliceHUB_StealAChicken_Cleanup)
    task.wait(0.08)
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

local function buildAliceNativeLibrary(gameName, guiName, iconAsset)
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local PlayersSvc = game:GetService("Players")
    local LP = PlayersSvc.LocalPlayer
    local resolvedGameName = tostring(gameName or "Steal An Egg")
    local resolvedGuiName = tostring(guiName or "AliceHUB_SAE_NativeUI")
    local resolvedIconAsset = iconAsset

    local L = {
        Toggles = {},
        Options = {},
        Scheme = {
            BackgroundColor = Color3.fromRGB(11, 9, 11),
            MainColor = Color3.fromRGB(24, 15, 19),
            AccentColor = Color3.fromRGB(181, 48, 83),
            OutlineColor = Color3.fromRGB(63, 34, 44),
            FontColor = Color3.fromRGB(242, 236, 239),
            RedColor = Color3.fromRGB(202, 55, 79),
            DestructiveColor = Color3.fromRGB(132, 30, 49),
            DarkColor = Color3.fromRGB(7, 6, 7),
            WhiteColor = Color3.fromRGB(242, 236, 239),
        },
        Toggled = true,
        _native = true,
    }

    -- SAE / Delta: keep the main menu in PlayerGui, matching Anime Dice V7 exactly.
    -- The floating logo can live in gethui, but the full menu was not rendering there.
    local function rootGui()
        return LP:WaitForChild("PlayerGui")
    end

    local root = rootGui()
    local old = root:FindFirstChild(resolvedGuiName)
    if old then pcall(function() old:Destroy() end) end

    local screen = Instance.new("ScreenGui")
    screen.Name = resolvedGuiName
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.Enabled = true
    screen.DisplayOrder = 999999
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local okParent = pcall(function()
        screen.Parent = root
    end)
    if not okParent or not screen.Parent then
        error("AliceHUB: failed to parent native UI into PlayerGui")
    end

    L.ScreenGui = screen

    local function corner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 4)
        c.Parent = parent
        return c
    end

    local function stroke(parent, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color or L.Scheme.OutlineColor
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0
        s.Parent = parent
        return s
    end

    local function padding(parent, l, r, t, b)
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, l or 0)
        p.PaddingRight = UDim.new(0, r or 0)
        p.PaddingTop = UDim.new(0, t or 0)
        p.PaddingBottom = UDim.new(0, b or 0)
        p.Parent = parent
        return p
    end

    local function newText(parent, text, size, bold)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Text = tostring(text or "")
        label.TextColor3 = L.Scheme.FontColor
        label.TextSize = size or 13
        label.Font = bold and Enum.Font.Code or Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.RichText = false
        label.Parent = parent
        return label
    end

    local function mkOption(initial)
        local option = {Value = initial, _callbacks = {}}
        function option:OnChanged(fn)
            if type(fn) == "function" then self._callbacks[#self._callbacks + 1] = fn end
            return self
        end
        function option:_emit()
            for _, fn in ipairs(self._callbacks) do pcall(fn, self.Value) end
        end
        function option:SetValue(value)
            self.Value = value
            if self._render then pcall(self._render, value) end
            self:_emit()
        end
        function option:SetAndFire(value) self:SetValue(value) end
        return option
    end

    local currentPopup
    local currentPopupOwner
    local currentPopupOverlay

    local function closePopup()
        if currentPopup and currentPopup.Parent then
            currentPopup:Destroy()
        end
        if currentPopupOverlay and currentPopupOverlay.Parent then
            currentPopupOverlay:Destroy()
        end
        currentPopup = nil
        currentPopupOwner = nil
        currentPopupOverlay = nil
    end

    function L:Notify(cfg)
        cfg = cfg or {}
        local toast = Instance.new("Frame")
        toast.AnchorPoint = Vector2.new(1, 0)
        toast.Position = UDim2.new(1, -16, 0, 22)
        toast.Size = UDim2.fromOffset(290, 68)
        toast.BackgroundColor3 = L.Scheme.MainColor
        toast.BorderSizePixel = 0
        toast.ZIndex = 1000
        toast.Parent = screen
        corner(toast, 7)
        stroke(toast, L.Scheme.AccentColor, 1.5, 0.15)
        local title = newText(toast, cfg.Title or "AliceHUB", 15, true)
        title.Position = UDim2.fromOffset(12, 7)
        title.Size = UDim2.new(1, -24, 0, 22)
        title.TextColor3 = L.Scheme.AccentColor
        local body = newText(toast, cfg.Description or cfg.Content or cfg.Body or "", 12, false)
        body.Position = UDim2.fromOffset(12, 29)
        body.Size = UDim2.new(1, -24, 0, 32)
        body.TextWrapped = true
        task.delay(tonumber(cfg.Time or cfg.Duration) or 3, function()
            if toast and toast.Parent then pcall(function() toast:Destroy() end) end
        end)
        return toast
    end

    function L:Toggle(force)
        if force == nil then L.Toggled = not L.Toggled else L.Toggled = force == true end
        if L.WindowContainer then L.WindowContainer.Visible = L.Toggled end
    end

    function L:CreateWindow(cfg)
        cfg = cfg or {}
        local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
        local target = cfg.Size or UDim2.fromOffset(760, 540)
        local targetW = math.min(target.X.Offset > 0 and target.X.Offset or 760, math.max(560, viewport.X - 70))
        local targetH = math.min(target.Y.Offset > 0 and target.Y.Offset or 540, math.max(400, viewport.Y - 60))

        local main = Instance.new("Frame")
        main.Name = "AliceHUBWindow"
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.Position = UDim2.fromScale(0.5, 0.5)
        main.Size = UDim2.fromOffset(targetW, targetH)
        main.BackgroundColor3 = L.Scheme.BackgroundColor
        main.BorderSizePixel = 0
        main.Visible = true
        main.ZIndex = 5
        main.Parent = screen
        corner(main, cfg.CornerRadius or 4)
        stroke(main, L.Scheme.OutlineColor, 1, 0.05)
        L.WindowContainer = main

        local top = Instance.new("Frame")
        top.Name = "Topbar"
        top.Size = UDim2.new(1, 0, 0, 52)
        top.BackgroundColor3 = L.Scheme.MainColor
        top.BorderSizePixel = 0
        top.Parent = main
        corner(top, 4)

        local iconHolder = Instance.new("Frame")
        iconHolder.Position = UDim2.fromOffset(12, 9)
        iconHolder.Size = UDim2.fromOffset(34, 34)
        iconHolder.BackgroundColor3 = Color3.fromRGB(20, 12, 16)
        iconHolder.BorderSizePixel = 0
        iconHolder.Parent = top
        corner(iconHolder, 8)
        stroke(iconHolder, L.Scheme.AccentColor, 1.2, 0.2)

        local iconFallback = newText(iconHolder, "A", 18, true)
        iconFallback.Size = UDim2.fromScale(1, 1)
        iconFallback.TextXAlignment = Enum.TextXAlignment.Center
        iconFallback.TextColor3 = L.Scheme.AccentColor

        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.fromScale(1, 1)
        icon.Image = resolvedIconAsset or ""
        icon.ImageTransparency = resolvedIconAsset and 0 or 1
        icon.ScaleType = Enum.ScaleType.Crop
        icon.Parent = iconHolder
        __aliceRegisterLogoTarget(icon, iconFallback)
        corner(icon, 8)
        iconFallback.Visible = not (resolvedIconAsset ~= nil)
        if resolvedIconAsset then
            icon.ImageTransparency = 0
            iconFallback.Visible = false
        end

        local title = newText(top, (cfg.Title or "AliceHUB") .. " ", 18, true)
        title.Name = "AliceHUBMainTitle"
        title.Position = UDim2.fromOffset(56, 6)
        title.Size = UDim2.new(1, -118, 0, 23)
        title.TextColor3 = L.Scheme.FontColor

        local subtitle = newText(top, resolvedGameName, 11, false)
        subtitle.Name = "AliceHUBSubtitle"
        subtitle.Position = UDim2.fromOffset(56, 28)
        subtitle.Size = UDim2.new(1, -118, 0, 17)
        subtitle.TextColor3 = Color3.fromRGB(180, 126, 143)
        subtitle.TextTransparency = 0.08

        local hide = Instance.new("TextButton")
        hide.AnchorPoint = Vector2.new(1, 0.5)
        hide.Position = UDim2.new(1, -12, 0.5, 0)
        hide.Size = UDim2.fromOffset(32, 30)
        hide.BackgroundColor3 = Color3.fromRGB(33, 20, 25)
        hide.BorderSizePixel = 0
        hide.Text = "—"
        hide.TextColor3 = L.Scheme.FontColor
        hide.TextSize = 18
        hide.Font = Enum.Font.Code
        hide.Parent = top
        corner(hide, 5)
        local hideBusy = false
        local function hideNow()
            if hideBusy then return end
            hideBusy = true
            main.Visible = false
            L.Toggled = false
            if type(getgenv) == "function" then getgenv().AliceHUB_MainWindowVisible = false end
            task.delay(0.12, function() hideBusy = false end)
        end
        hide.Activated:Connect(hideNow)
        hide.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                hideNow()
            end
        end)

        local tabRail = Instance.new("Frame")
        tabRail.Position = UDim2.fromOffset(0, 52)
        tabRail.Size = UDim2.new(0, 142, 1, -82)
        tabRail.BackgroundColor3 = Color3.fromRGB(15, 11, 13)
        tabRail.BorderSizePixel = 0
        tabRail.Parent = main
        padding(tabRail, 8, 8, 10, 8)
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Padding = UDim.new(0, 6)
        tabLayout.Parent = tabRail

        local body = Instance.new("Frame")
        body.Position = UDim2.fromOffset(142, 52)
        body.Size = UDim2.new(1, -142, 1, -82)
        body.BackgroundTransparency = 1
        body.Parent = main

        local footer = Instance.new("Frame")
        footer.AnchorPoint = Vector2.new(0, 1)
        footer.Position = UDim2.new(0, 0, 1, 0)
        footer.Size = UDim2.new(1, 0, 0, 30)
        footer.BackgroundColor3 = L.Scheme.MainColor
        footer.BorderSizePixel = 0
        footer.Parent = main
        local footText = newText(footer, "AliceHUB   |   " .. resolvedGameName, 11, false)
        footText.Position = UDim2.fromOffset(12, 0)
        footText.Size = UDim2.new(1, -24, 1, 0)
        footText.TextColor3 = Color3.fromRGB(180, 126, 143)

        -- drag window from topbar
        local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        top.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
        end)
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging and dragStart and startPos then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        local window = {_main = main, _tabs = {}, _active = nil}
        function window:Show()
            L.Toggled = true
            main.Visible = true
            if L.WindowContainer then L.WindowContainer.Visible = true end
        end
        function window:Hide()
            L.Toggled = false
            main.Visible = false
            if L.WindowContainer then L.WindowContainer.Visible = false end
        end
        function window:SetVisible(v)
            if v then self:Show() else self:Hide() end
        end

        local function activate(tabObj)
            closePopup()
            if window._active == tabObj then return end
            for _, t in ipairs(window._tabs) do
                t._content.Visible = false
                t._button.BackgroundColor3 = Color3.fromRGB(21, 15, 18)
                t._button.TextColor3 = Color3.fromRGB(190, 180, 185)
            end
            tabObj._content.Visible = true
            tabObj._button.BackgroundColor3 = Color3.fromRGB(49, 23, 32)
            tabObj._button.TextColor3 = L.Scheme.FontColor
            window._active = tabObj
        end

        local function makeGroup(column, groupTitle)
            local group = Instance.new("Frame")
            group.Size = UDim2.new(1, -2, 0, 0)
            group.AutomaticSize = Enum.AutomaticSize.Y
            group.BackgroundColor3 = L.Scheme.MainColor
            group.BorderSizePixel = 0
            group.Parent = column
            corner(group, 5)
            stroke(group, L.Scheme.OutlineColor, 1, 0.12)
            padding(group, 9, 9, 8, 9)
            local layout = Instance.new("UIListLayout")
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 6)
            layout.Parent = group

            local header = newText(group, groupTitle or "Section", 13, true)
            header.Size = UDim2.new(1, 0, 0, 22)
            header.TextColor3 = Color3.fromRGB(218, 178, 190)

            local G = {}
            function G:AddLabel(text, wrap)
                local label = newText(group, text, 12, false)
                label.Size = UDim2.new(1, 0, 0, wrap and 38 or 24)
                label.TextWrapped = wrap == true
                label.TextYAlignment = Enum.TextYAlignment.Top
                local wrapper = {_label = label}
                function wrapper:SetText(value)
                    if label and label.Parent then label.Text = tostring(value or "") end
                end
                return wrapper
            end

            function G:AddButton(conf)
                conf = conf or {}
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 0, 30)
                b.BackgroundColor3 = Color3.fromRGB(35, 23, 28)
                b.BorderSizePixel = 0
                b.Text = tostring(conf.Text or conf.Title or "Button")
                b.TextColor3 = L.Scheme.FontColor
                b.TextSize = 12
                b.Font = Enum.Font.Code
                b.Parent = group
                corner(b, 4)
                stroke(b, Color3.fromRGB(78, 41, 53), 1, 0.25)
                b.Activated:Connect(function()
                    local fn = conf.Func or conf.Callback
                    if type(fn) ~= "function" then return end

                    local ok, err = xpcall(fn, function(reason)
                        local message = tostring(reason)
                        pcall(function()
                            if debug and type(debug.traceback) == "function" then
                                message = debug.traceback(message, 2)
                            end
                        end)
                        return message
                    end)

                    if not ok then
                        warn("[AliceHUB/Button] " .. tostring(err))
                        pcall(function()
                            L:Notify({
                                Title = "AliceHUB · Button Error",
                                Description = tostring(err):sub(1, 240),
                                Time = 7,
                            })
                        end)
                    end
                end)
                return b
            end

            function G:AddToggle(id, conf)
                conf = conf or {}
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundColor3 = Color3.fromRGB(27, 18, 22)
                row.BorderSizePixel = 0
                row.Text = ""
                row.Parent = group
                corner(row, 4)
                local txt = newText(row, conf.Text or id, 12, false)
                txt.Position = UDim2.fromOffset(8, 0)
                txt.Size = UDim2.new(1, -46, 1, 0)
                local box = Instance.new("Frame")
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.Position = UDim2.new(1, -7, 0.5, 0)
                box.Size = UDim2.fromOffset(22, 18)
                box.BackgroundColor3 = Color3.fromRGB(45, 31, 37)
                box.BorderSizePixel = 0
                box.Parent = row
                corner(box, 9)
                local dot = Instance.new("Frame")
                dot.AnchorPoint = Vector2.new(0.5, 0.5)
                dot.Size = UDim2.fromOffset(12, 12)
                dot.BorderSizePixel = 0
                dot.Parent = box
                corner(dot, 6)
                local opt = mkOption(conf.Default == true)
                local function render(v)
                    box.BackgroundColor3 = v and Color3.fromRGB(91, 28, 48) or Color3.fromRGB(45, 31, 37)
                    dot.BackgroundColor3 = v and L.Scheme.AccentColor or Color3.fromRGB(118, 103, 110)
                    dot.Position = v and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)
                end
                opt._render = render; render(opt.Value)
                L.Toggles[id] = opt
                row.Activated:Connect(function() opt:SetValue(not opt.Value) end)
                return opt
            end

            function G:AddInput(id, conf)
                conf = conf or {}

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 52)
                row.BackgroundColor3 = Color3.fromRGB(27, 18, 22)
                row.BorderSizePixel = 0
                row.Parent = group
                corner(row, 4)

                local txt = newText(row, conf.Text or id, 11, false)
                txt.Position = UDim2.fromOffset(8, 2)
                txt.Size = UDim2.new(1, -16, 0, 20)

                local box = Instance.new("TextBox")
                box.Position = UDim2.fromOffset(8, 25)
                box.Size = UDim2.new(1, -16, 0, 21)
                box.BackgroundColor3 = Color3.fromRGB(35, 23, 28)
                box.BorderSizePixel = 0
                box.TextColor3 = L.Scheme.FontColor
                box.PlaceholderColor3 = Color3.fromRGB(128, 108, 116)
                box.PlaceholderText = tostring(conf.Placeholder or "")
                box.Text = tostring(conf.Default or "")
                box.TextSize = 11
                box.Font = Enum.Font.Code
                box.ClearTextOnFocus = false
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Parent = row
                corner(box, 3)
                padding(box, 6, 6, 0, 0)

                local opt = mkOption(tostring(conf.Default or ""))
                local syncingText = false

                local function render(v)
                    local value = tostring(v or "")
                    if box.Text ~= value then
                        syncingText = true
                        box.Text = value
                        syncingText = false
                    end
                end

                opt._render = render
                render(opt.Value)
                L.Options[id] = opt

                -- Keep option/state synced immediately while typing or pasting.
                -- This fixes mobile where "Send Test" could run before FocusLost.
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    if syncingText then return end
                    opt:SetValue(box.Text)
                end)

                box.FocusLost:Connect(function()
                    opt:SetValue(box.Text)
                end)

                return opt
            end

            function G:AddSlider(id, conf)
                conf = conf or {}
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 48)
                row.BackgroundColor3 = Color3.fromRGB(27, 18, 22)
                row.BorderSizePixel = 0
                row.Parent = group
                corner(row, 4)
                local txt = newText(row, conf.Text or id, 12, false)
                txt.Position = UDim2.fromOffset(8, 2)
                txt.Size = UDim2.new(0.62, 0, 0, 21)
                local valueText = newText(row, "", 11, false)
                valueText.AnchorPoint = Vector2.new(1, 0)
                valueText.Position = UDim2.new(1, -8, 0, 2)
                valueText.Size = UDim2.new(0.35, 0, 0, 21)
                valueText.TextXAlignment = Enum.TextXAlignment.Right
                local bar = Instance.new("TextButton")
                bar.Position = UDim2.fromOffset(8, 29)
                bar.Size = UDim2.new(1, -16, 0, 9)
                bar.BackgroundColor3 = Color3.fromRGB(52, 34, 41)
                bar.BorderSizePixel = 0
                bar.Text = ""
                bar.Parent = row
                corner(bar, 5)
                local fill = Instance.new("Frame")
                fill.Size = UDim2.fromScale(0, 1)
                fill.BackgroundColor3 = L.Scheme.AccentColor
                fill.BorderSizePixel = 0
                fill.Parent = bar
                corner(fill, 5)
                local minV, maxV = tonumber(conf.Min) or 0, tonumber(conf.Max) or 100
                local rounding = tonumber(conf.Rounding) or 0
                local suffix = tostring(conf.Suffix or "")
                local opt = mkOption(tonumber(conf.Default) or minV)
                local function normalize(v)
                    v = math.clamp(tonumber(v) or minV, minV, maxV)
                    local p = 10 ^ rounding
                    return math.floor(v * p + 0.5) / p
                end
                local function render(v)
                    v = normalize(v)
                    local alpha = maxV == minV and 0 or (v - minV) / (maxV - minV)
                    fill.Size = UDim2.fromScale(alpha, 1)
                    valueText.Text = tostring(v) .. suffix
                end
                local oldSet = opt.SetValue
                function opt:SetValue(v) oldSet(self, normalize(v)) end
                opt._render = render; render(opt.Value)
                L.Options[id] = opt
                local function setFromX(x)
                    local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                    opt:SetValue(minV + (maxV - minV) * alpha)
                end
                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setFromX(input.Position.X) end
                end)
                bar.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or input.UserInputType == Enum.UserInputType.Touch then setFromX(input.Position.X) end
                    end
                end)
                return opt
            end

            function G:AddDropdown(id, conf)
                conf = conf or {}
                local values = conf.Values or {}
                local multi = conf.Multi == true
                local initial = conf.Default
                if multi and type(initial) ~= "table" then initial = {} end
                if not multi and initial == nil then initial = values[1] end
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, 0, 0, 34)
                row.BackgroundColor3 = Color3.fromRGB(27, 18, 22)
                row.BorderSizePixel = 0
                row.Text = ""
                row.Parent = group
                corner(row, 4)
                local txt = newText(row, conf.Text or id, 11, false)
                txt.Position = UDim2.fromOffset(8, 0)
                txt.Size = UDim2.new(0.43, -4, 1, 0)
                local selected = newText(row, "", 11, false)
                selected.Position = UDim2.new(0.43, 2, 0, 0)
                selected.Size = UDim2.new(0.57, -28, 1, 0)
                selected.TextXAlignment = Enum.TextXAlignment.Right
                selected.TextColor3 = Color3.fromRGB(218, 178, 190)
                local arrow = newText(row, "v", 11, true)
                arrow.AnchorPoint = Vector2.new(1, 0)
                arrow.Position = UDim2.new(1, -8, 0, 0)
                arrow.Size = UDim2.fromOffset(16, 34)
                arrow.TextXAlignment = Enum.TextXAlignment.Center
                local opt = mkOption(initial)
                opt.Values = values
                local function summary(v)
                    if multi then
                        local names = {}
                        for _, name in ipairs(opt.Values or {}) do if type(v) == "table" and v[name] == true then names[#names+1] = name end end
                        return #names == 0 and "None" or (#names <= 2 and table.concat(names, ", ") or tostring(#names) .. " selected")
                    end
                    return tostring(v or "None")
                end
                local function render(v) selected.Text = summary(v) end
                opt._render = render; render(opt.Value)
                function opt:SetValues(newValues)
                    self.Values = newValues or {}
                    if not multi and self.Value ~= nil then
                        local ok = false
                        for _, v in ipairs(self.Values) do if v == self.Value then ok = true break end end
                        if not ok and self.Values[1] then self:SetValue(self.Values[1]) end
                    end
                    render(self.Value)
                end
                L.Options[id] = opt
                row.Activated:Connect(function()
                    -- Tapping the same dropdown again now closes it.
                    if currentPopup and currentPopupOwner == row then
                        closePopup()
                        return
                    end

                    closePopup()

                    -- Transparent click-catcher behind the popup.
                    local overlay = Instance.new("TextButton")
                    overlay.Name = "AliceHUBPopupDismiss"
                    overlay.Size = UDim2.fromScale(1, 1)
                    overlay.BackgroundTransparency = 1
                    overlay.Text = ""
                    overlay.ZIndex = 898
                    overlay.Parent = screen
                    overlay.Activated:Connect(closePopup)

                    local popup = Instance.new("Frame")
                    popup.BackgroundColor3 = Color3.fromRGB(20, 14, 17)
                    popup.BorderSizePixel = 0
                    popup.ZIndex = 900
                    popup.Parent = screen
                    corner(popup, 5)
                    stroke(popup, L.Scheme.AccentColor, 1, 0.25)

                    local count = math.min(#(opt.Values or {}), 8)
                    local popupHeight = math.max(70, count * 30 + 42)
                    popup.Size = UDim2.fromOffset(
                        math.max(190, row.AbsoluteSize.X),
                        popupHeight
                    )

                    local abs = row.AbsolutePosition
                    local y = abs.Y + row.AbsoluteSize.Y + 2
                    if y + popupHeight > viewport.Y - 20 then
                        y = math.max(20, abs.Y - popupHeight - 2)
                    end
                    popup.Position = UDim2.fromOffset(abs.X, y)

                    local header = Instance.new("Frame")
                    header.Size = UDim2.new(1, 0, 0, 32)
                    header.BackgroundColor3 = Color3.fromRGB(31, 19, 24)
                    header.BorderSizePixel = 0
                    header.ZIndex = 903
                    header.Parent = popup
                    corner(header, 5)

                    local headerText = newText(header, tostring(conf.Text or "Select"), 11, true)
                    headerText.Position = UDim2.fromOffset(8, 0)
                    headerText.Size = UDim2.new(1, -44, 1, 0)
                    headerText.ZIndex = 904
                    headerText.TextColor3 = Color3.fromRGB(218, 178, 190)

                    local closeBtn = Instance.new("TextButton")
                    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
                    closeBtn.Position = UDim2.new(1, -6, 0.5, 0)
                    closeBtn.Size = UDim2.fromOffset(26, 24)
                    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 28, 44)
                    closeBtn.BorderSizePixel = 0
                    closeBtn.Text = "×"
                    closeBtn.TextColor3 = Color3.fromRGB(255, 238, 243)
                    closeBtn.TextSize = 17
                    closeBtn.Font = Enum.Font.Code
                    closeBtn.ZIndex = 905
                    closeBtn.Parent = header
                    corner(closeBtn, 4)
                    closeBtn.Activated:Connect(closePopup)

                    local scroll = Instance.new("ScrollingFrame")
                    scroll.Position = UDim2.fromOffset(5, 37)
                    scroll.Size = UDim2.new(1, -10, 1, -42)
                    scroll.BackgroundTransparency = 1
                    scroll.BorderSizePixel = 0
                    scroll.ScrollBarThickness = 3
                    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                    scroll.CanvasSize = UDim2.new()
                    scroll.ZIndex = 901
                    scroll.Parent = popup

                    local lay = Instance.new("UIListLayout")
                    lay.Padding = UDim.new(0, 3)
                    lay.Parent = scroll

                    for _, name in ipairs(opt.Values or {}) do
                        local item = Instance.new("TextButton")
                        item.Size = UDim2.new(1, -2, 0, 27)
                        item.BorderSizePixel = 0
                        item.TextSize = 11
                        item.Font = Enum.Font.Code
                        item.ZIndex = 902
                        item.Parent = scroll
                        corner(item, 3)

                        local itemStroke = Instance.new("UIStroke")
                        itemStroke.Thickness = 1
                        itemStroke.Parent = item

                        local function itemIsSelected()
                            if multi then
                                return type(opt.Value) == "table" and opt.Value[name] == true
                            end
                            return opt.Value == name
                        end

                        local function renderItem()
                            local chosen = itemIsSelected()

                            item.BackgroundColor3 = chosen
                                and Color3.fromRGB(79, 27, 45)
                                or Color3.fromRGB(33, 22, 27)

                            item.TextColor3 = chosen
                                and Color3.fromRGB(255, 242, 247)
                                or Color3.fromRGB(205, 194, 199)

                            item.Text = (chosen and "✓  " or "   ") .. tostring(name)

                            itemStroke.Color = chosen
                                and L.Scheme.AccentColor
                                or L.Scheme.OutlineColor

                            itemStroke.Transparency = chosen and 0.05 or 0.55
                        end

                        renderItem()

                        item.Activated:Connect(function()
                            if multi then
                                local nextMap = {}
                                if type(opt.Value) == "table" then
                                    for k, v in pairs(opt.Value) do nextMap[k] = v end
                                end
                                nextMap[name] = not (nextMap[name] == true)
                                opt:SetValue(nextMap)
                                renderItem()
                            else
                                opt:SetValue(name)
                                closePopup()
                            end
                        end)
                    end

                    currentPopup = popup
                    currentPopupOwner = row
                    currentPopupOverlay = overlay
                end)
                return opt
            end
            return G
        end

        function window:AddTab(name, iconName)
            local tabButton = Instance.new("TextButton")
            tabButton.Size = UDim2.new(1, 0, 0, 36)
            tabButton.BackgroundColor3 = Color3.fromRGB(21, 15, 18)
            tabButton.BorderSizePixel = 0
            tabButton.Text = "  " .. tostring(name)
            tabButton.TextColor3 = Color3.fromRGB(190, 180, 185)
            tabButton.TextSize = 12
            tabButton.Font = Enum.Font.Code
            tabButton.TextXAlignment = Enum.TextXAlignment.Left
            tabButton.Parent = tabRail
            corner(tabButton, 4)

            local content = Instance.new("Frame")
            content.Size = UDim2.fromScale(1, 1)
            content.BackgroundTransparency = 1
            content.Visible = false
            content.Parent = body

            local left = Instance.new("ScrollingFrame")
            left.Position = UDim2.fromOffset(9, 9)
            left.Size = UDim2.new(0.5, -13, 1, -18)
            left.BackgroundTransparency = 1
            left.BorderSizePixel = 0
            left.ScrollBarThickness = 3
            left.ScrollBarImageColor3 = L.Scheme.AccentColor
            left.AutomaticCanvasSize = Enum.AutomaticSize.Y
            left.CanvasSize = UDim2.new()
            left.Parent = content
            padding(left, 0, 4, 0, 4)
            local ll = Instance.new("UIListLayout")
            ll.Padding = UDim.new(0, 8)
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent = left

            local right = Instance.new("ScrollingFrame")
            right.Position = UDim2.new(0.5, 4, 0, 9)
            right.Size = UDim2.new(0.5, -13, 1, -18)
            right.BackgroundTransparency = 1
            right.BorderSizePixel = 0
            right.ScrollBarThickness = 3
            right.ScrollBarImageColor3 = L.Scheme.AccentColor
            right.AutomaticCanvasSize = Enum.AutomaticSize.Y
            right.CanvasSize = UDim2.new()
            right.Parent = content
            padding(right, 4, 0, 0, 4)
            local rl = Instance.new("UIListLayout")
            rl.Padding = UDim.new(0, 8)
            rl.SortOrder = Enum.SortOrder.LayoutOrder
            rl.Parent = right

            local tab = {_button = tabButton, _content = content}
            function tab:AddLeftGroupbox(titleText) return makeGroup(left, titleText) end
            function tab:AddRightGroupbox(titleText) return makeGroup(right, titleText) end
            tabButton.Activated:Connect(function() activate(tab) end)
            window._tabs[#window._tabs + 1] = tab
            if #window._tabs == 1 then activate(tab) end
            return tab
        end

        return window
    end

    function L:Unload()
        closePopup()
        if screen and screen.Parent then pcall(function() screen:Destroy() end) end
        L.Unloaded = true
    end

    return L
end


local Library = buildAliceNativeLibrary(
    "Steal a Chicken",
    "AliceHUB_StealAChicken_NativeUI",
    ALICE_LOGO_ASSET
)

local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
local compact = viewport.X <= 1700 and viewport.Y <= 900
local window = Library:CreateWindow({
    Title = "AliceHUB",
    Size = UDim2.fromOffset(compact and 700 or 900, compact and 500 or 620),
    CornerRadius = 4,
})

-- Floating AliceHUB button.
local logoGui = Instance.new("ScreenGui")
logoGui.Name = "AliceHUB_StealAChicken_LogoGui"
logoGui.ResetOnSpawn = false
logoGui.IgnoreGuiInset = true
logoGui.DisplayOrder = 1000000
logoGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local logoRoot = nil
if type(gethui) == "function" then
    local ok, root = pcall(gethui)
    if ok and root then logoRoot = root end
end
logoRoot = logoRoot or LocalPlayer:WaitForChild("PlayerGui")
local oldLogoGui = logoRoot:FindFirstChild("AliceHUB_StealAChicken_LogoGui")
if oldLogoGui and oldLogoGui ~= logoGui then pcall(function() oldLogoGui:Destroy() end) end
logoGui.Parent = logoRoot

local oldLogo = logoRoot:FindFirstChild("AliceHUBLogoButton")
if oldLogo then pcall(function() oldLogo:Destroy() end) end

local logo = Instance.new("ImageButton")
logo.Name = "AliceHUBLogoButton"
logo.AnchorPoint = Vector2.new(0, 0.5)
logo.Position = UDim2.new(0, 14, 0.5, 0)
logo.Size = UDim2.fromOffset(62, 62)
logo.BackgroundColor3 = Color3.fromRGB(24, 15, 19)
logo.BorderSizePixel = 0
logo.Image = ALICE_LOGO_ASSET
logo.ScaleType = Enum.ScaleType.Crop
logo.AutoButtonColor = false
logo.Parent = logoGui
local logoFallback = Instance.new("TextLabel")
logoFallback.Name = "Fallback"
logoFallback.BackgroundTransparency = 1
logoFallback.Size = UDim2.fromScale(1, 1)
logoFallback.Font = Enum.Font.Code
logoFallback.Text = "A"
logoFallback.TextColor3 = Color3.fromRGB(214, 77, 112)
logoFallback.TextSize = 28
logoFallback.TextXAlignment = Enum.TextXAlignment.Center
logoFallback.TextYAlignment = Enum.TextYAlignment.Center
logoFallback.ZIndex = logo.ZIndex + 1
logoFallback.Parent = logo
__aliceRegisterLogoTarget(logo, logoFallback)

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(1, 0)
logoCorner.Parent = logo
local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Color3.fromRGB(181, 48, 83)
logoStroke.Thickness = 2
logoStroke.Transparency = 0.08
logoStroke.Parent = logo

local Runtime = {
    alive = true,
    connections = {},
    activeTween = nil,
    moveSerial = 0,
    moving = false,
    stealing = false,
    action = "Initializing",
    target = "-",
    lastNestKey = nil,
    lastTarget = nil,
    started = os.clock(),
    backendReady = false,
    backendError = nil,
    whiteScreen = nil,
    whiteWas3D = true,
    ultraConnections = {},
    ultraGeneration = 0,
    noclipOriginal = setmetatable({}, {__mode = "k"}),
    characterManager = nil,
    originalApplyForce = nil,
    guardParts = setmetatable({}, {__mode = "k"}),
    -- Once a nest is consumed, keep it blocked until we have actually observed it
    -- empty and then see a Chicken/Egg appear again. This matches the game's nest reset
    -- cycle and avoids retargeting stale nest attributes or the stolen chicken.
    consumedNests = setmetatable({}, {__mode = "k"}),
    lastPenUpgradeTry = 0,
    nextStealAt = 0,
}

local function rememberConnection(c)
    if c then Runtime.connections[#Runtime.connections + 1] = c end
    return c
end

local logoDragging, logoMoved, logoStart, logoPos = false, false, nil, nil
rememberConnection(logo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = true
        logoMoved = false
        logoStart = input.Position
        logoPos = logo.Position
        rememberConnection(input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then logoDragging = false end
        end))
    end
end))
rememberConnection(UserInputService.InputChanged:Connect(function(input)
    if logoDragging and logoStart and logoPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - logoStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then logoMoved = true end
        logo.Position = UDim2.new(logoPos.X.Scale, logoPos.X.Offset + delta.X, logoPos.Y.Scale, logoPos.Y.Offset + delta.Y)
    end
end))
rememberConnection(logo.Activated:Connect(function()
    if logoMoved then logoMoved = false return end
    Library:Toggle()
end))
rememberConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Library:Toggle() end
end))

local function notify(text, duration)
    pcall(function()
        Library:Notify({Title = "AliceHUB", Description = tostring(text), Time = duration or 4})
    end)
end

local function setAction(text)
    Runtime.action = tostring(text or "-")
end

local function fullName(inst)
    local ok, result = pcall(function() return inst:GetFullName() end)
    return ok and result or tostring(inst)
end

local function safeRequire(module)
    if not module or not module:IsA("ModuleScript") then return nil end
    local ok, result = pcall(require, module)
    if ok then return result end
    return nil
end

local function findModule(root, name, mustContain)
    if not root then return nil end
    for _, inst in ipairs(root:GetDescendants()) do
        if inst:IsA("ModuleScript") and inst.Name == name then
            if not mustContain or fullName(inst):lower():find(tostring(mustContain):lower(), 1, true) then
                return inst
            end
        end
    end
    return nil
end

local function getPath(root, ...)
    local node = root
    for _, name in ipairs({...}) do
        if not node then return nil end
        node = node:FindFirstChild(name)
    end
    return node
end

local function moduleAtOrFind(pathParts, fallbackName, hint)
    local node = ReplicatedStorage
    for _, part in ipairs(pathParts) do
        node = node and node:FindFirstChild(part)
    end
    if node and node:IsA("ModuleScript") then return safeRequire(node), node end
    local fallback = findModule(ReplicatedStorage, fallbackName, hint)
    return safeRequire(fallback), fallback
end

local function remoteFire(remote, ...)
    if not remote or type(remote.fire) ~= "function" then return false end
    local args = table.pack(...)
    local ok = pcall(function()
        remote:fire(table.unpack(args, 1, args.n))
    end)
    return ok
end

local function remoteRequest(remote, ...)
    if not remote or type(remote.request) ~= "function" then return false, nil end
    local args = table.pack(...)
    local ok, promise = pcall(function()
        return remote:request(table.unpack(args, 1, args.n))
    end)
    if not ok then return false, nil end
    return true, promise
end

local function awaitRemoteRequest(remote, timeout, ...)
    local ok, promise = remoteRequest(remote, ...)
    if not ok then return false, nil end
    if type(promise) ~= "table" and type(promise) ~= "userdata" then
        return true, promise
    end

    local done, success, result = false, false, nil
    local hooked = pcall(function()
        promise:andThen(function(value)
            success = true
            result = value
            done = true
        end):catch(function()
            success = false
            done = true
        end)
    end)
    if not hooked then return true, promise end

    local deadline = os.clock() + math.max(0.1, tonumber(timeout) or 1.5)
    while Runtime.alive and not done and os.clock() < deadline do
        RunService.Heartbeat:Wait()
    end
    return done and success, result
end

local Config = {
    AutoSteal = false,
    TargetPriority = "Highest Rarity",
    RarityFilter = {},
    IncludeInsane = true,
    MovementMode = "Smart",
    TweenSpeed = 350,
    StealDelay = 0.65,
    AutoReturn = true,
    AutoDrop = true,
    AutoRecover = true,
    ReturnDelay = 0.15,

    AutoCollectEggs = false,
    CollectDelay = 0.75,
    AutoOpenEggs = false,
    OpenDelay = 0.35,
    AutoSell = false,
    SellMode = "Sell All",
    SellRarity = {},
    SellDelay = 1.0,
    NeverSellFavorites = true,

    AutoTreadmillUpgrade = false,
    AutoSpeedUpgrade = false,
    AutoBaseUpgrade = false,
    UpgradePriority = "Balanced",
    UpgradeMode = "Buy 1",
    UpgradeDelay = 1.25,

    WalkSpeedOverride = false,
    WalkSpeed = 30,
    JumpPowerOverride = false,
    JumpPower = 70,
    InfiniteJump = false,
    Noclip = false,
    AntiGuard = true,
    AntiKnockback = true,

    AutoClaimAll = false,
    AutoSpinWheel = false,
    AutoEquipBest = false,
    AutoClaimFuse = false,
    TeleportZone = "Forest",

    AntiAFK = true,
    WhiteScreen = false,
    UltraPerformance = false,
    AutoReconnect = true,
}
local Defaults = {}
for k, v in pairs(Config) do
    if type(v) == "table" then
        Defaults[k] = table.clone(v)
    else
        Defaults[k] = v
    end
end

local CONFIG_DIR = "AliceHUB"
local CONFIG_FILE = CONFIG_DIR .. "/StealAChicken.json"
local saveQueued = false

local function ensureConfigFolder()
    if type(makefolder) ~= "function" then return end
    pcall(function()
        if type(isfolder) ~= "function" or not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
    end)
end

local function readConfig()
    if not (type(isfile) == "function" and type(readfile) == "function") then return nil end
    local okExists, exists = pcall(isfile, CONFIG_FILE)
    if not okExists or not exists then return nil end
    local okRead, raw = pcall(readfile, CONFIG_FILE)
    if not okRead or type(raw) ~= "string" then return nil end
    local okDecode, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if okDecode and type(data) == "table" then return data end
    return nil
end

local function applyLoadedConfig(data)
    if type(data) ~= "table" then return false end
    for k, v in pairs(data) do
        if Defaults[k] ~= nil then Config[k] = v end
    end
    return true
end

local function loadConfig()
    local data = readConfig()
    return data and applyLoadedConfig(data) or false
end

local function saveConfig()
    if type(writefile) ~= "function" then return false end
    ensureConfigFolder()
    local okEncode, encoded = pcall(HttpService.JSONEncode, HttpService, Config)
    if not okEncode then return false end
    return pcall(writefile, CONFIG_FILE, encoded)
end

local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.5, function()
        saveQueued = false
        saveConfig()
    end)
end

loadConfig()

-- Game modules.
local Remotes = nil
local ChickenUT = nil
local EggUT = nil
local BackpackUT = nil
local NestUT = nil
local PenUT = nil
local BaseUT = nil
local RaritiesIF = nil
local ZonesIF = nil
local CodesIF = nil
local PlayRewardsIF = nil
local StoreBackpackSelectors = nil
local StoreBaseSelectors = nil
local SessionBackpackSelectors = nil
local SessionBaseSelectors = nil
local SessionPlayerSelectors = nil
local PenEggSelectors = nil
local Producer = nil

local RarityNames = {}
local RarityOrderByName = {}
local ZoneKeys = {}
local ZoneDisplay = {}
local ZoneKeyByDisplay = {}
local CodeKeys = {"release", "september", "crystal", "relax"}
local PlayRewardKeys = {}

local function initBackend()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then return false, "ReplicatedStorage.shared not found" end

    Remotes = safeRequire(getPath(shared, "remotes"))
    ChickenUT = safeRequire(getPath(shared, "utils", "chickenUT"))
    EggUT = safeRequire(getPath(shared, "utils", "eggUT"))
    BackpackUT = safeRequire(getPath(shared, "utils", "backpackUT"))
    NestUT = safeRequire(getPath(shared, "utils", "nestUT"))
    PenUT = safeRequire(getPath(shared, "utils", "penUT"))
    BaseUT = safeRequire(getPath(shared, "utils", "baseUT"))
    RaritiesIF = safeRequire(getPath(shared, "gameData", "chickens", "raritiesIF"))
    ZonesIF = safeRequire(getPath(shared, "gameData", "zones", "zonesIF"))
    CodesIF = safeRequire(getPath(shared, "gameData", "rewards", "codesIF"))
    PlayRewardsIF = safeRequire(getPath(shared, "gameData", "rewards", "playRewardsIF"))

    StoreBackpackSelectors = safeRequire(getPath(shared, "state", "selectors", "storeSelectors", "backpackSelectors"))
    StoreBaseSelectors = safeRequire(getPath(shared, "state", "selectors", "storeSelectors", "baseSelectors"))
    SessionBackpackSelectors = safeRequire(getPath(shared, "state", "selectors", "sessionSelectors", "backpackSelectors"))
    SessionBaseSelectors = safeRequire(getPath(shared, "state", "selectors", "sessionSelectors", "baseSelectors"))
    SessionPlayerSelectors = safeRequire(getPath(shared, "state", "selectors", "sessionSelectors", "playerSelectors"))
    PenEggSelectors = safeRequire(getPath(shared, "state", "selectors", "sessionSelectors", "penEggSelectors"))

    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts") or LocalPlayer:WaitForChild("PlayerScripts", 10)
    local producerModule = playerScripts and findModule(playerScripts, "producer")
    Producer = safeRequire(producerModule)

    if not Remotes then return false, "shared.remotes failed to load" end
    if not ChickenUT or not EggUT or not BackpackUT or not NestUT then
        return false, "required chicken/egg/nest utils failed to load"
    end

    table.clear(RarityNames)
    table.clear(RarityOrderByName)
    local rarityRows = {}
    if type(RaritiesIF) == "table" then
        for _, rarity in pairs(RaritiesIF) do
            if type(rarity) == "table" and type(rarity.getName) == "function" then
                local okName, name = pcall(rarity.getName, rarity)
                local okOrder, order = pcall(rarity.getOrder, rarity)
                if okName and type(name) == "string" then
                    rarityRows[#rarityRows + 1] = {name = name, order = okOrder and tonumber(order) or 0}
                end
            end
        end
    end
    table.sort(rarityRows, function(a, b) return a.order < b.order end)
    for _, row in ipairs(rarityRows) do
        RarityNames[#RarityNames + 1] = row.name
        RarityOrderByName[row.name] = row.order
    end

    if #RarityNames == 0 then
        RarityNames = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Stellar", "Secret", "Celestial", "Divine", "Radiant", "Prismatic", "Rainbow", "Limited"}
        for i, name in ipairs(RarityNames) do RarityOrderByName[name] = i end
    end

    table.clear(ZoneKeys)
    table.clear(ZoneDisplay)
    table.clear(ZoneKeyByDisplay)
    if type(ZonesIF) == "table" then
        for key in pairs(ZonesIF) do
            if type(key) == "string" then ZoneKeys[#ZoneKeys + 1] = key end
        end
    end
    table.sort(ZoneKeys)
    local preferred = {"forest", "lake", "jungle", "desert", "snow", "volcano", "beach", "abyss", "cosmic", "crystal"}
    local present = {}
    for _, k in ipairs(ZoneKeys) do present[k] = true end
    local ordered = {}
    for _, k in ipairs(preferred) do if present[k] then ordered[#ordered + 1] = k; present[k] = nil end end
    for k in pairs(present) do ordered[#ordered + 1] = k end
    ZoneKeys = ordered
    for _, key in ipairs(ZoneKeys) do
        local display = key:sub(1,1):upper() .. key:sub(2)
        ZoneDisplay[#ZoneDisplay + 1] = display
        ZoneKeyByDisplay[display] = key
    end

    if type(CodesIF) == "table" and type(CodesIF.codes) == "table" then
        table.clear(CodeKeys)
        for key in pairs(CodesIF.codes) do CodeKeys[#CodeKeys + 1] = tostring(key) end
        table.sort(CodeKeys)
    end

    table.clear(PlayRewardKeys)
    if type(PlayRewardsIF) == "table" then
        local source = PlayRewardsIF.rewards or PlayRewardsIF
        if type(source) == "table" then
            for key in pairs(source) do
                if tostring(key):match("^reward%d+$") then PlayRewardKeys[#PlayRewardKeys + 1] = tostring(key) end
            end
        end
    end
    if #PlayRewardKeys == 0 then
        for i = 1, 15 do PlayRewardKeys[#PlayRewardKeys + 1] = "reward" .. i end
    end
    table.sort(PlayRewardKeys, function(a,b)
        return (tonumber(a:match("%d+")) or 0) < (tonumber(b:match("%d+")) or 0)
    end)

    return true
end

local function character()
    return LocalPlayer.Character
end

local function rootPart()
    local char = character()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function humanoid()
    local char = character()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getProducerState(selector)
    if not Producer or type(Producer.getState) ~= "function" or not selector then return nil end
    local ok, value = pcall(Producer.getState, Producer, selector)
    if ok then return value end
    return nil
end

local function selectorCall(module, name, ...)
    if type(module) ~= "table" or type(module[name]) ~= "function" then return nil end
    local args = table.pack(...)
    local ok, selector = pcall(function()
        return module[name](table.unpack(args, 1, args.n))
    end)
    return ok and selector or nil
end

local function getBackpackItems()
    local selector = selectorCall(StoreBackpackSelectors, "selectBackpackItems", LocalPlayer.Name)
    local value = getProducerState(selector)
    return type(value) == "table" and value or {}
end

local function getHoldingItem()
    local selector = selectorCall(SessionBackpackSelectors, "selectHoldingItem", LocalPlayer.Name)
    return getProducerState(selector)
end

-- Raw holding id is more reliable than selectHoldingItem during the few frames
-- after a stolen chicken transitions from yeetReward into the backpack/hotbar.
-- selectHoldingItem can temporarily be nil until the backpack item list catches up.
local function getHoldingId()
    local selector = selectorCall(SessionBackpackSelectors, "selectHolding", LocalPlayer.Name)
    local value = getProducerState(selector)
    if type(value) == "string" and value ~= "" then return value end

    local held = getHoldingItem()
    if type(held) == "string" and held ~= "" then return held end
    if type(held) == "table" then
        if BackpackUT and type(BackpackUT.getItemId) == "function" then
            local ok, id = pcall(BackpackUT.getItemId, held)
            if ok and type(id) == "string" and id ~= "" then return id end
        end
        local id = held.id or held.uuid or held.itemId or held.key
        if type(id) == "string" and id ~= "" then return id end
    end
    return nil
end

local function getBaseLevel()
    local selector = selectorCall(StoreBaseSelectors, "selectBaseLevel", LocalPlayer.Name)
    return tonumber(getProducerState(selector))
end

local function getBaseChickens()
    local selector = selectorCall(StoreBaseSelectors, "selectBaseChickens", LocalPlayer.Name)
    local value = getProducerState(selector)
    return type(value) == "table" and value or {}
end

local function getPenCapacity()
    local level = getBaseLevel()
    if level == nil or not BaseUT or type(BaseUT.getMaxChickens) ~= "function" then
        return nil, nil
    end
    local ok, max = pcall(BaseUT.getMaxChickens, level)
    if not ok or tonumber(max) == nil then return nil, nil end
    return #getBaseChickens(), tonumber(max)
end

local function isPenFull()
    local count, max = getPenCapacity()
    return count ~= nil and max ~= nil and max > 0 and count >= max, count, max
end

local function tryMakePenSpace()
    local full, count, max = isPenFull()
    if not full then return true, count, max end

    if Config.AutoBaseUpgrade and Remotes and Remotes.data and Remotes.data.base and Remotes.data.base.upgradeBase then
        local now = os.clock()
        if now - (Runtime.lastPenUpgradeTry or 0) >= math.max(0.8, tonumber(Config.UpgradeDelay) or 1.25) then
            Runtime.lastPenUpgradeTry = now
            setAction(string.format("Pen full %s/%s - upgrading base", tostring(count or "?"), tostring(max or "?")))
            remoteFire(Remotes.data.base.upgradeBase)
            task.wait(0.7)
            full, count, max = isPenFull()
            if not full then return true, count, max end
        end
    end

    setAction(string.format("Pen full %s/%s", tostring(count or "?"), tostring(max or "?")))
    return false, count, max
end

-- Stolen nest chickens are NOT represented by selectHoldingItem while the chase is active.
-- The game stores that carry in playerSession.yeetReward; this is the same state used by
-- the native RUN/DROP UI and guard systems.
local function getYeetReward()
    local selector = selectorCall(SessionPlayerSelectors, "selectPlayerYeetReward", LocalPlayer.Name)
    return getProducerState(selector)
end

local function isNestCarry()
    local reward = getYeetReward()
    if type(reward) ~= "table" then return false end
    if reward.source == "nest" then return true end
    -- Insane steals can use the same yeet payload with an insaneZone marker.
    if reward.insaneZone ~= nil then return true end
    return reward.isChasing == true and reward.zone ~= nil
end

local function isHolding()
    return isNestCarry() or getHoldingId() ~= nil or getHoldingItem() ~= nil
end

local function waitForCarry(timeout)
    local deadline = os.clock() + math.max(0.05, tonumber(timeout) or 1)
    repeat
        if isHolding() then return true end
        RunService.Heartbeat:Wait()
    until not Runtime.alive or os.clock() >= deadline
    return isHolding()
end

local function getPlayerBaseIndex()
    local selector = selectorCall(SessionBaseSelectors, "selectPlayerBase", LocalPlayer.Name)
    return getProducerState(selector)
end

local function getOwnBase()
    local targetIndex = getPlayerBaseIndex()
    local bases = CollectionService:GetTagged("Base")
    if targetIndex ~= nil then
        for _, base in ipairs(bases) do
            if base:GetAttribute("index") == targetIndex or tostring(base:GetAttribute("index")) == tostring(targetIndex) then
                return base
            end
        end
    end
    for _, base in ipairs(bases) do
        for _, attr in ipairs({"player", "playerName", "owner", "ownerName"}) do
            local value = base:GetAttribute(attr)
            if tostring(value or ""):lower() == LocalPlayer.Name:lower() then return base end
        end
    end
    return nil
end

local function getBaseTargetCFrame()
    local base = getOwnBase()
    if not base then return nil, nil end
    if PenUT and type(PenUT.getBounds) == "function" then
        local ok, cf = pcall(PenUT.getBounds, base)
        if ok and typeof(cf) == "CFrame" then
            local floorY = nil
            if type(PenUT.getFloorY) == "function" then
                local okFloor, value = pcall(PenUT.getFloorY, base, cf.Position)
                if okFloor and tonumber(value) then floorY = tonumber(value) end
            end
            local y = (floorY or cf.Position.Y) + 3
            local rotation = cf - cf.Position
            return CFrame.new(cf.Position.X, y, cf.Position.Z) * rotation, base
        end
    end
    if base:IsA("Model") then return base:GetPivot() * CFrame.new(0, 3, 0), base end
    if base:IsA("BasePart") then return base.CFrame * CFrame.new(0, 3, 0), base end
    return nil, base
end

local function cancelTween()
    Runtime.moveSerial = (Runtime.moveSerial or 0) + 1
    if Runtime.activeTween then pcall(function() Runtime.activeTween:Cancel() end) end
    Runtime.activeTween = nil
    Runtime.moving = false
end

local function stopCharacterMotion()
    local root = rootPart()
    local hum = humanoid()
    if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

local function pivotCharacter(cf, stabilizeFrames)
    local char = character()
    if not char or typeof(cf) ~= "CFrame" then return false end
    cancelTween()
    local frames = math.clamp(tonumber(stabilizeFrames) or 1, 1, 5)
    for _ = 1, frames do
        if not Runtime.alive or not char.Parent then return false end
        pcall(function()
            char:PivotTo(cf)
            local root = rootPart()
            if root then
                root.CFrame = cf
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end)
        stopCharacterMotion()
        RunService.Heartbeat:Wait()
    end
    return true
end

-- Manual PivotTo tween is intentionally used instead of only TweenService on HRP.
-- The game's own character/chase controller can overwrite a normal HRP tween; driving
-- the character pivot every frame keeps Tween mode smooth and deterministic.
local function tweenCharacter(cf, speed)
    local root = rootPart()
    local char = character()
    if not root or not char or typeof(cf) ~= "CFrame" then return false end

    cancelTween()
    Runtime.moveSerial = (Runtime.moveSerial or 0) + 1
    local serial = Runtime.moveSerial
    Runtime.moving = true

    local startCF = root.CFrame
    local distance = (startCF.Position - cf.Position).Magnitude
    local duration = math.clamp(distance / math.max(20, tonumber(speed) or 350), 0.04, 10)
    local started = os.clock()

    while Runtime.alive and Runtime.moveSerial == serial do
        local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
        local nowCF = startCF:Lerp(cf, alpha)
        pcall(function()
            char:PivotTo(nowCF)
            local currentRoot = rootPart()
            if currentRoot then
                currentRoot.AssemblyLinearVelocity = Vector3.zero
                currentRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end)
        local hum = humanoid()
        if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
        if alpha >= 1 then break end
        RunService.Heartbeat:Wait()
    end

    if Runtime.moveSerial == serial and Runtime.alive then
        pcall(function() char:PivotTo(cf) end)
        stopCharacterMotion()
    end
    Runtime.moving = false
    local finalRoot = rootPart()
    return finalRoot ~= nil and (finalRoot.Position - cf.Position).Magnitude <= 8
end

local function moveToPosition(position, modeOverride)
    local root = rootPart()
    if not root or typeof(position) ~= "Vector3" then return false end
    local mode = modeOverride or Config.MovementMode
    local horizontal = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
    local direction = horizontal.Magnitude > 0.05 and horizontal.Unit or Vector3.new(1,0,0)
    local finalPos = position + direction * 3.5 + Vector3.new(0, 3, 0)
    local finalCF = CFrame.lookAt(finalPos, Vector3.new(position.X, finalPos.Y, position.Z))

    if mode == "Instant TP" then
        return pivotCharacter(finalCF, 2)
    elseif mode == "Tween" then
        return tweenCharacter(finalCF, Config.TweenSpeed)
    else
        local distance = (root.Position - finalPos).Magnitude
        if distance > 95 then
            local stagePos = position + direction * 12 + Vector3.new(0, 3, 0)
            pivotCharacter(CFrame.lookAt(stagePos, Vector3.new(position.X, stagePos.Y, position.Z)))
            task.wait(0.05)
        end
        return tweenCharacter(finalCF, math.max(Config.TweenSpeed, 450))
    end
end

local function moveToBase(forceInstant)
    local cf, base = getBaseTargetCFrame()
    if not cf then
        remoteFire(Remotes and Remotes.game and Remotes.game.base and Remotes.game.base.teleportToBase)
        task.wait(0.25)
        cf, base = getBaseTargetCFrame()
    end
    if not cf then return false end
    if forceInstant or Config.MovementMode == "Instant TP" then
        pivotCharacter(cf, 3)
    elseif Config.MovementMode == "Tween" then
        tweenCharacter(cf, Config.TweenSpeed)
    else
        local root = rootPart()
        if root and (root.Position - cf.Position).Magnitude > 95 then
            -- Smart: snap most of the long trip, then visibly tween the final approach.
            local nearCF = cf * CFrame.new(0, 0, 18)
            pivotCharacter(nearCF, 2)
            task.wait(0.03)
        end
        tweenCharacter(cf, math.max(Config.TweenSpeed, 450))
    end
    stopCharacterMotion()
    return true, base
end

local function rarityInfo(chickenName, variant)
    if not ChickenUT or type(ChickenUT.getChicken) ~= "function" or not chickenName then return "Unknown", 0, nil end
    local okChicken, chicken = pcall(ChickenUT.getChicken, chickenName, variant or "normal")
    if not okChicken or not chicken then return "Unknown", 0, nil end
    local okRarity, rarity = pcall(function() return chicken:getRarity() end)
    if not okRarity or not rarity then return "Unknown", 0, chicken end
    local okName, name = pcall(function() return rarity:getName() end)
    local okOrder, order = pcall(function() return rarity:getOrder() end)
    return okName and tostring(name) or "Unknown", okOrder and tonumber(order) or 0, chicken
end

local function chickenValue(chickenName, variant, size)
    if not ChickenUT then return 0 end
    if type(ChickenUT.getPlacedValue) == "function" then
        local ok, value = pcall(ChickenUT.getPlacedValue, {
            name = chickenName,
            variant = variant or "normal",
            size = tonumber(size) or 1,
        }, 1)
        if ok and tonumber(value) then return tonumber(value) end
    end
    local _, _, chicken = rarityInfo(chickenName, variant)
    if chicken and type(chicken.getSellValue) == "function" then
        local ok, value = pcall(function() return chicken:getSellValue(tonumber(size) or 1) end)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 0
end

local function selectedMapAllows(map, name)
    if type(map) ~= "table" then return true end
    local any = false
    for _, enabled in pairs(map) do if enabled == true then any = true break end end
    if not any then return true end
    return map[name] == true
end

local function targetFromNest(nest)
    if not nest or not nest:IsDescendantOf(workspace) then return nil end

    -- Only an exact live Chicken/Egg child counts as an occupied nest. Attributes like
    -- chickenName can stay stale after a steal, so they are never enough by themselves.
    local liveSlot = nest:FindFirstChild("Chicken") or nest:FindFirstChild("Egg")
    local consumed = Runtime.consumedNests[nest]

    if not liveSlot or not (liveSlot:IsA("Model") or liveSlot:IsA("BasePart")) then
        -- Important: remember that this consumed nest has genuinely become empty.
        -- It remains blocked until a later scan sees a Chicken/Egg again.
        if consumed then consumed.observedEmpty = true end
        return nil
    end

    if consumed then
        if consumed.observedEmpty then
            -- The game has repopulated/reset this nest. A live payload appearing after an
            -- observed empty state is a new spawn, even if the game reuses the same Instance.
            Runtime.consumedNests[nest] = nil
        else
            -- We stole from this nest but have not yet observed it empty. Ignore any stale
            -- payload that lingers for a few frames instead of chasing it again.
            return nil
        end
    end

    local chickenName = nest:GetAttribute("chickenName")
    if type(chickenName) ~= "string" or chickenName == "" then return nil end
    local variant = nest:GetAttribute("chickenVariant") or "normal"
    local size = tonumber(nest:GetAttribute("chickenSize")) or 1
    local zone = nil
    if NestUT and type(NestUT.resolveZone) == "function" then
        local ok, z = pcall(function() return NestUT.resolveZone(nest) end)
        if ok then zone = z end
    end
    if type(zone) ~= "string" then return nil end
    local origin = nil
    if NestUT and type(NestUT.getNestOrigin) == "function" then
        local ok, value = pcall(NestUT.getNestOrigin, nest)
        if ok and typeof(value) == "Vector3" then origin = value end
    end
    if not origin then
        if nest:IsA("Model") then origin = nest:GetPivot().Position
        elseif nest:IsA("BasePart") then origin = nest.Position end
    end
    if not origin then return nil end
    local rarityName, order = rarityInfo(chickenName, variant)
    if not selectedMapAllows(Config.RarityFilter, rarityName) then return nil end
    local value = chickenValue(chickenName, variant, size)
    local root = rootPart()
    return {
        kind = "nest", instance = nest, name = chickenName, variant = variant,
        size = size, zone = zone, position = origin,
        rarity = rarityName, order = order, value = value,
        distance = root and (root.Position - origin).Magnitude or math.huge,
        key = NestUT and type(NestUT.nestKey) == "function" and NestUT.nestKey(zone, origin) or nil,
        liveSlot = liveSlot,
    }
end

Runtime.__rs_targetFromInsane = function(model)
    if not Config.IncludeInsane or not model or not model:IsDescendantOf(workspace) then return nil end
    local zone = model:GetAttribute("insaneZone")
    local chickenName = model:GetAttribute("chickenName")
    if type(zone) ~= "string" or type(chickenName) ~= "string" then return nil end
    local variant = model:GetAttribute("chickenVariant") or "normal"
    local size = tonumber(model:GetAttribute("chickenSize")) or 1
    local origin = model:IsA("Model") and model:GetPivot().Position or (model:IsA("BasePart") and model.Position or nil)
    if not origin then return nil end
    local rarityName, order = rarityInfo(chickenName, variant)
    if not selectedMapAllows(Config.RarityFilter, rarityName) then return nil end
    local root = rootPart()
    return {
        kind = "insane", instance = model, name = chickenName, variant = variant,
        size = size, zone = zone, position = origin,
        rarity = rarityName, order = order, value = chickenValue(chickenName, variant, size),
        distance = root and (root.Position - origin).Magnitude or math.huge,
        key = nil,
    }
end

Runtime.__rs_targetBetter = function(a, b)
    if not b then return true end
    if Config.TargetPriority == "Nearest" then
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.order > b.order
    elseif Config.TargetPriority == "Highest Value" then
        if a.value ~= b.value then return a.value > b.value end
        if a.order ~= b.order then return a.order > b.order end
        return a.distance < b.distance
    else
        if a.order ~= b.order then return a.order > b.order end
        if a.value ~= b.value then return a.value > b.value end
        return a.distance < b.distance
    end
end

Runtime.__rs_findBestTarget = function()
    local best = nil
    for _, nest in ipairs(CollectionService:GetTagged("Nest")) do
        local target = targetFromNest(nest)
        if target and Runtime.__rs_targetBetter(target, best) then best = target end
    end
    if Config.IncludeInsane then
        for _, egg in ipairs(CollectionService:GetTagged("InsaneEgg")) do
            local target = Runtime.__rs_targetFromInsane(egg)
            if target and Runtime.__rs_targetBetter(target, best) then best = target end
        end
    end
    return best
end

Runtime.__rs_formatCompact = function(value)
    value = tonumber(value) or 0
    local abs = math.abs(value)
    if abs >= 1e12 then return string.format("%.2fT", value/1e12) end
    if abs >= 1e9 then return string.format("%.2fB", value/1e9) end
    if abs >= 1e6 then return string.format("%.2fM", value/1e6) end
    if abs >= 1e3 then return string.format("%.1fK", value/1e3) end
    return tostring(math.floor(value + 0.5))
end

Runtime.__rs_waitForNestDeposit = function(timeout)
    local deadline = os.clock() + math.max(0.15, tonumber(timeout) or 1.25)
    while Runtime.alive and os.clock() < deadline do
        if not isNestCarry() then return true end
        local cf = getBaseTargetCFrame()
        local root = rootPart()
        if cf and root and (root.Position - cf.Position).Magnitude > 7 then
            -- Hold the character inside the pen if the game nudges/rubberbands it.
            pivotCharacter(cf, 1)
        else
            stopCharacterMotion()
            RunService.Heartbeat:Wait()
        end
    end
    return not isNestCarry()
end

-- After a stolen chicken reaches base, the game's chase/yeet state can end while
-- the chicken remains selected as the current holding item. Calling dropChicken at
-- that point tries to PLACE it into the pen and causes "Your pen is full" spam.
-- Store the held item back into backpack instead, so Auto Steal can continue even
-- when every pen slot is occupied.
Runtime.__rs_heldItemId = function()
    -- Prefer the raw session holding id. It remains available even when
    -- selectHoldingItem has not rebuilt the full item table yet.
    local rawId = getHoldingId()
    if rawId ~= nil then return rawId end

    local held = getHoldingItem()
    if held == nil then return nil end
    if type(held) == "string" then return held end
    if type(held) ~= "table" then return nil end

    if BackpackUT and type(BackpackUT.getItemId) == "function" then
        local ok, id = pcall(BackpackUT.getItemId, held)
        if ok and id ~= nil then return id end
    end

    return held.id or held.uuid or held.itemId or held.key
end

Runtime.__rs_storeHeldChicken = function(timeout)
    local deadline = os.clock() + math.max(0.35, tonumber(timeout) or 1.4)
    local backpackRemotes = Remotes and Remotes.data and Remotes.data.backpack
    local storeRemote = backpackRemotes and backpackRemotes.storeItem
    if not storeRemote then return false end

    while Runtime.alive and os.clock() < deadline do
        local id = Runtime.__rs_heldItemId()
        if id == nil then return true end

        setAction("Storing held chicken")

        -- The game's own backpack UI calls storeItem:request(itemId).
        -- V1.7 incorrectly used :fire(), so the server never cleared holding.
        awaitRemoteRequest(storeRemote, 0.9, id)

        local clearDeadline = math.min(deadline, os.clock() + 0.35)
        while Runtime.alive and os.clock() < clearDeadline do
            if getHoldingId() == nil then return true end
            RunService.Heartbeat:Wait()
        end

        -- Retry with the freshest holding id in case the stolen chicken changed
        -- from the chase payload into a backpack entry one frame later.
        task.wait(0.06)
    end

    return getHoldingId() == nil
end

Runtime.__rs_dropAtBase = function(forceInstant)
    if not Remotes then return false end
    local okMove, base = moveToBase(forceInstant)
    if not okMove then return false end

    task.wait(math.max(0, tonumber(Config.ReturnDelay) or 0.15))
    local root = rootPart()
    if base and PenUT and type(PenUT.isInside) == "function" and root then
        local okInside, inside = pcall(PenUT.isInside, base, root.Position)
        if okInside and not inside then
            local cf = getBaseTargetCFrame()
            if cf then pivotCharacter(cf, 2) end
        end
    end

    -- First finish the stolen-nest chase by standing inside our base/pen.
    if isNestCarry() then
        setAction("Depositing chicken")
        local deposited = Runtime.__rs_waitForNestDeposit(1.4)
        if not deposited then
            local cf = getBaseTargetCFrame()
            if cf then pivotCharacter(cf, 3) end
            deposited = Runtime.__rs_waitForNestDeposit(0.65)
        end

        -- Important: after deposit, the stolen chicken may become a held backpack
        -- item (especially when pen is full). Stash it instead of trying dropChicken.
        task.wait(0.12)
        local stored = Runtime.__rs_storeHeldChicken(1.4)
        return (deposited or not isNestCarry()) and stored
    end

    -- If a stolen chicken already transitioned from yeetReward -> holding before this
    -- function entered, just put it in the backpack. Do NOT call base.dropChicken.
    if getHoldingId() ~= nil or getHoldingItem() ~= nil then
        Runtime.__rs_storeHeldChicken(1.4)
    end
    return getHoldingId() == nil
end

Runtime.__rs_holdAtTarget = function(target, seconds)
    local duration = math.max(0, tonumber(seconds) or 0)
    if duration <= 0 then return true end
    local deadline = os.clock() + duration
    while Runtime.alive and os.clock() < deadline do
        local root = rootPart()
        if not root then return false end
        if (root.Position - target.position).Magnitude > 8 then
            moveToPosition(target.position, "Instant TP")
        else
            stopCharacterMotion()
            RunService.Heartbeat:Wait()
        end
    end
    return Runtime.alive
end

Runtime.__rs_settleInsideBase = function(seconds)
    local deadline = os.clock() + math.max(0.1, tonumber(seconds) or 0.65)
    while Runtime.alive and os.clock() < deadline do
        local cf = getBaseTargetCFrame()
        local root = rootPart()
        if not cf or not root then break end
        if (root.Position - cf.Position).Magnitude > 7 then
            pivotCharacter(cf, 2)
        else
            stopCharacterMotion()
            RunService.Heartbeat:Wait()
        end
    end
end

-- Remote promise/state propagation is not equally fast on every steal. A steal is also
-- considered successful when the exact chicken/egg instance we targeted leaves its nest.
-- This is especially important from cycle #2 onward, where the visual steal can complete
-- before stealEgg's promise/selectPlayerYeetReward is visible to AliceHUB.
Runtime.__rs_targetPayloadGone = function(target)
    if not target or target.kind ~= "nest" or not target.instance then return false end
    if not target.instance:IsDescendantOf(workspace) then return true end

    local original = target.liveSlot
    if original == nil or original.Parent == nil or not original:IsDescendantOf(target.instance) then
        return true
    end

    local current = target.instance:FindFirstChild("Chicken") or target.instance:FindFirstChild("Egg")
    return current == nil or current ~= original
end

Runtime.__rs_waitForTargetPayloadGone = function(target, timeout)
    if not target or target.kind ~= "nest" then return false end
    local deadline = os.clock() + math.max(0.05, tonumber(timeout) or 0.9)
    repeat
        if Runtime.__rs_targetPayloadGone(target) then return true end
        RunService.Heartbeat:Wait()
    until not Runtime.alive or os.clock() >= deadline
    return Runtime.__rs_targetPayloadGone(target)
end

Runtime.__rs_stealTarget = function(target)
    if Runtime.stealing or not target or not Remotes then return false end
    Runtime.stealing = true
    Runtime.lastTarget = target
    Runtime.lastNestKey = target.key
    Runtime.target = string.format("%s | %s | %s", target.name, target.rarity, Runtime.__rs_formatCompact(target.value))

    setAction("Moving to " .. tostring(target.name))

    local moved = moveToPosition(target.position)
    if not moved then
        Runtime.stealing = false
        return false
    end

    -- Instant TP needs time for the new position to replicate before the server validates
    -- steal distance. V1.2 waited mostly AFTER the steal request, which was too late.
    if Config.MovementMode == "Instant TP" then
        setAction("Waiting at " .. tostring(target.name))
        Runtime.__rs_holdAtTarget(target, math.max(0.30, tonumber(Config.StealDelay) or 0.65))
    else
        task.wait(0.04)
    end

    setAction("Stealing " .. tostring(target.name))
    local requestDone, requestResult
    if target.kind == "insane" then
        requestDone, requestResult = awaitRemoteRequest(Remotes.game.nests.takeInsaneEgg, 1.5, target.zone)
    else
        requestDone, requestResult = awaitRemoteRequest(Remotes.game.nests.stealEgg, 1.5, target.zone, target.position)
    end

    local stealConfirmed = requestDone and requestResult == true

    -- One retry for Instant only. If the first request was evaluated before the TP position
    -- reached the server, stay at the nest a little longer and retry once.
    if not stealConfirmed and Config.MovementMode == "Instant TP" and Runtime.alive then
        setAction("Retrying " .. tostring(target.name))
        Runtime.__rs_holdAtTarget(target, 0.28)
        if target.kind == "insane" then
            requestDone, requestResult = awaitRemoteRequest(Remotes.game.nests.takeInsaneEgg, 1.5, target.zone)
        else
            requestDone, requestResult = awaitRemoteRequest(Remotes.game.nests.stealEgg, 1.5, target.zone, target.position)
        end
        stealConfirmed = requestDone and requestResult == true
    end

    -- Cycle-safe confirmation: from the second steal onward the promise/selectors can be
    -- late even though the chicken visibly left the nest. The disappearing target itself
    -- is authoritative enough for movement: once it is gone, return to base immediately.
    local payloadGone = false
    if target.kind == "nest" then
        payloadGone = Runtime.__rs_waitForTargetPayloadGone(target, stealConfirmed and 0.30 or 1.10)
    end
    local actionConfirmed = stealConfirmed or payloadGone

    if actionConfirmed and target.instance and target.kind == "nest" then
        -- No timer here. This nest stays blocked until the scanner first observes it empty
        -- and later sees a Chicken/Egg appear again during the game's own reset cycle.
        Runtime.consumedNests[target.instance] = {
            slot = target.liveSlot,
            observedEmpty = payloadGone,
            consumedAt = os.clock(),
        }
    end

    local holding = false
    if actionConfirmed then
        setAction("Confirming chicken")
        -- Do not make returning depend on this selector. We only give state a chance to
        -- catch up; actionConfirmed already proves the chicken was taken.
        holding = waitForCarry(Config.MovementMode == "Instant TP" and 0.65 or 1.15)
        if Config.MovementMode == "Instant TP" then task.wait(0.12) end
    else
        -- Even if both confirmations are late, allow a longer carry-state grace period.
        holding = waitForCarry(1.0)
    end

    if Config.AutoRecover and not holding and not stealConfirmed and target.key then
        setAction("Recovering chicken")
        local recovered, recoverResult = awaitRemoteRequest(Remotes.game.nests.recoverEgg, 1.25, target.key)
        if recovered and recoverResult == true then
            holding = waitForCarry(0.8)
        else
            holding = waitForCarry(0.35)
        end
    end

    -- A true steal response is enough to return. Waiting for the store selector was the
    -- reason Instant could show RUN/DROP in-game yet remain at the nest in V1.2.
    local canReturn = holding or actionConfirmed
    if Config.AutoReturn and canReturn then
        if Config.AutoDrop then
            Runtime.__rs_dropAtBase(false)
        else
            setAction("Returning to base")
            moveToBase(false)
        end

        -- Keep the character inside the pen briefly even when yeetReward is late/missing.
        -- Reaching the pen is what deposits a stolen nest chicken.
        if actionConfirmed then
            Runtime.__rs_settleInsideBase(Config.MovementMode == "Instant TP" and 0.85 or 0.45)
            if Config.AutoDrop and (getHoldingId() ~= nil or getHoldingItem() ~= nil) then
                Runtime.__rs_storeHeldChicken(1.4)
            end
        end
    end

    -- Give the previous backpack/yeet transaction a tiny gap before the next steal.
    -- Without this, cycle #2 can start while the server is still finishing cycle #1.
    Runtime.nextStealAt = os.clock() + 0.30
    Runtime.stealing = false
    setAction("Ready")
    return holding or actionConfirmed
end

Runtime.__rs_eggRarityName = function(item)
    if type(item) ~= "table" or item.type ~= "egg" or type(item.egg) ~= "table" then return nil end
    if not EggUT or type(EggUT.getDisplayRarity) ~= "function" then return nil end
    local egg = item.egg
    local ok, rarity = pcall(EggUT.getDisplayRarity, egg.name, egg.chicken, egg.variant)
    if not ok or not rarity then return nil end
    local okName, name = pcall(function() return rarity:getName() end)
    return okName and tostring(name) or nil
end

Runtime.__rs_itemId = function(item)
    if BackpackUT and type(BackpackUT.getItemId) == "function" then
        local ok, id = pcall(BackpackUT.getItemId, item)
        if ok and type(id) == "string" then return id end
    end
    if type(item) == "table" and type(item.egg) == "table" then return item.egg.id end
    if type(item) == "table" and type(item.chicken) == "table" then return item.chicken.id end
    return nil
end

Runtime.__rs_sellSelectedEggs = function()
    if not Remotes then return end
    local mode = Config.SellMode
    if mode == "Sell All" then
        remoteFire(Remotes.data.backpack.sellAllItems, "egg")
        return
    end
    local sold = 0
    for _, item in pairs(getBackpackItems()) do
        if type(item) == "table" and item.type == "egg" then
            local favorite = item.favorite == true
            if not (Config.NeverSellFavorites and favorite) then
                local rarity = Runtime.__rs_eggRarityName(item) or "Unknown"
                local selected = type(Config.SellRarity) == "table" and Config.SellRarity[rarity] == true
                local shouldSell = (mode == "Selected Rarity" and selected) or (mode == "Keep Selected Rarity" and not selected)
                if shouldSell then
                    local id = Runtime.__rs_itemId(item)
                    if id then
                        remoteFire(Remotes.data.backpack.sellItem, id)
                        sold = sold + 1
                        if sold >= 14 then break end
                        task.wait(0.12)
                    end
                end
            end
        end
    end
end

Runtime.__rs_openEggsOnce = function()
    if not Remotes then return end
    local opened = 0
    for _, item in pairs(getBackpackItems()) do
        if type(item) == "table" and item.type == "egg" then
            local id = Runtime.__rs_itemId(item)
            if id then
                remoteRequest(Remotes.data.backpack.openEgg, id)
                opened = opened + 1
                if opened >= 8 then break end
                task.wait(0.20)
            end
        end
    end
end

Runtime.__rs_claimAllOnce = function()
    if not Remotes then return end
    local data = Remotes.data
    local gameR = Remotes.game
    if data.rewards then
        remoteFire(data.rewards.claimJoinReward)
        for _, key in ipairs(PlayRewardKeys) do
            remoteFire(data.rewards.claimPlayReward, key)
            task.wait(0.025)
        end
    end
    if data.group then remoteFire(data.group.claimReward) end
    if data.follow then remoteFire(data.follow.claimReward) end
    if data.index then
        remoteFire(data.index.claimMoney)
        remoteFire(data.index.claimFullReward)
        for _, zone in ipairs(ZoneKeys) do
            remoteFire(data.index.claimZoneReward, zone)
            task.wait(0.025)
        end
    end
    if gameR and gameR.wheels then remoteFire(gameR.wheels.claimReward) end
    if data.fuse then remoteFire(data.fuse.claimFuse) end
end

Runtime.__rs_redeemAllCodes = function()
    if not Remotes or not Remotes.data.codes then return end
    task.spawn(function()
        setAction("Redeeming codes")
        for _, key in ipairs(CodeKeys) do
            remoteFire(Remotes.data.codes.redeemCode, key)
            task.wait(0.25)
        end
        setAction("Ready")
        notify("Redeem All Codes sent")
    end)
end

Runtime.__rs_teleportZone = function(display)
    local key = ZoneKeyByDisplay[display] or tostring(display or ""):lower()
    if key ~= "" and Remotes and Remotes.game and Remotes.game.teleport then
        remoteFire(Remotes.game.teleport.teleportTo, key)
    end
end

Runtime.__rs_upgradeOnce = function(name)
    if not Remotes or not Remotes.data or not Remotes.data.upgrades then return end
    local amount = Config.UpgradeMode == "Buy Max" and 10 or 1
    if amount == 1 then
        remoteFire(Remotes.data.upgrades.upgrade, name, 1)
    else
        for _ = 1, amount do
            remoteFire(Remotes.data.upgrades.upgrade, name, 1)
            task.wait(0.07)
        end
    end
end

Runtime.__rs_baseUpgradeOnce = function()
    if not Remotes then return end
    local repeats = Config.UpgradeMode == "Buy Max" and 8 or 1
    for _ = 1, repeats do
        remoteFire(Remotes.data.base.upgradeBase)
        if repeats > 1 then task.wait(0.10) end
    end
end

Runtime.__rs_runUpgradeCycle = function()
    local priority = Config.UpgradePriority
    if priority == "Speed" then
        if Config.AutoSpeedUpgrade then Runtime.__rs_upgradeOnce("speedMultiplier") end
        if Config.AutoTreadmillUpgrade then Runtime.__rs_upgradeOnce("treadmill") end
        if Config.AutoBaseUpgrade then Runtime.__rs_baseUpgradeOnce() end
    elseif priority == "Base" then
        if Config.AutoBaseUpgrade then Runtime.__rs_baseUpgradeOnce() end
        if Config.AutoTreadmillUpgrade then Runtime.__rs_upgradeOnce("treadmill") end
        if Config.AutoSpeedUpgrade then Runtime.__rs_upgradeOnce("speedMultiplier") end
    else
        if Config.AutoTreadmillUpgrade then Runtime.__rs_upgradeOnce("treadmill") end
        if Config.AutoSpeedUpgrade then Runtime.__rs_upgradeOnce("speedMultiplier") end
        if Config.AutoBaseUpgrade then Runtime.__rs_baseUpgradeOnce() end
    end
end

Runtime.__rs_scanGuardPart = function(inst)
    if not inst or not inst:IsA("BasePart") then return end
    local ok, group = pcall(function() return inst.CollisionGroup end)
    if ok and group == "Guard" then Runtime.guardParts[inst] = true end
end
for _, inst in ipairs(workspace:GetDescendants()) do Runtime.__rs_scanGuardPart(inst) end
rememberConnection(workspace.DescendantAdded:Connect(Runtime.__rs_scanGuardPart))

Runtime.__rs_nearestGuardDistance = function()
    local root = rootPart()
    if not root then return math.huge end
    local best = math.huge
    for part in pairs(Runtime.guardParts) do
        if part and part.Parent then
            local d = (root.Position - part.Position).Magnitude
            if d < best then best = d end
        end
    end
    return best
end

Runtime.__rs_hookCharacterManager = function()
    local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local module = scripts and findModule(scripts, "characterManager")
    local manager = safeRequire(module)
    if type(manager) ~= "table" or type(manager.applyForce) ~= "function" then return false end
    Runtime.characterManager = manager
    Runtime.originalApplyForce = manager.applyForce
    manager.applyForce = function(...)
        if Runtime.alive and (Config.AntiKnockback or Config.AntiGuard) then
            setAction("Blocked knockback")
            return false
        end
        return Runtime.originalApplyForce(...)
    end
    return true
end

Runtime.__rs_restoreCharacterManager = function()
    if Runtime.characterManager and Runtime.originalApplyForce then
        pcall(function() Runtime.characterManager.applyForce = Runtime.originalApplyForce end)
    end
    Runtime.characterManager = nil
    Runtime.originalApplyForce = nil
end

Runtime.__rs_applyCharacterOverrides = function()
    local hum = humanoid()
    local root = rootPart()
    if hum then
        if Config.WalkSpeedOverride then pcall(function() hum.WalkSpeed = Config.WalkSpeed end) end
        if Config.JumpPowerOverride then
            pcall(function()
                hum.UseJumpPower = true
                hum.JumpPower = Config.JumpPower
            end)
        end
    end
    if root and (Config.AntiKnockback or Config.AntiGuard) then
        if root.AssemblyLinearVelocity.Magnitude > 140 then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

Runtime.__rs_applyNoclip = function()
    local char = character()
    if not char then return end
    if Config.Noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if Runtime.noclipOriginal[part] == nil then Runtime.noclipOriginal[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    else
        for part, original in pairs(Runtime.noclipOriginal) do
            if part and part.Parent then pcall(function() part.CanCollide = original end) end
            Runtime.noclipOriginal[part] = nil
        end
    end
end

rememberConnection(UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = humanoid()
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end))

-- White Screen.
Runtime.__rs_destroyWhiteScreen = function()
    if Runtime.whiteScreen and Runtime.whiteScreen.Parent then pcall(function() Runtime.whiteScreen:Destroy() end) end
    Runtime.whiteScreen = nil
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    if type(setfpscap) == "function" then pcall(setfpscap, 60) end
end

Runtime.__rs_setWhiteScreen = function(enabled)
    if not enabled then Runtime.__rs_destroyWhiteScreen() return end
    Runtime.__rs_destroyWhiteScreen()
    local root = nil
    if type(gethui) == "function" then local ok, r = pcall(gethui); if ok then root = r end end
    root = root or LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "AliceHUB_WhiteScreen"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 2147483000
    gui.Parent = root
    Runtime.whiteScreen = gui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1,1)
    bg.BackgroundColor3 = Color3.new(0,0,0)
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5,0.5)
    title.Position = UDim2.fromScale(0.5,0.46)
    title.Size = UDim2.fromOffset(420,40)
    title.BackgroundTransparency = 1
    title.Text = "AliceHUB"
    title.TextColor3 = Color3.fromRGB(242,236,239)
    title.TextSize = 24
    title.Font = Enum.Font.Code
    title.Parent = bg

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5,0.5)
    sub.Position = UDim2.fromScale(0.5,0.52)
    sub.Size = UDim2.fromOffset(520,50)
    sub.BackgroundTransparency = 1
    sub.Text = "Steal a Chicken | White Screen"
    sub.TextColor3 = Color3.fromRGB(181,126,143)
    sub.TextSize = 13
    sub.Font = Enum.Font.Code
    sub.Parent = bg

    local exit = Instance.new("TextButton")
    exit.AnchorPoint = Vector2.new(0.5,0.5)
    exit.Position = UDim2.fromScale(0.5,0.61)
    exit.Size = UDim2.fromOffset(170,34)
    exit.BackgroundColor3 = Color3.fromRGB(35,23,28)
    exit.TextColor3 = Color3.fromRGB(242,236,239)
    exit.Text = "Exit White Screen"
    exit.TextSize = 12
    exit.Font = Enum.Font.Code
    exit.BorderSizePixel = 0
    exit.Parent = bg
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = exit
    exit.Activated:Connect(function()
        Config.WhiteScreen = false
        queueSave()
        if Library.Toggles.SAC_WhiteScreen then Library.Toggles.SAC_WhiteScreen:SetValue(false) else Runtime.__rs_destroyWhiteScreen() end
    end)

    pcall(function() RunService:Set3dRenderingEnabled(false) end)
    if type(setfpscap) == "function" then pcall(setfpscap, 10) end
end

-- Ultra Performance. Changes are intentionally one-way until rejoin for stability.
Runtime.__rs_disconnectUltraConnections = function()
    for _, conn in ipairs(Runtime.ultraConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(Runtime.ultraConnections)
end

Runtime.__rs_shouldProtectVisual = function(inst)
    local char = character()
    if char and inst:IsDescendantOf(char) then return true end
    if Library.ScreenGui and inst:IsDescendantOf(Library.ScreenGui) then return true end
    if logoGui and inst:IsDescendantOf(logoGui) then return true end
    if Runtime.whiteScreen and inst:IsDescendantOf(Runtime.whiteScreen) then return true end
    return false
end

Runtime.__rs_optimizeUltraInstance = function(inst)
    if not inst or Runtime.__rs_shouldProtectVisual(inst) then return end
    if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
        inst.Enabled = false
    elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
        inst.Enabled = false
    elseif inst:IsA("PostEffect") then
        inst.Enabled = false
    elseif inst:IsA("Atmosphere") then
        inst.Density = 0
        inst.Haze = 0
    elseif inst:IsA("Clouds") then
        inst.Enabled = false
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        inst.Transparency = 1
    elseif inst:IsA("SurfaceAppearance") then
        pcall(function() inst:Destroy() end)
    elseif inst:IsA("MeshPart") then
        pcall(function() inst.TextureID = "" end)
        inst.CastShadow = false
    elseif inst:IsA("BasePart") then
        inst.CastShadow = false
        inst.Material = Enum.Material.SmoothPlastic
        inst.Reflectance = 0
    end
end

Runtime.__rs_setUltraPerformance = function(enabled)
    Runtime.__rs_disconnectUltraConnections()
    Runtime.ultraGeneration = Runtime.ultraGeneration + 1
    if not enabled then
        setAction("Ultra Performance off | rejoin restores visuals")
        return
    end
    local generation = Runtime.ultraGeneration
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
    end)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        pcall(function()
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.Decoration = false
        end)
    end
    task.spawn(function()
        local list = workspace:GetDescendants()
        local i = 1
        while Runtime.alive and Config.UltraPerformance and generation == Runtime.ultraGeneration and i <= #list do
            for _ = 1, 300 do
                local inst = list[i]
                if not inst then break end
                pcall(Runtime.__rs_optimizeUltraInstance, inst)
                i = i + 1
            end
            RunService.Heartbeat:Wait()
        end
        if Runtime.alive and Config.UltraPerformance and generation == Runtime.ultraGeneration then
            setAction("Ultra Performance active")
        end
    end)
    Runtime.ultraConnections[#Runtime.ultraConnections + 1] = workspace.DescendantAdded:Connect(function(inst)
        if Runtime.alive and Config.UltraPerformance and generation == Runtime.ultraGeneration then
            task.defer(function() pcall(Runtime.__rs_optimizeUltraInstance, inst) end)
        end
    end)
    Runtime.ultraConnections[#Runtime.ultraConnections + 1] = Lighting.ChildAdded:Connect(function(inst)
        if Runtime.alive and Config.UltraPerformance and generation == Runtime.ultraGeneration then
            task.defer(function() pcall(Runtime.__rs_optimizeUltraInstance, inst) end)
        end
    end)
end

-- UI binding / autosave.
local Controls = {}
local applyingControls = false

Runtime.__rs_bindToggle = function(box, id, key, text, callback)
    local opt = box:AddToggle(id, {Text = text, Default = Config[key] == true})
    Controls[key] = opt
    opt:OnChanged(function(value)
        Config[key] = value == true
        if not applyingControls then queueSave() end
        if callback then pcall(callback, Config[key]) end
    end)
    return opt
end

Runtime.__rs_bindSlider = function(box, id, key, text, min, max, rounding, suffix, callback)
    local opt = box:AddSlider(id, {Text = text, Min = min, Max = max, Default = tonumber(Config[key]) or min, Rounding = rounding or 0, Suffix = suffix or ""})
    Controls[key] = opt
    opt:OnChanged(function(value)
        Config[key] = tonumber(value) or Config[key]
        if not applyingControls then queueSave() end
        if callback then pcall(callback, Config[key]) end
    end)
    return opt
end

Runtime.__rs_bindDropdown = function(box, id, key, text, values, multi, callback)
    local default = Config[key]
    if multi and type(default) ~= "table" then default = {} end
    local opt = box:AddDropdown(id, {Text = text, Values = values, Default = default, Multi = multi == true})
    Controls[key] = opt
    opt:OnChanged(function(value)
        if multi and type(value) == "table" then Config[key] = table.clone(value) else Config[key] = value end
        if not applyingControls then queueSave() end
        if callback then pcall(callback, Config[key]) end
    end)
    return opt
end

Runtime.__rs_applyConfigToControls = function()
    applyingControls = true
    for key, opt in pairs(Controls) do
        if opt and type(opt.SetValue) == "function" and Config[key] ~= nil then
            pcall(opt.SetValue, opt, Config[key])
        end
    end
    applyingControls = false
end

local Tabs = {
    Main = window:AddTab("Main"),
    Eggs = window:AddTab("Eggs"),
    Upgrade = window:AddTab("Upgrade"),
    Player = window:AddTab("Player"),
    Misc = window:AddTab("Misc"),
    Settings = window:AddTab("Settings"),
}

local MainSteal = Tabs.Main:AddLeftGroupbox("Steal")
local MainReturn = Tabs.Main:AddLeftGroupbox("Return")
local MainStatus = Tabs.Main:AddRightGroupbox("Status")

Runtime.__rs_bindToggle(MainSteal, "SAC_AutoSteal", "AutoSteal", "Auto Steal Chicken")
Runtime.__rs_bindDropdown(MainSteal, "SAC_TargetPriority", "TargetPriority", "Target Priority", {"Nearest", "Highest Rarity", "Highest Value"}, false)
local rarityFilterControl = Runtime.__rs_bindDropdown(MainSteal, "SAC_RarityFilter", "RarityFilter", "Rarity Filter", RarityNames, true)
Runtime.__rs_bindToggle(MainSteal, "SAC_IncludeInsane", "IncludeInsane", "Include Insane Chicken")
Runtime.__rs_bindDropdown(MainSteal, "SAC_Movement", "MovementMode", "Movement", {"Instant TP", "Tween", "Smart"}, false)
Runtime.__rs_bindSlider(MainSteal, "SAC_TweenSpeed", "TweenSpeed", "Tween Speed", 50, 2500, 0, "")
Runtime.__rs_bindSlider(MainSteal, "SAC_StealDelay", "StealDelay", "Steal Delay", 0.15, 3, 2, "s")
MainSteal:AddButton({Text = "Steal Best Now", Func = function()
    task.spawn(function()
        local target = Runtime.__rs_findBestTarget()
        if target then Runtime.__rs_stealTarget(target) else notify("No matching chicken found") end
    end)
end})

Runtime.__rs_bindToggle(MainReturn, "SAC_AutoReturn", "AutoReturn", "Auto Return To Base")
Runtime.__rs_bindToggle(MainReturn, "SAC_AutoDrop", "AutoDrop", "Auto Drop Chicken")
Runtime.__rs_bindToggle(MainReturn, "SAC_AutoRecover", "AutoRecover", "Auto Recover Chicken")
Runtime.__rs_bindSlider(MainReturn, "SAC_ReturnDelay", "ReturnDelay", "Return Delay", 0, 2, 2, "s")
MainReturn:AddButton({Text = "Teleport To Base", Func = function() task.spawn(function() moveToBase(true) end) end})
MainReturn:AddButton({Text = "Drop Chicken Now", Func = function() task.spawn(function() Runtime.__rs_dropAtBase(true) end) end})

local StatusBackend = MainStatus:AddLabel("Backend: loading", true)
local StatusAction = MainStatus:AddLabel("Action: initializing", true)
local StatusTarget = MainStatus:AddLabel("Target: -", true)
local StatusHolding = MainStatus:AddLabel("Holding: -", true)
local StatusPen = MainStatus:AddLabel("Pen: -", true)

local EggCollect = Tabs.Eggs:AddLeftGroupbox("Collect")
local EggSell = Tabs.Eggs:AddRightGroupbox("Sell")
Runtime.__rs_bindToggle(EggCollect, "SAC_AutoCollect", "AutoCollectEggs", "Auto Collect Eggs")
Runtime.__rs_bindSlider(EggCollect, "SAC_CollectDelay", "CollectDelay", "Collect Delay", 0.55, 5, 2, "s")
Runtime.__rs_bindToggle(EggCollect, "SAC_AutoOpen", "AutoOpenEggs", "Auto Open Eggs")
Runtime.__rs_bindSlider(EggCollect, "SAC_OpenDelay", "OpenDelay", "Open Delay", 0.25, 5, 2, "s")
EggCollect:AddButton({Text = "Collect All Now", Func = function() if Remotes then remoteFire(Remotes.data.base.claimAllEggs) end end})
EggCollect:AddButton({Text = "Open Eggs Now", Func = function() task.spawn(Runtime.__rs_openEggsOnce) end})

Runtime.__rs_bindToggle(EggSell, "SAC_AutoSell", "AutoSell", "Auto Sell")
Runtime.__rs_bindDropdown(EggSell, "SAC_SellMode", "SellMode", "Sell Mode", {"Sell All", "Selected Rarity", "Keep Selected Rarity"}, false)
local sellRarityControl = Runtime.__rs_bindDropdown(EggSell, "SAC_SellRarity", "SellRarity", "Sell Rarity", RarityNames, true)
Runtime.__rs_bindSlider(EggSell, "SAC_SellDelay", "SellDelay", "Sell Delay", 0.6, 8, 2, "s")
Runtime.__rs_bindToggle(EggSell, "SAC_NeverSellFavorites", "NeverSellFavorites", "Never Sell Favorites")
EggSell:AddButton({Text = "Sell Now", Func = function() task.spawn(Runtime.__rs_sellSelectedEggs) end})

local UpgradeMain = Tabs.Upgrade:AddLeftGroupbox("Automation")
local UpgradeSettings = Tabs.Upgrade:AddRightGroupbox("Settings")
Runtime.__rs_bindToggle(UpgradeMain, "SAC_AutoTreadmillUpgrade", "AutoTreadmillUpgrade", "Auto Treadmill")
Runtime.__rs_bindToggle(UpgradeMain, "SAC_AutoSpeedUpgrade", "AutoSpeedUpgrade", "Auto Speed Upgrade")
Runtime.__rs_bindToggle(UpgradeMain, "SAC_AutoBaseUpgrade", "AutoBaseUpgrade", "Auto Base Upgrade")
Runtime.__rs_bindDropdown(UpgradeSettings, "SAC_UpgradePriority", "UpgradePriority", "Upgrade Priority", {"Speed", "Base", "Balanced"}, false)
Runtime.__rs_bindDropdown(UpgradeSettings, "SAC_UpgradeMode", "UpgradeMode", "Upgrade Mode", {"Buy 1", "Buy Max"}, false)
Runtime.__rs_bindSlider(UpgradeSettings, "SAC_UpgradeDelay", "UpgradeDelay", "Upgrade Delay", 0.3, 10, 2, "s")
UpgradeSettings:AddButton({Text = "Run Upgrade Cycle", Func = function() task.spawn(Runtime.__rs_runUpgradeCycle) end})

local PlayerMove = Tabs.Player:AddLeftGroupbox("Movement")
local PlayerSafety = Tabs.Player:AddRightGroupbox("Safety")
Runtime.__rs_bindToggle(PlayerMove, "SAC_WalkOverride", "WalkSpeedOverride", "WalkSpeed Override")
Runtime.__rs_bindSlider(PlayerMove, "SAC_WalkSpeed", "WalkSpeed", "WalkSpeed", 16, 200, 0, "")
Runtime.__rs_bindToggle(PlayerMove, "SAC_JumpOverride", "JumpPowerOverride", "JumpPower Override")
Runtime.__rs_bindSlider(PlayerMove, "SAC_JumpPower", "JumpPower", "JumpPower", 50, 200, 0, "")
Runtime.__rs_bindToggle(PlayerMove, "SAC_InfiniteJump", "InfiniteJump", "Infinite Jump")
Runtime.__rs_bindToggle(PlayerMove, "SAC_Noclip", "Noclip", "Noclip", function(value) if not value then Runtime.__rs_applyNoclip() end end)
Runtime.__rs_bindToggle(PlayerSafety, "SAC_AntiGuard", "AntiGuard", "Anti Guard")
Runtime.__rs_bindToggle(PlayerSafety, "SAC_AntiKnockback", "AntiKnockback", "Anti Knockback")
PlayerSafety:AddButton({Text = "Teleport To Base", Func = function() task.spawn(function() moveToBase(true) end) end})

local MiscReward = Tabs.Misc:AddLeftGroupbox("Rewards")
local MiscUtility = Tabs.Misc:AddRightGroupbox("Utility")
Runtime.__rs_bindToggle(MiscReward, "SAC_AutoClaimAll", "AutoClaimAll", "Auto Claim All")
Runtime.__rs_bindToggle(MiscReward, "SAC_AutoSpin", "AutoSpinWheel", "Auto Spin Wheel")
Runtime.__rs_bindToggle(MiscReward, "SAC_AutoClaimFuse", "AutoClaimFuse", "Auto Claim Fuse")
MiscReward:AddButton({Text = "Claim All Now", Func = function() task.spawn(Runtime.__rs_claimAllOnce) end})
MiscReward:AddButton({Text = "Redeem All Codes", Func = Runtime.__rs_redeemAllCodes})

Runtime.__rs_bindToggle(MiscUtility, "SAC_AutoEquipBest", "AutoEquipBest", "Auto Equip Best Chicken")
MiscUtility:AddButton({Text = "Equip Best Chicken", Func = function()
    if Remotes then remoteFire(Remotes.data.base.equipBestChickens) end
end})
local zoneDD = Runtime.__rs_bindDropdown(MiscUtility, "SAC_TeleportZone", "TeleportZone", "Teleport Zone", #ZoneDisplay > 0 and ZoneDisplay or {"Forest", "Lake", "Jungle", "Desert", "Snow", "Volcano", "Beach", "Abyss", "Cosmic", "Crystal"}, false)
MiscUtility:AddButton({Text = "Teleport To Zone", Func = function() Runtime.__rs_teleportZone(Config.TeleportZone) end})
MiscUtility:AddButton({Text = "Refresh Nests", Func = function() if Remotes then remoteFire(Remotes.game.nests.refreshNests) end end})

local SettingsUtility = Tabs.Settings:AddLeftGroupbox("Utility")
local SettingsPerformance = Tabs.Settings:AddLeftGroupbox("Performance")
local SettingsConfig = Tabs.Settings:AddRightGroupbox("AliceHUB")

Runtime.__rs_bindToggle(SettingsUtility, "SAC_AntiAFK", "AntiAFK", "Anti AFK")
Runtime.__rs_bindToggle(SettingsUtility, "SAC_WhiteScreen", "WhiteScreen", "White Screen", Runtime.__rs_setWhiteScreen)
Runtime.__rs_bindToggle(SettingsUtility, "SAC_AutoReconnect", "AutoReconnect", "Auto Reconnect")
Runtime.__rs_bindToggle(SettingsPerformance, "SAC_UltraPerformance", "UltraPerformance", "Ultra Performance", Runtime.__rs_setUltraPerformance)

SettingsConfig:AddLabel("Steal a Chicken", true)
SettingsConfig:AddLabel("UI: AliceHUB / SAE", true)
SettingsConfig:AddLabel("Config saves automatically", true)
SettingsConfig:AddButton({Text = "Load Config", Func = function()
    local data = readConfig()
    if data and applyLoadedConfig(data) then
        Runtime.__rs_applyConfigToControls()
        notify("Config loaded")
    else
        notify("No saved config found")
    end
end})
SettingsConfig:AddButton({Text = "Reset Config", Func = function()
    for k, v in pairs(Defaults) do
        Config[k] = type(v) == "table" and table.clone(v) or v
    end
    Runtime.__rs_applyConfigToControls()
    saveConfig()
    notify("Config reset")
end})
SettingsConfig:AddButton({Text = "Rejoin", Func = function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end})
SettingsConfig:AddButton({Text = "Server Hop", Func = function()
    task.spawn(function()
        local ok, body = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100")
        end)
        if not ok then notify("Server Hop request failed") return end
        local okDecode, data = pcall(HttpService.JSONDecode, HttpService, body)
        if not okDecode or type(data) ~= "table" or type(data.data) ~= "table" then notify("Server Hop data failed") return end
        for _, server in ipairs(data.data) do
            if server.id and server.id ~= game.JobId and tonumber(server.playing) and tonumber(server.maxPlayers) and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                return
            end
        end
        notify("No open server found")
    end)
end})
SettingsConfig:AddButton({Text = "Hide / Show UI", Func = function() Library:Toggle() end})

-- Dynamic values are refreshed after backend resolves.
Runtime.__rs_refreshDynamicControls = function()
    if rarityFilterControl and type(rarityFilterControl.SetValues) == "function" then rarityFilterControl:SetValues(RarityNames) end
    if sellRarityControl and type(sellRarityControl.SetValues) == "function" then sellRarityControl:SetValues(RarityNames) end
    if zoneDD and type(zoneDD.SetValues) == "function" and #ZoneDisplay > 0 then zoneDD:SetValues(ZoneDisplay) end
end

-- Backend init runs after UI so the menu always appears on mobile executors.
task.spawn(function()
    setAction("Loading game backend")
    local ok, err = initBackend()
    Runtime.backendReady = ok
    Runtime.backendError = ok and nil or err
    if ok then
        Runtime.__rs_refreshDynamicControls()
        Runtime.__rs_hookCharacterManager()
        setAction("Ready")
        notify("Steal a Chicken backend ready", 3)
    else
        setAction("Backend error")
        notify("Backend: " .. tostring(err), 7)
    end
end)

-- Main steal worker. Pen capacity is intentionally NOT a farming gate: when the pen
-- is full, stolen chickens can still be kept in backpack/inventory for Equip Best or trade.
task.spawn(function()
    while Runtime.alive do
        if Runtime.backendReady and Config.AutoSteal and not Runtime.stealing and not Runtime.moving and os.clock() >= (Runtime.nextStealAt or 0) then
            if isHolding() and Config.AutoReturn then
                if Config.AutoDrop then Runtime.__rs_dropAtBase(false) else moveToBase(false) end
                Runtime.nextStealAt = os.clock() + 0.25
            else
                local target = Runtime.__rs_findBestTarget()
                if target then
                    Runtime.__rs_stealTarget(target)
                else
                    setAction("Waiting for matching chicken")
                    task.wait(0.6)
                end
            end
        end
        task.wait(0.08)
    end
end)

-- Egg collection worker.
task.spawn(function()
    while Runtime.alive do
        if Runtime.backendReady and Config.AutoCollectEggs then
            remoteFire(Remotes.data.base.claimAllEggs)
            task.wait(math.max(0.55, tonumber(Config.CollectDelay) or 0.75))
        else
            task.wait(0.35)
        end
    end
end)

-- Egg open worker.
task.spawn(function()
    while Runtime.alive do
        if Runtime.backendReady and Config.AutoOpenEggs then
            Runtime.__rs_openEggsOnce()
            task.wait(math.max(0.25, tonumber(Config.OpenDelay) or 0.35))
        else
            task.wait(0.45)
        end
    end
end)

-- Sell worker.
task.spawn(function()
    while Runtime.alive do
        if Runtime.backendReady and Config.AutoSell then
            Runtime.__rs_sellSelectedEggs()
            task.wait(math.max(0.6, tonumber(Config.SellDelay) or 1))
        else
            task.wait(0.45)
        end
    end
end)

-- Upgrade worker.
task.spawn(function()
    while Runtime.alive do
        if Runtime.backendReady and (Config.AutoTreadmillUpgrade or Config.AutoSpeedUpgrade or Config.AutoBaseUpgrade) then
            Runtime.__rs_runUpgradeCycle()
            task.wait(math.max(0.3, tonumber(Config.UpgradeDelay) or 1.25))
        else
            task.wait(0.5)
        end
    end
end)

-- Reward / misc worker.
task.spawn(function()
    local lastClaim, lastSpin, lastEquip, lastFuse = 0, 0, 0, 0
    while Runtime.alive do
        local now = os.clock()
        if Runtime.backendReady then
            if Config.AutoClaimAll and now - lastClaim >= 10 then
                lastClaim = now
                task.spawn(Runtime.__rs_claimAllOnce)
            end
            if Config.AutoSpinWheel and now - lastSpin >= 12 then
                lastSpin = now
                remoteRequest(Remotes.game.wheels.spinWheel, "dailyWheel")
                task.wait(0.2)
                remoteFire(Remotes.game.wheels.claimReward)
            end
            if Config.AutoEquipBest and now - lastEquip >= 5 then
                lastEquip = now
                remoteFire(Remotes.data.base.equipBestChickens)
            end
            if Config.AutoClaimFuse and now - lastFuse >= 4 then
                lastFuse = now
                remoteFire(Remotes.data.fuse.claimFuse)
            end
        end
        task.wait(0.4)
    end
end)

-- Guard safety: when carrying and a guard is very close, snap home before force/drop resolves.
task.spawn(function()
    while Runtime.alive do
        if Runtime.backendReady and Config.AntiGuard and isHolding() then
            local distance = Runtime.__rs_nearestGuardDistance()
            if distance <= 18 then
                setAction("Guard close | returning")
                if Config.AutoDrop then Runtime.__rs_dropAtBase(true) else moveToBase(true) end
                task.wait(0.5)
            else
                task.wait(0.10)
            end
        else
            task.wait(0.25)
        end
    end
end)

-- Character overrides / noclip.
rememberConnection(RunService.Stepped:Connect(function()
    if not Runtime.alive then return end
    pcall(Runtime.__rs_applyCharacterOverrides)
    pcall(Runtime.__rs_applyNoclip)
end))

-- Anti AFK: event fallback + timed pulse.
rememberConnection(LocalPlayer.Idled:Connect(function()
    if not Config.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
end))
task.spawn(function()
    while Runtime.alive do
        task.wait(45)
        if Config.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end)
        end
    end
end)

-- Reconnect after Roblox error prompt.
local promptOverlay = getPath(CoreGui, "RobloxPromptGui", "promptOverlay")
if promptOverlay then
    rememberConnection(promptOverlay.ChildAdded:Connect(function(child)
        if not Config.AutoReconnect or not Runtime.alive then return end
        if not child:IsA("Frame") or child.Name ~= "ErrorPrompt" then return end
        task.delay(2.5, function()
            if Runtime.alive and Config.AutoReconnect then
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        end)
    end))
end

-- Status worker.
task.spawn(function()
    while Runtime.alive do
        if StatusBackend and type(StatusBackend.SetText) == "function" then
            StatusBackend:SetText("Backend: " .. (Runtime.backendReady and "ready" or (Runtime.backendError and "error" or "loading")))
        end
        if StatusAction and type(StatusAction.SetText) == "function" then StatusAction:SetText("Action: " .. tostring(Runtime.action)) end
        if StatusTarget and type(StatusTarget.SetText) == "function" then StatusTarget:SetText("Target: " .. tostring(Runtime.target)) end
        if StatusHolding and type(StatusHolding.SetText) == "function" then
            local item = getHoldingItem()
            local reward = getYeetReward()
            local text = "None"
            if type(reward) == "table" then
                local chicken = reward.chicken or reward.egg or reward.reward
                if type(chicken) == "table" and chicken.name then
                    text = tostring(chicken.name)
                else
                    text = "Stolen Chicken"
                end
            elseif type(item) == "table" then
                if item.chicken and item.chicken.name then text = tostring(item.chicken.name)
                elseif item.egg and item.egg.name then text = tostring(item.egg.name)
                else text = tostring(item.type or "Yes") end
            elseif item ~= nil then
                text = "Yes"
            end
            StatusHolding:SetText("Holding: " .. text)
        end
        if StatusPen and type(StatusPen.SetText) == "function" then
            local count, max = getPenCapacity()
            StatusPen:SetText(string.format("Pen: %s/%s", tostring(count or "?"), tostring(max or "?")))
        end
        task.wait(0.5)
    end
end)

-- Apply loaded visual/performance settings after controls exist.
if Config.WhiteScreen then task.defer(function() Runtime.__rs_setWhiteScreen(true) end) end
if Config.UltraPerformance then task.defer(function() Runtime.__rs_setUltraPerformance(true) end) end

Runtime.__rs_cleanup = function()
    if not Runtime.alive then return end
    Runtime.alive = false
    cancelTween()
    saveConfig()
    Runtime.__rs_restoreCharacterManager()
    Runtime.__rs_disconnectUltraConnections()
    Runtime.__rs_destroyWhiteScreen()
    Config.Noclip = false
    pcall(Runtime.__rs_applyNoclip)
    for _, conn in ipairs(Runtime.connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Runtime.connections)
    if logoGui and logoGui.Parent then pcall(function() logoGui:Destroy() end) end
    pcall(function() Library:Unload() end)
    if ENV.AliceHUB_StealAChicken_Cleanup == Runtime.__rs_cleanup then ENV.AliceHUB_StealAChicken_Cleanup = nil end
end

ENV.AliceHUB_StealAChicken_Cleanup = Runtime.__rs_cleanup
ENV.AliceHUB_StealAChicken = {
    Cleanup = Runtime.__rs_cleanup,
    Config = Config,
    State = Runtime,
    StealBest = function()
        local target = Runtime.__rs_findBestTarget()
        if target then return Runtime.__rs_stealTarget(target) end
        return false
    end,
}

print("[AliceHUB] Steal a Chicken loaded")
