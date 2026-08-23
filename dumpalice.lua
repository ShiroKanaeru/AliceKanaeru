--==============================================================
--              ALICE TRADE TARGETED DUMP V5
--==============================================================
-- Passive only.
-- No FireServer / InvokeServer.
--==============================================================

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local FILE = "AliceTradeTargeted_V5.txt"

local TARGET_LINES = {
    [382] = true,
    [711] = true,
    [715] = true,
    [716] = true,
    [719] = true,
    [750] = true,
    [618] = true,
    [658] = true,
    [686] = true,
    [703] = true,
}

local TARGET_REMOTE_NAMES = {
    ["r1da57731ba364e538fc0686aa098704a"] = true,
    ["rafc8477ddfa44695aaa5aaf0f12108db"] = true,
    ["rc2ceb901dae040328d00a26f5c849bf6"] = true,
    ["r6018fd612b014d28a1f75906c692af21"] = true,
    ["r52ec5ac453654b74affcbbeaf52ec06e"] = true,
    ["r6a00421ae5524d2dbe4ac737498585fa"] = true,
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

local function fullname(obj)
    local ok, result = pcall(function()
        return obj:GetFullName()
    end)

    return ok and result or tostring(obj)
end

local function isTradeController(fn)
    if not debug or type(debug.info) ~= "function" then
        return false
    end

    local ok, source = pcall(debug.info, fn, "s")

    return ok
        and tostring(source):find("TradeController", 1, true) ~= nil
end

local function getLine(fn)
    if not debug or type(debug.info) ~= "function" then
        return nil
    end

    local ok, line = pcall(debug.info, fn, "l")

    if ok then
        return line
    end

    return nil
end

local function hasTargetRemote(fn)
    if not debug or type(debug.getupvalues) ~= "function" then
        return false
    end

    local ok, ups = pcall(debug.getupvalues, fn)

    if not ok or type(ups) ~= "table" then
        return false
    end

    for _, up in pairs(ups) do
        if typeof(up) == "Instance"
        and (
            up:IsA("RemoteEvent")
            or up:IsA("RemoteFunction")
        ) then

            if TARGET_REMOTE_NAMES[up.Name] then
                return true
            end
        end
    end

    return false
end

local function dumpFunction(fn, index)
    divider("TARGET FUNCTION #" .. index)

    local source = "?"
    local name = "<anonymous>"
    local lineNumber = "?"

    if debug and type(debug.info) == "function" then

        local okS, s = pcall(debug.info, fn, "s")
        if okS then
            source = s
        end

        local okN, n = pcall(debug.info, fn, "n")
        if okN and n and n ~= "" then
            name = n
        end

        local okL, l = pcall(debug.info, fn, "l")
        if okL then
            lineNumber = l
        end
    end

    log("Source:", source)
    log("Name:", name)
    log("Line:", lineNumber)

    --==========================================================
    -- CONSTANTS
    --==========================================================

    log("")
    log("----- CONSTANTS -----")

    if debug and type(debug.getconstants) == "function" then

        local ok, constants =
            pcall(debug.getconstants, fn)

        if ok and type(constants) == "table" then

            for i, c in pairs(constants) do
                log(
                    "C[" .. tostring(i) .. "] =",
                    tostring(c),
                    "[" .. typeof(c) .. "]"
                )
            end

        else
            log("getconstants failed:", tostring(constants))
        end

    else
        log("debug.getconstants unavailable")
    end

    --==========================================================
    -- UPVALUES
    --==========================================================

    log("")
    log("----- UPVALUES -----")

    if debug and type(debug.getupvalues) == "function" then

        local ok, ups =
            pcall(debug.getupvalues, fn)

        if ok and type(ups) == "table" then

            for i, up in pairs(ups) do

                local t = typeof(up)

                if t == "Instance" then

                    log(
                        "U[" .. tostring(i) .. "]",
                        up.ClassName,
                        fullname(up)
                    )

                    if up:IsA("RemoteEvent")
                    or up:IsA("RemoteFunction") then

                        log(
                            "   >>> REMOTE:",
                            up.Name,
                            "<<<"
                        )
                    end

                elseif t == "string"
                or t == "number"
                or t == "boolean" then

                    log(
                        "U[" .. tostring(i) .. "] =",
                        tostring(up),
                        "[" .. t .. "]"
                    )

                elseif t == "function" then

                    local fnName = "<anonymous>"
                    local fnSource = "?"
                    local fnLine = "?"

                    if debug and type(debug.info) == "function" then

                        local okN, n =
                            pcall(debug.info, up, "n")

                        if okN and n and n ~= "" then
                            fnName = n
                        end

                        local okS, s =
                            pcall(debug.info, up, "s")

                        if okS then
                            fnSource = s
                        end

                        local okL, l =
                            pcall(debug.info, up, "l")

                        if okL then
                            fnLine = l
                        end
                    end

                    log(
                        "U[" .. tostring(i) .. "] = <function>",
                        "Name=" .. tostring(fnName),
                        "Source=" .. tostring(fnSource),
                        "Line=" .. tostring(fnLine)
                    )

                elseif t == "table" then

                    log(
                        "U[" .. tostring(i) .. "] = <table>"
                    )

                    local shown = 0

                    for k, v in pairs(up) do

                        shown += 1

                        if shown > 30 then
                            log("    ... truncated ...")
                            break
                        end

                        local vt = typeof(v)

                        if vt == "Instance" then
                            log(
                                "    [" .. tostring(k) .. "]",
                                v.ClassName,
                                fullname(v)
                            )
                        elseif vt == "string"
                        or vt == "number"
                        or vt == "boolean" then
                            log(
                                "    [" .. tostring(k) .. "] =",
                                tostring(v)
                            )
                        else
                            log(
                                "    [" .. tostring(k) .. "] = <" ..
                                vt ..
                                ">"
                            )
                        end
                    end

                else

                    log(
                        "U[" .. tostring(i) .. "] = <" ..
                        t ..
                        ">"
                    )
                end
            end

        else
            log("getupvalues failed:", tostring(ups))
        end

    else
        log("debug.getupvalues unavailable")
    end

    --==========================================================
    -- PROTOS / NESTED FUNCTIONS
    --==========================================================

    log("")
    log("----- PROTOS -----")

    local protoGetter =
        (debug and debug.getprotos)
        or getprotos

    if type(protoGetter) == "function" then

        local ok, protos =
            pcall(protoGetter, fn)

        if ok and type(protos) == "table" then

            log("Proto count:", #protos)

            for i, proto in ipairs(protos) do

                local pn = "<anonymous>"
                local ps = "?"
                local pl = "?"

                if debug and type(debug.info) == "function" then

                    local okN, n =
                        pcall(debug.info, proto, "n")

                    if okN and n and n ~= "" then
                        pn = n
                    end

                    local okS, s =
                        pcall(debug.info, proto, "s")

                    if okS then
                        ps = s
                    end

                    local okL, l =
                        pcall(debug.info, proto, "l")

                    if okL then
                        pl = l
                    end
                end

                log(
                    "Proto[" .. i .. "]",
                    "Name=" .. tostring(pn),
                    "Source=" .. tostring(ps),
                    "Line=" .. tostring(pl)
                )

                if debug
                and type(debug.getconstants) == "function" then

                    local okC, constants =
                        pcall(
                            debug.getconstants,
                            proto
                        )

                    if okC
                    and type(constants) == "table" then

                        for ci, c in pairs(constants) do

                            if type(c) == "string" then

                                log(
                                    "    C[" ..
                                    tostring(ci) ..
                                    "] =",
                                    c
                                )
                            end
                        end
                    end
                end
            end

        else
            log(
                "getprotos failed:",
                tostring(protos)
            )
        end

    else
        log("getprotos unavailable")
    end
end

--==============================================================
-- HEADER
--==============================================================

divider("ALICE TRADE TARGETED DUMP V5")

log("Player:", LP.Name)
log("PlaceId:", game.PlaceId)

--==============================================================
-- FIND TARGET FUNCTIONS
--==============================================================

local targets = {}

if type(getgc) == "function" then

    local objects = getgc(true)

    for _, fn in ipairs(objects) do

        if type(fn) == "function"
        and isTradeController(fn) then

            local line = getLine(fn)

            if TARGET_LINES[line]
            or hasTargetRemote(fn) then

                targets[#targets + 1] = fn
            end
        end
    end
end

log("Target functions:", #targets)

for i, fn in ipairs(targets) do
    dumpFunction(fn, i)
end

--==============================================================
-- DECOMPILE TRADECONTROLLER SCRIPT
--==============================================================

divider("TRADECONTROLLER SOURCE")

local playerScripts =
    LP:FindFirstChild("PlayerScripts")

local tradeScript =
    playerScripts
    and playerScripts:FindFirstChild(
        "TradeController"
    )

if tradeScript
and type(decompile) == "function" then

    local ok, source =
        pcall(
            decompile,
            tradeScript
        )

    if ok and type(source) == "string" then

        log("Decompile length:", #source)

        log("")
        log(
            "NOTE: Source below is complete TradeController decompile."
        )

        log(source)

    else
        log(
            "decompile failed:",
            tostring(source)
        )
    end

else
    log(
        "TradeController/decompile unavailable"
    )
end

--==============================================================
-- SAVE
--==============================================================

local text =
    table.concat(output, "\n")

if type(writefile) == "function" then

    local ok, err =
        pcall(function()

            writefile(
                FILE,
                text
            )

        end)

    if ok then
        print("DONE:", FILE)
        print("Chars:", #text)
        print("Targets:", #targets)
    else
        warn(err)
        print(text)
    end

else
    print(text)
end
