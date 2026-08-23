--====================================================
-- ALICE PASAR SETAN V2
-- Dynamic Remote Resolver via LID
-- GUI: Obsidian
--====================================================

if getgenv().AlicePasarV2 then
    warn("Alice Pasar V2 already loaded")
    return
end

getgenv().AlicePasarV2 = true

--====================================================
-- UI
--====================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

--====================================================
-- SERVICES
--====================================================

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

--====================================================
-- STATE
--====================================================

local Alive = true

local function isAlive()
    return Alive
end

local function getChar()
    return LP.Character
end

local function getHRP()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

--====================================================
-- DYNAMIC REMOTE RESOLVER
--====================================================

local RemoteCache = {}

local function GetRemote(lid)

    if RemoteCache[lid] then
        if RemoteCache[lid].Parent then
            return RemoteCache[lid]
        end
    end

    for _, obj in ipairs(RS:GetDescendants()) do

        if (
            obj:IsA("RemoteEvent")
            or obj:IsA("RemoteFunction")
        ) then

            local id = obj:GetAttribute("LID")

            if id == lid then

                RemoteCache[lid] = obj

                print(
                    "[Alice V2]",
                    lid,
                    "=>",
                    obj:GetFullName()
                )

                return obj
            end
        end
    end

    warn("[Alice V2] Remote not found:", lid)

    return nil
end

--====================================================
-- KNOWN REMOTES
--====================================================

local function RefreshRemotes()

    RemoteCache = {}

    GetRemote("Tanam")
    GetRemote("Siram")
    GetRemote("Panen")
    GetRemote("CookStove")
    GetRemote("HotbarSimpan")
    GetRemote("HotbarMuat")
    GetRemote("ShopPoll")
    GetRemote("ShopBuy")
    GetRemote("PusakaPoll")
    GetRemote("StoragePoll")
    GetRemote("StorageMove")

end

--====================================================
-- MOVE
--====================================================

local function MoveTo(pos)

    local hrp = getHRP()

    if not hrp then
        return false
    end

    hrp.CFrame =
        CFrame.new(
            pos + Vector3.new(0, 2.5, 0)
        )

    hrp.AssemblyLinearVelocity = Vector3.zero

    task.wait(0.15)

    return true
end

--====================================================
-- MATERIAL DATA
--====================================================

local MATERIALS = {
    Melati = true,
    Kemenyan = true,
    Dupa = true,
    Gagak = true,
    JamurKuburan = true,
    KepitingSungai = true
}

local function normalize(text)

    text = tostring(text or "")

    return text:
        lower():
        gsub("%s+", "")
end

--====================================================
-- AUTO FORAGE
--====================================================

local function IsMaterialPrompt(prompt)

    if not prompt:IsA("ProximityPrompt") then
        return false
    end

    if not prompt.Enabled then
        return false
    end

    local text =
        tostring(prompt.Name)
        .. " "
        .. tostring(prompt.ActionText)
        .. " "
        .. tostring(prompt.ObjectText)
        .. " "
        .. tostring(prompt.Parent and prompt.Parent.Name or "")

    local test = normalize(text)

    -- Harus berkaitan dengan pickup
    local pickup =
        test:find("ambil", 1, true)
        or test:find("pickup", 1, true)
        or test:find("collect", 1, true)

    if not pickup then
        return false
    end

    local filter =
        Options.MaterialFilter
        and Options.MaterialFilter.Value

    for material in pairs(MATERIALS) do

        local enabled = true

        if type(filter) == "table" then
            enabled = filter[material] == true
        end

        if enabled then

            if test:find(
                normalize(material),
                1,
                true
            ) then

                return true
            end
        end
    end

    return false
end

local function PromptPosition(prompt)

    local parent = prompt.Parent

    if not parent then
        return nil
    end

    if parent:IsA("BasePart") then
        return parent.Position
    end

    if parent:IsA("Attachment") then
        return parent.WorldPosition
    end

    local model =
        parent:FindFirstAncestorOfClass("Model")

    if model then
        return model:GetPivot().Position
    end

    return nil
end

local function FindMaterials()

    local hrp = getHRP()

    if not hrp then
        return {}
    end

    local found = {}

    for _, obj in ipairs(workspace:GetDescendants()) do

        if IsMaterialPrompt(obj) then

            local pos = PromptPosition(obj)

            if pos then

                table.insert(found, {
                    Prompt = obj,
                    Position = pos,
                    Distance =
                        (hrp.Position - pos).Magnitude
                })

            end
        end
    end

    table.sort(found, function(a, b)
        return a.Distance < b.Distance
    end)

    return found
