--=========================================================
-- ALICE DEEP DUMPER V3
-- Passive client-side audit only.
-- Does NOT FireServer / InvokeServer.
--=========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local TARGET_WORDS = {
    "StorageMove",
    "Trade",
    "TradeGetInventory",
    "TradeUpdateOffer",
    "TradeSetReady",
    "PetiArwah",
    "PetiArwahPull",
    "PetiArwahTrade",
    "Quest",
    "QuestClaim",
    "ShopBuy",
    "GrantShards",
    "AdminGrantCoins",
    "AdminPanel",
    "Coins",
    "Inventory",
    "Storage",
}

local output = {}

local function log(...)
    local t = {}

    for i = 1, select("#", ...) do
        t[#t + 1] = tostring(select(i, ...))
    end

    output[#output + 1] = table.concat(t, " ")
end

local function divider(title)
    log("")
    log("==============================================================")
    log(title)
    log("==============================================================")
end

local function containsTarget(text)
    text = tostring(text)

    local lower = text:lower()

    for _, word in ipairs(TARGET_WORDS) do
        if lower:find(word:lower(), 1, true) then
            return true, word
        end
    end

    return false
end

local function safeGetFullName(obj)
    local ok, result = pcall(function()
        return obj:GetFullName()
    end)

    return ok and result or tostring(obj)
end

--=========================================================
-- REMOTE SCANNER
--=========================================================

divider("REMOTE INVENTORY")

local remoteCount = 0

for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        remoteCount += 1

        local path = safeGetFullName(obj)

        local interesting, keyword = containsTarget(
            obj.Name .. " " .. path
        )

        log(
            interesting and "[MATCH]" or "[REMOTE]",
            obj.ClassName,
            "|",
            obj.Name,
            "|",
            path,
            interesting and ("| keyword=" .. keyword) or ""
        )
    end
end

log("")
log("Total remotes:", remoteCount)

--=========================================================
-- MODULE LIST
--=========================================================

divider("MODULESCRIPT INVENTORY")

local modules = {}

for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("ModuleScript") then
        modules[#modules + 1] = obj

        local path = safeGetFullName(obj)
        local interesting, keyword = containsTarget(path)

        if interesting then
            log(
                "[MATCH MODULE]",
                path,
                "| keyword=" .. keyword
            )
        else
            log("[MODULE]", path)
        end
    end
end

log("")
log("Total modules:", #modules)

--=========================================================
-- REQUIRE MODULES
--=========================================================

divider("MODULE EXPORTS")

local visited = {}

local function dumpTable(tbl, depth, path)
    depth = depth or 0
    path = path or "root"

    if depth > 4 then
        log(string.rep("  ", depth) .. path .. " = <MAX DEPTH>")
        return
    end

    if visited[tbl] then
        log(string.rep("  ", depth) .. path .. " = <ALREADY VISITED>")
        return
    end

    visited[tbl] = true

    for key, value in pairs(tbl) do
        local keyString = tostring(key)
        local valueType = typeof(value)

        local prefix = string.rep("  ", depth)

        local interesting, keyword = containsTarget(
            keyString .. " " .. tostring(value)
        )

        if valueType == "table" then
            log(
                prefix ..
                (interesting and "[MATCH] " or "") ..
                keyString ..
                " = table" ..
                (interesting and (" | keyword=" .. keyword) or "")
            )

            dumpTable(
                value,
                depth + 1,
                path .. "." .. keyString
            )

        elseif valueType == "function" then
            log(
                prefix ..
                (interesting and "[MATCH] " or "") ..
                keyString ..
                " = <function>" ..
                (interesting and (" | keyword=" .. keyword) or "")
            )

        elseif valueType == "Instance" then
            log(
                prefix ..
                (interesting and "[MATCH] " or "") ..
                keyString ..
                " = Instance(" ..
                value.ClassName ..
                ") " ..
                safeGetFullName(value)
            )

        else
            log(
                prefix ..
                (interesting and "[MATCH] " or "") ..
                keyString ..
                " = " ..
                tostring(value) ..
                " [" ..
                valueType ..
                "]"
            )
        end
    end
end

for _, module in ipairs(modules) do
    local modulePath = safeGetFullName(module)

    local ok, result = pcall(require, module)

    if ok then
        local moduleInteresting = containsTarget(modulePath)

        if moduleInteresting then
            log("")
            log("------------------------------------------------------------")
            log("[MODULE REQUIRE]", modulePath)
        end

        if type(result) == "table" then
            local oldCount = #output

            visited = {}

            dumpTable(result, 1, module.Name)

            if #output > oldCount and not moduleInteresting then
                -- output already collected
            end

        elseif type(result) == "function" then
            if moduleInteresting then
                log("Export: <function>")
            end

        elseif result ~= nil and moduleInteresting then
            log("Export:", tostring(result))
        end
    end
end

--=========================================================
-- DECOMPILE SEARCH
--=========================================================

divider("DECOMPILE / SOURCE SEARCH")

if type(decompile) == "function" then

    for _, module in ipairs(modules) do
        local ok, source = pcall(decompile, module)

        if ok and type(source) == "string" then
            local foundAnything = false

            for _, word in ipairs(TARGET_WORDS) do
                if source:lower():find(word:lower(), 1, true) then

                    if not foundAnything then
                        foundAnything = true

                        log("")
                        log("------------------------------------------------------------")
                        log("[SOURCE MATCH]")
                        log(safeGetFullName(module))
                    end

                    log("Keyword:", word)

                    local lower = source:lower()
                    local search = word:lower()

                    local startPos = 1

                    while true do
                        local pos = lower:find(
                            search,
                            startPos,
                            true
                        )

                        if not pos then
                            break
                        end

                        local snippetStart = math.max(1, pos - 300)
                        local snippetEnd = math.min(
                            #source,
                            pos + #word + 500
                        )

                        log("")
                        log(
                            source:sub(
                                snippetStart,
                                snippetEnd
                            )
                        )

                        startPos = pos + #word
                    end
                end
            end
        end
    end

else
    log("decompile() tidak tersedia di executor.")
end

--=========================================================
-- GETGC PASSIVE FUNCTION SEARCH
--=========================================================

divider("GETGC FUNCTION CONSTANT SEARCH")

if type(getgc) == "function"
and debug
and type(debug.getconstants) == "function" then

    local gcObjects = getgc(true)

    log("GC objects:", #gcObjects)

    local functionCount = 0
    local matchCount = 0

    for _, value in ipairs(gcObjects) do
        if type(value) == "function" then
            functionCount += 1

            local ok, constants = pcall(
                debug.getconstants,
                value
            )

            if ok and type(constants) == "table" then

                local matches = {}

                for index, constant in ipairs(constants) do
                    if type(constant) == "string" then
                        local interesting, keyword =
                            containsTarget(constant)

                        if interesting then
                            matches[#matches + 1] = {
                                index = index,
                                constant = constant,
                                keyword = keyword
                            }
                        end
                    end
                end

                if #matches > 0 then
                    matchCount += 1

                    log("")
                    log(
                        "[FUNCTION MATCH #" ..
                        matchCount ..
                        "]"
                    )

                    if debug.info then
                        local okInfo, source =
                            pcall(debug.info, value, "s")

                        if okInfo then
                            log("Source:", tostring(source))
                        end
                    end

                    for _, m in ipairs(matches) do
                        log(
                            "Constant[" ..
                            m.index ..
                            "] =",
                            m.constant,
                            "| keyword=" ..
                            m.keyword
                        )
                    end

                    -- Upvalues only DISPLAYED.
                    -- Nothing is changed.
                    if type(debug.getupvalues) == "function" then
                        local okUp, upvalues =
                            pcall(
                                debug.getupvalues,
                                value
                            )

                        if okUp
                        and type(upvalues) == "table" then
                            for index, up in pairs(upvalues) do
                                local upType = typeof(up)

                                if upType == "string"
                                or upType == "number"
                                or upType == "boolean"
                                or upType == "Instance" then

                                    log(
                                        "  Upvalue[" ..
                                        tostring(index) ..
                                        "] =",
                                        upType == "Instance"
                                            and safeGetFullName(up)
                                            or tostring(up)
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    log("")
    log("Functions scanned:", functionCount)
    log("Functions matched:", matchCount)

else
    log(
        "getgc/debug.getconstants tidak tersedia."
    )
end

--=========================================================
-- CONNECTION SEARCH
-- Passive metadata only
--=========================================================

divider("REMOTE CLIENT CONNECTIONS")

if type(getconnections) == "function" then

    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local ok, connections = pcall(
                getconnections,
                obj.OnClientEvent
            )

            if ok
            and type(connections) == "table"
            and #connections > 0 then

                local interesting =
                    containsTarget(
                        obj.Name ..
                        " " ..
                        safeGetFullName(obj)
                    )

                if interesting then
                    log("")
                    log(
                        "[CLIENT EVENT]",
                        safeGetFullName(obj),
                        "| connections=",
                        #connections
                    )

                    for index, connection in ipairs(connections) do
                        if connection.Function then
                            log(
                                "  Handler #" ..
                                index ..
                                ":",
                                tostring(
                                    connection.Function
                                )
                            )
                        end
                    end
                end
            end
        end
    end

else
    log("getconnections() tidak tersedia.")
end

--=========================================================
-- SAVE
--=========================================================

divider("SUMMARY")

log("Modules:", #modules)
log("Remotes:", remoteCount)
log("Player:", LocalPlayer and LocalPlayer.Name or "unknown")
log("PlaceId:", game.PlaceId)
log("GameId:", game.GameId)

local finalText = table.concat(output, "\n")

print(finalText)

if type(writefile) == "function" then
    local fileName = "AliceDeepDump_V3.txt"

    local ok, err = pcall(function()
        writefile(fileName, finalText)
    end)

    if ok then
        print("")
        print("Saved:", fileName)
    else
        warn("writefile gagal:", err)
    end
else
    warn("writefile() tidak tersedia.")
end
