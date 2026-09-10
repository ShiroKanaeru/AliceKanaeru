-- AliceHUB v3.0.3 · Register-Safe TEST · pullanegg.lua
-- Late chunk-scope helpers moved into State namespace for executor compiler compatibility.
-- Logic/UI behavior intentionally unchanged.

--[[
    AliceHUB · Pull An Egg
    V5 RELAY DROP FIX · SAE / Anime Dice V7 exact native UI + direct backend
    PlaceId: 70640255604878

    UI renderer is the same AliceHUB native renderer used by the current SAE build.
    Game backend initializes after the UI so the menu remains visible even while
    Pull An Egg's client library/plot is still loading.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ENV = (getgenv and getgenv()) or _G

if type(ENV.AliceHUB_PullAnEgg_Cleanup) == "function" then
    pcall(ENV.AliceHUB_PullAnEgg_Cleanup)
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
    "Pull An Egg",
    "AliceHUB_PullAnEgg_NativeUI",
    ALICE_LOGO_ASSET
)

local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280,720)
local compact = viewport.X <= 1700 and viewport.Y <= 900
local window = Library:CreateWindow({
    Title = "AliceHUB",
    Size = UDim2.fromOffset(compact and 700 or 900, compact and 500 or 620),
    CornerRadius = 4,
})

-- Floating Alice logo, same behavior as the other AliceHUB games.
local logoGui = Instance.new("ScreenGui")
logoGui.Name = "AliceHUB_PullAnEgg_LogoGui"
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
logoGui.Parent = logoRoot

local oldLogo = logoRoot:FindFirstChild("AliceHUBLogoButton")
if oldLogo and oldLogo ~= logoGui then pcall(function() oldLogo:Destroy() end) end

local logo = Instance.new("ImageButton")
logo.Name = "AliceHUBLogoButton"
logo.AnchorPoint = Vector2.new(0, 0.5)
logo.Position = UDim2.new(0, 14, 0.5, 0)
logo.Size = UDim2.fromOffset(62, 62)
logo.BackgroundColor3 = Color3.fromRGB(24,15,19)
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

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1,0)
    c.Parent = logo
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(181,48,83)
    s.Thickness = 2
    s.Transparency = 0.08
    s.Parent = logo
end

local logoDragging = false
local logoMoved = false
local logoStart, logoPos
logo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = true
        logoMoved = false
        logoStart = input.Position
        logoPos = logo.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                logoDragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if logoDragging and logoStart and logoPos
        and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - logoStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then logoMoved = true end
        logo.Position = UDim2.new(
            logoPos.X.Scale, logoPos.X.Offset + delta.X,
            logoPos.Y.Scale, logoPos.Y.Offset + delta.Y
        )
    end
end)
logo.Activated:Connect(function()
    if logoMoved then
        logoMoved = false
        return
    end
    Library:Toggle()
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Library:Toggle()
    end
end)

local Config = {
    AutoTrain = false,
    TrainDelay = 0.50,
    AutoBuyBestDumbell = false,

    AutoPull = false,
    EggChoice = "Any",
    SmartStrengthTarget = true,
    AutoPlace = true,
    AutoOpen = true,
    AutoEquipBest = false,

    AutoCollect = false,
    AutoUpgradePets = false,
    AutoSell = false,
    SellMaxRarity = "Common",

    AutoRebirth = false,
    StopRebirth = 0,
    AutoCarry = false,
    AutoDaily = false,
    AutoGroup = false,
    AutoClaimIndex = false,
    AutoBuyGear = false,
    AutoBestWorld = false,

    MovementMode = "Tween",
    TweenSpeed = 300,
    WalkTimeout = 12,

    WhiteScreen = false,
    AntiMonsterHit = true,
    AutoRejoin = false,
    RejoinMinutes = 17,
}

local defaults = {}
for k,v in pairs(Config) do defaults[k] = v end

local CONFIG_DIR = "AliceHUB"
local CONFIG_FILE = CONFIG_DIR .. "/PullAnEgg.json"
local saveQueued = false

local function loadConfig()
    if not (type(isfile) == "function" and type(readfile) == "function") then return end
    local okE, exists = pcall(isfile, CONFIG_FILE)
    if not okE or not exists then return end
    local okR, raw = pcall(readfile, CONFIG_FILE)
    if not okR or type(raw) ~= "string" then return end
    local okD, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okD or type(data) ~= "table" then return end
    for k,v in pairs(data) do
        if defaults[k] ~= nil then Config[k] = v end
    end
end

local function saveConfig()
    if type(writefile) ~= "function" then return false end
    pcall(function()
        if type(makefolder) == "function" then
            if type(isfolder) ~= "function" or not isfolder(CONFIG_DIR) then
                makefolder(CONFIG_DIR)
            end
        end
    end)
    local okE, encoded = pcall(HttpService.JSONEncode, HttpService, Config)
    if not okE then return false end
    return pcall(writefile, CONFIG_FILE, encoded)
end

local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.55, function()
        saveQueued = false
        saveConfig()
    end)
end

loadConfig()

