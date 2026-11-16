local addon, test, equal = ...

local function fixture(action)
    local savedDebug, savedLog, savedState = addon.db.debug, addon.db.log, addon.traceState
    local savedChat, savedClock = DEFAULT_CHAT_FRAME, GetTime
    local f = { messages = {}, now = 0 }
    addon.db.debug, addon.db.log, addon.traceState = false, {}, nil
    DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, message)
            f.messages[#f.messages + 1] = message
        end,
    }
    GetTime = function()
        return f.now
    end
    local ok, err = pcall(action, f)
    addon.db.debug, addon.db.log, addon.traceState = savedDebug, savedLog, savedState
    DEFAULT_CHAT_FRAME, GetTime = savedChat, savedClock
    assert(ok, err)
end

test("debug on/off is deterministic and disabled tracing does no formatting or retention", function()
    fixture(function(f)
        addon:Trace("test", 5, "%d", "would fail if formatted")
        equal(addon.traceState, nil)
        equal(#addon.db.log, 0)
        equal(#f.messages, 0)
        addon:Command("debug on")
        addon:Command("debug on")
        equal(addon.db.debug, true)
        assert(table.concat(f.messages, "\n"):find("12:00:00 [state] v" .. addon.version, 1, true))
        addon:Command("debug typo")
        equal(addon.db.debug, true)
        addon:Command("debug off")
        addon:Command("debug off")
        equal(addon.db.debug, false)
        addon:Command("debug")
        equal(addon.db.debug, true)
        addon:Command("debug")
        equal(addon.db.debug, false)
    end)
end)

test("debug event storms are summarized before formatting and retained logs are bounded", function()
    fixture(function(f)
        addon.db.debug = true
        addon:Trace("ui.update", 5, "first update")
        for _ = 1, 60000 do
            addon:Trace("ui.update", 5, "%d", "not formatted while throttled")
        end
        equal(#f.messages, 1)
        equal(#addon.db.log, 1)
        assert(addon:Report():find("Debug messages suppressed since last ui.update: 60000", 1, true))
        assert(addon:Report():find("Retained data: markets=", 1, true))
        f.now = 5
        addon:Trace("ui.update", 5, "next update")
        equal(#f.messages, 2)
        assert(f.messages[2]:find("60000 similar events suppressed", 1, true))
        for index = 1, 150 do
            addon:Trace("lifecycle", 0, "event %d", index)
        end
        equal(#addon.db.log, 100)
        assert(addon.db.log[100]:find("event 150", 1, true))
        addon:Log(string.rep("x", 2000))
        assert(#addon.db.log[100] < 1100)
    end)
end)

test("external scan watchdog is logged as unconfirmed completion with elapsed time", function()
    fixture(function(f)
        local a =
            { L = addon.L, db = { debug = true, log = {} }, Trace = addon.Trace, Log = addon.Log, Print = addon.Print }
        assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Providers.lua"))("WaylaidLedger", a)
        a.Providers.BeginExternalScan("external ReplicateItems hook")
        f.now = 121
        a.Providers.frame.scripts.OnUpdate()
        equal(a.Providers.scan, nil)
        local message = a.db.log[#a.db.log]
        assert(message:find("watchdog: no progress for 120 seconds (completion unconfirmed)", 1, true))
        assert(message:find("elapsed=121.0s", 1, true))
        assert(message:find("lastProgress=unknown%", 1, true))
    end)
end)

test("Shopping lifecycle suspends work independently of full-scan adapter availability", function()
    fixture(function(f)
        local saved = Auctionator
        local listeners, dbUpdate, retries, updates = {}, nil, 0, 0
        local a = {
            L = addon.L,
            Discovery = {
                Retry = function()
                    retries = retries + 1
                end,
            },
            UI = {
                Update = function()
                    updates = updates + 1
                end,
            },
        }
        local suspended
        a.Discovery.SetSuspended = function(value)
            suspended = value
        end
        Auctionator = {
            API = {
                v1 = {
                    RegisterForDBUpdate = function(_, callback)
                        dbUpdate = callback
                    end,
                },
            },
            Shopping = {
                Tab = {
                    Events = {
                        SearchStart = "start",
                        SearchIncrementalUpdate = "progress",
                        SearchEnd = "end",
                    },
                },
            },
            EventBus = {
                Register = function(_, receiver, events)
                    for _, event in ipairs(events) do
                        listeners[event] = receiver
                    end
                end,
            },
        }
        local ok, err = pcall(function()
            assert(loadfile(PROJECT_ROOT .. "/WaylaidLedger/Providers.lua"))("WaylaidLedger", a)
            a.Providers.Install()
            listeners.start:ReceiveEvent("start")
            equal(suspended, true)
            local cache = a.Providers.cache
            for index = 1, 200 do
                f.now = index
                dbUpdate()
                listeners.progress:ReceiveEvent("progress", { index })
                a.Providers.frame.scripts.OnUpdate()
            end
            equal(a.Providers.cache, cache)
            equal(updates, 0)
            equal(retries, 0)
            assert(a.Providers.scan)
            -- Full completion must not resume a concurrent Shopping search.
            a.Providers.BeginExternalScan("replicate")
            dbUpdate()
            assert(a.Providers.scan.owners.shopping)
            equal(suspended, true)
            listeners["end"]:ReceiveEvent("end", {}) -- also used for cancelled searches
            equal(suspended, false)
            equal(a.Providers.scan, nil)
            equal(retries, 1)
            f.now = f.now + 0.3
            a.Providers.frame.scripts.OnUpdate()
            equal(updates, 1)
            equal(a.Providers.frame.scripts.OnUpdate, nil)
            listeners.start:ReceiveEvent("start")
            f.now = f.now + 121
            a.Providers.frame.scripts.OnUpdate()
            equal(a.Providers.scan, nil)
            equal(suspended, false)
        end)
        Auctionator = saved
        assert(ok, err)
    end)
end)
