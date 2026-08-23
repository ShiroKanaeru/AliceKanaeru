--====================================================
-- ALICE PASAR SETAN V2.1
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

local LP = Players.LocalPlayer

--====================================================
-- STATE
--====================================================

local Alive = true
local RemoteCache = {}

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
-- REMOTE RESOLVER
--====================================================

local function GetRemote(lid)

    local cached = RemoteCache[lid]

    if cached and cached.Parent then
        return cached
    end

    for _, obj in ipairs(RS:GetDescendants()) do

        if (
            obj:IsA("RemoteEvent")
            or obj:IsA("RemoteFunction")
        ) and obj:GetAttribute("LID") == lid then

            RemoteCache[lid] = obj

            print(
                "[Alice Remote]",
                lid,
                "=>",
                obj:GetFullName()
            )

            return obj
        end
    end

    warn("[Alice] Remote tidak ditemukan:", lid)

    return nil
end

local function RefreshRemotes()

    RemoteCache = {}

    local list = {
        "Tanam",
        "Siram",
        "Panen",
        "CookStove",
        "HotbarSimpan",
        "HotbarMuat",
        "ShopPoll",
        "ShopBuy",
        "GaibShopPoll",
        "GaibBuy",
        "GaibUse",
        "PusakaPoll",
        "StoragePoll",
        "StorageMove",
        "QuestFetch",
        "QuestClaim"
    }

    for _, lid in ipairs(list) do
        GetRemote(lid)
    end
end

--====================================================
-- MOVEMENT
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

    hrp.AssemblyLinearVelocity =
        Vector3.zero

    task.wait(0.15)

    return true
end

--====================================================
-- GENERAL PROMPT
--====================================================

local function PromptPosition(prompt)

    if not prompt or not prompt.Parent then
        return nil
    end

    local parent = prompt.Parent

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

local function FirePrompt(prompt)

    if not prompt
    or not prompt.Parent
    or not prompt.Enabled then
        return false
    end

    return pcall(function()

        prompt:InputHoldBegin()

        task.wait(
            math.max(
                prompt.HoldDuration,
                0.05
            )
        )

        fireproximityprompt(prompt)

        prompt:InputHoldEnd()

    end)
end

--====================================================
-- STRING
--====================================================

local function normalize(text)

    return tostring(text or "")
        :lower()
        :gsub("%s+", "")
end

--====================================================
-- AUTO FORAGE
--====================================================

local MATERIALS = {
    Melati = true,
    Kemenyan = true,
    Dupa = true,
    Gagak = true,
    JamurKuburan = true,
    KepitingSungai = true
}

local function IsMaterialPrompt(prompt)

    if not prompt:IsA("ProximityPrompt")
    or not prompt.Enabled then
        return false
    end

    local text =
        tostring(prompt.Name)
        .. " "
        .. tostring(prompt.ActionText)
        .. " "
        .. tostring(prompt.ObjectText)
        .. " "
        .. tostring(
            prompt.Parent
            and prompt.Parent.Name
            or ""
        )

    local lower = normalize(text)

    local pickup =
        lower:find("ambil", 1, true)
        or lower:find("pickup", 1, true)
        or lower:find("collect", 1, true)

    if not pickup then
        return false
    end

    local filter =
        Options.MaterialFilter
        and Options.MaterialFilter.Value

    for material in pairs(MATERIALS) do

        local enabled = true

        if type(filter) == "table" then
            enabled =
                filter[material] == true
        end

        if enabled
        and lower:find(
            normalize(material),
            1,
            true
        ) then
            return true
        end
    end

    return false
end

local function FindMaterials()

    local hrp = getHRP()

    if not hrp then
        return {}
    end

    local result = {}

    for _, obj in ipairs(
        workspace:GetDescendants()
    ) do

        if IsMaterialPrompt(obj) then

            local pos =
                PromptPosition(obj)

            if pos then

                result[#result + 1] = {
                    Prompt = obj,
                    Position = pos,
                    Distance =
                        (hrp.Position - pos).Magnitude
                }

            end
        end
    end

    table.sort(
        result,
        function(a, b)
            return a.Distance < b.Distance
        end
    )

    return result
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

    return FirePrompt(data.Prompt)
end

--====================================================
-- PLOT
--====================================================

