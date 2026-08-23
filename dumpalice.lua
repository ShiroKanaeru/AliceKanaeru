--==============================================================
--                   ALICE TRADE DUMPER V2
--==============================================================
-- Passive dump only.
--
-- Focus:
--   * Game-owned containers
--   * Hashed remotes
--   * Remote registry / mapping
--   * Trade-related constants
--   * Trade client modules
--
-- DOES NOT:
--   * FireServer
--   * InvokeServer
--   * modify constants/upvalues
--==============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")

local FILE_NAME = "AliceTradeDump_V2.txt"

local TRADE_WORDS = {
    "TradeGetInventory",
    "TradeUpdateOffer",
    "TradeSetReady",
    "TradeAccept",
    "TradeConfirm",
    "TradeCancel",
    "TradeRequest",
    "TradeInvite",
    "TradeStart",
    "TradeEnd",
    "TradeState",
    "Trade"
}

local output = {}

local function out(...)
    local parts = {}

    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end

    output[#output + 1] = table.concat(parts, " ")
end

local function divider(title)
    out("")
    out("==============================================================")
    out(title)
    out("==============================================================")
end

local function fullName(obj)
    local ok, result = pcall(function()
        return obj:GetFullName()
    end)

    return ok and result or tostring(obj)
end

local function tradeMatch(text)
    text = tostring(text):lower()

    for _, word in ipairs(TRADE_WORDS) do
        if text:find(word:lower(), 1, true) then
            return true, word
        end
    end

    return false
end

local function isGameContainer(obj)
    if obj:IsDescendantOf(ReplicatedStorage) then
        return true
    end

    if PlayerScripts and obj:IsDescendantOf(PlayerScripts) then
        return true
    end

    if PlayerGui and obj:IsDescendantOf(PlayerGui) then
        return true
    end

    return false
end

divider("ALICE TRADE DUMPER V2")

out("Player:", LocalPlayer.Name)
out("PlaceId:", game.PlaceId)
out("GameId:", game.GameId)
out("JobId:", game.JobId)

if identifyexecutor then
    local ok, name = pcall(identifyexecutor)

    if ok then
        out("Executor:", name)
    end
end

--==============================================================
-- CAPABILITIES
--==============================================================

divider("CAPABILITIES")

out("writefile:", type(writefile))
out("decompile:", type(decompile))
out("getgc:", type(getgc))
out("getconnections:", type(getconnections))
out(
    "debug.getconstants:",
    debug and type(debug.getconstants) or "nil"
)
out(
    "debug.getupvalues:",
    debug and type(debug.getupvalues) or "nil"
)

--==============================================================
-- ALL GAME REMOTES
--==============================================================

divider("GAME REMOTES")

local gameRemotes = {}

for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent")
    or obj:IsA("RemoteFunction") then

        gameRemotes[#gameRemotes + 1] = obj

        out(
            "[REMOTE]",
            obj.ClassName,
            "| name=" .. obj.Name,
            "| path=" .. fullName(obj)
        )
    end
end

out("")
out("Total ReplicatedStorage remotes:", #gameRemotes)

--==============================================================
-- GAME MODULES ONLY
--==============================================================

divider("GAME MODULES")

local modules = {}

local roots = {
    ReplicatedStorage,
    PlayerScripts,
    PlayerGui
}

for _, root in ipairs(roots) do
    if root then
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                modules[#modules + 1] = obj

                local matched, keyword =
                    tradeMatch(
                        obj.Name .. " " .. fullName(obj)
                    )

                if matched then
                    out(
                        "[NAME MATCH]",
                        fullName(obj),
                        "| keyword=" .. keyword
                    )
                end
            end
        end
    end
end

out("")
out("Total game modules:", #modules)

--==============================================================
-- DECOMPILE ONLY TRADE SOURCE MATCHES
--==============================================================

divider("TRADE SOURCE MATCHES")

local sourceMatches = 0

if type(decompile) == "function" then

    for index, module in ipairs(modules) do

        local ok, source =
            pcall(decompile, module)

        if ok and type(source) == "string" then

            local lower = source:lower()
            local hits = {}

            for _, word in ipairs(TRADE_WORDS) do
                if lower:find(
                    word:lower(),
                    1,
                    true
                ) then
                    hits[#hits + 1] = word
                end
            end

            if #hits > 0 then
                sourceMatches += 1

                out("")
                out("--------------------------------------------------------------")
                out(
                    "[SOURCE MATCH " ..
                    sourceMatches ..
                    "]"
                )

                out("Module:", fullName(module))
                out(
                    "Keywords:",
                    table.concat(hits, ", ")
                )

                for _, word in ipairs(hits) do

                    local searchWord =
                        word:lower()

                    local startPos = 1
                    local hitNumber = 0

                    while true do

                        local pos =
                            lower:find(
                                searchWord,
                                startPos,
                                true
                            )

                        if not pos then
                            break
                        end

                        hitNumber += 1

                        local snippetStart =
                            math.max(1, pos - 700)

                        local snippetEnd =
                            math.min(
                                #source,
                                pos + #word + 1200
                            )

                        out("")
                        out(
                            "[KEYWORD " ..
                            word ..
                            " #" ..
                            hitNumber ..
                            "]"
                        )

                        out(
                            source:sub(
                                snippetStart,
                                snippetEnd
                            )
                        )

                        startPos =
                            pos + #word
                    end
                end
            end
        end
    end

else
    out("decompile() unavailable")
end

out("")
out("Source matches:", sourceMatches)

--==============================================================
-- GETGC TRADE FUNCTIONS
--==============================================================

divider("TRADE GETGC FUNCTIONS")

local gcMatchCount = 0
local gcFunctionCount = 0

if type(getgc) == "function"
and debug
and type(debug.getconstants) == "function" then

    local okGC, objects =
        pcall(getgc, true)

    if okGC
    and type(objects) == "table" then

        for _, value in ipairs(objects) do

            if type(value) == "function" then

                gcFunctionCount += 1

                local okConstants, constants =
                    pcall(
                        debug.getconstants,
                        value
                    )

                if okConstants
                and type(constants) == "table" then

                    local matches = {}

                    for index, constant
                        in pairs(constants) do

                        if type(constant) == "string" then

                            local matched, keyword =
                                tradeMatch(constant)

                            if matched then
                                matches[#matches + 1] = {
                                    index = index,
                                    value = constant,
                                    keyword = keyword
                                }
                            end
                        end
                    end

                    if #matches > 0 then

                        -- Ignore our own dumper where possible.
                        local looksLikeAlice = false

                        for _, c in pairs(constants) do
                            if c == "ALICE TRADE DUMPER V2"
                            or c == FILE_NAME then
                                looksLikeAlice = true
                                break
                            end
                        end

                        if not looksLikeAlice then

                            gcMatchCount += 1

                            out("")
                            out(
                                "--------------------------------------------------------------"
                            )

                            out(
                                "[GC MATCH #" ..
                                gcMatchCount ..
                                "]"
                            )

                            if debug.info then

                                local okSource, src =
                                    pcall(
                                        debug.info,
                                        value,
                                        "s"
                                    )

                                if okSource then
                                    out("Source:", src)
                                end

                                local okName, fnName =
                                    pcall(
                                        debug.info,
                                        value,
                                        "n"
                                    )

                                if okName
                                and fnName
                                and fnName ~= "" then
                                    out("Name:", fnName)
                                end
                            end

                            for _, match
                                in ipairs(matches) do

                                out(
                                    "Constant[" ..
                                    tostring(match.index) ..
                                    "] =",
                                    match.value
                                )
                            end

                            -- Passive upvalue inspection
                            if type(debug.getupvalues)
                                == "function" then

                                local okUp, ups =
                                    pcall(
                                        debug.getupvalues,
                                        value
                                    )

                                if okUp
                                and type(ups) == "table" then

                                    for upIndex, up
                                        in pairs(ups) do

                                        local t = typeof(up)

                                        if t == "Instance" then

                                            if isGameContainer(up)
                                            or up:IsA("RemoteEvent")
                                            or up:IsA("RemoteFunction") then

                                                out(
                                                    "  Upvalue[" ..
                                                    tostring(upIndex) ..
                                                    "] Instance:",
                                                    fullName(up)
                                                )
                                            end

                                        elseif t == "string" then

                                            local match =
                                                tradeMatch(up)

                                            if match then
                                                out(
                                                    "  Upvalue[" ..
                                                    tostring(upIndex) ..
                                                    "] String:",
                                                    up
                                                )
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

out("")
out("Functions scanned:", gcFunctionCount)
out("Trade GC matches:", gcMatchCount)

--==============================================================
-- TABLE / REGISTRY SEARCH
--==============================================================

divider("TRADE REGISTRY TABLE SEARCH")

local tableCount = 0

if type(getgc) == "function" then

    local okGC, objects =
        pcall(getgc, true)

    if okGC and type(objects) == "table" then

        for _, object in ipairs(objects) do

            if type(object) == "table" then

                local matchingKeys = {}

                for key, value in pairs(object) do

                    local matched, keyword =
                        tradeMatch(
                            tostring(key) ..
                            " " ..
                            tostring(value)
                        )

                    if matched then

                        matchingKeys[#matchingKeys + 1] = {
                            key = key,
                            value = value,
                            keyword = keyword
                        }
                    end
                end

                if #matchingKeys > 0 then

                    tableCount += 1

                    out("")
                    out(
                        "--------------------------------------------------------------"
                    )

                    out(
                        "[REGISTRY/TABLE MATCH #" ..
                        tableCount ..
                        "]"
                    )

                    for _, result
                        in ipairs(matchingKeys) do

                        local v = result.value

                        if typeof(v) == "Instance" then

                            out(
                                tostring(result.key),
                                "=>",
                                fullName(v),
                                "[" .. v.ClassName .. "]"
                            )

                        elseif type(v) == "table" then

                            out(
                                tostring(result.key),
                                "=> <table>"
                            )

                            local shown = 0

                            for k2, v2 in pairs(v) do

                                shown += 1

                                if shown > 30 then
                                    out("  ... truncated ...")
                                    break
                                end

                                if typeof(v2)
                                    == "Instance" then

                                    out(
                                        "  ",
                                        tostring(k2),
                                        "=>",
                                        fullName(v2),
                                        "[" ..
                                        v2.ClassName ..
                                        "]"
                                    )

                                else

                                    out(
                                        "  ",
                                        tostring(k2),
                                        "=>",
                                        tostring(v2)
                                    )
                                end
                            end

                        else

                            out(
                                tostring(result.key),
                                "=>",
                                tostring(v)
                            )
                        end
                    end
                end
            end
        end
    end
end

out("")
out("Registry/table matches:", tableCount)

--==============================================================
-- CONNECTIONS FOR HASHED REMOTES
--==============================================================

divider("HASHED REMOTE CLIENT CONNECTIONS")

if type(getconnections) == "function" then

    for _, remote in ipairs(gameRemotes) do

        if remote:IsA("RemoteEvent") then

            local ok, connections =
                pcall(
                    getconnections,
                    remote.OnClientEvent
                )

            if ok
            and type(connections) == "table"
            and #connections > 0 then

                out("")
                out(
                    "[REMOTE EVENT]",
                    fullName(remote)
                )

                out(
                    "Connections:",
                    #connections
                )

                for i, connection
                    in ipairs(connections) do

                    local fn =
                        connection.Function

                    if type(fn) == "function" then

                        out(
                            "Handler #" ..
                            i ..
                            ":",
                            tostring(fn)
                        )

                        if debug
                        and type(debug.info)
                            == "function" then

                            local okSource, src =
                                pcall(
                                    debug.info,
                                    fn,
                                    "s"
                                )

                            if okSource then
                                out(
                                    "  Source:",
                                    src
                                )
                            end
                        end

                        if debug
                        and type(debug.getconstants)
                            == "function" then

                            local okConstants, constants =
                                pcall(
                                    debug.getconstants,
                                    fn
                                )

                            if okConstants
                            and type(constants)
                                == "table" then

                                for index, constant
                                    in pairs(constants) do

                                    if type(constant)
                                        == "string" then

                                        local matched =
                                            tradeMatch(
                                                constant
                                            )

                                        if matched then

                                            out(
                                                "  TRADE CONSTANT[" ..
                                                tostring(index) ..
                                                "] =",
                                                constant
                                            )
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

else
    out("getconnections() unavailable")
end

--==============================================================
-- SUMMARY
--==============================================================

divider("SUMMARY")

out("Game remotes:", #gameRemotes)
out("Game modules:", #modules)
out("Trade source matches:", sourceMatches)
out("Trade GC matches:", gcMatchCount)
out("Trade table matches:", tableCount)

local finalText =
    table.concat(output, "\n")

--==============================================================
-- SAVE
--==============================================================

if type(writefile) == "function" then

    local ok, err =
        pcall(function()
            writefile(
                FILE_NAME,
                finalText
            )
        end)

    if ok then
        print("")
        print("==============================================")
        print("ALICE TRADE DUMPER V2 COMPLETE")
        print("Saved:", FILE_NAME)
        print("Characters:", #finalText)
        print("==============================================")
    else
        warn(
            "writefile failed:",
            err
        )
        print(finalText)
    end

else
    print(finalText)
end
