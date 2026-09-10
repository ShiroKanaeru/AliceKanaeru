-- AliceHUB v3.0.3 · Register-Safe TEST · chicken.lua
-- Late chunk-scope helpers moved into State namespace for executor compiler compatibility.
-- Logic/UI behavior intentionally unchanged.

local OBSIDIAN_REPO =
    "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"

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

local function buildAliceNativeLibrary(gameName, guiName)
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local PlayersSvc = game:GetService("Players")
    local LP = PlayersSvc.LocalPlayer

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
        _unloadCallbacks = {},
        Unloaded = false,
    }

    -- Anime Dice / Delta: keep the main menu in PlayerGui.
    -- The floating logo can live in gethui, but the full menu was not rendering there.
    local function rootGui()
        return LP:WaitForChild("PlayerGui")
    end

    local root = rootGui()
    local resolvedGuiName = tostring(guiName or "AliceHUB_NativeUI")
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
        label.RichText = true
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

    function L:SetFont(_font)
        return self
    end

    function L:UpdateColorsUsingRegistry()
        return self
    end

    function L:OnUnload(fn)
        if type(fn) == "function" then
            self._unloadCallbacks[#self._unloadCallbacks + 1] = fn
        end
        return self
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
        L.MainFrame = main

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
        icon.Image = ALICE_LOGO_ASSET or ""
        icon.ImageTransparency = ALICE_LOGO_ASSET and 0 or 1
        icon.ScaleType = Enum.ScaleType.Crop
        icon.Parent = iconHolder
        __aliceRegisterLogoTarget(icon, iconFallback)
        corner(icon, 8)
        iconFallback.Visible = not (ALICE_LOGO_ASSET ~= nil)
        if ALICE_LOGO_ASSET then
            icon.ImageTransparency = 0
            iconFallback.Visible = false
        end

        local title = newText(top, (cfg.Title or "AliceHUB") .. " ", 18, true)
        title.Name = "AliceHUBMainTitle"
        title.Position = UDim2.fromOffset(56, 6)
        title.Size = UDim2.new(1, -118, 0, 23)
        title.TextColor3 = L.Scheme.FontColor

        local subtitle = newText(top, tostring(cfg.SubTitle or gameName or "AliceHUB"), 11, false)
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
        local footText = newText(footer, "AliceHUB   |   " .. tostring(gameName or "AliceHUB"), 11, false)
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

                function wrapper:AddKeyPicker(id, conf)
                    conf = conf or {}
                    local default = conf.Default or "RightShift"
                    if typeof(default) == "EnumItem" then default = default.Name end

                    local opt = mkOption(tostring(default))
                    opt.Type = "KeyPicker"
                    L.Options[id] = opt

                    local keyButton = Instance.new("TextButton")
                    keyButton.AnchorPoint = Vector2.new(1, 0.5)
                    keyButton.Position = UDim2.new(1, 0, 0.5, 0)
                    keyButton.Size = UDim2.fromOffset(92, 22)
                    keyButton.BackgroundColor3 = Color3.fromRGB(35, 23, 28)
                    keyButton.BorderSizePixel = 0
                    keyButton.TextColor3 = L.Scheme.FontColor
                    keyButton.TextSize = 10
                    keyButton.Font = Enum.Font.Code
                    keyButton.Parent = label
                    corner(keyButton, 3)

                    local waiting = false
                    local function render(v)
                        keyButton.Text = waiting and "Press key..." or tostring(v or "None")
                    end
                    opt._render = render
                    render(opt.Value)

                    keyButton.Activated:Connect(function()
                        waiting = true
                        render(opt.Value)
                    end)

                    UIS.InputBegan:Connect(function(input, processed)
                        if waiting and input.KeyCode ~= Enum.KeyCode.Unknown then
                            waiting = false
                            opt:SetValue(input.KeyCode.Name)
                            return
                        end

                        if processed then return end
                        if L.ToggleKeybind == opt then
                            local wanted = tostring(opt.Value or "")
                            if input.KeyCode.Name == wanted then
                                L:Toggle()
                            end
                        end
                    end)

                    return opt
                end

                return wrapper
            end

            function G:AddDivider()
                local line = Instance.new("Frame")
                line.Size = UDim2.new(1, 0, 0, 1)
                line.BackgroundColor3 = L.Scheme.OutlineColor
                line.BackgroundTransparency = 0.2
                line.BorderSizePixel = 0
                line.Parent = group
                return line
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
                opt.Type = "Toggle"
                local function render(v)
                    box.BackgroundColor3 = v and Color3.fromRGB(91, 28, 48) or Color3.fromRGB(45, 31, 37)
                    dot.BackgroundColor3 = v and L.Scheme.AccentColor or Color3.fromRGB(118, 103, 110)
                    dot.Position = v and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)
                end
                opt._render = render; render(opt.Value)
                L.Toggles[id] = opt
                if type(conf.Callback) == "function" then
                    opt:OnChanged(conf.Callback)
                end
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
                opt.Type = "Input"
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
                if type(conf.Callback) == "function" then
                    opt:OnChanged(conf.Callback)
                end

                -- Keep option/state synced immediately while typing or pasting.
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
                opt.Type = "Slider"
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
                if type(conf.Callback) == "function" then
                    opt:OnChanged(conf.Callback)
                end
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

                if multi then
                    if type(initial) ~= "table" then
                        initial = {}
                    else
                        -- Normalize array-style defaults {"Common","Rare"} into
                        -- the map format used by the original automation logic.
                        local normalized = {}
                        for k, v in pairs(initial) do
                            if type(k) == "number" and type(v) == "string" then
                                normalized[v] = true
                            elseif v == true then
                                normalized[k] = true
                            end
                        end
                        initial = normalized
                    end
                else
                    -- Obsidian dropdowns commonly use Default = 1/2/3 as an index.
                    if type(initial) == "number" and values[initial] ~= nil then
                        initial = values[initial]
                    end
                    if initial == nil then
                        initial = values[1]
                    end
                end
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
                opt.Type = "Dropdown"
                opt.Multi = multi
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
                if type(conf.Callback) == "function" then
                    opt:OnChanged(conf.Callback)
                end
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
                        local itemStroke = stroke(item, L.Scheme.OutlineColor, 1, 0.45)

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
                            if itemStroke then
                                itemStroke.Color = chosen
                                    and L.Scheme.AccentColor
                                    or L.Scheme.OutlineColor
                                itemStroke.Transparency = chosen and 0.05 or 0.55
                            end
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

            local tab = {_button = tabButton, _content = content, _genericGroupCount = 0}
            function tab:AddLeftGroupbox(titleText) return makeGroup(left, titleText) end
            function tab:AddRightGroupbox(titleText) return makeGroup(right, titleText) end
            function tab:AddGroupbox(titleText)
                self._genericGroupCount += 1
                if self._genericGroupCount % 2 == 1 then
                    return makeGroup(left, titleText)
                end
                return makeGroup(right, titleText)
            end
            tabButton.Activated:Connect(function() activate(tab) end)
            window._tabs[#window._tabs + 1] = tab
            if #window._tabs == 1 then activate(tab) end
            return tab
        end

        return window
    end

    function L:Unload()
        if L.Unloaded then return end
        L.Unloaded = true
        closePopup()
        for _, fn in ipairs(L._unloadCallbacks or {}) do
            pcall(fn)
        end
        if screen and screen.Parent then
            pcall(function() screen:Destroy() end)
        end
    end

    return L
end



local NativeLoadstring = loadstring
assert(type(NativeLoadstring) == "function", "AliceHUB: loadstring is unavailable")

local Library = buildAliceNativeLibrary("Grow A Chicken Fighter", "AliceHUB_GACF_NativeUI")
assert(type(Library) == "table", "AliceHUB: native AliceHUB UI failed to load")

local AliceEnv = (getgenv and getgenv()) or _G
local previousLibrary = AliceEnv.__AliceHUBGrowChickenLib
if previousLibrary and type(previousLibrary.Unload) == "function" then
    pcall(function() previousLibrary:Unload() end)
end
AliceEnv.__AliceHUBGrowChickenLib = Library
local okSaveManager, SaveManager = false, nil
local okThemeManager, ThemeManager = false, nil

-- Match the AliceHUB UI palette.
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



local function applyAliceHubTheme()
    if type(Library.Scheme) ~= "table" then
        return
    end

    -- AliceHUB UI palette.
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

    -- Repaint already-created controls too, not only controls created later.
    if type(Library.UpdateColorsUsingRegistry) == "function" then
        pcall(function()
            Library:UpdateColorsUsingRegistry()
        end)
    end
end

applyAliceHubTheme()


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

local Options = Library.Options
local Toggles = Library.Toggles
local Window
local nextControlId = 0
local ConfigRestore = {
    Loading = false,
    Queue = {},
    Order = {},
}

local function uniqueId(flag, kind)
    local base = tostring(flag or kind or "Control"):gsub("[^%w_]", "_")
    if flag ~= nil and tostring(flag) ~= "" then
        return "AliceOriginal_" .. base
    end
    nextControlId = nextControlId + 1
    return "AliceOriginal_" .. base .. "_" .. tostring(nextControlId)
end

local function invoke(callback, value, kind)
    if type(callback) ~= "function" then return end
    if ConfigRestore.Loading then
        if ConfigRestore.Queue[callback] == nil then
            ConfigRestore.Order[#ConfigRestore.Order + 1] = callback
        end
        ConfigRestore.Queue[callback] = {value = value, kind = kind or "value"}
        return
    end
    local ok, err = pcall(callback, value)
    if not ok then
        warn("[AliceHUB/OriginalCallback] " .. tostring(err))
    end
end

local function flushRestoredCallbacks()
    local order = ConfigRestore.Order
    local queue = ConfigRestore.Queue
    ConfigRestore.Order = {}
    ConfigRestore.Queue = {}

    -- Restore values first so CPS, intervals, filters and targets are ready
    -- before any saved automation toggle starts its original callback.
    for _, callback in ipairs(order) do
        local entry = queue[callback]
        if entry and entry.kind ~= "toggle" then
            invoke(callback, entry.value, entry.kind)
        end
    end

    for _, callback in ipairs(order) do
        local entry = queue[callback]
        if entry and entry.kind == "toggle" and entry.value ~= true then
            invoke(callback, entry.value, entry.kind)
        end
    end

    for _, callback in ipairs(order) do
        local entry = queue[callback]
        if entry and entry.kind == "toggle" and entry.value == true then
            invoke(callback, true, entry.kind)
            task.wait(0.5)
        end
    end
end

local function controlProxy(rawControl, callback, kind)
    local proxy = {Raw = rawControl}
    function proxy:Set(value)
        if rawControl and type(rawControl.SetValue) == "function" then
            rawControl:SetValue(value)
        else
            invoke(callback, value, kind)
        end
    end
    return proxy
end

local TabLabels = {
    AutoFarm = "Farm",
    Auto = "Auto",
    Arena = "Arena",
    Eggs = "Eggs",
    Chickens = "Chickens",
    Events = "Events",
    Webhooks = "Webhook",
    Settings = "Settings",
}

local function newTabProxy(obsidianTab, tabName)
    local proxy = {
        _tab = obsidianTab,
        _name = tabName,
        _group = nil,
        _infoGroup = nil,
        _sectionCount = 0,
        _sectionActive = false,
        _sectionName = nil,
        _controlSide = nil,
        _pendingSection = nil,
    }

    -- AliceHUB two-column adapter. Real controls stay together on one side,
    -- while long status/paragraph output is placed on the opposite side.
    -- Multiple source sections alternate sides exactly like the SAE adapter.
    function proxy:_ensureSectionMeta()
        if self._sectionActive then return end
        self._sectionActive = true
        self._sectionName = self._pendingSection or "General"
        self._pendingSection = nil
        self._sectionCount = self._sectionCount + 1
        self._controlSide = (self._sectionCount % 2 == 1) and "left" or "right"
    end

    function proxy:_ensureGroup()
        if self._group then return self._group end
        self:_ensureSectionMeta()

        -- Chicken Arena is intentionally one-column: everything stacks LEFT.
        -- This is presentation-only; callbacks and the original payload stay unchanged.
        if self._name == "Arena" then
            self._group = self._tab:AddLeftGroupbox(self._sectionName)
        elseif self._controlSide == "left" then
            self._group = self._tab:AddLeftGroupbox(self._sectionName)
        else
            self._group = self._tab:AddRightGroupbox(self._sectionName)
        end
        return self._group
    end

    function proxy:_ensureInfoGroup()
        if self._infoGroup then return self._infoGroup end
        self:_ensureSectionMeta()

        local infoTitle
        if self._name == "Arena" then
            infoTitle = "Arena Status"
            self._infoGroup = self._tab:AddLeftGroupbox(infoTitle)
        else
            infoTitle = (self._sectionName == "General") and "Info" or (self._sectionName .. " Info")
            if self._controlSide == "left" then
                self._infoGroup = self._tab:AddRightGroupbox(infoTitle)
            else
                self._infoGroup = self._tab:AddLeftGroupbox(infoTitle)
            end
        end
        return self._infoGroup
    end

    function proxy:CreateSection(name)
        -- Do not render an empty box. The first actual control/paragraph decides
        -- which of the paired AliceHUB columns is created.
        self._group = nil
        self._infoGroup = nil
        self._sectionActive = false
        self._sectionName = nil
        self._controlSide = nil
        self._pendingSection = tostring(name or "General")
    end

    function proxy:CreateToggle(config)
        config = type(config) == "table" and config or {}
        local group = self:_ensureGroup()
        local id = uniqueId(config.Flag, "Toggle")
        group:AddToggle(id, {
            Text = tostring(config.Name or config.Flag or "Toggle"),
            Default = config.CurrentValue == true,
        })
        local raw = Toggles[id]
        if raw and type(raw.OnChanged) == "function" then
            raw:OnChanged(function()
            invoke(config.Callback, raw.Value == true, "toggle")
            end)
        end
        return controlProxy(raw, config.Callback, "toggle")
    end

    function proxy:CreateSlider(config)
        config = type(config) == "table" and config or {}
        local group = self:_ensureGroup()
        local range = type(config.Range) == "table" and config.Range or {0, 100}
        local id = uniqueId(config.Flag, "Slider")
        group:AddSlider(id, {
            Text = tostring(config.Name or config.Flag or "Slider"),
            Default = tonumber(config.CurrentValue) or tonumber(range[1]) or 0,
            Min = tonumber(range[1]) or 0,
            Max = tonumber(range[2]) or 100,
            Rounding = 0,
            Suffix = tostring(config.Suffix or ""),
        })
        local raw = Options[id]
        if raw and type(raw.OnChanged) == "function" then
            raw:OnChanged(function()
                invoke(config.Callback, raw.Value, "value")
            end)
        end
        return controlProxy(raw, config.Callback, "value")
    end

    function proxy:CreateDropdown(config)
        config = type(config) == "table" and config or {}
        local group = self:_ensureGroup()
        local values = type(config.Options) == "table" and config.Options or {}
        local multi = config.MultipleOptions == true
        local default = config.CurrentOption
        if default == nil then default = multi and {} or values[1] end
        local id = uniqueId(config.Flag, "Dropdown")
        group:AddDropdown(id, {
            Text = tostring(config.Name or config.Flag or "Dropdown"),
            Values = values,
            Default = default,
            Multi = multi,
            Searchable = true,
        })
        local raw = Options[id]
        if raw and type(raw.OnChanged) == "function" then
            raw:OnChanged(function()
                invoke(config.Callback, raw.Value, "value")
            end)
        end
        return controlProxy(raw, config.Callback, "value")
    end

    function proxy:CreateInput(config)
        config = type(config) == "table" and config or {}
        local group = self:_ensureGroup()
        local id = uniqueId(config.Flag, "Input")
        group:AddInput(id, {
            Text = tostring(config.Name or config.Flag or "Input"),
            Default = tostring(config.CurrentValue or ""),
            Placeholder = tostring(config.PlaceholderText or ""),
            Numeric = false,
            Finished = true,
        })
        local raw = Options[id]
        if raw and type(raw.OnChanged) == "function" then
            raw:OnChanged(function()
                invoke(config.Callback, raw.Value, "value")
            end)
        end
        return controlProxy(raw, config.Callback, "value")
    end

    function proxy:CreateParagraph(config)
        config = type(config) == "table" and config or {}
        local group = self:_ensureInfoGroup()
        local title = tostring(config.Title or "Info")
        local content = tostring(config.Content or "")
        local raw = group:AddLabel(title .. "\n" .. content, true)
        local paragraph = {
            _pgTitle = title,
            _pgContent = content,
            Raw = raw,
        }
        function paragraph:Set(value)
            if type(value) == "table" then
                self._pgTitle = tostring(value.Title or self._pgTitle or "Info")
                self._pgContent = tostring(value.Content or self._pgContent or "")
            else
                self._pgContent = tostring(value or "")
            end
            local text = self._pgTitle .. "\n" .. self._pgContent
            if self.Raw and type(self.Raw.SetText) == "function" then
                self.Raw:SetText(text)
            end
        end
        return paragraph
    end

    return proxy
end


-- ============================================================
-- AliceHUB · Grow A Chicken Fighter · Independent Core
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ENV = (getgenv and getgenv()) or _G

if type(ENV.AliceHUB_ChickenIndependentCleanup) == "function" then
    pcall(ENV.AliceHUB_ChickenIndependentCleanup)
end

local State = {
    Running = true,
    MoveBusy = false,
    LastCollect = "Idle",
    LastSell = "Idle",
    LastFuse = "Idle",
    LastPromote = "Idle",
    LastArena = "Idle",
    LastTower = "Idle",
    LastReward = "Idle",
    LastFeeder = "Idle",
    LastCharm = "Idle",
    LastChaos = "Idle",
    LastEncourage = "Idle",
    ScrapPicked = 0,
    ScrapDeposits = 0,
    SessionStart = os.clock(),
}

local Config = {
    Hatch = {
        Enabled = false,
        Egg = "auto",
        Delay = 1.0,
    },

    Collect = {
        Eggs = false,
        OnlyMine = true,
        Drops = false,
        Delay = 0.30,
        Priority = "Highest Value",
        DepositEvery = 20,
        ReturnToRecycler = true,
        Kinds = {
            scrap = true,
            ufoPart = true,
            meteorRock = true,
            eggPod = true,
            goldCoin = true,
            tradeOre = true,
        },
    },

    Sell = {
        Enabled = false,
        Interval = 5,
        MaxLevel = 10,
        MinReceive = 0,
        ProtectFavorite = true,
        ProtectActive = true,
        ProtectMutation = true,
        ProtectPromo = true,
        KeepPerType = 0,
        Rarities = {
            common = true,
            uncommon = true,
            rare = true,
            epic = false,
            legendary = false,
            mythic = false,
            divine = false,
            celestial = false,
            cosmic = false,
            secret = false,
        },
    },

    Chaos = {
        Enabled = false,
        Delay = 0.5,

        Encourage = false,
        EncourageCPS = 2,
    },

    Favorite = {
        Enabled = false,
        Interval = 10,
        Rarities = {
            mythic = true,
            divine = true,
            celestial = true,
            cosmic = true,
            secret = true,
        },
    },

    Fuse = {
        Enabled = false,
        Interval = 4,
    },

    Promote = {
        Enabled = false,
        Interval = 5,
    },

    Incubator = {
        AutoClaim = false,
        Interval = 20,
        SelectedId = nil,
    },

    Recycler = {
        AutoUpgrade = false,
        Interval = 8,
    },

    Generator = {
        AutoUpgrade = false,
        Interval = 10,
    },

    Feeder = {
        AutoBuy = false,
        AutoUpgrade = false,
        AutoExpand = false,
        UpgradeCPS = 5,
    },

    Charms = {
        SelectedId = nil,
        KeepTier = "legendary",
        AutoRoll = false,
        AutoLockGood = true,
        Interval = 2.5,
    },

    Arena = {
        AutoFight = false,
        Interval = 3,
        AutoAbility = false,
        AutoEquipBest = false,
        AutoClaim = false,
    },

    Tower = {
        AutoStart = false,
        AutoNoThanks = false,
        Interval = 12,
    },

    Rewards = {
        AutoClaim = false,
        Interval = 60,
    },

    Webhook = {
        URL = "",
        Enabled = false,
        Interval = 300,
        Last = "Idle",
        Generation = 0,
    },

    Settings = {
        AutoRejoin = false,
        RejoinMinutes = 17,
    },
}

local function notify(title, text, time)
    pcall(function()
        Library:Notify({
            Title = tostring(title or "AliceHUB"),
            Description = tostring(text or ""),
            Time = tonumber(time) or 5,
        })
    end)
end

local function safeRequire(instance)
    if not instance or not instance:IsA("ModuleScript") then
        return nil
    end
    local ok, result = pcall(require, instance)
    return ok and result or nil
end

local function getModule(path)
    local node = ReplicatedStorage
    for segment in string.gmatch(path, "[^%.]+") do
        node = node and node:FindFirstChild(segment)
    end
    return safeRequire(node)
end

local DataController = safeRequire(
    LocalPlayer:WaitForChild("PlayerScripts")
        :WaitForChild("Core")
        :WaitForChild("Data")
        :WaitForChild("DataController")
)

local ChickenTypes = getModule("Content.Catalog.ChickenTypes") or {}
local Eggs = getModule("Content.Catalog.Eggs") or {}
local SellValue = getModule("Features.Chicken.SellValue") or {}
local EggLadder = getModule("Features.Chicken.EggLadder") or {}
local RecyclerView = getModule("Features.Scrap.RecyclerView") or {}
local Stackables = getModule("Content.Stackables") or {}

local function getter(name)
    if type(DataController) ~= "table" or type(DataController[name]) ~= "function" then
        return nil
    end
    local ok, value = pcall(DataController[name])
    return ok and value or nil
end

local function RF(name)
    local obj = Remotes:FindFirstChild(name)
    return obj and obj:IsA("RemoteFunction") and obj or nil
end

local function RE(name)
    local obj = Remotes:FindFirstChild(name)
    return obj and obj:IsA("RemoteEvent") and obj or nil
end

local function invokeRemote(name, ...)
    local remote = RF(name)
    if not remote then
        return false, "RemoteFunction missing: " .. tostring(name)
    end
    return pcall(function(...)
        return remote:InvokeServer(...)
    end, ...)
end

local function fireRemote(name, ...)
    local remote = RE(name)
    if not remote then
        return false, "RemoteEvent missing: " .. tostring(name)
    end
    return pcall(function(...)
        remote:FireServer(...)
        return true
    end, ...)
end

local function roster()
    local value = getter("roster")
    return type(value) == "table" and value or {chickens = {}}
end

local function chickens()
    local r = roster()
    return type(r.chickens) == "table" and r.chickens or {}
end

local function chickenDisplay(chicken)
    if type(chicken) ~= "table" then return "?" end
    local def = ChickenTypes[chicken.typeId]
    local name = type(def) == "table" and def.name or chicken.typeId or chicken.id or "Chicken"
    return string.format(
        "%s · %s · Lv%s · %s",
        tostring(chicken.id or "?"),
        tostring(name),
        tostring(chicken.level or 1),
        tostring(chicken.rarity or "?")
    )
end

local function rebirthCount()
    local value = getter("rebirth")
    if type(value) == "table" then
        return tonumber(value.count) or 0
    end
    return tonumber(value) or 0
end

local function currentRecyclerLevel()
    return tonumber(getter("recyclerLevel")) or 0
end

local function towerPeak()
    return tonumber(getter("towerPeak")) or tonumber(getter("towerBest")) or 0
end

local function moneyNumber()
    local value = getter("money")
    if type(value) == "number" then
        return value
    end
    if type(value) == "table" then
        local mult = tonumber(value.multiplicand)
        local exp = tonumber(value.exponent) or 0
        if mult and exp >= 0 and exp < 100 then
            local ok, result = pcall(function()
                return mult * (10 ^ exp)
            end)
            if ok and tonumber(result) then
                return tonumber(result)
            end
        end
    end
    return nil
end

local function compactNumber(value)
    local n = tonumber(value)
    if not n then return tostring(value or "N/A") end

    local abs = math.abs(n)
    local function f(div, suffix)
        local x = n / div
        if math.abs(x) >= 100 then return string.format("%.0f%s", x, suffix) end
        if math.abs(x) >= 10 then return string.format("%.1f%s", x, suffix):gsub("%.0", "") end
        return string.format("%.2f%s", x, suffix):gsub("0+$", ""):gsub("%.$", "")
    end

    if abs >= 1e15 then return f(1e15, "Qa") end
    if abs >= 1e12 then return f(1e12, "T") end
    if abs >= 1e9 then return f(1e9, "B") end
    if abs >= 1e6 then return f(1e6, "M") end
    if abs >= 1e3 then return f(1e3, "K") end
    return n % 1 == 0 and string.format("%.0f", n) or tostring(n)
end

local function signedCompact(value)
    local n = tonumber(value) or 0
    if n >= 0 then
        return "+" .. compactNumber(n)
    end
    return compactNumber(n)
end

local function moneyText()
    local n = moneyNumber()
    return n and compactNumber(n) or "N/A"
end

local function activeChicken()
    local r = roster()
    local activeId = tostring(r.activeId or "")
    for _, c in ipairs(type(r.chickens) == "table" and r.chickens or {}) do
        if tostring(c.id) == activeId then
            return c
        end
    end
    return nil
end

local SessionBase = {
    Money = moneyNumber() or 0,
    Rebirth = rebirthCount(),
    Recycler = currentRecyclerLevel(),
    Tower = towerPeak(),
    ActiveId = nil,
    ActiveLevel = 0,
}

do
    local c = activeChicken()
    if c then
        SessionBase.ActiveId = tostring(c.id or "")
        SessionBase.ActiveLevel = tonumber(c.level) or 0
    end
end

local function valueOfSell(chicken)
    if type(SellValue) ~= "table" or type(SellValue.of) ~= "function" then
        return nil
    end
    local ok, result = pcall(
        SellValue.of,
        tostring(chicken.rarity or ""),
        tonumber(chicken.level) or 1,
        true
    )
    return ok and tonumber(result) or nil
end

local function selectedFromMulti(value)
    local set = {}
    if type(value) == "table" then
        for k, v in pairs(value) do
            if type(k) == "string" and v == true then
                set[string.lower(k)] = true
            elseif type(v) == "string" then
                set[string.lower(v)] = true
            end
        end
    elseif type(value) == "string" then
        set[string.lower(value)] = true
    end
    return set
end

local function sortedEggOptions()
    local out = {"auto"}
    local rows = {}
    for id, def in pairs(Eggs) do
        if type(def) == "table" then
            rows[#rows + 1] = {
                id = tostring(id),
                name = tostring(def.name or id),
            }
        end
    end
    table.sort(rows, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)
    for _, row in ipairs(rows) do
        out[#out + 1] = row.id
    end
    return out
end

local function resolveEgg()
    local selected = tostring(Config.Hatch.Egg or "auto")
    if selected ~= "auto" then
        return selected
    end
    if type(EggLadder) == "table" and type(EggLadder.resolve) == "function" then
        local ok, result = pcall(EggLadder.resolve, EggLadder.AUTO or "auto", rebirthCount())
        if ok and result then
            return tostring(result)
        end
    end
    return "feed"
end

-- ============================================================
-- Movement / Collect
-- ============================================================

local trackedDrops = {}

local function trackDrop(obj)
    if not obj or not obj:IsA("BasePart") then return end
    if obj:GetAttribute("StackKind") ~= nil then
        trackedDrops[obj] = true
    end

    pcall(function()
        obj:GetAttributeChangedSignal("StackKind"):Connect(function()
            if obj.Parent and obj:GetAttribute("StackKind") ~= nil then
                trackedDrops[obj] = true
            end
        end)
    end)
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") then
        trackDrop(obj)
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") then
        task.defer(function()
            task.wait(0.05)
            trackDrop(obj)
        end)
    end
end)

local function getCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
    return char, hum, root
end

local function moveToPosition(position, target, timeout)
    if State.MoveBusy then return false, "busy" end
    State.MoveBusy = true

    local okResult, reason = pcall(function()
        local _, hum, root = getCharacter()
        local started = os.clock()
        timeout = tonumber(timeout) or 8

        while State.Running and os.clock() - started < timeout do
            if target and not target.Parent then
                return true
            end

            hum:MoveTo(position)

            local d = (root.Position - position).Magnitude
            if d <= 4.5 then
                local grace = os.clock()
                while os.clock() - grace < 0.9 do
                    if target and not target.Parent then
                        return true
                    end
                    hum:MoveTo(position)
                    task.wait(0.08)
                end
                return true
            end

            task.wait(0.12)
        end

        return false
    end)

    State.MoveBusy = false
    return okResult and reason == true, okResult and "done" or tostring(reason)
end

local function tierMultiplier(kind, tier)
    local def = Stackables[kind]
    if type(def) == "table" and type(def.tiers) == "table" then
        for _, row in ipairs(def.tiers) do
            if tostring(row.id) == tostring(tier) then
                return tonumber(row.mult) or 1
            end
        end
    end
    return 1
end

local function pieceBase(kind)
    local def = Stackables[kind]
    if type(def) == "table" and type(def.value) == "table"
        and type(RecyclerView) == "table"
        and type(RecyclerView.pieceValue) == "function"
    then
        local ok, value = pcall(RecyclerView.pieceValue, def.value, currentRecyclerLevel())
        if ok and tonumber(value) then
            return tonumber(value)
        end
    end
    return 1
end

local function dropAllowed(obj)
    if not obj or not obj.Parent then return false end
    local kind = tostring(obj:GetAttribute("StackKind") or "")
    if kind == "" or Config.Collect.Kinds[kind] ~= true then
        return false
    end

    local pickupAt = tonumber(obj:GetAttribute("PickupAt"))
    local owner = tostring(obj:GetAttribute("DropOwner") or "")
    if pickupAt and Workspace.DistributedGameTime < pickupAt then
        if not string.find(owner, tostring(LocalPlayer.UserId), 1, true) then
            return false
        end
    end

    return true
end

local function bestDrop()
    local _, _, root = getCharacter()
    local candidates = {}

    for obj in pairs(trackedDrops) do
        if not obj.Parent then
            trackedDrops[obj] = nil
        elseif dropAllowed(obj) then
            local kind = tostring(obj:GetAttribute("StackKind"))
            local tier = tostring(obj:GetAttribute("StackTier") or "")
            local distance = (root.Position - obj.Position).Magnitude
            local score = pieceBase(kind) * tierMultiplier(kind, tier)
            candidates[#candidates + 1] = {
                obj = obj,
                distance = distance,
                score = score,
                kind = kind,
                tier = tier,
            }
        end
    end

    table.sort(candidates, function(a, b)
        if Config.Collect.Priority == "Nearest" then
            return a.distance < b.distance
        end
        if a.score == b.score then
            return a.distance < b.distance
        end
        return a.score > b.score
    end)

    return candidates[1]
end

local function nestEggOwnedByLocal(obj)
    if not obj then return false end

    local function matches(value)
        if value == nil then return false end

        if typeof(value) == "Instance" then
            if value == LocalPlayer then
                return true
            end
            if value:IsA("Player") then
                return value.UserId == LocalPlayer.UserId
            end
        end

        local s = string.lower(tostring(value))
        local uid = tostring(LocalPlayer.UserId)
        local username = string.lower(LocalPlayer.Name)

        return s == uid
            or s == username
            or s == ("player:" .. uid)
            or s == ("player_" .. uid)
            or string.find(s, uid, 1, true) ~= nil
            or string.find(s, username, 1, true) ~= nil
    end

    local keys = {
        "owner", "Owner",
        "ownerId", "OwnerId",
        "userId", "UserId",
        "ownerUserId", "OwnerUserId",
        "player", "Player",
        "username", "Username",
    }

    local node = obj

    for _ = 1, 6 do
        if not node then break end

        for _, key in ipairs(keys) do
            local ok, value = pcall(function()
                return node:GetAttribute(key)
            end)

            if ok and matches(value) then
                return true
            end
        end

        node = node.Parent
    end

    return false
end

local function bestNestEgg()
    local _, _, root = getCharacter()
    local best, bestDist

    local tagged = {}
    pcall(function()
        tagged = CollectionService:GetTagged("NestEgg")
    end)

    if #tagged == 0 then
        local folder = Workspace:FindFirstChild("NestEggs")
        if folder then
            tagged = folder:GetChildren()
        end
    end

    for _, obj in ipairs(tagged) do
        if obj:IsA("BasePart") and obj.Parent then
            -- AliceHUB safety rule: NEVER target other players' NestEggs.
            -- Accepts numeric owner, string owner, "player:<id>", username,
            -- and owner metadata inherited from an ancestor model.
            if nestEggOwnedByLocal(obj) then
                local d = (root.Position - obj.Position).Magnitude
                if not bestDist or d < bestDist then
                    best = obj
                    bestDist = d
                end
            end
        end
    end

    return best, bestDist
end

local function objectPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        local ok, cf = pcall(function() return obj:GetPivot() end)
        if ok then return cf.Position end
    end
    return nil
end

local HomeAnchor = nil
local CachedOwnRecycler = nil
local CachedOwnRecyclerAt = 0

local function attrMatchesLocalPlayer(obj)
    if not obj then return false end

    local attrs = obj:GetAttributes()
    local keys = {
        "owner", "Owner",
        "ownerId", "OwnerId",
        "userId", "UserId",
        "ownerUserId", "OwnerUserId",
        "player", "Player",
        "username", "Username",
    }

    for _, key in ipairs(keys) do
        local value = attrs[key]
        if value ~= nil then
            local s = tostring(value)
            if s == tostring(LocalPlayer.UserId)
                or s == tostring(LocalPlayer.Name)
                or string.find(s, tostring(LocalPlayer.UserId), 1, true)
                or string.find(string.lower(s), string.lower(LocalPlayer.Name), 1, true)
            then
                return true
            end
        end
    end

    return false
end

local function ownedByLocalPlayerInAncestors(obj)
    local node = obj
    for _ = 1, 8 do
        if not node or node == Workspace then break end
        if attrMatchesLocalPlayer(node) then
            return true
        end
        node = node.Parent
    end
    return false
end

local function refreshHomeAnchor()
    local ownedPositions = {}
    local tagged = {}

    pcall(function()
        tagged = CollectionService:GetTagged("NestEgg")
    end)

    for _, egg in ipairs(tagged) do
        if egg:IsA("BasePart")
            and nestEggOwnedByLocal(egg)
        then
            ownedPositions[#ownedPositions + 1] = egg.Position
        end
    end

    if #ownedPositions > 0 then
        local sum = Vector3.zero
        for _, pos in ipairs(ownedPositions) do
            sum += pos
        end
        HomeAnchor = sum / #ownedPositions
        return HomeAnchor
    end

    if not HomeAnchor then
        local _, _, root = getCharacter()
        HomeAnchor = root.Position
    end

    return HomeAnchor
end

local function findOwnRecyclerPosition()
    if CachedOwnRecycler
        and CachedOwnRecycler.Parent
        and os.clock() - CachedOwnRecyclerAt < 15
    then
        return objectPosition(CachedOwnRecycler)
    end

    local home = refreshHomeAnchor()
    local ownedBest, ownedScore
    local homeBest, homeScore

    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = string.lower(tostring(obj.Name or ""))

        if string.find(name, "recycler", 1, true) then
            local pos = objectPosition(obj)

            if pos then
                local own = ownedByLocalPlayerInAncestors(obj)
                local score = (pos - home).Magnitude

                if obj:IsA("BasePart") then
                    score -= 5
                end

                if string.find(name, "deposit", 1, true)
                    or string.find(name, "touch", 1, true)
                    or string.find(name, "hitbox", 1, true)
                    or string.find(name, "intake", 1, true)
                then
                    score -= 25
                end

                if own then
                    if not ownedScore or score < ownedScore then
                        ownedScore = score
                        ownedBest = obj
                    end
                elseif not homeScore or score < homeScore then
                    homeScore = score
                    homeBest = obj
                end
            end
        end
    end

    CachedOwnRecycler = ownedBest or homeBest
    CachedOwnRecyclerAt = os.clock()

    if CachedOwnRecycler then
        return objectPosition(CachedOwnRecycler)
    end

    return nil
end

local function returnToRecycler()
    local pos = findOwnRecyclerPosition()
    if not pos then
        State.LastCollect = "Own recycler not found"
        return false
    end

    State.LastCollect = "Returning → My Recycler"
    local ok = moveToPosition(pos, nil, 12)
    if ok then
        State.ScrapDeposits += 1
        State.ScrapPicked = 0
        State.LastCollect = "My Recycler reached · deposit #" .. tostring(State.ScrapDeposits)
        task.wait(0.8)
    end
    return ok
end

task.spawn(function()
    while State.Running do
        if not State.MoveBusy then
            local depositEvery = math.clamp(
                math.floor(tonumber(Config.Collect.DepositEvery) or 20),
                1,
                50
            )

            if Config.Collect.Drops
                and Config.Collect.ReturnToRecycler
                and State.ScrapPicked >= depositEvery
            then
                returnToRecycler()
            else
                local targetType, target, targetKind

                -- Drops get first priority while drop collection is enabled.
                -- This avoids bouncing between a NestEgg and scrap every frame.
                if Config.Collect.Drops then
                    local row = bestDrop()
                    if row then
                        targetType = row.kind .. ":" .. row.tier
                        targetKind = row.kind
                        target = row.obj
                    end
                end

                if not target and Config.Collect.Eggs then
                    local egg = bestNestEgg()
                    if egg then
                        targetType, target = "NestEgg", egg
                    end
                end

                if target and target.Parent then
                    State.LastCollect = "Moving → " .. tostring(targetType)

                    local beforeParent = target.Parent
                    moveToPosition(target.Position, target, 8)
                    task.wait(math.max(0.20, tonumber(Config.Collect.Delay) or 0.30))

                    local disappeared = target.Parent == nil or target.Parent ~= beforeParent
                    if targetKind == "scrap" and disappeared then
                        State.ScrapPicked += 1
                    end

                    State.LastCollect = string.format(
                        "%s · scrap %d/%d",
                        disappeared and ("Collected " .. tostring(targetType))
                            or ("Reached " .. tostring(targetType)),
                        State.ScrapPicked,
                        depositEvery
                    )
                end
            end
        end

        task.wait(math.max(0.20, tonumber(Config.Collect.Delay) or 0.30))
    end
end)

-- ============================================================
-- Hatch
-- ============================================================

local function hatchOnce()
    local egg = resolveEgg()
    local ok, result = invokeRemote("HatchEgg", egg)
    if ok then
        return true, egg, result
    end
    return false, egg, result
end

task.spawn(function()
    while State.Running do
        if Config.Hatch.Enabled then
            hatchOnce()
        end
        task.wait(math.max(0.15, tonumber(Config.Hatch.Delay) or 1))
    end
end)

-- ============================================================
-- Smart Sell
-- ============================================================

local function smartSellPreview()
    local r = roster()
    local list = type(r.chickens) == "table" and r.chickens or {}
    local activeId = tostring(r.activeId or "")
    local counts = {}

    for _, c in ipairs(list) do
        counts[tostring(c.typeId or "")] = (counts[tostring(c.typeId or "")] or 0) + 1
    end

    local selectedPerType = {}
    local ids = {}
    local total = 0

    for _, c in ipairs(list) do
        local reasons = {}
        local rarity = string.lower(tostring(c.rarity or ""))
        local id = tostring(c.id or "")
        local typeId = tostring(c.typeId or "")
        local level = tonumber(c.level) or 1
        local promo = tonumber(c.promo) or 0
        local receive = valueOfSell(c)

        if Config.Sell.Rarities[rarity] ~= true then
            reasons[#reasons + 1] = "rarity"
        end
        if level > (tonumber(Config.Sell.MaxLevel) or 10) then
            reasons[#reasons + 1] = "level"
        end
        if Config.Sell.ProtectFavorite and c.favorite == true then
            reasons[#reasons + 1] = "favorite"
        end
        if Config.Sell.ProtectActive and id == activeId then
            reasons[#reasons + 1] = "active"
        end
        if Config.Sell.ProtectMutation and c.mutation ~= nil and tostring(c.mutation) ~= "" then
            reasons[#reasons + 1] = "mutation"
        end
        if Config.Sell.ProtectPromo and promo > 0 then
            reasons[#reasons + 1] = "promo"
        end
        if receive == nil then
            reasons[#reasons + 1] = "value"
        elseif receive < (tonumber(Config.Sell.MinReceive) or 0) then
            reasons[#reasons + 1] = "minvalue"
        end

        if #reasons == 0 and (tonumber(Config.Sell.KeepPerType) or 0) > 0 then
            local keep = math.floor(tonumber(Config.Sell.KeepPerType) or 0)
            local already = selectedPerType[typeId] or 0
            if (counts[typeId] or 0) - already <= keep then
                reasons[#reasons + 1] = "keeptype"
            end
        end

        if #reasons == 0 and id ~= "" then
            ids[#ids + 1] = id
            total += receive or 0
            selectedPerType[typeId] = (selectedPerType[typeId] or 0) + 1
        end
    end

    return ids, math.floor(total)
end

local function smartSellOnce()
    local ids, total = smartSellPreview()
    if #ids == 0 then
        State.LastSell = "No candidates"
        return true, 0, total
    end

    local sold = 0
    for i = 1, #ids, 40 do
        local batch = {}
        for j = i, math.min(i + 39, #ids) do
            batch[#batch + 1] = ids[j]
        end
        local ok = invokeRemote("SellChickens", batch)
        if ok then sold += #batch end
        task.wait(0.2)
    end

    State.LastSell = string.format("Sold %d · ~%d", sold, total)
    return true, sold, total
end

task.spawn(function()
    while State.Running do
        if Config.Sell.Enabled then
            smartSellOnce()
        end
        task.wait(math.max(1, tonumber(Config.Sell.Interval) or 5))
    end
end)

-- ============================================================
-- Favorite / Fuse / Promote
-- ============================================================

local function protectedForMaterial(c, activeId)
    if c.favorite == true then return true end
    if tostring(c.id) == tostring(activeId) then return true end
    if c.mutation ~= nil and tostring(c.mutation) ~= "" then return true end
    if (tonumber(c.promo) or 0) > 0 then return true end
    return false
end

local function favoriteMatching()
    local count = 0
    for _, c in ipairs(chickens()) do
        local rarity = string.lower(tostring(c.rarity or ""))
        if Config.Favorite.Rarities[rarity] and c.favorite ~= true then
            local ok = invokeRemote("SetChickenFavorite", tostring(c.id), true)
            if ok then count += 1 end
            task.wait(0.12)
        end
    end
    return count
end

task.spawn(function()
    while State.Running do
        if Config.Favorite.Enabled then
            favoriteMatching()
        end
        task.wait(math.max(2, tonumber(Config.Favorite.Interval) or 10))
    end
end)

-- ============================================================
-- Chicken Order · Auto Chaos
-- Verified mapping: SetChickenOrder:FireServer("chaos")
-- ============================================================

task.spawn(function()
    while State.Running do
        if Config.Chaos.Enabled then
            local ok, result = fireRemote("SetChickenOrder", "chaos")
            State.LastChaos = ok and "Chaos active" or ("Chaos error: " .. tostring(result))
        else
            State.LastChaos = "Idle"
        end

        task.wait(math.max(0.1, tonumber(Config.Chaos.Delay) or 0.5))
    end
end)

local function encourageOnce()
    local ok, result = invokeRemote("EncourageChicken")
    State.LastEncourage = ok
        and "Encouraged active chicken"
        or ("Encourage error: " .. tostring(result))
    return ok, result
end

task.spawn(function()
    while State.Running do
        if Config.Chaos.Encourage then
            encourageOnce()
        end

        task.wait(
            0.5 / math.max(
                tonumber(Config.Chaos.EncourageCPS) or 2,
                1
            )
        )
    end
end)

local function fuseOnce()
    local r = roster()
    local activeId = r.activeId
    local groups = {}

    for _, c in ipairs(type(r.chickens) == "table" and r.chickens or {}) do
        if not protectedForMaterial(c, activeId) then
            local key = table.concat({
                tostring(c.typeId or ""),
                tostring(c.rarity or ""),
                tostring(c.level or 1),
            }, "|")
            groups[key] = groups[key] or {}
            groups[key][#groups[key] + 1] = c
        end
    end

    for _, group in pairs(groups) do
        if #group >= 2 then
            table.sort(group, function(a, b)
                return tostring(a.id) < tostring(b.id)
            end)
            local ok, result = invokeRemote(
                "FuseChickens",
                tostring(group[1].id),
                tostring(group[2].id),
                {}
            )
            State.LastFuse = ok
                and ("Fuse " .. tostring(group[1].id) .. " + " .. tostring(group[2].id))
                or ("Fuse error: " .. tostring(result))
            return ok, result
        end
    end

    State.LastFuse = "No safe pair"
    return false, "no safe pair"
end

task.spawn(function()
    while State.Running do
        if Config.Fuse.Enabled then
            fuseOnce()
        end
        task.wait(math.max(2, tonumber(Config.Fuse.Interval) or 4))
    end
end)

local function promoteOnce()
    local r = roster()
    local activeId = r.activeId
    local groups = {}

    for _, c in ipairs(type(r.chickens) == "table" and r.chickens or {}) do
        if not protectedForMaterial(c, activeId) then
            local key = tostring(c.typeId or "") .. "|" .. tostring(c.rarity or "")
            groups[key] = groups[key] or {}
            groups[key][#groups[key] + 1] = c
        end
    end

    for _, group in pairs(groups) do
        if #group >= 3 then
            table.sort(group, function(a, b)
                local pa = tonumber(a.promo) or 0
                local pb = tonumber(b.promo) or 0
                if pa ~= pb then return pa > pb end
                local la = tonumber(a.level) or 1
                local lb = tonumber(b.level) or 1
                if la ~= lb then return la > lb end
                return tostring(a.id) < tostring(b.id)
            end)

            local target = group[1]
            local fodder = {
                tostring(group[#group - 1].id),
                tostring(group[#group].id),
            }

            if tostring(target.id) ~= fodder[1]
                and tostring(target.id) ~= fodder[2]
                and fodder[1] ~= fodder[2]
            then
                local ok, result = invokeRemote(
                    "PromoteChicken",
                    tostring(target.id),
                    fodder
                )
                State.LastPromote = ok
                    and ("Promote " .. tostring(target.id))
                    or ("Promote error: " .. tostring(result))
                return ok, result
            end
        end
    end

    State.LastPromote = "No safe trio"
    return false, "no safe trio"
end

task.spawn(function()
    while State.Running do
        if Config.Promote.Enabled then
            promoteOnce()
        end
        task.wait(math.max(3, tonumber(Config.Promote.Interval) or 5))
    end
end)

-- ============================================================
-- Incubator / Recycler / Generator / Rebirth
-- ============================================================

task.spawn(function()
    while State.Running do
        if Config.Incubator.AutoClaim then
            invokeRemote("IncubatorClaim")
        end
        task.wait(math.max(5, tonumber(Config.Incubator.Interval) or 20))
    end
end)

local function recyclerCanTry()
    local level = currentRecyclerLevel()
    local max = 36
    if type(RecyclerView) == "table" and type(RecyclerView.maxLevel) == "function" then
        local ok, value = pcall(RecyclerView.maxLevel, rebirthCount())
        if ok and tonumber(value) then max = tonumber(value) end
    end
    if level >= max then
        return false, "MAX " .. tostring(max)
    end

    if type(RecyclerView) == "table" and type(RecyclerView.gateFloor) == "function" then
        local ok, gate = pcall(RecyclerView.gateFloor, level)
        if ok and tonumber(gate) and towerPeak() < tonumber(gate) then
            return false, "Need tower floor " .. tostring(gate)
        end
    end

    return true
end

task.spawn(function()
    while State.Running do
        if Config.Recycler.AutoUpgrade then
            local can = recyclerCanTry()
            if can then invokeRemote("UpgradeRecycler") end
        end
        task.wait(math.max(3, tonumber(Config.Recycler.Interval) or 8))
    end
end)

task.spawn(function()
    while State.Running do
        if Config.Generator.AutoUpgrade then
            invokeRemote("UpgradeGenerator")
        end
        task.wait(math.max(5, tonumber(Config.Generator.Interval) or 10))
    end
end)

-- ============================================================
-- Feeder / Coop
-- ============================================================

local FeederBuyId = 1
local FeederUpgradeId = 1

local function buyFeederStep()
    local id = FeederBuyId
    local ok1 = invokeRemote("BuyGenerator", id)
    task.wait(0.04)
    local ok2 = invokeRemote("BuyGenerator", id)
    FeederBuyId = FeederBuyId % 6 + 1
    State.LastFeeder = (ok1 or ok2) and ("Buy feeder ID " .. id) or ("Buy failed ID " .. id)
end

local function upgradeFeederStep()
    local id = FeederUpgradeId
    local ok, result = invokeRemote("UpgradeGenerator", id)
    FeederUpgradeId = FeederUpgradeId % 6 + 1
    State.LastFeeder = ok and ("Upgrade feeder ID " .. id) or tostring(result)
end

task.spawn(function()
    while State.Running do
        if Config.Feeder.AutoBuy then
            buyFeederStep()
        end
        task.wait(0.10)
    end
end)

task.spawn(function()
    while State.Running do
        if Config.Feeder.AutoUpgrade then
            upgradeFeederStep()
        end
        task.wait(0.5 / math.max(tonumber(Config.Feeder.UpgradeCPS) or 1, 1))
    end
end)

task.spawn(function()
    while State.Running do
        if Config.Feeder.AutoExpand then
            invokeRemote("ExpandCoop")
        end
        task.wait(0.10)
    end
end)

-- ============================================================
-- Arena - use the game's client API, not the raw no-arg remote
-- ============================================================

local ArenaClient, ArenaState, ArenaRankSettings, CharmReactive

local function loadArenaModules()
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local ui = playerScripts and playerScripts:FindFirstChild("UI")
    local twoD = ui and ui:FindFirstChild("2d")
    local arenaFolder = twoD and twoD:FindFirstChild("Arena")
    local settingsFolder = twoD and twoD:FindFirstChild("Settings")
    local packages = ReplicatedStorage:FindFirstChild("Packages")

    ArenaClient = safeRequire(arenaFolder and arenaFolder:FindFirstChild("ArenaClient"))
    ArenaState = safeRequire(arenaFolder and arenaFolder:FindFirstChild("ArenaState"))
    ArenaRankSettings = safeRequire(settingsFolder and settingsFolder:FindFirstChild("ArenaRankSettings"))
    CharmReactive = safeRequire(packages and packages:FindFirstChild("Charm"))
end

local function ensureArenaModules()
    if not ArenaClient or not ArenaState then
        loadArenaModules()
    end
end

local function callArenaClient(method, ...)
    ensureArenaModules()
    if type(ArenaClient) ~= "table" or type(ArenaClient[method]) ~= "function" then
        return false, "ArenaClient." .. tostring(method) .. " unavailable"
    end
    local args = table.pack(...)
    return pcall(function()
        return ArenaClient[method](table.unpack(args, 1, args.n))
    end)
end

local function arenaBattling()
    ensureArenaModules()
    if type(ArenaState) == "table" and type(ArenaState.battling) == "function" then
        local ok, value = pcall(ArenaState.battling)
        return ok and value == true
    end
    return false
end

local function arenaFightStep()
    if arenaBattling() then
        State.LastArena = "Battling..."
        return true
    end

    local ok, result = callArenaClient("fight")
    task.delay(0.12, function()
        callArenaClient("refresh")
    end)
    State.LastArena = ok and "Fight requested" or ("Fight failed: " .. tostring(result))
    return ok
end

local function arenaEquipBestStep()
    ensureArenaModules()
    local view = type(ArenaState) == "table"
        and type(ArenaState.view) == "function"
        and ArenaState.view()
        or nil

    local inventory = type(view) == "table" and view.inventory or nil
    if type(inventory) ~= "table" then
        State.LastArena = "Arena inventory unavailable"
        return false
    end

    if inventory[1] and inventory[1].id
        and inventory[2] and inventory[2].id
        and inventory[3] and inventory[3].id
    then
        local ok, result = callArenaClient("setTeam", {
            inventory[1].id,
            inventory[2].id,
            inventory[3].id,
        })
        if ok then State.LastArena = "Best team equipped" end
        return ok, result
    end

    State.LastArena = "Need 3 arena chickens"
    return false
end

local function arenaClaimStep()
    ensureArenaModules()
    local view = type(ArenaState) == "table"
        and type(ArenaState.view) == "function"
        and ArenaState.view()
        or nil
    local claimable = type(view) == "table" and view.claimable or nil
    if type(claimable) ~= "table" then return 0 end

    local claimed = 0
    for i = 1, 6 do
        local reward = claimable[i]
        if reward and reward.rankId ~= nil then
            local ok = callArenaClient("claim", reward.rankId)
            if ok then claimed += 1 end
            task.wait(0.15)
        end
    end
    if claimed > 0 then State.LastArena = "Claimed " .. claimed .. " arena reward(s)" end
    return claimed
end

local function setArenaAbility(value)
    ensureArenaModules()
    if type(ArenaRankSettings) == "table"
        and type(ArenaRankSettings.setAutoAbility) == "function"
    then
        local ok = pcall(ArenaRankSettings.setAutoAbility, value == true)
        return ok
    end
    local ok = fireRemote("SetArenaAutoAbility", value == true)
    return ok
end

task.spawn(function()
    while State.Running do
        if Config.Arena.AutoFight then
            arenaFightStep()
        end
        task.wait(math.max(3, tonumber(Config.Arena.Interval) or 3))
    end
end)

task.spawn(function()
    while State.Running do
        if Config.Arena.AutoEquipBest then
            arenaEquipBestStep()
        end
        task.wait(5)
    end
end)

task.spawn(function()
    while State.Running do
        if Config.Arena.AutoClaim then
            arenaClaimStep()
        end
        task.wait(3)
    end
end)

-- ============================================================
-- Tower
-- ============================================================

task.spawn(function()
    while State.Running do
        if Config.Tower.AutoStart then
            local ok, result = invokeRemote("TowerStart")
            State.LastTower = ok and "Start requested" or tostring(result)
        end
        task.wait(math.max(8, tonumber(Config.Tower.Interval) or 12))
    end
end)

task.spawn(function()
    while State.Running do
        if Config.Tower.AutoNoThanks then
            local ok, result = fireRemote("TowerContinueDecline")
            if ok then State.LastTower = "No Thanks watcher active" end
        end
        task.wait(0.20)
    end
end)

local rewardRemotes = {
    "DailyClaim",
    "ClaimIndexMilestones",
    "ClaimRebirthMilestones",
    "ClaimShopDust",
}

local function claimRewards()
    local okCount = 0
    for _, name in ipairs(rewardRemotes) do
        local ok = invokeRemote(name)
        if ok then okCount += 1 end
        task.wait(0.15)
    end
    State.LastReward = "Claims sent: " .. tostring(okCount)
    return okCount
end

task.spawn(function()
    while State.Running do
        if Config.Rewards.AutoClaim then
            claimRewards()
        end
        task.wait(math.max(30, tonumber(Config.Rewards.Interval) or 60))
    end
end)

-- ============================================================
-- Window
-- ============================================================

local viewport = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
local compact = viewport.X <= 1700 and viewport.Y <= 900
local targetWidth = compact and 700 or 900
local targetHeight = compact and 500 or 620
targetWidth = math.min(targetWidth, math.max(560, viewport.X - 80))
targetHeight = math.min(targetHeight, math.max(400, viewport.Y - 70))

Window = Library:CreateWindow({
    Title = "AliceHUB",
    Icon = ALICEHUB_LOGO_ASSET or "",
    IconSize = UDim2.fromOffset(28, 28),
    Font = Enum.Font.Code,
    Footer = {{Text = "AliceHUB", Copyable = false}, "|", "Grow A Chicken Fighter"},
    NotifySide = "Right",
    ShowMobileButtons = false,
    ShowCustomCursor = false,
    CornerRadius = 4,
    Size = UDim2.fromOffset(targetWidth, targetHeight),
})

applyAliceHubHeader(Window, "Grow A Chicken Fighter")
AliceEnv.AliceHUB_GACF_LogoGui = installAliceFloatingLogo(Window)

-- ============================================================
-- MAIN TAB
-- ============================================================

local MainTab = Window:AddTab("Main")

local HatchBox = MainTab:AddLeftGroupbox("Egg Automation")
HatchBox:AddDropdown("ChickenEggSelect", {
    Text = "Egg",
    Values = sortedEggOptions(),
    Default = "auto",
    Multi = false,
    Searchable = true,
})
Options.ChickenEggSelect:OnChanged(function()
    Config.Hatch.Egg = tostring(Options.ChickenEggSelect.Value or "auto")
end)

HatchBox:AddSlider("ChickenHatchDelay", {
    Text = "Hatch Delay",
    Default = 1,
    Min = 0.2,
    Max = 5,
    Rounding = 1,
    Suffix = " s",
})
Options.ChickenHatchDelay:OnChanged(function()
    Config.Hatch.Delay = tonumber(Options.ChickenHatchDelay.Value) or 1
end)

HatchBox:AddToggle("ChickenAutoHatch", {
    Text = "Auto Hatch",
    Default = false,
})
Toggles.ChickenAutoHatch:OnChanged(function()
    Config.Hatch.Enabled = Toggles.ChickenAutoHatch.Value == true
end)

HatchBox:AddButton({
    Text = "Hatch Once",
    Func = function()
        local ok, egg, result = hatchOnce()
        notify("AliceHUB · Hatch", ok and ("Hatched: " .. egg) or tostring(result))
    end,
})

local CollectBox = MainTab:AddRightGroupbox("Auto Collect")

CollectBox:AddToggle("ChickenCollectEggs", {
    Text = "Auto Collect Nest Eggs",
    Default = false,
})
Toggles.ChickenCollectEggs:OnChanged(function()
    Config.Collect.Eggs = Toggles.ChickenCollectEggs.Value == true
end)

CollectBox:AddToggle("ChickenOnlyMineEggs", {
    Text = "Only My Nest Eggs",
    Default = true,
})
Toggles.ChickenOnlyMineEggs:OnChanged(function()
    -- Locked to own eggs by design; turning this off will immediately be restored.
    if Toggles.ChickenOnlyMineEggs.Value ~= true then
        task.defer(function()
            Toggles.ChickenOnlyMineEggs:SetValue(true)
        end)
    end
    Config.Collect.OnlyMine = true
end)

CollectBox:AddToggle("ChickenCollectDrops", {
    Text = "Auto Collect Drops / Scrap",
    Default = false,
})
Toggles.ChickenCollectDrops:OnChanged(function()
    Config.Collect.Drops = Toggles.ChickenCollectDrops.Value == true
end)

CollectBox:AddDropdown("ChickenCollectKinds", {
    Text = "Collect Types",
    Values = {"scrap", "ufoPart", "meteorRock", "eggPod", "goldCoin", "tradeOre"},
    Default = {
        scrap = true,
        ufoPart = true,
        meteorRock = true,
        eggPod = true,
        goldCoin = true,
        tradeOre = true,
    },
    Multi = true,
    Searchable = false,
})
Options.ChickenCollectKinds:OnChanged(function()
    Config.Collect.Kinds = selectedFromMulti(Options.ChickenCollectKinds.Value)
end)

CollectBox:AddDropdown("ChickenCollectPriority", {
    Text = "Priority",
    Values = {"Highest Value", "Nearest"},
    Default = "Highest Value",
    Multi = false,
})
Options.ChickenCollectPriority:OnChanged(function()
    Config.Collect.Priority = tostring(Options.ChickenCollectPriority.Value or "Highest Value")
end)

CollectBox:AddSlider("ChickenDepositEvery", {
    Text = "Go Recycler Every",
    Default = 20,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Suffix = " scrap",
})
Options.ChickenDepositEvery:OnChanged(function()
    Config.Collect.DepositEvery = math.clamp(
        tonumber(Options.ChickenDepositEvery.Value) or 20,
        1,
        50
    )
end)

CollectBox:AddToggle("ChickenReturnRecycler", {
    Text = "Return To My Recycler",
    Default = true,
})
Toggles.ChickenReturnRecycler:OnChanged(function()
    Config.Collect.ReturnToRecycler = Toggles.ChickenReturnRecycler.Value == true
end)

local MainStatus = MainTab:AddRightGroupbox("Live Status")
local MainStatusLabel = MainStatus:AddLabel("Loading...", true)

-- ============================================================
-- CHICKENS TAB
-- ============================================================

local ChickensTab = Window:AddTab("Chickens")

local SellBox = ChickensTab:AddLeftGroupbox("Smart Sell")

SellBox:AddDropdown("ChickenSellRarities", {
    Text = "Sell Rarities",
    Values = {"common","uncommon","rare","epic","legendary","mythic","divine","celestial","cosmic","secret"},
    Default = {common=true, uncommon=true, rare=true},
    Multi = true,
    Searchable = false,
})
Options.ChickenSellRarities:OnChanged(function()
    Config.Sell.Rarities = selectedFromMulti(Options.ChickenSellRarities.Value)
end)

SellBox:AddSlider("ChickenSellMaxLevel", {
    Text = "Max Sell Level",
    Default = 10,
    Min = 1,
    Max = 100,
    Rounding = 0,
})
Options.ChickenSellMaxLevel:OnChanged(function()
    Config.Sell.MaxLevel = tonumber(Options.ChickenSellMaxLevel.Value) or 10
end)

SellBox:AddInput("ChickenSellMinValue", {
    Text = "Min Receive Value",
    Default = "0",
    Numeric = true,
    Finished = true,
})
Options.ChickenSellMinValue:OnChanged(function()
    Config.Sell.MinReceive = tonumber(Options.ChickenSellMinValue.Value) or 0
end)

SellBox:AddSlider("ChickenSellKeepPerType", {
    Text = "Keep Per Type",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 0,
})
Options.ChickenSellKeepPerType:OnChanged(function()
    Config.Sell.KeepPerType = tonumber(Options.ChickenSellKeepPerType.Value) or 0
end)

SellBox:AddToggle("ChickenProtectFav", {Text="Protect Favorite", Default=true})
SellBox:AddToggle("ChickenProtectActive", {Text="Protect Active", Default=true})
SellBox:AddToggle("ChickenProtectMutation", {Text="Protect Mutation", Default=true})
SellBox:AddToggle("ChickenProtectPromo", {Text="Protect Promo", Default=true})

Toggles.ChickenProtectFav:OnChanged(function() Config.Sell.ProtectFavorite = Toggles.ChickenProtectFav.Value end)
Toggles.ChickenProtectActive:OnChanged(function() Config.Sell.ProtectActive = Toggles.ChickenProtectActive.Value end)
Toggles.ChickenProtectMutation:OnChanged(function() Config.Sell.ProtectMutation = Toggles.ChickenProtectMutation.Value end)
Toggles.ChickenProtectPromo:OnChanged(function() Config.Sell.ProtectPromo = Toggles.ChickenProtectPromo.Value end)

SellBox:AddButton({
    Text = "Preview Sell",
    Func = function()
        local ids, total = smartSellPreview()
        notify("AliceHUB · Smart Sell", string.format("%d candidates · ~%d receive", #ids, total), 6)
    end,
})

SellBox:AddButton({
    Text = "Sell Once",
    Func = function()
        local _, sold, total = smartSellOnce()
        notify("AliceHUB · Smart Sell", string.format("Sold %d · ~%d", sold or 0, total or 0), 6)
    end,
})

SellBox:AddToggle("ChickenAutoSell", {
    Text = "Auto Smart Sell",
    Default = false,
})
Toggles.ChickenAutoSell:OnChanged(function()
    Config.Sell.Enabled = Toggles.ChickenAutoSell.Value == true
end)

local ManageBox = ChickensTab:AddRightGroupbox("Favorite / Fuse / Promote")

ManageBox:AddDropdown("ChickenFavoriteRarities", {
    Text = "Auto Favorite Rarities",
    Values = {"common","uncommon","rare","epic","legendary","mythic","divine","celestial","cosmic","secret"},
    Default = {mythic=true, divine=true, celestial=true, cosmic=true, secret=true},
    Multi = true,
})
Options.ChickenFavoriteRarities:OnChanged(function()
    Config.Favorite.Rarities = selectedFromMulti(Options.ChickenFavoriteRarities.Value)
end)

ManageBox:AddButton({
    Text = "Favorite Matching Now",
    Func = function()
        notify("AliceHUB · Favorite", "Favorited: " .. tostring(favoriteMatching()))
    end,
})

ManageBox:AddToggle("ChickenAutoFavorite", {Text="Auto Favorite", Default=false})
Toggles.ChickenAutoFavorite:OnChanged(function()
    Config.Favorite.Enabled = Toggles.ChickenAutoFavorite.Value == true
end)

ManageBox:AddDivider()

ManageBox:AddButton({
    Text = "Fuse One Safe Pair",
    Func = function()
        local ok, result = fuseOnce()
        notify("AliceHUB · Fuse", ok and State.LastFuse or tostring(result))
    end,
})

ManageBox:AddToggle("ChickenAutoFuse", {Text="Auto Fuse", Default=false})
Toggles.ChickenAutoFuse:OnChanged(function()
    Config.Fuse.Enabled = Toggles.ChickenAutoFuse.Value == true
end)

ManageBox:AddButton({
    Text = "Promote One Safe Trio",
    Func = function()
        local ok, result = promoteOnce()
        notify("AliceHUB · Promote", ok and State.LastPromote or tostring(result))
    end,
})

ManageBox:AddToggle("ChickenAutoPromote", {Text="Auto Promote", Default=false})
Toggles.ChickenAutoPromote:OnChanged(function()
    Config.Promote.Enabled = Toggles.ChickenAutoPromote.Value == true
end)

local ChaosBox = ChickensTab:AddRightGroupbox("Chicken Order")

ChaosBox:AddToggle("ChickenAutoChaos", {
    Text = "Auto Chaos",
    Default = false,
})
Toggles.ChickenAutoChaos:OnChanged(function()
    Config.Chaos.Enabled = Toggles.ChickenAutoChaos.Value == true
end)

ChaosBox:AddSlider("ChickenChaosDelay", {
    Text = "Chaos Delay",
    Default = 0.5,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Suffix = " s",
})
Options.ChickenChaosDelay:OnChanged(function()
    Config.Chaos.Delay = math.max(
        0.1,
        tonumber(Options.ChickenChaosDelay.Value) or 0.5
    )
end)

ChaosBox:AddDivider()

ChaosBox:AddButton({
    Text = "Encourage Once",
    Func = function()
        local ok, result = encourageOnce()
        notify(
            "AliceHUB · Encourage",
            ok and State.LastEncourage or tostring(result)
        )
    end,
})

ChaosBox:AddSlider("ChickenEncourageCPS", {
    Text = "Encourage CPS",
    Default = 2,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Suffix = " CPS",
})
Options.ChickenEncourageCPS:OnChanged(function()
    Config.Chaos.EncourageCPS =
        tonumber(Options.ChickenEncourageCPS.Value) or 2
end)

ChaosBox:AddToggle("ChickenAutoEncourage", {
    Text = "Auto Encourage",
    Default = false,
})
Toggles.ChickenAutoEncourage:OnChanged(function()
    Config.Chaos.Encourage =
        Toggles.ChickenAutoEncourage.Value == true
end)

local ChaosStatusLabel = ChaosBox:AddLabel(
    "Chaos: Idle\nEncourage: Idle",
    true
)

local IncubatorBox = ChickensTab:AddRightGroupbox("Incubator")

State.__rs_rosterOptions = function()
    local values = {}
    for _, c in ipairs(chickens()) do
        values[#values + 1] = chickenDisplay(c)
    end
    table.sort(values)
    return values
end

State.__rs_chickenIdFromDisplay = function(display)
    return tostring(display or ""):match("^([^%s]+)")
end

IncubatorBox:AddDropdown("ChickenIncubatorUnit", {
    Text = "Chicken",
    Values = State.__rs_rosterOptions(),
    Default = nil,
    Multi = false,
    Searchable = true,
})
Options.ChickenIncubatorUnit:OnChanged(function()
    Config.Incubator.SelectedId = State.__rs_chickenIdFromDisplay(Options.ChickenIncubatorUnit.Value)
end)

IncubatorBox:AddButton({
    Text = "Refresh Chicken List",
    Func = function()
        Options.ChickenIncubatorUnit:SetValues(State.__rs_rosterOptions())
        notify("AliceHUB · Incubator", "Roster refreshed")
    end,
})

IncubatorBox:AddButton({
    Text = "Insert Selected",
    Func = function()
        local id = Config.Incubator.SelectedId
        if not id then return notify("AliceHUB · Incubator", "Select chicken first") end
        local ok, result = invokeRemote("IncubatorInsert", id)
        notify("AliceHUB · Incubator", ok and ("Inserted " .. id) or tostring(result))
    end,
})

IncubatorBox:AddButton({
    Text = "Claim Incubator",
    Func = function()
        local ok, result = invokeRemote("IncubatorClaim")
        notify("AliceHUB · Incubator", ok and "Claim requested" or tostring(result))
    end,
})

IncubatorBox:AddButton({
    Text = "Remove Incubator",
    Func = function()
        local ok, result = invokeRemote("IncubatorRemove")
        notify("AliceHUB · Incubator", ok and "Remove requested" or tostring(result))
    end,
})

IncubatorBox:AddButton({
    Text = "Upgrade Incubator",
    Func = function()
        local ok, result = invokeRemote("IncubatorUpgrade")
        notify("AliceHUB · Incubator", ok and "Upgrade requested" or tostring(result))
    end,
})

IncubatorBox:AddToggle("ChickenAutoIncubatorClaim", {Text="Auto Claim Incubator", Default=false})
Toggles.ChickenAutoIncubatorClaim:OnChanged(function()
    Config.Incubator.AutoClaim = Toggles.ChickenAutoIncubatorClaim.Value == true
end)

-- ============================================================
-- PROGRESS TAB
-- ============================================================

local ProgressTab = Window:AddTab("Progress")

local RecyclerBox = ProgressTab:AddLeftGroupbox("Recycler")
local RecyclerStatus = RecyclerBox:AddLabel("Recycler: loading...", true)

RecyclerBox:AddButton({
    Text = "Upgrade Recycler Once",
    Func = function()
        local can, why = recyclerCanTry()
        if not can then return notify("AliceHUB · Recycler", why) end
        local ok, result = invokeRemote("UpgradeRecycler")
        notify("AliceHUB · Recycler", ok and "Upgrade requested" or tostring(result))
    end,
})

RecyclerBox:AddToggle("ChickenAutoRecycler", {Text="Auto Upgrade Recycler", Default=false})
Toggles.ChickenAutoRecycler:OnChanged(function()
    Config.Recycler.AutoUpgrade = Toggles.ChickenAutoRecycler.Value == true
end)

local GeneratorBox = ProgressTab:AddLeftGroupbox("Feeder / Coop")

GeneratorBox:AddButton({
    Text = "Buy Feeder Step",
    Func = function()
        buyFeederStep()
        notify("AliceHUB · Feeder", State.LastFeeder)
    end,
})

GeneratorBox:AddButton({
    Text = "Upgrade Feeder Step",
    Func = function()
        upgradeFeederStep()
        notify("AliceHUB · Feeder", State.LastFeeder)
    end,
})

GeneratorBox:AddSlider("ChickenFeederCPS", {
    Text = "Upgrade CPS",
    Default = 5,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Suffix = " CPS",
})
Options.ChickenFeederCPS:OnChanged(function()
    Config.Feeder.UpgradeCPS = tonumber(Options.ChickenFeederCPS.Value) or 5
end)

GeneratorBox:AddToggle("ChickenAutoBuyFeeder", {Text="Auto Buy Feeder", Default=false})
Toggles.ChickenAutoBuyFeeder:OnChanged(function()
    Config.Feeder.AutoBuy = Toggles.ChickenAutoBuyFeeder.Value == true
end)

GeneratorBox:AddToggle("ChickenAutoUpgradeFeeder", {Text="Auto Upgrade Feeder", Default=false})
Toggles.ChickenAutoUpgradeFeeder:OnChanged(function()
    Config.Feeder.AutoUpgrade = Toggles.ChickenAutoUpgradeFeeder.Value == true
end)

GeneratorBox:AddToggle("ChickenAutoExpandCoop", {Text="Auto Expand Coop", Default=false})
Toggles.ChickenAutoExpandCoop:OnChanged(function()
    Config.Feeder.AutoExpand = Toggles.ChickenAutoExpandCoop.Value == true
end)

local FeederStatusLabel = GeneratorBox:AddLabel("Feeder: Idle", true)

local RebirthBox = ProgressTab:AddRightGroupbox("Rebirth")
local RebirthStatusLabel = RebirthBox:AddLabel("Rebirth: Idle", true)

local AutoRebirthGeneration = 0

State.__rs_rebirthOnce = function()
    local before = rebirthCount()
    local ok, result = invokeRemote("Rebirth")

    if not ok then
        return false, tostring(result)
    end

    task.wait(0.15)

    local after = rebirthCount()
    if after > before then
        return true, ("Rebirth %d -> %d"):format(before, after)
    end

    if result == false then
        return false, "Belum memenuhi syarat Rebirth"
    end

    return true, "Rebirth request sent"
end

RebirthBox:AddButton({
    Text = "Rebirth Once",
    Func = function()
        task.spawn(function()
            local _, message = State.__rs_rebirthOnce()
            if RebirthStatusLabel then
                RebirthStatusLabel:SetText("Rebirth: " .. tostring(message))
            end
            notify("AliceHUB · Rebirth", tostring(message))
        end)
    end,
})

RebirthBox:AddToggle("ChickenAutoRebirth", {
    Text = "Auto Rebirth",
    Default = false,
})

Toggles.ChickenAutoRebirth:OnChanged(function()
    AutoRebirthGeneration += 1
    local generation = AutoRebirthGeneration

    if Toggles.ChickenAutoRebirth.Value ~= true then
        if RebirthStatusLabel then
            RebirthStatusLabel:SetText("Rebirth: OFF")
        end
        return
    end

    if RebirthStatusLabel then
        RebirthStatusLabel:SetText("Rebirth: Waiting")
    end

    task.spawn(function()
        while State.Running
            and Toggles.ChickenAutoRebirth
            and Toggles.ChickenAutoRebirth.Value == true
            and generation == AutoRebirthGeneration
        do
            local before = rebirthCount()
            local ok, result = invokeRemote("Rebirth")

            if not ok then
                if RebirthStatusLabel then
                    RebirthStatusLabel:SetText("Rebirth: " .. tostring(result))
                end
            else
                task.wait(0.12)
                local after = rebirthCount()

                if RebirthStatusLabel then
                    if after > before then
                        RebirthStatusLabel:SetText(("Rebirth: %d -> %d"):format(before, after))
                    else
                        RebirthStatusLabel:SetText(("Rebirth: waiting · current %d"):format(after))
                    end
                end
            end

            task.wait(0.38)
        end
    end)
end)

local CharmBox = ProgressTab:AddRightGroupbox("Purple Dust / Charms")

local CharmTierRank = {
    common = 1,
    uncommon = 2,
    rare = 3,
    epic = 4,
    legendary = 5,
}

local CharmTierValues = {"common", "uncommon", "rare", "epic", "legendary"}

State.__rs_getChickenById = function(id)
    id = tostring(id or "")
    for _, c in ipairs(chickens()) do
        if tostring(c.id or "") == id then
            return c
        end
    end
    return nil
end

State.__rs_charmRosterOptions = function()
    local values = {}
    for _, c in ipairs(chickens()) do
        values[#values + 1] = chickenDisplay(c)
    end
    table.sort(values)
    return values
end

State.__rs_currentCharmTarget = function()
    return Config.Charms.SelectedId and State.__rs_getChickenById(Config.Charms.SelectedId) or nil
end

State.__rs_refreshCharmInventory = function()
    local values = State.__rs_charmRosterOptions()
    Options.ChickenCharmTarget:SetValues(values)

    local currentId = tostring(Config.Charms.SelectedId or "")
    local stillExists = currentId ~= "" and State.__rs_getChickenById(currentId) ~= nil

    if not stillExists then
        local active = activeChicken()
        local fallback = active and chickenDisplay(active) or values[1]
        if fallback then
            Options.ChickenCharmTarget:SetValue(fallback)
            Config.Charms.SelectedId = State.__rs_chickenIdFromDisplay(fallback)
        else
            Config.Charms.SelectedId = nil
        end
    end

    notify("AliceHUB · Charms", "Chicken list refreshed · " .. tostring(#values) .. " in roster")
end

State.__rs_lockGoodCharms = function(target)
    if type(target) ~= "table" or type(target.charms) ~= "table" then
        return 0
    end

    local keepRank = CharmTierRank[string.lower(tostring(Config.Charms.KeepTier or "legendary"))] or 5
    local locked = 0

    for slot, charm in pairs(target.charms) do
        if type(charm) == "table" then
            local tier = string.lower(tostring(charm.tier or "common"))
            local rank = CharmTierRank[tier] or 0

            if rank >= keepRank and charm.locked ~= true then
                local slotArg = tonumber(slot) or slot
                local ok = invokeRemote(
                    "SetCharmLock",
                    tostring(target.id),
                    slotArg,
                    true
                )
                if ok then locked += 1 end
                task.wait(0.08)
            end
        end
    end

    return locked
end

State.__rs_rollCharmOnce = function()
    local target = State.__rs_currentCharmTarget()
    if not target then
        State.LastCharm = "Select chicken first"
        return false, State.LastCharm
    end

    if Config.Charms.AutoLockGood then
        State.__rs_lockGoodCharms(target)
    end

    local ok, result = invokeRemote("RollCharms", tostring(target.id))
    State.LastCharm = ok
        and ("Rolled " .. tostring(target.id))
        or ("Roll failed: " .. tostring(result))
    return ok, result
end

CharmBox:AddDropdown("ChickenCharmTarget", {
    Text = "Chicken",
    Values = State.__rs_charmRosterOptions(),
    Default = nil,
    Multi = false,
    Searchable = true,
})
Options.ChickenCharmTarget:OnChanged(function()
    Config.Charms.SelectedId = State.__rs_chickenIdFromDisplay(Options.ChickenCharmTarget.Value)
end)

CharmBox:AddButton({
    Text = "Refresh Chicken Inventory",
    Func = State.__rs_refreshCharmInventory,
})

CharmBox:AddDropdown("ChickenCharmKeepTier", {
    Text = "Keep / Lock ≥ Rarity",
    Values = CharmTierValues,
    Default = "legendary",
    Multi = false,
})
Options.ChickenCharmKeepTier:OnChanged(function()
    Config.Charms.KeepTier = string.lower(tostring(Options.ChickenCharmKeepTier.Value or "legendary"))
end)

CharmBox:AddToggle("ChickenCharmAutoLock", {
    Text = "Auto Lock Good Charms",
    Default = true,
})
Toggles.ChickenCharmAutoLock:OnChanged(function()
    Config.Charms.AutoLockGood = Toggles.ChickenCharmAutoLock.Value == true
end)

CharmBox:AddButton({
    Text = "Roll Purple Dust Once",
    Func = function()
        local ok, result = State.__rs_rollCharmOnce()
        notify("AliceHUB · Charms", ok and State.LastCharm or tostring(result))
    end,
})

CharmBox:AddToggle("ChickenAutoRollCharms", {
    Text = "Auto Roll Purple Dust",
    Default = false,
})
Toggles.ChickenAutoRollCharms:OnChanged(function()
    Config.Charms.AutoRoll = Toggles.ChickenAutoRollCharms.Value == true
end)

CharmBox:AddSlider("ChickenCharmInterval", {
    Text = "Roll Interval",
    Default = 2.5,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Suffix = " s",
})
Options.ChickenCharmInterval:OnChanged(function()
    Config.Charms.Interval = tonumber(Options.ChickenCharmInterval.Value) or 2.5
end)

CharmBox:AddButton({
    Text = "Claim Purple Dust",
    Func = function()
        local ok, result = invokeRemote("ClaimShopDust")
        notify("AliceHUB · Charms", ok and "Dust claim requested" or tostring(result))
    end,
})

local CharmStatusLabel = CharmBox:AddLabel("Dust: loading...\nCharm: Idle", true)

task.spawn(function()
    while State.Running do
        if Config.Charms.AutoRoll then
            State.__rs_rollCharmOnce()
        end
        task.wait(math.max(1, tonumber(Config.Charms.Interval) or 2.5))
    end
end)

-- ============================================================
-- BATTLE TAB
-- ============================================================

local BattleTab = Window:AddTab("Battle")

local ArenaBox = BattleTab:AddLeftGroupbox("Arena")

ArenaBox:AddButton({
    Text = "Arena Fight",
    Func = function()
        local ok, result = arenaFightStep()
        notify("AliceHUB · Arena", ok and State.LastArena or tostring(result))
    end,
})

ArenaBox:AddButton({
    Text = "Equip Best Arena Team",
    Func = function()
        local ok, result = arenaEquipBestStep()
        notify("AliceHUB · Arena", ok and State.LastArena or tostring(result))
    end,
})

ArenaBox:AddButton({
    Text = "Claim Arena Rewards",
    Func = function()
        local count = arenaClaimStep()
        notify("AliceHUB · Arena", "Claimed: " .. tostring(count))
    end,
})

ArenaBox:AddToggle("ChickenArenaAutoAbility", {Text="Native Auto Ability", Default=false})
Toggles.ChickenArenaAutoAbility:OnChanged(function()
    Config.Arena.AutoAbility = Toggles.ChickenArenaAutoAbility.Value == true
    if not setArenaAbility(Config.Arena.AutoAbility) then
        notify("AliceHUB · Arena", "Auto ability module unavailable")
    end
end)

ArenaBox:AddToggle("ChickenAutoArenaFight", {Text="Auto Arena Fight", Default=false})
Toggles.ChickenAutoArenaFight:OnChanged(function()
    Config.Arena.AutoFight = Toggles.ChickenAutoArenaFight.Value == true
end)

ArenaBox:AddToggle("ChickenAutoArenaEquipBest", {Text="Auto Equip Best Team", Default=false})
Toggles.ChickenAutoArenaEquipBest:OnChanged(function()
    Config.Arena.AutoEquipBest = Toggles.ChickenAutoArenaEquipBest.Value == true
end)

ArenaBox:AddToggle("ChickenAutoArenaClaim", {Text="Auto Claim Arena Rewards", Default=false})
Toggles.ChickenAutoArenaClaim:OnChanged(function()
    Config.Arena.AutoClaim = Toggles.ChickenAutoArenaClaim.Value == true
end)

local ArenaStatus = BattleTab:AddRightGroupbox("Arena Status")
local ArenaStatusLabel = ArenaStatus:AddLabel("Arena: loading...", true)

local TowerBox = BattleTab:AddLeftGroupbox("Tower")

TowerBox:AddButton({
    Text = "Tower Start",
    Func = function()
        local ok, result = invokeRemote("TowerStart")
        State.LastTower = ok and "Start requested" or tostring(result)
        notify("AliceHUB · Tower", State.LastTower)
    end,
})

TowerBox:AddButton({
    Text = "Tower Elevator",
    Func = function()
        local ok, result = invokeRemote("TowerElevator")
        notify("AliceHUB · Tower", ok and "Elevator requested" or tostring(result))
    end,
})

TowerBox:AddButton({
    Text = "Tower Surrender",
    Func = function()
        local ok, result = invokeRemote("TowerSurrender")
        notify("AliceHUB · Tower", ok and "Surrender requested" or tostring(result))
    end,
})

TowerBox:AddToggle("ChickenAutoTowerStart", {Text="Auto Tower Start", Default=false})
Toggles.ChickenAutoTowerStart:OnChanged(function()
    Config.Tower.AutoStart = Toggles.ChickenAutoTowerStart.Value == true
end)

TowerBox:AddToggle("ChickenAutoNoThanksTower", {
    Text = "Auto No Thanks After KO",
    Default = false,
})
Toggles.ChickenAutoNoThanksTower:OnChanged(function()
    Config.Tower.AutoNoThanks = Toggles.ChickenAutoNoThanksTower.Value == true
end)

local TowerStatus = BattleTab:AddRightGroupbox("Tower Status")
local TowerStatusLabel = TowerStatus:AddLabel("Tower: loading...", true)

-- ============================================================
-- REWARDS TAB
-- ============================================================

local RewardsTab = Window:AddTab("Rewards")

local ClaimsBox = RewardsTab:AddLeftGroupbox("Claims")

State.__rs_claimButton = function(text, remote)
    ClaimsBox:AddButton({
        Text = text,
        Func = function()
            local ok, result = invokeRemote(remote)
            notify("AliceHUB · Rewards", ok and (text .. " requested") or tostring(result))
        end,
    })
end

State.__rs_claimButton("Daily Claim", "DailyClaim")
State.__rs_claimButton("Claim Index Milestones", "ClaimIndexMilestones")
State.__rs_claimButton("Claim Rebirth Milestones", "ClaimRebirthMilestones")
State.__rs_claimButton("Claim Shop Dust", "ClaimShopDust")
State.__rs_claimButton("Offline Dice Roll", "OfflineDiceRoll")

ClaimsBox:AddButton({
    Text = "Claim All Safe Rewards",
    Func = function()
        notify("AliceHUB · Rewards", "Claims sent: " .. tostring(claimRewards()))
    end,
})

ClaimsBox:AddToggle("ChickenAutoRewards", {Text="Auto Claim Rewards", Default=false})
Toggles.ChickenAutoRewards:OnChanged(function()
    Config.Rewards.AutoClaim = Toggles.ChickenAutoRewards.Value == true
end)

local CodeBox = RewardsTab:AddRightGroupbox("Code")

CodeBox:AddInput("ChickenRedeemCode", {
    Text = "Redeem Code",
    Default = "",
    Placeholder = "Enter code",
    Numeric = false,
    Finished = true,
})

CodeBox:AddButton({
    Text = "Redeem",
    Func = function()
        local code = tostring(Options.ChickenRedeemCode.Value or "")
        if code == "" then return notify("AliceHUB · Code", "Enter code first") end
        local ok, result = invokeRemote("RedeemCode", code)
        notify("AliceHUB · Code", ok and "Redeem requested" or tostring(result))
    end,
})

local RewardStatus = RewardsTab:AddRightGroupbox("Status")
local RewardStatusLabel = RewardStatus:AddLabel("Reward: Idle", true)

-- ============================================================
-- WEBHOOK TAB
-- ============================================================

local WebhookTab = Window:AddTab("Webhook")

local WebhookBox = WebhookTab:AddLeftGroupbox("Discord Monitoring")
local WebhookStatusBox = WebhookTab:AddRightGroupbox("Status")
local WebhookStatusLabel = WebhookStatusBox:AddLabel("Webhook: OFF\nIdle", true)

State.__rs_executorRequest = function()
    return (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
end

State.__rs_validWebhook = function(url)
    url = tostring(url or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return url:match("^https://[%w%.%-]+/api/v?%d*/?webhooks/%d+/%S+")
        or url:match("^https://discord%.com/api/webhooks/%d+/%S+")
end

State.__rs_webhookSnapshot = function()
    local r = roster()
    local active = activeChicken()
    local arena = getter("arena") or {}

    return {
        username = LocalPlayer.Name,
        money = moneyText(),
        rebirth = rebirthCount(),
        roster = type(r.chickens) == "table" and #r.chickens or 0,
        active = active and chickenDisplay(active) or "None",
        recycler = currentRecyclerLevel(),
        tower = towerPeak(),
        arenaWins = type(arena) == "table" and tostring(arena.wins or arena.seasonWins or 0) or "0",
    }
end

State.__rs_sendWebhook = function(test)
    local url = tostring(Config.Webhook.URL or "")
    if not State.__rs_validWebhook(url) then
        Config.Webhook.Last = "Invalid URL"
        return false, "Invalid URL"
    end

    local req = State.__rs_executorRequest()
    if type(req) ~= "function" then
        Config.Webhook.Last = "request() unavailable"
        return false, Config.Webhook.Last
    end

    local s = State.__rs_webhookSnapshot()
    local body = HttpService:JSONEncode({
        username = "AliceHUB · GACF",
        embeds = {{
            title = test and "Grow A Chicken Fighter · Test" or "Grow A Chicken Fighter · Monitor",
            fields = {
                {name="Account", value=("User: %s\nMoney: %s\nRebirth: %s"):format(s.username, s.money, s.rebirth), inline=false},
                {name="Chicken", value=("Roster: %s\nActive: %s"):format(s.roster, s.active), inline=false},
                {name="Progress", value=("Recycler: %s\nTower: %s\nArena Wins: %s"):format(s.recycler, s.tower, s.arenaWins), inline=false},
                {name="Automation", value=("Hatch:%s | Collect:%s | Sell:%s | Fuse:%s | Promote:%s"):format(
                    tostring(Config.Hatch.Enabled),
                    tostring(Config.Collect.Drops or Config.Collect.Eggs),
                    tostring(Config.Sell.Enabled),
                    tostring(Config.Fuse.Enabled),
                    tostring(Config.Promote.Enabled)
                ), inline=false},
            },
            footer = {text="AliceHUB · Grow A Chicken Fighter"},
            timestamp = DateTime.now():ToIsoDate(),
        }}
    })

    local ok, response = pcall(req, {
        Url = url,
        Method = "POST",
        Headers = {["Content-Type"]="application/json"},
        Body = body,
    })

    local code = ok and type(response) == "table"
        and tonumber(response.StatusCode or response.Status or response.status_code)
        or nil

    local success = ok and (code == nil or (code >= 200 and code < 300))
    Config.Webhook.Last = success and ("Sent" .. (code and (" · HTTP " .. code) or "")) or ("Failed · " .. tostring(code or response))
    return success, Config.Webhook.Last
end

State.__rs_startWebhookWorker = function()
    Config.Webhook.Generation += 1
    local generation = Config.Webhook.Generation

    task.spawn(function()
        while State.Running
            and Config.Webhook.Enabled
            and Config.Webhook.Generation == generation
        do
            State.__rs_sendWebhook(false)
            local remaining = math.max(30, tonumber(Config.Webhook.Interval) or 300)
            while remaining > 0
                and State.Running
                and Config.Webhook.Enabled
                and Config.Webhook.Generation == generation
            do
                task.wait(1)
                remaining -= 1
            end
        end
    end)
end

WebhookBox:AddInput("ChickenWebhookURL", {
    Text = "Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = true,
})
Options.ChickenWebhookURL:OnChanged(function()
    Config.Webhook.URL = tostring(Options.ChickenWebhookURL.Value or "")
end)

WebhookBox:AddSlider("ChickenWebhookInterval", {
    Text = "Interval",
    Default = 300,
    Min = 30,
    Max = 1800,
    Rounding = 0,
    Suffix = " s",
})
Options.ChickenWebhookInterval:OnChanged(function()
    Config.Webhook.Interval = tonumber(Options.ChickenWebhookInterval.Value) or 300
end)

WebhookBox:AddToggle("ChickenWebhookEnabled", {
    Text = "Enable Monitoring",
    Default = false,
})
Toggles.ChickenWebhookEnabled:OnChanged(function()
    Config.Webhook.Enabled = Toggles.ChickenWebhookEnabled.Value == true
    Config.Webhook.Generation += 1
    if Config.Webhook.Enabled then
        State.__rs_startWebhookWorker()
    end
end)

WebhookBox:AddButton({
    Text = "Test Webhook",
    Func = function()
        local ok, result = State.__rs_sendWebhook(true)
        notify("AliceHUB · Webhook", tostring(result), 6)
    end,
})

-- ============================================================
-- SETTINGS TAB
-- ============================================================

local SettingsTab = Window:AddTab("Settings")
local DisplayBox = SettingsTab:AddLeftGroupbox("Display")
local PerformanceBox = SettingsTab:AddLeftGroupbox("Performance")
local SessionBox = SettingsTab:AddRightGroupbox("Session")
local CommunityBox = SettingsTab:AddRightGroupbox("Community")

local WhiteScreen = {
    Enabled = false,
    Gui = nil,
    Generation = 0,
}

State.__rs_destroyWhite = function()
    WhiteScreen.Enabled = false
    WhiteScreen.Generation += 1
    if WhiteScreen.Gui then
        pcall(function() WhiteScreen.Gui:Destroy() end)
        WhiteScreen.Gui = nil
    end
end

State.__rs_startWhite = function()
    State.__rs_destroyWhite()
    WhiteScreen.Enabled = true
    WhiteScreen.Generation += 1
    local generation = WhiteScreen.Generation

    local gui = Instance.new("ScreenGui")
    gui.Name = "AliceHUB_GACF_WhiteScreen"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647
    gui.Parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
    WhiteScreen.Gui = gui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1,1)
    bg.BackgroundColor3 = Color3.new(0,0,0)
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5,0.5)
    label.Position = UDim2.fromScale(0.5,0.5)
    label.Size = UDim2.new(0.9,0,0.7,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(240,240,240)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextWrapped = true
    label.Parent = bg

    local close = Instance.new("TextButton")
    close.AnchorPoint = Vector2.new(1,0)
    close.Position = UDim2.new(1,-15,0,15)
    close.Size = UDim2.fromOffset(44,44)
    close.BackgroundColor3 = Color3.fromRGB(132,30,49)
    close.Text = "X"
    close.TextColor3 = Color3.new(1,1,1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 22
    close.Parent = bg
    Instance.new("UICorner", close).CornerRadius = UDim.new(0,8)

    close.Activated:Connect(function()
        if Toggles.ChickenWhiteScreen then
            Toggles.ChickenWhiteScreen:SetValue(false)
        else
            State.__rs_destroyWhite()
        end
    end)

    task.spawn(function()
        while WhiteScreen.Enabled and WhiteScreen.Generation == generation and gui.Parent do
            local active = activeChicken()
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            local uptime = math.floor(os.clock() - State.SessionStart)

            local currentMoney = moneyNumber() or 0
            local currentRebirth = rebirthCount()
            local currentRecycler = currentRecyclerLevel()
            local currentTower = towerPeak()
            local activeLevel = active and (tonumber(active.level) or 0) or 0

            label.Text = table.concat({
                "ALICEHUB",
                "Grow A Chicken Fighter",
                "",
                "Username: " .. LocalPlayer.Name,
                "Money: " .. compactNumber(currentMoney)
                    .. " (" .. signedCompact(currentMoney - SessionBase.Money) .. ")",
                "Rebirth: " .. tostring(currentRebirth)
                    .. " (" .. string.format("%+d", currentRebirth - SessionBase.Rebirth) .. ")",
                "Recycler: " .. tostring(currentRecycler)
                    .. " (" .. string.format("%+d", currentRecycler - SessionBase.Recycler) .. ")",
                "Tower: " .. tostring(currentTower)
                    .. " (" .. string.format("%+d", currentTower - SessionBase.Tower) .. ")",
                "Active: " .. (active and chickenDisplay(active) or "None"),
                "Active Lv Δ: " .. string.format("%+d", activeLevel - SessionBase.ActiveLevel),
                "",
                "Collect: " .. tostring(State.LastCollect),
                "Sell: " .. tostring(State.LastSell),
                "Feeder: " .. tostring(State.LastFeeder),
                "Chaos: " .. tostring(State.LastChaos),
                "Encourage: " .. tostring(State.LastEncourage),
                "Charm: " .. tostring(State.LastCharm),
                string.format("Ping: %dms | Uptime: %02d:%02d:%02d", ping, math.floor(uptime/3600), math.floor((uptime%3600)/60), uptime%60),
            }, "\n")

            task.wait(0.6)
        end
    end)
end

DisplayBox:AddToggle("ChickenWhiteScreen", {Text="White Screen", Default=false})
Toggles.ChickenWhiteScreen:OnChanged(function()
    if Toggles.ChickenWhiteScreen.Value then State.__rs_startWhite() else State.__rs_destroyWhite() end
end)

local PerfSaved = {}
local UltraConnection

State.__rs_setBoost = function(enabled)
    if enabled then
        pcall(function()
            if PerfSaved.Quality == nil then PerfSaved.Quality = settings().Rendering.QualityLevel end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function()
            if PerfSaved.Shadows == nil then PerfSaved.Shadows = Lighting.GlobalShadows end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1000000
        end)
    else
        pcall(function()
            if PerfSaved.Quality ~= nil then settings().Rendering.QualityLevel = PerfSaved.Quality end
            if PerfSaved.Shadows ~= nil then Lighting.GlobalShadows = PerfSaved.Shadows end
        end)
    end
end

State.__rs_optimizeInstance = function(instance)
    if not instance or not instance.Parent then return end
    local node = instance
    while node do
        if string.find(tostring(node.Name), "AliceHUB", 1, true) then return end
        node = node.Parent
    end

    if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
        or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles")
    then
        pcall(function() instance.Enabled = false end)
    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        pcall(function() instance.Transparency = 1 end)
    elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
        pcall(function() instance.Enabled = false end)
    elseif instance:IsA("PostEffect") then
        pcall(function() instance.Enabled = false end)
    elseif instance:IsA("BasePart") then
        pcall(function()
            instance.CastShadow = false
            instance.Material = Enum.Material.Plastic
            instance.Reflectance = 0
        end)
    end
end

State.__rs_setUltra = function(enabled)
    if UltraConnection then
        pcall(function() UltraConnection:Disconnect() end)
        UltraConnection = nil
    end

    if not enabled then return end
    State.__rs_setBoost(true)

    task.spawn(function()
        for i, obj in ipairs(Workspace:GetDescendants()) do
            if not State.Running or not Toggles.ChickenUltraPerformance.Value then break end
            State.__rs_optimizeInstance(obj)
            if i % 300 == 0 then task.wait() end
        end
    end)

    UltraConnection = Workspace.DescendantAdded:Connect(function(obj)
        if Toggles.ChickenUltraPerformance and Toggles.ChickenUltraPerformance.Value then
            task.defer(State.__rs_optimizeInstance, obj)
        end
    end)
end

PerformanceBox:AddToggle("ChickenBoostFPS", {Text="Boost FPS + Low Graphics", Default=false})
Toggles.ChickenBoostFPS:OnChanged(function()
    State.__rs_setBoost(Toggles.ChickenBoostFPS.Value == true)
end)

PerformanceBox:AddToggle("ChickenUltraPerformance", {Text="Ultra Performance", Default=false})
Toggles.ChickenUltraPerformance:OnChanged(function()
    State.__rs_setUltra(Toggles.ChickenUltraPerformance.Value == true)
end)

PerformanceBox:AddToggle("ChickenAutoRejoin", {Text="Auto Rejoin", Default=false})
Toggles.ChickenAutoRejoin:OnChanged(function()
    Config.Settings.AutoRejoin = Toggles.ChickenAutoRejoin.Value == true
end)

PerformanceBox:AddSlider("ChickenRejoinMinutes", {
    Text = "Rejoin Interval",
    Default = 17,
    Min = 10,
    Max = 18,
    Rounding = 0,
    Suffix = " min",
})
Options.ChickenRejoinMinutes:OnChanged(function()
    Config.Settings.RejoinMinutes = tonumber(Options.ChickenRejoinMinutes.Value) or 17
end)

local SessionStatus = SessionBox:AddLabel("Session: Active", true)

CommunityBox:AddButton({
    Text = "Copy Discord",
    Func = function()
        local copy = setclipboard or toclipboard
        if type(copy) == "function" then
            copy("https://discord.gg/teUcVxmTd")
            notify("AliceHUB", "Discord copied")
        else
            notify("AliceHUB", "Clipboard unavailable")
        end
    end,
})

CommunityBox:AddButton({
    Text = "Unload AliceHUB UI",
    Func = function()
        State.Running = false
        State.__rs_destroyWhite()
        pcall(function() Library:Unload() end)
    end,
})

-- ============================================================
-- AliceHUB native config · automatic save + automatic load
-- No manual config setup required.
-- ============================================================

local AutoConfigStatus = SessionBox:AddLabel("Config: Loading...", true)
local AUTO_CONFIG_FOLDER = "AliceHub/GrowAChickenFighterOriginal"
local AUTO_CONFIG_FILE = AUTO_CONFIG_FOLDER .. "/AliceHUB_Auto.json"
local autoConfigGeneration = 0
local autoConfigReady = false

State.__rs_ensureAutoConfigFolder = function()
    if type(makefolder) ~= "function" then
        return false
    end

    pcall(function()
        if type(isfolder) ~= "function" or not isfolder("AliceHub") then
            makefolder("AliceHub")
        end
    end)
    pcall(function()
        if type(isfolder) ~= "function" or not isfolder(AUTO_CONFIG_FOLDER) then
            makefolder(AUTO_CONFIG_FOLDER)
        end
    end)
    return true
end

State.__rs_jsonSafe = function(value, depth)
    depth = depth or 0
    if depth > 8 then return nil end

    local kind = typeof(value)
    if kind == "boolean" or kind == "string" or kind == "number" then
        return value
    end
    if kind ~= "table" then
        return nil
    end

    local out = {}
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            local safe = State.__rs_jsonSafe(item, depth + 1)
            if safe ~= nil then
                out[key] = safe
            end
        end
    end
    return out
end

State.__rs_snapshotAutoConfig = function()
    local data = {
        Version = 1,
        Game = "Grow A Chicken Fighter",
        Toggles = {},
        Options = {},
    }

    for id, element in pairs(Toggles or {}) do
        if type(element) == "table" then
            local safe = State.__rs_jsonSafe(element.Value)
            if safe ~= nil then
                data.Toggles[tostring(id)] = safe
            end
        end
    end

    for id, element in pairs(Options or {}) do
        if type(element) == "table" then
            local safe = State.__rs_jsonSafe(element.Value)
            if safe ~= nil then
                data.Options[tostring(id)] = safe
            end
        end
    end

    return data
end

State.__rs_saveAutoConfigNow = function()
    if type(writefile) ~= "function" then
        if AutoConfigStatus and type(AutoConfigStatus.SetText) == "function" then
            AutoConfigStatus:SetText("Config: writefile unavailable")
        end
        return false
    end

    State.__rs_ensureAutoConfigFolder()
    local okEncode, encoded = pcall(HttpService.JSONEncode, HttpService, State.__rs_snapshotAutoConfig())
    if not okEncode or type(encoded) ~= "string" then
        return false
    end

    local okWrite = pcall(writefile, AUTO_CONFIG_FILE, encoded)
    if okWrite and AutoConfigStatus and type(AutoConfigStatus.SetText) == "function" then
        AutoConfigStatus:SetText("Config: Auto-saved")
    end
    return okWrite
end

State.__rs_scheduleAutoConfigSave = function()
    if not autoConfigReady or ConfigRestore.Loading or Library.Unloaded then
        return
    end

    autoConfigGeneration += 1
    local ticket = autoConfigGeneration
    task.delay(0.60, function()
        if not autoConfigReady
            or ConfigRestore.Loading
            or Library.Unloaded
            or ticket ~= autoConfigGeneration
        then
            return
        end
        State.__rs_saveAutoConfigNow()
    end)
end

State.__rs_loadAutoConfig = function()
    if type(readfile) ~= "function" then
        return false, "readfile unavailable"
    end

    local exists = false
    if type(isfile) == "function" then
        local okExists, result = pcall(isfile, AUTO_CONFIG_FILE)
        exists = okExists and result == true
    else
        local okRead = pcall(readfile, AUTO_CONFIG_FILE)
        exists = okRead
    end

    if not exists then
        return false, "first run"
    end

    local okRead, raw = pcall(readfile, AUTO_CONFIG_FILE)
    if not okRead or type(raw) ~= "string" or raw == "" then
        return false, "read failed"
    end

    local okDecode, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okDecode or type(data) ~= "table" then
        return false, "invalid config"
    end

    ConfigRestore.Loading = true

    -- Load value controls first. Their callbacks are queued while Loading=true.
    for id, value in pairs(type(data.Options) == "table" and data.Options or {}) do
        local element = Options[id]
        if type(element) == "table" and type(element.SetValue) == "function" then
            pcall(function() element:SetValue(value) end)
        end
    end

    -- Toggles are restored second so filters/speeds/targets are ready first.
    for id, value in pairs(type(data.Toggles) == "table" and data.Toggles or {}) do
        local element = Toggles[id]
        if type(element) == "table" and type(element.SetValue) == "function" then
            pcall(function() element:SetValue(value == true) end)
        end
    end

    ConfigRestore.Loading = false
    flushRestoredCallbacks()
    return true, "loaded"
end

State.__rs_installNativeAutoSave = function()
    local function hookRegistry(registry)
        for _, element in pairs(registry or {}) do
            if type(element) == "table"
                and type(element.OnChanged) == "function"
                and element.__AliceHUBNativeAutoSave ~= true
            then
                element.__AliceHUBNativeAutoSave = true
                element:OnChanged(function()
                    State.__rs_scheduleAutoConfigSave()
                end)
            end
        end
    end

    hookRegistry(Toggles)
    hookRegistry(Options)
end

State.__rs_ensureAutoConfigFolder()
local loadedConfig, loadReason = State.__rs_loadAutoConfig()
autoConfigReady = true
State.__rs_installNativeAutoSave()

if loadedConfig then
    if AutoConfigStatus and type(AutoConfigStatus.SetText) == "function" then
        AutoConfigStatus:SetText("Config: Auto-loaded")
    end
else
    -- First run: persist the current defaults immediately and use this file forever after.
    saveAutoConfigNow()
    if AutoConfigStatus and type(AutoConfigStatus.SetText) == "function" then
        AutoConfigStatus:SetText("Config: Ready (AliceHUB_Auto)")
    end
end

-- ============================================================
-- Status workers
-- ============================================================

task.spawn(function()
    local started = os.clock()
    while State.Running do
        local r = roster()
        local eggCounts = type(r.eggs) == "table" and r.eggs or {}
        local eggOwned = 0
        for _, amount in pairs(eggCounts) do
            eggOwned += tonumber(amount) or 0
        end

        if MainStatusLabel and type(MainStatusLabel.SetText) == "function" then
            MainStatusLabel:SetText(
                "Money: " .. moneyText()
                .. "\nRebirth: " .. tostring(rebirthCount())
                .. "\nRoster: " .. tostring(type(r.chickens) == "table" and #r.chickens or 0)
                .. "\nEggs: " .. tostring(eggOwned)
                .. "\nAuto Egg: " .. tostring(resolveEgg())
                .. "\nCollect: " .. tostring(State.LastCollect)
                .. "\nSell: " .. tostring(State.LastSell)
            )
        end

        if RecyclerStatus and type(RecyclerStatus.SetText) == "function" then
            local level = currentRecyclerLevel()
            local can, why = recyclerCanTry()
            RecyclerStatus:SetText(
                "Recycler Lv: " .. tostring(level)
                .. "\nMax: 36"
                .. "\nTower Peak: " .. tostring(towerPeak())
                .. "\nUpgrade: " .. (can and "Ready" or tostring(why))
            )
        end

        if FeederStatusLabel and type(FeederStatusLabel.SetText) == "function" then
            FeederStatusLabel:SetText(
                "Feeder: " .. tostring(State.LastFeeder)
                .. "\nBuy ID: " .. tostring(FeederBuyId)
                .. " | Upgrade ID: " .. tostring(FeederUpgradeId)
            )
        end

        if ChaosStatusLabel and type(ChaosStatusLabel.SetText) == "function" then
            ChaosStatusLabel:SetText(
                "Chaos: " .. tostring(State.LastChaos)
                .. "\nChaos Delay: " .. tostring(Config.Chaos.Delay) .. "s"
                .. "\nEncourage: " .. tostring(State.LastEncourage)
                .. "\nEncourage CPS: " .. tostring(Config.Chaos.EncourageCPS)
            )
        end

        if CharmStatusLabel and type(CharmStatusLabel.SetText) == "function" then
            local charmData = getter("charms")
            local dust = type(charmData) == "table" and tonumber(charmData.dust) or nil
            local target = State.__rs_currentCharmTarget()

            CharmStatusLabel:SetText(
                "Purple Dust: " .. compactNumber(dust or 0)
                .. "\nChicken: " .. (target and chickenDisplay(target) or "None")
                .. "\nKeep ≥ " .. tostring(Config.Charms.KeepTier)
                .. "\nLast: " .. tostring(State.LastCharm)
            )
        end

        local arena = getter("arena") or {}
        if ArenaStatusLabel and type(ArenaStatusLabel.SetText) == "function" then
            ArenaStatusLabel:SetText(
                "Wins: " .. tostring(type(arena)=="table" and (arena.wins or 0) or 0)
                .. "\nBattles: " .. tostring(type(arena)=="table" and (arena.battles or 0) or 0)
                .. "\nTrophies: " .. tostring(type(arena)=="table" and (arena.trophies or 0) or 0)
                .. "\nLast: " .. tostring(State.LastArena)
            )
        end

        if TowerStatusLabel and type(TowerStatusLabel.SetText) == "function" then
            TowerStatusLabel:SetText(
                "Best: " .. tostring(getter("towerBest") or 0)
                .. "\nPeak: " .. tostring(getter("towerPeak") or 0)
                .. "\nLast: " .. tostring(State.LastTower)
            )
        end

        if RewardStatusLabel and type(RewardStatusLabel.SetText) == "function" then
            RewardStatusLabel:SetText(
                "Last: " .. tostring(State.LastReward)
                .. "\nDaily: " .. tostring(getter("daily") or "N/A")
            )
        end

        if WebhookStatusLabel and type(WebhookStatusLabel.SetText) == "function" then
            WebhookStatusLabel:SetText(
                "Webhook: " .. (Config.Webhook.Enabled and "ON" or "OFF")
                .. "\n" .. tostring(Config.Webhook.Last)
            )
        end

        local elapsed = math.floor(os.clock() - started)
        if SessionStatus and type(SessionStatus.SetText) == "function" then
            SessionStatus:SetText(
                string.format(
                    "Session: %02d:%02d:%02d\nPlaceId: %s\nNo Anti-AFK",
                    math.floor(elapsed/3600),
                    math.floor((elapsed%3600)/60),
                    elapsed%60,
                    tostring(game.PlaceId)
                )
            )
        end

        task.wait(1)
    end
end)

task.spawn(function()
    local startedAt = os.clock()
    while State.Running do
        if Config.Settings.AutoRejoin then
            local target = math.clamp(tonumber(Config.Settings.RejoinMinutes) or 17, 10, 18) * 60
            if os.clock() - startedAt >= target then
                notify("AliceHUB", "Auto Rejoin...")
                task.wait(0.5)
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                return
            end
        else
            startedAt = os.clock()
        end
        task.wait(1)
    end
end)

ENV.AliceHUB_ChickenIndependent = {
    Config = Config,
    State = State,
    SmartSellPreview = smartSellPreview,
    SmartSellOnce = smartSellOnce,
    HatchOnce = hatchOnce,
    FuseOnce = fuseOnce,
    PromoteOnce = promoteOnce,
    ClaimRewards = claimRewards,
    Stop = function()
        State.Running = false
        Config.Webhook.Enabled = false
        State.__rs_destroyWhite()
        if UltraConnection then
            pcall(function() UltraConnection:Disconnect() end)
        end
    end,
}

ENV.AliceHUB_ChickenIndependentCleanup = function()
    if ENV.AliceHUB_ChickenIndependent then
        pcall(ENV.AliceHUB_ChickenIndependent.Stop)
    end
end

notify(
    "AliceHUB · Grow A Chicken Fighter",
    6
)
