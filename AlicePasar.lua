--[[
    AliceHub - PASAR SETAN
    Runtime / prompt resolver build
    Target: Sindukun: Pasar Malam Arwah / Pasar Setan

    Design notes:
    - Uses live world objects + ProximityPrompt instead of hardcoding random remote hashes.
    - Reads known client config when available (GameConfig / BabiConfig / PetiArwahConfig).
    - Executor helpers are optional and guarded.
    - Designed for mobile executors too.

    UI: Obsidian · mobile toggle button + RightShift keybind.
]]

--// Singleton cleanup
local ENV = (getgenv and getgenv()) or _G
if ENV.ALICEHUB_PASAR_SETAN and type(ENV.ALICEHUB_PASAR_SETAN.Unload) == "function" then
    pcall(ENV.ALICEHUB_PASAR_SETAN.Unload)
end

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local Backpack = LP:WaitForChild("Backpack")

local State = {
    Alive = true,
    Connections = {},
    Tweens = {},
    ESP = {},
    Cooldowns = setmetatable({}, {__mode = "k"}),
    PromptCache = {},
    PromptCacheAt = 0,
    LastActions = {},
    OriginalEffects = setmetatable({}, {__mode = "k"}),
    OriginalLighting = {
        GlobalShadows = Lighting.GlobalShadows,
    },
    BlackScreen = false,
}

local DEFAULTS = {
    -- Farm
    AutoHarvest = false,
    AutoWater = false,
    AutoPlant = false,
    SeedFilter = "All Seeds",
    PlantDelay = 0.35,
    WaterDelay = 0.35,
    HarvestDelay = 0.15,

    -- Forage
    AutoForage = false,
    ForageFilter = "All",
    ForageDistance = 250,
    ForageDelay = 0.15,
    TravelSpeed = 140,

    -- Kiosk/Kitchen
    AutoRestock = false,
    AutoSliceCrows = false,
    AutoBuyIncense = false,
    IncenseType = "Both",
    IncenseThreshold = 5,
    AutoCook = false,
    RecipeFilter = "All Recipes",
    KitchenDelay = 0.65,

    -- Pig
    AutoScrubPigs = false,
    AutoFeedPigs = false,
    AutoRollPigs = false,
    PigRollTier = "Biasa",
    PigDelay = 0.75,

    -- Gacha / quests
    AutoRollPusaka = false,
    AutoSpiritChest = false,
    ChestTier = "Umum",
    AutoWildTuyul = false,
    AutoClaimQuests = false,
    AutoBalai = false,
    GachaDelay = 1.0,

    -- ESP
    CropESP = false,
    ForageESP = false,
    GhostESP = false,
    PigESP = false,
    ESPMaxDistance = 500,

    -- Character
    WalkSpeed = 16,
    JumpPower = 50,
    Noclip = false,
    InfiniteJump = false,
    AntiAFK = true,
    BlackScreen = false,
    FPSBooster = false,
    FPSLimit = 60,

    -- Runtime
    AutoSave = true,
}

local Settings = {}
for k, v in pairs(DEFAULTS) do
    Settings[k] = v
end

--// Executor-safe file config
local CONFIG_DIR = "AliceHub"
local CONFIG_FILE = CONFIG_DIR .. "/PasarSetan.json"

local function notify(title, text, duration)
    title = title or "AliceHub"
    text = tostring(text or "")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 4,
        })
    end)
    print(("[AliceHub] %s | %s"):format(title, text))
end

local function ensureConfigDir()
    if makefolder and isfolder then
        if not isfolder(CONFIG_DIR) then
            pcall(makefolder, CONFIG_DIR)
        end
    elseif makefolder then
        pcall(makefolder, CONFIG_DIR)
    end
end

local function saveConfig(silent)
    if not writefile then
        if not silent then notify("Config", "Executor tidak support writefile().") end
        return false
    end
    ensureConfigDir()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Settings)
    if not ok then
        if not silent then notify("Config", "Gagal encode config.") end
        return false
    end
    local wrote = pcall(writefile, CONFIG_FILE, encoded)
    if not silent then
        notify("Config", wrote and "Config tersimpan." or "Gagal menyimpan config.")
    end
    return wrote
end

local function loadConfig(silent)
    if not (readfile and isfile and isfile(CONFIG_FILE)) then
        if not silent then notify("Config", "Belum ada config tersimpan.") end
        return false
    end
    local okRead, raw = pcall(readfile, CONFIG_FILE)
    if not okRead then return false end
    local okDecode, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okDecode or type(data) ~= "table" then
        if not silent then notify("Config", "Config rusak / tidak valid.") end
        return false
    end
    for k, v in pairs(data) do
        if DEFAULTS[k] ~= nil then
            Settings[k] = v
        end
    end
    if not silent then notify("Config", "Config dimuat.") end
    return true
end

loadConfig(true)

local function changed()
    if Settings.AutoSave then
        task.defer(function()
            saveConfig(true)
        end)
    end
end

--// Basic helpers
local function lower(v)
    return string.lower(tostring(v or ""))
end

local function compact(v)
    return lower(v):gsub("[%s%p_]+", "")
end

local function hasAny(text, words)
    text = lower(text)
    for _, w in ipairs(words) do
        if string.find(text, lower(w), 1, true) then
            return true
        end
    end
    return false
end

local function character()
    return LP.Character
end

local function humanoid()
    local ch = character()
    return ch and ch:FindFirstChildOfClass("Humanoid")
end

local function rootPart()
    local ch = character()
    return ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
end

local function basePartOf(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Attachment") then
        return obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or nil
    end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function worldPosition(obj)
    if not obj then return nil end
    if obj:IsA("ProximityPrompt") then
        local par = obj.Parent
        if par and par:IsA("Attachment") then
            return par.WorldPosition
        end
        local p = basePartOf(par)
        return p and p.Position or nil
    end
    if obj:IsA("Attachment") then
        return obj.WorldPosition
    end
    local p = basePartOf(obj)
    return p and p.Position or nil
end

local function distanceTo(obj)
    local r = rootPart()
    local p = worldPosition(obj)
    if not (r and p) then return math.huge end
    return (r.Position - p).Magnitude
end

local function instanceBlob(inst, depth)
    depth = depth or 5
    local out = {}
    local cur = inst
    for _ = 1, depth do
        if not cur then break end
        table.insert(out, cur.Name)
        if cur:IsA("ProximityPrompt") then
            table.insert(out, cur.ActionText)
            table.insert(out, cur.ObjectText)
        end
        local ok, attrs = pcall(cur.GetAttributes, cur)
        if ok and type(attrs) == "table" then
            for k, v in pairs(attrs) do
                table.insert(out, tostring(k))
                table.insert(out, tostring(v))
            end
        end
        cur = cur.Parent
    end
    return lower(table.concat(out, " "))
end

local function ownershipStatus(inst)
    local cur = inst
    for _ = 1, 8 do
        if not cur then break end
        local blobName = lower(cur.Name)
        if string.find(blobName, lower(LP.Name), 1, true) or string.find(blobName, tostring(LP.UserId), 1, true) then
            return true
        end
        local ok, attrs = pcall(cur.GetAttributes, cur)
        if ok and type(attrs) == "table" then
            for k, v in pairs(attrs) do
                local key = compact(k)
                if key == "owner" or key == "ownerid" or key == "owneruserid" or key == "userid" or key == "pemilik" then
                    if tonumber(v) then
                        if tonumber(v) == LP.UserId then return true else return false end
                    elseif type(v) == "string" then
                        if lower(v) == lower(LP.Name) or v == tostring(LP.UserId) then return true else return false end
                    elseif typeof(v) == "Instance" and v == LP then
                        return true
                    end
                end
            end
        end
        cur = cur.Parent
    end
    return nil
end

local function aliveCharacter()
    local h = humanoid()
    return h and h.Health > 0
end

local function safeCFrameAt(pos)
    return CFrame.new(pos + Vector3.new(0, 2.8, 0))
end

local function moveToPosition(pos, speed)
    local r = rootPart()
    if not (r and pos and aliveCharacter()) then return false end
    local dist = (r.Position - pos).Magnitude
    if dist < 5 then return true end

    speed = math.max(25, tonumber(speed) or 140)
    local duration = math.clamp(dist / speed, 0.04, 2.25)
    local tw = TweenService:Create(r, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = safeCFrameAt(pos)
    })
    table.insert(State.Tweens, tw)
    local ok = pcall(function()
        tw:Play()
        tw.Completed:Wait()
    end)
    return ok
