--====================================================
-- ALICE PASAR SETAN - FUNCTION DUMPER V2
-- Local/read-only module function inspection
--====================================================

local RS = game:GetService("ReplicatedStorage")

local output = {}
local visited = {}

local function add(text)
    text = tostring(text)
    table.insert(output, text)
    print(text)
end

local function indent(n)
    return string.rep("    ", n)
end

local function serialize(value, depth)
    depth = depth or 0

    local t = typeof(value)

    if t == "nil" then
        return "nil"

    elseif t == "string" then
        return string.format("%q", value)

    elseif t == "number" or t == "boolean" then
        return tostring(value)

    elseif t == "Vector3"
        or t == "Vector2"
        or t == "CFrame"
        or t == "Color3"
        or t == "UDim"
        or t == "UDim2"
        or t == "BrickColor"
        or t == "EnumItem"
        or t == "NumberRange"
    then
        return tostring(value)

    elseif t == "Instance" then
        return string.format(
            "<Instance %s | %s>",
            value.ClassName,
            value:GetFullName()
        )

    elseif t == "function" then
        return "<function>"

    elseif t == "thread" then
        return "<thread>"

    elseif t == "userdata" then
        return "<userdata>"

    elseif t ~= "table" then
        return "<" .. t .. ": " .. tostring(value) .. ">"
    end

    if visited[value] then
        return "<circular>"
    end

    visited[value] = true

    local keys = {}

    for k in pairs(value) do
        table.insert(keys, k)
    end

    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    local parts = {"{"}

    for _, k in ipairs(keys) do
        table.insert(
            parts,
            "\n"
            .. indent(depth + 1)
            .. "["
            .. serialize(k, 0)
            .. "] = "
            .. serialize(value[k], depth + 1)
            .. ","
        )
    end

    if #keys > 0 then
        table.insert(parts, "\n" .. indent(depth))
    end

    table.insert(parts, "}")

    visited[value] = nil

    return table.concat(parts)
end

local function getModule(name)
    local obj = RS:FindFirstChild(name)

    if obj and obj:IsA("ModuleScript") then
        return obj
    end

    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == name then
            return v
        end
    end

    return nil
end

local function requireSafe(name)
    local module = getModule(name)

    if not module then
        add("[ERROR] Module not found: " .. name)
        return nil
    end

    local ok, result = pcall(function()
        return require(module)
    end)

    if not ok then
        add("[ERROR] Require failed: " .. name)
        add(result)
        return nil
    end

    return result
end

local function callFunction(label, fn, ...)
    add("")
    add("--------------------------------------------------")
    add("CALL: " .. label)
    add("--------------------------------------------------")

    if type(fn) ~= "function" then
        add("NOT A FUNCTION")
        return
    end

    local args = {...}

    local ok, result1, result2, result3, result4 =
        pcall(function()
            return fn(table.unpack(args))
        end)

    if not ok then
        add("ERROR:")
        add(result1)
        return
    end

    visited = {}

    add("RETURN #1:")
    add(serialize(result1, 0))

    if result2 ~= nil then
        visited = {}
        add("RETURN #2:")
        add(serialize(result2, 0))
    end

    if result3 ~= nil then
        visited = {}
        add("RETURN #3:")
        add(serialize(result3, 0))
    end

    if result4 ~= nil then
        visited = {}
        add("RETURN #4:")
        add(serialize(result4, 0))
    end
end

add("==================================================")
add(" ALICE PASAR SETAN FUNCTION DUMPER V2")
add("==================================================")

--====================================================
-- REMOTE REGISTRY
--====================================================

local RemoteRegistry = requireSafe("RemoteRegistry")

if RemoteRegistry then
    callFunction(
        "RemoteRegistry.dump()",
        RemoteRegistry.dump
    )

    if type(RemoteRegistry.wadah) == "function" then
        callFunction(
            "RemoteRegistry.wadah()",
            RemoteRegistry.wadah
        )
    end

    if type(RemoteRegistry.folder) == "function" then
        callFunction(
            "RemoteRegistry.folder()",
            RemoteRegistry.folder
        )
    end
end

--====================================================
-- PUSAKA CONFIG
--====================================================

local PusakaConfig = requireSafe("PusakaConfig")