end

local function CollectPrompt(data)

    if not data
    or not data.Prompt
    or not data.Prompt.Parent
    or not data.Prompt.Enabled then
        return false
    end

    MoveTo(data.Position)

    task.wait(0.15)

    local ok = pcall(function()

        data.Prompt:InputHoldBegin()

        task.wait(
            math.max(
                data.Prompt.HoldDuration,
                0.05
            )
        )

        fireproximityprompt(data.Prompt)

        data.Prompt:InputHoldEnd()

    end)

    return ok
end

--====================================================
-- AUTO TANAM
--====================================================

local function FindSeed()

    local selected =
        Options.SeedType
        and Options.SeedType.Value
        or "Semua"

    local containers = {
        LP.Backpack,
        getChar()
    }

    for _, container in ipairs(containers) do

        if container then

            for _, tool in ipairs(container:GetChildren()) do

                if tool:IsA("Tool") then

                    local isSeed =
                        tool:GetAttribute("IsSeed")

                    local name =
                        normalize(tool.Name)

                    if isSeed then

                        if selected == "Semua" then
                            return tool
                        end

                        if name:find(
                            normalize(selected),
                            1,
                            true
                        ) then

                            return tool
                        end

                    end
                end
            end
        end
    end

    return nil
end

local function FindMyPlot()

    local folder =
        workspace:FindFirstChild("LahanPlot")

    if not folder then
        return nil
    end

    for _, obj in ipairs(folder:GetChildren()) do

        local owner =
            obj:GetAttribute("Owner")

        local ownerId =
            obj:GetAttribute("OwnerId")

        if owner == LP.UserId
        or ownerId == LP.UserId then

            return obj
        end
    end

    return nil
end

local function AutoPlantOnce()

    local Tanam =
        GetRemote("Tanam")

    if not Tanam then
        return "remote_missing"
    end

    local seed =
        FindSeed()

    if not seed then
        return "no_seed"
    end

    local plot =
        FindMyPlot()

    if not plot then
        return "no_plot"
    end

    local hum =
        getHumanoid()

    if hum then
        pcall(function()
            hum:EquipTool(seed)
        end)
    end

    task.wait(0.25)

    local size = plot.Size

    local offsetX =
        (math.random() - 0.5)
        * math.max(size.X - 4, 2)

    local offsetZ =
        (math.random() - 0.5)
        * math.max(size.Z - 4, 2)

    local pos =
        plot.Position
        + Vector3.new(
            offsetX,
            1,
            offsetZ
        )

    MoveTo(pos)

    task.wait(0.2)

    local ok = pcall(function()

        Tanam:FireServer(pos)

    end)

    return ok and "planted" or "failed"
end

--====================================================
-- PLANT SCANNER
--====================================================

local function FindPlants()

    local list = {}

    local folder =
        workspace:FindFirstChild("LahanPlot")

    if not folder then
        return list
    end

    for _, obj in ipairs(folder:GetDescendants()) do

        if obj:IsA("BasePart") then

            local plantKey =
                obj:GetAttribute("PlantKey")

            local owner =
                obj:GetAttribute("OwnerId")

            if plantKey
            and (
                owner == nil
                or owner == LP.UserId
            ) then

                table.insert(list, obj)

            end
        end
    end

    return list
end

--====================================================
-- AUTO SIRAM
--====================================================

local function FindWaterTool()

    local containers = {
        LP.Backpack,
        getChar()
    }

    for _, container in ipairs(containers) do

        if container then

            for _, obj in ipairs(container:GetChildren()) do

                if obj:IsA("Tool")
                and obj.Name == "PenyiramTanaman" then

                    return obj

                end
            end
        end
    end

end

local function WaterPlants()

    local Siram =
        GetRemote("Siram")

    if not Siram then
        return
    end

    local tool =
        FindWaterTool()

    if not tool then
        return
    end

    local hum =
        getHumanoid()

    if hum then
        pcall(function()
            hum:EquipTool(tool)
        end)
    end

    for _, plant in ipairs(FindPlants()) do

        if not Toggles.AutoSiram.Value then
            break
        end

        local wet =
            plant:GetAttribute("Wet")

        local air =
            tonumber(
                plant:GetAttribute("AirSisa")
            ) or 0

        local maxAir =
            tonumber(
                plant:GetAttribute("AirMax")
            ) or 0

        if wet ~= true
        or (
            maxAir > 0
            and air < maxAir
        ) then

            MoveTo(plant.Position)

            task.wait(0.15)

            -- berdasarkan behavior script lama:
            -- beberapa FireServer untuk isi air
            for i = 1, 5 do

                if not Toggles.AutoSiram.Value then
                    break
                end

                pcall(function()
                    Siram:FireServer()
                end)

                task.wait(
                    Options.SiramDelay.Value
                )

            end
        end
    end