end

local function teleportTo(obj)
    local pos = worldPosition(obj)
    local r = rootPart()
    if not (pos and r) then return false end
    r.CFrame = safeCFrameAt(pos)
    return true
end

local function triggerPrompt(prompt, moveIfNeeded)
    if not (prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled) then return false end
    local dist = distanceTo(prompt)
    local maxD = prompt.MaxActivationDistance or 10
    if moveIfNeeded and dist > math.max(3, maxD - 1) then
        moveToPosition(worldPosition(prompt), Settings.TravelSpeed)
        task.wait(0.04)
    end

    if fireproximityprompt then
        local ok = pcall(fireproximityprompt, prompt, 0)
        if ok then return true end
    end

    local oldHold = prompt.HoldDuration
    local ok = pcall(function()
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.wait()
        prompt:InputHoldEnd()
    end)
    pcall(function() prompt.HoldDuration = oldHold end)
    return ok
end

local function refreshPrompts(force)
    local now = os.clock()
    if not force and now - State.PromptCacheAt < 1.0 then
        return State.PromptCache
    end
    local list = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            table.insert(list, d)
        end
    end
    State.PromptCache = list
    State.PromptCacheAt = now
    return list
end

local function bestPrompt(includeWords, scopeWords, maxDistance, ownedPreference)
    local best, bestScore = nil, math.huge
    local r = rootPart()
    if not r then return nil end

    for _, p in ipairs(refreshPrompts()) do
        if p.Parent and p.Enabled then
            local blob = instanceBlob(p, 7)
            if hasAny(blob, includeWords) and (not scopeWords or #scopeWords == 0 or hasAny(blob, scopeWords)) then
                local dist = distanceTo(p)
                if not maxDistance or dist <= maxDistance then
                    local own = ownershipStatus(p)
                    if not (ownedPreference == true and own == false) then
                        local score = dist
                        if own == true then score = score - 30 end
                        if ownedPreference == true and own == nil then score = score + 10 end
                        if score < bestScore then
                            best, bestScore = p, score
                        end
                    end
                end
            end
        end
    end
    return best
end

local function findByExactName(names)
    for _, name in ipairs(names) do
        local obj = workspace:FindFirstChild(name, true)
        if obj then return obj end
    end
    return nil
end

local function bestWorldTarget(words, preferOwned)
    local r = rootPart()
    if not r then return nil end
    local best, score = nil, math.huge
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") or d:IsA("BasePart") then
            local blob = instanceBlob(d, 4)
            if hasAny(blob, words) then
                local p = worldPosition(d)
                if p then
                    local dist = (r.Position - p).Magnitude
                    local own = ownershipStatus(d)
                    if not (preferOwned and own == false) then
                        if own == true then dist = dist - 50 end
                        if preferOwned and own == nil then dist = dist + 20 end
                        if dist < score then
                            best, score = d, dist
                        end
                    end
                end
            end
        end
    end
    return best
end

--// Inventory
local function allTools()
    local out = {}
    local ch = character()
    for _, container in ipairs({Backpack, ch}) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") then table.insert(out, obj) end
            end
        end
    end
    return out
end

local function toolBlob(tool)
    local out = {tool.Name}
    local ok, attrs = pcall(tool.GetAttributes, tool)
    if ok then
        for k, v in pairs(attrs) do
            table.insert(out, tostring(k))
            table.insert(out, tostring(v))
        end
    end
    return lower(table.concat(out, " "))
end

local function countTools(aliases)
    local count = 0
    for _, tool in ipairs(allTools()) do
        local blob = toolBlob(tool)
        if hasAny(blob, aliases) then
            local qty = 1
            local ok, attrs = pcall(tool.GetAttributes, tool)
            if ok then
                for k, v in pairs(attrs) do
                    local key = compact(k)
                    if (key == "qty" or key == "quantity" or key == "amount" or key == "jumlah" or key == "count") and tonumber(v) then
                        qty = math.max(qty, tonumber(v))
                    end
                end
            end
            count = count + qty
        end
    end
    return count
end

local function equipTool(aliases)
    local h = humanoid()
    if not h then return nil end
    for _, tool in ipairs(allTools()) do
        if hasAny(toolBlob(tool), aliases) then
            pcall(function() h:EquipTool(tool) end)
            return tool
        end
    end
    return nil
end

local SEEDS = {
    ["Melati"] = {"bibitmelati", "bibit melati", "melati seed"},
    ["Kamboja"] = {"bibitkamboja", "bibit kamboja", "kamboja seed"},
    ["Pisang"] = {"bibitpisang", "bibit pisang", "pisang seed"},
}

local FEEDS = {
    {"satekepiting", "sate kepiting"},
    {"pisangrajarebus", "pisang raja rebus"},
    {"tumiskamboja", "tumis kamboja"},
    {"sategagak", "sate gagak"},
    {"jamurrebus", "jamur rebus"},
}

local SELLABLE = {
    {"satekepiting", "sate kepiting"},
    {"pisangrajarebus", "pisang raja rebus"},
    {"tumiskamboja", "tumis kamboja"},
    {"sategagak", "sate gagak"},
    {"jamurrebus", "jamur rebus"},
    {"kepitingsungai", "kepiting sungai"},
    {"kemenyan"},
    {"dupa"},
    {"melati"},
}

local function equipAny(list)
    for _, aliases in ipairs(list) do
        local t = equipTool(aliases)
        if t then return t end
    end
    return nil
end

local seedCycle = 0
local function equipSelectedSeed()
    if Settings.SeedFilter ~= "All Seeds" then
        return equipTool(SEEDS[Settings.SeedFilter] or {Settings.SeedFilter})
    end
    local order = {"Melati", "Kamboja", "Pisang"}
    for _ = 1, #order do
        seedCycle = (seedCycle % #order) + 1
        local t = equipTool(SEEDS[order[seedCycle]])
        if t then return t end
    end
    return nil
end

--// GUI clicking helpers
local function guiVisible(inst)
    local cur = inst
    for _ = 1, 8 do
        if not cur then break end
        if cur:IsA("GuiObject") and cur.Visible == false then return false end
        cur = cur.Parent
    end
    return true
end

local function buttonText(btn)
    local out = {btn.Name}
    if btn:IsA("TextButton") then table.insert(out, btn.Text) end
    for _, d in ipairs(btn:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            table.insert(out, d.Text)
        end
    end
    return lower(table.concat(out, " "))
end

local function ancestorGuiText(inst, depth)
    local out = {}
    local cur = inst
    for _ = 1, depth or 5 do
        if not cur then break end
        table.insert(out, cur.Name)
        if cur:IsA("TextLabel") or cur:IsA("TextButton") then
            table.insert(out, cur.Text)
        end
        cur = cur.Parent
    end
    return lower(table.concat(out, " "))
end

local function activateButton(btn)
    if not (btn and btn:IsA("GuiButton") and guiVisible(btn)) then return false end
    if firesignal then
        local ok = pcall(function()
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                firesignal(btn.MouseButton1Click)
            end
        end)
        if ok then return true end
    end
    return pcall(function() btn:Activate() end)
end

local function findVisibleButton(textWords, scopeWords)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local best
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiButton") and guiVisible(d) then
            local text = buttonText(d)
            if hasAny(text, textWords) then
                if not scopeWords or #scopeWords == 0 or hasAny(ancestorGuiText(d, 8), scopeWords) then
                    best = d
                    break
                end
            end
        end
    end
    return best
end

local function clickByText(words, scopeWords)
    local btn = findVisibleButton(words, scopeWords)
    if btn then return activateButton(btn), btn end
    return false, nil
end

local function findTextBox(scopeWords)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextBox") and guiVisible(d) then
            if not scopeWords or hasAny(ancestorGuiText(d, 8), scopeWords) then
                return d
            end
        end
    end
    return nil
end

--// Optional live config
local GameConfig, BabiConfig, PetiConfig
pcall(function()
    local m = ReplicatedStorage:FindFirstChild("GameConfig")
    if m and m:IsA("ModuleScript") then GameConfig = require(m) end
end)
pcall(function()
    local m = ReplicatedStorage:FindFirstChild("BabiConfig")
    if m and m:IsA("ModuleScript") then BabiConfig = require(m) end
end)
pcall(function()
    local m = ReplicatedStorage:FindFirstChild("PetiArwahConfig")
    if m and m:IsA("ModuleScript") then PetiConfig = require(m) end
end)

--// Actions: farm
local function doHarvest()
    local p = bestPrompt(
        {"panen", "harvest", "petik"},
        {"kebun", "lahan", "farm", "tanaman", "plant", "melati", "kamboja", "pisang"},
        nil,
        true
    )
    if p then
        return triggerPrompt(p, true)
    end
    return false
end

local function doWater()
    local p = bestPrompt(
        {"siram", "water"},
        {"kebun", "lahan", "farm", "tanaman", "plant", "melati", "kamboja", "pisang"},
        nil,
        true
    )
    if p then
        equipTool({"gembor", "penyiram", "watering"})
        return triggerPrompt(p, true)
    end
    return false
end

local function doPlant()
    local t = equipSelectedSeed()
    if not t then return false end
    local p = bestPrompt(
        {"tanam", "plant", "isi tanah", "bibit", "seed"},
        {"kebun", "lahan", "farm", "tanah", "tile", "plot"},
        nil,
        true
    )
    if p then
        return triggerPrompt(p, true)
    end
    return false
end

--// Forage
local FORAGE_NAMES = {
    ["Melati"] = {"melati"},
    ["Jamur Kuburan"] = {"jamurkuburan", "jamur kuburan"},
    ["Kemenyan"] = {"kemenyan"},
    ["Kepiting Sungai"] = {"kepitingsungai", "kepiting sungai"},
    ["Gagak"] = {"gagak"},
}

local function forageFolder()
    local fromCfg
    if type(GameConfig) == "table" and type(GameConfig.Forage) == "table" then
        fromCfg = GameConfig.Forage.SpawnFolder
    end
    return workspace:FindFirstChild(fromCfg or "SpawnBahan", true)
end

local function classifyForage(inst)
    local blob = instanceBlob(inst, 6)
    for label, aliases in pairs(FORAGE_NAMES) do
        if hasAny(blob, aliases) then return label end
    end
    return nil
end

local function foragePromptFor(obj)
    if obj:IsA("ProximityPrompt") then return obj end
    return obj:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function getForageCandidates()
    local folder = forageFolder()
    if not folder then return {} end
    local now = os.clock()
    local r = rootPart()
    if not r then return {} end
    local out, seen = {}, {}
    for _, d in ipairs(folder:GetDescendants()) do
        local p = d:IsA("ProximityPrompt") and d or nil
        if p and not seen[p] and p.Enabled then
            seen[p] = true
            local label = classifyForage(p)
            if label then
                local filterOk = Settings.ForageFilter == "All" or Settings.ForageFilter == label
                local dist = distanceTo(p)
                local last = State.Cooldowns[p] or 0
                local cd = 30
                if type(GameConfig) == "table" and type(GameConfig.Forage) == "table" then
                    cd = tonumber(GameConfig.Forage.RespawnCooldown) or cd
                end
                if filterOk and dist <= Settings.ForageDistance and (now - last) >= math.min(cd, 30) then
                    table.insert(out, {Prompt = p, Label = label, Distance = dist})
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.Distance < b.Distance end)
    return out
end

local function doForage()
    local list = getForageCandidates()
    local target = list[1]
    if not target then return false end
    local p = target.Prompt
    local pos = worldPosition(p)
    if pos then moveToPosition(pos, Settings.TravelSpeed) end
    task.wait(0.03)
    local ok = triggerPrompt(p, false)
    if ok then
        State.Cooldowns[p] = os.clock()
    end
    return ok
end

--// Kiosk / kitchen
local function doRestock()
    equipAny(SELLABLE)
    local p = bestPrompt(
        {"isi rak", "restock", "taruh", "stok", "rak"},
        {"kios", "lapak", "market", "rack", "rak"},
        nil,
        true
    )
    if p and not hasAny(instanceBlob(p, 5), {"storage", "gudang"}) then
        return triggerPrompt(p, true)
    end
    return false
end

local function doSliceCrow()
    if not equipTool({"gagak"}) then return false end
    local p = bestPrompt(
        {"potong gagak", "potong", "slice"},
        {"gagak", "daging", "prep", "meat", "dapur", "kitchen"},
        nil,
        nil
    )
    if p then return triggerPrompt(p, true) end
    return false
end

local RECIPE_GUI = {
    ["Sate Gagak"] = {"sate gagak", "bakar"},
    ["Jamur Rebus"] = {"jamur rebus", "rebus"},
    ["Tumis Kamboja"] = {"tumis kamboja"},
    ["Sate Kepiting"] = {"sate kepiting"},
    ["Pisang Rebus"] = {"pisang raja rebus", "pisang rebus"},
}

local recipeCycle = 0
local function selectedRecipeAliases()
    if Settings.RecipeFilter ~= "All Recipes" then
        return RECIPE_GUI[Settings.RecipeFilter] or {Settings.RecipeFilter}
    end
    local order = {"Sate Gagak", "Jamur Rebus", "Tumis Kamboja", "Sate Kepiting", "Pisang Rebus"}
    recipeCycle = (recipeCycle % #order) + 1
    return RECIPE_GUI[order[recipeCycle]]
end

local function openKitchen()
    local exact = findByExactName({"Kompor"})
    if exact then
        local p = exact:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p then return triggerPrompt(p, true) end
    end
    local p = bestPrompt({"buka dapur", "dapur", "kompor"}, {"dapur", "kompor", "kitchen", "stove"}, nil, nil)
    if p then return triggerPrompt(p, true) end
    return false
end

local function doCook()
    openKitchen()
    task.wait(0.12)
    local aliases = selectedRecipeAliases()
    local clicked = clickByText(aliases, {"dapur", "kompor", "masak", "cook", "resep", "recipe"})
    if clicked then
        task.wait(0.08)
        clickByText({"masak", "cook", "buat", "queue", "mulai"}, {"dapur", "kompor", "masak", "cook"})
        return true
    end
    return false
end

local function shopPrompt()
    local npc = findByExactName({"NpcShop"})
    if npc then
        local p = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p then return p end
    end
    return bestPrompt({"buka toko", "toko", "shop"}, {"npcshop", "toko", "shop"}, nil, nil)
end

local function buyShopItem(label)
    local p = shopPrompt()
    if p then triggerPrompt(p, true) end
    task.wait(0.12)
    local ok = clickByText({label}, {"toko", "shop", "beli", "alat"})
    if ok then
        task.wait(0.06)
        clickByText({"beli", "buy"}, {"toko", "shop"})
        return true
    end
    return false
end

local function doBuyIncense()
    local wants = {}
    if Settings.IncenseType == "Dupa" or Settings.IncenseType == "Both" then
        table.insert(wants, {"Dupa", {"dupa"}})
    end
    if Settings.IncenseType == "Pengelaris" or Settings.IncenseType == "Both" then
        table.insert(wants, {"Pengelaris", {"pengelaris", "dupa pemikat"}})
    end
    for _, item in ipairs(wants) do
        if countTools(item[2]) < Settings.IncenseThreshold then
            return buyShopItem(item[1])
        end
    end
    return false
end

--// Pigs
local function doScrubPig()
    if not equipTool({"pengosok", "gosok", "scrub"}) then return false end
    local p = bestPrompt(
        {"gosok", "mandi", "bersih", "scrub"},
        {"babi", "pig", "kandang"},
        nil,
        true
    )
    if p then return triggerPrompt(p, true) end
    return false
end

local function doFeedPig()
    if not equipAny(FEEDS) then return false end
    local p = bestPrompt(
        {"isi palung", "beri makan", "feed", "pakan"},
        {"babi", "pig", "kandang", "palung", "tempat makan"},
        nil,
        true
    )
    if p then return triggerPrompt(p, true) end
    return false
end

local function openBandar()
    local p = bestPrompt(
        {"bandar", "beli induk", "beli babi", "buka"},
        {"bandar", "babi", "pig"},
        nil,
        nil
    )
    if p then return triggerPrompt(p, true) end
    local target = bestWorldTarget({"bandar babi", "bandarbabi"}, false)
    if target then teleportTo(target) return true end
    return false
end

local function doRollPig()
    openBandar()
    task.wait(0.12)
    local tier = Settings.PigRollTier
    clickByText({tier}, {"bandar", "babi", "induk"})
    task.wait(0.05)
    local ok = clickByText({"beli induk", "roll", "undi", "gacha", "beli"}, {"bandar", "babi", "induk"})
    return ok
end

--// Gacha / chests / quests
local function doRollPusaka()
    local p = bestPrompt(
        {"pusaka", "roll", "undi", "putar", "buka"},
        {"pusaka", "gaib", "relic", "dark market", "pasar gaib"},
        nil,
        nil
    )
    if p then triggerPrompt(p, true) end
    task.wait(0.10)
    local ok = clickByText({"roll", "undi", "putar", "gacha"}, {"pusaka", "relic", "gaib"})
    return ok
end

local function doSpiritChest()
    local p = bestPrompt(
        {"peti", "chest", "buka"},
        {"peti arwah", "peti gaib", "spirit", "arwah", "chest"},
        nil,
        nil
    )
    if p then triggerPrompt(p, true) end
    task.wait(0.10)

    local tierWords = {lower(Settings.ChestTier)}
    if Settings.ChestTier == "Mistik" then
        tierWords = {"mistik", "mistis"}
    end
    clickByText(tierWords, {"peti", "chest", "arwah", "gaib"})
    task.wait(0.05)
    local ok = clickByText({"buka", "pull", "tarik", "open", "roll"}, {"peti", "chest", "arwah", "gaib"})
    return ok
end

local function findTuyulLiar()
    local exact = findByExactName({"TuyulLiar"})
    if exact then return exact end
    return bestWorldTarget({"tuyul liar", "tuyulliar"}, false)
end

local function doWildTuyul()
    if not equipTool({"satekepiting", "sate kepiting"}) then return false end
    local tuyul = findTuyulLiar()
    if not tuyul then return false end
    local p = tuyul:FindFirstChildWhichIsA("ProximityPrompt", true)
    if p then return triggerPrompt(p, true) end
    return false
end

local function doClaimQuests()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return false end
    local clicked = false
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiButton") and guiVisible(d) then
            local txt = buttonText(d)
            local scope = ancestorGuiText(d, 9)
            if hasAny(txt, {"klaim", "claim", "ambil hadiah", "collect"}) and hasAny(scope, {"quest", "misi", "tugas", "harian", "daily"}) then
                if activateButton(d) then
                    clicked = true
                    task.wait(0.05)
                end
            end
        end
    end
    return clicked
end

local function doBalai()
    local npc = findByExactName({"NpcBalaiDagang", "SpawnLocationBalaiDagang"})
    if npc then
        local p = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p then triggerPrompt(p, true) else teleportTo(npc) end
    else
        local p = bestPrompt({"balai", "village hall", "buka"}, {"balai", "desa", "village"}, nil, nil)
        if p then triggerPrompt(p, true) end
    end
    task.wait(0.10)
    local ok = clickByText({"klaim", "claim", "ambil", "collect"}, {"balai", "desa", "village", "perk"})
    return ok
end

local function collectClientCodes()
    local found, seen = {}, {}
    local function add(v)
        if type(v) ~= "string" then return end
        if #v < 3 or #v > 32 then return end
        if not v:match("^[%w%-%_]+$") then return end
        if seen[v] then return end
        seen[v] = true
        table.insert(found, v)
    end

    local function walk(t, depth)
        if depth > 4 or type(t) ~= "table" then return end
        for k, v in pairs(t) do
            if type(k) == "string" and hasAny(k, {"code", "kode", "promo"}) then
                if type(v) == "string" then add(v) end
                if type(v) == "table" then walk(v, depth + 1) end
            elseif type(v) == "table" then
                walk(v, depth + 1)
            end
        end
    end

    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("ModuleScript") and hasAny(d.Name, {"code", "kode", "promo", "redeem"}) then
            local ok, data = pcall(require, d)
            if ok then
                if type(data) == "table" then walk(data, 1)
                elseif type(data) == "string" then add(data) end
            end
        end
    end
    return found
end

local function redeemAllCodes()
    local codes = collectClientCodes()
    if #codes == 0 then
        notify("Redeem Codes", "Tidak ada daftar kode aktif yang diekspos client. Tidak mengarang kode palsu.")
        return false
    end

    local box = findTextBox({"code", "kode", "promo", "redeem"})
    if not box then
        clickByText({"code", "kode", "promo"}, nil)
        task.wait(0.15)
        box = findTextBox({"code", "kode", "promo", "redeem"})
    end
    if not box then
        notify("Redeem Codes", "UI input kode tidak ditemukan.")
        return false
    end

    local used = 0
    for _, code in ipairs(codes) do
        pcall(function() box.Text = code end)
        task.wait(0.03)
        local ok = clickByText({"redeem", "klaim", "claim", "tukar"}, {"code", "kode", "promo"})
        if ok then
            used = used + 1
            task.wait(0.25)
        end
    end
    notify("Redeem Codes", ("Mencoba %d kode client-side."):format(used))
    return used > 0
end

--// ESP
local ESP_ROOT_NAME = "AliceHub_ESP"

local function getGuiRoot()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return game:GetService("CoreGui")
end

local ESPRoot = Instance.new("Folder")
ESPRoot.Name = ESP_ROOT_NAME
ESPRoot.Parent = getGuiRoot()

local function metricValue(inst, keys)
    local cur = inst
    for _ = 1, 5 do
        if not cur then break end
        local ok, attrs = pcall(cur.GetAttributes, cur)
        if ok then
            for k, v in pairs(attrs) do
                local lk = compact(k)
                for _, wanted in ipairs(keys) do
                    if string.find(lk, compact(wanted), 1, true) then
                        return v
                    end
                end
            end
        end
        cur = cur.Parent
    end
    return nil
end

local function espTextFor(category, obj, label)
    if category == "Crop" then
        local growth = metricValue(obj, {"growth", "progress", "tumbuh", "umur", "stage"})
        local wet = metricValue(obj, {"wetleft", "moisture", "water", "siram", "basah"})
        local extra = {}
        if growth ~= nil then table.insert(extra, "Growth: " .. tostring(growth)) end
        if wet ~= nil then table.insert(extra, "Water: " .. tostring(wet)) end
        return label .. (#extra > 0 and ("\n" .. table.concat(extra, " | ")) or "")
    elseif category == "Pig" then
        local dirty = metricValue(obj, {"dirty", "kotor", "clean"})
        local hunger = metricValue(obj, {"hunger", "lapar", "kenyang", "food"})
        local extra = {}
        if dirty ~= nil then table.insert(extra, "Clean: " .. tostring(dirty)) end
        if hunger ~= nil then table.insert(extra, "Hunger: " .. tostring(hunger)) end
        return label .. (#extra > 0 and ("\n" .. table.concat(extra, " | ")) or "")
    end
    return label
end

local function ensureESP(category, obj, label)
    if not obj or not obj.Parent then return end
    State.ESP[category] = State.ESP[category] or {}
    local bucket = State.ESP[category]
    local entry = bucket[obj]
    local adorneePart = basePartOf(obj)
    if not adorneePart then return end

    if not entry then
        local highlight = Instance.new("Highlight")
        highlight.Name = "H_" .. category
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.82
        highlight.OutlineTransparency = 0
        highlight.Adornee = obj:IsA("Model") and obj or adorneePart
        highlight.Parent = ESPRoot

        local bill = Instance.new("BillboardGui")
        bill.Name = "B_" .. category
        bill.AlwaysOnTop = true
        bill.Size = UDim2.fromOffset(220, 48)
        bill.StudsOffset = Vector3.new(0, 2.7, 0)
        bill.Adornee = adorneePart
        bill.Parent = ESPRoot

        local txt = Instance.new("TextLabel")
        txt.BackgroundTransparency = 1
        txt.Size = UDim2.fromScale(1, 1)
        txt.Font = Enum.Font.GothamSemibold
        txt.TextSize = 13
        txt.TextStrokeTransparency = 0.35
        txt.TextWrapped = true
        txt.Text = label
        txt.Parent = bill

        entry = {Highlight = highlight, Billboard = bill, Text = txt}
        bucket[obj] = entry
    end

    local dist = distanceTo(obj)
    entry.Billboard.Enabled = dist <= Settings.ESPMaxDistance
    entry.Highlight.Enabled = dist <= Settings.ESPMaxDistance
    if entry.Billboard.Enabled then
        entry.Text.Text = espTextFor(category, obj, ("%s [%.0f]"):format(label, dist))
    end
end

local function clearESPCategory(category)
    local bucket = State.ESP[category]
    if not bucket then return end
    for obj, entry in pairs(bucket) do
        for _, ui in pairs(entry) do
            if typeof(ui) == "Instance" then pcall(function() ui:Destroy() end) end
        end
        bucket[obj] = nil
    end
end

local function cleanDeadESP(category)
    local bucket = State.ESP[category]
    if not bucket then return end
    for obj, entry in pairs(bucket) do
        if not obj.Parent then
            for _, ui in pairs(entry) do
                if typeof(ui) == "Instance" then pcall(function() ui:Destroy() end) end
            end
            bucket[obj] = nil
        end
    end
end

local function topModel(inst, stopAt)
    local cur = inst
    local lastModel
    while cur and cur ~= stopAt do
        if cur:IsA("Model") then lastModel = cur end
        cur = cur.Parent
    end
    return lastModel or inst
end

local function updateForageESP()
    if not Settings.ForageESP then clearESPCategory("Forage") return end
    local folder = forageFolder()
    if not folder then return end
    local seen = {}
    for _, p in ipairs(folder:GetDescendants()) do
        if p:IsA("ProximityPrompt") then
            local label = classifyForage(p)
            if label then
                local obj = topModel(p.Parent, folder)
                if not seen[obj] then
                    seen[obj] = true
                    ensureESP("Forage", obj, label)
                end
            end
        end
    end
    cleanDeadESP("Forage")
end

local function updateGhostESP()
    if not Settings.GhostESP then clearESPCategory("Ghost") return end
    local folder = workspace:FindFirstChild("Arwah", true)
    if not folder then return end
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            ensureESP("Ghost", obj, obj.Name)
        end
    end
    cleanDeadESP("Ghost")
end

local function updatePigESP()
    if not Settings.PigESP then clearESPCategory("Pig") return end
    local seen = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and hasAny(instanceBlob(d, 2), {"babi", "pig"}) then
            if not hasAny(instanceBlob(d, 3), {"npc", "bandar"}) then
                seen[d] = true
                ensureESP("Pig", d, d.Name)
            end
        end
    end
    cleanDeadESP("Pig")
end

local function updateCropESP()
    if not Settings.CropESP then clearESPCategory("Crop") return end
    local seen = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") then
            local blob = instanceBlob(d, 3)
            if hasAny(blob, {"melati", "kamboja", "pisang"}) and hasAny(blob, {"kebun", "lahan", "farm", "tanam", "plant"}) then
                seen[d] = true
                ensureESP("Crop", d, d.Name)
            end
        end
    end
    cleanDeadESP("Crop")
end

--// Teleports
local function teleportNamed(kind)
    local target
    if kind == "My Kiosk" then
        local folder = workspace:FindFirstChild("KiosAktif", true)
        if folder then
            for _, d in ipairs(folder:GetChildren()) do
                if ownershipStatus(d) == true then target = d break end
            end
        end
        target = target or bestWorldTarget({"kios", "lapak"}, true)
    elseif kind == "My Farm" then
        target = bestWorldTarget({"kebun", "lahan", "farm"}, true)
    elseif kind == "My Pig Pen" then
        target = bestWorldTarget({"kandang", "pig pen", "babi"}, true)
    elseif kind == "Seed Merchant" then
        target = findByExactName({"NpcBibit"}) or bestWorldTarget({"toko bibit", "npcbibit", "seed"}, false)
    elseif kind == "Tool Shop" then
        target = findByExactName({"NpcShop"}) or bestWorldTarget({"buka toko", "npcshop", "tool shop"}, false)
    elseif kind == "Village Hall" then
        target = findByExactName({"NpcBalaiDagang", "SpawnLocationBalaiDagang"}) or bestWorldTarget({"balai", "village hall"}, false)
    elseif kind == "Spirit Chest Area" then
        target = findByExactName({"PetiArwah", "PetiGaib"}) or bestWorldTarget({"peti arwah", "peti gaib", "spirit chest"}, false)
    elseif kind == "Dark Market" then
        target = findByExactName({"PasarGaib", "DarkMarket"}) or bestWorldTarget({"pasar gaib", "dark market", "gaib"}, false)
    end
    if target and teleportTo(target) then
        notify("Teleport", "Ke " .. kind)
        return true
    end
    notify("Teleport", "Lokasi " .. kind .. " belum ditemukan di workspace.")
    return false
end

--// Character utilities
local function applyMovement()
    local h = humanoid()
    if not h then return end
    pcall(function()
        h.UseJumpPower = true
        h.WalkSpeed = Settings.WalkSpeed
        h.JumpPower = Settings.JumpPower
    end)
end

local noclipConn
local function setNoclip(on)
    Settings.Noclip = on
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local ch = character()
            if ch then
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("BasePart") then d.CanCollide = false end
                end
            end
        end)
        table.insert(State.Connections, noclipConn)
    end
end

local infJumpConn
local function setInfiniteJump(on)
    Settings.InfiniteJump = on
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if on then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local h = humanoid()
            if h then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        table.insert(State.Connections, infJumpConn)
    end
end

local antiAfkConn
local function setAntiAFK(on)
    Settings.AntiAFK = on
    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if on then
        antiAfkConn = LP.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end)
        table.insert(State.Connections, antiAfkConn)
    end
end

local function setBlackScreen(on)
    Settings.BlackScreen = on
    State.BlackScreen = on
    pcall(function()
        RunService:Set3dRenderingEnabled(not on)
    end)
end

local function setFPSBooster(on)
    Settings.FPSBooster = on
    if on then
        State.OriginalLighting.GlobalShadows = Lighting.GlobalShadows
        Lighting.GlobalShadows = false
        for _, d in ipairs(game:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or
               d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") or
               d:IsA("BloomEffect") or d:IsA("BlurEffect") or
               d:IsA("ColorCorrectionEffect") or d:IsA("SunRaysEffect") or d:IsA("DepthOfFieldEffect") then
                local ok, enabled = pcall(function() return d.Enabled end)
                if ok then
                    State.OriginalEffects[d] = enabled
                    pcall(function() d.Enabled = false end)
                end
            end
        end
    else
        Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
        for d, enabled in pairs(State.OriginalEffects) do
            if d and d.Parent then
                pcall(function() d.Enabled = enabled end)
            end
            State.OriginalEffects[d] = nil
        end
    end
end

local function applyFPSLimit()
    if setfpscap then
        pcall(setfpscap, Settings.FPSLimit)
        notify("FPS", "Limiter: " .. tostring(Settings.FPSLimit))
    else
        notify("FPS", "Executor tidak support setfpscap().")
    end
end

local function fastRejoin()
    notify("Rejoin", "Rejoining server sekarang...")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
end

local function serverHop()
    task.spawn(function()
        local ok, raw = pcall(function()
            return game:HttpGet(
                "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) ..
                "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
            )
        end)
        if not ok then
            notify("Server Hop", "HTTP request gagal.")
            return
        end
        local okJson, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not okJson or type(data) ~= "table" or type(data.data) ~= "table" then
            notify("Server Hop", "Response server list tidak valid.")
            return
        end
        local choices = {}
        for _, s in ipairs(data.data) do
            if s.id and s.id ~= game.JobId and (not s.playing or not s.maxPlayers or s.playing < s.maxPlayers) then
                table.insert(choices, s.id)
            end
        end
        if #choices == 0 then
            notify("Server Hop", "Server lain tidak ditemukan.")
            return
        end
        local id = choices[math.random(1, #choices)]
        notify("Server Hop", "Pindah server...")
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LP)
        end)
    end)
end

--// Workers
local function worker(flag, delayGetter, action)
    task.spawn(function()
        while State.Alive do
            if Settings[flag] then
                local ok, err = pcall(action)
                if not ok then
                    warn("[AliceHub/" .. flag .. "] " .. tostring(err))
                end
                local d = type(delayGetter) == "function" and delayGetter() or delayGetter
                task.wait(math.max(0.03, tonumber(d) or 0.25))
            else
                task.wait(0.18)
            end
        end
    end)
end

worker("AutoHarvest", function() return Settings.HarvestDelay end, doHarvest)
worker("AutoWater", function() return Settings.WaterDelay end, doWater)
worker("AutoPlant", function() return Settings.PlantDelay end, doPlant)
worker("AutoForage", function() return Settings.ForageDelay end, doForage)
worker("AutoRestock", 0.45, doRestock)
worker("AutoSliceCrows", 0.45, doSliceCrow)
worker("AutoBuyIncense", 1.25, doBuyIncense)
worker("AutoCook", function() return Settings.KitchenDelay end, doCook)
worker("AutoScrubPigs", function() return Settings.PigDelay end, doScrubPig)
worker("AutoFeedPigs", function() return Settings.PigDelay end, doFeedPig)
worker("AutoRollPigs", 1.2, doRollPig)
worker("AutoRollPusaka", function() return Settings.GachaDelay end, doRollPusaka)
worker("AutoSpiritChest", function() return Settings.GachaDelay end, doSpiritChest)
worker("AutoWildTuyul", 0.25, doWildTuyul)
worker("AutoClaimQuests", 1.25, doClaimQuests)
worker("AutoBalai", 1.5, doBalai)

task.spawn(function()
    while State.Alive do
        pcall(updateCropESP)
        pcall(updateForageESP)
        pcall(updateGhostESP)
        pcall(updatePigESP)
        task.wait(1.0)
    end
end)

task.spawn(function()
    while State.Alive do
        pcall(applyMovement)
        task.wait(1.0)
    end
end)

--// UI · Obsidian Edition
local OBSIDIAN_REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local legacyNotify = notify

local okLibrary, Library = pcall(function()
    return loadstring(game:HttpGet(OBSIDIAN_REPO .. "Library.lua"))()
end)

if not okLibrary or type(Library) ~= "table" then
    State.Alive = false
    legacyNotify("AliceHub", "Gagal load Obsidian UI: " .. tostring(Library), 8)
    error("AliceHub: Obsidian UI gagal dimuat")
end

local okTheme, ThemeManager = pcall(function()
    return loadstring(game:HttpGet(OBSIDIAN_REPO .. "addons/ThemeManager.lua"))()
end)

local okSave, SaveManager = pcall(function()
    return loadstring(game:HttpGet(OBSIDIAN_REPO .. "addons/SaveManager.lua"))()
end)

local Options = Library.Options
local Toggles = Library.Toggles
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true
Library.NotifySide = "Right"
Library.ShowCustomCursor = false

notify = function(title, textValue, duration)
    title = title or "AliceHub"
    textValue = tostring(textValue or "")
    local ok = pcall(function()
        Library:Notify({
            Title = title,
            Description = textValue,
            Time = duration or 4,
        })
    end)
    if not ok then
        legacyNotify(title, textValue, duration)
    end
    print(("[AliceHub] %s | %s"):format(title, textValue))
end

local Window = Library:CreateWindow({
    Title = "AliceHub · Pasar Setan",
    Footer = "Obsidian Edition · runtime resolver",
    Center = true,
    AutoShow = true,
    Resizable = true,
    MobileButtonsSide = "Right",
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Farm = Window:AddTab("Farm", "sprout"),
    Forage = Window:AddTab("Forage", "leaf"),
    Lapak = Window:AddTab("Lapak", "cooking-pot"),
    Pig = Window:AddTab("Kandang", "piggy-bank"),
    Gacha = Window:AddTab("Gacha", "sparkles"),
    ESP = Window:AddTab("ESP", "eye"),
    Teleport = Window:AddTab("Teleport", "map-pin"),
    Utility = Window:AddTab("Utility", "settings-2"),
    Info = Window:AddTab("Info", "info"),
    Settings = Window:AddTab("UI Settings", "settings"),
}

local function markChanged()
    changed()
end

local function bindToggle(group, key, textLabel, tooltip, onChanged)
    group:AddToggle(key, {
        Text = textLabel,
        Default = Settings[key] == true,
        Tooltip = tooltip,
    })
    Toggles[key]:OnChanged(function()
        Settings[key] = Toggles[key].Value
        if onChanged then
            local ok, err = pcall(onChanged, Settings[key])
            if not ok then warn("[AliceHub/UI/" .. key .. "] " .. tostring(err)) end
        end
        markChanged()
    end)
    return Toggles[key]
end

local function bindSlider(group, key, textLabel, minValue, maxValue, rounding, suffix, tooltip, onChanged)
    group:AddSlider(key, {
        Text = textLabel,
        Default = tonumber(Settings[key]) or minValue,
        Min = minValue,
        Max = maxValue,
        Rounding = rounding or 0,
        Suffix = suffix or "",
        Tooltip = tooltip,
    })
    Options[key]:OnChanged(function()
        Settings[key] = Options[key].Value
        if onChanged then
            local ok, err = pcall(onChanged, Settings[key])
            if not ok then warn("[AliceHub/UI/" .. key .. "] " .. tostring(err)) end
        end
        markChanged()
    end)
    return Options[key]
end

local function bindDropdown(group, key, textLabel, values, searchable, tooltip, onChanged)
    group:AddDropdown(key, {
        Values = values,
        Default = Settings[key] or values[1],
        Multi = false,
        Text = textLabel,
        Searchable = searchable == true,
        Tooltip = tooltip,
    })
    Options[key]:OnChanged(function()
        Settings[key] = Options[key].Value
        if onChanged then
            local ok, err = pcall(onChanged, Settings[key])
            if not ok then warn("[AliceHub/UI/" .. key .. "] " .. tostring(err)) end
        end
        markChanged()
    end)
    return Options[key]
end

local function addButton(group, textLabel, func, tooltip, risky)
    return group:AddButton({
        Text = textLabel,
        Func = function()
            local ok, err = pcall(func)
            if not ok then
                notify("AliceHub", textLabel .. " gagal: " .. tostring(err), 6)
            end
        end,
        Tooltip = tooltip,
        DoubleClick = false,
        Risky = risky == true,
    })
end

-- Farm
local FarmAuto = Tabs.Farm:AddLeftGroupbox("Farm Automation", "sprout")
local FarmSetup = Tabs.Farm:AddRightGroupbox("Seed & Timing", "sliders-horizontal")
bindToggle(FarmAuto, "AutoHarvest", "Auto Harvest", "Scan tanaman matang lalu trigger aksi panen.")
bindToggle(FarmAuto, "AutoWater", "Auto Water", "Mendeteksi prompt/objek siram yang tersedia.")
bindToggle(FarmAuto, "AutoPlant", "Auto Plant Seeds", "Menanam pada slot kosong yang dapat di-resolve client.")
bindDropdown(FarmSetup, "SeedFilter", "Seed Filter", {"All Seeds", "Melati", "Kamboja", "Pisang"}, true)
bindSlider(FarmSetup, "PlantDelay", "Plant Delay", 0.05, 3, 2, " s")
bindSlider(FarmSetup, "WaterDelay", "Water Delay", 0.05, 3, 2, " s")
bindSlider(FarmSetup, "HarvestDelay", "Harvest Delay", 0.05, 2, 2, " s")

-- Forage
local ForageMain = Tabs.Forage:AddLeftGroupbox("Collection", "leaf")
local ForageMove = Tabs.Forage:AddRightGroupbox("Search & Movement", "route")
bindToggle(ForageMain, "AutoForage", "Auto Forage Materials", "Nearest-neighbor dari SpawnBahan dengan cooldown memory.")
bindDropdown(ForageMain, "ForageFilter", "Material Filter", {"All", "Melati", "Jamur Kuburan", "Kemenyan", "Kepiting Sungai", "Gagak"}, true)
bindSlider(ForageMove, "ForageDistance", "Forage Distance", 10, 500, 0, " m")
bindSlider(ForageMove, "TravelSpeed", "Travel Speed", 40, 300, 0, "")
bindSlider(ForageMove, "ForageDelay", "Action Delay", 0.05, 2, 2, " s")

-- Lapak / kitchen
local LapakStock = Tabs.Lapak:AddLeftGroupbox("Lapak & Stock", "store")
local Kitchen = Tabs.Lapak:AddRightGroupbox("Kitchen", "cooking-pot")
bindToggle(LapakStock, "AutoRestock", "Auto Restock Shelves")
bindToggle(LapakStock, "AutoBuyIncense", "Auto Buy Incense")
bindDropdown(LapakStock, "IncenseType", "Incense", {"Both", "Dupa", "Pengelaris"}, false)
bindSlider(LapakStock, "IncenseThreshold", "Restock Threshold", 1, 30, 0, "")
bindToggle(Kitchen, "AutoSliceCrows", "Auto Slice Crows")
bindToggle(Kitchen, "AutoCook", "Auto Cook Stove")
bindDropdown(Kitchen, "RecipeFilter", "Recipe", {"All Recipes", "Sate Gagak", "Jamur Rebus", "Tumis Kamboja", "Sate Kepiting", "Pisang Rebus"}, true)
bindSlider(Kitchen, "KitchenDelay", "Kitchen Delay", 0.15, 3, 2, " s")

-- Pig pen
local PigCare = Tabs.Pig:AddLeftGroupbox("Pig Care", "heart-handshake")
local PigBandar = Tabs.Pig:AddRightGroupbox("Bandar Babi", "dice-5")
bindToggle(PigCare, "AutoScrubPigs", "Auto Scrub Pigs")
bindToggle(PigCare, "AutoFeedPigs", "Auto Feed Pigs")
bindSlider(PigCare, "PigDelay", "Care Delay", 0.2, 3, 2, " s")
bindToggle(PigBandar, "AutoRollPigs", "Auto Roll Pigs")
bindDropdown(PigBandar, "PigRollTier", "Roll Tier", {"Biasa", "Langka", "Mitos", "Sultan"}, false)

-- Gacha / chests / quests
local GachaMain = Tabs.Gacha:AddLeftGroupbox("Pusaka & Peti", "gem")
local GachaEvents = Tabs.Gacha:AddRightGroupbox("Events & Quests", "scroll-text")
bindToggle(GachaMain, "AutoRollPusaka", "Auto Roll Pusaka")
bindToggle(GachaMain, "AutoSpiritChest", "Auto Pull Spirit Chests")
bindDropdown(GachaMain, "ChestTier", "Chest Tier", {"Umum", "Langka", "Kuno", "Mistik"}, false)
bindSlider(GachaMain, "GachaDelay", "Gacha Delay", 0.25, 5, 2, " s")
bindToggle(GachaEvents, "AutoWildTuyul", "Auto Wild Tuyul Event", "Mencari TuyulLiar dan mencoba aksi Sate Kepiting yang tersedia.")
bindToggle(GachaEvents, "AutoClaimQuests", "Auto Claim Quests")
bindToggle(GachaEvents, "AutoBalai", "Auto Balai Desa")
addButton(GachaEvents, "Redeem All Client Codes", redeemAllCodes, "Hanya memakai kode yang benar-benar diekspos client; tidak menebak kode.")

-- ESP
local ESPMain = Tabs.ESP:AddLeftGroupbox("Visual Overlays", "eye")
local ESPRange = Tabs.ESP:AddRightGroupbox("Range", "scan")
bindToggle(ESPMain, "CropESP", "Crop ESP")
bindToggle(ESPMain, "ForageESP", "Forage ESP")
bindToggle(ESPMain, "GhostESP", "Ghost / Buyer ESP")
bindToggle(ESPMain, "PigESP", "Pig ESP")
bindSlider(ESPRange, "ESPMaxDistance", "ESP Max Distance", 50, 1000, 0, " studs")

-- Teleports
local TPLeft = Tabs.Teleport:AddLeftGroupbox("Farm & Shops", "map-pin")
local TPRight = Tabs.Teleport:AddRightGroupbox("Village & Gaib", "map")
for _, name in ipairs({"My Kiosk", "My Farm", "My Pig Pen", "Seed Merchant"}) do
    addButton(TPLeft, name, function() teleportNamed(name) end)
end
for _, name in ipairs({"Tool Shop", "Village Hall", "Spirit Chest Area", "Dark Market"}) do
    addButton(TPRight, name, function() teleportNamed(name) end)
end

-- Utilities
local CharacterGroup = Tabs.Utility:AddLeftGroupbox("Character", "person-standing")
local PerformanceGroup = Tabs.Utility:AddRightGroupbox("Performance & Session", "gauge")
bindSlider(CharacterGroup, "WalkSpeed", "WalkSpeed", 16, 200, 0, "", nil, function() applyMovement() end)
bindSlider(CharacterGroup, "JumpPower", "JumpPower", 50, 200, 0, "", nil, function() applyMovement() end)
bindToggle(CharacterGroup, "Noclip", "Noclip", nil, setNoclip)
bindToggle(CharacterGroup, "InfiniteJump", "Infinite Jump", nil, setInfiniteJump)
bindToggle(CharacterGroup, "AntiAFK", "Anti-AFK", nil, setAntiAFK)
bindToggle(PerformanceGroup, "BlackScreen", "Black Screen Mode", "Mematikan 3D rendering; UI Obsidian tetap aktif.", setBlackScreen)
bindToggle(PerformanceGroup, "FPSBooster", "FPS Booster", "Mengurangi efek visual lokal.", setFPSBooster)
bindSlider(PerformanceGroup, "FPSLimit", "FPS Limiter", 10, 240, 0, " FPS", nil, function() applyFPSLimit() end)
addButton(PerformanceGroup, "Server Hop", serverHop)
addButton(PerformanceGroup, "Fast Rejoin", fastRejoin)

-- Info / runtime
local InfoRuntime = Tabs.Info:AddLeftGroupbox("Runtime", "activity")
local InfoTools = Tabs.Info:AddRightGroupbox("Maintenance", "wrench")
InfoRuntime:AddLabel("RuntimeStatus", {
    Text = "Loading runtime status...",
    DoesWrap = true,
})
InfoRuntime:AddLabel("ResolverInfo", {
    Text = "AliceHub menggunakan live object / ProximityPrompt resolver. Hash remote yang berubah tidak di-hardcode untuk aksi yang belum terbukti.",
    DoesWrap = true,
})
addButton(InfoTools, "Refresh Runtime Cache", function()
    refreshPrompts(true)
    GameConfig, BabiConfig, PetiConfig = nil, nil, nil
    pcall(function()
        local m = ReplicatedStorage:FindFirstChild("GameConfig")
        if m then GameConfig = require(m) end
    end)
    pcall(function()
        local m = ReplicatedStorage:FindFirstChild("BabiConfig")
        if m then BabiConfig = require(m) end
    end)
    pcall(function()
        local m = ReplicatedStorage:FindFirstChild("PetiArwahConfig")
        if m then PetiConfig = require(m) end
    end)
    notify("Runtime", "Cache di-refresh.")
end)
addButton(InfoTools, "Save Runtime Snapshot", function() saveConfig(false) end)
addButton(InfoTools, "Load Runtime Snapshot", function()
    if loadConfig(false) then
        for key, toggleObj in pairs(Toggles) do
            if DEFAULTS[key] ~= nil and type(Settings[key]) == "boolean" and toggleObj and toggleObj.SetValue then
                pcall(function() toggleObj:SetValue(Settings[key]) end)
            end
        end
        for key, optionObj in pairs(Options) do
            if DEFAULTS[key] ~= nil and Settings[key] ~= nil and optionObj and optionObj.SetValue then
                pcall(function() optionObj:SetValue(Settings[key]) end)
            end
        end
        applyMovement()
        setNoclip(Settings.Noclip)
        setInfiniteJump(Settings.InfiniteJump)
        setAntiAFK(Settings.AntiAFK)
        setBlackScreen(Settings.BlackScreen)
        setFPSBooster(Settings.FPSBooster)
        applyFPSLimit()
    end
end)

-- UI Settings / Obsidian addons
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddDropdown("NotificationSide", {
    Values = {"Left", "Right"},
    Default = "Right",
    Multi = false,
    Text = "Notification Side",
    Callback = function(value)
        Library:SetNotifySide(value)
    end,
})
MenuGroup:AddDropdown("DPIDropdown", {
    Values = {"75%", "100%", "125%", "150%"},
    Default = Library.IsMobile and "75%" or "100%",
    Multi = false,
    Text = "DPI Scale",
    Callback = function(value)
        local dpi = tonumber((value:gsub("%%", "")))
        if dpi then Library:SetDPIScale(dpi) end
    end,
})
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind",
})
Library.ToggleKeybind = Options.MenuKeybind
bindToggle(MenuGroup, "AutoSave", "Auto Save Runtime Snapshot")

local unloading = false
local function unload(fromLibrary)
    if unloading or not State.Alive then return end
    unloading = true
    State.Alive = false
    saveConfig(true)

    for _, tw in ipairs(State.Tweens) do
        pcall(function() tw:Cancel() end)
    end
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    if noclipConn then pcall(function() noclipConn:Disconnect() end) end
    if infJumpConn then pcall(function() infJumpConn:Disconnect() end) end
    if antiAfkConn then pcall(function() antiAfkConn:Disconnect() end) end

    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    pcall(function() setFPSBooster(false) end)
    pcall(function() ESPRoot:Destroy() end)

    ENV.ALICEHUB_PASAR_SETAN = nil

    if not fromLibrary then
        pcall(function() Library:Unload() end)
    end
    legacyNotify("AliceHub · Pasar Setan", "Unloaded.", 4)
end

addButton(MenuGroup, "Unload AliceHub", function() unload(false) end, nil, true)

Library:OnUnload(function()
    if not unloading then
        unload(true)
    end
end)

if okTheme and type(ThemeManager) == "table" then
    pcall(function()
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetFolder("AliceHub")
        ThemeManager:ApplyToTab(Tabs.Settings)
    end)
else
    MenuGroup:AddLabel("ThemeManager gagal dimuat; UI utama tetap bisa dipakai.", true)
end

if okSave and type(SaveManager) == "table" then
    pcall(function()
        SaveManager:SetLibrary(Library)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({"MenuKeybind", "NotificationSide", "DPIDropdown"})
        SaveManager:SetFolder("AliceHub/PasarSetan")
        SaveManager:BuildConfigSection(Tabs.Settings)
        SaveManager:LoadAutoloadConfig()
    end)
else
    MenuGroup:AddLabel("SaveManager gagal dimuat; runtime JSON fallback tetap aktif.", true)
end

-- Runtime status updater
task.spawn(function()
    while State.Alive do
        local folder = forageFolder()
        local prompts = #refreshPrompts()
        local gameVer = "?"
        if type(GameConfig) == "table" and type(GameConfig.Game) == "table" then
            gameVer = tostring(GameConfig.Game.Version or "?")
        end
        local textValue = ("Game v%s\nPrompts: %d | SpawnBahan: %s\nPlaceId: %s\nJob: %s\nDevice: %s")
            :format(
                gameVer,
                prompts,
                folder and "FOUND" or "MISSING",
                tostring(game.PlaceId),
                string.sub(tostring(game.JobId), 1, 16),
                Library.IsMobile and "Mobile" or "Desktop"
            )
        if Options.RuntimeStatus and Options.RuntimeStatus.SetText then
            pcall(function() Options.RuntimeStatus:SetText(textValue) end)
        end
        task.wait(1.5)
    end
end)

ENV.ALICEHUB_PASAR_SETAN = {
    Settings = Settings,
    State = State,
    Library = Library,
    Window = Window,
    Unload = function() unload(false) end,
    Save = saveConfig,
    Load = loadConfig,
    Refresh = function() return refreshPrompts(true) end,
    Teleport = teleportNamed,
}

-- Apply loaded/autoload settings
applyMovement()
setNoclip(Settings.Noclip)
setInfiniteJump(Settings.InfiniteJump)
setAntiAFK(Settings.AntiAFK)
setBlackScreen(Settings.BlackScreen)
if Settings.FPSBooster then setFPSBooster(true) end
applyFPSLimit()

table.insert(State.Connections, LP.CharacterAdded:Connect(function()
    task.wait(1)
    applyMovement()
end))

notify("AliceHub · Pasar Setan", "Loaded · Obsidian UI aktif.", 5)
