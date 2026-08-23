--==============================================================
--                    ALICE TRADE DUMPER
--==============================================================
-- Passive trade-only client dump
--
-- Tidak:
--   FireServer()
--   InvokeServer()
--   modify upvalue
--   modify constant
--
-- Output:
--   AliceTradeDump.txt
--==============================================================

local FILE_NAME = "AliceTradeDump.txt"

local TARGET_WORDS = {
    "Trade",
    "TradeGetInventory",
    "TradeUpdateOffer",
    "TradeSetReady",
    "TradeAccept",
    "TradeConfirm",
    "TradeCancel",

    "Offer",
    "Ready",
    "Confirm",
    "Cancel",

    "Inventory",
    "Item",
    "Items",
    "Amount",
    "Quantity",
    "Count",

    "TargetPlayer",
    "PlayerId",
    "UserId",

    "TradeId",
    "SessionId",
    "RequestId",
    "Nonce"
}


--==============================================================
-- OUTPUT
--==============================================================

local output = {}

local function safeName(obj)
    local ok, result = pcall(function()
        return obj:GetFullName()
    end)

    return ok and result or tostring(obj)
end


local function line(...)
    local t = {}

    for i = 1, select("#", ...) do
        t[#t + 1] = tostring(select(i, ...))
    end

    output[#output + 1] = table.concat(t, " ")
end


local function divider(title)
    line("")
    line("==============================================================")
    line(title)
    line("==============================================================")
end


local function matchTarget(text)
    text = tostring(text):lower()

    for _, word in ipairs(TARGET_WORDS) do
        if text:find(word:lower(), 1, true) then
            return true, word
        end
    end

    return false
end


--==============================================================
-- HEADER
--==============================================================

divider("ALICE TRADE DUMPER")

line("PlaceId:", game.PlaceId)
line("GameId :", game.GameId)
line("JobId  :", game.JobId)

if identifyexecutor then
    local ok, result = pcall(identifyexecutor)

    if ok then
        line("Executor:", result)
    end
end


--==============================================================
-- CAPABILITIES
--==============================================================

divider("CAPABILITIES")

line("writefile          :", type(writefile))
line("decompile          :", type(decompile))
line("getgc              :", type(getgc))
line("getconnections     :", type(getconnections))

line(
    "debug.getconstants :",
    debug and type(debug.getconstants) or "nil"
)

line(
    "debug.getupvalues  :",
    debug and type(debug.getupvalues) or "nil"
)

line(
    "debug.info         :",
    debug and type(debug.info) or "nil"
)


--==============================================================
-- TRADE REMOTES
--==============================================================

divider("TRADE REMOTES")

local tradeRemotes = {}

for _, obj in ipairs(game:GetDescendants()) do

    if obj:IsA("RemoteEvent")
    or obj:IsA("RemoteFunction") then

        local path = safeName(obj)

        local matched, keyword =
            matchTarget(obj.Name .. " " .. path)

        if matched then

            tradeRemotes[#tradeRemotes + 1] = obj

            line(
                "[REMOTE]",
                obj.ClassName,
                "|",
                obj.Name,
                "|",
                path,
                "| match=",
                keyword
            )

        end
    end
end

line("")
line("Trade remotes:", #tradeRemotes)


--==============================================================
-- TRADE MODULES
--==============================================================

divider("TRADE MODULES")

local tradeModules = {}

for _, obj in ipairs(game:GetDescendants()) do

    if obj:IsA("ModuleScript") then

        local path = safeName(obj)

        local matched, keyword =
            matchTarget(obj.Name .. " " .. path)

        if matched then

            tradeModules[#tradeModules + 1] = obj

            line(
                "[MODULE]",
                path,
                "| match=",
                keyword
            )

        end
    end
end

line("")
line("Trade modules:", #tradeModules)


--==============================================================
-- DECOMPILE TRADE MODULES
--==============================================================

divider("DECOMPILE TRADE MODULES")

if type(decompile) == "function" then

    for index, module in ipairs(tradeModules) do

        line("")
        line(
            "[DECOMPILE " ..
            index ..
            "/" ..
            #tradeModules ..
            "]"
        )

        line(safeName(module))

        local ok, source =
            pcall(decompile, module)

        if ok and type(source) == "string" then

            local sourceLower = source:lower()

            local found = {}

            for _, word in ipairs(TARGET_WORDS) do

                if sourceLower:find(
                    word:lower(),
                    1,
                    true
                ) then

                    found[#found + 1] = word
                end
            end

            line(
                "Keywords:",
                table.concat(found, ", ")
            )

            for _, word in ipairs(found) do

                local lowerWord = word:lower()
                local startPos = 1
                local hit = 0

                while true do

                    local pos =
                        sourceLower:find(
                            lowerWord,
                            startPos,
                            true
                        )

                    if not pos then
                        break
                    end

                    hit += 1

                    local snippetStart =
                        math.max(1, pos - 500)

                    local snippetEnd =
                        math.min(
                            #source,
                            pos + #word + 900
                        )

                    line("")
                    line(
                        "[MATCH " ..
                        word ..
                        " #" ..
                        hit ..
                        "]"
                    )

                    line(
                        source:sub(
                            snippetStart,
                            snippetEnd
                        )
                    )

                    startPos =
                        pos + #word
                end
            end

        else
            line(
                "decompile failed:",
                tostring(source)
            )
        end
    end

else
    line("decompile() unavailable")
end


--==============================================================
-- GETGC TRADE CONSTANT SEARCH
--==============================================================

divider("GETGC TRADE CONSTANTS")

if type(getgc) == "function"
and debug
and type(debug.getconstants) == "function" then

    local okGC, gcObjects =
        pcall(getgc, true)

    if okGC
    and type(gcObjects) == "table" then

        local functionCount = 0
        local matchCount = 0

        for _, value in ipairs(gcObjects) do

            if type(value) == "function" then

                functionCount += 1

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
                                matchTarget(constant)

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

                        matchCount += 1

                        line("")
                        line(
                            "[FUNCTION MATCH #" ..
                            matchCount ..
                            "]"
                        )

                        if type(debug.info)
                            == "function" then

                            local okSource, source =
                                pcall(
                                    debug.info,
                                    value,
                                    "s"
                                )

                            if okSource then
                                line(
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

                                line(
                                    "Name:",
                                    name
                                )
                            end
                        end


                        for _, match in ipairs(matches) do

                            line(
                                "Constant[" ..
                                tostring(match.index) ..
                                "] =",
                                match.value,
                                "| match=",
                                match.keyword
                            )

                        end


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

                                for upIndex, upValue
                                    in pairs(upvalues) do

                                    local t =
                                        typeof(upValue)

                                    if t == "string"
                                    or t == "number"
                                    or t == "boolean"
                                    or t == "Instance" then

                                        line(
                                            "  Upvalue[" ..
                                            tostring(upIndex) ..
                                            "] =",
                                            t == "Instance"
                                                and safeName(upValue)
                                                or tostring(upValue)
                                        )

                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        line("")
        line("Functions scanned:", functionCount)
        line("Trade matches    :", matchCount)

    else
        line(
            "getgc failed:",
            tostring(gcObjects)
        )
    end

else
    line(
        "getgc/debug.getconstants unavailable"
    )
end


--==============================================================
-- TRADE ONCLIENTEVENT HANDLERS
--==============================================================

divider("TRADE CLIENT EVENT HANDLERS")

if type(getconnections) == "function" then

    for _, remote in ipairs(tradeRemotes) do

        if remote:IsA("RemoteEvent") then

            local ok, connections =
                pcall(
                    getconnections,
                    remote.OnClientEvent
                )

            if ok
            and type(connections) == "table"
            and #connections > 0 then

                line("")
                line(
                    "[EVENT]",
                    safeName(remote)
                )

                line(
                    "Connections:",
                    #connections
                )

                for index, connection
                    in ipairs(connections) do

                    local fn =
                        connection.Function

                    if type(fn) == "function" then

                        line(
                            "Handler #" ..
                            index ..
                            ":",
                            tostring(fn)
                        )

                        if debug
                        and type(debug.info)
                            == "function" then

                            local okSource, source =
                                pcall(
                                    debug.info,
                                    fn,
                                    "s"
                                )

                            if okSource then
                                line(
                                    "  Source:",
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

                                line(
                                    "  Name:",
                                    name
                                )
                            end
                        end
                    end
                end
            end
        end
    end

else
    line(
        "getconnections() unavailable"
    )
end


--==============================================================
-- REMOTE OBJECT DETAIL
--==============================================================

divider("TRADE REMOTE DETAILS")

for _, remote in ipairs(tradeRemotes) do

    line("")
    line("[REMOTE]")
    line("Name :", remote.Name)
    line("Class:", remote.ClassName)
    line("Path :", safeName(remote))

    local parent = remote.Parent

    if parent then
        line(
            "Parent:",
            safeName(parent)
        )
    end
end


--==============================================================
-- SUMMARY
--==============================================================

divider("SUMMARY")

line("Trade remotes :", #tradeRemotes)
line("Trade modules :", #tradeModules)

local finalText =
    table.concat(output, "\n")


--==============================================================
-- SAVE
--==============================================================

print(finalText)

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
        print("========================================")
        print("ALICE TRADE DUMP COMPLETE")
        print("Saved:", FILE_NAME)
        print("Characters:", #finalText)
        print("========================================")

    else

        warn(
            "writefile failed:",
            err
        )
    end

else

    warn(
        "writefile() unavailable"
    )
end