if PusakaConfig then
    callFunction(
        "PusakaConfig.PusakaIds()",
        PusakaConfig.PusakaIds
    )

    callFunction(
        "PusakaConfig.GetReelOrder()",
        PusakaConfig.GetReelOrder
    )

    for _, id in ipairs({
        "KerisBerkarat",
        "BonekaJelangkung",
        "LenteraArwah",
        "CincinKuntilanak",
        "TengkorakKemenyan",
        "MahkotaGenderuwo"
    }) do
        callFunction(
            "PusakaConfig.GetById(" .. id .. ")",
            PusakaConfig.GetById,
            id
        )
    end
end

--====================================================
-- PETI ARWAH CONFIG
--====================================================

local Peti = requireSafe("PetiArwahConfig")

if Peti then
    callFunction(
        "PetiArwahConfig.TradeList()",
        Peti.TradeList
    )

    callFunction(
        "PetiArwahConfig.Rates()",
        Peti.Rates
    )

    callFunction(
        "PetiArwahConfig.ReelOrder()",
        Peti.ReelOrder
    )

    for _, id in ipairs({
        "KerisBerkarat",
        "BonekaJelangkung",
        "LenteraArwah",
        "CincinKuntilanak",
        "TengkorakKemenyan",
        "MahkotaGenderuwo"
    }) do

        callFunction(
            "PetiArwahConfig.TradeValueOf(" .. id .. ")",
            Peti.TradeValueOf,
            id
        )

        callFunction(
            "PetiArwahConfig.WeightOf(" .. id .. ")",
            Peti.WeightOf,
            id
        )
    end
end

--====================================================
-- SHOP CONFIG
--====================================================

local Shop = requireSafe("ShopConfig")

if Shop then
    callFunction(
        "ShopConfig.List()",
        Shop.List
    )

    for _, id in ipairs({
        "BibitMelati",
        "BibitKamboja",
        "BibitPisang",
        "Payung",
        "Pengelaris",
        "PetGagak",
        "OwlStaff"
    }) do
        callFunction(
            "ShopConfig.Get(" .. id .. ")",
            Shop.Get,
            id
        )
    end
end

--====================================================
-- GAIB CONFIG
--====================================================

local Gaib = requireSafe("GaibConfig")

if Gaib then
    callFunction(
        "GaibConfig.List()",
        Gaib.List
    )

    for _, id in ipairs({
        "SandalAngin",
        "MinyakJelangkung",
        "KemenyanPerak",
        "AirKembang",
        "ArangKeramat",
        "RamuanHoki",
        "CoinPasarSetan"
    }) do
        callFunction(
            "GaibConfig.Get(" .. id .. ")",
            Gaib.Get,
            id
        )
    end
end

--====================================================
-- QUEST CONFIG
--====================================================

local Quest = requireSafe("QuestConfig")

if Quest then
    callFunction(
        "QuestConfig.TodayQuests()",
        Quest.TodayQuests
    )

    callFunction(
        "QuestConfig.DayKey()",
        Quest.DayKey
    )

    callFunction(
        "QuestConfig.SecondsToReset()",
        Quest.SecondsToReset
    )

    for _, id in ipairs({
        "jual10",
        "jualmasak5",
        "masak4",
        "bibit3",
        "tanam6",
        "siram6",
        "panen6",
        "panenmelati6"
    }) do
        callFunction(
            "QuestConfig.GetById(" .. id .. ")",
            Quest.GetById,
            id
        )
    end
end

--====================================================
-- PLANT CATALOG
--====================================================

local Plant = requireSafe("PlantCatalog")

if Plant then
    callFunction(
        "PlantCatalog.list()",
        Plant.list
    )

    for _, id in ipairs({
        "Melati",
        "Kamboja",
        "Pisang"
    }) do
        callFunction(
            "PlantCatalog.get(" .. id .. ")",
            Plant.get,
            id
        )

        callFunction(
            "PlantCatalog.ringkasTumbuh(" .. id .. ")",
            Plant.ringkasTumbuh,
            id
        )
    end
end

--====================================================
-- SAVE
--====================================================

local text = table.concat(output, "\n")

if writefile then
    local fileName = "AlicePasar_FunctionDumpV2.txt"
    writefile(fileName, text)

    print("")
    print("SAVED:", fileName)
end

if setclipboard then
    pcall(function()
        setclipboard(text)
    end)

    print("Copied to clipboard.")
end

print("")
print("==================================================")
print(" FUNCTION DUMP COMPLETE")
print("==================================================")
