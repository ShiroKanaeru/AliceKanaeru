--==============================================================
--            ALICE TRADE CONTEXT MAPPER V4
--==============================================================
-- Passive only
-- No FireServer / InvokeServer
--==============================================================

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local FILE = "AliceTradeContext_V4.txt"

local TARGET_REMOTES = {
    ["r6018fd612b014d28a1f75906c692af21"] = "Candidate_GetInventory",
    ["rc2ceb901dae040328d00a26f5c849bf6"] = "Candidate_UpdateOffer",
    ["r1da57731ba364e538fc0686aa098704a"] = "Candidate_StateAction",
    ["r52ec5ac453654b74affcbbeaf52ec06e"] = "Candidate_TradeRequest",
    ["r6a00421ae5524d2dbe4ac737498585fa"] = "Candidate_InviteResponse",
    ["rafc8477ddfa44695aaa5aaf0f12108db"] = "UnknownTradeRemote",
}

local out = {}

local function log(...)
    local t = {}
    for i = 1, select("#", ...) do
        t[#t + 1] = tostring(select(i, ...))
    end
    out[#out + 1] = table.concat(t, " ")
end

local function fullname(obj)
    local ok, result = pcall(function()
        return obj:GetFullName()
    end)
    return ok and result or tostring(obj)
end

local function divider(title)
    log("")
    log("==============================================================")
    log(title)
    log("==============================================================")
end

local function sourceIsTrade(fn)
    if not debug or type(debug.info) ~= "function" then
        return false
    end

    local ok, src = pcall(debug.info, fn, "s")
    return ok
        and tostring(src):find("TradeController", 1, true) ~= nil
end

divider("ALICE TRADE CONTEXT MAPPER V4")

log("Player:", LP.Name)
log("PlaceId:", game.PlaceId)

if type(getgc) ~= "function" then
    log("getgc unavailable")
else
    local gc = getgc(true)

    local matches = 0

    for _, fn in ipairs(gc) do
        if type(fn) == "function"
        and sourceIsTrade(fn) then

            local remoteHits = {}

            if debug
            and type(debug.getupvalues) == "function" then

                local okU, ups =
                    pcall(debug.getupvalues, fn)

                if okU and type(ups) == "table" then

                    for upIndex, up in pairs(ups) do
                        if typeof(up) == "Instance"
                        and (
                            up:IsA("RemoteEvent")
                            or up:IsA("RemoteFunction")
                        ) then

                            local mapped =
                                TARGET_REMOTES[up.Name]

                            if mapped then
                                remoteHits[#remoteHits + 1] = {
                                    index = upIndex,
                                    instance = up,
                                    label = mapped
                                }
                            end
                        end
                    end
                end
            end

            if #remoteHits > 0 then
                matches += 1

                divider("MATCH #" .. matches)

                local okS, src =
                    pcall(debug.info, fn, "s")

                local okN, name =
                    pcall(debug.info, fn, "n")

                local okL, line =
                    pcall(debug.info, fn, "l")

                log(
                    "Source:",
                    okS and src or "?"
                )

                log(
                    "Name:",
                    okN and name ~= ""
                        and name
                        or "<anonymous>"
                )

                log(
                    "Line:",
                    okL and line or "?"
                )

                log("")
                log("----- REMOTES -----")

                for _, hit in ipairs(remoteHits) do
                    local r = hit.instance

                    log(
                        "Upvalue[" ..
                        tostring(hit.index) ..
                        "]"
                    )

                    log(
                        "Label:",
                        hit.label
                    )

                    log(
                        "Class:",
                        r.ClassName
                    )

                    log(
                        "Name:",
                        r.Name
                    )

                    log(
                        "Path:",
                        fullname(r)
                    )

                    log("")
                end

                log("----- CONSTANTS -----")

                if debug
                and type(debug.getconstants)
                    == "function" then

                    local okC, constants =
                        pcall(
                            debug.getconstants,
                            fn
                        )

                    if okC
                    and type(constants)
                        == "table" then

                        for index, c
                            in pairs(constants) do

                            if type(c) == "string"
                            or type(c) == "number"
                            or type(c) == "boolean" then

                                log(
                                    "C[" ..
                                    tostring(index) ..
                                    "] =",
                                    tostring(c)
                                )
                            end
                        end
                    end
                end

                log("")
                log("----- ALL INSTANCE UPVALUES -----")

                if debug
                and type(debug.getupvalues)
                    == "function" then

                    local okU, ups =
                        pcall(
                            debug.getupvalues,
                            fn
                        )

                    if okU
                    and type(ups) == "table" then

                        for index, up
                            in pairs(ups) do

                            if typeof(up)
                                == "Instance" then

                                log(
                                    "U[" ..
                                    tostring(index) ..
                                    "]",
                                    up.ClassName,
                                    fullname(up)
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    divider("SUMMARY")

    log("Mapped closures:", matches)
end

local text =
    table.concat(out, "\n")

if type(writefile) == "function" then
    local ok, err = pcall(function()
        writefile(FILE, text)
    end)

    if ok then
        print("DONE:", FILE)
        print("Chars:", #text)
    else
        warn(err)
        print(text)
    end
else
    print(text)
end