end

--====================================================
-- AUTO HARVEST
--====================================================

local function HarvestPlants()

    local Panen =
        GetRemote("Panen")

    if not Panen then
        return
    end

    for _, plant in ipairs(FindPlants()) do

        if not Toggles.AutoHarvest.Value then
            break
        end

        local ready =
            plant:GetAttribute("Ready")

        local harvested =
            plant:GetAttribute("Harvested")

        if ready == true
        and harvested ~= true then

            MoveTo(plant.Position)

            task.wait(0.15)

            pcall(function()

                Panen:FireServer(plant)

            end)

            task.wait(
                Options.HarvestDelay.Value
            )
        end
    end
end

--====================================================
-- AUTO COOK
--====================================================

local function Cook(menu)

    local CookStove =
        GetRemote("CookStove")

    if not CookStove then
        return
    end

    local ok, result =
        pcall(function()

            return CookStove:
                InvokeServer(menu)

        end)

    if ok then

        print(
            "[Alice Cook]",
            menu,
            result
        )

    end
end

--====================================================
-- WINDOW
--====================================================

local Window =
    Library:CreateWindow({
        Title = "Alice Pasar Setan V2",
        Footer = "Dynamic LID Remote Resolver",
        NotifySide = "Right",
        ShowCustomCursor = true
    })

local Main =
    Window:AddTab(
        "Main",
        "house"
    )

--====================================================
-- FORAGE UI
--====================================================

local ForageBox =
    Main:AddLeftGroupbox(
        "Auto Forage"
    )

ForageBox:AddToggle(
    "AutoForage",
    {
        Text = "Auto Collect Material",
        Default = false
    }
)

ForageBox:AddDropdown(
    "MaterialFilter",
    {
        Values = {
            "Melati",
            "Kemenyan",
            "Dupa",
            "Gagak",
            "JamurKuburan",
            "KepitingSungai"
        },

        Default = {
            "Melati",
            "Kemenyan",
            "Dupa",
            "Gagak",
            "JamurKuburan",
            "KepitingSungai"
        },

        Multi = true,

        Text = "Material"
    }
)

ForageBox:AddSlider(
    "CollectDelay",
    {
        Text = "Collect Delay",
        Default = 0.5,
        Min = 0.1,
        Max = 5,
        Rounding = 1
    }
)

--====================================================
-- KEBUN UI
--====================================================

local KebunBox =
    Main:AddRightGroupbox(
        "Auto Kebun"
    )

KebunBox:AddToggle(
    "AutoTanam",
    {
        Text = "Auto Tanam",
        Default = false
    }
)

KebunBox:AddDropdown(
    "SeedType",
    {
        Values = {
            "Semua",
            "Melati",
            "Kamboja",
            "Pisang"
        },

        Default = "Semua",

        Text = "Bibit"
    }
)

KebunBox:AddSlider(
    "PlantDelay",
    {
        Text = "Tanam Delay",
        Default = 5,
        Min = 1,
        Max = 30,
        Rounding = 0
    }
)

KebunBox:AddToggle(
    "AutoSiram",
    {
        Text = "Auto Siram",
        Default = false
    }
)

KebunBox:AddSlider(
    "SiramDelay",
    {
        Text = "Siram Delay",
        Default = 0.3,
        Min = 0.1,
        Max = 3,
        Rounding = 1
    }
)

KebunBox:AddToggle(
    "AutoHarvest",
    {
        Text = "Auto Panen",
        Default = false
    }
)

KebunBox:AddSlider(
    "HarvestDelay",
    {
        Text = "Panen Delay",
        Default = 0.5,
        Min = 0.1,
        Max = 5,
        Rounding = 1
    }
)

--====================================================
-- COOK UI
--====================================================

local CookBox =
    Main:AddLeftGroupbox(
        "Auto Cook"
    )

CookBox:AddToggle(
    "AutoCook",
    {
        Text = "Auto Cook",
        Default = false
    }
)