local function FindMyPlot()

    local folder =
        workspace:FindFirstChild("LahanPlot")

    if not folder then
        return nil
    end

    for _, obj in ipairs(
        folder:GetChildren()
    ) do

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

--====================================================
-- SEED
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

            for _, tool in ipairs(
                container:GetChildren()
            ) do

                if tool:IsA("Tool")
                and tool:GetAttribute("IsSeed") then

                    if selected == "Semua" then
                        return tool
                    end

                    if normalize(tool.Name):find(
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

    return nil
end

--====================================================
-- AUTO TANAM
--====================================================

local function AutoPlantOnce()

    local Tanam = GetRemote("Tanam")

    if not Tanam then
        return "remote_missing"
    end

    local seed = FindSeed()

    if not seed then
        return "no_seed"
    end

    local plot = FindMyPlot()

    if not plot then
        return "no_plot"
    end

    local hum = getHumanoid()

    if hum then
        pcall(function()
            hum:EquipTool(seed)
        end)
    end

    task.wait(0.25)

    local size = plot.Size

    local x =
        (math.random() - 0.5)
        * math.max(size.X - 4, 2)

    local z =
        (math.random() - 0.5)
        * math.max(size.Z - 4, 2)

    local pos =
        plot.Position
        + Vector3.new(x, 1, z)

    MoveTo(pos)

    task.wait(0.2)

    local ok =
        pcall(function()
            Tanam:FireServer(pos)
        end)

    return ok
        and "planted"
        or "failed"
end

--====================================================
-- PLANTS
--====================================================

local function FindPlants()

    local result = {}

    local folder =
        workspace:FindFirstChild("LahanPlot")

    if not folder then
        return result
    end

    for _, obj in ipairs(
        folder:GetDescendants()
    ) do

        if obj:IsA("BasePart")
        and obj:GetAttribute("PlantKey") then

            local owner =
                obj:GetAttribute("OwnerId")

            if owner == nil
            or owner == LP.UserId then

                result[#result + 1] =
                    obj
            end
        end
    end

    return result
end

--====================================================
-- WATER TOOL
--====================================================

local function FindWaterTool()

    local containers = {
        LP.Backpack,
        getChar()
    }

    for _, container in ipairs(containers) do

        if container then

            for _, obj in ipairs(
                container:GetChildren()
            ) do

                if obj:IsA("Tool")
                and obj.Name
                == "PenyiramTanaman" then

                    return obj
                end
            end
        end
    end

    return nil
end

--====================================================
-- AUTO SIRAM
--====================================================

local function WaterPlants()

    local Siram = GetRemote("Siram")

    if not Siram then
        return
    end

    local tool = FindWaterTool()

    if not tool then
        return
    end

    local hum = getHumanoid()

    if hum then
        pcall(function()
            hum:EquipTool(tool)
        end)
    end

    for _, plant in ipairs(
        FindPlants()
    ) do

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

    local Panen = GetRemote("Panen")

    if not Panen then
        return
    end

    for _, plant in ipairs(
        FindPlants()
    ) do

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
        return "remote_missing"
    end

    local ok, response =
        pcall(function()

            return CookStove:
                InvokeServer(menu)

        end)

    if not ok then
        return "error"
    end

    return response
end

--====================================================
-- AUTO SERVE
--====================================================

local function FindMyKios()

    local folder =
        workspace:FindFirstChild("KiosAktif")

    if not folder then
        return nil
    end

    local named =
        folder:FindFirstChild(
            "Kios_" .. LP.Name
        )

    if named then
        return named
    end

    for _, kios in ipairs(
        folder:GetChildren()
    ) do

        local owner =
            kios:GetAttribute("Owner")

        local ownerId =
            kios:GetAttribute("OwnerId")

        if owner == LP.UserId
        or ownerId == LP.UserId then
            return kios
        end
    end

    return nil
end

local function FindTakePrompt(
    kios,
    keyword
)

    keyword =
        string.lower(keyword)

    for _, obj in ipairs(
        kios:GetDescendants()
    ) do

        if obj:IsA("ProximityPrompt")
        and obj.Enabled then

            local text =
                string.lower(
                    tostring(obj.ActionText)
                    .. " "
                    .. tostring(obj.ObjectText)
                )

            if text:find(
                "ambil",
                1,
                true
            )
            and text:find(
                keyword,
                1,
                true
            ) then

                return obj
            end
        end
    end

    return nil
end

local function FindReadyGhost(kios)

    local folder =
        workspace:FindFirstChild("Arwah")

    if not folder then
        return nil
    end

    local kiosPos =
        kios:GetPivot().Position

    local closest = nil
    local closestDist = math.huge

    for _, ghost in ipairs(
        folder:GetChildren()
    ) do

        if ghost:IsA("Model") then

            local ghostPos =
                ghost:GetPivot().Position

            local dist =
                (ghostPos - kiosPos).Magnitude

            if dist <= Options.ServeRadius.Value
            and dist < closestDist then

                for _, prompt in ipairs(
                    ghost:GetDescendants()
                ) do

                    if prompt:IsA(
                        "ProximityPrompt"
                    )
                    and prompt.Enabled
                    and tostring(
                        prompt.ActionText
                    ):find(
                        "Beri ",
                        1,
                        true
                    ) then

                        closest = {
                            Ghost = ghost,
                            Prompt = prompt,
                            Position = ghostPos
                        }

                        closestDist = dist

                        break
                    end
                end
            end
        end
    end

    return closest
end

local function GetRequestedItem(
    actionText
)

    local text =
        tostring(actionText or "")

    text =
        text:gsub(
            "^Beri%s+",
            ""
        )

    if text:find(
        "Jamur Rebus",
        1,
        true
    ) then
        return "Jamur Rebus"

    elseif text:find(
        "Sate Gagak",
        1,
        true
    ) then
        return "Sate Gagak"

    elseif text:find(
        "Bunga Melati",
        1,
        true
    ) then
        return "Melati"

    elseif text:find(
        "Sate Kepiting",
        1,
        true
    ) then
        return "Sate Kepiting"

    elseif text:find(
        "Tumis Kamboja",
        1,
        true
    ) then
        return "Tumis Kamboja"

    elseif text:find(
        "Pisang Raja Rebus",
        1,
        true
    ) then
        return "Pisang Raja Rebus"

    elseif text:find(
        "Dupa",
        1,
        true
    ) then
        return "Dupa"

    elseif text:find(
        "Kamboja",
        1,
        true
    ) then
        return "Kamboja"

    elseif text:find(
        "Melati",
        1,
        true
    ) then
        return "Melati"
    end

    return text
end

local function ServeOnce()

    local kios = FindMyKios()

    if not kios then
        return "no_kios"
    end

    local ghost =
        FindReadyGhost(kios)

    if not ghost then
        return "no_ghost"
    end

    local requested =
        GetRequestedItem(
            ghost.Prompt.ActionText
        )

    if requested == "" then
        return "unknown_item"
    end

    local takePrompt =
        FindTakePrompt(
            kios,
            requested:lower()
        )

    if not takePrompt then
        return "item_not_found: "
            .. requested
    end

    -- kosongkan tangan
    local char = getChar()

    if char then
        for _, tool in ipairs(
            char:GetChildren()
        ) do

            if tool:IsA("Tool") then
                tool.Parent = LP.Backpack
            end
        end
    end

    task.wait(0.2)

    local takePos =
        PromptPosition(takePrompt)

    if takePos then
        MoveTo(takePos)
    end

    task.wait(0.2)

    FirePrompt(takePrompt)

    task.wait(0.7)

    if not ghost.Prompt.Parent
    or not ghost.Prompt.Enabled then
        return "ghost_changed"
    end

    MoveTo(
        ghost.Position
        + Vector3.new(0, 0, 3)
    )

    task.wait(0.25)

    local coinsBefore = 0

    local leaderstats =
        LP:FindFirstChild("leaderstats")

    local coin =
        leaderstats
        and (
            leaderstats:FindFirstChild("Koin")
            or leaderstats:FindFirstChild("Coins")
        )

    if coin then
        coinsBefore = coin.Value
    end

    local ok =
        FirePrompt(
            ghost.Prompt
        )

    task.wait(1)

    local coinsAfter =
        coin and coin.Value
        or coinsBefore

    if ok
    and coinsAfter > coinsBefore then

        return
            "served +"
            .. tostring(
                coinsAfter - coinsBefore
            )
    end

    return ok
        and "served"
        or "failed"
end

--====================================================
-- WINDOW
--====================================================

local Window =
    Library:CreateWindow({
        Title = "Alice Pasar Setan V2.1",
        Footer = "AliceHub • Dynamic LID Resolver",
        NotifySide = "Right",
        ShowCustomCursor = true
    })

local Main =
    Window:AddTab(
        "Main",
        "house"
    )

--====================================================
-- FORAGE GUI
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
-- KEBUN GUI
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
-- COOK GUI
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
-- SERVE GUI
--====================================================

local ServeBox =
    Main:AddRightGroupbox(
        "Auto Serve"
    )

ServeBox:AddToggle(
    "AutoServe",
    {
        Text = "Auto Serve Arwah",
        Default = false
    }
)

ServeBox:AddSlider(
    "ServeDelay",
    {
        Text = "Serve Delay",
        Default = 3,
        Min = 1,
        Max = 15,
        Rounding = 0
    }
)

ServeBox:AddSlider(
    "ServeRadius",
    {
        Text = "Ghost Radius",
        Default = 35,
        Min = 10,
        Max = 100,
        Rounding = 0
    }
)

--====================================================
-- DEBUG GUI
--====================================================

local DebugBox =
    Main:AddLeftGroupbox(
        "Debug / Remote"
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

        print(
            "========== ALICE REMOTES =========="
        )

        for _, name in ipairs({
            "Tanam",
            "Siram",
            "Panen",
            "CookStove",
            "HotbarSimpan",
            "HotbarMuat",
            "ShopPoll",
            "ShopBuy",
            "GaibShopPoll",
            "GaibBuy",
            "GaibUse",
            "PusakaPoll",
            "StoragePoll",
            "StorageMove",
            "QuestFetch",
            "QuestClaim"
        }) do

            local remote =
                GetRemote(name)

            print(
                name,
                "=",
                remote
                and remote:GetFullName()
                or "NOT FOUND"
            )
        end

        print(
            "=================================="
        )
    end
)

--====================================================
-- UI SETTINGS
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
    "AlicePasar"
)

SaveManager:SetFolder(
    "AlicePasar/config"
)

SaveManager:
    BuildConfigSection(Settings)

ThemeManager:
    ApplyToTab(Settings)

SaveManager:
    LoadAutoloadConfig()

--====================================================
-- FORAGE LOOP
--====================================================

task.spawn(function()

    while isAlive() do

        if Toggles.AutoForage.Value then

            local list =
                FindMaterials()

            for _, data in ipairs(list) do

                if not Toggles.AutoForage.Value
                or not isAlive() then
                    break
                end

                CollectPrompt(data)

                task.wait(
                    Options.CollectDelay.Value
                )
            end

        else
            task.wait(0.5)
        end
    end

end)

--====================================================
-- PLANT LOOP
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
-- WATER LOOP
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
-- HARVEST LOOP
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
-- COOK LOOP
--====================================================

task.spawn(function()

    while isAlive() do

        if Toggles.AutoCook.Value then

            local result =
                Cook(
                    Options.CookMenu.Value
                )

            print(
                "[Alice Cook]",
                Options.CookMenu.Value,
                result
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
-- SERVE LOOP
--====================================================

task.spawn(function()

    while isAlive() do

        if Toggles.AutoServe.Value then

            local result =
                ServeOnce()

            print(
                "[Alice Serve]",
                result
            )

            task.wait(
                Options.ServeDelay.Value
            )

        else
            task.wait(1)
        end
    end

end)

--====================================================
-- CLEANUP
--====================================================

Library:OnUnload(function()

    Alive = false

    getgenv().AlicePasarV2 = nil

end)

--====================================================
-- START
--====================================================

RefreshRemotes()

Library:Notify({
    Title = "Alice Pasar Setan V2.1",
    Description = "All systems loaded!",
    Time = 5
})

print("======================================")
print(" ALICE PASAR SETAN V2.1")
print(" Auto Forage")
print(" Auto Tanam")
print(" Auto Siram")
print(" Auto Panen")
print(" Auto Cook")
print(" Auto Serve")
print(" Dynamic LID Remote Resolver")
print("======================================")
