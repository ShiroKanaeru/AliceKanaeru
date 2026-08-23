--==============================================================
--                    ALICE DEEP DUMPER V3
--==============================================================
-- Passive client-side audit / dump utility.
--
-- Features:
--  - RemoteEvent / RemoteFunction scanner
--  - ModuleScript scanner
--  - Safe require() export dump
--  - decompile() keyword search (if supported)
--  - getgc() + debug.getconstants() search (if supported)
--  - getconnections() client handler scan (if supported)
--  - writefile() output
--  - Clipboard fallback
--  - Clipboard chunk system
--
-- Does NOT:
--  - FireServer()
--  - InvokeServer()
--  - Modify remotes
--  - Modify upvalues/constants
--==============================================================


--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer


--==============================================================
-- CONFIG
--==============================================================

local FILE_NAME = "AliceDeepDump_V3.txt"

-- Smaller chunks are generally safer for executor clipboard limits.
local CHUNK_SIZE = 90000

local MAX_TABLE_DEPTH = 5

local TARGET_WORDS = {

    -- Storage / inventory
    "Storage",
    "StorageMove",
    "Inventory",
    "Backpack",

    -- Trading
    "Trade",
    "TradeGetInventory",
    "TradeUpdateOffer",
    "TradeSetReady",
    "TradeAccept",
    "TradeConfirm",

    -- Peti Arwah
    "PetiArwah",
    "PetiArwahPull",
    "PetiArwahTrade",

    -- Quest
    "Quest",
    "QuestClaim",
    "QuestComplete",
    "QuestReward",

    -- Economy
    "Coins",
    "Coin",
    "Money",
    "Cash",
    "Currency",
    "Shop",
    "ShopBuy",
    "Buy",
    "Sell",

    -- Shards
    "Shard",
    "Shards",
    "GrantShards",

    -- Admin
    "Admin",
    "AdminGrantCoins",
    "AdminPanel",

    -- Generic interesting words
    "Reward",
    "Claim",
    "Grant",
    "Give",
    "Item",
    "Items",
    "Amount",
    "Quantity",
    "Count",
    "Nonce",
    "Transaction",
    "TransactionId",
    "RequestId",
    "Cooldown",
}


--==============================================================
-- OUTPUT
--==============================================================

local output = {}

local function stringify(value)

    local valueType = typeof(value)

    if valueType == "Instance" then

        local ok, path = pcall(function()
            return value:GetFullName()
        end)

        if ok then
            return path
        end

    end

    return tostring(value)
end


