-- AliceHUB Arceus Lite Exact Payload Compile Probe V5
-- COMPILE ONLY: payload is NEVER executed.
local CoreGui = game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AliceHUB_ExactCompileProbeV5"
gui.ResetOnSpawn = false

local parent = CoreGui
if type(gethui) == "function" then
    local ok, hui = pcall(gethui)
    if ok and hui then parent = hui end
end
gui.Parent = parent

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(620, 310)
label.Position = UDim2.new(0.5, -310, 0.5, -155)
label.BackgroundColor3 = Color3.fromRGB(18,18,18)
label.BorderSizePixel = 0
label.TextColor3 = Color3.new(1,1,1)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Font = Enum.Font.Code
label.TextSize = 15
label.Parent = gui

local lines = {}
local function stage(s)
    lines[#lines+1] = s
    label.Text = "AliceHUB · Exact Payload Compile V5\n\n" .. table.concat(lines, "\n")
    print("[AliceHUB ExactCompile]", s)
    task.wait(0.8)
end

stage("UI READY")

stage("Target = stealanegg.lua")
local PAYLOAD = [=[--[[
    AliceHUB · Steal An Egg
    AliceHUB SAE · Anime Dice V7 exact native UI · 2026-09-07 client-dump additions

    AliceHUB scripts:
      - Steal An Egg
      - Grow A Chicken Fighter
      - Jump For Animals

    Runtime session validation is preserved.
]]

-- ============================================================
-- AliceHUB Direct Loader v3 runtime
-- Auth/session is already validated by the AliceHUB API before this payload runs.
-- Do not restore the old MuiHub context or reuse its endpoints.
-- ============================================================
do
    local __g = getgenv()
    __g.__MH_ctx = nil
    __g.__AliceHUB_ctx = nil
    __g.AliceHUB_BaseURL = nil
    __g.AliceHUB_TradeBaseURL = nil
    __g.AliceHUB_CdnURL = nil
    __g.script_key = nil
end

-- Cleanly stop an older AliceHUB SAE instance before re-executing.
do
    local oldCleanup = getgenv() [("AliceHUB_SAE_Cleanup")]
    if type (oldCleanup) == ("function") then
        pcall(oldCleanup)
    else
        local hadWhiteScreen = _G [("SAE_WhiteScreen")] == true
        for _, flag in ipairs({
            ("SAE_FarmEgg"), ("SAE_AAFarmEgg"), ("SAE_StealParasite"), ("SAE_TakeRiftEgg"), ("SAE_CompleteIndex"),
            ("SAE_AutoTreadmill"), ("SAE_AutoUpgradeTreadmill"), ("SAE_AutoSell"), ("SAE_SellByValue"),
            ("SAE_AutoFav"), ("SAE_AutoUnfav"), ("SAE_FuseAll"), ("SAE_FuseByRarity"),
            ("SAE_AutoUpgradePen"), ("SAE_AutoUpgradeTrail"), ("SAE_AutoIndexClaim"),
            ("SAE_AutoPlaceHatch"), ("SAE_AlwaysBest"), ("SAE_EspEgg"),
            ("SAE_RiftAutoFuse"), ("SAE_RiftAutoReroll"), ("SAE_BossAutoClaim"), ("SAE_BossAutoShop"),
            ("SAE_Noclip"), ("SAE_AntiHit"), ("SAE_BoostFPS"), ("SAE_DestroyUI"), ("SAE_UltraPerf"),
            ("SAE_HideOtherPet"), ("SAE_WhiteScreen"), ("SAE_Webhook"), ("SAE_DashboardEnabled")
        }) do
            _G [flag] = false
        end
        if hadWhiteScreen then
            pcall(function () settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
            pcall(function () UserSettings():GetService(("UserGameSettings")).SavedQualityLevel = Enum.SavedQualitySetting.Automatic end)
        end
        pcall(function ()
            local player = game:GetService(("Players")).LocalPlayer
            for _, root in ipairs({game:GetService(("CoreGui")), player and player:FindFirstChildOfClass(("PlayerGui"))}) do
                local gui = root and root:FindFirstChild(("AliceHUB_SAE_WhiteScreen"))
                if gui then gui:Destroy() end
                for _, guiName in ipairs({("AliceHUBLogoButton"), ("AliceHUBToggleButton")}) do
                    local oldLogo = root and root:FindFirstChild(guiName)
                    if oldLogo then oldLogo:Destroy() end
                end
            end
        end)
        task.wait(0.12)
    end
end

-- ============================================================
-- AliceHUB UI · Anime Dice V7 exact native renderer
-- Same visual renderer/layout as the user-provided Anime Dice reference.
-- SAE feature/runtime logic remains from the latest SAE build.
-- ============================================================
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

local Library = buildAliceNativeLibrary("Steal An Egg", "AliceHUB_SAE_NativeUI", ALICE_LOGO_ASSET)

local AliceUI = (function()
    local API = {
        Flags = {},
        _library = Library,
        _loadingConfig = nil,
    }

    local function safeId(value)
        local id = tostring(value or "AliceHUB_Option")
        id = id:gsub("[^%w_]", "_")
        if id == "" then id = "AliceHUB_Option" end
        return id
    end

    -- The original UI used arrays for MultiDropdown values, while Obsidian uses a
    -- map/set. Normalize both directions so the original feature logic gets
    -- exactly the value shape it expects.
    local function multiToArray(value, order)
        local out, seen = {}, {}
        if type(value) ~= "table" then return out end

        for _, v in ipairs(value) do
            if type(v) == "string" and not seen[v] then
                seen[v] = true
                out[#out + 1] = v
            end
        end

        if type(order) == "table" then
            for _, name in ipairs(order) do
                if value[name] == true and not seen[name] then
                    seen[name] = true
                    out[#out + 1] = name
                end
            end
        end

        for k, v in pairs(value) do
            if type(k) == "string" and v == true and not seen[k] then
                seen[k] = true
                out[#out + 1] = k
            end
        end
        return out
    end

    local function multiToMap(value, order)
        local out = {}
        if type(value) ~= "table" then return out end

        for _, v in ipairs(value) do
            if type(v) == "string" then out[v] = true end
        end
        for k, v in pairs(value) do
            if type(k) == "string" and v == true then out[k] = true end
        end

        -- Keep only valid dropdown options when an option list exists.
        if type(order) == "table" and #order > 0 then
            local valid, clean = {}, {}
            for _, name in ipairs(order) do valid[name] = true end
            for name in pairs(out) do
                if valid[name] then clean[name] = true end
            end
            return clean
        end
        return out
    end

    local function makeFlagProxy(option, kind, values)
        local proxy = {
            _option = option,
            _kind = kind,
            _values = values,
            _callbacks = {},
            _mute = false,
        }

        local function readValue()
            local value = option and option.Value
            if kind == "multi" then
                return multiToArray(value, values)
            end
            return value
        end

        local function writeValue(value)
            local actual = kind == "multi" and multiToMap(value, values) or value
            if option and type(option.SetValue) == "function" then
                option:SetValue(actual)
            elseif option then
                option.Value = actual
            end
        end

        function proxy:_fire(value)
            local snapshot = {}
            for i, fn in ipairs(self._callbacks) do snapshot[i] = fn end
            for _, fn in ipairs(snapshot) do
                pcall(fn, value)
            end
        end

        function proxy:Set(value)
            self._mute = true
            local ok, err = pcall(writeValue, value)
            self._mute = false
            if not ok then
                warn("[AliceHUB/UI] Set flag gagal: " .. tostring(err))
            end
            return ok
        end

        function proxy:SetAndFire(value)
            self:Set(value)
            self:_fire(readValue())
        end

        function proxy:OnChanged(fn)
            if type(fn) ~= "function" then
                return {Disconnect = function() end}
            end
            self._callbacks[#self._callbacks + 1] = fn
            local active = true
            local index = #self._callbacks
            return {
                Disconnect = function()
                    if active then
                        active = false
                        self._callbacks[index] = function() end
                    end
                end
            }
        end

        if option and type(option.OnChanged) == "function" then
            option:OnChanged(function()
                if proxy._mute then return end
                proxy:_fire(readValue())
            end)
        end

        return setmetatable(proxy, {
            __index = function(t, k)
                if k == "Value" then return readValue() end
                local own = rawget(t, k)
                if own ~= nil then return own end
                return option and option[k] or nil
            end,
            __newindex = function(t, k, v)
                if k == "Value" then
                    t:Set(v)
                else
                    rawset(t, k, v)
                end
            end,
        })
    end

    local function registerFlag(id, option, kind, values, callback)
        local proxy = makeFlagProxy(option, kind, values)
        API.Flags[id] = proxy
        if type(callback) == "function" then
            proxy:OnChanged(callback)
        end
        return proxy
    end

    local function makeSection(group)
        local section = {_group = group}

        function section:AddButton(cfg)
            cfg = cfg or {}
            return group:AddButton({
                Text = cfg.Title or cfg.Name or cfg.Text or "Button",
                Func = cfg.Callback or cfg.Func or function() end,
                Tooltip = cfg.Desc or cfg.Description or cfg.Tooltip,
            })
        end

        function section:AddToggle(cfg)
            cfg = cfg or {}
            local id = safeId(cfg.ID or cfg.Flag or cfg.Title or cfg.Text)
            group:AddToggle(id, {
                Text = cfg.Title or cfg.Text or id,
                Default = cfg.Default ~= nil and cfg.Default or cfg.Value == true,
                Tooltip = cfg.Desc or cfg.Description or cfg.Tooltip,
            })
            return registerFlag(id, Library.Toggles and Library.Toggles[id], "toggle", nil, cfg.Callback)
        end

        function section:AddSlider(cfg)
            cfg = cfg or {}
            local id = safeId(cfg.ID or cfg.Flag or cfg.Title or cfg.Text)
            local step = tonumber(cfg.Step) or 1
            local rounding = 0
            if step > 0 and step < 1 then
                rounding = math.max(0, math.ceil(-math.log10(step)))
            end
            group:AddSlider(id, {
                Text = cfg.Title or cfg.Text or id,
                Default = cfg.Default ~= nil and cfg.Default or cfg.Value or 0,
                Min = cfg.Min or 0,
                Max = cfg.Max or 100,
                Rounding = rounding,
                Suffix = cfg.Suffix or "",
                Tooltip = cfg.Desc or cfg.Tooltip,
            })
            return registerFlag(id, Library.Options and Library.Options[id], "slider", nil, cfg.Callback)
        end

        function section:AddTextInput(cfg)
            cfg = cfg or {}
            local id = safeId(cfg.ID or cfg.Flag or cfg.Title or cfg.Text)
            group:AddInput(id, {
                Text = cfg.Title or cfg.Text or id,
                Default = tostring(cfg.Default ~= nil and cfg.Default or cfg.Value or ""),
                Placeholder = cfg.Placeholder or "",
                Finished = true,
                AllowEmpty = true,
                Tooltip = cfg.Desc or cfg.Tooltip,
            })
            return registerFlag(id, Library.Options and Library.Options[id], "input", nil, cfg.Callback)
        end

        function section:AddTextarea(cfg)
            return self:AddTextInput(cfg)
        end

        function section:AddDropdown(cfg)
            cfg = cfg or {}
            local id = safeId(cfg.ID or cfg.Flag or cfg.Title or cfg.Text)
            local values = cfg.Options or cfg.Values or {}
            group:AddDropdown(id, {
                Values = values,
                Multi = false,
                Searchable = true,
                AllowNull = true,
                Text = cfg.Title or cfg.Text or id,
                Default = cfg.Default ~= nil and cfg.Default or cfg.Value,
                Tooltip = cfg.Desc or cfg.Tooltip,
            })
            return registerFlag(id, Library.Options and Library.Options[id], "dropdown", values, cfg.Callback)
        end

        function section:AddMultiDropdown(cfg)
            cfg = cfg or {}
            local id = safeId(cfg.ID or cfg.Flag or cfg.Title or cfg.Text)
            local values = cfg.Options or cfg.Values or {}
            group:AddDropdown(id, {
                Values = values,
                Multi = true,
                Searchable = true,
                AllowNull = true,
                Text = cfg.Title or cfg.Text or id,
                Default = multiToMap(cfg.Default or cfg.Value or {}, values),
                Tooltip = cfg.Desc or cfg.Tooltip,
            })
            return registerFlag(id, Library.Options and Library.Options[id], "multi", values, cfg.Callback)
        end

        function section:AddParagraph(cfg)
            cfg = cfg or {}
            local title = tostring(cfg.Title or "")
            local body = tostring(cfg.Body or cfg.Content or "")
            local text = title
            if body ~= "" then
                text = (text ~= "" and (text .. "\n") or "") .. body
            end
            return group:AddLabel(text, true)
        end

        function section:AddKeybind(cfg)
            cfg = cfg or {}
            local id = safeId(cfg.ID or cfg.Flag or cfg.Title or "AliceHUB_Keybind")
            local defaultKey = cfg.Default or Enum.KeyCode.RightShift
            if typeof(defaultKey) == "EnumItem" then defaultKey = defaultKey.Name end
            local label = group:AddLabel(cfg.Title or "Keybind")
            label:AddKeyPicker(id, {
                Default = tostring(defaultKey),
                NoUI = false,
                Text = cfg.Title or "Keybind",
            })
            return registerFlag(id, Library.Options and Library.Options[id], "keybind", nil, cfg.Callback)
        end

        function section:ClearComponents()
            -- Compatibility no-op.
        end

        return section
    end

    local function makeTab(tab)
        local wrapper = {_tab = tab, _sectionCount = 0}
        function wrapper:AddSection(cfg)
            cfg = cfg or {}
            self._sectionCount = self._sectionCount + 1
            local title = cfg.Title or "Section"
            local group
            if self._sectionCount % 2 == 1 then
                group = tab:AddLeftGroupbox(title)
            else
                group = tab:AddRightGroupbox(title)
            end
            return makeSection(group)
        end
        return wrapper
    end

    local function makeWindow(window)
        local wrapper = {_window = window, _win = nil, _visible = true}
        function wrapper:AddTab(cfg)
            local title = type(cfg) == "table" and (cfg.Title or cfg.Name) or tostring(cfg)
            local icon = type(cfg) == "table" and cfg.Icon or nil
            if type(icon) ~= "string" then icon = nil end
            return makeTab(window:AddTab(title or "Tab", icon))
        end
        function wrapper:Show()
            self._visible = true
            pcall(function() Library:Toggle(true) end)
        end
        function wrapper:Hide()
            self._visible = false
            pcall(function() Library:Toggle(false) end)
        end
        return wrapper
    end

    function API:SetLoadingScreen(cfg)
        self._loadingConfig = cfg
    end

    function API:Notify(cfg)
        cfg = cfg or {}
        local ok = pcall(function()
            Library:Notify({
                Title = cfg.Title or "AliceHUB",
                Description = tostring(cfg.Body or cfg.Content or cfg.Description or ""),
                Time = cfg.Duration or cfg.Time or 3,
            })
        end)
        if not ok then
            warn("[AliceHUB] " .. tostring(cfg.Title or "Notify") .. ": " .. tostring(cfg.Body or cfg.Content or ""))
        end
    end

    function API:CreateWindow(cfg)
        cfg = cfg or {}

        -- Match Anime Dice V7 sizing exactly.
        local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
        local compact = viewport.X <= 1700 and viewport.Y <= 900
        local targetWidth = compact and 700 or 900
        local targetHeight = compact and 500 or 620
        targetWidth = math.min(targetWidth, math.max(560, viewport.X - 80))
        targetHeight = math.min(targetHeight, math.max(400, viewport.Y - 70))

        local window = Library:CreateWindow({
            Title = "AliceHUB",
            Icon = ALICE_LOGO_ASSET or "",
            IconSize = UDim2.fromOffset(28, 28),
            Font = Enum.Font.Code,
            Footer = {{Text = "AliceHUB", Copyable = false}, "|", tostring(cfg.SubTitle or "Steal An Egg")},
            NotifySide = "Right",
            ShowMobileButtons = false,
            ShowCustomCursor = false,
            CornerRadius = 4,
            Size = UDim2.fromOffset(targetWidth, targetHeight),
        })

        getgenv().AliceHUB_MainWindowVisible = true
        local wrapped = makeWindow(window)

        local steps = nil
        if type(cfg.BuildTabs) == "function" then
            local ok, result = pcall(cfg.BuildTabs, wrapped)
            if ok then
                steps = result
            else
                warn("[AliceHUB/UI] BuildTabs error: " .. tostring(result))
            end
        end
        if type(steps) == "table" then
            for _, step in ipairs(steps) do
                if type(step) == "table" and type(step.Run) == "function" then
                    local ok, err = pcall(step.Run)
                    if not ok then
                        warn("[AliceHUB/UI] loading step error: " .. tostring(err))
                    end
                end
            end
        end
        if type(cfg.OnReady) == "function" then
            task.defer(function()
                local ok, err = pcall(cfg.OnReady, wrapped)
                if not ok then
                    warn("[AliceHUB/UI] OnReady error: " .. tostring(err))
                end
            end)
        end
        return wrapped
    end

    getgenv().AliceHUB_Library = Library
    getgenv().AliceHUB_NativeUI = Library
    getgenv().AliceHUB_Obsidian = nil
    return API
end)()

-- AliceHUB filter diagnostic helper
getgenv().AliceHUB_SAE_DebugFarmFilter = function()
    local selected = {}
    for rarity, enabled in pairs(_G.SAE_RarityFilter or {}) do
        if enabled == true then selected[#selected + 1] = tostring(rarity) end
    end
    table.sort(selected)
    print("[AliceHUB/Farm] selected rarities:", #selected > 0 and table.concat(selected, ", ") or "ALL")
    print("[AliceHUB/Farm] value minimum:", tostring(_G.SAE_StealValueMinM or "OFF"))
    return selected
end

-- ============================================================
-- AliceHUB UI compatibility adapter
-- ============================================================
local UIAdapter = (function ()
    local Qy = {}
    local function wrapSectionAdapter(Sy)
        local Ty = {}
        function Ty:Button(Uy)
            return Sy:AddButton({Title = Uy.Title or Uy.Name or (""), Desc = Uy.Desc or Uy.Description or nil, Style = ("Default"), Callback = Uy.Callback or
            function ()
            end
            ,})
        end
        function Ty:Toggle(Vy)
            return Sy:AddToggle({ID = Vy.Flag or Vy.Title or tostring(math.random(1e6)), Title = Vy.Title or (""), Desc = Vy.Desc or Vy.Description or nil, Default = Vy.Value or false, Callback = Vy.Callback or
            function ()
            end
            ,})
        end
        function Ty:Slider(Wy)
            return Sy:AddSlider({ID = Wy.Flag or Wy.Title or tostring(math.random(1e6)), Title = Wy.Title or (""), Desc = Wy.Desc or nil, Min = Wy.Min or 0, Max = Wy.Max or 100, Step = Wy.Step or 1, Default = Wy.Default or Wy.Value or 0, Suffix = Wy.Suffix or (""), Callback = Wy.Callback or
            function ()
            end
            ,})
        end
        function Ty:Input(Xy)
            return Sy:AddTextInput({ID = Xy.Flag or Xy.Title or tostring(math.random(1e6)), Title = Xy.Title or (""), Desc = Xy.Desc or nil, Placeholder = Xy.Placeholder or (""), Default = Xy.Value or (""), Width = Xy.Width or nil, Align = Xy.Align or nil, Callback = Xy.Callback or
            function ()
            end
            ,})
        end
        function Ty:Textarea(Yy)
            return Sy:AddTextarea({ID = Yy.Flag or Yy.Title or tostring(math.random(1e6)), Title = Yy.Title or (""), Desc = Yy.Desc or nil, Placeholder = Yy.Placeholder or (""), Default = Yy.Value or (""), Callback = Yy.Callback or
            function ()
            end
            ,})
        end
        function Ty:Dropdown(Zy)
            return Sy:AddDropdown({ID = Zy.Flag or Zy.Title or tostring(math.random(1e6)), Title = Zy.Title or (""), Options = Zy.Values or Zy.Options or {}, Default = Zy.Default ~= nil and Zy.Default or Zy.Value, Callback = Zy.Callback or
            function ()
            end
            ,})
        end
        function Ty:MultiDropdown(az)
            return Sy:AddMultiDropdown({ID = az.Flag or az.Title or tostring(math.random(1e6)), Title = az.Title or (""), Desc = az.Desc or nil, Options = az.Values or az.Options or {}, Default = az.Default or az.Value or {}, Callback = az.Callback or
            function ()
            end
            ,})
        end
        function Ty:Paragraph(bz)
            return Sy:AddParagraph({Title = bz.Title or (""), Body = bz.Content or bz.Body or (""),})
        end
        function Ty:Keybind(cz)
            return Sy:AddKeybind({ID = cz.Title or tostring(math.random(1e6)), Title = cz.Title or (""), Default = cz.Default or Enum.KeyCode.Unknown, Callback = cz.Callback or
            function ()
            end
            ,})
        end
        function Ty:Destroy()
            pcall(function ()
                Sy:ClearComponents()
            end
            )
        end
        return Ty
    end
    local function wrapTabAdapter(ez)
        local fz = {}
        function fz:Section(gz)
            local hz = ez:AddSection({Title = gz.Title or ("")})
            return wrapSectionAdapter(hz)
        end
        function fz:Button(iz)
            local jz = ez:AddSection({Title = ("")})
            return wrapSectionAdapter(jz):Button(iz)
        end
        function fz:Toggle(kz)
            local lz = ez:AddSection({Title = ("")})
            return wrapSectionAdapter(lz):Toggle(kz)
        end
        return fz
    end
    function Qy.Init(mz)
        if not mz then
            warn(("[AliceHUB/UI] AliceUI library tidak ditemukan"))
            return
        end
        local nz = getgenv() [("__MH_ctx")] or {}
        if nz.key then
            getgenv() [("script_key")] = nz.key
        end
        local oz = nz.api or nz.base or getgenv() [("AliceHUB_BaseURL")] or ("")
        getgenv() [("AliceHUB_BaseURL")] = oz
        local pz = nz.tradeApi or getgenv() [("AliceHUB_TradeBaseURL")] or ("")
        getgenv() [("AliceHUB_TradeBaseURL")] = pz
        getgenv() [("AliceHUB_CdnURL")] = oz
        local qz = getgenv() [("AliceHUB_PlaceId")] or tostring(game.PlaceId)
        getgenv() [("AliceHUB_PlaceId")] = qz
        local rz = getgenv() [("AliceHUB_GameName")]
        if not rz or rz == ("") then
            local sz, tz = pcall(function ()
                return game:GetService(("MarketplaceService")):GetProductInfo(game.PlaceId)
            end
            )
            rz = (sz and tz and tz.Name) or ("Roblox")
            getgenv() [("AliceHUB_GameName")] = rz
        end
        local uz = {}
        local function allowNotificationRate()
            local wz = os.clock()
            local xz = {}
            for yz, zz in ipairs(uz) do
                if (wz - zz) < 2 then
                    xz [#xz + 1] = zz
                end
            end
            uz = xz
            if #uz >= 5 then
                return false
            end
            uz [#uz + 1] = wz
            return true
        end
        local Az = {}
        function Az:Notify(Bz)
            Bz = Bz or {}
            if Bz.Title ~= ("Config") and not allowNotificationRate() then
                return
            end
            mz:Notify({Title = Bz.Title or (""), Body = Bz.Content or Bz.Body or (""), Type = Bz.Type or ("info"), Duration = Bz.Duration or 3,})
        end
        getgenv() [("AliceHUB_Notify")] = Az
        getgenv() [("AliceHUB_WindUI")] = Az
        pcall(function ()
            getgenv() [("AliceHUB_Flags")] = mz.Flags
        end
        ) do
            local Cz = {}
            local Dz = game:GetService(("ReplicatedStorage"))
            local Ez, Fz = nil, false
            local function getNetworkPackage()
                if Fz then
                    return Ez
                end
                Fz = true
                local Hz, Iz = pcall(function ()
                    return Dz:WaitForChild(("Shared"), 3):WaitForChild(("Packages"), 3):WaitForChild(("Network"), 3)
                end
                )
                Ez = Hz and Iz or nil
                return Ez
            end
            local Jz = setmetatable({}, {__index = function ()
                return _NOOP
            end
            , __call = function ()
                return _NOOP
            end
            , __newindex = function ()
            end
            ,})
            getgenv() [("AliceHUB_Remote")] = function (Kz)
                return setmetatable({}, {__index = function (Lz, Mz)
                    if Cz [Kz] == nil then
                        local Nz = getNetworkPackage()
                        Cz [Kz] = (Nz and Nz:FindFirstChild(Kz)) or false
                    end
                    local Oz = Cz [Kz]
                    if not Oz then
                        return Jz
                    end
                    local Pz = Oz [Mz]
                    return Pz ~= nil and Pz or Jz
                end
                , __newindex = function (Qz, Rz, Sz)
                    if Cz [Kz] then
                        Cz [Kz] [Rz] = Sz
                    end
                end
                ,})
            end
        end
        local Tz = false
        local Uz = nil
        if mz.SetLoadingScreen then
            mz:SetLoadingScreen({Title = ("AliceHUB")})
        end
        mz:CreateWindow({Title = ("AliceHUB  |  https://discord.gg/teUcVxmTd"), SubTitle = rz, Version = ("v1.0.0"), Key = nil, BuildTabs = function (Vz)
            local Wz = {("Home"), ("Farm"), ("Shop"), ("Misc")}
            local Xz = ("https://discord.gg/teUcVxmTd")
            local Yz = false
            local Zz = {Home = {16898613869, 967, 661}, Farm = {16898613869, 453, 967}, Guild = {16898613777, 869, 0}, Gear = {16898613044, 918, 563}, Shop = {16898613777, 869, 257}, Trade = {16898613699, 820, 710}, Misc = {16898613699, 49, 918}, Movement = {16898613353, 918, 710}, Weather = {16898613044, 0, 967}, Settings = {16898613777, 771, 257}, Config = {16898613699, 918, 453}, Main = {16898613777, 967, 147}, Inventory = {16898612629, 710, 869}, Pet = {16898613699, 771, 257}, Utility = {16898613869, 820, 906}, Esp = {16898613353, 771, 563}, Webhook = {16898612819, 820, 257}, Event = {16898613613, 918, 955}, Quest = {16898613699, 918, 808}, Events = {16898613613, 918, 955}, Eggs = {16898613353, 514, 771}, Upgrades = {16898613044, 918, 563}, Items = {16898612629, 710, 869}, Fishing = {16898613353, 869, 147}, Mailbox = {16898613613, 820, 0},}
            local aA = {16898613044, 514, 771}
            local function buildTabs(cA)
                if Yz then
                    return
                end
                Yz = true
                if type (cA) ~= ("table") or #cA == 0 then
                    cA = Wz
                end
                local dA = {}
                for eA, fA in ipairs(cA) do
                    if type (fA) == ("string") and fA ~= ("") then
                        local gA = Zz [fA] or aA
                        local hA = Vz:AddTab({Title = fA, Icon = {Image = ("rbxassetid://") .. tostring(gA [1]), RectOffset = Vector2.new(gA [2], gA [3]), RectSize = Vector2.new(48, 48),},})
                        dA [fA] = hA
                        local iA = fA:gsub(("[^%w]"), (""))
                        if iA ~= ("") then
                            getgenv() [("AliceHUB_Tab") .. iA] = wrapTabAdapter(hA)
                        end
                    end
                end
                getgenv() [("AliceHUB_Window")] = Vz
                local jA = dA [("Home")]
                if jA then
                    local kA = wrapSectionAdapter(jA:AddSection({Title = ("AliceHUB Info")}))
                    kA:Paragraph({Title = ("Welcome to AliceHUB"), Body = ("Discord: ") .. Xz .. ("\nGame: ") .. rz .. ("\nPlaceId: ") .. qz,})
                    kA:Button({Title = ("Copy Discord Link"), Desc = Xz, Callback = function ()
                        local lA = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)
                        local mA = lA and pcall(lA, Xz)
                        mz:Notify({Title = ("AliceHUB"), Body = mA and ("Discord link disalin ke clipboard!") or ("Executor tidak mendukung copy clipboard."), Type = mA and ("success") or ("warn"), Duration = 3,})
                    end
                    ,})
                end
            end
            getgenv() [("AliceHUB_DeclareTabs")] = function (nA)
                buildTabs(nA)
            end
            return {{Message = ("Loading..."), Run = function ()
                if getgenv() [("AliceHUB_BundleWindow")] == Vz then
                    if not Yz then
                        buildTabs(Wz)
                    end
                    return
                end
                getgenv() [("AliceHUB_BundleWindow")] = Vz
                local oA = getgenv() [("AliceHUB_RunBundle")]
                if type (oA) == ("function") then
                    pcall(oA)
                end
                if not Yz then
                    buildTabs(Wz)
                end
            end
            ,},}
        end
        , OnReady = function (pA)
            if Uz then
                mz:Notify({Title = ("AliceHUB"), Body = Uz, Type = ("warn"), Duration = 8})
            elseif Tz then
                mz:Notify({Title = ("AliceHUB"), Body = ("Game ini belum disupport."), Type = ("warn"), Duration = 4})
            end
            do
                local qA = tostring(getgenv() [("AutoStart")] or _G [("AutoStart")] or AutoStart or (""))
                if qA:find(("WhiteScreen")) then
                    task.delay(0.2, function ()
                        pcall(function ()
                            local rA = pA and pA._win and pA._win.Parent
                            if rA and rA:IsA(("ScreenGui")) then
                                rA:Destroy()
                                return
                            end
                            local function destroyAliceUIGuis(tA)
                                if not tA then
                                    return
                                end
                                for uA, vA in ipairs(tA:GetChildren()) do
                                    if vA:IsA(("ScreenGui")) and vA.Name:find(("AliceUI")) then
                                        vA:Destroy()
                                    end
                                end
                            end
                            destroyAliceUIGuis(game:GetService(("CoreGui")))
                            local wA = game:GetService(("Players")).LocalPlayer
                            destroyAliceUIGuis(wA and wA:FindFirstChild(("PlayerGui")))
                        end
                        )
                    end
                    )
                end
            end
            if _G [("SAE_DestroyUI")] == true then
                pcall(function ()
                    pA:Hide()
                end
                )
            end
            local xA = game:GetService(("UserInputService"))
            local yA = game:GetService(("Players"))
            local zA = game:GetService(("CoreGui"))
            local AA = game:GetService(("TweenService"))
            local BA = not (_G [("SAE_DestroyUI")] == true)
            local CA = yA.LocalPlayer
            local DA = CA:WaitForChild(("PlayerGui"))
            local function toggleMainWindow()
                BA = not BA
                pcall(function ()
                    if BA then
                        pA:Show()
                    else
                        pA:Hide()
                    end
                end
                )
            end
            -- Remove stale floating buttons from older AliceHUB builds before creating the logo.
            for _, root in ipairs({zA, DA}) do
                if root then
                    for _, guiName in ipairs({("AliceHUBLogoButton"), ("AliceHUBToggleButton")}) do
                        local stale = root:FindFirstChild(guiName)
                        if stale then pcall(function () stale:Destroy() end) end
                    end
                end
            end
            local FA = Instance.new(("ScreenGui"))
            FA.Name = ("AliceHUBLogoButton")
            FA.ResetOnSpawn = false
            FA.IgnoreGuiInset = true
            FA.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            pcall(function ()
                FA.Parent = zA
            end
            )
            if not FA.Parent then
                FA.Parent = DA
            end
            local GA = Instance.new(("ImageButton"))
            GA.Name = ("AliceHUBLogo")
            GA.Size = UDim2.new(0, 72, 0, 72)
            GA.Position = UDim2.new(0, 10, 0.5, - 36)
            GA.BackgroundColor3 = Color3.fromRGB(20, 12, 16)
            GA.BackgroundTransparency = 0.08
            GA.BorderSizePixel = 0
            GA.AutoButtonColor = false
            GA.Image = ALICE_LOGO_ASSET or ""
            GA.ImageColor3 = Color3.fromRGB(255, 255, 255)
            GA.ScaleType = Enum.ScaleType.Crop
            GA.Parent = FA
            local logoFallback = Instance.new(("TextLabel"))
            logoFallback.Name = ("Fallback")
            logoFallback.BackgroundTransparency = 1
            logoFallback.Size = UDim2.fromScale(1, 1)
            logoFallback.Font = Enum.Font.Code
            logoFallback.Text = ("A")
            logoFallback.TextColor3 = Color3.fromRGB(214, 77, 112)
            logoFallback.TextSize = 30
            logoFallback.TextXAlignment = Enum.TextXAlignment.Center
            logoFallback.TextYAlignment = Enum.TextYAlignment.Center
            logoFallback.ZIndex = GA.ZIndex + 1
            logoFallback.Parent = GA
            __aliceRegisterLogoTarget(GA, logoFallback)

            local HA = Instance.new(("UICorner"))
            HA.CornerRadius = UDim.new(0, 16)
            HA.Parent = GA
            local IA = Instance.new(("UIStroke"))
            IA.Name = ("RubyOutline")
            IA.Color = Color3.fromRGB(181, 48, 83)
            IA.Thickness = 2
            IA.Transparency = 0.12
            IA.Parent = GA
            task.delay(3, function ()
                if GA and GA.Parent then
                    local loaded = false
                    pcall(function () loaded = GA.IsLoaded end)
                    if not loaded then
                        GA.Image = ""
                    end
                end
            end)
            local XA, YA, ZA, aB = false, nil, nil, nil
            local draggedLogo = false
            GA.InputBegan:Connect(function (bB)
                if bB.UserInputType == Enum.UserInputType.MouseButton1 or bB.UserInputType == Enum.UserInputType.Touch then
                    XA = true
                    draggedLogo = false
                    ZA = bB.Position
                    aB = GA.Position
                    bB.Changed:Connect(function ()
                        if bB.UserInputState == Enum.UserInputState.End then
                            XA = false
                        end
                    end
                    )
                end
            end
            )
            GA.InputChanged:Connect(function (cB)
                if cB.UserInputType == Enum.UserInputType.MouseMovement or cB.UserInputType == Enum.UserInputType.Touch then
                    YA = cB
                end
            end
            )
            xA.InputChanged:Connect(function (dB)
                if dB == YA and XA then
                    local eB = dB.Position - ZA
                    if math.abs(eB.X) > 5 or math.abs(eB.Y) > 5 then
                        draggedLogo = true
                    end
                    GA.Position = UDim2.new(aB.X.Scale, aB.X.Offset + eB.X, aB.Y.Scale, aB.Y.Offset + eB.Y)
                end
            end
            )
            GA.MouseButton1Click:Connect(function ()
                if draggedLogo then
                    draggedLogo = false
                    return
                end
                AA:Create(GA, TweenInfo.new(0.08), {Size = UDim2.new(0, 66, 0, 66)}):Play()
                task.wait(0.08)
                AA:Create(GA, TweenInfo.new(0.08), {Size = UDim2.new(0, 72, 0, 72)}):Play()
                toggleMainWindow()
            end
            )
            xA.InputBegan:Connect(function (fB, gB)
                if gB then
                    return
                end
                if fB.KeyCode == Enum.KeyCode.RightShift then
                    toggleMainWindow()
                end
            end
            )
            mz:Notify({Title = ("AliceHUB Ready"), Body = ("Semua modul berhasil dimuat"), Type = ("success"), Duration = 3})
        end
        ,})
    end
    return Qy
end
)()
getgenv() [("AliceHUB_RunBundle")] = function ()
    local iB = ("v1.52.0-alicehub-anime-ui-exact")
    local jB = {("Farm"), ("Machine"), ("Upgrade"), ("Events"), ("Movement"), ("Webhook"), ("Settings"), ("Info")}
    pcall(function ()
        if getgenv and type (getgenv() [("AliceHUB_DeclareTabs")]) == ("function") then
            getgenv() [("AliceHUB_DeclareTabs")]({("Farm"), ("Machine"), ("Upgrade"), ("Events"), ("Movement"), ("Webhook"), ("Settings"), ("Info")})
        end
    end
    )
    pcall(function ()
        local infoTab = getgenv() [("AliceHUB_TabInfo")]
        if not infoTab then return end
        local player = game:GetService(("Players")).LocalPlayer
        local executor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or (getexecutor and getexecutor()) or ("Unknown")
        local account = infoTab:Section({Title = ("Account Status")})
        account:Paragraph({Title = ("Username"), Content = player and player.Name or ("Unknown")})
        account:Paragraph({Title = ("Status"), Content = ("Active")})
        account:Paragraph({Title = ("Executor"), Content = tostring(executor)})
        local gameInfo = infoTab:Section({Title = ("Game Info")})
        gameInfo:Paragraph({Title = ("Game"), Content = ("Steal An Egg")})
        gameInfo:Paragraph({Title = ("Place ID"), Content = tostring(game.PlaceId)})
        local scripts = infoTab:Section({Title = ("AliceHUB Scripts")})
        scripts:Paragraph({Title = ("1"), Content = ("Steal An Egg")})
        scripts:Paragraph({Title = ("2"), Content = ("Grow A Chicken Fighter")})
        scripts:Paragraph({Title = ("3"), Content = ("Jump For Animals")})
    end)
    local moduleErrors = {}
    getgenv() [("AliceHUB_SAE_ModuleErrors")] = moduleErrors
    local function runAliceModule(name, fn)
        local ok, err = xpcall(fn, function (reason)
            local message = tostring(reason)
            pcall(function ()
                if debug and type (debug.traceback) == ("function") then
                    message = debug.traceback(message, 2)
                end
            end)
            return message
        end)
        if not ok then
            moduleErrors [name] = err
            warn(("[AliceHUB/%s] %s"):format(tostring(name), tostring(err)))
            local notify = getgenv() [("AliceHUB_Notify")]
            if notify and type (notify.Notify) == ("function") then
                pcall(function ()
                    notify:Notify({Title = ("AliceHUB Module Error"), Content = tostring(name) .. (" failed to load. Check console."), Duration = 6})
                end)
            end
        else
            moduleErrors [name] = nil
        end
        return ok, err
    end
    local function spawnAliceWorker(name, fn, cleanup)
        task.spawn(function ()
            local ok, err = xpcall(fn, function (reason)
                local message = tostring(reason)
                pcall(function ()
                    if debug and type (debug.traceback) == ("function") then
                        message = debug.traceback(message, 2)
                    end
                end)
                return message
            end)
            local key = ("runtime:") .. tostring(name)
            if not ok then
                moduleErrors [key] = err
                warn((("[AliceHUB/%s] runtime worker stopped: %s")):format(tostring(name), tostring(err)))
            else
                moduleErrors [key] = nil
            end
            if type (cleanup) == ("function") then
                pcall(cleanup, ok, err)
            end
        end)
    end
    runAliceModule("AntiAFK", function (...)
        local kB = game:GetService(("Players"))
        local lB = kB.LocalPlayer
        if not lB then
            return
        end
        if getgenv() [("AliceHUB_SAE_AfkRunning")] then
            return
        end
        getgenv() [("AliceHUB_SAE_AfkRunning")] = true do
            getgenv() [("AliceHUB_SAE_AfkActions")] = getgenv() [("AliceHUB_SAE_AfkActions")] or 0
            local function disableGameAntiAfkScript()
                local nB = lB:FindFirstChildOfClass(("PlayerScripts"))
                if not nB then
                    return
                end
                local oB = nB:FindFirstChild(("Game"))
                if not oB then
                    return
                end
                local pB = oB:FindFirstChild(("AntiAFK"))
                if not pB then
                    return
                end
                if pB.Disabled then
                    return
                end
                if pcall(function ()
                    pB.Disabled = true
                end
                ) then
                    getgenv() [("AliceHUB_SAE_AfkActions")] = getgenv() [("AliceHUB_SAE_AfkActions")] + 1
                end
            end
            local function disableIdledConnections()
                local rB, sB = pcall(function ()
                    return getconnections(lB.Idled)
                end
                )
                if not rB or type (sB) ~= ("table") then
                    return
                end
                for tB, uB in ipairs(sB) do
                    if uB.Enabled then
                        if pcall(function ()
                            uB:Disable()
                        end
                        ) then
                            getgenv() [("AliceHUB_SAE_AfkActions")] = getgenv() [("AliceHUB_SAE_AfkActions")] + 1
                        end
                    end
                end
            end
            local vB = false
            local function runAntiAfkSetup()
                if vB then
                    return
                end
                vB = true disableGameAntiAfkScript()
                disableIdledConnections()
                getgenv() [("AliceHUB_SAE_AfkLastRun")] = os.time()
                vB = false
            end
            runAntiAfkSetup()
            lB.CharacterAdded:Connect(function ()
                task.wait(1)
                runAntiAfkSetup()
            end
            )
            task.delay(5, runAntiAfkSetup)
            task.delay(20, runAntiAfkSetup)
        end
    end
    )
    runAliceModule("FarmCore", function (...)
        local xB = getgenv() [("AliceHUB_WindUI")]
        local yB = getgenv() [("AliceHUB_TabFarm")]
        if not yB then
            return
        end
        local zB = game:GetService(("ReplicatedStorage"))
        local AB = game:GetService(("Players"))
        local BB = game:GetService(("RunService"))
        local CB = AB.LocalPlayer
        local DB = 20
        local EB = 0.10
        local FB = 8
        local GB = 45
        local HB = 3
        local IB = 12
        local JB = 3
        local KB = CFrame.new(545.498169, 70.5743179, - 373.694336, - 0.387677997, 4.65573002e-08, - 0.921794832, 2.49264431e-08, 1, 4.0023945e-08, 0.921794832, - 7.46066409e-09, - 0.387677997)
        local LB = CFrame.new(527.195068, 70.5743103, - 366.193207, 0.991655886, 3.10400239e-08, 0.128913239, - 2.53748063e-08, 1, - 4.55884077e-08, - 0.128913239, 4.19368646e-08, 0.991655886)
        local MB = CFrame.new(543.658569, 70.5743103, - 420.763092, 0.23178184, - 1.76178219e-08, - 0.97276777, - 9.24899837e-08, 1, - 4.0148656e-08, 0.97276777, 9.92770026e-08, 0.23178184)
        local NB = CFrame.new(535.798279, 70.5743103, - 410.650757, - 0.986485302, - 8.97836472e-08, 0.163849756, - 8.35836218e-08, 1, 4.47338842e-08, - 0.163849756, 3.04341654e-08, - 0.986485302)
        local OB = {4, 12, 30, 60, 120}
        local PB = {}
        local QB = 45
        local RB = 3
        local SB = {}
        local TB = 2.5
        local UB = 4.0
        local VB = 2.0
        local WB = 0.05
        local XB = 1.0
        local YB = 1.5
        local ZB = 8
        local aC = 1.0
        local bC = 4
        local cC = 60
        local dC = 3.0
        local eC = 1.2
        local fC = 120
        local gC = 0.001
        local hC = {Slot = true, Dropped = true}
        local iC = {Carried = true}
        local jC = {GuardCarried = true}
        local kC = {Claimed = true}
        local lC = 12.0
        local mC = 1.0
        local nC = 2.0
        local oC = 3.0
        local pC = 0.30
        local qC = 0.30
        local rC = 1.5
        local sC = 15
        local tC = 33
        local uC = 1000
        local vC = 300
        local wC = 18
        local xC = 0.05
        local yC = 200
        local zC = 4
        local AC = 0.15
        local BC = {UP = 6, DOWN = 24, MAX_DY = 8}
        _G [("SAE_TweenMove")] = _G [("SAE_TweenMove")] or false _G [("SAE_TweenSpeed")] = tonumber(_G [("SAE_TweenSpeed")]) or vC
        _G [("SAE_InstantTP")] = _G [("SAE_InstantTP")] or false
        -- ============================================================
        -- SAE core movement / field-egg engine
        -- ============================================================
        local MovementTurnConfig = (function ()
            local CC = 5.0
            local DC = 16
            local EC = nil
            return {armWait = CC, wsUmpan = DC, rejectMax = 2, tandai = function (FC)
                EC = FC
            end
            , tanda = function ()
                return EC
            end
            , left = function ()
                if not EC then
                    return 0
                end
                local GC = EC - workspace:GetServerTimeNow()
                return GC > 0 and GC or 0
            end
            , siapkan = function ()
                local HC = game:GetService(("Players")).LocalPlayer
                local IC = HC and HC.Character
                if not IC then
                    return false
                end
                if IC:FindFirstChild(("AliceHUBGodmode")) then
                    return true
                end
                local JC = IC:FindFirstChildOfClass(("Humanoid"))
                if not JC then
                    return false
                end
                local KC = Instance.new(("BoolValue"))
                KC.Name = ("AliceHUBGodmode")
                KC.Value = true KC.Parent = IC
                local LC = Instance.new(("Humanoid"))
                LC.RigType = JC.RigType
                LC.WalkSpeed = JC.WalkSpeed
                LC.JumpPower = JC.JumpPower
                LC.JumpHeight = JC.JumpHeight
                LC.HipHeight = JC.HipHeight
                LC.UseJumpPower = JC.UseJumpPower
                LC.AutoJumpEnabled = JC.AutoJumpEnabled
                LC.MaxHealth = JC.MaxHealth
                LC.Health = JC.MaxHealth
                LC.BreakJointsOnDeath = false LC.RequiresNeck = false
                for MC, NC in ipairs(JC:GetChildren()) do
                    if not NC:IsA(("Animator")) and NC.Name ~= ("Status") then
                        pcall(function ()
                            NC:Clone().Parent = LC
                        end
                        )
                    end
                end
                JC:Destroy()
                LC.Parent = IC
                local OC = IC:FindFirstChild(("Animate"))
                if OC then
                    OC.Disabled = true task.wait(0.15)
                    OC.Disabled = false
                end
                task.wait(0.2)
                pcall(function ()
                    local PC = HC.PlayerScripts:WaitForChild(("PlayerModule"), 5)
                    if not PC then
                        return
                    end
                    local QC = require(PC):GetControls()
                    QC.humanoid = LC
                    QC:Disable()
                    task.wait(0.1)
                    QC:Enable()
                end
                )
                HC:SetAttribute(("AntiAfkIdleOverride"), 99999999)
                return true
            end
            ,}
        end
        )()
        local SC = nil
        local function getCoreEggState()
            if SC then
                return SC
            end
            local UC = zB:FindFirstChild(("Client"))
            if not UC then
                return nil
            end
            local VC = UC:FindFirstChild(("EggState"))
            if not VC then
                return nil
            end
            local WC, XC = pcall(require, VC)
            if WC and type (XC) == ("table") then
                SC = XC
            end
            return SC
        end
        local YC = nil
        local function getAreaEggSlotIdentity()
            if YC then
                return YC
            end
            local aD = zB:FindFirstChild(("Shared"))
            if not aD then
                return nil
            end
            local bD = aD:FindFirstChild(("Util"))
            if not bD then
                return nil
            end
            local cD = bD:FindFirstChild(("AreaEggSlotIdentity"))
            if not cD then
                return nil
            end
            local dD, eD = pcall(require, cD)
            if dD and type (eD) == ("table") then
                YC = eD
            end
            return YC
        end
        local function looksLikeFirstAreaEggUid(gD)
            local hD = getAreaEggSlotIdentity()
            if hD and type (hD.LooksLikeFirstAreaUid) == ("function") then
                local iD, jD = pcall(hD.LooksLikeFirstAreaUid, gD)
                if iD then
                    return jD and true or false
                end
            end
            return gD:sub(1, 13) == ("FirstAreaEgg_")
        end
        local function getFirstAreaEggOwnerUserId(lD)
            local mD = getAreaEggSlotIdentity()
            if mD and type (mD.FirstAreaOwnerUserId) == ("function") then
                local nD, oD = pcall(mD.FirstAreaOwnerUserId, lD)
                if nD then
                    return oD
                end
            end
            return tonumber(lD:match(("^FirstAreaEgg_(-?%d+)_")))
        end
        local function isOwnFirstAreaEgg(qD)
            if not looksLikeFirstAreaEggUid(qD) then
                return false
            end
            return getFirstAreaEggOwnerUserId(qD) == CB.UserId
        end
        local rD = nil
        local function getCoreAssetDirectory()
            if rD ~= nil then
                return rD or nil
            end
            local tD = zB:FindFirstChild(("Data"))
            local uD = tD and tD:FindFirstChild(("Assets"))
            local vD = nil
            if uD then
                local wD, xD = pcall(require, uD)
                if wD and type (xD) == ("table") and type (xD.Directory) == ("table") then
                    vD = xD.Directory
                end
            end
            rD = vD or false
            return vD
        end
        local yD = {}
        local function getEggRarity(AD)
            if AD == nil then
                return nil
            end
            local BD = yD [AD]
            if BD ~= nil then
                if BD == false then
                    return nil
                end
                return BD
            end
            local CD = getCoreAssetDirectory()
            local DD = CD and CD [AD]
            if type (DD) ~= ("table") or type (DD.Rarity) ~= ("table") then
                yD [AD] = false
                return nil
            end
            local ED = DD.Rarity._id or DD.Rarity.DisplayName
            if type (ED) ~= ("string") then
                yD [AD] = false
                return nil
            end
            yD [AD] = ED
            return ED
        end
        getgenv() [("AliceHUB_SAE_RarityOf")] = getEggRarity
        local FD = nil
        local function getCoreAssetItems()
            if FD ~= nil then
                return FD or nil
            end
            local HD = zB:FindFirstChild(("Shared"))
            local ID = HD and HD:FindFirstChild(("Util"))
            local JD = ID and ID:FindFirstChild(("AssetItems"))
            local KD = nil
            if JD then
                local LD, MD = pcall(require, JD)
                if LD and type (MD) == ("table") and type (MD.SalePrice) == ("function") then
                    KD = MD
                end
            end
            FD = KD or false
            return KD
        end
        local function getEggSaleValue(OD)
            if type (OD) ~= ("table") then
                return nil
            end
            local PD = getCoreAssetItems()
            if not PD then
                return nil
            end
            local QD, RD = pcall(PD.SalePrice, {Category = OD.AssetCategory, Scale = OD.AssetScale, Mutations = OD.Mutations, BaseMutation = OD.BaseMutation, EyeColor = OD.AssetEyeColor, ColorSeed = OD.AssetColorSeed, ColorIndex = OD.AssetColorIndex,})
            if QD and tonumber(RD) then
                return tonumber(RD)
            end
            return nil
        end
        getgenv() [("AliceHUB_SAE_EggValue")] = getEggSaleValue
        local function getEggWeightKg(TD)
            if type (TD) ~= ("table") then
                return nil
            end
            local UD = getCoreAssetItems()
            if not UD or type (UD.WeightKg) ~= ("function") then
                return nil
            end
            local VD, WD = pcall(UD.WeightKg, {Category = TD.AssetCategory, Scale = TD.AssetScale, Mutations = TD.Mutations,})
            if VD and tonumber(WD) then
                return tonumber(WD)
            end
            return nil
        end
        getgenv() [("AliceHUB_SAE_EggWeight")] = getEggWeightKg
        getgenv() [("AliceHUB_SAE_MutationEarningsFactor")] = function (XD)
            if type (XD) ~= ("table") then
                return 1
            end
            local YD = getgenv() [("AliceHUB_SAE_MutationsMod")]
            local ZD = nil
            if YD ~= nil then
                ZD = YD or nil
            else
                local aE = zB:FindFirstChild(("Shared"))
                local bE = aE and aE:FindFirstChild(("Modules"))
                local cE = bE and bE:FindFirstChild(("Mutations"))
                if cE then
                    local dE, eE = pcall(require, cE)
                    if dE and type (eE) == ("table") and type (eE.EarningsFor) == ("function") then
                        ZD = eE
                    end
                end
                getgenv() [("AliceHUB_SAE_MutationsMod")] = ZD or false
            end
            if not ZD then
                return 1
            end
            local fE, gE = pcall(ZD.EarningsFor, XD)
            if fE and tonumber(gE) then
                return tonumber(gE)
            end
            return 1
        end
        local function getEggMoneyPerSecond(iE)
            if type (iE) ~= ("table") then
                return nil
            end
            local jE = getCoreAssetDirectory()
            local kE = jE and jE [iE.AssetCategory]
            local lE = kE and tonumber(kE.EarningRate)
            if not lE then
                return nil
            end
            local mE = tonumber(iE.AssetScale) or 1
            return lE * (mE ^ 1.85) * getgenv() [("AliceHUB_SAE_MutationEarningsFactor")](iE.Mutations)
        end
        getgenv() [("AliceHUB_SAE_EggMoneyPerSecond")] = getEggMoneyPerSecond
        local function buildEggInfo(oE)
            if type (oE) ~= ("table") then
                return nil
            end
            local pE = {}
            if type (oE.Mutations) == ("table") then
                for qE, rE in ipairs(oE.Mutations) do
                    pE [qE] = tostring(rE)
                end
            end
            return {category = oE.AssetCategory, rarity = getEggRarity(oE.AssetCategory), scale = tonumber(oE.AssetScale), mutations = pE, baseMutation = (type (oE.BaseMutation) == ("string")) and oE.BaseMutation or nil, moneyPerSecond = getEggMoneyPerSecond(oE), weight = getEggWeightKg(oE), value = getEggSaleValue(oE),}
        end
        getgenv() [("AliceHUB_SAE_EggEsp")] = buildEggInfo
        local sE = {k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15, qt = 1e18, sx = 1e21,}
        local function parseStealValueInput(uE)
            if type (uE) ~= ("string") then
                return nil
            end
            local vE = (uE:gsub(("%s+"), (""))):gsub((","), (""))
            if vE == ("") then
                return nil
            end
            local wE, xE = vE:match(("^(%d+%.?%d*)([A-Za-z]*)$"))
            if not wE then
                return nil
            end
            local yE = tonumber(wE)
            if not yE then
                return nil
            end
            local zE = xE:lower()
            local AE
            if zE == ("") then
                AE = 1e6
            else
                AE = sE [zE]
                if not AE then
                    return nil
                end
            end
            return (yE * AE) / 1e6
        end
        getgenv() [("AliceHUB_SAE_StealValueText")] = getgenv() [("AliceHUB_SAE_StealValueText")] or ("")
        _G [("SAE_StealValueMinM")] = _G [("SAE_StealValueMinM")] or nil
        local function setStealValueInput(CE)
            CE = tostring(CE or (""))
            getgenv() [("AliceHUB_SAE_StealValueText")] = CE
            local DE = parseStealValueInput(CE)
            if DE ~= nil and DE > 0 then
                _G [("SAE_StealValueMinM")] = DE
            else
                _G [("SAE_StealValueMinM")] = nil
            end
        end
        local function hasStealValueFilter()
            return type (_G [("SAE_StealValueMinM")]) == ("number") and _G [("SAE_StealValueMinM")] > 0
        end
        local function passesStealValueFilter(GE)
            local HE = getEggMoneyPerSecond(GE)
            if not HE then
                return false
            end
            return HE >= (_G [("SAE_StealValueMinM")] * 1e6)
        end
        local IE = {("Common"), ("Uncommon"), ("Rare"), ("Epic"), ("Legendary"), ("Mythic"), ("Divine"), ("Cosmic"), ("Secret"), ("Eternal"),}
        local JE = {}
        for KE, LE in ipairs(IE) do
            JE [LE] = KE
        end
        getgenv() [("AliceHUB_SAE_RarityOptions")] = IE
        _G [("SAE_RarityFilter")] = _G [("SAE_RarityFilter")] or {}
        local function isEggRarityFilterEmpty()
            for NE in pairs(_G [("SAE_RarityFilter")]) do
                return false
            end
            return true
        end
        local OE = getgenv() [("AliceHUB_SAE_Stats")]
        if not OE then
            OE = {collected = 0, byRarity = {}, dropped = 0, startedAt = os.clock()}
            getgenv() [("AliceHUB_SAE_Stats")] = OE
        end
        local function recordEggCollected(QE)
            OE.collected = OE.collected + 1
            local RE = getEggRarity(QE.AssetCategory) or ("Unknown")
            OE.byRarity [RE] = (OE.byRarity [RE] or 0) + 1
            local SE = getgenv() [("AliceHUB_SAE_WebhookEggStolen")]
            if type (SE) == ("function") then
                local TE, UE = pcall(buildEggInfo, QE)
                pcall(SE, QE.AssetCategory, getEggRarity(QE.AssetCategory), TE and UE or nil)
            end
        end
        local function passesEggRarityFilter(WE)
            if isEggRarityFilterEmpty() then
                return true
            end
            local XE = getEggRarity(WE.AssetCategory)
            if XE == nil then
                return false
            end
            return _G [("SAE_RarityFilter")] [XE] == true
        end
        local function getAreaEggSlotKey(ZE)
            if not looksLikeFirstAreaEggUid(ZE.Uid) then
                return nil
            end
            local aF = getAreaEggSlotIdentity()
            if aF and type (aF.SlotKey) == ("function") then
                local bF, cF = pcall(aF.SlotKey, ZE.AreaId, ZE.NestId)
                if bF and type (cF) == ("string") then
                    return cF
                end
            end
            return tostring(ZE.AreaId) .. (":") .. tostring(ZE.NestId)
        end
        local dF = false
        local eF = nil
        local fF = nil
        local gF = {}
        task.spawn(function ()
            local hF = nil
            for iF = 1, 60 do
                local jF = zB:FindFirstChild(("Shared"))
                local kF = jF and jF:FindFirstChild(("Remotes"))
                if kF then
                    local lF, mF = pcall(require, kF)
                    if lF and type (mF) == ("table") and type (mF.EggWorld) == ("table") then
                        hF = mF.EggWorld
                    end
                end
                if hF then
                    break
                end
                task.wait(0.25)
            end
            if not hF then
                return
            end
            local nF = hF.FieldEggCarry
            if nF then
                pcall(function ()
                    nF.OnClientEvent:Connect(function (oF)
                        if type (oF) == ("table") then
                            dF = oF.IsCarrying and true or false eF = dF and oF.Uid or nil fF = dF and os.clock() or nil getgenv() [("AliceHUB_SAE_Carrying")] = dF
                        end
                    end
                    )
                end
                )
            end
            local pF = hF.FieldEggShifted
            if pF then
                pcall(function ()
                    pF.OnClientEvent:Connect(function (qF)
                        if type (qF) == ("table") and qF.DroppedAt and type (qF.Uid) == ("string") then
                            gF [qF.Uid] = os.clock()
                        end
                    end
                    )
                end
                )
            end
        end
        )
        pcall(function ()
            CB:GetAttributeChangedSignal(("RagdollEndTime")):Connect(function ()
                MovementTurnConfig.tandai(CB:GetAttribute(("RagdollEndTime")))
            end
            )
            MovementTurnConfig.tandai(CB:GetAttribute(("RagdollEndTime")))
        end
        )
        local function getHumanoidRootPart()
            local sF = CB.Character
            if not sF then
                return nil
            end
            return sF:FindFirstChild(("HumanoidRootPart"))
        end
        local tF = true CB.CharacterAdded:Connect(function ()
            tF = true
        end
        )
        local uF = 1e6
        local vF = false
        local wF = nil
        local function bindProtectedHumanoid(yF)
            if not yF or wF == yF then
                return
            end
            wF = yF
            pcall(function ()
                yF.MaxHealth = uF
                yF.Health = uF
            end
            )
            yF.HealthChanged:Connect(function (zF)
                if vF and yF == wF and zF < uF then
                    yF.Health = uF
                end
            end
            )
        end
        local function setTemporaryGodmode(BF)
            vF = BF and true or false
            local CF = CB.Character
            local DF = CF and CF:FindFirstChildOfClass(("Humanoid"))
            if not vF then
                wF = nil
                if DF then
                    pcall(function ()
                        DF.MaxHealth = 100
                        if DF.Health > 100 then
                            DF.Health = 100
                        end
                    end
                    )
                end
                return
            end
            if DF then
                bindProtectedHumanoid(DF)
            end
        end
        local EF = nil
        local function installAntiRagdoll()
            local GF = CB.Character
            local HF = GF and GF:FindFirstChildOfClass(("Humanoid"))
            local IF = GF and GF:FindFirstChild(("HumanoidRootPart"))
            if not GF or not HF or EF == GF then
                return
            end
            EF = GF
            if IF then
                IF:GetPropertyChangedSignal(("Anchored")):Connect(function ()
                    if not vF or EF ~= GF then
                        return
                    end
                    if IF.Anchored then
                        pcall(function ()
                            IF.Anchored = false
                        end
                        )
                    end
                end
                )
                if IF.Anchored then
                    pcall(function ()
                        IF.Anchored = false
                    end
                    )
                end
            end
            local function removeRagdollConstraint(KF)
                if (KF:IsA(("BallSocketConstraint")) or KF:IsA(("HingeConstraint"))) and KF:GetAttribute(("RagdollConstraint")) then
                    pcall(function ()
                        KF:Destroy()
                    end
                    )
                end
            end
            for LF, MF in ipairs(GF:GetDescendants()) do
                removeRagdollConstraint(MF)
                if MF:IsA(("Motor6D")) and not MF.Enabled then
                    pcall(function ()
                        MF.Enabled = true
                    end
                    )
                end
            end
            GF.DescendantAdded:Connect(function (NF)
                if not vF or EF ~= GF then
                    return
                end
                task.spawn(function ()
                    removeRagdollConstraint(NF)
                end
                )
            end
            )
            for OF, PF in ipairs(GF:GetDescendants()) do
                if PF:IsA(("Motor6D")) then
                    PF:GetPropertyChangedSignal(("Enabled")):Connect(function ()
                        if not vF or EF ~= GF then
                            return
                        end
                        if not PF.Enabled then
                            task.spawn(function ()
                                pcall(function ()
                                    PF.Enabled = true
                                end
                                )
                            end
                            )
                        end
                    end
                    )
                end
            end
            HF.StateChanged:Connect(function (QF, RF)
                if not vF or EF ~= GF then
                    return
                end
                if RF ~= Enum.HumanoidStateType.Physics then
                    return
                end
                task.spawn(function ()
                    pcall(function ()
                        HF.PlatformStand = false
                    end
                    )
                    pcall(function ()
                        HF:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                    )
                    for SF = 1, 6 do
                        local TF = getHumanoidRootPart()
                        if TF then
                            pcall(function ()
                                TF.AssemblyLinearVelocity = Vector3.new(0, TF.AssemblyLinearVelocity.Y, 0)
                                TF.AssemblyAngularVelocity = Vector3.zero
                            end
                            )
                        end
                        BB.Heartbeat:Wait()
                    end
                end
                )
            end
            )
            if HF:GetState() == Enum.HumanoidStateType.Physics then
                pcall(function ()
                    HF:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                )
            end
        end
        CB.CharacterAdded:Connect(function (UF)
            if not vF then
                return
            end
            local VF = UF:WaitForChild(("Humanoid"), 10)
            if VF then
                bindProtectedHumanoid(VF)
            end
            installAntiRagdoll()
        end
        )
        local WF = 20
        local XF = 8
        local YF = 6
        local ZF = 8
        local aG = 1.5
        local bG, cG = nil, 0
        local dG = 30.0
        local function getCachedTreadmillPosition()
            if bG and (os.clock() - cG) < dG then
                return bG
            end
            local fG = getgenv() [("AliceHUB_SAE_TreadmillPos")]
            if type (fG) ~= ("function") then
                return bG
            end
            local gG, hG = pcall(fG)
            cG = os.clock()
            if gG and typeof(hG) == ("Vector3") then
                bG = hG
            end
            return bG
        end
        local function distancePointToSegment2D(jG, kG, lG)
            local mG, nG = lG.X - kG.X, lG.Z - kG.Z
            local oG, pG = jG.X - kG.X, jG.Z - kG.Z
            local qG = mG * mG + nG * nG
            local rG = 0
            if qG > 1e-6 then
                rG = math.clamp((oG * mG + pG * nG) / qG, 0, 1)
            end
            local sG, tG = kG.X + mG * rG, kG.Z + nG * rG
            local uG, vG = jG.X - sG, jG.Z - tG
            return math.sqrt(uG * uG + vG * vG)
        end
        local wG = 6
        local xG = 60
        local yG = 3
        local zG = 6
        local AG = 0.15
        local BG = 2.0
        local CG, DG = {}, 0
        local function getCachedTrapPositions()
            if (os.clock() - DG) < BG then
                return CG
            end
            DG = os.clock()
            local FG = {}
            local GG = {}
            local function addTrapPosition(IG)
                local JG = IG:FindFirstChild(("Hitbox"))
                local KG = (JG and JG:IsA(("BasePart"))) and JG or (IG:IsA(("BasePart")) and IG or nil)
                if KG and not GG [KG] then
                    GG [KG] = true FG [#FG + 1] = KG.Position
                end
            end
            pcall(function ()
                for LG, MG in ipairs(game:GetService(("CollectionService")):GetTagged(("PlacedTrap"))) do
                    addTrapPosition(MG)
                end
            end
            )
            pcall(function ()
                local NG = workspace:FindFirstChild(("__DEBRIS"))
                if not NG then
                    return
                end
                for OG, PG in ipairs(NG:GetChildren()) do
                    if PG.Name == ("PlayerTrap") then
                        addTrapPosition(PG)
                    end
                end
            end
            )
            CG = FG
            return FG
        end
        local function isPathNearTrap(RG, SG, TG)
            local UG = getCachedTrapPositions()
            if #UG == 0 then
                return false
            end
            for VG, WG in ipairs(UG) do
                if distancePointToSegment2D(WG, RG, SG) <= TG then
                    return true
                end
            end
            return false
        end
        local XG = 3.0
        local YG = 180.0
        local ZG = 12.0
        local function walkMoveTo(bH, cH, dH, eH, fH)
            local gH = getHumanoidRootPart()
            if not gH then
                return false
            end
            local hH = os.clock()
            local iH = 0
            local jH = gH.Position
            local kH = os.clock()
            local lH = Vector3.new(bH.X - gH.Position.X, 0, bH.Z - gH.Position.Z)
            if lH.Magnitude > 0.1 then
                lH = lH.Unit
            else
                lH = Vector3.new(1, 0, 0)
            end
            local mH = nil
            local nH = 0
            local oH = false
            local pH = nil
            while (cH == nil or cH()) and (os.clock() - hH) < YG do
                if eH and not eH() then
                    return false
                end
                local qH = getHumanoidRootPart()
                local rH = CB.Character and CB.Character:FindFirstChildOfClass(("Humanoid"))
                if not qH or not rH then
                    BB.Heartbeat:Wait()
                elseif rH.Health <= 0 then
                    return false
                else
                    local sH = qH.Position
                    local tH = Vector3.new(bH.X - sH.X, 0, bH.Z - sH.Z)
                    local uH = tH.Magnitude
                    if uH < JB then
                        rH:MoveTo(sH)
                        return true
                    end
                    if dH and uH <= 35 and dH(uH) then
                        rH:MoveTo(sH)
                        return true
                    end
                    if (sH - jH).Magnitude > 1.0 then
                        jH = sH
                        kH = os.clock()
                    elseif (os.clock() - kH) > ZG then
                        return false
                    end
                    local vH = (not fH) and getCachedTreadmillPosition() or nil
                    local wH = false
                    if vH then
                        local xH, yH = bH.X - vH.X, bH.Z - vH.Z
                        wH = math.sqrt(xH * xH + yH * yH) < (WF * aG)
                    end
                    local zH = false
                    if vH and not wH and not oH then
                        zH = distancePointToSegment2D(vH, sH, bH) < WF
                    end
                    local AH = false
                    if mH then
                        local BH, CH = mH.X - sH.X, mH.Z - sH.Z
                        local DH = math.sqrt(BH * BH + CH * CH) <= YF
                        if DH or (not zH) or (os.clock() - nH) > ZF then
                            mH = nil oH = true AH = true
                        end
                    elseif zH then
                        local EH, FH = tH.X / uH, tH.Z / uH
                        local GH, HH = - FH, EH
                        if ((sH.X - vH.X) * GH + (sH.Z - vH.Z) * HH) < 0 then
                            GH, HH = - GH, - HH
                        end
                        if (GH * GH + HH * HH) < 0.01 then
                            GH, HH = - lH.Z, lH.X
                        end
                        mH = Vector3.new(vH.X + GH * (WF + XF), sH.Y, vH.Z + HH * (WF + XF))
                        nH = os.clock()
                        AH = true
                    end
                    local IH = rH:GetState()
                    local JH = IH ~= Enum.HumanoidStateType.Physics and IH ~= Enum.HumanoidStateType.FallingDown and IH ~= Enum.HumanoidStateType.Ragdoll and IH ~= Enum.HumanoidStateType.PlatformStanding and IH ~= Enum.HumanoidStateType.Seated
                    if JH and pH == false then
                        AH = true
                    end
                    pH = JH
                    if (not AH) and JH and rH.MoveDirection.Magnitude < 0.05 and (os.clock() - iH) > pC then
                        AH = true
                    end
                    if AH or (os.clock() - iH) >= XG then
                        iH = os.clock()
                        rH:MoveTo(mH or bH)
                    end
                    BB.Heartbeat:Wait()
                end
            end
            local KH = getHumanoidRootPart()
            if KH and (Vector2.new(KH.Position.X, KH.Position.Z) - Vector2.new(bH.X, bH.Z)).Magnitude < JB then
                return true
            end
            return false
        end
        local LH = nil
        local function getGroundRaycastParams()
            local NH = CB.Character
            if not NH then
                return nil
            end
            if not LH then
                LH = RaycastParams.new()
                LH.FilterType = Enum.RaycastFilterType.Exclude
                pcall(function ()
                    LH.RespectCanCollide = true
                end
                )
            end
            LH.FilterDescendantsInstances = {NH}
            return LH
        end
        local function resolveGroundY(PH, QH, RH, SH, TH)
            local UH = getGroundRaycastParams()
            if not UH then
                return SH
            end
            local VH = workspace:Raycast(Vector3.new(RH.X, SH + BC.UP, RH.Z), Vector3.new(0, - BC.DOWN, 0), UH)
            if not VH then
                return SH
            end
            local WH = VH.Position.Y + (PH.Size.Y * 0.5) + QH.HipHeight
            if math.abs(WH - SH) > (TH or BC.MAX_DY) then
                return SH
            end
            return WH
        end
        local XH = {("LastSample"), ("LastGoodSample"), ("LastValidatedSample"), ("LastObservedSample"), ("LastGameplayTrustedSample"), ("LastValidatedGroundedSample"), ("LastConfirmedGroundSample"), ("CandidateGroundedSample"),}
        local YH, ZH = nil, nil
        local aI = 0
        local function canInspectRuntimeConnections()
            return type (getconnections) == ("function") and type (debug) == ("table") and type (debug.info) == ("function") and type (debug.getupvalues) == ("function")
        end
        local function findGroundingController()
            local dI = CB.Character
            if not dI then
                return nil
            end
            if YH and ZH == dI then
                return YH
            end
            YH, ZH = nil, nil
            if (os.clock() - aI) < 2 then
                return nil
            end
            aI = os.clock()
            if not canInspectRuntimeConnections() then
                return nil
            end
            local eI
            pcall(function ()
                for fI, gI in ipairs(getconnections(BB.PostSimulation)) do
                    local hI = gI.Function
                    if type (hI) == ("function") then
                        local iI, jI = pcall(debug.info, hI, ("s"))
                        if iI and type (jI) == ("string") and jI:find(("ContentCatalog.Surface"), 1, true) then
                            local kI, lI = pcall(debug.getupvalues, hI)
                            if kI and type (lI) == ("table") then
                                for mI, nI in pairs(lI) do
                                    if type (nI) == ("table") and rawget(nI, ("HistoryCapacity")) ~= nil and rawget(nI, ("SampleHistory")) ~= nil then
                                        eI = nI
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if eI then
                        break
                    end
                end
            end
            )
            if eI then
                YH, ZH = eI, dI
            end
            return eI
        end
        local function syncGroundingSample(pI, qI)
            if not pI or not qI then
                return
            end
            pcall(function ()
                local rI = qI.CFrame
                local sI = rI.Position
                for tI, uI in ipairs(XH) do
                    local vI = pI [uI]
                    if type (vI) == ("table") then
                        vI.Position = sI;
                        vI.CFrame = rI
                    end
                end
                local wI = pI.SampleHistory
                if type (wI) == ("table") then
                    for xI = 1, (pI.HistoryCapacity or 29) do
                        local yI = wI [xI]
                        if type (yI) == ("table") then
                            yI.Position = sI;
                            yI.CFrame = rI
                        end
                    end
                end
            end
            )
        end
        local function tweenMoveTo(AI, BI, CI, DI, EI)
            local FI = getHumanoidRootPart()
            if not FI then
                return false
            end
            local GI = tonumber(_G [("SAE_TweenSpeed")]) or vC
            if GI < sC then
                GI = sC
            end
            if GI > uC then
                GI = uC
            end
            local HI = os.clock()
            local II = FI.Position.Y
            local JI = os.clock()
            local KI = Vector3.new(AI.X - FI.Position.X, 0, AI.Z - FI.Position.Z)
            if KI.Magnitude > 0.1 then
                KI = KI.Unit
            else
                KI = Vector3.new(1, 0, 0)
            end
            local LI = nil
            local MI = nil
            local NI = 0
            local OI = false
            local PI = 0
            while (BI == nil or BI()) and (os.clock() - HI) < yC do
                if DI and not DI() then
                    return false
                end
                local QI = BB.Heartbeat:Wait()
                local RI = getHumanoidRootPart()
                local SI = CB.Character and CB.Character:FindFirstChildOfClass(("Humanoid"))
                if not RI or not SI then
                    II = nil
                elseif SI.Health <= 0 then
                    return false
                else
                    local TI = RI.Position
                    if II == nil or math.abs(TI.Y - (II + PI)) > BC.MAX_DY then
                        II = TI.Y - PI
                    end
                    local UI = Vector3.new(AI.X - TI.X, 0, AI.Z - TI.Z)
                    local VI = UI.Magnitude
                    if VI < JB then
                        RI.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        SI:MoveTo(TI)
                        return true
                    end
                    if CI and VI <= 35 and CI(VI) then
                        RI.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        SI:MoveTo(TI)
                        return true
                    end
                    local WI = sC * (os.clock() - JI)
                    if LI == nil then
                        LI, JI = VI, os.clock()
                    elseif (LI - VI) >= WI * AC then
                        LI, JI = VI, os.clock()
                    elseif (os.clock() - JI) > zC then
                        return false
                    end
                    local XI = (not EI) and getCachedTreadmillPosition() or nil
                    local YI = false
                    if XI then
                        local ZI, aJ = AI.X - XI.X, AI.Z - XI.Z
                        YI = math.sqrt(ZI * ZI + aJ * aJ) < (WF * aG)
                    end
                    local bJ = false
                    if XI and not YI and not OI then
                        bJ = distancePointToSegment2D(XI, TI, AI) < WF
                    end
                    if MI then
                        local cJ, dJ = MI.X - TI.X, MI.Z - TI.Z
                        if math.sqrt(cJ * cJ + dJ * dJ) <= YF or (not bJ) or (os.clock() - NI) > ZF then
                            MI = nil OI = true
                        end
                    elseif bJ then
                        local eJ, fJ = UI.X / VI, UI.Z / VI
                        local gJ, hJ = - fJ, eJ
                        if ((TI.X - XI.X) * gJ + (TI.Z - XI.Z) * hJ) < 0 then
                            gJ, hJ = - gJ, - hJ
                        end
                        if (gJ * gJ + hJ * hJ) < 0.01 then
                            gJ, hJ = - KI.Z, KI.X
                        end
                        MI = Vector3.new(XI.X + gJ * (WF + XF), TI.Y, XI.Z + hJ * (WF + XF))
                        NI = os.clock()
                    end
                    local iJ = MI or AI
                    local jJ = Vector3.new(iJ.X - TI.X, 0, iJ.Z - TI.Z)
                    local kJ = jJ.Magnitude
                    if kJ > 0.05 then
                        jJ = jJ.Unit
                        local lJ = findGroundingController()
                        local mJ = lJ and GI or math.min(GI, tC)
                        local nJ = math.max(wC, mJ * xC)
                        local oJ = math.min(mJ * QI, kJ, nJ)
                        local pJ = TI + jJ * oJ
                        II = resolveGroundY(RI, SI, pJ, II, math.max(BC.MAX_DY, oJ * 0.5))
                        local qJ = math.max(zG, mJ * AG)
                        local rJ = TI + jJ * math.min(qJ, kJ)
                        local sJ = isPathNearTrap(TI, rJ, zG) and wG or 0
                        local tJ = math.min(xG * QI, yG)
                        if PI < sJ then
                            PI = math.min(sJ, PI + tJ)
                        elseif PI > sJ then
                            PI = math.max(sJ, PI - tJ)
                        end
                        pJ = Vector3.new(pJ.X, II + PI, pJ.Z)
                        RI.CFrame = CFrame.new(pJ, pJ + jJ)
                        if lJ then
                            syncGroundingSample(lJ, RI)
                        end
                        RI.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
            local uJ = getHumanoidRootPart()
            if uJ and (Vector2.new(uJ.Position.X, uJ.Position.Z) - Vector2.new(AI.X, AI.Z)).Magnitude < JB then
                return true
            end
            return false
        end
        getgenv() [("AliceHUB_SAE_MoveTo")] = function (vJ, wJ, xJ, yJ)
            getgenv() [("AliceHUB_SAE_Moving")] = true
            local zJ = walkMoveTo(vJ.Position, wJ, nil, xJ, yJ)
            getgenv() [("AliceHUB_SAE_Moving")] = false
            return zJ
        end
        MovementTurnConfig.lompatKe = function (AJ, BJ, CJ, DJ, EJ)
            local FJ = getHumanoidRootPart()
            if not FJ then
                return false
            end
            local GJ = CFrame.new(AJ)
            local HJ
            if EJ then
                HJ = os.clock() + math.max(math.min(MovementTurnConfig.left(), 1.2), 0.25)
            else
                HJ = os.clock() + 0.35
            end
            local JJ = BB.Heartbeat:Connect(function ()
                local IJ = getHumanoidRootPart()
                if IJ then
                    IJ.CFrame = GJ
                    IJ.AssemblyLinearVelocity = Vector3.zero
                end
            end
            )
            local KJ = false
            while os.clock() < HJ do
                if BJ and not BJ() then
                    break
                end
                if DJ and not DJ() then
                    break
                end
                if EJ and EJ() then
                    KJ = true
                    break
                end
                if CJ and CJ(0) then
                    KJ = true
                    break
                end
                task.wait(0.03)
            end
            JJ:Disconnect()
            local LJ = getHumanoidRootPart()
            if not LJ then
                return false
            end
            if KJ then
                return true
            end
            return (LJ.Position - AJ).Magnitude <= JB
        end
        local function moveToTarget(NJ, OJ, PJ, QJ, RJ)
            getgenv() [("AliceHUB_SAE_Moving")] = true
            local SJ
            if _G [("SAE_InstantTP")] then
                SJ = MovementTurnConfig.lompatKe(NJ, OJ, PJ, QJ, RJ)
            elseif _G [("SAE_TweenMove")] then
                SJ = tweenMoveTo(NJ, OJ, PJ, QJ)
            else
                SJ = walkMoveTo(NJ, OJ, PJ, QJ)
            end
            getgenv() [("AliceHUB_SAE_Moving")] = false
            return SJ
        end
        getgenv() [("AliceHUB_SAE_MoveToFast")] = function (TJ, UJ, VJ)
            if typeof(TJ) == ("CFrame") then
                TJ = TJ.Position
            end
            if typeof(TJ) ~= ("Vector3") then
                return false
            end
            return moveToTarget(TJ, UJ, nil, VJ)
        end
        getgenv() [("AliceHUB_SAE_MoveToTween")] = function (WJ, XJ, YJ, ZJ)
            if typeof(WJ) == ("CFrame") then
                WJ = WJ.Position
            end
            if typeof(WJ) ~= ("Vector3") then
                return false
            end
            if ZJ == nil then
                ZJ = true
            end
            getgenv() [("AliceHUB_SAE_Moving")] = true
            local aK = tweenMoveTo(WJ, XJ, nil, YJ, ZJ)
            getgenv() [("AliceHUB_SAE_Moving")] = false
            return aK
        end
        local function waitHeartbeat(cK, dK)
            local eK = os.clock()
            while (os.clock() - eK) < cK do
                if dK and not dK() then
                    return
                end
                BB.Heartbeat:Wait()
            end
        end
        local fK = nil
        local function getAreaEggCycle()
            if fK then
                return fK
            end
            local hK = zB:FindFirstChild(("Shared"))
            local iK = hK and hK:FindFirstChild(("Util"))
            local jK = iK and iK:FindFirstChild(("AreaEggCycle"))
            if not jK then
                return nil
            end
            local kK, lK = pcall(require, jK)
            if kK and type (lK) == ("table") then
                fK = lK
            end
            return fK
        end
        local function getSecondsUntilEggReset()
            local nK = getAreaEggCycle()
            if not nK or type (nK.SecondsUntilReset) ~= ("function") then
                return nil
            end
            local oK, pK = pcall(function ()
                return workspace:GetServerTimeNow()
            end
            )
            if not oK or type (pK) ~= ("number") then
                return nil
            end
            local qK, rK = pcall(nK.SecondsUntilReset, pK)
            if qK and type (rK) == ("number") then
                return rK
            end
            return nil
        end
        local function isEggResetImminent()
            local tK = getSecondsUntilEggReset()
            if tK == nil then
                return false
            end
            return tK <= 10
        end
        local uK = {}
        local function backoffEggUid(wK, xK)
            if wK == nil then
                return
            end
            local yK = (PB [wK] or 0) + 1
            PB [wK] = yK
            local zK = xK and #OB or math.min(yK, #OB)
            uK [wK] = os.clock() + OB [zK]
        end
        local function clearEggUidBackoff(BK)
            if BK == nil then
                return
            end
            PB [BK] = nil SB [BK] = nil
        end
        local CK, DK = nil, false
        local EK = 3
        local FK = 0
        local GK = 10
        local HK = 30
        local IK = 0
        local function syncFieldEggs(KK)
            if not KK and (os.clock() - IK) < GK then
                return false
            end
            local LK = getCoreEggState()
            if not LK or type (LK.SyncFieldEggs) ~= ("function") then
                return false
            end
            IK = os.clock()
            return (pcall(LK.SyncFieldEggs))
        end
        local MK = {}
        local function markEggObserved(OK)
            if OK ~= nil then
                MK [tostring(OK)] = os.clock()
            end
        end
        -- Rift field eggs use Rift-exclusive AssetCategory values. The field record
        -- itself has no EggSkin field, so build the target set from Data.Rift.Banners.
        local RiftAssetCategories = {}
        do
            local okRift, RiftData = pcall(function ()
                local dataFolder = zB:FindFirstChild(("Data"))
                local riftModule = dataFolder and dataFolder:FindFirstChild(("Rift"))
                return riftModule and require(riftModule) or nil
            end)
            if okRift and type (RiftData) == ("table") and type (RiftData.Banners) == ("table") then
                for _, banner in ipairs(RiftData.Banners) do
                    if type (banner) == ("table") and type (banner.Pets) == ("table") then
                        for _, pet in ipairs(banner.Pets) do
                            if type (pet) == ("table") and type (pet.AssetId) == ("string") then
                                RiftAssetCategories [pet.AssetId] = true
                            end
                        end
                    end
                end
            end
        end
        local function isRiftFieldEggRecord(record)
            return type (record) == ("table")
                and type (record.AssetCategory) == ("string")
                and RiftAssetCategories [record.AssetCategory] == true
        end
        local function getEggCandidates(QK, RK, SK, RiftOnly)
            local TK = nil
            if SK then
                local UK = zB:FindFirstChild(("Shared"))
                local VK = UK and UK:FindFirstChild(("Save"))
                if VK then
                    local WK, XK = pcall(require, VK)
                    if WK and type (XK) == ("table") and type (XK.Get) == ("function") then
                        local YK, ZK = pcall(XK.Get)
                        if YK and type (ZK) == ("table") and type (ZK.Index) == ("table") then
                            TK = ZK.Index
                        end
                    end
                end
            end
            local aL = getCoreEggState()
            if not aL or type (aL.ReadFieldEggs) ~= ("function") then
                return {}
            end
            local bL, cL = pcall(aL.ReadFieldEggs)
            if not bL or type (cL) ~= ("table") then
                return {}
            end
            local dL = cL.Records
            if type (dL) ~= ("table") then
                return {}
            end
            local eL = os.clock()
            local fL = {}
            for gL, hL in pairs(dL) do
                local iL
                if RiftOnly then
                    iL = isRiftFieldEggRecord(hL)
                elseif RK then
                    iL = type (hL) == ("table") and hL.HasParasite == true
                elseif SK then
                    iL = TK ~= nil and type (hL) == ("table") and type (hL.AssetCategory) == ("string") and TK [hL.AssetCategory] ~= true
                else
                    iL = passesEggRarityFilter(hL)
                    if iL and hasStealValueFilter() then
                        iL = passesStealValueFilter(hL)
                    end
                end
                local jL = type (hL) == ("table") and type (hL.Uid) == ("string") and hC [hL.State] and typeof(hL.BottomCFrame) == ("CFrame") and iL
                if jL then
                    local kL = SB [hL.Uid]
                    local lL = (kL ~= nil) and (eL < kL)
                    local mL = uK [hL.Uid]
                    if lL or not mL or eL >= mL then
                        local nL = hL.BottomCFrame.Position
                        local oL = 1
                        if looksLikeFirstAreaEggUid(hL.Uid) then
                            oL = isOwnFirstAreaEgg(hL.Uid) and 0 or 2
                        end
                        local pL
                        if hasStealValueFilter() then
                            pL = getEggMoneyPerSecond(hL) or 0
                        else
                            pL = JE [getEggRarity(hL.AssetCategory)] or 0
                        end
                        fL [#fL + 1] = {rec = hL, pos = nL, area = hL.AreaId, dist = (nL - QK).Magnitude, first = (oL == 0), rank = oL, rarityRank = pL, sejakArea = MK [tostring(hL.AreaId)] or 0, rebut = lL and 1 or 0,}
                    end
                end
            end
            table.sort(fL, function (qL, rL)
                if qL.rebut ~= rL.rebut then
                    return qL.rebut > rL.rebut
                end
                if qL.rank ~= rL.rank then
                    return qL.rank < rL.rank
                end
                if qL.rarityRank ~= rL.rarityRank then
                    return qL.rarityRank > rL.rarityRank
                end
                if qL.dist ~= rL.dist then
                    return qL.dist < rL.dist
                end
                return qL.sejakArea < rL.sejakArea
            end
            )
            return fL
        end
        local function readFieldEggByUid(tL)
            local uL = getCoreEggState()
            if not uL then
                return nil
            end
            if type (uL.ReadFieldEgg) == ("function") then
                local vL, wL = pcall(uL.ReadFieldEgg, tL)
                if vL then
                    return (type (wL) == ("table")) and wL or nil
                end
            end
            if type (uL.ReadFieldEggs) ~= ("function") then
                return nil
            end
            local xL, yL = pcall(uL.ReadFieldEggs)
            if not xL or type (yL) ~= ("table") or type (yL.Records) ~= ("table") then
                return nil
            end
            for zL, AL in pairs(yL.Records) do
                if type (AL) == ("table") and AL.Uid == tL then
                    return AL
                end
            end
            return nil
        end
        local function isFieldEggCarryable(CL)
            local DL = getCoreEggState()
            if not DL or type (DL.ReadFieldEggs) ~= ("function") then
                return false
            end
            local EL, FL = pcall(DL.ReadFieldEggs)
            if not EL or type (FL) ~= ("table") then
                return false
            end
            local GL = FL.Records
            if type (GL) ~= ("table") then
                return false
            end
            for HL, IL in pairs(GL) do
                if type (IL) == ("table") and IL.Uid == CL then
                    return hC [IL.State] and true or false
                end
            end
            return false
        end
        local function dropCarriedFieldEgg()
            local KL = getCoreEggState()
            if not KL or type (KL.DropFieldEgg) ~= ("function") then
                return false
            end
            pcall(KL.DropFieldEgg)
            local LL = os.clock()
            while dF and (os.clock() - LL) < 1.5 do
                BB.Heartbeat:Wait()
            end
            if not dF then
                return true
            end
            dF, eF, fF = false, nil, nil
            return false
        end
        local function ensureNotCarryingFieldEgg(NL)
            local OL = os.clock()
            while dF and NL() and (os.clock() - OL) < UB do
                if fF and (os.clock() - fF) > TB then
                    dropCarriedFieldEgg()
                    break
                end
                BB.Heartbeat:Wait()
            end
            if dF then
                dropCarriedFieldEgg()
            end
            return not dF
        end
        local function waitForCarriedEggUid(QL, RL, SL)
            local TL = os.clock()
            while RL() and (os.clock() - TL) < SL do
                if dF and eF == QL then
                    return true
                end
                BB.Heartbeat:Wait()
            end
            return dF and eF == QL
        end
        local function isNearPosition(VL, WL)
            local XL = getHumanoidRootPart()
            if not XL or not VL then
                return false
            end
            return (XL.Position - VL).Magnitude <= (WL or bC)
        end
        local function isNearHomePlot()
            return isNearPosition(KB.Position)
        end
        local ZL = 2
        local function moveToWithRetries(bM, cM, dM, eM)
            if not bM then
                return false
            end
            for fM = 1, ZL do
                if isNearPosition(bM, eM) then
                    return true
                end
                if cM and not cM() then
                    break
                end
                moveToTarget(bM, cM, nil, dM)
            end
            return isNearPosition(bM, eM)
        end
        MovementTurnConfig.arm = function (gM, hM)
            local iM = getCoreEggState()
            if not iM or type (iM.CarryFieldEgg) ~= ("function") then
                return false
            end
            pcall(MovementTurnConfig.siapkan)
            local jM = CB.Character and CB.Character:FindFirstChildOfClass(("Humanoid"))
            local kM = jM and jM.WalkSpeed or nil
            local function restoreWalkSpeed()
                local mM = CB.Character and CB.Character:FindFirstChildOfClass(("Humanoid"))
                if mM and kM then
                    mM.WalkSpeed = kM
                end
            end
            for nM = 1, 6 do
                local oM = false
                local pM, qM = pcall(iM.ReadFieldEggs)
                if pM and type (qM) == ("table") and type (qM.Records) == ("table") then
                    for rM, sM in pairs(qM.Records) do
                        if type (sM) == ("table") and sM.State == ("Carried") and sM.CarrierUserId == CB.UserId then
                            oM = true
                            break
                        end
                    end
                end
                if not oM then
                    break
                end
                dropCarriedFieldEgg()
                if not waitHeartbeat(0.35, gM) then
                    restoreWalkSpeed()
                    return false
                end
            end
            pcall(function ()
                local tM = CB.Character
                local uM = zB:FindFirstChild(("Shared"))
                uM = uM and uM:FindFirstChild(("Modules"))
                uM = uM and uM:FindFirstChild(("Ragdoll"))
                if tM and uM then
                    local vM, wM = pcall(require, uM)
                    if vM and type (wM) == ("table") then
                        if type (wM.ClearClientRagdoll) == ("function") then
                            pcall(wM.ClearClientRagdoll, tM)
                        end
                        if type (wM.Unragdoll) == ("function") then
                            pcall(wM.Unragdoll, tM)
                        end
                    end
                end
                local xM = tM and tM:FindFirstChildOfClass(("Humanoid"))
                if xM then
                    xM.PlatformStand = false xM.Sit = false pcall(function ()
                        xM:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                    )
                end
            end
            )
            if not waitHeartbeat(0.35, gM) then
                restoreWalkSpeed()
                return false
            end
            local yM = CB.Character and CB.Character:FindFirstChildOfClass(("Humanoid"))
            if yM then
                yM.WalkSpeed = MovementTurnConfig.wsUmpan
            end
            local zM = os.clock()
            while (os.clock() - zM) < (MovementTurnConfig.armWait * 3) do
                if gM and not gM() then
                    restoreWalkSpeed()
                    return false
                end
                if hM and not hM() then
                    restoreWalkSpeed()
                    return false
                end
                local AM, BM = pcall(iM.ReadFieldEggs)
                local CM = AM and type (BM) == ("table") and BM.Records or nil
                local DM = {}
                if type (CM) == ("table") then
                    local EM = {("Forest"), ("Desert"), ("Snow")}
                    local FM = {}
                    for GM, HM in ipairs(EM) do
                        FM [HM] = GM
                    end
                    for IM, JM in pairs(CM) do
                        if type (JM) == ("table") and type (JM.Uid) == ("string") and hC [JM.State] and typeof(JM.BottomCFrame) == ("CFrame") then
                            local KM
                            if isOwnFirstAreaEgg(JM.Uid) then
                                KM = 0
                            elseif not looksLikeFirstAreaEggUid(JM.Uid) then
                                KM = FM [JM.AreaId]
                            end
                            if KM then
                                DM [#DM + 1] = {rec = JM, r = KM}
                            end
                        end
                    end
                    table.sort(DM, function (LM, MM)
                        return LM.r < MM.r
                    end
                    )
                    for NM, OM in ipairs(DM) do
                        DM [NM] = OM.rec
                    end
                end
                if #DM == 0 then
                    if not waitHeartbeat(0.8, gM) then
                        restoreWalkSpeed()
                        return false
                    end
                else
                    for PM, QM in ipairs(DM) do
                        if gM and not gM() then
                            restoreWalkSpeed()
                            return false
                        end
                        if MovementTurnConfig.left() > 0.15 then
                            restoreWalkSpeed()
                            return true
                        end
                        local RM = QM.BottomCFrame.Position
                        local SM = getAreaEggSlotKey(QM)
                        local TM = QM.Uid
                        MovementTurnConfig.lompatKe(KB.Position, gM, nil, hM)
                        local UM = false
                        local VM = CFrame.new(RM)
                        local XM = BB.Heartbeat:Connect(function ()
                            local WM = getHumanoidRootPart()
                            if WM then
                                WM.CFrame = VM
                                WM.AssemblyLinearVelocity = Vector3.zero
                            end
                        end
                        )
                        local YM = os.clock()
                        while (os.clock() - YM) < 1.2 do
                            if gM and not gM() then
                                break
                            end
                            local ZM, aN = pcall(iM.CarryFieldEgg, TM, SM)
                            if ZM and aN == true then
                                UM = true
                                break
                            end
                            task.wait(0.03)
                        end
                        XM:Disconnect()
                        if gM and not gM() then
                            restoreWalkSpeed()
                            return false
                        end
                        if UM then
                            local bN = CFrame.new(getHumanoidRootPart() and getHumanoidRootPart().Position or RM)
                            local dN = BB.Heartbeat:Connect(function ()
                                local cN = getHumanoidRootPart()
                                if cN then
                                    cN.CFrame = bN
                                    cN.AssemblyLinearVelocity = Vector3.zero
                                end
                            end
                            )
                            local eN = os.clock()
                            while (os.clock() - eN) < MovementTurnConfig.armWait do
                                if gM and not gM() then
                                    dN:Disconnect()
                                    dropCarriedFieldEgg()
                                    restoreWalkSpeed()
                                    return false
                                end
                                if MovementTurnConfig.left() > 0.15 then
                                    dN:Disconnect()
                                    dropCarriedFieldEgg()
                                    restoreWalkSpeed()
                                    return true
                                end
                                task.wait(0.05)
                            end
                            dN:Disconnect()
                            dropCarriedFieldEgg()
                        end
                    end
                end
            end
            restoreWalkSpeed()
            return false
        end
        local function claimFieldEgg(gN, hN, iN, jN, kN)
            kN = kN or KB.Position
            local lN = getCoreEggState()
            if not lN or type (lN.CarryFieldEgg) ~= ("function") then
                return ("failed")
            end
            local function keepClaimTurnAlive()
                if jN == nil then
                    return true
                end
                local nN = getgenv() [("AliceHUB_SAE_Turn")]
                if type (nN) ~= ("table") then
                    return true
                end
                if type (nN.keep) == ("function") then
                    pcall(nN.keep, jN)
                end
                if type (nN.state) == ("function") then
                    local oN, pN = pcall(nN.state)
                    if oN and type (pN) == ("table") and pN.token ~= jN then
                        return false
                    end
                end
                return true
            end
            if not ensureNotCarryingFieldEgg(iN) then
                return ("busy")
            end
            if not iN() then
                return ("failed")
            end
            local qN = kN
            local rN = os.clock()
            local sN = function ()
                return iN() and (os.clock() - rN) < cC
            end
            if not moveToWithRetries(qN, sN, keepClaimTurnAlive) then
                backoffEggUid(gN.rec.Uid)
                return ("offzone")
            end
            tF = false
            if _G [("SAE_InstantTP")] and MovementTurnConfig.left() <= 0.15 then
                MovementTurnConfig.arm(iN, keepClaimTurnAlive)
            end
            local tN = gN.rec.Uid
            local function claimEggStillCarryable()
                return isFieldEggCarryable(tN)
            end
            local vN = os.clock()
            local function claimAttemptTimedOut()
                return (os.clock() - vN) > GB
            end
            local function canContinueClaimAttempt()
                return iN() and claimEggStillCarryable() and not claimAttemptTimedOut()
            end
            if not claimEggStillCarryable() then
                return ("gone")
            end
            local yN = gN.pos
            local zN = 0
            local AN = false
            local BN = 0
            local CN = 0
            local DN = false
            local EN = getAreaEggSlotKey(gN.rec)
            local function attemptCarryFieldEgg(GN)
                if not claimEggStillCarryable() then
                    return true
                end
                if (os.clock() - BN) < EB then
                    return false
                end
                BN = os.clock()
                zN = zN + 1
                local HN, IN = pcall(lN.CarryFieldEgg, tN, EN)
                if HN and IN == true then
                    AN = true
                    return true
                end
                CN = CN + 1
                if CN >= FB then
                    DN = true
                    return true
                end
                return false
            end
            for JN = 1, HB do
                if AN or claimAttemptTimedOut() or not iN() then
                    break
                end
                if JN > 1 then
                    if _G [("SAE_InstantTP")] then
                        MovementTurnConfig.arm(canContinueClaimAttempt, keepClaimTurnAlive)
                    else
                        local KN = getHumanoidRootPart()
                        if KN then
                            local LN = KN.Position - yN
                            LN = Vector3.new(LN.X, 0, LN.Z)
                            local MN = (LN.Magnitude > 0.1) and LN.Unit or Vector3.new(1, 0, 0)
                            moveToTarget(yN + MN * IB, canContinueClaimAttempt, nil, keepClaimTurnAlive)
                        end
                    end
                    if AN or claimAttemptTimedOut() or not iN() then
                        break
                    end
                    if not claimEggStillCarryable() then
                        break
                    end
                end
                CN, DN = 0, false
                local NN = 0
                local function attemptCarryFieldEggFallback()
                    if not claimEggStillCarryable() then
                        return true
                    end
                    zN = zN + 1
                    local PN, QN = pcall(lN.CarryFieldEgg, tN, EN)
                    if PN and QN == true then
                        AN = true
                        return true
                    end
                    NN = NN + 1
                    if NN >= MovementTurnConfig.rejectMax then
                        return true
                    end
                    return false
                end
                moveToTarget(yN, canContinueClaimAttempt, attemptCarryFieldEgg, keepClaimTurnAlive, attemptCarryFieldEggFallback)
                if not iN() then
                    return ("failed")
                end
                if AN then
                    break
                end
                if not claimEggStillCarryable() then
                    break
                end
                local RN = _G [("SAE_InstantTP")] and MovementTurnConfig.rejectMax or DB
                for SN = 1, RN do
                    if not iN() or claimAttemptTimedOut() then
                        break
                    end
                    if not claimEggStillCarryable() then
                        break
                    end
                    local TN, UN, VN = pcall(lN.CarryFieldEgg, tN, EN)
                    zN = zN + 1
                    if TN and UN == true then
                        AN = true
                        break
                    end
                    local WN = tostring(VN)
                    if WN:find(("not found")) then
                        return ("gone")
                    end
                    if WN:find(("carrying")) then
                        dropCarriedFieldEgg()
                        return ("busy")
                    end
                    if SN < RN then
                        waitHeartbeat(_G [("SAE_InstantTP")] and 0.03 or EB, iN)
                    end
                end
            end
            if not iN() then
                return ("failed")
            end
            local XN = CB.Character and CB.Character:FindFirstChildOfClass(("Humanoid"))
            if not AN and (not XN or XN.Health <= 0) then
                return ("failed")
            end
            if not AN and not claimEggStillCarryable() then
                return ("gone")
            end
            if not AN then
                backoffEggUid(gN.rec.Uid, claimAttemptTimedOut())
                moveToWithRetries(qN, iN, keepClaimTurnAlive)
                return ("unreachable")
            end
            local YN = LB.Position
            local ZN = os.clock()
            local aO = ("dapat")
            local bO = os.clock()
            local function setCarryAttemptState(dO)
                if dO ~= aO then
                    aO, bO = dO, os.clock()
                end
            end
            local eO = true task.spawn(function ()
                while eO and iN() do
                    local fO, gO, hO = pcall(lN.CarryFieldEgg, tN, EN)
                    if fO then
                        if gO == true then
                            setCarryAttemptState(("dapat"))
                        else
                            local iO = tostring(hO or (""))
                            if iO:find(("carrying")) then
                                setCarryAttemptState(("sudah"))
                            elseif iO:find(("not found")) then
                                setCarryAttemptState(("hilang"))
                            else
                                setCarryAttemptState(("gagal"))
                            end
                        end
                    end
                    task.wait(gC)
                end
            end
            )
            local jO, kO = nil, 0
            local function readClaimEggCached()
                if (os.clock() - kO) > 0.10 then
                    jO, kO = readFieldEggByUid(tN), os.clock()
                end
                return jO
            end
            local function carryRequestReportedSuccess()
                return aO == ("dapat") or aO == ("sudah")
            end
            local function isClaimEggCarried()
                local oO = readClaimEggCached()
                if oO ~= nil then
                    if iC [oO.State] then
                        return true
                    end
                    return carryRequestReportedSuccess() and (os.clock() - bO) < mC
                end
                if carryRequestReportedSuccess() then
                    return true
                end
                return dF
            end
            local function isClaimEggDropped()
                local qO = readClaimEggCached()
                if qO == nil or not hC [qO.State] then
                    return false
                end
                return not isClaimEggCarried()
            end
            local function isClaimEggGuardCarried()
                local sO = readClaimEggCached()
                return (sO ~= nil and jC [sO.State]) and true or false
            end
            local tO = 0
            local function dropStaleClaimCarry()
                if aO ~= ("sudah") then
                    return
                end
                if (os.clock() - bO) < nC then
                    return
                end
                if (os.clock() - tO) < oC then
                    return
                end
                local vO = readClaimEggCached()
                if vO == nil or not hC [vO.State] then
                    return
                end
                tO = os.clock()
                dropCarriedFieldEgg()
            end
            local function isReturnWindowActive()
                return (os.clock() - ZN) < fC
            end
            local function retryCarryDuringReturn()
                if isClaimEggCarried() then
                    return true
                end
                if (os.clock() - BN) < EB then
                    return false
                end
                BN = os.clock()
                zN = zN + 1
                pcall(lN.CarryFieldEgg, tN, EN)
                return false
            end
            local yO = false
            local zO = false
            local AO = nil
            while iN() and (os.clock() - ZN) < fC do
                local BO = readClaimEggCached()
                if BO == nil then
                    break
                end
                if kC [BO.State] then
                    break
                end
                if isClaimEggGuardCarried() then
                    AO = AO or os.clock()
                    if (os.clock() - AO) > lC then
                        break
                    end
                    BB.Heartbeat:Wait()
                elseif isClaimEggCarried() then
                    AO = nil
                    local CO = function ()
                        return iN() and isReturnWindowActive() and isClaimEggCarried() and (readClaimEggCached() ~= nil)
                    end
                    moveToWithRetries(qN, CO, keepClaimTurnAlive)
                    yO = CO() and moveToWithRetries(YN, CO, keepClaimTurnAlive) or false
                    local DO = os.clock()
                    while iN() and (readClaimEggCached() ~= nil) and isClaimEggCarried() and (os.clock() - DO) < dC do
                        BB.Heartbeat:Wait()
                    end
                elseif isClaimEggDropped() then
                    zO = true AO = nil dropStaleClaimCarry()
                    local EO = readClaimEggCached()
                    local FO = (EO and typeof(EO.BottomCFrame) == ("CFrame")) and EO.BottomCFrame.Position or nil
                    if not FO then
                        break
                    end
                    moveToTarget(FO, function ()
                        return iN() and isReturnWindowActive() and (not isClaimEggCarried()) and isClaimEggDropped()
                    end
                    , retryCarryDuringReturn, keepClaimTurnAlive)
                    local GO = os.clock()
                    while iN() and (not isClaimEggCarried()) and isClaimEggDropped() and (os.clock() - GO) < eC do
                        BB.Heartbeat:Wait()
                    end
                else
                    BB.Heartbeat:Wait()
                end
            end
            eO = false
            local HO = readFieldEggByUid(gN.rec.Uid)
            if HO == nil then
                task.wait(0.20)
                HO = readFieldEggByUid(gN.rec.Uid)
            end
            if HO == nil then
                gF [gN.rec.Uid] = nil clearEggUidBackoff(gN.rec.Uid)
                recordEggCollected(gN.rec)
                return ("claimed")
            end
            if kC [HO.State] then
                backoffEggUid(gN.rec.Uid)
                return ("stranded")
            end
            if not hC [HO.State] then
                backoffEggUid(gN.rec.Uid)
                return ("stranded")
            end
            local IO = gN.rec.Uid
            gF [IO] = nil
            local JO = (PB [IO] or 0) + 1
            PB [IO] = JO
            if JO <= RB then
                SB [IO] = os.clock() + QB
                uK [IO] = nil
            else
                SB [IO] = nil uK [IO] = os.clock() + OB [math.min(JO, #OB)]
            end
            if zO then
                OE.dropped = OE.dropped + 1
                return ("dropped")
            end
            if not yO then
                return ("stranded")
            end
            return ("unreachable")
        end
        local KO = getgenv() [("AliceHUB_SAE_Turn")]
        if type (KO) ~= ("table") then
            local LO = game:GetService(("RunService"))
            local MO = 4.0
            local NO = 18.0
            local OO = 12.0
            local PO = {holder = nil, token = nil, took = 0, alive = 0, seq = 0, nextNo = 1, queue = {}, sejak = {}}
            local function clearFarmTurnLock()
                PO.holder, PO.token = nil, nil
            end
            local function removeFarmTurnQueueEntry(SO)
                for TO, UO in ipairs(PO.queue) do
                    if UO == SO then
                        table.remove(PO.queue, TO)
                        PO.sejak [SO] = nil
                        return
                    end
                end
            end
            KO = {}
            function KO.take(VO, WO)
                local XO = PO.nextNo
                PO.nextNo = PO.nextNo + 1
                local YO = #PO.queue + 1
                if VO == ("steal-egg") and #PO.queue > 0 then
                    local ZO = PO.queue [1]
                    local aP = os.clock() - (PO.sejak [ZO] or os.clock())
                    if aP < OO then
                        YO = 1
                    end
                end
                table.insert(PO.queue, YO, XO)
                PO.sejak [XO] = os.clock()
                local bP = os.clock() + (WO or 15)
                while true do
                    if PO.holder ~= nil and (os.clock() - PO.alive) > NO then
                        clearFarmTurnLock()
                    end
                    if PO.holder == nil and PO.queue [1] == XO then
                        table.remove(PO.queue, 1)
                        PO.sejak [XO] = nil PO.seq = PO.seq + 1
                        PO.holder, PO.token = VO, PO.seq
                        PO.took, PO.alive = os.clock(), os.clock()
                        return PO.seq
                    end
                    if os.clock() >= bP then
                        removeFarmTurnQueueEntry(XO)
                        return nil
                    end
                    LO.Heartbeat:Wait()
                end
            end
            function KO.keep(cP)
                if cP == nil or PO.token ~= cP then
                    return false
                end
                PO.alive = os.clock()
                if #PO.queue > 0 and (os.clock() - PO.took) >= MO then
                    return false
                end
                if #PO.queue > 0 and (os.clock() - PO.took) >= NO then
                    return false
                end
                return true
            end
            function KO.give(dP)
                if dP ~= nil and PO.token == dP then
                    clearFarmTurnLock()
                end
            end
            function KO.state()
                return PO
            end
            getgenv() [("AliceHUB_SAE_Turn")] = KO
        end
        _G [("SAE_FarmEgg")] = _G [("SAE_FarmEgg")] or false getgenv() [("AliceHUB_SAE_FarmEggBusy")] = getgenv() [("AliceHUB_SAE_FarmEggBusy")] or false
        local eP = 3
        local fP = 45.0
        local gP = 0
        local hP = nil
        local iP = nil
        local jP = false
        local kP = nil
        -- ============================================================
        -- Farm Egg / AA Farm / Steal Parasite / Complete Index
        -- ============================================================
        local function getSaveData()
            if kP == nil then
                local mP = zB:FindFirstChild(("Shared"))
                local nP = mP and mP:FindFirstChild(("Save"))
                kP = (nP and select(2, pcall(require, nP))) or false
            end
            local oP = kP or nil
            if not oP or type (oP.Get) ~= ("function") then
                return nil
            end
            local pP, qP = pcall(oP.Get)
            if pP and type (qP) == ("table") then
                return qP
            end
            return nil
        end
        local function getEggInventoryCount()
            local sP = getSaveData()
            local tP = 0
            if type (sP) == ("table") and type (sP.EggInventory) == ("table") then
                for uP in pairs(sP.EggInventory) do
                    tP = tP + 1
                end
            end
            return tP
        end
        local function shouldPauseForFullEggInventory()
            if gP < eP then
                return false
            end
            local wP = getEggInventoryCount()
            if hP == nil then
                hP = os.clock()
                iP = wP
            end
            if wP < iP then
                gP, hP, iP, jP = 0, nil, nil, false
                return false
            end
            if (os.clock() - hP) >= fP then
                gP, hP, iP, jP = 0, nil, nil, false
                return false
            end
            if not jP then
                jP = true pcall(function ()
                    xB:Notify({Title = ("Farm Egg"), Content = ("Egg inventory looks full — pausing so Auto Sell Egg can catch up."), Duration = 8,})
                end
                )
            end
            getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] = true
            return true
        end
        local function isFarmEggEnabled()
            return _G [("SAE_FarmEgg")] and true or false
        end
        _G [("SAE_AAFarmEgg")] = _G [("SAE_AAFarmEgg")] or false
        local function isAAFarmEggEnabled()
            return _G [("SAE_AAFarmEgg")] and true or false
        end
        _G [("SAE_StealParasite")] = _G [("SAE_StealParasite")] or false
        _G [("SAE_TakeRiftEgg")] = _G [("SAE_TakeRiftEgg")] or false
        local function isTakeRiftEggEnabled()
            return _G [("SAE_TakeRiftEgg")] and true or false
        end
        local function feedClaimedEggToParasite(AP)
            if type (AP) ~= ("table") or type (AP.Uid) ~= ("string") then
                return
            end
            local BP = nil do
                local CP = zB:FindFirstChild(("Shared"))
                local DP = CP and CP:FindFirstChild(("Remotes"))
                if DP then
                    local EP, FP = pcall(require, DP)
                    if EP and type (FP) == ("table") and FP.MonsterParasite then
                        BP = FP.MonsterParasite
                    end
                end
            end
            if not BP or not BP.AskFeed then
                pcall(function ()
                    xB:Notify({Title = ("Steal Parasite Egg"), Content = ("Remotes.MonsterParasite.AskFeed not available."), Duration = 5})
                end
                )
                return
            end
            local GP = getgenv() [("AliceHUB_SAE_Turn")]
            local HP = nil
            if type (GP) == ("table") and type (GP.take) == ("function") then
                HP = GP.take(("steal-parasite-feed"), 10)
            end
            local function keepParasiteTurnAlive()
                if HP == nil or type (GP) ~= ("table") then
                    return true
                end
                if type (GP.keep) == ("function") then
                    pcall(GP.keep, HP)
                end
                return true
            end
            local function moveToParasiteCheckpoint()
                return moveToWithRetries(NB.Position, function ()
                    return true
                end
                , keepParasiteTurnAlive, 2)
            end
            if not moveToParasiteCheckpoint() then
                if HP and type (GP.give) == ("function") then
                    pcall(GP.give, HP)
                end
                pcall(function ()
                    xB:Notify({Title = ("Steal Parasite Egg"), Content = ("Could not reach the monster checkpoint."), Duration = 5})
                end
                )
                return
            end
            local KP = 8
            local LP = 3
            local MP = 0.15
            local NP, OP = false, nil
            for PP = 1, LP do
                for QP = 1, KP do
                    NP, OP = pcall(BP.AskFeed.InvokeServer, BP.AskFeed)
                    if NP and type (OP) == ("table") and OP.Success == true then
                        break
                    end
                    if QP < KP then
                        task.wait(MP)
                    end
                end
                if NP and type (OP) == ("table") and OP.Success == true then
                    break
                end
                local RP = NP and type (OP) == ("table") and type (OP.Message) == ("string") and OP.Message:lower():find(("closer"))
                if PP < LP and RP then
                    moveToParasiteCheckpoint()
                end
            end
            if not (NP and type (OP) == ("table") and OP.Success == true) then
                pcall(function ()
                    local SP = (NP and type (OP) == ("table") and OP.Message) or tostring(OP)
                    xB:Notify({Title = ("Steal Parasite Egg"), Content = ("Feed failed: ") .. tostring(SP), Duration = 6})
                end
                )
            end
            if HP and type (GP.give) == ("function") then
                pcall(GP.give, HP)
            end
        end
        local TP = 0
        local UP = false
        local VP = nil
        local function startFarmWorker(XP, YP, ZP, aQ)
            XP = XP or isFarmEggEnabled
            YP = YP or KB.Position
            ZP = ZP or ("Farm Egg")
            aQ = aQ or {}
            TP = TP + 1
            UP = true VP = ZP
            local bQ = TP
            local function farmWorkerStillValid()
                return XP() and TP == bQ
            end
            local function finishFarmWorker()
                if TP == bQ then
                    UP = false
                    if VP == ZP then
                        VP = nil
                    end
                    setTemporaryGodmode(false)
                    getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] = false
                end
            end
            local eQ = YP
            task.spawn(function ()
                local fQ = os.clock() + 30
                while farmWorkerStillValid() and not getHumanoidRootPart() and os.clock() < fQ do
                    BB.Heartbeat:Wait()
                end
                if not farmWorkerStillValid() then
                    finishFarmWorker()
                    return
                end
                if not getHumanoidRootPart() then
                    finishFarmWorker()
                    xB:Notify({Title = ZP, Content = ("Character not ready, try again."), Duration = 3})
                    return
                end
                setTemporaryGodmode(true)
                installAntiRagdoll()
                syncFieldEggs(true)
                local gQ, hQ = nil, 0
                local function notifyFarmWorkerFailure(jQ)
                    local kQ = tostring(jQ)
                    if kQ == gQ and (os.clock() - hQ) < 20 then
                        return
                    end
                    gQ, hQ = kQ, os.clock()
                    pcall(function ()
                        xB:Notify({Title = ZP, Content = ("Putaran gagal: ") .. kQ, Duration = 8,})
                    end
                    )
                end
                local lQ = false
                local mQ = os.clock()
                while farmWorkerStillValid() do
                    local QQ, RQ = pcall(function ()
                        if (os.clock() - mQ) >= HK then
                            mQ = os.clock()
                            syncFieldEggs(true)
                        end
                        local nQ = WB
                        local oQ = getSecondsUntilEggReset()
                        local pQ = (oQ ~= nil) and (oQ <= 10) or false
                        if pQ then
                            lQ = true nQ = aC
                        elseif oQ ~= nil and oQ <= ZB then
                            nQ = math.min(oQ, aC)
                        else
                            if lQ then
                                lQ = false uK = {}
                                gF = {}
                                PB = {}
                                SB = {}
                                if dF and fF and (os.clock() - fF) > TB then
                                    dF, eF, fF = false, nil, nil
                                end
                                syncFieldEggs(true)
                            end
                            local qQ = false
                            if aQ.indexOnly then
                                local rQ = getgenv() [("AliceHUB_SAE_ReadOwnedEggUids")]
                                local sQ = getgenv() [("AliceHUB_SAE_HatchEggUid")]
                                if type (rQ) == ("function") and type (sQ) == ("function") then
                                    local tQ, uQ = pcall(rQ)
                                    if tQ and type (uQ) == ("table") then
                                        local vQ = nil
                                        local wQ = zB:FindFirstChild(("Shared"))
                                        local xQ = wQ and wQ:FindFirstChild(("Save"))
                                        if xQ then
                                            local yQ, zQ = pcall(require, xQ)
                                            if yQ and type (zQ) == ("table") and type (zQ.Get) == ("function") then
                                                local AQ, BQ = pcall(zQ.Get)
                                                if AQ and type (BQ) == ("table") and type (BQ.Index) == ("table") then
                                                    vQ = BQ.Index
                                                end
                                            end
                                        end
                                        if vQ then
                                            for CQ, DQ in ipairs(uQ) do
                                                if DQ.ready and type (DQ.cat) == ("string") and vQ [DQ.cat] ~= true then
                                                    local EQ, FQ = pcall(sQ, DQ.uid, farmWorkerStillValid)
                                                    if EQ and FQ then
                                                        qQ = true
                                                        local GQ = getgenv() [("AliceHUB_SAE_ShowIndexToast")]
                                                        if type (GQ) == ("function") then
                                                            pcall(GQ)
                                                        end
                                                    end
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            local HQ = shouldPauseForFullEggInventory()
                            local IQ = qQ and nil or (HQ and nil or getEggCandidates(eQ, aQ.parasiteOnly, aQ.indexOnly, aQ.riftOnly) [1])
                            if qQ then
                            elseif not IQ then
                                if not HQ then
                                    if CK == nil then
                                        CK = os.clock()
                                    end
                                    if not DK and (os.clock() - CK) > 30 then
                                        DK = true pcall(function ()
                                            xB:Notify({Title = ZP, Content = ("No egg is reachable right now — waiting for the next reset."), Duration = 8,})
                                        end
                                        )
                                    end
                                    FK = FK + 1
                                    if FK >= EK then
                                        getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] = false
                                    end
                                end
                                nQ = _G [("SAE_AutoTreadmill")] and 0.15 or VB
                            else
                                FK = 0
                                getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] = true
                                local JQ = getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] or getgenv() [("AliceHUB_SAE_EquipBestBusy")]
                                if JQ then
                                    nQ = YB
                                else
                                    local KQ = KO.take(("steal-egg"), 10)
                                    if not KQ then
                                        nQ = YB
                                    else
                                        markEggObserved(IQ.area)
                                        getgenv() [("AliceHUB_SAE_FarmEggBusy")] = true
                                        local LQ = getEggInventoryCount()
                                        local MQ = claimFieldEgg(IQ, eQ, farmWorkerStillValid, KQ, YP)
                                        getgenv() [("AliceHUB_SAE_FarmEggBusy")] = false KO.give(KQ)
                                        if MQ == ("claimed") then
                                            -- Farm -> Place -> Hatch -> Treadmill.  This grace window lets
                                            -- the Place/Hatch worker notice the newly claimed egg first.
                                            getgenv() [("AliceHUB_SAE_EggPipelineHoldUntil")] = os.clock() + (_G [("SAE_AutoPlaceHatch")] and 0.85 or 0.20)
                                        end
                                        if MQ == ("claimed") and type (aQ.onClaimed) == ("function") then
                                            local NQ, OQ = pcall(aQ.onClaimed, IQ.rec)
                                            if not NQ then
                                                notifyFarmWorkerFailure(("Steal Parasite Egg: ") .. tostring(OQ))
                                            end
                                        end
                                        if getEggInventoryCount() > LQ then
                                            gP = 0
                                        elseif MQ == ("claimed") or MQ == ("unreachable") or MQ == ("stranded") then
                                            gP = gP + 1
                                        end
                                        if MQ == ("offzone") then
                                            nQ = YB
                                        elseif MQ == ("dropped") then
                                            nQ = rC
                                        elseif MQ == ("busy") or MQ == ("stranded") then
                                            nQ = XB
                                        elseif MQ == ("gone") then
                                            syncFieldEggs(false)
                                        else
                                            nQ = qC
                                        end
                                    end
                                end
                            end
                        end
                        local PQ = os.clock()
                        while farmWorkerStillValid() and (os.clock() - PQ) < nQ do
                            BB.Heartbeat:Wait()
                        end
                    end
                    )
                    if not QQ then
                        notifyFarmWorkerFailure(RQ)
                        local SQ = os.clock()
                        while farmWorkerStillValid() and (os.clock() - SQ) < 1.0 do
                            BB.Heartbeat:Wait()
                        end
                    end
                end
                finishFarmWorker()
            end
            )
        end
        local function setFlagAndFire(UQ, VQ)
            pcall(function ()
                local WQ = getgenv() [("AliceHUB_Flags")]
                local XQ = WQ and WQ [UQ]
                if XQ and type (XQ.SetAndFire) == ("function") then
                    XQ:SetAndFire(VQ)
                end
            end
            )
        end
        local function startExclusiveFarmMode(ZQ, aR, bR, cR, dR)
            if not ZQ() then
                if VP == bR then
                    TP = TP + 1
                    UP = false
                end
                return
            end
            if UP and not cR then
                return
            end
            startFarmWorker(ZQ, aR, bR, dR)
        end
        local function startFarmEgg(fR)
            startExclusiveFarmMode(isFarmEggEnabled, KB.Position, ("Farm Egg"), fR)
        end
        local function startAAFarmEgg(hR)
            startExclusiveFarmMode(isAAFarmEggEnabled, MB.Position, ("AA Farm Egg"), hR)
        end
        local function startStealParasiteEgg(jR)
            startExclusiveFarmMode(function ()
                return _G [("SAE_StealParasite")] and true or false
            end
            , NB.Position, ("Steal Parasite Egg"), jR, {parasiteOnly = true, onClaimed = feedClaimedEggToParasite})
        end
        local function startTakeRiftEgg(kR)
            startExclusiveFarmMode(isTakeRiftEggEnabled, KB.Position, ("Auto Take Rift Egg"), kR, {riftOnly = true})
        end
        local function setFarmEggEnabled(lR)
            _G [("SAE_FarmEgg")] = lR and true or false
            if _G [("SAE_FarmEgg")] then
                if _G [("SAE_AAFarmEgg")] then
                    setFlagAndFire(("SAE_AAFarmEgg"), false)
                end
                if _G [("SAE_StealParasite")] then
                    setFlagAndFire(("SAE_StealParasite"), false)
                end
                if _G [("SAE_TakeRiftEgg")] then
                    setFlagAndFire(("SAE_TakeRiftEgg"), false)
                end
                if _G [("SAE_CompleteIndex")] then
                    setFlagAndFire(("SAE_CompleteIndex"), false)
                end
            end
            startFarmEgg(true)
        end
        local function setAAFarmEggEnabled(nR)
            _G [("SAE_AAFarmEgg")] = nR and true or false
            if _G [("SAE_AAFarmEgg")] then
                if _G [("SAE_FarmEgg")] then
                    setFlagAndFire(("SAE_FarmEgg"), false)
                end
                if _G [("SAE_StealParasite")] then
                    setFlagAndFire(("SAE_StealParasite"), false)
                end
                if _G [("SAE_TakeRiftEgg")] then
                    setFlagAndFire(("SAE_TakeRiftEgg"), false)
                end
                if _G [("SAE_CompleteIndex")] then
                    setFlagAndFire(("SAE_CompleteIndex"), false)
                end
            end
            startAAFarmEgg(true)
        end
        local function setStealParasiteEnabled(pR)
            _G [("SAE_StealParasite")] = pR and true or false
            if _G [("SAE_StealParasite")] then
                if _G [("SAE_FarmEgg")] then
                    setFlagAndFire(("SAE_FarmEgg"), false)
                end
                if _G [("SAE_AAFarmEgg")] then
                    setFlagAndFire(("SAE_AAFarmEgg"), false)
                end
                if _G [("SAE_TakeRiftEgg")] then
                    setFlagAndFire(("SAE_TakeRiftEgg"), false)
                end
                if _G [("SAE_CompleteIndex")] then
                    setFlagAndFire(("SAE_CompleteIndex"), false)
                end
            end
            startStealParasiteEgg(true)
        end
        getgenv() [("AliceHUB_SAE_ApplyStealParasite")] = setStealParasiteEnabled
        local function setTakeRiftEggEnabled(rR)
            _G [("SAE_TakeRiftEgg")] = rR and true or false
            if _G [("SAE_TakeRiftEgg")] then
                if _G [("SAE_FarmEgg")] then
                    setFlagAndFire(("SAE_FarmEgg"), false)
                end
                if _G [("SAE_AAFarmEgg")] then
                    setFlagAndFire(("SAE_AAFarmEgg"), false)
                end
                if _G [("SAE_StealParasite")] then
                    setFlagAndFire(("SAE_StealParasite"), false)
                end
                if _G [("SAE_CompleteIndex")] then
                    setFlagAndFire(("SAE_CompleteIndex"), false)
                end
            end
            startTakeRiftEgg(true)
        end
        getgenv() [("AliceHUB_SAE_ApplyTakeRiftEgg")] = setTakeRiftEggEnabled
        local function setCompleteIndexEnabled(rR)
            _G [("SAE_CompleteIndex")] = rR and true or false
            if _G [("SAE_CompleteIndex")] then
                if _G [("SAE_FarmEgg")] then
                    setFlagAndFire(("SAE_FarmEgg"), false)
                end
                if _G [("SAE_AAFarmEgg")] then
                    setFlagAndFire(("SAE_AAFarmEgg"), false)
                end
                if _G [("SAE_StealParasite")] then
                    setFlagAndFire(("SAE_StealParasite"), false)
                end
                if _G [("SAE_TakeRiftEgg")] then
                    setFlagAndFire(("SAE_TakeRiftEgg"), false)
                end
            end
            startExclusiveFarmMode(function ()
                return _G [("SAE_CompleteIndex")] and true or false
            end
            , KB.Position, ("Auto Complete Index"), true, {indexOnly = true, onClaimed = function (sR)
                if type (sR) ~= ("table") or type (sR.Uid) ~= ("string") then
                    return
                end
                local tR = getgenv() [("AliceHUB_SAE_PlaceEggUid")]
                if type (tR) ~= ("function") then
                    return
                end
                local function isCompleteIndexEnabled()
                    return _G [("SAE_CompleteIndex")] == true
                end
                local vR = nil
                if type (KO) == ("table") and type (KO.take) == ("function") then
                    vR = KO.take(("complete-index-place"), 10)
                end
                if not vR then
                    return
                end
                local function keepCompleteIndexTurnAlive()
                    if type (KO.keep) == ("function") then
                        pcall(KO.keep, vR)
                    end
                    return true
                end
                pcall(tR, {uid = sR.Uid, cat = sR.AssetCategory}, isCompleteIndexEnabled, keepCompleteIndexTurnAlive)
                if type (KO.give) == ("function") then
                    pcall(KO.give, vR)
                end
            end
            ,})
        end
        getgenv() [("AliceHUB_SAE_ApplyCompleteIndex")] = setCompleteIndexEnabled
        getgenv() [("AliceHUB_SAE_ShowIndexToast")] = function ()
            local yR, zR, AR, BR = pcall(function ()
                local xR = require(zB.Client.GUI).AreaGui()
                return xR, xR.Frame.Texts.Main, xR.Frame.Texts.Emoji
            end
            )
            if not yR then
                return
            end
            local CR = (getgenv() [("AliceHUB_SAE_IndexNotifSeq")] or 0) + 1
            getgenv() [("AliceHUB_SAE_IndexNotifSeq")] = CR
            local function isIndexToastCurrent()
                return getgenv() [("AliceHUB_SAE_IndexNotifSeq")] == CR
            end
            local function renderIndexToastText(FR)
                pcall(function ()
                    BR.Text = ("")
                    AR.Text = FR
                    AR.TextTransparency = 0
                    AR.TextStrokeTransparency = 0
                    BR.TextTransparency = 0
                    zR.Frame.BackgroundTransparency = 1
                    zR.Frame.Background.BackgroundTransparency = 1
                    zR.Frame.Texts.BackgroundTransparency = 1
                    zR.Enabled = true
                end
                )
            end
            task.spawn(function ()
                renderIndexToastText(("+1 Index"))
                task.wait(1.6)
                if not isIndexToastCurrent() then
                    return
                end
                renderIndexToastText(("AliceHUB on Top"))
                task.wait(3)
                if not isIndexToastCurrent() then
                    return
                end
                pcall(function ()
                    zR.Enabled = false
                end
                )
            end
            )
        end
        local function registerFarmConfigEntry(HR, IR, JR)
            local KR = getgenv() [("AliceHUB_SAE_Config")]
            if not KR then
                KR = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = KR
            end
            if KR._byKey [HR] then
                KR._byKey [HR].get = IR
                KR._byKey [HR].set = JR
            else
                local LR = {key = HR, get = IR, set = JR}
                KR._entries [#KR._entries + 1] = LR
                KR._byKey [HR] = LR
            end
        end
        local function notifyFarmConfigChanged()
            local NR = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (NR) == ("function") then
                NR()
            end
        end
        local OR = yB:Section({Title = ("Farm Egg")})
        local ORMoveTab = getgenv() [("AliceHUB_TabMovement")]
        local ORMove = ORMoveTab and ORMoveTab:Section({Title = ("Farm Movement")}) or OR
        getgenv() [("AliceHUB_SAE_FarmMovementSection")] = ORMove
        getgenv() [("AliceHUB_SAE_FarmSection")] = OR
        OR:Toggle({Title = ("Auto Farm Egg"), Desc = ("Automatically grab area eggs and return to your base"), Flag = ("SAE_FarmEgg"), ID = ("SAE_FarmEgg"), Value = false, Callback = function (PR)
            setFarmEggEnabled(PR)
            notifyFarmConfigChanged()
        end
        ,})
        registerFarmConfigEntry(("SAE_FarmEgg"), function ()
            return _G [("SAE_FarmEgg")]
        end
        , function (QR)
            QR = QR and true or false setFlagAndFire(("SAE_FarmEgg"), QR)
            setFarmEggEnabled(QR)
        end
        )
        OR:Toggle({Title = ("Auto Farm Egg (Alternate)"), Desc = (""), Flag = ("SAE_AAFarmEgg"), ID = ("SAE_AAFarmEgg"), Value = false, Callback = function (RR)
            setAAFarmEggEnabled(RR)
            notifyFarmConfigChanged()
        end
        ,})
        registerFarmConfigEntry(("SAE_AAFarmEgg"), function ()
            return _G [("SAE_AAFarmEgg")]
        end
        , function (SR)
            SR = SR and true or false setFlagAndFire(("SAE_AAFarmEgg"), SR)
            setAAFarmEggEnabled(SR)
        end
        )
        OR:Toggle({Title = ("Steal Parasite Egg"), Desc = ("Steal parasite eggs and feed the claimed egg at the monster checkpoint"), Flag = ("SAE_StealParasite"), ID = ("SAE_StealParasite"), Value = false, Callback = function (ParasiteEnabled)
            setStealParasiteEnabled(ParasiteEnabled)
            notifyFarmConfigChanged()
        end
        ,})
        registerFarmConfigEntry(("SAE_StealParasite"), function ()
            return _G [("SAE_StealParasite")]
        end
        , function (TR)
            TR = TR and true or false setFlagAndFire(("SAE_StealParasite"), TR)
            setStealParasiteEnabled(TR)
        end
        )
        OR:Toggle({Title = ("Auto Take Rift Egg"), Desc = ("Automatically target Rift eggs and return them to your base"), Flag = ("SAE_TakeRiftEgg"), ID = ("SAE_TakeRiftEgg"), Value = false, Callback = function (RiftTakeEnabled)
            setTakeRiftEggEnabled(RiftTakeEnabled)
            notifyFarmConfigChanged()
        end
        ,})
        registerFarmConfigEntry(("SAE_TakeRiftEgg"), function ()
            return _G [("SAE_TakeRiftEgg")]
        end
        , function (RiftTakeValue)
            RiftTakeValue = RiftTakeValue and true or false
            setFlagAndFire(("SAE_TakeRiftEgg"), RiftTakeValue)
            setTakeRiftEggEnabled(RiftTakeValue)
        end
        )
        registerFarmConfigEntry(("SAE_CompleteIndex"), function ()
            return _G [("SAE_CompleteIndex")]
        end
        , function (UR)
            UR = UR and true or false setFlagAndFire(("SAE_CompleteIndex"), UR)
            setCompleteIndexEnabled(UR)
        end
        )
        OR:Input({Title = ("Minimum Money/s"), Desc = ("Optional minimum money/s. When set, BOTH this value and the selected rarity filter must match. 0 = rarity filter only"), Flag = ("SAE_StealValueText"), ID = ("SAE_StealValueText"), Placeholder = ("0"), Value = getgenv() [("AliceHUB_SAE_StealValueText")], Callback = function (VR)
            setStealValueInput(VR)
            notifyFarmConfigChanged()
        end
        ,})
        registerFarmConfigEntry(("SAE_StealValueText"), function ()
            return getgenv() [("AliceHUB_SAE_StealValueText")]
        end
        , function (WR)
            WR = tostring(WR or (""))
            setFlagAndFire(("SAE_StealValueText"), WR)
            setStealValueInput(WR)
        end
        )
        local function setTweenMovementEnabled(YR)
            _G [("SAE_TweenMove")] = YR and true or false
        end
        ORMove:Toggle({Title = ("Tween Movement"), Desc = ("Move by fast steps instead of walking — reaches far areas in seconds"), Flag = ("SAE_TweenMove"), ID = ("SAE_TweenMove"), Value = false, Callback = function (ZR)
            setTweenMovementEnabled(ZR)
            notifyFarmConfigChanged()
        end
        ,})
        registerFarmConfigEntry(("SAE_TweenMove"), function ()
            return _G [("SAE_TweenMove")]
        end
        , function (aS)
            aS = aS and true or false setFlagAndFire(("SAE_TweenMove"), aS)
            setTweenMovementEnabled(aS)
        end
        )
        MovementTurnConfig.apply = function (bS)
            _G [("SAE_InstantTP")] = bS and true or false
            if not _G [("SAE_InstantTP")] then
                return
            end
            if _G [("SAE_AntiHit")] then
                _G [("SAE_AntiHit")] = false pcall(setFlagAndFire, ("SAE_AntiHit"), false)
            end
            pcall(function ()
                local cS = getgenv() [("AliceHUB_SAE_RestoreGuardTouch")]
                if type (cS) == ("function") then
                    cS()
                end
            end
            )
            task.spawn(function ()
                pcall(MovementTurnConfig.siapkan)
            end
            )
        end
        ORMove:Toggle({Title = ("Instant TP"), Desc = ("Reach far-area eggs instantly"), Flag = ("SAE_InstantTP"), ID = ("SAE_InstantTP"), Value = false, Callback = function (dS)
            MovementTurnConfig.apply(dS)
            notifyFarmConfigChanged()
        end
        ,})
        registerFarmConfigEntry(("SAE_InstantTP"), function ()
            return _G [("SAE_InstantTP")]
        end
        , function (eS)
            eS = eS and true or false setFlagAndFire(("SAE_InstantTP"), eS)
            MovementTurnConfig.apply(eS)
        end
        )
        local function currentFarmMovementMode()
            if _G [("SAE_InstantTP")] then return ("TP") end
            if _G [("SAE_TweenMove")] then return ("Tween") end
            return ("Walk")
        end
        ORMove:Dropdown({
            Title = ("Movement Method"),
            Desc = ("Choose one movement style for Auto Steal: normal walk, smooth tween, or instant TP"),
            Flag = ("SAE_MovementMethod"),
            Values = {("Walk"), ("Tween"), ("TP")},
            Value = currentFarmMovementMode(),
            Callback = function(mode)
                mode = tostring(mode or ("Walk"))
                if mode == ("TP") then
                    setTweenMovementEnabled(false)
                    MovementTurnConfig.apply(true)
                elseif mode == ("Tween") then
                    MovementTurnConfig.apply(false)
                    setTweenMovementEnabled(true)
                else
                    MovementTurnConfig.apply(false)
                    setTweenMovementEnabled(false)
                end
                notifyFarmConfigChanged()
            end,
        })
        registerFarmConfigEntry(("SAE_MovementMethod"), currentFarmMovementMode, function(mode)
            mode = tostring(mode or ("Walk"))
            if mode == ("TP") then
                setTweenMovementEnabled(false)
                MovementTurnConfig.apply(true)
            elseif mode == ("Tween") then
                MovementTurnConfig.apply(false)
                setTweenMovementEnabled(true)
            else
                MovementTurnConfig.apply(false)
                setTweenMovementEnabled(false)
            end
        end)

        local function setTweenSpeed(gS)
            gS = tonumber(gS) or vC
            if gS < sC then
                gS = sC
            end
            if gS > uC then
                gS = uC
            end
            _G [("SAE_TweenSpeed")] = gS
            return gS
        end
        ORMove:Input({
            Title = ("Tween Speed"),
            Desc = ("Type Tween speed manually in studs/s. Default: 300"),
            Flag = ("SAE_TweenSpeed"),
            ID = ("SAE_TweenSpeed"),
            Placeholder = ("300"),
            Value = tostring(_G [("SAE_TweenSpeed")] or vC),
            Callback = function (hS)
                local parsed = tonumber(hS)
                if parsed then
                    setTweenSpeed(parsed)
                    notifyFarmConfigChanged()
                end
            end,
        })
        registerFarmConfigEntry(("SAE_TweenSpeed"), function ()
            return _G [("SAE_TweenSpeed")]
        end
        , function (iS)
            local jS = setTweenSpeed(iS)
            pcall(function ()
                local kS = getgenv() [("AliceHUB_Flags")]
                local lS = kS and kS [("SAE_TweenSpeed")]
                if lS and type (lS.SetAndFire) == ("function") then
                    lS:SetAndFire(jS)
                end
            end
            )
        end
        )
        local function setEggRarityFilterFromList(nS)
            local oS = {}
            if type (nS) == ("table") then
                for pS, qS in ipairs(nS) do
                    if type (qS) == ("string") and JE [qS] then
                        oS [qS] = true
                    end
                end
                for pS, qS in pairs(nS) do
                    if type (pS) == ("string") and qS == true and JE [pS] then
                        oS [pS] = true
                    end
                end
            end
            _G [("SAE_RarityFilter")] = oS
        end
        local function getEggRarityFilterList()
            local sS = {}
            for tS, uS in ipairs(IE) do
                if _G [("SAE_RarityFilter")] [uS] then
                    table.insert(sS, uS)
                end
            end
            return sS
        end
        OR:MultiDropdown({Title = ("Farm Rarity Filter"), Desc = ("STRICT: farm only the selected rarities. Leave empty = all rarities"), Flag = ("SAE_RarityFilter"), Options = IE, Default = {}, Callback = function (vS)
            setEggRarityFilterFromList(vS)
            notifyFarmConfigChanged()
        end
        ,})
        registerFarmConfigEntry(("SAE_RarityFilter"), function ()
            return getEggRarityFilterList()
        end
        , function (wS)
            setEggRarityFilterFromList(wS)
            pcall(function ()
                local xS = getgenv() [("AliceHUB_Flags")]
                local yS = xS and xS [("SAE_RarityFilter")]
                if yS and type (yS.SetAndFire) == ("function") then
                    yS:SetAndFire(getEggRarityFilterList())
                end
            end
            )
        end
        )
    end
    )
    runAliceModule("CompleteIndex", function (...)
        local zS = getgenv() [("AliceHUB_TabFarm")]
        if not zS then
            return
        end
        local AS = getgenv() [("AliceHUB_SAE_FarmSection")]
        if not AS then
            AS = zS:Section({Title = ("Farm Egg")})
        end
        local function registerCompleteIndexConfigEntry(CS, DS, ES)
            local FS = getgenv() [("AliceHUB_SAE_Config")]
            if not FS then
                FS = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = FS
            end
            if FS._byKey [CS] then
                FS._byKey [CS].get = DS
                FS._byKey [CS].set = ES
            else
                local GS = {key = CS, get = DS, set = ES}
                FS._entries [#FS._entries + 1] = GS
                FS._byKey [CS] = GS
            end
        end
        local function notifyCompleteIndexConfigChanged()
            local IS = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (IS) == ("function") then
                IS()
            end
        end
        AS:Toggle({Title = ("Auto Complete Index"), Desc = ("Steal eggs whose species is not yet discovered in the Pet Index, then bring them home"), Flag = ("SAE_CompleteIndex"), ID = ("SAE_CompleteIndex"), Value = false, Callback = function (JS)
            local KS = getgenv() [("AliceHUB_SAE_ApplyCompleteIndex")]
            if type (KS) == ("function") then
                KS(JS)
            end
            notifyCompleteIndexConfigChanged()
        end
        ,})
    end
    )
    runAliceModule("Treadmill", function (...)
        local LS = getgenv() [("AliceHUB_WindUI")]
        local MS = getgenv() [("AliceHUB_TabFarm")]
        if not MS then
            return
        end
        local NS = game:GetService(("ReplicatedStorage"))
        local OS = game:GetService(("Players"))
        local PS = game:GetService(("RunService"))
        local QS = OS.LocalPlayer
        local RS = Vector3.new(0, 0, - 1)
        local SS = 12
        local TS = 2.0
        local US = 5.0
        local VS = 10.0
        local WS = nil
        -- ============================================================
        -- Treadmill / Auto Speed
        -- ============================================================
        local function getTreadmillPlotState()
            if WS ~= nil then
                return WS or nil
            end
            local YS = NS:FindFirstChild(("Client"))
            local ZS = YS and YS:FindFirstChild(("PlotState"))
            local aT = nil
            if ZS then
                local bT, cT = pcall(require, ZS)
                if bT and type (cT) == ("table") then
                    aT = cT
                end
            end
            WS = aT or false
            return aT
        end
        local dT, eT = nil, 0
        local function resolveLocalPlotSlot()
            if dT and dT.Parent and (os.clock() - eT) < VS then
                return dT
            end
            local gT = getTreadmillPlotState()
            if gT and type (gT.ResolvePlot) == ("function") then
                local okPlot, plotData = pcall(gT.ResolvePlot)
                if okPlot and type (plotData) == ("table") then
                    local plotFolder = plotData.PlotFolder
                    if typeof(plotFolder) == ("Instance") and plotFolder.Parent then
                        dT, eT = plotFolder, os.clock()
                        return plotFolder
                    end
                end
            end
            if gT and type (gT.ResolveLocalSlot) == ("function") then
                local hT, iT = pcall(gT.ResolveLocalSlot)
                if hT and iT ~= nil then
                    local jT = nil
                    if type (gT.ResolveFolder) == ("function") then
                        local kT, lT = pcall(gT.ResolveFolder)
                        if kT then
                            jT = lT
                        end
                    end
                    jT = jT or workspace:FindFirstChild(("Plots"))
                    local mT = jT and jT:FindFirstChild(tostring(iT))
                    if mT then
                        local nT, oT = true, nil
                        if type (gT.LookupOwner) == ("function") then
                            nT, oT = pcall(gT.LookupOwner, iT)
                        end
                        if (not nT) or oT == nil or oT == QS.UserId then
                            dT, eT = mT, os.clock()
                            return mT
                        end
                    end
                end
            end
            local pT = workspace:FindFirstChild(("Plots"))
            if not pT then
                return nil
            end
            for qT, rT in ipairs(pT:GetChildren()) do
                for sT, tT in ipairs(rT:GetDescendants()) do
                    if (tT:IsA(("TextLabel")) or tT:IsA(("TextBox"))) and tostring(tT.Text) == QS.Name then
                        dT, eT = rT, os.clock()
                        return rT
                    end
                end
            end
            return nil
        end
        local function getTreadmillBottomPosition()
            local vT = resolveLocalPlotSlot()
            local wT = vT and vT:FindFirstChild(("TreadmillBottom"))
            if wT and wT:IsA(("BasePart")) then
                return wT.Position
            end
            return nil
        end
        local function getTreadmillRootPart()
            local yT = QS.Character
            return yT and yT:FindFirstChild(("HumanoidRootPart")) or nil
        end
        local function getTreadmillHumanoid()
            local AT = QS.Character
            return AT and AT:FindFirstChildOfClass(("Humanoid")) or nil
        end
        local function waitTreadmillInterval(CT, DT)
            local ET = os.clock()
            while (os.clock() - ET) < CT do
                if DT and not DT() then
                    return
                end
                PS.Heartbeat:Wait()
            end
        end
        local FT = getgenv() [("AliceHUB_SAE_Turn")]
        if type (FT) ~= ("table") then
            local GT = game:GetService(("RunService"))
            local HT = 4.0
            local IT = 18.0
            local JT = 12.0
            local KT = {holder = nil, token = nil, took = 0, alive = 0, seq = 0, nextNo = 1, queue = {}, sejak = {}}
            local function clearTreadmillTurnLock()
                KT.holder, KT.token = nil, nil
            end
            local function removeTreadmillTurnQueueEntry(NT)
                for OT, PT in ipairs(KT.queue) do
                    if PT == NT then
                        table.remove(KT.queue, OT)
                        KT.sejak [NT] = nil
                        return
                    end
                end
            end
            FT = {}
            function FT.take(QT, RT)
                local ST = KT.nextNo
                KT.nextNo = KT.nextNo + 1
                local TT = #KT.queue + 1
                if QT == ("steal-egg") and #KT.queue > 0 then
                    local UT = KT.queue [1]
                    local VT = os.clock() - (KT.sejak [UT] or os.clock())
                    if VT < JT then
                        TT = 1
                    end
                end
                table.insert(KT.queue, TT, ST)
                KT.sejak [ST] = os.clock()
                local WT = os.clock() + (RT or 15)
                while true do
                    if KT.holder ~= nil and (os.clock() - KT.alive) > IT then
                        clearTreadmillTurnLock()
                    end
                    if KT.holder == nil and KT.queue [1] == ST then
                        table.remove(KT.queue, 1)
                        KT.sejak [ST] = nil KT.seq = KT.seq + 1
                        KT.holder, KT.token = QT, KT.seq
                        KT.took, KT.alive = os.clock(), os.clock()
                        return KT.seq
                    end
                    if os.clock() >= WT then
                        removeTreadmillTurnQueueEntry(ST)
                        return nil
                    end
                    GT.Heartbeat:Wait()
                end
            end
            function FT.keep(XT)
                if XT == nil or KT.token ~= XT then
                    return false
                end
                KT.alive = os.clock()
                if #KT.queue > 0 and (os.clock() - KT.took) >= HT then
                    return false
                end
                if #KT.queue > 0 and (os.clock() - KT.took) >= IT then
                    return false
                end
                return true
            end
            function FT.give(YT)
                if YT ~= nil and KT.token == YT then
                    clearTreadmillTurnLock()
                end
            end
            function FT.state()
                return KT
            end
            getgenv() [("AliceHUB_SAE_Turn")] = FT
        end
        local ZT = nil
        local function getTreadmillRemotes()
            if ZT ~= nil then
                return ZT or nil
            end
            local bU = NS:FindFirstChild(("Shared"))
            local cU = bU and bU:FindFirstChild(("Remotes"))
            local dU = nil
            if cU then
                local eU, fU = pcall(require, cU)
                if eU and type (fU) == ("table") and type (fU.Treadmill) == ("table") then
                    dU = fU.Treadmill
                end
            end
            ZT = dU or false
            return dU
        end
        local function requestTreadmillDoff()
            local hU = getTreadmillRemotes()
            local iU = hU and hU.AskDoff
            if not (iU and iU:IsA(("RemoteFunction"))) then
                return false
            end
            local jU, kU = pcall(function ()
                return iU:InvokeServer()
            end
            )
            return jU and kU ~= false
        end
        local function requestTreadmillWearStill()
            local remotes = getTreadmillRemotes()
            local remote = remotes and remotes.AskWearStill
            if not (remote and remote:IsA(("RemoteFunction"))) then
                return false
            end
            local ok, result = pcall(function ()
                return remote:InvokeServer()
            end)
            return ok and result ~= false
        end
        local lU = nil
        local function bindTreadmillAssignmentListener()
            if lU then
                return
            end
            local nU = getTreadmillRemotes()
            local oU = nU and nU.AssignedBeltShifted
            if not (oU and oU:IsA(("RemoteEvent"))) then
                return
            end
            lU = oU.OnClientEvent:Connect(function (pU)
                if pU == nil then
                    return
                end
                if not _G [("SAE_AutoTreadmill")] then
                    task.defer(function ()
                        if not _G [("SAE_AutoTreadmill")] then
                            requestTreadmillDoff()
                        end
                    end
                    )
                end
            end
            )
        end
        _G [("SAE_AutoTreadmill")] = _G [("SAE_AutoTreadmill")] or false
        getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] = getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] or false
        getgenv() [("AliceHUB_SAE_EggPipelineHoldUntil")] = getgenv() [("AliceHUB_SAE_EggPipelineHoldUntil")] or 0
        getgenv() [("AliceHUB_SAE_TreadmillCycleDelay")] = tonumber(getgenv() [("AliceHUB_SAE_TreadmillCycleDelay")]) or 0.12
        local qU = 0
        local rU = false
        local function setAutoTreadmillEnabled(tU)
            _G [("SAE_AutoTreadmill")] = tU and true or false
            qU = qU + 1
            if not _G [("SAE_AutoTreadmill")] then
                requestTreadmillDoff()
                return
            end
            local uU = qU
            local function isAutoTreadmillWorkerCurrent()
                return _G [("SAE_AutoTreadmill")] and qU == uU
            end
            local function isTreadmillPipelineBlocked()
                local now = os.clock()
                return getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] == true
                    or getgenv() [("AliceHUB_SAE_FarmEggBusy")] == true
                    or getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] == true
                    or getgenv() [("AliceHUB_SAE_EquipBestBusy")] == true
                    or now < (getgenv() [("AliceHUB_SAE_EggPipelineHoldUntil")] or 0)
                    or now < (getgenv() [("AliceHUB_SAE_PlaceHatchActiveUntil")] or 0)
                    or now < (getgenv() [("AliceHUB_SAE_EquipBestActiveUntil")] or 0)
            end
            local function treadmillCanMove()
                return isAutoTreadmillWorkerCurrent() and not isTreadmillPipelineBlocked()
            end
            local xU = nil
            local function releaseTreadmillTurn()
                local humanoid = getTreadmillHumanoid()
                if humanoid then
                    pcall(function () humanoid:Move(Vector3.new(0, 0, 0), false) end)
                end
                requestTreadmillDoff()
                if xU ~= nil then
                    pcall(FT.give, xU)
                    xU = nil
                end
            end
            spawnAliceWorker(("TreadmillWorker"), function ()
                local lastRepositionAt = 0
                while isAutoTreadmillWorkerCurrent() do
                    local plot = resolveLocalPlotSlot()
                    local baseLevel = plot and plot:GetAttribute(("BaseUpgradeLevel"))
                    if baseLevel ~= nil and tonumber(baseLevel) == 0 then
                        releaseTreadmillTurn()
                        if not rU then
                            rU = true
                            pcall(function ()
                                LS:Notify({Title = ("Auto Treadmill"), Content = ("Your base is not upgraded yet — the treadmill does not exist at level 0. Upgrade the base first."), Duration = 8,})
                            end)
                        end
                        waitTreadmillInterval(1.0, isAutoTreadmillWorkerCurrent)
                    else
                        if baseLevel ~= nil and tonumber(baseLevel) ~= 0 then rU = false end
                        local standPos = getTreadmillBottomPosition()
                        if not standPos then
                            releaseTreadmillTurn()
                            waitTreadmillInterval(0.35, isAutoTreadmillWorkerCurrent)
                        elseif isTreadmillPipelineBlocked() then
                            -- Selected Egg / Farm / Place / Hatch owns the character now.
                            releaseTreadmillTurn()
                            waitTreadmillInterval(0.05, isAutoTreadmillWorkerCurrent)
                        else
                            if xU == nil then
                                xU = FT.take(("treadmill"), 2)
                            end
                            if xU == nil then
                                waitTreadmillInterval(0.05, isAutoTreadmillWorkerCurrent)
                            elseif not FT.keep(xU) then
                                releaseTreadmillTurn()
                                waitTreadmillInterval(0.05, isAutoTreadmillWorkerCurrent)
                            else
                                local root = getTreadmillRootPart()
                                local humanoid = getTreadmillHumanoid()
                                if not root or not humanoid then
                                    releaseTreadmillTurn()
                                    waitTreadmillInterval(0.10, isAutoTreadmillWorkerCurrent)
                                else
                                    if (root.Position - standPos).Magnitude > SS or (os.clock() - lastRepositionAt) > TS then
                                        lastRepositionAt = os.clock()
                                        local moveTo = getgenv() [("AliceHUB_SAE_MoveTo")]
                                        if type (moveTo) == ("function") then
                                            pcall(moveTo, CFrame.new(standPos + Vector3.new(0, 4, 0)), treadmillCanMove)
                                        end
                                    end
                                    if not treadmillCanMove() then
                                        releaseTreadmillTurn()
                                    else
                                        root = getTreadmillRootPart()
                                        if root and (root.Position - standPos).Magnitude <= SS then
                                            -- "Naik" treadmill.
                                            requestTreadmillWearStill()
                                            pcall(function () humanoid:Move(RS, false) end)
                                            local cycleDelay = math.clamp(tonumber(getgenv() [("AliceHUB_SAE_TreadmillCycleDelay")]) or 0.12, 0.05, 0.50)
                                            waitTreadmillInterval(cycleDelay, treadmillCanMove)
                                            -- "Turun" treadmill, then release the turn so Farm can preempt.
                                            pcall(function () humanoid:Move(Vector3.new(0, 0, 0), false) end)
                                            requestTreadmillDoff()
                                            waitTreadmillInterval(cycleDelay, treadmillCanMove)
                                            if xU ~= nil then
                                                pcall(FT.give, xU)
                                                xU = nil
                                            end
                                        else
                                            releaseTreadmillTurn()
                                        end
                                    end
                                end
                            end
                        end
                    end
                    PS.Heartbeat:Wait()
                end
                releaseTreadmillTurn()
            end
            , function (ok, err)
                releaseTreadmillTurn()
                if not ok and qU == uU then
                    _G [("SAE_AutoTreadmill")] = false
                    local flags = getgenv() [("AliceHUB_Flags")]
                    local flag = flags and flags [("SAE_AutoTreadmill")]
                    if flag and type(flag.Set) == ("function") then pcall(flag.Set, flag, false) end
                end
            end)
        end
        _G [("SAE_AutoUpgradeTreadmill")] = _G [("SAE_AutoUpgradeTreadmill")] or false
        local JU = 0
        local KU = nil
        local function getTreadmillUpgradeController()
            if KU ~= nil then
                return KU or nil
            end
            local MU = nil pcall(function ()
                local NU = QS:FindFirstChild(("PlayerScripts"))
                local OU = NU and NU:FindFirstChild(("GUI"))
                local PU = OU and OU:FindFirstChild(("TreadmillUpgrade"))
                local QU = PU and PU:FindFirstChild(("Client"))
                if QU then
                    local RU, SU = pcall(require, QU)
                    if RU and type (SU) == ("table") and type (SU.RequestCashUpgrade) == ("function") then
                        MU = SU
                    end
                end
            end
            )
            KU = MU or false
            return MU
        end
        local function requestTreadmillTierRaiseRemote()
            local UU = getTreadmillRemotes()
            local VU = UU and UU.AskTierRaise
            if not (VU and VU:IsA(("RemoteFunction"))) then
                return false
            end
            local WU = false pcall(function ()
                local XU = require(NS.Shared.Save)
                local YU = require(NS.Data.Treadmills)
                local ZU = XU.Get()
                if type (ZU) ~= ("table") then
                    return
                end
                local aV = (tonumber(ZU.TreadmillUpgradeLevel) or 0) + 1
                local bV = YU.GetByUpgradeLevel(aV)
                if type (bV) ~= ("table") or bV._id == nil then
                    return
                end
                if (tonumber(ZU.Money) or 0) < (tonumber(bV.Price) or math.huge) then
                    return
                end
                local result = VU:InvokeServer(bV._id)
                WU = (result ~= false)
            end
            )
            return WU
        end
        local function requestTreadmillUpgrade()
            local dV = getTreadmillUpgradeController()
            if dV then
                local eV, fV = pcall(dV.RequestCashUpgrade)
                if eV then
                    return fV ~= false
                end
            end
            return requestTreadmillTierRaiseRemote()
        end
        local function setAutoUpgradeTreadmillEnabled(hV)
            _G [("SAE_AutoUpgradeTreadmill")] = hV and true or false JU = JU + 1
            if not _G [("SAE_AutoUpgradeTreadmill")] then
                return
            end
            local iV = JU
            local function isTreadmillUpgradeWorkerCurrent()
                return _G [("SAE_AutoUpgradeTreadmill")] and JU == iV
            end
            task.spawn(function ()
                while isTreadmillUpgradeWorkerCurrent() do
                    pcall(requestTreadmillUpgrade)
                    waitTreadmillInterval(US, isTreadmillUpgradeWorkerCurrent)
                end
            end
            )
        end
        local function registerTreadmillConfigEntry(lV, mV, nV)
            local oV = getgenv() [("AliceHUB_SAE_Config")]
            if not oV then
                oV = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = oV
            end
            if oV._byKey [lV] then
                oV._byKey [lV].get = mV
                oV._byKey [lV].set = nV
            else
                local pV = {key = lV, get = mV, set = nV}
                oV._entries [#oV._entries + 1] = pV
                oV._byKey [lV] = pV
            end
        end
        local function notifyTreadmillConfigChanged()
            local rV = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (rV) == ("function") then
                rV()
            end
        end
        local function setTreadmillUiFlag(tV, uV)
            pcall(function ()
                local vV = getgenv() [("AliceHUB_Flags")]
                local wV = vV and vV [tV]
                if wV and type (wV.SetAndFire) == ("function") then
                    wV:SetAndFire(uV)
                end
            end
            )
        end
        local xV = MS:Section({Title = ("Auto Speed")})
        xV:Toggle({Title = ("Auto Treadmill"), Desc = ("Idle loop: mount/dismount treadmill until a selected Farm Egg target appears; resumes after Farm/Place/Hatch"), Flag = ("SAE_AutoTreadmill"), ID = ("SAE_AutoTreadmill"), Value = false, Callback = function (yV)
            setAutoTreadmillEnabled(yV)
            notifyTreadmillConfigChanged()
        end
        ,})
        registerTreadmillConfigEntry(("SAE_AutoTreadmill"), function ()
            return _G [("SAE_AutoTreadmill")]
        end
        , function (zV)
            zV = zV and true or false setTreadmillUiFlag(("SAE_AutoTreadmill"), zV)
            setAutoTreadmillEnabled(zV)
        end
        )
        xV:Toggle({Title = ("Auto Upgrade Treadmill"), Desc = ("Keep buying treadmill upgrades whenever you can afford them"), Flag = ("SAE_AutoUpgradeTreadmill"), ID = ("SAE_AutoUpgradeTreadmill"), Value = false, Callback = function (AV)
            setAutoUpgradeTreadmillEnabled(AV)
            notifyTreadmillConfigChanged()
        end
        ,})
        registerTreadmillConfigEntry(("SAE_AutoUpgradeTreadmill"), function ()
            return _G [("SAE_AutoUpgradeTreadmill")]
        end
        , function (BV)
            BV = BV and true or false setTreadmillUiFlag(("SAE_AutoUpgradeTreadmill"), BV)
            setAutoUpgradeTreadmillEnabled(BV)
        end
        )
        getgenv() [("AliceHUB_SAE_SetTreadmill")] = function (CV)
            CV = CV and true or false setTreadmillUiFlag(("SAE_AutoTreadmill"), CV)
            setAutoTreadmillEnabled(CV)
        end
        getgenv() [("AliceHUB_SAE_TreadmillReady")] = function ()
            return getTreadmillBottomPosition() ~= nil
        end
        getgenv() [("AliceHUB_SAE_TreadmillPos")] = function ()
            return getTreadmillBottomPosition()
        end
        bindTreadmillAssignmentListener()
        task.spawn(function ()
            task.wait(2)
            if not _G [("SAE_AutoTreadmill")] then
                requestTreadmillDoff()
            end
        end
        )
    end
    )
    runAliceModule("AutoSell", function (...)
        local DV = getgenv() [("AliceHUB_WindUI")]
        local EV = getgenv() [("AliceHUB_TabFarm")]
        if not EV then
            return
        end
        local FV = game:GetService(("ReplicatedStorage"))
        local GV = game:GetService(("Players"))
        local HV = game:GetService(("RunService"))
        local IV = GV.LocalPlayer
        local JV = 0.12
        local KV = 0.60
        local LV = 0.35
        local MV = 20
        local NV = 1.00
        local OV = 6
        _G [("SAE_AutoSell")] = _G [("SAE_AutoSell")] or false _G [("SAE_SellRarity")] = _G [("SAE_SellRarity")] or {}
        local PV = false
        local QV = {("Common"), ("Uncommon"), ("Rare"), ("Epic"), ("Legendary"), ("Mythic"), ("Cosmic"), ("Secret"), ("Eternal"), ("Divine"),}
        local RV = nil
        -- ============================================================
        -- Auto Sell / Sell By Value / Auto Sell Egg
        -- ============================================================
        local function getAutoSellAssetDirectory()
            if RV ~= nil then
                return RV or nil
            end
            local TV = FV:FindFirstChild(("Data"))
            local UV = TV and TV:FindFirstChild(("Assets"))
            local VV = nil
            if UV then
                local WV, XV = pcall(require, UV)
                if WV and type (XV) == ("table") and type (XV.Directory) == ("table") then
                    VV = XV.Directory
                end
            end
            RV = VV or false
            return VV
        end
        local function getAutoSellRarityOptions()
            local ZV = getAutoSellAssetDirectory()
            if not ZV then
                return nil
            end
            local aW, bW = {}, {}
            for cW, dW in pairs(ZV) do
                if type (dW) == ("table") and type (dW.Rarity) == ("table") then
                    local eW = dW.Rarity._id
                    if type (eW) == ("string") and not aW [eW] then
                        aW [eW] = true bW [#bW + 1] = {id = eW, num = tonumber(dW.Rarity.RarityNumber) or 0}
                    end
                end
            end
            if #bW == 0 then
                return nil
            end
            table.sort(bW, function (fW, gW)
                if fW.num == gW.num then
                    return fW.id < gW.id
                end
                return fW.num < gW.num
            end
            )
            local hW = {}
            for iW, jW in ipairs(bW) do
                hW [iW] = jW.id
            end
            return hW
        end
        local kW = nil pcall(function ()
            kW = getAutoSellRarityOptions()
        end
        )
        kW = kW or QV
        local lW = {}
        for mW, nW in ipairs(kW) do
            lW [nW] = true
        end
        local oW = {}
        local function requireAutoSellSharedModule(qW, rW)
            if oW [rW] ~= nil then
                return oW [rW] or nil
            end
            local sW = FV:FindFirstChild(("Shared"))
            for tW, uW in ipairs(qW) do
                sW = sW and sW:FindFirstChild(uW)
            end
            sW = sW and sW:FindFirstChild(rW)
            local vW = nil
            if sW then
                local wW, xW = pcall(require, sW)
                if wW then
                    vW = xW
                end
            end
            oW [rW] = vW or false
            return vW
        end
        local yW = nil
        local function getAutoSellSaveData()
            if yW == nil then
                local AW = FV:FindFirstChild(("Shared"))
                local BW = AW and AW:FindFirstChild(("Save"))
                yW = (BW and select(2, pcall(require, BW))) or false
            end
            local CW = yW or nil
            if not CW or type (CW.Get) ~= ("function") then
                return nil
            end
            local DW, EW = pcall(CW.Get)
            if DW and type (EW) == ("table") then
                return EW
            end
            return nil
        end
        local function decodeAutoSellAssetItem(GW)
            local HW = requireAutoSellSharedModule({("Util")}, ("AssetItems"))
            if not HW or type (HW.Decode) ~= ("function") then
                return nil
            end
            local IW, JW = pcall(HW.Decode, GW)
            if IW and type (JW) == ("table") then
                return JW
            end
            return nil
        end
        local KW = {}
        local function getAutoSellAssetRarity(MW)
            if type (MW) ~= ("string") then
                return nil
            end
            if KW [MW] ~= nil then
                return KW [MW] or nil
            end
            local NW = getAutoSellAssetDirectory()
            local OW = NW and NW [MW]
            local PW = nil
            if type (OW) == ("table") and type (OW.Rarity) == ("table") and type (OW.Rarity._id) == ("string") then
                PW = OW.Rarity._id
            end
            KW [MW] = PW or false
            return PW
        end
        local QW = nil
        local function getAutoSellRemotes()
            if QW ~= nil then
                return QW or nil
            end
            local SW = FV:FindFirstChild(("Shared"))
            local TW = SW and SW:FindFirstChild(("Remotes"))
            local UW = nil
            if TW then
                local VW, WW = pcall(require, TW)
                if VW and type (WW) == ("table") then
                    UW = WW
                end
            end
            QW = UW or false
            return UW
        end
        local function getAutoSellRemote(YW, ZW, aX)
            local bX = getAutoSellRemotes()
            local cX = bX and bX [YW]
            local dX = cX and cX [ZW]
            if dX and dX:IsA(aX) then
                return dX
            end
            return nil
        end
        local function fetchServerAutoSellConfig()
            local fX = getAutoSellRemote(("Haul"), ("FetchAutoSell"), ("RemoteFunction"))
            if not fX then
                return nil
            end
            local gX, hX = pcall(function ()
                return fX:InvokeServer()
            end
            )
            if gX and type (hX) == ("table") then
                return hX
            end
            return nil
        end
        local function writeServerAutoSellConfig(jX)
            local kX = getAutoSellRemote(("Haul"), ("WriteAutoSell"), ("RemoteFunction"))
            if not kX then
                return false, ("remote tidak ada")
            end
            local lX = table.pack(pcall(kX.InvokeServer, kX, jX))
            if not lX [1] then
                return false, tostring(lX [2])
            end
            return lX [2] ~= false, lX [3]
        end
        local function getSelectedSellRarityMap()
            local nX = {}
            if not _G [("SAE_AutoSell")] then
                return nX
            end
            for oX, pX in ipairs(kW) do
                if _G [("SAE_SellRarity")] [pX] == true then
                    nX [pX] = true
                end
            end
            return nX
        end
        local function countMapEntries(rX)
            local sX = 0
            for tX in pairs(rX or {}) do
                sX = sX + 1
            end
            return sX
        end
        local function countSelectedSellRarities()
            local vX = 0
            for wX, xX in ipairs(kW) do
                if _G [("SAE_SellRarity")] [xX] == true then
                    vX = vX + 1
                end
            end
            return vX
        end
        local function getSellablePetCandidates()
            local zX = {}
            if countSelectedSellRarities() == 0 then
                return zX
            end
            local AX = getAutoSellSaveData()
            if not AX or type (AX.Inventory) ~= ("table") then
                return zX
            end
            local BX = type (AX.EquippedAssets) == ("table") and AX.EquippedAssets or {}
            for CX, DX in pairs(AX.Inventory) do
                local EX = decodeAutoSellAssetItem(DX)
                if EX and EX.IsFavorite ~= true and table.find(BX, CX) == nil and not EX.InFuse then
                    local FX = getAutoSellAssetRarity(EX.Category)
                    if FX and _G [("SAE_SellRarity")] [FX] == true then
                        local GX = 0
                        local HX = requireAutoSellSharedModule({("Util")}, ("GetPriceValueForItem"))
                        if type (HX) == ("function") then
                            local IX, JX = pcall(HX, EX)
                            if IX and tonumber(JX) then
                                GX = tonumber(JX)
                            end
                        end
                        zX [#zX + 1] = {uid = CX, rarity = FX, category = EX.Category, price = GX}
                    end
                end
            end
            table.sort(zX, function (KX, LX)
                if KX.price == LX.price then
                    return KX.uid < LX.uid
                end
                return KX.price < LX.price
            end
            )
            return zX
        end
        local function getCharacterHumanoidBackpack()
            local NX = IV.Character
            if not NX then
                return nil, nil, nil
            end
            return NX, NX:FindFirstChildOfClass(("Humanoid")), IV:FindFirstChild(("Backpack"))
        end
        local function findToolByUid(PX)
            local QX, RX, SX = getCharacterHumanoidBackpack()
            for TX, UX in ipairs({SX, QX}) do
                for VX, WX in ipairs(UX and UX:GetChildren() or {}) do
                    if WX:IsA(("Tool")) and WX:GetAttribute(("UID")) == PX then
                        return WX
                    end
                end
            end
            return nil
        end
        local function getEquippedTool()
            local YX = IV.Character
            return YX and YX:FindFirstChildWhichIsA(("Tool")) or nil
        end
        local function inventoryContainsUid(aY)
            local bY = getAutoSellSaveData()
            return (bY and type (bY.Inventory) == ("table") and bY.Inventory [aY] ~= nil) or false
        end
        local function waitSellHeartbeat(dY)
            local eY = os.clock()
            while os.clock() - eY < dY do
                HV.Heartbeat:Wait()
            end
        end
        local function sellPetByUid(gY)
            local hY = findToolByUid(gY)
            if not hY then
                return false, ("tool tak ada")
            end
            local iY, jY = getCharacterHumanoidBackpack()
            if not (iY and jY) then
                return false, ("karakter belum siap")
            end
            if getEquippedTool() ~= hY then
                pcall(function ()
                    jY:EquipTool(hY)
                end
                )
                local kY = os.clock()
                while os.clock() - kY < KV do
                    if getEquippedTool() == hY then
                        break
                    end
                    HV.Heartbeat:Wait()
                end
            end
            local lY = getEquippedTool()
            if not lY or lY:GetAttribute(("UID")) ~= gY then
                return false, ("yang dipegang bukan sasaran")
            end
            local mY = getAutoSellRemote(("PetSatchel"), ("SellPet"), ("RemoteEvent"))
            if not mY then
                return false, ("remote tidak ada")
            end
            local fired = pcall(function ()
                mY:FireServer(gY)
            end)
            if not fired then
                return false, ("sell remote error")
            end
            waitSellHeartbeat(LV)
            if inventoryContainsUid(gY) then
                return false, ("masih ada setelah dijual")
            end
            return true
        end
        local nY = getgenv() [("AliceHUB_SAE_Turn")]
        if type (nY) ~= ("table") then
            local oY = game:GetService(("RunService"))
            local pY = 4.0
            local qY = 18.0
            local rY = 12.0
            local sY = {holder = nil, token = nil, took = 0, alive = 0, seq = 0, nextNo = 1, queue = {}, sejak = {}}
            local function clearSellTurnLock()
                sY.holder, sY.token = nil, nil
            end
            local function removeSellTurnQueueEntry(vY)
                for wY, xY in ipairs(sY.queue) do
                    if xY == vY then
                        table.remove(sY.queue, wY)
                        sY.sejak [vY] = nil
                        return
                    end
                end
            end
            nY = {}
            function nY.take(yY, zY)
                local AY = sY.nextNo
                sY.nextNo = sY.nextNo + 1
                local BY = #sY.queue + 1
                if yY == ("steal-egg") and #sY.queue > 0 then
                    local CY = sY.queue [1]
                    local DY = os.clock() - (sY.sejak [CY] or os.clock())
                    if DY < rY then
                        BY = 1
                    end
                end
                table.insert(sY.queue, BY, AY)
                sY.sejak [AY] = os.clock()
                local EY = os.clock() + (zY or 15)
                while true do
                    if sY.holder ~= nil and (os.clock() - sY.alive) > qY then
                        clearSellTurnLock()
                    end
                    if sY.holder == nil and sY.queue [1] == AY then
                        table.remove(sY.queue, 1)
                        sY.sejak [AY] = nil sY.seq = sY.seq + 1
                        sY.holder, sY.token = yY, sY.seq
                        sY.took, sY.alive = os.clock(), os.clock()
                        return sY.seq
                    end
                    if os.clock() >= EY then
                        removeSellTurnQueueEntry(AY)
                        return nil
                    end
                    oY.Heartbeat:Wait()
                end
            end
            function nY.keep(FY)
                if FY == nil or sY.token ~= FY then
                    return false
                end
                sY.alive = os.clock()
                if #sY.queue > 0 and (os.clock() - sY.took) >= pY then
                    return false
                end
                if #sY.queue > 0 and (os.clock() - sY.took) >= qY then
                    return false
                end
                return true
            end
            function nY.give(GY)
                if GY ~= nil and sY.token == GY then
                    clearSellTurnLock()
                end
            end
            function nY.state()
                return sY
            end
            getgenv() [("AliceHUB_SAE_Turn")] = nY
        end
        local HY = 0
        local BATCH_MAX = 60
        getgenv() [("AliceHUB_SAE_SellStats")] = getgenv() [("AliceHUB_SAE_SellStats")] or {sold = 0}
        local IY
        local JY
        local function runAutoSellSelectionBatch()
            local LY, MY = {}, {}
            if _G [("SAE_SellPets")] then
                for NY, OY in ipairs(getSellablePetCandidates()) do
                    if #LY >= BATCH_MAX then
                        break
                    end
                    LY [#LY + 1] = OY.uid
                end
            end
            if _G [("SAE_SellEggs")] then
                for PY, QY in ipairs(JY()) do
                    if (#LY + #MY) >= BATCH_MAX then
                        break
                    end
                    MY [#MY + 1] = QY.uid
                end
            end
            if #LY == 0 and #MY == 0 then
                return 0
            end
            local RY = IY(LY, MY)
            if RY > 0 then
                HY = HY + RY
                getgenv() [("AliceHUB_SAE_SellStats")].sold = HY
            end
            return RY
        end
        local function startAutoSellLoop()
            if PV then
                return
            end
            PV = true spawnAliceWorker(("AutoSellWorker"), function ()
                while _G [("SAE_AutoSell")] do
                    local okBatch, batchErr = pcall(runAutoSellSelectionBatch)
                    if not okBatch then
                        warn(("[AliceHUB/AutoSell] ") .. tostring(batchErr))
                    end
                    local TY = os.clock()
                    while os.clock() - TY < NV and _G [("SAE_AutoSell")] do
                        HV.Heartbeat:Wait()
                    end
                end
            end
            , function (ok, err)
                PV = false
                if not ok then
                    _G [("SAE_AutoSell")] = false
                    local flags = getgenv() [("AliceHUB_Flags")]
                    local flag = flags and flags [("SAE_AutoSell")]
                    if flag and type(flag.Set) == ("function") then pcall(flag.Set, flag, false) end
                end
            end)
        end
        _G [("SAE_SellByValue")] = _G [("SAE_SellByValue")] or false _G [("SAE_SellValueMaxM")] = _G [("SAE_SellValueMaxM")] or nil
        local UY = {k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15, qt = 1e18, sx = 1e21,}
        local function parseSellValueInput(WY)
            if type (WY) ~= ("string") then
                return nil
            end
            local XY = (WY:gsub(("%s+"), (""))):gsub((","), (""))
            if XY == ("") then
                return nil
            end
            local YY, ZY = XY:match(("^(%d+%.?%d*)([A-Za-z]*)$"))
            if not YY then
                return nil
            end
            local aZ = tonumber(YY)
            if not aZ then
                return nil
            end
            local bZ = ZY:lower()
            local cZ
            if bZ == ("") then
                cZ = 1e6
            else
                cZ = UY [bZ]
                if not cZ then
                    return nil
                end
            end
            return (aZ * cZ) / 1e6
        end
        getgenv() [("AliceHUB_SAE_ParseValueInput")] = parseSellValueInput
        local function getSellValueThreshold()
            local eZ = tonumber(_G [("SAE_SellValueMaxM")])
            if not eZ then
                return nil
            end
            return eZ * 1e6
        end
        local fZ = {}
        local function getBaseEarningRate(hZ)
            if type (hZ) ~= ("string") then
                return 0
            end
            local iZ = fZ [hZ]
            if iZ ~= nil then
                return iZ
            end
            local jZ = getAutoSellAssetDirectory()
            local kZ = jZ and jZ [hZ]
            local lZ = 0
            if type (kZ) == ("table") and tonumber(kZ.EarningRate) then
                lZ = tonumber(kZ.EarningRate)
            end
            fZ [hZ] = lZ
            return lZ
        end
        local function getAssetMoneyPerSecond(nZ)
            return getBaseEarningRate(nZ.Category) * (tonumber(nZ.Scale) or 1)
        end
        local function getPetsBelowValueThreshold()
            local pZ = {}
            local qZ = getSellValueThreshold()
            if qZ == nil then
                return pZ
            end
            local rZ = getAutoSellSaveData()
            if not rZ or type (rZ.Inventory) ~= ("table") then
                return pZ
            end
            local sZ = type (rZ.EquippedAssets) == ("table") and rZ.EquippedAssets or {}
            for tZ, uZ in pairs(rZ.Inventory) do
                local vZ = decodeAutoSellAssetItem(uZ)
                if vZ and vZ.IsFavorite ~= true and table.find(sZ, tZ) == nil and not vZ.InFuse then
                    local wZ = getAssetMoneyPerSecond(vZ)
                    if wZ < qZ then
                        pZ [#pZ + 1] = {uid = tZ, mps = wZ, category = vZ.Category}
                    end
                end
            end
            table.sort(pZ, function (xZ, yZ)
                if xZ.mps == yZ.mps then
                    return xZ.uid < yZ.uid
                end
                return xZ.mps < yZ.mps
            end
            )
            return pZ
        end
        local function runSellByValueBatch()
            local AZ = getEquippedTool()
            if AZ and AZ:GetAttribute(("ItemType")) ~= ("Asset") then
                return 0
            end
            local BZ = AZ and AZ:GetAttribute(("UID")) or nil
            local CZ = getPetsBelowValueThreshold()
            if #CZ == 0 then
                return 0
            end
            local DZ = nY.take(("auto-sell"), 20)
            if not DZ then
                return 0
            end
            local EZ, FZ = 0, 0
            for GZ, HZ in ipairs(CZ) do
                if not _G [("SAE_SellByValue")] then
                    break
                end
                if EZ >= MV then
                    break
                end
                if not nY.keep(DZ) then
                    break
                end
                local IZ = sellPetByUid(HZ.uid)
                if IZ then
                    EZ = EZ + 1
                    FZ = 0
                    HY = HY + 1
                    getgenv() [("AliceHUB_SAE_SellStats")].sold = HY
                else
                    FZ = FZ + 1
                    if FZ >= OV then
                        break
                    end
                end
                waitSellHeartbeat(JV)
            end
            if BZ and inventoryContainsUid(BZ) then
                local JZ = findToolByUid(BZ)
                local KZ, LZ = getCharacterHumanoidBackpack()
                if JZ and LZ then
                    pcall(function ()
                        LZ:EquipTool(JZ)
                    end
                    )
                end
            elseif EZ > 0 then
                local MZ, NZ = getCharacterHumanoidBackpack()
                if NZ then
                    pcall(function ()
                        NZ:UnequipTools()
                    end
                    )
                end
            end
            nY.give(DZ)
            return EZ
        end
        local OZ = false
        local function startSellByValueLoop()
            if OZ then
                return
            end
            OZ = true spawnAliceWorker(("SellByValueWorker"), function ()
                while _G [("SAE_SellByValue")] do
                    local okBatch, batchErr = pcall(runSellByValueBatch)
                    if not okBatch then
                        warn(("[AliceHUB/SellByValue] ") .. tostring(batchErr))
                    end
                    local QZ = os.clock()
                    while os.clock() - QZ < NV and _G [("SAE_SellByValue")] do
                        HV.Heartbeat:Wait()
                    end
                end
            end
            , function (ok, err)
                OZ = false
                if not ok then
                    _G [("SAE_SellByValue")] = false
                    local flags = getgenv() [("AliceHUB_Flags")]
                    local flag = flags and flags [("SAE_SellByValue")]
                    if flag and type(flag.Set) == ("function") then pcall(flag.Set, flag, false) end
                end
            end)
        end
        local function syncServerAutoSellConfig(SZ)
            local TZ = getSelectedSellRarityMap()
            local UZ, VZ = writeServerAutoSellConfig(TZ)
            if not UZ then
                if SZ then
                    DV:Notify({Title = ("Auto Sell"), Content = ("Server rejected the change") .. (type (VZ) == ("string") and ((": ") .. VZ) or ("")), Duration = 5,})
                end
                return false
            end
            local WZ = (type (VZ) == ("table") and VZ) or fetchServerAutoSellConfig()
            if type (WZ) ~= ("table") then
                WZ = TZ
            end
            local XZ = nil
            for YZ in pairs(WZ) do
                if not TZ [YZ] then
                    XZ = ("server menyalakan ") .. tostring(YZ)
                end
            end
            if not XZ then
                for ZZ in pairs(TZ) do
                    if not WZ [ZZ] then
                        XZ = ("server menolak ") .. tostring(ZZ)
                    end
                end
            end
            if XZ then
                _G [("SAE_AutoSell")] = false DV:Notify({Title = ("Auto Sell"), Content = ("State mismatch — ") .. XZ, Duration = 6})
                return false
            end
            if SZ then
                local a0 = countMapEntries(WZ)
                local b0
                if a0 > 0 then
                    b0 = ("Selling ") .. a0 .. (" rarity(s) — existing pets included")
                elseif _G [("SAE_AutoSell")] then
                    b0 = ("Nothing armed — no valid rarity selected")
                else
                    b0 = ("Disabled — nothing will be sold")
                end
                DV:Notify({Title = ("Auto Sell"), Content = b0, Duration = 4})
            end
            return true
        end
        local function registerAutoSellConfigEntry(d0, e0, f0)
            local g0 = getgenv() [("AliceHUB_SAE_Config")]
            if not g0 then
                g0 = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = g0
            end
            if g0._byKey [d0] then
                g0._byKey [d0].get = e0
                g0._byKey [d0].set = f0
            else
                local h0 = {key = d0, get = e0, set = f0}
                g0._entries [#g0._entries + 1] = h0
                g0._byKey [d0] = h0
            end
        end
        local function notifyAutoSellConfigChanged()
            local j0 = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (j0) == ("function") then
                j0()
            end
        end
        local function setAutoSellUiFlag(l0, m0)
            pcall(function ()
                local n0 = getgenv() [("AliceHUB_Flags")]
                local o0 = n0 and n0 [l0]
                if o0 and type (o0.SetAndFire) == ("function") then
                    o0:SetAndFire(m0)
                end
            end
            )
        end
        local function rarityListToMap(q0)
            local r0 = {}
            if type (q0) == ("table") then
                for s0, t0 in ipairs(q0) do
                    if type (t0) == ("string") and lW [t0] then
                        r0 [t0] = true
                    end
                end
            end
            return r0
        end
        local function rarityMapToList(v0)
            local w0 = {}
            for x0, y0 in ipairs(kW) do
                if v0 [y0] then
                    w0 [#w0 + 1] = y0
                end
            end
            return w0
        end
        local z0 = nil
        local function getSellSelectionRemote()
            if z0 ~= nil then
                return z0 or nil
            end
            local B0 = getAutoSellRemote(("PetSatchel"), ("SellSelection"), ("RemoteEvent"))
            z0 = B0 or false
            return B0
        end
        local C0 = 60
        function IY(D0, E0)
            local F0 = getSellSelectionRemote()
            if not F0 then
                return 0
            end
            if #D0 == 0 and #E0 == 0 then
                return 0
            end
            local G0 = pcall(function ()
                F0:FireServer({Assets = D0, Eggs = E0})
            end
            )
            if not G0 then
                return 0
            end
            waitSellHeartbeat(0.45)
            local H0 = getAutoSellSaveData()
            local I0 = (H0 and type (H0.Inventory) == ("table")) and H0.Inventory or {}
            local J0 = (H0 and type (H0.EggInventory) == ("table")) and H0.EggInventory or {}
            local K0 = 0
            for L0, M0 in ipairs(D0) do
                if I0 [M0] == nil then
                    K0 = K0 + 1
                end
            end
            for N0, O0 in ipairs(E0) do
                if J0 [O0] == nil then
                    K0 = K0 + 1
                end
            end
            return K0
        end
        local P0 = EV:Section({Title = ("Auto Sell")})
        _G [("SAE_SellPets")] = _G [("SAE_SellPets")] == nil and true or _G [("SAE_SellPets")] _G [("SAE_SellEggs")] = _G [("SAE_SellEggs")] or false P0:MultiDropdown({Title = ("Sell Rarity"), Desc = ("Which rarities to sell. Empty = nothing is sold"), Flag = ("SAE_SellRarity"), Options = kW, Default = {}, Callback = function (Q0)
            _G [("SAE_SellRarity")] = rarityListToMap(Q0)
            _G [("SAE_SellEggRarity")] = _G [("SAE_SellRarity")]
            if _G [("SAE_AutoSell")] then
                syncServerAutoSellConfig(false)
            end
            notifyAutoSellConfigChanged()
        end
        ,})
        P0:Toggle({Title = ("Sell Pets"), Desc = ("Include pets in Auto Sell"), Flag = ("SAE_SellPets"), ID = ("SAE_SellPets"), Value = true, Callback = function (R0)
            _G [("SAE_SellPets")] = R0 and true or false notifyAutoSellConfigChanged()
        end
        ,})
        registerAutoSellConfigEntry(("SAE_SellPets"), function ()
            return _G [("SAE_SellPets")]
        end
        , function (S0)
            S0 = S0 and true or false _G [("SAE_SellPets")] = S0
            setAutoSellUiFlag(("SAE_SellPets"), S0)
        end
        )
        P0:Toggle({Title = ("Sell Eggs"), Desc = ("Include eggs in Auto Sell (placed eggs are never sold)"), Flag = ("SAE_SellEggs"), ID = ("SAE_SellEggs"), Value = false, Callback = function (T0)
            _G [("SAE_SellEggs")] = T0 and true or false notifyAutoSellConfigChanged()
        end
        ,})
        registerAutoSellConfigEntry(("SAE_SellEggs"), function ()
            return _G [("SAE_SellEggs")]
        end
        , function (U0)
            U0 = U0 and true or false _G [("SAE_SellEggs")] = U0
            setAutoSellUiFlag(("SAE_SellEggs"), U0)
        end
        )
        P0:Toggle({Title = ("Enable Auto Sell"), Desc = ("Keep selling everything of the rarities picked above"), Flag = ("SAE_AutoSell"), ID = ("SAE_AutoSell"), Value = false, Callback = function (V0)
            _G [("SAE_AutoSell")] = V0 and true or false
            if _G [("SAE_AutoSell")] and countSelectedSellRarities() == 0 then
                _G [("SAE_AutoSell")] = false setAutoSellUiFlag(("SAE_AutoSell"), false)
                syncServerAutoSellConfig(false)
                DV:Notify({Title = ("Auto Sell"), Content = ("Pick at least one rarity first — nothing was enabled"), Duration = 5,})
                notifyAutoSellConfigChanged()
                return
            end
            if _G [("SAE_AutoSell")] and not _G [("SAE_SellPets")] and not _G [("SAE_SellEggs")] then
                _G [("SAE_AutoSell")] = false setAutoSellUiFlag(("SAE_AutoSell"), false)
                DV:Notify({Title = ("Auto Sell"), Content = ("Turn on Sell Pets or Sell Eggs first — nothing was enabled"), Duration = 5,})
                notifyAutoSellConfigChanged()
                return
            end
            syncServerAutoSellConfig(true)
            if _G [("SAE_AutoSell")] then
                startAutoSellLoop()
            end
            notifyAutoSellConfigChanged()
        end
        ,})
        registerAutoSellConfigEntry(("SAE_SellRarity"), function ()
            return rarityMapToList(_G [("SAE_SellRarity")])
        end
        , function (W0)
            _G [("SAE_SellRarity")] = rarityListToMap(W0)
            _G [("SAE_SellEggRarity")] = _G [("SAE_SellRarity")] setAutoSellUiFlag(("SAE_SellRarity"), rarityMapToList(_G [("SAE_SellRarity")]))
        end
        )
        registerAutoSellConfigEntry(("SAE_AutoSell"), function ()
            return _G [("SAE_AutoSell")]
        end
        , function (X0)
            X0 = X0 and true or false
            if X0 and countSelectedSellRarities() == 0 then
                X0 = false
            end
            _G [("SAE_AutoSell")] = X0
            setAutoSellUiFlag(("SAE_AutoSell"), X0)
            syncServerAutoSellConfig(false)
            if X0 then
                startAutoSellLoop()
            end
        end
        )
        task.spawn(function ()
            task.wait(1.0)
            local Y0 = fetchServerAutoSellConfig()
            if type (Y0) == ("table") and countMapEntries(Y0) > 0 and not _G [("SAE_AutoSell")] then
                DV:Notify({Title = ("Auto Sell"), Content = ("The game already has auto-sell ON for ") .. countMapEntries(Y0) .. (" rarity(s) from a previous session"), Duration = 7,})
            end
        end
        )
        getgenv() [("AliceHUB_SAE_SellValueText")] = getgenv() [("AliceHUB_SAE_SellValueText")] or ("")
        local function setSellValueText(a1)
            a1 = tostring(a1 or (""))
            getgenv() [("AliceHUB_SAE_SellValueText")] = a1
            _G [("SAE_SellValueMaxM")] = parseSellValueInput(a1)
        end
        P0:Input({Title = ("Sell below value (money/s)"), Desc = ("Pets below this estimated money/s get sold, e.g. 500m, 2.5b, 9T (no suffix = Million)"), Flag = ("SAE_SellValueText"), ID = ("SAE_SellValueText"), Placeholder = ("9T"), Value = getgenv() [("AliceHUB_SAE_SellValueText")], Callback = function (b1)
            setSellValueText(b1)
            notifyAutoSellConfigChanged()
        end
        ,})
        registerAutoSellConfigEntry(("SAE_SellValueText"), function ()
            return getgenv() [("AliceHUB_SAE_SellValueText")]
        end
        , function (c1)
            c1 = tostring(c1 or (""))
            setAutoSellUiFlag(("SAE_SellValueText"), c1)
            setSellValueText(c1)
        end
        )
        P0:Toggle({Title = ("Sell Below Value"), Desc = ("Keep selling any pet (any rarity) whose estimated money/s falls under the value above"), Flag = ("SAE_SellByValue"), ID = ("SAE_SellByValue"), Value = false, Callback = function (d1)
            _G [("SAE_SellByValue")] = d1 and true or false
            if _G [("SAE_SellByValue")] and _G [("SAE_SellValueMaxM")] == nil then
                _G [("SAE_SellByValue")] = false setAutoSellUiFlag(("SAE_SellByValue"), false)
                DV:Notify({Title = ("Sell Below Value"), Content = ("Enter a value first — nothing was enabled"), Duration = 5,})
                notifyAutoSellConfigChanged()
                return
            end
            if _G [("SAE_SellByValue")] then
                startSellByValueLoop()
            end
            notifyAutoSellConfigChanged()
        end
        ,})
        registerAutoSellConfigEntry(("SAE_SellByValue"), function ()
            return _G [("SAE_SellByValue")]
        end
        , function (e1)
            e1 = e1 and true or false
            if e1 and _G [("SAE_SellValueMaxM")] == nil then
                e1 = false
            end
            _G [("SAE_SellByValue")] = e1
            setAutoSellUiFlag(("SAE_SellByValue"), e1)
            if e1 then
                startSellByValueLoop()
            end
        end
        )
        local f1 = 0.15
        local g1 = 0.70
        local h1 = 25
        local i1 = 1.00
        local j1 = 6
        _G [("SAE_SellEggRarity")] = _G [("SAE_SellEggRarity")] or {}
        local k1 = false
        local function getEggSellRarity(m1)
            local n1 = getgenv() [("AliceHUB_SAE_RarityOf")]
            if type (n1) == ("function") then
                local o1, p1 = pcall(n1, m1)
                if o1 and type (p1) == ("string") then
                    return p1
                end
            end
            return getAutoSellAssetRarity(m1)
        end
        function JY()
            local q1 = {}
            local r1 = getAutoSellSaveData()
            local s1 = r1 and r1.EggInventory
            if type (s1) ~= ("table") then
                return q1
            end
            for t1, u1 in pairs(s1) do
                if type (t1) == ("string") and type (u1) == ("table") and u1.Placement == nil then
                    local v1 = getEggSellRarity(u1.AssetCategory)
                    if v1 and _G [("SAE_SellEggRarity")] [v1] == true then
                        q1 [#q1 + 1] = {uid = t1, rarity = v1}
                    end
                end
            end
            return q1
        end
        local function countSelectedEggSellRarities()
            local x1 = 0
            for y1, z1 in ipairs(kW) do
                if _G [("SAE_SellEggRarity")] [z1] == true then
                    x1 = x1 + 1
                end
            end
            return x1
        end
        local A1 = nil
        local function getAutoSellEggState()
            if A1 ~= nil then
                return A1 or nil
            end
            local C1 = FV:FindFirstChild(("Client"))
            local D1 = C1 and C1:FindFirstChild(("EggState"))
            local E1 = nil
            if D1 then
                local F1, G1 = pcall(require, D1)
                if F1 and type (G1) == ("table") then
                    E1 = G1
                end
            end
            A1 = E1 or false
            return E1
        end
        local function sellEggByUid(I1)
            local J1 = getAutoSellEggState()
            if not J1 or type (J1.WearEggTool) ~= ("function") then
                return false
            end
            local K1 = getAutoSellRemote(("PetSatchel"), ("SellPet"), ("RemoteEvent"))
            if not K1 then
                return false
            end
            if not pcall(J1.WearEggTool, I1) then
                return false
            end
            local L1 = os.clock()
            local M1 = false
            while (os.clock() - L1) < g1 do
                local N1 = IV.Character
                local O1 = N1 and N1:FindFirstChildWhichIsA(("Tool"))
                if O1 and tostring(O1:GetAttribute(("UID"))) == I1 then
                    M1 = true
                    break
                end
                HV.Heartbeat:Wait()
            end
            if not M1 then
                return false
            end
            if not pcall(function ()
                K1:FireServer(I1)
            end
            ) then
                return false
            end
            local P1 = os.clock()
            while (os.clock() - P1) < LV do
                local Q1 = getAutoSellSaveData()
                local R1 = Q1 and Q1.EggInventory
                if type (R1) == ("table") and R1 [I1] == nil then
                    return true
                end
                HV.Heartbeat:Wait()
            end
            return false
        end
        local function runAutoSellEggBatch()
            local T1 = JY()
            if #T1 == 0 then
                return 0
            end
            local U1, V1 = 0, 0
            for W1, X1 in ipairs(T1) do
                if not _G [("SAE_AutoSellEgg")] then
                    break
                end
                if W1 > h1 then
                    break
                end
                if sellEggByUid(X1.uid) then
                    U1 = U1 + 1
                    V1 = 0
                else
                    V1 = V1 + 1
                    if V1 >= j1 then
                        break
                    end
                end
                local Y1 = os.clock()
                while (os.clock() - Y1) < f1 do
                    if not _G [("SAE_AutoSellEgg")] then
                        break
                    end
                    HV.Heartbeat:Wait()
                end
            end
            return U1
        end
        local function startAutoSellEggLoop()
            if k1 then
                return
            end
            k1 = true task.spawn(function ()
                while _G [("SAE_AutoSellEgg")] do
                    if not getgenv() [("AliceHUB_SAE_Moving")] then
                        pcall(runAutoSellEggBatch)
                    end
                    local a2 = os.clock()
                    while (os.clock() - a2) < i1 do
                        if not _G [("SAE_AutoSellEgg")] then
                            break
                        end
                        HV.Heartbeat:Wait()
                    end
                end
                k1 = false
            end
            )
        end
    end
    )
    runAliceModule("Whitelist", function (...)
        local b2 = getgenv() [("AliceHUB_TabFarm")]
        if not b2 then
            return
        end
        local c2 = getgenv() [("AliceHUB_WindUI")]
        local d2 = game:GetService(("ReplicatedStorage"))
        -- ============================================================
        -- Whitelist / Favorite protection
        -- ============================================================
        local function registerWhitelistConfigEntry(f2, g2, h2)
            local i2 = getgenv() [("AliceHUB_SAE_Config")]
            if not i2 then
                i2 = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = i2
            end
            if i2._byKey [f2] then
                i2._byKey [f2].get = g2
                i2._byKey [f2].set = h2
            else
                local j2 = {key = f2, get = g2, set = h2}
                i2._entries [#i2._entries + 1] = j2
                i2._byKey [f2] = j2
            end
        end
        local function notifyWhitelistConfigChanged()
            local l2 = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (l2) == ("function") then
                l2()
            end
        end
        local function setWhitelistUiFlag(n2, o2)
            pcall(function ()
                local p2 = getgenv() [("AliceHUB_Flags")]
                local q2 = p2 and p2 [n2]
                if q2 and type (q2.SetAndFire) == ("function") then
                    q2:SetAndFire(o2)
                end
            end
            )
        end
        local function notifyWhitelist(s2, t2, u2)
            if not c2 then
                return
            end
            pcall(function ()
                c2:Notify({Title = s2, Content = t2, Duration = u2 or 4})
            end
            )
        end
        local v2 = nil
        local function getWhitelistModules()
            if v2 ~= nil then
                return v2 or nil
            end
            local x2, y2 = pcall(function ()
                return {Save = require(d2.Shared.Save), Remotes = require(d2.Shared.Remotes), AssetItems = require(d2.Shared.Util.AssetItems),}
            end
            )
            v2 = (x2 and type (y2) == ("table")) and y2 or false
            return v2 or nil
        end
        local function getWhitelistSaveData()
            local A2 = getWhitelistModules()
            if not A2 then
                return nil
            end
            local B2, C2 = pcall(function ()
                return A2.Save.Get()
            end
            )
            return (B2 and type (C2) == ("table")) and C2 or nil
        end
        local function getOwnedPetCategories()
            local E2, F2 = getWhitelistModules(), getWhitelistSaveData()
            if not E2 or not F2 or type (F2.Inventory) ~= ("table") then
                return {}
            end
            local G2, H2 = {}, {}
            for I2, J2 in pairs(F2.Inventory) do
                local K2, L2 = pcall(E2.AssetItems.Decode, J2)
                if K2 and L2 and type (L2.Category) == ("string") and not G2 [L2.Category] then
                    G2 [L2.Category] = true H2 [#H2 + 1] = L2.Category
                end
            end
            table.sort(H2)
            return H2
        end
        _G [("SAE_WLPick")] = _G [("SAE_WLPick")] or {}
        _G [("SAE_AutoFav")] = _G [("SAE_AutoFav")] or false _G [("SAE_AutoUnfav")] = _G [("SAE_AutoUnfav")] or false
        local M2, N2 = 0, 0
        local O2 = 5
        local P2 = 5
        local function getProtectedPetSet()
            local R2 = {}
            for S2, T2 in ipairs(_G [("SAE_WLPick")] or {}) do
                R2 [T2] = true
            end
            return R2
        end
        local function setPetFavoriteState(V2, W2)
            local X2 = getWhitelistModules()
            if not X2 then
                return false
            end
            return (pcall(function ()
                X2.Remotes.PetSatchel.WriteFavourite:FireServer(V2, W2)
            end
            ))
        end
        local function syncProtectedPetFavoriteState(Z2)
            local a3, b3 = getWhitelistModules(), getWhitelistSaveData()
            if not a3 or not b3 or type (b3.Inventory) ~= ("table") then
                return 0
            end
            local c3 = getProtectedPetSet()
            local d3 = next(c3) ~= nil
            local e3 = 0
            for f3, g3 in pairs(b3.Inventory) do
                local h3, i3 = pcall(a3.AssetItems.Decode, g3)
                if h3 and i3 then
                    local j3 = i3.IsFavorite == true
                    local k3
                    if Z2 then
                        k3 = d3 and c3 [i3.Category] == true
                    else
                        k3 = true
                    end
                    if k3 and j3 ~= Z2 then
                        if setPetFavoriteState(f3, Z2) then
                            e3 = e3 + 1
                        end
                    end
                end
            end
            return e3
        end
        local function startPeriodicWorker(m3, n3, o3)
            task.spawn(function ()
                while m3() do
                    pcall(o3)
                    local p3 = 0
                    while p3 < n3 do
                        if not m3() then
                            return
                        end
                        task.wait(0.5)
                        p3 = p3 + 0.5
                    end
                end
            end
            )
        end
        local q3 = b2:Section({Title = ("Whitelist")}) do
            local r3 = getOwnedPetCategories()
            q3:MultiDropdown({Title = ("Protected Pets"), Desc = ("Pets to keep. Empty = nothing is protected"), Flag = ("SAE_WLPick"), Options = r3, Default = {}, Callback = function (s3)
                _G [("SAE_WLPick")] = type (s3) == ("table") and s3 or {}
                notifyWhitelistConfigChanged()
            end
            ,})
        end
        registerWhitelistConfigEntry(("SAE_WLPick"), function ()
            return _G [("SAE_WLPick")]
        end
        , function (t3)
            if type (t3) == ("table") then
                _G [("SAE_WLPick")] = t3
                setWhitelistUiFlag(("SAE_WLPick"), t3)
            end
        end
        )
        local function setAutoFavoriteEnabled(v3)
            _G [("SAE_AutoFav")] = v3 and true or false M2 = M2 + 1
            if not _G [("SAE_AutoFav")] then
                return
            end
            if _G [("SAE_AutoUnfav")] then
                _G [("SAE_AutoUnfav")] = false N2 = N2 + 1
                setWhitelistUiFlag(("SAE_AutoUnfav"), false)
            end
            local w3 = M2
            startPeriodicWorker(function ()
                return _G [("SAE_AutoFav")] and M2 == w3
            end
            , O2, function ()
                syncProtectedPetFavoriteState(true)
            end
            )
        end
        q3:Toggle({Title = ("Auto Favorite"), Desc = ("Keep the selected pets safe from selling"), Flag = ("SAE_AutoFav"), ID = ("SAE_AutoFav"), Value = false, Callback = function (x3)
            if x3 then
                local y3 = 0
                for z3 in ipairs(_G [("SAE_WLPick")] or {}) do
                    y3 = y3 + 1
                end
                if y3 == 0 then
                    setWhitelistUiFlag(("SAE_AutoFav"), false)
                    _G [("SAE_AutoFav")] = false notifyWhitelist(("Whitelist"), ("Pick at least one pet first — nothing was enabled"), 5)
                    notifyWhitelistConfigChanged()
                    return
                end
            end
            setAutoFavoriteEnabled(x3)
            notifyWhitelistConfigChanged()
        end
        ,})
        registerWhitelistConfigEntry(("SAE_AutoFav"), function ()
            return _G [("SAE_AutoFav")]
        end
        , function (A3)
            A3 = A3 and true or false
            local B3 = 0
            for C3 in ipairs(_G [("SAE_WLPick")] or {}) do
                B3 = B3 + 1
            end
            if A3 and B3 == 0 then
                A3 = false
            end
            setWhitelistUiFlag(("SAE_AutoFav"), A3)
            setAutoFavoriteEnabled(A3)
        end
        )
        local function setAutoUnfavoriteEnabled(E3)
            _G [("SAE_AutoUnfav")] = E3 and true or false N2 = N2 + 1
            if not _G [("SAE_AutoUnfav")] then
                return
            end
            if _G [("SAE_AutoFav")] then
                _G [("SAE_AutoFav")] = false M2 = M2 + 1
                setWhitelistUiFlag(("SAE_AutoFav"), false)
            end
            local F3 = N2
            task.spawn(function ()
                local G3 = syncProtectedPetFavoriteState(false)
                if G3 > 0 then
                    notifyWhitelist(("Whitelist"), ("Released ") .. tostring(G3) .. (" pet(s)."), 3)
                end
            end
            )
            startPeriodicWorker(function ()
                return _G [("SAE_AutoUnfav")] and N2 == F3
            end
            , P2, function ()
                syncProtectedPetFavoriteState(false)
            end
            )
        end
        q3:Toggle({Title = ("Auto Unfavorite"), Desc = ("Release every protected pet"), Flag = ("SAE_AutoUnfav"), ID = ("SAE_AutoUnfav"), Value = false, Callback = function (H3)
            setAutoUnfavoriteEnabled(H3)
            notifyWhitelistConfigChanged()
        end
        ,})
        registerWhitelistConfigEntry(("SAE_AutoUnfav"), function ()
            return _G [("SAE_AutoUnfav")]
        end
        , function (I3)
            I3 = I3 and true or false setWhitelistUiFlag(("SAE_AutoUnfav"), I3)
            setAutoUnfavoriteEnabled(I3)
        end
        )
    end
    )
    runAliceModule("Fuse", function (...)
        local J3 = getgenv() [("AliceHUB_WindUI")]
        local K3 = getgenv() [("AliceHUB_TabMachine")] or getgenv() [("AliceHUB_TabFarm")]
        if not K3 then
            return
        end
        local L3 = game:GetService(("ReplicatedStorage"))
        local M3 = game:GetService(("Players"))
        local N3 = game:GetService(("RunService"))
        local O3 = M3.LocalPlayer
        local P3 = 0.30
        local Q3 = 2.0
        local R3 = 1.0
        local S3 = 3
        local T3 = 0.20
        _G [("SAE_FuseAll")] = _G [("SAE_FuseAll")] or false _G [("SAE_FuseRarity")] = _G [("SAE_FuseRarity")] or {}
        local U3 = {}
        -- ============================================================
        -- Auto Fuse
        -- ============================================================
        local function requireFuseSharedModule(W3, X3)
            local Y3 = table.concat(W3, ("/")) .. ("/") .. X3
            if U3 [Y3] ~= nil then
                return U3 [Y3] or nil
            end
            local Z3 = L3:FindFirstChild(("Shared"))
            for a4, b4 in ipairs(W3) do
                Z3 = Z3 and Z3:FindFirstChild(b4)
            end
            Z3 = Z3 and Z3:FindFirstChild(X3)
            local c4 = nil
            if Z3 then
                local d4, e4 = pcall(require, Z3)
                if d4 then
                    c4 = e4
                end
            end
            U3 [Y3] = c4 or false
            return c4
        end
        local f4 = nil
        local function getFuseSaveData()
            if f4 == nil then
                local h4 = L3:FindFirstChild(("Shared"))
                local i4 = h4 and h4:FindFirstChild(("Save"))
                f4 = (i4 and select(2, pcall(require, i4))) or false
            end
            local j4 = f4 or nil
            if not j4 or type (j4.Get) ~= ("function") then
                return nil
            end
            local k4, l4 = pcall(j4.Get)
            if k4 and type (l4) == ("table") then
                return l4
            end
            return nil
        end
        local function getFuseAssetDirectory()
            local n4 = L3:FindFirstChild(("Data"))
            local o4 = n4 and n4:FindFirstChild(("Assets"))
            if not o4 then
                return nil
            end
            local p4, q4 = pcall(require, o4)
            if p4 and type (q4) == ("table") and type (q4.Directory) == ("table") then
                return q4.Directory
            end
            return nil
        end
        local r4 = {}
        local function getFuseAssetDefinition(t4)
            if type (t4) ~= ("string") then
                return nil
            end
            if r4 [t4] ~= nil then
                return r4 [t4] or nil
            end
            local u4 = getFuseAssetDirectory()
            local v4 = u4 and u4 [t4] r4 [t4] = v4 or false
            return v4
        end
        local function decodeFuseAssetItem(x4)
            local y4 = requireFuseSharedModule({("Util")}, ("AssetItems"))
            if not y4 or type (y4.Decode) ~= ("function") then
                return nil
            end
            local z4, A4 = pcall(y4.Decode, x4)
            if z4 and type (A4) == ("table") then
                return A4
            end
            return nil
        end
        local B4 = {("Common"), ("Uncommon"), ("Rare"), ("Epic"), ("Legendary"), ("Mythic"), ("Cosmic"), ("Secret"), ("Eternal"), ("Divine"),}
        local function getFuseRarityOptions()
            local D4 = getFuseAssetDirectory()
            if not D4 then
                return nil
            end
            local E4, F4 = {}, {}
            for G4, H4 in pairs(D4) do
                if type (H4) == ("table") and type (H4.Rarity) == ("table") then
                    local I4 = H4.Rarity._id
                    if type (I4) == ("string") and not E4 [I4] then
                        E4 [I4] = true F4 [#F4 + 1] = {id = I4, num = tonumber(H4.Rarity.RarityNumber) or 0}
                    end
                end
            end
            if #F4 == 0 then
                return nil
            end
            table.sort(F4, function (J4, K4)
                if J4.num == K4.num then
                    return J4.id < K4.id
                end
                return J4.num < K4.num
            end
            )
            local L4 = {}
            for M4, N4 in ipairs(F4) do
                L4 [M4] = N4.id
            end
            return L4
        end
        local O4 = nil pcall(function ()
            O4 = getFuseRarityOptions()
        end
        )
        O4 = O4 or B4
        local P4 = {}
        for Q4, R4 in ipairs(O4) do
            P4 [R4] = true
        end
        local S4 = {INSERT_MOB = ("LoadPet"), REMOVE_MOB = ("EjectPet"), START_FUSE = ("BeginFuse"), COMPLETE_REVEAL = ("FinishReveal"),}
        local function getFuseRemote(U4)
            local V4 = S4 [U4]
            if not V4 then
                return nil
            end
            local W4 = L3:FindFirstChild(("Shared"))
            local X4 = W4 and W4:FindFirstChild(("Remotes"))
            if not X4 then
                return nil
            end
            local Y4, Z4 = pcall(require, X4)
            if not (Y4 and type (Z4) == ("table") and type (Z4.Fusery) == ("table")) then
                return nil
            end
            return Z4.Fusery [V4]
        end
        local function invokeFuseAction(b5, c5, d5, e5)
            local f5 = getFuseRemote(b5)
            if not f5 or type (f5.InvokeServer) ~= ("function") then
                return false, ("endpoint unavailable")
            end
            local g5 = ("unknown")
            for h5 = 1, d5 do
                local i5, j5, k5, l5 = pcall(function ()
                    if c5 == nil then
                        return f5:InvokeServer()
                    end
                    return f5:InvokeServer(c5)
                end
                )
                if i5 and j5 ~= false then
                    if j5 == true then
                        return true, k5, l5
                    end
                    return true, j5, k5
                end
                g5 = (not i5) and tostring(j5) or (type (k5) == ("string") and k5 or type (j5) == ("string") and j5 or ("rejected"))
                if h5 < d5 then
                    local m5 = os.clock()
                    while (os.clock() - m5) < e5 do
                        N3.Heartbeat:Wait()
                    end
                end
            end
            return false, g5
        end
        local function getFuseTurnCoordinator()
            return getgenv() [("AliceHUB_SAE_Turn")]
        end
        local function enqueueFuseWebhook(p5)
            local q5 = getgenv() [("AliceHUB_SAE_WebhookEnqueue")]
            if type (q5) == ("function") then
                pcall(q5, p5)
            end
        end
        local function getFuseWebhookAssetInfo(s5)
            local t5 = getgenv() [("AliceHUB_SAE_WebhookAssetInfo")]
            if type (t5) ~= ("function") then
                return nil
            end
            local u5, v5 = pcall(t5, s5)
            if u5 then
                return v5
            end
            return nil
        end
        local function getFuseWebhookThumbnail(x5)
            local y5 = getgenv() [("AliceHUB_SAE_WebhookThumbUrl")]
            if type (y5) ~= ("function") then
                return nil
            end
            local z5, A5 = pcall(y5, x5)
            if z5 then
                return A5
            end
            return nil
        end
        local function buildFuseWebhookPayload(C5, D5, E5)
            local F5 = getgenv() [("AliceHUB_SAE_WebhookRarityColor")] F5 = type (F5) == ("table") and F5 or {}
            local G5 = getFuseWebhookAssetInfo(C5) or {}
            local H5 = (type (E5) == ("table") and E5.DisplayName) or ("Egg")
            local I5 = nil
            if type (E5) == ("table") and type (E5.Icon) == ("string") then
                I5 = E5.Icon:match(("%d+"))
            end
            local J5 = getgenv() [("AliceHUB_SAE_WebhookName")]
            if type (J5) ~= ("string") or J5 == ("") then
                J5 = ("AliceHUB - Steal An Egg")
            end
            return {username = J5, embeds = {{title = ("Fused: ") .. tostring(G5.name or C5 or ("?")) .. (" x3 -> ") .. tostring(H5), color = F5 [D5 or G5.rarity or ("")] or 5793266, fields = {{name = ("Input rarity"), value = tostring(D5 or G5.rarity or ("?")), inline = true}, {name = ("Input category"), value = tostring(C5 or ("?")), inline = true}, {name = ("Reward egg"), value = tostring(H5), inline = true}, {name = ("Username"), value = O3.Name, inline = true},}, thumbnail = I5 and getFuseWebhookThumbnail(I5) and {url = getFuseWebhookThumbnail(I5)} or nil, footer = {text = J5},}},}
        end
        local function isFuseCandidate(L5, M5, N5)
            if type (M5) ~= ("table") then
                return false
            end
            local O5 = getFuseAssetDefinition(M5.Category)
            if not O5 or O5.CannotFuse == true then
                return false
            end
            if M5.IsFavorite == true or M5.InFuse == true then
                return false
            end
            if N5 [L5] then
                return false
            end
            return true
        end
        local function getEquippedAssetSet(Q5)
            local R5 = {}
            if type (Q5.EquippedAssets) == ("table") then
                for S5, T5 in ipairs(Q5.EquippedAssets) do
                    R5 [T5] = true
                end
            end
            return R5
        end
        local function collectFuseCandidates()
            local V5 = getFuseSaveData()
            if not V5 or type (V5.Inventory) ~= ("table") then
                return {}
            end
            local W5 = getEquippedAssetSet(V5)
            local X5 = {}
            for Y5, Z5 in pairs(V5.Inventory) do
                local a6 = decodeFuseAssetItem(Z5)
                if a6 and isFuseCandidate(Y5, a6, W5) then
                    local b6 = a6.Category
                    local c6 = X5 [b6]
                    if not c6 then
                        c6 = {category = b6, uids = {}}
                        X5 [b6] = c6
                    end
                    c6.uids [#c6.uids + 1] = Y5
                end
            end
            for d6, e6 in pairs(X5) do
                table.sort(e6.uids)
            end
            return X5
        end
        local function chooseFuseTriple(g6)
            local h6 = collectFuseCandidates()
            local i6 = {}
            for j6, k6 in pairs(h6) do
                if #k6.uids >= 3 then
                    local l6 = getFuseAssetDefinition(j6)
                    local m6 = l6 and type (l6.Rarity) == ("table") and l6.Rarity._id or nil
                    local n6 = l6 and type (l6.Rarity) == ("table") and tonumber(l6.Rarity.RarityNumber) or 0
                    local o6 = true
                    if g6 then
                        o6 = m6 ~= nil and _G [("SAE_FuseRarity")] [m6] == true
                    end
                    if o6 then
                        i6 [#i6 + 1] = {category = j6, uids = k6.uids, rarNum = n6}
                    end
                end
            end
            if #i6 == 0 then
                return nil, nil
            end
            table.sort(i6, function (p6, q6)
                if p6.rarNum ~= q6.rarNum then
                    return p6.rarNum > q6.rarNum
                end
                return p6.category < q6.category
            end
            )
            local r6 = i6 [1]
            return r6.category, {r6.uids [1], r6.uids [2], r6.uids [3]}
        end
        local function getFusePriceForUids(saveData, uids)
            if type (saveData) ~= ("table") or type (saveData.Inventory) ~= ("table") then
                return nil
            end
            local kernel = requireFuseSharedModule({("Util")}, ("FuseKernel"))
            if not kernel or type (kernel.PriceFor) ~= ("function") then
                return nil
            end
            local items = {}
            for index, uid in ipairs(uids or {}) do
                local record = saveData.Inventory [uid]
                if record == nil then
                    return nil
                end
                local decoded = decodeFuseAssetItem(record)
                if type (decoded) ~= ("table") then
                    return nil
                end
                items [index] = decoded
            end
            local ok, price = pcall(kernel.PriceFor, items)
            return ok and tonumber(price) or nil
        end
        local pendingFuseWebhook = nil
        local function finishPendingFuseReveal()
            local saveData = getFuseSaveData()
            if not (saveData and saveData.FusionLocked == true) then
                return false, ("not locked")
            end
            local ok, reward = invokeFuseAction(("COMPLETE_REVEAL"), nil, S3, T3)
            if ok and pendingFuseWebhook then
                local pending = pendingFuseWebhook
                pendingFuseWebhook = nil
                enqueueFuseWebhook(buildFuseWebhookPayload(pending.category, pending.rarity, reward))
            end
            return ok, reward
        end
        local function clearFuseMachineSlots()
            local t6 = getFuseSaveData()
            if not t6 or type (t6.FusionSlots) ~= ("table") then
                return true
            end
            local u6 = true
            for v6 = 1, 3 do
                local w6 = t6.FusionSlots [v6]
                if w6 ~= nil then
                    local removeRemote = getFuseRemote(("REMOVE_MOB"))
                    if removeRemote then
                        local x6 = invokeFuseAction(("REMOVE_MOB"), w6, S3, T3)
                        if not x6 then
                            u6 = false
                        end
                    end
                end
            end
            return u6
        end
        local function insertFuseCandidates(z6)
            local A6 = {}
            for B6, C6 in ipairs(z6) do
                local D6, E6 = invokeFuseAction(("INSERT_MOB"), C6, S3, T3)
                if not D6 then
                    for F6, G6 in ipairs(A6) do
                        invokeFuseAction(("REMOVE_MOB"), G6, S3, T3)
                    end
                    return false, E6
                end
                A6 [#A6 + 1] = C6
            end
            return true, nil
        end
        local H6 = {("close"), ("near"), ("distance"), ("range"), ("too far"), ("proximity")}
        local function isFuseProximityError(J6)
            if type (J6) ~= ("string") then
                return false
            end
            local K6 = J6:lower()
            for L6, M6 in ipairs(H6) do
                if K6:find(M6, 1, true) then
                    return true
                end
            end
            return false
        end
        local function getFuseMachinePart()
            local O6, P6 = pcall(function ()
                return workspace.__OBJECTS.Machines.FuseMachine.Machine
            end
            )
            if O6 and typeof(P6) == ("Instance") and P6:IsA(("BasePart")) then
                return P6
            end
            return nil
        end
        local function moveToFuseMachine()
            local R6 = getgenv() [("AliceHUB_SAE_MoveTo")]
            local S6 = getFuseMachinePart()
            if type (R6) ~= ("function") or not S6 then
                return false
            end
            local T6 = pcall(R6, S6.CFrame, function ()
                return true
            end
            , nil)
            return T6
        end
        local function fuseCandidateTriple(V6, W6)
            local X6 = getFuseSaveData()
            if X6 and X6.FusionLocked == true then
                local revealOk, revealResult = finishPendingFuseReveal()
                if revealOk then
                    return ("revealed"), nil
                end
                return ("waiting"), tostring(revealResult or ("reveal pending"))
            end
            pcall(function ()
                local shared = L3:FindFirstChild(("Shared"))
                local remotesModule = shared and shared:FindFirstChild(("Remotes"))
                local ok, remotes = remotesModule and pcall(require, remotesModule)
                local confirm = ok and type(remotes) == ("table") and remotes.Fusery and remotes.Fusery.ConfirmBriefing
                if confirm and type(confirm.InvokeServer) == ("function") and X6 and X6.FusionInfoAcknowledged ~= true then
                    confirm:InvokeServer()
                end
            end)
            if X6 and type (X6.EggInventory) == ("table") then
                local Y6 = requireFuseSharedModule({("Types")}, ("Eggs"))
                local Z6 = Y6 and tonumber(Y6.MAX_INVENTORY) or nil
                if Z6 then
                    local a7 = 0
                    for b7 in pairs(X6.EggInventory) do
                        a7 = a7 + 1
                    end
                    if a7 >= Z6 then
                        return ("waiting"), ("egg inventory full")
                    end
                end
            end
            local fusePrice = getFusePriceForUids(X6, W6)
            if fusePrice and X6 then
                local money = tonumber(X6.Money) or 0
                if money < fusePrice then
                    return ("waiting"), ("not enough money")
                end
            end
            if not clearFuseMachineSlots() then
                return ("failed"), ("could not clear stale slots")
            end
            local c7, d7 = insertFuseCandidates(W6)
            if not c7 then
                if isFuseProximityError(d7) and moveToFuseMachine() then
                    c7, d7 = insertFuseCandidates(W6)
                end
                if not c7 then
                    return ("failed"), d7
                end
            end
            local e7, f7 = invokeFuseAction(("START_FUSE"), nil, S3, T3)
            if not e7 and isFuseProximityError(f7) and moveToFuseMachine() then
                e7, f7 = invokeFuseAction(("START_FUSE"), nil, S3, T3)
            end
            if not e7 then
                for g7, h7 in ipairs(W6) do
                    invokeFuseAction(("REMOVE_MOB"), h7, S3, T3)
                end
                return ("failed"), tostring(f7)
            end
            local k7 = getFuseAssetDefinition(V6)
            local l7 = k7 and type (k7.Rarity) == ("table") and k7.Rarity._id or nil
            pendingFuseWebhook = {category = V6, rarity = l7}
            local revealWaitStarted = os.clock()
            while (os.clock() - revealWaitStarted) < 1.25 do
                local latestSave = getFuseSaveData()
                if latestSave and latestSave.FusionLocked == true then
                    local revealOk = finishPendingFuseReveal()
                    if revealOk then
                        return ("fused"), nil
                    end
                    return ("started"), ("reveal pending")
                end
                N3.Heartbeat:Wait()
            end
            return ("started"), nil
        end
        local m7 = 0
        local function startFuseWorker(o7, p7)
            m7 = m7 + 1
            local q7 = m7
            local function isFuseWorkerCurrent()
                return p7() and m7 == q7
            end
            local activeFuseTurn = nil
            spawnAliceWorker(("FuseWorker"), function ()
                while isFuseWorkerCurrent() do
                    if getgenv() [("AliceHUB_SAE_FarmEggBusy")] then
                        local s7 = os.clock()
                        while isFuseWorkerCurrent() and (os.clock() - s7) < R3 do
                            N3.Heartbeat:Wait()
                        end
                    else
                        local t7, u7 = chooseFuseTriple(o7)
                        if not t7 then
                            local v7 = os.clock()
                            while isFuseWorkerCurrent() and (os.clock() - v7) < Q3 do
                                N3.Heartbeat:Wait()
                            end
                        else
                            local w7 = getFuseTurnCoordinator()
                            local x7 = nil
                            if type (w7) == ("table") and type (w7.take) == ("function") then
                                x7 = w7.take(("fuse"), 15)
                                activeFuseTurn = x7
                            end
                            if type (w7) == ("table") and x7 == nil then
                                local y7 = os.clock()
                                while isFuseWorkerCurrent() and (os.clock() - y7) < R3 do
                                    N3.Heartbeat:Wait()
                                end
                            else
                                fuseCandidateTriple(t7, u7)
                                if type (w7) == ("table") and type (w7.give) == ("function") and x7 ~= nil then
                                    w7.give(x7)
                                    activeFuseTurn = nil
                                end
                                local z7 = os.clock()
                                while isFuseWorkerCurrent() and (os.clock() - z7) < P3 do
                                    N3.Heartbeat:Wait()
                                end
                            end
                        end
                    end
                end
            end
            )
        end
        local function countSelectedFuseRarities()
            local B7 = 0
            for C7, D7 in ipairs(O4) do
                if _G [("SAE_FuseRarity")] [D7] == true then
                    B7 = B7 + 1
                end
            end
            return B7
        end
        local setFuseAllEnabled
        local setFuseByRarityEnabled
        function setFuseAllEnabled(G7)
            _G [("SAE_FuseAll")] = G7 and true or false
            if _G [("SAE_FuseAll")] then
                if _G [("SAE_FuseByRarity")] then
                    _G [("SAE_FuseByRarity")] = false pcall(function ()
                        local H7 = getgenv() [("AliceHUB_Flags")]
                        local I7 = H7 and H7 [("SAE_FuseByRarity")]
                        if I7 and type (I7.SetAndFire) == ("function") then
                            I7:SetAndFire(false)
                        end
                    end
                    )
                end
                startFuseWorker(false, function ()
                    return _G [("SAE_FuseAll")]
                end
                )
            else
                m7 = m7 + 1
            end
        end
        function setFuseByRarityEnabled(J7)
            _G [("SAE_FuseByRarity")] = J7 and true or false
            if _G [("SAE_FuseByRarity")] then
                if _G [("SAE_FuseAll")] then
                    _G [("SAE_FuseAll")] = false pcall(function ()
                        local K7 = getgenv() [("AliceHUB_Flags")]
                        local L7 = K7 and K7 [("SAE_FuseAll")]
                        if L7 and type (L7.SetAndFire) == ("function") then
                            L7:SetAndFire(false)
                        end
                    end
                    )
                end
                startFuseWorker(true, function ()
                    return _G [("SAE_FuseByRarity")]
                end
                )
            else
                m7 = m7 + 1
            end
        end
        _G [("SAE_FuseByRarity")] = _G [("SAE_FuseByRarity")] or false
        local function registerFuseConfigEntry(N7, O7, P7)
            local Q7 = getgenv() [("AliceHUB_SAE_Config")]
            if not Q7 then
                Q7 = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = Q7
            end
            if Q7._byKey [N7] then
                Q7._byKey [N7].get = O7
                Q7._byKey [N7].set = P7
            else
                local R7 = {key = N7, get = O7, set = P7}
                Q7._entries [#Q7._entries + 1] = R7
                Q7._byKey [N7] = R7
            end
        end
        local function notifyFuseConfigChanged()
            local T7 = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (T7) == ("function") then
                T7()
            end
        end
        local function setFuseUiFlag(V7, W7)
            pcall(function ()
                local X7 = getgenv() [("AliceHUB_Flags")]
                local Y7 = X7 and X7 [V7]
                if Y7 and type (Y7.SetAndFire) == ("function") then
                    Y7:SetAndFire(W7)
                end
            end
            )
        end
        local function fuseRarityListToMap(a8)
            local b8 = {}
            if type (a8) == ("table") then
                for c8, d8 in ipairs(a8) do
                    if type (d8) == ("string") and P4 [d8] then
                        b8 [d8] = true
                    end
                end
            end
            return b8
        end
        local function fuseRarityMapToList(f8)
            local g8 = {}
            for h8, i8 in ipairs(O4) do
                if f8 [i8] then
                    g8 [#g8 + 1] = i8
                end
            end
            return g8
        end
        local j8 = K3:Section({Title = ("Auto Fuse")})
        j8:MultiDropdown({Title = ("Fuse Rarity"), Desc = ("Which rarities to fuse (used only by \"by Rarity\" below). Empty = nothing is fused"), Flag = ("SAE_FuseRarity"), Options = O4, Default = {}, Callback = function (k8)
            _G [("SAE_FuseRarity")] = fuseRarityListToMap(k8)
            notifyFuseConfigChanged()
        end
        ,})
        j8:Toggle({Title = ("Enable Auto Fuse All"), Desc = ("Fuse any 3 matching pets regardless of rarity. Runs only outside a Farm Egg cycle"), Flag = ("SAE_FuseAll"), ID = ("SAE_FuseAll"), Value = false, Callback = function (l8)
            setFuseAllEnabled(l8)
            notifyFuseConfigChanged()
        end
        ,})
        j8:Toggle({Title = ("Enable Auto Fuse by Rarity"), Desc = ("Fuse only pets whose rarity is picked above. Runs only outside a Farm Egg cycle"), Flag = ("SAE_FuseByRarity"), ID = ("SAE_FuseByRarity"), Value = false, Callback = function (m8)
            if m8 and countSelectedFuseRarities() == 0 then
                setFuseUiFlag(("SAE_FuseByRarity"), false)
                J3:Notify({Title = ("Auto Fuse"), Content = ("Pick at least one rarity first — nothing was enabled"), Duration = 5,})
                notifyFuseConfigChanged()
                return
            end
            setFuseByRarityEnabled(m8)
            notifyFuseConfigChanged()
        end
        ,})
        registerFuseConfigEntry(("SAE_FuseRarity"), function ()
            return fuseRarityMapToList(_G [("SAE_FuseRarity")])
        end
        , function (n8)
            _G [("SAE_FuseRarity")] = fuseRarityListToMap(n8)
            setFuseUiFlag(("SAE_FuseRarity"), fuseRarityMapToList(_G [("SAE_FuseRarity")]))
        end
        )
        registerFuseConfigEntry(("SAE_FuseAll"), function ()
            return _G [("SAE_FuseAll")]
        end
        , function (o8)
            o8 = o8 and true or false setFuseUiFlag(("SAE_FuseAll"), o8)
            setFuseAllEnabled(o8)
        end
        )
        registerFuseConfigEntry(("SAE_FuseByRarity"), function ()
            return _G [("SAE_FuseByRarity")]
        end
        , function (p8)
            p8 = p8 and true or false
            if p8 and countSelectedFuseRarities() == 0 then
                p8 = false
            end
            setFuseUiFlag(("SAE_FuseByRarity"), p8)
            setFuseByRarityEnabled(p8)
        end
        )
    end
    )
    runAliceModule("UpgradePen", function (...)
        local q8 = getgenv() [("AliceHUB_WindUI")]
        local r8 = getgenv() [("AliceHUB_TabUpgrade")] or getgenv() [("AliceHUB_TabFarm")]
        if not r8 then
            return
        end
        local s8 = game:GetService(("ReplicatedStorage"))
        local t8 = game:GetService(("RunService"))
        local u8 = 5.0
        _G [("SAE_AutoUpgradePen")] = _G [("SAE_AutoUpgradePen")] or false
        local v8 = nil
        -- ============================================================
        -- Auto Upgrade Pen / Trail
        -- ============================================================
        local function getUpgradePenSaveModule()
            if v8 then
                return v8
            end
            local x8 = s8:FindFirstChild(("Shared"))
            local y8 = x8 and x8:FindFirstChild(("Save"))
            if not y8 then
                return nil
            end
            local z8, A8 = pcall(require, y8)
            if z8 and type (A8) == ("table") then
                v8 = A8
            end
            return v8
        end
        local function getUpgradePenSaveData()
            local C8 = getUpgradePenSaveModule()
            if not C8 or type (C8.Get) ~= ("function") then
                return nil
            end
            local D8, E8 = pcall(C8.Get)
            if D8 and type (E8) == ("table") then
                return E8
            end
            return nil
        end
        local F8 = nil
        local function getBaseUpgradeController()
            if F8 then
                return F8
            end
            local H8 = s8:FindFirstChild(("Client"))
            local I8 = H8 and H8:FindFirstChild(("BaseUpgrade"))
            if not I8 then
                return nil
            end
            local J8, K8 = pcall(require, I8)
            if J8 and type (K8) == ("table") then
                F8 = K8
            end
            return F8
        end
        local function getBaseUpgradeLevel(M8)
            local N8 = M8 and tonumber(M8.BaseUpgradeLevel)
            return N8
        end
        local function isNextBaseTierAffordable(P8)
            local Q8 = getBaseUpgradeController()
            if not (Q8 and type (Q8.IsNextTierAffordable) == ("function")) then
                return nil
            end
            local R8, S8 = pcall(Q8.IsNextTierAffordable, P8)
            if not R8 then
                return nil
            end
            return S8 and true or false
        end
        local function requestBaseTierRaise()
            local U8 = s8:FindFirstChild(("Shared"))
            local V8 = U8 and U8:FindFirstChild(("Remotes"))
            if not V8 then
                return false
            end
            local W8, X8 = pcall(require, V8)
            if not (W8 and type (X8) == ("table") and type (X8.Homestead) == ("table")) then
                return false
            end
            local Y8 = X8.Homestead.AskBaseTierRaise
            if not (Y8 and Y8:IsA(("RemoteEvent"))) then
                return false
            end
            return (pcall(function ()
                Y8:FireServer()
            end
            ))
        end
        local Z8 = 0
        local function setAutoUpgradePenEnabled(b9)
            _G [("SAE_AutoUpgradePen")] = b9 and true or false Z8 = Z8 + 1
            if not _G [("SAE_AutoUpgradePen")] then
                return
            end
            local c9 = Z8
            local function isUpgradePenWorkerCurrent()
                return _G [("SAE_AutoUpgradePen")] and Z8 == c9
            end
            task.spawn(function ()
                local e9 = 0
                while isUpgradePenWorkerCurrent() do
                    local f9 = getUpgradePenSaveData()
                    local g9 = getBaseUpgradeLevel(f9)
                    local h9 = isNextBaseTierAffordable(f9)
                    if h9 ~= false and (os.clock() - e9) >= u8 then
                        e9 = os.clock()
                        requestBaseTierRaise()
                        local i9 = os.clock()
                        while isUpgradePenWorkerCurrent() and (os.clock() - i9) < 1.0 do
                            t8.Heartbeat:Wait()
                        end
                        local j9 = getUpgradePenSaveData()
                        local k9 = getBaseUpgradeLevel(j9)
                        if k9 and g9 and k9 > g9 then
                            pcall(function ()
                                q8:Notify({Title = ("Auto Upgrade Pen"), Content = (("Pen upgraded: level %d -> %d.")):format(g9, k9), Duration = 5,})
                            end
                            )
                        end
                    end
                    local l9 = os.clock()
                    while isUpgradePenWorkerCurrent() and (os.clock() - l9) < u8 do
                        t8.Heartbeat:Wait()
                    end
                end
            end
            )
        end
        local function registerUpgradePenConfigEntry(n9, o9, p9)
            local q9 = getgenv() [("AliceHUB_SAE_Config")]
            if not q9 then
                q9 = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = q9
            end
            if q9._byKey [n9] then
                q9._byKey [n9].get = o9
                q9._byKey [n9].set = p9
            else
                local r9 = {key = n9, get = o9, set = p9}
                q9._entries [#q9._entries + 1] = r9
                q9._byKey [n9] = r9
            end
        end
        local function notifyUpgradePenConfigChanged()
            local t9 = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (t9) == ("function") then
                t9()
            end
        end
        local function setUpgradePenUiFlag(v9, w9)
            pcall(function ()
                local x9 = getgenv() [("AliceHUB_Flags")]
                local y9 = x9 and x9 [v9]
                if y9 and type (y9.SetAndFire) == ("function") then
                    y9:SetAndFire(w9)
                end
            end
            )
        end
        local z9 = r8:Section({Title = ("Upgrade")})
        getgenv() [("AliceHUB_SAE_UpgradeSection")] = z9
        z9:Toggle({Title = ("Enable Auto Upgrade Pen"), Flag = ("SAE_AutoUpgradePen"), ID = ("SAE_AutoUpgradePen"), Value = false, Callback = function (A9)
            setAutoUpgradePenEnabled(A9)
            notifyUpgradePenConfigChanged()
        end
        ,})
        registerUpgradePenConfigEntry(("SAE_AutoUpgradePen"), function ()
            return _G [("SAE_AutoUpgradePen")]
        end
        , function (B9)
            B9 = B9 and true or false setUpgradePenUiFlag(("SAE_AutoUpgradePen"), B9)
            setAutoUpgradePenEnabled(B9)
        end
        )
    end
    )
    runAliceModule("UpgradeTrail", function (...)
        local C9 = getgenv() [("AliceHUB_WindUI")]
        local D9 = getgenv() [("AliceHUB_TabUpgrade")] or getgenv() [("AliceHUB_TabFarm")]
        if not D9 then
            return
        end
        local E9 = game:GetService(("ReplicatedStorage"))
        local F9 = game:GetService(("RunService"))
        local G9 = 5.0
        _G [("SAE_AutoUpgradeTrail")] = _G [("SAE_AutoUpgradeTrail")] or false
        local H9 = nil
        local function getTrailSaveModule()
            if H9 then
                return H9
            end
            local J9 = E9:FindFirstChild(("Shared"))
            local K9 = J9 and J9:FindFirstChild(("Save"))
            if not K9 then
                return nil
            end
            local L9, M9 = pcall(require, K9)
            if L9 and type (M9) == ("table") then
                H9 = M9
            end
            return H9
        end
        local function getTrailSaveData()
            local O9 = getTrailSaveModule()
            if not O9 or type (O9.Get) ~= ("function") then
                return nil
            end
            local P9, Q9 = pcall(O9.Get)
            if P9 and type (Q9) == ("table") then
                return Q9
            end
            return nil
        end
        local R9 = nil
        local function getTrailUpgradeList()
            if R9 then
                return R9
            end
            local T9 = E9:FindFirstChild(("Data"))
            local U9 = T9 and T9:FindFirstChild(("Trails"))
            if not U9 then
                return nil
            end
            local V9, W9 = pcall(require, U9)
            if not (V9 and type (W9) == ("table") and type (W9.Directory) == ("table")) then
                return nil
            end
            local X9 = {}
            for Y9, Z9 in pairs(W9.Directory) do
                if type (Z9) == ("table") and type (Z9.Price) == ("number") then
                    X9 [#X9 + 1] = {id = Y9, price = Z9.Price}
                end
            end
            table.sort(X9, function (aaa, baa)
                return aaa.price < baa.price
            end
            )
            R9 = X9
            return R9
        end
        local function getNextTrailUpgrade(daa)
            local eaa = getTrailUpgradeList()
            if not eaa then
                return nil
            end
            local faa = daa and daa.TrailInventory
            for gaa, haa in ipairs(eaa) do
                if not (faa and faa [haa.id] == true) then
                    return haa
                end
            end
            return nil
        end
        local function purchaseTrailUpgrade(jaa)
            local kaa = E9:FindFirstChild(("Shared"))
            local laa = kaa and kaa:FindFirstChild(("Remotes"))
            if not laa then
                return false
            end
            local maa, naa = pcall(require, laa)
            if not (maa and type (naa) == ("table") and type (naa.Trailwear) == ("table")) then
                return false
            end
            local oaa = naa.Trailwear.AskPurchase
            if not (oaa and oaa:IsA(("RemoteFunction"))) then
                return false
            end
            local paa, qaa = pcall(function ()
                return oaa:InvokeServer(jaa)
            end
            )
            return paa and qaa ~= false
        end
        local raa = 0
        local function setAutoUpgradeTrailEnabled(taa)
            _G [("SAE_AutoUpgradeTrail")] = taa and true or false raa = raa + 1
            if not _G [("SAE_AutoUpgradeTrail")] then
                return
            end
            local uaa = raa
            local function isUpgradeTrailWorkerCurrent()
                return _G [("SAE_AutoUpgradeTrail")] and raa == uaa
            end
            task.spawn(function ()
                while isUpgradeTrailWorkerCurrent() do
                    local waa = getTrailSaveData()
                    local xaa = getNextTrailUpgrade(waa)
                    if not xaa then
                        break
                    end
                    local yaa = waa and tonumber(waa.Money) or 0
                    if yaa >= xaa.price then
                        local zaa = waa and waa.TrailInventory and waa.TrailInventory [xaa.id]
                        local Aaa = purchaseTrailUpgrade(xaa.id)
                        if Aaa then
                            local Baa = os.clock()
                            while isUpgradeTrailWorkerCurrent() and (os.clock() - Baa) < 1.0 do
                                F9.Heartbeat:Wait()
                            end
                            local Caa = getTrailSaveData()
                            local Daa = Caa and Caa.TrailInventory and Caa.TrailInventory [xaa.id] == true
                            if Daa then
                                pcall(function ()
                                    C9:Notify({Title = ("Auto Upgrade Trail"), Content = (("Bought %s (price %d).")):format(xaa.id, xaa.price), Duration = 5,})
                                end
                                )
                            end
                        end
                    else
                        local Eaa = os.clock()
                        while isUpgradeTrailWorkerCurrent() and (os.clock() - Eaa) < G9 do
                            F9.Heartbeat:Wait()
                        end
                    end
                end
            end
            )
        end
        local function registerUpgradeTrailConfigEntry(Gaa, Haa, Iaa)
            local Jaa = getgenv() [("AliceHUB_SAE_Config")]
            if not Jaa then
                Jaa = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = Jaa
            end
            if Jaa._byKey [Gaa] then
                Jaa._byKey [Gaa].get = Haa
                Jaa._byKey [Gaa].set = Iaa
            else
                local Kaa = {key = Gaa, get = Haa, set = Iaa}
                Jaa._entries [#Jaa._entries + 1] = Kaa
                Jaa._byKey [Gaa] = Kaa
            end
        end
        local function notifyUpgradeTrailConfigChanged()
            local Maa = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (Maa) == ("function") then
                Maa()
            end
        end
        local function setUpgradeTrailUiFlag(Oaa, Paa)
            pcall(function ()
                local Qaa = getgenv() [("AliceHUB_Flags")]
                local Raa = Qaa and Qaa [Oaa]
                if Raa and type (Raa.SetAndFire) == ("function") then
                    Raa:SetAndFire(Paa)
                end
            end
            )
        end
        local Saa = getgenv() [("AliceHUB_SAE_UpgradeSection")]
        if not Saa then
            Saa = D9:Section({Title = ("Upgrade")})
        end
        Saa:Toggle({Title = ("Enable Auto Upgrade Trail"), Flag = ("SAE_AutoUpgradeTrail"), ID = ("SAE_AutoUpgradeTrail"), Value = false, Callback = function (Taa)
            setAutoUpgradeTrailEnabled(Taa)
            notifyUpgradeTrailConfigChanged()
        end
        ,})
        registerUpgradeTrailConfigEntry(("SAE_AutoUpgradeTrail"), function ()
            return _G [("SAE_AutoUpgradeTrail")]
        end
        , function (Uaa)
            Uaa = Uaa and true or false setUpgradeTrailUiFlag(("SAE_AutoUpgradeTrail"), Uaa)
            setAutoUpgradeTrailEnabled(Uaa)
        end
        )
    end
    )
    runAliceModule("IndexReward", function (...)
        local Vaa = getgenv() [("AliceHUB_WindUI")]
        local Waa = getgenv() [("AliceHUB_TabUpgrade")] or getgenv() [("AliceHUB_TabFarm")]
        if not Waa then
            return
        end
        local Xaa = game:GetService(("ReplicatedStorage"))
        local Yaa = nil
        -- ============================================================
        -- Auto Index Reward
        -- ============================================================
        local function getIndexSaveModule()
            if Yaa then
                return Yaa
            end
            local aba = Xaa:FindFirstChild(("Shared"))
            local bba = aba and aba:FindFirstChild(("Save"))
            if not bba then
                return nil
            end
            local cba, dba = pcall(require, bba)
            if cba and type (dba) == ("table") then
                Yaa = dba
            end
            return Yaa
        end
        local function getIndexSaveData()
            local fba = getIndexSaveModule()
            if not fba or type (fba.Get) ~= ("function") then
                return nil
            end
            local gba, hba = pcall(fba.Get)
            if gba and type (hba) == ("table") then
                return hba
            end
            return nil
        end
        local iba = nil
        local function getIndexRemotes()
            if iba then
                return iba
            end
            local kba = Xaa:FindFirstChild(("Shared"))
            local lba = kba and kba:FindFirstChild(("Remotes"))
            if not lba then
                return nil
            end
            local mba, nba = pcall(require, lba)
            if mba and type (nba) == ("table") then
                iba = nba
            end
            return iba
        end
        local function hasUnclaimedIndexRewards(pba)
            if type (pba) ~= ("table") or type (pba.Index) ~= ("table") then
                return false
            end
            local qba = pba.IndexClaimedCategories
            if type (qba) ~= ("table") then
                qba = {}
            end
            for rba, sba in pairs(pba.Index) do
                if sba == true and qba [rba] ~= true then
                    return true
                end
            end
            return false
        end
        _G [("SAE_AutoIndexClaim")] = _G [("SAE_AutoIndexClaim")] or false
        local tba = 0
        local uba = 2.0
        local vba = false
        local function claimAllIndexRewards()
            if not _G [("SAE_AutoIndexClaim")] then
                return
            end
            local xba = os.clock()
            if (xba - tba) < uba then
                vba = true
                return
            end
            local yba = getIndexRemotes()
            local zba = yba and type (yba.Codex) == ("table") and yba.Codex.AskRedeemAll
            if not (zba and type (zba.InvokeServer) == ("function")) then
                return
            end
            tba = xba
            vba = false task.spawn(function ()
                local Aba, Bba, Cba, Dba = pcall(function ()
                    return zba:InvokeServer()
                end
                )
                if Aba and Bba ~= false then
                    local Eba = (type (Dba) == ("table")) and #Dba or 0
                    if Eba > 0 then
                        pcall(function ()
                            Vaa:Notify({Title = ("Index Reward"), Content = (("Claimed %d index reward%s.")):format(Eba, Eba == 1 and ("") or ("s")), Duration = 5,})
                        end
                        )
                    end
                end
                if vba then
                    task.wait(uba)
                    claimAllIndexRewards()
                end
            end
            )
        end
        local function checkIndexRewards()
            local Gba = getIndexSaveData()
            if hasUnclaimedIndexRewards(Gba) then
                claimAllIndexRewards()
            end
        end
        local Hba = nil
        local function setAutoIndexClaimEnabled(Jba)
            _G [("SAE_AutoIndexClaim")] = Jba and true or false
            if Hba then
                Hba:Destroy()
                Hba = nil
            end
            if not _G [("SAE_AutoIndexClaim")] then
                return
            end
            checkIndexRewards()
            local Kba = getIndexSaveModule()
            if not Kba or type (Kba.WatchFields) ~= ("function") then
                return
            end
            local Lba, Mba = pcall(Kba.WatchFields, {("Index"), ("IndexClaimedCategories")}, function ()
                if _G [("SAE_AutoIndexClaim")] then
                    claimAllIndexRewards()
                end
            end
            )
            if Lba and Mba then
                Hba = Mba
            end
        end
        local function registerIndexConfigEntry(Oba, Pba, Qba)
            local Rba = getgenv() [("AliceHUB_SAE_Config")]
            if not Rba then
                Rba = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = Rba
            end
            if Rba._byKey [Oba] then
                Rba._byKey [Oba].get = Pba
                Rba._byKey [Oba].set = Qba
            else
                local Sba = {key = Oba, get = Pba, set = Qba}
                Rba._entries [#Rba._entries + 1] = Sba
                Rba._byKey [Oba] = Sba
            end
        end
        local function notifyIndexConfigChanged()
            local Uba = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (Uba) == ("function") then
                Uba()
            end
        end
        local function setIndexUiFlag(Wba, Xba)
            pcall(function ()
                local Yba = getgenv() [("AliceHUB_Flags")]
                local Zba = Yba and Yba [Wba]
                if Zba and type (Zba.SetAndFire) == ("function") then
                    Zba:SetAndFire(Xba)
                end
            end
            )
        end
        local aca = Waa:Section({Title = ("Index")})
        aca:Toggle({Title = ("Auto Claim Index Reward"), Desc = ("Claim index rewards the instant a new species is discovered — no need to open the Index panel"), Flag = ("SAE_AutoIndexClaim"), ID = ("SAE_AutoIndexClaim"), Value = false, Callback = function (bca)
            setAutoIndexClaimEnabled(bca)
            notifyIndexConfigChanged()
        end
        ,})
        registerIndexConfigEntry(("SAE_AutoIndexClaim"), function ()
            return _G [("SAE_AutoIndexClaim")]
        end
        , function (cca)
            cca = cca and true or false setIndexUiFlag(("SAE_AutoIndexClaim"), cca)
            setAutoIndexClaimEnabled(cca)
        end
        )
    end
    )
    runAliceModule("PlaceHatch", function (...)
        local dca = getgenv() [("AliceHUB_WindUI")]
        local eca = getgenv() [("AliceHUB_TabFarm")]
        if not eca then
            return
        end
        local fca = game:GetService(("ReplicatedStorage"))
        local gca = game:GetService(("Players"))
        local hca = game:GetService(("RunService"))
        local ica = gca.LocalPlayer
        local jca = 4
        local kca = 6
        local lca = 0.25
        local mca = 0.35
        local nca = 0.35
        local oca = 2.0
        local pca = 15
        -- ============================================================
        -- Egg placement / hatch / Always Best / pet data
        -- ============================================================
        local function getClientModuleScript(rca)
            local sca = fca:FindFirstChild(("Client"))
            return sca and sca:FindFirstChild(rca) or nil
        end
        local tca, uca, vca, wca
        local function getPlaceEggState()
            if tca then
                return tca
            end
            local yca = getClientModuleScript(("EggState"))
            if not yca then
                return nil
            end
            local zca, Aca = pcall(require, yca)
            if zca and type (Aca) == ("table") then
                tca = Aca
            end
            return tca
        end
        local function getAssetRoster()
            if uca then
                return uca
            end
            local Cca = getClientModuleScript(("AssetRoster"))
            if not Cca then
                return nil
            end
            local Dca, Eca = pcall(require, Cca)
            if Dca and type (Eca) == ("table") then
                uca = Eca
            end
            return uca
        end
        local function getPlaceEggRemotes()
            if wca then
                return wca
            end
            local Gca = fca:FindFirstChild(("Shared"))
            local Hca = Gca and Gca:FindFirstChild(("Remotes"))
            if not Hca then
                return nil
            end
            local Ica, Jca = pcall(require, Hca)
            if Ica and type (Jca) == ("table") then
                wca = Jca
            end
            return wca
        end
        local function getPlaceEggSaveModule()
            if vca then
                return vca
            end
            local Lca = fca:FindFirstChild(("Shared"))
            local Mca = Lca and Lca:FindFirstChild(("Save"))
            if not Mca then
                return nil
            end
            local Nca, Oca = pcall(require, Mca)
            if Nca and type (Oca) == ("table") then
                vca = Oca
            end
            return vca
        end
        local function getPlaceEggSaveData()
            local Qca = getPlaceEggSaveModule()
            if not Qca or type (Qca.Get) ~= ("function") then
                return nil
            end
            local Rca, Sca = pcall(Qca.Get)
            if Rca and type (Sca) == ("table") then
                return Sca
            end
            return nil
        end
        local Tca = nil
        local function getPlaceEggAssetDirectory()
            if Tca ~= nil then
                return Tca or nil
            end
            local Vca = fca:FindFirstChild(("Data"))
            local Wca = Vca and Vca:FindFirstChild(("Assets"))
            local Xca = nil
            if Wca then
                local Yca, Zca = pcall(require, Wca)
                if Yca and type (Zca) == ("table") and type (Zca.Directory) == ("table") then
                    Xca = Zca.Directory
                end
            end
            Tca = Xca or false
            return Xca
        end
        local function getPlaceAssetRarity(bda)
            local cda = getgenv() [("AliceHUB_SAE_RarityOf")]
            if type (cda) == ("function") then
                local dda, eda = pcall(cda, bda)
                if dda then
                    return eda
                end
            end
            if type (bda) ~= ("string") then
                return nil
            end
            local fda = getPlaceEggAssetDirectory()
            local gda = fda and fda [bda]
            if type (gda) == ("table") and type (gda.Rarity) == ("table") then
                return gda.Rarity._id
            end
            return nil
        end
        local hda = nil
        local function getPlaceAssetItems()
            if hda ~= nil then
                return hda or nil
            end
            local jda = fca:FindFirstChild(("Shared"))
            local kda = jda and jda:FindFirstChild(("Util"))
            local lda = kda and kda:FindFirstChild(("AssetItems"))
            local mda = nil
            if lda then
                local nda, oda = pcall(require, lda)
                if nda and type (oda) == ("table") and type (oda.SalePrice) == ("function") then
                    mda = oda
                end
            end
            hda = mda or false
            return mda
        end
        local function buildEggEspInfo(qda)
            local rda = getgenv() [("AliceHUB_SAE_EggEsp")]
            if type (rda) == ("function") then
                local sda, tda = pcall(rda, qda)
                if sda then
                    return tda
                end
            end
            if type (qda) ~= ("table") then
                return nil
            end
            local uda = {}
            if type (qda.Mutations) == ("table") then
                for vda, wda in ipairs(qda.Mutations) do
                    uda [vda] = tostring(wda)
                end
            end
            local xda, yda = nil, nil
            local zda = getPlaceAssetItems()
            if zda then
                local Ada, Bda = pcall(zda.SalePrice, {Category = qda.AssetCategory, Scale = qda.AssetScale, Mutations = qda.Mutations, BaseMutation = qda.BaseMutation, EyeColor = qda.AssetEyeColor, ColorSeed = qda.AssetColorSeed, ColorIndex = qda.AssetColorIndex,})
                if Ada and tonumber(Bda) then
                    xda = tonumber(Bda)
                end
                if type (zda.WeightKg) == ("function") then
                    local Cda, Dda = pcall(zda.WeightKg, {Category = qda.AssetCategory, Scale = qda.AssetScale, Mutations = qda.Mutations})
                    if Cda and tonumber(Dda) then
                        yda = tonumber(Dda)
                    end
                end
            end
            local Eda = nil do
                local Fda = getPlaceEggAssetDirectory()
                local Gda = Fda and Fda [qda.AssetCategory]
                local Hda = Gda and tonumber(Gda.EarningRate)
                if Hda then
                    local Ida = getgenv() [("AliceHUB_SAE_MutationEarningsFactor")]
                    local Jda = (type (Ida) == ("function")) and Ida(qda.Mutations) or 1
                    Eda = Hda * ((tonumber(qda.AssetScale) or 1) ^ 1.85) * Jda
                end
            end
            return {category = qda.AssetCategory, rarity = getPlaceAssetRarity(qda.AssetCategory), scale = tonumber(qda.AssetScale), mutations = uda, baseMutation = (type (qda.BaseMutation) == ("string")) and qda.BaseMutation or nil, moneyPerSecond = Eda, weight = yda, value = xda,}
        end
        local function getAssetWeightKg(Lda)
            if type (Lda) ~= ("table") then
                return nil
            end
            local Mda = getPlaceAssetItems()
            if not Mda or type (Mda.WeightKg) ~= ("function") then
                return nil
            end
            local Nda, Oda = pcall(Mda.WeightKg, {Category = Lda.Category, Scale = Lda.Scale, Mutations = Lda.Mutations})
            if Nda and tonumber(Oda) then
                return tonumber(Oda)
            end
            return nil
        end
        local Pda = {("Common"), ("Uncommon"), ("Rare"), ("Epic"), ("Legendary"), ("Mythic"), ("Divine"), ("Cosmic"), ("Secret"), ("Eternal"),}
        local function isSelectionMapEmpty(Rda)
            for Sda in pairs(Rda) do
                return false
            end
            return true
        end
        local function passesPlaceRarityFilter(Uda, Vda)
            if isSelectionMapEmpty(Uda) then
                return true
            end
            local Wda = getPlaceAssetRarity(Vda)
            if Wda == nil then
                return false
            end
            return Uda [Wda] == true
        end
        _G [("SAE_PlaceRarity")] = _G [("SAE_PlaceRarity")] or {}
        local function getEggTools()
            local Yda = {}
            local function scanEggToolsInContainer(aea)
                if not aea then
                    return
                end
                for bea, cea in ipairs(aea:GetChildren()) do
                    if cea:IsA(("Tool")) and cea:GetAttribute(("ItemType")) == ("AssetEgg") then
                        Yda [#Yda + 1] = {tool = cea, uid = cea:GetAttribute(("UID")), cat = cea:GetAttribute(("AssetCategory")),}
                    end
                end
            end
            scanEggToolsInContainer(ica:FindFirstChildOfClass(("Backpack")))
            scanEggToolsInContainer(ica.Character)
            return Yda
        end
        local function countEggTools()
            return #getEggTools()
        end
        local function waitCancelable(fea, gea)
            local hea = os.clock()
            while (os.clock() - hea) < fea do
                if gea and not gea() then
                    return
                end
                hca.Heartbeat:Wait()
            end
        end
        local function getUnplacedEggInventory()
            local jea = getPlaceEggSaveData()
            local kea = {}
            if not jea or type (jea.EggInventory) ~= ("table") then
                return kea
            end
            for lea, mea in pairs(jea.EggInventory) do
                if type (lea) == ("string") and type (mea) == ("table") and mea.Placement == nil then
                    kea [#kea + 1] = {uid = lea, cat = mea.AssetCategory}
                end
            end
            return kea
        end
        local function wearEggToolAndWait(oea, pea, qea)
            local rea = getPlaceEggState()
            if not rea or type (rea.WearEggTool) ~= ("function") then
                return false
            end
            local sea = pcall(rea.WearEggTool, oea)
            if not sea then
                return false
            end
            local tea = os.clock()
            while qea() and (os.clock() - tea) < oca do
                if countEggTools() > pea then
                    return true
                end
                hca.Heartbeat:Wait()
            end
            return countEggTools() > pea
        end
        local uea = nil
        local function getPlotState()
            if uea ~= nil then
                return uea or nil
            end
            local wea = fca:FindFirstChild(("Client"))
            local xea = wea and wea:FindFirstChild(("PlotState"))
            local yea = nil
            if xea then
                local zea, Aea = pcall(require, xea)
                if zea and type (Aea) == ("table") then
                    yea = Aea
                end
            end
            uea = yea or false
            return yea
        end
        local function getPlotCenterPoint()
            local Cea = getPlotState()
            if not Cea or type (Cea.ResolvePlot) ~= ("function") then
                return nil
            end
            local Dea, Eea = pcall(Cea.ResolvePlot)
            if Dea and type (Eea) == ("table") and Eea.CenterPoint then
                return Eea.CenterPoint
            end
            return nil
        end
        local function getPlotPetArea()
            local Gea = getPlotState()
            if not Gea or type (Gea.ResolvePlot) ~= ("function") then
                return nil
            end
            local Hea, Iea = pcall(Gea.ResolvePlot)
            if Hea and type (Iea) == ("table") and Iea.PetArea and Iea.PetArea:IsA(("BasePart")) then
                return Iea.PetArea
            end
            return nil
        end
        local function distanceToPartBounds(Kea, Lea)
            if not Kea or not Lea then
                return math.huge
            end
            local Mea = Kea.CFrame:PointToObjectSpace(Lea)
            local Nea = Kea.Size * 0.5
            local Oea = Vector3.new(math.clamp(Mea.X, - Nea.X, Nea.X), math.clamp(Mea.Y, - Nea.Y, Nea.Y), math.clamp(Mea.Z, - Nea.Z, Nea.Z))
            return (Lea - Kea.CFrame:PointToWorldSpace(Oea)).Magnitude
        end
        local function moveIntoPetArea(Qea, Rea)
            local Sea = getPlotPetArea()
            if not Sea then
                return false
            end
            local Tea = Sea.Position
            local function distanceToPetArea()
                local Vea = ica.Character and ica.Character:FindFirstChild(("HumanoidRootPart"))
                if not Vea then
                    return math.huge
                end
                return distanceToPartBounds(Sea, Vea.Position)
            end
            if distanceToPetArea() <= pca then
                return true
            end
            local Wea = getgenv() [("AliceHUB_SAE_MoveTo")]
            if type (Wea) == ("function") then
                pcall(Wea, CFrame.new(Tea + Vector3.new(0, 4, 0)), Qea, Rea, true)
            end
            if distanceToPetArea() <= pca then
                return true
            end
            local Xea = getgenv() [("AliceHUB_SAE_MoveToTween")]
            if type (Xea) == ("function") then
                pcall(Xea, Tea + Vector3.new(0, 4, 0), Qea, Rea)
            end
            return distanceToPetArea() <= pca
        end
        local Yea = 2
        local function buildEggPlacementOffsets(afa, bfa)
            local cfa = {}
            if not afa or not bfa then
                return cfa
            end
            local dfa = bfa.Size * 0.5
            local efa = math.max(dfa.X - Yea, 0)
            local ffa = math.max(dfa.Z - Yea, 0)
            local gfa = math.min(kca, math.floor(efa / jca))
            local hfa = math.min(kca, math.floor(ffa / jca))
            for ifa = 0, math.max(gfa, hfa) do
                for jfa = - ifa, ifa do
                    for kfa = - ifa, ifa do
                        if ifa == 0 or math.abs(jfa) == ifa or math.abs(kfa) == ifa then
                            if math.abs(jfa) <= gfa and math.abs(kfa) <= hfa then
                                local lfa = Vector3.new(jfa * jca, dfa.Y, kfa * jca)
                                local mfa = bfa.CFrame:PointToWorldSpace(lfa)
                                cfa [#cfa + 1] = afa.CFrame:ToObjectSpace(CFrame.new(mfa))
                            end
                        end
                    end
                end
            end
            local nfa = math.random(0, math.max(#cfa - 1, 0))
            local ofa = {}
            for pfa = 1, #cfa do
                ofa [pfa] = cfa [((pfa + nfa - 1) % #cfa) + 1]
            end
            return ofa
        end
        local qfa = ("belum pernah menembak")
        local rfa, sfa = nil, 0
        local tfa = {("full"), ("no space"), ("no room"), ("limit"), ("maximum"), ("max "), ("too many"), ("capacity"),}
        local ufa = 90
        local vfa = 0
        local wfa = nil
        local function isPlotCapacityError(yfa)
            local zfa = string.lower(tostring(yfa or ("")))
            if zfa == ("") then
                return false
            end
            for Afa, Bfa in ipairs(tfa) do
                if zfa:find(Bfa, 1, true) then
                    return true
                end
            end
            return false
        end
        local function markPlotCapacityBlocked(Dfa)
            vfa = os.clock() + ufa
            wfa = tostring(Dfa or ("penuh"))
        end
        local function clearPlotCapacityBlocked()
            vfa = 0
            wfa = nil
        end
        local function isPlotCapacityBlocked()
            return os.clock() < vfa
        end
        local function getPlotCapacityReason()
            return wfa or ("plot penuh")
        end
        local function plantEggEntry(Ifa, Jfa, Kfa)
            local Lfa = getPlaceEggState()
            if not Lfa or type (Lfa.PlantEgg) ~= ("function") then
                return false, ("EggState.PlantEgg tidak ada")
            end
            if not Ifa.uid then
                return false, ("entry tanpa uid")
            end
            local Mfa = getPlotCenterPoint()
            if not Mfa then
                return false, ("PlotState.ResolvePlot().CenterPoint tidak terbaca")
            end
            local Nfa = ica.Character
            local Ofa = Nfa and Nfa:FindFirstChildWhichIsA(("Tool"))
            if not (Ofa and Ofa:GetAttribute(("UID")) == Ifa.uid) then
                local Pfa = getPlaceEggState()
                if Pfa and type (Pfa.WearEggTool) == ("function") then
                    pcall(Pfa.WearEggTool, Ifa.uid)
                end
                local Qfa = os.clock()
                while Jfa() and (os.clock() - Qfa) < oca do
                    Nfa = ica.Character
                    Ofa = Nfa and Nfa:FindFirstChildWhichIsA(("Tool"))
                    if Ofa and Ofa:GetAttribute(("UID")) == Ifa.uid then
                        break
                    end
                    hca.Heartbeat:Wait()
                end
            end
            if not (Ofa and Ofa:GetAttribute(("UID")) == Ifa.uid) then
                return false, ("telur tidak berhasil dipegang (masih di backpack)")
            end
            if not moveIntoPetArea(Jfa, Kfa) then
                local Rfa = ica.Character and ica.Character:FindFirstChild(("HumanoidRootPart"))
                local Sfa = getPlotPetArea()
                local Tfa = (Rfa and Sfa) and math.floor(distanceToPartBounds(Sfa, Rfa.Position)) or - 1
                return false, (("tidak bisa mencapai PetArea (jarak permukaan ") .. Tfa .. (" stud)"))
            end
            local Ufa = getPlotPetArea()
            if not Ufa then
                return false, ("PetArea plot tidak terbaca (plot belum termuat?)")
            end
            local Vfa = countEggTools()
            for Wfa, Xfa in ipairs(buildEggPlacementOffsets(Mfa, Ufa)) do
                if not Jfa() then
                    return false
                end
                local Yfa, Zfa, aga = pcall(Lfa.PlantEgg, Ifa.uid, Xfa)
                qfa = (not Yfa) and (("error: ") .. tostring(Zfa)) or (Zfa == true and ("diterima") or (("ditolak: ") .. tostring(aga)))
                if Zfa ~= true then
                    local bga = os.clock()
                    if qfa ~= rfa or (bga - sfa) > 15 then
                        rfa, sfa = qfa, bga
                        pcall(function ()
                            dca:Notify({Title = ("Place Egg"), Content = qfa, Duration = 8})
                        end
                        )
                    end
                end
                if Yfa and Zfa == true then
                    waitCancelable(lca, Jfa)
                    if countEggTools() < Vfa then
                        clearPlotCapacityBlocked()
                        return true
                    end
                elseif Yfa and type (aga) == ("string") then
                    if isPlotCapacityError(aga) then
                        markPlotCapacityBlocked(aga)
                        return false, (("plot penuh: ") .. tostring(aga))
                    end
                    if not aga:find(("too close")) then
                        return false, (("ditolak server: ") .. tostring(aga))
                    end
                end
                waitCancelable(lca, Jfa)
            end
            return false, (("semua titik gagal — balasan terakhir: ") .. tostring(qfa))
        end
        local function hasReadyEggToHatch()
            local dga = getPlaceEggState()
            if not dga or type (dga.IsReadyToHatch) ~= ("function") then
                return false
            end
            local ega, fga = pcall(dga.ReadOwnedEggs)
            if not ega or typeof(fga) ~= ("table") then
                return false
            end
            for gga, hga in pairs(fga) do
                if typeof(hga) == ("table") and tostring(hga.OwnerUserId) == tostring(ica.UserId) then
                    for iga, jga in pairs(hga.Records or {}) do
                        local kga = typeof(jga) == ("table") and jga.AssetCategory or nil
                        if passesPlaceRarityFilter(_G [("SAE_PlaceRarity")], kga) then
                            local lga, mga = pcall(dga.IsReadyToHatch, iga)
                            if lga and mga then
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end
        getgenv() [("AliceHUB_SAE_PlaceEggUid")] = plantEggEntry
        getgenv() [("AliceHUB_SAE_HatchEggUid")] = function (nga, oga)
            local pga = getPlaceEggState()
            if not pga or type (pga.IsReadyToHatch) ~= ("function") then
                return false
            end
            local qga, rga = pcall(pga.IsReadyToHatch, nga)
            if not (qga and rga) then
                return false
            end
            local sga = pcall(pga.BeginHatch, nga)
            if not sga then
                return false
            end
            waitCancelable(mca, oga)
            local tga = pcall(pga.FinishHatch, nga)
            waitCancelable(mca, oga)
            return tga
        end
        getgenv() [("AliceHUB_SAE_ReadOwnedEggUids")] = function ()
            local uga = {}
            local vga = getPlaceEggState()
            if not vga or type (vga.ReadOwnedEggs) ~= ("function") then
                return uga
            end
            local wga, xga = pcall(vga.ReadOwnedEggs)
            if not wga or typeof(xga) ~= ("table") then
                return uga
            end
            for yga, zga in pairs(xga) do
                if typeof(zga) == ("table") and tostring(zga.OwnerUserId) == tostring(ica.UserId) then
                    for Aga, Bga in pairs(zga.Records or {}) do
                        local Cga = typeof(Bga) == ("table") and Bga.AssetCategory or nil
                        local Dga, Ega = pcall(vga.IsReadyToHatch, Aga)
                        uga [#uga + 1] = {uid = Aga, cat = Cga, ready = Dga and Ega == true}
                    end
                end
            end
            return uga
        end
        local Fga, Gga = nil, 0
        local function notifyPlaceHatchStatus(Iga)
            local Jga = os.clock()
            if Iga == Fga and (Jga - Gga) < 20 then
                return
            end
            Fga, Gga = Iga, Jga
            pcall(function ()
                dca:Notify({Title = ("Auto Place & Hatch"), Content = Iga, Duration = 6})
            end
            )
        end
        local function hatchReadyOwnedEggs(Lga, Mga)
            local Nga = getPlaceEggState()
            if not Nga or type (Nga.IsReadyToHatch) ~= ("function") then
                return 0
            end
            local Oga = select(2, pcall(Nga.ReadOwnedEggs))
            if typeof(Oga) ~= ("table") then
                return 0
            end
            local Pga = 0
            for Qga, Rga in pairs(Oga) do
                if typeof(Rga) == ("table") and tostring(Rga.OwnerUserId) == tostring(ica.UserId) then
                    for Sga, Tga in pairs(Rga.Records or {}) do
                        if not Lga() then
                            return Pga
                        end
                        local Uga = typeof(Tga) == ("table") and Tga.AssetCategory or nil
                        if passesPlaceRarityFilter(_G [("SAE_PlaceRarity")], Uga) then
                            local Vga, Wga = pcall(Nga.IsReadyToHatch, Sga)
                            if Vga and Wga then
                                local Xga = pcall(Nga.BeginHatch, Sga)
                                if Xga then
                                    waitCancelable(mca, Lga)
                                    pcall(Nga.FinishHatch, Sga)
                                    Pga = Pga + 1
                                    if Mga then
                                        pcall(Mga)
                                    end
                                    waitCancelable(mca, Lga)
                                end
                            end
                        end
                    end
                end
            end
            return Pga
        end
        local function readAssetRosterSnapshot()
            local Zga = getAssetRoster()
            local aha = {}
            if not Zga or type (Zga.ReadSnapshot) ~= ("function") then
                return aha
            end
            local bha, cha = pcall(Zga.ReadSnapshot)
            if not bha or typeof(cha) ~= ("table") then
                return aha
            end
            for dha, eha in pairs(cha) do
                if typeof(eha) == ("table") and tostring(eha.OwnerUserId) == tostring(ica.UserId) then
                    for fha, gha in pairs(eha.Records or {}) do
                        if typeof(gha) == ("table") and tonumber(gha.MoneyPerSecond) then
                            aha [fha] = tonumber(gha.MoneyPerSecond)
                        end
                    end
                end
            end
            return aha
        end
        local hha = {}
        local function getPlaceBaseEarningRate(jha)
            if type (jha) ~= ("string") then
                return 0
            end
            local kha = hha [jha]
            if kha ~= nil then
                return kha
            end
            local lha = getPlaceEggAssetDirectory()
            local mha = lha and lha [jha]
            local nha = 0
            if type (mha) == ("table") and tonumber(mha.EarningRate) then
                nha = tonumber(mha.EarningRate)
            end
            hha [jha] = nha
            return nha
        end
        local function estimatePetMoneyPerSecond(pha, qha, rha)
            local sha = rha [pha]
            if sha then
                return sha, true
            end
            local tha = tonumber(qha.Scale) or 1
            local uha = getgenv() [("AliceHUB_SAE_MutationEarningsFactor")]
            local vha = (type (uha) == ("function")) and uha(qha.Mutations) or 1
            return getPlaceBaseEarningRate(qha.Category) * (tha ^ 1.85) * vha, false
        end
        local function wearBestPets()
            local xha = getPlaceEggRemotes()
            local yha = xha and xha.Haul and xha.Haul.WearBest
            if typeof(yha) ~= ("Instance") or not yha:IsA(("RemoteFunction")) then
                return false, ("remote tak terbaca")
            end
            local zha, Aha = pcall(function ()
                return yha:InvokeServer()
            end
            )
            if not zha then
                return false, tostring(Aha)
            end
            return Aha ~= false, nil
        end
        local Bha = {}
        local function getAssetDisplayInfo(Dha)
            Dha = tostring(Dha or (""))
            if Dha == ("") then
                return nil
            end
            local Eha = Bha [Dha]
            if Eha ~= nil then
                if Eha == false then
                    return nil
                end
                return Eha
            end
            local Fha = getPlaceEggAssetDirectory()
            local Gha = Fha and Fha [Dha]
            if type (Gha) ~= ("table") then
                Bha [Dha] = false
                return nil
            end
            local Hha = tostring(Gha.Icon or (""))
            local Iha = {image = string.match(Hha, ("%d+")) or (""), name = tostring(Gha.DisplayName or Dha),}
            Bha [Dha] = Iha
            return Iha
        end
        getgenv() [("AliceHUB_SAE_ReadAssetIcons")] = function ()
            local Jha = getPlaceEggAssetDirectory()
            if type (Jha) ~= ("table") then
                return {}
            end
            local Kha = {}
            for Lha in pairs(Jha) do
                local Mha = getAssetDisplayInfo(Lha)
                if Mha and Mha.image ~= ("") then
                    Kha [#Kha + 1] = {cat = Lha, assetId = Mha.image}
                end
            end
            return Kha
        end
        local function updateMinMaxStat(Oha, Pha, Qha)
            if Qha == nil then
                return
            end
            local Rha, Sha = Pha .. ("Min"), Pha .. ("Max")
            if Oha [Rha] == nil or Qha < Oha [Rha] then
                Oha [Rha] = Qha
            end
            if Oha [Sha] == nil or Qha > Oha [Sha] then
                Oha [Sha] = Qha
            end
        end
        local function aggregatePetSummary(Uha, Vha, Wha)
            local Xha = getAssetDisplayInfo(Vha)
            local Yha = (Xha and Xha.name) or tostring(Vha or ("?"))
            local Zha = Uha [Yha]
            local aia = (Wha and #Wha.mutations > 0) and 1 or 0
            if Zha then
                Zha.count = Zha.count + 1
                if Wha then
                    updateMinMaxStat(Zha, ("mps"), tonumber(Wha.moneyPerSecond))
                    updateMinMaxStat(Zha, ("weight"), tonumber(Wha.weight))
                    updateMinMaxStat(Zha, ("value"), tonumber(Wha.value))
                end
                Zha.mutatedCount = (Zha.mutatedCount or 0) + aia
            else
                Zha = {name = Yha, count = 1, image = (Xha and Xha.image) or (""), rarity = getPlaceAssetRarity(Vha) or (""), mutatedCount = aia}
                if Wha then
                    updateMinMaxStat(Zha, ("mps"), tonumber(Wha.moneyPerSecond))
                    updateMinMaxStat(Zha, ("weight"), tonumber(Wha.weight))
                    updateMinMaxStat(Zha, ("value"), tonumber(Wha.value))
                end
                Uha [Yha] = Zha
            end
            return Uha [Yha]
        end
        local bia = 500
        getgenv() [("AliceHUB_SAE_ReadPets")] = function ()
            local cia = {equipped = {}, owned = {}, all = {}, allTruncated = false, limit = 0}
            local dia = getPlaceEggSaveData()
            if type (dia) ~= ("table") or type (dia.Inventory) ~= ("table") then
                return cia
            end
            local eia = getAssetRoster()
            if eia and type (eia.ReadWearLimit) == ("function") then
                local fia, gia = pcall(eia.ReadWearLimit)
                if fia then
                    cia.limit = tonumber(gia) or 0
                end
            end
            local hia = {}
            for iia, jia in pairs(dia.EquippedAssets or {}) do
                hia [jia] = true
            end
            local kia = readAssetRosterSnapshot()
            local lia = {}
            for mia, nia in pairs(dia.Inventory) do
                if type (nia) == ("table") and nia.InFuse ~= true then
                    local oia, pia = estimatePetMoneyPerSecond(mia, nia, kia)
                    local qia = getAssetDisplayInfo(nia.Category)
                    local ria = (qia and qia.name) or tostring(nia.Category or ("?"))
                    local sia = getPlaceAssetRarity(nia.Category) or ("")
                    local tia = tonumber(oia) or 0
                    local uia = getAssetWeightKg(nia)
                    local via = lia [ria]
                    if not via then
                        via = {name = ria, count = 0, image = (qia and qia.image) or (""), rarity = sia, mpsMin = tia, mpsMax = tia, mpsExact = pia == true, weightMin = uia, weightMax = uia}
                        lia [ria] = via
                    else
                        if tia < via.mpsMin then
                            via.mpsMin = tia
                        end
                        if tia > via.mpsMax then
                            via.mpsMax = tia
                        end
                        if pia == false then
                            via.mpsExact = false
                        end
                        if uia then
                            if via.weightMin == nil or uia < via.weightMin then
                                via.weightMin = uia
                            end
                            if via.weightMax == nil or uia > via.weightMax then
                                via.weightMax = uia
                            end
                        end
                    end
                    via.count = via.count + 1
                    if hia [mia] then
                        cia.equipped [#cia.equipped + 1] = {name = ria, image = (qia and qia.image) or (""), rarity = sia, mps = tia, mpsExact = pia == true, weight = uia,}
                    end
                    if #cia.all < bia then
                        cia.all [#cia.all + 1] = {name = ria, image = (qia and qia.image) or (""), rarity = sia, mps = tia, mpsExact = pia == true, weight = uia}
                    else
                        cia.allTruncated = true
                    end
                end
            end
            for wia, xia in pairs(lia) do
                cia.owned [#cia.owned + 1] = xia
            end
            return cia
        end
        getgenv() [("AliceHUB_SAE_ReadEggs")] = function ()
            local yia = {}
            local zia = getPlaceEggSaveData()
            if type (zia) ~= ("table") or type (zia.EggInventory) ~= ("table") then
                return yia
            end
            local Aia = {}
            for Bia, Cia in pairs(zia.EggInventory) do
                if type (Cia) == ("table") and Cia.Placement == nil then
                    aggregatePetSummary(Aia, Cia.AssetCategory, buildEggEspInfo(Cia))
                end
            end
            for Dia, Eia in pairs(Aia) do
                Eia.category = ("Egg")
                yia [#yia + 1] = Eia
            end
            return yia
        end
        local Fia
        local function getEggRecordsModule()
            if Fia then
                return Fia
            end
            local Hia = fca:FindFirstChild(("Shared"))
            local Iia = Hia and Hia:FindFirstChild(("Util"))
            local Jia = Iia and Iia:FindFirstChild(("EggRecords"))
            if not Jia then
                return nil
            end
            local Kia, Lia = pcall(require, Jia)
            if Kia and type (Lia) == ("table") then
                Fia = Lia
            end
            return Fia
        end
        local Mia = 60
        getgenv() [("AliceHUB_SAE_ReadPlacedEggs")] = function ()
            local Nia = {}
            local Oia, Pia = getPlaceEggState(), getEggRecordsModule()
            if not (Oia and Pia) or type (Oia.ReadOwnerEggs) ~= ("function") then
                return Nia
            end
            local Qia, Ria = pcall(Oia.ReadOwnerEggs, ica.UserId)
            if not Qia or type (Ria) ~= ("table") then
                return Nia
            end
            local Sia = workspace:GetServerTimeNow()
            local Tia = os.time()
            for Uia, Via in pairs(Ria) do
                if type (Via) == ("table") and type (Via.Placement) == ("table") and #Nia < Mia then
                    local Wia = getAssetDisplayInfo(Via.AssetCategory)
                    local Xia = nil
                    local Yia, Zia = pcall(Pia.CurrentNightCredit, Via, Sia, Via.GrowthSpeedMultiplier)
                    local aja, bja = pcall(Pia.WallSecondsRemaining, Via, Sia, Via.GrowthSpeedMultiplier, Yia and Zia or nil)
                    if aja and type (bja) == ("number") then
                        Xia = math.max(0, bja)
                    end
                    local cja = buildEggEspInfo(Via)
                    Nia [#Nia + 1] = {name = (Wia and Wia.name) or tostring(Via.AssetCategory or ("?")), image = (Wia and Wia.image) or (""), rarity = getPlaceAssetRarity(Via.AssetCategory) or (""), ready = (Xia ~= nil) and (Xia <= 0) or false, readyAt = (Xia ~= nil) and (Tia + Xia) or nil, moneyPerSecond = cja and cja.moneyPerSecond or nil, weight = cja and cja.weight or nil, value = cja and cja.value or nil, mutations = cja and cja.mutations or {},}
                end
            end
            return Nia
        end
        local function doffAllEquippedAssets()
            local eja = getAssetRoster()
            if not eja or type (eja.DoffAsset) ~= ("function") then
                return 0
            end
            local function countEquippedAssets()
                local gja = getPlaceEggSaveData()
                local hja = 0
                for ija in pairs((gja and gja.EquippedAssets) or {}) do
                    hja = hja + 1
                end
                return hja
            end
            local jja = countEquippedAssets()
            local kja = getPlaceEggSaveData()
            for lja, mja in pairs((kja and kja.EquippedAssets) or {}) do
                pcall(eja.DoffAsset, mja)
                task.wait(0.15)
            end
            task.wait(0.6)
            return jja - countEquippedAssets()
        end
        local nja = getgenv() [("AliceHUB_SAE_Turn")]
        if type (nja) ~= ("table") then
            local oja = game:GetService(("RunService"))
            local pja = 4.0
            local qja = 18.0
            local rja = 12.0
            local sja = {holder = nil, token = nil, took = 0, alive = 0, seq = 0, nextNo = 1, queue = {}, sejak = {}}
            local function clearPlaceHatchTurnLock()
                sja.holder, sja.token = nil, nil
            end
            local function removePlaceHatchTurnQueueEntry(vja)
                for wja, xja in ipairs(sja.queue) do
                    if xja == vja then
                        table.remove(sja.queue, wja)
                        sja.sejak [vja] = nil
                        return
                    end
                end
            end
            nja = {}
            function nja.take(yja, zja)
                local Aja = sja.nextNo
                sja.nextNo = sja.nextNo + 1
                local Bja = #sja.queue + 1
                if yja == ("steal-egg") and #sja.queue > 0 then
                    local Cja = sja.queue [1]
                    local Dja = os.clock() - (sja.sejak [Cja] or os.clock())
                    if Dja < rja then
                        Bja = 1
                    end
                end
                table.insert(sja.queue, Bja, Aja)
                sja.sejak [Aja] = os.clock()
                local Eja = os.clock() + (zja or 15)
                while true do
                    if sja.holder ~= nil and (os.clock() - sja.alive) > qja then
                        clearPlaceHatchTurnLock()
                    end
                    if sja.holder == nil and sja.queue [1] == Aja then
                        table.remove(sja.queue, 1)
                        sja.sejak [Aja] = nil sja.seq = sja.seq + 1
                        sja.holder, sja.token = yja, sja.seq
                        sja.took, sja.alive = os.clock(), os.clock()
                        return sja.seq
                    end
                    if os.clock() >= Eja then
                        removePlaceHatchTurnQueueEntry(Aja)
                        return nil
                    end
                    oja.Heartbeat:Wait()
                end
            end
            function nja.keep(Fja)
                if Fja == nil or sja.token ~= Fja then
                    return false
                end
                sja.alive = os.clock()
                if #sja.queue > 0 and (os.clock() - sja.took) >= pja then
                    return false
                end
                if #sja.queue > 0 and (os.clock() - sja.took) >= qja then
                    return false
                end
                return true
            end
            function nja.give(Gja)
                if Gja ~= nil and sja.token == Gja then
                    clearPlaceHatchTurnLock()
                end
            end
            function nja.state()
                return sja
            end
            getgenv() [("AliceHUB_SAE_Turn")] = nja
        end
        local function makeTurnKeepAlive(Ija)
            return function ()
                if Ija == nil then
                    return true
                end
                if type (nja.keep) == ("function") then
                    pcall(nja.keep, Ija)
                end
                if type (nja.state) == ("function") then
                    local Jja, Kja = pcall(nja.state)
                    if Jja and type (Kja) == ("table") and Kja.token ~= Ija then
                        return false
                    end
                end
                return true
            end
        end
        _G [("SAE_AutoPlaceHatch")] = _G [("SAE_AutoPlaceHatch")] or false
        local function isAutoPlaceHatchEnabled()
            return _G [("SAE_AutoPlaceHatch")] and true or false
        end
        local function isAlwaysBestEnabled()
            return _G [("SAE_AlwaysBest")] and true or false
        end
        local Nja = 5.0
        getgenv() [("AliceHUB_SAE_PlaceHatchActiveUntil")] = getgenv() [("AliceHUB_SAE_PlaceHatchActiveUntil")] or 0
        getgenv() [("AliceHUB_SAE_EquipBestActiveUntil")] = getgenv() [("AliceHUB_SAE_EquipBestActiveUntil")] or 0
        local Oja, Pja = 0, 0
        local Qja, Rja = false, false
        local Sja, Tja = nil, 0
        local Uja = {15, 30, 120}
        local Vja = {}
        local function isEggUidBackedOff(Xja)
            local Yja = Vja [Xja]
            if not Yja then
                return false
            end
            if os.clock() >= Yja.until_ then
                return false
            end
            return true
        end
        local function backoffPlaceEggUid(aka)
            local bka = Vja [aka] or {n = 0, until_ = 0}
            bka.n = bka.n + 1
            local cka = Uja [math.min(bka.n, #Uja)] bka.until_ = os.clock() + cka
            Vja [aka] = bka
        end
        local function clearPlaceEggUidBackoff(eka)
            Vja [eka] = nil
        end
        local function startPlaceHatchWorker()
            Oja = Oja + 1
            Qja = true
            local gka = Oja
            local function isPlaceHatchWorkerCurrent()
                return isAutoPlaceHatchEnabled() and Oja == gka
            end
            local function finishPlaceHatchWorker()
                if Oja == gka then
                    Qja = false getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] = false
                end
            end
            local heldPlaceTurn = nil
            spawnAliceWorker(("PlaceHatchWorker"), function ()
                while isPlaceHatchWorkerCurrent() do
                    local jka = false
                    local kka = nil
                    local lka = #getEggTools() > 0
                    local mka = false
                    if not lka then
                        for nka, oka in ipairs(getUnplacedEggInventory()) do
                            if passesPlaceRarityFilter(_G [("SAE_PlaceRarity")], oka.cat) and not isEggUidBackedOff(oka.uid) then
                                mka = true
                                break
                            end
                        end
                    end
                    local pka = hasReadyEggToHatch()
                    local qka = isPlotCapacityBlocked()
                    local rka = (lka or mka) and not qka
                    if not (rka or pka) then
                        if qka and (lka or mka) then
                            notifyPlaceHatchStatus(("plot penuh — menunggu telur menetas (") .. getPlotCapacityReason() .. (")"))
                        end
                        waitCancelable(nca, isPlaceHatchWorkerCurrent)
                    else
                        getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] = true getgenv() [("AliceHUB_SAE_PlaceHatchActiveUntil")] = os.clock() + Nja
                        local ska = nja.take(("place-hatch"), 20)
                        heldPlaceTurn = ska
                        if not ska then
                            kka = ("tidak kebagian giliran karakter")
                            getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] = false
                        end
                        if not ska then
                            waitCancelable(nca, isPlaceHatchWorkerCurrent)
                        else
                            local tka = moveIntoPetArea(isPlaceHatchWorkerCurrent, makeTurnKeepAlive(ska))
                            if not tka then
                                kka = ("tidak bisa mencapai PetArea plot")
                            end
                            local uka = tka and getEggTools() or {}
                            local vka = false
                            if tka and #uka == 0 then
                                for wka, xka in ipairs(getUnplacedEggInventory()) do
                                    if not isPlaceHatchWorkerCurrent() then
                                        break
                                    end
                                    if passesPlaceRarityFilter(_G [("SAE_PlaceRarity")], xka.cat) then
                                        vka = true
                                        if wearEggToolAndWait(xka.uid, 0, isPlaceHatchWorkerCurrent) then
                                            uka = getEggTools()
                                            break
                                        end
                                    end
                                end
                            end
                            if #uka == 0 and tka then
                                if vka then
                                    kka = ("telur ditemukan tapi equip ditolak server (WearEggTool gagal)")
                                else
                                    kka = ("tidak ada telur yang cocok filter rarity untuk ditaruh")
                                end
                            end
                            if #uka > 0 then
                                do
                                    local yka = 0
                                    for zka, Aka in ipairs(uka) do
                                        if not isPlaceHatchWorkerCurrent() then
                                            break
                                        end
                                        if yka >= 2 then
                                            break
                                        end
                                        if not nja.keep(ska) then
                                            break
                                        end
                                        if passesPlaceRarityFilter(_G [("SAE_PlaceRarity")], Aka.cat) and not isEggUidBackedOff(Aka.uid) then
                                            yka = yka + 1
                                            local Bka, Cka = plantEggEntry(Aka, isPlaceHatchWorkerCurrent, makeTurnKeepAlive(ska))
                                            if Bka then
                                                jka = true clearPlaceEggUidBackoff(Aka.uid)
                                            else
                                                kka = Cka or kka
                                                if isPlotCapacityBlocked() then
                                                    break
                                                end
                                                backoffPlaceEggUid(Aka.uid)
                                            end
                                        end
                                    end
                                end
                            end
                            if isPlaceHatchWorkerCurrent() and hatchReadyOwnedEggs(isPlaceHatchWorkerCurrent, makeTurnKeepAlive(ska)) > 0 then
                                jka = true
                                if isPlaceHatchWorkerCurrent() and _G [("SAE_AlwaysBest")] then
                                    wearBestPets()
                                end
                            end
                            nja.give(ska)
                            heldPlaceTurn = nil
                            getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] = false
                            if (not jka) and kka then
                                if kka ~= Sja or (os.clock() - Tja) > 20 then
                                    Sja, Tja = kka, os.clock()
                                    pcall(function ()
                                        dca:Notify({Title = ("Auto Place & Hatch"), Content = ("Belum menaruh telur — ") .. tostring(kka), Duration = 8,})
                                    end
                                    )
                                end
                            end
                            waitCancelable(jka and lca or nca, isPlaceHatchWorkerCurrent)
                        end
                    end
                end
                finishPlaceHatchWorker()
            end
            , function (ok, err)
                if heldPlaceTurn ~= nil then
                    pcall(nja.give, heldPlaceTurn)
                    heldPlaceTurn = nil
                end
                getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] = false
                getgenv() [("AliceHUB_SAE_PlaceHatchActiveUntil")] = 0
                finishPlaceHatchWorker()
                if not ok and Oja == gka then
                    _G [("SAE_AutoPlaceHatch")] = false
                    local flags = getgenv() [("AliceHUB_Flags")]
                    local flag = flags and flags [("SAE_AutoPlaceHatch")]
                    if flag and type(flag.Set) == ("function") then pcall(flag.Set, flag, false) end
                end
            end)
        end
        local function ensurePlaceHatchWorker(Eka)
            if not isAutoPlaceHatchEnabled() then
                Oja = Oja + 1
                Qja = false
                return
            end
            if Qja and not Eka then
                return
            end
            startPlaceHatchWorker()
        end
        local function setAutoPlaceHatchEnabled(Gka)
            _G [("SAE_AutoPlaceHatch")] = Gka and true or false ensurePlaceHatchWorker(true)
        end
        _G [("SAE_AlwaysBest")] = _G [("SAE_AlwaysBest")] or false
        local function startAlwaysBestWorker()
            Pja = Pja + 1
            Rja = true
            local Ika = Pja
            local function isAlwaysBestWorkerCurrent()
                return isAlwaysBestEnabled() and Pja == Ika
            end
            local Kka = 5.0
            spawnAliceWorker(("AlwaysBestWorker"), function ()
                while isAlwaysBestWorkerCurrent() do
                    local Lka = wearBestPets()
                    waitCancelable(Lka and Kka or nca, isAlwaysBestWorkerCurrent)
                end
            end
            , function (ok, err)
                if Pja == Ika then
                    Rja = false
                    if not ok then
                        _G [("SAE_AlwaysBest")] = false
                        local flags = getgenv() [("AliceHUB_Flags")]
                        local flag = flags and flags [("SAE_AlwaysBest")]
                        if flag and type(flag.Set) == ("function") then pcall(flag.Set, flag, false) end
                    end
                end
            end)
        end
        local function ensureAlwaysBestWorker(Nka)
            if not isAlwaysBestEnabled() then
                Pja = Pja + 1
                Rja = false
                return
            end
            if Rja and not Nka then
                return
            end
            startAlwaysBestWorker()
        end
        local function setAlwaysBestEnabled(Pka)
            _G [("SAE_AlwaysBest")] = Pka and true or false ensureAlwaysBestWorker(true)
        end
        local function registerPlaceHatchConfigEntry(Rka, Ska, Tka)
            local Uka = getgenv() [("AliceHUB_SAE_Config")]
            if not Uka then
                Uka = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = Uka
            end
            if Uka._byKey [Rka] then
                Uka._byKey [Rka].get = Ska
                Uka._byKey [Rka].set = Tka
            else
                local Vka = {key = Rka, get = Ska, set = Tka}
                Uka._entries [#Uka._entries + 1] = Vka
                Uka._byKey [Rka] = Vka
            end
        end
        local function notifyPlaceHatchConfigChanged()
            local Xka = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (Xka) == ("function") then
                Xka()
            end
        end
        local function setPlaceHatchUiFlag(Zka, ala)
            pcall(function ()
                local bla = getgenv() [("AliceHUB_Flags")]
                local cla = bla and bla [Zka]
                if cla and type (cla.SetAndFire) == ("function") then
                    cla:SetAndFire(ala)
                end
            end
            )
        end
        local function placeRarityListToMap(ela)
            local fla = {}
            if type (ela) == ("table") then
                for gla, hla in ipairs(ela) do
                    if type (hla) == ("string") then
                        fla [hla] = true
                    end
                end
            end
            return fla
        end
        local function placeRarityMapToList(jla)
            local kla = {}
            for lla, mla in ipairs(Pda) do
                if jla [mla] then
                    kla [#kla + 1] = mla
                end
            end
            return kla
        end
        local nla = eca:Section({Title = ("Egg & Pet")})
        nla:MultiDropdown({Title = ("Egg Rarity to Place"), Desc = ("Only place & hatch eggs of these rarities. Leave empty for every rarity"), Flag = ("SAE_PlaceRarity"), Options = Pda, Default = {}, Callback = function (ola)
            _G [("SAE_PlaceRarity")] = placeRarityListToMap(ola)
            notifyPlaceHatchConfigChanged()
        end
        ,})
        nla:Toggle({Title = ("Auto Place & Hatch Egg"), Desc = ("Place eggs from your backpack onto the plot, then hatch them when ready"), Flag = ("SAE_AutoPlaceHatch"), ID = ("SAE_AutoPlaceHatch"), Value = false, Callback = function (pla)
            setAutoPlaceHatchEnabled(pla)
            notifyPlaceHatchConfigChanged()
        end
        ,})
        nla:Button({Title = ("Unequip All Pets"), Desc = ("Take every pet off your plot"), Callback = function ()
            if _G [("SAE_AlwaysBest")] then
                _G [("SAE_AlwaysBest")] = false setPlaceHatchUiFlag(("SAE_AlwaysBest"), false)
            end
            task.spawn(function ()
                local qla = doffAllEquippedAssets()
                dca:Notify({Title = ("Pets"), Content = qla > 0 and (("Removed ") .. qla .. (" pets from your plot")) or ("No pets were equipped"), Duration = 3,})
            end
            )
        end
        ,})
        registerPlaceHatchConfigEntry(("SAE_PlaceRarity"), function ()
            return placeRarityMapToList(_G [("SAE_PlaceRarity")])
        end
        , function (rla)
            _G [("SAE_PlaceRarity")] = placeRarityListToMap(rla)
            setPlaceHatchUiFlag(("SAE_PlaceRarity"), rla or {})
        end
        )
        registerPlaceHatchConfigEntry(("SAE_AutoPlaceHatch"), function ()
            return _G [("SAE_AutoPlaceHatch")]
        end
        , function (sla)
            sla = sla and true or false setPlaceHatchUiFlag(("SAE_AutoPlaceHatch"), sla)
            setAutoPlaceHatchEnabled(sla)
        end
        )
        nla:Toggle({Title = ("Always Equip Best"), Desc = ("Swap out weaker pets on your plot for stronger ones from your backpack"), Flag = ("SAE_AlwaysBest"), ID = ("SAE_AlwaysBest"), Value = false, Callback = function (tla)
            setAlwaysBestEnabled(tla)
            notifyPlaceHatchConfigChanged()
        end
        ,})
        registerPlaceHatchConfigEntry(("SAE_AlwaysBest"), function ()
            return _G [("SAE_AlwaysBest")]
        end
        , function (ula)
            ula = ula and true or false setPlaceHatchUiFlag(("SAE_AlwaysBest"), ula)
            setAlwaysBestEnabled(ula)
        end
        )
        registerPlaceHatchConfigEntry(("SAE_AutoEquipPet"), function ()
            return nil
        end
        , function (vla)
            if vla ~= true or _G [("SAE_AlwaysBest")] then
                return
            end
            local wla = false pcall(function ()
                local xla = getgenv() [("AliceHUB_Flags")]
                local yla = xla and xla [("SAE_AlwaysBest")]
                if yla and type (yla.SetAndFire) == ("function") then
                    yla:SetAndFire(true)
                    wla = true
                end
            end
            )
            if not wla then
                setAlwaysBestEnabled(true)
            end
        end
        )
        local zla = 1.0
        local Ala = {}
        local Bla = nil
        local Cla = false
        local Dla = {Slot = true, Dropped = true}
        local function formatSignedCompactNumber(Fla)
            Fla = tonumber(Fla)
            if not Fla then
                return ("?")
            end
            local Gla = Fla < 0 and ("-") or ("")
            Fla = math.abs(Fla)
            if Fla >= 1e9 then
                return Gla .. string.format(("%.1fB"), Fla / 1e9)
            end
            if Fla >= 1e6 then
                return Gla .. string.format(("%.1fM"), Fla / 1e6)
            end
            if Fla >= 1e3 then
                return Gla .. string.format(("%.1fK"), Fla / 1e3)
            end
            return Gla .. string.format(("%.0f"), Fla)
        end
        local function getEggEspRarityColor(Ila)
            local Jla = getPlaceEggAssetDirectory()
            local Kla = Ila and Jla and Jla [Ila]
            local Lla = type (Kla) == ("table") and type (Kla.Rarity) == ("table") and Kla.Rarity.Color
            if typeof(Lla) == ("Color3") then
                return Lla
            end
            return Color3.new(1, 1, 1)
        end
        local function removeEggEspBillboard(Nla)
            local Ola = Ala [Nla]
            if Ola then
                pcall(function ()
                    Ola:Destroy()
                end
                )
                Ala [Nla] = nil
            end
        end
        -- ============================================================
        -- Egg ESP
        -- ============================================================
        local function clearEggEsp()
            for Qla in pairs(Ala) do
                removeEggEspBillboard(Qla)
            end
        end
        local function createEggEspBillboard(Sla, Tla)
            local Ula = Sla:FindFirstChild(("Hitbox")) or Sla:FindFirstChildWhichIsA(("BasePart"))
            if not Ula then
                return nil
            end
            local Vla = Instance.new(("BillboardGui"))
            Vla.Name = ("AliceHUB_SAE_EggEsp")
            Vla.Adornee = Ula
            Vla.Size = UDim2.new(15, 0, 3.5, 0)
            Vla.SizeOffset = Vector2.new(0, 0)
            Vla.StudsOffset = Vector3.new(0, 3.2, 0)
            Vla.AlwaysOnTop = true Vla.MaxDistance = 100000
            Vla.ResetOnSpawn = false
            local Wla = Instance.new(("TextLabel"))
            Wla.BackgroundTransparency = 1
            Wla.Size = UDim2.new(1, 0, 1, 0)
            Wla.Font = Enum.Font.GothamBold
            Wla.TextScaled = true Wla.TextStrokeTransparency = 0
            Wla.TextStrokeColor3 = Color3.new(0, 0, 0)
            Wla.TextWrapped = false Wla.Text = ("")
            Wla.Parent = Vla
            local Xla = Instance.new(("UITextSizeConstraint"))
            Xla.MinTextSize = 35
            Xla.MaxTextSize = 75
            Xla.Parent = Wla
            Vla.Parent = Ula
            return Vla, Wla
        end
        local function updateEggEspBillboard(Zla, ama)
            local bma = Zla:FindFirstChildOfClass(("TextLabel"))
            if not bma then
                return
            end
            local cma = buildEggEspInfo(ama)
            local dma = (cma and cma.rarity) or getPlaceAssetRarity(ama.AssetCategory) or ("?")
            local ema = (cma and cma.value) and formatSignedCompactNumber(cma.value) or ("?")
            local fma = (cma and cma.moneyPerSecond) and (formatSignedCompactNumber(cma.moneyPerSecond) .. ("/s")) or ("?/s")
            bma.Text = dma .. (" | ") .. ema .. (" | ") .. fma
            bma.TextColor3 = getEggEspRarityColor(ama.AssetCategory)
        end
        local function refreshEggEsp()
            local hma = getPlaceEggState()
            if not hma or type (hma.ReadFieldEggs) ~= ("function") then
                return
            end
            local ima, jma = pcall(hma.ReadFieldEggs)
            if not ima or type (jma) ~= ("table") or type (jma.Records) ~= ("table") then
                return
            end
            local kma = workspace:FindFirstChild(("AreaEggSlotsClient"))
            if not kma then
                clearEggEsp()
                return
            end
            local lma = {}
            for mma, nma in pairs(jma.Records) do
                if type (nma) == ("table") and type (nma.Uid) == ("string") and Dla [nma.State] then
                    lma [nma.Uid] = true
                    local oma = Ala [nma.Uid]
                    if not oma or not oma.Parent then
                        local pma = kma:FindFirstChild(nma.Uid)
                        if pma then
                            local qma = createEggEspBillboard(pma, nma)
                            if qma then
                                Ala [nma.Uid] = qma
                                updateEggEspBillboard(qma, nma)
                            end
                        end
                    else
                        updateEggEspBillboard(oma, nma)
                    end
                end
            end
            for rma in pairs(Ala) do
                if not lma [rma] then
                    removeEggEspBillboard(rma)
                end
            end
        end
        local function stopEggEsp()
            if Bla then
                pcall(function ()
                    Bla:Disconnect()
                end
                );
                Bla = nil
            end
            clearEggEsp()
            Cla = false
        end
        local function startEggEsp()
            if Cla then
                return
            end
            Cla = true refreshEggEsp()
            local uma = 0
            Bla = hca.Heartbeat:Connect(function (vma)
                if not Cla then
                    return
                end
                uma = uma + vma
                if uma >= zla then
                    uma = 0
                    refreshEggEsp()
                end
            end
            )
        end
        _G [("SAE_EspEgg")] = _G [("SAE_EspEgg")] or false
        local function setEggEspEnabled(xma)
            _G [("SAE_EspEgg")] = xma and true or false
            if _G [("SAE_EspEgg")] then
                startEggEsp()
            else
                stopEggEsp()
            end
        end
        local yma = getgenv() [("AliceHUB_SAE_FarmSection")] or nla
        yma:Toggle({Title = ("Esp Egg"), Desc = ("Show rarity, value, and money/s above every field egg on the map"), Flag = ("SAE_EspEgg"), ID = ("SAE_EspEgg"), Value = false, Callback = function (zma)
            setEggEspEnabled(zma)
            notifyPlaceHatchConfigChanged()
        end
        ,})
        registerPlaceHatchConfigEntry(("SAE_EspEgg"), function ()
            return _G [("SAE_EspEgg")]
        end
        , function (Ama)
            Ama = Ama and true or false setPlaceHatchUiFlag(("SAE_EspEgg"), Ama)
            setEggEspEnabled(Ama)
        end
        )
    end
    )
    runAliceModule("RiftCore", function (...)
        local yoa = getgenv() [("AliceHUB_TabEvents")] or getgenv() [("AliceHUB_TabFarm")]
        if not yoa then
            return
        end
        local zoa = game:GetService(("ReplicatedStorage"))
        local Aoa = yoa:Section({Title = ("Rift")})
        getgenv() [("AliceHUB_SAE_RiftSection")] = Aoa
        local Boa = {}
        local Coa = nil
        function Boa.mods()
            if Coa then
                return Coa
            end
            local Doa, Eoa = pcall(function ()
                return {Save = require(zoa.Shared.Save), Remotes = require(zoa.Shared.Remotes), AssetItems = require(zoa.Shared.Util.AssetItems), FuseKernel = require(zoa.Shared.Util.FuseKernel), Rift = require(zoa.Data.Rift), BossMcy = require(zoa.Data.BossMastery),}
            end
            )
            if Doa and type (Eoa) == ("table") then
                Coa = Eoa
            end
            return Coa
        end
        function Boa.save()
            local Foa = Boa.mods()
            if not Foa then
                return nil
            end
            local Goa, Hoa = pcall(function ()
                return Foa.Save.Get()
            end
            )
            if Goa and type (Hoa) == ("table") then
                return Hoa
            end
            return nil
        end
        function Boa.registerCfg(Ioa, Joa, Koa)
            local Loa = getgenv() [("AliceHUB_SAE_Config")]
            if not Loa then
                Loa = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = Loa
            end
            if Loa._byKey [Ioa] then
                Loa._byKey [Ioa].get = Joa
                Loa._byKey [Ioa].set = Koa
            else
                local Moa = {key = Ioa, get = Joa, set = Koa}
                Loa._entries [#Loa._entries + 1] = Moa
                Loa._byKey [Ioa] = Moa
            end
        end
        function Boa.cfgChanged()
            local Noa = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (Noa) == ("function") then
                Noa()
            end
        end
        function Boa.notify(Ooa, Poa, Qoa)
            local Roa = getgenv() [("AliceHUB_WindUI")]
            if not Roa then
                return
            end
            pcall(function ()
                Roa:Notify({Title = Ooa, Content = Poa, Duration = Qoa or 4})
            end
            )
        end
        function Boa.loop(Soa, Toa, Uoa)
            task.spawn(function ()
                while true do
                    if not Soa() then
                        return
                    end
                    local okWorker, workerErr = pcall(Uoa)
                    if not okWorker then
                        warn(("[AliceHUB/EventWorker] ") .. tostring(workerErr))
                    end
                    local Voa = Toa()
                    local Woa = 0
                    while Woa < Voa do
                        if not Soa() then
                            return
                        end
                        task.wait(0.5)
                        Woa = Woa + 0.5
                    end
                end
            end
            )
        end
        getgenv() [("AliceHUB_SAE_Rift")] = Boa
    end
    )
    runAliceModule("RiftPredictor", function (...)
        local Xoa = getgenv() [("AliceHUB_SAE_Rift")]
        if not Xoa then
            return
        end
        local Yoa = getgenv() [("AliceHUB_SAE_RiftSection")]
        if not Yoa then
            return
        end
        local Zoa = 8
        local apa = 20
        local bpa = ("Reading the Rift...")
        local cpa = Yoa:Paragraph({Title = ("Rift Egg Predictor"), Body = bpa,})
        -- ============================================================
        -- Rift automation
        -- ============================================================
        local function findTextLabelByText(epa, fpa)
            if typeof(epa) ~= ("Instance") then
                return nil
            end
            for gpa, hpa in ipairs(epa:GetDescendants()) do
                if hpa:IsA(("TextLabel")) and hpa.Text == fpa then
                    return hpa
                end
            end
            return nil
        end
        local ipa = nil
        local function setRiftStatusText(kpa)
            if ipa == nil or ipa.Parent == nil then
                ipa = findTextLabelByText(cpa, bpa)
            end
            if ipa then
                pcall(function ()
                    ipa.Text = kpa
                end
                )
            end
        end
        local function getRiftRotationInfo()
            local mpa = Xoa.mods()
            if not mpa then
                return nil
            end
            local Apa, Bpa = pcall(function ()
                local npa = mpa.Rift
                local opa = npa.CurrentPeriod()
                local ppa = npa.SecondsUntilRotation()
                local qpa = npa.RotationSeconds()
                local rpa = npa.BannerIdForPeriod(opa)
                local spa = npa.BannerIdForPeriod(opa + 1)
                local tpa, upa = nil, nil
                for vpa, wpa in ipairs(npa.BannerIds()) do
                    local xpa = npa.GetBannerWeight(wpa)
                    if type (xpa) == ("number") and xpa > 0 and (upa == nil or xpa < upa) then
                        tpa, upa = wpa, xpa
                    end
                end
                local ypa = nil
                if tpa then
                    if rpa == tpa then
                        ypa = 0
                    else
                        for zpa = 1, Zoa do
                            if npa.BannerIdForPeriod(opa + zpa) == tpa then
                                ypa = ppa + (zpa - 1) * qpa
                                break
                            end
                        end
                    end
                end
                return {now = npa.GetBannerDisplayName(rpa), sisa = ppa, next = npa.GetBannerDisplayName(spa), rare = tpa and npa.GetBannerDisplayName(tpa) or nil, rareIn = ypa,}
            end
            )
            if Apa and type (Bpa) == ("table") then
                return Bpa
            end
            return nil
        end
        local function formatRiftTime(Dpa)
            if type (Dpa) ~= ("number") or Dpa < 0 then
                return ("?")
            end
            local Epa = math.floor(Dpa / 3600)
            local Fpa = math.floor((Dpa % 3600) / 60)
            if Epa > 0 then
                return string.format(("%dh %dm"), Epa, Fpa)
            end
            if Fpa > 0 then
                return string.format(("%dm"), Fpa)
            end
            return string.format(("%ds"), math.floor(Dpa))
        end
        task.spawn(function ()
            while true do
                pcall(function ()
                    local Gpa = getRiftRotationInfo()
                    if not Gpa then
                        setRiftStatusText(("The Rift is out of reach right now."))
                        return
                    end
                    local Hpa = (("Now: %s  ·  changes in %s\nNext: %s")):format(tostring(Gpa.now), formatRiftTime(Gpa.sisa), tostring(Gpa.next))
                    if Gpa.rare then
                        if Gpa.rareIn == 0 then
                            Hpa = Hpa .. (("\n%s is active now.")):format(tostring(Gpa.rare))
                        elseif type (Gpa.rareIn) == ("number") then
                            Hpa = Hpa .. (("\n%s in %s")):format(tostring(Gpa.rare), formatRiftTime(Gpa.rareIn))
                        end
                    end
                    setRiftStatusText(Hpa)
                end
                )
                task.wait(apa)
            end
        end
        )
    end
    )
    runAliceModule("RiftAutomation", function (...)
        local Ipa = getgenv() [("AliceHUB_SAE_Rift")]
        if not Ipa then
            return
        end
        local Jpa = getgenv() [("AliceHUB_SAE_RiftSection")]
        if not Jpa then
            return
        end
        local Kpa, Lpa = false, 0
        local Mpa, Npa = false, 0
        local Opa = 6
        local Ppa = 8
        local function requestRiftState()
            local Rpa = Ipa.mods()
            if not Rpa then
                return nil
            end
            local Spa, Tpa = pcall(function ()
                return Rpa.Remotes.Rift.AskState:InvokeServer()
            end
            )
            if Spa and type (Tpa) == ("table") then
                return Tpa
            end
            return nil
        end
        local function findRiftRequirementItem(Vpa, Wpa)
            local Xpa = Ipa.mods()
            local Ypa = Ipa.save()
            if not Xpa or not Ypa or type (Ypa.Inventory) ~= ("table") then
                return nil
            end
            local Zpa = {}
            for aqa, bqa in pairs(Ypa.EquippedAssets or {}) do
                Zpa [bqa] = true
            end
            local cqa, dqa = nil, nil
            for eqa, fqa in pairs(Ypa.Inventory) do
                if not Wpa [eqa] and not Zpa [eqa] then
                    local gqa, hqa = pcall(Xpa.AssetItems.Decode, fqa)
                    if gqa and hqa and hqa.Category == Vpa then
                        local iqa, jqa = pcall(Xpa.FuseKernel.MayEnterRift, eqa, fqa)
                        if iqa and jqa == true then
                            local kqa, lqa = pcall(Xpa.AssetItems.WeightKg, hqa)
                            lqa = (kqa and type (lqa) == ("number")) and lqa or math.huge
                            if dqa == nil or lqa < dqa then
                                cqa, dqa = eqa, lqa
                            end
                        end
                    end
                end
            end
            return cqa
        end
        local function tryTradeForRiftEgg(nqa)
            local oqa = Ipa.mods()
            if not oqa or type (nqa) ~= ("table") then
                return ("belum")
            end
            if nqa.Unlocked ~= true then
                return ("belum")
            end
            local pqa = nqa.Requirements
            if type (pqa) ~= ("table") or #pqa < 3 then
                return ("belum")
            end
            local qqa, rqa = {}, {}
            for sqa = 1, 3 do
                local tqa = findRiftRequirementItem(pqa [sqa], qqa)
                if not tqa then
                    return ("kurang")
                end
                qqa [tqa] = true rqa [sqa] = tqa
            end
            local uqa, vqa = pcall(function ()
                return oqa.Remotes.Rift.AskTradeIn:InvokeServer(rqa)
            end
            )
            if not uqa or vqa == false then
                return ("gagal")
            end
            pcall(function ()
                oqa.Remotes.Rift.AskFinishReveal:InvokeServer()
            end
            )
            return ("ok")
        end
        local function tryFreeRiftReroll(xqa)
            local yqa = Ipa.mods()
            if not yqa or type (xqa) ~= ("table") then
                return ("belum")
            end
            if xqa.Unlocked ~= true then
                return ("belum")
            end
            local zqa = tonumber(xqa.FreeRefreshesRemaining) or 0
            if zqa <= 0 then
                return ("habis")
            end
            local Aqa, Bqa = pcall(function ()
                return yqa.Remotes.Rift.AskRefresh:InvokeServer()
            end
            )
            if not Aqa or Bqa == false then
                return ("gagal")
            end
            return ("ok")
        end
        Jpa:Toggle({Title = ("Auto Fuse Rift Egg"), Desc = ("Offer the requested pets to receive a Rift egg"), Flag = ("SAE_RiftAutoFuse"), ID = ("SAE_RiftAutoFuse"), Value = false, Callback = function (Cqa)
            Kpa = Cqa and true or false Lpa = Lpa + 1
            local Dqa = Lpa
            if not Kpa then
                Ipa.cfgChanged()
                return
            end
            local Eqa = false Ipa.loop(function ()
                return Kpa and Lpa == Dqa
            end
            , function ()
                return Opa
            end
            , function ()
                local Fqa = requestRiftState()
                if not Fqa then
                    return
                end
                local Gqa = tryTradeForRiftEgg(Fqa)
                if Gqa == ("ok") then
                    Eqa = false Ipa.notify(("Auto Fuse Rift Egg"), ("Traded — a Rift egg was received."), 4)
                elseif Gqa == ("kurang") then
                    if not Eqa then
                        Eqa = true Ipa.notify(("Auto Fuse Rift Egg"), ("Waiting — you do not have the pets being asked for."), 5)
                    end
                end
            end
            )
            Ipa.cfgChanged()
        end
        ,})
        Ipa.registerCfg(("SAE_RiftAutoFuse"), function ()
            return Kpa
        end
        , function (Hqa)
            Hqa = Hqa and true or false
            local flags = getgenv() [("AliceHUB_Flags")]
            local flag = flags and flags [("SAE_RiftAutoFuse")]
            if flag and type (flag.SetAndFire) == ("function") then
                flag:SetAndFire(Hqa)
            else
                Kpa = Hqa
            end
        end
        )
        Jpa:Toggle({Title = ("Auto Reroll (free only)"), Desc = ("Reroll the request while free rerolls remain"), Flag = ("SAE_RiftAutoReroll"), ID = ("SAE_RiftAutoReroll"), Value = false, Callback = function (Iqa)
            Mpa = Iqa and true or false Npa = Npa + 1
            local Jqa = Npa
            if not Mpa then
                Ipa.cfgChanged()
                return
            end
            Ipa.loop(function ()
                return Mpa and Npa == Jqa
            end
            , function ()
                return Ppa
            end
            , function ()
                local Kqa = requestRiftState()
                if not Kqa then
                    return
                end
                local Lqa = tryFreeRiftReroll(Kqa)
                if Lqa == ("habis") then
                    Mpa = false
                    local Mqa = getgenv() [("AliceHUB_Flags")]
                    local Nqa = Mqa and Mqa [("SAE_RiftAutoReroll")]
                    if Nqa and type (Nqa.SetAndFire) == ("function") then
                        pcall(function ()
                            Nqa:SetAndFire(false)
                        end
                        )
                    end
                    Ipa.notify(("Auto Reroll"), ("No free rerolls left — stopped."), 5)
                    Ipa.cfgChanged()
                end
            end
            )
            Ipa.cfgChanged()
        end
        ,})
        Ipa.registerCfg(("SAE_RiftAutoReroll"), function ()
            return Mpa
        end
        , function (Oqa)
            Oqa = Oqa and true or false
            local flags = getgenv() [("AliceHUB_Flags")]
            local flag = flags and flags [("SAE_RiftAutoReroll")]
            if flag and type (flag.SetAndFire) == ("function") then
                flag:SetAndFire(Oqa)
            else
                Mpa = Oqa
            end
        end
        )
    end
    )
    runAliceModule("Boss", function (...)
        local Pqa = getgenv() [("AliceHUB_SAE_Rift")]
        if not Pqa then
            return
        end
        local Qqa = getgenv() [("AliceHUB_SAE_RiftSection")]
        if not Qqa then
            return
        end
        local Rqa, Sqa = false, 0
        local Tqa, Uqa = false, 0
        local Vqa = {}
        local Wqa = 10
        local Xqa = 10
        local Yqa = {("CashBooster"), ("SpeedBoost"), ("TreadmillBooster"), ("MutationConsumable")}
        -- ============================================================
        -- Boss shop / mastery
        -- ============================================================
        local function getBossShopProducts()
            local ara = Pqa.mods()
            if not ara then
                return Yqa
            end
            local bra, cra = pcall(function ()
                return ara.BossMcy.GetShopProducts()
            end
            )
            if not bra or type (cra) ~= ("table") or #cra == 0 then
                return Yqa
            end
            local dra = {}
            for era, fra in ipairs(cra) do
                if type (fra) == ("table") and fra.Id then
                    dra [#dra + 1] = fra.Id
                end
            end
            return #dra > 0 and dra or Yqa
        end
        local function getBossShopOptionMap()
            local hra = Pqa.mods()
            local ira, jra = getBossShopProducts(), {}
            for kra, lra in ipairs(ira) do
                local mra = lra
                if hra then
                    local nra, ora = pcall(function ()
                        return hra.BossMcy.GetShopProduct(lra)
                    end
                    )
                    if nra and type (ora) == ("table") then
                        local pra, qra = pcall(function ()
                            return hra.BossMcy.GetShopDisplayName(ora)
                        end
                        )
                        if pra and type (qra) == ("string") and qra ~= ("") then
                            mra = qra
                        end
                        local rra, sra = pcall(function ()
                            return hra.BossMcy.GetShopPrice(ora)
                        end
                        )
                        if rra and type (sra) == ("number") then
                            mra = mra .. ("  (") .. tostring(sra) .. (")")
                        end
                    end
                end
                jra [#jra + 1] = mra
            end
            return ira, jra
        end
        local function normalizeBossShopSelection(ura)
            local vra, wra = getBossShopOptionMap()
            local xra = {}
            for yra, zra in ipairs(wra) do
                xra [zra] = vra [yra]
            end
            local Ara = {}
            for Bra, Cra in ipairs(ura or {}) do
                local Dra = xra [Cra] or Cra
                Ara [#Ara + 1] = Dra
            end
            return Ara
        end
        local function getBossShopProduct(Fra)
            local Gra = Pqa.mods()
            if not Gra then
                return nil
            end
            local Hra, Ira = pcall(function ()
                return Gra.BossMcy.GetShopProduct(Fra)
            end
            )
            if not Hra or type (Ira) ~= ("table") then
                return nil
            end
            local Jra, Kra = pcall(function ()
                return Gra.BossMcy.GetShopPrice(Ira)
            end
            )
            if Jra and type (Kra) == ("number") then
                return Kra
            end
            return nil
        end
        local function getClaimableBossMilestones()
            local Mra = Pqa.mods()
            local Nra = Pqa.save()
            if not Mra or not Nra or type (Nra.BossMastery) ~= ("table") then
                return {}
            end
            local Ora = Nra.BossMastery
            local Pra = tonumber(Ora.Mastery) or 0
            local Qra = Ora.ClaimedMilestoneIds or {}
            local Rra = {}
            local Vra = pcall(function ()
                for Sra, Tra in ipairs(Mra.BossMcy.Milestones or {}) do
                    if not Qra [Tra.Id] then
                        local Ura = Mra.BossMcy.GetMilestoneKills(Tra)
                        if type (Ura) == ("number") and Pra >= Ura then
                            Rra [#Rra + 1] = Tra.Id
                        end
                    end
                end
            end
            )
            if not Vra then
                return Rra
            end
            pcall(function ()
                local Wra = Mra.BossMcy.ClaimableInfiniteCount(Ora)
                if type (Wra) == ("number") and Wra > 0 then
                    for Xra = 1, Wra do
                        Rra [#Rra + 1] = Mra.BossMcy.InfiniteMilestoneId
                    end
                end
            end
            )
            return Rra
        end
        local function claimBossMilestone(Zra)
            local asa = Pqa.mods()
            if not asa then
                return false
            end
            local bsa, csa = pcall(function ()
                return asa.Remotes.BossMastery.AskClaimMilestone:InvokeServer(Zra)
            end
            )
            return bsa and csa ~= false
        end
        Qqa:Toggle({Title = ("Auto Claim Boss Mastery"), Desc = ("Collect mastery rewards as soon as they are ready"), Flag = ("SAE_BossAutoClaim"), ID = ("SAE_BossAutoClaim"), Value = false, Callback = function (dsa)
            Rqa = dsa and true or false Sqa = Sqa + 1
            local esa = Sqa
            if not Rqa then
                Pqa.cfgChanged()
                return
            end
            Pqa.loop(function ()
                return Rqa and Sqa == esa
            end
            , function ()
                return Wqa
            end
            , function ()
                local fsa = getClaimableBossMilestones()
                local gsa = 0
                for hsa, isa in ipairs(fsa) do
                    if not (Rqa and Sqa == esa) then
                        break
                    end
                    if claimBossMilestone(isa) then
                        gsa = gsa + 1
                        task.wait(0.6)
                    end
                end
                if gsa > 0 then
                    Pqa.notify(("Boss Mastery"), ("Collected ") .. tostring(gsa) .. (" reward") .. (gsa > 1 and ("s") or ("")) .. ("."), 4)
                end
            end
            )
            Pqa.cfgChanged()
        end
        ,})
        Pqa.registerCfg(("SAE_BossAutoClaim"), function ()
            return Rqa
        end
        , function (jsa)
            jsa = jsa and true or false
            local flags = getgenv() [("AliceHUB_Flags")]
            local flag = flags and flags [("SAE_BossAutoClaim")]
            if flag and type (flag.SetAndFire) == ("function") then
                flag:SetAndFire(jsa)
            else
                Rqa = jsa
            end
        end
        ) do
            local ksa, lsa = getBossShopOptionMap()
            Qqa:MultiDropdown({Title = ("Boss Shop Items"), Desc = ("Which items to buy"), Values = lsa, Value = {}, Flag = ("SAE_BossShopItems"), ID = ("SAE_BossShopItems"), Callback = function (msa)
                Vqa = type (msa) == ("table") and msa or {}
                Pqa.cfgChanged()
            end
            ,})
        end
        Pqa.registerCfg(("SAE_BossShopItems"), function ()
            return Vqa
        end
        , function (nsa)
            if type (nsa) == ("table") then
                Vqa = nsa
                local flags = getgenv() [("AliceHUB_Flags")]
                local flag = flags and flags [("SAE_BossShopItems")]
                if flag and type (flag.SetAndFire) == ("function") then
                    flag:SetAndFire(nsa)
                end
            end
        end
        )
        Qqa:Toggle({Title = ("Auto Boss Shop"), Desc = ("Buy the selected items once tokens allow"), Flag = ("SAE_BossAutoShop"), ID = ("SAE_BossAutoShop"), Value = false, Callback = function (osa)
            Tqa = osa and true or false Uqa = Uqa + 1
            local psa = Uqa
            if not Tqa then
                Pqa.cfgChanged()
                return
            end
            Pqa.loop(function ()
                return Tqa and Uqa == psa
            end
            , function ()
                return Xqa
            end
            , function ()
                local qsa = normalizeBossShopSelection(Vqa)
                if #qsa == 0 then
                    return
                end
                local rsa = Pqa.save()
                if not rsa then
                    return
                end
                local ssa = tonumber(rsa.BossTokens) or 0
                local tsa = Pqa.mods()
                if not tsa then
                    return
                end
                for usa, vsa in ipairs(qsa) do
                    if not (Tqa and Uqa == psa) then
                        break
                    end
                    local wsa = getBossShopProduct(vsa)
                    if wsa and ssa >= wsa then
                        local xsa, ysa = pcall(function ()
                            return tsa.Remotes.BossMastery.AskBuyShopItem:InvokeServer(vsa)
                        end
                        )
                        if xsa and ysa ~= false then
                            ssa = ssa - wsa
                            Pqa.notify(("Boss Shop"), ("Purchased an item."), 3)
                            task.wait(0.6)
                        else
                            break
                        end
                    end
                end
            end
            )
            Pqa.cfgChanged()
        end
        ,})
        Pqa.registerCfg(("SAE_BossAutoShop"), function ()
            return Tqa
        end
        , function (zsa)
            zsa = zsa and true or false
            local flags = getgenv() [("AliceHUB_Flags")]
            local flag = flags and flags [("SAE_BossAutoShop")]
            if flag and type (flag.SetAndFire) == ("function") then
                flag:SetAndFire(zsa)
            else
                Tqa = zsa
            end
        end
        )
    end
    )
    runAliceModule("Movement", function (...)
        local Asa = getgenv() [("AliceHUB_WindUI")]
        local Bsa = getgenv() [("AliceHUB_TabMovement")] or getgenv() [("AliceHUB_TabFarm")]
        if not Bsa then
            return
        end
        local Csa = game:GetService(("Players"))
        local Dsa = game:GetService(("RunService"))
        local Esa = Csa.LocalPlayer
        _G [("SAE_Noclip")] = _G [("SAE_Noclip")] or false
        local Fsa = {}
        local Gsa = nil
        -- ============================================================
        -- Noclip / Anti Hit
        -- ============================================================
        local function applyCharacterNoclip()
            local Isa = Esa.Character
            if not Isa then
                return
            end
            for Jsa, Ksa in ipairs(Isa:GetDescendants()) do
                if Ksa:IsA(("BasePart")) and Ksa.CanCollide then
                    if Fsa [Ksa] == nil then
                        Fsa [Ksa] = true
                    end
                    Ksa.CanCollide = false
                end
            end
        end
        local function restoreCharacterCollision()
            for Msa, Nsa in pairs(Fsa) do
                pcall(function ()
                    if Msa and Msa.Parent then
                        Msa.CanCollide = Nsa
                    end
                end
                )
            end
            Fsa = {}
        end
        local function setNoclipEnabled(Psa)
            _G [("SAE_Noclip")] = Psa and true or false
            if Gsa then
                pcall(function ()
                    Gsa:Disconnect()
                end
                )
                Gsa = nil
            end
            if not _G [("SAE_Noclip")] then
                restoreCharacterCollision()
                return
            end
            Gsa = Dsa.Stepped:Connect(function ()
                if not _G [("SAE_Noclip")] then
                    return
                end
                pcall(applyCharacterNoclip)
            end
            )
        end
        Esa.CharacterAdded:Connect(function ()
            Fsa = {}
            if _G [("SAE_Noclip")] then
                task.defer(applyCharacterNoclip)
            end
        end
        )
        local Qsa = 0.5
        local Rsa = {}
        local Ssa = 0
        local function getGuardAreas()
            local Usa = workspace:FindFirstChild(("__OBJECTS"))
            local Vsa = Usa and Usa:FindFirstChild(("Areas"))
            local Wsa = Vsa and Vsa:FindFirstChild(("GuardAreas"))
            if not Wsa then
                return nil
            end
            return Wsa
        end
        local function disableGuardCollisions()
            local Ysa = getGuardAreas()
            if not Ysa then
                return
            end
            for Zsa, ata in ipairs(Ysa:GetChildren()) do
                local bta = ata:FindFirstChild(("Guard"))
                if bta then
                    for cta, dta in ipairs(bta:GetDescendants()) do
                        if dta:IsA(("BasePart")) and (dta.CanCollide or dta.CanTouch) then
                            if Rsa [dta] == nil then
                                Rsa [dta] = {collide = dta.CanCollide, touch = dta.CanTouch}
                            end
                            dta.CanCollide = false dta.CanTouch = false
                        end
                    end
                end
            end
        end
        local function restoreGuardCollisions()
            for fta, gta in pairs(Rsa) do
                pcall(function ()
                    if fta and fta.Parent then
                        fta.CanCollide = gta.collide
                        fta.CanTouch = gta.touch
                    end
                end
                )
            end
            Rsa = {}
        end
        local function applyGuardNoclip()
            restoreGuardCollisions()
            local ita = getGuardAreas()
            if not ita then
                return
            end
            for jta, kta in ipairs(ita:GetChildren()) do
                local lta = kta:FindFirstChild(("Guard"))
                if lta then
                    for mta, nta in ipairs(lta:GetDescendants()) do
                        if nta:IsA(("BasePart")) then
                            pcall(function ()
                                nta.CanTouch = true nta.CanCollide = true
                            end
                            )
                        end
                    end
                end
            end
        end
        getgenv() [("AliceHUB_SAE_RestoreGuardTouch")] = applyGuardNoclip
        _G [("SAE_AntiHit")] = _G [("SAE_AntiHit")] or false
        local ota = nil
        local pta = nil
        local qta = nil
        local function setAntiHitEnabled(sta)
            _G [("SAE_AntiHit")] = sta and true or false
            if ota then
                pcall(function ()
                    ota:Disconnect()
                end
                )
                ota = nil
            end
            pta = nil
            if not _G [("SAE_AntiHit")] then
                restoreGuardCollisions()
                return
            end
            Ssa = 0
            pcall(disableGuardCollisions)
            ota = Dsa.Heartbeat:Connect(function ()
                if not _G [("SAE_AntiHit")] then
                    return
                end
                if (os.clock() - Ssa) >= Qsa then
                    Ssa = os.clock()
                    pcall(disableGuardCollisions)
                end
                local tta = Esa.Character
                local uta = tta and tta:FindFirstChild(("HumanoidRootPart"))
                if not uta then
                    pta = nil
                    return
                end
                if tta ~= qta then
                    qta, pta = tta, nil
                end
                if not getgenv() [("AliceHUB_SAE_FarmEggBusy")] then
                    pta = nil
                    return
                end
                if getgenv() [("AliceHUB_SAE_Moving")] then
                    pta = uta.CFrame
                    return
                end
                local vta = tta:FindFirstChildOfClass(("Humanoid"))
                if vta and vta.MoveDirection.Magnitude > 0.05 then
                    pta = uta.CFrame
                    return
                end
                if not pta then
                    pta = uta.CFrame
                    return
                end
                uta.CFrame = pta
                uta.AssemblyLinearVelocity = Vector3.zero
                uta.AssemblyAngularVelocity = Vector3.zero
            end
            )
        end
        Esa.CharacterAdded:Connect(function ()
            pta = nil
        end
        )
        local function registerMovementConfigEntry(xta, yta, zta)
            local Ata = getgenv() [("AliceHUB_SAE_Config")]
            if not Ata then
                Ata = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = Ata
            end
            if Ata._byKey [xta] then
                Ata._byKey [xta].get = yta
                Ata._byKey [xta].set = zta
            else
                local Bta = {key = xta, get = yta, set = zta}
                Ata._entries [#Ata._entries + 1] = Bta
                Ata._byKey [xta] = Bta
            end
        end
        local function notifyMovementConfigChanged()
            local Dta = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (Dta) == ("function") then
                Dta()
            end
        end
        local function setMovementUiFlag(Fta, Gta)
            pcall(function ()
                local Hta = getgenv() [("AliceHUB_Flags")]
                local Ita = Hta and Hta [Fta]
                if Ita and type (Ita.SetAndFire) == ("function") then
                    Ita:SetAndFire(Gta)
                end
            end
            )
        end
        local Jta = Bsa:Section({Title = ("Movement")})
        Jta:Toggle({Title = ("Noclip"), Desc = ("Walk through walls, fences, and mobs — nothing can block or push you"), Flag = ("SAE_Noclip"), ID = ("SAE_Noclip"), Value = false, Callback = function (Kta)
            setNoclipEnabled(Kta)
            notifyMovementConfigChanged()
        end
        ,})
        registerMovementConfigEntry(("SAE_Noclip"), function ()
            return _G [("SAE_Noclip")]
        end
        , function (Lta)
            Lta = Lta and true or false setMovementUiFlag(("SAE_Noclip"), Lta)
            setNoclipEnabled(Lta)
        end
        )
        local Mta = Jta
        Mta:Toggle({Title = ("Anti-Hit"), Desc = ("Guards can no longer knock you around — they circle you and nothing happens"), Flag = ("SAE_AntiHit"), ID = ("SAE_AntiHit"), Value = false, Callback = function (Nta)
            if Nta and _G [("SAE_InstantTP")] then
                _G [("SAE_InstantTP")] = false pcall(setMovementUiFlag, ("SAE_InstantTP"), false)
            end
            setAntiHitEnabled(Nta)
            notifyMovementConfigChanged()
        end
        ,})
        registerMovementConfigEntry(("SAE_AntiHit"), function ()
            return _G [("SAE_AntiHit")]
        end
        , function (Ota)
            Ota = Ota and true or false setMovementUiFlag(("SAE_AntiHit"), Ota)
            setAntiHitEnabled(Ota)
        end
        )
    end
    )
    runAliceModule("Performance", function (...)
        local Pta = getgenv() [("AliceHUB_WindUI")]
        local Qta = getgenv() [("AliceHUB_TabSettings")]
        if not Qta then
            return
        end
        local Rta = game:GetService(("ReplicatedStorage"))
        local Sta = game:GetService(("Players"))
        local Tta = game:GetService(("RunService"))
        local Uta = game:GetService(("Stats"))
        local Vta = Sta.LocalPlayer
        local Wta = 1.0
        local Xta = nil
        -- ============================================================
        -- Stats overlay
        -- ============================================================
        local function getStatsSaveModule()
            if Xta then
                return Xta
            end
            local Zta = Rta:FindFirstChild(("Shared"))
            local aua = Zta and Zta:FindFirstChild(("Save"))
            if not aua then
                return nil
            end
            local bua, cua = pcall(require, aua)
            if bua and type (cua) == ("table") then
                Xta = cua
            end
            return Xta
        end
        local function getStatsSaveData()
            local eua = getStatsSaveModule()
            if not eua or type (eua.Get) ~= ("function") then
                return nil
            end
            local fua, gua = pcall(eua.Get)
            if not fua or type (gua) ~= ("table") then
                return nil
            end
            return tonumber(gua.Money)
        end
        local function getPlayerSpeed()
            local iua = Vta:FindFirstChild(("leaderstats"))
            local jua = iua and iua:FindFirstChild(("Speed"))
            if jua and tonumber(jua.Value) then
                return tonumber(jua.Value)
            end
            local kua = getStatsSaveModule()
            if kua and type (kua.Get) == ("function") then
                local lua, mua = pcall(kua.Get)
                if lua and type (mua) == ("table") then
                    return tonumber(mua.SpeedPower)
                end
            end
            return nil
        end
        local function getMoneyPerSecond()
            local oua = Vta:FindFirstChild(("leaderstats"))
            local pua = oua and oua:FindFirstChild(("Money/s"))
            if pua then
                return tonumber(pua.Value)
            end
            return nil
        end
        local qua = nil
        local function getEggStateModule()
            if qua then
                return qua
            end
            local sua = Rta:FindFirstChild(("Client"))
            local tua = sua and sua:FindFirstChild(("EggState"))
            if not tua then
                return nil
            end
            local uua, vua = pcall(require, tua)
            if uua and type (vua) == ("table") then
                qua = vua
            end
            return qua
        end
        local function getEggInventorySize()
            local xua = getStatsSaveModule()
            if xua and type (xua.Get) == ("function") then
                local yua, zua = pcall(xua.Get)
                if yua and type (zua) == ("table") and type (zua.EggInventory) == ("table") then
                    local Aua = 0
                    for Bua in pairs(zua.EggInventory) do
                        Aua = Aua + 1
                    end
                    return Aua
                end
            end
            local Cua = 0
            local Dua = Vta:FindFirstChildOfClass(("Backpack"))
            local function countAssetEggTools(Fua)
                if not Fua then
                    return
                end
                for Gua, Hua in ipairs(Fua:GetChildren()) do
                    if Hua:IsA(("Tool")) and Hua:GetAttribute(("ItemType")) == ("AssetEgg") then
                        Cua = Cua + 1
                    end
                end
            end
            countAssetEggTools(Dua)
            countAssetEggTools(Vta.Character)
            return Cua
        end
        getgenv() [("AliceHUB_SAE_ReadStats")] = function ()
            local Iua = getgenv() [("AliceHUB_SAE_Stats")]
            return {money = tonumber(getStatsSaveData()) or 0, mps = tonumber(getMoneyPerSecond()) or 0, speed = tonumber(getPlayerSpeed()) or 0, totalEgg = tonumber(getEggInventorySize()) or 0, collected = (type (Iua) == ("table") and tonumber(Iua.collected)) or 0,}
        end
        local function formatCompactNumber(Kua)
            if type (Kua) ~= ("number") then
                return ("-")
            end
            local Lua = math.abs(Kua)
            if Lua >= 1e12 then
                return string.format(("%.2fT"), Kua / 1e12)
            end
            if Lua >= 1e9 then
                return string.format(("%.2fB"), Kua / 1e9)
            end
            if Lua >= 1e6 then
                return string.format(("%.2fM"), Kua / 1e6)
            end
            if Lua >= 1e3 then
                return string.format(("%.2fK"), Kua / 1e3)
            end
            return string.format(("%d"), Kua)
        end
        local function formatElapsedTime(Nua)
            Nua = math.max(math.floor(Nua or 0), 0)
            local Oua = math.floor(Nua / 3600)
            local Pua = math.floor((Nua % 3600) / 60)
            local Qua = Nua % 60
            if Oua > 0 then
                return string.format(("%dh %dm %ds"), Oua, Pua, Qua)
            end
            if Pua > 0 then
                return string.format(("%dm %ds"), Pua, Qua)
            end
            return string.format(("%ds"), Qua)
        end
        local function formatSignedDelta(Sua, Tua)
            if type (Sua) ~= ("number") or type (Tua) ~= ("number") then
                return ("")
            end
            local Uua = Sua - Tua
            if Uua == 0 then
                return ("")
            end
            local Vua = Uua > 0 and ("6EE782") or ("F87171")
            local Wua = Uua > 0 and ("+") or ("-")
            return string.format((" <font color=\"#%s\">%s%s</font>"), Vua, Wua, formatCompactNumber(math.abs(Uua)))
        end
        local Xua = {{("Common"), ("C")}, {("Uncommon"), ("U")}, {("Rare"), ("R")}, {("Epic"), ("E")}, {("Legendary"), ("L")}, {("Mythic"), ("M")}, {("Divine"), ("D")}, {("Cosmic"), ("Co")}, {("Secret"), ("S")}, {("Eternal"), ("Et")},}
        local function formatRarityStats()
            local Zua = getgenv() [("AliceHUB_SAE_Stats")]
            if type (Zua) ~= ("table") or type (Zua.byRarity) ~= ("table") then
                return ("-")
            end
            local ava = {}
            for bva, cva in ipairs(Xua) do
                local dva = Zua.byRarity [cva [1]]
                if dva and dva > 0 then
                    table.insert(ava, cva [2] .. ("=") .. dva)
                end
            end
            if #ava == 0 then
                return ("-")
            end
            return table.concat(ava, (" "))
        end
        local eva = {enabled = false}
        local fva = false
        local function cleanupExistingStatsGui()
            local function destroyExistingWhiteScreen(iva)
                if not iva then
                    return
                end
                local jva, kva = pcall(function ()
                    return iva:GetChildren()
                end
                )
                if not jva then
                    return
                end
                for lva, mva in ipairs(kva) do
                    if mva.Name == ("AliceHUB_SAE_WhiteScreen") then
                        pcall(function ()
                            mva:Destroy()
                        end
                        )
                    end
                end
            end
            pcall(function ()
                destroyExistingWhiteScreen(game:GetService(("CoreGui")))
            end
            )
            pcall(function ()
                if typeof(gethui) == ("function") then
                    destroyExistingWhiteScreen(gethui())
                end
            end
            )
            pcall(function ()
                destroyExistingWhiteScreen(Vta:FindFirstChildOfClass(("PlayerGui")))
            end
            )
        end
        local function stopStatsOverlay()
            if not eva.enabled then
                return
            end
            eva.enabled = false
            if eva.conn then
                pcall(function ()
                    eva.conn:Disconnect()
                end
                )
            end
            eva.conn = nil eva.labels = nil eva.gui = nil eva.base = nil
            if eva.guiRef then
                pcall(function ()
                    eva.guiRef:Destroy()
                end
                );
                eva.guiRef = nil
            end
            cleanupExistingStatsGui()
            pcall(function ()
                settings().Rendering.QualityLevel = eva.savedQuality or Enum.QualityLevel.Automatic
            end
            )
            pcall(function ()
                UserSettings():GetService(("UserGameSettings")).SavedQualityLevel = eva.savedUserQuality or Enum.SavedQualitySetting.Automatic
            end
            )
            eva.savedQuality = nil
            eva.savedUserQuality = nil
        end
        local xva = {function (ova)
            return ("ALICEHUB")
        end
        , function (pva)
            return ("Steal An Egg")
        end
        , function (qva)
            return ("Username : ") .. tostring(qva.user)
        end
        , function (rva)
            return ("Status : Active")
        end
        , function (sva)
            return ("Uptime : ") .. formatElapsedTime(sva.uptime)
        end
        , function (tva)
            return ("FPS: ") .. tva.fps .. ("   Ping: ") .. tva.ping .. ("ms   Players: ") .. tva.players
        end
        , function (uva)
            return ("Money: ") .. formatCompactNumber(uva.money) .. formatSignedDelta(uva.money, uva.base.money)
        end
        , function (vva)
            return ("Speed: ") .. formatCompactNumber(vva.speed) .. formatSignedDelta(vva.speed, vva.base.speed)
        end
        , function (wva)
            return ("Money/s: ") .. formatCompactNumber(wva.mps) .. ("   Est/h: ") .. formatCompactNumber((wva.mps or 0) * 3600)
        end
        , function (xvaRow)
            return ("Total Egg: ") .. xvaRow.totalEgg .. formatSignedDelta(xvaRow.totalEgg, xvaRow.base.totalEgg)
        end
        , function (yvaRow)
            return ("Collected Egg: ") .. yvaRow.eggs .. formatSignedDelta(yvaRow.eggs, yvaRow.base.eggs)
        end
        ,}
        local function buildStatsOverlayRows()
            local zva = getgenv() [("AliceHUB_SAE_Stats")] or {}
            local Ava = getStatsSaveData()
            local Bva = 0
            pcall(function ()
                Bva = math.floor(1 / Tta.RenderStepped:Wait())
            end
            )
            local Cva = 0
            pcall(function ()
                Cva = math.floor(Uta.Network.ServerStatsItem [("Data Ping")]:GetValue())
            end
            )
            return {user = Vta.Name, uptime = os.clock() - (eva.startAt or os.clock()), fps = Bva, ping = Cva, players = #Sta:GetPlayers(), money = Ava, mps = getMoneyPerSecond(), speed = getPlayerSpeed(), totalEgg = getEggInventorySize(), eggs = zva.collected or 0, base = eva.base or {},}
        end
        local function startStatsOverlay()
            if eva.enabled then
                return
            end
            eva.enabled = true eva.startAt = os.clock()
            local Eva = getgenv() [("AliceHUB_SAE_Stats")] or {}
            eva.base = {money = getStatsSaveData(), speed = getPlayerSpeed(), totalEgg = getEggInventorySize(), eggs = Eva.collected or 0}
            pcall(function ()
                eva.savedQuality = settings().Rendering.QualityLevel
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end
            )
            pcall(function ()
                local userSettings = UserSettings():GetService(("UserGameSettings"))
                eva.savedUserQuality = userSettings.SavedQualityLevel
                userSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            end
            )
            cleanupExistingStatsGui()
            local Fva = Instance.new(("ScreenGui"))
            Fva.Name = ("AliceHUB_SAE_WhiteScreen")
            Fva.ResetOnSpawn = false Fva.IgnoreGuiInset = true Fva.DisplayOrder = 2147483647
            Fva.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            local Gva = false pcall(function ()
                Fva.Parent = game:GetService(("CoreGui"));
                Gva = Fva.Parent ~= nil
            end
            )
            if not Gva then
                pcall(function ()
                    if typeof(gethui) == ("function") then
                        Fva.Parent = gethui()
                    end
                end
                )
            end
            if not Fva.Parent then
                Fva.Parent = Vta:WaitForChild(("PlayerGui"))
            end
            eva.guiRef = Fva
            task.spawn(function ()
                while eva.enabled do
                    pcall(function ()
                        local Hva = game:GetService(("CoreGui")):FindFirstChild(("DevConsoleMaster"))
                        if Hva and Hva.Enabled then
                            Hva.Enabled = false
                        end
                    end
                    )
                    pcall(function ()
                        if Fva and Fva.Parent then
                            Fva.DisplayOrder = 2147483647
                            Fva.Enabled = true
                        end
                    end
                    )
                    task.wait(0.5)
                end
            end
            )
            local Iva = Instance.new(("Frame"))
            Iva.Size = UDim2.new(1, 0, 1, 0)
            Iva.BackgroundColor3 = Color3.new(0, 0, 0)
            Iva.BorderSizePixel = 0
            Iva.Parent = Fva
            local Jva = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
            local Kva = math.clamp(math.floor(math.min(Jva.X, Jva.Y) * 0.075), 26, 54)
            local Lva = math.floor(Kva * 0.3 + 0.5)
            local Mva = Instance.new(("TextButton"))
            Mva.Name = ("WSCloseButton")
            Mva.AnchorPoint = Vector2.new(1, 0)
            Mva.Position = UDim2.new(1, - Lva, 0, Lva)
            Mva.Size = UDim2.new(0, Kva, 0, Kva)
            Mva.BackgroundColor3 = Color3.fromRGB(132, 30, 49)
            Mva.AutoButtonColor = true Mva.Text = ("X")
            Mva.Font = Enum.Font.GothamBold
            Mva.TextColor3 = Color3.fromRGB(255, 255, 255)
            Mva.TextSize = math.floor(Kva * 0.54 + 0.5)
            Mva.ZIndex = 10
            Mva.Parent = Fva
            local Nva = Instance.new(("UICorner"))
            Nva.CornerRadius = UDim.new(0, 10)
            Nva.Parent = Mva
            Mva.Activated:Connect(function ()
                fva = true pcall(stopStatsOverlay)
                pcall(function ()
                    Pta:Notify({Title = ("AliceHUB White Screen"), Content = ("Closed. Render is back to normal."), Duration = 3,})
                end
                )
            end
            )
            local Ova = Instance.new(("Frame"))
            Ova.AnchorPoint = Vector2.new(0.5, 0.5)
            Ova.Position = UDim2.new(0.5, 0, 0.5, 0)
            Ova.Size = UDim2.new(0.92, 0, 0.86, 0)
            Ova.BackgroundTransparency = 1
            Ova.Parent = Iva
            local Pva = Instance.new(("UIListLayout"))
            Pva.FillDirection = Enum.FillDirection.Vertical
            Pva.HorizontalAlignment = Enum.HorizontalAlignment.Center
            Pva.VerticalAlignment = Enum.VerticalAlignment.Center
            Pva.SortOrder = Enum.SortOrder.LayoutOrder
            Pva.Padding = UDim.new(0, 6)
            Pva.Parent = Ova
            local Qva = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
            local Rva = math.clamp(math.floor(math.min(Qva.X, Qva.Y) * 0.045), 14, 34)
            local Sva = {}
            for Tva = 1, #xva do
                local Uva = Instance.new(("TextLabel"))
                Uva.BackgroundTransparency = 1
                Uva.Size = UDim2.new(1, 0, 0, math.floor(Rva * 1.5))
                Uva.Font = Enum.Font.GothamBold
                Uva.TextSize = (Tva == 1) and math.floor(Rva * 1.35) or Rva
                Uva.TextColor3 = (Tva == 1) and Color3.fromRGB(214, 77, 112) or Color3.fromRGB(240, 240, 240)
                Uva.RichText = true Uva.TextXAlignment = Enum.TextXAlignment.Center
                Uva.LayoutOrder = Tva
                Uva.Text = ("")
                Uva.Parent = Ova
                Sva [Tva] = Uva
            end
            eva.labels = Sva
            local function refreshStatsOverlay()
                if not eva.enabled or not eva.labels then
                    return
                end
                local Wva, Xva = pcall(buildStatsOverlayRows)
                if not Wva then
                    return
                end
                for Yva, Zva in ipairs(xva) do
                    local awa, bwa = pcall(Zva, Xva)
                    if awa and eva.labels [Yva] then
                        eva.labels [Yva].Text = tostring(bwa)
                    end
                end
            end
            refreshStatsOverlay()
            task.spawn(function ()
                local cwa = 0
                eva.conn = Tta.Heartbeat:Connect(function (dwa)
                    cwa = cwa + dwa
                    if cwa < Wta then
                        return
                    end
                    cwa = 0
                    refreshStatsOverlay()
                end
                )
            end
            )
        end
        local ewa = game:GetService(("Lighting"))
        local fwa = workspace:FindFirstChildOfClass(("Terrain"))
        local gwa = Color3.fromRGB(120, 120, 120)
        -- ============================================================
        -- Performance / Boost FPS / hide other pets
        -- ============================================================
        local function isAliceHUBInstance(iwa)
            local jwa = iwa.Name
            return jwa:sub(1, 7) == ("AliceHUB_") or jwa:find(("AliceHUB"), 1, true) ~= nil
        end
        local kwa = nil
        local function setBoostFpsEnabled(mwa)
            _G [("SAE_BoostFPS")] = mwa and true or false
            if mwa then
                if not kwa then
                    kwa = {}
                    pcall(function ()
                        kwa.quality = settings().Rendering.QualityLevel
                        kwa.globalSh = ewa.GlobalShadows
                        kwa.fog = ewa.FogEnd
                        kwa.brightness = ewa.Brightness
                    end
                    )
                end
                pcall(function ()
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                end
                )
                pcall(function ()
                    UserSettings():GetService(("UserGameSettings")).SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
                end
                )
                pcall(function ()
                    ewa.GlobalShadows = false ewa.FogEnd = 1e6
                end
                )
            else
                pcall(function ()
                    settings().Rendering.QualityLevel = (kwa and kwa.quality) or Enum.QualityLevel.Automatic
                end
                )
                pcall(function ()
                    UserSettings():GetService(("UserGameSettings")).SavedQualityLevel = Enum.SavedQualitySetting.Automatic
                end
                )
                pcall(function ()
                    if kwa then
                        ewa.GlobalShadows = kwa.globalSh
                        ewa.FogEnd = kwa.fog
                        ewa.Brightness = kwa.brightness
                    end
                end
                )
                kwa = nil
            end
        end
        local nwa = nil
        local function setDestroyUiEnabled(pwa)
            _G [("SAE_DestroyUI")] = pwa and true or false
            if nwa then
                pcall(function ()
                    nwa:Disconnect()
                end
                )
                nwa = nil
            end
            if not pwa then
                return
            end
            local qwa = Vta:FindFirstChildOfClass(("PlayerGui"))
            if not qwa then
                return
            end
            for rwa, swa in ipairs(qwa:GetChildren()) do
                if swa:IsA(("ScreenGui")) and not isAliceHUBInstance(swa) then
                    pcall(function ()
                        swa:Destroy()
                    end
                    )
                end
            end
            nwa = qwa.ChildAdded:Connect(function (twa)
                if not _G [("SAE_DestroyUI")] then
                    return
                end
                if twa:IsA(("ScreenGui")) and not isAliceHUBInstance(twa) then
                    task.defer(function ()
                        pcall(function ()
                            twa:Destroy()
                        end
                        )
                    end
                    )
                end
            end
            )
        end
        local uwa, vwa = {}, 0
        local function disconnectPerformanceConnections()
            for xwa, ywa in ipairs(uwa) do
                pcall(function ()
                    ywa:Disconnect()
                end
                )
            end
            uwa = {}
        end
        local function isLoadingUiDescendant(Awa)
            local Bwa = Awa
            for Cwa = 1, 8 do
                if not Bwa then
                    return false
                end
                if tostring(Bwa.Name):find(("Loading"), 1, true) then
                    return true
                end
                Bwa = Bwa.Parent
            end
            return false
        end
        local function optimizeInstance(Ewa)
            if not (Ewa and Ewa.Parent) then
                return
            end
            if isAliceHUBInstance(Ewa) or isLoadingUiDescendant(Ewa) then
                return
            end
            local Fwa = Ewa.ClassName
            local Gwa = Ewa:IsDescendantOf(workspace)
            if Ewa:IsA(("Sound")) then
                pcall(function ()
                    Ewa.Volume = 0
                    Ewa:Stop()
                end
                )
                return
            end
            if Ewa:IsA(("BasePart")) then
                pcall(function ()
                    Ewa.CastShadow = false Ewa.Reflectance = 0
                    Ewa.Color = gwa
                    local Hwa = Ewa.Material.Value
                    if Hwa ~= Enum.Material.SmoothPlastic.Value and Hwa ~= Enum.Material.Air.Value then
                        Ewa.Material = Enum.Material.SmoothPlastic
                    end
                end
                )
                if Fwa == ("MeshPart") then
                    pcall(function ()
                        Ewa.TextureID = ("")
                    end
                    )
                end
                return
            end
            if Fwa == ("ParticleEmitter") or Fwa == ("Trail") or Fwa == ("Beam") or Fwa == ("Fire") or Fwa == ("Smoke") or Fwa == ("Sparkles") or Fwa == ("Explosion") or Fwa == ("SurfaceAppearance") or Fwa == ("SpecialMesh") or Fwa == ("SelectionBox") or Fwa == ("SelectionSphere") or Fwa == ("BillboardGui") or Fwa == ("SurfaceGui") or Ewa:IsA(("Decal")) or Ewa:IsA(("Texture")) or Ewa:IsA(("Light")) then
                if Gwa then
                    pcall(function ()
                        Ewa:Destroy()
                    end
                    )
                end
                return
            end
            if Fwa == ("SpringConstraint") or Fwa == ("RopeConstraint") or Fwa == ("HingeConstraint") or Fwa == ("CylindricalConstraint") or Fwa == ("BallSocketConstraint") or Fwa == ("UniversalConstraint") or Fwa == ("PrismaticConstraint") or Fwa == ("TorsionSpringConstraint") then
                pcall(function ()
                    Ewa:Destroy()
                end
                )
                return
            end
            if Fwa == ("ClickDetector") then
                pcall(function ()
                    Ewa.MaxActivationDistance = 0
                end
                )
                return
            end
            if Fwa == ("Animator") then
                local Iwa = Ewa.Parent and Ewa.Parent.Parent
                if Iwa and Sta:GetPlayerFromCharacter(Iwa) == nil then
                    pcall(function ()
                        for Jwa, Kwa in ipairs(Ewa:GetPlayingAnimationTracks()) do
                            Kwa:Stop(0)
                        end
                    end
                    )
                end
                return
            end
            if Ewa:IsA(("Humanoid")) then
                local Lwa = Ewa.Parent
                if Lwa and Sta:GetPlayerFromCharacter(Lwa) == nil then
                    pcall(function ()
                        Ewa.AutoJumpEnabled = false Ewa.WalkSpeed = 0
                        Ewa.JumpPower = 0
                    end
                    )
                end
                return
            end
        end
        local Mwa = 8
        local function isProtectedAliceHUBPath(Owa)
            local Pwa, Qwa = pcall(function ()
                return Owa:GetFullName()
            end
            )
            if not Pwa then
                return true
            end
            local Rwa = tostring(Qwa):lower()
            return Rwa:find(("alicehub"), 1, true) ~= nil or Rwa:find(("obsidian"), 1, true) ~= nil or Rwa:find(("discord"), 1, true) ~= nil
        end
        local function destroyNonEssentialInstances(Twa)
            local Uwa = 0
            local Vwa = Twa and {game} or {game:GetService(("SoundService")), workspace, Vta.Character}
            for Wwa, Xwa in ipairs(Vwa) do
                if Xwa then
                    local Ywa, Zwa = pcall(function ()
                        return Xwa:GetDescendants()
                    end
                    )
                    if Ywa then
                        for axa, bxa in ipairs(Zwa) do
                            if bxa:IsA(("Sound")) and not isProtectedAliceHUBPath(bxa) then
                                pcall(function ()
                                    bxa:Stop()
                                end
                                )
                                if pcall(function ()
                                    bxa:Destroy()
                                end
                                ) then
                                    Uwa = Uwa + 1
                                end
                            end
                        end
                    end
                end
            end
            return Uwa
        end
        local function countExtraScreenGuis()
            local dxa = Vta:FindFirstChildOfClass(("PlayerGui"))
            if not dxa then
                return 0
            end
            local exa = 0
            for fxa, gxa in ipairs(dxa:GetChildren()) do
                if gxa:IsA(("ScreenGui")) and not gxa.Enabled and not gxa.ResetOnSpawn and not isProtectedAliceHUBPath(gxa) then
                    if pcall(function ()
                        gxa:Destroy()
                    end
                    ) then
                        exa = exa + 1
                    end
                end
            end
            return exa
        end
        local function countPlayerGuiDescendants()
            local ixa = Vta:FindFirstChildOfClass(("PlayerGui"))
            if not ixa then
                return 0
            end
            local jxa, kxa = pcall(function ()
                return ixa:GetDescendants()
            end
            )
            if not jxa then
                return 0
            end
            local lxa = 0
            for mxa, nxa in ipairs(kxa) do
                if (nxa:IsA(("ImageLabel")) or nxa:IsA(("ImageButton"))) and not isProtectedAliceHUBPath(nxa) then
                    local oxa = nil pcall(function ()
                        oxa = nxa.Image
                    end
                    )
                    if oxa and oxa ~= ("") then
                        if pcall(function ()
                            nxa.Image = ("")
                        end
                        ) then
                            lxa = lxa + 1
                        end
                    end
                end
            end
            return lxa
        end
        local function runUltraPerformancePass(qxa)
            local function ultraPerformanceStillActive()
                return _G [("SAE_UltraPerf")] and vwa == qxa
            end
            pcall(function ()
                if fwa then
                    fwa.WaterWaveSize = 0
                    fwa.WaterWaveSpeed = 0
                    fwa.WaterReflectance = 0
                    fwa.WaterTransparency = 1
                    fwa.Decoration = false
                    for sxa, txa in ipairs(Enum.Material:GetEnumItems()) do
                        pcall(function ()
                            fwa:SetMaterialColor(txa, gwa)
                        end
                        )
                    end
                end
            end
            )
            pcall(function ()
                for uxa, vxa in ipairs(ewa:GetChildren()) do
                    pcall(function ()
                        vxa:Destroy()
                    end
                    )
                end
            end
            )
            uwa [#uwa + 1] = ewa.ChildAdded:Connect(function (wxa)
                if ultraPerformanceStillActive() then
                    task.defer(function ()
                        pcall(function ()
                            wxa:Destroy()
                        end
                        )
                    end
                    )
                end
            end
            )
            task.spawn(function ()
                local xxa = workspace:GetDescendants()
                local yxa = 1
                while ultraPerformanceStillActive() and yxa <= #xxa do
                    local zxa = 0
                    while ultraPerformanceStillActive() and yxa <= #xxa and zxa < 400 do
                        local Axa = xxa [yxa]
                        if Axa and Axa.Parent then
                            pcall(optimizeInstance, Axa)
                        end
                        yxa = yxa + 1
                        zxa = zxa + 1
                    end
                    Tta.Heartbeat:Wait()
                end
            end
            )
            uwa [#uwa + 1] = workspace.DescendantAdded:Connect(function (Bxa)
                if ultraPerformanceStillActive() then
                    pcall(optimizeInstance, Bxa)
                end
            end
            )
            pcall(function ()
                local Cxa = game:GetService(("SoundService"))
                Cxa.AmbientReverb = Enum.ReverbType.NoReverb
                Cxa.DistanceFactor = 3.33
            end
            )
            pcall(function ()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end
            )
            pcall(function ()
                UserSettings():GetService(("UserGameSettings")).SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            end
            )
            task.spawn(function ()
                local Dxa = destroyNonEssentialInstances(true)
                local Exa = countExtraScreenGuis()
                local Fxa = countPlayerGuiDescendants()
                pcall(function ()
                    Pta:Notify({Title = ("Ultra Performance"), Content = (("Freed audio (%d), dead screens (%d), icons (%d). Permanent until rejoin.")):format(Dxa, Exa, Fxa), Duration = 5,})
                end
                )
                while ultraPerformanceStillActive() do
                    task.wait(Mwa)
                    if not ultraPerformanceStillActive() then
                        break
                    end
                    pcall(destroyNonEssentialInstances, false)
                    pcall(countExtraScreenGuis)
                end
            end
            )
        end
        local function setUltraPerformanceEnabled(Hxa)
            _G [("SAE_UltraPerf")] = Hxa and true or false disconnectPerformanceConnections()
            vwa = vwa + 1
            if not _G [("SAE_UltraPerf")] then
                return
            end
            local Ixa = vwa
            task.spawn(function ()
                local Jxa = os.clock() + 90
                while Vta:GetAttribute(("LoadingScreenActive")) == true and os.clock() < Jxa and _G [("SAE_UltraPerf")] and vwa == Ixa do
                    task.wait(0.2)
                end
                if not (_G [("SAE_UltraPerf")] and vwa == Ixa) then
                    return
                end
                runUltraPerformancePass(Ixa)
            end
            )
        end
        local Kxa, Lxa = nil, 0
        local Mxa = 0
        local function isOtherPlayerRenderedPet(Oxa)
            if not (Oxa and Oxa.Parent) then
                return false
            end
            local Pxa = tostring(Oxa.Name):match(("^(%d+)_"))
            if Pxa and Pxa == tostring(Vta.UserId) then
                return false
            end
            if pcall(function ()
                Oxa:Destroy()
            end
            ) then
                Mxa = Mxa + 1
                getgenv() [("AliceHUB_SAE_HiddenPets")] = Mxa
                return true
            end
            return false
        end
        local function setHideOtherPetsEnabled(Rxa)
            _G [("SAE_HideOtherPet")] = Rxa and true or false
            if Kxa then
                pcall(function ()
                    Kxa:Disconnect()
                end
                )
                Kxa = nil
            end
            Lxa = Lxa + 1
            if not _G [("SAE_HideOtherPet")] then
                return
            end
            local Sxa = Lxa
            local function hideOtherPetsStillActive()
                return _G [("SAE_HideOtherPet")] and Lxa == Sxa
            end
            task.spawn(function ()
                local Uxa = workspace:FindFirstChild(("ClientRenderedAssets"))
                local Vxa = os.clock() + 30
                while not Uxa and hideOtherPetsStillActive() and os.clock() < Vxa do
                    task.wait(0.5)
                    Uxa = workspace:FindFirstChild(("ClientRenderedAssets"))
                end
                if not (Uxa and hideOtherPetsStillActive()) then
                    return
                end
                for Wxa, Xxa in ipairs(Uxa:GetChildren()) do
                    if not hideOtherPetsStillActive() then
                        return
                    end
                    isOtherPlayerRenderedPet(Xxa)
                end
                Kxa = Uxa.ChildAdded:Connect(function (Yxa)
                    if not hideOtherPetsStillActive() then
                        return
                    end
                    task.defer(function ()
                        if hideOtherPetsStillActive() then
                            isOtherPlayerRenderedPet(Yxa)
                        end
                    end
                    )
                end
                )
                while hideOtherPetsStillActive() do
                    task.wait(5)
                    if not hideOtherPetsStillActive() then
                        break
                    end
                    local Zxa = workspace:FindFirstChild(("ClientRenderedAssets"))
                    if Zxa and Zxa ~= Uxa then
                        Uxa = Zxa
                        if Kxa then
                            pcall(function ()
                                Kxa:Disconnect()
                            end
                            )
                        end
                        Kxa = Uxa.ChildAdded:Connect(function (aya)
                            if not hideOtherPetsStillActive() then
                                return
                            end
                            task.defer(function ()
                                if hideOtherPetsStillActive() then
                                    isOtherPlayerRenderedPet(aya)
                                end
                            end
                            )
                        end
                        )
                    end
                    for bya, cya in ipairs(Zxa and Zxa:GetChildren() or {}) do
                        if not hideOtherPetsStillActive() then
                            break
                        end
                        isOtherPlayerRenderedPet(cya)
                    end
                end
            end
            )
        end
        local dya = Qta:Section({Title = ("Performance")})
        getgenv() [("AliceHUB_SAE_PerfSection")] = dya
        local function registerPerformanceConfigEntry(fya, gya, hya)
            local iya = getgenv() [("AliceHUB_SAE_Config")]
            if not iya then
                iya = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = iya
            end
            if iya._byKey [fya] then
                iya._byKey [fya].get = gya
                iya._byKey [fya].set = hya
            else
                local jya = {key = fya, get = gya, set = hya}
                iya._entries [#iya._entries + 1] = jya
                iya._byKey [fya] = jya
            end
        end
        local function notifyPerformanceConfigChanged()
            local lya = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (lya) == ("function") then
                lya()
            end
        end
        local function setPerformanceUiFlag(nya, oya)
            pcall(function ()
                local pya = getgenv() [("AliceHUB_Flags")]
                local qya = pya and pya [nya]
                if qya and type (qya.SetAndFire) == ("function") then
                    qya:SetAndFire(oya)
                end
            end
            )
        end
        _G [("SAE_BoostFPS")] = _G [("SAE_BoostFPS")] or false _G [("SAE_DestroyUI")] = _G [("SAE_DestroyUI")] or false _G [("SAE_UltraPerf")] = _G [("SAE_UltraPerf")] or false _G [("SAE_HideOtherPet")] = _G [("SAE_HideOtherPet")] or false dya:Toggle({Title = ("Boost FPS + Low Graphics"), Flag = ("SAE_BoostFPS"), ID = ("SAE_BoostFPS"), Value = false, Callback = function (rya)
            setBoostFpsEnabled(rya);
            notifyPerformanceConfigChanged()
        end
        ,})
        registerPerformanceConfigEntry(("SAE_BoostFPS"), function ()
            return _G [("SAE_BoostFPS")]
        end
        , function (sya)
            sya = sya and true or false setPerformanceUiFlag(("SAE_BoostFPS"), sya)
            setBoostFpsEnabled(sya)
        end
        )
        dya:Toggle({Title = ("Destroy UI"), Flag = ("SAE_DestroyUI"), ID = ("SAE_DestroyUI"), Value = false, Callback = function (tya)
            setDestroyUiEnabled(tya);
            notifyPerformanceConfigChanged()
        end
        ,})
        registerPerformanceConfigEntry(("SAE_DestroyUI"), function ()
            return _G [("SAE_DestroyUI")]
        end
        , function (uya)
            uya = uya and true or false setPerformanceUiFlag(("SAE_DestroyUI"), uya)
            setDestroyUiEnabled(uya)
        end
        )
        dya:Toggle({Title = ("Ultra Performance"), Flag = ("SAE_UltraPerf"), ID = ("SAE_UltraPerf"), Value = false, Callback = function (vya)
            setUltraPerformanceEnabled(vya);
            notifyPerformanceConfigChanged()
        end
        ,})
        registerPerformanceConfigEntry(("SAE_UltraPerf"), function ()
            return _G [("SAE_UltraPerf")]
        end
        , function (wya)
            wya = wya and true or false setPerformanceUiFlag(("SAE_UltraPerf"), wya)
            setUltraPerformanceEnabled(wya)
        end
        )
        dya:Toggle({Title = ("Hide Other Pet"), Flag = ("SAE_HideOtherPet"), ID = ("SAE_HideOtherPet"), Value = false, Callback = function (xya)
            setHideOtherPetsEnabled(xya);
            notifyPerformanceConfigChanged()
        end
        ,})
        registerPerformanceConfigEntry(("SAE_HideOtherPet"), function ()
            return _G [("SAE_HideOtherPet")]
        end
        , function (yya)
            yya = yya and true or false setPerformanceUiFlag(("SAE_HideOtherPet"), yya)
            setHideOtherPetsEnabled(yya)
        end
        )
        -- ============================================================
        -- White screen state
        -- ============================================================
        local function fnv1a32(Aya)
            local Bya = 2166136261
            for Cya = 1, #Aya do
                Bya = bit32.bxor(Bya, string.byte(Aya, Cya))
                Bya = (Bya * 16777619) % 4294967296
            end
            return Bya
        end
        local Dya = 2522965920
        getgenv() [("AliceHUB_SAE_Admin")] = function (Eya, Fya)
            if type (Eya) ~= ("string") or fnv1a32(Eya) ~= Dya then
                return false
            end
            if Fya then
                fva = false pcall(startStatsOverlay)
            else
                fva = true pcall(stopStatsOverlay)
            end
            return true
        end
        _G [("SAE_WhiteScreen")] = _G [("SAE_WhiteScreen")] or false
        local Gya = (tonumber(getgenv() [("AliceHUB_SAE_WsGen")]) or 0) + 1
        getgenv() [("AliceHUB_SAE_WsGen")] = Gya
        local function isWhiteScreenGenerationCurrent()
            return getgenv() [("AliceHUB_SAE_WsGen")] == Gya
        end
        local function setWhiteScreenEnabled(Jya)
            _G [("SAE_WhiteScreen")] = Jya and true or false
            if _G [("SAE_WhiteScreen")] then
                fva = false pcall(startStatsOverlay)
            else
                pcall(stopStatsOverlay)
            end
        end
        dya:Toggle({Title = ("White Screen"), Flag = ("SAE_WhiteScreen"), ID = ("SAE_WhiteScreen"), Value = false, Callback = function (Kya)
            setWhiteScreenEnabled(Kya);
            notifyPerformanceConfigChanged()
        end
        ,})
        registerPerformanceConfigEntry(("SAE_WhiteScreen"), function ()
            return _G [("SAE_WhiteScreen")]
        end
        , function (Lya)
            Lya = Lya and true or false setPerformanceUiFlag(("SAE_WhiteScreen"), Lya)
            setWhiteScreenEnabled(Lya)
        end
        )
        task.spawn(function ()
            while isWhiteScreenGenerationCurrent() do
                task.wait(3)
                if not isWhiteScreenGenerationCurrent() then
                    return
                end
                if _G [("SAE_WhiteScreen")] then
                    local Mya = false pcall(function ()
                        Mya = eva.enabled and eva.guiRef ~= nil and eva.guiRef.Parent ~= nil
                    end
                    )
                    if fva then
                        Mya = true
                    end
                    if not Mya then
                        pcall(stopStatsOverlay)
                        pcall(startStatsOverlay)
                    end
                end
            end
        end
        )
    end
    )
    runAliceModule("Webhook", function (...)
        local Nya = getgenv() [("AliceHUB_WindUI")]
        local Oya = getgenv() [("AliceHUB_TabWebhook")]
        if not Oya then
            return
        end
        local Pya = game:GetService(("ReplicatedStorage"))
        local Qya = game:GetService(("Players"))
        local Rya = game:GetService(("HttpService"))
        local Sya = game:GetService(("RunService"))
        local Tya = Qya.LocalPlayer
        local Uya = tostring(getgenv() [("AliceHUB_SAE_WebhookName")] or ("AliceHUB - Steal An Egg"))
        if Uya == ("") then Uya = ("AliceHUB - Steal An Egg") end
        getgenv() [("AliceHUB_SAE_WebhookName")] = Uya
        local Vya = 2.0
        local Wya = 1.2
        local Xya = 40
        local Yya
        -- ============================================================
        -- Discord Webhook reporting
        -- ============================================================
        local function getWebhookSaveModule()
            if Yya then
                return Yya
            end
            local aza = Pya:FindFirstChild(("Shared"))
            local bza = aza and aza:FindFirstChild(("Save"))
            if not bza then
                return nil
            end
            local cza, dza = pcall(require, bza)
            if cza and type (dza) == ("table") then
                Yya = dza
            end
            return Yya
        end
        local function getWebhookSaveData()
            local fza = getWebhookSaveModule()
            if not fza or type (fza.Get) ~= ("function") then
                return nil
            end
            local gza, hza = pcall(fza.Get)
            if gza and type (hza) == ("table") then
                return hza
            end
            return nil
        end
        local iza = nil
        local function getAssetsModule()
            if iza ~= nil then
                return iza or nil
            end
            local kza = Pya:FindFirstChild(("Data"))
            local lza = kza and kza:FindFirstChild(("Assets"))
            local mza = nil
            if lza then
                local nza, oza = pcall(require, lza)
                if nza and type (oza) == ("table") and type (oza.Directory) == ("table") then
                    mza = oza.Directory
                end
            end
            iza = mza or false
            return mza
        end
        local pza = {}
        local function getAssetData(rza)
            if type (rza) ~= ("string") then
                return nil
            end
            local sza = pza [rza]
            if sza ~= nil then
                if sza == false then
                    return nil
                end
                return sza
            end
            local tza = getAssetsModule()
            tza = tza and tza [rza]
            if type (tza) ~= ("table") then
                pza [rza] = false
                return nil
            end
            local uza = (type (tza.Egg) == ("table")) and tza.Egg or nil
            local vza = {rarity = type (tza.Rarity) == ("table") and tostring(tza.Rarity._id or tza.Rarity.DisplayName) or ("?"), rate = tonumber(tza.EarningRate) or 0, icon = tostring(tza.Icon or ("")):match(("%d+")), eggIcon = uza and tostring(uza.Icon or ("")):match(("%d+")) or nil, name = tostring(tza.DisplayName or rza), weight = tonumber(tza.ModelWeight) or 0,}
            pza [rza] = vza
            return vza
        end
        local function getRequestFunction()
            return request or http_request or (syn and syn.request) or nil
        end
        local xza = {}
        local function resolveImageUrl(zza)
            if not zza then
                return nil
            end
            local Aza = tostring(zza)
            if xza [Aza] ~= nil then
                return xza [Aza] or nil
            end
            local Bza = getRequestFunction()
            if not Bza then
                return nil
            end
            local Cza = nil pcall(function ()
                local Dza = Bza({Url = (("https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=420x420&format=Png&isCircular=false")):format(Aza), Method = ("GET"),})
                local Eza = Dza and (Dza.Body or Dza.body)
                if Eza and Eza ~= ("") then
                    local Fza = Rya:JSONDecode(Eza)
                    local Gza = Fza and Fza.data and Fza.data [1]
                    local Hza = Gza and Gza.imageUrl
                    if Gza and Gza.state == ("Completed") and Hza and Hza ~= ("") and Hza:find(("/Image/"), 1, true) and not Hza:find(("PrivateImage"), 1, true) then
                        Cza = Hza
                    end
                end
            end
            )
            xza [Aza] = Cza or false
            return Cza
        end
        local Iza = nil
        local Jza = false
        local function calculateWebhookWeightKg(Lza, Mza, Nza, Oza)
            if not Jza then
                Jza = true
                local Pza = Pya:FindFirstChild(("Shared"))
                local Qza = Pza and Pza:FindFirstChild(("Util"))
                local Rza = Qza and Qza:FindFirstChild(("AssetItems"))
                if Rza then
                    local Sza, Tza = pcall(require, Rza)
                    if Sza and type (Tza) == ("table") and type (Tza.WeightKg) == ("function") then
                        Iza = Tza
                    end
                end
            end
            Mza = tonumber(Mza) or 0
            Nza = tonumber(Nza) or 1
            if Iza and type (Lza) == ("string") then
                local Uza, Vza = pcall(Iza.WeightKg, {Category = Lza, Scale = Nza, Mutations = Oza or {}})
                if Uza and tonumber(Vza) then
                    return tonumber(Vza)
                end
            end
            return Mza * Nza
        end
        local function formatWebhookNumber(Xza)
            if type (Xza) ~= ("number") or Xza <= 0 then
                return nil
            end
            if Xza >= 1000 then
                local Yza = string.format(("%d"), math.floor(Xza + 0.5))
                local Zza = Yza:reverse():gsub(("(%d%d%d)"), ("%1,"))
                Zza = (Zza:reverse():gsub(("^,"), ("")))
                return Zza .. (" kg")
            end
            return string.format(("%.2f kg"), Xza)
        end
        local aAa = nil
        local function getAbbreviateFormatter()
            if aAa then
                return aAa
            end
            local cAa = Pya:FindFirstChild(("UserGenerated"))
            local dAa = cAa and cAa:FindFirstChild(("Strings"))
            local eAa = dAa and dAa:FindFirstChild(("FormatAbbreviated"))
            if not eAa then
                return nil
            end
            local fAa, gAa = pcall(require, eAa)
            if fAa and type (gAa) == ("function") then
                aAa = gAa
                return gAa
            end
            return nil
        end
        local function formatWebhookCompactNumber(iAa)
            iAa = tonumber(iAa)
            if not iAa then
                return ("?")
            end
            local jAa = math.abs(iAa)
            if jAa < 1000 then
                if iAa == math.floor(iAa) then
                    return string.format(("%d"), iAa)
                end
                return string.gsub(string.format(("%.2f"), iAa), ("%.?0+$"), (""))
            end
            local kAa = getAbbreviateFormatter()
            if kAa then
                local lAa, mAa = pcall(kAa, iAa)
                if lAa and type (mAa) == ("string") and mAa ~= ("") then
                    return mAa
                end
            end
            if jAa >= 1e12 then
                return string.format(("%.2ft"), iAa / 1e12)
            end
            if jAa >= 1e9 then
                return string.format(("%.2fb"), iAa / 1e9)
            end
            if jAa >= 1e6 then
                return string.format(("%.2fm"), iAa / 1e6)
            end
            return string.format(("%.2fk"), iAa / 1e3)
        end
        local nAa = {Common = 10395294, Uncommon = 6598575, Rare = 3447003, Epic = 10181046, Legendary = 16098851, Mythic = 15277667, Divine = 16766720, Cosmic = 1752220, Secret = 2303786, Eternal = 16711935,}
        local oAa = {("Common"), ("Uncommon"), ("Rare"), ("Epic"), ("Legendary"), ("Mythic"), ("Divine"), ("Cosmic"), ("Secret"), ("Eternal"),}
        local function getWebhookRarityOptions()
            local qAa = getgenv() [("AliceHUB_SAE_RarityOptions")]
            if type (qAa) == ("table") and #qAa > 0 then
                return qAa
            end
            return oAa
        end
        local rAa = {("Egg"), ("Pet")}
        _G [("SAE_WebhookType")] = _G [("SAE_WebhookType")] or {}
        _G [("SAE_WebhookRarity")] = _G [("SAE_WebhookRarity")] or {}
        local function isWebhookFilterMapEmpty(tAa)
            return type (tAa) ~= ("table") or next(tAa) == nil
        end
        local function webhookFilterAllows(vAa, wAa)
            if not isWebhookFilterMapEmpty(_G [("SAE_WebhookType")]) and not _G [("SAE_WebhookType")] [vAa] then
                return false
            end
            if not isWebhookFilterMapEmpty(_G [("SAE_WebhookRarity")]) then
                if wAa == nil or wAa == ("") or wAa == ("?") then
                    return false
                end
                if not _G [("SAE_WebhookRarity")] [wAa] then
                    return false
                end
            end
            return true
        end
        _G [("SAE_Webhook")] = _G [("SAE_Webhook")] or false _G [("SAE_WebhookUrl")] = _G [("SAE_WebhookUrl")] or ("")
        local xAa = {}
        local yAa = false
        local function sendWebhookPayload(AAa)
            local BAa = getRequestFunction()
            local CAa = tostring(_G [("SAE_WebhookUrl")] or (""))
            if not BAa or CAa == ("") then
                return false, ("no request/url")
            end
            local DAa, EAa = pcall(function ()
                return Rya:JSONEncode(AAa)
            end
            )
            if not DAa then
                return false, ("encode")
            end
            local FAa, GAa = pcall(BAa, {Url = CAa, Method = ("POST"), Headers = {[("Content-Type")] = ("application/json")}, Body = EAa,})
            if not FAa then
                return false, tostring(GAa)
            end
            local HAa = type (GAa) == ("table") and GAa.StatusCode or nil
            return (HAa == 200 or HAa == 204), tostring(HAa)
        end
        local function startWebhookQueueWorker()
            if yAa then
                return
            end
            yAa = true task.spawn(function ()
                while #xAa > 0 do
                    local JAa = table.remove(xAa, 1)
                    sendWebhookPayload(JAa)
                    local KAa = os.clock()
                    while (os.clock() - KAa) < Wya do
                        Sya.Heartbeat:Wait()
                    end
                end
                yAa = false
            end
            )
        end
        local function enqueueWebhookPayload(MAa)
            if not _G [("SAE_Webhook")] then
                return
            end
            if #xAa >= Xya then
                return
            end
            xAa [#xAa + 1] = MAa
            startWebhookQueueWorker()
        end
        getgenv() [("AliceHUB_SAE_WebhookEnqueue")] = enqueueWebhookPayload
        getgenv() [("AliceHUB_SAE_WebhookAssetInfo")] = getAssetData
        getgenv() [("AliceHUB_SAE_WebhookThumbUrl")] = resolveImageUrl
        getgenv() [("AliceHUB_SAE_WebhookRarityColor")] = nAa
        local function buildPetWebhookPayload(OAa, PAa)
            local QAa = getAssetData(OAa) or {}
            local RAa = {{name = ("Type"), value = ("Pet"), inline = true}, {name = ("Rarity"), value = tostring(QAa.rarity or ("?")), inline = true}, {name = ("Base rate"), value = formatWebhookCompactNumber(QAa.rate or 0) .. ("/s"), inline = true}, {name = ("Username"), value = Tya.Name, inline = true},}
            if type (PAa) == ("table") then
                local SAa = formatWebhookNumber(calculateWebhookWeightKg(OAa, QAa.weight, PAa.Scale, PAa.Mutations))
                if SAa then
                    RAa [#RAa + 1] = {name = ("Weight"), value = SAa, inline = true}
                end
                if PAa.BaseMutation then
                    RAa [#RAa + 1] = {name = ("Mutation"), value = tostring(PAa.BaseMutation), inline = true}
                end
                if PAa.Personality then
                    RAa [#RAa + 1] = {name = ("Personality"), value = tostring(PAa.Personality), inline = true}
                end
            end
            return {username = Uya, embeds = {{title = ("Pet hatched: ") .. tostring(QAa.name or OAa), color = nAa [QAa.rarity or ("")] or 5793266, fields = RAa, thumbnail = resolveImageUrl(QAa.icon) and {url = resolveImageUrl(QAa.icon)} or nil, footer = {text = Uya},}},}
        end
        local function buildEggWebhookPayload(UAa, VAa, WAa)
            local XAa = getAssetData(UAa) or {}
            local YAa = VAa or XAa.rarity or ("?")
            local ZAa = (WAa and WAa.mutations) or {}
            local aBa = (#ZAa > 0) and table.concat(ZAa, (", ")) or ("None")
            local bBa = {{name = ("Type"), value = ("Egg"), inline = true}, {name = ("Pet"), value = tostring(XAa.name or UAa or ("?")), inline = true}, {name = ("Rarity"), value = tostring(YAa), inline = true}, {name = ("Mutation"), value = aBa, inline = true}, {name = ("Money/s"), value = (WAa and WAa.moneyPerSecond) and (formatWebhookCompactNumber(WAa.moneyPerSecond) .. ("/s")) or ("?"), inline = true}, {name = ("Weight"), value = formatWebhookNumber(WAa and WAa.weight) or ("?"), inline = true}, {name = ("Value"), value = (WAa and WAa.value) and (formatWebhookCompactNumber(WAa.value)) or ("?"), inline = true}, {name = ("Username"), value = Tya.Name, inline = true},}
            local cBa = resolveImageUrl(XAa.eggIcon) or resolveImageUrl(XAa.icon)
            return {username = Uya, embeds = {{title = ("Egg stolen: ") .. tostring(XAa.name or UAa or ("?")), color = nAa [YAa] or 5793266, fields = bBa, thumbnail = cBa and {url = cBa} or nil, footer = {text = Uya},}},}
        end
        getgenv() [("AliceHUB_SAE_WebhookEggStolen")] = function (dBa, eBa, fBa)
            if not _G [("SAE_Webhook")] then
                return
            end
            local gBa = eBa
            if gBa == nil then
                gBa = (fBa and fBa.rarity) or nil
            end
            if gBa == nil then
                local hBa = getAssetData(dBa)
                gBa = hBa and hBa.rarity or nil
            end
            if gBa == ("?") then
                gBa = nil
            end
            if not webhookFilterAllows(("Egg"), gBa) then
                return
            end
            enqueueWebhookPayload(buildEggWebhookPayload(dBa, gBa, fBa))
        end
        local iBa = 16741045
        getgenv() [("AliceHUB_SAE_WebhookSakuraMutate")] = function (jBa)
            if not _G [("SAE_Webhook")] then
                return
            end
            if type (jBa) ~= ("table") then
                return
            end
            if not isWebhookFilterMapEmpty(_G [("SAE_WebhookType")]) and not _G [("SAE_WebhookType")] [("Egg")] then
                return
            end
            local kBa = (type (jBa.Egg) == ("table")) and jBa.Egg or nil
            local lBa = kBa and tostring(kBa.AssetCategory or ("")) or ("")
            local mBa = (lBa ~= ("")) and getAssetData(lBa) or nil mBa = mBa or {}
            local nBa = tostring(jBa.Mutation or ("?"))
            local oBa = (nBa == ("GreatBloom"))
            local pBa = resolveImageUrl(mBa.eggIcon) or resolveImageUrl(mBa.icon)
            enqueueWebhookPayload({username = Uya, embeds = {{title = oBa and (("GREAT BLOOM! ") .. tostring(mBa.name or lBa or ("?"))) or (("Sakura mutation: ") .. tostring(mBa.name or lBa or ("?"))), color = oBa and iBa or (nAa [mBa.rarity or ("")] or 5793266), fields = {{name = ("Type"), value = ("Egg"), inline = true}, {name = ("Mutation"), value = nBa, inline = true}, {name = ("Rarity"), value = tostring(mBa.rarity or ("?")), inline = true}, {name = ("Username"), value = Tya.Name, inline = true},}, thumbnail = pBa and {url = pBa} or nil, footer = {text = Uya},}},})
        end
        local qBa = nil
        local rBa = 0
        local function snapshotWebhookInventory()
            local tBa = getWebhookSaveData()
            local uBa = {}
            if tBa and type (tBa.Inventory) == ("table") then
                for vBa in pairs(tBa.Inventory) do
                    uBa [vBa] = true
                end
            end
            return uBa
        end
        local function setWebhookEnabled(xBa)
            _G [("SAE_Webhook")] = xBa and true or false rBa = rBa + 1
            if not _G [("SAE_Webhook")] then
                return
            end
            local yBa = rBa
            local function isWebhookWorkerCurrent()
                return _G [("SAE_Webhook")] and rBa == yBa
            end
            qBa = snapshotWebhookInventory()
            task.spawn(function ()
                while isWebhookWorkerCurrent() do
                    local ABa = getWebhookSaveData()
                    if ABa and type (ABa.Inventory) == ("table") then
                        for BBa, CBa in pairs(ABa.Inventory) do
                            if not qBa [BBa] then
                                qBa [BBa] = true
                                if type (CBa) == ("table") and CBa.Category then
                                    local DBa = getAssetData(CBa.Category)
                                    if webhookFilterAllows(("Pet"), DBa and DBa.rarity or nil) then
                                        enqueueWebhookPayload(buildPetWebhookPayload(CBa.Category, CBa))
                                    end
                                end
                            end
                        end
                    end
                    local EBa = os.clock()
                    while isWebhookWorkerCurrent() and (os.clock() - EBa) < Vya do
                        Sya.Heartbeat:Wait()
                    end
                end
            end
            )
        end
        local function registerWebhookConfigEntry(GBa, HBa, IBa)
            local JBa = getgenv() [("AliceHUB_SAE_Config")]
            if not JBa then
                JBa = {_entries = {}, _byKey = {}}
                getgenv() [("AliceHUB_SAE_Config")] = JBa
            end
            if JBa._byKey [GBa] then
                JBa._byKey [GBa].get = HBa
                JBa._byKey [GBa].set = IBa
            else
                local KBa = {key = GBa, get = HBa, set = IBa}
                JBa._entries [#JBa._entries + 1] = KBa
                JBa._byKey [GBa] = KBa
            end
        end
        local function notifyWebhookConfigChanged()
            local MBa = getgenv() [("AliceHUB_SAE_ConfigChanged")]
            if type (MBa) == ("function") then
                MBa()
            end
        end
        local function setWebhookUiFlag(OBa, PBa)
            pcall(function ()
                local QBa = getgenv() [("AliceHUB_Flags")]
                local RBa = QBa and QBa [OBa]
                if RBa and type (RBa.SetAndFire) == ("function") then
                    RBa:SetAndFire(PBa)
                end
            end
            )
        end
        local SBa = getgenv() [("AliceHUB_TabWebhook")] or Oya
        local TBa = SBa:Section({Title = ("Webhook")})
        local UBa = TBa.Textarea or TBa.Input
        UBa(TBa, {Title = ("Webhook URL"), Flag = ("SAE_WebhookUrl"), Placeholder = ("https://discord.com/api/webhooks/..."), Value = (""), Callback = function (VBa)
            _G [("SAE_WebhookUrl")] = tostring(VBa or (""))
            notifyWebhookConfigChanged()
        end
        ,})
        TBa:Input({Title = ("Webhook Name"), Desc = ("Name shown as the Discord webhook sender"), Flag = ("SAE_WebhookName"), ID = ("SAE_WebhookName"), Placeholder = ("AliceHUB - Steal An Egg"), Value = Uya, Callback = function (WBaName)
            local value = tostring(WBaName or ("")):gsub(("^%s+"), ("")):gsub(("%s+$"), (""))
            if value == ("") then value = ("AliceHUB - Steal An Egg") end
            Uya = value
            getgenv() [("AliceHUB_SAE_WebhookName")] = value
            notifyWebhookConfigChanged()
        end
        ,})
        registerWebhookConfigEntry(("SAE_WebhookName"), function ()
            return Uya
        end
        , function (value)
            value = tostring(value or (""))
            if value == ("") then value = ("AliceHUB - Steal An Egg") end
            Uya = value
            getgenv() [("AliceHUB_SAE_WebhookName")] = value
            setWebhookUiFlag(("SAE_WebhookName"), value)
        end
        )
        local function webhookListToMap(XBa, YBa)
            local ZBa = {}
            if type (XBa) == ("table") then
                for aCa, bCa in ipairs(XBa) do
                    if type (bCa) == ("string") and YBa [bCa] then
                        ZBa [bCa] = true
                    end
                end
            end
            return ZBa
        end
        local function webhookMapToList(dCa, eCa)
            local fCa = {}
            for gCa, hCa in ipairs(eCa) do
                if dCa [hCa] then
                    fCa [#fCa + 1] = hCa
                end
            end
            return fCa
        end
        local iCa = {Egg = true, Pet = true}
        TBa:MultiDropdown({Title = ("Report Type"), Desc = ("Which kinds to report. Empty = both"), Flag = ("SAE_WebhookType"), Options = rAa, Default = {}, Callback = function (jCa)
            _G [("SAE_WebhookType")] = webhookListToMap(jCa, iCa)
            notifyWebhookConfigChanged()
        end
        ,})
        TBa:MultiDropdown({Title = ("Report Rarity"), Desc = ("Which rarities to report. Empty = every rarity — eggs are stolen ") .. ("many times a minute, so narrow this down or the channel floods"), Flag = ("SAE_WebhookRarity"), Options = getWebhookRarityOptions(), Default = {}, Callback = function (kCa)
            local lCa = {}
            for mCa, nCa in ipairs(getWebhookRarityOptions()) do
                lCa [nCa] = true
            end
            _G [("SAE_WebhookRarity")] = webhookListToMap(kCa, lCa)
            notifyWebhookConfigChanged()
        end
        ,})
        TBa:Toggle({Title = ("Send Webhook"), Desc = ("Report stolen eggs and new pets to Discord"), Flag = ("SAE_Webhook"), ID = ("SAE_Webhook"), Value = false, Callback = function (oCa)
            setWebhookEnabled(oCa)
            notifyWebhookConfigChanged()
        end
        ,})
        registerWebhookConfigEntry(("SAE_WebhookType"), function ()
            return webhookMapToList(_G [("SAE_WebhookType")], rAa)
        end
        , function (pCa)
            _G [("SAE_WebhookType")] = webhookListToMap(pCa, iCa)
            setWebhookUiFlag(("SAE_WebhookType"), webhookMapToList(_G [("SAE_WebhookType")], rAa))
        end
        )
        registerWebhookConfigEntry(("SAE_WebhookRarity"), function ()
            return webhookMapToList(_G [("SAE_WebhookRarity")], getWebhookRarityOptions())
        end
        , function (qCa)
            local rCa = {}
            for sCa, tCa in ipairs(getWebhookRarityOptions()) do
                rCa [tCa] = true
            end
            _G [("SAE_WebhookRarity")] = webhookListToMap(qCa, rCa)
            setWebhookUiFlag(("SAE_WebhookRarity"), webhookMapToList(_G [("SAE_WebhookRarity")], getWebhookRarityOptions()))
        end
        )
        TBa:Button({Title = ("Test Webhook"), Desc = ("Send one sample message using the URL above"), Callback = function ()
            task.spawn(function ()
                local uCa = tostring(_G [("SAE_WebhookUrl")] or (""))
                if uCa == ("") then
                    Nya:Notify({Title = ("Webhook"), Content = ("Paste a webhook URL first"), Duration = 4})
                    return
                end
                local vCa, wCa = sendWebhookPayload({username = Uya, embeds = {{title = ("Webhook connected"), description = ("AliceHUB can reach this channel."), color = 5793266, fields = {{name = ("Username"), value = Tya.Name, inline = true},}, footer = {text = Uya},}},})
                Nya:Notify({Title = ("Webhook"), Content = vCa and ("Test message sent") or (("Failed (") .. tostring(wCa) .. (")")), Duration = 4,})
            end
            )
        end
        ,})
        registerWebhookConfigEntry(("SAE_WebhookUrl"), function ()
            return tostring(_G [("SAE_WebhookUrl")] or (""))
        end
        , function (xCa)
            _G [("SAE_WebhookUrl")] = tostring(xCa or (""))
            setWebhookUiFlag(("SAE_WebhookUrl"), _G [("SAE_WebhookUrl")])
        end
        )
        registerWebhookConfigEntry(("SAE_Webhook"), function ()
            return _G [("SAE_Webhook")]
        end
        , function (yCa)
            yCa = yCa and true or false setWebhookUiFlag(("SAE_Webhook"), yCa)
            setWebhookEnabled(yCa)
        end
        )
        _G [("SAE_DashboardEnabled")] = _G [("SAE_DashboardEnabled")] or false
        if getgenv() [("AliceHUB_ApiKey")] == nil then
            getgenv() [("AliceHUB_ApiKey")] = ("")
        end
        local zCa = Oya:Section({Title = ("Dashboard")})
        zCa:Input({Title = ("Dashboard API Key"), Flag = ("AliceHUB_ApiKey"), ID = ("AliceHUB_ApiKey"), Desc = ("Your AliceHUB dashboard key"), Placeholder = ("Paste dashboard key"), Value = tostring(getgenv() [("AliceHUB_ApiKey")] or ("")), Callback = function (ACa)
            getgenv() [("AliceHUB_ApiKey")] = string.gsub(tostring(ACa or ("")), ("%s+"), (""))
            notifyWebhookConfigChanged()
        end
        ,})
        registerWebhookConfigEntry(("AliceHUB_ApiKey"), function ()
            return tostring(getgenv() [("AliceHUB_ApiKey")] or (""))
        end
        , function (BCa)
            getgenv() [("AliceHUB_ApiKey")] = string.gsub(tostring(BCa or ("")), ("%s+"), (""))
            setWebhookUiFlag(("AliceHUB_ApiKey"), getgenv() [("AliceHUB_ApiKey")])
        end
        )
        -- ============================================================
        -- Dashboard presence / remote monitoring
        -- ============================================================
        local function setDashboardEnabled(DCa)
            _G [("SAE_DashboardEnabled")] = (DCa == true)
            if _G [("SAE_DashboardEnabled")] and tostring(getgenv() [("AliceHUB_ApiKey")] or ("")) == ("") then
                pcall(function ()
                    Nya:Notify({Title = ("Dashboard"), Content = ("Set your Dashboard API Key first"), Duration = 5,})
                end
                )
            end
        end
        zCa:Toggle({Title = ("Enable Dashboard"), Desc = ("Send this account's stats to the AliceHUB dashboard"), Flag = ("SAE_DashboardEnabled"), ID = ("SAE_DashboardEnabled"), Value = false, Callback = function (ECa)
            setDashboardEnabled(ECa)
            notifyWebhookConfigChanged()
        end
        ,})
        registerWebhookConfigEntry(("SAE_DashboardEnabled"), function ()
            return _G [("SAE_DashboardEnabled")] == true
        end
        , function (FCa)
            FCa = FCa and true or false setWebhookUiFlag(("SAE_DashboardEnabled"), FCa)
            setDashboardEnabled(FCa)
        end
        )
    end
    )
    runAliceModule("DashboardPresence", function (...)
        local GCa = game:GetService(("Players"))
        local HCa = game:GetService(("HttpService"))
        local ICa = GCa.LocalPlayer
        local JCa = getgenv() [("AliceHUB_BaseURL")]
        local KCa = script_key or _G [("script_key")] or getgenv() [("script_key")]
        local LCa = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if not (JCa and KCa and LCa) then
            warn(("[SAE Presence] BaseURL/key/httpRequest tak tersedia — modul dilewati"))
            return
        end
        getgenv() [("AliceHUB_SAE_PresenceSession")] = (getgenv() [("AliceHUB_SAE_PresenceSession")] or 0) + 1
        local MCa = getgenv() [("AliceHUB_SAE_PresenceSession")]
        local function isPresenceSessionCurrent()
            return getgenv() [("AliceHUB_SAE_PresenceSession")] == MCa
        end
        local function waitPresenceInterval(PCa)
            task.wait(PCa)
            return isPresenceSessionCurrent()
        end
        local QCa = HCa:GenerateGUID(false)
        local RCa = 60
        local SCa, TCa, UCa = false, false, false
        local function getDashboardApiKey()
            return tostring(getgenv() [("AliceHUB_ApiKey")] or (""))
        end
        local function shouldSendDashboardPresence()
            if _G [("SAE_DashboardEnabled")] ~= true then
                return false
            end
            if getDashboardApiKey() == ("") then
                if not SCa then
                    SCa = true warn(("[SAE Presence] Dashboard ON tapi API Key kosong — ") .. ("data terkirim tapi tak akan pernah terlihat (semua ") .. ("pembacaan dashboard memfilter per-apiKey)"))
                end
                return false
            end
            SCa = false
            return true
        end
        local function readStatsForPresence()
            local YCa = getgenv() [("AliceHUB_SAE_ReadStats")]
            if type (YCa) ~= ("function") then
                if not TCa then
                    TCa = true warn(("[SAE Presence] AliceHUB_SAE_ReadStats tak ada — perf.lua tak ") .. ("termuat? Angka dikirim sebagai 0"))
                end
                return nil
            end
            local ZCa, aDa = pcall(YCa)
            if ZCa and type (aDa) == ("table") then
                return aDa
            end
            return nil
        end
        local function readPetsForPresence()
            local cDa = getgenv() [("AliceHUB_SAE_ReadPets")]
            local dDa = {equipped = {}, owned = {}, all = {}, allTruncated = false, limit = 0}
            if type (cDa) ~= ("function") then
                return dDa
            end
            local eDa, fDa = pcall(cDa)
            if eDa and type (fDa) == ("table") then
                return fDa
            end
            return dDa
        end
        local function readPlacedEggsForPresence()
            local hDa = getgenv() [("AliceHUB_SAE_ReadPlacedEggs")]
            if type (hDa) ~= ("function") then
                return {}
            end
            local iDa, jDa = pcall(hDa)
            if iDa and type (jDa) == ("table") then
                return jDa
            end
            return {}
        end
        local function isSuccessfulHttpResponse(lDa)
            local oDa, pDa = pcall(function ()
                if type (lDa) ~= ("table") then
                    return nil
                end
                local mDa = lDa.StatusCode or lDa.Status
                if type (mDa) == ("number") then
                    return mDa >= 200 and mDa < 300
                end
                local nDa = lDa.success
                if nDa == nil then
                    nDa = lDa.Success
                end
                if type (nDa) == ("boolean") then
                    return nDa
                end
                return nil
            end
            )
            if not oDa or pDa == nil then
                return true
            end
            return pDa
        end
        local qDa = 3
        local function sendPresenceUpdate()
            if not shouldSendDashboardPresence() then
                return
            end
            local sDa = readStatsForPresence() or {}
            local tDa = readPetsForPresence()
            local function performPresenceRequest()
                return pcall(function ()
                    return LCa({Url = JCa .. ("/presence"), Method = ("POST"), Headers = {[("Content-Type")] = ("application/json")}, Body = HCa:JSONEncode({key = KCa, apiKey = getDashboardApiKey(), username = ICa.Name, userId = tostring(ICa.UserId), placeId = getgenv() [("AliceHUB_PlaceId")] or tostring(game.PlaceId), session = QCa, saeMoney = tonumber(sDa.money) or 0, saeMps = tonumber(sDa.mps) or 0, saeSpeed = tonumber(sDa.speed) or 0, saeEggs = tonumber(sDa.totalEgg) or 0, saeCollected = tonumber(sDa.collected) or 0, saePetLimit = tonumber(tDa.limit) or 0, pets = tDa.equipped, invPets = tDa.owned, petsAll = tDa.all, petsAllTruncated = tDa.allTruncated == true, placedEggs = readPlacedEggsForPresence(),}),})
                end
                )
            end
            local vDa, wDa = performPresenceRequest()
            if not (vDa and isSuccessfulHttpResponse(wDa)) then
                task.wait(qDa)
                if isPresenceSessionCurrent() then
                    vDa, wDa = performPresenceRequest()
                end
            end
            if vDa and isSuccessfulHttpResponse(wDa) then
                UCa = false
            elseif not UCa then
                UCa = true warn(("[SAE Presence] Gagal mengirim presence — httpRequest melempar ") .. ("error atau server menolak (cek koneksi / kompatibilitas ") .. ("executor / status API key)"))
            end
        end
        local xDa = 300
        local yDa = nil
        local zDa, ADa = false, false
        local function sendEggInventoryUpdate()
            if not shouldSendDashboardPresence() then
                return
            end
            local CDa = getgenv() [("AliceHUB_SAE_ReadEggs")]
            if type (CDa) ~= ("function") then
                if not zDa then
                    zDa = true warn(("[SAE Presence] AliceHUB_SAE_ReadEggs tak ada — egghatch.lua ") .. ("tak termuat? Backpack tak pernah terkirim"))
                end
                return
            end
            local DDa, EDa = pcall(CDa)
            if not DDa or type (EDa) ~= ("table") then
                return
            end
            local FDa, GDa = pcall(function ()
                return HCa:JSONEncode({key = KCa, apiKey = getDashboardApiKey(), username = ICa.Name, userId = tostring(ICa.UserId), placeId = getgenv() [("AliceHUB_PlaceId")] or tostring(game.PlaceId), gameName = ("Steal An Egg"), items = EDa,})
            end
            )
            if not FDa or type (GDa) ~= ("string") then
                return
            end
            if GDa == yDa then
                return
            end
            local HDa, IDa = pcall(function ()
                return LCa({Url = JCa .. ("/backpack"), Method = ("POST"), Headers = {[("Content-Type")] = ("application/json")}, Body = GDa,})
            end
            )
            if HDa and isSuccessfulHttpResponse(IDa) then
                yDa = GDa
                ADa = false
            elseif not ADa then
                ADa = true warn(("[SAE Presence] Gagal mengirim backpack — httpRequest melempar ") .. ("error atau server menolak (cek koneksi / status API key)"))
            end
        end
        local JDa = nil
        local function sendConfigPresenceUpdate()
            if not shouldSendDashboardPresence() then
                return
            end
            local LDa = getgenv() [("AliceHUB_SAE_Config")]
            if type (LDa) ~= ("table") or type (LDa._entries) ~= ("table") then
                return
            end
            local MDa, NDa = {}, 0
            for ODa, PDa in ipairs(LDa._entries) do
                if type (PDa) == ("table") and type (PDa.key) == ("string") and type (PDa.get) == ("function") then
                    local QDa, RDa = pcall(PDa.get)
                    if QDa then
                        local SDa = type (RDa)
                        local TDa = (SDa == ("boolean") and ("bool")) or (SDa == ("number") and ("number")) or (SDa == ("string") and ("string")) or (SDa == ("table") and ("list")) or nil
                        if TDa then
                            MDa [PDa.key] = TDa;
                            NDa = NDa + 1
                        end
                    end
                end
            end
            if NDa == 0 then
                return
            end
            local UDa = {}
            for VDa, WDa in pairs(MDa) do
                UDa [#UDa + 1] = VDa .. (":") .. WDa
            end
            table.sort(UDa)
            local XDa = table.concat(UDa, ("|"))
            if XDa == JDa then
                return
            end
            local YDa, ZDa = pcall(function ()
                return LCa({Url = JCa .. ("/api/script-config/catalog"), Method = ("POST"), Headers = {[("Content-Type")] = ("application/json")}, Body = HCa:JSONEncode({key = KCa, placeId = getgenv() [("AliceHUB_PlaceId")] or tostring(game.PlaceId), entries = MDa,}),})
            end
            )
            if YDa and isSuccessfulHttpResponse(ZDa) then
                JDa = XDa
            end
        end
        local aEa = 0.2
        local function getAssetServiceForIconRender()
            local cEa, dEa = pcall(function ()
                return game:GetService(("AssetService"))
            end
            )
            if not cEa or not dEa then
                return nil
            end
            if type (dEa.CreateEditableImageAsync) ~= ("function") then
                return nil
            end
            return dEa
        end
        local eEa = nil
        local fEa = false
        local function getBase64Encoder()
            if fEa then
                return eEa
            end
            fEa = true
            local hEa, iEa = pcall(function ()
                return game:GetService(("EncodingService"))
            end
            )
            if hEa and iEa and type (iEa.Base64Encode) == ("function") then
                eEa = function (jEa)
                    local kEa, lEa = pcall(function ()
                        return iEa:Base64Encode(jEa)
                    end
                    )
                    if not kEa or not lEa then
                        return nil
                    end
                    local mEa, nEa = pcall(function ()
                        return buffer.tostring(lEa)
                    end
                    )
                    if not mEa then
                        return nil
                    end
                    return nEa
                end
            end
            return eEa
        end
        local oEa = 256
        local function renderAssetToPixelPayload(qEa, rEa)
            local sEa, tEa = pcall(function ()
                return Content.fromUri(("rbxassetid://") .. rEa)
            end
            )
            if not sEa then
                tEa = ("rbxassetid://") .. rEa
            end
            local uEa, vEa = pcall(function ()
                return qEa:CreateEditableImageAsync(tEa)
            end
            )
            if not uEa or not vEa then
                return nil
            end
            local wEa, xEa = pcall(function ()
                return vEa.Size
            end
            )
            if not wEa or not xEa or xEa.X <= 0 or xEa.Y <= 0 then
                pcall(function ()
                    vEa:Destroy()
                end
                )
                return nil
            end
            local yEa, zEa = vEa, vEa
            local AEa = xEa
            local BEa = math.max(xEa.X, xEa.Y)
            if BEa > oEa then
                local CEa = oEa / BEa
                local DEa = Vector2.new(math.max(1, math.floor(xEa.X * CEa)), math.max(1, math.floor(xEa.Y * CEa)))
                local EEa, FEa = pcall(function ()
                    return qEa:CreateEditableImage({Size = DEa})
                end
                )
                if EEa and FEa then
                    local GEa = pcall(function ()
                        FEa:DrawImageTransformed(Vector2.new(DEa.X / 2, DEa.Y / 2), Vector2.new(CEa, CEa), 0, yEa)
                    end
                    )
                    if GEa then
                        zEa, AEa = FEa, DEa
                    else
                        pcall(function ()
                            FEa:Destroy()
                        end
                        )
                    end
                end
            end
            local HEa, IEa = pcall(function ()
                return zEa:ReadPixelsBuffer(Vector2.new(0, 0), AEa)
            end
            )
            pcall(function ()
                vEa:Destroy()
            end
            )
            if zEa ~= vEa then
                pcall(function ()
                    zEa:Destroy()
                end
                )
            end
            if not HEa or not IEa then
                return nil
            end
            local JEa = getBase64Encoder()
            if not JEa then
                return nil
            end
            local KEa, LEa = pcall(function ()
                return JEa(IEa)
            end
            )
            if not KEa or type (LEa) ~= ("string") then
                return nil
            end
            return {w = AEa.X, h = AEa.Y, pixels = LEa}
        end
        local function uploadRenderedIcon(NEa, OEa, PEa)
            return pcall(function ()
                return LCa({Url = JCa .. ("/api/icon-render"), Method = ("POST"), Headers = {[("Content-Type")] = ("application/json")}, Body = HCa:JSONEncode({placeId = NEa, assetId = OEa, w = PEa.w, h = PEa.h, pixels = PEa.pixels,}),})
            end
            )
        end
        local function uploadAssetIcons()
            if not shouldSendDashboardPresence() then
                return
            end
            local REa = getgenv() [("AliceHUB_SAE_ReadAssetIcons")]
            if type (REa) ~= ("function") then
                return
            end
            local SEa = getAssetServiceForIconRender()
            if not SEa then
                return
            end
            local TEa = getgenv() [("AliceHUB_PlaceId")] or tostring(game.PlaceId)
            local UEa, VEa = pcall(function ()
                return LCa({Url = JCa .. ("/api/icon-render-status/") .. TEa, Method = ("GET")})
            end
            )
            if not UEa or not VEa then
                return
            end
            local WEa, XEa = pcall(function ()
                return HCa:JSONDecode(VEa.Body or VEa.body or ("{}"))
            end
            )
            if not WEa or type (XEa) ~= ("table") then
                return
            end
            local YEa = {}
            for ZEa, aFa in ipairs(XEa.rendered or {}) do
                YEa [tostring(aFa)] = true
            end
            local bFa, cFa = pcall(REa)
            if not bFa or type (cFa) ~= ("table") then
                return
            end
            local dFa, eFa = {}, {}
            for fFa, gFa in ipairs(cFa) do
                local hFa = tostring(gFa.assetId or (""))
                if hFa ~= ("") and not YEa [hFa] and not dFa [hFa] then
                    dFa [hFa] = true eFa [#eFa + 1] = hFa
                end
            end
            if #eFa == 0 then
                return
            end
            for iFa = 1, #eFa do
                if not isPresenceSessionCurrent() then
                    return
                end
                local jFa = eFa [iFa]
                local kFa = renderAssetToPixelPayload(SEa, jFa)
                if kFa then
                    uploadRenderedIcon(TEa, jFa, kFa)
                end
                task.wait(aEa)
            end
        end
        task.spawn(function ()
            if not waitPresenceInterval(30) then
                return
            end
            pcall(uploadAssetIcons)
        end
        )
        task.spawn(function ()
            if not waitPresenceInterval(20) then
                return
            end
            while isPresenceSessionCurrent() do
                sendEggInventoryUpdate()
                if not waitPresenceInterval(xDa) then
                    return
                end
            end
        end
        )
        task.spawn(function ()
            if not waitPresenceInterval(10) then
                return
            end
            while isPresenceSessionCurrent() do
                sendPresenceUpdate()
                sendConfigPresenceUpdate()
                if not waitPresenceInterval(RCa) then
                    return
                end
            end
        end
        )
    end
    )
    runAliceModule("ConfigManager", function (...)
        local lFa = getgenv() [("AliceHUB_WindUI")]
        local nFa = getgenv() [("AliceHUB_TabSettings")]
        local oFa = game:GetService(("HttpService"))
        if not nFa then
            return
        end
        local pFa = ("AliceHUB/sae_config.json")
        local qFa = getgenv() [("AliceHUB_SAE_Config")]
        if not qFa then
            qFa = {_entries = {}, _byKey = {}}
            getgenv() [("AliceHUB_SAE_Config")] = qFa
        end
        getgenv() [("AliceHUB_SAE_RegisterConfig")] = function (rFa, sFa, tFa)
            if type (rFa) ~= ("string") or type (sFa) ~= ("function") or type (tFa) ~= ("function") then
                return
            end
            if qFa._byKey [rFa] then
                qFa._byKey [rFa].get = sFa
                qFa._byKey [rFa].set = tFa
                return
            end
            local uFa = {key = rFa, get = sFa, set = tFa}
            qFa._entries [#qFa._entries + 1] = uFa
            qFa._byKey [rFa] = uFa
        end
        -- ============================================================
        -- Config save / import / export
        -- ============================================================
        local function ensureAliceHUBFolder()
            pcall(function ()
                if isfolder and not isfolder(("AliceHUB")) then
                    makefolder(("AliceHUB"))
                end
            end
            )
        end
        local function serializeCurrentConfig()
            local xFa = {}
            for yFa, zFa in ipairs(qFa._entries) do
                local AFa, BFa = pcall(zFa.get)
                if AFa then
                    xFa [zFa.key] = BFa
                end
            end
            local CFa, DFa = pcall(function ()
                return oFa:JSONEncode(xFa)
            end
            )
            return CFa and DFa or nil
        end
        local function saveConfigToFile()
            if not (writefile and isfolder) then
                return false
            end
            ensureAliceHUBFolder()
            local FFa = serializeCurrentConfig()
            if not FFa then
                return false
            end
            return (pcall(writefile, pFa, FFa))
        end
        local function deleteConfigFile()
            local HFa = false
            if isfile then
                pcall(function ()
                    HFa = isfile(pFa)
                end
                )
            end
            if delfile and pcall(delfile, pFa) then
                return HFa
            end
            if writefile and pcall(writefile, pFa, ("")) then
                return HFa
            end
            return false
        end
        local IFa = false
        local JFa = false getgenv() [("AliceHUB_SAE_ConfigChanged")] = function ()
            if JFa then
                return
            end
            if IFa then
                return
            end
            IFa = true task.spawn(function ()
                task.wait(0.5)
                IFa = false
                if JFa then
                    return
                end
                saveConfigToFile()
            end
            )
        end
        local function loadConfigFromFile()
            if not (isfile and readfile) then
                return nil
            end
            local LFa, MFa = pcall(isfile, pFa)
            if not LFa or not MFa then
                return nil
            end
            local NFa, OFa = pcall(readfile, pFa)
            if not NFa or not OFa or OFa == ("") then
                return nil
            end
            local PFa, QFa = pcall(function ()
                return oFa:JSONDecode(OFa)
            end
            )
            return PFa and type (QFa) == ("table") and QFa or nil
        end
        local function applyConfigTable(SFa)
            if type (SFa) ~= ("table") then
                return 0
            end
            local workerKeys = {
                SAE_FarmEgg = true, SAE_AAFarmEgg = true, SAE_StealParasite = true, SAE_TakeRiftEgg = true, SAE_CompleteIndex = true,
                SAE_AutoTreadmill = true, SAE_AutoUpgradeTreadmill = true, SAE_AutoSell = true, SAE_SellByValue = true,
                SAE_AutoFav = true, SAE_AutoUnfav = true, SAE_FuseAll = true, SAE_FuseByRarity = true,
                SAE_AutoUpgradePen = true, SAE_AutoUpgradeTrail = true, SAE_AutoIndexClaim = true,
                SAE_AutoPlaceHatch = true, SAE_AlwaysBest = true, SAE_EspEgg = true,
                SAE_RiftAutoFuse = true, SAE_RiftAutoReroll = true, SAE_BossAutoClaim = true, SAE_BossAutoShop = true,
                SAE_Noclip = true, SAE_AntiHit = true, SAE_BoostFPS = true, SAE_DestroyUI = true, SAE_UltraPerf = true,
                SAE_HideOtherPet = true, SAE_WhiteScreen = true, SAE_Webhook = true, SAE_DashboardEnabled = true,
            }
            local TFa = 0
            local function applyPhase(deferredWorkers)
                for _, entry in ipairs(qFa._entries) do
                    if SFa [entry.key] ~= nil and (workerKeys [entry.key] == true) == deferredWorkers then
                        local ok = pcall(entry.set, SFa [entry.key])
                        if ok then TFa = TFa + 1 end
                    end
                end
            end
            applyPhase(false)
            task.wait()
            applyPhase(true)
            return TFa
        end
        local function getImportedConfig()
            local YFa = getgenv() [("AliceHUB_ImportConfig")]
            if YFa == nil then
                YFa = getgenv() [("AliceHUB_SAE_ImportConfig")]
            end
            if YFa == nil then
                return nil
            end
            if type (YFa) == ("table") then
                return YFa
            end
            if type (YFa) == ("string") and YFa ~= ("") then
                local ZFa, aGa = pcall(function ()
                    return oFa:JSONDecode(YFa)
                end
                )
                if ZFa and type (aGa) == ("table") then
                    return aGa
                end
            end
            return nil
        end
        local function mergeConfigTables(cGa, dGa)
            local eGa = {}
            if type (cGa) == ("table") then
                for fGa, gGa in pairs(cGa) do
                    eGa [fGa] = gGa
                end
            end
            if type (dGa) == ("table") then
                for hGa, iGa in pairs(dGa) do
                    eGa [hGa] = iGa
                end
            end
            return eGa
        end
        local function resolveDashboardConfig(kGa)
            local lGa = tostring(getgenv() [("AliceHUB_ApiKey")] or (""))
            if lGa == ("") and type (kGa) == ("table") then
                lGa = tostring(kGa.AliceHUB_ApiKey or (""))
            end
            local mGa = (_G [("SAE_DashboardEnabled")] == true) or (type (kGa) == ("table") and kGa.SAE_DashboardEnabled == true)
            if not mGa then
                return nil
            end
            if lGa == ("") then
                warn(("[AliceHUB] Script Manager dilewati: Dashboard API Key kosong"))
                return nil
            end
            local nGa = getgenv() [("AliceHUB_BaseURL")]
            local oGa = script_key or _G [("script_key")] or getgenv() [("script_key")]
            local pGa = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
            if not (nGa and oGa and type (pGa) == ("function")) then
                warn(("[AliceHUB] Script Manager dilewati: BaseURL/key/httpRequest tak tersedia"))
                return nil
            end
            local qGa, rGa = pcall(function ()
                return pGa({Url = nGa .. ("/api/script-config/fetch"), Method = ("POST"), Headers = {[("Content-Type")] = ("application/json")}, Body = oFa:JSONEncode({key = oGa, apiKey = lGa, username = game:GetService(("Players")).LocalPlayer.Name,}),})
            end
            )
            if not qGa or type (rGa) ~= ("table") then
                warn(("[AliceHUB] Script Manager: request gagal terkirim"))
                return nil
            end
            local sGa = rGa.Body or rGa.body
            if type (sGa) ~= ("string") or sGa == ("") then
                warn(("[AliceHUB] Script Manager: respons kosong (HTTP ") .. tostring(rGa.StatusCode or rGa.status_code) .. (")"))
                return nil
            end
            local tGa, uGa = pcall(function ()
                return oFa:JSONDecode(sGa)
            end
            )
            if not tGa or type (uGa) ~= ("table") or uGa.ok ~= true then
                warn(("[AliceHUB] Script Manager: respons ditolak — ") .. tostring(sGa):sub(1, 120))
                return nil
            end
            return uGa
        end
        local vGa = loadConfigFromFile()
        local wGa = getImportedConfig()
        local xGa = vGa
        if wGa then
            xGa = mergeConfigTables(vGa, wGa)
        end
        task.spawn(function ()
            task.wait(0.5)
            local yGa = resolveDashboardConfig(vGa)
            if yGa and yGa.remove == true then
                local zGa = tostring(getgenv() [("AliceHUB_ApiKey")] or (""))
                if zGa == ("") and type (vGa) == ("table") then
                    zGa = tostring(vGa.AliceHUB_ApiKey or (""))
                end
                JFa = true deleteConfigFile()
                getgenv() [("AliceHUB_ApiKey")] = zGa
                xGa = {SAE_DashboardEnabled = true, AliceHUB_ApiKey = zGa}
                pcall(function ()
                    writefile(pFa, oFa:JSONEncode(xGa))
                end
                )
                task.delay(0.6, function ()
                    JFa = false
                end
                )
                lFa:Notify({Title = ("Config"), Content = ("Config removed from dashboard"), Duration = 4})
            elseif yGa and type (yGa.config) == ("table") then
                yGa.config.SAE_DashboardEnabled = nil
                local AGa, BGa = {}, 0
                for CGa, DGa in pairs(yGa.config) do
                    if qFa._byKey [CGa] then
                        AGa [CGa] = DGa
                    else
                        BGa = BGa + 1
                    end
                end
                yGa.config = AGa
                if BGa > 0 then
                    print((("[AliceHUB] Script Manager: %d key bukan milik game ini diabaikan")):format(BGa))
                end
            end
            if yGa and type (yGa.config) == ("table") and next(yGa.config) == nil then
                yGa = nil
            end
            if yGa and type (yGa.config) == ("table") then
                xGa = mergeConfigTables(vGa, yGa.config)
                pcall(function ()
                    writefile(pFa, oFa:JSONEncode(xGa))
                end
                )
            end
            if xGa then
                local EGa = applyConfigTable(xGa)
                if EGa > 0 then
                    if yGa and type (yGa.config) == ("table") then
                        lFa:Notify({Title = ("Config"), Content = ("✅ Loaded config from dashboard (") .. EGa .. (" settings)"), Duration = 4,})
                    elseif wGa then
                        local FGa = 0
                        for GGa in pairs(wGa) do
                            FGa = FGa + 1
                        end
                        lFa:Notify({Title = ("Config"), Content = ("✅ Loaded (") .. EGa .. (") + ImportConfig overwrite (") .. FGa .. (" keys, this session only)"), Duration = 4,})
                    else
                        lFa:Notify({Title = ("Config"), Content = ("✅ Loaded config (") .. EGa .. (" settings)"), Duration = 3})
                    end
                end
            end
        end
        )
        local HGa = nFa:Section({Title = ("Settings"), Open = true})
        HGa:Button({Title = ("Stop and Reset"), Desc = ("Stop every AliceHUB action, clear filters/state, and DELETE the saved config file"), Callback = function ()
            JFa = true
            local cfg = getgenv() [("AliceHUB_SAE_Config")]
            if cfg and type (cfg._entries) == ("table") then
                for _, entry in ipairs(cfg._entries) do
                    if type (entry) == ("table") and type (entry.get) == ("function") and type (entry.set) == ("function") then
                        local ok, current = pcall(entry.get)
                        if ok and type (current) == ("boolean") then
                            pcall(entry.set, false)
                        end
                    end
                end
            end
            for _, key in ipairs({("SAE_RarityFilter"), ("SAE_PlaceRarity"), ("SAE_SellRarity"), ("SAE_FuseRarity"), ("SAE_WLPick"), ("SAE_WebhookType"), ("SAE_WebhookRarity"), ("SAE_BossShopItems")}) do
                _G [key] = {}
                local entry = cfg and cfg._byKey and cfg._byKey [key]
                if entry and type (entry.set) == ("function") then pcall(entry.set, {}) end
            end
            _G [("SAE_StealValueMinM")] = nil
            _G [("SAE_SellValueMaxM")] = nil
            for key, value in pairs({SAE_StealValueText = ("0"), SAE_SellValueText = (""), SAE_TweenSpeed = 300}) do
                local entry = cfg and cfg._byKey and cfg._byKey [key]
                if entry and type (entry.set) == ("function") then pcall(entry.set, value) end
            end
            getgenv() [("AliceHUB_SAE_FarmEggBusy")] = false
            getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] = false
            getgenv() [("AliceHUB_SAE_EquipBestBusy")] = false
            getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] = false
            getgenv() [("AliceHUB_SAE_EggPipelineHoldUntil")] = 0
            getgenv() [("AliceHUB_SAE_PlaceHatchActiveUntil")] = 0
            getgenv() [("AliceHUB_SAE_EquipBestActiveUntil")] = 0
            pcall(function ()
                local turn = getgenv() [("AliceHUB_SAE_Turn")]
                local state = turn and type (turn.state) == ("function") and turn.state() or nil
                if type (state) == ("table") then
                    state.holder, state.token, state.took, state.alive = nil, nil, 0, 0
                    state.queue, state.sejak = {}, {}
                end
            end)
            pcall(function ()
                local stopTreadmill = getgenv() [("AliceHUB_SAE_SetTreadmill")]
                if type (stopTreadmill) == ("function") then stopTreadmill(false) end
            end)
            local YGa = deleteConfigFile()
            task.delay(0.6, function () JFa = false end)
            lFa:Notify({Title = ("Stop and Reset"), Content = YGa and ("🛑 All actions stopped, runtime state cleared, config deleted.") or ("🛑 All actions stopped and runtime state cleared."), Duration = 4,})
        end
        ,})
        HGa:Button({Title = ("Save Config"), Desc = ("Manually save current settings to file"), Callback = function ()
            local ZGa = saveConfigToFile()
            lFa:Notify({Title = ("Config"), Content = ZGa and ("💾 Saved to AliceHUB/sae_config.json") or ("❌ Save failed (executor fs?)"), Duration = 3,})
        end
        ,})
        HGa:Button({Title = ("Load Config"), Desc = ("Reload settings from file & apply"), Callback = function ()
            local aHa = loadConfigFromFile()
            if not aHa then
                lFa:Notify({Title = ("Config"), Content = ("⚠️ No config file found"), Duration = 4})
                return
            end
            local bHa = applyConfigTable(aHa)
            lFa:Notify({Title = ("Config"), Content = ("✅ Loaded (") .. bHa .. (" settings)"), Duration = 3})
        end
        ,})
        HGa:Input({Title = ("Import Config (paste JSON)"), Placeholder = ("{\"SAE_FarmEgg\":true}"), Value = (""), Callback = function (cHa)
            cHa = tostring(cHa or (""))
            if cHa == ("") then
                return
            end
            local dHa, eHa = pcall(function ()
                return oFa:JSONDecode(cHa)
            end
            )
            if not dHa or type (eHa) ~= ("table") then
                lFa:Notify({Title = ("Config"), Content = ("❌ Invalid JSON"), Duration = 4})
                return
            end
            local fHa = applyConfigTable(eHa)
            ensureAliceHUBFolder()
            pcall(writefile, pFa, cHa)
            lFa:Notify({Title = ("Config"), Content = ("✅ Imported & saved (") .. fHa .. (" settings)"), Duration = 3})
        end
        ,})
        HGa:Button({Title = ("Copy Config (to clipboard)"), Callback = function ()
            local gHa = serializeCurrentConfig()
            local hHa = setclipboard or toclipboard or (syn and syn.write_clipboard)
            if gHa and hHa and pcall(hHa, gHa) then
                lFa:Notify({Title = ("Config"), Content = ("📋 Config copied to clipboard"), Duration = 3})
            else
                lFa:Notify({Title = ("Config"), Content = ("❌ Copy failed"), Duration = 4})
            end
        end
        ,})
    end
    )
    getgenv() [("AliceHUB_SAE_Cleanup")] = function ()
        local cfg = getgenv() [("AliceHUB_SAE_Config")]
        if cfg and type (cfg._entries) == ("table") then
            for _, entry in ipairs(cfg._entries) do
                if type (entry) == ("table") and type (entry.get) == ("function") and type (entry.set) == ("function") then
                    local ok, value = pcall(entry.get)
                    if ok and type (value) == ("boolean") and value == true then
                        pcall(entry.set, false)
                    end
                end
            end
        end
        for _, flag in ipairs({("SAE_FarmEgg"), ("SAE_AAFarmEgg"), ("SAE_StealParasite"), ("SAE_TakeRiftEgg"), ("SAE_CompleteIndex"), ("SAE_AutoTreadmill"), ("SAE_AutoSell"), ("SAE_SellByValue"), ("SAE_FuseAll"), ("SAE_FuseByRarity"), ("SAE_AutoPlaceHatch"), ("SAE_AlwaysBest"), ("SAE_RiftAutoFuse"), ("SAE_RiftAutoReroll"), ("SAE_BossAutoClaim"), ("SAE_BossAutoShop"), ("SAE_Noclip"), ("SAE_AntiHit"), ("SAE_WhiteScreen"), ("SAE_Webhook"), ("SAE_DashboardEnabled")}) do
            _G [flag] = false
        end
        getgenv() [("AliceHUB_SAE_FarmEggBusy")] = false
        getgenv() [("AliceHUB_SAE_PlaceHatchBusy")] = false
        getgenv() [("AliceHUB_SAE_EquipBestBusy")] = false
        getgenv() [("AliceHUB_SAE_TreadmillSuppressed")] = false
        getgenv() [("AliceHUB_SAE_EggPipelineHoldUntil")] = 0
        pcall(function ()
            local turn = getgenv() [("AliceHUB_SAE_Turn")]
            local state = turn and type (turn.state) == ("function") and turn.state() or nil
            if type (state) == ("table") then
                state.holder, state.token = nil, nil
                state.queue, state.sejak = {}, {}
            end
        end)
        pcall(function ()
            for _, root in ipairs({game:GetService(("CoreGui")), game:GetService(("Players")).LocalPlayer:FindFirstChildOfClass(("PlayerGui"))}) do
                local gui = root and root:FindFirstChild(("AliceHUB_SAE_WhiteScreen"))
                if gui then gui:Destroy() end
                local logoGui = root and root:FindFirstChild(("AliceHUBLogoButton"))
                if logoGui then logoGui:Destroy() end
            end
        end)
    end
end
-- ============================================================
-- AliceHUB Direct Loader v3 startup
-- Server-side /s -> /l authorization already completed before payload execution.
-- Keep payload startup local so executor HTTP implementations cannot stall the UI.
-- ============================================================
do
    local __uiOk, __uiErr = pcall(function()
        UIAdapter.Init(AliceUI)
    end)

    if not __uiOk then
        warn("[AliceHUB/SAE] UI init error: " .. tostring(__uiErr))
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "AliceHUB",
                Text = "SAE UI init error: " .. tostring(__uiErr),
                Duration = 8,
            })
        end)
    end
end

-- =====================================================================
-- AliceHUB SAE · 2026-09-07 latest dump additions
-- Compact integration: no extra top-level tabs. New surfaces are folded
-- into Machine / Upgrade / Events / Movement to keep the preferred UI.
-- =====================================================================
task.defer(function()
    task.wait(1.0)

    local G = getgenv()
    if G.AliceHUB_SAE_LatestDumpAddonLoaded then return end
    G.AliceHUB_SAE_LatestDumpAddonLoaded = true

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer

    local okRemotes, Remotes = pcall(function()
        return require(ReplicatedStorage.Shared.Remotes)
    end)
    if not okRemotes or type(Remotes) ~= "table" then
        warn("[AliceHUB/LatestDump] Shared.Remotes unavailable: " .. tostring(Remotes))
        return
    end

    local function notify(title, body, duration)
        local ui = G.AliceHUB_WindUI
        if ui and type(ui.Notify) == "function" then
            pcall(function()
                ui:Notify({Title = title or "AliceHUB", Content = tostring(body or ""), Body = tostring(body or ""), Duration = duration or 5})
            end)
            return
        end
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title or "AliceHUB",
                Text = tostring(body or ""),
                Duration = duration or 5,
            })
        end)
    end

    local function callRemote(remote, ...)
        if typeof(remote) ~= "Instance" then return false, "remote missing" end
        local args = table.pack(...)
        local ok, result = pcall(function()
            if remote:IsA("RemoteFunction") then
                return remote:InvokeServer(table.unpack(args, 1, args.n))
            elseif remote:IsA("RemoteEvent") then
                remote:FireServer(table.unpack(args, 1, args.n))
                return true
            end
            return nil
        end)
        return ok, result
    end

    local function jsonShort(value)
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, value)
        if ok then return tostring(encoded):sub(1, 360) end
        return tostring(value)
    end

    local function configEntry(key, getter, setter)
        local cfg = G.AliceHUB_SAE_Config
        if type(cfg) ~= "table" then
            cfg = {_entries = {}, _byKey = {}}
            G.AliceHUB_SAE_Config = cfg
        end
        cfg._entries = cfg._entries or {}
        cfg._byKey = cfg._byKey or {}
        if cfg._byKey[key] then
            cfg._byKey[key].get = getter
            cfg._byKey[key].set = setter
        else
            local entry = {key = key, get = getter, set = setter}
            cfg._entries[#cfg._entries + 1] = entry
            cfg._byKey[key] = entry
        end
    end

    local function configChanged()
        local fn = G.AliceHUB_SAE_ConfigChanged
        if type(fn) == "function" then pcall(fn) end
    end

    local function setFlag(key, value)
        _G[key] = value
        local flags = G.AliceHUB_Flags
        local flag = flags and flags[key]
        if flag and type(flag.SetAndFire) == "function" then
            pcall(flag.SetAndFire, flag, value)
        end
    end

    -- -------------------------------------------------------------
    -- MACHINE · Sakura / Bloomery (new client dump surface)
    -- -------------------------------------------------------------
    local machineTab = G.AliceHUB_TabMachine
    if machineTab and Remotes.Bloomery then
        local sec = machineTab:Section({Title = "Sakura / Bloomery"})
        local eggUid = ""
        sec:Input({
            Title = "Egg UID",
            Desc = "UID egg for Bloomery/Sakura machine",
            Flag = "SAE_BloomeryEggUid",
            Placeholder = "egg uid",
            Value = "",
            Callback = function(v) eggUid = tostring(v or "") end,
        })
        sec:Button({Title = "Confirm Briefing", Callback = function()
            local ok, r = callRemote(Remotes.Bloomery.AskBriefingConfirm)
            notify("Bloomery", ok and "Briefing confirmed" or tostring(r), 4)
        end})
        sec:Button({Title = "Load Egg", Desc = "Insert the UID above into Bloomery", Callback = function()
            if eggUid == "" then notify("Bloomery", "Fill Egg UID first", 4); return end
            local ok, r = callRemote(Remotes.Bloomery.AskLoadEgg, eggUid)
            notify("Bloomery", ok and "Load Egg request sent" or tostring(r), 4)
        end})
        sec:Button({Title = "Handoff / Start", Callback = function()
            local ok, r = callRemote(Remotes.Bloomery.AskHandoff)
            notify("Bloomery", ok and "Handoff request sent" or tostring(r), 4)
        end})
        sec:Button({Title = "Mutate", Callback = function()
            local ok, r = callRemote(Remotes.Bloomery.AskMutate)
            notify("Bloomery", ok and "Mutate request sent" or tostring(r), 4)
        end})
        sec:Button({Title = "Gather Petal", Callback = function()
            local ok, r = callRemote(Remotes.Bloomery.AskGatherPetal)
            notify("Bloomery", ok and "Gather Petal request sent" or tostring(r), 4)
        end})
        sec:Button({Title = "Crane Return", Callback = function()
            local ok, r = callRemote(Remotes.Bloomery.AskCraneReturn)
            notify("Bloomery", ok and "Crane returned" or tostring(r), 4)
        end})
        sec:Button({Title = "Eject Egg", Callback = function()
            local ok, r = callRemote(Remotes.Bloomery.AskEjectEgg)
            notify("Bloomery", ok and "Eject request sent" or tostring(r), 4)
        end})
    end

    -- -------------------------------------------------------------
    -- UPGRADE · Rewards / latest claim surfaces
    -- -------------------------------------------------------------
    local upgradeTab = G.AliceHUB_TabUpgrade
    if upgradeTab then
        local rewards = upgradeTab:Section({Title = "Rewards"})
        _G.SAE_AutoOfflineEarnings = _G.SAE_AutoOfflineEarnings or false
        _G.SAE_AutoGroupPerk = _G.SAE_AutoGroupPerk or false

        local function claimOffline(silent)
            if not Remotes.AwayEarnings then return false end
            local okSummary, summary = callRemote(Remotes.AwayEarnings.FetchSummary)
            if not okSummary or type(summary) ~= "table" then
                if not silent then notify("Offline Earnings", "Summary unavailable", 4) end
                return false
            end
            local amount = tonumber(summary.ClaimableAmount) or 0
            if amount <= 0 then
                if not silent then notify("Offline Earnings", "Nothing claimable", 4) end
                return false
            end
            local ok, r = callRemote(Remotes.AwayEarnings.AskCollect)
            if not silent then notify("Offline Earnings", ok and ("Claim request sent · " .. tostring(amount)) or tostring(r), 5) end
            return ok
        end

        rewards:Toggle({
            Title = "Auto Claim Offline Earnings",
            Desc = "Checks the latest AwayEarnings summary every 15 seconds",
            Flag = "SAE_AutoOfflineEarnings",
            Value = _G.SAE_AutoOfflineEarnings,
            Callback = function(v) _G.SAE_AutoOfflineEarnings = v and true or false; configChanged() end,
        })
        rewards:Button({Title = "Claim Offline Earnings Now", Callback = function() claimOffline(false) end})
        configEntry("SAE_AutoOfflineEarnings", function() return _G.SAE_AutoOfflineEarnings end, function(v) setFlag("SAE_AutoOfflineEarnings", v and true or false) end)

        if Remotes.Codex then
            rewards:Button({Title = "Claim All Index Rewards", Callback = function()
                local ok, r = callRemote(Remotes.Codex.AskRedeemAll)
                notify("Index", ok and "Claim All request sent" or tostring(r), 4)
            end})
            rewards:Button({Title = "Claim Limited Egg", Desc = "Latest Codex limited-egg reward remote", Callback = function()
                local ok, r = callRemote(Remotes.Codex.AskRedeemLimitedEgg)
                notify("Index", ok and "Limited Egg request sent" or tostring(r), 5)
            end})
        end

        local constants
        pcall(function() constants = require(ReplicatedStorage.Shared.Globals.Constants) end)
        local function claimGroup(silent)
            if not Remotes.GroupPerk or not Remotes.GroupPerk.RedeemPerk then return false end
            local inGroup = false
            if constants and constants.GROUP_ID then
                pcall(function() inGroup = LocalPlayer:IsInGroupAsync(constants.GROUP_ID) == true end)
            end
            local ok, r = callRemote(Remotes.GroupPerk.RedeemPerk, inGroup)
            if not silent then notify("Group Reward", ok and "Group reward request sent" or tostring(r), 5) end
            return ok
        end
        rewards:Toggle({
            Title = "Auto Claim Group Reward",
            Flag = "SAE_AutoGroupPerk",
            Value = _G.SAE_AutoGroupPerk,
            Callback = function(v) _G.SAE_AutoGroupPerk = v and true or false; configChanged() end,
        })
        rewards:Button({Title = "Claim Group Reward Now", Callback = function() claimGroup(false) end})
        configEntry("SAE_AutoGroupPerk", function() return _G.SAE_AutoGroupPerk end, function(v) setFlag("SAE_AutoGroupPerk", v and true or false) end)

        task.spawn(function()
            while G.AliceHUB_SAE_LatestDumpAddonLoaded do
                task.wait(15)
                if _G.SAE_AutoOfflineEarnings then pcall(claimOffline, true) end
            end
        end)
        task.spawn(function()
            while G.AliceHUB_SAE_LatestDumpAddonLoaded do
                task.wait(20)
                if _G.SAE_AutoGroupPerk then pcall(claimGroup, true) end
            end
        end)

        if Remotes.Haul then
            local backpack = upgradeTab:Section({Title = "Backpack / Native Tools"})
            backpack:Button({Title = "Equip Best Pets", Callback = function()
                local ok, r = callRemote(Remotes.Haul.WearBest)
                notify("Pets", ok and "Equip Best request sent" or tostring(r), 4)
            end})
            backpack:Button({Title = "Wear Best Status", Callback = function()
                local ok, r = callRemote(Remotes.Haul.FetchWearBestStatus)
                notify("Pets", ok and jsonShort(r) or tostring(r), 7)
            end})
            backpack:Button({Title = "Offer Full Satchel Sale", Desc = "Uses the game's native full-satchel sale offer", Callback = function()
                local ok, r = callRemote(Remotes.Haul.OfferFullSatchelSale)
                notify("Satchel", ok and jsonShort(r) or tostring(r), 7)
            end})
        end

        if Remotes.Trailwear then
            local trails = upgradeTab:Section({Title = "Trail Tools"})
            local trailId = ""
            trails:Input({Title = "Trail ID", Flag = "SAE_LatestTrailId", Placeholder = "trail id", Value = "", Callback = function(v) trailId = tostring(v or "") end})
            trails:Button({Title = "Select Trail", Callback = function()
                if trailId == "" then notify("Trail", "Fill Trail ID first", 4); return end
                local ok, r = callRemote(Remotes.Trailwear.AskChoose, trailId)
                notify("Trail", ok and "Select request sent" or tostring(r), 4)
            end})
            trails:Button({Title = "Worn Trail Snapshot", Callback = function()
                local ok, r = callRemote(Remotes.Trailwear.AskWornSnapshot)
                notify("Trail", ok and jsonShort(r) or tostring(r), 7)
            end})
        end
    end

    -- -------------------------------------------------------------
    -- EVENTS · Boss event / Monster event / onboarding questline
    -- Existing Rift + Boss Mastery automation is preserved above.
    -- -------------------------------------------------------------
    local eventsTab = G.AliceHUB_TabEvents
    if eventsTab then
        if Remotes.BossEvent then
            local boss = eventsTab:Section({Title = "Boss Event"})
            boss:Button({Title = "Boss Snapshot", Callback = function()
                local ok, r = callRemote(Remotes.BossEvent.AskSnapshot)
                notify("Boss Event", ok and jsonShort(r) or tostring(r), 8)
            end})
            boss:Button({Title = "Enter Boss Event", Callback = function()
                local ok, r = callRemote(Remotes.BossEvent.AskEnter)
                notify("Boss Event", ok and "Enter request sent" or tostring(r), 5)
            end})
        end

        if Remotes.MonsterEvent then
            local monster = eventsTab:Section({Title = "Monster Event"})
            monster:Button({Title = "Teleport to Monster Event", Callback = function()
                local ok, r = callRemote(Remotes.MonsterEvent.RequestTeleport)
                notify("Monster Event", ok and "Teleport request sent" or tostring(r), 5)
            end})
            monster:Button({Title = "Get Wins", Callback = function()
                local ok, r = callRemote(Remotes.MonsterEvent.GetWins)
                notify("Monster Event", ok and ("Wins: " .. tostring(r)) or tostring(r), 6)
            end})
            monster:Button({Title = "Get Win Parts", Callback = function()
                local ok, r = callRemote(Remotes.MonsterEvent.GetWinParts)
                notify("Monster Event", ok and jsonShort(r) or tostring(r), 7)
            end})
        end

        if Remotes.OnboardingQuestline then
            local quest = eventsTab:Section({Title = "Questline"})
            local claimId = ""
            quest:Input({Title = "Claim ID", Flag = "SAE_OnboardingClaimId", Placeholder = "optional claim id", Value = "", Callback = function(v) claimId = tostring(v or "") end})
            quest:Button({Title = "Acknowledge Questline", Callback = function()
                local ok, r = callRemote(Remotes.OnboardingQuestline.AskAcknowledge)
                notify("Questline", ok and "Acknowledge request sent" or tostring(r), 4)
            end})
            quest:Button({Title = "Claim Quest Reward", Callback = function()
                local ok, r
                if claimId == "" then ok, r = callRemote(Remotes.OnboardingQuestline.AskClaim)
                else ok, r = callRemote(Remotes.OnboardingQuestline.AskClaim, claimId) end
                notify("Questline", ok and "Claim request sent" or tostring(r), 5)
            end})
        end

        if Remotes.BossMastery and Remotes.BossMastery.AskUseMutationConsumable then
            local mastery = eventsTab:Section({Title = "Boss Mastery Tools"})
            local consumableId = ""
            mastery:Input({Title = "Mutation Consumable ID", Flag = "SAE_BossConsumableId", Placeholder = "consumable id", Value = "", Callback = function(v) consumableId = tostring(v or "") end})
            mastery:Button({Title = "Use Mutation Consumable", Callback = function()
                if consumableId == "" then notify("Boss Mastery", "Fill consumable ID first", 4); return end
                local ok, r = callRemote(Remotes.BossMastery.AskUseMutationConsumable, consumableId)
                notify("Boss Mastery", ok and "Use request sent" or tostring(r), 5)
            end})
        end
    end

    notify("AliceHUB · Latest Dump", "Compact latest-dump modules loaded", 4)
end)
]=]

stage("Payload bytes = " .. tostring(#PAYLOAD))
stage("BEFORE exact loadstring(payload)")

local started = os.clock()
local ok, chunk, compileErr = pcall(function()
    local fn, err = loadstring(PAYLOAD)
    return fn, err
end)
local elapsed = os.clock() - started

if not ok then
    stage("THREW after " .. string.format("%.3fs", elapsed) .. " -> " .. tostring(chunk))
elseif type(chunk) ~= "function" then
    stage("COMPILE FAIL after " .. string.format("%.3fs", elapsed) .. " -> " .. tostring(compileErr))
else
    stage("COMPILE PASS in " .. string.format("%.3fs", elapsed))
    stage("IMPORTANT: payload NOT executed")
end

stage("DONE")

local copy = setclipboard or toclipboard
if type(copy) == "function" then
    pcall(copy, table.concat(lines, "\n"))
end