local State = {
    Running = true,
    Ready = false,
    InitStatus = "Waiting for game client...",
    Pulling = false,
    Moving = false,
    Action = "Loading...",
    LastEgg = "-",
    LastEggRequirement = "-",
    BestWorld = "-",
    Holding = false,
    HeldUID = nil,
    LastError = "-",
    SessionStart = os.clock(),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- V3 backend:
-- Do NOT depend on the game's LocalScript _G. Exploit/executor _G may be isolated.
-- We talk directly to SharedModules.Network.Remotes and locate the player's plot.
local Lib = {Database = {}}
local Database = {}
local RemoteFolder = nil
local DataGetRemote = nil
local MyPlot, Base, Live, WorldFriends, PlayerFriendsRoot, MyPlayerFriends
local R = {}

local DataCache = nil
local DataCacheAt = 0

local function notify(title, body, dur)
    pcall(function()
        Library:Notify({
            Title = title or "AliceHUB",
            Description = tostring(body or ""),
            Time = dur or 4,
        })
    end)
end

local function setAction(text)
    State.Action = tostring(text or "Idle")
end

local function findMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:FindFirstChild("owner")
        if owner then
            local ok, value = pcall(function() return owner.Value end)
            if ok and tostring(value) == LocalPlayer.Name then
                return plot
            end
        end
    end
    return nil
end

local function findNetworkModule()
    local shared = ReplicatedStorage:FindFirstChild("SharedModules")
    if not shared then return nil end

    local direct = shared:FindFirstChild("Network")
    if direct and direct:IsA("ModuleScript") then return direct end

    for _, obj in ipairs(shared:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "Network" then
            return obj
        end
    end
    return nil
end

local function findDatabaseModule()
    local shared = ReplicatedStorage:FindFirstChild("SharedModules")
    if not shared then return nil end

    local direct = shared:FindFirstChild("Database")
    if direct and direct:IsA("ModuleScript") then return direct end

    for _, obj in ipairs(shared:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "Database" then
            return obj
        end
    end
    return nil
end

local function recoverDatabaseFromGC()
    if type(getgc) ~= "function" then return nil end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return nil end

    for _, obj in ipairs(objects) do
        if type(obj) == "table" then
            local okProbe, friends, dumbells, rebirths = pcall(function()
                return rawget(obj, "Friends"), rawget(obj, "Dumbells"), rawget(obj, "Rebirths")
            end)
            if okProbe and type(friends) == "table"
                and type(dumbells) == "table"
                and type(rebirths) == "table" then
                return obj
            end
        end
    end
    return nil
end

local function getData(force)
    if not DataGetRemote then return DataCache end

    local now = os.clock()
    if not force and DataCache and now - DataCacheAt < 0.55 then
        return DataCache
    end

    local ok, result = pcall(function()
        return DataGetRemote:InvokeServer(LocalPlayer)
    end)

    if ok and type(result) == "table" then
        DataCache = result
        DataCacheAt = now
    elseif not ok then
        State.LastError = "Data:Get " .. tostring(result)
    end

    return DataCache
end

local function makeRemote(name, kind)
    if not RemoteFolder then return nil end
    local remote = RemoteFolder:FindFirstChild(name)
    if remote then return remote end

    local ok, found = pcall(function()
        return RemoteFolder:WaitForChild(name, 3)
    end)
    return ok and found or nil
end

local function remoteFire(remote, ...)
    if not remote then return false, "remote unavailable" end
    local args = table.pack(...)

    local ok, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(table.unpack(args, 1, args.n))
            return true
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(table.unpack(args, 1, args.n))
        end
        error("Unsupported remote class: " .. tostring(remote.ClassName))
    end)

    if not ok then
        State.LastError = tostring(result)
    end
    return ok, result
end

local function requireReady()
    if State.Ready then return true end
    notify("AliceHUB", State.InitStatus or "Game client belum siap.", 4)
    return false
end

local rarityRank = {
    -- Exact order from the game's SharedVariables.RarityOrders dump.
    Common=1, Rare=2, Epic=3, Legendary=4, Mythic=5, Secret=6,
    ["Brainrot God"]=7, OG=9, Divine=10, Transcendent=11,
    Celestial=12, Ancient=13, Cosmic=14, Atlantian=15,
    ["Sci Fi"]=16, Exclusive=17,
}

-- Exact pull gates recovered from SharedVariables.RARITY_PULL_STRENGTHS.
-- Best Egg By Strength now uses these game values instead of BasePart.AssemblyMass.
local rarityMinStrength = {
    Common=0,
    Rare=500,
    Epic=9500,
    Legendary=45000,
    Mythic=290000,
    Secret=2450000,
    ["Brainrot God"]=9500000,
    OG=48500000,
    Divine=420000000,
    Transcendent=4500000000,
    Ancient=17500000000,
    Celestial=95000000000,
    Atlantian=345000000000,
    Cosmic=490000000000,
    ["Sci Fi"]=490000000000,
    Exclusive=5000000,
}

local eggChoices = {"Any"}
local function rebuildEggChoices()
    local newList = {"Any"}
    if not (Lib and type(Lib.Database) == "table" and type(Lib.Database.Friends) == "table") then
        eggChoices = newList
        return newList
    end
    local found = {}
    local defs = {}
    for id, def in pairs(Lib.Database.Friends) do
        if type(def) == "table" and def.Type == "Lucky Block" and def.Name then
            local name = tostring(def.Name)
            if not found[name] then
                found[name] = true
                defs[#defs+1] = {
                    name=name,
                    rarity=tostring(def.Rarity or "Common"),
                    hatch=tonumber(def.HatchTime) or 0,
                }
            end
        end
    end
    table.sort(defs, function(a,b)
        local ar, br = rarityRank[a.rarity] or 0, rarityRank[b.rarity] or 0
        if ar ~= br then return ar < br end
        if a.hatch ~= b.hatch then return a.hatch < b.hatch end
        return a.name < b.name
    end)
    for _, item in ipairs(defs) do newList[#newList+1] = item.name end
    eggChoices = newList
    return newList
end

local activeTween
local moveSerial = 0

local function rootHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil,nil end
    return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function moveToPosition(position)
    if not requireReady() then return false end
    local hrp, hum = rootHumanoid()
    if not hrp then return false end

    moveSerial += 1
    local serial = moveSerial
    State.Moving = true

    if activeTween then pcall(function() activeTween:Cancel() end) end
    activeTween = nil

    local dest = position + Vector3.new(0,3,0)

    if Config.MovementMode == "TP" then
        pcall(function()
            hrp.CFrame = CFrame.new(dest)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end)
        task.wait(0.1)
        State.Moving = false
        return true
    end

    if Config.MovementMode == "Walk" and hum then
        hum:MoveTo(dest)
        local deadline = os.clock() + math.max(3, tonumber(Config.WalkTimeout) or 12)
        while State.Running and serial == moveSerial and os.clock() < deadline do
            if not hrp.Parent then break end
            if (hrp.Position - dest).Magnitude <= 5 then
                State.Moving = false
                return true
            end
            task.wait(0.1)
        end
        State.Moving = false
        return hrp.Parent and (hrp.Position-dest).Magnitude <= 7
    end

    local speed = math.max(30, tonumber(Config.TweenSpeed) or 300)
    local duration = math.clamp((hrp.Position-dest).Magnitude / speed, 0.05, 15)
    activeTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(dest)
    })
    activeTween:Play()

    local deadline = os.clock() + duration + 1.5
    while State.Running and serial == moveSerial and os.clock() < deadline do
        if (hrp.Position-dest).Magnitude <= 5 then break end
        task.wait(0.05)
    end
    pcall(function() activeTween:Cancel() end)
    activeTween = nil
    State.Moving = false
    return hrp.Parent and (hrp.Position-dest).Magnitude <= 8
end

local function getEggDefinition(model)
    if not model then return nil end
    local friends = Lib and Lib.Database and Lib.Database.Friends
    if type(friends) ~= "table" then return nil end

    local id = model:GetAttribute("ID")
    if id ~= nil then
        local def = friends[id] or friends[tostring(id)] or friends[tonumber(id)]
        if type(def) == "table" then return def end
    end

    -- Fallback for executors/dumps where the ID attribute is not visible yet.
    for _, def in pairs(friends) do
        if type(def) == "table" and def.Type == "Lucky Block"
            and tostring(def.Name or "") == tostring(model.Name) then
            return def
        end
    end
    return nil
end

local function getEggRarity(model)
    local def = getEggDefinition(model)
    return tostring((def and def.Rarity) or model:GetAttribute("Rarity") or "Common")
end

local function getEggRarityRank(model)
    return rarityRank[getEggRarity(model)] or 0
end

local function getEggRequirement(model)
    if not model then return nil, "none" end

    -- The real game gates pulling by RARITY_PULL_STRENGTHS.MinStrength.
    local rarity = getEggRarity(model)
    local req = rarityMinStrength[rarity]
    if req ~= nil then return req, "rarity:" .. rarity end

    -- Runtime attribute/value fallback for future game updates/new rarities.
    local names = {"StrengthRequirement", "RequiredStrength", "MinStrength"}
    local probes = {model, model:FindFirstChild("Mass")}
    for _, obj in ipairs(probes) do
        if obj then
            for _, key in ipairs(names) do
                local okA, attr = pcall(function() return obj:GetAttribute(key) end)
                local n = okA and tonumber(attr) or nil
                if n and n >= 0 then return n, "attribute" end
            end
        end
    end
    for _, key in ipairs(names) do
        local value = model:FindFirstChild(key, true)
        if value and (value:IsA("NumberValue") or value:IsA("IntValue")) then
            local n = tonumber(value.Value)
            if n and n >= 0 then return n, "value" end
        end
    end
    return nil, "unknown"
end

local function findTargetEgg()
    if not requireReady() then return nil end
    local hrp = rootHumanoid()
    if not hrp then return nil end

    local d = getData(true)
    local strength = tonumber(d and d.Strength) or 0
    local smart = Config.SmartStrengthTarget and Config.EggChoice == "Any"
    local chosen, chosenRank, chosenReq, chosenDist = nil, -math.huge, -math.huge, math.huge
    local nextLockedReq = math.huge

    for _, model in ipairs(WorldFriends:GetChildren()) do
        if model:IsA("Model") and model.PrimaryPart then
            if Config.EggChoice == "Any" or model.Name == Config.EggChoice then
                local mass = model:FindFirstChild("Mass")
                local stealing = mass and mass:FindFirstChild("STEALING")
                local prompt = model:FindFirstChild("StealPrompt", true)
                if not stealing and prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled ~= false then
                    local dist = (model.PrimaryPart.Position - hrp.Position).Magnitude
                    if not smart then
                        if dist < chosenDist then
                            chosenDist, chosen = dist, model
                        end
                    else
                        local req = select(1, getEggRequirement(model))
                        local rank = getEggRarityRank(model)
                        if req ~= nil then
                            if req > strength and req < nextLockedReq then
                                nextLockedReq = req
                            end
                            if req <= strength then
                                if rank > chosenRank
                                    or (rank == chosenRank and req > chosenReq)
                                    or (rank == chosenRank and req == chosenReq and dist < chosenDist) then
                                    chosen, chosenRank, chosenReq, chosenDist = model, rank, req, dist
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if smart and chosen then
        State.LastEggRequirement = string.format("%s · Need %s / STR %s",
            getEggRarity(chosen), tostring(chosenReq), tostring(strength))
    elseif smart and nextLockedReq < math.huge then
        State.LastEggRequirement = string.format("Next Need %s / STR %s", tostring(nextLockedReq), tostring(strength))
    elseif smart then
        State.LastEggRequirement = "No pullable egg spawned"
    else
        State.LastEggRequirement = "Manual target"
    end
    return chosen
end

local function triggerPrompt(prompt)
    if not prompt then return false end
    if type(fireproximityprompt) ~= "function" then
        State.LastError = "Executor missing fireproximityprompt"
        return false
    end
    local old = prompt.HoldDuration
    pcall(function() prompt.HoldDuration = 0 end)
    local ok = pcall(function() fireproximityprompt(prompt) end)
    if not ok then
        ok = pcall(function() fireproximityprompt(prompt, old or 0) end)
    end
    task.delay(0.15, function()
        pcall(function() prompt.HoldDuration = old end)
    end)
    return ok
end

local function heldFriendUID()
    local char = LocalPlayer.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                local uid = child:GetAttribute("friendUID")
                if uid then return tostring(uid) end
            end
        end
    end
    if State.Holding and State.HeldUID then
        return tostring(State.HeldUID)
    end
    return nil
end

local function isHoldingFriend()
    if State.Holding then return true end
    local ok, attr = pcall(function() return LocalPlayer:GetAttribute("holdingFriend") end)
    if ok and attr then return true end
    return heldFriendUID() ~= nil
end

local function getExistingPositions()
    local out = {}
    local d = getData()
    for _, info in pairs((d and d.PlotFriends) or {}) do
        if type(info) == "table" and type(info.pos) == "table" then
            local x,z = tonumber(info.pos.x), tonumber(info.pos.z)
            if x and z then out[#out+1] = Vector2.new(x,z) end
        end
    end
    return out
end

local function choosePlacement()
    if not Base then return 0,0 end
    local sx = math.max(8, Base.Size.X * 0.72)
    local sz = math.max(8, Base.Size.Z * 0.72)
    local existing = getExistingPositions()

    for ix=-2,2 do
        for iz=-2,2 do
            local c = Vector2.new(ix*sx/5, iz*sz/5)
            local clear = true
            for _, old in ipairs(existing) do
                if (c-old).Magnitude < 4 then clear=false break end
            end
            if clear then return c.X,c.Y end
        end
    end
    return 0,0
end

-- Relay transport constants. Every movement hop while carrying an egg MUST be
-- followed by Drop Friend, then the SAME egg is picked up again before the next hop.
local RELAY_MAX_HOPS = 100
local RELAY_SETTLE_TIME = 0.22
local RELAY_DROP_TIMEOUT = 2.0
local RELAY_PICKUP_TIMEOUT = 5.0

local function waitHolding(wanted, timeout)
    local deadline = os.clock() + (timeout or 2)
    while State.Running and os.clock() < deadline do
        if isHoldingFriend() == wanted then return true end
        task.wait(0.05)
    end
    return isHoldingFriend() == wanted
end

local function makeEggToken(model)
    local id = model and model:GetAttribute("ID")
    return {
        model = model,
        id = id ~= nil and tostring(id) or nil,
        name = model and model.Name or nil,
        rarity = model and getEggRarity(model) or nil,
        uid = nil,
    }
end

local function eggMatchesToken(model, token)
    if not (model and token and model:IsA("Model")) then return false end
    if token.uid then
        local uid = model:GetAttribute("friendUID") or model:GetAttribute("FriendUID")
            or model:GetAttribute("uid") or model:GetAttribute("UID")
        if uid ~= nil and tostring(uid) == tostring(token.uid) then return true end
    end
    if token.id then
        local id = model:GetAttribute("ID")
        if id ~= nil and tostring(id) == tostring(token.id) then return true end
    end
    return token.name ~= nil and model.Name == token.name
end

local function findLockedEgg(token, nearPosition)
    if not token or not WorldFriends then return nil end

    local original = token.model
    if original and original.Parent and original:IsDescendantOf(WorldFriends) and original.PrimaryPart then
        return original
    end

    local origin = nearPosition
    if not origin then
        local hrp = rootHumanoid()
        origin = hrp and hrp.Position or Vector3.zero
    end

    local best, bestDist = nil, math.huge
    for _, model in ipairs(WorldFriends:GetChildren()) do
        if model:IsA("Model") and model.PrimaryPart and eggMatchesToken(model, token) then
            local dist = (model.PrimaryPart.Position - origin).Magnitude
            if dist < bestDist then
                best, bestDist = model, dist
            end
        end
    end
    if best then token.model = best end
    return best
end

State.__rs_waitLockedEggReady = function(token, nearPosition, timeout)
    local deadline = os.clock() + (timeout or RELAY_PICKUP_TIMEOUT)
    local lastModel
    while State.Running and os.clock() < deadline do
        local model = findLockedEgg(token, nearPosition)
        if model then
            lastModel = model
            local mass = model:FindFirstChild("Mass")
            local stealing = mass and mass:FindFirstChild("STEALING")
            local prompt = model:FindFirstChild("StealPrompt", true)
            if not stealing and prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled ~= false then
                return model, prompt
            end
        end
        task.wait(0.06)
    end
    if lastModel then
        return lastModel, lastModel:FindFirstChild("StealPrompt", true)
    end
    return nil, nil
end

State.__rs_forceDropHeldEgg = function()
    if not isHoldingFriend() then return true end
    setAction("DROP wajib")

    for attempt = 1, 3 do
        remoteFire(R.DropFriend)
        if waitHolding(false, RELAY_DROP_TIMEOUT) then
            task.wait(0.08)
            return true
        end
        State.LastError = "Drop retry " .. tostring(attempt)
    end

    State.LastError = "Drop Friend did not release egg"
    return false
end

State.__rs_pickupLockedEgg = function(token, nearPosition)
    if isHoldingFriend() then
        local uid = heldFriendUID()
        if uid then token.uid = tostring(uid) end
        return true
    end

    local model, prompt = State.__rs_waitLockedEggReady(token, nearPosition, RELAY_PICKUP_TIMEOUT)
    if not (model and prompt) then
        State.LastError = "Locked egg not found after drop"
        return false
    end

    token.model = model
    setAction("Ambil lagi: " .. tostring(token.name or model.Name))

    -- After a hop the egg can lag behind the player. Always return to the SAME egg first.
    if model.PrimaryPart then
        local hrp = rootHumanoid()
        if hrp and (hrp.Position - model.PrimaryPart.Position).Magnitude > 7 then
            if not moveToPosition(model.PrimaryPart.Position) then
                State.LastError = "Could not return to dropped egg"
                return false
            end
            task.wait(0.08)
        end
    end

    prompt = model:FindFirstChild("StealPrompt", true)
    if not prompt or not triggerPrompt(prompt) then
        State.LastError = "Re-pick prompt failed"
        return false
    end

    if not waitHolding(true, RELAY_PICKUP_TIMEOUT) then
        State.LastError = "Could not re-pick locked egg"
        return false
    end

    local uid = heldFriendUID()
    if uid then token.uid = tostring(uid) end
    return true
end

State.__rs_currentRelayStep = function(token)
    -- V6: use the map's actual plot spacing instead of rope length.
    -- This makes each TP feel like moving roughly one plot forward: far enough
    -- to visibly move the player/egg, but still conservative for mobile executors.
    local plots = workspace:FindFirstChild("Plots")
    local bases = {}
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local b = plot:FindFirstChild("Base")
            if b and b:IsA("BasePart") then
                bases[#bases+1] = b.Position
            end
        end
    end

    local nearestSpacing = math.huge
    if #bases >= 2 then
        -- Find the smallest normal horizontal spacing between plot bases.
        -- Ignore tiny/duplicate distances so decorative/overlapping parts do not skew it.
        for i = 1, #bases do
            for j = i + 1, #bases do
                local a, b = bases[i], bases[j]
                local d = (Vector3.new(a.X,0,a.Z) - Vector3.new(b.X,0,b.Z)).Magnitude
                if d >= 20 and d < nearestSpacing then
                    nearestSpacing = d
                end
            end
        end
    end

    if nearestSpacing < math.huge then
        -- ~90% of one plot gap: reaches the next plot area without making a huge jump.
        return math.clamp(nearestSpacing * 0.90, 38, 62)
    end

    -- Safe fallback if Plots are not fully streamed yet.
    return 48
end

State.__rs_eggAtBase = function(token)
    local model = findLockedEgg(token, Base and Base.Position)
    if not (model and model.PrimaryPart and Base) then return false end
    local flatEgg = Vector3.new(model.PrimaryPart.Position.X, Base.Position.Y, model.PrimaryPart.Position.Z)
    local flatBase = Vector3.new(Base.Position.X, Base.Position.Y, Base.Position.Z)
    local radius = math.max(Base.Size.X, Base.Size.Z) * 0.52 + 5
    return (flatEgg - flatBase).Magnitude <= radius
end

State.__rs_placeLockedEgg = function(token)
    if not Config.AutoPlace then return true end
    if not isHoldingFriend() then
        if not State.__rs_pickupLockedEgg(token, Base and Base.Position) then return false end
    end

    local uid = heldFriendUID() or token.uid
    if not uid then
        State.LastError = "Held UID not found for final place"
        return false
    end

    local x,z = choosePlacement()
    setAction("Placing egg")
    local ok = remoteFire(R.PlaceFriend, uid, x, z)
    task.wait(0.45)
    if ok then
        waitHolding(false, 1.5)
    end
    return ok
end

State.__rs_relayLockedEggToBase = function(token)
    if not (token and Base) then return false end

    -- We enter this function holding the selected egg. Every teleport/movement hop below
    -- is ALWAYS followed by a drop. No conditional "drop if needed" path exists.
    for hop = 1, RELAY_MAX_HOPS do
        if not State.Running then return false end
        if not isHoldingFriend() then
            if not State.__rs_pickupLockedEgg(token) then return false end
        end

        local model = findLockedEgg(token)
        local hrp = rootHumanoid()
        if not hrp then return false end
        local basePos = Base.Position

        -- V6 IMPORTANT: route from PLAYER position, not the lagging egg position.
        -- Using the egg as the origin could calculate a destination that was nearly
        -- identical to the player's current position, making the TP look stuck.
        local flatFrom = Vector3.new(hrp.Position.X, basePos.Y, hrp.Position.Z)
        local delta = basePos - flatFrom
        local dist = delta.Magnitude
        local step = State.__rs_currentRelayStep(token)
        local dest

        if dist <= step then
            dest = basePos
        else
            dest = flatFrom + delta.Unit * step
        end

        State.LastEggRequirement = (State.LastEggRequirement or "")
            .. string.format(" · Relay %d", hop)
        setAction(string.format("TP relay %d → base", hop))

        if not moveToPosition(dest) then
            State.LastError = "Relay TP failed at hop " .. tostring(hop)
            return false
        end

        -- Required sequence: TP completes -> settle -> DROP, every single hop.
        task.wait(RELAY_SETTLE_TIME)
        if not State.__rs_forceDropHeldEgg() then return false end

        local droppedModel = State.__rs_waitLockedEggReady(token, dest, RELAY_PICKUP_TIMEOUT)
        if droppedModel then token.model = droppedModel end

        -- Judge completion from the EGG position, not the player position. If the rope
        -- lagged behind, we re-grab the same egg and repeat another base-directed TP.
        if State.__rs_eggAtBase(token) then
            setAction("Egg sampai base · final drop done")
            if Config.AutoPlace then
                -- No TP here: re-grab at the base and place it. The final TP has already
                -- been followed by its mandatory drop above.
                return State.__rs_placeLockedEgg(token)
            end
            return true
        end

        if not State.__rs_pickupLockedEgg(token, dest) then return false end
        task.wait(0.06)
    end

    State.LastError = "Relay exceeded max hops"
    return false
end

State.__rs_returnHomeAndPlace = function()
    if not requireReady() then return false end

    -- Recovery path for an already-held egg (for example after re-execute).
    local nearest, nearestDist
    local hrp = rootHumanoid()
    if WorldFriends and hrp then
        for _, model in ipairs(WorldFriends:GetChildren()) do
            if model:IsA("Model") and model.PrimaryPart then
                local mass = model:FindFirstChild("Mass")
                if mass and mass:FindFirstChild("STEALING") then
                    local dist = (model.PrimaryPart.Position - hrp.Position).Magnitude
                    if not nearestDist or dist < nearestDist then
                        nearest, nearestDist = model, dist
                    end
                end
            end
        end
    end

    if nearest then
        local token = makeEggToken(nearest)
        local uid = heldFriendUID()
        if uid then token.uid = tostring(uid) end
        return State.__rs_relayLockedEggToBase(token)
    end

    -- If the world model cannot be resolved, keep a safe legacy recovery rather than
    -- discarding whatever the player is already holding.
    setAction("Returning held egg to plot")
    if not moveToPosition(Base.Position) then return false end
    task.wait(RELAY_SETTLE_TIME)
    if not State.__rs_forceDropHeldEgg() then return false end
    return true
end

State.__rs_pullOnce = function()
    if not requireReady() or State.Pulling then return end
    State.Pulling = true
    local ok, err = xpcall(function()
        if isHoldingFriend() then
            State.__rs_returnHomeAndPlace()
            return
        end

        local target = findTargetEgg()
        if not target then
            setAction("Waiting for egg")
            return
        end

        local token = makeEggToken(target)
        State.LastEgg = target.Name
        setAction("Going to " .. target.Name)
        if not moveToPosition(target.PrimaryPart.Position) then
            State.LastError = "Could not reach egg"
            return
        end

        local prompt = target:FindFirstChild("StealPrompt", true)
        if not prompt then
            State.LastError = "StealPrompt missing"
            return
        end

        setAction("Pulling " .. target.Name)
        if not triggerPrompt(prompt) then
            State.LastError = "Prompt trigger failed"
            return
        end

        if not waitHolding(true, 7) then
            State.LastError = "Pull did not start"
            return
        end

        local uid = heldFriendUID()
        if uid then token.uid = tostring(uid) end
        task.wait(0.06)

        -- Lock this exact egg until it reaches the base. Target selection does not run
        -- again during the relay, so a dropped egg cannot be replaced by a nearby one.
        relayLockedEggToBase(token)
    end, function(e)
        local msg = tostring(e)
        pcall(function()
            if debug and debug.traceback then msg = debug.traceback(msg,2) end
        end)
        return msg
    end)
    if not ok then State.LastError = tostring(err) end
    State.Pulling = false
    if State.Action ~= "Waiting for egg" then setAction("Idle") end
end

State.__rs_buyBestDumbellOnce = function()
    if not requireReady() then return end
    local d = getData()
    if not d then return end
    local db = (Lib.Database and Lib.Database.Dumbells) or {}
    local unlocked = d.UnlockedDumbells or {}
    local cash = tonumber(d.Cash) or 0

    local bestOwned, bestOwnedStrength = nil, -math.huge
    for _, id in ipairs(unlocked) do
        local def = db[id]
        local strength = def and tonumber(def.Strength)
        if strength and strength > bestOwnedStrength then
            bestOwnedStrength, bestOwned = strength, id
        end
    end

    local bestBuy, bestBuyStrength = nil, bestOwnedStrength
    for id,def in pairs(db) do
        if type(def)=="table" and def.DisplayInShop ~= false then
            local price, strength = tonumber(def.Price), tonumber(def.Strength)
            if price and strength and price <= cash and not table.find(unlocked,id) and strength > bestBuyStrength then
                bestBuyStrength, bestBuy = strength, id
            end
        end
    end

    if bestBuy then
        remoteFire(R.BuyDumbell, bestBuy)
        task.wait(0.2)
        bestOwned = bestBuy
    end

    local latest = getData()
    if latest then
        local best, bestStrength = nil, -math.huge
        for _,id in ipairs(latest.UnlockedDumbells or {}) do
            local def = db[id]
            local strength = def and tonumber(def.Strength)
            if strength and strength > bestStrength then bestStrength,best=strength,id end
        end
        if best and latest.EquippedDumbell ~= best then
            remoteFire(R.EquipDumbell, best)
        end
    end
end

State.__rs_openReadyEggOnce = function()
    if not requireReady() then return false end
    local d = getData()
    if not d then return false end
    local now = os.time()
    for uid,info in pairs(d.PlotFriends or {}) do
        if type(info)=="table" then
            local def = Lib.Database.Friends and Lib.Database.Friends[tostring(info.id)]
            if def and def.Type=="Lucky Block" and (tonumber(info.finishTime) or 0) <= now then
                remoteFire(R.OpenLucky, tostring(uid))
                return true
            end
        end
    end
    return false
end

State.__rs_collectEarningsOnce = function()
    if not requireReady() then return end
    local pads = MyPlot and MyPlot:FindFirstChild("CollectPads")
    if not pads then return end
    for _,pad in ipairs(pads:GetChildren()) do
        if pad:IsA("Model") then
            remoteFire(R.CollectEarnings, pad.Name)
            task.wait(0.03)
        end
    end
end

State.__rs_upgradePetOnce = function()
    if not requireReady() then return end
    local d = getData()
    if not d then return end
    for uid,info in pairs(d.PlotFriends or {}) do
        if type(info)=="table" then
            local def = Lib.Database.Friends and Lib.Database.Friends[tostring(info.id)]
            if def and def.Type ~= "Lucky Block" then
                remoteFire(R.UpgradeFriend, tostring(uid))
                return
            end
        end
    end
end

State.__rs_protectedFriend = function(friend, def, plotSet)
    if not def or def.Type=="Lucky Block" then return true end
    if plotSet[tostring(friend.uid)] then return true end
    if friend.locked==true or friend.Locked==true or friend.favorite==true
        or friend.favorited==true or friend.isFavorite==true or friend.starred==true then
        return true
    end
    return false
end

State.__rs_sellOneSafe = function()
    if not requireReady() then return end
    local d = getData()
    if not (d and d.Inventory and type(d.Inventory.Friends)=="table") then return end

    local plotSet={}
    for uid in pairs(d.PlotFriends or {}) do plotSet[tostring(uid)] = true end
    local maxRank = rarityRank[Config.SellMaxRarity] or 1

    for _,friend in ipairs(d.Inventory.Friends) do
        local def = Lib.Database.Friends and Lib.Database.Friends[tostring(friend.id)]
        if not State.__rs_protectedFriend(friend,def,plotSet) then
            local rr = rarityRank[tostring(def.Rarity or "Common")] or 999
            if rr <= maxRank then
                remoteFire(R.SellFriend, tostring(friend.uid))
                return
            end
        end
    end
end

State.__rs_rebirthOnce = function()
    if not requireReady() then return end
    local d=getData()
    if not d then return end
    local current=tonumber(d.Rebirth) or 0
    local stop=tonumber(Config.StopRebirth) or 0
    if stop>0 and current>=stop then return end
    local nextDef=Lib.Database.Rebirths and Lib.Database.Rebirths[current+1]
    if nextDef and (tonumber(d.Strength) or 0) >= (tonumber(nextDef.StrengthRequirement) or math.huge) then
        remoteFire(R.Rebirth)
    end
end

State.__rs_carryUpgradeOnce = function()
    if not requireReady() then return end
    local d=getData()
    if not d then return end
    local current=tonumber(d.CarryLevel) or 0
    local price=Lib.Database.CarryLevelPrices and Lib.Database.CarryLevelPrices[current+1]
    if price and (tonumber(d.Cash) or 0) >= tonumber(price) then
        remoteFire(R.UpgradeCarry)
    end
end

State.__rs_dailyOnce = function()
    if not requireReady() then return end
    local d=getData()
    if not (d and d.DailyData) then return end
    local claimed=d.DailyData.Claimed or {}
    local rewardTime=tonumber(d.DailyData.RewardTime) or math.huge
    if os.time() >= rewardTime then
        local day=#claimed+1
        if day>=1 and day<=7 then remoteFire(R.ClaimDaily,day) end
    end
end

State.__rs_groupOnce = function()
    if not requireReady() then return end
    local inGroup=false
    pcall(function() inGroup=LocalPlayer:IsInGroup(487434901) end)
    if inGroup then remoteFire(R.ClaimGroup) end
end

State.__rs_buyGearOnce = function()
    if not requireReady() then return end
    local d=getData()
    if not d then return end
    local owned=d.OwnedGears or {}
    local cash=tonumber(d.Cash) or 0
    local candidates={}
    for id,def in pairs((Lib.Database and Lib.Database.Gears) or {}) do
        if type(def)=="table" and def.DisplayInShop ~= false and tonumber(def.Price) then
            candidates[#candidates+1]={id=id,price=tonumber(def.Price)}
        end
    end
    table.sort(candidates,function(a,b) return a.price<b.price end)
    for _,item in ipairs(candidates) do
        if item.price<=cash and not table.find(owned,item.id) then
            remoteFire(R.BuyGear,item.id,"Buy")
            return
        end
    end
end

State.__rs_claimIndexOnce = function()
    if not requireReady() or not R.ClaimIndex then return false end
    local d = getData(true)
    local rewards = d and d.IndexRewards
    if type(rewards) ~= "table" then return false end

    local claimed = 0
    for friendId, variants in pairs(rewards) do
        if type(variants) == "table" then
            for variant, status in pairs(variants) do
                if status == "pending" then
                    setAction("Claiming index")
                    local ok, result = remoteFire(R.ClaimIndex, tostring(friendId), tostring(variant))
                    if ok and (type(result) ~= "table" or result.success ~= false) then
                        claimed += 1
                    end
                    DataCacheAt = 0
                    task.wait(0.12)
                end
            end
        end
    end
    if claimed > 0 then setAction("Claimed index x"..tostring(claimed)) end
    return claimed > 0
end

State.__rs_bestWorldName = function()
    local d = getData()
    local rebirth = tonumber(d and d.Rebirth) or 0
    local bestName, bestIndex = "Spawn", 1
    local worlds = Lib and Lib.Database and Lib.Database.Worlds
    if type(worlds) == "table" then
        for name, def in pairs(worlds) do
            if type(def) == "table" and not def.ComingSoon then
                local req = tonumber(def.RebirthRequirement) or 0
                local idx = tonumber(def.Index) or 1
                if req <= rebirth and idx > bestIndex then
                    bestName, bestIndex = tostring(name), idx
                end
            end
        end
    end
    State.BestWorld = bestName
    return bestName
end

State.__rs_goBestWorldOnce = function()
    if not requireReady() or State.Pulling or isHoldingFriend() then return false end
    local d = getData(true)
    if not d then return false end
    local target = State.__rs_bestWorldName()
    local current = tostring(d.CurrentWorld or "Spawn")
    if current == target then return true end

    setAction("TP best world: "..target)
    local ok
    if target == "Spawn" then
        ok = select(1, remoteFire(R.TeleportSpawn))
    else
        ok = select(1, remoteFire(R.TeleportWorld, target))
    end
    if ok then
        DataCacheAt = 0
        task.wait(0.7)
    end
    return ok
end

State.__rs_applyAntiMonsterHit = function()
    if not Config.AntiMonsterHit then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local rag = char:FindFirstChild("Ragdolled")

    if rag and rag:IsA("BoolValue") and rag.Value then
        pcall(function() rag.Value = false end)
    end
    pcall(function() char:SetAttribute("inDangerZone", nil) end)
    pcall(function() workspace:SetAttribute("inDangerZone", nil) end)

    if hum then
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true) end)
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.FallingDown then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)
        end
    end

    if hrp then
        pcall(function()
            hrp.AssemblyAngularVelocity = Vector3.zero
            -- Preserve normal walking, but kill the huge velocity spikes caused by guardians.
            if hrp.AssemblyLinearVelocity.Magnitude > 95 then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end
end

local whiteGui
State.__rs_setWhiteScreen = function(on)
    if on then
        if whiteGui then return end
        local root = LocalPlayer:WaitForChild("PlayerGui")
        whiteGui=Instance.new("ScreenGui")
        whiteGui.Name="AliceHUB_PAE_WhiteScreen"
        whiteGui.IgnoreGuiInset=true
        whiteGui.ResetOnSpawn=false
        whiteGui.DisplayOrder=999998
        local f=Instance.new("Frame")
        f.Size=UDim2.fromScale(1,1)
        f.BackgroundColor3=Color3.new(0,0,0)
        f.BorderSizePixel=0
        f.Parent=whiteGui
        local t=Instance.new("TextLabel")
        t.AnchorPoint=Vector2.new(0.5,0.5)
        t.Position=UDim2.fromScale(0.5,0.5)
        t.Size=UDim2.fromOffset(340,80)
        t.BackgroundTransparency=1
        t.Text="AliceHUB\nPull An Egg"
        t.Font=Enum.Font.Code
        t.TextSize=18
        t.TextColor3=Color3.fromRGB(242,236,239)
        t.Parent=f
        whiteGui.Parent=root
    else
        if whiteGui then pcall(function() whiteGui:Destroy() end); whiteGui=nil end
    end
end

-- ============================================================
-- Exact AliceHUB tabs
-- ============================================================

local FarmTab = window:AddTab("Farm")
local PetsTab = window:AddTab("Pets")
local ProgressTab = window:AddTab("Progression")
local MoveTab = window:AddTab("Movement")
local SettingsTab = window:AddTab("Settings")
local InfoTab = window:AddTab("Info")

local TrainBox = FarmTab:AddLeftGroupbox("Training")
local PullBox = FarmTab:AddRightGroupbox("Egg Farm")

local tAutoTrain = TrainBox:AddToggle("PAE_AutoTrain",{Text="Auto Train",Default=Config.AutoTrain})
tAutoTrain:OnChanged(function(v) Config.AutoTrain=v; queueSave() end)

local iTrainDelay = TrainBox:AddInput("PAE_TrainDelay",{Text="Train Delay",Default=tostring(Config.TrainDelay),Placeholder="0.50"})
iTrainDelay:OnChanged(function(v)
    local n=tonumber(v)
    if n then Config.TrainDelay=math.clamp(n,0.05,5); queueSave() end
end)

local tBestDumb = TrainBox:AddToggle("PAE_BestDumb",{Text="Auto Buy + Equip Best Dumbbell",Default=Config.AutoBuyBestDumbell})
tBestDumb:OnChanged(function(v) Config.AutoBuyBestDumbell=v; queueSave() end)
TrainBox:AddButton({Text="Buy / Equip Best Now",Func=State.__rs_buyBestDumbellOnce})

local tPull = PullBox:AddToggle("PAE_AutoPull",{Text="Auto Pull Egg",Default=Config.AutoPull})
tPull:OnChanged(function(v) Config.AutoPull=v; queueSave() end)

local eggDropdown = PullBox:AddDropdown("PAE_EggChoice",{
    Text="Egg",
    Values=eggChoices,
    Default=Config.EggChoice,
})
eggDropdown:OnChanged(function(v) Config.EggChoice=tostring(v or "Any"); queueSave() end)

local tSmartStrength = PullBox:AddToggle("PAE_SmartStrength",{Text="Smart Best Egg By Strength",Default=Config.SmartStrengthTarget})
tSmartStrength:OnChanged(function(v) Config.SmartStrengthTarget=v; queueSave() end)

local tPlace = PullBox:AddToggle("PAE_AutoPlace",{Text="Auto Place On Plot",Default=Config.AutoPlace})
tPlace:OnChanged(function(v) Config.AutoPlace=v; queueSave() end)

local tOpen = PullBox:AddToggle("PAE_AutoOpen",{Text="Auto Open Ready Eggs",Default=Config.AutoOpen})
tOpen:OnChanged(function(v) Config.AutoOpen=v; queueSave() end)

local tEquip = PullBox:AddToggle("PAE_EquipBest",{Text="Auto Equip Best Pets",Default=Config.AutoEquipBest})
tEquip:OnChanged(function(v) Config.AutoEquipBest=v; queueSave() end)

PullBox:AddButton({Text="Pull One Egg",Func=State.__rs_pullOnce})
PullBox:AddButton({Text="Open Ready Egg",Func=State.__rs_openReadyEggOnce})

local PetMain = PetsTab:AddLeftGroupbox("Pets")
local SellBox = PetsTab:AddRightGroupbox("Smart Sell")
local FuseBox = PetsTab:AddRightGroupbox("Fuse")

local tCollect=PetMain:AddToggle("PAE_Collect",{Text="Auto Collect Earnings",Default=Config.AutoCollect})
tCollect:OnChanged(function(v) Config.AutoCollect=v; queueSave() end)

local tUpPets=PetMain:AddToggle("PAE_UpgradePets",{Text="Auto Upgrade Placed Pets",Default=Config.AutoUpgradePets})
tUpPets:OnChanged(function(v) Config.AutoUpgradePets=v; queueSave() end)

PetMain:AddButton({Text="Collect Earnings Now",Func=State.__rs_collectEarningsOnce})
PetMain:AddButton({Text="Equip Best Now",Func=function() if requireReady() then remoteFire(R.EquipBest) end end})

local tSell=SellBox:AddToggle("PAE_AutoSell",{Text="Auto Sell",Default=Config.AutoSell})
tSell:OnChanged(function(v) Config.AutoSell=v; queueSave() end)

local sellDD=SellBox:AddDropdown("PAE_SellRarity",{
    Text="Sell Up To",
    Values={"Common","Rare","Epic","Legendary","Mythic"},
    Default=Config.SellMaxRarity,
})
sellDD:OnChanged(function(v) Config.SellMaxRarity=tostring(v or "Common"); queueSave() end)
SellBox:AddLabel("Eggs, placed pets and detected favourites are protected.",true)
SellBox:AddButton({Text="Sell One Matching Pet",Func=State.__rs_sellOneSafe})

FuseBox:AddButton({Text="Place Held Pet To Fuse",Func=function()
    if not requireReady() then return end
    local uid=heldFriendUID()
    if uid then remoteFire(R.PlaceFuse,uid) else notify("AliceHUB","Hold a pet first.") end
end})
FuseBox:AddButton({Text="Activate Fuse",Func=function()
    if not requireReady() then return end
    local ok,res=remoteFire(R.ActivateFuse)
    notify("Fuse",ok and ("Result: "..tostring(res)) or "Failed")
end})
FuseBox:AddButton({Text="Claim Fuse",Func=function() if requireReady() then remoteFire(R.ClaimFuse) end end})

local ProgBox=ProgressTab:AddLeftGroupbox("Progression")
local RewardBox=ProgressTab:AddRightGroupbox("Rewards")

local tRebirth=ProgBox:AddToggle("PAE_Rebirth",{Text="Auto Rebirth",Default=Config.AutoRebirth})
tRebirth:OnChanged(function(v) Config.AutoRebirth=v; queueSave() end)

local iStop=ProgBox:AddInput("PAE_StopRebirth",{Text="Stop At Rebirth (0 = no limit)",Default=tostring(Config.StopRebirth)})
iStop:OnChanged(function(v) local n=tonumber(v); if n then Config.StopRebirth=math.max(0,n); queueSave() end end)

local tCarry=ProgBox:AddToggle("PAE_Carry",{Text="Auto Upgrade Carry Limit",Default=Config.AutoCarry})
tCarry:OnChanged(function(v) Config.AutoCarry=v; queueSave() end)

local tGear=ProgBox:AddToggle("PAE_Gear",{Text="Auto Buy Affordable Gear",Default=Config.AutoBuyGear})
tGear:OnChanged(function(v) Config.AutoBuyGear=v; queueSave() end)

ProgBox:AddButton({Text="Rebirth Now",Func=State.__rs_rebirthOnce})
ProgBox:AddButton({Text="Upgrade Carry Now",Func=State.__rs_carryUpgradeOnce})
ProgBox:AddButton({Text="Buy Affordable Gear",Func=State.__rs_buyGearOnce})

local tDaily=RewardBox:AddToggle("PAE_Daily",{Text="Auto Daily Reward",Default=Config.AutoDaily})
tDaily:OnChanged(function(v) Config.AutoDaily=v; queueSave() end)
local tGroup=RewardBox:AddToggle("PAE_Group",{Text="Auto Group Reward",Default=Config.AutoGroup})
tGroup:OnChanged(function(v) Config.AutoGroup=v; queueSave() end)
RewardBox:AddButton({Text="Claim Daily Now",Func=State.__rs_dailyOnce})
RewardBox:AddButton({Text="Claim Group Now",Func=State.__rs_groupOnce})
local tIndex=RewardBox:AddToggle("PAE_Index",{Text="Auto Claim Index",Default=Config.AutoClaimIndex})
tIndex:OnChanged(function(v) Config.AutoClaimIndex=v; queueSave() end)
RewardBox:AddButton({Text="Claim Index Now",Func=State.__rs_claimIndexOnce})

local MoveBox=MoveTab:AddLeftGroupbox("Movement")
local moveDD=MoveBox:AddDropdown("PAE_MoveMode",{
    Text="Mode",Values={"TP","Tween","Walk"},Default=Config.MovementMode
})
moveDD:OnChanged(function(v) Config.MovementMode=tostring(v or "Tween"); queueSave() end)

local iSpeed=MoveBox:AddInput("PAE_TweenSpeed",{Text="Tween Speed",Default=tostring(Config.TweenSpeed),Placeholder="300"})
iSpeed:OnChanged(function(v) local n=tonumber(v); if n then Config.TweenSpeed=math.clamp(n,30,3000); queueSave() end end)

local iWalk=MoveBox:AddInput("PAE_WalkTimeout",{Text="Walk Timeout",Default=tostring(Config.WalkTimeout)})
iWalk:OnChanged(function(v) local n=tonumber(v); if n then Config.WalkTimeout=math.clamp(n,3,60); queueSave() end end)
MoveBox:AddButton({Text="Go To Plot",Func=function() if requireReady() then moveToPosition(Base.Position) end end})
local tBestWorld=MoveBox:AddToggle("PAE_BestWorld",{Text="Auto TP World Best",Default=Config.AutoBestWorld})
tBestWorld:OnChanged(function(v) Config.AutoBestWorld=v; queueSave() end)
MoveBox:AddButton({Text="TP World Best Now",Func=State.__rs_goBestWorldOnce})

local ClientBox=SettingsTab:AddLeftGroupbox("Client")
local ConfigBox=SettingsTab:AddRightGroupbox("Config")

local tWhite=ClientBox:AddToggle("PAE_White",{Text="White Screen",Default=Config.WhiteScreen})
tWhite:OnChanged(function(v) Config.WhiteScreen=v; State.__rs_setWhiteScreen(v); queueSave() end)

local tAntiMonster=ClientBox:AddToggle("PAE_AntiMonster",{Text="Anti Hit / Anti Fling Monster",Default=Config.AntiMonsterHit})
tAntiMonster:OnChanged(function(v) Config.AntiMonsterHit=v; queueSave() end)

local tRejoin=ClientBox:AddToggle("PAE_Rejoin",{Text="Auto Rejoin",Default=Config.AutoRejoin})
tRejoin:OnChanged(function(v) Config.AutoRejoin=v; queueSave() end)

local iRejoin=ClientBox:AddInput("PAE_RejoinMin",{Text="Rejoin Minutes",Default=tostring(Config.RejoinMinutes)})
iRejoin:OnChanged(function(v) local n=tonumber(v); if n then Config.RejoinMinutes=math.clamp(n,5,120); queueSave() end end)

ConfigBox:AddButton({Text="Save Config",Func=function()
    notify("AliceHUB",saveConfig() and "Config saved." or "Config save unavailable.")
end})
ConfigBox:AddButton({Text="Reset Config",Func=function()
    for k,v in pairs(defaults) do Config[k]=v end
    saveConfig()
    notify("AliceHUB","Config reset. Re-execute to refresh controls.")
end})

local StatusBox=InfoTab:AddLeftGroupbox("Status")
local AccountBox=InfoTab:AddRightGroupbox("Account")
local GameBox=InfoTab:AddRightGroupbox("Game Info")

local lblInit=StatusBox:AddLabel("Game Client: waiting...",true)
local lblAction=StatusBox:AddLabel("Action: Loading...",true)
local lblStats=StatusBox:AddLabel("Stats: waiting...",true)
local lblEgg=StatusBox:AddLabel("Last Egg: -",true)
local lblSmart=StatusBox:AddLabel("Smart Target: -",true)
local lblWorld=StatusBox:AddLabel("Best World: -",true)
local lblErr=StatusBox:AddLabel("Last Error: -",true)

AccountBox:AddLabel("Username : "..tostring(LocalPlayer.Name),true)
local executorName="Unknown"
pcall(function()
    executorName=(identifyexecutor and identifyexecutor())
        or (getexecutorname and getexecutorname())
        or executorName
end)
AccountBox:AddLabel("Executor : "..tostring(executorName),true)
AccountBox:AddLabel("Status : Active",true)

GameBox:AddLabel("Game : Pull An Egg",true)
GameBox:AddLabel("PlaceId : "..tostring(game.PlaceId),true)
GameBox:AddLabel("AliceHUB Gothic UI · V6 Plot-Step Relay Backend",true)

-- ============================================================
-- Backend initialization AFTER UI
-- ============================================================

task.spawn(function()
    local deadline = os.clock() + 25

    while State.Running and os.clock() < deadline do
        State.InitStatus = "Finding Network remotes..."

        local networkModule = findNetworkModule()
        if networkModule then
            RemoteFolder = networkModule:FindFirstChild("Remotes")
        end

        if not RemoteFolder then
            -- fallback: locate a Remotes folder whose parent is a Network ModuleScript
            local shared = ReplicatedStorage:FindFirstChild("SharedModules")
            if shared then
                for _, obj in ipairs(shared:GetDescendants()) do
                    if obj:IsA("Folder") and obj.Name == "Remotes"
                        and obj.Parent and obj.Parent:IsA("ModuleScript")
                        and obj.Parent.Name == "Network" then
                        RemoteFolder = obj
                        break
                    end
                end
            end
        end

        if RemoteFolder then
            DataGetRemote = RemoteFolder:FindFirstChild("Data: Get")
        end

        State.InitStatus = "Finding player plot..."
        MyPlot = findMyPlot() or MyPlot

        if MyPlot then
            Base = MyPlot:FindFirstChild("Base") or Base
        end

        Live = workspace:FindFirstChild("Live") or Live
        if Live then
            WorldFriends = Live:FindFirstChild("Friends") or WorldFriends
            PlayerFriendsRoot = Live:FindFirstChild("PlayerFriends") or PlayerFriendsRoot
            if PlayerFriendsRoot then
                MyPlayerFriends = PlayerFriendsRoot:FindFirstChild(LocalPlayer.Name) or MyPlayerFriends
            end
        end

        State.InitStatus = "Loading game database..."
        if not next(Database) then
            local dbModule = findDatabaseModule()
            if dbModule then
                local okDB, db = pcall(require, dbModule)
                if okDB and type(db) == "table" then
                    Database = db
                end
            end

            if not next(Database) then
                local recovered = recoverDatabaseFromGC()
                if recovered then Database = recovered end
            end

            Lib.Database = Database
        end

        if RemoteFolder and DataGetRemote and MyPlot and Base and Live and WorldFriends then
            R.ActivateDumbell = makeRemote("Activate Dumbell", "RemoteEvent")
            R.BuyDumbell = makeRemote("Buy Dumbell", "RemoteEvent")
            R.EquipDumbell = makeRemote("Equip Dumbell", "RemoteEvent")
            R.PlaceFriend = makeRemote("Place Friend", "RemoteEvent")
            R.EquipBest = makeRemote("Equip Best", "RemoteEvent")
            R.CollectEarnings = makeRemote("Collect Earnings", "RemoteEvent")
            R.UpgradeCarry = makeRemote("Upgrade Carry Limit", "RemoteEvent")
            R.SellFriend = makeRemote("Sell Friend From Inventory", "RemoteEvent")
            R.SellAll = makeRemote("Sell All Friends", "RemoteEvent")
            R.OpenLucky = makeRemote("Open Lucky Block", "RemoteEvent")
            R.ClaimDaily = makeRemote("Claim Daily Reward", "RemoteEvent")
            R.ClaimGroup = makeRemote("Claim Group Reward", "RemoteEvent")
            R.ClaimIndex = makeRemote("Claim Index Reward", "RemoteFunction")
            R.TeleportSpawn = makeRemote("Teleport To Spawn", "RemoteEvent")
            R.TeleportWorld = makeRemote("Teleport To World", "RemoteEvent")
            R.HoldingFriend = makeRemote("Holding Friend", "RemoteEvent")
            R.Rebirth = makeRemote("Rebirth", "RemoteEvent")
            R.BuyGear = makeRemote("Buy Gear", "RemoteEvent")
            R.PickupFriend = makeRemote("Pickup Friend", "RemoteEvent")
            R.UpgradeFriend = makeRemote("Upgrade Friend", "RemoteEvent")
            R.DropFriend = makeRemote("Drop Friend", "RemoteEvent")
            R.PlaceFuse = makeRemote("Place to Fuse", "RemoteEvent")
            R.RemoveFuse = makeRemote("Remove from Fuse", "RemoteEvent")
            R.ActivateFuse = makeRemote("Activate Fuse", "RemoteFunction")
            R.ClaimFuse = makeRemote("Claim Fuse", "RemoteEvent")

            if R.HoldingFriend and R.HoldingFriend:IsA("RemoteEvent") and not State.HoldingConnection then
                State.HoldingConnection = R.HoldingFriend.OnClientEvent:Connect(function(on, uid)
                    State.Holding = on == true
                    if on == true and uid ~= nil then
                        if type(uid) == "table" then
                            uid = uid.friendUID or uid.FriendUID or uid.uid or uid.UID or uid.id or uid.Id
                        end
                        State.HeldUID = uid ~= nil and tostring(uid) or nil
                    else
                        State.HeldUID = nil
                    end
                end)
            end

            -- Test Data:Get directly. This proves backend communication is alive.
            local d = getData(true)
            if type(d) == "table" then
                local newEggs = rebuildEggChoices()
                eggDropdown:SetValues(newEggs)
                if table.find(newEggs, Config.EggChoice) then
                    eggDropdown:SetValue(Config.EggChoice)
                else
                    Config.EggChoice = "Any"
                    eggDropdown:SetValue("Any")
                end

                local foundCount = 0
                for _, remote in pairs(R) do
                    if typeof(remote) == "Instance" then foundCount += 1 end
                end

                State.Ready = true
                State.InitStatus = ("Ready · Direct Remotes %d"):format(foundCount)
                State.Action = "Idle"
                State.LastError = "-"
                notify("AliceHUB Ready", "Pull An Egg direct backend connected.", 4)
                return
            else
                State.InitStatus = "Data:Get found, waiting for player data..."
            end
        else
            local parts = {}
            if not RemoteFolder then parts[#parts+1] = "Remotes" end
            if not DataGetRemote then parts[#parts+1] = "Data:Get" end
            if not MyPlot then parts[#parts+1] = "Plot" end
            if not Base then parts[#parts+1] = "Base" end
            if not WorldFriends then parts[#parts+1] = "Friends" end
            State.InitStatus = "Waiting: " .. table.concat(parts, ", ")
        end

        task.wait(0.35)
    end

    if not State.Ready then
        State.InitStatus = "Backend init failed"
        if State.LastError == "-" then
            State.LastError = "Direct remotes/data/plot not resolved"
        end
        notify("AliceHUB", "UI work, backend belum connect. Cek tab Info.", 7)
    end
end)

-- ============================================================
-- Workers
-- ============================================================

task.spawn(function()
    while State.Running do
        if State.Ready and Config.AutoTrain and not State.Pulling
            and not isHoldingFriend() then
            remoteFire(R.ActivateDumbell)
        end
        task.wait(math.clamp(tonumber(Config.TrainDelay) or 0.5,0.05,5))
    end
end)

task.spawn(function()
    while State.Running do
        if State.Ready and Config.AutoBuyBestDumbell and not State.Pulling then pcall(State.__rs_buyBestDumbellOnce) end
        task.wait(1)
    end
end)

task.spawn(function()
    while State.Running do
        if State.Ready and Config.AutoPull then pcall(State.__rs_pullOnce) end
        task.wait(Config.AutoPull and 0.35 or 1)
    end
end)

task.spawn(function()
    while State.Running do
        if State.Ready then
            if Config.AutoOpen then pcall(State.__rs_openReadyEggOnce) end
            if Config.AutoEquipBest and not isHoldingFriend() then
                pcall(function() remoteFire(R.EquipBest) end)
            end
        end
        task.wait(2)
    end
end)

task.spawn(function()
    while State.Running do
        if State.Ready and Config.AutoCollect then pcall(State.__rs_collectEarningsOnce) end
        task.wait(2.5)
    end
end)

task.spawn(function()
    while State.Running do
        if State.Ready then
            if Config.AutoUpgradePets then pcall(State.__rs_upgradePetOnce) end
            if Config.AutoSell then pcall(State.__rs_sellOneSafe) end
        end
        task.wait(0.8)
    end
end)

task.spawn(function()
    local groupClock=0
    while State.Running do
        if State.Ready then
            if Config.AutoRebirth then pcall(State.__rs_rebirthOnce) end
            if Config.AutoCarry then pcall(State.__rs_carryUpgradeOnce) end
            if Config.AutoDaily then pcall(State.__rs_dailyOnce) end
            if Config.AutoBuyGear then pcall(State.__rs_buyGearOnce) end
            if Config.AutoGroup and os.clock()-groupClock>=30 then
                groupClock=os.clock()
                pcall(State.__rs_groupOnce)
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while State.Running do
        if State.Ready and Config.AutoClaimIndex then pcall(State.__rs_claimIndexOnce) end
        task.wait(6)
    end
end)

task.spawn(function()
    while State.Running do
        if State.Ready and Config.AutoBestWorld and not State.Pulling and not isHoldingFriend() then
            pcall(State.__rs_goBestWorldOnce)
        end
        task.wait(3)
    end
end)

task.spawn(function()
    while State.Running do
        if Config.AntiMonsterHit then pcall(State.__rs_applyAntiMonsterHit) end
        task.wait(0.03)
    end
end)

task.spawn(function()
    local startedAt=os.clock()
    while State.Running do
        if Config.AutoRejoin then
            local target=math.max(5,tonumber(Config.RejoinMinutes) or 17)*60
            if os.clock()-startedAt>=target then
                State.Action="Rejoining"
                pcall(function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end)
                return
            end
        else
            startedAt=os.clock()
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while State.Running do
        lblInit:SetText("Game Client: "..tostring(State.InitStatus))
        lblAction:SetText("Action: "..tostring(State.Action))
        lblEgg:SetText("Last Egg: "..tostring(State.LastEgg))
        lblSmart:SetText("Smart Target: "..tostring(State.LastEggRequirement))
        lblWorld:SetText("Best World: "..tostring(State.BestWorld))
        lblErr:SetText("Last Error: "..tostring(State.LastError))

        local d=getData()
        if d then
            lblStats:SetText(
                ("Cash: %s\nStrength: %s\nRebirth: %s")
                :format(tostring(d.Cash or 0),tostring(d.Strength or 0),tostring(d.Rebirth or 0))
            )
        else
            lblStats:SetText("Stats: waiting...")
        end
        task.wait(0.5)
    end
end)

State.__rs_setWhiteScreen(Config.WhiteScreen)

ENV.AliceHUB_PullAnEgg = {
    Config=Config,
    State=State,
    Remotes=R,
    PullOnce=State.__rs_pullOnce,
    BuyBestDumbellOnce=State.__rs_buyBestDumbellOnce,
    OpenReadyEggOnce=State.__rs_openReadyEggOnce,
    CollectEarningsOnce=State.__rs_collectEarningsOnce,
    RebirthOnce=State.__rs_rebirthOnce,
    ClaimIndexOnce=State.__rs_claimIndexOnce,
    GoBestWorldOnce=State.__rs_goBestWorldOnce,
    Stop=function()
        State.Running=false
        if State.HoldingConnection then pcall(function() State.HoldingConnection:Disconnect() end); State.HoldingConnection=nil end
        moveSerial += 1
        if activeTween then pcall(function() activeTween:Cancel() end) end
        State.__rs_setWhiteScreen(false)
        pcall(function() Library:Unload() end)
        pcall(function() logoGui:Destroy() end)
    end,
}

ENV.AliceHUB_PullAnEgg_Cleanup=function()
    local obj=ENV.AliceHUB_PullAnEgg
    if obj and type(obj.Stop)=="function" then pcall(obj.Stop) end
    ENV.AliceHUB_PullAnEgg=nil
end

notify("AliceHUB","Pull An Egg V6 Plot-Step Relay loaded · connecting backend...",4)
print("AliceHUB · Pull An Egg · V6 PLOT-STEP RELAY loaded")
