--==============================================================
--              ALICE TRADE V5 LITE
--==============================================================
-- Passive only.
-- No FireServer / InvokeServer.
-- Fokus: line 711 / 715 / 716 / 719
--==============================================================

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local FILE = "AliceTrade_V5_Lite.txt"

local TARGET_LINES = {
    [711] = true,
    [715] = true,
    [716] = true,
    [719] = true,
}

local out = {}

local function log(...)
    local t = {}
    for i = 1, select("#", ...) do
        t[#t + 1] = tostring(select(i, ...))
    end
    out[#out + 1] = table.concat(t, " ")
end

local function divider(title)
    log("")
    log("==============================================")
    log(title)
    log("==============================================")
end

local function fullname(obj)
    local ok, result = pcall(function()
        return obj:GetFullName()
    end)

    return ok and result or tostring(obj)
end

local function getInfo(fn, mode)
    local ok, result = pcall(debug.info, fn, mode)

    if ok then
        return result
    end

    return nil
end

divider("ALICE TRADE V5 LITE")

log("Player:", LP.Name)
log("PlaceId:", game.PlaceId)

if type(getgc) ~= "function" then
    log("getgc unavailable")
else
    local gc = getgc(true)
    local matched = 0

    for _, fn in ipairs(gc) do

        if type(fn) == "function" then

            local source = getInfo(fn, "s")

            if source
            and tostring(source):find(
                "TradeController",
                1,
                true
            ) then

                local lineNumber = getInfo(fn, "l")

                if TARGET_LINES[lineNumber] then

                    matched += 1

                    divider(
                        "FUNCTION #" ..
                        matched ..
                        " | LINE " ..
                        tostring(lineNumber)
                    )

                    local name =
                        getInfo(fn, "n")

                    log(
                        "Name:",
                        name and name ~= ""
                            and name
                            or "<anonymous>"
                    )

                    log(
                        "Source:",
                        source
                    )

                    --==========================================
                    -- CONSTANTS
                    --==========================================

                    log("")
                    log("-- CONSTANTS --")

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

                            for i, c
                                in pairs(constants) do

                                if type(c) == "string"
                                or type(c) == "number"
                                or type(c) == "boolean" then

                                    log(
                                        "C[" ..
                                        tostring(i) ..
                                        "] =",
                                        tostring(c)
                                    )
                                end
                            end
                        end
                    end

                    --==========================================
                    -- INSTANCE UPVALUES
                    --==========================================

                    log("")
                    log("-- INSTANCE UPVALUES --")

                    if debug
                    and type(debug.getupvalues)
                        == "function" then

                        local okU, ups =
                            pcall(
                                debug.getupvalues,
                                fn
                            )

                        if okU
                        and type(ups)
                            == "table" then

                            for i, up
                                in pairs(ups) do

                                if typeof(up)
                                    == "Instance" then

                                    log(
                                        "U[" ..
                                        tostring(i) ..
                                        "]",
                                        up.ClassName,
                                        fullname(up)
                                    )

                                    if up:IsA("RemoteEvent")
                                    or up:IsA("RemoteFunction") then

                                        log(
                                            ">>> REMOTE:",
                                            up.Name,
                                            "<<<"
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

    divider("SUMMARY")

    log(
        "Matched functions:",
        matched
    )
end

local text =
    table.concat(out, "\n")

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
    else
        warn(err)
        print(text)
    end

else
    print(text)
end