local function log(...)

    local pieces = {}

    for i = 1, select("#", ...) do
        pieces[#pieces + 1] = stringify(select(i, ...))
    end

    local line = table.concat(pieces, " ")

    output[#output + 1] = line
end


local function divider(title)

    log("")
    log("==============================================================")
    log(title)
    log("==============================================================")

end


local function safeGetFullName(instance)

    local ok, result = pcall(function()
        return instance:GetFullName()
    end)

    if ok then
        return result
    end

    return tostring(instance)
end


local function containsTarget(text)

    text = tostring(text)

    local lowerText = string.lower(text)

    for _, word in ipairs(TARGET_WORDS) do

        if string.find(
            lowerText,
            string.lower(word),
            1,
            true
        ) then

            return true, word

        end

    end

    return false, nil
end


--==============================================================
-- HEADER
--==============================================================

divider("ALICE DEEP DUMPER V3")

log("Player   :", LocalPlayer and LocalPlayer.Name or "Unknown")
log("PlaceId  :", game.PlaceId)
log("GameId   :", game.GameId)
log("JobId    :", game.JobId)
log("Loaded   :", game:IsLoaded())

if identifyexecutor then

    local ok, executorName = pcall(identifyexecutor)

    if ok then
        log("Executor :", executorName)
    end

elseif getexecutorname then

    local ok, executorName = pcall(getexecutorname)

    if ok then
        log("Executor :", executorName)
    end

end


--==============================================================
-- CAPABILITY CHECK
--==============================================================

divider("EXECUTOR CAPABILITIES")


local capabilities = {

    writefile = type(writefile) == "function",
    appendfile = type(appendfile) == "function",
    readfile = type(readfile) == "function",
    listfiles = type(listfiles) == "function",

    setclipboard = type(setclipboard) == "function",
    toclipboard = type(toclipboard) == "function",

    decompile = type(decompile) == "function",
    getgc = type(getgc) == "function",
    getconnections = type(getconnections) == "function",

    debug_getconstants =
        debug
        and type(debug.getconstants) == "function",

    debug_getupvalues =
        debug
        and type(debug.getupvalues) == "function",

    debug_info =
        debug
        and type(debug.info) == "function",

}


for name, available in pairs(capabilities) do

    log(
        string.format(
            "%-22s : %s",
            name,
            available and "YES" or "NO"
        )
    )

end


--==============================================================
-- REMOTE SCANNER
--==============================================================

divider("REMOTE INVENTORY")


local remoteCount = 0
local interestingRemoteCount = 0

local discoveredRemotes = {}


for _, object in ipairs(game:GetDescendants()) do

    if object:IsA("RemoteEvent")
    or object:IsA("RemoteFunction") then

        remoteCount += 1

        local path = safeGetFullName(object)

        local interesting, keyword = containsTarget(
            object.Name .. " " .. path
        )

        if interesting then
            interestingRemoteCount += 1
        end

        discoveredRemotes[#discoveredRemotes + 1] = object

        log(
            interesting and "[MATCH]" or "[REMOTE]",
            object.ClassName,
            "|",
            object.Name,
            "|",
            path,
            interesting and ("| keyword=" .. keyword) or ""
        )

    end

end


log("")
log("Total remotes       :", remoteCount)
log("Interesting remotes :", interestingRemoteCount)


--==============================================================
-- MODULESCRIPT INVENTORY
--==============================================================

divider("MODULESCRIPT INVENTORY")


local modules = {}


for _, object in ipairs(game:GetDescendants()) do

    if object:IsA("ModuleScript") then

        modules[#modules + 1] = object

        local path = safeGetFullName(object)

        local interesting, keyword = containsTarget(path)

        if interesting then

            log(
                "[MATCH MODULE]",
                path,
                "| keyword=" .. keyword
            )

        else

            log(
                "[MODULE]",
                path
            )

        end

    end

end


log("")
log("Total modules:", #modules)


--==============================================================
-- TABLE EXPORT DUMPER
--==============================================================

local function dumpValue(
    value,
    depth,
    name,
    visited
)

    depth = depth or 0
    name = tostring(name or "value")
    visited = visited or {}

    local indent = string.rep("  ", depth)

    if depth > MAX_TABLE_DEPTH then

        log(
            indent ..
            name ..
            " = <MAX DEPTH>"
        )

        return

    end


    local valueType = typeof(value)


    if valueType == "table" then

        if visited[value] then

            log(
                indent ..
                name ..
                " = <ALREADY VISITED>"
            )

            return

        end

        visited[value] = true

        log(
            indent ..
            name ..
            " = {"
        )

        for key, childValue in pairs(value) do

            local keyString = tostring(key)

            local interesting, keyword = containsTarget(
                keyString ..
                " " ..
                tostring(childValue)
            )

            if interesting then

                log(
                    indent ..
                    "  [MATCH KEY] " ..
                    keyString ..
                    " | keyword=" ..
                    tostring(keyword)
                )

            end


            dumpValue(
                childValue,
                depth + 1,
                keyString,
                visited
            )

        end

        log(
            indent ..
            "}"
        )


    elseif valueType == "Instance" then

        log(
            indent ..
            name ..
            " = Instance(" ..
            value.ClassName ..
            ") " ..
            safeGetFullName(value)
        )


    elseif valueType == "function" then

        log(
            indent ..
            name ..
            " = <function>"
        )


    elseif valueType == "string" then

        log(
            indent ..
            name ..
            " = " ..
            string.format("%q", value)
        )


    else

        log(
            indent ..
            name ..
            " = " ..
            tostring(value) ..
            " [" ..
            valueType ..
            "]"
        )

    end

end


--==============================================================
-- REQUIRE MODULE EXPORTS
--==============================================================

divider("MODULE EXPORTS")


for _, module in ipairs(modules) do

    local path = safeGetFullName(module)

    local pathInteresting =
        containsTarget(path)

    local ok, result = pcall(
        require,
        module
    )

    if ok then

        local resultInteresting = false

        if typeof(result) == "table" then

            for key, value in pairs(result) do

                local match =
                    containsTarget(
                        tostring(key) ..
                        " " ..
                        tostring(value)
                    )

                if match then
                    resultInteresting = true
                    break
                end

            end

        end


        if pathInteresting
        or resultInteresting then

            log("")
            log("------------------------------------------------------------")
            log("[MODULE REQUIRE]")
            log(path)

            local visited = {}

            dumpValue(
                result,
                1,
                module.Name,
                visited
            )

        end

    else

        if pathInteresting then

            log("")
            log("[REQUIRE FAILED]")
            log(path)
            log("Error:", result)

        end

    end

end


--==============================================================
-- DECOMPILE SEARCH
--==============================================================

divider("DECOMPILE / SOURCE SEARCH")


local decompileModuleCount = 0
local decompileMatchCount = 0


if type(decompile) == "function" then

    for _, module in ipairs(modules) do

        local ok, source = pcall(
            decompile,
            module
        )

        if ok
        and type(source) == "string" then

            decompileModuleCount += 1

            local sourceLower =
                string.lower(source)

            local matchedKeywords = {}


            for _, word in ipairs(TARGET_WORDS) do

                if string.find(
                    sourceLower,
                    string.lower(word),
                    1,
                    true
                ) then

                    matchedKeywords[#matchedKeywords + 1] =
                        word

                end

            end


            if #matchedKeywords > 0 then

                decompileMatchCount += 1

                log("")
                log("------------------------------------------------------------")
                log("[SOURCE MATCH]")
                log(safeGetFullName(module))
                log(
                    "Keywords:",
                    table.concat(
                        matchedKeywords,
                        ", "
                    )
                )


                for _, keyword in ipairs(matchedKeywords) do

                    local lowerKeyword =
                        string.lower(keyword)

                    local startPosition = 1

                    local matchIndex = 0


                    while true do

                        local position =
                            string.find(
                                sourceLower,
                                lowerKeyword,
                                startPosition,
                                true
                            )

                        if not position then
                            break
                        end


                        matchIndex += 1


                        local snippetStart =
                            math.max(
                                1,
                                position - 400
                            )


                        local snippetEnd =
                            math.min(
                                #source,
                                position +
                                #keyword +
                                700
                            )


                        log("")
                        log(
                            "[Snippet " ..
                            keyword ..
                            " #" ..
                            matchIndex ..
                            "]"
                        )


                        log(
                            source:sub(
                                snippetStart,
                                snippetEnd
                            )
                        )


                        startPosition =
                            position +
                            #keyword

                    end

                end

            end

        end

    end


    log("")
    log(
        "Modules decompiled:",
        decompileModuleCount
    )

    log(
        "Source matches:",
        decompileMatchCount
    )

else

    log(
        "decompile() tidak tersedia."
    )

end


--==============================================================
-- GETGC CONSTANT SEARCH
--==============================================================

divider("GETGC CONSTANT SEARCH")


local gcFunctionCount = 0
local gcMatchCount = 0


if type(getgc) == "function"
and debug
and type(debug.getconstants) == "function" then


    local okGC, gcObjects = pcall(
        getgc,
        true
    )


    if okGC
    and type(gcObjects) == "table" then


        log(
            "GC objects:",
            #gcObjects
        )


        for _, value in ipairs(gcObjects) do

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


                            local interesting, keyword =
                                containsTarget(
                                    constant
                                )


                            if interesting then

                                matches[#matches + 1] = {

                                    index = index,
                                    value = constant,
                                    keyword = keyword,

                                }

                            end

                        end

                    end


                    if #matches > 0 then

                        gcMatchCount += 1


                        log("")
                        log(
                            "------------------------------------------------------------"
                        )

                        log(
                            "[FUNCTION MATCH #" ..
                            gcMatchCount ..
                            "]"
                        )


                        if debug.info then

                            local okSource, source =
                                pcall(
                                    debug.info,
                                    value,
                                    "s"
                                )

                            if okSource then
                                log(
                                    "Source:",
                                    source
                                )
                            end


                            local okName, name =
                                pcall(
                                    debug.info,
                                    value,
                                    "n"
                                )

                            if okName
                            and name
                            and name ~= "" then

                                log(
                                    "Name:",
                                    name
                                )

                            end

                        end


                        for _, match in ipairs(matches) do

                            log(
                                "Constant[" ..
                                tostring(match.index) ..
                                "] =",
                                match.value,
                                "| keyword=" ..
                                tostring(
                                    match.keyword
                                )
                            )

                        end


                        -- Passive upvalue read only.
                        if type(debug.getupvalues)
                            == "function" then


                            local okUpvalues, upvalues =
                                pcall(
                                    debug.getupvalues,
                                    value
                                )


                            if okUpvalues
                            and type(upvalues)
                                == "table" then


                                for index, upvalue
                                    in pairs(upvalues) do


                                    local upvalueType =
                                        typeof(
                                            upvalue
                                        )


                                    if upvalueType == "string"
                                    or upvalueType == "number"
                                    or upvalueType == "boolean"
                                    or upvalueType == "Instance" then


                                        log(
                                            "  Upvalue[" ..
                                            tostring(index) ..
                                            "] =",
                                            stringify(
                                                upvalue
                                            )
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
        log(
            "Functions scanned:",
            gcFunctionCount
        )

        log(
            "Functions matched:",
            gcMatchCount
        )


    else

        log(
            "getgc() gagal:",
            tostring(gcObjects)
        )

    end

else

    log(
        "getgc/debug.getconstants tidak tersedia."
    )

end


--==============================================================
-- CLIENT REMOTE CONNECTION SCANNER
--==============================================================

divider("REMOTE CLIENT CONNECTIONS")


local connectionRemoteCount = 0


if type(getconnections) == "function" then


    for _, remote in ipairs(discoveredRemotes) do


        if remote:IsA("RemoteEvent") then


            local path =
                safeGetFullName(remote)


            local interesting =
                containsTarget(
                    remote.Name ..
                    " " ..
                    path
                )


            if interesting then


                local okConnections, connections =
                    pcall(
                        getconnections,
                        remote.OnClientEvent
                    )


                if okConnections
                and type(connections) == "table"
                and #connections > 0 then


                    connectionRemoteCount += 1


                    log("")
                    log(
                        "[CLIENT EVENT]",
                        path
                    )

                    log(
                        "Connections:",
                        #connections
                    )


                    for index, connection
                        in ipairs(connections) do


                        local fn =
                            connection.Function


                        if type(fn) == "function" then


                            log(
                                "  Handler #" ..
                                index ..
                                ":",
                                tostring(fn)
                            )


                            if debug
                            and debug.info then


                                local okSource, source =
                                    pcall(
                                        debug.info,
                                        fn,
                                        "s"
                                    )


                                if okSource then

                                    log(
                                        "    Source:",
                                        source
                                    )

                                end


                                local okName, name =
                                    pcall(
                                        debug.info,
                                        fn,
                                        "n"
                                    )


                                if okName
                                and name
                                and name ~= "" then

                                    log(
                                        "    Name:",
                                        name
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
    log(
        "Matched client-event remotes:",
        connectionRemoteCount
    )

else

    log(
        "getconnections() tidak tersedia."
    )

end


--==============================================================
-- GLOBAL TABLE SCAN
--==============================================================

divider("GETGENV TARGET SEARCH")


local globalMatchCount = 0


if type(getgenv) == "function" then


    local okEnv, environment =
        pcall(getgenv)


    if okEnv
    and type(environment) == "table" then


        for key, value in pairs(environment) do


            local interesting, keyword =
                containsTarget(
                    tostring(key) ..
                    " " ..
                    tostring(value)
                )


            if interesting then

                globalMatchCount += 1

                log(
                    "[GLOBAL MATCH]",
                    tostring(key),
                    "=",
                    tostring(value),
                    "| keyword=" ..
                    tostring(keyword)
                )

            end

        end

    end


    log("")
    log(
        "Global matches:",
        globalMatchCount
    )

else

    log(
        "getgenv() tidak tersedia."
    )

end


--==============================================================
-- SUMMARY
--==============================================================

divider("SUMMARY")


log("Player               :", LocalPlayer and LocalPlayer.Name or "Unknown")
log("PlaceId              :", game.PlaceId)
log("GameId               :", game.GameId)

log("")
log("Modules              :", #modules)
log("Remotes              :", remoteCount)
log("Interesting remotes  :", interestingRemoteCount)

log("")
log("Decompiler modules   :", decompileModuleCount)
log("Decompiler matches   :", decompileMatchCount)

log("")
log("GC functions         :", gcFunctionCount)
log("GC matches           :", gcMatchCount)

log("")
log("Event-handler remotes:", connectionRemoteCount)


--==============================================================
-- BUILD FINAL TEXT
--==============================================================

local finalText =
    table.concat(
        output,
        "\n"
    )


--==============================================================
-- CLIPBOARD HELPERS
--==============================================================

local function getClipboardFunction()


    if type(setclipboard) == "function" then
        return setclipboard
    end


    if type(toclipboard) == "function" then
        return toclipboard
    end


    if type(set_clipboard) == "function" then
        return set_clipboard
    end


    return nil

end


local function makeChunks(
    text,
    chunkSize
)


    local chunks = {}


    local position = 1

    local totalLength = #text


    while position <= totalLength do


        local ending =
            math.min(
                position +
                chunkSize -
                1,

                totalLength
            )


        chunks[#chunks + 1] =
            text:sub(
                position,
                ending
            )


        position =
            ending + 1

    end


    if #chunks == 0 then
        chunks[1] = ""
    end


    return chunks

end


local dumpChunks =
    makeChunks(
        finalText,
        CHUNK_SIZE
    )


--==============================================================
-- GLOBAL DUMP COMMANDS
--==============================================================

local ENV =
    getgenv
    and getgenv()
    or _G


ENV.AliceDumpChunks =
    dumpChunks


ENV.AliceDumpText =
    finalText


ENV.AliceDumpInfo =
    function()


        print("")
        print("==============================================================")
        print("                  ALICE DEEP DUMPER V3")
        print("==============================================================")

        print(
            "Characters :",
            #finalText
        )

        print(
            "Parts      :",
            #dumpChunks
        )

        print(
            "Chunk size :",
            CHUNK_SIZE
        )

        print("")
        print(
            "Copy part:"
        )

        print(
            "AliceDumpPart(1)"
        )

        print(
            "AliceDumpPart(2)"
        )

        print(
            "..."
        )

        print("==============================================================")

    end


ENV.AliceDumpPart =
    function(index)


        index =
            tonumber(index)


        if not index then

            warn(
                "Masukkan nomor part."
            )

            return

        end


        local chunk =
            dumpChunks[index]


        if not chunk then

            warn(
                "Part tidak ada. Available: 1-" ..
                tostring(
                    #dumpChunks
                )
            )

            return

        end


        local clipboard =
            getClipboardFunction()


        if not clipboard then

            warn(
                "Clipboard function tidak tersedia."
            )

            print(chunk)

            return

        end


        local content =
            string.format(
                "===== ALICE DEEP DUMP V3 | PART %d/%d =====\n",
                index,
                #dumpChunks
            )
            ..
            chunk
            ..
            string.format(
                "\n===== END PART %d/%d =====",
                index,
                #dumpChunks
            )


        local ok, err =
            pcall(
                clipboard,
                content
            )


        if ok then

            print(
                "Copied PART " ..
                index ..
                "/" ..
                #dumpChunks
            )

        else

            warn(
                "Clipboard gagal:",
                err
            )

        end

    end


--==============================================================
-- FILE SAVE
--==============================================================

local savedToFile = false


if type(writefile) == "function" then


    local ok, err =
        pcall(function()

            writefile(
                FILE_NAME,
                finalText
            )

        end)


    if ok then

        savedToFile = true

        print("")
        print("==============================================================")
        print("ALICE DEEP DUMP COMPLETE")
        print("==============================================================")
        print("Saved:", FILE_NAME)
        print("Characters:", #finalText)
        print("Clipboard Parts:", #dumpChunks)

    else

        warn(
            "writefile gagal:",
            err
        )

    end

end


--==============================================================
-- CLIPBOARD FALLBACK
--==============================================================

if not savedToFile then


    local clipboard =
        getClipboardFunction()


    if clipboard then


        ENV.AliceDumpPart(1)


        print("")
        print("==============================================================")
        print("ALICE DEEP DUMP COMPLETE")
        print("==============================================================")
        print("File save unavailable / failed.")
        print("PART 1 copied to clipboard.")
        print("Total parts:", #dumpChunks)

        if #dumpChunks > 1 then

            print("")
            print("Next:")
            print("AliceDumpPart(2)")

        end

        print("")
        print("Info:")
        print("AliceDumpInfo()")


    else


        print("")
        print("==============================================================")
        print("NO FILE / CLIPBOARD API")
        print("==============================================================")
        print("Dump will be printed below.")
        print("")
        print(finalText)

    end

end


--==============================================================
-- OPTIONAL FIRST MATCH SUMMARY
--==============================================================

print("")
print(
    "AliceDeepDump V3 finished."
)

print(
    "Run AliceDumpInfo() for dump information."
)

--==============================================================
-- END
--==============================================================