CookBox:AddDropdown(
    "CookMenu",
    {
        Values = {
            "Bakar",
            "Rebus",
            "TumisKamboja",
            "SateKepiting",
            "PisangRebus"
        },

        Default = "Rebus",

        Text = "Menu"
    }
)

CookBox:AddSlider(
    "CookDelay",
    {
        Text = "Cook Delay",
        Default = 5,
        Min = 1,
        Max = 30,
        Rounding = 0
    }
)

--====================================================
-- DEBUG
--====================================================

local DebugBox =
    Main:AddRightGroupbox(
        "Debug"
    )

DebugBox:AddButton(
    "Refresh Remotes",
    function()

        RefreshRemotes()

        Library:Notify({
            Title = "Alice V2",
            Description = "Remote cache refreshed",
            Time = 3
        })

    end
)

DebugBox:AddButton(
    "Print Remote Mapping",
    function()

        print("========= ALICE REMOTES =========")

        for _, name in ipairs({
            "Tanam",
            "Siram",
            "Panen",
            "CookStove",
            "ShopPoll",
            "ShopBuy",
            "StoragePoll",
            "StorageMove",
            "PusakaPoll"
        }) do

            local r =
                GetRemote(name)

            print(
                name,
                "=",
                r and r:GetFullName()
                or "NOT FOUND"
            )

        end

        print("===============================")

    end
)

--====================================================
-- SETTINGS
--====================================================

local Settings =
    Window:AddTab(
        "UI Settings",
        "settings"
    )

local MenuGroup =
    Settings:AddLeftGroupbox(
        "Menu"
    )

MenuGroup:
    AddLabel("Menu bind"):
    AddKeyPicker(
        "MenuKeybind",
        {
            Default = "RightShift",
            NoUI = true,
            Text = "Menu keybind"
        }
    )

Library.ToggleKeybind =
    Options.MenuKeybind

MenuGroup:AddButton(
    "Unload",
    function()
        Library:Unload()
    end
)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({
    "MenuKeybind"
})

ThemeManager:SetFolder(
    "AlicePasarV2"
)

SaveManager:SetFolder(
    "AlicePasarV2/config"
)

SaveManager:
    BuildConfigSection(Settings)

ThemeManager:
    ApplyToTab(Settings)

SaveManager:
    LoadAutoloadConfig()

--====================================================
-- AUTO FORAGE LOOP
--====================================================

task.spawn(function()

    while isAlive() do

        if Toggles.AutoForage.Value then

            local materials =
                FindMaterials()

            for _, data in ipairs(materials) do

                if not Toggles.AutoForage.Value then
                    break
                end

                CollectPrompt(data)

                task.wait(
                    Options.CollectDelay.Value
                )
            end
        end

        task.wait(0.5)
    end

end)

--====================================================
-- AUTO TANAM LOOP
--====================================================

task.spawn(function()

    while isAlive() do

        if Toggles.AutoTanam.Value then

            local result =
                AutoPlantOnce()

            print(
                "[Alice Tanam]",
                result
            )

            task.wait(
                Options.PlantDelay.Value
            )

        else

            task.wait(1)

        end
    end

end)

--====================================================
-- AUTO SIRAM LOOP
--====================================================

task.spawn(function()

    while isAlive() do

        if Toggles.AutoSiram.Value then

            WaterPlants()

        end

        task.wait(1)

    end

end)

--====================================================
-- AUTO HARVEST LOOP
--====================================================

task.spawn(function()

    while isAlive() do

        if Toggles.AutoHarvest.Value then

            HarvestPlants()

        end

        task.wait(1)

    end

end)

--====================================================
-- AUTO COOK LOOP
--====================================================

task.spawn(function()

    while isAlive() do

        if Toggles.AutoCook.Value then

            Cook(
                Options.CookMenu.Value
            )

            task.wait(
                Options.CookDelay.Value
            )

        else

            task.wait(1)

        end
    end

end)

--====================================================
-- UNLOAD
--====================================================

Library:OnUnload(function()

    Alive = false

    getgenv().AlicePasarV2 = nil

end)

--====================================================
-- STARTUP
--====================================================

RefreshRemotes()

Library:Notify({
    Title = "Alice Pasar Setan V2",
    Description = "LID resolver loaded!",
    Time = 5
})

print("======================================")
print(" Alice Pasar Setan V2 Loaded")
print(" Dynamic LID Remote Resolver")
print("======================================")
