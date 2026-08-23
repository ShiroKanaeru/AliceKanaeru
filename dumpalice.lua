--==============================================================
--             ALICE TRADECONTROLLER DEEP DUMP V3
--==============================================================
-- Passive only.
--
-- Fokus:
--   Players.LocalPlayer.PlayerScripts.TradeController
--   Players.LocalPlayer.PlayerScripts.CarryPrompSetup
--
-- Dump:
--   * all matching closures from getgc()
--   * function name/source
--   * all constants
--   * all upvalues
--   * Instance paths/classes
--   * RemoteEvent / RemoteFunction references
--   * shallow table contents
--
-- Tidak:
--   FireServer()
--   InvokeServer()
--   modify upvalues/constants
--==============================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FILE_NAME = "AliceTradeController_V3.txt"

local TARGET_SOURCES = {
    "TradeController",
    "CarryPrompSetup"
}

local output = {}

local function out(...)
    local p = {}

    for i = 1, select("#", ...) do
        p[#p + 1] = tostring(select(i, ...))
    end

    output[#output + 1] = table.concat(p, " ")
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

local function isTargetSource(source)
    source = tostring(source)

    for _, word in ipairs(TARGET_SOURCES) do
        if source:find(word, 1, true) then
            return true
        end
    end

    return false
end

local function dumpInstance(value, prefix)
    prefix = prefix or ""

    out(
        prefix ..
        "Instance:",
        fullName(value),
        "| Class=" .. value.ClassName
    )

    if value:IsA("RemoteEvent") then
        out(prefix .. ">>> REMOTE EVENT <<<")
    elseif value:IsA("RemoteFunction") then
        out(prefix .. ">>> REMOTE FUNCTION <<<")
    end
end

local function dumpTable(tbl, prefix, maxItems)
    prefix = prefix or ""
    maxItems = maxItems or 50

    local count = 0

    for key, value in pairs(tbl) do
        count += 1

        if count > maxItems then
            out(prefix .. "... table truncated ...")
            break
        end

        local t = typeof(value)

        if t == "Instance" then
            out(
                prefix ..
                "[" ..
                tostring(key) ..
                "] =>"
            )

            dumpInstance(value, prefix .. "  ")

        elseif t == "string"
        or t == "number"
        or t == "boolean"
        or t == "nil" then

            out(
                prefix ..
                "[" ..
                tostring(key) ..
                "] =",
                tostring(value),
                "[" .. t .. "]"
            )

        elseif t == "table" then

            out(
                prefix ..
                "[" ..
                tostring(key) ..
                "] = <table>"
            )

            local subCount = 0

            for k2, v2 in pairs(value) do
                subCount += 1

                if subCount > 15 then
                    out(prefix .. "    ...")
                    break
                end

                local t2 = typeof(v2)

                if t2 == "Instance" then

                    out(
                        prefix ..
                        "    [" ..
                        tostring(k2) ..
                        "] =>"
                    )

                    dumpInstance(
                        v2,
                        prefix .. "      "
                    )

                elseif t2 == "string"
                or t2 == "number"
                or t2 == "boolean" then

                    out(
                        prefix ..
                        "    [" ..
                        tostring(k2) ..
                        "] =",
                        tostring(v2),
                        "[" .. t2 .. "]"
                    )

                else

                    out(
                        prefix ..
                        "    [" ..
                        tostring(k2) ..
                        "] = <" ..
                        t2 ..
                        ">"
                    )

                end
            end

        else

            out(
                prefix ..
                "[" ..
                tostring(key) ..
                "] = <" ..
                t ..
                ">"
            )

        end
    end
end


--==============================================================
-- HEADER
--==============================================================

divider("ALICE TRADECONTROLLER DEEP DUMP V3")

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

divider("CAPABILITIES")

out("getgc:", type(getgc))
out(
    "debug.info:",
    debug and type(debug.info) or "nil"
)
out(
    "debug.getconstants:",
    debug and type(debug.getconstants) or "nil"
)
out(
    "debug.getupvalues:",
    debug and type(debug.getupvalues) or "nil"
)
out("writefile:", type(writefile))


--==============================================================
-- FIND TARGET LOCAL SCRIPTS
--==============================================================

divider("TARGET SCRIPTS")

local playerScripts =
    LocalPlayer:FindFirstChild("PlayerScripts")

if playerScripts then

    for _, obj in ipairs(
        playerScripts:GetDescendants()
    ) do

        if obj:IsA("LocalScript") then

            if isTargetSource(obj.Name)
            or isTargetSource(fullName(obj)) then

                out(
                    "[SCRIPT]",
                    fullName(obj)
                )
            end
        end
    end
end


--==============================================================
-- GETGC TARGET FUNCTIONS
--==============================================================

divider("TARGET GC FUNCTIONS")

local targetFunctions = {}
local scannedFunctions = 0

if type(getgc) == "function"
and debug
and type(debug.info) == "function" then

    local okGC, objects =
        pcall(getgc, true)

    if okGC and type(objects) == "table" then

        for _, value in ipairs(objects) do

            if type(value) == "function" then

                scannedFunctions += 1

                local okSource, source =
                    pcall(
                        debug.info,
                        value,
                        "s"
                    )

                if okSource
                and isTargetSource(source) then

                    targetFunctions[
                        #targetFunctions + 1
                    ] = {
                        fn = value,
                        source = source
                    }
                end
            end
        end
    end
end

out("Functions scanned:", scannedFunctions)
out("Target functions:", #targetFunctions)


--==============================================================
-- DUMP EACH TARGET FUNCTION
--==============================================================

for index, entry
    in ipairs(targetFunctions) do

    local fn = entry.fn

    divider(
        "FUNCTION " ..
        index ..
        "/" ..
        #targetFunctions
    )

    out("Source:", entry.source)

    if debug and type(debug.info) == "function" then

        local okName, name =
            pcall(
                debug.info,
                fn,
                "n"
            )

        if okName then
            out(
                "Name:",
                name ~= "" and name or "<anonymous>"
            )
        end

        local okLine, line =
            pcall(
                debug.info,
                fn,
                "l"
            )

        if okLine then
            out("Line:", line)
        end

        local okParams, params =
            pcall(
                debug.info,
                fn,
                "a"
            )

        if okParams then
            out(
                "ArgInfo:",
                tostring(params)
            )
        end
    end


    --==========================================================
    -- CONSTANTS
    --==========================================================

    out("")
    out("----- CONSTANTS -----")

    if debug
    and type(debug.getconstants)
        == "function" then

        local okConst, constants =
            pcall(
                debug.getconstants,
                fn
            )

        if okConst
        and type(constants) == "table" then

            for cIndex, constant
                in pairs(constants) do

                out(
                    "Constant[" ..
                    tostring(cIndex) ..
                    "] =",
                    tostring(constant),
                    "[" ..
                    typeof(constant) ..
                    "]"
                )
            end

        else
            out(
                "getconstants failed:",
                tostring(constants)
            )
        end

    else
        out("debug.getconstants unavailable")
    end


    --==========================================================
    -- UPVALUES
    --==========================================================

    out("")
    out("----- UPVALUES -----")

    if debug
    and type(debug.getupvalues)
        == "function" then

        local okUps, upvalues =
            pcall(
                debug.getupvalues,
                fn
            )

        if okUps
        and type(upvalues) == "table" then

            for upIndex, up
                in pairs(upvalues) do

                local t = typeof(up)

                out("")
                out(
                    "Upvalue[" ..
                    tostring(upIndex) ..
                    "] Type=" ..
                    t
                )

                if t == "Instance" then

                    dumpInstance(up, "  ")

                elseif t == "table" then

                    dumpTable(
                        up,
                        "  ",
                        50
                    )

                elseif t == "string"
                or t == "number"
                or t == "boolean"
                or t == "nil" then

                    out(
                        "  Value:",
                        tostring(up)
                    )

                elseif t == "function" then

                    out(
                        "  Function:",
                        tostring(up)
                    )

                    if debug
                    and type(debug.info)
                        == "function" then

                        local okUSource,
                            uSource =
                            pcall(
                                debug.info,
                                up,
                                "s"
                            )

                        if okUSource then
                            out(
                                "  Function Source:",
                                uSource
                            )
                        end

                        local okUName,
                            uName =
                            pcall(
                                debug.info,
                                up,
                                "n"
                            )

                        if okUName then
                            out(
                                "  Function Name:",
                                uName ~= ""
                                    and uName
                                    or "<anonymous>"
                            )
                        end
                    end

                else

                    out(
                        "  Value:",
                        tostring(up)
                    )
                end
            end

        else

            out(
                "getupvalues failed:",
                tostring(upvalues)
            )
        end

    else
        out("debug.getupvalues unavailable")
    end
end


--==============================================================
-- ALL REMOTE INSTANCE UPVALUES SUMMARY
--==============================================================

divider("REMOTE UPVALUE SUMMARY")

local remoteRefs = {}
local seenRemote = {}

for _, entry in ipairs(targetFunctions) do

    local fn = entry.fn

    if debug
    and type(debug.getupvalues)
        == "function" then

        local ok, ups =
            pcall(
                debug.getupvalues,
                fn
            )

        if ok
        and type(ups) == "table" then

            for _, up in pairs(ups) do

                if typeof(up) == "Instance"
                and (
                    up:IsA("RemoteEvent")
                    or up:IsA("RemoteFunction")
                ) then

                    if not seenRemote[up] then

                        seenRemote[up] = true

                        remoteRefs[
                            #remoteRefs + 1
                        ] = {
                            instance = up,
                            source = entry.source
                        }
                    end

                elseif type(up) == "table" then

                    for key, value in pairs(up) do

                        if typeof(value)
                            == "Instance"
                        and (
                            value:IsA("RemoteEvent")
                            or value:IsA("RemoteFunction")
                        ) then

                            if not seenRemote[value] then

                                seenRemote[value] = true

                                remoteRefs[
                                    #remoteRefs + 1
                                ] = {
                                    instance = value,
                                    source = entry.source,
                                    key = key
                                }
                            end
                        end
                    end
                end
            end
        end
    end
end

for i, data in ipairs(remoteRefs) do

    local remote = data.instance

    out("")
    out(
        "[REMOTE REF #" ..
        i ..
        "]"
    )

    out("Class:", remote.ClassName)
    out("Name:", remote.Name)
    out("Path:", fullName(remote))
    out("From source:", data.source)

    if data.key ~= nil then
        out(
            "Table key:",
            tostring(data.key)
        )
    end
end

out("")
out(
    "Unique remote references:",
    #remoteRefs
)


--==============================================================
-- SUMMARY
--==============================================================

divider("SUMMARY")

out("Functions scanned:", scannedFunctions)
out("Target functions:", #targetFunctions)
out("Remote refs:", #remoteRefs)

local finalText =
    table.concat(
        output,
        "\n"
    )


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
        print(
            "=============================================="
        )
        print(
            "ALICE TRADECONTROLLER V3 COMPLETE"
        )
        print(
            "Saved:",
            FILE_NAME
        )
        print(
            "Characters:",
            #finalText
        )
        print(
            "Remote refs:",
            #remoteRefs
        )
        print(
            "=============================================="
        )

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
