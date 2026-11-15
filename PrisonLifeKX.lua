--[=[
    Prison Life 2026 — KX Edition V3 (PC & Mobile)
    PlaceId: 155615604
    Module 1: Core Environment, Services, Janitor, EventBus, Palette, StateMeta, SafeArea, Motion Engine & Persistence
]=]

local GEN_ENV = (getgenv and getgenv()) or _G
if type(GEN_ENV.__PL_KX_Cleanup) == "function" then
    pcall(GEN_ENV.__PL_KX_Cleanup)
end

local Services = {}
local App = {}
local State = {}
local Palette = {}
local Janitor = {}
local Bus = {}
local UI = {}

-- ============================================================================
-- // BLOCK 1: SERVICES, ENVIRONMENT CAPABILITIES & CORE HELPERS
-- ============================================================================
do
    local function initCore()
        local serviceNames = {
            "Players",
            "RunService",
            "UserInputService",
            "ReplicatedStorage",
            "Teams",
            "Workspace",
            "TweenService",
            "StarterGui",
            "TeleportService",
            "HttpService",
            "CollectionService",
            "CoreGui",
            "GuiService",
            "MarketplaceService",
            "ContentProvider",
            "SoundService",
            "VirtualUser",
            "TextChatService",
        }

        local g = game
        local getSvc = g and g.GetService
        if g and getSvc then
            for i = 1, #serviceNames do
                local sName = serviceNames[i]
                local ok, svc = pcall(getSvc, g, sName)
                if ok and svc then
                    Services[sName] = svc
                end
            end
        end

        local players = Services.Players
        local lp = players and players.LocalPlayer
        if players and not lp then
            local tries = 0
            while not lp and tries < 120 do
                tries = tries + 1
                local added = players.PlayerAdded
                if added and added.Wait then
                    local okW = pcall(added.Wait, added)
                    if not okW then
                        break
                    end
                elseif task and task.wait then
                    task.wait(0.05)
                else
                    break
                end
                lp = players.LocalPlayer
            end
        end

        App.Running = true
        GEN_ENV.__PL_KX_Running = true
        App.LocalPlayer = lp

        local execName = "Unknown"
        if type(identifyexecutor) == "function" then
            local okE, nm = pcall(identifyexecutor)
            if okE and type(nm) == "string" and nm ~= "" then
                execName = nm
            end
        elseif type(getexecutorname) == "function" then
            local okE, nm = pcall(getexecutorname)
            if okE and type(nm) == "string" and nm ~= "" then
                execName = nm
            end
        end

        local placeId = 155615604
        local jobId = ""
        local gameId = 0
        if g then
            pcall(function() placeId = g.PlaceId or placeId end)
            pcall(function() jobId = g.JobId or "" end)
            pcall(function() gameId = g.GameId or 0 end)
        end

        local isStudio = false
        if Services.RunService and Services.RunService.IsStudio then
            local okS, res = pcall(Services.RunService.IsStudio, Services.RunService)
            isStudio = (okS and res == true)
        end

        App.Env = {
            Global = GEN_ENV,
            Executor = execName,
            PlaceId = placeId,
            JobId = jobId,
            GameId = gameId,
            IsStudio = isStudio,
        }

        local dbg = type(debug) == "table" and debug or nil
        local hasDrawing = false
        if Drawing ~= nil then
            local okD, fn = pcall(function() return Drawing.new end)
            hasDrawing = (okD and type(fn) == "function")
        end

        App.Has = {
            GetConnections = (type(getconnections) == "function"),
            HookFunction = (type(hookfunction) == "function" or type(hookfunc) == "function" or type(replaceclosure) == "function"),
            HookMetamethod = (type(hookmetamethod) == "function"),
            RestoreFunction = (type(restorefunction) == "function"),
            DebugUpvalue = (dbg ~= nil and type(dbg.getupvalue) == "function"),
            DebugSetStack = (dbg ~= nil and type(dbg.setstack) == "function"),
            GetGC = (type(getgc) == "function"),
            GetSenv = (type(getsenv) == "function"),
            IsLClosure = (type(islclosure) == "function"),
            WritingFiles = (type(writefile) == "function" and type(readfile) == "function"),
            GetHui = (type(gethui) == "function"),
            NewCClosure = (type(newcclosure) == "function"),
            Drawing = hasDrawing,
            FileFolders = (type(isfolder) == "function" and type(makefolder) == "function"),
            ListFiles = (type(listfiles) == "function"),
            DelFile = (type(delfile) == "function"),
            IsFile = (type(isfile) == "function"),
            DebugInfo = (dbg ~= nil and type(dbg.info) == "function"),
            FireTouchInterest = (type(firetouchinterest) == "function"),
            SetClipboard = (type(setclipboard) == "function"),
        }

        -- Detect whether debug.getupvalue follows Lua 5.1/LuaJIT (name, val) or Roblox Luau (val)
        local upvalProbe = 42
        local function probeUpval()
            return upvalProbe
        end
        local upvalTakesSecond = false
        if App.Has.DebugUpvalue then
            local okP, r1, r2 = pcall(dbg.getupvalue, probeUpval, 1)
            if okP and r1 ~= 42 and r2 == 42 then
                upvalTakesSecond = true
            end
        end

        function App.HookFn(target, replacement)
            if type(target) ~= "function" or type(replacement) ~= "function" then
                return nil
            end
            if type(hookfunction) == "function" then
                local ok, orig = pcall(hookfunction, target, replacement)
                if ok and orig then
                    return orig
                end
            end
            if type(hookfunc) == "function" then
                local ok, orig = pcall(hookfunc, target, replacement)
                if ok and orig then
                    return orig
                end
            end
            if type(replaceclosure) == "function" then
                local ok, orig = pcall(replaceclosure, target, replacement)
                if ok and orig then
                    return orig
                end
            end
            return nil
        end

        function App.RestoreFn(target, origFn)
            if type(target) ~= "function" then
                return false
            end
            if type(restorefunction) == "function" then
                local ok = pcall(restorefunction, target)
                if ok then
                    return true
                end
            end
            if type(origFn) == "function" then
                local prev = App.HookFn(target, origFn)
                return prev ~= nil
            end
            return false
        end

        function App.SafeUpvalue(fn, idx)
            if type(fn) ~= "function" or type(idx) ~= "number" or idx < 1 then
                return nil, false
            end
            if type(islclosure) == "function" then
                local okL, isL = pcall(islclosure, fn)
                if not okL or not isL then
                    return nil, false
                end
            elseif dbg and type(dbg.getinfo) == "function" then
                local okI, info = pcall(dbg.getinfo, fn, "S")
                if not okI or not info or info.what ~= "Lua" then
                    return nil, false
                end
            end
            if not dbg or type(dbg.getupvalue) ~= "function" then
                return nil, false
            end
            local ok, r1, r2 = pcall(dbg.getupvalue, fn, idx)
            if not ok then
                return nil, false
            end
            if upvalTakesSecond then
                return r2, (r1 ~= nil)
            end
            local exists = true
            if type(dbg.getinfo) == "function" then
                local okI, info = pcall(dbg.getinfo, fn)
                if okI and type(info) == "table" and type(info.nups) == "number" then
                    exists = idx <= info.nups
                end
            end
            return r1, exists
        end

        function App.SafeSetStack(level, idx, val)
            if type(level) ~= "number" or type(idx) ~= "number" then
                return false
            end
            if not dbg or type(dbg.setstack) ~= "function" then
                return false
            end
            local ok = pcall(dbg.setstack, level, idx, val)
            return ok == true
        end

        function App.IsMobileInput()
            local uis = Services.UserInputService
            if not uis then
                return (App.SafeArea and App.SafeArea.IsPhone) or false
            end
            local touchOn = false
            local mouseOn = true
            local keyOn = true
            pcall(function() touchOn = (uis.TouchEnabled == true) end)
            pcall(function() mouseOn = (uis.MouseEnabled == true) end)
            pcall(function() keyOn = (uis.KeyboardEnabled == true) end)

            local lastType = nil
            if uis.GetLastInputType then
                local okL, lt = pcall(uis.GetLastInputType, uis)
                if okL then
                    lastType = lt
                end
            end

            local touchEnum = Enum and Enum.UserInputType and Enum.UserInputType.Touch
            if touchEnum and lastType == touchEnum then
                return true
            end

            if touchOn then
                if not mouseOn or not keyOn then
                    return true
                end
                local mouseEnum = Enum and Enum.UserInputType and Enum.UserInputType.MouseMovement
                local keyEnum = Enum and Enum.UserInputType and Enum.UserInputType.Keyboard
                local isDesktopInput = (mouseEnum and lastType == mouseEnum) or (keyEnum and lastType == keyEnum)
                if not isDesktopInput and App.SafeArea and App.SafeArea.IsCompact then
                    return true
                end
            end

            return false
        end

        function App.Trim(s)
            if type(s) ~= "string" then
                return ""
            end
            return (s:gsub("^%s+", ""):gsub("%s+$", ""))
        end

        function App.EscapeRichText(s)
            if s == nil then
                return ""
            end
            return (tostring(s)
                :gsub("&", "&amp;")
                :gsub("<", "&lt;")
                :gsub(">", "&gt;")
                :gsub('"', "&quot;")
                :gsub("'", "&apos;"))
        end

        local function clampByte(v)
            local n = math.floor((tonumber(v) or 0) * 255 + 0.5)
            if n < 0 then
                return 0
            elseif n > 255 then
                return 255
            end
            return n
        end

        function App.ColorToHex(c)
            local tc = type(c)
            if tc ~= "table" and tc ~= "userdata" then
                return "#FFFFFF"
            end
            local ok, r, g2, b = pcall(function()
                return c.R, c.G, c.B
            end)
            if not ok or type(r) ~= "number" or type(g2) ~= "number" or type(b) ~= "number" then
                return "#FFFFFF"
            end
            return string.format("#%02X%02X%02X", clampByte(r), clampByte(g2), clampByte(b))
        end

        local function copyValue(v, seen)
            if type(v) ~= "table" then
                return v
            end
            if seen[v] then
                return seen[v]
            end
            local copy = {}
            seen[v] = copy
            for k, val in pairs(v) do
                copy[copyValue(k, seen)] = copyValue(val, seen)
            end
            return copy
        end

        function App.DeepCopy(v)
            return copyValue(v, {})
        end

        function App.GetCamera()
            local ws = Services.Workspace
            return ws and ws.CurrentCamera or nil
        end

        function App.GetChar(plr)
            return plr and plr.Character or nil
        end

        function App.GetRoot(char)
            if not char then
                return nil
            end
            return char:FindFirstChild("HumanoidRootPart")
                or char:FindFirstChild("Torso")
                or char:FindFirstChild("UpperTorso")
        end

        function App.GetHum(char)
            if not char then
                return nil
            end
            return char:FindFirstChildOfClass("Humanoid")
        end

        function App.GetSafeGuiParent()
            if type(gethui) == "function" then
                local ok, ui = pcall(gethui)
                if ok and ui then
                    return ui
                end
            end
            local coreGui = Services.CoreGui
            if coreGui then
                local okCore = pcall(function()
                    local _ = coreGui.Name
                end)
                if okCore then
                    return coreGui
                end
            end
            local localPlr = App.LocalPlayer or (Services.Players and Services.Players.LocalPlayer)
            if localPlr then
                if localPlr.FindFirstChildOfClass then
                    local pg = localPlr:FindFirstChildOfClass("PlayerGui")
                    if pg then
                        return pg
                    end
                end
                if localPlr.WaitForChild then
                    local okPg, pg = pcall(localPlr.WaitForChild, localPlr, "PlayerGui", 10)
                    if okPg and pg then
                        return pg
                    end
                end
            end
            return nil
        end
    end

    initCore()
end

-- ============================================================================
-- // BLOCK 2: JANITOR LIFECYCLE MANAGER & EVENT BUS
-- ============================================================================
do
    local function initJanitorAndBus()
        local activeConns = {}
        local trackedInsts = {}
        local boundRenders = {}
        local trackedThreads = {}
        local activeScopes = {}
        local cleanupCallbacks = {}
        local busListeners = {}
        local isCleaning = false

        local clearTbl = table.clear or function(t)
            for k in pairs(t) do
                t[k] = nil
            end
        end

        local findInTbl = table.find or function(t, v)
            for i = 1, #t do
                if t[i] == v then
                    return i
                end
            end
            return nil
        end

        local function pruneConnections(list)
            for i = #list, 1, -1 do
                local c = list[i]
                local okC, alive = pcall(function()
                    return c.Connected
                end)
                if not c or (okC and alive == false) then
                    table.remove(list, i)
                end
            end
        end

        local function cancelThread(th)
            if not th then
                return
            end
            if type(th) == "thread" then
                if th ~= coroutine.running() and task and task.cancel then
                    pcall(task.cancel, th)
                end
            elseif type(th) == "table" then
                th.cancelled = true
            end
        end

        local function disconnectConn(c)
            if not c then
                return
            end
            if type(c) == "function" then
                pcall(c)
            elseif c.Disconnect then
                pcall(c.Disconnect, c)
            end
        end

        local function destroyInst(inst)
            if not inst then
                return
            end
            if inst.Destroy then
                pcall(inst.Destroy, inst)
            end
        end

        function Janitor.Add(conn)
            if not conn then
                return nil
            end
            if #activeConns >= 120 then
                pruneConnections(activeConns)
            end
            table.insert(activeConns, conn)
            return conn
        end

        function Janitor.Track(inst)
            if not inst then
                return nil
            end
            if not findInTbl(trackedInsts, inst) then
                table.insert(trackedInsts, inst)
            end
            return inst
        end

        function Janitor.BindRender(name, priority, fn)
            if type(name) ~= "string" or type(fn) ~= "function" then
                return nil
            end
            local rs = Services.RunService
            if rs and rs.UnbindFromRenderStep then
                pcall(rs.UnbindFromRenderStep, rs, name)
            end
            if not findInTbl(boundRenders, name) then
                table.insert(boundRenders, name)
            end
            if rs and rs.BindToRenderStep then
                pcall(rs.BindToRenderStep, rs, name, priority or 200, fn)
            end
            return name
        end

        function Janitor.UnbindRender(name)
            if type(name) ~= "string" then
                return
            end
            local rs = Services.RunService
            if rs and rs.UnbindFromRenderStep then
                pcall(rs.UnbindFromRenderStep, rs, name)
            end
            local idx = findInTbl(boundRenders, name)
            if idx then
                table.remove(boundRenders, idx)
            end
        end

        local function spawnInto(threadSet, fn)
            if type(fn) ~= "function" or not App.Running then
                return nil
            end
            if task and task.spawn then
                local finished = false
                local th
                th = task.spawn(function()
                    pcall(fn)
                    finished = true
                    if th then
                        threadSet[th] = nil
                    end
                end)
                if not finished and th then
                    threadSet[th] = true
                end
                return th
            end
            local finished = false
            local co = coroutine.create(function()
                pcall(fn)
                finished = true
            end)
            threadSet[co] = true
            coroutine.resume(co)
            if finished or coroutine.status(co) == "dead" then
                threadSet[co] = nil
            end
            return co
        end

        local function delayInto(threadSet, sec, fn)
            if type(fn) ~= "function" or not App.Running then
                return nil
            end
            local waitSec = math.max(0, tonumber(sec) or 0)
            if task and task.delay then
                local finished = false
                local th
                th = task.delay(waitSec, function()
                    if th then
                        threadSet[th] = nil
                    end
                    finished = true
                    if App.Running then
                        pcall(fn)
                    end
                end)
                if not finished and th then
                    threadSet[th] = true
                end
                return th
            end
            local handle = { cancelled = false }
            threadSet[handle] = true
            return handle
        end

        function Janitor.Spawn(fn)
            return spawnInto(trackedThreads, fn)
        end

        function Janitor.Delay(sec, fn)
            return delayInto(trackedThreads, sec, fn)
        end

        function Janitor.NewScope()
            local scopeConns = {}
            local scopeInsts = {}
            local scopeThreads = {}
            local scopeCleanups = {}
            local scope = {}

            function scope:Add(conn)
                if not conn then
                    return nil
                end
                if #scopeConns >= 64 then
                    pruneConnections(scopeConns)
                end
                table.insert(scopeConns, conn)
                return conn
            end

            function scope:Track(inst)
                if not inst then
                    return nil
                end
                if not findInTbl(scopeInsts, inst) then
                    table.insert(scopeInsts, inst)
                end
                return inst
            end

            function scope:Spawn(fn)
                return spawnInto(scopeThreads, fn)
            end

            function scope:Delay(sec, fn)
                return delayInto(scopeThreads, sec, fn)
            end

            function scope:AddCleanup(fn)
                if type(fn) == "function" then
                    table.insert(scopeCleanups, fn)
                end
            end

            function scope:Clean()
                for i = #scopeCleanups, 1, -1 do
                    pcall(scopeCleanups[i])
                end
                clearTbl(scopeCleanups)

                for th in pairs(scopeThreads) do
                    cancelThread(th)
                    scopeThreads[th] = nil
                end

                for i = #scopeConns, 1, -1 do
                    disconnectConn(scopeConns[i])
                    scopeConns[i] = nil
                end

                for i = #scopeInsts, 1, -1 do
                    destroyInst(scopeInsts[i])
                    scopeInsts[i] = nil
                end
            end

            activeScopes[scope] = true
            return scope
        end

        function Janitor.AddCleanup(fn)
            if type(fn) == "function" then
                table.insert(cleanupCallbacks, fn)
            end
            return fn
        end

        function Bus.On(eventName, fn)
            if type(eventName) ~= "string" or type(fn) ~= "function" then
                return function() end
            end
            local list = busListeners[eventName]
            if not list then
                list = {}
                busListeners[eventName] = list
            end
            local entry = { fn = fn, active = true }
            table.insert(list, entry)

            local function unbind()
                if not entry.active then
                    return
                end
                entry.active = false
                local curList = busListeners[eventName]
                if curList then
                    for i = #curList, 1, -1 do
                        if curList[i] == entry then
                            table.remove(curList, i)
                            break
                        end
                    end
                end
            end

            Janitor.Add(unbind)
            return unbind
        end

        function Bus.Emit(eventName, ...)
            local list = busListeners[eventName]
            if not list or #list == 0 then
                return
            end
            local snapshot = {}
            for i = 1, #list do
                local item = list[i]
                if item.active then
                    snapshot[#snapshot + 1] = item
                end
            end
            for i = 1, #snapshot do
                local item = snapshot[i]
                if item.active then
                    local ok, err = pcall(item.fn, ...)
                    if not ok then
                        App._BusErrorCount = (App._BusErrorCount or 0) + 1
                        if type(warn) == "function" and App._BusErrorCount <= 12 then
                            warn("[PL-KX Bus Error] " .. tostring(eventName) .. ": " .. tostring(err))
                        end
                    end
                end
            end
        end

        function Bus.Clear()
            for k in pairs(busListeners) do
                local list = busListeners[k]
                for i = 1, #list do
                    list[i].active = false
                end
                busListeners[k] = nil
            end
        end

        function Janitor.CleanupAll()
            if isCleaning then
                return
            end
            isCleaning = true
            App.Running = false
            GEN_ENV.__PL_KX_Running = false

            pcall(Bus.Emit, "Cleanup")

            for i = #cleanupCallbacks, 1, -1 do
                pcall(cleanupCallbacks[i])
            end
            clearTbl(cleanupCallbacks)

            Bus.Clear()

            for scope in pairs(activeScopes) do
                pcall(scope.Clean, scope)
                activeScopes[scope] = nil
            end

            for i = #boundRenders, 1, -1 do
                local rName = boundRenders[i]
                if Services.RunService and Services.RunService.UnbindFromRenderStep then
                    pcall(Services.RunService.UnbindFromRenderStep, Services.RunService, rName)
                end
                boundRenders[i] = nil
            end

            for th in pairs(trackedThreads) do
                cancelThread(th)
                trackedThreads[th] = nil
            end

            for i = #activeConns, 1, -1 do
                disconnectConn(activeConns[i])
                activeConns[i] = nil
            end

            for i = #trackedInsts, 1, -1 do
                destroyInst(trackedInsts[i])
                trackedInsts[i] = nil
            end

            isCleaning = false
        end

        GEN_ENV.__PL_KX_Cleanup = Janitor.CleanupAll
    end

    initJanitorAndBus()
end

-- ============================================================================
-- // BLOCK 3: COLOR PALETTE (CONTRACT SECTION 2)
-- ============================================================================
do
    local function initPalette()
        local rgb = (Color3 and Color3.fromRGB) or function(r, g, b)
            return { R = r / 255, G = g / 255, B = b / 255 }
        end

        Palette.BgDark = rgb(13, 15, 22)
        Palette.BgCard = rgb(20, 24, 34)
        Palette.BgElevated = rgb(27, 32, 46)
        Palette.BgInset = rgb(10, 12, 18)
        Palette.NeonBlue = rgb(56, 148, 255)
        Palette.NeonCyan = rgb(72, 212, 255)
        Palette.ElectricBlue = rgb(38, 118, 235)
        Palette.TextPrimary = rgb(242, 246, 255)
        Palette.TextMuted = rgb(160, 170, 192)
        Palette.TextSubtle = rgb(108, 118, 140)
        Palette.RedAlert = rgb(255, 68, 72)
        Palette.RageCrimson = rgb(225, 48, 62)
        Palette.StreakGold = rgb(255, 206, 68)
        Palette.Emerald = rgb(64, 224, 138)
        Palette.Amber = rgb(255, 184, 52)
        Palette.Border = rgb(48, 56, 76)
        Palette.GuardBlue = rgb(62, 142, 255)
        Palette.InmateOrange = rgb(255, 146, 56)
        Palette.CrimRed = rgb(240, 74, 78)
        Palette.NeutralGrey = rgb(170, 178, 194)
    end

    initPalette()
end

-- ============================================================================
-- // BLOCK 4: STATE META SCHEMA, DEFAULTS & App.SetState
-- ============================================================================
do
    local function initStateSchema()
        App.StateMeta = {}
        App.StateOrder = {}
        App.StateDefaults = {}

        local function registerOne(tab, def)
            local key = def[1]
            local defaultVal = def[2]
            local kind = def[3]
            local label = def[4]
            local opts = def[5] or {}
            local meta = {
                key = key,
                default = App.DeepCopy(defaultVal),
                kind = kind,
                min = opts.min,
                max = opts.max,
                step = opts.step,
                options = opts.options,
                label = label,
                tab = tab,
                tags = opts.tags or {},
            }
            App.StateMeta[key] = meta
            table.insert(App.StateOrder, key)
            App.StateDefaults[key] = App.DeepCopy(defaultVal)
            State[key] = App.DeepCopy(defaultVal)
        end

        local function registerGroup(tab, rows)
            for i = 1, #rows do
                registerOne(tab, rows[i])
            end
        end

        local function regShield()
            registerGroup("Shield", {
                { "ShieldEnabled", true, "bool", "Bullet Shield", { tags = { "shield", "defense", "block", "riot" } } },
                { "ShieldMode", "Hybrid", "string", "Shield Mode", { options = { "Hybrid", "RiotOnly", "DesyncBox", "FEGhost" }, tags = { "shield", "mode", "desync", "ghost" } } },
                { "ShieldSize", 6.5, "number", "Shield Box Size", { min = 3, max = 14, step = 0.5, tags = { "shield", "size", "box" } } },
                { "ShieldTransparency", 0.84, "number", "Shield Transparency", { min = 0.45, max = 0.95, step = 0.01, tags = { "shield", "opacity", "transparency" } } },
                { "ShieldAutoEquip", true, "bool", "Auto Equip Shield", { tags = { "shield", "equip", "riot" } } },
                { "ShieldAutoFaceShooter", false, "bool", "Auto Face Shooter", { tags = { "shield", "face", "rotate" } } },
                { "ShieldSpinBlock", false, "bool", "Spin Block", { tags = { "shield", "spin", "antiaim" } } },
                { "ShieldSpinSpeed", 16, "number", "Spin Block Speed", { min = 4, max = 40, step = 1, tags = { "shield", "spin", "speed" } } },
                { "DesyncJitterRadius", 3.2, "number", "Desync Jitter Radius", { min = 1, max = 8, step = 0.2, tags = { "shield", "desync", "jitter" } } },
                { "AntiTaze", true, "bool", "Anti-Taze", { tags = { "defense", "taze", "stun" } } },
                { "AntiArrest", false, "bool", "Anti-Arrest", { tags = { "defense", "arrest", "cuffs" } } },
                { "FEInvisible", false, "bool", "FE Invisible", { tags = { "invis", "fe", "ghost" } } },
                { "AntiInvisible", false, "bool", "Anti-Invisible", { tags = { "reveal", "invis", "anti" } } },
            })
        end

        local function regCombat()
            registerGroup("Combat", {
                { "Ragebot", false, "bool", "Ragebot", { tags = { "rage", "autofire", "combat" } } },
                { "RagebotAutoSwitch", true, "bool", "Ragebot Auto-Switch", { tags = { "rage", "switch", "gun" } } },
                { "Ragebot360", true, "bool", "Ragebot 360°", { tags = { "rage", "360", "fov" } } },
                { "RagebotRate", 18, "number", "Ragebot Fire Rate", { min = 2, max = 35, step = 1, tags = { "rage", "rate", "sps" } } },
                { "RagebotPeekShield", true, "bool", "Ragebot Peek Shield", { tags = { "rage", "shield", "peek" } } },
                { "SilentAim", false, "bool", "Silent Aim", { tags = { "silent", "aimbot", "bullet" } } },
                { "SilentAimFOV", 110, "number", "Silent Aim FOV", { min = 30, max = 360, step = 5, tags = { "silent", "fov", "circle" } } },
                { "SilentAimShowFOV", true, "bool", "Show FOV Circle", { tags = { "silent", "fov", "visual" } } },
                { "SilentAimHitChance", 100, "number", "Silent Aim Hit Chance", { min = 10, max = 100, step = 5, tags = { "silent", "hitchance" } } },
                { "SilentAimHeadChance", 70, "number", "Headshot Chance %", { min = 0, max = 100, step = 5, tags = { "silent", "headshot", "crit" } } },
                { "SilentAimTargetPart", "Head", "string", "Silent Aim Part", { options = { "Head", "Torso", "Random" }, tags = { "silent", "part", "head", "torso" } } },
                { "SilentAimWallcheck", true, "bool", "Wall Check", { tags = { "silent", "los", "wall" } } },
                { "SilentAimWallbang", true, "bool", "Wallbang Scanner", { tags = { "silent", "wallbang", "origin" } } },
                { "SilentAimTeamCheck", true, "bool", "Team Check", { tags = { "silent", "team", "friendly" } } },
                { "SilentAimHostileCheck", false, "bool", "Hostile Inmates Only", { tags = { "silent", "hostile", "inmate" } } },
                { "SilentAimSkipDown", true, "bool", "Skip Downed / ForceField", { tags = { "silent", "forcefield", "downed" } } },
                { "AimAssist", false, "bool", "Aim Assist", { tags = { "aim", "assist", "camera" } } },
                { "AimAssistFOV", 130, "number", "Aim Assist FOV", { min = 30, max = 350, step = 5, tags = { "aim", "fov" } } },
                { "AimAssistSmooth", 0.28, "number", "Aim Assist Smooth", { min = 0.05, max = 0.95, step = 0.01, tags = { "aim", "smooth" } } },
                { "KillAura", false, "bool", "Melee KillAura", { tags = { "melee", "killaura", "aura" } } },
                { "KillAuraRange", 18, "number", "KillAura Range", { min = 6, max = 30, step = 1, tags = { "killaura", "range" } } },
                { "KillAuraRate", 14, "number", "KillAura Rate", { min = 4, max = 24, step = 1, tags = { "killaura", "rate" } } },
                { "KillAuraTeamCheck", true, "bool", "KillAura Team Check", { tags = { "killaura", "team" } } },
                { "KillAuraHostileOnly", false, "bool", "KillAura Hostile Only", { tags = { "killaura", "hostile" } } },
                { "HitboxExpander", false, "bool", "Hitbox Expander", { tags = { "hitbox", "expander", "size" } } },
                { "HitboxSize", 10, "number", "Hitbox Size", { min = 3, max = 25, step = 0.5, tags = { "hitbox", "size" } } },
                { "HitboxTransparency", 0.65, "number", "Hitbox Transparency", { min = 0, max = 0.95, step = 0.05, tags = { "hitbox", "transparency" } } },
                { "HitboxTeamCheck", true, "bool", "Hitbox Team Check", { tags = { "hitbox", "team" } } },
                { "AntiRiotShield", false, "bool", "Anti-Riot Shield", { tags = { "shield", "pierce", "anti" } } },
                { "AutoArmorPen", true, "bool", "Auto Armor Pen", { tags = { "armor", "penetration", "headshot" } } },
                { "ComboAutoGrabGuns", true, "bool", "Combo Auto Grab Guns", { tags = { "combo1", "guns", "grab" } } },
                { "ComboReEquipShield", true, "bool", "Combo Re-Equip Shield", { tags = { "combo1", "shield" } } },
                { "ComboLoop", false, "bool", "Loop .combo1", { tags = { "combo1", "loop", "macro" } } },
                { "ComboLoopInterval", 0.55, "number", "Combo Loop Interval", { min = 0.2, max = 2.5, step = 0.05, tags = { "combo1", "interval" } } },
            })
        end

        local function regGuns()
            registerGroup("Guns", {
                { "GunMods", false, "bool", "Gun Mods", { tags = { "guns", "mods", "weapon" } } },
                { "GunAutoFire", true, "bool", "Full Auto", { tags = { "guns", "auto", "fire" } } },
                { "GunFireRateSPS", 22, "number", "Fire Rate (SPS)", { min = 5, max = 45, step = 1, tags = { "guns", "firerate", "sps" } } },
                { "GunNoSpread", true, "bool", "No Spread", { tags = { "guns", "spread", "accuracy" } } },
                { "GunInfiniteRange", true, "bool", "Infinite Range", { tags = { "guns", "range", "distance" } } },
                { "GunAutoReload", true, "bool", "Auto Reload", { tags = { "guns", "reload", "ammo" } } },
                { "AutoGetGuns", false, "bool", "Auto Get Guns", { tags = { "guns", "grab", "spawn" } } },
                { "AutoGunsSelection", { "Remington 870", "M4A1", "AK-47" }, "list", "Auto Guns List", { options = { "Remington 870", "M4A1", "AK-47", "MP5", "FAL", "M9" }, tags = { "guns", "list", "loadout" } } },
                { "AutoArmor", false, "bool", "Auto Armor", { tags = { "armor", "vest", "loot" } } },
                { "AutoHeal", false, "bool", "Auto Heal", { tags = { "heal", "food", "health" } } },
                { "AutoHealThreshold", 65, "number", "Auto Heal HP %", { min = 20, max = 95, step = 5, tags = { "heal", "threshold" } } },
                { "AutoPickupDrops", false, "bool", "Auto Pickup Drops", { tags = { "pickup", "drops", "loot" } } },
            })
        end

        local function regPrison()
            registerGroup("Prison", {
                { "AutoArrest", false, "bool", "Auto Arrest", { tags = { "arrest", "guard", "prison" } } },
                { "AutoArrestRange", 14, "number", "Auto Arrest Range", { min = 5, max = 22, step = 0.5, tags = { "arrest", "range" } } },
                { "AutoTaze", false, "bool", "Auto Taze", { tags = { "taze", "guard", "stun" } } },
                { "AutoDetonateC4", false, "bool", "Auto Detonate C4", { tags = { "c4", "detonate", "explosive" } } },
                { "AutoCriminal", false, "bool", "Auto Criminal", { tags = { "criminal", "team", "escape" } } },
                { "AutoRespawn", false, "bool", "Auto Fast Respawn", { tags = { "respawn", "fast", "spawn" } } },
                { "FenceGodmode", true, "bool", "Fence Godmode", { tags = { "fence", "godmode", "electric" } } },
                { "OpenAllDoors", false, "bool", "Open All Doors", { tags = { "doors", "prison", "open" } } },
                { "AntiKillPlane", true, "bool", "Anti-KillPlane", { tags = { "void", "killplane", "safety" } } },
                { "VehicleFly", false, "bool", "Vehicle Fly", { tags = { "car", "vehicle", "fly" } } },
                { "VehicleFlySpeed", 75, "number", "Vehicle Fly Speed", { min = 25, max = 220, step = 5, tags = { "car", "fly", "speed" } } },
                { "VehicleSpeedMod", false, "bool", "Vehicle Speed Mod", { tags = { "car", "speed", "boost" } } },
                { "VehicleSpeedMult", 2.2, "number", "Vehicle Speed Mult", { min = 1.0, max = 4.5, step = 0.1, tags = { "car", "multiplier" } } },
                { "VehicleFling", false, "bool", "Vehicle Fling", { tags = { "car", "fling" } } },
                { "VehicleWallbang", false, "bool", "Vehicle Wallbang", { tags = { "car", "wallbang" } } },
                { "AntiFling", false, "bool", "Anti-Fling", { tags = { "antifling", "protection", "physics" } } },
            })
        end

        local function regMove()
            registerGroup("Move", {
                { "MaxSpeed", false, "bool", "Max Speed", { tags = { "speed", "walkspeed", "move" } } },
                { "SpeedMode", "RegionSafe", "string", "Speed Mode", { options = { "RegionSafe", "Custom", "AlwaysSprint" }, tags = { "speed", "mode", "sprint" } } },
                { "WalkSpeed", 42, "number", "Walk Speed", { min = 16, max = 110, step = 1, tags = { "speed", "walkspeed" } } },
                { "JumpPowerEnabled", false, "bool", "JumpPower Boost", { tags = { "jump", "power" } } },
                { "JumpPower", 68, "number", "Jump Power", { min = 50, max = 135, step = 1, tags = { "jump", "power" } } },
                { "InfiniteJump", false, "bool", "Infinite Jump", { tags = { "jump", "infinite", "air" } } },
                { "AntiJumpCooldown", true, "bool", "Anti Jump Cooldown", { tags = { "jump", "cooldown" } } },
                { "AntiNoclipBypass", true, "bool", "Bypass Anti-Noclip", { tags = { "noclip", "bypass", "anti" } } },
                { "Fly", false, "bool", "Character Fly", { tags = { "fly", "move", "air" } } },
                { "FlySpeed", 60, "number", "Fly Speed", { min = 20, max = 220, step = 5, tags = { "fly", "speed" } } },
                { "Noclip", false, "bool", "Noclip", { tags = { "noclip", "wall", "phase" } } },
                { "AntiAFK", true, "bool", "Anti-AFK", { tags = { "afk", "idle", "utility" } } },
            })
        end

        local function regVisuals()
            registerGroup("Visuals", {
                { "ESPEnabled", true, "bool", "Player ESP", { tags = { "esp", "wallhack", "visuals" } } },
                { "ESPHideTeam", false, "bool", "ESP Hide Teammates", { tags = { "esp", "team", "filter" } } },
                { "ESPBoxes", true, "bool", "ESP Boxes / Chams", { tags = { "esp", "box", "chams" } } },
                { "ESPNames", true, "bool", "ESP Names", { tags = { "esp", "names", "tag" } } },
                { "ESPHealthBar", true, "bool", "ESP Health Bar", { tags = { "esp", "health", "hp" } } },
                { "ESPDistance", false, "bool", "ESP Distance", { tags = { "esp", "distance", "studs" } } },
                { "ESPDiamondMarker", false, "bool", "ESP Diamond Marker", { tags = { "esp", "marker", "diamond" } } },
                { "ESPMaxDistance", 500, "number", "ESP Max Distance", { min = 100, max = 1200, step = 25, tags = { "esp", "distance", "range" } } },
                { "ESPDetailDistance", 140, "number", "ESP Detail Distance", { min = 40, max = 400, step = 10, tags = { "esp", "detail", "lod" } } },
                { "ESPTracers", false, "bool", "ESP Snaplines", { tags = { "esp", "tracers", "snaplines" } } },
                { "C4ESP", true, "bool", "C4 ESP", { tags = { "esp", "c4", "explosive" } } },
                { "BulletTracers", true, "bool", "Bullet Tracers", { tags = { "vfx", "tracers", "bullet" } } },
                { "BulletTracerFade", 0.24, "number", "Tracer Fade (s)", { min = 0.08, max = 0.6, step = 0.02, tags = { "vfx", "tracer", "fade" } } },
                { "Hitmarker", true, "bool", "Hitmarker", { tags = { "vfx", "hitmarker", "crosshair" } } },
                { "HitSound", true, "bool", "Hit Sound", { tags = { "audio", "hitsound", "sfx" } } },
                { "KillSound", true, "bool", "Kill Sound", { tags = { "audio", "killsound", "sfx" } } },
                { "DamageNumbers", true, "bool", "Damage Numbers", { tags = { "vfx", "damage", "indicator" } } },
                { "ShieldHitVFX", true, "bool", "Shield Block VFX", { tags = { "vfx", "shield", "sparks" } } },
            })
        end

        local function regHudAndLists()
            registerGroup("HUD", {
                { "ShowComboButton", true, "bool", "Show .combo1 Button", { tags = { "hud", "combo1", "button" } } },
                { "ShowKXBar", true, "bool", "Show KX Cmd Bar", { tags = { "hud", "command", "bar" } } },
                { "ShowIYPill", true, "bool", "Show KX Pill", { tags = { "hud", "crest", "pill" } } },
                { "ShowRightActions", true, "bool", "Show Right Action Buttons", { tags = { "hud", "mobile", "actions" } } },
                { "ShowPinnedPills", true, "bool", "Show Pinned Quick Pills", { tags = { "hud", "pinned", "pills" } } },
                { "PinnedPills", { "Rage", "Shield", "Fly" }, "list", "Pinned Quick Pills", { options = { "Rage", "Shield", "Fly", "Noclip", "KillAura", "SilentAim", "AutoArrest" }, tags = { "hud", "pinned", "pills" } } },
                { "ShowShieldBadge", true, "bool", "Show Shield HP Badge", { tags = { "hud", "shield", "badge" } } },
                { "ShowKillfeed", true, "bool", "Show Killfeed", { tags = { "hud", "killfeed", "streak" } } },
                { "KillfeedPosition", "AboveHotbar", "string", "Killfeed Position", { options = { "AboveHotbar", "TopLeft" }, tags = { "hud", "killfeed", "position" } } },
                { "ShowAlerts", true, "bool", "Show Alert Banners", { tags = { "hud", "alerts", "banner" } } },
                { "CheaterAlerts", true, "bool", "Cheater Alerts", { tags = { "alerts", "cheater", "detector" } } },
                { "CarTPAlerts", true, "bool", "Car TP Alerts", { tags = { "alerts", "car", "teleport" } } },
                { "AlertDuration", 3.8, "number", "Alert Duration (s)", { min = 1.5, max = 8.0, step = 0.1, tags = { "alerts", "duration" } } },
                { "LockHUDLayout", false, "bool", "Lock HUD Layout", { tags = { "hud", "lock", "drag" } } },
                { "HUDPositions", {}, "list", "HUD Positions", { tags = { "hud", "positions", "layout" } } },
            })

            registerGroup("Settings", {
                { "HubVisible", false, "bool", "Hub Visible", { tags = { "hub", "menu", "ui" } } },
                { "ActiveTab", "Shield", "string", "Active Tab", { options = { "Shield", "Combat", "Guns", "Prison", "Move", "Settings" }, tags = { "hub", "tab" } } },
                { "ChatCommands", false, "bool", "Chat Commands", { tags = { "commands", "chat", "admin" } } },
                { "AutoLoadConfig", true, "bool", "Auto-Load Default Profile", { tags = { "config", "profile", "autoload" } } },
                { "HubSearch", "", "string", "Hub Search Query", { tags = { "hub", "search", "filter" } } },
                { "Keybinds", {
                    ToggleHub = "K",
                    AltToggleHub = "RightShift",
                    ToggleShield = "G",
                    Combo1 = "X",
                    ToggleRagebot = "B",
                    ToggleFly = "F",
                    ToggleNoclip = "N",
                    FocusCmdBar = "Semicolon",
                }, "keybind", "Keybinds", { tags = { "keybinds", "hotkeys", "keyboard" } } },
            })

            registerGroup("Combat", {
                { "KillAuraWhitelist", {}, "list", "KillAura Whitelist", { tags = { "killaura", "whitelist", "friends" } } },
                { "LoopKillTargets", {}, "list", "LoopKill Targets", { tags = { "loopkill", "targets", "combat" } } },
            })

            registerGroup("Prison", {
                { "ArrestWhitelist", {}, "list", "Arrest Whitelist", { tags = { "arrest", "whitelist", "friends" } } },
            })
        end

        regShield()
        regCombat()
        regGuns()
        regPrison()
        regMove()
        regVisuals()
        regHudAndLists()

        local function deepEqual(a, b, seen)
            if a == b then
                return true
            end
            if type(a) ~= "table" or type(b) ~= "table" then
                return false
            end
            seen = seen or {}
            if seen[a] == b then
                return true
            end
            seen[a] = b
            for k, va in pairs(a) do
                if not deepEqual(va, b[k], seen) then
                    return false
                end
            end
            for k in pairs(b) do
                if a[k] == nil then
                    return false
                end
            end
            return true
        end

        local function normalizeByMeta(meta, val)
            if meta.kind == "bool" then
                return true, (val == true)
            elseif meta.kind == "number" then
                local num = tonumber(val)
                if not num or num ~= num then
                    return false, nil
                end
                if meta.min ~= nil and num < meta.min then
                    num = meta.min
                end
                if meta.max ~= nil and num > meta.max then
                    num = meta.max
                end
                return true, num
            elseif meta.kind == "string" then
                local s = (type(val) == "string") and val or tostring(val or meta.default or "")
                if meta.options and #meta.options > 0 then
                    local matched = nil
                    local low = string.lower(s)
                    for i = 1, #meta.options do
                        local opt = meta.options[i]
                        if opt == s or string.lower(opt) == low then
                            matched = opt
                            break
                        end
                    end
                    if not matched then
                        return false, nil
                    end
                    s = matched
                end
                return true, s
            elseif meta.kind == "list" or meta.kind == "keybind" then
                if type(val) ~= "table" then
                    return false, nil
                end
                return true, val
            end
            return true, val
        end

        function App.SetState(key, val, silent, force)
            if type(key) ~= "string" then
                return false, nil
            end
            local meta = App.StateMeta[key]
            local nextVal = val
            if meta then
                local okNorm, coerced = normalizeByMeta(meta, val)
                if not okNorm then
                    return false, State[key]
                end
                nextVal = coerced
            end

            local oldVal = State[key]
            if not force then
                if type(nextVal) == "table" and type(oldVal) == "table" then
                    if oldVal == nextVal or deepEqual(oldVal, nextVal) then
                        return false, oldVal
                    end
                elseif oldVal == nextVal then
                    return false, oldVal
                end
            end

            if type(nextVal) == "table" and nextVal == App.StateDefaults[key] then
                nextVal = App.DeepCopy(nextVal)
            end

            State[key] = nextVal
            Bus.Emit("StateChanged", key, nextVal, oldVal, silent)
            return true, nextVal
        end
    end

    initStateSchema()
end

-- ============================================================================
-- // BLOCK 5: SAFE AREA & RESPONSIVE LAYOUT VIEWPORT WATCHER
-- ============================================================================
do
    local function initSafeArea()
        local SafeArea = {
            InsetTop = 36,
            InsetLeft = 0,
            InsetBottom = 0,
            InsetRight = 0,
            Viewport = { X = 1280, Y = 720 },
            IsCompact = false,
            IsPhone = false,
        }
        App.SafeArea = SafeArea

        local camScope = nil
        local watcherActive = false

        local function clampNum(x, lo, hi)
            if x < lo then
                return lo
            elseif x > hi then
                return hi
            end
            return x
        end

        local function readInsets()
            local gs = Services.GuiService
            if not gs or not gs.GetGuiInset then
                return SafeArea.InsetTop, SafeArea.InsetLeft, SafeArea.InsetBottom, SafeArea.InsetRight
            end
            local ok, top, left, bottom, right = pcall(function()
                local tl, br = gs:GetGuiInset()
                if type(tl) == "number" then
                    return tl, 0, 0, 0
                end
                local t = (tl and tonumber(tl.Y)) or 0
                local l = (tl and tonumber(tl.X)) or 0
                local b = (br and tonumber(br.Y)) or 0
                local r = (br and tonumber(br.X)) or 0
                return t, l, b, r
            end)
            if ok and top ~= nil then
                return top, left, bottom, right
            end
            return SafeArea.InsetTop, SafeArea.InsetLeft, SafeArea.InsetBottom, SafeArea.InsetRight
        end

        local function readViewport()
            local cam = App.GetCamera()
            if cam then
                local ok, vp = pcall(function()
                    return cam.ViewportSize
                end)
                if ok and vp and tonumber(vp.X) and tonumber(vp.Y) then
                    if vp.X > 2 and vp.Y > 2 then
                        return { X = vp.X, Y = vp.Y }
                    end
                end
            end
            return SafeArea.Viewport
        end

        function SafeArea.ComputeLayout()
            local prevVp = SafeArea.Viewport
            local prevTop = SafeArea.InsetTop

            local top, left, bottom, right = readInsets()
            local vp = readViewport()

            SafeArea.InsetTop = top
            SafeArea.InsetLeft = left
            SafeArea.InsetBottom = bottom
            SafeArea.InsetRight = right
            SafeArea.Viewport = vp
            SafeArea.IsCompact = (vp.X < 920 or vp.Y < 480)
            SafeArea.IsPhone = (vp.X < 740 or vp.Y < 430)

            if vp.X ~= prevVp.X or vp.Y ~= prevVp.Y or top ~= prevTop then
                Bus.Emit("LayoutChanged", vp, top, SafeArea)
            end
            return SafeArea
        end

        function SafeArea.ClampPoint(a, b, c, d, e)
            local x, y, w, h
            if a == SafeArea then
                x, y, w, h = b, c, d, e
            else
                x, y, w, h = a, b, c, d
            end

            x = tonumber(x) or 0
            y = tonumber(y) or 0
            w = math.max(0, tonumber(w) or 0)
            h = math.max(0, tonumber(h) or 0)

            local vp = SafeArea.Viewport or { X = 1280, Y = 720 }
            local pad = 4
            local minX = (SafeArea.InsetLeft or 0) + pad
            local minY = (SafeArea.InsetTop or 0) + pad
            local maxX = vp.X - w - (SafeArea.InsetRight or 0) - pad
            local maxY = vp.Y - h - (SafeArea.InsetBottom or 0) - pad

            if maxX < minX then
                minX = math.max(0, (vp.X - w) * 0.5)
                maxX = minX
            end
            if maxY < minY then
                minY = math.max(SafeArea.InsetTop or 0, 0)
                maxY = minY
            end

            return clampNum(x, minX, maxX), clampNum(y, minY, maxY)
        end

        local function bindCameraSignals()
            if camScope then
                camScope:Clean()
            else
                camScope = Janitor.NewScope()
            end
            local cam = App.GetCamera()
            if cam and cam.GetPropertyChangedSignal then
                local okSig, sig = pcall(cam.GetPropertyChangedSignal, cam, "ViewportSize")
                if okSig and sig and sig.Connect then
                    camScope:Add(sig:Connect(function()
                        SafeArea.ComputeLayout()
                    end))
                end
            end
        end

        local function ensureWatchers()
            if watcherActive then
                return
            end
            watcherActive = true
            bindCameraSignals()
            local ws = Services.Workspace
            if ws and ws.GetPropertyChangedSignal then
                local okSig, sig = pcall(ws.GetPropertyChangedSignal, ws, "CurrentCamera")
                if okSig and sig and sig.Connect then
                    Janitor.Add(sig:Connect(function()
                        bindCameraSignals()
                        SafeArea.ComputeLayout()
                    end))
                end
            end
        end

        function SafeArea.Watch(a, b)
            local cb = (a == SafeArea) and b or a
            ensureWatchers()
            if type(cb) == "function" then
                return Bus.On("LayoutChanged", cb)
            end
            return nil
        end

        SafeArea.ComputeLayout()
        ensureWatchers()
    end

    initSafeArea()
end

-- ============================================================================
-- // BLOCK 6: MOTION ENGINE (App.Anim)
-- ============================================================================
do
    local function initAnim()
        local Anim = {}
        App.Anim = Anim

        local Tweens = setmetatable({}, { __mode = "k" })
        local Tokens = setmetatable({}, { __mode = "k" })
        local Threads = setmetatable({}, { __mode = "k" })
        local NumberConns = setmetatable({}, { __mode = "k" })

        local function enumVal(groupName, itemName)
            if Enum and Enum[groupName] then
                return Enum[groupName][itemName]
            end
            return itemName
        end

        local function makeTweenInfo(dur, styleName, dirName, repeatCount, reverses)
            if TweenInfo and TweenInfo.new then
                return TweenInfo.new(
                    dur,
                    enumVal("EasingStyle", styleName),
                    enumVal("EasingDirection", dirName),
                    repeatCount or 0,
                    reverses == true,
                    0
                )
            end
            return {
                Time = dur,
                EasingStyle = styleName,
                EasingDirection = dirName,
                RepeatCount = repeatCount or 0,
                Reverses = (reverses == true),
            }
        end

        local Presets = {
            Flash = makeTweenInfo(0.08, "Quad", "Out"),
            Snappy = makeTweenInfo(0.14, "Quint", "Out"),
            Spring = makeTweenInfo(0.24, "Back", "Out"),
            SpringSoft = makeTweenInfo(0.28, "Quint", "Out"),
            Exit = makeTweenInfo(0.16, "Quad", "In"),
            Pulse = makeTweenInfo(0.85, "Sine", "InOut", -1, true),
        }

        Anim.Presets = Presets
        for k, v in pairs(Presets) do
            Anim[k] = v
        end

        local function bumpToken(inst, groupKey)
            local tokMap = Tokens[inst]
            if not tokMap then
                tokMap = {}
                Tokens[inst] = tokMap
            end
            local nextTok = (tokMap[groupKey] or 0) + 1
            tokMap[groupKey] = nextTok
            return nextTok
        end

        local function cancelGroup(inst, groupKey)
            bumpToken(inst, groupKey)

            local twMap = Tweens[inst]
            if twMap and twMap[groupKey] then
                local rec = twMap[groupKey]
                twMap[groupKey] = nil
                if rec.conn then
                    pcall(rec.conn.Disconnect, rec.conn)
                end
                if rec.tween then
                    pcall(rec.tween.Cancel, rec.tween)
                    pcall(rec.tween.Destroy, rec.tween)
                end
            end

            local thMap = Threads[inst]
            if thMap and thMap[groupKey] then
                local th = thMap[groupKey]
                thMap[groupKey] = nil
                if type(th) == "thread" then
                    if th ~= coroutine.running() and task and task.cancel then
                        pcall(task.cancel, th)
                    end
                elseif type(th) == "table" then
                    th.cancelled = true
                end
            end

            local numMap = NumberConns[inst]
            if numMap and numMap[groupKey] then
                local conn = numMap[groupKey]
                numMap[groupKey] = nil
                if type(conn) == "function" then
                    pcall(conn)
                elseif conn.Disconnect then
                    pcall(conn.Disconnect, conn)
                end
            end
        end

        function Anim.Cancel(inst, groupKey)
            if not inst then
                return
            end
            if groupKey ~= nil then
                cancelGroup(inst, groupKey)
                return
            end

            local keys = {}
            if Tweens[inst] then
                for k in pairs(Tweens[inst]) do
                    keys[k] = true
                end
            end
            if Threads[inst] then
                for k in pairs(Threads[inst]) do
                    keys[k] = true
                end
            end
            if NumberConns[inst] then
                for k in pairs(NumberConns[inst]) do
                    keys[k] = true
                end
            end
            if Tokens[inst] then
                for k in pairs(Tokens[inst]) do
                    keys[k] = true
                end
            end
            for k in pairs(keys) do
                cancelGroup(inst, k)
            end
        end

        function Anim.Play(inst, groupKey, info, props, onComplete)
            if not App.Running or not inst or not inst.Parent then
                return nil
            end
            if type(props) ~= "table" then
                return nil
            end
            local ts = Services.TweenService
            if not ts or not ts.Create then
                return nil
            end

            local gKey = groupKey or "_default"
            cancelGroup(inst, gKey)
            local tok = bumpToken(inst, gKey)

            local okTw, tw = pcall(ts.Create, ts, inst, info or Presets.Snappy, props)
            if not okTw or not tw then
                return nil
            end

            local twMap = Tweens[inst]
            if not twMap then
                twMap = {}
                Tweens[inst] = twMap
            end
            local rec = { tween = tw, conn = nil, isPulse = false }
            twMap[gKey] = rec

            local completedEnum = enumVal("PlaybackState", "Completed")
            if tw.Completed and tw.Completed.Connect then
                rec.conn = tw.Completed:Connect(function(playbackState)
                    if rec.conn then
                        pcall(rec.conn.Disconnect, rec.conn)
                        rec.conn = nil
                    end
                    local curMap = Tweens[inst]
                    if curMap and curMap[gKey] == rec then
                        curMap[gKey] = nil
                    end
                    pcall(tw.Destroy, tw)

                    local curTok = Tokens[inst] and Tokens[inst][gKey]
                    local doneOk = (not completedEnum) or (playbackState == completedEnum) or (playbackState == nil)
                    if App.Running and curTok == tok and doneOk and type(onComplete) == "function" then
                        pcall(onComplete, inst)
                    end
                end)
            end

            pcall(tw.Play, tw)
            return tw
        end

        function Anim.EnsureScale(gui)
            if not gui then
                return nil
            end
            local existing = gui.FindFirstChild and gui:FindFirstChild("PLKX_UIScale")
            if existing then
                return existing
            end
            if Instance and Instance.new then
                local sc = Instance.new("UIScale")
                sc.Name = "PLKX_UIScale"
                sc.Scale = 1
                sc.Parent = gui
                return sc
            end
            return nil
        end

        function Anim.BindButton(btn, opts)
            if not btn then
                return nil
            end
            opts = opts or {}
            pcall(function()
                btn.AutoButtonColor = false
            end)

            local scale = Anim.EnsureScale(btn)
            local stroke = opts.stroke or (btn.FindFirstChildOfClass and btn:FindFirstChildOfClass("UIStroke"))
            local pressScale = opts.pressScale or 0.94
            local baseTrans = stroke and stroke.Transparency or 0.35
            local hoverTrans = opts.hoverTransparency or math.max(0, baseTrans - 0.25)
            local baseColor = stroke and stroke.Color or nil
            local hoverColor = opts.hoverColor or baseColor

            local touchType = enumVal("UserInputType", "Touch")
            local mb1Type = enumVal("UserInputType", "MouseButton1")

            local function isPressInput(inp)
                if not inp then
                    return true
                end
                local ut = inp.UserInputType
                if ut == nil then
                    return true
                end
                return ut == mb1Type or ut == touchType or ut == "MouseButton1" or ut == "Touch"
            end

            if btn.MouseEnter and btn.MouseEnter.Connect then
                Janitor.Add(btn.MouseEnter:Connect(function()
                    if stroke then
                        local goal = { Transparency = hoverTrans }
                        if hoverColor then
                            goal.Color = hoverColor
                        end
                        Anim.Play(stroke, "btnHover", Presets.Flash, goal)
                    end
                    if opts.hoverScale and scale then
                        Anim.Play(scale, "btnPress", Presets.Flash, { Scale = opts.hoverScale })
                    end
                end))
            end

            if btn.MouseLeave and btn.MouseLeave.Connect then
                Janitor.Add(btn.MouseLeave:Connect(function()
                    if stroke then
                        local goal = { Transparency = baseTrans }
                        if baseColor then
                            goal.Color = baseColor
                        end
                        Anim.Play(stroke, "btnHover", Presets.Snappy, goal)
                    end
                    if scale then
                        Anim.Play(scale, "btnPress", Presets.Spring, { Scale = 1.0 })
                    end
                end))
            end

            if btn.InputBegan and btn.InputBegan.Connect then
                Janitor.Add(btn.InputBegan:Connect(function(inp)
                    if scale and isPressInput(inp) then
                        Anim.Play(scale, "btnPress", Presets.Flash, { Scale = pressScale })
                    end
                end))
            end

            if btn.InputEnded and btn.InputEnded.Connect then
                Janitor.Add(btn.InputEnded:Connect(function(inp)
                    if scale and isPressInput(inp) then
                        Anim.Play(scale, "btnPress", Presets.Spring, { Scale = 1.0 })
                    end
                end))
            end

            return scale
        end

        function Anim.Pulse(inst, groupKey, info, props, active)
            if not inst then
                return nil
            end
            local gKey = groupKey or "_pulse"
            if not active then
                cancelGroup(inst, gKey)
                return nil
            end
            local curMap = Tweens[inst]
            if curMap and curMap[gKey] and curMap[gKey].isPulse then
                return curMap[gKey].tween
            end
            local tw = Anim.Play(inst, gKey, info or Presets.Pulse, props)
            if tw and Tweens[inst] and Tweens[inst][gKey] then
                Tweens[inst][gKey].isPulse = true
            end
            return tw
        end

        local function evalEaseOut(alpha)
            local ts = Services.TweenService
            if ts and ts.GetValue and Enum and Enum.EasingStyle and Enum.EasingDirection then
                local ok, val = pcall(ts.GetValue, ts, alpha, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                if ok and type(val) == "number" then
                    return val
                end
            end
            local inv = 1 - alpha
            return 1 - (inv * inv * inv * inv * inv)
        end

        function Anim.Number(inst, key, fromV, toV, dur, onStep, onComplete)
            if not App.Running or not inst or not inst.Parent then
                return nil
            end
            local gKey = key or "_num"
            cancelGroup(inst, gKey)
            local tok = bumpToken(inst, gKey)

            local fromNum = tonumber(fromV) or 0
            local toNum = tonumber(toV) or 0
            local totalDur = tonumber(dur) or 0

            if totalDur <= 0 or fromNum == toNum then
                if type(onStep) == "function" then
                    pcall(onStep, toNum, 1)
                end
                if type(onComplete) == "function" then
                    pcall(onComplete, inst)
                end
                return nil
            end

            local rs = Services.RunService
            if not rs or not rs.RenderStepped or not rs.RenderStepped.Connect then
                if type(onStep) == "function" then
                    pcall(onStep, toNum, 1)
                end
                if type(onComplete) == "function" then
                    pcall(onComplete, inst)
                end
                return nil
            end

            local numMap = NumberConns[inst]
            if not numMap then
                numMap = {}
                NumberConns[inst] = numMap
            end

            local startT = os.clock()
            local conn
            conn = rs.RenderStepped:Connect(function()
                local curTok = Tokens[inst] and Tokens[inst][gKey]
                if not App.Running or not inst.Parent or curTok ~= tok then
                    if conn then
                        pcall(conn.Disconnect, conn)
                    end
                    if NumberConns[inst] and NumberConns[inst][gKey] == conn then
                        NumberConns[inst][gKey] = nil
                    end
                    return
                end

                local alpha = (os.clock() - startT) / totalDur
                if alpha < 0 then
                    alpha = 0
                elseif alpha > 1 then
                    alpha = 1
                end

                local eased = evalEaseOut(alpha)
                local currentVal = fromNum + (toNum - fromNum) * eased
                if type(onStep) == "function" then
                    pcall(onStep, currentVal, alpha)
                end

                if alpha >= 1 then
                    if conn then
                        pcall(conn.Disconnect, conn)
                    end
                    if NumberConns[inst] and NumberConns[inst][gKey] == conn then
                        NumberConns[inst][gKey] = nil
                    end
                    if type(onComplete) == "function" then
                        pcall(onComplete, inst)
                    end
                end
            end)

            numMap[gKey] = conn
            Janitor.Add(conn)
            return conn
        end

        function Anim.Delay(inst, key, sec, fn)
            if not App.Running or not inst or not inst.Parent or type(fn) ~= "function" then
                return nil
            end
            local gKey = key or "_delay"
            cancelGroup(inst, gKey)
            local tok = bumpToken(inst, gKey)

            local thMap = Threads[inst]
            if not thMap then
                thMap = {}
                Threads[inst] = thMap
            end

            local th = Janitor.Delay(sec, function()
                local curMap = Threads[inst]
                if curMap then
                    curMap[gKey] = nil
                end
                local curTok = Tokens[inst] and Tokens[inst][gKey]
                if App.Running and inst.Parent and curTok == tok then
                    pcall(fn, inst)
                end
            end)

            if th then
                thMap[gKey] = th
            end
            return th
        end

        function Anim.CleanupAll()
            local allInsts = {}
            for inst in pairs(Tweens) do
                allInsts[inst] = true
            end
            for inst in pairs(Threads) do
                allInsts[inst] = true
            end
            for inst in pairs(NumberConns) do
                allInsts[inst] = true
            end
            for inst in pairs(Tokens) do
                allInsts[inst] = true
            end

            for inst in pairs(allInsts) do
                Anim.Cancel(inst)
                Tweens[inst] = nil
                Threads[inst] = nil
                NumberConns[inst] = nil
                Tokens[inst] = nil
            end
        end

        Janitor.AddCleanup(Anim.CleanupAll)
    end

    initAnim()
end

-- ============================================================================
-- // BLOCK 7: PERSISTENCE & PRESETS (App.Persistence)
-- ============================================================================
do
    local function initPersistence()
        local Persistence = {}
        App.Persistence = Persistence

        local ROOT_DIR = "PrisonLifeKX"
        local PROFILE_DIR = "PrisonLifeKX/profiles"
        local TRANSIENT_KEYS = {
            HubVisible = true,
            HubSearch = true,
        }
        local memoryProfiles = {}

        local function sanitizeName(name)
            local s = App.Trim(tostring(name or ""))
            s = s:gsub("%.json$", "")
            s = s:gsub("[^%w_%-]", "_")
            if s == "" then
                s = "default"
            end
            return s
        end

        local function profilePath(name)
            return PROFILE_DIR .. "/" .. sanitizeName(name) .. ".json"
        end

        local function ensureFolders()
            if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
                return false
            end
            local ok1, hasRoot = pcall(isfolder, ROOT_DIR)
            if ok1 and not hasRoot then
                pcall(makefolder, ROOT_DIR)
            end
            local ok2, hasProf = pcall(isfolder, PROFILE_DIR)
            if ok2 and not hasProf then
                pcall(makefolder, PROFILE_DIR)
            end
            local ok3, ready = pcall(isfolder, PROFILE_DIR)
            return ok3 and ready == true
        end

        local function isContiguousArray(t)
            local n = #t
            if n == 0 then
                return false
            end
            for k in pairs(t) do
                if type(k) ~= "number" or k < 1 or k > n or math.floor(k) ~= k then
                    return false
                end
            end
            return true
        end

        local function sanitizeJsonVal(v, seen)
            local tv = type(v)
            if tv == "boolean" or tv == "string" then
                return v
            elseif tv == "number" then
                if v ~= v or v == math.huge or v == -math.huge then
                    return 0
                end
                return v
            elseif tv == "table" then
                if seen[v] then
                    return nil
                end
                seen[v] = true
                local out = {}
                if isContiguousArray(v) then
                    for i = 1, #v do
                        local sv = sanitizeJsonVal(v[i], seen)
                        if sv ~= nil then
                            out[#out + 1] = sv
                        end
                    end
                else
                    for k, val in pairs(v) do
                        local tk = type(k)
                        if tk == "string" or tk == "number" then
                            local sv = sanitizeJsonVal(val, seen)
                            if sv ~= nil then
                                out[tostring(k)] = sv
                            end
                        end
                    end
                end
                return out
            end
            return nil
        end

        -- Pure Lua JSON encoder/decoder fallback when HttpService is absent (e.g. headless LuaJIT)
        local function encodeStr(s)
            local esc = {
                ['"'] = '\\"',
                ['\\'] = '\\\\',
                ['\b'] = '\\b',
                ['\f'] = '\\f',
                ['\n'] = '\\n',
                ['\r'] = '\\r',
                ['\t'] = '\\t',
            }
            return '"' .. (s:gsub('[%z\1-\31\\"]', function(c)
                return esc[c] or string.format("\\u%04x", string.byte(c))
            end)) .. '"'
        end

        local function fallbackEncode(val)
            local tv = type(val)
            if tv == "nil" then
                return "null"
            elseif tv == "boolean" then
                return val and "true" or "false"
            elseif tv == "number" then
                return tostring(val)
            elseif tv == "string" then
                return encodeStr(val)
            elseif tv == "table" then
                local n = #val
                local isArray = n > 0
                if isArray then
                    for k in pairs(val) do
                        if type(k) ~= "number" or k < 1 or k > n or math.floor(k) ~= k then
                            isArray = false
                            break
                        end
                    end
                end
                local parts = {}
                if isArray then
                    for i = 1, n do
                        parts[#parts + 1] = fallbackEncode(val[i])
                    end
                    return "[" .. table.concat(parts, ",") .. "]"
                end
                for k, v in pairs(val) do
                    if type(k) == "string" then
                        parts[#parts + 1] = encodeStr(k) .. ":" .. fallbackEncode(v)
                    end
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
            return "null"
        end

        local function fallbackDecode(str)
            local pos = 1
            local len = #str

            local function skipWs()
                while pos <= len do
                    local b = string.byte(str, pos)
                    if b == 32 or b == 9 or b == 10 or b == 13 then
                        pos = pos + 1
                    else
                        break
                    end
                end
            end

            local parseValue

            local function parseStr()
                pos = pos + 1
                local out = {}
                while pos <= len do
                    local ch = string.sub(str, pos, pos)
                    if ch == '"' then
                        pos = pos + 1
                        return table.concat(out)
                    elseif ch == '\\' then
                        local nxt = string.sub(str, pos + 1, pos + 1)
                        local map = { ['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b', f = '\f', n = '\n', r = '\r', t = '\t' }
                        if map[nxt] then
                            out[#out + 1] = map[nxt]
                            pos = pos + 2
                        elseif nxt == 'u' then
                            local hex = string.sub(str, pos + 2, pos + 5)
                            local code = tonumber(hex, 16) or 32
                            out[#out + 1] = (code < 128) and string.char(code) or "?"
                            pos = pos + 6
                        else
                            out[#out + 1] = nxt
                            pos = pos + 2
                        end
                    else
                        out[#out + 1] = ch
                        pos = pos + 1
                    end
                end
                error("Unterminated JSON string")
            end

            local function parseArr()
                pos = pos + 1
                local arr = {}
                skipWs()
                if string.sub(str, pos, pos) == "]" then
                    pos = pos + 1
                    return arr
                end
                while pos <= len do
                    arr[#arr + 1] = parseValue()
                    skipWs()
                    local ch = string.sub(str, pos, pos)
                    if ch == "]" then
                        pos = pos + 1
                        return arr
                    elseif ch == "," then
                        pos = pos + 1
                    else
                        error("Expected ',' or ']' in JSON array")
                    end
                end
                error("Unterminated JSON array")
            end

            local function parseObj()
                pos = pos + 1
                local obj = {}
                skipWs()
                if string.sub(str, pos, pos) == "}" then
                    pos = pos + 1
                    return obj
                end
                while pos <= len do
                    skipWs()
                    if string.sub(str, pos, pos) ~= '"' then
                        error("Expected string key in JSON object")
                    end
                    local key = parseStr()
                    skipWs()
                    if string.sub(str, pos, pos) ~= ":" then
                        error("Expected ':' in JSON object")
                    end
                    pos = pos + 1
                    obj[key] = parseValue()
                    skipWs()
                    local ch = string.sub(str, pos, pos)
                    if ch == "}" then
                        pos = pos + 1
                        return obj
                    elseif ch == "," then
                        pos = pos + 1
                    else
                        error("Expected ',' or '}' in JSON object")
                    end
                end
                error("Unterminated JSON object")
            end

            parseValue = function()
                skipWs()
                local ch = string.sub(str, pos, pos)
                if ch == '"' then
                    return parseStr()
                elseif ch == "{" then
                    return parseObj()
                elseif ch == "[" then
                    return parseArr()
                elseif string.sub(str, pos, pos + 3) == "true" then
                    pos = pos + 4
                    return true
                elseif string.sub(str, pos, pos + 4) == "false" then
                    pos = pos + 5
                    return false
                elseif string.sub(str, pos, pos + 3) == "null" then
                    pos = pos + 4
                    return nil
                else
                    local s, e = string.find(str, "^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
                    if s then
                        local num = tonumber(string.sub(str, s, e))
                        pos = e + 1
                        if num ~= nil then
                            return num
                        end
                    end
                    error("Invalid JSON token at " .. tostring(pos))
                end
            end

            return parseValue()
        end

        local function jsonEncode(tbl)
            local hs = Services.HttpService
            if hs and hs.JSONEncode then
                local ok, res = pcall(hs.JSONEncode, hs, tbl)
                if ok and type(res) == "string" then
                    return true, res
                end
            end
            local okF, resF = pcall(fallbackEncode, tbl)
            return okF, resF
        end

        local function jsonDecode(raw)
            if type(raw) ~= "string" or raw == "" then
                return false, "Empty JSON"
            end
            local hs = Services.HttpService
            if hs and hs.JSONDecode then
                local ok, res = pcall(hs.JSONDecode, hs, raw)
                if ok and type(res) == "table" then
                    return true, res
                end
            end
            local okF, resF = pcall(fallbackDecode, raw)
            if okF and type(resF) == "table" then
                return true, resF
            end
            return false, resF
        end

        local function buildPayload()
            local data = {}
            for i = 1, #App.StateOrder do
                local key = App.StateOrder[i]
                if not TRANSIENT_KEYS[key] then
                    local cleanVal = sanitizeJsonVal(State[key], {})
                    if cleanVal ~= nil then
                        data[key] = cleanVal
                    end
                end
            end
            return {
                version = 3,
                placeId = (App.Env and App.Env.PlaceId) or 155615604,
                state = data,
            }
        end

        local NUMERIC_ID_MAPS = {
            KillAuraWhitelist = true,
            ArrestWhitelist = true,
            LoopKillTargets = true,
        }

        local function applyLoadedState(tbl)
            local stateMap = (type(tbl.state) == "table") and tbl.state or tbl
            if type(stateMap) ~= "table" then
                return false
            end
            for i = 1, #App.StateOrder do
                local key = App.StateOrder[i]
                if not TRANSIENT_KEYS[key] and stateMap[key] ~= nil then
                    local rawVal = stateMap[key]
                    if key == "Keybinds" and type(rawVal) == "table" then
                        local merged = App.DeepCopy(App.StateDefaults.Keybinds)
                        for actionName, bindKey in pairs(rawVal) do
                            if type(actionName) == "string" and type(bindKey) == "string" then
                                merged[actionName] = bindKey
                            end
                        end
                        App.SetState(key, merged, true)
                    elseif NUMERIC_ID_MAPS[key] and type(rawVal) == "table" then
                        local restored = {}
                        for k, v in pairs(rawVal) do
                            if type(k) == "string" and k:match("^%d+$") then
                                local n = tonumber(k)
                                if n then
                                    restored[n] = App.DeepCopy(v)
                                end
                            else
                                restored[k] = App.DeepCopy(v)
                            end
                        end
                        App.SetState(key, restored, true)
                    else
                        App.SetState(key, App.DeepCopy(rawVal), true)
                    end
                end
            end
            return true
        end

        function Persistence.Save(profileName)
            local safeName = sanitizeName(profileName)
            local payload = buildPayload()
            local okEnc, json = jsonEncode(payload)
            if not okEnc or type(json) ~= "string" then
                return false, "JSON encode failed"
            end

            memoryProfiles[safeName] = json

            if type(writefile) == "function" then
                ensureFolders()
                local path = profilePath(safeName)
                local okW, errW = pcall(writefile, path, json)
                if okW then
                    Bus.Emit("ProfileSaved", safeName, path)
                    return true, path
                end
                return false, tostring(errW or "writefile failed")
            end

            Bus.Emit("ProfileSaved", safeName, "memory")
            return true, "memory:" .. safeName
        end

        function Persistence.Load(profileName)
            local safeName = sanitizeName(profileName)
            local raw = nil

            if type(readfile) == "function" then
                local path = profilePath(safeName)
                local exists = true
                if type(isfile) == "function" then
                    local okIs, resIs = pcall(isfile, path)
                    exists = (okIs and resIs == true)
                end
                if exists then
                    local okR, data = pcall(readfile, path)
                    if okR and type(data) == "string" and data ~= "" then
                        raw = data
                    end
                end
            end

            if not raw then
                raw = memoryProfiles[safeName]
            end
            if not raw then
                return false, "Profile not found: " .. safeName
            end

            local okDec, parsed = jsonDecode(raw)
            if not okDec or type(parsed) ~= "table" then
                return false, "Invalid profile JSON"
            end

            applyLoadedState(parsed)
            Bus.Emit("ProfileLoaded", safeName)
            return true, safeName
        end

        function Persistence.Delete(profileName)
            local safeName = sanitizeName(profileName)
            local removed = false
            if memoryProfiles[safeName] ~= nil then
                memoryProfiles[safeName] = nil
                removed = true
            end
            if type(delfile) == "function" then
                local path = profilePath(safeName)
                local exists = true
                if type(isfile) == "function" then
                    local okIs, resIs = pcall(isfile, path)
                    exists = (okIs and resIs == true)
                end
                if exists then
                    local okD = pcall(delfile, path)
                    if okD then
                        removed = true
                    end
                end
            end
            if removed then
                Bus.Emit("ProfileDeleted", safeName)
                return true, safeName
            end
            return false, "Profile not found: " .. safeName
        end

        function Persistence.List()
            local seen = {}
            local out = {}
            for name in pairs(memoryProfiles) do
                if not seen[name] then
                    seen[name] = true
                    out[#out + 1] = name
                end
            end
            if type(listfiles) == "function" then
                ensureFolders()
                local okL, files = pcall(listfiles, PROFILE_DIR)
                if okL and type(files) == "table" then
                    for i = 1, #files do
                        local p = tostring(files[i])
                        local stem = p:match("([^/\\]+)%.json$")
                        if stem and not seen[stem] then
                            seen[stem] = true
                            out[#out + 1] = stem
                        end
                    end
                end
            end
            table.sort(out)
            return out
        end

        function Persistence.Reset()
            for i = 1, #App.StateOrder do
                local key = App.StateOrder[i]
                local def = App.DeepCopy(App.StateDefaults[key])
                App.SetState(key, def, true)
            end
            Bus.Emit("ProfileReset")
            return true
        end

        function Persistence.AutoLoad(profileName)
            if not State.AutoLoadConfig then
                return false, "AutoLoadConfig disabled"
            end
            return Persistence.Load(profileName or "default")
        end

        local PRESETS = {
            Legit = {
                ShieldEnabled = false,
                ShieldAutoEquip = false,
                ShieldSpinBlock = false,
                FEInvisible = false,
                Ragebot = false,
                KillAura = false,
                HitboxExpander = false,
                SilentAim = true,
                SilentAimFOV = 70,
                SilentAimShowFOV = false,
                SilentAimHitChance = 75,
                SilentAimHeadChance = 35,
                SilentAimWallcheck = true,
                SilentAimWallbang = false,
                SilentAimTeamCheck = true,
                SilentAimSkipDown = true,
                AimAssist = true,
                AimAssistFOV = 110,
                AimAssistSmooth = 0.35,
                GunMods = false,
                AutoGetGuns = false,
                AutoArrest = false,
                AutoTaze = false,
                AutoDetonateC4 = false,
                MaxSpeed = false,
                Fly = false,
                Noclip = false,
                JumpPowerEnabled = false,
                InfiniteJump = false,
                VehicleFly = false,
                VehicleFling = false,
                ESPEnabled = true,
                ESPHideTeam = true,
                ESPBoxes = false,
                ESPNames = true,
                ESPHealthBar = true,
                ESPDistance = true,
                ESPTracers = false,
                BulletTracers = false,
                Hitmarker = true,
                HitSound = true,
                KillSound = true,
                DamageNumbers = true,
                FenceGodmode = true,
                AntiKillPlane = true,
                AntiTaze = true,
                AntiAFK = true,
            },
            Rage = {
                ShieldEnabled = true,
                ShieldMode = "Hybrid",
                ShieldSize = 7.0,
                ShieldTransparency = 0.84,
                ShieldAutoEquip = true,
                ShieldAutoFaceShooter = true,
                ShieldSpinBlock = false,
                AntiTaze = true,
                AntiArrest = true,
                Ragebot = true,
                Ragebot360 = true,
                RagebotAutoSwitch = true,
                RagebotRate = 24,
                RagebotPeekShield = true,
                SilentAim = true,
                SilentAimFOV = 180,
                SilentAimShowFOV = true,
                SilentAimHitChance = 100,
                SilentAimHeadChance = 95,
                SilentAimWallcheck = false,
                SilentAimWallbang = true,
                SilentAimTeamCheck = true,
                SilentAimSkipDown = true,
                KillAura = true,
                KillAuraRange = 18,
                KillAuraRate = 16,
                HitboxExpander = false,
                AntiRiotShield = true,
                AutoArmorPen = true,
                GunMods = true,
                GunAutoFire = true,
                GunFireRateSPS = 28,
                GunNoSpread = true,
                GunInfiniteRange = true,
                GunAutoReload = true,
                AutoGetGuns = true,
                AutoArmor = true,
                AutoHeal = true,
                AutoHealThreshold = 75,
                AutoRespawn = true,
                FenceGodmode = true,
                AntiKillPlane = true,
                AntiFling = true,
                AntiJumpCooldown = true,
                AntiNoclipBypass = true,
                AntiAFK = true,
                ESPEnabled = true,
                ESPBoxes = true,
                ESPNames = true,
                ESPHealthBar = true,
                BulletTracers = true,
                Hitmarker = true,
                HitSound = true,
                KillSound = true,
                DamageNumbers = true,
                ShieldHitVFX = true,
            },
            Mobile = {
                ShieldEnabled = true,
                ShieldMode = "Hybrid",
                ShieldAutoEquip = true,
                ShieldTransparency = 0.86,
                AntiTaze = true,
                Ragebot = false,
                SilentAim = true,
                SilentAimFOV = 150,
                SilentAimShowFOV = true,
                SilentAimHitChance = 100,
                SilentAimHeadChance = 75,
                SilentAimWallcheck = true,
                SilentAimWallbang = true,
                AimAssist = true,
                AimAssistFOV = 150,
                AimAssistSmooth = 0.30,
                KillAura = true,
                KillAuraRange = 16,
                KillAuraRate = 12,
                GunMods = true,
                GunAutoFire = true,
                GunFireRateSPS = 20,
                GunNoSpread = true,
                GunInfiniteRange = true,
                GunAutoReload = true,
                AutoArmor = true,
                AutoHeal = true,
                AutoHealThreshold = 70,
                FenceGodmode = true,
                AntiKillPlane = true,
                AntiJumpCooldown = true,
                AntiAFK = true,
                ShowComboButton = true,
                ShowKXBar = true,
                ShowIYPill = true,
                ShowRightActions = true,
                ShowPinnedPills = true,
                ShowShieldBadge = true,
                ESPEnabled = true,
                ESPBoxes = true,
                ESPNames = true,
                ESPHealthBar = true,
                ESPDistance = false,
                ESPTracers = false,
                ESPMaxDistance = 420,
                ESPDetailDistance = 120,
                BulletTracers = true,
                Hitmarker = true,
                HitSound = true,
                KillSound = true,
            },
        }

        function Persistence.ApplyPreset(presetName)
            local q = string.lower(App.Trim(tostring(presetName or "")))
            local canonical = nil
            for name in pairs(PRESETS) do
                if string.lower(name) == q then
                    canonical = name
                    break
                end
            end
            if not canonical then
                return false, "Unknown preset: " .. tostring(presetName)
            end
            for key, val in pairs(PRESETS[canonical]) do
                App.SetState(key, App.DeepCopy(val), true)
            end
            Bus.Emit("PresetApplied", canonical)
            return true, canonical
        end
    end

    initPersistence()
end


-- ============================================================================
-- // MODULE 2: REMOTES, TARGET RESOLVER, VFX POOL, TOOL ARBITER, COMBAT & WEAPONS
-- ============================================================================

--!nocheck
-- Prison Life 2026 - KX Edition V3 | Module 2: Game Combat, Remotes, Targets, VFX & Weapons
-- Consumes Module 1 exports cleanly (GEN_ENV, Services, App, State, Palette, Janitor, Bus, UI).
-- Zero extra file-scope locals; all subsystems are scoped inside `do ... end` blocks.

--------------------------------------------------------------------------------
-- 1. APP.REMOTES
--------------------------------------------------------------------------------
do
    local function findOrWait(parent, name, timeout)
        if not parent then
            return nil
        end
        local direct = parent:FindFirstChild(name)
        if direct then
            return direct
        end
        local ok, waited = pcall(parent.WaitForChild, parent, name, timeout or 8)
        if ok then
            return waited
        end
        return nil
    end

    local function initRemotes()
        local rs = Services.ReplicatedStorage
        local remCache = {}
        local gunRemCache = {}

        local RemotesApi = {
            GetRemotes = function()
                return remCache
            end,
            GetGunRemotes = function()
                return gunRemCache
            end,
        }

        function RemotesApi.Refresh()
            local remFolder = findOrWait(rs, "Remotes", 8)
            local gunFolder = findOrWait(rs, "GunRemotes", 8)

            local c4Folder = remFolder and (remFolder:FindFirstChild("C4") or findOrWait(remFolder, "C4", 2)) or nil
            local c4Act = c4Folder and (c4Folder:FindFirstChild("ActivateC4") or c4Folder:FindFirstChild("DetonateC4")) or nil
            if not c4Act and remFolder then
                c4Act = remFolder:FindFirstChild("ActivateC4") or remFolder:FindFirstChild("DetonateC4")
            end

            remCache = {
                Folder = remFolder,
                RequestTeamChange = remFolder and remFolder:FindFirstChild("RequestTeamChange") or nil,
                GiverPressed = remFolder and remFolder:FindFirstChild("GiverPressed") or nil,
                InteractWithItem = remFolder and remFolder:FindFirstChild("InteractWithItem") or nil,
                TouchGiver = remFolder and remFolder:FindFirstChild("TouchGiver") or nil,
                ArrestPlayer = remFolder and remFolder:FindFirstChild("ArrestPlayer") or nil,
                ShieldEquipped = remFolder and remFolder:FindFirstChild("ShieldEquipped") or nil,
                ActivateC4 = c4Act,
                DetonateC4 = c4Act,
                EatFood = remFolder and (remFolder:FindFirstChild("EatFood") or remFolder:FindFirstChild("SnackEaten")) or nil,
                SnackEaten = remFolder and remFolder:FindFirstChild("SnackEaten") or nil,
                UpdateSetting = remFolder and remFolder:FindFirstChild("UpdateSetting") or nil,
                RequestHere = remFolder and remFolder:FindFirstChild("RequestHere") or nil,
                ClientArrested = remFolder and remFolder:FindFirstChild("ClientArrested") or nil,
                MessageReceived = remFolder and remFolder:FindFirstChild("MessageReceived") or nil,
                RequestCollisionChange = remFolder and remFolder:FindFirstChild("RequestCollisionChange") or nil,
                ShootEvent = remFolder and remFolder:FindFirstChild("ShootEvent") or nil,
                MeleeEvent = rs:FindFirstChild("meleeEvent") or findOrWait(rs, "meleeEvent", 1),
            }

            gunRemCache = {
                Folder = gunFolder,
                PlayerTased = (gunFolder and gunFolder:FindFirstChild("PlayerTased")) or (remFolder and remFolder:FindFirstChild("PlayerTased")) or nil,
                TasePlayer = gunFolder and gunFolder:FindFirstChild("TasePlayer") or nil,
                ShootEvent = gunFolder and gunFolder:FindFirstChild("ShootEvent") or remCache.ShootEvent,
                Reload = gunFolder and gunFolder:FindFirstChild("Reload") or nil,
                ReplicateEvent = gunFolder and gunFolder:FindFirstChild("ReplicateEvent") or nil,
            }

            RemotesApi.RequestTeamChange = remCache.RequestTeamChange
            RemotesApi.GiverPressed = remCache.GiverPressed
            RemotesApi.InteractWithItem = remCache.InteractWithItem
            RemotesApi.TouchGiver = remCache.TouchGiver
            RemotesApi.ArrestPlayer = remCache.ArrestPlayer
            RemotesApi.MeleeEvent = remCache.MeleeEvent
            RemotesApi.ShieldEquipped = remCache.ShieldEquipped
            RemotesApi.DetonateC4 = c4Act
            RemotesApi.ActivateC4 = c4Act
            RemotesApi.EatFood = remCache.EatFood
            RemotesApi.SnackEaten = remCache.SnackEaten
            RemotesApi.UpdateSetting = remCache.UpdateSetting
            RemotesApi.RequestHere = remCache.RequestHere
            RemotesApi.ClientArrested = remCache.ClientArrested
            RemotesApi.MessageReceived = remCache.MessageReceived
            RemotesApi.RequestCollisionChange = remCache.RequestCollisionChange
            RemotesApi.PlayerTased = gunRemCache.PlayerTased
            RemotesApi.TasePlayer = gunRemCache.TasePlayer
            RemotesApi.ShootEvent = gunRemCache.ShootEvent
            RemotesApi.Reload = gunRemCache.Reload
            RemotesApi.ReplicateEvent = gunRemCache.ReplicateEvent

            local shared = rs:FindFirstChild("SharedModules") or findOrWait(rs, "SharedModules", 4)
            local tracersMod = shared and shared:FindFirstChild("GunTracers") or nil
            if tracersMod then
                local reqFn = (GEN_ENV and rawget(GEN_ENV, "require")) or (type(require) == "function" and require) or rawget(_G, "require")
                if type(reqFn) == "function" then
                    local ok, mod = pcall(reqFn, tracersMod)
                    RemotesApi.GunTracers = (ok and type(mod) == "table") and mod or nil
                end
            else
                RemotesApi.GunTracers = nil
            end

            return RemotesApi
        end

        App.Remotes = RemotesApi
        RemotesApi.Refresh()
    end

    initRemotes()
end

--------------------------------------------------------------------------------
-- 2. APP.TARGETS
--------------------------------------------------------------------------------
do
    local function getOverlapCtor()
        local ok, ov = pcall(function()
            return OverlapParams
        end)
        if ok and ov ~= nil then
            return ov
        end
        return (GEN_ENV and rawget(GEN_ENV, "OverlapParams")) or rawget(_G, "OverlapParams")
    end

    local function initTargets()
        local Players = Services.Players
        local Workspace = Services.Workspace
        local UserInputService = Services.UserInputService

        local Targets = {}
        local scannerRayParams = RaycastParams.new()
        scannerRayParams.FilterType = Enum.RaycastFilterType.Exclude
        scannerRayParams.RespectCanCollide = true

        local overlapCtor = getOverlapCtor()
        local scannerOverlapParams = overlapCtor and overlapCtor.new() or nil
        if scannerOverlapParams then
            scannerOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
        end

        local function isWhitelistBlocked(plr, whitelistMap)
            if type(whitelistMap) ~= "table" or not plr then
                return false
            end
            if whitelistMap[plr] or whitelistMap[plr.UserId] or whitelistMap[plr.Name] then
                return true
            end
            local lowerName = string.lower(plr.Name)
            if whitelistMap[lowerName] then
                return true
            end
            return false
        end

        function Targets.GetTeamColor(plr)
            if not plr then
                return Palette.TextPrimary
            end
            local tName = plr.Team and plr.Team.Name or "Neutral"
            if tName == "Guards" then
                return Palette.GuardBlue
            elseif tName == "Criminals" then
                return Palette.CrimRed
            elseif tName == "Inmates" then
                local char = App.GetChar(plr)
                if char and char:GetAttribute("Hostile") then
                    return Palette.RageCrimson
                end
                return Palette.InmateOrange
            elseif tName == "Neutral" then
                return Palette.NeutralGrey
            end
            if plr.TeamColor then
                return plr.TeamColor.Color
            end
            return Palette.TextPrimary
        end

        function Targets.GetCursorOrCenterPos()
            local cam = App.GetCamera()
            local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
            if App.IsMobileInput() then
                local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
                local lplr = App.LocalPlayer
                local off = lplr and lplr:GetAttribute("MobileCursorOffset") or nil
                if typeof(off) == "Vector2" then
                    return center + off
                elseif type(off) == "number" then
                    return center + Vector2.new(0, off)
                end
                return center
            end
            local ok, loc = pcall(UserInputService.GetMouseLocation, UserInputService)
            if ok and typeof(loc) == "Vector2" then
                return loc
            end
            return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        end

        function Targets.IsValidCombatTarget(plr, requireHostileInmate, whitelistMap, skipDownOverride, teamCheckOverride)
            local lplr = App.LocalPlayer
            if not plr or plr == lplr or isWhitelistBlocked(plr, whitelistMap) then
                return false
            end

            local char = App.GetChar(plr)
            local root = App.GetRoot(char)
            local hum = App.GetHum(char)
            if not char or not root or not hum or hum.Health <= 0 then
                return false
            end
            if char:FindFirstChildOfClass("ForceField") then
                return false
            end

            local hs = hum:GetState()
            if hs == Enum.HumanoidStateType.Dead then
                return false
            end

            local skipDown = skipDownOverride
            if skipDown == nil then
                skipDown = State.SilentAimSkipDown
            end
            if skipDown then
                if hs == Enum.HumanoidStateType.Physics or hs == Enum.HumanoidStateType.Ragdoll then
                    return false
                end
                if char:GetAttribute("Tased") == true or char:GetAttribute("isTased") == true
                    or char:GetAttribute("Downed") == true or char:GetAttribute("Arrested") == true then
                    return false
                end
            end

            local myTeam = lplr and lplr.Team
            local myTeamName = myTeam and myTeam.Name or ""
            local tTeam = plr.Team
            local tTeamName = tTeam and tTeam.Name or ""

            if tTeamName == "Neutral" then
                return false
            end
            local doTeamCheck = teamCheckOverride
            if doTeamCheck == nil then
                doTeamCheck = (State.SilentAimTeamCheck ~= false)
            end
            if doTeamCheck and myTeam and tTeam == myTeam then
                return false
            end
            -- Prison Life server prevents Criminals from damaging non-Hostile Inmates regardless of client toggle.
            if tTeamName == "Inmates" then
                local isHostile = char:GetAttribute("Hostile") == true
                if myTeamName == "Criminals" and not isHostile then
                    return false
                end
                if requireHostileInmate == true and not isHostile then
                    return false
                end
            end

            return true
        end

        local function hasTargetArmor(char)
            if not char then
                return false
            end
            if char:FindFirstChild("RiotShieldPart")
                or char:FindFirstChild("Armor")
                or char:FindFirstChild("Vest")
                or char:FindFirstChild("BulletproofVest")
            then
                return true
            end
            if (tonumber(char:GetAttribute("Armor")) or 0) > 0 or (tonumber(char:GetAttribute("VestHealth")) or 0) > 0 then
                return true
            end
            return false
        end

        function Targets.PickAimPart(char, modeOrForceHead)
            if not char then
                return nil
            end
            local wantHead = false
            local forceFalse = (modeOrForceHead == false)
            local explicitName = nil

            if type(modeOrForceHead) == "boolean" then
                wantHead = modeOrForceHead
            elseif type(modeOrForceHead) == "table" then
                if modeOrForceHead.forceHead then
                    wantHead = true
                elseif type(modeOrForceHead.mode) == "string" then
                    modeOrForceHead = modeOrForceHead.mode
                end
            end

            local mode = type(modeOrForceHead) == "string" and modeOrForceHead or State.SilentAimTargetPart
            if not wantHead and not forceFalse then
                if mode == "Head" then
                    wantHead = true
                elseif mode == "Random" then
                    local chance = tonumber(State.SilentAimHeadChance) or 70
                    wantHead = math.random(1, 100) <= chance
                elseif mode ~= "Torso" and mode ~= nil then
                    explicitName = mode
                end
                if not wantHead and not explicitName and State.AutoArmorPen and hasTargetArmor(char) then
                    wantHead = true
                end
            end

            if explicitName then
                local custom = char:FindFirstChild(explicitName)
                if custom and custom:IsA("BasePart") then
                    return custom
                end
            end

            if wantHead then
                local p = char:FindFirstChild("Head")
                    or char:FindFirstChild("UpperTorso")
                    or char:FindFirstChild("Torso")
                    or char:FindFirstChild("HumanoidRootPart")
                return (p and p:IsA("BasePart")) and p or nil
            end

            local body = char:FindFirstChild("Torso")
                or char:FindFirstChild("UpperTorso")
                or char:FindFirstChild("HumanoidRootPart")
                or char:FindFirstChild("Head")
            return (body and body:IsA("BasePart")) and body or nil
        end

        function Targets.BuildIgnoreList(extraChar)
            local list = {}
            local seen = {}
            local function addInst(inst)
                if inst and not seen[inst] then
                    seen[inst] = true
                    list[#list + 1] = inst
                end
            end

            local combat = App.Combat
            local hook = combat and combat.GunHook or nil
            if hook and type(hook.BaseIgnoreList) == "table" then
                for _, inst in ipairs(hook.BaseIgnoreList) do
                    addInst(inst)
                end
            end

            addInst(App.GetChar(App.LocalPlayer))
            addInst(extraChar)
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    addInst(p.Character)
                end
            end

            if State.OpenAllDoors then
                addInst(Workspace:FindFirstChild("Doors"))
            end
            if State.VehicleWallbang or State.SilentAimWallbang then
                addInst(Workspace:FindFirstChild("CarContainer"))
            end
            addInst(Workspace:FindFirstChild("PLKX_VFX_Pool"))
            addInst(Workspace:FindFirstChild("PLKX_BulletShieldBox"))
            addInst(Workspace:FindFirstChild("PLKX_ShieldVisual"))
            addInst(Workspace:FindFirstChild("ShieldBoxPart"))
            addInst(Workspace:FindFirstChild("RayIgnore"))
            addInst(Workspace:FindFirstChild("Ignore"))

            return list
        end

        local function isPointInsideSolid(pos, ignoreList)
            if not Workspace.GetPartBoundsInRadius or not scannerOverlapParams then
                return false
            end
            scannerOverlapParams.FilterDescendantsInstances = ignoreList
            local ok, parts = pcall(Workspace.GetPartBoundsInRadius, Workspace, pos, 0.2, scannerOverlapParams)
            if not ok or type(parts) ~= "table" then
                return false
            end
            for _, part in ipairs(parts) do
                if part and part:IsA("BasePart") and part.CanCollide and part.GetClosestPointOnSurface then
                    local okSurf, surfPos = pcall(part.GetClosestPointOnSurface, part, pos)
                    if okSurf and typeof(surfPos) == "Vector3" and (surfPos - pos).Magnitude < 0.015 then
                        return true
                    end
                end
            end
            return false
        end

        local function isSegmentClear(a, b, rayParams)
            local delta = b - a
            if delta.Magnitude < 0.05 then
                return true
            end
            if Workspace:Raycast(a, delta, rayParams) then
                return false
            end
            if Workspace:Raycast(b, -delta, rayParams) then
                return false
            end
            return true
        end

        function Targets.HasLineOfSight(originPos, targetPart, targetChar)
            if typeof(originPos) ~= "Vector3" or not targetPart then
                return false
            end
            scannerRayParams.FilterDescendantsInstances = Targets.BuildIgnoreList(targetChar or targetPart.Parent)
            return isSegmentClear(originPos, targetPart.Position, scannerRayParams)
        end

        local ORIGIN_RING_DIRS = {
            Vector3.new(1, 0, 0),
            Vector3.new(-1, 0, 0),
            Vector3.new(0, 0, 1),
            Vector3.new(0, 0, -1),
            Vector3.new(0, 1, 0),
            Vector3.new(0, -0.65, 0),
            Vector3.new(0.7, 0.7, 0),
            Vector3.new(-0.7, 0.7, 0),
            Vector3.new(0, 0.7, 0.7),
            Vector3.new(0, 0.7, -0.7),
        }

        function Targets.FindWallbangOrigin(basePos, targetPos, targetChar, useWallbang)
            if typeof(basePos) ~= "Vector3" or typeof(targetPos) ~= "Vector3" then
                return nil, nil
            end
            local ignoreList = Targets.BuildIgnoreList(targetChar)
            scannerRayParams.FilterDescendantsInstances = ignoreList

            if isSegmentClear(basePos, targetPos, scannerRayParams) then
                return basePos, targetPos
            end
            if not useWallbang then
                return nil, nil
            end

            local radii = { 3.2, 6.8 }
            for _, r in ipairs(radii) do
                for _, dir in ipairs(ORIGIN_RING_DIRS) do
                    local candOrigin = basePos + dir * r
                    if not isPointInsideSolid(candOrigin, ignoreList) then
                        if isSegmentClear(candOrigin, targetPos, scannerRayParams) then
                            return candOrigin, targetPos
                        end
                    end
                end
            end

            -- NormalId edge peek around target surface for thin cover corners
            for _, normId in ipairs(Enum.NormalId:GetEnumItems()) do
                local nVec = Vector3.FromNormalId(normId)
                local candTarget = targetPos + nVec * 1.35
                local candOrigin = basePos + nVec * 5.8
                if not isPointInsideSolid(candOrigin, ignoreList) then
                    if isSegmentClear(candOrigin, candTarget, scannerRayParams) then
                        return candOrigin, candTarget
                    end
                end
            end

            return nil, nil
        end

        local function getEquippedWeaponRange()
            if State.GunInfiniteRange then
                return 9999
            end
            local combat = App.Combat
            local hook = combat and combat.GunHook or nil
            if hook and type(hook.GunData) == "table" and tonumber(hook.GunData.Range) then
                return tonumber(hook.GunData.Range)
            end
            local char = App.GetChar(App.LocalPlayer)
            local eq = char and char:FindFirstChildOfClass("Tool") or nil
            local attrRange = eq and eq:GetAttribute("Range") or nil
            if tonumber(attrRange) then
                return tonumber(attrRange)
            end
            return 1400
        end

        function Targets.GetBestTarget(opts)
            opts = type(opts) == "table" and opts or {}
            local cam = App.GetCamera()
            local myRoot = App.GetRoot(App.GetChar(App.LocalPlayer))
            if not myRoot then
                return nil
            end

            local baseOrigin = typeof(opts.origin) == "Vector3" and opts.origin or (myRoot.Position + Vector3.new(0, 1.5, 0))
            local maxRange = tonumber(opts.range) or getEquippedWeaponRange()
            local use360 = opts.use360 == true
            local fovLimit = tonumber(opts.fov) or tonumber(State.SilentAimFOV) or 180
            local wallcheck = opts.wallcheck
            if wallcheck == nil then
                wallcheck = State.SilentAimWallcheck
            end
            local wallbang = opts.wallbang
            if wallbang == nil then
                wallbang = State.SilentAimWallbang
            end
            local reqHostile = opts.requireHostile
            if reqHostile == nil then
                reqHostile = State.SilentAimHostileCheck
            end
            local forceHead = opts.forceHead
            local aimMode = opts.targetPart
            local cursorPos = Targets.GetCursorOrCenterPos()

            local candidates = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if Targets.IsValidCombatTarget(plr, reqHostile, opts.whitelistMap, opts.skipDown, opts.teamCheck) then
                    local char = App.GetChar(plr)
                    local part = Targets.PickAimPart(char, forceHead and true or aimMode)
                    if part then
                        local worldDist = (part.Position - baseOrigin).Magnitude
                        if worldDist <= maxRange then
                            local score = worldDist
                            local okScreen = true
                            if not use360 and cam then
                                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                                if not onScreen or sp.Z <= 0 then
                                    okScreen = false
                                else
                                    score = (cursorPos - Vector2.new(sp.X, sp.Y)).Magnitude
                                    if score > fovLimit then
                                        okScreen = false
                                    end
                                end
                            end
                            if okScreen then
                                candidates[#candidates + 1] = {
                                    player = plr,
                                    char = char,
                                    part = part,
                                    score = score,
                                    dist = worldDist,
                                }
                            end
                        end
                    end
                end
            end

            if #candidates == 0 then
                return nil
            end
            table.sort(candidates, function(a, b)
                return a.score < b.score
            end)

            for _, cand in ipairs(candidates) do
                if not wallcheck then
                    return {
                        player = cand.player,
                        part = cand.part,
                        origin = baseOrigin,
                        hitPos = cand.part.Position,
                        distance = cand.dist,
                    }
                end
                local clearOrigin, clearHit = Targets.FindWallbangOrigin(baseOrigin, cand.part.Position, cand.char, wallbang)
                if clearOrigin then
                    return {
                        player = cand.player,
                        part = cand.part,
                        origin = clearOrigin,
                        hitPos = clearHit or cand.part.Position,
                        distance = cand.dist,
                    }
                end
            end

            return nil
        end

        local function matchByTier(token, atUser)
            local lq = string.lower(token)
            local tiers = { {}, {}, {}, {}, {}, {} }
            for _, p in ipairs(Players:GetPlayers()) do
                local nl = string.lower(p.Name)
                local dl = string.lower(p.DisplayName or p.Name)
                if nl == lq then
                    tiers[1][#tiers[1] + 1] = p
                elseif not atUser and dl == lq then
                    tiers[2][#tiers[2] + 1] = p
                elseif string.sub(nl, 1, #lq) == lq then
                    tiers[3][#tiers[3] + 1] = p
                elseif string.sub(dl, 1, #lq) == lq then
                    tiers[4][#tiers[4] + 1] = p
                elseif string.find(nl, lq, 1, true) then
                    tiers[5][#tiers[5] + 1] = p
                elseif string.find(dl, lq, 1, true) then
                    tiers[6][#tiers[6] + 1] = p
                end
            end
            for _, bucket in ipairs(tiers) do
                if #bucket > 0 then
                    table.sort(bucket, function(a, b)
                        return #a.Name < #b.Name
                    end)
                    return bucket
                end
            end
            return {}
        end

        local TEAM_TOKEN_MAP = {
            guards = "Guards", guard = "Guards", cops = "Guards", cop = "Guards", police = "Guards",
            inmates = "Inmates", inmate = "Inmates", prisoners = "Inmates", prisoner = "Inmates",
            criminals = "Criminals", criminal = "Criminals", crims = "Criminals", crim = "Criminals",
            neutral = "Neutral", neutrals = "Neutral",
        }

        local function resolveSingleToken(rawTok)
            local tok = App.Trim(rawTok)
            if tok == "" then
                return {}
            end
            local low = string.lower(tok)
            local lplr = App.LocalPlayer

            if low == "me" or low == "self" then
                return lplr and { lplr } or {}
            elseif low == "all" then
                return Players:GetPlayers()
            elseif low == "others" then
                local res = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lplr then
                        res[#res + 1] = p
                    end
                end
                return res
            elseif low == "random" then
                local pool = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lplr then
                        pool[#pool + 1] = p
                    end
                end
                if #pool > 0 then
                    return { pool[math.random(1, #pool)] }
                end
                return lplr and { lplr } or {}
            elseif low == "nearest" or low == "closest" then
                local myRoot = App.GetRoot(App.GetChar(lplr))
                if not myRoot then
                    return {}
                end
                local bestP, bestDist = nil, math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lplr then
                        local r = App.GetRoot(App.GetChar(p))
                        if r then
                            local d = (r.Position - myRoot.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestP = p
                            end
                        end
                    end
                end
                return bestP and { bestP } or {}
            elseif TEAM_TOKEN_MAP[low] then
                local wantTeam = TEAM_TOKEN_MAP[low]
                local res = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Team and p.Team.Name == wantTeam then
                        res[#res + 1] = p
                    end
                end
                return res
            elseif string.sub(low, 1, 1) == "@" then
                local bare = string.sub(tok, 2)
                if bare == "" then
                    return {}
                end
                return matchByTier(bare, true)
            end

            return matchByTier(tok, false)
        end

        function Targets.Resolve(query)
            if type(query) ~= "string" then
                return {}
            end
            local trimmed = App.Trim(query)
            if trimmed == "" then
                return {}
            end

            local out, seen = {}, {}
            for part in string.gmatch(trimmed, "[^,]+") do
                local matched = resolveSingleToken(part)
                for _, plr in ipairs(matched) do
                    if plr and not seen[plr] then
                        seen[plr] = true
                        out[#out + 1] = plr
                    end
                end
            end
            return out
        end

        function Targets.FuzzyKillfeedPlayer(rawName)
            if type(rawName) ~= "string" then
                return nil
            end
            local cleaned = rawName:gsub("<[^>]+>", "")
            cleaned = cleaned:gsub("^%[[^%]]+%]%s*", "")
            cleaned = App.Trim(cleaned)
            if cleaned == "" then
                return nil
            end
            local parenUser = string.match(cleaned, "%(@([^%)]+)%)")
            if parenUser and parenUser ~= "" then
                local pRes = matchByTier(App.Trim(parenUser), true)
                if pRes[1] then
                    return pRes[1]
                end
            end
            if string.sub(cleaned, 1, 1) == "@" then
                local atRes = matchByTier(string.sub(cleaned, 2), true)
                return atRes[1]
            end
            local res = matchByTier(cleaned, false)
            return res[1]
        end

        App.Targets = Targets
    end

    initTargets()
end

--------------------------------------------------------------------------------
-- 3. APP.VFX
--------------------------------------------------------------------------------
do
    local TRACER_POOL_SIZE = 48
    local DMG_POOL_SIZE = 16
    local SFX_SLOTS = 3
    local PARK_CF = CFrame.new(0, -9000, 0)

    local SOUND_CONFIG = {
        HitBody = { id = "rbxassetid://4817809188", fallback = "rbxasset://sounds/Snap.wav", vol = 0.65, pitch = 1.0 },
        HitHead = { id = "rbxassetid://4817809188", fallback = "rbxasset://sounds/electronicpingshort.wav", vol = 0.8, pitch = 1.3 },
        Kill = { id = "rbxassetid://160432334", fallback = "rbxasset://sounds/electronicpingshort.wav", vol = 0.85, pitch = 1.45 },
        Ricochet = { id = "rbxassetid://2935002319", fallback = "rbxasset://sounds/collide.wav", vol = 0.6, pitch = 1.0 },
    }

    local function initVFX()
        local Workspace = Services.Workspace
        local SoundService = Services.SoundService
        local ContentProvider = Services.ContentProvider

        local VFX = {}
        local vfxPoolFolder = nil
        local sfxFolder = nil
        local tracerRing = {}
        local tracerIdx = 0
        local dmgRing = {}
        local dmgIdx = 0
        local activeDmgByPlayer = {}
        local sparkPart = nil
        local sparkAtt = nil
        local sparkEmitter = nil
        local sparkLight = nil
        local sfxBanks = {}
        local sfxPreloaded = false
        local lastHitSfxClock = 0
        local lastRicochetClock = 0
        local tracerHooks = { createBullet = nil, createTaser = nil, createSniper = nil, mod = nil, active = false }

        local function createTracerPart(parent)
            local p = Instance.new("Part")
            p.Name = "PLKX_Tracer"
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = Enum.Material.Neon
            p.Transparency = 1
            p.Size = Vector3.new(0.05, 0.05, 0.05)
            p.CFrame = PARK_CF
            p.Parent = parent
            return p
        end

        local function createDmgSlot(parent)
            local part = Instance.new("Part")
            part.Name = "PLKX_DmgAnchor"
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.Transparency = 1
            part.Size = Vector3.new(0.2, 0.2, 0.2)
            part.CFrame = PARK_CF
            part.Parent = parent

            local bb = Instance.new("BillboardGui")
            bb.Name = "PLKX_DmgBB"
            bb.Adornee = part
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 84, 0, 32)
            bb.StudsOffsetWorldSpace = Vector3.new(0, 0.6, 0)
            bb.Enabled = false
            bb.Parent = part

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextScaled = false
            lbl.TextSize = 18
            lbl.TextColor3 = Palette.TextPrimary
            lbl.TextStrokeTransparency = 0.2
            lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            lbl.Text = ""
            lbl.Parent = bb

            return { part = part, bb = bb, label = lbl, bornAt = 0, totalDmg = 0, player = nil, token = 0 }
        end

        local function ensureSoundBank(poolSfx)
            if sfxBanks.HitBody then
                return
            end
            local allSounds = {}
            for key, cfg in pairs(SOUND_CONFIG) do
                local bank = { idx = 0, slots = {}, cfg = cfg }
                for i = 1, SFX_SLOTS do
                    local snd = Instance.new("Sound")
                    snd.Name = "PLKX_" .. key .. "_" .. tostring(i)
                    snd.SoundId = cfg.id
                    snd.Volume = cfg.vol
                    snd.PlaybackSpeed = cfg.pitch
                    snd.PlayOnRemove = false
                    snd.Parent = poolSfx
                    bank.slots[i] = snd
                    allSounds[#allSounds + 1] = snd
                end
                sfxBanks[key] = bank
            end

            if not sfxPreloaded then
                sfxPreloaded = true
                task.spawn(function()
                    pcall(ContentProvider.PreloadAsync, ContentProvider, allSounds)
                    for _, bank in pairs(sfxBanks) do
                        for _, snd in ipairs(bank.slots) do
                            if not snd.IsLoaded and snd.TimeLength == 0 then
                                snd.SoundId = bank.cfg.fallback
                            end
                        end
                    end
                end)
            end
        end

        function VFX.EnsurePool()
            if vfxPoolFolder and vfxPoolFolder.Parent then
                return vfxPoolFolder
            end

            local existing = Workspace:FindFirstChild("PLKX_VFX_Pool")
            if existing then
                pcall(existing.Destroy, existing)
            end
            local folder = Instance.new("Folder")
            folder.Name = "PLKX_VFX_Pool"
            folder.Parent = Workspace
            Janitor.Track(folder)
            vfxPoolFolder = folder

            local existingSfx = SoundService:FindFirstChild("PLKX_SFX")
            if existingSfx then
                pcall(existingSfx.Destroy, existingSfx)
            end
            local sFolder = Instance.new("Folder")
            sFolder.Name = "PLKX_SFX"
            sFolder.Parent = SoundService
            Janitor.Track(sFolder)
            sfxFolder = sFolder

            tracerRing = {}
            for i = 1, TRACER_POOL_SIZE do
                tracerRing[i] = createTracerPart(folder)
            end
            tracerIdx = 0

            dmgRing = {}
            for i = 1, DMG_POOL_SIZE do
                dmgRing[i] = createDmgSlot(folder)
            end
            dmgIdx = 0
            activeDmgByPlayer = {}

            sparkPart = Instance.new("Part")
            sparkPart.Name = "PLKX_ShieldSparkHost"
            sparkPart.Anchored = true
            sparkPart.CanCollide = false
            sparkPart.CanTouch = false
            sparkPart.CanQuery = false
            sparkPart.CastShadow = false
            sparkPart.Material = Enum.Material.Neon
            sparkPart.Color = Palette.NeonCyan
            sparkPart.Size = Vector3.new(0.45, 0.45, 0.12)
            sparkPart.Transparency = 1
            sparkPart.CFrame = PARK_CF
            sparkPart.Parent = folder

            sparkAtt = Instance.new("Attachment")
            sparkAtt.Parent = sparkPart

            sparkEmitter = Instance.new("ParticleEmitter")
            sparkEmitter.Enabled = false
            sparkEmitter.Speed = NumberRange.new(8, 18)
            sparkEmitter.Lifetime = NumberRange.new(0.12, 0.24)
            sparkEmitter.SpreadAngle = Vector2.new(65, 65)
            sparkEmitter.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.25),
                NumberSequenceKeypoint.new(1, 0),
            })
            sparkEmitter.Color = ColorSequence.new(Palette.NeonCyan, Palette.NeonBlue)
            sparkEmitter.LightEmission = 1
            sparkEmitter.Parent = sparkAtt

            sparkLight = Instance.new("PointLight")
            sparkLight.Enabled = false
            sparkLight.Color = Palette.NeonCyan
            sparkLight.Range = 7
            sparkLight.Brightness = 2.5
            sparkLight.Parent = sparkPart

            ensureSoundBank(sFolder)
            return folder
        end

        function VFX.IsHooked()
            return tracerHooks.active == true
        end

        function VFX.SpawnTracer(origin, hitPos, color)
            if typeof(origin) ~= "Vector3" or typeof(hitPos) ~= "Vector3" then
                return
            end
            local pool = VFX.EnsurePool()
            local dist = (hitPos - origin).Magnitude
            if dist < 0.2 or dist > 10000 then
                return
            end

            tracerIdx = (tracerIdx % TRACER_POOL_SIZE) + 1
            local part = tracerRing[tracerIdx]
            if not part or not part.Parent then
                part = createTracerPart(pool)
                tracerRing[tracerIdx] = part
            end

            App.Anim.Cancel(part, "Tracer")
            part.Color = typeof(color) == "Color3" and color or Palette.NeonCyan
            part.Transparency = 0.12
            part.Size = Vector3.new(0.1, 0.1, dist)
            part.CFrame = CFrame.lookAt(origin, hitPos) * CFrame.new(0, 0, -dist * 0.5)

            local fadeSec = math.max(0.08, math.min(0.8, tonumber(State.BulletTracerFade) or 0.24))
            local fadeInfo = TweenInfo.new(fadeSec, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            App.Anim.Play(part, "Tracer", fadeInfo, {
                Transparency = 1,
                Size = Vector3.new(0.015, 0.015, dist),
            }, function()
                if part and part.Parent then
                    part.Transparency = 1
                    part.Size = Vector3.new(0.05, 0.05, 0.05)
                    part.CFrame = PARK_CF
                end
            end)
        end

        function VFX.TriggerHitmarker(isHeadshot, isKill, damage, worldPos, targetPlayer)
            if not State.Hitmarker then
                return
            end
            Bus.Emit("HitConfirm", isHeadshot == true, isKill == true, damage, worldPos, targetPlayer)
        end

        local function playSfxFromBank(key, pitchScale)
            VFX.EnsurePool()
            local bank = sfxBanks[key]
            if not bank then
                return
            end
            bank.idx = (bank.idx % SFX_SLOTS) + 1
            local snd = bank.slots[bank.idx]
            if snd and snd.Parent then
                if not snd.IsLoaded and snd.TimeLength == 0 then
                    snd.SoundId = bank.cfg.fallback
                end
                local jitter = math.random(94, 108) / 100
                snd.PlaybackSpeed = bank.cfg.pitch * (pitchScale or 1) * jitter
                snd:Play()
            end
        end

        function VFX.PlayHitSound(isHeadshot)
            if not State.HitSound then
                return
            end
            local now = os.clock()
            if (now - lastHitSfxClock) < 0.045 then
                return
            end
            lastHitSfxClock = now
            playSfxFromBank(isHeadshot and "HitHead" or "HitBody", 1)
        end

        function VFX.PlayKillSound(streak)
            if not State.KillSound then
                return
            end
            local s = math.max(1, tonumber(streak) or 1)
            local streakPitch = math.min(1.3, 1 + (s - 1) * 0.04)
            playSfxFromBank("Kill", streakPitch)
        end

        function VFX.SpawnDamageNumber(worldPos, dmg, isHeadshot, targetPlayer)
            if not State.DamageNumbers or typeof(worldPos) ~= "Vector3" then
                return
            end
            local amt = math.floor((tonumber(dmg) or 0) + 0.5)
            if amt <= 0 then
                return
            end
            local pool = VFX.EnsurePool()
            local now = os.clock()

            local entry = targetPlayer and activeDmgByPlayer[targetPlayer] or nil
            if entry and entry.part and entry.part.Parent and (now - entry.bornAt) < 0.45 then
                entry.totalDmg = entry.totalDmg + amt
            else
                dmgIdx = (dmgIdx % DMG_POOL_SIZE) + 1
                entry = dmgRing[dmgIdx]
                if not entry or not entry.part or not entry.part.Parent then
                    entry = createDmgSlot(pool)
                    dmgRing[dmgIdx] = entry
                end
                if entry.player and activeDmgByPlayer[entry.player] == entry then
                    activeDmgByPlayer[entry.player] = nil
                end
                entry.totalDmg = amt
                entry.player = targetPlayer
                if targetPlayer then
                    activeDmgByPlayer[targetPlayer] = entry
                end
            end

            entry.bornAt = now
            entry.token = entry.token + 1
            local myToken = entry.token

            local jx = (math.random(-35, 35)) / 100
            entry.part.CFrame = CFrame.new(worldPos + Vector3.new(jx, 0.35, 0))
            entry.bb.Enabled = true
            entry.bb.StudsOffsetWorldSpace = Vector3.new(0, 0.4, 0)
            entry.label.Text = (isHeadshot and "*" or "") .. "-" .. tostring(entry.totalDmg)
            entry.label.TextColor3 = isHeadshot and Palette.StreakGold or Palette.TextPrimary
            entry.label.TextSize = isHeadshot and 21 or 18
            entry.label.TextTransparency = 0
            entry.label.TextStrokeTransparency = 0.2

            App.Anim.Cancel(entry.bb, "DmgRise")
            App.Anim.Cancel(entry.label, "DmgFade")

            local riseInfo = TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            App.Anim.Play(entry.bb, "DmgRise", riseInfo, { StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0) })
            local fadeInfo = TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            App.Anim.Play(entry.label, "DmgFade", fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }, function()
                if entry.token == myToken then
                    entry.bb.Enabled = false
                    entry.part.CFrame = PARK_CF
                    if entry.player and activeDmgByPlayer[entry.player] == entry then
                        activeDmgByPlayer[entry.player] = nil
                    end
                    entry.player = nil
                end
            end)
        end

        function VFX.SpawnShieldBlockEffect(hitPos, normal)
            if not State.ShieldHitVFX or typeof(hitPos) ~= "Vector3" then
                return
            end
            VFX.EnsurePool()
            local n = (typeof(normal) == "Vector3" and normal.Magnitude > 0.01) and normal.Unit or Vector3.new(0, 1, 0)

            if sparkPart and sparkPart.Parent then
                App.Anim.Cancel(sparkPart, "ShieldFlash")
                sparkPart.CFrame = CFrame.lookAt(hitPos, hitPos + n)
                sparkPart.Transparency = 0.25
                sparkLight.Enabled = true
                if sparkEmitter then
                    pcall(sparkEmitter.Emit, sparkEmitter, 10)
                end
                App.Anim.Play(sparkPart, "ShieldFlash", TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Transparency = 1,
                }, function()
                    if sparkLight then
                        sparkLight.Enabled = false
                    end
                    if sparkPart and sparkPart.Parent then
                        sparkPart.CFrame = PARK_CF
                    end
                end)
            end

            local now = os.clock()
            if (now - lastRicochetClock) >= 0.045 then
                lastRicochetClock = now
                playSfxFromBank("Ricochet", 1)
            end
        end

        local function resolveLocalMuzzlePos(fallbackOrigin)
            local char = App.GetChar(App.LocalPlayer)
            local tool = char and char:FindFirstChildOfClass("Tool") or nil
            if tool then
                local muzzle = tool:FindFirstChild("Muzzle", true) or tool:FindFirstChild("Handle")
                if muzzle and muzzle:IsA("BasePart") then
                    return muzzle.Position
                end
            end
            return fallbackOrigin
        end

        local function handleTracerCall(origFn, isLocalCaller, origin, hitPos, ...)
            if not isLocalCaller then
                if typeof(origin) == "Vector3" and typeof(hitPos) == "Vector3" then
                    if App.Shield and type(App.Shield.TryInterceptIncomingRay) == "function" then
                        pcall(App.Shield.TryInterceptIncomingRay, origin, hitPos)
                    end
                end
                if type(origFn) == "function" then
                    return origFn(origin, hitPos, ...)
                end
                return nil
            end

            if State.BulletTracers and typeof(origin) == "Vector3" and typeof(hitPos) == "Vector3" then
                local startPos = resolveLocalMuzzlePos(origin)
                local col = (App.Combat and App.Combat.GunHook and App.Combat.GunHook.LastShotWasRage)
                    and Palette.RageCrimson or Palette.NeonCyan
                VFX.SpawnTracer(startPos, hitPos, col)
                return nil
            end

            if type(origFn) == "function" then
                return origFn(origin, hitPos, ...)
            end
            return nil
        end

        local function isCallerLocal()
            local infoFn = debug and rawget(debug, "info") or nil
            if App.Has.DebugInfo and type(infoFn) == "function" then
                for lvl = 3, 6 do
                    local ok, src = pcall(infoFn, lvl, "s")
                    if ok and type(src) == "string" and string.find(src, "ClientReplicator", 1, true) then
                        return false
                    end
                end
                return true
            end
            local getInfoFn = debug and rawget(debug, "getinfo") or nil
            if type(getInfoFn) == "function" then
                for lvl = 3, 6 do
                    local ok, info = pcall(getInfoFn, lvl, "S")
                    local src = ok and type(info) == "table" and info.source or nil
                    if type(src) == "string" and string.find(src, "ClientReplicator", 1, true) then
                        return false
                    end
                end
            end
            return true
        end

        local function wrapTracerSlot(key)
            local gt = tracerHooks.mod
            local origFn = gt and gt[key] or nil
            if type(origFn) ~= "function" then
                return false
            end
            local hookedOrig
            local wrapper = function(origin, hitPos, ...)
                local localCaller = isCallerLocal()
                return handleTracerCall(hookedOrig or origFn, localCaller, origin, hitPos, ...)
            end
            hookedOrig = App.HookFn(origFn, wrapper)
            if hookedOrig then
                tracerHooks[key] = hookedOrig
                tracerHooks[key .. "_mode"] = "hookfn"
            else
                tracerHooks[key] = origFn
                tracerHooks[key .. "_mode"] = "table"
                gt[key] = wrapper
            end
            return true
        end

        function VFX.HookGunTracers()
            if tracerHooks.active then
                return true
            end
            local gt = App.Remotes and App.Remotes.GunTracers or nil
            if type(gt) ~= "table" then
                if App.Remotes and App.Remotes.Refresh then
                    App.Remotes.Refresh()
                    gt = App.Remotes.GunTracers
                end
            end
            if type(gt) ~= "table" then
                return false
            end

            tracerHooks.mod = gt
            local okB = wrapTracerSlot("createBullet")
            wrapTracerSlot("createTaser")
            wrapTracerSlot("createSniper")

            tracerHooks.active = okB or (tracerHooks.createTaser ~= nil) or (tracerHooks.createSniper ~= nil)
            return tracerHooks.active
        end

        function VFX.RestoreGunTracers()
            local gt = tracerHooks.mod
            if type(gt) == "table" then
                for _, key in ipairs({ "createBullet", "createTaser", "createSniper" }) do
                    local origFn = tracerHooks[key]
                    if origFn then
                        if tracerHooks[key .. "_mode"] == "table" then
                            gt[key] = origFn
                        elseif type(gt[key]) == "function" then
                            App.RestoreFn(gt[key], origFn)
                        end
                    end
                    tracerHooks[key] = nil
                    tracerHooks[key .. "_mode"] = nil
                end
            end
            tracerHooks.active = false
            return true
        end

        Janitor.AddCleanup(VFX.RestoreGunTracers)
        VFX.EnsurePool()
        VFX.HookGunTracers()
        App.VFX = VFX
    end

    initVFX()
end

--------------------------------------------------------------------------------
-- 4. APP.TOOLARBITER
--------------------------------------------------------------------------------
do
    local function initToolArbiter()
        local arbiter = {
            Priority = {
                Combo1 = 4,
                Rage = 3,
                AutoDetonate = 2,
                AutoTaze = 2,
                AutoArrest = 2,
                AutoHeal = 1,
                IdleShield = 1,
            },
        }

        local lock = {
            priority = 0,
            reason = "",
            expiresAt = 0,
            tool = nil,
        }

        function arbiter.Release(reason)
            if reason == nil or lock.reason == reason then
                lock.priority = 0
                lock.reason = ""
                lock.expiresAt = 0
                lock.tool = nil
            end
        end

        function arbiter.GetLock()
            return lock
        end

        function arbiter.TryEquip(tool, priority, reason, dwellSec)
            local now = os.clock()
            local prio = tonumber(priority) or 1
            local dwell = tonumber(dwellSec) or 0.18
            local why = tostring(reason or "")

            local char = App.GetChar(App.LocalPlayer)
            local hum = App.GetHum(char)
            if not char or not hum or hum.Health <= 0 then
                return false
            end

            -- Respect active higher-priority dwell lock; also block equal-priority cross-reason churn.
            if now < lock.expiresAt then
                local lockToolValid = lock.tool and lock.tool.Parent ~= nil
                if prio < lock.priority and lockToolValid then
                    return false
                end
                if prio == lock.priority and lock.reason ~= why and lockToolValid then
                    return false
                end
            end

            if not tool or typeof(tool) ~= "Instance" or not tool:IsA("Tool") or not tool.Parent then
                return false
            end

            if tool.Parent ~= char then
                local ok = pcall(hum.EquipTool, hum, tool)
                if not ok then
                    pcall(function()
                        tool.Parent = char
                    end)
                end
            end

            lock.priority = prio
            lock.reason = why
            lock.expiresAt = now + math.max(0.02, dwell)
            lock.tool = tool
            return tool.Parent == char
        end

        App.ToolArbiter = arbiter
    end

    initToolArbiter()
end

--------------------------------------------------------------------------------
-- 5. APP.COMBAT
--------------------------------------------------------------------------------
do
    local NIL_SENTINEL = {}
    local unpackFn = table.unpack or unpack

    local function packArgs(...)
        return { n = select("#", ...), ... }
    end

    local function initCombat()
        local Players = Services.Players
        local Workspace = Services.Workspace
        local RunService = Services.RunService

        local Combat = {}
        local origAttrs = setmetatable({}, { __mode = "k" })
        local origGunData = setmetatable({}, { __mode = "k" })
        local dmgWatchers = setmetatable({}, { __mode = "k" })

        local GunHook = {
            Ready = false,
            IsBulletHooked = false,
            IsEquipHooked = false,
            IsPlaySoundHooked = false,
            IsNamecallHooked = false,
            Shoot = nil,
            Reload = nil,
            Bullet = nil,
            Equip = nil,
            OldBullet = nil,
            OldEquip = nil,
            OldPlaySound = nil,
            OldNamecall = nil,
            CastRayParams = nil,
            BaseIgnoreList = nil,
            PlaySound = nil,
            GunData = nil,
            Tool = nil,
            CanBeDamaged = nil,
            CurrentTargetPart = nil,
            LastRageShotClock = 0,
            LastComboShotClock = 0,
            LastTaseShotClock = 0,
            LastShotWasRage = false,
            ForceRageShot = false,
            RageTargetPart = nil,
            TaseTargetPart = nil,
            FrameCache = { valid = false, time = 0, mode = "", tool = nil, hitPassed = false, target = nil },
            _shotToken = 0,
        }
        Combat.GunHook = GunHook

        function Combat.ClearFrameCache()
            local fc = GunHook.FrameCache
            fc.valid = false
            fc.target = nil
            fc.tool = nil
            fc.mode = ""
            fc.time = 0
            fc.hitPassed = false
        end

        function Combat.IsFirearmTool(tool, includeTaser)
            if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
                return false
            end
            local isTaser = (tool.Name == "Taser")
                or (tool:GetAttribute("Behavior") == "Taser")
                or (tool:GetAttribute("Projectile") == "Taser")
            if isTaser and not includeTaser then
                return false
            end
            return tool:GetAttribute("ToolType") == "Gun"
                or tool:GetAttribute("FireRate") ~= nil
                or tool:GetAttribute("MaxAmmo") ~= nil
                or tool:GetAttribute("CurrentAmmo") ~= nil
        end

        function Combat.GetToolAmmo(tool)
            if not tool then
                return nil
            end
            -- Read Local_CurrentAmmo before CurrentAmmo; never coerce nil to 1.
            local localAmmo = tool:GetAttribute("Local_CurrentAmmo")
            if localAmmo ~= nil then
                return tonumber(localAmmo)
            end
            local curAmmo = tool:GetAttribute("CurrentAmmo")
            if curAmmo ~= nil then
                return tonumber(curAmmo)
            end
            return nil
        end

        function Combat.IsToolReadyToFire(tool)
            if not Combat.IsFirearmTool(tool, true) then
                return false
            end
            local ammo = Combat.GetToolAmmo(tool)
            if ammo == nil or ammo <= 0 then
                return false
            end
            if tool:GetAttribute("Local_IsShooting") == true then
                return false
            end
            local relSess = tool:GetAttribute("Local_ReloadSession")
            if relSess == true or (type(relSess) == "number" and relSess > 0) then
                return false
            end
            if tool:GetAttribute("IsReloading") == true then
                return false
            end
            return true
        end

        function Combat.ForEachOwnedTool(fn)
            if type(fn) ~= "function" then
                return
            end
            local lplr = App.LocalPlayer
            local char = App.GetChar(lplr)
            if char then
                for _, item in ipairs(char:GetChildren()) do
                    if item:IsA("Tool") then
                        if fn(item) == false then
                            return
                        end
                    end
                end
            end
            local bp = lplr and (lplr:FindFirstChildOfClass("Backpack") or lplr:FindFirstChild("Backpack")) or nil
            if bp then
                for _, item in ipairs(bp:GetChildren()) do
                    if item:IsA("Tool") then
                        if fn(item) == false then
                            return
                        end
                    end
                end
            end
        end

        local MOD_KEYS = { "FireRate", "AutoFire", "SpreadRadius", "Range", "AccurateRange" }

        local function snapshotToolAttrs(tool)
            if origAttrs[tool] then
                return origAttrs[tool]
            end
            local snap = {}
            for _, k in ipairs(MOD_KEYS) do
                local v = tool:GetAttribute(k)
                snap[k] = (v ~= nil) and v or NIL_SENTINEL
            end
            origAttrs[tool] = snap
            return snap
        end

        local function restoreValOrNil(val)
            if val == NIL_SENTINEL then
                return nil
            end
            return val
        end

        local function applyModValuesToGunData(data)
            if type(data) ~= "table" then
                return
            end
            if not origGunData[data] then
                local snap = {}
                for _, k in ipairs(MOD_KEYS) do
                    local v = data[k]
                    snap[k] = (v ~= nil) and v or NIL_SENTINEL
                end
                origGunData[data] = snap
            end
            local snap = origGunData[data]
            if State.GunMods then
                data.FireRate = 1 / math.max(1, tonumber(State.GunFireRateSPS) or 22)
                data.AutoFire = State.GunAutoFire and true or restoreValOrNil(snap.AutoFire)
                data.SpreadRadius = State.GunNoSpread and 0 or restoreValOrNil(snap.SpreadRadius)
                data.Range = State.GunInfiniteRange and 9999 or restoreValOrNil(snap.Range)
                data.AccurateRange = State.GunInfiniteRange and 9999 or restoreValOrNil(snap.AccurateRange)
            else
                for _, k in ipairs(MOD_KEYS) do
                    data[k] = restoreValOrNil(snap[k])
                end
            end
        end

        function Combat.ApplyGunModsToTool(tool)
            if not Combat.IsFirearmTool(tool, false) then
                return
            end
            local snap = snapshotToolAttrs(tool)
            if State.GunMods then
                tool:SetAttribute("FireRate", 1 / math.max(1, tonumber(State.GunFireRateSPS) or 22))
                tool:SetAttribute("AutoFire", State.GunAutoFire and true or restoreValOrNil(snap.AutoFire))
                tool:SetAttribute("SpreadRadius", State.GunNoSpread and 0 or restoreValOrNil(snap.SpreadRadius))
                tool:SetAttribute("Range", State.GunInfiniteRange and 9999 or restoreValOrNil(snap.Range))
                tool:SetAttribute("AccurateRange", State.GunInfiniteRange and 9999 or restoreValOrNil(snap.AccurateRange))
            else
                for _, k in ipairs(MOD_KEYS) do
                    tool:SetAttribute(k, restoreValOrNil(snap[k]))
                end
            end
            local char = App.GetChar(App.LocalPlayer)
            if type(GunHook.GunData) == "table" and (GunHook.Tool == tool or (GunHook.Tool == nil and char and tool.Parent == char)) then
                applyModValuesToGunData(GunHook.GunData)
            end
        end

        function Combat.ApplyGunModsAll()
            Combat.ForEachOwnedTool(function(tool)
                Combat.ApplyGunModsToTool(tool)
            end)
            if type(GunHook.GunData) == "table" then
                applyModValuesToGunData(GunHook.GunData)
            end
        end

        function Combat.RestoreGunMods()
            for tool, snap in pairs(origAttrs) do
                if typeof(tool) == "Instance" and tool.Parent then
                    for _, k in ipairs(MOD_KEYS) do
                        pcall(tool.SetAttribute, tool, k, restoreValOrNil(snap[k]))
                    end
                end
            end
            for data, snap in pairs(origGunData) do
                if type(data) == "table" then
                    for _, k in ipairs(MOD_KEYS) do
                        data[k] = restoreValOrNil(snap[k])
                    end
                end
            end
            return true
        end

        function Combat.ApplyAntiRiotShield(enable)
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= App.LocalPlayer and plr.Character then
                    local shield = plr.Character:FindFirstChild("RiotShieldPart")
                    if shield and shield:IsA("BasePart") then
                        shield.CanQuery = not enable
                    end
                end
            end
        end

        function Combat.UpdateCastRayFilter()
            local rp = GunHook.CastRayParams
            if typeof(rp) == "RaycastParams" then
                if not GunHook.BaseIgnoreList then
                    GunHook.BaseIgnoreList = rp.FilterDescendantsInstances
                end
                local updated = {}
                local seen = {}
                local function addInst(inst)
                    if inst and not seen[inst] then
                        seen[inst] = true
                        updated[#updated + 1] = inst
                    end
                end
                if type(GunHook.BaseIgnoreList) == "table" then
                    for _, inst in ipairs(GunHook.BaseIgnoreList) do
                        if typeof(inst) == "Instance" and inst.Parent then
                            addInst(inst)
                        end
                    end
                end
                addInst(App.GetChar(App.LocalPlayer))
                if App.Shield and type(App.Shield.GetBarrierInstance) == "function" then
                    addInst(App.Shield.GetBarrierInstance())
                end
                if State.OpenAllDoors then
                    addInst(Workspace:FindFirstChild("Doors"))
                end
                if State.VehicleWallbang or State.SilentAimWallbang then
                    addInst(Workspace:FindFirstChild("CarContainer"))
                end
                if State.AntiRiotShield then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= App.LocalPlayer and p.Character then
                            local rsp = p.Character:FindFirstChild("RiotShieldPart")
                            if rsp then
                                addInst(rsp)
                            end
                        end
                    end
                end
                addInst(Workspace:FindFirstChild("PLKX_VFX_Pool"))
                addInst(Workspace:FindFirstChild("PLKX_BulletShieldBox"))
                addInst(Workspace:FindFirstChild("PLKX_ShieldVisual"))
                addInst(Workspace:FindFirstChild("ShieldBoxPart"))
                addInst(Workspace:FindFirstChild("KX_HoloShieldBarrier"))
                local cam = App.GetCamera()
                if cam then
                    addInst(cam:FindFirstChild("KX_HoloShieldBarrier"))
                end
                addInst(Workspace:FindFirstChild("RayIgnore"))
                addInst(Workspace:FindFirstChild("Ignore"))
                rp.FilterDescendantsInstances = updated
            end
        end

        local function registerHitDamageWatcher(hitPart, hitPos)
            if typeof(hitPart) ~= "Instance" then
                return
            end
            local model = hitPart:FindFirstAncestorOfClass("Model")
            local plr = model and Players:GetPlayerFromCharacter(model) or nil
            if not plr or plr == App.LocalPlayer then
                return
            end
            local hum = App.GetHum(model)
            if not hum or hum.Health <= 0 then
                return
            end

            local isHead = (hitPart.Name == "Head")
            App.VFX.TriggerHitmarker(isHead, false, nil, hitPos, plr)
            App.VFX.PlayHitSound(isHead)

            if not State.DamageNumbers and not State.Hitmarker then
                return
            end

            local w = dmgWatchers[hum]
            if not w then
                w = {
                    lastHP = hum.Health,
                    expireAt = os.clock() + 0.55,
                    hitPos = hitPos or hitPart.Position,
                    isHead = isHead,
                    plr = plr,
                    killedReported = false,
                }
                dmgWatchers[hum] = w
                w.conn = hum.HealthChanged:Connect(function(newHP)
                    if os.clock() > w.expireAt then
                        if w.conn then
                            w.conn:Disconnect()
                            w.conn = nil
                        end
                        dmgWatchers[hum] = nil
                        return
                    end
                    local delta = w.lastHP - newHP
                    if delta > 0.2 then
                        w.lastHP = newHP
                        App.VFX.SpawnDamageNumber(w.hitPos, delta, w.isHead, w.plr)
                        if newHP <= 0 and not w.killedReported then
                            w.killedReported = true
                            App.VFX.TriggerHitmarker(w.isHead, true, delta, w.hitPos, w.plr)
                        end
                    elseif newHP > w.lastHP then
                        w.lastHP = newHP
                    end
                end)
                Janitor.Add(w.conn)
            else
                w.expireAt = os.clock() + 0.55
                w.hitPos = hitPos or hitPart.Position
                w.isHead = isHead
            end
        end

        local function resolveActiveCombatTarget(baseOrigin)
            local char = App.GetChar(App.LocalPlayer)
            local eqTool = char and char:FindFirstChildOfClass("Tool") or nil
            local isTaser = eqTool and (eqTool.Name == "Taser" or eqTool:GetAttribute("Behavior") == "Taser")

            if isTaser and GunHook.TaseTargetPart and GunHook.TaseTargetPart.Parent then
                local o, h = App.Targets.FindWallbangOrigin(baseOrigin, GunHook.TaseTargetPart.Position, GunHook.TaseTargetPart.Parent, State.SilentAimWallbang)
                if o then
                    return { part = GunHook.TaseTargetPart, origin = o, hitPos = h or GunHook.TaseTargetPart.Position, player = Players:GetPlayerFromCharacter(GunHook.TaseTargetPart.Parent) }
                end
            end

            if GunHook.ForceRageShot and GunHook.RageTargetPart and GunHook.RageTargetPart.Parent then
                local o, h = App.Targets.FindWallbangOrigin(baseOrigin, GunHook.RageTargetPart.Position, GunHook.RageTargetPart.Parent, true)
                if o then
                    return { part = GunHook.RageTargetPart, origin = o, hitPos = h or GunHook.RageTargetPart.Position, player = Players:GetPlayerFromCharacter(GunHook.RageTargetPart.Parent) }
                end
            end

            local mode = State.Ragebot and "rage" or (State.SilentAim and "silent" or "")
            if mode == "" then
                return nil
            end

            local now = os.clock()
            local fc = GunHook.FrameCache
            if fc.valid and (now - fc.time) < 0.015 and fc.mode == mode and fc.tool == eqTool then
                if not fc.hitPassed then
                    return nil
                end
                if fc.target and fc.target.part and fc.target.part.Parent then
                    return fc.target
                end
            end

            local hitPassed = true
            if mode == "silent" then
                local chance = tonumber(State.SilentAimHitChance) or 100
                hitPassed = math.random(1, 100) <= chance
            end

            local found = nil
            if hitPassed then
                found = App.Targets.GetBestTarget({
                    origin = baseOrigin,
                    use360 = (mode == "rage") and State.Ragebot360 or false,
                    fov = State.SilentAimFOV,
                    wallcheck = (mode == "rage") and true or State.SilentAimWallcheck,
                    wallbang = (mode == "rage") and true or State.SilentAimWallbang,
                    requireHostile = State.SilentAimHostileCheck,
                    forceHead = (mode == "rage"),
                    targetPart = State.SilentAimTargetPart,
                })
            end

            fc.valid = true
            fc.time = now
            fc.mode = mode
            fc.tool = eqTool
            fc.hitPassed = hitPassed
            fc.target = found
            return found
        end

        local function syncCallerOriginStack(origStart, newOrigin)
            if origStart == newOrigin or not App.Has.DebugSetStack then
                return
            end
            local getStack = rawget(debug, "getstack")
            if type(getStack) ~= "function" then
                return
            end
            -- Search frames 4..9 (skipping 1=syncCallerOriginStack, 2=applySilentOverride, 3=hook closure)
            for level = 4, 9 do
                local ok, stackTbl = pcall(getStack, level)
                if not ok or type(stackTbl) ~= "table" then
                    if level > 6 then
                        break
                    end
                else
                    for idx, val in pairs(stackTbl) do
                        if val == origStart then
                            App.SafeSetStack(level, idx, newOrigin)
                        end
                    end
                end
            end
        end

        local function applySilentOverride(origOrigin, args)
            local target = resolveActiveCombatTarget(origOrigin)
            if not target or not target.part then
                return nil
            end
            args[2] = target.hitPos or target.part.Position
            if type(args[3]) == "number" then
                args[3] = 0
            end
            if target.origin and typeof(origOrigin) == "Vector3" and target.origin ~= origOrigin then
                syncCallerOriginStack(origOrigin, target.origin)
                args[1] = target.origin
            end
            return target
        end

        local function findUpvalueRP(fn)
            local rp = App.SafeUpvalue(fn, 2)
            if typeof(rp) == "RaycastParams" then
                return rp
            end
            for idx = 1, 16 do
                local v, exists = App.SafeUpvalue(fn, idx)
                if not exists then
                    break
                end
                if typeof(v) == "RaycastParams" then
                    return v
                end
            end
            return nil
        end

        local function inspectUpvaluesFromShoot(shootFn)
            if type(shootFn) ~= "function" then
                return false
            end
            local bullet = App.SafeUpvalue(shootFn, 16)
            local rp = type(bullet) == "function" and findUpvalueRP(bullet) or nil
            if type(bullet) ~= "function" or not rp then
                bullet = nil
                rp = nil
                for idx = 1, 28 do
                    local uv, exists = App.SafeUpvalue(shootFn, idx)
                    if not exists then
                        break
                    end
                    if type(uv) == "function" then
                        local candRp = findUpvalueRP(uv)
                        if candRp then
                            bullet = uv
                            rp = candRp
                            break
                        end
                    end
                end
            end
            if type(bullet) ~= "function" then
                return false
            end
            GunHook.Shoot = shootFn
            GunHook.Bullet = bullet
            local reloadFn = App.SafeUpvalue(shootFn, 2)
            if type(reloadFn) ~= "function" or reloadFn == bullet then
                reloadFn = nil
                for idx = 1, 20 do
                    local uv, exists = App.SafeUpvalue(shootFn, idx)
                    if not exists then
                        break
                    end
                    if type(uv) == "function" and uv ~= bullet then
                        reloadFn = uv
                        break
                    end
                end
            end
            GunHook.Reload = reloadFn
            local gd = App.SafeUpvalue(shootFn, 10)
            if type(gd) ~= "table" or not (gd.Range or gd.FireRate) then
                for idx = 1, 20 do
                    local uv, exists = App.SafeUpvalue(shootFn, idx)
                    if not exists then
                        break
                    end
                    if type(uv) == "table" and (uv.Range ~= nil or uv.FireRate ~= nil) then
                        gd = uv
                        break
                    end
                end
            end
            GunHook.GunData = gd
            if type(GunHook.Reload) == "function" then
                GunHook.PlaySound = App.SafeUpvalue(GunHook.Reload, 3) or App.SafeUpvalue(GunHook.Reload, 1)
            end
            if typeof(rp) == "RaycastParams" then
                GunHook.CastRayParams = rp
                if not GunHook.BaseIgnoreList then
                    GunHook.BaseIgnoreList = rp.FilterDescendantsInstances
                end
            end
            return true
        end

        local function getFnSource(fn)
            if type(fn) ~= "function" then
                return ""
            end
            local infoFn = debug and rawget(debug, "info") or nil
            if App.Has.DebugInfo and type(infoFn) == "function" then
                local ok, src = pcall(infoFn, fn, "s")
                if ok and type(src) == "string" then
                    return src
                end
            end
            local getInfoFn = debug and rawget(debug, "getinfo") or nil
            if type(getInfoFn) == "function" then
                local ok, info = pcall(getInfoFn, fn, "S")
                if ok and type(info) == "table" and type(info.source) == "string" then
                    return info.source
                end
            end
            return ""
        end

        local function discoverFromGetConnections()
            if not App.Has.GetConnections then
                return false
            end
            local lplr = App.LocalPlayer
            local pg = lplr and lplr:FindFirstChild("PlayerGui") or nil
            local home = pg and pg:FindFirstChild("Home") or nil
            local hud = home and home:FindFirstChild("hud") or nil
            local actionArea = hud and hud:FindFirstChild("ActionArea") or nil

            if actionArea then
                local ok, conns = pcall(getconnections, actionArea.InputBegan)
                if ok and type(conns) == "table" then
                    for _, conn in ipairs(conns) do
                        local fn = conn and conn.Function or nil
                        if fn and (inspectUpvaluesFromShoot(fn) or inspectUpvaluesFromShoot(App.SafeUpvalue(fn, 2))) then
                            break
                        end
                    end
                end
            end

            if lplr then
                local okC, charConns = pcall(getconnections, lplr.CharacterAdded)
                if okC and type(charConns) == "table" then
                    for _, conn in ipairs(charConns) do
                        local fn = conn and conn.Function or nil
                        if fn then
                            local src = getFnSource(fn)
                            if type(src) == "string" and string.find(src, "GunController", 1, true) then
                                local rp = App.SafeUpvalue(fn, 2)
                                if typeof(rp) == "RaycastParams" and not GunHook.CastRayParams then
                                    GunHook.CastRayParams = rp
                                    if not GunHook.BaseIgnoreList then
                                        GunHook.BaseIgnoreList = rp.FilterDescendantsInstances
                                    end
                                end
                                local eqFn = App.SafeUpvalue(fn, 3)
                                if type(eqFn) == "function" then
                                    GunHook.Equip = eqFn
                                    local cbd = App.SafeUpvalue(eqFn, 20)
                                    if type(cbd) == "function" then
                                        GunHook.CanBeDamaged = cbd
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end
            return GunHook.Bullet ~= nil
        end

        local function discoverFromGetSenv()
            if GunHook.Bullet or not App.Has.GetSenv then
                return GunHook.Bullet ~= nil
            end
            local lplr = App.LocalPlayer
            local roots = {
                lplr and lplr:FindFirstChild("PlayerScripts") or nil,
                lplr and lplr:FindFirstChild("PlayerGui") or nil,
                App.GetChar(lplr),
            }
            for _, rootInst in ipairs(roots) do
                if rootInst then
                    local gcScript = rootInst:FindFirstChild("GunController", true)
                    if gcScript then
                        local ok, env = pcall(getsenv, gcScript)
                        if ok and type(env) == "table" then
                            for _, val in pairs(env) do
                                if type(val) == "function" then
                                    if inspectUpvaluesFromShoot(val) or inspectUpvaluesFromShoot(App.SafeUpvalue(val, 2)) then
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return GunHook.Bullet ~= nil
        end

        local function discoverFromGetGC()
            if GunHook.Bullet or not App.Has.GetGC then
                return GunHook.Bullet ~= nil
            end
            local ok, gcList = pcall(getgc, true)
            if not ok or type(gcList) ~= "table" then
                return false
            end
            for _, item in ipairs(gcList) do
                if type(item) == "function" then
                    local src = getFnSource(item)
                    if type(src) == "string" and string.find(src, "GunController", 1, true) then
                        if inspectUpvaluesFromShoot(item) then
                            break
                        end
                    end
                end
            end
            return GunHook.Bullet ~= nil
        end

        local function attachHooks()
            if type(GunHook.Bullet) == "function" and not GunHook.IsBulletHooked then
                local origBullet
                origBullet = App.HookFn(GunHook.Bullet, function(...)
                    local args = packArgs(...)
                    local origStart = args[1]
                    local aimedTarget = nil
                    if App.Running and (State.Ragebot or State.SilentAim or GunHook.ForceRageShot or GunHook.TaseTargetPart) then
                        aimedTarget = applySilentOverride(origStart, args)
                    end
                    local ret = packArgs(origBullet(unpackFn(args, 1, args.n)))
                    local hitPart = ret[1]
                    local hitPos = typeof(ret[2]) == "Vector3" and ret[2] or (aimedTarget and aimedTarget.hitPos) or args[2]
                    if State.BulletTracers and not App.VFX.IsHooked() and typeof(args[1]) == "Vector3" and typeof(hitPos) == "Vector3" then
                        App.VFX.SpawnTracer(args[1], hitPos, (State.Ragebot or GunHook.ForceRageShot) and Palette.RageCrimson or Palette.NeonCyan)
                    end
                    if typeof(hitPart) == "Instance" then
                        registerHitDamageWatcher(hitPart, hitPos)
                    end
                    return unpackFn(ret, 1, ret.n)
                end)
                if origBullet then
                    GunHook.OldBullet = origBullet
                    GunHook.IsBulletHooked = true
                end
            end

            if type(GunHook.Equip) == "function" and not GunHook.IsEquipHooked then
                local origEquip
                origEquip = App.HookFn(GunHook.Equip, function(tool, ...)
                    local ret = packArgs(origEquip(tool, ...))
                    if typeof(tool) == "Instance" and tool:IsA("Tool") then
                        GunHook.Tool = tool
                    else
                        local char = App.GetChar(App.LocalPlayer)
                        GunHook.Tool = char and char:FindFirstChildOfClass("Tool") or nil
                    end
                    if type(GunHook.Shoot) == "function" then
                        local gd = App.SafeUpvalue(GunHook.Shoot, 10)
                        if type(gd) == "table" then
                            GunHook.GunData = gd
                        end
                    end
                    Combat.UpdateCastRayFilter()
                    Combat.ApplyGunModsToTool(GunHook.Tool)
                    return unpackFn(ret, 1, ret.n)
                end)
                if origEquip then
                    GunHook.OldEquip = origEquip
                    GunHook.IsEquipHooked = true
                end
            end

            if type(GunHook.PlaySound) == "function" and not GunHook.IsPlaySoundHooked then
                local origPlay
                origPlay = App.HookFn(GunHook.PlaySound, function(soundName, ...)
                    if type(soundName) == "string" and not string.find(soundName, "rbxasset", 1, true) then
                        local char = App.GetChar(App.LocalPlayer)
                        local tool = char and char:FindFirstChildOfClass("Tool") or nil
                        local handle = tool and tool:FindFirstChild("Handle") or nil
                        if not handle or (not handle:FindFirstChild(soundName) and not tool:FindFirstChild(soundName)) then
                            return nil
                        end
                    end
                    return origPlay(soundName, ...)
                end)
                if origPlay then
                    GunHook.OldPlaySound = origPlay
                    GunHook.IsPlaySoundHooked = true
                end
            end
        end

        local function attachNamecallFallback()
            if GunHook.IsBulletHooked or GunHook.IsNamecallHooked or not App.Has.HookMetamethod then
                return
            end
            local checkcallerFn = (GEN_ENV and rawget(GEN_ENV, "checkcaller")) or (type(checkcaller) == "function" and checkcaller) or rawget(_G, "checkcaller")
            local getMethodFn = (GEN_ENV and rawget(GEN_ENV, "getnamecallmethod")) or (type(getnamecallmethod) == "function" and getnamecallmethod) or rawget(_G, "getnamecallmethod")
            local newcclosureFn = (GEN_ENV and rawget(GEN_ENV, "newcclosure")) or (type(newcclosure) == "function" and newcclosure) or rawget(_G, "newcclosure")
            local wrap = type(newcclosureFn) == "function" and newcclosureFn or function(f) return f end

            local oldNc
            local hookClosure = wrap(function(self, ...)
                local method = type(getMethodFn) == "function" and getMethodFn() or ""
                if App.Running and not (checkcallerFn and checkcallerFn()) and self == Workspace and method == "Raycast" then
                    if State.SilentAim or State.Ragebot or GunHook.ForceRageShot then
                        local args = packArgs(...)
                        local origin, dir = args[1], args[2]
                        if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" and dir.Magnitude > 40 then
                            local target = resolveActiveCombatTarget(origin)
                            if target and target.part then
                                local tOrg = target.origin or origin
                                local tHit = target.hitPos or target.part.Position
                                args[1] = tOrg
                                args[2] = (tHit - tOrg).Unit * math.max(dir.Magnitude, (tHit - tOrg).Magnitude + 2)
                                return oldNc(self, unpackFn(args, 1, args.n))
                            end
                        end
                    end
                end
                return oldNc(self, ...)
            end)

            local ok, res = pcall(hookmetamethod, game, "__namecall", hookClosure)
            if ok and type(res) == "function" then
                oldNc = res
                GunHook.OldNamecall = res
                GunHook.IsNamecallHooked = true
            end
        end

        function Combat.SetupGunControllerHooks()
            discoverFromGetConnections()
            discoverFromGetSenv()
            discoverFromGetGC()
            attachHooks()
            attachNamecallFallback()
            Combat.UpdateCastRayFilter()
            GunHook.Ready = (GunHook.Bullet ~= nil) or (GunHook.Shoot ~= nil) or GunHook.IsNamecallHooked
            return GunHook.Ready
        end

        function Combat.RestoreHooks()
            Combat.ClearFrameCache()
            if GunHook.IsBulletHooked and GunHook.Bullet and GunHook.OldBullet then
                App.RestoreFn(GunHook.Bullet, GunHook.OldBullet)
            end
            if GunHook.IsEquipHooked and GunHook.Equip and GunHook.OldEquip then
                App.RestoreFn(GunHook.Equip, GunHook.OldEquip)
            end
            if GunHook.IsPlaySoundHooked and GunHook.PlaySound and GunHook.OldPlaySound then
                App.RestoreFn(GunHook.PlaySound, GunHook.OldPlaySound)
            end
            if GunHook.IsNamecallHooked and GunHook.OldNamecall and App.Has.HookMetamethod then
                pcall(hookmetamethod, game, "__namecall", GunHook.OldNamecall)
            end
            if typeof(GunHook.CastRayParams) == "RaycastParams" and GunHook.BaseIgnoreList then
                GunHook.CastRayParams.FilterDescendantsInstances = GunHook.BaseIgnoreList
            end
            GunHook.OldBullet = nil
            GunHook.OldEquip = nil
            GunHook.OldPlaySound = nil
            GunHook.OldNamecall = nil
            GunHook.IsBulletHooked = false
            GunHook.IsEquipHooked = false
            GunHook.IsPlaySoundHooked = false
            GunHook.IsNamecallHooked = false
            GunHook.Ready = false
            return true
        end

        function Combat.FireGunOnce(tool, targetPart, isRage, isTase, isCombo)
            local char = App.GetChar(App.LocalPlayer)
            local hum = App.GetHum(char)
            if not char or not hum or hum.Health <= 0 or not tool then
                return false
            end
            if GunHook._firingBusy then
                return false
            end

            if not GunHook.Shoot then
                Combat.SetupGunControllerHooks()
            end

            GunHook._firingBusy = true
            if tool.Parent ~= char then
                pcall(hum.EquipTool, hum, tool)
                local deadline = os.clock() + 0.14
                while App.Running and tool.Parent == char and GunHook.IsEquipHooked and GunHook.Tool ~= tool and os.clock() < deadline do
                    RunService.Heartbeat:Wait()
                end
            elseif GunHook.IsEquipHooked and GunHook.Tool ~= tool then
                local deadline = os.clock() + 0.08
                while App.Running and tool.Parent == char and GunHook.Tool ~= tool and os.clock() < deadline do
                    RunService.Heartbeat:Wait()
                end
            end
            GunHook._firingBusy = false

            if tool.Parent ~= char or not Combat.IsToolReadyToFire(tool) then
                return false
            end

            if isTase then
                GunHook.TaseTargetPart = targetPart
            elseif isRage then
                GunHook.RageTargetPart = targetPart
                GunHook.ForceRageShot = true
                GunHook.LastShotWasRage = true
            else
                GunHook.CurrentTargetPart = targetPart
                GunHook.ForceRageShot = false
                GunHook.LastShotWasRage = false
            end

            GunHook._shotToken = GunHook._shotToken + 1
            local token = GunHook._shotToken

            local ok = false
            if type(GunHook.Shoot) == "function" then
                local obj = {
                    UserInputType = Enum.UserInputType.MouseButton1,
                    UserInputState = Enum.UserInputState.Begin,
                    KeyCode = Enum.KeyCode.Unknown,
                }
                ok = pcall(task.spawn, GunHook.Shoot, obj)
                -- Flip UserInputState synchronously to End immediately after task.spawn so Shoot executes 1 shot cleanly.
                obj.UserInputState = Enum.UserInputState.End
            else
                ok = pcall(tool.Activate, tool)
            end

            local now = os.clock()
            local comboShot = isCombo == true
            if not isCombo then
                local lockInfo = App.ToolArbiter and App.ToolArbiter.GetLock and App.ToolArbiter.GetLock() or nil
                if lockInfo and lockInfo.reason == "Combo1" then
                    comboShot = true
                end
            end
            if isTase then
                GunHook.LastTaseShotClock = now
            elseif comboShot then
                GunHook.LastComboShotClock = now
            elseif isRage then
                GunHook.LastRageShotClock = now
            end

            local chargeDelay = math.max(0.05, (tonumber(tool:GetAttribute("ChargeTime")) or 0) + 0.06)
            task.delay(chargeDelay, function()
                if GunHook._shotToken == token then
                    GunHook.ForceRageShot = false
                    GunHook.RageTargetPart = nil
                    GunHook.TaseTargetPart = nil
                end
            end)

            return ok
        end

        Janitor.AddCleanup(Combat.RestoreHooks)
        Janitor.AddCleanup(Combat.RestoreGunMods)
        Janitor.AddCleanup(function()
            Combat.ApplyAntiRiotShield(false)
        end)
        if App.LocalPlayer then
            Janitor.Add(App.LocalPlayer.CharacterAdded:Connect(function()
                task.delay(0.25, function()
                    if App.Running then
                        Combat.SetupGunControllerHooks()
                        Combat.ApplyGunModsAll()
                    end
                end)
            end))
        end

        App.Combat = Combat
    end

    initCombat()
end

--------------------------------------------------------------------------------
-- 6. APP.WEAPONS
--------------------------------------------------------------------------------
do
    local COMBO_ORDER = { "Remington 870", "M700", "FAL", "M4A1", "AK-47", "Revolver", "MP5", "M9" }
    local KNOWN_GAMEPASSES = {
        ["M4A1"] = 643697197,
        ["Riot Shield"] = 643697197,
        ["FAL"] = 1443271,
        ["M700"] = 699360089,
    }
    local DEATH_WINDOW = 10
    local HIDE_FRAMES = 3
    local FIGHT_TIME = 0.12

    local function initWeapons()
        local Workspace = Services.Workspace
        local CollectionService = Services.CollectionService
        local MarketplaceService = Services.MarketplaceService
        local Teams = Services.Teams
        local RunService = Services.RunService

        local Weapons = {}
        -- Distinct verified armory / warehouse coordinates only (M9 resolves dynamically via Giver tags/TouchGiver).
        Weapons.KnownGunLocations = {
            ["Remington 870"] = Vector3.new(820.3, 97.85, 2229.4),
            ["MP5"] = Vector3.new(813.7, 97.85, 2229.4),
            ["AK-47"] = Vector3.new(-931.8, 91.28, 2039.3),
            ["M4A1"] = Vector3.new(847.5, 97.85, 2229.4),
            ["FAL"] = Vector3.new(-938.5, 91.28, 2039.3),
            ["Riot Shield"] = Vector3.new(840.0, 97.85, 2229.4),
        }

        local gamepassCache = {}
        local isGrabbing = false
        local isRespawning = false
        local isComboRunning = false
        local lastAliveCF = nil
        local lastAliveTime = 0
        local wasOnTeamsMenu = false

        function Weapons.HasTool(name, equippedOnly)
            if type(name) ~= "string" or name == "" then
                return nil
            end
            local char = App.GetChar(App.LocalPlayer)
            local inChar = char and char:FindFirstChild(name) or nil
            if inChar and inChar:IsA("Tool") then
                return inChar
            end
            if equippedOnly then
                return nil
            end
            local lplr = App.LocalPlayer
            local bp = lplr and (lplr:FindFirstChildOfClass("Backpack") or lplr:FindFirstChild("Backpack")) or nil
            local inBp = bp and bp:FindFirstChild(name) or nil
            if inBp and inBp:IsA("Tool") then
                return inBp
            end
            return nil
        end

        local function userOwnsPassCached(passId)
            if not passId or passId <= 0 then
                return true
            end
            if gamepassCache[passId] ~= nil then
                return gamepassCache[passId]
            end
            local lplr = App.LocalPlayer
            if not lplr then
                return true
            end
            local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, lplr.UserId, passId)
            if ok then
                gamepassCache[passId] = (owns == true)
                return gamepassCache[passId]
            end
            return true
        end

        local function isGiverAllowed(inst, toolName)
            local lplr = App.LocalPlayer
            local myTeamName = (lplr and lplr.Team and lplr.Team.Name) or ""

            local okTags, tags = pcall(CollectionService.GetTags, CollectionService, inst)
            if okTags and type(tags) == "table" and #tags > 0 then
                local hasTeamRestriction = false
                local allowedByTag = false
                for _, tag in ipairs(tags) do
                    if tag == "Team_Any" then
                        allowedByTag = true
                        break
                    elseif string.sub(tag, 1, 5) == "Team_" then
                        hasTeamRestriction = true
                        if string.sub(tag, 6) == myTeamName then
                            allowedByTag = true
                        end
                    end
                end
                if hasTeamRestriction and not allowedByTag then
                    return false
                end
            end

            local gpId = tonumber(inst:GetAttribute("RequiredGamepass"))
                or tonumber(inst:GetAttribute("GamepassId"))
                or (inst.Parent and tonumber(inst.Parent:GetAttribute("RequiredGamepass")))
            if not gpId and inst:GetAttribute("Gamepass") then
                gpId = KNOWN_GAMEPASSES[toolName]
            end
            if gpId and not userOwnsPassCached(gpId) then
                return false
            end
            return true
        end

        local function resolveGiverPart(inst)
            if not inst or not inst.Parent then
                return nil
            end
            if inst:IsA("BasePart") then
                return inst
            end
            local tg = inst:FindFirstChild("TouchGiver") or inst:FindFirstChildWhichIsA("BasePart")
            return (tg and tg:IsA("BasePart")) and tg or nil
        end

        local function pickClosestGiver(candidates, hintPos)
            if #candidates == 0 then
                return nil, nil
            end
            local refPos = hintPos
            if not refPos then
                local root = App.GetRoot(App.GetChar(App.LocalPlayer))
                refPos = root and root.Position or nil
            end
            if not refPos then
                return candidates[1].part, candidates[1].cf
            end
            local best = candidates[1]
            local bestDist = (best.part.Position - refPos).Magnitude
            for i = 2, #candidates do
                local d = (candidates[i].part.Position - refPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = candidates[i]
                end
            end
            return best.part, best.cf
        end

        function Weapons.FindTouchGiverForTool(toolName)
            if type(toolName) ~= "string" or toolName == "" then
                return nil, nil
            end
            local lowTarget = string.lower(toolName)
            local candidates = {}
            local seenParts = {}

            local function consider(inst)
                if not inst or not inst.Parent or inst:IsA("Tool") or inst:FindFirstAncestorOfClass("Tool") then
                    return
                end
                local attrName = inst:GetAttribute("ToolName") or (inst.Parent and inst.Parent:GetAttribute("ToolName"))
                local matchName = (type(attrName) == "string" and string.lower(attrName) == lowTarget)
                    or string.lower(inst.Name) == lowTarget
                    or (inst.Parent and string.lower(inst.Parent.Name) == lowTarget)
                if not matchName then
                    return
                end
                if not isGiverAllowed(inst, toolName) then
                    return
                end
                local part = resolveGiverPart(inst)
                if part and not seenParts[part] then
                    seenParts[part] = true
                    candidates[#candidates + 1] = {
                        part = part,
                        cf = part.CFrame + Vector3.new(0, 1.5, 0),
                    }
                end
            end

            local okTagged, tagged = pcall(CollectionService.GetTagged, CollectionService, "Giver")
            if okTagged and type(tagged) == "table" then
                for _, inst in ipairs(tagged) do
                    consider(inst)
                end
            end

            if #candidates == 0 then
                local itemsFolder = Workspace:FindFirstChild("Prison_ITEMS")
                local giverFolder = itemsFolder and itemsFolder:FindFirstChild("giver") or nil
                if giverFolder then
                    for _, desc in ipairs(giverFolder:GetDescendants()) do
                        if desc.Name == "TouchGiver" or desc:IsA("Model") then
                            consider(desc)
                        end
                    end
                end
            end

            if #candidates == 0 then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj.Name == "TouchGiver" then
                        consider(obj.Parent or obj)
                    end
                end
            end

            return pickClosestGiver(candidates, Weapons.KnownGunLocations[toolName])
        end

        local function exitSeatSafely(hum)
            if not hum or (not hum.Sit and hum.SeatPart == nil) then
                return true
            end
            hum.Sit = false
            local deadline = os.clock() + 0.35
            while App.Running and hum.SeatPart ~= nil and os.clock() < deadline do
                RunService.Heartbeat:Wait()
            end
            task.wait(0.05)
            return hum.SeatPart == nil
        end

        local function triggerGiverTouch(root, touchPart)
            if App.Has.FireTouchInterest then
                pcall(firetouchinterest, root, touchPart, 0)
                pcall(firetouchinterest, root, touchPart, 1)
            end
            local rem = App.Remotes
            if rem then
                if rem.GiverPressed then
                    pcall(rem.GiverPressed.FireServer, rem.GiverPressed, touchPart)
                end
                if rem.TouchGiver then
                    pcall(rem.TouchGiver.FireServer, rem.TouchGiver, touchPart)
                end
                if rem.InteractWithItem then
                    pcall(task.spawn, rem.InteractWithItem.InvokeServer, rem.InteractWithItem, touchPart)
                end
            end
        end

        function Weapons.GrabWeapons(list, silent)
            if isGrabbing then
                return 0
            end
            local char = App.GetChar(App.LocalPlayer)
            local root = App.GetRoot(char)
            local hum = App.GetHum(char)
            if not char or not root or not hum or hum.Health <= 0 then
                return 0
            end

            local targetList = (type(list) == "table" and #list > 0) and list or State.AutoGunsSelection
            if type(targetList) ~= "table" or #targetList == 0 then
                return 0
            end

            local queue = {}
            for _, gunName in ipairs(targetList) do
                if type(gunName) == "string" and gunName ~= "" and not Weapons.HasTool(gunName) then
                    local tPart, tCF = Weapons.FindTouchGiverForTool(gunName)
                    if tPart and tCF then
                        queue[#queue + 1] = { name = gunName, part = tPart, cf = tCF }
                    end
                end
            end
            if #queue == 0 then
                return 0
            end

            isGrabbing = true
            local grabbed = 0
            local savedCF = root.CFrame

            pcall(function()
                exitSeatSafely(hum)
                root = App.GetRoot(App.GetChar(App.LocalPlayer))
                if not root or hum.Health <= 0 then
                    return
                end
                savedCF = root.CFrame

                for _, entry in ipairs(queue) do
                    if not App.Running or hum.Health <= 0 then
                        break
                    end
                    local deadline = os.clock() + 0.65
                    while App.Running and hum.Health > 0 and os.clock() < deadline do
                        if Weapons.HasTool(entry.name) then
                            grabbed = grabbed + 1
                            break
                        end
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        root.CFrame = entry.cf
                        triggerGiverTouch(root, entry.part)
                        RunService.Heartbeat:Wait()
                    end
                end

                if root and root.Parent then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = savedCF
                end
            end)

            isGrabbing = false
            App.Combat.SetupGunControllerHooks()
            App.Combat.ApplyGunModsAll()
            if not silent and grabbed > 0 then
                Bus.Emit("Alert", "Weapons", string.format("Equipped %d weapon(s)", grabbed), "success")
            end
            return grabbed
        end

        function Weapons.GetCriminalsSpawnPart()
            local cs = Workspace:FindFirstChild("Criminals Spawn")
            if cs then
                if cs:IsA("BasePart") then
                    return cs
                end
                local sp = cs:FindFirstChild("SpawnLocation") or cs:FindFirstChildWhichIsA("BasePart", true)
                if sp and sp:IsA("BasePart") then
                    return sp
                end
            end
            local crimTeam = Teams:FindFirstChild("Criminals")
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("SpawnLocation") then
                    if (crimTeam and obj.TeamColor == crimTeam.TeamColor) or string.find(string.lower(obj.Name), "criminal", 1, true) then
                        return obj
                    end
                end
            end
            return nil
        end

        local function isOnTeamsMenu()
            local lplr = App.LocalPlayer
            local pg = lplr and lplr:FindFirstChild("PlayerGui") or nil
            local home = pg and pg:FindFirstChild("Home") or nil
            local intro = home and home:FindFirstChild("IntroFrame") or nil
            if intro and intro.Visible then
                return true
            end
            return false
        end

        local function restoreCameraAfterSpawn(newHum)
            local cam = App.GetCamera()
            if cam then
                if cam.CameraType == Enum.CameraType.Scriptable then
                    cam.CameraType = Enum.CameraType.Custom
                end
                if newHum then
                    cam.CameraSubject = newHum
                end
            end
            local lplr = App.LocalPlayer
            local pg = lplr and lplr:FindFirstChild("PlayerGui") or nil
            local home = pg and pg:FindFirstChild("Home") or nil
            local intro = home and home:FindFirstChild("IntroFrame") or nil
            if intro and lplr.Team and lplr.Team.Name ~= "Neutral" then
                intro.Visible = false
            end
        end

        local function readTeamsMenuRejection(targetTeamName)
            local lplr = App.LocalPlayer
            local pg = lplr and lplr:FindFirstChild("PlayerGui") or nil
            local home = pg and pg:FindFirstChild("Home") or nil
            if not home then
                return nil
            end
            local hud = home:FindFirstChild("hud")
            local containers = {}
            if hud then
                local tm = hud:FindFirstChild("TeamsMenu")
                if tm then table.insert(containers, tm) end
            end
            local homeTm = home:FindFirstChild("TeamsMenu")
            if homeTm then table.insert(containers, homeTm) end
            local intro = home:FindFirstChild("IntroFrame")
            if intro then table.insert(containers, intro) end
            local lowTarget = string.lower(targetTeamName)
            for _, box in ipairs(containers) do
                if box then
                    for _, desc in ipairs(box:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible then
                            local tl = string.lower(desc.Text or "")
                            if string.find(tl, "team full", 1, true) or string.find(tl, "unbalanced", 1, true) then
                                return desc.Text
                            end
                        elseif desc:IsA("GuiButton") and desc.Visible and desc.AutoButtonColor == false then
                            if string.find(string.lower(desc.Name), lowTarget, 1, true) then
                                return targetTeamName .. " locked (Full / Unbalanced)"
                            end
                        end
                    end
                end
            end
            return nil
        end

        local function switchUntil(targetTeam, timeoutSec)
            local lplr = App.LocalPlayer
            local rem = App.Remotes and App.Remotes.RequestTeamChange or nil
            if not lplr or not targetTeam or not rem then
                return lplr and lplr.Team == targetTeam
            end
            local deadline = os.clock() + (timeoutSec or 3.0)
            local nextFire = 0

            while App.Running and os.clock() < deadline do
                if lplr.Team == targetTeam then
                    return true
                end
                local uiRejection = readTeamsMenuRejection(targetTeam.Name)
                if uiRejection then
                    Bus.Emit("Alert", "Team", uiRejection, "warn")
                    return false
                end
                local now = os.clock()
                if now >= nextFire then
                    nextFire = now + 0.1
                    local ok, res, msg = pcall(function()
                        if rem:IsA("RemoteFunction") then
                            return rem:InvokeServer(targetTeam, 1)
                        else
                            rem:FireServer(targetTeam, 1)
                            return true
                        end
                    end)
                    if ok and res == false and type(msg) == "string" then
                        local lm = string.lower(msg)
                        if string.find(lm, "full", 1, true) or string.find(lm, "unbalanced", 1, true) then
                            Bus.Emit("Alert", "Team", msg, "warn")
                            return false
                        end
                    end
                end
                task.wait(0.03)
            end
            return lplr.Team == targetTeam
        end

        local TEAM_ALIASES = {
            guards = "Guards", guard = "Guards", cops = "Guards", cop = "Guards", police = "Guards",
            inmates = "Inmates", inmate = "Inmates", prisoners = "Inmates", prisoner = "Inmates",
            criminals = "Criminals", criminal = "Criminals", crims = "Criminals", crim = "Criminals",
            neutral = "Neutral",
        }

        function Weapons.SwitchToTeam(teamName)
            if type(teamName) ~= "string" then
                return false
            end
            local trimmed = App.Trim(teamName)
            if trimmed == "" then
                return false
            end

            local canonName = TEAM_ALIASES[string.lower(trimmed)] or trimmed
            local targetTeam = Teams:FindFirstChild(canonName)
            if not targetTeam then
                for _, t in ipairs(Teams:GetTeams()) do
                    if string.lower(t.Name) == string.lower(trimmed) then
                        targetTeam = t
                        break
                    end
                end
            end
            if not targetTeam then
                return false
            end

            local lplr = App.LocalPlayer
            if lplr and lplr.Team == targetTeam then
                return true
            end

            if targetTeam.Name == "Criminals" then
                local inmatesTeam = Teams:FindFirstChild("Inmates")
                if inmatesTeam and lplr.Team ~= inmatesTeam then
                    local oldChar = App.GetChar(lplr)
                    if not switchUntil(inmatesTeam, 3.0) then
                        return false
                    end
                    local deadline = os.clock() + 2.5
                    local curChar = App.GetChar(lplr)
                    while App.Running and (curChar == nil or (oldChar and curChar == oldChar and oldChar.Parent == Workspace)) and os.clock() < deadline do
                        task.wait(0.05)
                        curChar = App.GetChar(lplr)
                    end
                end
                local deadline = os.clock() + 3.0
                local root = App.GetRoot(App.GetChar(lplr))
                while App.Running and not root and os.clock() < deadline do
                    task.wait(0.05)
                    root = App.GetRoot(App.GetChar(lplr))
                end
                local sp = Weapons.GetCriminalsSpawnPart()
                if not root or not sp then
                    return false
                end
                local savedCF = root.CFrame
                local cDead = os.clock() + 1.5
                while App.Running and lplr.Team ~= targetTeam and os.clock() < cDead do
                    if App.Has.FireTouchInterest then
                        pcall(firetouchinterest, root, sp, 0)
                        pcall(firetouchinterest, root, sp, 1)
                    end
                    root.CFrame = sp.CFrame + Vector3.new(0, 2.5, 0)
                    task.wait(0.05)
                end
                if root and root.Parent then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.CFrame = savedCF
                end
                restoreCameraAfterSpawn(App.GetHum(App.GetChar(lplr)))
                return lplr.Team == targetTeam
            end

            local ok = switchUntil(targetTeam, 3.0)
            if ok then
                restoreCameraAfterSpawn(App.GetHum(App.GetChar(lplr)))
            end
            return ok
        end

        local function teleportSeamless(character, root, targetCF)
            if not character or not root or not targetCF then
                return
            end
            local hidden = {}
            for _, d in ipairs(character:GetDescendants()) do
                if d:IsA("BasePart") then
                    hidden[d] = d.LocalTransparencyModifier
                    d.LocalTransparencyModifier = 1
                end
            end
            local addedConn = Janitor.Add(character.DescendantAdded:Connect(function(d)
                if d:IsA("BasePart") then
                    hidden[d] = d.LocalTransparencyModifier
                    d.LocalTransparencyModifier = 1
                end
            end))

            root.CFrame = targetCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero

            for _ = 1, HIDE_FRAMES do
                if not App.Running or not root.Parent then
                    break
                end
                root.CFrame = targetCF
                root.AssemblyLinearVelocity = Vector3.zero
                RunService.RenderStepped:Wait()
            end

            for part, orig in pairs(hidden) do
                if part and part.Parent then
                    part.LocalTransparencyModifier = orig
                end
            end
            pcall(addedConn.Disconnect, addedConn)

            local fightDeadline = os.clock() + FIGHT_TIME
            while App.Running and os.clock() < fightDeadline do
                if root and root.Parent then
                    root.CFrame = targetCF
                    root.AssemblyLinearVelocity = Vector3.zero
                end
                RunService.RenderStepped:Wait()
            end
        end

        local function awaitRespawnedChar(oldChar, timeoutSec)
            local lplr = App.LocalPlayer
            local spawned = nil
            local conn = lplr.CharacterAdded:Connect(function(nc)
                if nc and nc ~= oldChar then
                    spawned = nc
                end
            end)
            local deadline = os.clock() + (timeoutSec or 5.0)
            while App.Running and os.clock() < deadline do
                local cur = spawned or lplr.Character
                if cur and cur ~= oldChar and cur.Parent then
                    conn:Disconnect()
                    return cur
                end
                task.wait(0.03)
            end
            conn:Disconnect()
            return spawned or lplr.Character
        end

        function Weapons.PerformFastRespawn()
            if isRespawning then
                return false
            end
            local lplr = App.LocalPlayer
            if not lplr then
                return false
            end

            isRespawning = true
            local succeeded = false

            pcall(function()
                local oldChar = lplr.Character
                local oldRoot = App.GetRoot(oldChar)
                local oldHum = App.GetHum(oldChar)
                local restoreCF = nil

                if oldRoot and oldHum and oldHum.Health > 0 then
                    restoreCF = oldRoot.CFrame
                elseif lastAliveCF and (os.clock() - lastAliveTime) <= DEATH_WINDOW then
                    restoreCF = lastAliveCF
                end

                local origTeam = lplr.Team
                if not origTeam or origTeam.Name == "Neutral" then
                    if not restoreCF then
                        return
                    end
                    origTeam = Teams:FindFirstChild("Inmates")
                end
                if not origTeam then
                    return
                end

                if origTeam.Name == "Criminals" then
                    local inmatesTeam = Teams:FindFirstChild("Inmates")
                    if inmatesTeam then
                        switchUntil(inmatesTeam, 3.0)
                    end
                    local newChar = awaitRespawnedChar(oldChar, 5.0)
                    local newRoot = newChar and (newChar:FindFirstChild("HumanoidRootPart") or newChar:WaitForChild("HumanoidRootPart", 4)) or nil
                    local newHum = newChar and (newChar:FindFirstChildOfClass("Humanoid") or newChar:WaitForChild("Humanoid", 4)) or nil
                    restoreCameraAfterSpawn(newHum)

                    local sp = Weapons.GetCriminalsSpawnPart()
                    if newRoot and sp then
                        local tDead = os.clock() + 1.5
                        while App.Running and lplr.Team ~= origTeam and os.clock() < tDead do
                            if App.Has.FireTouchInterest then
                                pcall(firetouchinterest, newRoot, sp, 0)
                                pcall(firetouchinterest, newRoot, sp, 1)
                            end
                            newRoot.CFrame = sp.CFrame + Vector3.new(0, 2.5, 0)
                            task.wait(0.05)
                        end
                    end
                    if newChar and newRoot and restoreCF then
                        teleportSeamless(newChar, newRoot, restoreCF)
                    end
                    succeeded = (lplr.Team == origTeam)
                else
                    local neutralTeam = Teams:FindFirstChild("Neutral")
                    if neutralTeam then
                        switchUntil(neutralTeam, 2.5)
                        task.wait(0.05)
                    end
                    if not switchUntil(origTeam, 4.5) then
                        local fallback = Teams:FindFirstChild("Inmates")
                        if fallback and origTeam ~= fallback then
                            switchUntil(fallback, 3.0)
                        end
                    end
                    local newChar = awaitRespawnedChar(oldChar, 5.0)
                    local newRoot = newChar and (newChar:FindFirstChild("HumanoidRootPart") or newChar:WaitForChild("HumanoidRootPart", 4)) or nil
                    local newHum = newChar and (newChar:FindFirstChildOfClass("Humanoid") or newChar:WaitForChild("Humanoid", 4)) or nil
                    restoreCameraAfterSpawn(newHum)

                    if newChar and newRoot and restoreCF then
                        teleportSeamless(newChar, newRoot, restoreCF)
                    end
                    succeeded = (newChar ~= nil)
                end

                if App.Running then
                    App.Combat.SetupGunControllerHooks()
                    App.Combat.ApplyGunModsAll()
                end
            end)

            isRespawning = false
            return succeeded
        end

        function Weapons.GetOwnedLoadedGuns()
            local loadedMap = {}
            local ordered = {}

            App.Combat.ForEachOwnedTool(function(tool)
                if App.Combat.IsFirearmTool(tool, false) and App.Combat.IsToolReadyToFire(tool) then
                    loadedMap[tool] = true
                end
            end)

            for _, preferred in ipairs(COMBO_ORDER) do
                for tool in pairs(loadedMap) do
                    if tool.Name == preferred then
                        ordered[#ordered + 1] = tool
                        loadedMap[tool] = nil
                    end
                end
            end
            for tool in pairs(loadedMap) do
                ordered[#ordered + 1] = tool
            end
            return ordered
        end

        local function syncShieldAfterCombo(hadShield)
            local wantsShield = (State.ComboReEquipShield and State.ShieldEnabled) or hadShield
            if App.Shield and type(App.Shield.SetEnabled) == "function" then
                pcall(App.Shield.SetEnabled, wantsShield == true)
                return
            end
            if State.ComboReEquipShield then
                local shieldTool = Weapons.HasTool("Riot Shield")
                if shieldTool then
                    App.ToolArbiter.TryEquip(shieldTool, App.ToolArbiter.Priority.IdleShield, "IdleShield", 0.2)
                    if State.ShieldEnabled and App.Remotes and App.Remotes.ShieldEquipped then
                        pcall(App.Remotes.ShieldEquipped.FireServer, App.Remotes.ShieldEquipped, true)
                    end
                end
            end
        end

        function Weapons.ExecuteCombo1(targetPlr)
            if isComboRunning then
                return false
            end
            local myChar = App.GetChar(App.LocalPlayer)
            local myHum = App.GetHum(myChar)
            local myRoot = App.GetRoot(myChar)
            if not myChar or not myHum or myHum.Health <= 0 then
                return false
            end

            isComboRunning = true
            local didFire = false
            local hadShield = State.ShieldEnabled == true
            local hook = App.Combat.GunHook

            pcall(function()
                if State.ComboAutoGrabGuns and #Weapons.GetOwnedLoadedGuns() < 2 then
                    Weapons.GrabWeapons(State.AutoGunsSelection, true)
                end

                local guns = Weapons.GetOwnedLoadedGuns()
                if #guns == 0 then
                    Bus.Emit("Alert", "Combo", "No loaded guns ready", "warn")
                    return
                end

                local target = nil
                if targetPlr and App.Targets.IsValidCombatTarget(targetPlr, State.SilentAimHostileCheck) then
                    local tChar = App.GetChar(targetPlr)
                    local tPart = App.Targets.PickAimPart(tChar, true)
                    if tPart and myRoot then
                        local o, h = App.Targets.FindWallbangOrigin(myRoot.Position + Vector3.new(0, 1.5, 0), tPart.Position, tChar, true)
                        if o then
                            target = { player = targetPlr, part = tPart, origin = o, hitPos = h or tPart.Position }
                        end
                    end
                end
                if not target then
                    target = App.Targets.GetBestTarget({
                        use360 = true,
                        wallcheck = true,
                        wallbang = true,
                        requireHostile = State.SilentAimHostileCheck,
                        forceHead = true,
                        range = 9999,
                    })
                end
                if not target or not target.part then
                    Bus.Emit("Alert", "Combo", "No valid target", "warn")
                    return
                end

                Bus.Emit("Alert", "Combo", string.format("BURST -> %s (%d guns)", target.player.Name, #guns), "combo")
                Bus.Emit("ComboFlash", target.player, #guns)
                if App.HUD and type(App.HUD.FlashCombo) == "function" then
                    pcall(App.HUD.FlashCombo)
                end

                for _, gun in ipairs(guns) do
                    if not App.Running or myHum.Health <= 0 then
                        break
                    end
                    local tHum = App.GetHum(target.part and target.part.Parent)
                    if not target.part or not target.part.Parent or not tHum or tHum.Health <= 0 then
                        target = App.Targets.GetBestTarget({
                            use360 = true,
                            wallcheck = true,
                            wallbang = true,
                            requireHostile = State.SilentAimHostileCheck,
                            forceHead = true,
                            range = 9999,
                        })
                        if not target or not target.part then
                            break
                        end
                    end

                    hook.ForceRageShot = true
                    hook.RageTargetPart = target.part
                    if App.ToolArbiter.TryEquip(gun, App.ToolArbiter.Priority.Combo1, "Combo1", 0.35) then
                        local charge = tonumber(gun:GetAttribute("ChargeTime")) or 0
                        if charge > 0 then
                            task.wait(0.03)
                        end
                        if App.Combat.IsToolReadyToFire(gun) then
                            if App.Combat.FireGunOnce(gun, target.part, true, false, true) then
                                didFire = true
                            end
                            task.wait(math.max(0.045, charge > 0 and (charge + 0.04) or 0.045))
                        end
                    end
                end
            end)

            hook.ForceRageShot = false
            hook.RageTargetPart = nil
            App.ToolArbiter.Release("Combo1")
            syncShieldAfterCombo(hadShield)
            isComboRunning = false
            return didFire
        end

        -- Continuous alive CFrame tracking (10s TTL) + AutoRespawn listener
        Janitor.Add(RunService.Heartbeat:Connect(function()
            if not App.Running then
                return
            end
            if isOnTeamsMenu() then
                lastAliveCF = nil
                lastAliveTime = 0
                wasOnTeamsMenu = true
                return
            end
            if wasOnTeamsMenu then
                wasOnTeamsMenu = false
                lastAliveCF = nil
                lastAliveTime = 0
            end
            local char = App.GetChar(App.LocalPlayer)
            local root = App.GetRoot(char)
            local hum = App.GetHum(char)
            if root and hum and hum.Health > 0 then
                lastAliveCF = root.CFrame
                lastAliveTime = os.clock()
            end
        end))

        local function bindDeathRespawn(char)
            local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 6)) or nil
            if not hum then
                return
            end
            Janitor.Add(hum.Died:Connect(function()
                if App.Running and State.AutoRespawn and not isRespawning and not isOnTeamsMenu() then
                    task.spawn(Weapons.PerformFastRespawn)
                end
            end))
        end

        if App.LocalPlayer then
            if App.LocalPlayer.Character then
                task.spawn(bindDeathRespawn, App.LocalPlayer.Character)
            end
            Janitor.Add(App.LocalPlayer.CharacterAdded:Connect(function(char)
                task.spawn(bindDeathRespawn, char)
            end))
        end

        App.Weapons = Weapons
    end

    initWeapons()
end


-- ============================================================================
-- // MODULE 3: 3D HOLOGRAPHIC SHIELD, WORLD, ANOMALY ENGINE, LOD ESP, KILLFEED & SCHEDULER
-- ============================================================================

-- ============================================================================
-- MODULE 3: 03_shield_world_loops.lua
-- Prison Life 2026 — KX Edition V3
-- Exports: App.Shield, App.World, App.Anomaly, App.Visuals, App.Killfeed, App.Scheduler
-- Zero redeclarations of Module 1's 8 top-level locals. Zero file-scope locals.
-- Cross-compatible LuaJIT 2.1 + Luau (no continue, no +=, explicit pairs/ipairs).
-- ============================================================================

-- ============================================================================
-- SECTION 1: App.Shield (Holo Shield, Ray Interception, Desync, FEInvis, AntiTaze)
-- ============================================================================
do
    local S = {
        ShieldHP = 180,
        MaxShieldHP = 180,
        LastHitClock = -999,
        LastShieldRemoteSent = nil,
        DesyncJitterAngle = 0,
        SavedPosition = nil,
        SpoofedCFrame = nil,
        DesyncActive = false,
        ShieldPart = nil,
        ShieldRimPart = nil,
        LastRiotAlertClock = -999,
        LastDepletedAlertClock = -999,
        FEInvisActive = false,
        FEInvisSource = nil, -- "toggle" | "mode"
        FEInvisTrack = nil,
        FEInvisAnim = nil,
        FEInvisChar = nil,
        FEInvisTimePos = 1.95,
        FEInvisConns = {},
        FEInvisParts = setmetatable({}, { __mode = "k" }),
        AntiInvisWarnClock = setmetatable({}, { __mode = "k" }),
        AntiTazeInstalled = false,
        AntiTazeConn = nil,
        SavedWalkSpeed = 16,
        SavedJumpHeight = 7.2,
        SavedJumpPower = 50,
        SavedHeadConns = setmetatable({}, { __mode = "k" }),
        AntiJumpCleanups = setmetatable({}, { __mode = "k" }),
        VisualAnimBusy = false,
    }

    local H = {}

    function H.clamp(x, lo, hi)
        if x < lo then return lo end
        if x > hi then return hi end
        return x
    end

    function H.getGetConnections()
        if App.Has and App.Has.GetConnections then
            return (GEN_ENV and rawget(GEN_ENV, "getconnections")) or (type(getconnections) == "function" and getconnections) or rawget(_G, "getconnections")
        end
        return nil
    end

    function H.getPlayerGui()
        local lp = App.LocalPlayer
        if lp then
            return lp:FindFirstChildOfClass("PlayerGui")
        end
        return nil
    end

    function H.readGameShieldHP()
        local pgui = H.getPlayerGui()
        if not pgui then return nil end
        local home = pgui:FindFirstChild("Home")
        local hud = home and home:FindFirstChild("hud")
        local frame = hud and hud:FindFirstChild("ShieldHealthFrame")
        if not frame then return nil end
        local lbl = frame:FindFirstChildWhichIsA("TextLabel")
        if lbl and type(lbl.Text) == "string" then
            local num = tonumber(lbl.Text:match("(%d+)"))
            if num then return num end
        end
        local bar = frame:FindFirstChild("bar")
        if bar and bar:IsA("GuiObject") then
            return math.floor(H.clamp(bar.Size.X.Scale, 0, 1) * S.MaxShieldHP + 0.5)
        end
        return nil
    end

    function H.getRiotRemote()
        if App.Remotes and App.Remotes.ShieldEquipped then
            return App.Remotes.ShieldEquipped
        end
        local remFolder = Services.ReplicatedStorage:FindFirstChild("Remotes")
        return remFolder and remFolder:FindFirstChild("ShieldEquipped") or nil
    end

    function H.pushShieldRemote(wantOn)
        local rem = H.getRiotRemote()
        if wantOn then
            if S.LastShieldRemoteSent ~= true then
                if rem then pcall(function() rem:FireServer(true) end) end
                S.LastShieldRemoteSent = true
            end
        else
            if S.LastShieldRemoteSent == true and rem then
                pcall(function() rem:FireServer(false) end)
            end
            S.LastShieldRemoteSent = false
        end
    end

    -- Always fires FireServer(false) BEFORE clearing LastShieldRemoteSent when exiting active state
    function H.clearShieldRemoteState()
        local rem = H.getRiotRemote()
        if S.LastShieldRemoteSent == true and rem then
            pcall(function() rem:FireServer(false) end)
        end
        S.LastShieldRemoteSent = nil
    end

    function H.getVisualParent()
        local cam = App.GetCamera()
        if cam then return cam end
        return Services.Workspace
    end

    function H.getBarrierSize()
        local sz = tonumber(State.ShieldSize) or 6.5
        local w = H.clamp(sz * 0.72, 2.8, 8.2)
        local h = H.clamp(sz * 0.84, 3.8, 9.0)
        return Vector3.new(w, h, 0.14)
    end

    function H.getBarrierCFrame(hrp)
        return hrp.CFrame * CFrame.new(0, 0.15, -2.1)
    end

    function H.isAnyTaseAnimPlaying(hum)
        if not hum then return false end
        local animator = hum:FindFirstChildOfClass("Animator") or hum
        local ok, res = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if not ok or type(res) ~= "table" then return false end
        for _, tr in ipairs(res) do
            local anim = tr and tr.Animation
            local aid = anim and tostring(anim.AnimationId) or ""
            if aid:find("279227693", 1, true) or aid:find("279229192", 1, true) then
                return true
            end
        end
        return false
    end

    function H.recordPriorMoveStats(hum)
        if not hum or hum.Health <= 0 or hum.PlatformStand or hum.Sit then return end
        if H.isAnyTaseAnimPlaying(hum) then return end
        if hum.WalkSpeed > 0.5 then
            S.SavedWalkSpeed = hum.WalkSpeed
        end
        if hum.JumpHeight and hum.JumpHeight > 0.5 then
            S.SavedJumpHeight = hum.JumpHeight
        end
        if hum.JumpPower and hum.JumpPower > 0.5 then
            S.SavedJumpPower = hum.JumpPower
        end
    end

    function H.raySegmentHitsOBB(p0, p1, halfExt)
        local dir = p1 - p0
        local tMin = 0
        local tMax = 1
        local hitAxis = 0
        local hitSign = 0

        local axes = {
            { p0.X, dir.X, halfExt.X, 1 },
            { p0.Y, dir.Y, halfExt.Y, 2 },
            { p0.Z, dir.Z, halfExt.Z, 3 },
        }

        for _, a in ipairs(axes) do
            local o, d, ext = a[1], a[2], a[3]
            if math.abs(d) < 1e-6 then
                if o < -ext or o > ext then
                    return false, nil, nil, nil
                end
            else
                local invD = 1 / d
                local t1 = (-ext - o) * invD
                local t2 = (ext - o) * invD
                local sgn = -1
                if t1 > t2 then
                    t1, t2 = t2, t1
                    sgn = 1
                end
                if t1 > tMin then
                    tMin = t1
                    hitAxis = a[4]
                    hitSign = sgn
                end
                if t2 < tMax then tMax = t2 end
                if tMin > tMax then
                    return false, nil, nil, nil
                end
            end
        end

        if tMin < 0 or tMin > 1 then
            return false, nil, nil, nil
        end

        local localHit = p0 + dir * tMin
        local norm = Vector3.new(0, 0, -1)
        if hitAxis == 1 then
            norm = Vector3.new(hitSign, 0, 0)
        elseif hitAxis == 2 then
            norm = Vector3.new(0, hitSign, 0)
        elseif hitAxis == 3 then
            norm = Vector3.new(0, 0, hitSign)
        end
        return true, tMin, localHit, norm
    end

    function H.cleanupFEInvisConns()
        for i = #S.FEInvisConns, 1, -1 do
            local c = S.FEInvisConns[i]
            pcall(function() c:Disconnect() end)
            S.FEInvisConns[i] = nil
        end
    end

    function H.restoreFEInvisParts()
        for part, origMod in pairs(S.FEInvisParts) do
            if part and part.Parent then
                pcall(function() part.LocalTransparencyModifier = origMod end)
            end
            S.FEInvisParts[part] = nil
        end
    end

    function H.applyGhostTransparency(char)
        if not char then return end
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name ~= "HumanoidRootPart" then
                if S.FEInvisParts[desc] == nil then
                    S.FEInvisParts[desc] = desc.LocalTransparencyModifier or 0
                end
                desc.LocalTransparencyModifier = 0.55
            end
        end
    end

    S.InStateKey = S.InStateKey or {}

    function H.notifyShieldChange(reasonKey, val)
        if reasonKey and S.FromOnStateChanged == reasonKey then
            reasonKey = "ShieldState"
        end
        Bus.Emit("StateChanged", reasonKey or "ShieldState", val, nil, true)
    end

    local Shield = {}

    function Shield.HasEquippedRiotShield()
        local char = App.GetChar(App.LocalPlayer)
        if not char then return false end
        if char:FindFirstChild("Riot Shield") then return true end
        if char:FindFirstChild("RiotShield") then return true end
        if char:FindFirstChild("RiotShieldPart") then return true end
        return false
    end

    function Shield.HasOwnedRiotShield()
        if Shield.HasEquippedRiotShield() then return true end
        local lp = App.LocalPlayer
        local bp = lp and lp:FindFirstChildOfClass("Backpack")
        if bp then
            if bp:FindFirstChild("Riot Shield") or bp:FindFirstChild("RiotShield") then
                return true
            end
        end
        return false
    end

    function Shield.GetStatus()
        local eq = Shield.HasEquippedRiotShield()
        local owned = Shield.HasOwnedRiotShield()
        local hp = S.ShieldHP
        if eq then
            local gameHP = H.readGameShieldHP()
            if gameHP then hp = gameHP end
        end
        local mode = State.ShieldMode or "Hybrid"
        local label = "OFF"
        if State.ShieldEnabled then
            if mode == "Hybrid" then
                label = eq and "HYB:RIOT" or "HYB:DSYNC"
            elseif mode == "RiotOnly" then
                label = eq and "RIOT:ON" or "RIOT:WAIT"
            elseif mode == "DesyncBox" then
                label = "DSYNC"
            elseif mode == "FEGhost" then
                label = "FEGHOST"
            else
                label = tostring(mode)
            end
        elseif State.FEInvisible or S.FEInvisActive then
            label = "FEGHOST"
        end
        return eq, owned, hp, label
    end

    function Shield.ShouldDesyncNow()
        if not App.Running or not State.ShieldEnabled then return false end
        local char = App.GetChar(App.LocalPlayer)
        local hum = App.GetHum(char)
        local hrp = App.GetRoot(char)
        if not hum or hum.Health <= 0 or not hrp or hum.Sit then return false end

        local mode = State.ShieldMode or "Hybrid"
        local wantsDesync = false
        if mode == "DesyncBox" then
            wantsDesync = true
        elseif mode == "Hybrid" then
            wantsDesync = not Shield.HasEquippedRiotShield()
        end
        if not wantsDesync then return false end

        if State.RagebotPeekShield and App.Combat and App.Combat.GunHook then
            local lastShot = App.Combat.GunHook.LastRageShotClock or 0
            if lastShot > 0 and (os.clock() - lastShot) < 0.11 then
                return false
            end
        end
        return S.ShieldHP > 0
    end

    function Shield.GetBarrierInstance()
        return S.ShieldPart
    end

    function Shield.GetRealPosition(hrp)
        if S.DesyncActive and S.SavedPosition then
            return S.SavedPosition
        end
        return hrp and hrp.CFrame or nil
    end

    function Shield.ResetDesyncForTeleport()
        S.DesyncActive = false
        S.SavedPosition = nil
    end

    function Shield.EnsureVisual(hrp)
        if not hrp or not hrp.Parent then return end
        local targetSize = H.getBarrierSize()
        local targetTrans = H.clamp(tonumber(State.ShieldTransparency) or 0.84, 0.45, 0.95)
        local targetCF = H.getBarrierCFrame(hrp)

        if S.ShieldPart and S.ShieldPart.Parent then
            S.ShieldPart.CFrame = targetCF
            if not S.VisualAnimBusy then
                S.ShieldPart.Size = targetSize
                S.ShieldPart.Transparency = targetTrans
            end
            if S.ShieldRimPart and S.ShieldRimPart.Parent then
                S.ShieldRimPart.CFrame = targetCF * CFrame.new(0, 0, -0.02)
                if not S.VisualAnimBusy then
                    S.ShieldRimPart.Size = Vector3.new(targetSize.X + 0.14, 0.09, 0.18)
                end
            end
            return
        end

        local parentInst = H.getVisualParent()
        local barrier = Instance.new("Part")
        barrier.Name = "KX_HoloShieldBarrier"
        barrier.Anchored = true
        barrier.CanCollide = false
        barrier.CanTouch = false
        barrier.CanQuery = false
        barrier.CastShadow = false
        barrier.Massless = true
        barrier.Material = Enum.Material.ForceField
        barrier.Color = Palette.ElectricBlue
        barrier.Size = Vector3.new(targetSize.X * 0.25, targetSize.Y * 0.25, 0.1)
        barrier.Transparency = 1
        barrier.CFrame = targetCF
        barrier.Parent = parentInst
        Janitor.Track(barrier)

        local rim = Instance.new("Part")
        rim.Name = "KX_HoloShieldRim"
        rim.Anchored = true
        rim.CanCollide = false
        rim.CanTouch = false
        rim.CanQuery = false
        rim.CastShadow = false
        rim.Massless = true
        rim.Material = Enum.Material.Neon
        rim.Color = Palette.NeonBlue
        rim.Size = Vector3.new(targetSize.X * 0.25, 0.08, 0.16)
        rim.Transparency = 1
        rim.CFrame = targetCF * CFrame.new(0, 0, -0.02)
        rim.Parent = barrier

        S.ShieldPart = barrier
        S.ShieldRimPart = rim
        S.VisualAnimBusy = true

        if App.Running and App.Anim and App.Anim.Play then
            local presets = App.Anim.Presets
            App.Anim.Play(barrier, "HoloShield", presets and presets.Spring or nil, {
                Size = targetSize,
                Transparency = targetTrans,
            }, function()
                S.VisualAnimBusy = false
            end)
            App.Anim.Play(rim, "HoloShieldRim", presets and presets.Spring or nil, {
                Size = Vector3.new(targetSize.X + 0.14, 0.09, 0.18),
                Transparency = 0.68,
            })
        else
            barrier.Size = targetSize
            barrier.Transparency = targetTrans
            rim.Size = Vector3.new(targetSize.X + 0.14, 0.09, 0.18)
            rim.Transparency = 0.68
            S.VisualAnimBusy = false
        end

        if App.Combat and App.Combat.UpdateCastRayFilter then
            pcall(App.Combat.UpdateCastRayFilter)
        end
    end

    function Shield.DestroyVisual()
        local barrier = S.ShieldPart
        local rim = S.ShieldRimPart
        S.ShieldPart = nil
        S.ShieldRimPart = nil
        S.VisualAnimBusy = false

        if barrier and barrier.Parent then
            if App.Running and App.Anim and App.Anim.Play then
                local presets = App.Anim.Presets
                if rim and rim.Parent then
                    App.Anim.Play(rim, "HoloShieldRim", presets and presets.Exit or nil, { Transparency = 1 })
                end
                local tw = App.Anim.Play(barrier, "HoloShield", presets and presets.Exit or nil, {
                    Transparency = 1,
                    Size = Vector3.new(0.2, 0.2, 0.05),
                }, function()
                    if barrier and barrier.Parent then pcall(function() barrier:Destroy() end) end
                    if App.Combat and App.Combat.UpdateCastRayFilter then
                        pcall(App.Combat.UpdateCastRayFilter)
                    end
                end)
                if not tw then
                    pcall(function() barrier:Destroy() end)
                    if App.Combat and App.Combat.UpdateCastRayFilter then
                        pcall(App.Combat.UpdateCastRayFilter)
                    end
                end
            else
                pcall(function() barrier:Destroy() end)
                if App.Combat and App.Combat.UpdateCastRayFilter then
                    pcall(App.Combat.UpdateCastRayFilter)
                end
            end
        end
    end

    function Shield.RegisterBlockedHit(dmgEstimate, hitPos, normal)
        if S.ShieldHP <= 0 then return false end
        local dmg = math.max(1, tonumber(dmgEstimate) or 14)
        S.ShieldHP = math.max(0, S.ShieldHP - dmg)
        S.LastHitClock = os.clock()

        if S.ShieldPart and S.ShieldPart.Parent and App.Anim and App.Anim.Play then
            local baseColor = Palette.ElectricBlue
            S.ShieldPart.Color = Palette.NeonCyan or Palette.TextPrimary
            App.Anim.Play(S.ShieldPart, "ShieldFlash", App.Anim.Presets and App.Anim.Presets.Flash or nil, {
                Color = baseColor,
            })
        end

        if State.ShieldHitVFX and App.VFX and App.VFX.SpawnShieldBlockEffect then
            pcall(App.VFX.SpawnShieldBlockEffect, hitPos, normal)
        end
        Bus.Emit("ShieldHit", dmg, S.ShieldHP, hitPos)

        if S.ShieldHP <= 0 and (os.clock() - S.LastDepletedAlertClock) > 5 then
            S.LastDepletedAlertClock = os.clock()
            Bus.Emit("Alert", "Shield", "Holo shield depleted — recharging out of combat", "warn")
        end
        return true
    end

    function Shield.TryInterceptIncomingRay(origin, hitPos)
        if not origin or not hitPos then return false, nil, nil end
        local active = State.ShieldEnabled or Shield.HasEquippedRiotShield()
        if not active or S.ShieldHP <= 0 then return false, nil, nil end

        local char = App.GetChar(App.LocalPlayer)
        local hrp = App.GetRoot(char)
        if not hrp then return false, nil, nil end

        local cf
        local halfExt
        if S.ShieldPart and S.ShieldPart.Parent then
            cf = S.ShieldPart.CFrame
            local sz = S.ShieldPart.Size
            halfExt = Vector3.new(sz.X * 0.5, sz.Y * 0.5, math.max(0.85, sz.Z * 0.5))
        else
            cf = H.getBarrierCFrame(hrp)
            local sz = H.getBarrierSize()
            halfExt = Vector3.new(sz.X * 0.5, sz.Y * 0.5, 0.85)
        end

        if (State.ShieldMode or "Hybrid") == "DesyncBox" then
            cf = hrp.CFrame
            local rad = math.max(3.0, (tonumber(State.ShieldSize) or 6.5) * 0.5)
            halfExt = Vector3.new(rad, math.max(3.6, rad), rad)
        end

        local p0 = cf:PointToObjectSpace(origin)
        local p1 = cf:PointToObjectSpace(hitPos)
        local hit, _, localHit, localNorm = H.raySegmentHitsOBB(p0, p1, halfExt)
        if not hit then return false, nil, nil end

        local worldHit = cf:PointToWorldSpace(localHit)
        local worldNorm = cf:VectorToWorldSpace(localNorm)
        Shield.RegisterBlockedHit(14, worldHit, worldNorm)
        return true, worldHit, worldNorm
    end

    function Shield.StartFEInvisible(sourceTag)
        local char = App.GetChar(App.LocalPlayer)
        local hum = App.GetHum(char)
        if not char or not hum or hum.Health <= 0 then return false end

        local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
        local animId = isR15 and "rbxassetid://18665825805" or "rbxassetid://215384594"
        local timePos = isR15 and 1.95 or 0.4

        if S.FEInvisActive and S.FEInvisChar == char and S.FEInvisTrack then
            S.FEInvisSource = sourceTag or S.FEInvisSource or "toggle"
            H.applyGhostTransparency(char)
            return true
        end

        Shield.StopFEInvisible(true)
        S.FEInvisActive = true
        S.FEInvisSource = sourceTag or "toggle"
        S.FEInvisChar = char
        S.FEInvisTimePos = timePos

        local anim = Instance.new("Animation")
        anim.Name = "KX_FEGhostAnim"
        anim.AnimationId = animId
        S.FEInvisAnim = anim

        local ok, track = pcall(function()
            local animator = hum:FindFirstChildOfClass("Animator") or hum
            return animator:LoadAnimation(anim)
        end)

        if ok and track then
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Action4
            pcall(function()
                track:Play(0.05, 1, 0)
                track.TimePosition = timePos
                track:AdjustSpeed(0)
            end)
            S.FEInvisTrack = track
        end

        H.applyGhostTransparency(char)
        local ca = char.DescendantAdded:Connect(function(inst)
            if S.FEInvisActive and inst:IsA("BasePart") and inst.Name ~= "HumanoidRootPart" then
                S.FEInvisParts[inst] = inst.LocalTransparencyModifier or 0
                inst.LocalTransparencyModifier = 0.55
            end
        end)
        table.insert(S.FEInvisConns, ca)
        H.notifyShieldChange("FEInvisible", true)
        return true
    end

    function Shield.StopFEInvisible(silent)
        local wasActive = S.FEInvisActive
        S.FEInvisActive = false
        S.FEInvisSource = nil
        S.FEInvisChar = nil
        if S.FEInvisTrack then
            pcall(function() S.FEInvisTrack:Stop(0) end)
            S.FEInvisTrack = nil
        end
        if S.FEInvisAnim then
            pcall(function() S.FEInvisAnim:Destroy() end)
            S.FEInvisAnim = nil
        end
        H.cleanupFEInvisConns()
        H.restoreFEInvisParts()
        if wasActive and not silent then
            H.notifyShieldChange("FEInvisible", false)
        end
    end

    function Shield.SetFEInvisible(on)
        if S.InStateKey.FEInvisible then return end
        S.InStateKey.FEInvisible = true
        local ok, err = pcall(function()
            local want = (on == true)
            if State.FEInvisible ~= want then
                App.SetState("FEInvisible", want, true, true)
            end
            if want then
                Shield.StartFEInvisible("toggle")
            elseif not (State.ShieldEnabled and State.ShieldMode == "FEGhost") then
                Shield.StopFEInvisible(false)
            end
        end)
        S.InStateKey.FEInvisible = nil
        if not ok then error(err) end
    end

    function Shield.SetEnabled(on)
        if S.InStateKey.ShieldEnabled then return end
        S.InStateKey.ShieldEnabled = true
        local ok, err = pcall(function()
            local want = (on == true)
            if State.ShieldEnabled ~= want then
                App.SetState("ShieldEnabled", want, true, true)
            end
            if want then
                if S.ShieldHP <= 0 then
                    S.ShieldHP = S.MaxShieldHP
                end
                local mode = State.ShieldMode or "Hybrid"
                if mode == "RiotOnly" and not Shield.HasOwnedRiotShield() then
                    local now = os.clock()
                    if (now - S.LastRiotAlertClock) > 4 then
                        S.LastRiotAlertClock = now
                        Bus.Emit("Alert", "Shield", "RiotOnly selected without a Riot Shield in inventory — grab one at Armory or use Hybrid/DesyncBox", "warn")
                    end
                elseif mode == "FEGhost" then
                    Shield.StartFEInvisible("mode")
                end
            else
                H.clearShieldRemoteState()
                Shield.DestroyVisual()
                if S.DesyncActive and S.SavedPosition then
                    local hrp = App.GetRoot(App.GetChar(App.LocalPlayer))
                    if hrp then pcall(function() hrp.CFrame = S.SavedPosition end) end
                end
                S.DesyncActive = false
                S.SavedPosition = nil
                if S.FEInvisSource == "mode" and not State.FEInvisible then
                    Shield.StopFEInvisible(false)
                end
            end
            H.notifyShieldChange("ShieldEnabled", want)
        end)
        S.InStateKey.ShieldEnabled = nil
        if not ok then error(err) end
    end

    function Shield.SetMode(mode)
        if S.InStateKey.ShieldMode then return end
        local valid = (mode == "Hybrid" or mode == "RiotOnly" or mode == "DesyncBox" or mode == "FEGhost")
        if not valid then return end
        S.InStateKey.ShieldMode = true
        local ok, err = pcall(function()
            if State.ShieldMode ~= mode then
                App.SetState("ShieldMode", mode, true, true)
            end
            if mode ~= "Hybrid" and mode ~= "RiotOnly" then
                H.clearShieldRemoteState()
            end
            if State.ShieldEnabled then
                if mode == "RiotOnly" and not Shield.HasOwnedRiotShield() then
                    Bus.Emit("Alert", "Shield", "RiotOnly selected without a Riot Shield — grab one at Armory or switch to Hybrid", "warn")
                end
                if mode == "FEGhost" then
                    Shield.DestroyVisual()
                    Shield.StartFEInvisible("mode")
                elseif S.FEInvisSource == "mode" and not State.FEInvisible then
                    Shield.StopFEInvisible(false)
                end
            end
            H.notifyShieldChange("ShieldMode", mode)
        end)
        S.InStateKey.ShieldMode = nil
        if not ok then error(err) end
    end

    function Shield.NotifyShieldStateChanged()
        H.notifyShieldChange("ShieldState", State.ShieldEnabled)
    end

    function Shield.PurgeTaseAndRagdoll()
        local lp = App.LocalPlayer
        if lp then
            pcall(function()
                if lp:GetAttribute("BackpackEnabled") == false then
                    lp:SetAttribute("BackpackEnabled", true)
                end
            end)
        end
        local char = App.GetChar(lp)
        local hum = App.GetHum(char)
        local hrp = App.GetRoot(char)
        if not char or not hum or hum.Health <= 0 then return end

        H.recordPriorMoveStats(hum)
        local inVehicleSeat = (hum.SeatPart and hum.SeatPart:IsA("VehicleSeat")) or false
        if hum.PlatformStand then hum.PlatformStand = false end
        if hum.Sit and not inVehicleSeat then hum.Sit = false end

        local animator = hum:FindFirstChildOfClass("Animator") or hum
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if ok and type(tracks) == "table" then
            for _, tr in ipairs(tracks) do
                local anim = tr and tr.Animation
                local aid = anim and tostring(anim.AnimationId) or ""
                if aid:find("279227693", 1, true) or aid:find("279229192", 1, true) then
                    pcall(function() tr:Stop(0) end)
                end
            end
        end

        if hum.WalkSpeed < 1 then
            local targetWS = S.SavedWalkSpeed
            if State.MaxSpeed and State.SpeedMode == "Custom" then
                targetWS = tonumber(State.WalkSpeed) or targetWS
            elseif not targetWS or targetWS < 8 then
                targetWS = 16
            end
            hum.WalkSpeed = targetWS
        end
        if hum.JumpHeight and hum.JumpHeight < 0.5 then
            hum.JumpHeight = (S.SavedJumpHeight and S.SavedJumpHeight > 0.5) and S.SavedJumpHeight or 7.2
        end
        if hum.JumpPower and hum.JumpPower < 1 then
            local targetJP = State.JumpPowerEnabled and (tonumber(State.JumpPower) or 50) or S.SavedJumpPower
            hum.JumpPower = (targetJP and targetJP > 1) and targetJP or 50
        end

        if hrp then
            for _, child in ipairs(hrp:GetChildren()) do
                if (child:IsA("BodyVelocity") or child:IsA("BodyGyro")) and child.Name:sub(1, 3) ~= "KX_" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end

    function Shield.RestoreAntiTaze()
        S.AntiTazeInstalled = false
        if S.AntiTazeConn then
            pcall(function() S.AntiTazeConn:Disconnect() end)
            S.AntiTazeConn = nil
        end
        if type(S.HookedRemotePairs) == "table" and App.RestoreFn then
            for i = #S.HookedRemotePairs, 1, -1 do
                local pair = S.HookedRemotePairs[i]
                S.HookedRemotePairs[i] = nil
                pcall(App.RestoreFn, pair.fn, pair.orig)
                if pair.conn then
                    pair.conn._kxHooked = nil
                end
            end
        end
        if type(S.DisabledRemoteConns) == "table" then
            for i = #S.DisabledRemoteConns, 1, -1 do
                local c = S.DisabledRemoteConns[i]
                S.DisabledRemoteConns[i] = nil
                if c and c.Enable then
                    pcall(function() c:Enable() end)
                end
            end
        end
    end

    function Shield.InstallAntiTaze()
        if S.AntiTazeInstalled then return end
        S.AntiTazeInstalled = true
        S.HookedRemotePairs = S.HookedRemotePairs or {}
        S.DisabledRemoteConns = S.DisabledRemoteConns or {}

        local remFolder = Services.ReplicatedStorage:FindFirstChild("Remotes")
        local pt = (App.Remotes and App.Remotes.PlayerTased) or (remFolder and remFolder:FindFirstChild("PlayerTased"))
        local getconns = H.getGetConnections()

        -- Hook existing remote connections FIRST before adding our own fallback listener!
        if pt and getconns then
            local ok, conns = pcall(getconns, pt.OnClientEvent)
            if ok and type(conns) == "table" then
                for _, conn in ipairs(conns) do
                    local fn = conn and conn.Function
                    if fn and App.HookFn and not conn._kxHooked then
                        local origFn
                        origFn = App.HookFn(fn, function(...)
                            if App.Running and State.AntiTaze then
                                local hum = App.GetHum(App.GetChar(App.LocalPlayer))
                                H.recordPriorMoveStats(hum)
                                return nil
                            end
                            if origFn then return origFn(...) end
                            return nil
                        end)
                        if origFn then
                            conn._kxHooked = true
                            table.insert(S.HookedRemotePairs, { fn = fn, orig = origFn, conn = conn })
                        end
                    elseif conn and conn.Disable and not conn._kxHooked then
                        pcall(function() conn:Disable() end)
                        table.insert(S.DisabledRemoteConns, conn)
                    end
                end
            end
        end

        if pt then
            S.AntiTazeConn = Janitor.Add(pt.OnClientEvent:Connect(function()
                if App.Running and State.AntiTaze then
                    Shield.PurgeTaseAndRagdoll()
                end
            end))
        end

        local ca = remFolder and remFolder:FindFirstChild("ClientArrested")
        if ca and getconns then
            local ok2, conns2 = pcall(getconns, ca.OnClientEvent)
            if ok2 and type(conns2) == "table" then
                for _, conn in ipairs(conns2) do
                    local fn = conn and conn.Function
                    if fn and App.HookFn and not conn._kxHooked then
                        local orig
                        orig = App.HookFn(fn, function(...)
                            if App.Running and State.AntiArrest then return nil end
                            if orig then return orig(...) end
                            return nil
                        end)
                        if orig then
                            conn._kxHooked = true
                            table.insert(S.HookedRemotePairs, { fn = fn, orig = orig, conn = conn })
                        end
                    end
                end
            end
        end
    end

    function Shield.BypassClientAntiNoclip(char, enable)
        if type(char) == "boolean" then
            enable = char
            char = nil
        end
        if enable == nil then enable = State.AntiNoclipBypass end
        if not enable then
            if char then
                local saved = S.SavedHeadConns[char]
                if saved then
                    for _, c in ipairs(saved) do
                        if c and c.Enable then pcall(function() c:Enable() end) end
                    end
                    S.SavedHeadConns[char] = nil
                end
            else
                for ch, saved in pairs(S.SavedHeadConns) do
                    for _, c in ipairs(saved) do
                        if c and c.Enable then pcall(function() c:Enable() end) end
                    end
                    S.SavedHeadConns[ch] = nil
                end
            end
            return
        end

        char = char or App.GetChar(App.LocalPlayer)
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end

        local saved = S.SavedHeadConns[char]
        if saved then return end
        local getconns = H.getGetConnections()
        if not getconns then return end
        local list = {}
        local ok, conns = pcall(getconns, head:GetPropertyChangedSignal("CanCollide"))
        if ok and type(conns) == "table" then
            for _, c in ipairs(conns) do
                if c and c.Disable then
                    pcall(function() c:Disable() end)
                    table.insert(list, c)
                end
            end
        end
        S.SavedHeadConns[char] = list
    end

    function Shield.BypassAntiJump(char, enable)
        if type(char) == "boolean" then
            enable = char
            char = nil
        end
        if enable == nil then enable = State.AntiJumpCooldown end
        if not enable then
            if char then
                local existing = S.AntiJumpCleanups[char]
                if existing then
                    pcall(existing)
                    S.AntiJumpCleanups[char] = nil
                end
            else
                for ch, existing in pairs(S.AntiJumpCleanups) do
                    pcall(existing)
                    S.AntiJumpCleanups[ch] = nil
                end
            end
            return
        end

        char = char or App.GetChar(App.LocalPlayer)
        if not char then return end
        local existing = S.AntiJumpCleanups[char]
        if existing then return end
        local hum = App.GetHum(char)
        if not hum then return end

        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
        local c1 = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if State.AntiJumpCooldown and hum.JumpPower < 5 then
                hum.JumpPower = State.JumpPowerEnabled and (tonumber(State.JumpPower) or 50) or 50
            end
        end)
        local c2 = hum.StateChanged:Connect(function(_, newState)
            if State.AntiJumpCooldown and newState == Enum.HumanoidStateType.Landed then
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
            end
        end)
        S.AntiJumpCleanups[char] = function()
            pcall(function() c1:Disconnect() end)
            pcall(function() c2:Disconnect() end)
        end
    end

    function Shield.StepAntiInvisible()
        if not State.AntiInvisible then return end
        local lp = App.LocalPlayer
        local now = os.clock()
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= lp then
                local char = App.GetChar(plr)
                local hum = App.GetHum(char)
                if char and hum and hum.Health > 0 then
                    local animator = hum:FindFirstChildOfClass("Animator") or hum
                    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
                    if ok and type(tracks) == "table" then
                        for _, tr in ipairs(tracks) do
                            local anim = tr and tr.Animation
                            local aid = anim and tostring(anim.AnimationId) or ""
                            local isTase = aid:find("279227693", 1, true) or aid:find("279229192", 1, true)
                            local knownBad = aid:find("18665825805", 1, true)
                                or aid:find("215384594", 1, true)
                                or aid:find("181525546", 1, true)
                                or aid:find("181526230", 1, true)
                                or aid:find("182789003", 1, true)
                            local frozenMove = (not isTase) and (tr.Speed == 0 and tr.TimePosition > 0.2 and hum.MoveDirection.Magnitude > 0.15)
                            if knownBad or frozenMove then
                                pcall(function()
                                    tr:AdjustWeight(0, 0)
                                    tr:Stop(0)
                                end)
                                local prevWarn = S.AntiInvisWarnClock[plr] or 0
                                if State.CheaterAlerts and (now - prevWarn) > 10 then
                                    S.AntiInvisWarnClock[plr] = now
                                    Bus.Emit("Alert", plr.Name, "Stripped FE-Invisible animation exploit", "warn")
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    function Shield.CleanCharacterEffects()
        S.DesyncActive = false
        S.SavedPosition = nil
        S.SpoofedCFrame = nil
        S.LastShieldRemoteSent = nil
        S.ShieldHP = S.MaxShieldHP
        Shield.DestroyVisual()
        if S.FEInvisActive then
            Shield.StopFEInvisible(true)
        end
    end

    function Shield.StepRenderDesync(hrp)
        if S.DesyncActive and S.SavedPosition and hrp and hrp.Parent then
            hrp.CFrame = S.SavedPosition
            S.DesyncActive = false
            S.SavedPosition = nil
        end
    end

    function Shield.StepHeartbeatShield(hrp, dt)
        local char = App.GetChar(App.LocalPlayer)
        local hum = App.GetHum(char)
        if hum then H.recordPriorMoveStats(hum) end

        if S.FEInvisActive then
            if char ~= S.FEInvisChar or not hum or hum.Health <= 0 then
                Shield.StopFEInvisible(true)
            elseif S.FEInvisTrack then
                pcall(function()
                    if not S.FEInvisTrack.IsPlaying then S.FEInvisTrack:Play(0, 1, 0) end
                    S.FEInvisTrack:AdjustSpeed(0)
                    S.FEInvisTrack.TimePosition = S.FEInvisTimePos
                end)
            end
        elseif State.FEInvisible and char and hum and hum.Health > 0 then
            Shield.StartFEInvisible("toggle")
        end

        if not State.ShieldEnabled or not hrp or not hum or hum.Health <= 0 then
            Shield.DestroyVisual()
            return
        end

        local now = os.clock()
        if (now - S.LastHitClock) >= 2.5 and S.ShieldHP < S.MaxShieldHP then
            S.ShieldHP = math.min(S.MaxShieldHP, S.ShieldHP + 28 * (dt or 0.016))
        end

        local mode = State.ShieldMode or "Hybrid"
        if mode == "FEGhost" then
            Shield.DestroyVisual()
            if not S.FEInvisActive then Shield.StartFEInvisible("mode") end
            H.pushShieldRemote(false)
            return
        end

        if (mode == "Hybrid" or mode == "RiotOnly") and State.ShieldAutoEquip then
            if not Shield.HasEquippedRiotShield() and Shield.HasOwnedRiotShield() then
                local lp = App.LocalPlayer
                local bp = lp and lp:FindFirstChildOfClass("Backpack")
                local riot = bp and (bp:FindFirstChild("Riot Shield") or bp:FindFirstChild("RiotShield"))
                if riot and App.ToolArbiter and App.ToolArbiter.TryEquip then
                    local prio = (App.ToolArbiter.Priority and App.ToolArbiter.Priority.IdleShield) or 1
                    App.ToolArbiter.TryEquip(riot, prio, "ShieldAutoEquip", 0.4)
                end
            end
        end

        local eq = Shield.HasEquippedRiotShield()
        H.pushShieldRemote(eq and (mode == "Hybrid" or mode == "RiotOnly"))

        if not Shield.ShouldDesyncNow() then
            if State.ShieldAutoFaceShooter and App.Targets and App.Targets.GetBestTarget then
                local best = App.Targets.GetBestTarget({ use360 = true, wallcheck = false, range = 90 })
                local part = (type(best) == "table" and best.part) or nil
                if part and part.Parent and not State.ShieldSpinBlock then
                    local p = part.Position
                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(p.X, hrp.Position.Y, p.Z))
                end
            end
            if State.ShieldSpinBlock then
                local spd = tonumber(State.ShieldSpinSpeed) or 16
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, spd * (dt or 0.016), 0)
            end
            if eq or S.ShieldHP > 0 then
                Shield.EnsureVisual(hrp)
            else
                Shield.DestroyVisual()
            end
            return
        end

        Shield.EnsureVisual(hrp)
        local rad = H.clamp(tonumber(State.DesyncJitterRadius) or 3.2, 0.8, 8.0)
        S.DesyncJitterAngle = (S.DesyncJitterAngle + 2.35) % (math.pi * 2)
        local ox = math.cos(S.DesyncJitterAngle) * rad
        local oz = math.sin(S.DesyncJitterAngle) * rad
        local oy = ((S.DesyncJitterAngle % 1.0) > 0.5) and 0.45 or -0.35

        S.SavedPosition = hrp.CFrame
        S.SpoofedCFrame = S.SavedPosition + Vector3.new(ox, oy, oz)
        if State.ShieldSpinBlock then
            local spd = tonumber(State.ShieldSpinSpeed) or 16
            S.SpoofedCFrame = S.SpoofedCFrame * CFrame.Angles(0, S.DesyncJitterAngle * (spd * 0.1), 0)
        end
        S.DesyncActive = true
        hrp.CFrame = S.SpoofedCFrame
    end

    App.Shield = Shield
end

-- ============================================================================
-- SECTION 2: App.World (Teleports, FenceGodmode, Doors, AntiFling, Vehicles, C4, Pickups)
-- ============================================================================
do
    local TELEPORTS = {
        yard      = CFrame.new(781.2, 98.1, 2456.4),
        nexus     = CFrame.new(888.4, 100.0, 2390.6),
        cafeteria = CFrame.new(902.5, 100.0, 2292.8),
        cells     = CFrame.new(916.2, 100.0, 2442.5),
        armory    = CFrame.new(835.8, 100.0, 2266.3),
        crimbase  = CFrame.new(-943.7, 94.2, 2056.2),
        roof      = CFrame.new(832.0, 118.9, 2368.0),
        tower     = CFrame.new(822.4, 125.9, 2588.2),
        gate      = CFrame.new(503.6, 102.2, 2248.5),
        sewer     = CFrame.new(917.2, 78.7, 2436.1),
        hideout   = CFrame.new(-975.1, 108.5, 2064.8),
        cars      = CFrame.new(-888.5, 95.3, 2149.4),
        store     = CFrame.new(-423.5, 54.4, 1742.8),
        gas       = CFrame.new(-518.2, 54.4, 1662.4),
        neutral   = CFrame.new(876.0, 27.9, 2351.0),
    }

    local INDOOR_SUBREGIONS = {
        { cx = 924.85, cy = 99.65, cz = 2292.95, hx = 92.60 / 2, hy = 27.60 / 2, hz = 65.40 / 2 },
        { cx = 877.80, cy = 114.95, cz = 2472.70, hx = 93.10 / 2, hy = 30.80 / 2, hz = 83.40 / 2 },
        { cx = 885.40, cy = 99.65, cz = 2389.60, hx = 63.40 / 2, hy = 27.20 / 2, hz = 75.80 / 2 },
        { cx = 939.70, cy = 104.20, cz = 2457.50, hx = 77.50 / 2, hy = 32.00 / 2, hz = 52.20 / 2 },
        { cx = 918.80, cy = 104.20, cz = 2504.30, hx = 36.20 / 2, hy = 32.00 / 2, hz = 41.80 / 2 },
        { cx = 916.20, cy = 99.65, cz = 2443.10, hx = 59.00 / 2, hy = 27.00 / 2, hz = 87.20 / 2 },
        { cx = 834.00, cy = 99.80, cz = 2266.20, hx = 56.00 / 2, hy = 27.00 / 2, hz = 40.00 / 2 },
        { cx = 835.40, cy = 99.80, cz = 2341.00, hx = 54.00 / 2, hy = 27.00 / 2, hz = 105.00 / 2 },
        { cx = 795.50, cy = 99.80, cz = 2274.20, hx = 40.00 / 2, hy = 27.00 / 2, hz = 55.00 / 2 },
        { cx = 798.50, cy = 99.80, cz = 2368.00, hx = 42.00 / 2, hy = 27.00 / 2, hz = 75.00 / 2 },
        { cx = 853.50, cy = 99.80, cz = 2306.00, hx = 32.00 / 2, hy = 27.00 / 2, hz = 42.00 / 2 },
        { cx = 955.00, cy = 99.80, cz = 2368.00, hx = 48.00 / 2, hy = 27.00 / 2, hz = 82.00 / 2 },
        { cx = 983.50, cy = 110.00, cz = 2318.00, hx = 28.00 / 2, hy = 30.00 / 2, hz = 40.00 / 2 },
        { cx = 822.40, cy = 123.00, cz = 2588.20, hx = 22.00 / 2, hy = 24.00 / 2, hz = 22.00 / 2 },
        { cx = 504.00, cy = 102.00, cz = 2248.00, hx = 36.00 / 2, hy = 24.00 / 2, hz = 24.00 / 2 },
        { cx = 640.00, cy = 105.00, cz = 2588.00, hx = 22.00 / 2, hy = 24.00 / 2, hz = 22.00 / 2 },
        { cx = 640.00, cy = 105.00, cz = 2070.00, hx = 22.00 / 2, hy = 24.00 / 2, hz = 22.00 / 2 },
        { cx = 1044.00, cy = 105.00, cz = 2588.00, hx = 22.00 / 2, hy = 24.00 / 2, hz = 22.00 / 2 },
        { cx = 1044.00, cy = 105.00, cz = 2070.00, hx = 22.00 / 2, hy = 24.00 / 2, hz = 22.00 / 2 },
        { cx = -943.70, cy = 96.00, cz = 2056.20, hx = 78.00 / 2, hy = 26.00 / 2, hz = 78.00 / 2 },
    }
    local PRISON_OUTER_BOX = { cx = 773.62, cz = 2327.43, hx = 563.37 / 2, hz = 540.30 / 2 }

    local S = {
        FenceConns = {},
        FenceRestore = setmetatable({}, { __mode = "k" }),
        DoorConns = {},
        DoorRestore = setmetatable({}, { __mode = "k" }),
        AntiFlingConns = {},
        AntiFlingRestore = setmetatable({}, { __mode = "k" }),
        PlayerFlingRestore = setmetatable({}, { __mode = "k" }),
        NoclipRestore = setmetatable({}, { __mode = "k" }),
        VehSpeedRestore = setmetatable({}, { __mode = "k" }),
        FlyBV = nil,
        FlyBG = nil,
        VehFlyBV = nil,
        VehFlyBG = nil,
        LastSpeedSeat = nil,
        CarSpawnBusy = false,
        C4HostileTicks = setmetatable({}, { __mode = "k" }),
        C4DetonateLock = false,
        LastC4DetonateClock = -999,
        LastAutoHealClock = -999,
        LastPickupClock = -999,
        PickupCooldowns = setmetatable({}, { __mode = "k" }),
        LastVehFlingClock = -999,
        CachedCrimSpawn = nil,
        WasFlying = false,
    }

    local World = {}
    World.TeleportLocations = TELEPORTS
    App.MobileFlyInput = App.MobileFlyInput or { Up = 0, Down = 0 }
    World.MobileFlyInput = App.MobileFlyInput

    local H = {}

    function H.clamp(x, lo, hi)
        if x < lo then return lo end
        if x > hi then return hi end
        return x
    end

    function H.clearConns(list)
        for i = #list, 1, -1 do
            pcall(function() list[i]:Disconnect() end)
            list[i] = nil
        end
    end

    function H.applyFencePart(inst)
        if not State.FenceGodmode then return end
        if inst:IsA("BasePart") then
            if S.FenceRestore[inst] == nil then
                S.FenceRestore[inst] = { CanTouch = inst.CanTouch, CanCollide = inst.CanCollide }
            end
            inst.CanTouch = false
            local nl = inst.Name:lower()
            if nl:find("barbed", 1, true) or nl:find("damage", 1, true) or nl:find("kill", 1, true) then
                inst.CanCollide = false
            end
        elseif inst:IsA("TouchTransmitter") and inst.Parent and inst.Parent:IsA("BasePart") then
            local p = inst.Parent
            if S.FenceRestore[p] == nil then
                S.FenceRestore[p] = { CanTouch = p.CanTouch, CanCollide = p.CanCollide }
            end
            p.CanTouch = false
        end
    end

    function H.applyDoorPart(inst)
        if not State.OpenAllDoors then return end
        if inst:IsA("BasePart") then
            if S.DoorRestore[inst] == nil then
                S.DoorRestore[inst] = {
                    CanCollide = inst.CanCollide,
                    Transparency = inst.Transparency,
                    CanQuery = inst.CanQuery,
                }
            end
            inst.CanCollide = false
            inst.CanQuery = false
            -- Never turn invisible colliders (Transparency == 1) opaque!
            local origT = S.DoorRestore[inst].Transparency
            if origT < 0.9 then
                inst.Transparency = math.max(origT, 0.72)
            end
        end
    end

    function H.applyAntiFlingPart(inst, ownVehicle)
        if not State.AntiFling then return end
        if not inst:IsA("BasePart") then return end
        if ownVehicle and inst:IsDescendantOf(ownVehicle) then return end
        if inst.CollisionGroup == "Wheels" then return end
        if S.AntiFlingRestore[inst] == nil then
            S.AntiFlingRestore[inst] = { CanCollide = inst.CanCollide, CanQuery = inst.CanQuery }
        end
        inst.CanCollide = false
        inst.CanQuery = false
    end

    function H.getOwnVehicle()
        local hum = App.GetHum(App.GetChar(App.LocalPlayer))
        local seat = hum and hum.SeatPart
        if seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then
            return seat:FindFirstAncestorOfClass("Model") or seat.Parent
        end
        return nil
    end

    function H.destroyBodyMover(nameKey)
        local m = S[nameKey]
        S[nameKey] = nil
        if m and m.Parent then pcall(function() m:Destroy() end) end
    end

    function H.computeCameraMoveDir(speed)
        local cam = App.GetCamera()
        if not cam then return Vector3.zero, CFrame.identity end
        local uis = Services.UserInputService
        local cf = cam.CFrame
        local move = Vector3.zero
        if uis:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) or uis:IsKeyDown(Enum.KeyCode.E) or (World.MobileFlyInput.Up or 0) > 0 then
            move = move + Vector3.new(0, 1, 0)
        end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.Q) or (World.MobileFlyInput.Down or 0) > 0 then
            move = move - Vector3.new(0, 1, 0)
        end
        local hum = App.GetHum(App.GetChar(App.LocalPlayer))
        if hum and hum.MoveDirection and hum.MoveDirection.Magnitude > 0.05 and App.IsMobileInput and App.IsMobileInput() then
            local md = hum.MoveDirection
            move = move + Vector3.new(md.X, 0, md.Z)
        end
        if move.Magnitude > 0.01 then
            move = move.Unit * speed
        end
        return move, cf
    end

    function H.getDetonateRemote()
        if App.Remotes and App.Remotes.DetonateC4 then
            return App.Remotes.DetonateC4
        end
        local r = Services.ReplicatedStorage:FindFirstChild("Remotes")
        local c4f = r and r:FindFirstChild("C4")
        return c4f and c4f:FindFirstChild("ActivateC4") or nil
    end

    function H.getSnackRemote()
        local r = Services.ReplicatedStorage:FindFirstChild("Remotes")
        return (App.Remotes and App.Remotes.EatFood)
            or (r and r:FindFirstChild("SnackEaten"))
            or (r and r:FindFirstChild("EatFood"))
    end

    function H.collectPlantedC4List()
        local out = {}
        local seen = {}
        for _, inst in ipairs(Services.CollectionService:GetTagged("C4")) do
            if inst and inst:IsDescendantOf(Services.Workspace) and not seen[inst] then
                seen[inst] = true
                table.insert(out, inst)
            end
        end
        for _, child in ipairs(Services.Workspace:GetChildren()) do
            if not seen[child] and (child:IsA("BasePart") or child:IsA("Model")) then
                local nl = child.Name:lower()
                if nl == "c4" or nl:find("plantedc4", 1, true) then
                    seen[child] = true
                    table.insert(out, child)
                end
            end
        end
        return out
    end

    function H.getInstancePos(inst)
        if inst:IsA("BasePart") then return inst.Position end
        if inst:IsA("Model") then
            local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            if pp then return pp.Position end
        end
        return nil
    end

    function H.tryInvokeInteract(item)
        local rem = App.Remotes and App.Remotes.InteractWithItem
        if not rem then
            local r = Services.ReplicatedStorage:FindFirstChild("Remotes")
            rem = r and r:FindFirstChild("InteractWithItem")
        end
        if rem and rem:IsA("RemoteFunction") then
            return pcall(function() return rem:InvokeServer(item) end)
        elseif rem and rem:IsA("RemoteEvent") then
            return pcall(function() rem:FireServer(item) end)
        end
        return false, nil
    end

    function World.SetMobileFlyInput(up, down)
        World.MobileFlyInput.Up = tonumber(up) or 0
        World.MobileFlyInput.Down = tonumber(down) or 0
    end

    function World.GetCriminalsSpawnPart()
        if S.CachedCrimSpawn and S.CachedCrimSpawn.Parent then
            return S.CachedCrimSpawn
        end
        local cs = Services.Workspace:FindFirstChild("Criminals Spawn")
        if cs then
            if cs:IsA("BasePart") then
                S.CachedCrimSpawn = cs
                return cs
            end
            local part = cs:FindFirstChildWhichIsA("SpawnLocation", true) or cs:FindFirstChildWhichIsA("BasePart", true)
            if part then
                S.CachedCrimSpawn = part
                return part
            end
        end
        return nil
    end

    function World.SafeTeleportCF(cf)
        if not cf or S.TeleportLock then return false end
        local targetCF = (typeof(cf) == "Vector3") and CFrame.new(cf) or cf
        local char = App.GetChar(App.LocalPlayer)
        local hrp = App.GetRoot(char)
        local hum = App.GetHum(char)
        if not char or not hrp then return false end
        S.TeleportLock = true
        if App.Shield and App.Shield.ResetDesyncForTeleport then
            App.Shield.ResetDesyncForTeleport()
        end
        if hum and hum.Sit then
            hum.Sit = false
            task.wait(0.03)
        end
        if App.Shield and App.Shield.ResetDesyncForTeleport then
            App.Shield.ResetDesyncForTeleport()
        end
        if hrp and hrp.Parent then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            local ok = pcall(function() char:PivotTo(targetCF) end)
            if not ok then hrp.CFrame = targetCF end
        end
        S.TeleportLock = false
        return true
    end

    function World.SetFenceGodmode(on)
        local want = (on == true)
        H.clearConns(S.FenceConns)
        if want then
            local fences = Services.Workspace:FindFirstChild("Prison_Fences")
            if fences then
                for _, desc in ipairs(fences:GetDescendants()) do H.applyFencePart(desc) end
                table.insert(S.FenceConns, fences.DescendantAdded:Connect(H.applyFencePart))
            end
            table.insert(S.FenceConns, Services.Workspace.ChildAdded:Connect(function(child)
                if State.FenceGodmode and child.Name == "Prison_Fences" then
                    for _, d in ipairs(child:GetDescendants()) do H.applyFencePart(d) end
                    table.insert(S.FenceConns, child.DescendantAdded:Connect(H.applyFencePart))
                end
            end))
        else
            for part, orig in pairs(S.FenceRestore) do
                if part and part.Parent then
                    pcall(function()
                        part.CanTouch = orig.CanTouch
                        part.CanCollide = orig.CanCollide
                    end)
                end
                S.FenceRestore[part] = nil
            end
        end
    end

    function World.SetOpenAllDoors(on)
        local want = (on == true)
        H.clearConns(S.DoorConns)
        if want then
            local doors = Services.Workspace:FindFirstChild("Doors")
            if doors then
                for _, desc in ipairs(doors:GetDescendants()) do H.applyDoorPart(desc) end
                table.insert(S.DoorConns, doors.DescendantAdded:Connect(H.applyDoorPart))
            end
            table.insert(S.DoorConns, Services.Workspace.ChildAdded:Connect(function(child)
                if State.OpenAllDoors and child.Name == "Doors" then
                    for _, d in ipairs(child:GetDescendants()) do H.applyDoorPart(d) end
                    table.insert(S.DoorConns, child.DescendantAdded:Connect(H.applyDoorPart))
                end
            end))
        else
            for part, orig in pairs(S.DoorRestore) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = orig.CanCollide
                        part.Transparency = orig.Transparency
                        part.CanQuery = orig.CanQuery
                    end)
                end
                S.DoorRestore[part] = nil
            end
        end
    end

    function World.SafeSetAntiFlingEnabled(on)
        local want = (on == true)
        H.clearConns(S.AntiFlingConns)
        if want then
            local ownVeh = H.getOwnVehicle()
            local cc = Services.Workspace:FindFirstChild("CarContainer")
            if cc then
                for _, desc in ipairs(cc:GetDescendants()) do H.applyAntiFlingPart(desc, ownVeh) end
                table.insert(S.AntiFlingConns, cc.DescendantAdded:Connect(function(desc)
                    H.applyAntiFlingPart(desc, H.getOwnVehicle())
                end))
            end
            table.insert(S.AntiFlingConns, Services.Workspace.ChildAdded:Connect(function(child)
                if State.AntiFling and child.Name == "CarContainer" then
                    local ov = H.getOwnVehicle()
                    for _, d in ipairs(child:GetDescendants()) do H.applyAntiFlingPart(d, ov) end
                    table.insert(S.AntiFlingConns, child.DescendantAdded:Connect(function(d)
                        H.applyAntiFlingPart(d, H.getOwnVehicle())
                    end))
                end
            end))
        else
            for part, orig in pairs(S.AntiFlingRestore) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = orig.CanCollide
                        part.CanQuery = orig.CanQuery
                    end)
                end
                S.AntiFlingRestore[part] = nil
            end
            for part, orig in pairs(S.PlayerFlingRestore) do
                if part and part.Parent then
                    pcall(function() part.CanCollide = orig end)
                end
                S.PlayerFlingRestore[part] = nil
            end
        end
    end

    function World.StepAntiFlingPlayers()
        if not State.AntiFling then return end
        local lp = App.LocalPlayer
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= lp then
                local char = App.GetChar(plr)
                local hrp = App.GetRoot(char)
                if hrp and hrp.AssemblyAngularVelocity.Magnitude > 85 then
                    for _, desc in ipairs(char:GetDescendants()) do
                        if desc:IsA("BasePart") and desc.CanCollide then
                            if S.PlayerFlingRestore[desc] == nil then
                                S.PlayerFlingRestore[desc] = true
                            end
                            desc.CanCollide = false
                        end
                    end
                end
            end
        end
    end

    function World.SpawnAndEnterNearestCar()
        if S.CarSpawnBusy then
            Bus.Emit("Alert", "CarSpawner", "Spawn request already in progress", "info")
            return false
        end
        S.CarSpawnBusy = true

        Janitor.Spawn(function()
            local okSpawn, errMsg = pcall(function()
                local char = App.GetChar(App.LocalPlayer)
                local hrp = App.GetRoot(char)
                local hum = App.GetHum(char)
                if not hrp or not hum or hum.Health <= 0 then
                    error("Character unavailable")
                end

                local items = Services.Workspace:FindFirstChild("Prison_ITEMS")
                local buttons = items and items:FindFirstChild("buttons")
                if not buttons then error("Car spawner buttons missing") end

                local bestBtn = nil
                local bestDist = math.huge
                for _, model in ipairs(buttons:GetChildren()) do
                    if model.Name == "Car Spawner" then
                        local part = model:FindFirstChild("Car Spawner") or model:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local d = (part.Position - hrp.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestBtn = part
                            end
                        end
                    end
                end
                if not bestBtn then error("No Car Spawner found") end

                local cc = Services.Workspace:FindFirstChild("CarContainer")
                if not cc then error("CarContainer missing") end

                local before = {}
                for _, car in ipairs(cc:GetChildren()) do
                    before[car] = true
                end

                World.SafeTeleportCF(CFrame.new(bestBtn.Position + Vector3.new(0, 3.2, 0)))
                task.wait(0.1)

                H.tryInvokeInteract(bestBtn)
                local giverRem = App.Remotes and App.Remotes.GiverPressed
                if giverRem then pcall(function() giverRem:FireServer(bestBtn) end) end

                local spawnedCar = nil
                local deadline = os.clock() + 5.0
                while os.clock() < deadline and App.Running do
                    for _, car in ipairs(cc:GetChildren()) do
                        if not before[car] then
                            spawnedCar = car
                            break
                        end
                    end
                    if spawnedCar then break end
                    task.wait(0.1)
                end

                if not spawnedCar then error("Timed out waiting for car spawn (5s)") end

                local seat = spawnedCar:FindFirstChildWhichIsA("VehicleSeat", true)
                local seatWait = os.clock() + 1.5
                while not seat and os.clock() < seatWait do
                    task.wait(0.05)
                    seat = spawnedCar:FindFirstChildWhichIsA("VehicleSeat", true)
                end
                if not seat then error("Spawned car has no VehicleSeat") end

                World.SafeTeleportCF(CFrame.new(seat.Position + Vector3.new(0, 2.5, 0)))
                task.wait(0.08)
                pcall(function() seat:Sit(hum) end)
                task.wait(0.15)
                if hum.SeatPart ~= seat and seat.Parent then
                    pcall(function() seat:Sit(hum) end)
                end
                Bus.Emit("Alert", "CarSpawner", "Spawned & entered vehicle", "success")
            end)
            S.CarSpawnBusy = false
            if not okSpawn then
                Bus.Emit("Alert", "CarSpawner", tostring(errMsg), "warn")
            end
        end)
        return true
    end

    function World.GetSafeRegionMaxSpeed(pos)
        if not pos then return 50, 25 end
        for _, b in ipairs(INDOOR_SUBREGIONS) do
            if math.abs(pos.X - b.cx) <= b.hx
                and math.abs(pos.Y - b.cy) <= b.hy
                and math.abs(pos.Z - b.cz) <= b.hz
            then
                return 32, 7.2
            end
        end
        if math.abs(pos.X - PRISON_OUTER_BOX.cx) <= PRISON_OUTER_BOX.hx
            and math.abs(pos.Z - PRISON_OUTER_BOX.cz) <= PRISON_OUTER_BOX.hz
        then
            return 50, 25
        end
        return 100, 50
    end

    function World.RestoreNoclipCollide()
        for part, orig in pairs(S.NoclipRestore) do
            if part and part.Parent then
                pcall(function() part.CanCollide = orig end)
            end
            S.NoclipRestore[part] = nil
        end
    end

    function World.StepNoclip(char)
        if not State.Noclip or not char then
            World.RestoreNoclipCollide()
            return
        end
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BasePart") then
                if S.NoclipRestore[desc] == nil then
                    S.NoclipRestore[desc] = desc.CanCollide
                end
                if desc.CanCollide then desc.CanCollide = false end
            end
        end
    end

    function World.StepCharacterFly(char)
        local hrp = App.GetRoot(char)
        local hum = App.GetHum(char)
        if not State.Fly or not hrp or not hum or hum.Health <= 0 or hum.Sit then
            H.destroyBodyMover("FlyBV")
            H.destroyBodyMover("FlyBG")
            if S.WasFlying then
                S.WasFlying = false
                if hum and hum.Parent then hum.PlatformStand = false end
            end
            return
        end

        S.WasFlying = true

        if not S.FlyBV or S.FlyBV.Parent ~= hrp then
            H.destroyBodyMover("FlyBV")
            local bv = Instance.new("BodyVelocity")
            bv.Name = "KX_FlyBV"
            bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
            bv.P = 1250
            bv.Velocity = Vector3.zero
            bv.Parent = hrp
            S.FlyBV = bv
        end
        if not S.FlyBG or S.FlyBG.Parent ~= hrp then
            H.destroyBodyMover("FlyBG")
            local bg = Instance.new("BodyGyro")
            bg.Name = "KX_FlyBG"
            bg.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
            bg.P = 9000
            bg.D = 400
            bg.CFrame = hrp.CFrame
            bg.Parent = hrp
            S.FlyBG = bg
        end

        local vel, camCF = H.computeCameraMoveDir(tonumber(State.FlySpeed) or 65)
        S.FlyBV.Velocity = vel
        S.FlyBG.CFrame = camCF
        hum.PlatformStand = true
    end

    function World.UpdateVehicles(dt)
        local char = App.GetChar(App.LocalPlayer)
        local hum = App.GetHum(char)
        local seat = hum and hum.SeatPart
        if not (seat and seat:IsA("VehicleSeat")) then
            seat = nil
        end

        if S.LastSpeedSeat and (S.LastSpeedSeat ~= seat or not State.VehicleSpeedMod) then
            local orig = S.VehSpeedRestore[S.LastSpeedSeat]
            if orig and S.LastSpeedSeat.Parent then
                pcall(function()
                    S.LastSpeedSeat.MaxSpeed = orig.MaxSpeed
                    S.LastSpeedSeat.Torque = orig.Torque
                end)
            end
            S.LastSpeedSeat = nil
        end

        if not seat or not State.VehicleFly then
            H.destroyBodyMover("VehFlyBV")
            H.destroyBodyMover("VehFlyBG")
        else
            local speed = tonumber(State.VehicleFlySpeed) or 85
            if not S.VehFlyBV or S.VehFlyBV.Parent ~= seat then
                H.destroyBodyMover("VehFlyBV")
                local bv = Instance.new("BodyVelocity")
                bv.Name = "KX_VehFlyBV"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.zero
                bv.Parent = seat
                S.VehFlyBV = bv
            end
            if not S.VehFlyBG or S.VehFlyBG.Parent ~= seat then
                H.destroyBodyMover("VehFlyBG")
                local bg = Instance.new("BodyGyro")
                bg.Name = "KX_VehFlyBG"
                bg.MaxTorque = Vector3.new(9e5, 9e5, 9e5)
                bg.P = 1.2e4
                bg.D = 600
                bg.CFrame = seat.CFrame
                bg.Parent = seat
                S.VehFlyBG = bg
            end
            local vel, camCF = H.computeCameraMoveDir(speed)
            S.VehFlyBV.Velocity = vel
            S.VehFlyBG.CFrame = camCF
        end

        if seat and State.VehicleSpeedMod then
            if S.VehSpeedRestore[seat] == nil then
                S.VehSpeedRestore[seat] = { MaxSpeed = seat.MaxSpeed, Torque = seat.Torque }
            end
            local mult = H.clamp(tonumber(State.VehicleSpeedMult) or 2.0, 0.5, 5.0)
            local orig = S.VehSpeedRestore[seat]
            seat.MaxSpeed = orig.MaxSpeed * mult
            seat.Torque = orig.Torque * math.max(1.2, mult)
            S.LastSpeedSeat = seat
        end

        if State.VehicleFling and (os.clock() - S.LastVehFlingClock) > 0.2 then
            S.LastVehFlingClock = os.clock()
            local cc = Services.Workspace:FindFirstChild("CarContainer")
            local hrp = App.GetRoot(char)
            local isNetOwner = (GEN_ENV and rawget(GEN_ENV, "isnetworkowner")) or (type(isnetworkowner) == "function" and isnetworkowner) or rawget(_G, "isnetworkowner")
            local ownCar = H.getOwnVehicle()
            if cc and hrp then
                for _, car in ipairs(cc:GetChildren()) do
                    if car ~= ownCar then
                        local vs = car:FindFirstChildWhichIsA("VehicleSeat", true)
                        if vs and not vs.Occupant and (vs.Position - hrp.Position).Magnitude < 120 then
                            local owned = (not isNetOwner) or (pcall(isNetOwner, vs) and isNetOwner(vs))
                            if owned then
                                local best = App.Targets and App.Targets.GetBestTarget and App.Targets.GetBestTarget({ use360 = true, range = 250, wallcheck = false })
                                local tp = (type(best) == "table" and best.part) or nil
                                local targetPos = (tp and tp.Position) or (vs.Position + Vector3.new(0, 60, 0))
                                local dir = targetPos - vs.Position
                                vs.AssemblyLinearVelocity = (dir.Magnitude > 1) and dir.Unit * 240 or Vector3.new(0, 240, 0)
                                vs.AssemblyAngularVelocity = Vector3.new(60, 120, 60)
                            end
                        end
                    end
                end
            end
        end
    end

    function World.CleanupFly()
        H.destroyBodyMover("FlyBV")
        H.destroyBodyMover("FlyBG")
        H.destroyBodyMover("VehFlyBV")
        H.destroyBodyMover("VehFlyBG")
        local char = App.GetChar(App.LocalPlayer)
        local hum = App.GetHum(char)
        if hum and hum.Parent and (S.WasFlying or hum.PlatformStand) then
            hum.PlatformStand = false
        end
        S.WasFlying = false
        World.SetMobileFlyInput(0, 0)
    end

    function World.RestoreSeats()
        for seat, orig in pairs(S.VehSpeedRestore) do
            if orig and seat and seat.Parent then
                pcall(function()
                    seat.MaxSpeed = orig.MaxSpeed
                    seat.Torque = orig.Torque
                end)
            end
            S.VehSpeedRestore[seat] = nil
        end
        S.LastSpeedSeat = nil
    end

    function World.CheckAntiKillPlane(hrp)
        if not State.AntiKillPlane or not hrp then return end
        if hrp.Position.Y <= -12 then
            hrp.AssemblyLinearVelocity = Vector3.zero
            World.SafeTeleportCF(CFrame.new(hrp.Position.X, 108, hrp.Position.Z))
        end
    end

    function World.StepAutoDetonateC4(now)
        if not State.AutoDetonateC4 then return end
        if S.C4DetonateLock or (now - S.LastC4DetonateClock) < 0.45 then return end

        local lp = App.LocalPlayer
        local localChar = App.GetChar(lp)
        local localRoot = App.GetRoot(localChar)
        local hum = App.GetHum(localChar)
        if not localRoot or not hum or hum.Health <= 0 then return end

        local c4List = H.collectPlantedC4List()
        if #c4List == 0 then return end

        local blastRange = 22
        local shouldDetonate = false

        for _, c4 in ipairs(c4List) do
            local pos = H.getInstancePos(c4)
            if pos then
                local selfDist = (pos - localRoot.Position).Magnitude
                local safeForSelf = (selfDist > 16) or (hum.Health > 55)
                local enemyClose = false
                if safeForSelf then
                    for _, plr in ipairs(Services.Players:GetPlayers()) do
                        if plr ~= lp then
                            local valid = true
                            if App.Targets and App.Targets.IsValidCombatTarget then
                                valid = App.Targets.IsValidCombatTarget(plr, State.SilentAimHostileCheck, nil)
                            elseif lp.Team and plr.Team == lp.Team then
                                valid = false
                            end
                            if valid then
                                local ec = App.GetChar(plr)
                                local eh = App.GetHum(ec)
                                local er = App.GetRoot(ec)
                                if eh and eh.Health > 0 and er and (er.Position - pos).Magnitude <= blastRange then
                                    local los = true
                                    if App.Targets and App.Targets.HasLineOfSight then
                                        los = App.Targets.HasLineOfSight(pos + Vector3.new(0, 1.2, 0), er, ec)
                                    end
                                    if los then
                                        enemyClose = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end

                local prevTicks = S.C4HostileTicks[c4] or 0
                if enemyClose then
                    S.C4HostileTicks[c4] = prevTicks + 1
                    if S.C4HostileTicks[c4] > 3 then
                        shouldDetonate = true
                        break
                    end
                else
                    S.C4HostileTicks[c4] = 0
                end
            end
        end

        if not shouldDetonate then return end
        local detRem = H.getDetonateRemote()
        if not detRem then return end

        S.C4DetonateLock = true
        S.LastC4DetonateClock = now
        Janitor.Spawn(function()
            local prevTool = localChar:FindFirstChildOfClass("Tool")
            local bp = lp:FindFirstChildOfClass("Backpack")
            local detTool = (localChar:FindFirstChild("C4") or localChar:FindFirstChild("Detonator"))
                or (bp and (bp:FindFirstChild("C4") or bp:FindFirstChild("Detonator")))
            if detTool and detTool.Parent == bp and hum then
                pcall(function() hum:EquipTool(detTool) end)
                task.wait(0.05)
            end

            pcall(function()
                if detRem:IsA("RemoteFunction") then
                    detRem:InvokeServer()
                else
                    detRem:FireServer()
                end
            end)

            if hum and hum.Parent then
                if prevTool == nil then
                    task.wait(0.05)
                    pcall(function() hum:UnequipTools() end)
                elseif prevTool ~= detTool and prevTool.Parent == bp then
                    task.wait(0.05)
                    pcall(function() hum:EquipTool(prevTool) end)
                end
            end
            S.C4DetonateLock = false
        end)
    end

    function World.AutoHealAndArmor()
        local now = os.clock()
        if (now - S.LastAutoHealClock) < 0.65 then return end
        local char = App.GetChar(App.LocalPlayer)
        local hum = App.GetHum(char)
        if not hum or hum.Health <= 0 then return end

        if State.AutoHeal then
            local pct = (hum.Health / math.max(1, hum.MaxHealth)) * 100
            if pct <= (tonumber(State.AutoHealThreshold) or 55) then
                S.LastAutoHealClock = now
                local bp = App.LocalPlayer:FindFirstChildOfClass("Backpack")
                local snack = nil
                local containers = { char, bp }
                for _, c in ipairs(containers) do
                    if c and not snack then
                        for _, t in ipairs(c:GetChildren()) do
                            if t:IsA("Tool") then
                                local nl = t.Name:lower()
                                if nl:find("donut", 1, true) or nl:find("soda", 1, true)
                                    or nl:find("snack", 1, true) or nl:find("food", 1, true)
                                    or nl:find("med", 1, true) then
                                    snack = t
                                    break
                                end
                            end
                        end
                    end
                end
                local eatRem = H.getSnackRemote()
                if snack then
                    if snack.Parent == bp then pcall(function() hum:EquipTool(snack) end) end
                    pcall(function() snack:Activate() end)
                    if eatRem then pcall(function() eatRem:FireServer(snack) end) end
                elseif eatRem then
                    pcall(function() eatRem:FireServer() end)
                end
            end
        end

        if State.AutoArmor and (now - S.LastPickupClock) >= 1.2 then
            local hasVest = char:FindFirstChild("Light Vest") or char:FindFirstChild("Armor") or char:FindFirstChild("Vest")
            if not hasVest then
                local items = Services.Workspace:FindFirstChild("Prison_ITEMS")
                local clothes = items and items:FindFirstChild("clothes")
                local hrp = App.GetRoot(char)
                if clothes and hrp then
                    for _, item in ipairs(clothes:GetChildren()) do
                        local cd = S.PickupCooldowns[item] or 0
                        if (now - cd) > 3.0 and not item:GetAttribute("RequiredGamepass") then
                            local nl = item.Name:lower()
                            if nl:find("vest", 1, true) or nl:find("armor", 1, true) then
                                local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                                if part and (part.Position - hrp.Position).Magnitude <= 18 then
                                    S.PickupCooldowns[item] = now
                                    S.LastPickupClock = now
                                    Janitor.Spawn(function() H.tryInvokeInteract(item) end)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    function World.CollectAutoPickups()
        if not State.AutoPickupDrops then return end
        local now = os.clock()
        if (now - S.LastPickupClock) < 0.35 then return end

        local char = App.GetChar(App.LocalPlayer)
        local hrp = App.GetRoot(char)
        local hum = App.GetHum(char)
        if not hrp or not hum or hum.Health <= 0 then return end

        local itemsFolder = Services.Workspace:FindFirstChild("Prison_ITEMS")
        local single = itemsFolder and itemsFolder:FindFirstChild("single")
        local scanParents = {}
        if single then table.insert(scanParents, single) end
        table.insert(scanParents, Services.Workspace)

        for _, parentFolder in ipairs(scanParents) do
            for _, obj in ipairs(parentFolder:GetChildren()) do
                local nl = obj.Name:lower()
                local isDrop = (parentFolder == single)
                    or nl:find("keycard", 1, true)
                    or nl:find("dropped", 1, true)
                    or obj:IsA("Tool")
                if isDrop and (now - (S.PickupCooldowns[obj] or 0)) > 2.5 then
                    local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                    if p and (p.Position - hrp.Position).Magnitude <= 14 then
                        S.PickupCooldowns[obj] = now
                        S.LastPickupClock = now
                        Janitor.Spawn(function() H.tryInvokeInteract(obj) end)
                        return
                    end
                end
            end
        end
    end

    App.World = World
end

-- ============================================================================
-- SECTION 3: App.Anomaly (Multi-Strike Cheater & Car-TP Detector w/ 12s TTL)
-- ============================================================================
do
    local S = {
        LastEvalClock = -999,
        PrevPos = setmetatable({}, { __mode = "k" }),
        PrevSeated = setmetatable({}, { __mode = "k" }),
        Strikes = {}, -- [userId] = { count, lastStrike, reason, lastAlert }
        TTL = 12.0,
    }

    local H = {}

    function H.cleanupLeftPlayer(plr)
        if plr then
            S.Strikes[plr.UserId] = nil
            S.PrevPos[plr] = nil
            S.PrevSeated[plr] = nil
        end
    end

    Janitor.Add(Services.Players.PlayerRemoving:Connect(H.cleanupLeftPlayer))

    function H.buildVehiclePosCache()
        local cache = {}
        local cc = Services.Workspace:FindFirstChild("CarContainer")
        if not cc then return cache end
        for _, car in ipairs(cc:GetChildren()) do
            local vs = car:FindFirstChildWhichIsA("VehicleSeat", true)
            if vs then table.insert(cache, vs.Position) end
        end
        return cache
    end

    function H.recordStrike(plr, reason, isCarTP, now)
        local uid = plr.UserId
        local st = S.Strikes[uid]
        if not st or (now - st.lastStrike) > S.TTL then
            st = { count = 0, lastStrike = now, reason = reason, lastAlert = -999 }
            S.Strikes[uid] = st
        end
        st.count = st.count + 1
        st.lastStrike = now
        st.reason = reason

        local requiredStrikes = isCarTP and 1 or 2
        if st.count >= requiredStrikes and (now - st.lastAlert) > 8.0 then
            st.lastAlert = now
            local allowed = isCarTP and State.CarTPAlerts or State.CheaterAlerts
            if allowed then
                Bus.Emit("Alert", plr.Name, reason, "warn")
            end
        end
    end

    local Anomaly = {}

    function Anomaly.IsFlagged(plr)
        if not plr then return false, nil end
        local st = S.Strikes[plr.UserId]
        if not st then return false, nil end
        if (os.clock() - st.lastStrike) > S.TTL then
            S.Strikes[plr.UserId] = nil
            return false, nil
        end
        if st.count >= 2 then
            return true, st.reason
        end
        return false, nil
    end

    function Anomaly.Evaluate(now)
        now = now or os.clock()
        if (now - S.LastEvalClock) < 0.25 then return end
        S.LastEvalClock = now

        for uid, st in pairs(S.Strikes) do
            if (now - st.lastStrike) > S.TTL then
                S.Strikes[uid] = nil
            end
        end

        if not State.CheaterAlerts and not State.CarTPAlerts then return end

        local lp = App.LocalPlayer
        local vehCache = nil -- built at most once per Evaluate pass when needed

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= lp then
                local char = App.GetChar(plr)
                local hrp = App.GetRoot(char)
                local hum = App.GetHum(char)
                if hrp and hum and hum.Health > 0 then
                    local seated = (hum.SeatPart and hum.SeatPart:IsA("VehicleSeat")) and true or false
                    local prev = S.PrevPos[plr]
                    local wasSeated = S.PrevSeated[plr]
                    local curPos = hrp.Position

                    if prev and prev.char == char then
                        local dt = math.max(0.05, now - prev.t)
                        local dist = (curPos - prev.pos).Magnitude
                        local horizDist = Vector3.new(curPos.X - prev.pos.X, 0, curPos.Z - prev.pos.Z).Magnitude
                        local speed = horizDist / dt

                        if State.CarTPAlerts and seated and not wasSeated and dist > 110 then
                            H.recordStrike(plr, string.format("Car-TP snap (%.0f studs)", dist), true, now)
                        elseif State.CarTPAlerts and seated and wasSeated and speed > 290 then
                            H.recordStrike(plr, string.format("Car-TP speed (%.0f st/s)", speed), true, now)
                        elseif State.CheaterAlerts and not seated and speed > 175 and dist > 55 then
                            if not vehCache then vehCache = H.buildVehiclePosCache() end
                            local nearCar = false
                            for _, vpos in ipairs(vehCache) do
                                if (vpos - curPos).Magnitude < 18 then
                                    nearCar = true
                                    break
                                end
                            end
                            if not nearCar then
                                H.recordStrike(plr, string.format("Speed/TP anomaly (%.0f st/s)", speed), false, now)
                            end
                        end
                    end

                    S.PrevPos[plr] = { pos = curPos, t = now, char = char }
                    S.PrevSeated[plr] = seated
                else
                    S.PrevPos[plr] = nil
                    S.PrevSeated[plr] = nil
                end
            end
        end
    end

    App.Anomaly = Anomaly
end

-- ============================================================================
-- SECTION 4: App.Visuals (31-Highlight Cap, Distance-LOD Billboard, Tracers, C4 ESP, Hitboxes)
-- ============================================================================
do
    local MAX_HIGHLIGHTS = 30

    local S = {
        PlayerESP = {}, -- [plr] = { highlight, bb, nameLbl, hpBg, hpFill, pip, tracerLine }
        C4Visuals = {}, -- [c4Inst] = { box, bb, lbl }
        C4WatchInit = false,
        C4Conns = {},
        HitboxOrig = setmetatable({}, { __mode = "k" }),
        HitboxActiveParts = {},
        ScratchCandidates = {},
        ScratchActivePlayers = {},
        ScratchHitboxSeen = {},
        CachedHitboxSize = nil,
        CachedHitboxVec = nil,
    }

    local function sortCandidatesByDist(a, b)
        return a.dist < b.dist
    end

    local H = {}

    function H.clamp(x, lo, hi)
        if x < lo then return lo end
        if x > hi then return hi end
        return x
    end

    function H.getDrawingCtor()
        if App.Has and App.Has.Drawing then
            return (GEN_ENV and rawget(GEN_ENV, "Drawing")) or (type(Drawing) == "table" and Drawing) or rawget(_G, "Drawing")
        end
        return nil
    end

    function H.getTeamColor(plr)
        if App.Targets and App.Targets.GetTeamColor then
            return App.Targets.GetTeamColor(plr)
        end
        if plr.Team and plr.TeamColor then
            return plr.TeamColor.Color
        end
        return Palette.TextPrimary
    end

    function H.isTeammate(plr)
        local lp = App.LocalPlayer
        return (lp and lp.Team and plr.Team and plr.Team == lp.Team) or false
    end

    function H.createBillboard(parentParent)
        local bb = Instance.new("BillboardGui")
        bb.Name = "KX_CompactESP"
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.Size = UDim2.fromOffset(92, 22)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
        bb.ResetOnSpawn = false
        bb.Enabled = false

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "NameTag"
        nameLbl.BackgroundTransparency = 1
        nameLbl.Size = UDim2.new(1, 0, 0, 15)
        nameLbl.Font = Enum.Font.GothamMedium
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = Palette.TextPrimary
        nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLbl.TextStrokeTransparency = 0.25
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Text = ""
        nameLbl.Parent = bb

        local hpBg = Instance.new("Frame")
        hpBg.Name = "HPBg"
        hpBg.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
        hpBg.BackgroundTransparency = 0.2
        hpBg.BorderSizePixel = 0
        hpBg.Position = UDim2.new(0.08, 0, 0, 17)
        hpBg.Size = UDim2.new(0.84, 0, 0, 2)
        hpBg.Parent = bb

        local hpFill = Instance.new("Frame")
        hpFill.Name = "HPFill"
        hpFill.BackgroundColor3 = Palette.Emerald
        hpFill.BorderSizePixel = 0
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.Parent = hpBg

        local pip = Instance.new("Frame")
        pip.Name = "LODPip"
        pip.AnchorPoint = Vector2.new(0.5, 0.5)
        pip.Position = UDim2.fromScale(0.5, 0.5)
        pip.Size = UDim2.fromOffset(8, 8)
        pip.BorderSizePixel = 0
        pip.BackgroundColor3 = Palette.ElectricBlue
        pip.Visible = false
        pip.Parent = bb

        local pipStroke = Instance.new("UIStroke")
        pipStroke.Thickness = 1
        pipStroke.Color = Color3.new(0, 0, 0)
        pipStroke.Transparency = 0.25
        pipStroke.Parent = pip

        local guiParent = (App.GetSafeGuiParent and App.GetSafeGuiParent()) or parentParent
        bb.Parent = guiParent
        return bb, nameLbl, hpBg, hpFill, pip
    end

    function H.ensurePlayerRecord(plr)
        local rec = S.PlayerESP[plr]
        if rec then return rec end

        local guiParent = (App.GetSafeGuiParent and App.GetSafeGuiParent()) or Services.CoreGui
        local bb, nameLbl, hpBg, hpFill, pip = H.createBillboard(guiParent)

        local hl = Instance.new("Highlight")
        hl.Name = "KX_Chams_" .. tostring(plr.UserId)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.72
        hl.OutlineTransparency = 0.12
        hl.Enabled = false
        hl.Parent = guiParent
        local tracerLine = nil
        local drawCtor = H.getDrawingCtor()
        if drawCtor and drawCtor.new then
            local ok, ln = pcall(drawCtor.new, "Line")
            if ok and ln then
                ln.Thickness = 1.25
                ln.Transparency = 0.65
                ln.Visible = false
                tracerLine = ln
            end
        end

        rec = {
            highlight = hl,
            bb = bb,
            nameLbl = nameLbl,
            hpBg = hpBg,
            hpFill = hpFill,
            pip = pip,
            tracerLine = tracerLine,
        }
        S.PlayerESP[plr] = rec
        return rec
    end

    function H.hidePlayerRecord(rec)
        if not rec then return end
        if rec.highlight then rec.highlight.Enabled = false end
        if rec.bb then rec.bb.Enabled = false end
        if rec.tracerLine then pcall(function() rec.tracerLine.Visible = false end) end
    end

    function H.updateCandidateVisual(item, idx, detailDist, cam, tracerOrigin)
        local rec = H.ensurePlayerRecord(item.plr)
        local color = H.getTeamColor(item.plr)
        local head = item.char:FindFirstChild("Head") or item.hrp
        local inDetail = (item.dist <= detailDist)

        local wantHL = (State.ESPBoxes and idx <= MAX_HIGHLIGHTS) and true or false
        if wantHL then
            if rec.highlight.Adornee ~= item.char then rec.highlight.Adornee = item.char end
            if rec.lastColor ~= color then
                rec.highlight.FillColor = color
                rec.highlight.OutlineColor = color
            end
            rec.highlight.Enabled = true
        elseif rec.highlight.Enabled then
            rec.highlight.Enabled = false
        end

        local wantBB = State.ESPNames or State.ESPHealthBar or State.ESPDistance or State.ESPDiamondMarker
        if wantBB then
            if rec.bb.Adornee ~= head then rec.bb.Adornee = head end
            rec.bb.Enabled = true
            if inDetail then
                rec.pip.Visible = false
                local showName = (State.ESPNames or State.ESPDistance) and true or false
                rec.nameLbl.Visible = showName
                if showName then
                    local prefix = State.ESPNames and item.plr.Name or ""
                    local distInt = math.floor(item.dist + 0.5)
                    local fullTxt = (prefix ~= "" and State.ESPDistance) and (prefix .. " " .. tostring(distInt) .. "m")
                        or (prefix ~= "" and prefix)
                        or (tostring(distInt) .. "m")
                    if rec.lastLabel ~= fullTxt then
                        rec.lastLabel = fullTxt
                        rec.nameLbl.Text = fullTxt
                    end
                    if rec.lastNameColor ~= color then
                        rec.lastNameColor = color
                        rec.nameLbl.TextColor3 = color
                    end
                end
                rec.hpBg.Visible = State.ESPHealthBar and true or false
                if rec.hpBg.Visible then
                    local ratio = H.clamp(item.hum.Health / math.max(1, item.hum.MaxHealth), 0, 1)
                    if rec.lastRatio ~= ratio then
                        rec.lastRatio = ratio
                        rec.hpFill.Size = UDim2.new(ratio, 0, 1, 0)
                        rec.hpFill.BackgroundColor3 = (ratio > 0.55 and Palette.Emerald)
                            or (ratio > 0.28 and Palette.Amber)
                            or Palette.RedAlert
                    end
                end
            else
                rec.nameLbl.Visible = false
                rec.hpBg.Visible = false
                rec.pip.Visible = (State.ESPDiamondMarker ~= false)
                if rec.lastPipColor ~= color then
                    rec.lastPipColor = color
                    rec.pip.BackgroundColor3 = color
                end
                rec.pip.Rotation = State.ESPDiamondMarker and 45 or 0
            end
        elseif rec.bb.Enabled then
            rec.bb.Enabled = false
        end
        rec.lastColor = color

        if rec.tracerLine then
            if State.ESPTracers and cam then
                local screenPos, onScreen = cam:WorldToViewportPoint(item.hrp.Position)
                if onScreen and screenPos.Z > 0 then
                    rec.tracerLine.From = tracerOrigin
                    rec.tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    rec.tracerLine.Color = color
                    rec.tracerLine.Visible = true
                else
                    rec.tracerLine.Visible = false
                end
            else
                rec.tracerLine.Visible = false
            end
        end
    end

    function H.attachC4Visual(c4)
        if S.C4Visuals[c4] or not c4 or not c4.Parent then return end
        local parentGui = (App.GetSafeGuiParent and App.GetSafeGuiParent()) or Services.CoreGui

        local box = Instance.new("SelectionBox")
        box.Name = "KX_C4Box"
        box.Adornee = c4
        box.Color3 = Palette.RedAlert
        box.SurfaceColor3 = Palette.RedAlert
        box.LineThickness = 0.04
        box.SurfaceTransparency = 0.78
        box.Visible = State.C4ESP and true or false
        box.Parent = parentGui

        local bb = Instance.new("BillboardGui")
        bb.Name = "KX_C4Tag"
        bb.Adornee = c4
        bb.AlwaysOnTop = true
        bb.Size = UDim2.fromOffset(64, 18)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
        bb.Enabled = State.C4ESP and true or false

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextColor3 = Palette.RedAlert
        lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        lbl.TextStrokeTransparency = 0.15
        lbl.Text = "[C4]"
        lbl.Parent = bb
        bb.Parent = parentGui

        S.C4Visuals[c4] = { box = box, bb = bb, lbl = lbl }
    end

    function H.detachC4Visual(c4)
        local v = S.C4Visuals[c4]
        S.C4Visuals[c4] = nil
        if v then
            if v.box then pcall(function() v.box:Destroy() end) end
            if v.bb then pcall(function() v.bb:Destroy() end) end
        end
    end

    local Visuals = {}

    function Visuals.InitC4Watchers()
        if S.C4WatchInit then return end
        S.C4WatchInit = true
        for _, inst in ipairs(Services.CollectionService:GetTagged("C4")) do
            H.attachC4Visual(inst)
        end
        table.insert(S.C4Conns, Janitor.Add(Services.CollectionService:GetInstanceAddedSignal("C4"):Connect(H.attachC4Visual)))
        table.insert(S.C4Conns, Janitor.Add(Services.CollectionService:GetInstanceRemovedSignal("C4"):Connect(H.detachC4Visual)))
    end

    function Visuals.RemovePlayerESP(plr)
        local hrp = App.GetRoot(App.GetChar(plr))
        if hrp then Visuals.RestorePlayerHitbox(hrp) end
        local rec = S.PlayerESP[plr]
        S.PlayerESP[plr] = nil
        if not rec then return end
        if rec.highlight then pcall(function() rec.highlight:Destroy() end) end
        if rec.bb then pcall(function() rec.bb:Destroy() end) end
        if rec.tracerLine then pcall(function() rec.tracerLine:Remove() end) end
    end

    function Visuals.RemoveAllESP()
        for plr in pairs(S.PlayerESP) do
            Visuals.RemovePlayerESP(plr)
        end
        for c4 in pairs(S.C4Visuals) do
            H.detachC4Visual(c4)
        end
        for part in pairs(S.HitboxActiveParts) do
            Visuals.RestorePlayerHitbox(part)
        end
    end

    function Visuals.RestorePlayerHitbox(part)
        if not part then return end
        local orig = S.HitboxOrig[part]
        if orig and part.Parent then
            pcall(function()
                part.Size = orig.Size
                part.Transparency = orig.Transparency
                part.CanCollide = orig.CanCollide
                part.Material = orig.Material
            end)
        end
        S.HitboxOrig[part] = nil
        S.HitboxActiveParts[part] = nil
    end

    function Visuals.UpdateHitboxExpander()
        if not State.HitboxExpander then
            for part in pairs(S.HitboxActiveParts) do
                Visuals.RestorePlayerHitbox(part)
            end
            return
        end

        local lp = App.LocalPlayer
        local sz = H.clamp(tonumber(State.HitboxSize) or 8, 3, 25)
        local tr = H.clamp(tonumber(State.HitboxTransparency) or 0.72, 0, 0.95)
        if S.CachedHitboxSize ~= sz or not S.CachedHitboxVec then
            S.CachedHitboxSize = sz
            S.CachedHitboxVec = Vector3.new(sz, sz, sz)
        end
        local targetVec = S.CachedHitboxVec
        local validSeen = S.ScratchHitboxSeen
        for k in pairs(validSeen) do
            validSeen[k] = nil
        end

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= lp then
                local skip = State.HitboxTeamCheck and H.isTeammate(plr)
                local char = App.GetChar(plr)
                local hum = App.GetHum(char)
                local hrp = App.GetRoot(char)
                if not skip and char and hum and hum.Health > 0 and hrp then
                    validSeen[hrp] = true
                    if S.HitboxOrig[hrp] == nil then
                        S.HitboxOrig[hrp] = {
                            Size = hrp.Size,
                            Transparency = hrp.Transparency,
                            CanCollide = hrp.CanCollide,
                            Material = hrp.Material,
                        }
                    end
                    S.HitboxActiveParts[hrp] = true
                    if hrp.Size ~= targetVec then hrp.Size = targetVec end
                    if hrp.Transparency ~= tr then hrp.Transparency = tr end
                    if hrp.CanCollide ~= false then hrp.CanCollide = false end
                    if hrp.Material ~= Enum.Material.ForceField then hrp.Material = Enum.Material.ForceField end
                end
            end
        end

        for part in pairs(S.HitboxActiveParts) do
            if not validSeen[part] or not part.Parent then
                Visuals.RestorePlayerHitbox(part)
            end
        end
    end

    function Visuals.UpdateRenderESP()
        if not S.C4WatchInit then Visuals.InitC4Watchers() end

        local cam = App.GetCamera()
        local lp = App.LocalPlayer
        local lpRoot = App.GetRoot(App.GetChar(lp))
        local refPos = (lpRoot and lpRoot.Position) or (cam and cam.CFrame.Position)

        for c4, vis in pairs(S.C4Visuals) do
            if not c4 or not c4.Parent then
                H.detachC4Visual(c4)
            else
                local showC4 = State.C4ESP and true or false
                vis.box.Visible = showC4
                vis.bb.Enabled = showC4
                if showC4 and refPos and vis.lbl then
                    local p = c4:IsA("BasePart") and c4.Position or (c4.PrimaryPart and c4.PrimaryPart.Position)
                    if p then vis.lbl.Text = string.format("[C4 %.0fm]", (p - refPos).Magnitude) end
                end
            end
        end

        if not State.ESPEnabled then
            for _, rec in pairs(S.PlayerESP) do H.hidePlayerRecord(rec) end
            return
        end

        local maxDist = tonumber(State.ESPMaxDistance) or 600
        local detailDist = tonumber(State.ESPDetailDistance) or 130
        local candidates = S.ScratchCandidates
        local activePlayers = S.ScratchActivePlayers
        for i = #candidates, 1, -1 do
            candidates[i] = nil
        end
        for k in pairs(activePlayers) do
            activePlayers[k] = nil
        end

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= lp then
                local char = App.GetChar(plr)
                local hum = App.GetHum(char)
                local hrp = App.GetRoot(char)
                local skipTeam = State.ESPHideTeam and H.isTeammate(plr)
                if char and hum and hum.Health > 0 and hrp and not skipTeam then
                    local d = refPos and (hrp.Position - refPos).Magnitude or 0
                    if d <= maxDist then
                        activePlayers[plr] = true
                        candidates[#candidates + 1] = { plr = plr, char = char, hum = hum, hrp = hrp, dist = d }
                    end
                end
            end
        end

        for plr, rec in pairs(S.PlayerESP) do
            if not activePlayers[plr] then H.hidePlayerRecord(rec) end
        end

        table.sort(candidates, sortCandidatesByDist)

        local vpSize = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local tracerOrigin = Vector2.new(vpSize.X * 0.5, vpSize.Y - 6)
        for idx, item in ipairs(candidates) do
            H.updateCandidateVisual(item, idx, detailDist, cam, tracerOrigin)
        end
    end

    Janitor.Add(Services.Players.PlayerRemoving:Connect(Visuals.RemovePlayerESP))
    App.Visuals = Visuals
end

-- ============================================================================
-- SECTION 5: App.Killfeed (Pre-Existing Filter, Safe Name Parse, Streak UserId Map)
-- ============================================================================
do
    local S = {
        WatcherInit = false,
        IgnoredChildren = setmetatable({}, { __mode = "k" }),
        KillerStreaks = {}, -- [userId] = count
        PlayerJanitors = {}, -- [plr] = scope
        HealthCache = setmetatable({}, { __mode = "k" }),
        Conns = {},
    }

    local H = {}

    function H.resolvePlayer(rawName)
        if not rawName or rawName == "" then return nil end
        if App.Targets and App.Targets.FuzzyKillfeedPlayer then
            local p = App.Targets.FuzzyKillfeedPlayer(rawName)
            if p then return p end
        end
        local clean = rawName:gsub("^@", "")
        local low = clean:lower()
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            local nLow = plr.Name and plr.Name:lower()
            local dLow = plr.DisplayName and plr.DisplayName:lower()
            if nLow == low or dLow == low then
                return plr
            end
        end
        return nil
    end

    -- Split on the LAST " with " so DisplayNames containing " with " parse safely
    function H.splitLastWith(str)
        local lastIdx = nil
        local idx = 1
        while true do
            local found = str:find(" with ", idx, true)
            if not found then break end
            lastIdx = found
            idx = found + 6
        end
        if lastIdx then
            return str:sub(1, lastIdx - 1), str:sub(lastIdx + 6)
        end
        return str, nil
    end

    function H.extractKillfeedText(inst)
        if not inst then return nil end
        if inst:IsA("StringValue") and inst.Value ~= "" then return inst.Value end
        if inst:IsA("TextLabel") and inst.Text ~= "" then return inst.Text end
        local attr = inst:GetAttribute("Text") or inst:GetAttribute("Message")
        if type(attr) == "string" and attr ~= "" then return attr end
        local sv = inst:FindFirstChildWhichIsA("StringValue", true)
        if sv and sv.Value ~= "" then return sv.Value end
        local tl = inst:FindFirstChildWhichIsA("TextLabel", true)
        if tl and tl.Text ~= "" then return tl.Text end
        if type(inst.Name) == "string" and inst.Name:find("killed", 1, true) then
            return inst.Name
        end
        return nil
    end

    function H.processKillfeedChild(child)
        if S.IgnoredChildren[child] then return end
        S.IgnoredChildren[child] = true

        task.defer(function()
            if not child or not child.Parent or not App.Running then return end
            task.wait(0.03)
            local raw = H.extractKillfeedText(child)
            if not raw then return end

            local killerRaw, rest = raw:match("^(.+) killed (.+)$")
            if not killerRaw or not rest then return end

            local victimRaw, weaponRaw = H.splitLastWith(rest)
            local killerPlr = H.resolvePlayer(killerRaw)
            local victimPlr = H.resolvePlayer(victimRaw)

            if victimPlr then
                S.KillerStreaks[victimPlr.UserId] = 0
            end

            local streak = 1
            if killerPlr then
                streak = (S.KillerStreaks[killerPlr.UserId] or 0) + 1
                S.KillerStreaks[killerPlr.UserId] = streak
            end

            local tag = nil
            local lp = App.LocalPlayer
            if killerPlr and lp and killerPlr == lp then
                local now = os.clock()
                local hook = App.Combat and App.Combat.GunHook
                if hook then
                    local lc = hook.LastComboShotClock or 0
                    local lr = hook.LastRageShotClock or 0
                    if lc > 0 and (now - lc) <= 1.2 then
                        tag = "COMBO"
                    elseif lr > 0 and (now - lr) <= 1.2 then
                        tag = "RAGEBOT"
                    end
                end
                if State.KillSound and App.VFX and App.VFX.PlayKillSound then
                    pcall(App.VFX.PlayKillSound, streak)
                end
            end

            local killerDisp = (killerPlr and type(killerPlr.DisplayName) == "string" and killerPlr.DisplayName ~= "" and killerPlr.DisplayName) or killerRaw
            local victimDisp = (victimPlr and type(victimPlr.DisplayName) == "string" and victimPlr.DisplayName ~= "" and victimPlr.DisplayName) or victimRaw
            local entry = {
                raw = raw,
                killer = killerDisp,
                victim = victimDisp,
                killerDisplay = killerDisp,
                victimDisplay = victimDisp,
                killerName = killerPlr and killerPlr.Name or killerRaw,
                victimName = victimPlr and victimPlr.Name or victimRaw,
                killerColor = killerPlr and killerPlr.TeamColor and killerPlr.TeamColor.Color or Palette.TextPrimary,
                victimColor = victimPlr and victimPlr.TeamColor and victimPlr.TeamColor.Color or Palette.TextMuted,
                weapon = weaponRaw or "Weapon",
                tag = tag,
                streak = streak,
                streakLabel = (streak > 1) and (tostring(streak) .. "x") or nil,
                isLocalKill = (killerPlr == lp),
                isLocalDeath = (victimPlr == lp),
                timestamp = os.clock(),
            }
            Bus.Emit("KillfeedRow", entry)
        end)
    end

    function H.bindFeedFolder(folder)
        if not folder then return end
        for _, child in ipairs(folder:GetChildren()) do
            S.IgnoredChildren[child] = true
        end
        table.insert(S.Conns, Janitor.Add(folder.ChildAdded:Connect(H.processKillfeedChild)))
    end

    local Killfeed = {}

    function Killfeed.GetKillerStreak(uid)
        return S.KillerStreaks[uid] or 0
    end

    function Killfeed.EvictPlayer(plr)
        if not plr then return end
        S.KillerStreaks[plr.UserId] = nil
        local scope = S.PlayerJanitors[plr]
        S.PlayerJanitors[plr] = nil
        if scope and scope.Clean then
            pcall(function() scope:Clean() end)
        end
    end

    function Killfeed.TrackHealth(plr)
        if not plr or plr == App.LocalPlayer then return end
        Killfeed.EvictPlayer(plr)

        local scope = Janitor.NewScope()
        S.PlayerJanitors[plr] = scope
        local charConns = {}

        local function bindChar(char)
            for i = #charConns, 1, -1 do
                pcall(function() charConns[i]:Disconnect() end)
                charConns[i] = nil
            end
            if not char then return end
            Janitor.Spawn(function()
                local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 4)
                if not hum or not App.Running or S.PlayerJanitors[plr] ~= scope or plr.Character ~= char then return end
                S.HealthCache[plr] = hum.Health
                table.insert(charConns, scope:Add(hum.HealthChanged:Connect(function(newHP)
                    S.HealthCache[plr] = newHP
                end)))
                table.insert(charConns, scope:Add(hum.Died:Connect(function()
                    S.KillerStreaks[plr.UserId] = 0
                    S.HealthCache[plr] = 0
                end)))
            end)
        end

        if plr.Character then bindChar(plr.Character) end
        scope:Add(plr.CharacterAdded:Connect(bindChar))
    end

    function Killfeed.SetupWatcher()
        if S.WatcherInit then return end
        S.WatcherInit = true

        local kf = Services.ReplicatedStorage:FindFirstChild("Killfeed")
        if kf then
            H.bindFeedFolder(kf)
        else
            table.insert(S.Conns, Janitor.Add(Services.ReplicatedStorage.ChildAdded:Connect(function(child)
                if child.Name == "Killfeed" then H.bindFeedFolder(child) end
            end)))
        end

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            Killfeed.TrackHealth(plr)
        end
        Janitor.Add(Services.Players.PlayerAdded:Connect(Killfeed.TrackHealth))
        Janitor.Add(Services.Players.PlayerRemoving:Connect(Killfeed.EvictPlayer))
    end

    App.Killfeed = Killfeed
end

-- ============================================================================
-- SECTION 6: App.Scheduler (Stepped / Heartbeat / RenderStepped / ViewTarget)
-- ============================================================================
do
    local S = {
        Started = false,
        StopHooks = {},
        InStateKey = {},
        FromOnStateChanged = nil,
        InitialFOV = nil,
        DiedConn = nil,
        LastRageClock = -999,
        LastKillAuraClock = -999,
        LastAutoTazeClock = -999,
        LastComboClock = -999,
        LastLoopKillClock = -999,
        LastRespawnClock = -999,
        LastAutoCrimClock = -999,
        LastAutoReloadClock = -999,
        AutoArrestLock = false,
        AutoArrestCooldowns = {},
        ViewTarget = nil,
        ViewConns = {},
        LoopKillIdx = 1,
    }

    local H = {}

    function H.clamp(x, lo, hi)
        if x < lo then return lo end
        if x > hi then return hi end
        return x
    end

    function H.clearViewConns()
        for i = #S.ViewConns, 1, -1 do
            pcall(function() S.ViewConns[i]:Disconnect() end)
            S.ViewConns[i] = nil
        end
    end

    function H.applyRegionOrCustomSpeed(hum, hrp)
        if not State.MaxSpeed or not hum or not hrp then return end
        if hum.Health <= 0 or hum.PlatformStand then return end
        local mode = State.SpeedMode or "RegionSafe"
        if mode == "RegionSafe" then
            local safeWS, safeJH = App.World.GetSafeRegionMaxSpeed(hrp.Position)
            if hum.WalkSpeed < safeWS then hum.WalkSpeed = safeWS end
            if not State.JumpPowerEnabled and hum.JumpHeight and hum.JumpHeight < safeJH then
                hum.JumpHeight = safeJH
            end
        elseif mode == "Custom" then
            hum.WalkSpeed = tonumber(State.WalkSpeed) or 28
        elseif mode == "AlwaysSprint" then
            if hum.WalkSpeed < 24 then hum.WalkSpeed = 24 end
        end
    end

    function H.applyJumpPower(hum)
        if not State.JumpPowerEnabled or not hum or hum.Health <= 0 then return end
        hum.UseJumpPower = true
        hum.JumpPower = tonumber(State.JumpPower) or 50
    end

    function H.onStateChanged(key, val)
        if not key or (S.InStateKey and S.InStateKey[key]) then
            return
        end
        local prevFrom = S.FromOnStateChanged
        S.FromOnStateChanged = key
        if key == "FenceGodmode" then
            App.World.SetFenceGodmode(val)
        elseif key == "OpenAllDoors" then
            App.World.SetOpenAllDoors(val)
        elseif key == "AntiFling" then
            App.World.SafeSetAntiFlingEnabled(val)
        elseif key == "ShieldEnabled" then
            App.Shield.SetEnabled(val)
        elseif key == "ShieldMode" then
            App.Shield.SetMode(val)
        elseif key == "FEInvisible" then
            App.Shield.SetFEInvisible(val)
        elseif key == "Noclip" and not val then
            App.World.RestoreNoclipCollide()
        elseif (key == "Fly" or key == "VehicleFly") and not val then
            App.World.CleanupFly()
        elseif key == "HitboxExpander" and not val then
            App.Visuals.UpdateHitboxExpander()
        elseif (key == "ESPEnabled" or key == "C4ESP") and not val then
            App.Visuals.UpdateRenderESP()
        elseif key == "AntiJumpCooldown" then
            App.Shield.BypassAntiJump(nil, val)
        elseif key == "AntiNoclipBypass" then
            App.Shield.BypassClientAntiNoclip(nil, val)
        elseif key == "AntiTaze" or key == "AntiArrest" then
            if val then
                App.Shield.InstallAntiTaze()
            elseif not (State.AntiTaze or State.AntiArrest) then
                App.Shield.RestoreAntiTaze()
            end
        elseif key == "AntiRiotShield" then
            if App.Combat and App.Combat.ApplyAntiRiotShield then
                App.Combat.ApplyAntiRiotShield(val == true)
            end
            if App.Combat and App.Combat.UpdateCastRayFilter then
                App.Combat.UpdateCastRayFilter()
            end
        elseif key == "SilentAimWallbang" or key == "VehicleWallbang" then
            if App.Combat and App.Combat.UpdateCastRayFilter then
                App.Combat.UpdateCastRayFilter()
            end
        end
        S.FromOnStateChanged = prevFrom
    end

    function H.findToolInCharOrBP(char, bp, nameMatchFn)
        if char then
            local eq = char:FindFirstChildOfClass("Tool")
            if eq and nameMatchFn(eq) then return eq, true end
        end
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and nameMatchFn(t) then return t, false end
            end
        end
        return nil, false
    end

    function H.getGunAmmo(tool)
        if not tool then return 0 end
        local localCur = tool:GetAttribute("Local_CurrentAmmo")
        if type(localCur) == "number" then return localCur end
        local cur = tool:GetAttribute("CurrentAmmo") or tool:GetAttribute("Ammo")
        if type(cur) == "number" then return cur end
        local ammoVal = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo")
        if ammoVal and ammoVal:IsA("ValueBase") and type(ammoVal.Value) == "number" then
            return ammoVal.Value
        end
        local st = tool:FindFirstChild("GunStates")
        local req = (GEN_ENV and rawget(GEN_ENV, "require")) or (type(require) == "function" and require) or rawget(_G, "require")
        if st and st:IsA("ModuleScript") and type(req) == "function" then
            local ok, tbl = pcall(req, st)
            if ok and type(tbl) == "table" and type(tbl.CurrentAmmo) == "number" then
                return tbl.CurrentAmmo
            end
        end
        return nil
    end

    function H.stepAutoReload(now, char)
        if not State.GunAutoReload or (now - S.LastAutoReloadClock) < 0.45 then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool or not (App.Combat and App.Combat.IsFirearmTool and App.Combat.IsFirearmTool(tool, true)) then
            return
        end
        local ammo = H.getGunAmmo(tool)
        if ammo == nil or ammo > 0 then return end
        S.LastAutoReloadClock = now
        local hook = App.Combat and App.Combat.GunHook
        if hook and type(hook.Reload) == "function" then
            pcall(task.spawn, hook.Reload)
        elseif App.Combat and App.Combat.TryReload then
            pcall(App.Combat.TryReload, tool)
        else
            local rem = App.Remotes and (App.Remotes.Reload or App.Remotes.ReloadGun)
            if not rem then
                local r = Services.ReplicatedStorage:FindFirstChild("Remotes")
                rem = r and (r:FindFirstChild("ReloadWeapon") or r:FindFirstChild("Reload"))
            end
            if rem then pcall(function() rem:FireServer(tool) end) end
        end
    end

    function H.stepAutoCriminal(now)
        if not State.AutoCriminal or (now - S.LastAutoCrimClock) < 1.5 then return end
        local lp = App.LocalPlayer
        if not lp.Team or lp.Team.Name ~= "Inmates" then return end
        local cs = App.World.GetCriminalsSpawnPart()
        local hrp = App.GetRoot(App.GetChar(lp))
        if not cs or not hrp then return end
        S.LastAutoCrimClock = now
        local prevCF = (App.Shield and App.Shield.GetRealPosition and App.Shield.GetRealPosition(hrp)) or hrp.CFrame
        App.World.SafeTeleportCF(CFrame.new(cs.Position + Vector3.new(0, 2.2, 0)))
        Janitor.Delay(0.18, function()
            if App.Running and hrp.Parent then
                App.World.SafeTeleportCF(prevCF)
            end
        end)
    end

    function H.stepRagebot(now, char)
        if not State.Ragebot or not App.Combat or not App.Targets then return end
        local interval = math.max(0.03, 1 / math.max(1, tonumber(State.RagebotRate) or 18))
        if (now - S.LastRageClock) < interval then return end

        local use360 = State.Ragebot360 == true
        local fov = use360 and 360 or (tonumber(State.SilentAimFOV) or 160)
        local best = App.Targets.GetBestTarget({
            use360 = use360,
            fov = fov,
            wallcheck = State.SilentAimWallcheck,
            wallbang = State.SilentAimWallbang,
            teamCheck = State.SilentAimTeamCheck,
            requireHostile = State.SilentAimHostileCheck,
            skipDown = State.SilentAimSkipDown,
            forceHead = true,
        })
        local targetPart = (type(best) == "table" and best.part) or nil
        if not targetPart then return end

        local gun = char:FindFirstChildOfClass("Tool")
        if not (gun and App.Combat.IsFirearmTool(gun, false) and App.Combat.IsToolReadyToFire(gun)) then
            gun = nil
            if State.RagebotAutoSwitch and App.Weapons and App.Weapons.GetOwnedLoadedGuns then
                local guns = App.Weapons.GetOwnedLoadedGuns()
                if guns and guns[1] then
                    gun = guns[1]
                    if App.ToolArbiter and App.ToolArbiter.TryEquip then
                        local prio = (App.ToolArbiter.Priority and App.ToolArbiter.Priority.Rage) or 3
                        App.ToolArbiter.TryEquip(gun, prio, "Ragebot", 0.25)
                    end
                end
            end
        end
        if not gun or gun.Parent ~= char then return end
        if not App.Combat.IsToolReadyToFire(gun) then return end

        S.LastRageClock = now
        if App.Combat.GunHook then
            App.Combat.GunHook.CurrentTargetPart = targetPart
            App.Combat.GunHook.LastRageShotClock = now
        end
        pcall(App.Combat.FireGunOnce, gun, targetPart, true, false)
    end

    function H.stepKillAura(now, hrp)
        if not State.KillAura then return end
        local rate = math.max(0.04, 1 / math.max(1, tonumber(State.KillAuraRate) or 14))
        if (now - S.LastKillAuraClock) < rate then return end
        local meleeRem = App.Remotes and (App.Remotes.Melee or App.Remotes.MeleeEvent)
        if not meleeRem then
            meleeRem = Services.ReplicatedStorage:FindFirstChild("meleeEvent")
            if not meleeRem then
                local r = Services.ReplicatedStorage:FindFirstChild("Remotes")
                meleeRem = r and r:FindFirstChild("MeleeEvent")
            end
        end
        if not meleeRem then return end

        local range = tonumber(State.KillAuraRange) or 14
        local lp = App.LocalPlayer
        local fired = false
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= lp then
                local allow = true
                if App.Targets and App.Targets.IsValidCombatTarget then
                    allow = App.Targets.IsValidCombatTarget(plr, State.KillAuraHostileOnly, State.KillAuraWhitelist)
                end
                if allow and State.KillAuraTeamCheck and lp.Team and plr.Team == lp.Team then
                    allow = false
                end
                if allow then
                    local er = App.GetRoot(App.GetChar(plr))
                    local eh = App.GetHum(App.GetChar(plr))
                    if eh and eh.Health > 0 and er and (er.Position - hrp.Position).Magnitude <= range then
                        fired = true
                        pcall(function() meleeRem:FireServer(plr, 1, 1) end)
                    end
                end
            end
        end
        if fired then S.LastKillAuraClock = now end
    end

    function H.stepAutoTaze(now, char, hrp, hum)
        if not State.AutoTaze or not App.Combat or not App.Targets then return end
        if (now - S.LastAutoTazeClock) < 1.15 then return end

        local bp = App.LocalPlayer:FindFirstChildOfClass("Backpack")
        local taser = H.findToolInCharOrBP(char, bp, function(t)
            return t.Name:lower():find("taser", 1, true) ~= nil
        end)
        local taserAmmo = H.getGunAmmo(taser)
        if not taser or (taserAmmo ~= nil and taserAmmo <= 0) then return end

        local lp = App.LocalPlayer
        local chosenHead = nil
        local bestDist = 48
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= lp and App.Targets.IsValidCombatTarget(plr, true, State.ArrestWhitelist) then
                local ec = App.GetChar(plr)
                local eh = App.GetHum(ec)
                local er = App.GetRoot(ec)
                local eHead = ec and ec:FindFirstChild("Head")
                if eh and eh.Health > 0 and er and eHead and not ec:GetAttribute("Tased") then
                    local d = (er.Position - hrp.Position).Magnitude
                    if d < bestDist and er.AssemblyLinearVelocity.Magnitude < 40 then
                        if App.Targets.HasLineOfSight(hrp.Position, eHead, ec) then
                            bestDist = d
                            chosenHead = eHead
                        end
                    end
                end
            end
        end
        if not chosenHead then return end

        S.LastAutoTazeClock = now
        local prevTool = char:FindFirstChildOfClass("Tool")
        if taser.Parent == bp then
            if App.ToolArbiter and App.ToolArbiter.TryEquip then
                local prio = (App.ToolArbiter.Priority and App.ToolArbiter.Priority.AutoTaze) or 2
                App.ToolArbiter.TryEquip(taser, prio, "AutoTaze", 0.3)
            else
                pcall(function() hum:EquipTool(taser) end)
            end
        end
        if taser.Parent == char and App.Combat.IsToolReadyToFire(taser) then
            pcall(App.Combat.FireGunOnce, taser, chosenHead, false, true)
        end
        if prevTool and prevTool ~= taser and prevTool.Parent == bp then
            Janitor.Delay(0.12, function()
                if hum and hum.Parent and prevTool.Parent == bp then
                    pcall(function() hum:EquipTool(prevTool) end)
                end
            end)
        end
    end

    function H.isWhitelisted(list, plr)
        if type(list) ~= "table" or not plr then return false end
        if list[plr.Name] or list[tostring(plr.UserId)] or list[plr.UserId] then
            return true
        end
        for _, v in ipairs(list) do
            if v == plr.Name or tostring(v) == tostring(plr.UserId) then
                return true
            end
        end
        return false
    end

    function H.stepAutoArrest(now, hrp)
        if not State.AutoArrest or S.AutoArrestLock then return end
        local lp = App.LocalPlayer
        if not lp.Team or lp.Team.Name ~= "Guards" then return end

        local arrestRem = App.Remotes and App.Remotes.ArrestPlayer
        if not arrestRem then
            local r = Services.ReplicatedStorage:FindFirstChild("Remotes")
            arrestRem = r and r:FindFirstChild("ArrestPlayer")
        end
        if not arrestRem then return end

        local range = tonumber(State.AutoArrestRange) or 14
        local nearestChar = nil
        local nearestPlr = nil
        local bestDist = range + 0.01

        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= lp and not H.isWhitelisted(State.ArrestWhitelist, plr) then
                local expire = S.AutoArrestCooldowns[plr.UserId] or 0
                if now >= expire then
                    local ec = App.GetChar(plr)
                    local eh = App.GetHum(ec)
                    local er = App.GetRoot(ec)
                    if ec and eh and eh.Health > 0 and er then
                        local isCrim = (plr.Team and plr.Team.Name == "Criminals")
                        local isInmate = (plr.Team and plr.Team.Name == "Inmates")
                        local isHostile = ec:GetAttribute("Hostile") or (ec:FindFirstChild("Hostile") ~= nil) or isCrim
                        local isTased = ec:GetAttribute("Tased") or eh.PlatformStand
                        local isTresp = ec:GetAttribute("Trespassing") or (ec:FindFirstChild("Trespassing") ~= nil)
                        local arrestable = isCrim or (isInmate and ((isHostile and isTased) or isTresp))
                        if arrestable then
                            local d = (er.Position - hrp.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                                nearestChar = ec
                                nearestPlr = plr
                            end
                        end
                    end
                end
            end
        end

        if not nearestChar or not nearestPlr then return end
        S.AutoArrestLock = true
        S.AutoArrestCooldowns[nearestPlr.UserId] = now + 7.0
        Janitor.Spawn(function()
            pcall(function()
                if arrestRem:IsA("RemoteFunction") then
                    arrestRem:InvokeServer(nearestPlr, 1)
                else
                    arrestRem:FireServer(nearestPlr, 1)
                end
            end)
            S.AutoArrestLock = false
        end)
    end

    function H.stepLoopKill(now, char)
        local targets = State.LoopKillTargets
        if type(targets) ~= "table" or not App.Combat or not App.Weapons then return end
        if (now - S.LastLoopKillClock) < 0.35 then return end

        local keys = {}
        for k, val in pairs(targets) do
            if type(k) == "number" and type(val) == "string" and val ~= "" then
                table.insert(keys, val)
            elseif val then
                table.insert(keys, k)
            end
        end
        if #keys == 0 then return end

        S.LoopKillIdx = ((S.LoopKillIdx - 1) % #keys) + 1
        local pick = keys[S.LoopKillIdx]
        S.LoopKillIdx = S.LoopKillIdx + 1

        local targetPlr = nil
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= App.LocalPlayer and (p.Name == pick or tostring(p.UserId) == tostring(pick)) then
                targetPlr = p
                break
            end
        end
        if not targetPlr or H.isWhitelisted(State.KillAuraWhitelist, targetPlr) then return end

        local tc = App.GetChar(targetPlr)
        local th = App.GetHum(tc)
        local tPart = tc and (tc:FindFirstChild("Head") or App.GetRoot(tc))
        if not th or th.Health <= 0 or not tPart then return end

        local gun = char:FindFirstChildOfClass("Tool")
        if not (gun and App.Combat.IsFirearmTool(gun, false) and App.Combat.IsToolReadyToFire(gun)) then
            local guns = App.Weapons.GetOwnedLoadedGuns and App.Weapons.GetOwnedLoadedGuns()
            if guns and guns[1] then
                gun = guns[1]
                if App.ToolArbiter and App.ToolArbiter.TryEquip then
                    local prio = (App.ToolArbiter.Priority and App.ToolArbiter.Priority.Rage) or 3
                    App.ToolArbiter.TryEquip(gun, prio, "LoopKill", 0.3)
                end
            end
        end
        if gun and gun.Parent == char and App.Combat.IsToolReadyToFire(gun) then
            S.LastLoopKillClock = now
            pcall(App.Combat.FireGunOnce, gun, tPart, true, false)
        end
    end

    function H.stepHeartbeatCombat(now, char, hrp, hum)
        if not hum or hum.Health <= 0 then return end
        H.stepAutoReload(now, char)
        H.stepRagebot(now, char)
        H.stepKillAura(now, hrp)
        H.stepAutoTaze(now, char, hrp, hum)
        H.stepAutoArrest(now, hrp)
        H.stepLoopKill(now, char)

        if State.ComboLoop and App.Weapons and App.Weapons.ExecuteCombo1 then
            local iv = math.max(0.15, tonumber(State.ComboLoopInterval) or 0.45)
            if (now - S.LastComboClock) >= iv then
                S.LastComboClock = now
                pcall(App.Weapons.ExecuteCombo1)
            end
        end
    end

    function H.stepAimAssist(dt)
        if not State.AimAssist or not App.Targets then return end
        local cam = App.GetCamera()
        if not cam then return end
        if not Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

        local best = App.Targets.GetBestTarget({
            fov = tonumber(State.AimAssistFOV) or 140,
            wallcheck = true,
            teamCheck = State.SilentAimTeamCheck,
            requireHostile = State.SilentAimHostileCheck,
            skipDown = State.SilentAimSkipDown,
        })
        local part = (type(best) == "table" and best.part) or nil
        if not part or not part.Parent then return end

        local s = H.clamp(tonumber(State.AimAssistSmooth) or 0.28, 0.05, 0.95)
        local alpha = H.clamp(1 - (1 - s) ^ (math.max(0.001, dt) * 60), 0.02, 1)
        cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, part.Position), alpha)
    end

    function H.onLocalCharAdded(newChar)
        App.Shield.CleanCharacterEffects()
        local hum = newChar:WaitForChild("Humanoid", 5)
        if not hum or not App.Running then return end
        if S.DiedConn then
            pcall(function() S.DiedConn:Disconnect() end)
            S.DiedConn = nil
        end
        if State.AntiNoclipBypass then App.Shield.BypassClientAntiNoclip(newChar, true) end
        if State.AntiJumpCooldown then App.Shield.BypassAntiJump(newChar, true) end
        if State.FEInvisible then App.Shield.StartFEInvisible("toggle") end
        S.DiedConn = hum.Died:Connect(function()
            if State.AutoRespawn and App.Running and App.Weapons and App.Weapons.PerformFastRespawn then
                local now = os.clock()
                if (now - S.LastRespawnClock) > 0.35 then
                    S.LastRespawnClock = now
                    Janitor.Delay(0.15, function()
                        if App.Running and State.AutoRespawn then
                            pcall(App.Weapons.PerformFastRespawn)
                        end
                    end)
                end
            end
        end)
    end

    local Scheduler = {}

    function Scheduler.SetViewTarget(plr)
        H.clearViewConns()
        S.ViewTarget = plr
        local cam = App.GetCamera()
        if not cam then return end

        if not plr or plr == App.LocalPlayer then
            S.ViewTarget = nil
            local lHum = App.GetHum(App.GetChar(App.LocalPlayer))
            if lHum then cam.CameraSubject = lHum end
            return
        end

        local tHum = App.GetHum(App.GetChar(plr))
        if tHum and tHum.Health > 0 then
            cam.CameraSubject = tHum
        else
            Bus.Emit("Alert", "View", plr.Name .. " has no active character", "warn")
            Scheduler.SetViewTarget(nil)
            return
        end

        table.insert(S.ViewConns, plr.CharacterAdded:Connect(function(newChar)
            local nh = newChar:WaitForChild("Humanoid", 4)
            if S.ViewTarget == plr and nh then
                local c = App.GetCamera()
                if c then c.CameraSubject = nh end
            end
        end))
        table.insert(S.ViewConns, Services.Players.PlayerRemoving:Connect(function(leftPlr)
            if leftPlr == plr then Scheduler.SetViewTarget(nil) end
        end))
    end

    function Scheduler.Start()
        if S.Started then return end
        S.Started = true

        local cam = App.GetCamera()
        if cam and type(cam.FieldOfView) == "number" then
            S.InitialFOV = cam.FieldOfView
        end

        if App.Shield and (State.AntiTaze or State.AntiArrest) then App.Shield.InstallAntiTaze() end
        if State.AntiRiotShield and App.Combat and App.Combat.ApplyAntiRiotShield then
            App.Combat.ApplyAntiRiotShield(true)
        end
        if State.FenceGodmode then App.World.SetFenceGodmode(true) end
        if State.OpenAllDoors then App.World.SetOpenAllDoors(true) end
        if State.AntiFling then App.World.SafeSetAntiFlingEnabled(true) end
        if App.Killfeed then App.Killfeed.SetupWatcher() end
        if App.Visuals then App.Visuals.InitC4Watchers() end

        table.insert(S.StopHooks, Bus.On("StateChanged", H.onStateChanged))

        if App.LocalPlayer.Character then task.spawn(H.onLocalCharAdded, App.LocalPlayer.Character) end
        if App.LocalPlayer and App.LocalPlayer.CharacterAdded then
            table.insert(S.StopHooks, Janitor.Add(App.LocalPlayer.CharacterAdded:Connect(H.onLocalCharAdded)))
        end

        if Services.UserInputService and Services.UserInputService.JumpRequest then
            table.insert(S.StopHooks, Janitor.Add(Services.UserInputService.JumpRequest:Connect(function()
                if not App.Running or not State.InfiniteJump then return end
                local hum = App.GetHum(App.GetChar(App.LocalPlayer))
                if hum and hum.Health > 0 and not hum.Sit then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)))
        end

        table.insert(S.StopHooks, Janitor.Add(Services.RunService.Stepped:Connect(function(_, dt)
            if not App.Running then return end
            local char = App.GetChar(App.LocalPlayer)
            local hrp = App.GetRoot(char)
            local hum = App.GetHum(char)
            App.World.StepNoclip(char)
            App.World.StepCharacterFly(char)
            App.World.UpdateVehicles(dt)
            H.applyRegionOrCustomSpeed(hum, hrp)
            H.applyJumpPower(hum)
        end)))

        table.insert(S.StopHooks, Janitor.Add(Services.RunService.Heartbeat:Connect(function(dt)
            if not App.Running then return end
            local now = os.clock()
            local char = App.GetChar(App.LocalPlayer)
            local hrp = App.GetRoot(char)
            local hum = App.GetHum(char)

            if State.AntiTaze or State.AntiArrest then App.Shield.PurgeTaseAndRagdoll() end
            App.World.CheckAntiKillPlane(hrp)
            App.Visuals.UpdateHitboxExpander()

            -- Run combat BEFORE shield desync shift so LOS, range, & RagebotPeekShield use real position!
            if char and hrp and hum then
                H.stepHeartbeatCombat(now, char, hrp, hum)
            end

            App.Shield.StepHeartbeatShield(hrp, dt)
            App.Shield.StepAntiInvisible()
            App.World.StepAntiFlingPlayers()

            H.stepAutoCriminal(now)
            App.World.StepAutoDetonateC4(now)
            App.World.AutoHealAndArmor()
            App.World.CollectAutoPickups()
            App.Anomaly.Evaluate(now)
        end)))

        local camPrio = (Enum and Enum.RenderPriority and Enum.RenderPriority.Camera and tonumber(Enum.RenderPriority.Camera.Value)) or 200
        Janitor.BindRender("KX_PreCamDesync", camPrio - 1, function()
            if not App.Running then return end
            App.Shield.StepRenderDesync(App.GetRoot(App.GetChar(App.LocalPlayer)))
        end)

        table.insert(S.StopHooks, Janitor.Add(Services.RunService.RenderStepped:Connect(function(dt)
            if not App.Running then return end
            H.stepAimAssist(dt)
            if App.Combat and App.Combat.ClearFrameCache then pcall(App.Combat.ClearFrameCache) end
            App.Visuals.UpdateRenderESP()
        end)))
    end

    function Scheduler.Stop()
        if not S.Started then return end
        S.Started = false
        Janitor.UnbindRender("KX_PreCamDesync")
        Scheduler.SetViewTarget(nil)
        if S.DiedConn then
            pcall(function() S.DiedConn:Disconnect() end)
            S.DiedConn = nil
        end

        for i = #S.StopHooks, 1, -1 do
            local hk = S.StopHooks[i]
            S.StopHooks[i] = nil
            if type(hk) == "function" then
                pcall(hk)
            elseif hk and hk.Disconnect then
                pcall(function() hk:Disconnect() end)
            end
        end

        App.World.CleanupFly()
        App.World.RestoreSeats()
        App.World.SetFenceGodmode(false)
        App.World.SetOpenAllDoors(false)
        App.World.SafeSetAntiFlingEnabled(false)
        App.World.RestoreNoclipCollide()
        App.Shield.RestoreAntiTaze()
        App.Shield.BypassClientAntiNoclip(nil, false)
        App.Shield.BypassAntiJump(nil, false)
        App.Shield.CleanCharacterEffects()
        App.Visuals.RemoveAllESP()

        local lHum = App.GetHum(App.GetChar(App.LocalPlayer))
        if lHum then
            pcall(function()
                lHum.PlatformStand = false
                if State.MaxSpeed then lHum.WalkSpeed = 16 end
                if State.JumpPowerEnabled then lHum.JumpPower = 50 end
            end)
        end
        if S.InitialFOV then
            local cam = App.GetCamera()
            if cam then pcall(function() cam.FieldOfView = S.InitialFOV end) end
        end
    end

    Janitor.AddCleanup(Scheduler.Stop)
    App.Scheduler = Scheduler
end


-- ============================================================================
-- // MODULE 4: ANIMATED HUD, KX ADMIN AUTOCOMPLETE, SHIELD PILL & OBSIDIAN 6-TAB HUB
-- ============================================================================

-- ============================================================================
-- MODULE 4: 04_hud_and_hub_ui.lua
-- Prison Life 2026 - KX Edition V3 (PC & Mobile)
-- UI Widget Kit, Responsive Collision-Free HUD, KX Bar & Drawers, 6-Tab Hub
-- ============================================================================

do
    local ctx = {
        Draggables = {},
        AlertItems = {},
        KillfeedItems = {},
        CmdLogEntries = {},
        PinnedChips = {},
        TabData = {},
        TabOrder = { "Shield", "Combat", "Guns", "Prison", "Move", "Settings" },
        SyncFns = {},
        WidgetFilterEntries = {},
        KeybindRows = {},
        DropdownControls = {},
        RightBtns = {},
        FlyBtns = {},
        Badges = {},
        LastShieldText = "",
        DisplayShieldHP = 180,
        LastKillTime = 0,
    }

    local clampNum = rawget(math, "clamp") or function(v, lo, hi)
        if v < lo then return lo end
        if v > hi then return hi end
        return v
    end

    local function clearTbl(t)
        local tc = rawget(table, "clear")
        if tc then
            tc(t)
            return
        end
        for k in pairs(t) do
            t[k] = nil
        end
    end

    local function safeCall(fn, ...)
        if type(fn) == "function" then
            return pcall(fn, ...)
        end
        return false
    end

    local function getSafeTopY()
        local sa = App.SafeArea or {}
        local insetTop = sa.InsetTop or 36
        if insetTop >= 52 then
            return insetTop + 6
        end
        return math.max(58, insetTop + 10)
    end

    local function getIYPillTopY()
        local sa = App.SafeArea or {}
        local insetTop = sa.InsetTop or 36
        return math.max(getSafeTopY(), insetTop + 30)
    end

    local function isCompactLayout()
        local sa = App.SafeArea
        if not sa then
            return App.IsMobileInput()
        end
        local vp = sa.Viewport
        if sa.IsPhone or sa.IsCompact then
            return true
        end
        if vp and vp.X < 960 then
            return true
        end
        return false
    end

    local function getViewport()
        local sa = App.SafeArea
        if sa and sa.Viewport then
            return sa.Viewport
        end
        return Vector2.new(1280, 720)
    end

    local CONTAINER_CLASSES = {
        Frame = true,
        ScrollingFrame = true,
        CanvasGroup = true,
        TextButton = true,
        ImageButton = true,
        TextBox = true,
    }

    -- ========================================================================
    -- BLOCK 1: UI WIDGET KIT & MAIN SCREENGUI
    -- ========================================================================
    do
        local function createGui(className, props, children)
            local inst = Instance.new(className)
            if CONTAINER_CLASSES[className] then
                if not props or props.Active == nil then
                    inst.Active = true
                end
            end
            if inst:IsA("GuiObject") then
                if not props or props.BorderSizePixel == nil then
                    inst.BorderSizePixel = 0
                end
            end
            local parent = nil
            if props then
                parent = props.Parent
                for k, v in pairs(props) do
                    if k ~= "Parent" then
                        inst[k] = v
                    end
                end
            end
            if type(children) == "table" then
                for _, child in ipairs(children) do
                    if child then
                        child.Parent = inst
                    end
                end
            end
            if parent ~= nil then
                inst.Parent = parent
            end
            return inst
        end

        local function addCorner(parent, radius)
            local r = radius or 8
            return createGui("UICorner", {
                CornerRadius = UDim.new(0, r),
                Parent = parent,
            })
        end

        local function addStroke(parent, color, thickness, transparency)
            return createGui("UIStroke", {
                Color = color or Palette.Border,
                Thickness = thickness or 1,
                Transparency = transparency or 0,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = parent,
            })
        end

        local function addPad(parent, l, r, t, b)
            local pl, pr, pt, pb
            if r == nil and t == nil and b == nil then
                local a = l or 6
                pl, pr, pt, pb = a, a, a, a
            elseif t == nil and b == nil then
                pl = l or 6
                pr = pl
                pt = r or 6
                pb = pt
            else
                pl = l or 0
                pr = r or pl
                pt = t or pl
                pb = b or pt
            end
            return createGui("UIPadding", {
                PaddingLeft = UDim.new(0, pl),
                PaddingRight = UDim.new(0, pr),
                PaddingTop = UDim.new(0, pt),
                PaddingBottom = UDim.new(0, pb),
                Parent = parent,
            })
        end

        local function makeApplyPosition(frame, opts)
            return function()
                local id = opts and opts.id
                local saved = id and State.HUDPositions and State.HUDPositions[id]
                if saved and type(saved.x) == "number" and type(saved.y) == "number" then
                    local sz = frame.AbsoluteSize
                    local w = (sz.X > 2) and sz.X or (opts.defaultW or 90)
                    local h = (sz.Y > 2) and sz.Y or (opts.defaultH or 36)
                    local cx, cy = App.SafeArea.ClampPoint(saved.x, saved.y, w, h)
                    frame.AnchorPoint = Vector2.new(0, 0)
                    frame.Position = UDim2.fromOffset(cx, cy)
                    return
                end
                if opts and type(opts.defaultPos) == "function" then
                    local anchor, pos = opts.defaultPos()
                    if anchor then
                        frame.AnchorPoint = anchor
                    end
                    if pos then
                        frame.Position = pos
                    end
                elseif opts and opts.fallbackAnchor and opts.fallbackPos then
                    frame.AnchorPoint = opts.fallbackAnchor
                    frame.Position = opts.fallbackPos
                end
            end
        end

        local activeDragState = nil
        local globalDragConn = nil

        local function ensureGlobalDragConn()
            if globalDragConn then
                return
            end
            globalDragConn = Janitor.Add(Services.UserInputService.InputChanged:Connect(function(inp)
                local st = activeDragState
                if not st or not st.dragging or State.LockHUDLayout then
                    return
                end
                local t = inp.UserInputType
                local isMove = (t == Enum.UserInputType.MouseMovement) or (t == Enum.UserInputType.Touch and inp == st.dragInput)
                if not isMove then
                    return
                end
                local dx = inp.Position.X - st.startMouse.X
                local dy = inp.Position.Y - st.startMouse.Y
                if not st.moved and (dx * dx + dy * dy) >= (st.threshold * st.threshold) then
                    st.moved = true
                    if st.opts.onDragStart then
                        st.opts.onDragStart(st.frame)
                    end
                end
                if st.moved then
                    local sz = st.frame.AbsoluteSize
                    local w = (sz.X > 2) and sz.X or (st.opts.defaultW or 90)
                    local h = (sz.Y > 2) and sz.Y or (st.opts.defaultH or 36)
                    local cx, cy = App.SafeArea.ClampPoint(st.startLeft + dx, st.startTop + dy, w, h)
                    st.frame.AnchorPoint = Vector2.new(0, 0)
                    st.frame.Position = UDim2.fromOffset(cx, cy)
                    if st.opts.id and State.HUDPositions then
                        State.HUDPositions[st.opts.id] = { x = cx, y = cy }
                    end
                end
            end))
        end

        local function bindDrag(frame, handle, opts)
            opts = opts or {}
            handle = handle or frame
            opts.fallbackAnchor = opts.fallbackAnchor or frame.AnchorPoint
            opts.fallbackPos = opts.fallbackPos or frame.Position
            local applyPos = makeApplyPosition(frame, opts)
            local entry = {
                id = opts.id,
                frame = frame,
                apply = applyPos,
            }
            if opts.id then
                ctx.Draggables[opts.id] = entry
            end

            local state = {
                frame = frame,
                opts = opts,
                dragging = false,
                moved = false,
                dragInput = nil,
                startMouse = Vector2.new(0, 0),
                startLeft = 0,
                startTop = 0,
                threshold = opts.threshold or (App.IsMobileInput() and 8 or 5),
            }

            local function finishDrag(inp)
                if not state.dragging or (state.dragInput and inp ~= state.dragInput) then
                    return
                end
                state.dragging = false
                state.dragInput = nil
                if activeDragState == state then
                    activeDragState = nil
                end
                if state.moved then
                    if opts.onDragEnd then
                        opts.onDragEnd(frame)
                    end
                elseif opts.onTap then
                    opts.onTap()
                end
            end

            ensureGlobalDragConn()
            Janitor.Add(handle.InputBegan:Connect(function(inp)
                local t = inp.UserInputType
                if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
                    return
                end
                if state.dragging or (activeDragState and activeDragState.dragging and activeDragState.frame == frame) then
                    return
                end
                state.dragging = true
                state.moved = false
                state.dragInput = inp
                state.startMouse = Vector2.new(inp.Position.X, inp.Position.Y)
                local absPos = frame.AbsolutePosition
                state.startLeft = absPos.X
                state.startTop = absPos.Y
                activeDragState = state

                local changedConn
                changedConn = Janitor.Add(inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End or inp.UserInputState == Enum.UserInputState.Cancel then
                        if changedConn and changedConn.Disconnect then
                            changedConn:Disconnect()
                        end
                        finishDrag(inp)
                    end
                end))
            end))

            return entry
        end

        UI.Create = createGui
        UI.Corner = addCorner
        UI.Stroke = addStroke
        UI.Pad = addPad
        UI.BindDrag = bindDrag

        local mainGui = createGui("ScreenGui", {
            Name = "PL2026_KX_V3",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 100,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = App.GetSafeGuiParent(),
        })
        Janitor.Track(mainGui)
        App.MainGui = mainGui

        local espOverlay = createGui("Frame", {
            Name = "KX_ESPContainer",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Active = false,
            ZIndex = 1,
            Parent = mainGui,
        })
        Janitor.Track(espOverlay)
        App.ESPContainer = espOverlay

        App.MobileFlyInput = (App.World and App.World.MobileFlyInput) or App.MobileFlyInput or { Up = 0, Down = 0 }
        if App.World and not App.World.MobileFlyInput then
            App.World.MobileFlyInput = App.MobileFlyInput
        end
        ctx.MainGui = mainGui
    end

    -- ========================================================================
    -- BLOCK 2: FOV RING & 4-TICK HITMARKER
    -- ========================================================================
    do
        local fovRing = UI.Create("Frame", {
            Name = "FOVRing",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(220, 220),
            BackgroundTransparency = 1,
            Active = false,
            Visible = false,
            ZIndex = 5,
            Parent = ctx.MainGui,
        })
        UI.Corner(fovRing, 9999)
        local fovStroke = UI.Stroke(fovRing, Palette.NeonBlue, 1.4, 0.25)

        local hitGroup = UI.Create("Frame", {
            Name = "HitmarkerGroup",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(32, 32),
            BackgroundTransparency = 1,
            Active = false,
            Visible = false,
            ZIndex = 12,
            Parent = ctx.MainGui,
        })
        App.Anim.EnsureScale(hitGroup)

        local tickDefs = {
            { x = 10, y = 10, rot = -45 },
            { x = 22, y = 10, rot = 45 },
            { x = 10, y = 22, rot = 45 },
            { x = 22, y = 22, rot = -45 },
        }
        local hitTicks = {}
        for idx, td in ipairs(tickDefs) do
            local bar = UI.Create("Frame", {
                Name = "Tick" .. idx,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromOffset(td.x, td.y),
                Size = UDim2.fromOffset(2, 8),
                Rotation = td.rot,
                BackgroundColor3 = Palette.TextPrimary,
                BackgroundTransparency = 0,
                Active = false,
                ZIndex = 13,
                Parent = hitGroup,
            })
            UI.Corner(bar, 1)
            UI.Stroke(bar, Palette.BgDark, 1, 0.45)
            hitTicks[idx] = bar
        end

        local function triggerHitmarker(isHead, isKill)
            if not State.Hitmarker then
                return
            end
            local col = Palette.TextPrimary
            if isKill then
                col = Palette.RageCrimson
            elseif isHead then
                col = Palette.StreakGold
            end
            hitGroup.Visible = true
            local sc = App.Anim.EnsureScale(hitGroup)
            sc.Scale = isKill and 1.48 or 1.32
            App.Anim.Play(sc, "HitScale", App.Anim.Spring, { Scale = 1.0 })
            for _, bar in ipairs(hitTicks) do
                bar.BackgroundColor3 = col
                bar.BackgroundTransparency = 0
                App.Anim.Cancel(bar, "HitFade")
                App.Anim.Play(bar, "HitFade", TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1,
                })
            end
            App.Anim.Delay(hitGroup, "HitHide", 0.25, function()
                hitGroup.Visible = false
            end)
        end

        local function updateReticleFrame()
            local vp = getViewport()
            local pos = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
            if App.Targets and App.Targets.GetCursorOrCenterPos then
                local ok, res = pcall(App.Targets.GetCursorOrCenterPos)
                if ok and res then
                    pos = res
                end
            end
            local pOffset = UDim2.fromOffset(pos.X, pos.Y)
            hitGroup.Position = pOffset

            local rageAllRound = State.Ragebot and State.Ragebot360
            local showFov = (State.SilentAim and State.SilentAimShowFOV) and (not State.HubVisible) and (not rageAllRound)
            fovRing.Visible = showFov and true or false
            if showFov then
                local maxDia = math.max(48, math.min(vp.X, vp.Y) * 0.72)
                local rawDia = (State.SilentAimFOV or 110) * 2
                local dia = clampNum(math.min(rawDia, maxDia), 24, maxDia)
                fovRing.Size = UDim2.fromOffset(dia, dia)
                fovRing.Position = pOffset
                fovStroke.Color = State.Ragebot and Palette.RageCrimson or Palette.NeonBlue
            end
        end

        ctx.FOVRing = fovRing
        ctx.FOVStroke = fovStroke
        ctx.HitmarkerGroup = hitGroup
        ctx.TriggerHitmarker = triggerHitmarker
        ctx.UpdateReticleFrame = updateReticleFrame
    end

    -- ========================================================================
    -- BLOCK 3: TOP HUD (COMBO + KX CREST + PINNED PILLS + IY PILL + ALERTS)
    -- ========================================================================
    do
        local PIN_META = {
            Rage = { label = "RAGE", key = "Ragebot", color = Palette.RageCrimson },
            Shield = { label = "SHIELD", key = "ShieldEnabled", color = Palette.NeonBlue },
            Fly = { label = "FLY", key = "Fly", color = Palette.Emerald },
            Noclip = { label = "NOCLIP", key = "Noclip", color = Palette.NeonCyan },
            KillAura = { label = "AURA", key = "KillAura", color = Palette.RageCrimson },
            SilentAim = { label = "SILENT", key = "SilentAim", color = Palette.NeonBlue },
            AutoArrest = { label = "ARREST", key = "AutoArrest", color = Palette.StreakGold },
        }

        local function buildCrestEmblem(crestBtn)
            local wingsLeftTop = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 7, 0.5, -5),
                Size = UDim2.fromOffset(10, 2),
                Rotation = -26,
                BackgroundColor3 = Palette.NeonCyan,
                Active = false,
                ZIndex = 16,
                Parent = crestBtn,
            })
            UI.Corner(wingsLeftTop, 1)

            local wingsLeftBot = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 7, 0.5, 4),
                Size = UDim2.fromOffset(8, 2),
                Rotation = 22,
                BackgroundColor3 = Palette.NeonBlue,
                Active = false,
                ZIndex = 16,
                Parent = crestBtn,
            })
            UI.Corner(wingsLeftBot, 1)

            local wingsRightTop = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(1, -7, 0.5, -5),
                Size = UDim2.fromOffset(10, 2),
                Rotation = 26,
                BackgroundColor3 = Palette.NeonCyan,
                Active = false,
                ZIndex = 16,
                Parent = crestBtn,
            })
            UI.Corner(wingsRightTop, 1)

            local wingsRightBot = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(1, -7, 0.5, 4),
                Size = UDim2.fromOffset(8, 2),
                Rotation = -22,
                BackgroundColor3 = Palette.NeonBlue,
                Active = false,
                ZIndex = 16,
                Parent = crestBtn,
            })
            UI.Corner(wingsRightBot, 1)

            local shieldCore = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(22, 22),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.08,
                Active = false,
                ZIndex = 17,
                Parent = crestBtn,
            })
            UI.Corner(shieldCore, 6)
            UI.Stroke(shieldCore, Palette.NeonBlue, 1.2, 0.2)

            local crownLine = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 2),
                Size = UDim2.fromOffset(12, 2),
                BackgroundColor3 = Palette.NeonCyan,
                Active = false,
                ZIndex = 18,
                Parent = shieldCore,
            })
            UI.Corner(crownLine, 1)

            UI.Create("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 1),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBlack,
                Text = "KX",
                TextSize = 11,
                TextColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 19,
                Parent = shieldCore,
            })
        end

        local function buildTopLeftCluster()
            local cluster = UI.Create("Frame", {
                Name = "TopLeftCluster",
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.fromOffset(14, getSafeTopY()),
                Size = UDim2.fromOffset(152, 38),
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                ZIndex = 15,
                Parent = ctx.MainGui,
            })
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = cluster,
            })

            local topRow = UI.Create("Frame", {
                Name = "TopRow",
                LayoutOrder = 1,
                Size = UDim2.fromOffset(152, 38),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                ZIndex = 15,
                Parent = cluster,
            })
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = topRow,
            })

            local comboBtn = UI.Create("TextButton", {
                Name = "ComboBtn",
                LayoutOrder = 1,
                Size = UDim2.fromOffset(106, 36),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.14,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 16,
                Parent = topRow,
            })
            UI.Corner(comboBtn, 18)
            local comboStroke = UI.Stroke(comboBtn, Palette.Border, 1.3, 0.15)
            App.Anim.EnsureScale(comboBtn)

            local comboDot = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 12, 0.5, 0),
                Size = UDim2.fromOffset(8, 8),
                Rotation = 45,
                BackgroundColor3 = Palette.NeonCyan,
                Active = false,
                ZIndex = 17,
                Parent = comboBtn,
            })
            UI.Corner(comboDot, 2)

            local comboLabel = UI.Create("TextLabel", {
                Position = UDim2.fromOffset(25, 0),
                Size = UDim2.new(1, -32, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = ".combo1",
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 17,
                Parent = comboBtn,
            })

            local crestBtn = UI.Create("TextButton", {
                Name = "KXCrestBtn",
                LayoutOrder = 2,
                Size = UDim2.fromOffset(36, 36),
                BackgroundColor3 = Palette.BgElevated,
                BackgroundTransparency = 0.08,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 16,
                Parent = topRow,
            })
            UI.Corner(crestBtn, 10)
            local crestStroke = UI.Stroke(crestBtn, Palette.NeonBlue, 1.8, 0.08)
            App.Anim.EnsureScale(crestBtn)
            buildCrestEmblem(crestBtn)

            local pinnedRow = UI.Create("Frame", {
                Name = "PinnedPillsRow",
                LayoutOrder = 2,
                Size = UDim2.fromOffset(10, 24),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Visible = State.ShowPinnedPills == true,
                ZIndex = 15,
                Parent = cluster,
            })
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = pinnedRow,
            })

            local function getClusterDefaultPos()
                return Vector2.new(0, 0), UDim2.fromOffset(14, getSafeTopY())
            end

            UI.BindDrag(cluster, comboBtn, {
                id = "TopLeftCluster",
                defaultW = 152,
                defaultH = 66,
                defaultPos = getClusterDefaultPos,
                onTap = function()
                    if ctx.FlashCombo then
                        ctx.FlashCombo()
                    end
                    if App.Weapons and App.Weapons.ExecuteCombo1 then
                        App.Weapons.ExecuteCombo1()
                    end
                end,
            })
            UI.BindDrag(cluster, crestBtn, {
                id = "TopLeftCluster",
                defaultW = 152,
                defaultH = 66,
                defaultPos = getClusterDefaultPos,
                onTap = function()
                    if App.Hub and App.Hub.SetVisible then
                        App.Hub.SetVisible(not State.HubVisible)
                    end
                end,
            })

            local function syncPinnedChips()
                for _, item in ipairs(ctx.PinnedChips) do
                    local active = State[item.key] == true
                    if item.lastActive ~= active then
                        item.lastActive = active
                        local targetBg = active and item.color or Palette.BgDark
                        local targetBgTr = active and 0.72 or 0.16
                        local targetStrk = active and item.color or Palette.Border
                        local targetTxt = active and Palette.TextPrimary or Palette.TextMuted
                        App.Anim.Play(item.btn, "PinBg", App.Anim.Snappy, {
                            BackgroundColor3 = targetBg,
                            BackgroundTransparency = targetBgTr,
                        })
                        App.Anim.Play(item.stroke, "PinStroke", App.Anim.Snappy, {
                            Color = targetStrk,
                            Transparency = active and 0.08 or 0.35,
                        })
                        item.label.TextColor3 = targetTxt
                    end
                end
            end

            local function rebuildPinnedPills()
                for _, child in ipairs(pinnedRow:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                clearTbl(ctx.PinnedChips)
                local list = type(State.PinnedPills) == "table" and State.PinnedPills or {}
                local count = 0
                for idx, pinName in ipairs(list) do
                    local meta = PIN_META[pinName]
                    if meta and count < 4 then
                        count = count + 1
                        local chip = UI.Create("TextButton", {
                            Name = "Pin_" .. pinName,
                            LayoutOrder = idx,
                            Size = UDim2.fromOffset(0, 22),
                            AutomaticSize = Enum.AutomaticSize.X,
                            BackgroundColor3 = Palette.BgDark,
                            BackgroundTransparency = 0.16,
                            AutoButtonColor = false,
                            Text = "",
                            ZIndex = 16,
                            Parent = pinnedRow,
                        })
                        UI.Corner(chip, 11)
                        UI.Pad(chip, 9, 9, 0, 0)
                        local cStroke = UI.Stroke(chip, Palette.Border, 1.1, 0.35)
                        local cLbl = UI.Create("TextLabel", {
                            Size = UDim2.fromOffset(0, 22),
                            AutomaticSize = Enum.AutomaticSize.X,
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            Text = meta.label,
                            TextSize = 10,
                            TextColor3 = Palette.TextMuted,
                            Active = false,
                            ZIndex = 17,
                            Parent = chip,
                        })
                        App.Anim.BindButton(chip)
                        Janitor.Add(chip.MouseButton1Click:Connect(function()
                            local nextVal = not (State[meta.key] == true)
                            App.SetState(meta.key, nextVal)
                            if meta.key == "ShieldEnabled" and App.Shield and App.Shield.SetEnabled then
                                safeCall(App.Shield.SetEnabled, nextVal)
                            elseif meta.key == "Noclip" and not nextVal and App.World and App.World.RestoreNoclipCollide then
                                safeCall(App.World.RestoreNoclipCollide)
                            end
                        end))
                        table.insert(ctx.PinnedChips, {
                            name = pinName,
                            key = meta.key,
                            color = meta.color,
                            btn = chip,
                            stroke = cStroke,
                            label = cLbl,
                        })
                    end
                end
                pinnedRow.Visible = (State.ShowPinnedPills == true) and (State.ShowComboButton ~= false) and (count > 0)
                syncPinnedChips()
                if ctx.SyncKillfeedAnchor then
                    ctx.SyncKillfeedAnchor()
                end
            end

            ctx.TopLeftCluster = cluster
            ctx.ComboBtn = comboBtn
            ctx.ComboStroke = comboStroke
            ctx.ComboDot = comboDot
            ctx.ComboLabel = comboLabel
            ctx.CrestBtn = crestBtn
            ctx.CrestStroke = crestStroke
            ctx.PinnedRow = pinnedRow
            ctx.RebuildPinnedPills = rebuildPinnedPills
            ctx.SyncPinnedChips = syncPinnedChips
            rebuildPinnedPills()
        end

        local function buildIYPillAndAlerts()
            local iyBtn = UI.Create("TextButton", {
                Name = "IYPill",
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, getIYPillTopY()),
                Size = UDim2.fromOffset(34, 24),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.14,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBlack,
                Text = "IY",
                TextSize = 11,
                TextColor3 = Palette.NeonCyan,
                Visible = State.ShowIYPill == true,
                ZIndex = 16,
                Parent = ctx.MainGui,
            })
            UI.Corner(iyBtn, 12)
            local iyStroke = UI.Stroke(iyBtn, Palette.NeonCyan, 1.2, 0.25)
            App.Anim.EnsureScale(iyBtn)

            UI.BindDrag(iyBtn, iyBtn, {
                id = "IYPill",
                defaultW = 34,
                defaultH = 24,
                defaultPos = function()
                    return Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, getIYPillTopY())
                end,
                onTap = function()
                    if ctx.ToggleCmdDrawer then
                        ctx.ToggleCmdDrawer(true, "Output")
                    end
                end,
            })

            local alertHost = UI.Create("Frame", {
                Name = "AlertBannerHost",
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, getIYPillTopY() + 28),
                Size = UDim2.fromOffset(isCompactLayout() and 236 or 320, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Active = false,
                Visible = false,
                ZIndex = 24,
                Parent = ctx.MainGui,
            })
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = alertHost,
            })

            ctx.IYPill = iyBtn
            ctx.IYStroke = iyStroke
            ctx.AlertHost = alertHost
        end

        buildTopLeftCluster()
        buildIYPillAndAlerts()
    end

    -- ========================================================================
    -- BLOCK 4: KX ADMIN BAR, AUTOCOMPLETE & 2-TAB COMMAND/OUTPUT DRAWER
    -- ========================================================================
    do
        local FALLBACK_CMDS = {
            { cmd = "re", aliases = { "respawn" }, usage = ";re", desc = "Respawn in place", cat = "Player" },
            { cmd = "guns", aliases = { "loadout" }, usage = ";guns", desc = "Grab selected guns", cat = "Weapons" },
            { cmd = "crim", aliases = { "criminal" }, usage = ";crim", desc = "Switch to Criminals", cat = "Team" },
            { cmd = "guard", aliases = { "cop" }, usage = ";guard", desc = "Switch to Guards", cat = "Team" },
            { cmd = "inmate", aliases = {}, usage = ";inmate", desc = "Switch to Inmates", cat = "Team" },
            { cmd = "fly", aliases = {}, usage = ";fly", desc = "Toggle Fly", cat = "Move" },
            { cmd = "noclip", aliases = { "nc" }, usage = ";noclip", desc = "Toggle Noclip", cat = "Move" },
            { cmd = "shield", aliases = {}, usage = ";shield", desc = "Toggle Riot Shield", cat = "Defense" },
            { cmd = "rage", aliases = { "ragebot" }, usage = ";rage", desc = "Toggle Ragebot", cat = "Combat" },
            { cmd = "arrestall", aliases = { "aa" }, usage = ";arrestall", desc = "Arrest criminals", cat = "Prison" },
            { cmd = "loopkill", aliases = { "lk" }, usage = ";lk <plr>", desc = "Loopkill target", cat = "Combat" },
            { cmd = "tp", aliases = { "goto" }, usage = ";tp <loc|plr>", desc = "Teleport", cat = "Prison" },
            { cmd = "cmds", aliases = { "help" }, usage = ";cmds", desc = "Open command list", cat = "System" },
        }
        local QUICK_CHIPS = { ";re", ";guns", ";crim", ";guard", ";fly", ";shield", ";arrestall", ";cmds" }

        local function buildKXSystem()
            local drawerTab = "Commands"
            local drawerOpen = false
            local barExpanded = not isCompactLayout()
            local autoMatches = {}
            local selectedIdx = 1

            local kxBar = UI.Create("Frame", {
                Name = "KXBarFrame",
                AnchorPoint = Vector2.new(1, 0),
                Position = isCompactLayout() and UDim2.new(1, -146, 0, getSafeTopY()) or UDim2.new(1, -14, 0, getSafeTopY() + 34),
                Size = barExpanded and UDim2.fromOffset(224, 38) or UDim2.fromOffset(96, 32),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.12,
                ClipsDescendants = true,
                Visible = State.ShowKXBar ~= false,
                ZIndex = 20,
                Parent = ctx.MainGui,
            })
            UI.Corner(kxBar, 12)
            local kxStroke = UI.Stroke(kxBar, Palette.NeonBlue, 1.3, 0.2)

            local kxHandle = UI.Create("TextButton", {
                Name = "KXHandle",
                Position = UDim2.fromOffset(4, 4),
                Size = UDim2.fromOffset(barExpanded and 40 or 88, barExpanded and 30 or 24),
                BackgroundColor3 = Palette.BgElevated,
                BackgroundTransparency = 0.2,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBlack,
                Text = barExpanded and "KX" or "> CMD",
                TextSize = 11,
                TextColor3 = Palette.NeonCyan,
                ZIndex = 21,
                Parent = kxBar,
            })
            UI.Corner(kxHandle, 8)
            UI.Stroke(kxHandle, Palette.NeonBlue, 1, 0.45)

            local kxInput = UI.Create("TextBox", {
                Name = "KXInput",
                Position = UDim2.fromOffset(48, 4),
                Size = UDim2.new(1, -84, 1, -8),
                BackgroundColor3 = Palette.BgInset,
                BackgroundTransparency = 0.2,
                ClearTextOnFocus = false,
                Font = Enum.Font.GothamMedium,
                PlaceholderText = ";cmd or player",
                PlaceholderColor3 = Palette.TextSubtle,
                Text = "",
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Palette.TextPrimary,
                Visible = barExpanded,
                ZIndex = 21,
                Parent = kxBar,
            })
            UI.Corner(kxInput, 8)
            UI.Pad(kxInput, 8, 6, 0, 0)

            local drawerToggleBtn = UI.Create("TextButton", {
                Name = "DrawerToggleBtn",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -5, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                BackgroundColor3 = Palette.BgElevated,
                BackgroundTransparency = 0.15,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "=",
                TextSize = 14,
                TextColor3 = Palette.NeonCyan,
                Visible = barExpanded,
                ZIndex = 21,
                Parent = kxBar,
            })
            UI.Corner(drawerToggleBtn, 8)
            App.Anim.BindButton(drawerToggleBtn)

            local autoFrame = UI.Create("Frame", {
                Name = "KXAutoFrame",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -14, 0, getSafeTopY() + 88),
                Size = UDim2.fromOffset(232, 0),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.06,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 28,
                Parent = ctx.MainGui,
            })
            UI.Corner(autoFrame, 10)
            UI.Stroke(autoFrame, Palette.NeonBlue, 1.2, 0.25)
            UI.Pad(autoFrame, 6, 6, 6, 6)
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = autoFrame,
            })

            local drawer = UI.Create("Frame", {
                Name = "KXDrawer",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -14, 0, getSafeTopY() + 88),
                Size = UDim2.fromOffset(308, 240),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.05,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 27,
                Parent = ctx.MainGui,
            })
            UI.Corner(drawer, 12)
            UI.Stroke(drawer, Palette.Border, 1.3, 0.15)
            App.Anim.EnsureScale(drawer)

            local drawerHead = UI.Create("Frame", {
                Name = "DrawerHead",
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Palette.BgElevated,
                BackgroundTransparency = 0.15,
                ZIndex = 28,
                Parent = drawer,
            })
            UI.Corner(drawerHead, 12)

            local tabCmdBtn = UI.Create("TextButton", {
                Position = UDim2.fromOffset(8, 5),
                Size = UDim2.fromOffset(88, 28),
                BackgroundColor3 = Palette.NeonBlue,
                BackgroundTransparency = 0.72,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "Commands",
                TextSize = 11,
                TextColor3 = Palette.TextPrimary,
                ZIndex = 29,
                Parent = drawerHead,
            })
            UI.Corner(tabCmdBtn, 8)
            local tabCmdStroke = UI.Stroke(tabCmdBtn, Palette.NeonBlue, 1.1, 0.15)

            local tabOutBtn = UI.Create("TextButton", {
                Position = UDim2.fromOffset(102, 5),
                Size = UDim2.fromOffset(72, 28),
                BackgroundColor3 = Palette.BgInset,
                BackgroundTransparency = 0.25,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "Output",
                TextSize = 11,
                TextColor3 = Palette.TextMuted,
                ZIndex = 29,
                Parent = drawerHead,
            })
            UI.Corner(tabOutBtn, 8)
            local tabOutStroke = UI.Stroke(tabOutBtn, Palette.Border, 1.1, 0.45)

            local clearOutBtn = UI.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -44, 0.5, 0),
                Size = UDim2.fromOffset(52, 26),
                BackgroundColor3 = Palette.BgInset,
                BackgroundTransparency = 0.2,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "Clear",
                TextSize = 10,
                TextColor3 = Palette.TextMuted,
                Visible = false,
                ZIndex = 29,
                Parent = drawerHead,
            })
            UI.Corner(clearOutBtn, 7)

            local closeDrawerBtn = UI.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                BackgroundColor3 = Palette.BgInset,
                BackgroundTransparency = 0.15,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "X",
                TextSize = 12,
                TextColor3 = Palette.RedAlert,
                ZIndex = 29,
                Parent = drawerHead,
            })
            UI.Corner(closeDrawerBtn, 8)
            App.Anim.BindButton(closeDrawerBtn)

            local cmdScroll = UI.Create("ScrollingFrame", {
                Name = "CmdBrowserScroll",
                Position = UDim2.fromOffset(0, 40),
                Size = UDim2.new(1, 0, 1, -42),
                BackgroundTransparency = 1,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Palette.NeonBlue,
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 28,
                Parent = drawer,
            })
            UI.Pad(cmdScroll, 8, 8, 4, 8)
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = cmdScroll,
            })

            local outScroll = UI.Create("ScrollingFrame", {
                Name = "CmdOutputScroll",
                Position = UDim2.fromOffset(0, 40),
                Size = UDim2.new(1, 0, 1, -42),
                BackgroundTransparency = 1,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Palette.NeonCyan,
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false,
                ZIndex = 28,
                Parent = drawer,
            })
            UI.Pad(outScroll, 8, 8, 4, 8)
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = outScroll,
            })

            local function getKXDefaultPos()
                if isCompactLayout() then
                    return Vector2.new(1, 0), UDim2.new(1, -146, 0, getSafeTopY())
                end
                return Vector2.new(1, 0), UDim2.new(1, -14, 0, getSafeTopY() + 34)
            end

            local function positionPopups(targetBarW, targetBarH)
                local vp = getViewport()
                local absPos = kxBar.AbsolutePosition
                local absSz = kxBar.AbsoluteSize
                local barW = targetBarW or ((absSz.X > 10) and absSz.X or (barExpanded and 224 or 96))
                local barH = targetBarH or ((absSz.Y > 10) and absSz.Y or (barExpanded and 38 or 32))
                local rightEdge = (absSz.X > 10) and (absPos.X + absSz.X) or (absPos.X + barW)
                local dW = math.min(312, vp.X - 24)
                local dH = clampNum(vp.Y - 160, 150, 250)
                local rawX = rightEdge - dW
                local rawY = absPos.Y + barH + 6
                if rawY + dH > vp.Y - 82 then
                    rawY = math.max(getSafeTopY(), absPos.Y - dH - 6)
                end
                local cx, cy = App.SafeArea.ClampPoint(rawX, rawY, dW, dH)
                drawer.AnchorPoint = Vector2.new(0, 0)
                drawer.Size = UDim2.fromOffset(dW, dH)
                drawer.Position = UDim2.fromOffset(cx, cy)

                local aW = math.max(220, barW)
                local aH = autoFrame.Size.Y.Offset
                local ax, ay = App.SafeArea.ClampPoint(rightEdge - aW, absPos.Y + barH + 5, aW, math.max(36, aH))
                autoFrame.AnchorPoint = Vector2.new(0, 0)
                autoFrame.Position = UDim2.fromOffset(ax, ay)
            end

            local function setBarExpanded(exp, instant)
                barExpanded = exp and true or false
                local compact = isCompactLayout()
                local w = barExpanded and (compact and 220 or 224) or 96
                local h = barExpanded and 38 or 32
                kxHandle.Size = UDim2.fromOffset(barExpanded and 40 or 88, barExpanded and 30 or 24)
                kxHandle.Text = barExpanded and "KX" or "> CMD"
                kxInput.Visible = barExpanded
                drawerToggleBtn.Visible = barExpanded
                if instant then
                    kxBar.Size = UDim2.fromOffset(w, h)
                else
                    App.Anim.Play(kxBar, "KXSize", App.Anim.Spring, { Size = UDim2.fromOffset(w, h) })
                end
                positionPopups(w, h)
            end

            local function setDrawerTab(tabName)
                drawerTab = (tabName == "Output") and "Output" or "Commands"
                local isCmd = (drawerTab == "Commands")
                cmdScroll.Visible = isCmd
                outScroll.Visible = not isCmd
                clearOutBtn.Visible = not isCmd
                tabCmdBtn.BackgroundColor3 = isCmd and Palette.NeonBlue or Palette.BgInset
                tabCmdBtn.BackgroundTransparency = isCmd and 0.72 or 0.25
                tabCmdBtn.TextColor3 = isCmd and Palette.TextPrimary or Palette.TextMuted
                tabCmdStroke.Color = isCmd and Palette.NeonBlue or Palette.Border
                tabOutBtn.BackgroundColor3 = (not isCmd) and Palette.NeonCyan or Palette.BgInset
                tabOutBtn.BackgroundTransparency = (not isCmd) and 0.75 or 0.25
                tabOutBtn.TextColor3 = (not isCmd) and Palette.TextPrimary or Palette.TextMuted
                tabOutStroke.Color = (not isCmd) and Palette.NeonCyan or Palette.Border
            end

            local function toggleCmdDrawer(forceState, forceTab)
                if forceTab then
                    setDrawerTab(forceTab)
                end
                local nextOpen = (forceState ~= nil) and (forceState == true) or (not drawerOpen)
                drawerOpen = nextOpen
                if nextOpen then
                    if not barExpanded then
                        setBarExpanded(true, false)
                    end
                    positionPopups()
                    drawer.Visible = true
                    local sc = App.Anim.EnsureScale(drawer)
                    sc.Scale = 0.94
                    App.Anim.Play(sc, "DrawerPop", App.Anim.Spring, { Scale = 1 })
                else
                    autoFrame.Visible = false
                    local sc = App.Anim.EnsureScale(drawer)
                    App.Anim.Play(sc, "DrawerPop", App.Anim.Exit, { Scale = 0.94 }, function()
                        if not drawerOpen then
                            drawer.Visible = false
                        end
                    end)
                end
            end

            local function runAdminText(rawLine)
                local txt = App.Trim(rawLine or "")
                if txt == "" then
                    return
                end
                if App.Admin and App.Admin.ExecuteLine then
                    local ok, res = pcall(App.Admin.ExecuteLine, txt, "bar")
                    if ok and type(res) == "table" and res.msg and not res.emitted then
                        ctx.LogCmd(res.msg, res.ok == false and Palette.RedAlert or Palette.NeonCyan)
                    elseif not ok then
                        ctx.LogCmd("CMD err: " .. tostring(res), Palette.RedAlert)
                    end
                else
                    ctx.LogCmd("Queued: " .. txt, Palette.TextMuted)
                end
            end

            local function hideAutocomplete()
                clearTbl(autoMatches)
                autoFrame.Visible = false
                App.Anim.Play(autoFrame, "AutoH", App.Anim.Exit, { Size = UDim2.fromOffset(autoFrame.Size.X.Offset, 0) })
            end

            local function renderAutocomplete(list)
                for _, c in ipairs(autoFrame:GetChildren()) do
                    if c:IsA("TextButton") then
                        c:Destroy()
                    end
                end
                clearTbl(autoMatches)
                local count = 0
                for idx, item in ipairs(list) do
                    if count < 5 then
                        count = count + 1
                        autoMatches[count] = item
                        local isSel = (idx == selectedIdx)
                        local rowBtn = UI.Create("TextButton", {
                            LayoutOrder = count,
                            Size = UDim2.new(1, 0, 0, 26),
                            BackgroundColor3 = isSel and Palette.NeonBlue or Palette.BgElevated,
                            BackgroundTransparency = isSel and 0.72 or 0.2,
                            AutoButtonColor = false,
                            Text = "",
                            ZIndex = 29,
                            Parent = autoFrame,
                        })
                        UI.Corner(rowBtn, 7)
                        UI.Pad(rowBtn, 8, 8, 0, 0)
                        UI.Create("TextLabel", {
                            Size = UDim2.fromScale(0.55, 1),
                            BackgroundTransparency = 1,
                            Font = Enum.Font.GothamBold,
                            Text = item.display or item.insert or "",
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            TextColor3 = isSel and Palette.TextPrimary or Palette.NeonCyan,
                            Active = false,
                            ZIndex = 30,
                            Parent = rowBtn,
                        })
                        UI.Create("TextLabel", {
                            Position = UDim2.fromScale(0.56, 0),
                            Size = UDim2.fromScale(0.44, 1),
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            Text = item.desc or "",
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Right,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            TextColor3 = Palette.TextMuted,
                            Active = false,
                            ZIndex = 30,
                            Parent = rowBtn,
                        })
                        Janitor.Add(rowBtn.MouseButton1Click:Connect(function()
                            local ins = item.insert or ""
                            if string.sub(ins, -1) == " " then
                                kxInput.Text = ins
                                kxInput:CaptureFocus()
                            else
                                kxInput.Text = ""
                                hideAutocomplete()
                                runAdminText(ins)
                            end
                        end))
                    end
                end
                if count == 0 then
                    hideAutocomplete()
                    return
                end
                local targetH = count * 30 + 8
                local w = math.max(230, kxBar.AbsoluteSize.X)
                autoFrame.Visible = true
                positionPopups()
                App.Anim.Play(autoFrame, "AutoH", App.Anim.Spring, { Size = UDim2.fromOffset(w, targetH) })
            end

            local function querySuggestions(rawText)
                local txt = App.Trim(rawText or "")
                if txt == "" then
                    hideAutocomplete()
                    return
                end
                if App.Admin and App.Admin.GetSuggestions then
                    local ok, list = pcall(App.Admin.GetSuggestions, txt)
                    if ok and type(list) == "table" then
                        selectedIdx = 1
                        renderAutocomplete(list)
                        return
                    end
                end
                local clean = string.lower((string.gsub(txt, "^[;:.]", "")))
                local matches = {}
                for _, entry in ipairs(FALLBACK_CMDS) do
                    if string.find(entry.cmd, clean, 1, true) == 1 then
                        local hasArg = string.find(entry.usage, "<", 1, true) ~= nil
                        table.insert(matches, {
                            display = entry.usage,
                            insert = ";" .. entry.cmd .. (hasArg and " " or ""),
                            desc = entry.desc,
                        })
                    end
                end
                selectedIdx = 1
                renderAutocomplete(matches)
            end

            local function refreshCommandBrowser()
                for _, c in ipairs(cmdScroll:GetChildren()) do
                    if c:IsA("GuiObject") then
                        c:Destroy()
                    end
                end

                local quickHeader = UI.Create("TextLabel", {
                    LayoutOrder = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = "QUICK ACTIONS",
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = Palette.NeonCyan,
                    Active = false,
                    ZIndex = 29,
                    Parent = cmdScroll,
                })
                local quickWrap = UI.Create("Frame", {
                    LayoutOrder = 2,
                    Size = UDim2.new(1, 0, 0, 62),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    ZIndex = 29,
                    Parent = cmdScroll,
                })
                UI.Create("UIGridLayout", {
                    CellSize = UDim2.fromOffset(66, 26),
                    CellPadding = UDim2.fromOffset(5, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = quickWrap,
                })
                for idx, cmdStr in ipairs(QUICK_CHIPS) do
                    local chip = UI.Create("TextButton", {
                        LayoutOrder = idx,
                        BackgroundColor3 = Palette.BgElevated,
                        BackgroundTransparency = 0.12,
                        AutoButtonColor = false,
                        Font = Enum.Font.GothamBold,
                        Text = cmdStr,
                        TextSize = 11,
                        TextColor3 = Palette.TextPrimary,
                        ZIndex = 30,
                        Parent = quickWrap,
                    })
                    UI.Corner(chip, 7)
                    UI.Stroke(chip, Palette.NeonBlue, 1, 0.35)
                    App.Anim.BindButton(chip)
                    Janitor.Add(chip.MouseButton1Click:Connect(function()
                        if cmdStr == ";cmds" then
                            setDrawerTab("Output")
                        end
                        runAdminText(cmdStr)
                    end))
                end

                local regList = {}
                if App.Admin and type(App.Admin.Registry) == "table" then
                    for _, info in pairs(App.Admin.Registry) do
                        table.insert(regList, info)
                    end
                else
                    for _, info in ipairs(FALLBACK_CMDS) do
                        table.insert(regList, info)
                    end
                end
                table.sort(regList, function(a, b)
                    return tostring(a.cmd or "") < tostring(b.cmd or "")
                end)

                local allHeader = UI.Create("TextLabel", {
                    LayoutOrder = 3,
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = "ALL COMMANDS (" .. tostring(#regList) .. ")",
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = Palette.TextMuted,
                    Active = false,
                    ZIndex = 29,
                    Parent = cmdScroll,
                })
                local _ = quickHeader or allHeader

                for idx, info in ipairs(regList) do
                    local cmdName = tostring(info.cmd or "")
                    local usageStr = tostring(info.usage or (";" .. cmdName))
                    local row = UI.Create("TextButton", {
                        LayoutOrder = 10 + idx,
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundColor3 = Palette.BgCard,
                        BackgroundTransparency = 0.15,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 29,
                        Parent = cmdScroll,
                    })
                    UI.Corner(row, 8)
                    UI.Pad(row, 8, 8, 0, 0)
                    UI.Create("TextLabel", {
                        Size = UDim2.fromScale(0.46, 1),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        Text = usageStr,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        TextColor3 = Palette.NeonCyan,
                        Active = false,
                        ZIndex = 30,
                        Parent = row,
                    })
                    UI.Create("TextLabel", {
                        Position = UDim2.fromScale(0.47, 0),
                        Size = UDim2.fromScale(0.53, 1),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = tostring(info.desc or ""),
                        TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        TextColor3 = Palette.TextMuted,
                        Active = false,
                        ZIndex = 30,
                        Parent = row,
                    })
                    Janitor.Add(row.MouseButton1Click:Connect(function()
                        if string.find(usageStr, "<", 1, true) then
                            setBarExpanded(true, false)
                            kxInput.Text = ";" .. cmdName .. " "
                            kxInput:CaptureFocus()
                        else
                            runAdminText(";" .. cmdName)
                        end
                    end))
                end
            end

            UI.BindDrag(kxBar, kxHandle, {
                id = "KXBar",
                defaultW = 224,
                defaultH = 38,
                defaultPos = getKXDefaultPos,
                onDragStart = function()
                    positionPopups()
                end,
                onDragEnd = function()
                    positionPopups()
                end,
                onTap = function()
                    if not barExpanded then
                        setBarExpanded(true, false)
                    end
                    kxInput:CaptureFocus()
                end,
            })

            Janitor.Add(drawerToggleBtn.MouseButton1Click:Connect(function()
                toggleCmdDrawer(nil, nil)
            end))
            Janitor.Add(closeDrawerBtn.MouseButton1Click:Connect(function()
                toggleCmdDrawer(false, nil)
            end))
            Janitor.Add(tabCmdBtn.MouseButton1Click:Connect(function()
                setDrawerTab("Commands")
            end))
            Janitor.Add(tabOutBtn.MouseButton1Click:Connect(function()
                setDrawerTab("Output")
            end))
            Janitor.Add(clearOutBtn.MouseButton1Click:Connect(function()
                if App.HUD and App.HUD.ClearCmdLog then
                    App.HUD.ClearCmdLog()
                end
            end))

            Janitor.Add(kxInput:GetPropertyChangedSignal("Text"):Connect(function()
                querySuggestions(kxInput.Text)
            end))
            Janitor.Add(kxInput.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    local raw = kxInput.Text
                    kxInput.Text = ""
                    hideAutocomplete()
                    runAdminText(raw)
                else
                    App.Anim.Delay(autoFrame, "AutoBlur", 0.14, function()
                        if not kxInput:IsFocused() then
                            hideAutocomplete()
                        end
                    end)
                end
            end))
            Janitor.Add(Services.UserInputService.InputBegan:Connect(function(inp)
                if not kxInput:IsFocused() or #autoMatches == 0 then
                    return
                end
                local kc = inp.KeyCode
                if kc == Enum.KeyCode.Down then
                    selectedIdx = (selectedIdx % #autoMatches) + 1
                    renderAutocomplete(autoMatches)
                elseif kc == Enum.KeyCode.Up then
                    selectedIdx = ((selectedIdx - 2) % #autoMatches) + 1
                    renderAutocomplete(autoMatches)
                elseif kc == Enum.KeyCode.Tab then
                    local chosen = autoMatches[selectedIdx]
                    if chosen and chosen.insert then
                        kxInput.Text = chosen.insert
                        kxInput:CaptureFocus()
                    end
                end
            end))

            ctx.KXBar = kxBar
            ctx.KXStroke = kxStroke
            ctx.KXInput = kxInput
            ctx.KXAutoFrame = autoFrame
            ctx.KXDrawer = drawer
            ctx.OutScroll = outScroll
            ctx.ToggleCmdDrawer = toggleCmdDrawer
            ctx.SetBarExpanded = setBarExpanded
            ctx.PositionKXPopups = positionPopups
            ctx.RefreshCommandBrowser = refreshCommandBrowser
            ctx.HideAutocomplete = hideAutocomplete
        end

        buildKXSystem()
    end

    -- ========================================================================
    -- BLOCK 5: RIGHT QUICK ACTIONS DOCK & MOBILE FLYPAD
    -- ========================================================================
    do
        local function makeQuickButton(parent, order, name, caption, iconBuilder)
            local btn = UI.Create("TextButton", {
                Name = name,
                LayoutOrder = order,
                Size = UDim2.fromOffset(46, 46),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.14,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 16,
                Parent = parent,
            })
            UI.Corner(btn, 9999)
            local stroke = UI.Stroke(btn, Palette.Border, 1.3, 0.25)
            App.Anim.EnsureScale(btn)

            local iconHost = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 6),
                Size = UDim2.fromOffset(24, 22),
                BackgroundTransparency = 1,
                Active = false,
                ZIndex = 17,
                Parent = btn,
            })
            local parts = iconBuilder(iconHost)

            local lbl = UI.Create("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -3),
                Size = UDim2.new(1, -4, 0, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = caption,
                TextSize = 9,
                TextColor3 = Palette.TextMuted,
                Active = false,
                ZIndex = 17,
                Parent = btn,
            })

            return {
                btn = btn,
                iconHost = iconHost,
                stroke = stroke,
                parts = parts,
                label = lbl,
            }
        end

        local function buildShieldVector(host)
            local box = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(14, 17),
                BackgroundTransparency = 1,
                Active = false,
                ZIndex = 18,
                Parent = host,
            })
            UI.Corner(box, 5)
            local boxStroke = UI.Stroke(box, Palette.TextMuted, 1.7, 0.05)
            local core = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(6, 8),
                BackgroundColor3 = Palette.TextMuted,
                BackgroundTransparency = 0.25,
                Active = false,
                ZIndex = 18,
                Parent = box,
            })
            UI.Corner(core, 2)
            return { stroke = boxStroke, fill = core }
        end

        local function buildGhostVector(host)
            local outer = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(18, 12),
                BackgroundTransparency = 1,
                Active = false,
                ZIndex = 18,
                Parent = host,
            })
            UI.Corner(outer, 9)
            local outerStroke = UI.Stroke(outer, Palette.TextMuted, 1.6, 0.05)
            local pupil = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Palette.TextMuted,
                Active = false,
                ZIndex = 18,
                Parent = outer,
            })
            UI.Corner(pupil, 3)
            return { stroke = outerStroke, fill = pupil }
        end

        local function buildCleanVector(host)
            local barA = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(14, 2),
                Rotation = 45,
                BackgroundColor3 = Palette.TextMuted,
                Active = false,
                ZIndex = 18,
                Parent = host,
            })
            UI.Corner(barA, 1)
            local barB = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(14, 2),
                Rotation = -45,
                BackgroundColor3 = Palette.TextMuted,
                Active = false,
                ZIndex = 18,
                Parent = host,
            })
            UI.Corner(barB, 1)
            return { fill = barA, fill2 = barB }
        end

        local function buildQuickDock()
            local function getRightDefaultPos()
                if isCompactLayout() then
                    return Vector2.new(1, 1), UDim2.new(1, -76, 1, -16)
                end
                return Vector2.new(1, 1), UDim2.new(1, -18, 1, -110)
            end

            local rightDock = UI.Create("Frame", {
                Name = "RightQuickActions",
                AnchorPoint = Vector2.new(1, 1),
                Position = isCompactLayout() and UDim2.new(1, -76, 1, -16) or UDim2.new(1, -18, 1, -110),
                Size = isCompactLayout() and UDim2.fromOffset(36, 110) or UDim2.fromOffset(46, 150),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Visible = State.ShowRightActions ~= false,
                ZIndex = 15,
                Parent = ctx.MainGui,
            })
            local rightList = UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, isCompactLayout() and 4 or 6),
                Parent = rightDock,
            })

            local shieldQ = makeQuickButton(rightDock, 1, "QuickShield", "SHIELD", buildShieldVector)
            local ghostQ = makeQuickButton(rightDock, 2, "QuickGhost", "GHOST", buildGhostVector)
            local cleanQ = makeQuickButton(rightDock, 3, "QuickClean", "CLEAN", buildCleanVector)

            UI.BindDrag(rightDock, shieldQ.btn, {
                id = "RightQuickActions",
                defaultW = 48,
                defaultH = 150,
                defaultPos = getRightDefaultPos,
                onTap = function()
                    local nextVal = not (State.ShieldEnabled == true)
                    App.SetState("ShieldEnabled", nextVal)
                    if App.Shield and App.Shield.SetEnabled then
                        safeCall(App.Shield.SetEnabled, nextVal)
                    end
                    local sc = App.Anim.EnsureScale(shieldQ.btn)
                    sc.Scale = 1.12
                    App.Anim.Play(sc, "QShield", App.Anim.Spring, { Scale = 1.0 })
                end,
            })

            UI.BindDrag(rightDock, ghostQ.btn, {
                id = "RightQuickActions",
                defaultW = 48,
                defaultH = 150,
                defaultPos = getRightDefaultPos,
                onTap = function()
                    local nextVal = not (State.FEInvisible == true)
                    App.SetState("FEInvisible", nextVal)
                    if App.Shield and App.Shield.SetFEInvisible then
                        safeCall(App.Shield.SetFEInvisible, nextVal)
                    end
                end,
            })

            UI.BindDrag(rightDock, cleanQ.btn, {
                id = "RightQuickActions",
                defaultW = 48,
                defaultH = 150,
                defaultPos = getRightDefaultPos,
                onTap = function()
                    if App.Shield and App.Shield.CleanCharacterEffects then
                        safeCall(App.Shield.CleanCharacterEffects)
                    end
                    if not State.Noclip and App.World and App.World.RestoreNoclipCollide then
                        safeCall(App.World.RestoreNoclipCollide)
                    end
                    cleanQ.stroke.Color = Palette.Emerald
                    cleanQ.parts.fill.BackgroundColor3 = Palette.Emerald
                    cleanQ.parts.fill2.BackgroundColor3 = Palette.Emerald
                    App.Anim.Delay(cleanQ.btn, "CleanFlash", 0.35, function()
                        cleanQ.stroke.Color = Palette.Border
                        cleanQ.parts.fill.BackgroundColor3 = Palette.TextMuted
                        cleanQ.parts.fill2.BackgroundColor3 = Palette.TextMuted
                    end)
                end,
            })

            ctx.RightQuickActions = rightDock
            ctx.RightQuickList = rightList
            ctx.RightBtns.shield = shieldQ
            ctx.RightBtns.ghost = ghostQ
            ctx.RightBtns.clean = cleanQ
            ctx.UpdateQuickDockLayout = function()
                local compact = isCompactLayout()
                local bSz = compact and 34 or 44
                rightDock.Size = UDim2.fromOffset(bSz + 2, compact and 110 or 144)
                if rightList then
                    rightList.Padding = UDim.new(0, compact and 4 or 6)
                end
                for _, item in pairs(ctx.RightBtns) do
                    if item and item.btn then
                        item.btn.Size = UDim2.fromOffset(bSz, bSz)
                    end
                    if item and item.iconHost then
                        item.iconHost.Size = compact and UDim2.fromOffset(18, 13) or UDim2.fromOffset(24, 22)
                        item.iconHost.Position = compact and UDim2.new(0.5, 0, 0, 3) or UDim2.new(0.5, 0, 0, 6)
                    end
                    if item and item.label then
                        item.label.TextSize = compact and 8 or 9
                        item.label.Size = compact and UDim2.new(1, -2, 0, 10) or UDim2.new(1, -4, 0, 12)
                        item.label.Position = compact and UDim2.new(0.5, 0, 1, -2) or UDim2.new(0.5, 0, 1, -3)
                    end
                end
            end
        end

        local function bindHoldFlyButton(btn, keyName)
            local holding = false
            local function releaseHold()
                if holding then
                    holding = false
                    local target = (App.World and App.World.MobileFlyInput) or App.MobileFlyInput
                    if target then
                        target[keyName] = 0
                    end
                    if App.MobileFlyInput then
                        App.MobileFlyInput[keyName] = 0
                    end
                    App.Anim.Play(btn, "FlyHold", App.Anim.Snappy, { BackgroundTransparency = 0.14 })
                end
            end
            Janitor.Add(btn.InputBegan:Connect(function(inp)
                local t = inp.UserInputType
                if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
                    return
                end
                holding = true
                local target = (App.World and App.World.MobileFlyInput) or App.MobileFlyInput
                if target then
                    target[keyName] = 1
                end
                if App.MobileFlyInput then
                    App.MobileFlyInput[keyName] = 1
                end
                App.Anim.Play(btn, "FlyHold", App.Anim.Flash, { BackgroundTransparency = 0.02 })
                local chConn
                chConn = Janitor.Add(inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End or inp.UserInputState == Enum.UserInputState.Cancel then
                        if chConn and chConn.Disconnect then
                            chConn:Disconnect()
                        end
                        releaseHold()
                    end
                end))
            end))
            Janitor.Add(Services.UserInputService.InputEnded:Connect(function(inp)
                if holding and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
                    releaseHold()
                end
            end))
        end

        local function buildFlyPad()
            local function getFlyDefaultPos()
                if isCompactLayout() then
                    return Vector2.new(1, 1), UDim2.new(1, -122, 1, -74)
                end
                return Vector2.new(1, 1), UDim2.new(1, -74, 1, -110)
            end

            local flyDock = UI.Create("Frame", {
                Name = "FlyPadStack",
                AnchorPoint = Vector2.new(1, 1),
                Position = isCompactLayout() and UDim2.new(1, -122, 1, -74) or UDim2.new(1, -74, 1, -110),
                Size = UDim2.fromOffset(50, 102),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Visible = (State.Fly == true or State.VehicleFly == true),
                ZIndex = 15,
                Parent = ctx.MainGui,
            })
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = flyDock,
            })

            local grip = UI.Create("TextButton", {
                Name = "FlyGrip",
                LayoutOrder = 1,
                Size = UDim2.fromOffset(48, 16),
                BackgroundColor3 = Palette.BgElevated,
                BackgroundTransparency = 0.2,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "FLY",
                TextSize = 8,
                TextColor3 = Palette.NeonCyan,
                ZIndex = 16,
                Parent = flyDock,
            })
            UI.Corner(grip, 6)

            local upBtn = UI.Create("TextButton", {
                Name = "FlyUpBtn",
                LayoutOrder = 2,
                Size = UDim2.fromOffset(48, 38),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.14,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "UP",
                TextSize = 11,
                TextColor3 = Palette.Emerald,
                ZIndex = 16,
                Parent = flyDock,
            })
            UI.Corner(upBtn, 10)
            UI.Stroke(upBtn, Palette.Emerald, 1.3, 0.2)

            local dnBtn = UI.Create("TextButton", {
                Name = "FlyDownBtn",
                LayoutOrder = 3,
                Size = UDim2.fromOffset(48, 38),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.14,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "DN",
                TextSize = 11,
                TextColor3 = Palette.NeonCyan,
                ZIndex = 16,
                Parent = flyDock,
            })
            UI.Corner(dnBtn, 10)
            UI.Stroke(dnBtn, Palette.NeonBlue, 1.3, 0.2)

            UI.BindDrag(flyDock, grip, {
                id = "FlyPadStack",
                defaultW = 50,
                defaultH = 102,
                defaultPos = getFlyDefaultPos,
            })
            bindHoldFlyButton(upBtn, "Up")
            bindHoldFlyButton(dnBtn, "Down")

            ctx.FlyPadStack = flyDock
            ctx.FlyGrip = grip
            ctx.FlyBtns.up = upBtn
            ctx.FlyBtns.dn = dnBtn
        end

        buildQuickDock()
        buildFlyPad()
    end

    -- ========================================================================
    -- BLOCK 6: SHIELD HP BADGE & STAGGERED ANIMATED KILLFEED
    -- ========================================================================
    do
        local function buildShieldBadge()
            local badge = UI.Create("Frame", {
                Name = "ShieldHPBadge",
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -78),
                Size = UDim2.fromOffset(96, 30),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.14,
                Visible = (State.ShowShieldBadge ~= false) and (State.ShieldEnabled == true or State.FEInvisible == true),
                ZIndex = 16,
                Parent = ctx.MainGui,
            })
            UI.Corner(badge, 14)
            UI.Pad(badge, 10, 12, 0, 3)
            local stroke = UI.Stroke(badge, Palette.NeonBlue, 1.4, 0.15)
            App.Anim.EnsureScale(badge)

            local innerRow = UI.Create("Frame", {
                Size = UDim2.fromOffset(72, 24),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Active = false,
                ZIndex = 17,
                Parent = badge,
            })
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = innerRow,
            })

            local vecShield = UI.Create("Frame", {
                LayoutOrder = 1,
                Size = UDim2.fromOffset(12, 15),
                BackgroundColor3 = Palette.NeonBlue,
                BackgroundTransparency = 0.72,
                Active = false,
                ZIndex = 18,
                Parent = innerRow,
            })
            UI.Corner(vecShield, 4)
            local vecStroke = UI.Stroke(vecShield, Palette.NeonBlue, 1.5, 0.05)

            local hpLabel = UI.Create("TextLabel", {
                LayoutOrder = 2,
                Size = UDim2.fromOffset(48, 24),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "180",
                TextSize = 13,
                TextColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 18,
                Parent = innerRow,
            })

            local meterBg = UI.Create("Frame", {
                Name = "ShieldMeterBg",
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -1),
                Size = UDim2.new(1, -16, 0, 3),
                BackgroundColor3 = Palette.BgInset,
                BackgroundTransparency = 0.15,
                Active = false,
                ZIndex = 18,
                Parent = badge,
            })
            UI.Corner(meterBg, 2)

            local meterFill = UI.Create("Frame", {
                Name = "ShieldMeterFill",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Palette.NeonBlue,
                Active = false,
                ZIndex = 19,
                Parent = meterBg,
            })
            UI.Corner(meterFill, 2)

            UI.BindDrag(badge, badge, {
                id = "ShieldBadge",
                defaultW = 96,
                defaultH = 30,
                defaultPos = function()
                    return Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -78)
                end,
            })

            local function flashShieldHit()
                stroke.Color = Palette.RedAlert
                badge.BackgroundColor3 = Palette.RageCrimson
                App.Anim.Play(badge, "ShieldHitBg", App.Anim.Spring, {
                    BackgroundColor3 = Palette.BgDark,
                })
                local sc = App.Anim.EnsureScale(badge)
                sc.Scale = 1.1
                App.Anim.Play(sc, "ShieldHitSc", App.Anim.Spring, { Scale = 1.0 })
                innerRow.Position = UDim2.fromOffset(6, 0)
                App.Anim.Play(innerRow, "ShieldShake", App.Anim.Spring, { Position = UDim2.fromOffset(0, 0) })
            end

            ctx.ShieldBadge = badge
            ctx.ShieldBadgeStroke = stroke
            ctx.ShieldVecBox = vecShield
            ctx.ShieldVecStroke = vecStroke
            ctx.ShieldHPLabel = hpLabel
            ctx.ShieldMeterFill = meterFill
            ctx.FlashShieldHit = flashShieldHit
        end

        local function buildKillfeedHost()
            local function useTopLeftKillfeed()
                return isCompactLayout() or State.KillfeedPosition == "TopLeft"
            end
            local function getKillfeedDefaultPos()
                if useTopLeftKillfeed() then
                    local hasPins = (State.ShowPinnedPills ~= false) and (#(State.PinnedPills or {}) > 0)
                    local yStart = getSafeTopY() + (hasPins and 72 or 44)
                    return Vector2.new(0, 0), UDim2.fromOffset(14, yStart)
                end
                return Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -114)
            end

            local kfHost = UI.Create("Frame", {
                Name = "KillfeedStack",
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.fromOffset(14, getSafeTopY() + 72),
                Size = UDim2.fromOffset(isCompactLayout() and 154 or 260, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Active = false,
                Visible = (State.ShowKillfeed ~= false) and (#ctx.KillfeedItems > 0),
                ZIndex = 14,
                Parent = ctx.MainGui,
            })
            local kfList = UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = kfHost,
            })

            local function syncKillfeedAnchor()
                local compact = isCompactLayout()
                kfHost.Size = UDim2.fromOffset(compact and 154 or 260, 0)
                if useTopLeftKillfeed() then
                    kfList.VerticalAlignment = Enum.VerticalAlignment.Top
                    kfList.HorizontalAlignment = Enum.HorizontalAlignment.Left
                else
                    kfList.VerticalAlignment = Enum.VerticalAlignment.Bottom
                    kfList.HorizontalAlignment = Enum.HorizontalAlignment.Center
                end
                local entry = ctx.Draggables["KillfeedStack"]
                if entry and entry.apply then
                    entry.apply()
                end
            end

            UI.BindDrag(kfHost, kfHost, {
                id = "KillfeedStack",
                defaultW = 154,
                defaultH = 72,
                defaultPos = getKillfeedDefaultPos,
            })

            ctx.KillfeedHost = kfHost
            ctx.KillfeedLayout = kfList
            ctx.SyncKillfeedAnchor = syncKillfeedAnchor
            syncKillfeedAnchor()
        end

        buildShieldBadge()
        buildKillfeedHost()
    end

    -- ========================================================================
    -- BLOCK 7: OBSIDIAN GLASS 6-TAB HUB SHELL & ANIMATED CONTROL FACTORIES
    -- ========================================================================
    do
        local TAB_DEFS = {
            { id = "Shield", label = "Shield", short = "SHIELD" },
            { id = "Combat", label = "Rage & Aim", short = "COMBAT" },
            { id = "Guns", label = "Guns & Loot", short = "GUNS" },
            { id = "Prison", label = "Prison & Car", short = "PRISON" },
            { id = "Move", label = "Move & ESP", short = "MOVE/ESP" },
            { id = "Settings", label = "Settings & Admin", short = "SETTINGS" },
        }

        local TAB_ALIAS = {
            shield = "Shield", defense = "Shield",
            combat = "Combat", rage = "Combat", aim = "Combat", ["rage & aim"] = "Combat",
            guns = "Guns", weapons = "Guns", loot = "Guns", ["guns & loot"] = "Guns",
            prison = "Prison", car = "Prison", vehicle = "Prison", ["prison & car"] = "Prison",
            move = "Move", movement = "Move", visuals = "Move", esp = "Move", ["move & esp"] = "Move",
            settings = "Settings", hud = "Settings", cmds = "Settings", admin = "Settings", ["settings & admin"] = "Settings",
        }

        local function registerFilterWidget(tabId, card, textBlob)
            table.insert(ctx.WidgetFilterEntries, {
                tab = tabId,
                card = card,
                search = string.lower(textBlob or ""),
            })
        end

        local function makeSection(tab, title, accent)
            local order = tab.nextOrder()
            local row = UI.Create("Frame", {
                LayoutOrder = order,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Active = false,
                ZIndex = 44,
                Parent = tab.scroll,
            })
            local dot = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = accent or Palette.NeonCyan,
                Active = false,
                ZIndex = 45,
                Parent = row,
            })
            UI.Corner(dot, 3)
            UI.Create("TextLabel", {
                Position = UDim2.fromOffset(14, 0),
                Size = UDim2.new(1, -16, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = string.upper(title),
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = accent or Palette.NeonCyan,
                Active = false,
                ZIndex = 45,
                Parent = row,
            })
            registerFilterWidget(tab.id, row, "__sec__" .. title)
            return row
        end

        local function makeToggle(tab, meta)
            local order = tab.nextOrder()
            local accent = meta.color or Palette.NeonBlue
            local card = UI.Create("TextButton", {
                LayoutOrder = order,
                Size = UDim2.new(1, 0, 0, meta.sub and 48 or 42),
                BackgroundColor3 = Palette.BgCard,
                BackgroundTransparency = 0.08,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 44,
                Parent = tab.scroll,
            })
            UI.Corner(card, 10)
            local stroke = UI.Stroke(card, Palette.Border, 1.1, 0.35)
            UI.Pad(card, 12, 12, 0, 0)

            UI.Create("TextLabel", {
                Position = UDim2.fromOffset(0, meta.sub and 6 or 0),
                Size = UDim2.new(1, -56, 0, meta.sub and 20 or 42),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = meta.label,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 45,
                Parent = card,
            })

            if meta.sub then
                UI.Create("TextLabel", {
                    Position = UDim2.fromOffset(0, 25),
                    Size = UDim2.new(1, -56, 0, 16),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = meta.sub,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextColor3 = Palette.TextMuted,
                    Active = false,
                    ZIndex = 45,
                    Parent = card,
                })
            end

            local track = UI.Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(42, 22),
                BackgroundColor3 = Palette.BgInset,
                Active = false,
                ZIndex = 45,
                Parent = card,
            })
            UI.Corner(track, 11)
            local trackStroke = UI.Stroke(track, Palette.Border, 1, 0.25)

            local knob = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                BackgroundColor3 = Palette.TextMuted,
                Active = false,
                ZIndex = 46,
                Parent = track,
            })
            UI.Corner(knob, 8)
            local knobScale = App.Anim.EnsureScale(knob)

            local lastOn = nil
            local function sync(instant)
                local on = State[meta.key] == true
                if lastOn == on then
                    return
                end
                lastOn = on
                local tPos = on and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                local tTrack = on and accent or Palette.BgInset
                local tKnob = on and Palette.TextPrimary or Palette.TextMuted
                local tStrk = on and accent or Palette.Border
                if instant or not (ctx.HubOpen and card.Visible) then
                    track.BackgroundColor3 = tTrack
                    trackStroke.Color = tStrk
                    knob.Position = tPos
                    knob.BackgroundColor3 = tKnob
                    stroke.Color = on and accent or Palette.Border
                    stroke.Transparency = on and 0.32 or 0.35
                    return
                end
                App.Anim.Play(track, "TogTrk", App.Anim.Snappy, { BackgroundColor3 = tTrack })
                App.Anim.Play(trackStroke, "TogStrk", App.Anim.Snappy, { Color = tStrk })
                App.Anim.Play(knob, "TogKnb", App.Anim.Spring, { Position = tPos, BackgroundColor3 = tKnob })
                App.Anim.Play(stroke, "CardStrk", App.Anim.Snappy, {
                    Color = on and accent or Palette.Border,
                    Transparency = on and 0.28 or 0.35,
                })
                knobScale.Scale = 1.16
                App.Anim.Play(knobScale, "KnbSq", App.Anim.Spring, { Scale = 1.0 })
            end

            Janitor.Add(card.MouseButton1Click:Connect(function()
                local nextVal = not (State[meta.key] == true)
                App.SetState(meta.key, nextVal)
                if meta.onChange then
                    safeCall(meta.onChange, nextVal)
                end
                sync(false)
            end))

            ctx.SyncFns[meta.key] = ctx.SyncFns[meta.key] or {}
            table.insert(ctx.SyncFns[meta.key], sync)
            registerFilterWidget(tab.id, card, meta.label .. " " .. tostring(meta.sub or "") .. " " .. meta.key)
            sync(true)
            return card
        end

        local function makeSlider(tab, meta)
            local order = tab.nextOrder()
            local minV = meta.min or 0
            local maxV = meta.max or 100
            local step = meta.step or 1
            local accent = meta.color or Palette.NeonBlue

            local card = UI.Create("Frame", {
                LayoutOrder = order,
                Size = UDim2.new(1, 0, 0, 56),
                BackgroundColor3 = Palette.BgCard,
                BackgroundTransparency = 0.08,
                ZIndex = 44,
                Parent = tab.scroll,
            })
            UI.Corner(card, 10)
            UI.Stroke(card, Palette.Border, 1.1, 0.35)
            UI.Pad(card, 12, 12, 6, 4)

            UI.Create("TextLabel", {
                Size = UDim2.new(1, -68, 0, 18),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = meta.label,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 45,
                Parent = card,
            })

            local valLbl = UI.Create("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromOffset(62, 18),
                BackgroundColor3 = Palette.BgInset,
                BackgroundTransparency = 0.25,
                Font = Enum.Font.GothamBold,
                Text = "0",
                TextSize = 11,
                TextColor3 = accent,
                Active = false,
                ZIndex = 45,
                Parent = card,
            })
            UI.Corner(valLbl, 6)

            local hitZone = UI.Create("TextButton", {
                Position = UDim2.fromOffset(0, 20),
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 45,
                Parent = card,
            })

            local groove = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 5),
                BackgroundColor3 = Palette.BgInset,
                Active = false,
                ZIndex = 46,
                Parent = hitZone,
            })
            UI.Corner(groove, 3)

            local fill = UI.Create("Frame", {
                Size = UDim2.fromScale(0.5, 1),
                BackgroundColor3 = accent,
                Active = false,
                ZIndex = 47,
                Parent = groove,
            })
            UI.Corner(fill, 3)

            local thumb = UI.Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(16, 16),
                BackgroundColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 48,
                Parent = hitZone,
            })
            UI.Corner(thumb, 8)
            UI.Stroke(thumb, accent, 2, 0.05)

            local function formatVal(v)
                if meta.fmt then
                    return string.format(meta.fmt, v)
                end
                if step < 1 then
                    return string.format("%.2f", v)
                end
                return tostring(math.floor(v + 0.5))
            end

            local sliding = false
            local pendingTouch = false
            local activeInput = nil
            local slideConn = nil
            local startX = 0
            local startY = 0
            local lastVal = nil

            local function sync(instant)
                local raw = tonumber(State[meta.key]) or minV
                local cur = clampNum(raw, minV, maxV)
                if lastVal == cur then
                    return
                end
                lastVal = cur
                local frac = (maxV > minV) and ((cur - minV) / (maxV - minV)) or 0
                valLbl.Text = formatVal(cur) .. (meta.suffix or "")
                if instant or sliding or not (ctx.HubOpen and card.Visible) then
                    fill.Size = UDim2.fromScale(frac, 1)
                    thumb.Position = UDim2.fromScale(frac, 0.5)
                else
                    App.Anim.Play(fill, "SlFill", App.Anim.Snappy, { Size = UDim2.fromScale(frac, 1) })
                    App.Anim.Play(thumb, "SlThmb", App.Anim.Snappy, { Position = UDim2.fromScale(frac, 0.5) })
                end
            end

            local function applyScreenX(screenX)
                local absX = groove.AbsolutePosition.X
                local absW = groove.AbsoluteSize.X
                if absW <= 4 then
                    return
                end
                local frac = clampNum((screenX - absX) / absW, 0, 1)
                local raw = minV + frac * (maxV - minV)
                local snapped = minV + math.floor(((raw - minV) / step) + 0.5) * step
                snapped = clampNum(tonumber(string.format("%.4f", snapped)) or snapped, minV, maxV)
                if State[meta.key] ~= snapped then
                    App.SetState(meta.key, snapped)
                    if meta.onChange then
                        safeCall(meta.onChange, snapped)
                    end
                    sync(true)
                end
            end

            local function endSlide()
                if slideConn and slideConn.Disconnect then
                    slideConn:Disconnect()
                    slideConn = nil
                end
                pendingTouch = false
                if sliding then
                    sliding = false
                    activeInput = nil
                    if tab.scroll and tab.scroll.Parent then
                        tab.scroll.ScrollingEnabled = true
                    end
                    App.Anim.Play(thumb, "ThmbPop", App.Anim.Snappy, { Size = UDim2.fromOffset(16, 16) })
                else
                    activeInput = nil
                end
            end

            Janitor.Add(hitZone.InputBegan:Connect(function(inp)
                local t = inp.UserInputType
                if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
                    return
                end
                endSlide()
                activeInput = inp
                if t == Enum.UserInputType.MouseButton1 then
                    sliding = true
                    tab.scroll.ScrollingEnabled = false
                    App.Anim.Play(thumb, "ThmbPop", App.Anim.Spring, { Size = UDim2.fromOffset(20, 20) })
                    applyScreenX(inp.Position.X)
                else
                    pendingTouch = true
                    startX = inp.Position.X
                    startY = inp.Position.Y
                end
                if inp.Changed then
                    slideConn = Janitor.Add(inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End or inp.UserInputState == Enum.UserInputState.Cancel then
                            if pendingTouch and inp.UserInputState == Enum.UserInputState.End then
                                applyScreenX(inp.Position.X)
                            end
                            endSlide()
                        end
                    end))
                end
            end))

            Janitor.Add(Services.UserInputService.InputEnded:Connect(function(inp)
                if not sliding and not pendingTouch then
                    return
                end
                if inp == activeInput or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    if pendingTouch and inp.UserInputState == Enum.UserInputState.End then
                        applyScreenX(inp.Position.X)
                    end
                    endSlide()
                end
            end))

            Janitor.Add(Services.UserInputService.InputChanged:Connect(function(inp)
                if pendingTouch and inp == activeInput and inp.UserInputType == Enum.UserInputType.Touch then
                    local dx = inp.Position.X - startX
                    local dy = inp.Position.Y - startY
                    if math.abs(dy) > 6 and math.abs(dy) > math.abs(dx) then
                        endSlide()
                        return
                    elseif math.abs(dx) > 6 and math.abs(dx) >= math.abs(dy) then
                        pendingTouch = false
                        sliding = true
                        tab.scroll.ScrollingEnabled = false
                        App.Anim.Play(thumb, "ThmbPop", App.Anim.Spring, { Size = UDim2.fromOffset(20, 20) })
                        applyScreenX(inp.Position.X)
                        return
                    end
                end
                if not sliding then
                    return
                end
                local t = inp.UserInputType
                if t == Enum.UserInputType.MouseMovement or (t == Enum.UserInputType.Touch and inp == activeInput) then
                    applyScreenX(inp.Position.X)
                end
            end))

            if tab.scroll and tab.scroll.GetPropertyChangedSignal then
                Janitor.Add(tab.scroll:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not tab.scroll.Visible then
                        endSlide()
                    end
                end))
            end
            if ctx.HubWindow and ctx.HubWindow.GetPropertyChangedSignal then
                Janitor.Add(ctx.HubWindow:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not ctx.HubWindow.Visible then
                        endSlide()
                    end
                end))
            end
            Janitor.AddCleanup(endSlide)

            ctx.SyncFns[meta.key] = ctx.SyncFns[meta.key] or {}
            table.insert(ctx.SyncFns[meta.key], sync)
            registerFilterWidget(tab.id, card, meta.label .. " " .. meta.key)
            sync(true)
            return card
        end

        local function makeSegmented(tab, meta)
            local order = tab.nextOrder()
            local opts = meta.options or {}
            local card = UI.Create("Frame", {
                LayoutOrder = order,
                Size = UDim2.new(1, 0, 0, 62),
                BackgroundColor3 = Palette.BgCard,
                BackgroundTransparency = 0.08,
                ZIndex = 44,
                Parent = tab.scroll,
            })
            UI.Corner(card, 10)
            UI.Stroke(card, Palette.Border, 1.1, 0.35)
            UI.Pad(card, 10, 10, 6, 8)

            UI.Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = meta.label,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Palette.TextMuted,
                Active = false,
                ZIndex = 45,
                Parent = card,
            })

            local strip = UI.Create("Frame", {
                Position = UDim2.fromOffset(0, 22),
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = Palette.BgInset,
                ZIndex = 45,
                Parent = card,
            })
            UI.Corner(strip, 8)
            UI.Pad(strip, 3, 3, 3, 3)

            local count = math.max(1, #opts)
            local pillW = 1 / count
            local optBtns = {}
            for idx, opt in ipairs(opts) do
                local btn = UI.Create("TextButton", {
                    Position = UDim2.fromScale((idx - 1) * pillW, 0),
                    Size = UDim2.fromScale(pillW, 1),
                    BackgroundColor3 = Palette.NeonBlue,
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                    Font = Enum.Font.GothamBold,
                    Text = tostring(opt),
                    TextSize = 10,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextColor3 = Palette.TextMuted,
                    ZIndex = 46,
                    Parent = strip,
                })
                UI.Corner(btn, 6)
                local bStroke = UI.Stroke(btn, Palette.NeonBlue, 1, 1)
                optBtns[opt] = { btn = btn, stroke = bStroke }
                Janitor.Add(btn.MouseButton1Click:Connect(function()
                    App.SetState(meta.key, opt)
                    if meta.onChange then
                        safeCall(meta.onChange, opt)
                    end
                end))
            end

            local lastSel = nil
            local function sync(instant)
                local cur = State[meta.key]
                if lastSel == cur then
                    return
                end
                lastSel = cur
                local doInstant = instant or not (ctx.HubOpen and card.Visible)
                for opt, info in pairs(optBtns) do
                    local sel = (cur == opt)
                    info.btn.TextColor3 = sel and Palette.TextPrimary or Palette.TextMuted
                    if doInstant then
                        info.btn.BackgroundTransparency = sel and 0.72 or 1
                        info.stroke.Transparency = sel and 0.15 or 1
                    else
                        App.Anim.Play(info.btn, "SegBg", App.Anim.Snappy, {
                            BackgroundTransparency = sel and 0.72 or 1,
                        })
                        App.Anim.Play(info.stroke, "SegStr", App.Anim.Snappy, {
                            Transparency = sel and 0.15 or 1,
                        })
                    end
                end
            end

            ctx.SyncFns[meta.key] = ctx.SyncFns[meta.key] or {}
            table.insert(ctx.SyncFns[meta.key], sync)
            registerFilterWidget(tab.id, card, meta.label .. " " .. meta.key .. " " .. table.concat(opts, " "))
            sync(true)
            return card
        end

        local function makeDropdown(tab, meta)
            local order = tab.nextOrder()
            local opts = meta.options or {}
            local expanded = false
            local cols = 2
            local rows = math.ceil(#opts / cols)
            local bodyH = math.max(36, rows * 32 + 6)
            local closedH = 44

            local card = UI.Create("Frame", {
                LayoutOrder = order,
                Size = UDim2.new(1, 0, 0, closedH),
                BackgroundColor3 = Palette.BgCard,
                BackgroundTransparency = 0.08,
                ClipsDescendants = true,
                ZIndex = 44,
                Parent = tab.scroll,
            })
            UI.Corner(card, 10)
            UI.Stroke(card, Palette.Border, 1.1, 0.35)

            local headerBtn = UI.Create("TextButton", {
                Size = UDim2.new(1, 0, 0, closedH),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 45,
                Parent = card,
            })
            UI.Pad(headerBtn, 12, 12, 0, 0)

            UI.Create("TextLabel", {
                Size = UDim2.new(0.55, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = meta.label,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 46,
                Parent = headerBtn,
            })

            local summaryLbl = UI.Create("TextLabel", {
                Position = UDim2.fromScale(0.55, 0),
                Size = UDim2.new(0.45, -20, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "",
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextColor3 = Palette.NeonCyan,
                Active = false,
                ZIndex = 46,
                Parent = headerBtn,
            })

            local chevLbl = UI.Create("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "v",
                TextSize = 11,
                TextColor3 = Palette.TextMuted,
                Active = false,
                ZIndex = 46,
                Parent = headerBtn,
            })

            local body = UI.Create("Frame", {
                Position = UDim2.fromOffset(8, closedH),
                Size = UDim2.new(1, -16, 0, bodyH),
                BackgroundTransparency = 1,
                ZIndex = 45,
                Parent = card,
            })
            UI.Create("UIGridLayout", {
                CellSize = UDim2.new(0.5, -4, 0, 26),
                CellPadding = UDim2.fromOffset(6, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = body,
            })

            local itemBtns = {}
            local function isSelected(opt)
                local cur = State[meta.key]
                if type(cur) ~= "table" then
                    return false
                end
                for _, v in ipairs(cur) do
                    if v == opt then
                        return true
                    end
                end
                return false
            end

            for idx, opt in ipairs(opts) do
                local optBtn = UI.Create("TextButton", {
                    LayoutOrder = idx,
                    BackgroundColor3 = Palette.BgInset,
                    BackgroundTransparency = 0.15,
                    AutoButtonColor = false,
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(opt),
                    TextSize = 10,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextColor3 = Palette.TextMuted,
                    ZIndex = 46,
                    Parent = body,
                })
                UI.Corner(optBtn, 7)
                local oStroke = UI.Stroke(optBtn, Palette.Border, 1, 0.45)
                itemBtns[opt] = { btn = optBtn, stroke = oStroke }
                Janitor.Add(optBtn.MouseButton1Click:Connect(function()
                    local nextList = {}
                    local cur = type(State[meta.key]) == "table" and State[meta.key] or {}
                    local existed = false
                    for _, v in ipairs(cur) do
                        if v == opt then
                            existed = true
                        else
                            table.insert(nextList, v)
                        end
                    end
                    if not existed then
                        table.insert(nextList, opt)
                    end
                    App.SetState(meta.key, nextList)
                    if meta.onChange then
                        safeCall(meta.onChange, nextList)
                    end
                end))
            end

            local function sync()
                local cur = type(State[meta.key]) == "table" and State[meta.key] or {}
                summaryLbl.Text = tostring(#cur) .. " selected"
                for opt, info in pairs(itemBtns) do
                    local sel = isSelected(opt)
                    info.btn.BackgroundColor3 = sel and Palette.NeonBlue or Palette.BgInset
                    info.btn.BackgroundTransparency = sel and 0.74 or 0.15
                    info.btn.TextColor3 = sel and Palette.TextPrimary or Palette.TextMuted
                    info.stroke.Color = sel and Palette.NeonBlue or Palette.Border
                    info.stroke.Transparency = sel and 0.1 or 0.45
                end
            end

            Janitor.Add(headerBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                chevLbl.Text = expanded and "^" or "v"
                local targetH = expanded and (closedH + bodyH + 6) or closedH
                App.Anim.Play(card, "DropExp", App.Anim.SpringSoft, {
                    Size = UDim2.new(1, 0, 0, targetH),
                })
            end))

            ctx.SyncFns[meta.key] = ctx.SyncFns[meta.key] or {}
            table.insert(ctx.SyncFns[meta.key], sync)
            registerFilterWidget(tab.id, card, meta.label .. " " .. meta.key .. " " .. table.concat(opts, " "))
            sync()
            return card
        end

        local function makeActionBtn(tab, meta)
            local order = tab.nextOrder()
            local accent = meta.color or Palette.NeonBlue
            local btn = UI.Create("TextButton", {
                LayoutOrder = order,
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = accent,
                BackgroundTransparency = 0.82,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = meta.label,
                TextSize = 12,
                TextColor3 = Palette.TextPrimary,
                ZIndex = 44,
                Parent = tab.scroll,
            })
            UI.Corner(btn, 10)
            UI.Stroke(btn, accent, 1.2, 0.25)
            App.Anim.BindButton(btn)
            Janitor.Add(btn.MouseButton1Click:Connect(function()
                if meta.onClick then
                    safeCall(meta.onClick, btn)
                end
            end))
            registerFilterWidget(tab.id, btn, meta.label .. " " .. tostring(meta.tags or ""))
            return btn
        end

        local function buildHubShell()
            local backdrop = UI.Create("Frame", {
                Name = "HubBackdrop",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 1,
                Visible = false,
                ZIndex = 40,
                Parent = ctx.MainGui,
            })
            local modalBtn = UI.Create("TextButton", {
                Name = "ModalUnlockBtn",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Modal = true,
                Text = "",
                ZIndex = 40,
                Parent = backdrop,
            })

            local win = UI.Create("Frame", {
                Name = "HubWindow",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(580, 390),
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.05,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 42,
                Parent = ctx.MainGui,
            })
            UI.Corner(win, 14)
            UI.Stroke(win, Palette.Border, 1.4, 0.1)
            local winScale = App.Anim.EnsureScale(win)

            local header = UI.Create("Frame", {
                Name = "HubHeader",
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = Palette.BgElevated,
                BackgroundTransparency = 0.1,
                ZIndex = 43,
                Parent = win,
            })
            UI.Create("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Palette.Border,
                BackgroundTransparency = 0.3,
                Active = false,
                ZIndex = 44,
                Parent = header,
            })

            UI.Create("TextLabel", {
                Position = UDim2.fromOffset(14, 0),
                Size = UDim2.fromOffset(146, 44),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBlack,
                Text = "PRISON LIFE 2026",
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 44,
                Parent = header,
            })

            local verPill = UI.Create("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 162, 0.5, 0),
                Size = UDim2.fromOffset(48, 20),
                BackgroundColor3 = Palette.NeonBlue,
                BackgroundTransparency = 0.76,
                Font = Enum.Font.GothamBold,
                Text = "KX V3",
                TextSize = 10,
                TextColor3 = Palette.NeonCyan,
                Active = false,
                ZIndex = 44,
                Parent = header,
            })
            UI.Corner(verPill, 6)
            UI.Stroke(verPill, Palette.NeonBlue, 1, 0.35)

            local closeBtn = UI.Create("TextButton", {
                Name = "HubCloseBtn",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(30, 30),
                BackgroundColor3 = Palette.BgInset,
                BackgroundTransparency = 0.1,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "X",
                TextSize = 13,
                TextColor3 = Palette.RedAlert,
                ZIndex = 44,
                Parent = header,
            })
            UI.Corner(closeBtn, 8)
            App.Anim.BindButton(closeBtn)

            local searchRow = UI.Create("Frame", {
                Name = "SearchBarWrap",
                Position = UDim2.fromOffset(10, 48),
                Size = UDim2.new(1, -20, 0, 30),
                BackgroundColor3 = Palette.BgInset,
                BackgroundTransparency = 0.15,
                ZIndex = 43,
                Parent = win,
            })
            UI.Corner(searchRow, 8)
            UI.Stroke(searchRow, Palette.Border, 1, 0.35)

            local searchBox = UI.Create("TextBox", {
                Name = "HubSearchBox",
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -46, 1, 0),
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                Font = Enum.Font.GothamMedium,
                PlaceholderText = "Search features across all 6 tabs...",
                PlaceholderColor3 = Palette.TextSubtle,
                Text = tostring(State.HubSearch or ""),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Palette.TextPrimary,
                ZIndex = 44,
                Parent = searchRow,
            })

            local searchClear = UI.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(24, 22),
                BackgroundColor3 = Palette.BgElevated,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "x",
                TextSize = 11,
                TextColor3 = Palette.TextMuted,
                Visible = false,
                ZIndex = 44,
                Parent = searchRow,
            })
            UI.Corner(searchClear, 6)

            local navScroll = UI.Create("ScrollingFrame", {
                Name = "HubNav",
                Position = UDim2.fromOffset(10, 84),
                Size = UDim2.new(0, 124, 1, -94),
                BackgroundColor3 = Palette.BgCard,
                BackgroundTransparency = 0.25,
                ScrollBarThickness = 0,
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 43,
                Parent = win,
            })
            UI.Corner(navScroll, 10)
            UI.Pad(navScroll, 5, 5, 5, 5)
            local navLayout = UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = navScroll,
            })

            local contentHost = UI.Create("Frame", {
                Name = "HubContent",
                Position = UDim2.fromOffset(142, 84),
                Size = UDim2.new(1, -152, 1, -94),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                ZIndex = 43,
                Parent = win,
            })

            for idx, def in ipairs(TAB_DEFS) do
                local navBtn = UI.Create("TextButton", {
                    LayoutOrder = idx,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Palette.BgElevated,
                    BackgroundTransparency = 0.8,
                    AutoButtonColor = false,
                    Text = "",
                    ZIndex = 44,
                    Parent = navScroll,
                })
                UI.Corner(navBtn, 8)
                local nStroke = UI.Stroke(navBtn, Palette.NeonBlue, 1.1, 1)
                local barAccent = UI.Create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 3, 0.5, 0),
                    Size = UDim2.fromOffset(3, 18),
                    BackgroundColor3 = Palette.NeonCyan,
                    Visible = false,
                    Active = false,
                    ZIndex = 45,
                    Parent = navBtn,
                })
                UI.Corner(barAccent, 2)
                local nLbl = UI.Create("TextLabel", {
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -14, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = def.label,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextColor3 = Palette.TextMuted,
                    Active = false,
                    ZIndex = 45,
                    Parent = navBtn,
                })

                local page = UI.Create("ScrollingFrame", {
                    Name = "Page_" .. def.id,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Palette.NeonBlue,
                    CanvasSize = UDim2.fromOffset(0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    ZIndex = 43,
                    Parent = contentHost,
                })
                UI.Pad(page, 2, 6, 2, 8)
                UI.Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 7),
                    Parent = page,
                })

                local orderCounter = 0
                local tabApi = {
                    id = def.id,
                    def = def,
                    navBtn = navBtn,
                    navStroke = nStroke,
                    navAccent = barAccent,
                    navLabel = nLbl,
                    scroll = page,
                    nextOrder = function()
                        orderCounter = orderCounter + 1
                        return orderCounter
                    end,
                }
                tabApi.Section = function(title, accent)
                    return makeSection(tabApi, title, accent)
                end
                tabApi.Toggle = function(meta)
                    return makeToggle(tabApi, meta)
                end
                tabApi.Slider = function(meta)
                    return makeSlider(tabApi, meta)
                end
                tabApi.Segmented = function(meta)
                    return makeSegmented(tabApi, meta)
                end
                tabApi.Dropdown = function(meta)
                    return makeDropdown(tabApi, meta)
                end
                tabApi.Button = function(meta)
                    return makeActionBtn(tabApi, meta)
                end
                ctx.TabData[def.id] = tabApi
            end

            local function layoutHubWindow()
                local vp = getViewport()
                local sa = App.SafeArea or {}
                local insetTop = sa.InsetTop or 36
                local winW = clampNum(vp.X - 32, 340, 640)
                local topBound = insetTop + 4
                local botBound = vp.Y - 64
                local maxAvailH = math.max(200, botBound - topBound)
                local winH = clampNum(vp.Y - insetTop - 110, 200, math.min(440, maxAvailH))
                if winH > maxAvailH then
                    winH = maxAvailH
                end
                local halfH = math.floor(winH * 0.5)
                local minCenter = topBound + halfH
                local maxCenter = math.max(minCenter, botBound - halfH)
                local centerY = clampNum(math.floor((topBound + botBound) * 0.5), minCenter, maxCenter)
                win.Size = UDim2.fromOffset(winW, winH)
                win.Position = UDim2.fromOffset(math.floor(vp.X * 0.5), centerY)

                local compact = isCompactLayout() or vp.X <= 740 or vp.Y < 450
                if compact then
                    navScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
                    navScroll.Position = UDim2.fromOffset(10, 84)
                    navScroll.Size = UDim2.new(1, -20, 0, 34)
                    navLayout.FillDirection = Enum.FillDirection.Horizontal
                    navLayout.Padding = UDim.new(0, 5)
                    contentHost.Position = UDim2.fromOffset(10, 124)
                    contentHost.Size = UDim2.new(1, -20, 1, -132)
                    for _, td in pairs(ctx.TabData) do
                        td.navBtn.Size = UDim2.fromOffset(82, 24)
                        td.navAccent.Visible = false
                        td.navLabel.Text = td.def.short
                        td.navLabel.Position = UDim2.fromOffset(4, 0)
                        td.navLabel.Size = UDim2.new(1, -8, 1, 0)
                        td.navLabel.TextXAlignment = Enum.TextXAlignment.Center
                        td.navLabel.TextSize = 10
                    end
                else
                    navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                    navScroll.Position = UDim2.fromOffset(10, 84)
                    navScroll.Size = UDim2.new(0, 126, 1, -94)
                    navLayout.FillDirection = Enum.FillDirection.Vertical
                    navLayout.Padding = UDim.new(0, 5)
                    contentHost.Position = UDim2.fromOffset(144, 84)
                    contentHost.Size = UDim2.new(1, -154, 1, -94)
                    for _, td in pairs(ctx.TabData) do
                        td.navBtn.Size = UDim2.new(1, 0, 0, 34)
                        td.navLabel.Text = td.def.label
                        td.navLabel.Position = UDim2.fromOffset(10, 0)
                        td.navLabel.Size = UDim2.new(1, -14, 1, 0)
                        td.navLabel.TextXAlignment = Enum.TextXAlignment.Left
                        td.navLabel.TextSize = 11
                    end
                end
                if ctx.CurrentTab and ctx.TabData[ctx.CurrentTab] then
                    ctx.TabData[ctx.CurrentTab].navAccent.Visible = not compact
                end
            end

            local function selectTab(rawName, instant)
                if ctx.StopKeybindListen then
                    ctx.StopKeybindListen()
                end
                local key = TAB_ALIAS[string.lower(tostring(rawName or "Shield"))] or rawName
                if not ctx.TabData[key] then
                    key = "Shield"
                end
                ctx.CurrentTab = key
                if State.ActiveTab ~= key then
                    App.SetState("ActiveTab", key, true)
                end
                local vp = getViewport()
                local compact = isCompactLayout() or vp.X <= 740 or vp.Y < 450
                for id, td in pairs(ctx.TabData) do
                    local active = (id == key)
                    td.navBtn.BackgroundColor3 = active and Palette.NeonBlue or Palette.BgElevated
                    td.navBtn.BackgroundTransparency = active and 0.72 or 0.55
                    td.navStroke.Transparency = active and 0.15 or 1
                    td.navAccent.Visible = active and (not compact)
                    td.navLabel.TextColor3 = active and Palette.TextPrimary or Palette.TextMuted
                    if active then
                        td.scroll.Visible = true
                        if not instant then
                            td.scroll.Position = UDim2.fromOffset(0, 12)
                            App.Anim.Play(td.scroll, "PageIn", App.Anim.SpringSoft, { Position = UDim2.fromOffset(0, 0) })
                        else
                            td.scroll.Position = UDim2.fromOffset(0, 0)
                        end
                    else
                        td.scroll.Visible = false
                    end
                end
            end

            local function filterWidgets(query)
                local q = string.lower(App.Trim(query or ""))
                searchClear.Visible = (q ~= "")
                local tabMatches = {}
                for _, item in ipairs(ctx.WidgetFilterEntries) do
                    if string.sub(item.search, 1, 7) == "__sec__" then
                        item.card.Visible = (q == "")
                    elseif q == "" or string.find(item.search, q, 1, true) then
                        item.card.Visible = true
                        tabMatches[item.tab] = (tabMatches[item.tab] or 0) + 1
                    else
                        item.card.Visible = false
                    end
                end
                if q ~= "" and (tabMatches[ctx.CurrentTab] or 0) == 0 then
                    for _, id in ipairs(ctx.TabOrder) do
                        if (tabMatches[id] or 0) > 0 then
                            selectTab(id, true)
                            break
                        end
                    end
                end
            end

            for id, td in pairs(ctx.TabData) do
                Janitor.Add(td.navBtn.MouseButton1Click:Connect(function()
                    selectTab(id, false)
                end))
            end
            Janitor.Add(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                App.SetState("HubSearch", searchBox.Text, true)
                filterWidgets(searchBox.Text)
            end))
            Janitor.Add(searchClear.MouseButton1Click:Connect(function()
                searchBox.Text = ""
            end))
            Janitor.Add(closeBtn.MouseButton1Click:Connect(function()
                if App.Hub and App.Hub.SetVisible then
                    App.Hub.SetVisible(false)
                end
            end))
            Janitor.Add(modalBtn.MouseButton1Click:Connect(function()
                if App.Hub and App.Hub.SetVisible then
                    App.Hub.SetVisible(false)
                end
            end))

            ctx.HubBackdrop = backdrop
            ctx.HubWindow = win
            ctx.HubScale = winScale
            ctx.LayoutHubWindow = layoutHubWindow
            ctx.SelectHubTab = selectTab
            ctx.FilterHubWidgets = filterWidgets
            ctx.RegisterFilterWidget = registerFilterWidget
            layoutHubWindow()
        end

        buildHubShell()
    end

    -- ========================================================================
    -- BLOCK 8: POPULATE ALL 6 HUB TABS + KEYBIND REBIND + PROFILE MANAGER
    -- ========================================================================
    do
        local function buildTabShield(tab)
            tab.Section("Riot Shield & Defense", Palette.NeonBlue)
            tab.Toggle({
                key = "ShieldEnabled",
                label = "Riot Shield Master",
                sub = "Equips & maintains protective shield",
                onChange = function(v)
                    if App.Shield and App.Shield.SetEnabled then
                        safeCall(App.Shield.SetEnabled, v)
                    end
                end,
            })
            tab.Segmented({
                key = "ShieldMode",
                label = "Protection Mode",
                options = { "Hybrid", "RiotOnly", "DesyncBox", "FEGhost" },
                onChange = function(mode)
                    if App.Shield and App.Shield.SetMode then
                        safeCall(App.Shield.SetMode, mode)
                    end
                end,
            })
            tab.Toggle({ key = "ShieldAutoEquip", label = "Auto-Equip Shield", sub = "Re-equips when holster clears" })
            tab.Toggle({ key = "ShieldAutoFaceShooter", label = "Auto-Face Shooter", sub = "Turns defense toward incoming fire" })
            tab.Toggle({ key = "ShieldSpinBlock", label = "Spin Block", sub = "360 desync shield rotation" })
            tab.Slider({ key = "ShieldSize", label = "Shield Box Scale", min = 3, max = 14, step = 0.5 })
            tab.Slider({ key = "ShieldTransparency", label = "Shield Transparency", min = 0.45, max = 0.95, step = 0.01 })
            tab.Slider({ key = "ShieldSpinSpeed", label = "Spin Block Speed", min = 4, max = 40, step = 1 })
            tab.Slider({ key = "DesyncJitterRadius", label = "Desync Jitter Radius", min = 1, max = 8, step = 0.2 })

            tab.Section("Anti-CC & Stealth", Palette.NeonCyan)
            tab.Toggle({
                key = "AntiTaze",
                label = "Anti-Taze",
                onChange = function(v)
                    if v and App.Shield and App.Shield.InstallAntiTaze then
                        safeCall(App.Shield.InstallAntiTaze)
                    end
                end,
            })
            tab.Toggle({ key = "AntiArrest", label = "Anti-Arrest", sub = "Counters cuff / arrest prompts" })
            tab.Toggle({
                key = "FEInvisible",
                label = "FE Ghost Invisibility",
                color = Palette.NeonCyan,
                onChange = function(v)
                    if App.Shield and App.Shield.SetFEInvisible then
                        safeCall(App.Shield.SetFEInvisible, v)
                    end
                end,
            })
            tab.Toggle({ key = "AntiInvisible", label = "Reveal Invisible Players" })
            tab.Button({
                label = "Clean Character Effects",
                color = Palette.Emerald,
                tags = "taze cuffragdoll clean",
                onClick = function()
                    if App.Shield and App.Shield.CleanCharacterEffects then
                        safeCall(App.Shield.CleanCharacterEffects)
                    end
                end,
            })
        end

        local function buildCombatRage(tab)
            tab.Section("Ragebot & Combo", Palette.RageCrimson)
            tab.Toggle({ key = "Ragebot", label = "Ragebot", sub = "Rapid auto-kill visible or walled hostiles", color = Palette.RageCrimson })
            tab.Toggle({ key = "Ragebot360", label = "360-Degree Target Scan" })
            tab.Toggle({ key = "RagebotAutoSwitch", label = "Auto-Switch Best Gun" })
            tab.Toggle({ key = "RagebotPeekShield", label = "Peek Through Shield", sub = "Alternates guard frame to fire" })
            tab.Slider({ key = "RagebotRate", label = "Ragebot Fire Rate", min = 2, max = 35, step = 1, suffix = " sps", color = Palette.RageCrimson })
            tab.Toggle({ key = "ComboAutoGrabGuns", label = "Combo Auto-Grab Guns" })
            tab.Toggle({ key = "ComboReEquipShield", label = "Combo Re-Equip Shield" })
            tab.Toggle({ key = "ComboLoop", label = "Loop .combo1", color = Palette.StreakGold })
            tab.Slider({ key = "ComboLoopInterval", label = "Combo Loop Interval", min = 0.2, max = 2.5, step = 0.05, suffix = "s" })
            tab.Button({
                label = "Execute .combo1 Now",
                color = Palette.StreakGold,
                tags = "combo1 quick macro",
                onClick = function()
                    if ctx.FlashCombo then
                        ctx.FlashCombo()
                    end
                    if App.Weapons and App.Weapons.ExecuteCombo1 then
                        safeCall(App.Weapons.ExecuteCombo1)
                    end
                end,
            })
        end

        local function buildCombatSilent(tab)
            tab.Section("Silent Aim", Palette.NeonBlue)
            tab.Toggle({ key = "SilentAim", label = "Silent Aim", sub = "Redirects bullet raycast inside FOV" })
            tab.Toggle({ key = "SilentAimShowFOV", label = "Show Clamped FOV Circle" })
            tab.Slider({ key = "SilentAimFOV", label = "Silent Aim FOV", min = 30, max = 360, step = 5, suffix = " px" })
            tab.Segmented({ key = "SilentAimTargetPart", label = "Priority Bone", options = { "Head", "Torso", "Random" } })
            tab.Slider({ key = "SilentAimHitChance", label = "Hit Chance", min = 10, max = 100, step = 5, suffix = "%" })
            tab.Slider({ key = "SilentAimHeadChance", label = "Headshot Chance", min = 0, max = 100, step = 5, suffix = "%" })
            tab.Toggle({ key = "SilentAimWallcheck", label = "Wallcheck" })
            tab.Toggle({ key = "SilentAimWallbang", label = "Wallbang Assist" })
            tab.Toggle({ key = "SilentAimTeamCheck", label = "Team Check" })
            tab.Toggle({ key = "SilentAimHostileCheck", label = "Hostiles Only" })
            tab.Toggle({ key = "SilentAimSkipDown", label = "Skip Downed Players" })
        end

        local function buildCombatAura(tab)
            tab.Section("Aim Assist, Aura & Hitbox", Palette.NeonCyan)
            tab.Toggle({ key = "AimAssist", label = "Camera Aim Assist" })
            tab.Slider({ key = "AimAssistFOV", label = "Aim Assist FOV", min = 30, max = 350, step = 5, suffix = " px" })
            tab.Slider({ key = "AimAssistSmooth", label = "Aim Assist Smooth", min = 0.05, max = 0.95, step = 0.01 })
            tab.Toggle({ key = "KillAura", label = "Melee KillAura", color = Palette.RageCrimson })
            tab.Slider({ key = "KillAuraRange", label = "KillAura Range", min = 6, max = 30, step = 1, color = Palette.RageCrimson })
            tab.Slider({ key = "KillAuraRate", label = "KillAura Rate", min = 4, max = 24, step = 1, color = Palette.RageCrimson })
            tab.Toggle({ key = "KillAuraTeamCheck", label = "KillAura Team Check" })
            tab.Toggle({ key = "KillAuraHostileOnly", label = "KillAura Hostiles Only" })
            tab.Toggle({
                key = "HitboxExpander",
                label = "Hitbox Expander",
                onChange = function()
                    if App.Visuals and App.Visuals.UpdateHitboxExpander then
                        safeCall(App.Visuals.UpdateHitboxExpander)
                    end
                end,
            })
            tab.Slider({
                key = "HitboxSize",
                label = "Hitbox Size",
                min = 3,
                max = 25,
                step = 0.5,
                onChange = function()
                    if App.Visuals and App.Visuals.UpdateHitboxExpander then
                        safeCall(App.Visuals.UpdateHitboxExpander)
                    end
                end,
            })
            tab.Slider({ key = "HitboxTransparency", label = "Hitbox Transparency", min = 0, max = 0.95, step = 0.05 })
            tab.Toggle({ key = "HitboxTeamCheck", label = "Hitbox Team Check" })
            tab.Toggle({ key = "AntiRiotShield", label = "Bypass Enemy Riot Shield" })
            tab.Toggle({ key = "AutoArmorPen", label = "Auto Armor Penetration" })
            tab.Button({
                label = "Clear KillAura Whitelist",
                color = Palette.Amber,
                tags = "whitelist reset",
                onClick = function()
                    App.SetState("KillAuraWhitelist", {})
                end,
            })
            tab.Button({
                label = "Clear Loopkill Targets",
                color = Palette.RageCrimson,
                tags = "loopkill reset",
                onClick = function()
                    App.SetState("LoopKillTargets", {})
                end,
            })
        end

        local function buildTabGuns(tab)
            tab.Section("Weapon Modifications", Palette.NeonBlue)
            tab.Toggle({
                key = "GunMods",
                label = "Gun Mods Master",
                sub = "Applies spread, auto-fire & rate boosts",
                onChange = function()
                    if App.Combat and App.Combat.ApplyGunModsAll then
                        safeCall(App.Combat.ApplyGunModsAll)
                    end
                end,
            })
            tab.Toggle({ key = "GunAutoFire", label = "Automatic Fire" })
            tab.Slider({ key = "GunFireRateSPS", label = "Fire Rate Target", min = 5, max = 45, step = 1, suffix = " sps" })
            tab.Toggle({ key = "GunNoSpread", label = "Zero Spread" })
            tab.Toggle({ key = "GunInfiniteRange", label = "Extended / Inf Range" })
            tab.Toggle({ key = "GunAutoReload", label = "Auto-Reload Empty" })

            tab.Section("Loadout & Survival", Palette.Emerald)
            tab.Toggle({ key = "AutoGetGuns", label = "Auto-Grab Guns on Spawn" })
            tab.Dropdown({
                key = "AutoGunsSelection",
                label = "Loadout Weapons",
                options = { "Remington 870", "M4A1", "AK-47", "MP5", "FAL", "M9" },
            })
            tab.Toggle({ key = "AutoArmor", label = "Auto-Equip Armor" })
            tab.Toggle({ key = "AutoHeal", label = "Auto-Heal / Snack" })
            tab.Slider({ key = "AutoHealThreshold", label = "Heal HP Threshold", min = 20, max = 95, step = 5, suffix = "%" })
            tab.Toggle({ key = "AutoPickupDrops", label = "Auto-Pickup Weapon Drops" })
            tab.Button({
                label = "Grab Selected Loadout Now",
                color = Palette.NeonBlue,
                onClick = function()
                    if App.Weapons and App.Weapons.GrabWeapons then
                        safeCall(App.Weapons.GrabWeapons, State.AutoGunsSelection, false)
                    end
                end,
            })
            tab.Button({
                label = "Switch Team -> Guards",
                color = Palette.GuardBlue,
                onClick = function()
                    if App.Weapons and App.Weapons.SwitchToTeam then
                        safeCall(App.Weapons.SwitchToTeam, "Guards")
                    end
                end,
            })
            tab.Button({
                label = "Switch Team -> Inmates",
                color = Palette.InmateOrange,
                onClick = function()
                    if App.Weapons and App.Weapons.SwitchToTeam then
                        safeCall(App.Weapons.SwitchToTeam, "Inmates")
                    end
                end,
            })
            tab.Button({
                label = "Switch Team -> Criminals",
                color = Palette.CrimRed,
                onClick = function()
                    if App.Weapons and App.Weapons.SwitchToTeam then
                        safeCall(App.Weapons.SwitchToTeam, "Criminals")
                    end
                end,
            })
        end

        local function buildTabPrison(tab)
            tab.Section("Prison & World", Palette.Amber)
            tab.Toggle({ key = "AutoArrest", label = "Auto-Arrest Criminals", color = Palette.GuardBlue })
            tab.Slider({ key = "AutoArrestRange", label = "Auto-Arrest Range", min = 5, max = 22, step = 0.5 })
            tab.Toggle({ key = "AutoTaze", label = "Auto-Taze Nearby" })
            tab.Toggle({ key = "AutoDetonateC4", label = "Auto-Detonate C4" })
            tab.Toggle({ key = "AutoCriminal", label = "Auto-Become Criminal" })
            tab.Toggle({ key = "AutoRespawn", label = "Fast Auto-Respawn" })
            tab.Toggle({
                key = "FenceGodmode",
                label = "Electric Fence Godmode",
                onChange = function(v)
                    if App.World and App.World.SetFenceGodmode then
                        safeCall(App.World.SetFenceGodmode, v)
                    end
                end,
            })
            tab.Toggle({
                key = "OpenAllDoors",
                label = "Open / Pass Doors",
                onChange = function(v)
                    if App.World and App.World.SetOpenAllDoors then
                        safeCall(App.World.SetOpenAllDoors, v)
                    end
                end,
            })
            tab.Toggle({ key = "AntiKillPlane", label = "Anti-Void / KillPlane" })
            tab.Toggle({
                key = "AntiFling",
                label = "Anti-Fling Protection",
                onChange = function(v)
                    if App.World and App.World.SafeSetAntiFlingEnabled then
                        safeCall(App.World.SafeSetAntiFlingEnabled, v)
                    end
                end,
            })

            tab.Section("Vehicle Mods", Palette.NeonCyan)
            tab.Toggle({ key = "VehicleFly", label = "Vehicle Fly", color = Palette.NeonCyan })
            tab.Slider({ key = "VehicleFlySpeed", label = "Vehicle Fly Speed", min = 25, max = 220, step = 5 })
            tab.Toggle({ key = "VehicleSpeedMod", label = "Vehicle Speed Boost" })
            tab.Slider({ key = "VehicleSpeedMult", label = "Speed Multiplier", min = 1.0, max = 4.5, step = 0.1, suffix = "x" })
            tab.Toggle({ key = "VehicleFling", label = "Vehicle Fling Impact", color = Palette.RageCrimson })
            tab.Toggle({ key = "VehicleWallbang", label = "Vehicle Wallbang" })
            tab.Button({
                label = "Spawn & Enter Nearest Car",
                color = Palette.NeonBlue,
                onClick = function()
                    if App.World and App.World.SpawnAndEnterNearestCar then
                        safeCall(App.World.SpawnAndEnterNearestCar)
                    end
                end,
            })
            tab.Button({
                label = "Clear Arrest Whitelist",
                color = Palette.Amber,
                onClick = function()
                    App.SetState("ArrestWhitelist", {})
                end,
            })
        end

        local function buildTabMoveSection(tab)
            tab.Section("Movement", Palette.Emerald)
            tab.Toggle({ key = "MaxSpeed", label = "Speed Override Master", color = Palette.Emerald })
            tab.Segmented({ key = "SpeedMode", label = "Speed Mode", options = { "RegionSafe", "Custom", "AlwaysSprint" } })
            tab.Slider({ key = "WalkSpeed", label = "Custom WalkSpeed", min = 16, max = 110, step = 1 })
            tab.Toggle({ key = "JumpPowerEnabled", label = "Custom JumpPower" })
            tab.Slider({ key = "JumpPower", label = "JumpPower", min = 50, max = 135, step = 1 })
            tab.Toggle({ key = "InfiniteJump", label = "Infinite Air Jump" })
            tab.Toggle({ key = "AntiJumpCooldown", label = "Remove Jump Cooldown" })
            tab.Toggle({ key = "AntiNoclipBypass", label = "Bypass Anti-Noclip" })
            tab.Toggle({ key = "Fly", label = "Player Fly", color = Palette.NeonCyan })
            tab.Slider({ key = "FlySpeed", label = "Fly Speed", min = 20, max = 220, step = 5 })
            tab.Toggle({
                key = "Noclip",
                label = "Wall Noclip",
                onChange = function(v)
                    if not v and App.World and App.World.RestoreNoclipCollide then
                        safeCall(App.World.RestoreNoclipCollide)
                    end
                end,
            })
            tab.Toggle({ key = "AntiAFK", label = "Anti-AFK Idle Guard" })
        end

        local function buildTabVisualsSection(tab)
            tab.Section("Player & C4 ESP", Palette.NeonBlue)
            tab.Toggle({ key = "ESPEnabled", label = "ESP Master" })
            tab.Toggle({ key = "ESPHideTeam", label = "Hide Teammates" })
            tab.Toggle({ key = "ESPBoxes", label = "2D Bounding Boxes" })
            tab.Toggle({ key = "ESPNames", label = "Name & Wanted Tag" })
            tab.Toggle({ key = "ESPHealthBar", label = "Health Bars" })
            tab.Toggle({ key = "ESPDistance", label = "Distance Studs" })
            tab.Toggle({ key = "ESPDiamondMarker", label = "Head Diamond Marker" })
            tab.Toggle({ key = "ESPTracers", label = "Snaplines / Tracers" })
            tab.Toggle({ key = "C4ESP", label = "C4 Explosive ESP" })
            tab.Slider({ key = "ESPMaxDistance", label = "ESP Max Distance", min = 100, max = 1200, step = 25 })
            tab.Slider({ key = "ESPDetailDistance", label = "Detail Fade Distance", min = 40, max = 400, step = 10 })

            tab.Section("Combat Feedback & VFX", Palette.StreakGold)
            tab.Toggle({ key = "BulletTracers", label = "Bullet Tracer Beams" })
            tab.Slider({ key = "BulletTracerFade", label = "Tracer Fade Time", min = 0.08, max = 0.6, step = 0.02, suffix = "s" })
            tab.Toggle({ key = "Hitmarker", label = "4-Tick Hitmarker" })
            tab.Toggle({ key = "HitSound", label = "Hit Confirm Audio" })
            tab.Toggle({ key = "KillSound", label = "Kill Audio Cue" })
            tab.Toggle({ key = "DamageNumbers", label = "Floating Damage Numbers" })
            tab.Toggle({ key = "ShieldHitVFX", label = "Shield Block Pulse VFX" })
        end

        local function buildKeybindCard(tab)
            tab.Section("Keybinds (Click to Rebind)", Palette.NeonCyan)
            local actions = {
                { key = "ToggleHub", label = "Toggle Hub" },
                { key = "AltToggleHub", label = "Alt Toggle Hub" },
                { key = "ToggleShield", label = "Toggle Shield" },
                { key = "Combo1", label = "Execute .combo1" },
                { key = "ToggleRagebot", label = "Toggle Ragebot" },
                { key = "ToggleFly", label = "Toggle Fly" },
                { key = "ToggleNoclip", label = "Toggle Noclip" },
                { key = "FocusCmdBar", label = "Focus KX Bar" },
            }

            local card = UI.Create("Frame", {
                LayoutOrder = tab.nextOrder(),
                Size = UDim2.new(1, 0, 0, #actions * 32 + 12),
                BackgroundColor3 = Palette.BgCard,
                BackgroundTransparency = 0.08,
                ZIndex = 44,
                Parent = tab.scroll,
            })
            UI.Corner(card, 10)
            UI.Stroke(card, Palette.Border, 1.1, 0.35)
            UI.Pad(card, 10, 10, 6, 6)
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = card,
            })

            local listeningAction = nil
            local listenConn = nil

            local function stopListening()
                local prevAct = listeningAction
                listeningAction = nil
                ctx.HubRebinding = false
                if App.Hub then
                    App.Hub._IsRebinding = false
                end
                if listenConn and listenConn.Disconnect then
                    listenConn:Disconnect()
                    listenConn = nil
                end
                if prevAct and ctx.KeybindRows[prevAct] then
                    local r = ctx.KeybindRows[prevAct]
                    if r.btn then
                        r.btn.Text = tostring((State.Keybinds and State.Keybinds[prevAct]) or "None")
                    end
                    if r.stroke then
                        r.stroke.Color = Palette.Border
                    end
                end
            end
            ctx.StopKeybindListen = stopListening

            for idx, item in ipairs(actions) do
                local row = UI.Create("Frame", {
                    LayoutOrder = idx,
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    ZIndex = 45,
                    Parent = card,
                })
                UI.Create("TextLabel", {
                    Size = UDim2.new(1, -104, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    Text = item.label,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = Palette.TextPrimary,
                    Active = false,
                    ZIndex = 46,
                    Parent = row,
                })
                local keyBtn = UI.Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(98, 24),
                    BackgroundColor3 = Palette.BgInset,
                    BackgroundTransparency = 0.12,
                    AutoButtonColor = false,
                    Font = Enum.Font.GothamBold,
                    Text = tostring((State.Keybinds and State.Keybinds[item.key]) or "None"),
                    TextSize = 10,
                    TextColor3 = Palette.NeonCyan,
                    ZIndex = 46,
                    Parent = row,
                })
                UI.Corner(keyBtn, 6)
                local kStroke = UI.Stroke(keyBtn, Palette.Border, 1, 0.35)
                ctx.KeybindRows[item.key] = { btn = keyBtn, stroke = kStroke }

                Janitor.Add(keyBtn.MouseButton1Click:Connect(function()
                    if listeningAction == item.key then
                        stopListening()
                        return
                    end
                    stopListening()
                    listeningAction = item.key
                    ctx.HubRebinding = true
                    if App.Hub then
                        App.Hub._IsRebinding = true
                    end
                    keyBtn.Text = "Press key..."
                    kStroke.Color = Palette.StreakGold

                    listenConn = Janitor.Add(Services.UserInputService.InputBegan:Connect(function(inp)
                        if not listeningAction then
                            return
                        end
                        if inp.UserInputType ~= Enum.UserInputType.Keyboard then
                            return
                        end
                        local kc = inp.KeyCode
                        local targetAct = listeningAction
                        stopListening()
                        kStroke.Color = Palette.Border
                        if kc == Enum.KeyCode.Escape then
                            keyBtn.Text = tostring((State.Keybinds and State.Keybinds[targetAct]) or "None")
                            return
                        end
                        local newKey = (kc == Enum.KeyCode.Backspace) and "None" or kc.Name
                        if newKey ~= "None" and State.Keybinds then
                            for otherAct, otherKey in pairs(State.Keybinds) do
                                if otherAct ~= targetAct and otherKey == newKey then
                                    App.HUD.PushAlert("Keybind", newKey .. " already bound to " .. otherAct, "warn")
                                    keyBtn.Text = tostring(State.Keybinds[targetAct] or "None")
                                    return
                                end
                            end
                        end
                        local nextBinds = App.DeepCopy(State.Keybinds or {})
                        nextBinds[targetAct] = newKey
                        App.SetState("Keybinds", nextBinds)
                        keyBtn.Text = newKey
                    end))
                end))
            end

            ctx.RegisterFilterWidget(tab.id, card, "keybind togglehub shield combo1 ragebot fly noclip focus")
        end

        local function buildProfileCard(tab)
            tab.Section("Presets & Config Profiles", Palette.Emerald)
            local card = UI.Create("Frame", {
                LayoutOrder = tab.nextOrder(),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Palette.BgCard,
                BackgroundTransparency = 0.08,
                ZIndex = 44,
                Parent = tab.scroll,
            })
            UI.Corner(card, 10)
            UI.Stroke(card, Palette.Border, 1.1, 0.35)
            UI.Pad(card, 10, 10, 8, 8)
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 7),
                Parent = card,
            })

            local presetRow = UI.Create("Frame", {
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                ZIndex = 45,
                Parent = card,
            })
            UI.Create("UIGridLayout", {
                CellSize = UDim2.new(0.333, -4, 1, 0),
                CellPadding = UDim2.fromOffset(6, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = presetRow,
            })
            local presets = {
                { name = "Legit", col = Palette.Emerald },
                { name = "Rage", col = Palette.RageCrimson },
                { name = "Mobile", col = Palette.NeonBlue },
            }
            for idx, p in ipairs(presets) do
                local pb = UI.Create("TextButton", {
                    LayoutOrder = idx,
                    BackgroundColor3 = p.col,
                    BackgroundTransparency = 0.78,
                    AutoButtonColor = false,
                    Font = Enum.Font.GothamBold,
                    Text = p.name .. " Preset",
                    TextSize = 10,
                    TextColor3 = Palette.TextPrimary,
                    ZIndex = 46,
                    Parent = presetRow,
                })
                UI.Corner(pb, 7)
                UI.Stroke(pb, p.col, 1, 0.3)
                App.Anim.BindButton(pb)
                Janitor.Add(pb.MouseButton1Click:Connect(function()
                    if App.Persistence and App.Persistence.ApplyPreset then
                        safeCall(App.Persistence.ApplyPreset, p.name)
                    end
                    if App.Hub and App.Hub.SyncHub then
                        App.Hub.SyncHub(true)
                    end
                    if ctx.RebuildPinnedPills then
                        ctx.RebuildPinnedPills()
                    end
                    App.HUD.PushAlert("Preset", "Applied " .. p.name .. " configuration", "success")
                end))
            end

            local saveRow = UI.Create("Frame", {
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                ZIndex = 45,
                Parent = card,
            })
            local profInput = UI.Create("TextBox", {
                Size = UDim2.new(1, -124, 1, 0),
                BackgroundColor3 = Palette.BgInset,
                ClearTextOnFocus = false,
                Font = Enum.Font.GothamMedium,
                PlaceholderText = "Profile name (default)",
                PlaceholderColor3 = Palette.TextSubtle,
                Text = "default",
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Palette.TextPrimary,
                ZIndex = 46,
                Parent = saveRow,
            })
            UI.Corner(profInput, 7)
            UI.Pad(profInput, 8, 6, 0, 0)

            local saveBtn = UI.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -60, 0, 0),
                Size = UDim2.fromOffset(56, 30),
                BackgroundColor3 = Palette.NeonBlue,
                BackgroundTransparency = 0.72,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "Save",
                TextSize = 11,
                TextColor3 = Palette.TextPrimary,
                ZIndex = 46,
                Parent = saveRow,
            })
            UI.Corner(saveBtn, 7)
            App.Anim.BindButton(saveBtn)

            local resetCfgBtn = UI.Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromOffset(54, 30),
                BackgroundColor3 = Palette.RedAlert,
                BackgroundTransparency = 0.78,
                AutoButtonColor = false,
                Font = Enum.Font.GothamBold,
                Text = "Reset",
                TextSize = 11,
                TextColor3 = Palette.TextPrimary,
                ZIndex = 46,
                Parent = saveRow,
            })
            UI.Corner(resetCfgBtn, 7)
            App.Anim.BindButton(resetCfgBtn)

            local profListHost = UI.Create("Frame", {
                LayoutOrder = 3,
                Size = UDim2.new(1, 0, 0, 26),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ZIndex = 45,
                Parent = card,
            })
            UI.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = profListHost,
            })

            local function refreshProfiles()
                for _, ch in ipairs(profListHost:GetChildren()) do
                    if ch:IsA("GuiObject") then
                        ch:Destroy()
                    end
                end
                local list = {}
                if App.Persistence and App.Persistence.List then
                    local ok, res = pcall(App.Persistence.List)
                    if ok and type(res) == "table" then
                        list = res
                    end
                end
                if #list == 0 then
                    UI.Create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 22),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = "No saved profiles yet",
                        TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextColor3 = Palette.TextSubtle,
                        Active = false,
                        ZIndex = 46,
                        Parent = profListHost,
                    })
                    return
                end
                for idx, pName in ipairs(list) do
                    local pRow = UI.Create("Frame", {
                        LayoutOrder = idx,
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = Palette.BgInset,
                        BackgroundTransparency = 0.25,
                        ZIndex = 46,
                        Parent = profListHost,
                    })
                    UI.Corner(pRow, 6)
                    UI.Pad(pRow, 8, 4, 0, 0)
                    UI.Create("TextLabel", {
                        Size = UDim2.new(1, -104, 1, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamMedium,
                        Text = tostring(pName),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextColor3 = Palette.TextPrimary,
                        Active = false,
                        ZIndex = 47,
                        Parent = pRow,
                    })
                    local ldBtn = UI.Create("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -46, 0.5, 0),
                        Size = UDim2.fromOffset(44, 20),
                        BackgroundColor3 = Palette.Emerald,
                        BackgroundTransparency = 0.78,
                        AutoButtonColor = false,
                        Font = Enum.Font.GothamBold,
                        Text = "Load",
                        TextSize = 10,
                        TextColor3 = Palette.TextPrimary,
                        ZIndex = 47,
                        Parent = pRow,
                    })
                    UI.Corner(ldBtn, 5)
                    local dlBtn = UI.Create("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.fromOffset(42, 20),
                        BackgroundColor3 = Palette.RedAlert,
                        BackgroundTransparency = 0.78,
                        AutoButtonColor = false,
                        Font = Enum.Font.GothamBold,
                        Text = "Del",
                        TextSize = 10,
                        TextColor3 = Palette.TextPrimary,
                        ZIndex = 47,
                        Parent = pRow,
                    })
                    UI.Corner(dlBtn, 5)
                    Janitor.Add(ldBtn.MouseButton1Click:Connect(function()
                        if App.Persistence and App.Persistence.Load then
                            safeCall(App.Persistence.Load, pName)
                        end
                        if App.Hub and App.Hub.SyncHub then
                            App.Hub.SyncHub(true)
                        end
                        if ctx.RebuildPinnedPills then
                            ctx.RebuildPinnedPills()
                        end
                        App.HUD.PushAlert("Config", "Loaded profile: " .. tostring(pName), "info")
                    end))
                    Janitor.Add(dlBtn.MouseButton1Click:Connect(function()
                        if App.Persistence and App.Persistence.Delete then
                            safeCall(App.Persistence.Delete, pName)
                        end
                        refreshProfiles()
                    end))
                end
            end

            Janitor.Add(saveBtn.MouseButton1Click:Connect(function()
                local nm = App.Trim(profInput.Text)
                if nm == "" then
                    nm = "default"
                end
                if App.Persistence and App.Persistence.Save then
                    safeCall(App.Persistence.Save, nm)
                end
                refreshProfiles()
                App.HUD.PushAlert("Config", "Saved profile: " .. nm, "success")
            end))

            Janitor.Add(resetCfgBtn.MouseButton1Click:Connect(function()
                if App.Persistence and App.Persistence.Reset then
                    safeCall(App.Persistence.Reset)
                end
                if App.Hub and App.Hub.SyncHub then
                    App.Hub.SyncHub(true)
                end
                if ctx.RebuildPinnedPills then
                    ctx.RebuildPinnedPills()
                end
                App.HUD.PushAlert("Config", "Factory defaults restored", "warn")
            end))

            ctx.RefreshProfilesFn = refreshProfiles
            ctx.RegisterFilterWidget(tab.id, card, "profile preset legit rage mobile save load delete config")
            refreshProfiles()
        end

        local function buildTabSettings(tab)
            tab.Section("HUD Layout & Notifications", Palette.NeonBlue)
            tab.Toggle({ key = "LockHUDLayout", label = "Lock HUD Dragging", sub = "Prevents accidental dragging in combat" })
            tab.Toggle({ key = "ShowComboButton", label = "Show Top-Left .combo1 + KX Crest" })
            tab.Toggle({ key = "ShowKXBar", label = "Show KX Admin Bar" })
            tab.Toggle({ key = "ShowIYPill", label = "Show Top-Center IY Pill" })
            tab.Toggle({ key = "ShowRightActions", label = "Show Right Quick Actions Dock" })
            tab.Toggle({
                key = "ShowPinnedPills",
                label = "Show Top-Left Quick Pin Chips",
                onChange = function()
                    if ctx.RebuildPinnedPills then
                        ctx.RebuildPinnedPills()
                    end
                end,
            })
            tab.Dropdown({
                key = "PinnedPills",
                label = "Pinned Quick Chips",
                options = { "Rage", "Shield", "Fly", "Noclip", "KillAura", "SilentAim", "AutoArrest" },
                onChange = function()
                    if ctx.RebuildPinnedPills then
                        ctx.RebuildPinnedPills()
                    end
                end,
            })
            tab.Toggle({ key = "ShowShieldBadge", label = "Show Shield / Ghost HP Pill" })
            tab.Toggle({ key = "ShowKillfeed", label = "Show Killfeed Stack" })
            tab.Segmented({
                key = "KillfeedPosition",
                label = "Killfeed Placement",
                options = { "AboveHotbar", "TopLeft" },
                onChange = function()
                    if ctx.SyncKillfeedAnchor then
                        ctx.SyncKillfeedAnchor()
                    end
                end,
            })
            tab.Toggle({ key = "ShowAlerts", label = "Show Alert Banners" })
            tab.Toggle({ key = "CheaterAlerts", label = "Suspect / Cheater Alerts" })
            tab.Toggle({ key = "CarTPAlerts", label = "Car Teleport Alerts" })
            tab.Slider({ key = "AlertDuration", label = "Alert Duration", min = 1.5, max = 8.0, step = 0.1, suffix = "s" })
            tab.Toggle({ key = "ChatCommands", label = "Chat Prefix Commands (;cmd)" })
            tab.Toggle({ key = "AutoLoadConfig", label = "Auto-Load Default Config" })
            tab.Button({
                label = "Reset All HUD Positions",
                color = Palette.Amber,
                tags = "layout reset hud positions",
                onClick = function()
                    if App.HUD and App.HUD.ResetLayoutPositions then
                        App.HUD.ResetLayoutPositions()
                    end
                end,
            })
            tab.Button({
                label = "Open KX Command Drawer",
                color = Palette.NeonCyan,
                onClick = function()
                    if ctx.ToggleCmdDrawer then
                        ctx.ToggleCmdDrawer(true, "Commands")
                    end
                end,
            })
        end

        buildTabShield(ctx.TabData.Shield)
        buildCombatRage(ctx.TabData.Combat)
        buildCombatSilent(ctx.TabData.Combat)
        buildCombatAura(ctx.TabData.Combat)
        buildTabGuns(ctx.TabData.Guns)
        buildTabPrison(ctx.TabData.Prison)
        buildTabMoveSection(ctx.TabData.Move)
        buildTabVisualsSection(ctx.TabData.Move)
        buildTabSettings(ctx.TabData.Settings)
        buildKeybindCard(ctx.TabData.Settings)
        buildProfileCard(ctx.TabData.Settings)
    end

    -- ========================================================================
    -- BLOCK 9: APIS (App.HUD, App.Hub), BUS SUBSCRIPTIONS & FINALIZATION
    -- ========================================================================
    do
        local LEVEL_COLORS = {
            info = Palette.NeonBlue,
            combo = Palette.StreakGold,
            warn = Palette.Amber,
            danger = Palette.RageCrimson,
            error = Palette.RedAlert,
            success = Palette.Emerald,
        }

        local function setComboVisible(on)
            local show = on ~= false
            if ctx.TopLeftCluster then
                ctx.TopLeftCluster.Visible = show
            end
            if ctx.PinnedRow then
                ctx.PinnedRow.Visible = show and (State.ShowPinnedPills == true)
            end
        end

        local function flashCombo()
            if not ctx.ComboBtn then
                return
            end
            local sc = App.Anim.EnsureScale(ctx.ComboBtn)
            sc.Scale = 1.13
            App.Anim.Play(sc, "ComboPunch", App.Anim.Spring, { Scale = 1.0 })
            ctx.ComboBtn.BackgroundColor3 = Palette.StreakGold
            ctx.ComboBtn.BackgroundTransparency = 0.55
            ctx.ComboStroke.Color = Palette.StreakGold
            App.Anim.Play(ctx.ComboBtn, "ComboBgFade", App.Anim.SpringSoft, {
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.14,
            })
            App.Anim.Play(ctx.ComboStroke, "ComboStrFade", App.Anim.SpringSoft, {
                Color = State.ComboLoop and Palette.StreakGold or Palette.Border,
            })
        end

        local function logCmd(msg, color)
            if not ctx.OutScroll then
                return
            end
            while #ctx.CmdLogEntries >= 80 do
                local oldest = table.remove(ctx.CmdLogEntries, 1)
                if oldest and oldest.Parent then
                    oldest:Destroy()
                end
            end
            local orderIdx = (#ctx.CmdLogEntries > 0) and (ctx.CmdLogEntries[#ctx.CmdLogEntries].LayoutOrder + 1) or 1
            local col = (typeof(color) == "Color3") and color or Palette.TextPrimary
            local line = UI.Create("TextLabel", {
                LayoutOrder = orderIdx,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Font = Enum.Font.RobotoMono,
                Text = tostring(msg or ""),
                TextSize = 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = col,
                Active = false,
                ZIndex = 29,
                Parent = ctx.OutScroll,
            })
            table.insert(ctx.CmdLogEntries, line)
            pcall(function()
                ctx.OutScroll.CanvasPosition = Vector2.new(0, 999999)
            end)
        end

        local function clearCmdLog()
            for _, lbl in ipairs(ctx.CmdLogEntries) do
                if lbl and lbl.Parent then
                    lbl:Destroy()
                end
            end
            clearTbl(ctx.CmdLogEntries)
        end

        local function pushAlert(subject, message, levelOrColor)
            if State.ShowAlerts == false or not ctx.AlertHost then
                return
            end
            local col = LEVEL_COLORS.info
            if typeof(levelOrColor) == "Color3" then
                col = levelOrColor
            elseif type(levelOrColor) == "string" and LEVEL_COLORS[string.lower(levelOrColor)] then
                col = LEVEL_COLORS[string.lower(levelOrColor)]
            end

            while #ctx.AlertItems >= 2 do
                local old = table.remove(ctx.AlertItems, 1)
                if old and old.Parent then
                    old:Destroy()
                end
            end

            local vp = getViewport()
            local maxW = clampNum(math.floor(vp.X * 0.44), 190, 380)
            local subjTxt = App.EscapeRichText(tostring(subject or "KX"))
            local bodyTxt = App.EscapeRichText(tostring(message or ""))
            local hexCol = App.ColorToHex(col)

            local pill = UI.Create("Frame", {
                LayoutOrder = math.floor(os.clock() * 1000) % 1000000,
                Size = UDim2.fromOffset(0, 30),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.08,
                ClipsDescendants = true,
                ZIndex = 25,
                Parent = ctx.AlertHost,
            })
            UI.Corner(pill, 15)
            UI.Stroke(pill, col, 1.3, 0.15)
            UI.Pad(pill, 10, 12, 0, 0)
            local pScale = App.Anim.EnsureScale(pill)
            pScale.Scale = 0.88
            App.Anim.Play(pScale, "AlertIn", App.Anim.Spring, { Scale = 1.0 })

            UI.Create("TextLabel", {
                Size = UDim2.fromOffset(0, 30),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                RichText = true,
                Text = '<font color="' .. hexCol .. '"><b>[' .. subjTxt .. ']</b></font> ' .. bodyTxt,
                TextSize = 11,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextColor3 = Palette.TextPrimary,
                Active = false,
                ZIndex = 26,
                Parent = pill,
            })
            UI.Create("UISizeConstraint", {
                MaxSize = Vector2.new(maxW, 32),
                Parent = pill,
            })

            if ctx.AlertHost then
                ctx.AlertHost.Visible = true
            end
            table.insert(ctx.AlertItems, pill)
            local hold = tonumber(State.AlertDuration) or 3.8
            App.Anim.Delay(pill, "AlertLife", hold, function()
                for idx, item in ipairs(ctx.AlertItems) do
                    if item == pill then
                        table.remove(ctx.AlertItems, idx)
                        break
                    end
                end
                App.Anim.Play(pScale, "AlertOut", App.Anim.Exit, { Scale = 0.84 }, function()
                    if pill and pill.Parent then
                        pill:Destroy()
                    end
                    if ctx.AlertHost and #ctx.AlertItems == 0 then
                        ctx.AlertHost.Visible = false
                    end
                end)
                App.Anim.Play(pill, "AlertBgOut", App.Anim.Exit, { BackgroundTransparency = 1 })
            end)
        end

        local function pushKillfeed(entryOrKiller, victimArg, weaponArg, headArg)
            if State.ShowKillfeed == false or not ctx.KillfeedHost then
                return
            end
            local entry
            if type(entryOrKiller) == "table" then
                entry = entryOrKiller
            else
                entry = {
                    killer = entryOrKiller,
                    victim = victimArg,
                    weapon = weaponArg,
                    headshot = headArg,
                }
            end

            local maxRows = isCompactLayout() and 3 or 5
            while #ctx.KillfeedItems >= maxRows do
                local old = table.remove(ctx.KillfeedItems, 1)
                if old and old.Parent then
                    old:Destroy()
                end
            end

            local killerName = App.EscapeRichText(tostring(entry.killerDisplay or entry.killer or entry.killerName or "?"))
            local victimName = App.EscapeRichText(tostring(entry.victimDisplay or entry.victim or entry.victimName or "?"))
            local weap = App.EscapeRichText(tostring(entry.weapon or "Weapon"))
            local isHead = entry.headshot == true
            local accent = (typeof(entry.teamColor) == "Color3" and entry.teamColor)
                or (typeof(entry.killerColor) == "Color3" and entry.killerColor)
                or (isHead and Palette.StreakGold or Palette.NeonCyan)
            local vAccent = (typeof(entry.victimColor) == "Color3" and entry.victimColor) or Palette.TextSecondary
            local kHex = App.ColorToHex(accent)
            local vHex = App.ColorToHex(vAccent)
            local badgeTxt = ""
            if isHead then
                badgeTxt = badgeTxt .. '<font color="#FACC15"><b> [HS]</b></font>'
            end
            if entry.tag and entry.tag ~= "" then
                badgeTxt = badgeTxt .. '<font color="#FACC15"><b> [' .. App.EscapeRichText(tostring(entry.tag)) .. ']</b></font>'
            end
            if entry.streakLabel and entry.streakLabel ~= "" then
                badgeTxt = badgeTxt .. '<font color="#FF6B4A"><b> ' .. App.EscapeRichText(tostring(entry.streakLabel)) .. '</b></font>'
            end
            local tagTxt = badgeTxt
            local distTxt = entry.dist and (" (" .. tostring(math.floor(entry.dist)) .. "m)") or ""

            local row = UI.Create("Frame", {
                LayoutOrder = math.floor(os.clock() * 1000) % 1000000,
                Size = UDim2.fromOffset(0, 22),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Palette.BgDark,
                BackgroundTransparency = 0.16,
                ClipsDescendants = true,
                Active = false,
                ZIndex = 15,
                Parent = ctx.KillfeedHost,
            })
            UI.Corner(row, 8)
            UI.Stroke(row, isHead and Palette.StreakGold or Palette.Border, 1, 0.28)
            UI.Pad(row, 8, 9, 0, 0)
            local rScale = App.Anim.EnsureScale(row)
            rScale.Scale = 0.85
            App.Anim.Play(rScale, "KfIn", App.Anim.Spring, { Scale = 1.0 })

            UI.Create("TextLabel", {
                Size = UDim2.fromOffset(0, 22),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                RichText = true,
                Text = '<font color="' .. kHex .. '"><b>' .. killerName .. '</b></font> [' .. weap .. ']' .. tagTxt .. ' -> <font color="' .. vHex .. '">' .. victimName .. '</font>' .. distTxt,
                TextSize = 10,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextColor3 = Palette.TextMuted,
                Active = false,
                ZIndex = 16,
                Parent = row,
            })
            UI.Create("UISizeConstraint", {
                MaxSize = Vector2.new(isCompactLayout() and 152 or 310, 24),
                Parent = row,
            })

            ctx.KillfeedHost.Visible = true
            table.insert(ctx.KillfeedItems, row)
            App.Anim.Delay(row, "KfFade", 4.2, function()
                for idx, item in ipairs(ctx.KillfeedItems) do
                    if item == row then
                        table.remove(ctx.KillfeedItems, idx)
                        break
                    end
                end
                App.Anim.Play(rScale, "KfOut", App.Anim.Exit, { Scale = 0.82 }, function()
                    if row and row.Parent then
                        row:Destroy()
                    end
                    if ctx.KillfeedHost and #ctx.KillfeedItems == 0 then
                        ctx.KillfeedHost.Visible = false
                    end
                end)
            end)
        end

        local function updateShieldBadgeVisual(force)
            if not ctx.ShieldBadge then
                return
            end
            local shieldOn = State.ShieldEnabled == true
            local ghostOn = State.FEInvisible == true
            local shouldShow = (State.ShowShieldBadge ~= false) and (shieldOn or ghostOn)
            ctx.ShieldBadge.Visible = shouldShow
            if not shouldShow then
                ctx.AnimatingShieldHP = false
                return
            end

            local hp = shieldOn and 180 or 0
            local hasEquipped = shieldOn
            local hasOwned = shieldOn
            if App.Shield and App.Shield.GetStatus then
                local ok, eq, ow, curHp = pcall(App.Shield.GetStatus)
                if ok then
                    hasEquipped = eq and true or false
                    hasOwned = ow and true or false
                    hp = tonumber(curHp) or hp
                end
            end

            local targetHP = math.floor(hp + 0.5)
            local displayHP = math.floor((ctx.DisplayShieldHP or targetHP) + 0.5)
            if force or math.abs(targetHP - (ctx.DisplayShieldHP or 0)) < 1 then
                ctx.AnimatingShieldHP = false
                ctx.TargetShieldHP = targetHP
                ctx.DisplayShieldHP = targetHP
                displayHP = targetHP
            elseif ctx.TargetShieldHP ~= targetHP then
                ctx.TargetShieldHP = targetHP
                ctx.AnimatingShieldHP = true
                local fromHP = ctx.DisplayShieldHP or targetHP
                App.Anim.Number(ctx.ShieldBadge, "ShieldHPNum", fromHP, targetHP, 0.22, function(v)
                    ctx.DisplayShieldHP = v
                    if ctx.ShieldHPLabel and shieldOn then
                        local num = tostring(math.floor(v + 0.5))
                        local txt = ghostOn and ("GHOST " .. num) or (hasOwned and num or "NO SHIELD")
                        ctx.ShieldHPLabel.Text = txt
                        ctx.LastShieldText = txt
                    end
                end, function()
                    ctx.AnimatingShieldHP = false
                    ctx.DisplayShieldHP = targetHP
                    if ctx.ShieldHPLabel and shieldOn then
                        local num = tostring(math.floor(targetHP + 0.5))
                        local txt = ghostOn and ("GHOST " .. num) or (hasOwned and num or "NO SHIELD")
                        ctx.ShieldHPLabel.Text = txt
                        ctx.LastShieldText = txt
                    end
                end)
            end

            local col = Palette.NeonBlue
            local labelText
            local frac = 0
            if ghostOn and not shieldOn then
                col = Palette.NeonCyan
                labelText = "GHOST ON"
                frac = 1
            elseif shieldOn then
                frac = hasOwned and clampNum(hp / 180, 0, 1) or 0
                if frac < 0.28 then
                    col = Palette.RageCrimson
                elseif frac < 0.60 then
                    col = Palette.Amber
                else
                    col = ghostOn and Palette.NeonCyan or (hasEquipped and Palette.NeonBlue or Palette.TextMuted)
                end
                if not hasOwned then
                    labelText = ghostOn and "GHOST" or "NO SHIELD"
                else
                    labelText = ghostOn and ("GHOST " .. tostring(displayHP)) or tostring(displayHP)
                end
            else
                col = Palette.TextMuted
                labelText = "OFF"
                frac = 0
            end

            if (not ctx.AnimatingShieldHP or not shieldOn) and (labelText ~= ctx.LastShieldText or force) then
                ctx.LastShieldText = labelText
                ctx.ShieldHPLabel.Text = labelText
            end
            if col ~= ctx.LastShieldColor or force then
                ctx.LastShieldColor = col
                ctx.ShieldBadgeStroke.Color = col
                ctx.ShieldVecBox.BackgroundColor3 = col
                ctx.ShieldVecStroke.Color = col
                if ctx.ShieldMeterFill then
                    ctx.ShieldMeterFill.BackgroundColor3 = col
                end
            end
            if ctx.ShieldMeterFill and (frac ~= ctx.LastShieldMeterFrac or force) then
                ctx.LastShieldMeterFrac = frac
                if force then
                    ctx.ShieldMeterFill.Size = UDim2.fromScale(frac, 1)
                else
                    App.Anim.Play(ctx.ShieldMeterFill, "ShieldMeter", App.Anim.Snappy, { Size = UDim2.fromScale(frac, 1) })
                end
            end
        end

        local function updateQuickDockVisuals()
            local sq = ctx.RightBtns.shield
            if sq then
                local on = State.ShieldEnabled == true
                local c = on and Palette.NeonBlue or Palette.TextMuted
                sq.stroke.Color = on and Palette.NeonBlue or Palette.Border
                sq.stroke.Transparency = on and 0.1 or 0.28
                sq.label.TextColor3 = on and Palette.NeonCyan or Palette.TextMuted
                if sq.parts.stroke then
                    sq.parts.stroke.Color = c
                end
                if sq.parts.fill then
                    sq.parts.fill.BackgroundColor3 = c
                end
            end
            local gq = ctx.RightBtns.ghost
            if gq then
                local on = State.FEInvisible == true
                local c = on and Palette.NeonCyan or Palette.TextMuted
                gq.stroke.Color = on and Palette.NeonCyan or Palette.Border
                gq.stroke.Transparency = on and 0.1 or 0.28
                gq.label.TextColor3 = on and Palette.NeonCyan or Palette.TextMuted
                if gq.parts.stroke then
                    gq.parts.stroke.Color = c
                end
                if gq.parts.fill then
                    gq.parts.fill.BackgroundColor3 = c
                end
            end
            if ctx.CrestStroke then
                ctx.CrestStroke.Color = State.HubVisible and Palette.NeonCyan or Palette.NeonBlue
            end
            if ctx.ComboStroke and ctx.ComboDot then
                local loopOn = State.ComboLoop == true
                ctx.ComboDot.BackgroundColor3 = loopOn and Palette.StreakGold or Palette.NeonCyan
                ctx.ComboStroke.Color = loopOn and Palette.StreakGold or Palette.Border
            end
            if ctx.FlyPadStack then
                ctx.FlyPadStack.Visible = (State.Fly == true or State.VehicleFly == true)
            end
            if ctx.FlyGrip then
                ctx.FlyGrip.Visible = not (State.LockHUDLayout == true)
            end
        end

        local function clearHUD()
            for _, pill in ipairs(ctx.AlertItems) do
                if pill and pill.Parent then
                    pill:Destroy()
                end
            end
            clearTbl(ctx.AlertItems)
            for _, row in ipairs(ctx.KillfeedItems) do
                if row and row.Parent then
                    row:Destroy()
                end
            end
            clearTbl(ctx.KillfeedItems)
            if ctx.HideAutocomplete then
                ctx.HideAutocomplete()
            end
            if ctx.ToggleCmdDrawer then
                ctx.ToggleCmdDrawer(false)
            end
            if ctx.StopKeybindListen then
                ctx.StopKeybindListen()
            end
            if App.MobileFlyInput then
                App.MobileFlyInput.Up = 0
                App.MobileFlyInput.Down = 0
            end
            if App.World and App.World.MobileFlyInput then
                App.World.MobileFlyInput.Up = 0
                App.World.MobileFlyInput.Down = 0
            end
        end

        local function syncPositionsToViewport()
            local compact = isCompactLayout()
            if ctx.SetBarExpanded and not (ctx.KXInput and ctx.KXInput:IsFocused()) then
                ctx.SetBarExpanded(not compact, true)
            end
            if ctx.UpdateQuickDockLayout then
                ctx.UpdateQuickDockLayout()
            end
            if ctx.SyncKillfeedAnchor then
                ctx.SyncKillfeedAnchor()
            end
            for _, entry in pairs(ctx.Draggables) do
                if entry and entry.apply then
                    entry.apply()
                end
            end
            if ctx.AlertHost then
                ctx.AlertHost.Position = UDim2.new(0.5, 0, 0, getIYPillTopY() + 28)
                ctx.AlertHost.Size = UDim2.fromOffset(compact and 236 or 320, 0)
            end
            if ctx.PositionKXPopups then
                ctx.PositionKXPopups()
            end
            if ctx.LayoutHubWindow then
                ctx.LayoutHubWindow()
            end
        end

        local function resetLayoutPositions()
            App.SetState("HUDPositions", {})
            syncPositionsToViewport()
            pushAlert("HUD Layout", "Reset all HUD positions", "info")
        end

        local function focusCmdBar()
            if ctx.KXBar then
                ctx.KXBar.Visible = true
            end
            if ctx.SetBarExpanded then
                ctx.SetBarExpanded(true, false)
            end
            if ctx.KXInput then
                ctx.KXInput:CaptureFocus()
            end
        end

        local function setHubVisible(on)
            local show = on and true or false
            ctx.HubOpen = show
            if not show and ctx.StopKeybindListen then
                ctx.StopKeybindListen()
            end
            if State.HubVisible ~= show then
                App.SetState("HubVisible", show, true)
            end
            if ctx.HubBackdrop then
                if show then
                    ctx.HubBackdrop.Visible = true
                    App.Anim.Play(ctx.HubBackdrop, "BgDim", App.Anim.SpringSoft, { BackgroundTransparency = 0.48 })
                else
                    App.Anim.Play(ctx.HubBackdrop, "BgDim", App.Anim.Exit, { BackgroundTransparency = 1 }, function()
                        if not State.HubVisible and ctx.HubBackdrop then
                            ctx.HubBackdrop.Visible = false
                        end
                    end)
                end
            end
            if ctx.HubWindow and ctx.HubScale then
                if show then
                    if ctx.LayoutHubWindow then
                        ctx.LayoutHubWindow()
                    end
                    ctx.HubWindow.Visible = true
                    ctx.HubScale.Scale = 0.92
                    App.Anim.Play(ctx.HubScale, "HubPop", App.Anim.Spring, { Scale = 1.0 })
                else
                    App.Anim.Play(ctx.HubScale, "HubPop", App.Anim.Exit, { Scale = 0.92 }, function()
                        if not State.HubVisible and ctx.HubWindow then
                            ctx.HubWindow.Visible = false
                        end
                    end)
                end
            end
            updateQuickDockVisuals()
        end

        local function syncHub(instant, onlyKey)
            if onlyKey then
                local fns = ctx.SyncFns[onlyKey]
                if fns then
                    for _, fn in ipairs(fns) do
                        fn(instant)
                    end
                end
                if onlyKey == "Keybinds" and State.Keybinds then
                    for act, k in pairs(State.Keybinds) do
                        local r = ctx.KeybindRows[act]
                        if r and r.btn then
                            r.btn.Text = tostring(k)
                        end
                    end
                end
                return
            end
            for _, fns in pairs(ctx.SyncFns) do
                for _, fn in ipairs(fns) do
                    fn(instant)
                end
            end
            if State.Keybinds then
                for act, k in pairs(State.Keybinds) do
                    local r = ctx.KeybindRows[act]
                    if r and r.btn then
                        r.btn.Text = tostring(k)
                    end
                end
            end
            if ctx.SyncPinnedChips then
                ctx.SyncPinnedChips()
            end
        end

        local function notifyKeybind(actionName, keyName)
            local r = ctx.KeybindRows[actionName]
            if r and r.btn then
                r.btn.Text = tostring(keyName or "None")
                r.stroke.Color = Palette.Emerald
                App.Anim.Delay(r.btn, "KbFlash", 0.35, function()
                    r.stroke.Color = Palette.Border
                end)
            end
        end

        ctx.FlashCombo = flashCombo
        ctx.LogCmd = logCmd

        App.HUD = {
            SetComboVisible = setComboVisible,
            FlashCombo = flashCombo,
            LogCmd = logCmd,
            ClearCmdLog = clearCmdLog,
            ClearHUD = clearHUD,
            PushAlert = pushAlert,
            PushKillfeed = pushKillfeed,
            UpdateBadges = function(force)
                updateShieldBadgeVisual(force)
                updateQuickDockVisuals()
                if ctx.SyncPinnedChips then
                    ctx.SyncPinnedChips()
                end
            end,
            ResetLayoutPositions = resetLayoutPositions,
            SyncPositionsToViewport = syncPositionsToViewport,
            RefreshCommandBrowser = function()
                if ctx.RefreshCommandBrowser then
                    ctx.RefreshCommandBrowser()
                end
            end,
            FocusCmdBar = focusCmdBar,
        }

        App.Hub = {
            _IsRebinding = false,
            IsRebinding = function()
                return ctx.HubRebinding == true or (App.Hub and App.Hub._IsRebinding == true)
            end,
            SetVisible = setHubVisible,
            SelectTab = function(tabName)
                if ctx.SelectHubTab then
                    ctx.SelectHubTab(tabName, false)
                end
            end,
            SyncHub = syncHub,
            NotifyKeybind = notifyKeybind,
            RefreshProfiles = function()
                if ctx.RefreshProfilesFn then
                    ctx.RefreshProfilesFn()
                end
            end,
        }

        Bus.On("StateChanged", function(key, val)
            if key == "ShowComboButton" then
                setComboVisible(val)
            elseif key == "ShowPinnedPills" or key == "PinnedPills" then
                if ctx.RebuildPinnedPills then
                    ctx.RebuildPinnedPills()
                end
            elseif key == "ShowKXBar" and ctx.KXBar then
                ctx.KXBar.Visible = (val ~= false)
            elseif key == "ShowIYPill" and ctx.IYPill then
                ctx.IYPill.Visible = (val == true)
            elseif key == "ShowRightActions" and ctx.RightQuickActions then
                ctx.RightQuickActions.Visible = (val ~= false)
            elseif key == "ShowShieldBadge" then
                updateShieldBadgeVisual(true)
            elseif key == "ShowKillfeed" and ctx.KillfeedHost then
                ctx.KillfeedHost.Visible = (val ~= false) and (#ctx.KillfeedItems > 0)
            elseif key == "KillfeedPosition" and ctx.SyncKillfeedAnchor then
                ctx.SyncKillfeedAnchor()
            elseif key == "HubVisible" then
                setHubVisible(val)
            elseif key == "ActiveTab" and ctx.SelectHubTab then
                if ctx.CurrentTab ~= val then
                    ctx.SelectHubTab(val, false)
                end
            end
            syncHub(not (ctx.HubOpen and key ~= nil), key)
            updateShieldBadgeVisual(false)
            updateQuickDockVisuals()
            if ctx.SyncPinnedChips then
                ctx.SyncPinnedChips()
            end
        end)

        Bus.On("Alert", function(subject, message, levelOrColor)
            pushAlert(subject, message, levelOrColor)
        end)

        Bus.On("KillfeedRow", function(...)
            pushKillfeed(...)
        end)

        Bus.On("Killfeed", function(...)
            pushKillfeed(...)
        end)

        Bus.On("HitConfirm", function(arg1, arg2, arg3)
            local isHead = false
            local isKill = false
            if type(arg1) == "table" then
                isHead = arg1.headshot == true
                isKill = arg1.kill == true
            else
                isHead = arg1 == true
                isKill = arg2 == true
            end
            if ctx.TriggerHitmarker then
                ctx.TriggerHitmarker(isHead, isKill)
            end
        end)

        Bus.On("ShieldHit", function()
            if State.ShieldHitVFX ~= false and ctx.FlashShieldHit then
                ctx.FlashShieldHit()
            end
            updateShieldBadgeVisual(false)
        end)

        Bus.On("CmdLog", function(msg, col)
            logCmd(msg, col)
        end)

        Bus.On("CommandOutput", function(msg, col)
            logCmd(msg, col)
        end)

        Bus.On("LayoutChanged", function()
            syncPositionsToViewport()
        end)

        Bus.On("Cleanup", function()
            clearHUD()
        end)

        Janitor.AddCleanup(clearHUD)

        local badgeAccum = 0
        local lastPrio = (Enum and Enum.RenderPriority and Enum.RenderPriority.Last and tonumber(Enum.RenderPriority.Last.Value)) or 2000
        Janitor.BindRender("KX_HUDFrame", lastPrio, function(dt)
            if ctx.UpdateReticleFrame then
                ctx.UpdateReticleFrame()
            end
            badgeAccum = badgeAccum + (dt or 0.016)
            if badgeAccum >= 0.14 then
                badgeAccum = 0
                updateShieldBadgeVisual(false)
                updateQuickDockVisuals()
            end
        end)

        if ctx.SelectHubTab then
            ctx.SelectHubTab(State.ActiveTab or "Shield", true)
        end
        syncPositionsToViewport()
        App.HUD.UpdateBadges(true)
        App.HUD.RefreshCommandBrowser()
        App.Hub.RefreshProfiles()
        syncHub(true)
        if State.HubVisible == true then
            setHubVisible(true)
        end
    end
end


-- ============================================================================
-- // MODULE 5: DECLARATIVE ADMIN COMMAND ENGINE (85+ CMDS), KEYBINDS, RESPAWN & CLEANUP
-- ============================================================================

-- ============================================================================
--  PRISON LIFE 2026 — KX EDITION V3
--  Module 5: Declarative Command Engine (App.Admin), Dynamic Keybinds,
--            Anti-AFK, Character Respawn Lifecycle, Startup & Cleanup
-- ============================================================================
--  Strict Contract:
--   * Zero redeclarations of the 8 top-level locals:
--     GEN_ENV, Services, App, State, Palette, Janitor, Bus, UI
--   * Zero extra file-scope locals (all code wrapped in do ... end blocks)
--   * LuaJIT 2.1 + Luau compatible (explicit pairs/ipairs, no continue, no +=)
--   * Every proto < 95 stackslots and < 35 upvalues
-- ============================================================================

do
    local Admin = App.Admin
    if type(Admin) ~= "table" then
        Admin = {}
        App.Admin = Admin
    end

    Admin.Registry = Admin.Registry or {}
    Admin.RegistryMap = Admin.RegistryMap or {}
    Admin.Aliases = Admin.Aliases or {}

    local function trimStr(s)
        if type(App.Trim) == "function" then
            return App.Trim(s)
        end
        return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    end

    local function clampNum(val, minVal, maxVal)
        local n = tonumber(val)
        if not n then
            return minVal
        end
        if minVal ~= nil and n < minVal then
            return minVal
        end
        if maxVal ~= nil and n > maxVal then
            return maxVal
        end
        return n
    end

    local function getLP()
        return App.LocalPlayer or (Services.Players and Services.Players.LocalPlayer)
    end

    local function getChar(plr)
        local p = plr or getLP()
        if type(App.GetChar) == "function" then
            return App.GetChar(p)
        end
        return p and p.Character or nil
    end

    local function getRoot(char)
        if type(App.GetRoot) == "function" then
            return App.GetRoot(char)
        end
        return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart) or nil
    end

    local function getHum(char)
        if type(App.GetHum) == "function" then
            return App.GetHum(char)
        end
        return char and char:FindFirstChildOfClass("Humanoid") or nil
    end

    local function emitOutput(ok, msg)
        local text = tostring(msg or "")
        local didEmit = false
        if text ~= "" then
            local color = ok and (Palette.Emerald or Palette.NeonBlue) or Palette.RedAlert
            Bus.Emit("CommandOutput", text, color)
            didEmit = true
            if not App.MainGui and App.HUD and type(App.HUD.LogCmd) == "function" then
                pcall(App.HUD.LogCmd, text, color)
            end
        end
        return { ok = (ok == true), msg = text, emitted = didEmit }
    end

    local function emitAlert(subj, msg, level)
        Bus.Emit("Alert", subj, msg, level)
        if not App.MainGui and App.HUD and type(App.HUD.PushAlert) == "function" then
            pcall(App.HUD.PushAlert, subj, msg, level)
        end
    end

    local function syncUI(instant)
        if App.HUD and type(App.HUD.UpdateBadges) == "function" then
            pcall(App.HUD.UpdateBadges, true)
        end
        if App.Hub and type(App.Hub.SyncHub) == "function" then
            pcall(App.Hub.SyncHub, instant == true)
        end
    end

    local DEFAULT_TELEPORTS = {
        yard = CFrame.new(780, 98, 2470),
        nexus = CFrame.new(875, 100, 2390),
        cafeteria = CFrame.new(905, 100, 2290),
        cells = CFrame.new(915, 100, 2445),
        armory = CFrame.new(830, 100, 2235),
        crimbase = CFrame.new(-943, 94, 2056),
        roof = CFrame.new(825, 119, 2350),
        tower = CFrame.new(822, 130, 2588),
        gate = CFrame.new(504, 103, 2250),
        sewer = CFrame.new(917, 79, 2110),
        hideout = CFrame.new(-97, 72, 1910),
        cars = CFrame.new(-525, 54, 1775),
        store = CFrame.new(415, 55, 1735),
        gas = CFrame.new(-515, 54, 1665),
        neutral = CFrame.new(879, 28, 2349),
    }

    local function getTeleportLocations()
        if App.World and type(App.World.TeleportLocations) == "table" then
            return App.World.TeleportLocations
        end
        return DEFAULT_TELEPORTS
    end

    local CANONICAL_GUNS = {
        "Remington 870",
        "AK-47",
        "M4A1",
        "M9",
        "MP5",
        "FAL",
        "Riot Shield",
        "C4 Explosive",
        "Taser",
    }

    local GUN_ALIASES = {
        remington = "Remington 870",
        rem = "Remington 870",
        rem870 = "Remington 870",
        ["870"] = "Remington 870",
        shotgun = "Remington 870",
        ak = "AK-47",
        ak47 = "AK-47",
        ["ak-47"] = "AK-47",
        m4 = "M4A1",
        m4a1 = "M4A1",
        rifle = "M4A1",
        m9 = "M9",
        pistol = "M9",
        mp5 = "MP5",
        smg = "MP5",
        fal = "FAL",
        riot = "Riot Shield",
        riotshield = "Riot Shield",
        shield = "Riot Shield",
        c4 = "C4 Explosive",
        c4explosive = "C4 Explosive",
        explosive = "C4 Explosive",
        taser = "Taser",
        tazer = "Taser",
    }

    local function resolveGunName(raw)
        local q = trimStr(raw)
        if q == "" then
            return nil
        end
        local low = string.lower(q)
        local compact = (low:gsub("[%s%-_]+", ""))
        if GUN_ALIASES[low] then
            return GUN_ALIASES[low]
        end
        if GUN_ALIASES[compact] then
            return GUN_ALIASES[compact]
        end
        for i = 1, #CANONICAL_GUNS do
            local name = CANONICAL_GUNS[i]
            if string.lower(name) == low or string.sub(string.lower(name), 1, #low) == low then
                return name
            end
        end
        return nil
    end

    local FALLBACK_TEAM_MAP = {
        guards = "Guards", guard = "Guards", cops = "Guards", cop = "Guards", police = "Guards",
        inmates = "Inmates", inmate = "Inmates", prisoners = "Inmates", prisoner = "Inmates",
        criminals = "Criminals", criminal = "Criminals", crims = "Criminals", crim = "Criminals",
        neutral = "Neutral", neutrals = "Neutral",
    }

    local function fallbackResolveTargets(query)
        local playersSvc = Services.Players
        if not playersSvc or type(playersSvc.GetPlayers) ~= "function" then
            return {}
        end
        local q = trimStr(query or "")
        if q == "" then
            return {}
        end
        local allPlayers = playersSvc:GetPlayers()
        local lp = getLP()
        local out = {}
        local seen = {}

        local function pushPlr(p)
            if p and not seen[p] then
                seen[p] = true
                table.insert(out, p)
            end
        end

        local function matchByTier(token, atUser)
            local lq = string.lower(token)
            local tiers = { {}, {}, {}, {}, {}, {} }
            for _, p in ipairs(allPlayers) do
                local nl = string.lower(tostring(p.Name or ""))
                local dl = string.lower(tostring(p.DisplayName or p.Name or ""))
                if nl == lq then
                    table.insert(tiers[1], p)
                elseif not atUser and dl == lq then
                    table.insert(tiers[2], p)
                elseif string.sub(nl, 1, #lq) == lq then
                    table.insert(tiers[3], p)
                elseif string.sub(dl, 1, #lq) == lq then
                    table.insert(tiers[4], p)
                elseif string.find(nl, lq, 1, true) then
                    table.insert(tiers[5], p)
                elseif string.find(dl, lq, 1, true) then
                    table.insert(tiers[6], p)
                end
            end
            for _, bucket in ipairs(tiers) do
                if #bucket > 0 then
                    table.sort(bucket, function(a, b)
                        return #tostring(a.Name or "") < #tostring(b.Name or "")
                    end)
                    return bucket
                end
            end
            return {}
        end

        for seg in string.gmatch(q, "[^,]+") do
            local rawTok = trimStr(seg)
            local tok = string.lower(rawTok)
            if tok == "all" then
                for _, p in ipairs(allPlayers) do
                    pushPlr(p)
                end
            elseif tok == "others" then
                for _, p in ipairs(allPlayers) do
                    if p ~= lp then
                        pushPlr(p)
                    end
                end
            elseif tok == "me" or tok == "self" then
                if lp then
                    pushPlr(lp)
                end
            elseif FALLBACK_TEAM_MAP[tok] then
                local wantTeam = FALLBACK_TEAM_MAP[tok]
                for _, p in ipairs(allPlayers) do
                    if p.Team and p.Team.Name == wantTeam then
                        pushPlr(p)
                    end
                end
            elseif tok == "nearest" or tok == "closest" then
                local lr = getRoot(getChar(lp))
                local bestP, bestD = nil, math.huge
                if lr then
                    for _, p in ipairs(allPlayers) do
                        if p ~= lp then
                            local tr = getRoot(getChar(p))
                            if tr then
                                local d = (tr.Position - lr.Position).Magnitude
                                if d < bestD then
                                    bestD = d
                                    bestP = p
                                end
                            end
                        end
                    end
                end
                if bestP then
                    pushPlr(bestP)
                end
            elseif tok == "random" then
                local pool = {}
                for _, p in ipairs(allPlayers) do
                    if p ~= lp then
                        table.insert(pool, p)
                    end
                end
                if #pool > 0 then
                    pushPlr(pool[math.random(1, #pool)])
                elseif lp then
                    pushPlr(lp)
                end
            elseif string.sub(tok, 1, 1) == "@" then
                local bare = string.sub(rawTok, 2)
                if bare ~= "" then
                    for _, p in ipairs(matchByTier(bare, true)) do
                        pushPlr(p)
                    end
                end
            elseif tok ~= "" then
                for _, p in ipairs(matchByTier(rawTok, false)) do
                    pushPlr(p)
                end
            end
        end
        return out
    end

    local function resolveTargets(queryOrArgs)
        local q
        if type(queryOrArgs) == "table" then
            q = trimStr(table.concat(queryOrArgs, " "))
        else
            q = trimStr(queryOrArgs or "")
        end
        if q == "" then
            return {}
        end

        local resolver = (App.Targets and type(App.Targets.Resolve) == "function") and App.Targets.Resolve or fallbackResolveTargets
        local list = resolver(q)
        if (type(list) ~= "table" or #list == 0) and type(queryOrArgs) == "table" and #queryOrArgs > 1 then
            local combined = {}
            local seen = {}
            for i = 1, #queryOrArgs do
                local sub = resolver(queryOrArgs[i])
                if type(sub) == "table" then
                    for _, p in ipairs(sub) do
                        if p and not seen[p] then
                            seen[p] = true
                            table.insert(combined, p)
                        end
                    end
                end
            end
            return combined
        end
        return type(list) == "table" and list or {}
    end

    -- Quote-aware tokenizer preserving '...' and "..." plus negative numeric args
    local function parseTokens(line)
        local str = tostring(line or "")
        local tokens = {}
        local buf = {}
        local inToken = false
        local quoteChar = nil
        local i = 1
        local len = #str

        while i <= len do
            local ch = string.sub(str, i, i)
            if quoteChar then
                if ch == "\\" and i < len then
                    local nxt = string.sub(str, i + 1, i + 1)
                    if nxt == quoteChar or nxt == "\\" then
                        table.insert(buf, nxt)
                        i = i + 2
                    else
                        table.insert(buf, ch)
                        i = i + 1
                    end
                elseif ch == quoteChar then
                    quoteChar = nil
                    i = i + 1
                else
                    table.insert(buf, ch)
                    i = i + 1
                end
            else
                if ch == '"' or ch == "'" then
                    quoteChar = ch
                    inToken = true
                    i = i + 1
                elseif string.match(ch, "%s") then
                    if inToken then
                        table.insert(tokens, table.concat(buf))
                        buf = {}
                        inToken = false
                    end
                    i = i + 1
                else
                    inToken = true
                    table.insert(buf, ch)
                    i = i + 1
                end
            end
        end

        if inToken or #buf > 0 then
            table.insert(tokens, table.concat(buf))
        end

        return tokens
    end

    -- Splits sequential commands on ';' ONLY outside single/double quotes
    local function splitSegments(line)
        local str = tostring(line or "")
        local out = {}
        local startIdx = 1
        local quoteChar = nil
        local i = 1
        local len = #str

        while i <= len do
            local ch = string.sub(str, i, i)
            if quoteChar then
                if ch == "\\" and i < len then
                    i = i + 2
                elseif ch == quoteChar then
                    quoteChar = nil
                    i = i + 1
                else
                    i = i + 1
                end
            else
                if ch == '"' or ch == "'" then
                    quoteChar = ch
                    i = i + 1
                elseif ch == ";" then
                    local seg = trimStr(string.sub(str, startIdx, i - 1))
                    if seg ~= "" then
                        table.insert(out, seg)
                    end
                    startIdx = i + 1
                    i = i + 1
                else
                    i = i + 1
                end
            end
        end

        local tail = trimStr(string.sub(str, startIdx, len))
        if tail ~= "" then
            table.insert(out, tail)
        end
        return out
    end

    Admin.ParseTokens = parseTokens
    Admin.SplitSegments = splitSegments

    local function bindAliases(aliasList, entry)
        local outAliases = {}
        local seen = {}
        for _, raw in ipairs(aliasList) do
            local low = string.lower(trimStr(raw))
            if low ~= "" and not seen[low] then
                seen[low] = true
                table.insert(outAliases, low)
                Admin.Aliases[low] = entry
            end
        end
        return outAliases
    end

    local function addRegistryEntry(entry)
        Admin.RegistryMap[entry.cmd] = entry
        for i = 1, #Admin.Registry do
            if Admin.Registry[i].cmd == entry.cmd then
                Admin.Registry[i] = entry
                return entry
            end
        end
        table.insert(Admin.Registry, entry)
        return entry
    end

    function Admin.RegisterToggle(aliases, stateKey, label, opts)
        local list = type(aliases) == "table" and aliases or { aliases }
        local options = type(opts) == "table" and opts or {}
        local offSet = {}
        local allAliases = {}

        for _, a in ipairs(list) do
            table.insert(allAliases, a)
        end
        if type(options.offAliases) == "table" then
            for _, oa in ipairs(options.offAliases) do
                local low = string.lower(trimStr(oa))
                if low ~= "" then
                    offSet[low] = true
                    table.insert(allAliases, low)
                end
            end
        end
        if options.autoUn ~= false then
            local primary = string.lower(trimStr(list[1] or ""))
            if primary ~= "" and string.sub(primary, 1, 2) ~= "un" then
                local autoOff = "un" .. primary
                if not offSet[autoOff] then
                    offSet[autoOff] = true
                    table.insert(allAliases, autoOff)
                end
            end
        end

        local primaryCmd = string.lower(trimStr(allAliases[1] or ""))
        local entry = {
            cmd = primaryCmd,
            aliases = {},
            usage = options.usage or (primaryCmd .. " [on|off]"),
            desc = options.desc or ("Toggle " .. tostring(label or stateKey)),
            cat = options.cat or "General",
            kind = "toggle",
            stateKey = stateKey,
            label = label or stateKey,
            argType = options.argType or "toggle",
        }

        entry.handler = function(args, ctx)
            local arg1 = args[1] and string.lower(trimStr(args[1])) or nil
            local targetVal
            local numVal = options.numericKey and tonumber(args[1]) or nil
            if offSet[ctx.cmd] then
                if arg1 == "on" or arg1 == "true" or arg1 == "1" then
                    targetVal = true
                elseif arg1 == nil or arg1 == "off" or arg1 == "false" or arg1 == "0" then
                    targetVal = false
                else
                    return { ok = false, msg = "Usage: " .. entry.usage }
                end
            elseif numVal ~= nil then
                local nMeta = App.StateMeta and App.StateMeta[options.numericKey] or nil
                local nMin = options.numericMin ~= nil and options.numericMin or (nMeta and nMeta.min) or 0
                local nMax = options.numericMax ~= nil and options.numericMax or (nMeta and nMeta.max) or 100
                local clamped = clampNum(numVal, nMin, nMax)
                App.SetState(options.numericKey, clamped)
                targetVal = true
            elseif arg1 == nil or arg1 == "toggle" then
                targetVal = not (State[stateKey] == true)
            elseif arg1 == "on" or arg1 == "true" or arg1 == "1" or arg1 == "enable" then
                targetVal = true
            elseif arg1 == "off" or arg1 == "false" or arg1 == "0" or arg1 == "disable" then
                targetVal = false
            else
                return { ok = false, msg = "Invalid argument '" .. tostring(args[1]) .. "'. Usage: " .. entry.usage }
            end

            if type(options.applyFn) == "function" then
                local customOk, customMsg = options.applyFn(targetVal, args, ctx)
                if customOk == false then
                    return { ok = false, msg = customMsg or (tostring(entry.label) .. " failed") }
                end
                syncUI()
                return {
                    ok = true,
                    msg = customMsg or (tostring(entry.label) .. ": " .. (targetVal and "ON" or "OFF")),
                }
            end

            App.SetState(stateKey, targetVal)
            if type(options.onChanged) == "function" then
                pcall(options.onChanged, targetVal, args, ctx)
            end
            syncUI()
            local suffix = (numVal ~= nil and targetVal) and (" (" .. tostring(State[options.numericKey]) .. ")") or ""
            return { ok = true, msg = tostring(entry.label) .. ": " .. (targetVal and "ON" or "OFF") .. suffix }
        end

        entry.aliases = bindAliases(allAliases, entry)
        return addRegistryEntry(entry)
    end

    function Admin.RegisterRange(aliases, stateKey, enableKey, metaKey, opts)
        local list = type(aliases) == "table" and aliases or { aliases }
        local options = type(opts) == "table" and opts or {}
        local mKey = metaKey or stateKey
        local meta = App.StateMeta and App.StateMeta[mKey] or nil
        local minV = options.min ~= nil and options.min or (meta and meta.min) or 0
        local maxV = options.max ~= nil and options.max or (meta and meta.max) or 100
        local primaryCmd = string.lower(trimStr(list[1] or ""))
        local label = options.label or (meta and meta.label) or stateKey

        local entry = {
            cmd = primaryCmd,
            aliases = {},
            usage = options.usage or (primaryCmd .. " <" .. tostring(minV) .. ".." .. tostring(maxV) .. ">"),
            desc = options.desc or ("Set " .. tostring(label) .. " (" .. tostring(minV) .. ".." .. tostring(maxV) .. ")"),
            cat = options.cat or (meta and meta.cat) or "General",
            kind = "range",
            stateKey = stateKey,
            enableKey = enableKey,
            min = minV,
            max = maxV,
        }

        entry.handler = function(args, ctx)
            if not args[1] or trimStr(args[1]) == "" then
                return {
                    ok = true,
                    msg = tostring(label) .. " = " .. tostring(State[stateKey]) .. " (range " .. tostring(minV) .. ".." .. tostring(maxV) .. ")",
                }
            end
            local rawNum = tonumber(args[1])
            if not rawNum then
                return {
                    ok = false,
                    msg = "Invalid number '" .. tostring(args[1]) .. "' for " .. primaryCmd .. " (" .. tostring(minV) .. ".." .. tostring(maxV) .. ")",
                }
            end
            local clamped = clampNum(rawNum, minV, maxV)
            if enableKey then
                App.SetState(enableKey, true)
            end
            App.SetState(stateKey, clamped)
            if type(options.onChanged) == "function" then
                pcall(options.onChanged, clamped, ctx)
            end
            syncUI()
            local note = (clamped ~= rawNum) and " (clamped)" or ""
            return { ok = true, msg = tostring(label) .. " = " .. tostring(clamped) .. note }
        end

        entry.aliases = bindAliases(list, entry)
        return addRegistryEntry(entry)
    end

    function Admin.RegisterTargetCmd(aliases, desc, fn, opts)
        local list = type(aliases) == "table" and aliases or { aliases }
        local options = type(opts) == "table" and opts or {}
        local primaryCmd = string.lower(trimStr(list[1] or ""))

        local entry = {
            cmd = primaryCmd,
            aliases = {},
            usage = options.usage or (primaryCmd .. (options.optionalTarget and " [target]" or " <target|all>")),
            desc = desc or primaryCmd,
            cat = options.cat or "Targets",
            kind = "target",
            argType = "target",
        }

        entry.handler = function(args, ctx)
            local queryStr = trimStr(table.concat(args, " "))
            if queryStr == "" and options.defaultQuery then
                queryStr = options.defaultQuery
            end
            if queryStr == "" then
                return { ok = false, msg = "Usage: " .. entry.usage }
            end
            local targets = resolveTargets(args[1] and args or queryStr)
            if #targets == 0 then
                return { ok = false, msg = "No matching target for '" .. queryStr .. "'" }
            end
            local okRes, msgRes, extra = fn(targets, args, ctx)
            if type(okRes) == "table" then
                return okRes
            end
            if okRes == nil then
                okRes = true
            end
            return {
                ok = (okRes == true),
                msg = tostring(msgRes or ""),
                async = (extra == true),
            }
        end

        entry.aliases = bindAliases(list, entry)
        return addRegistryEntry(entry)
    end

    function Admin.RegisterAction(aliases, desc, fn, opts)
        local list = type(aliases) == "table" and aliases or { aliases }
        local options = type(opts) == "table" and opts or {}
        local primaryCmd = string.lower(trimStr(list[1] or ""))

        local entry = {
            cmd = primaryCmd,
            aliases = {},
            usage = options.usage or primaryCmd,
            desc = desc or primaryCmd,
            cat = options.cat or "General",
            kind = "action",
            argType = options.argType,
            argChoices = options.argChoices,
        }

        entry.handler = function(args, ctx)
            local r1, r2, r3 = fn(args, ctx)
            if type(r1) == "table" then
                return r1
            end
            if r1 == nil then
                return { ok = true, msg = "" }
            end
            return { ok = (r1 == true), msg = tostring(r2 or ""), async = (r3 == true) }
        end

        entry.aliases = bindAliases(list, entry)
        return addRegistryEntry(entry)
    end

    local function runSingleSegment(seg, continueChain)
        local tokens = parseTokens(seg)
        if #tokens == 0 then
            return { ok = true, msg = "" }
        end

        -- Strip command prefixes ONLY from tokens[1], preserving negative numeric args in tokens[2..]
        local rawCmd = tostring(tokens[1] or "")
        local cleanCmd = string.lower((rawCmd:gsub("^[-;/!%.]+", "")))
        if cleanCmd == "" then
            return { ok = true, msg = "" }
        end

        local args = {}
        for i = 2, #tokens do
            table.insert(args, tokens[i])
        end

        local entry = Admin.Aliases[cleanCmd]
        if not entry then
            return emitOutput(false, "Unknown cmd '" .. cleanCmd .. "' (type 'cmds' for help)")
        end

        local ctx = {
            cmd = cleanCmd,
            rawCmd = rawCmd,
            entry = entry,
            rawSegment = seg,
            continueChain = continueChain,
        }

        local okCall, res = pcall(entry.handler, args, ctx)
        if not okCall then
            return emitOutput(false, "Cmd '" .. cleanCmd .. "' error: " .. tostring(res))
        end

        if type(res) ~= "table" then
            res = { ok = true, msg = tostring(res or "") }
        end
        local emitted = emitOutput(res.ok ~= false, res.msg)
        emitted.async = (res.async == true)
        return emitted
    end

    function Admin.ExecuteSingle(segment)
        return runSingleSegment(segment, nil)
    end

    function Admin.ExecuteLine(rawLine)
        local line = trimStr(rawLine or "")
        if line == "" then
            return { ok = true, msg = "", emitted = false, results = {} }
        end
        local segments = splitSegments(line)
        if #segments == 0 then
            return { ok = true, msg = "", emitted = false, results = {} }
        end

        local results = {}
        local lastRes = { ok = true, msg = "", emitted = false }
        local anyEmitted = false

        local function stepFrom(startIdx)
            local idx = startIdx
            while idx <= #segments do
                local yielded = false
                local curIdx = idx
                local res = runSingleSegment(segments[curIdx], function()
                    if not yielded then
                        return
                    end
                    stepFrom(curIdx + 1)
                end)
                table.insert(results, res)
                lastRes = res
                if res.emitted then
                    anyEmitted = true
                end
                if res.async then
                    yielded = true
                    return
                end
                idx = idx + 1
            end
            syncUI()
        end

        stepFrom(1)
        return {
            ok = lastRes.ok,
            msg = lastRes.msg,
            emitted = anyEmitted or (lastRes.emitted == true),
            results = results,
        }
    end

    function Admin.GetSuggestions(rawText)
        local raw = tostring(rawText or "")
        local segs = splitSegments(raw)
        local hasTrailingSemi = (string.match(raw, ";%s*$") ~= nil)
        local lastSeg = ""
        local beforePrefix = ""

        if hasTrailingSemi then
            beforePrefix = raw
            lastSeg = ""
        elseif #segs <= 1 then
            lastSeg = raw
        else
            lastSeg = segs[#segs]
            local lastPos = nil
            local searchFrom = 1
            while true do
                local p = string.find(raw, lastSeg, searchFrom, true)
                if not p then
                    break
                end
                lastPos = p
                searchFrom = p + 1
            end
            if lastPos and lastPos > 1 then
                beforePrefix = string.sub(raw, 1, lastPos - 1)
            end
        end

        local trimmedSeg = (lastSeg:gsub("^%s+", ""))
        local typedCmdPrefix = string.match(trimmedSeg, "^([-;/!%.]+)") or ""
        local body = string.sub(trimmedSeg, #typedCmdPrefix + 1)
        local hasSpace = (string.find(body, "%s", 1, false) ~= nil)
        local candidates = {}

        if not hasSpace then
            local q = string.lower(body)
            local seenCmd = {}
            for _, entry in ipairs(Admin.Registry) do
                if not seenCmd[entry.cmd] then
                    seenCmd[entry.cmd] = true
                    local matchedAlias = nil
                    local score = 0
                    if q == "" then
                        score = 1
                    elseif string.sub(entry.cmd, 1, #q) == q then
                        score = 3
                    else
                        for _, al in ipairs(entry.aliases) do
                            if string.sub(al, 1, #q) == q then
                                matchedAlias = al
                                score = 2
                                break
                            elseif string.find(entry.cmd, q, 1, true) or string.find(al, q, 1, true) then
                                matchedAlias = al
                                score = 1
                                break
                            end
                        end
                    end
                    if score > 0 then
                        local nameToUse = (score == 2 and matchedAlias) or entry.cmd
                        table.insert(candidates, {
                            score = score,
                            display = nameToUse .. " (" .. entry.usage .. ")",
                            insert = beforePrefix .. typedCmdPrefix .. nameToUse .. " ",
                            desc = "[" .. entry.cat .. "] " .. entry.desc,
                        })
                    end
                end
            end
            table.sort(candidates, function(a, b)
                if a.score ~= b.score then
                    return a.score > b.score
                end
                return a.display < b.display
            end)
        else
            local tokens = parseTokens(body)
            local cmdTok = string.lower(tokens[1] or "")
            local argPartial = ""
            if not string.match(body, "%s$") then
                argPartial = string.lower(tokens[#tokens] or "")
            end
            local entry = Admin.Aliases[cmdTok]
            local basePrefix = beforePrefix .. typedCmdPrefix .. cmdTok .. " "
            local argType = entry and entry.argType or nil

            local function pushChoice(label, insertVal, desc)
                local low = string.lower(label)
                if argPartial == "" or string.find(low, argPartial, 1, true) then
                    local score = (argPartial ~= "" and string.sub(low, 1, #argPartial) == argPartial) and 2 or 1
                    table.insert(candidates, {
                        score = score,
                        display = label,
                        insert = basePrefix .. insertVal,
                        desc = desc,
                    })
                end
            end

            if entry and type(entry.argChoices) == "table" then
                for _, ch in ipairs(entry.argChoices) do
                    local ins = string.find(ch, "%s") and ('"' .. ch .. '"') or ch
                    pushChoice(ch, ins, entry.desc)
                end
            elseif argType == "toggle" then
                pushChoice("on", "on", "Enable")
                pushChoice("off", "off", "Disable")
                pushChoice("toggle", "toggle", "Flip state")
            elseif argType == "target" or cmdTok == "goto" or cmdTok == "to" or cmdTok == "tp" then
                if cmdTok == "goto" or cmdTok == "to" or cmdTok == "tp" then
                    for locName in pairs(getTeleportLocations()) do
                        pushChoice(locName, locName, "Location")
                    end
                else
                    pushChoice("all", "all", "All players")
                    pushChoice("others", "others", "Other players")
                    pushChoice("inmates", "inmates", "Inmates team")
                    pushChoice("guards", "guards", "Guards team")
                    pushChoice("criminals", "criminals", "Criminals team")
                    pushChoice("nearest", "nearest", "Nearest player")
                end
                local playersSvc = Services.Players
                if playersSvc and type(playersSvc.GetPlayers) == "function" then
                    local lp = getLP()
                    for _, p in ipairs(playersSvc:GetPlayers()) do
                        if p ~= lp or argType == "target" then
                            local dn = (p.DisplayName and p.DisplayName ~= p.Name) and (" (" .. p.DisplayName .. ")") or ""
                            pushChoice(p.Name .. dn, p.Name, "Player")
                        end
                    end
                end
            elseif argType == "gun" then
                for _, gName in ipairs(CANONICAL_GUNS) do
                    local ins = string.find(gName, "%s") and ('"' .. gName .. '"') or gName
                    pushChoice(gName, ins, "Weapon")
                end
            elseif argType == "profile" and App.Persistence and type(App.Persistence.List) == "function" then
                local okL, plist = pcall(App.Persistence.List)
                if okL and type(plist) == "table" then
                    for _, pname in ipairs(plist) do
                        pushChoice(pname, pname, "Saved profile")
                    end
                end
            elseif argType == "cmd" then
                for _, e in ipairs(Admin.Registry) do
                    pushChoice(e.cmd, e.cmd, e.desc)
                end
            end

            table.sort(candidates, function(a, b)
                if a.score ~= b.score then
                    return a.score > b.score
                end
                return a.display < b.display
            end)
        end

        local trimmedOut = {}
        local limit = math.min(#candidates, 12)
        for i = 1, limit do
            local c = candidates[i]
            table.insert(trimmedOut, {
                display = c.display,
                insert = c.insert,
                desc = c.desc,
            })
        end
        return trimmedOut
    end

    local function runAsync(pendingMsg, continueChain, workFn)
        local finished = false
        local syncOk, syncMsg = true, ""
        local yieldedToChild = false

        Janitor.Spawn(function()
            local ok, msg = workFn()
            syncOk = (ok ~= false)
            syncMsg = tostring(msg or "")
            finished = true
            if yieldedToChild then
                if syncMsg ~= "" then
                    emitOutput(syncOk, syncMsg)
                end
                syncUI()
                if continueChain then
                    continueChain()
                end
            end
        end)

        if finished then
            return { ok = syncOk, msg = syncMsg, async = false }
        end
        yieldedToChild = true
        return { ok = true, msg = pendingMsg, async = true }
    end

    Admin._Helpers = {
        trimStr = trimStr,
        clampNum = clampNum,
        getLP = getLP,
        getChar = getChar,
        getRoot = getRoot,
        getHum = getHum,
        emitOutput = emitOutput,
        emitAlert = emitAlert,
        syncUI = syncUI,
        runAsync = runAsync,
        resolveTargets = resolveTargets,
        resolveGunName = resolveGunName,
        getTeleportLocations = getTeleportLocations,
        CANONICAL_GUNS = CANONICAL_GUNS,
    }
end

-- ============================================================================
--  COMMAND REGISTRATIONS: GUNS, COMBAT & WHITELISTS
-- ============================================================================
do
    local function registerGunsAndCombat(Admin, H)
        local KITS = {
            cop = { "Remington 870", "M4A1", "M9", "MP5", "Riot Shield" },
            guard = { "Remington 870", "M4A1", "M9", "MP5", "Riot Shield" },
            inmate = { "M9", "AK-47" },
            crim = { "AK-47", "FAL", "Remington 870", "M9" },
            criminal = { "AK-47", "FAL", "Remington 870", "M9" },
            combo = { "Remington 870", "AK-47", "M4A1", "M9", "MP5", "FAL", "Riot Shield" },
            all = { "Remington 870", "AK-47", "M4A1", "M9", "MP5", "FAL", "Riot Shield", "C4 Explosive" },
        }

        local NON_GUN_TOOLS = {
            Handcuffs = true,
            ["Riot Shield"] = true,
            ["C4 Explosive"] = true,
            Taser = true,
        }

        local function getBestWeapon()
            local char = H.getChar()
            if not char then
                return nil
            end
            local held = char:FindFirstChildOfClass("Tool")
            if held and not NON_GUN_TOOLS[held.Name]
                and (held:GetAttribute("FireRate") ~= nil or held:GetAttribute("AutoFire") ~= nil or held:GetAttribute("CurrentAmmo") ~= nil) then
                return held
            end
            if App.Weapons and type(App.Weapons.GetOwnedLoadedGuns) == "function" then
                local okG, guns = pcall(App.Weapons.GetOwnedLoadedGuns)
                if okG and type(guns) == "table" and guns[1] then
                    return guns[1]
                end
            end
            for _, gName in ipairs(H.CANONICAL_GUNS) do
                if not NON_GUN_TOOLS[gName] then
                    local tool = App.Weapons and App.Weapons.HasTool and App.Weapons.HasTool(gName)
                    if tool then
                        return tool
                    end
                end
            end
            return nil
        end

        local function mutateIdMap(stateKey, targets, isAdd, clearAll)
            local cur = type(State[stateKey]) == "table" and State[stateKey] or {}
            local copy = {}
            if not clearAll then
                for k, v in pairs(cur) do
                    copy[k] = v
                end
                for _, plr in ipairs(targets) do
                    copy[plr.UserId] = isAdd and true or nil
                end
            end
            App.SetState(stateKey, copy, false, true)
            H.syncUI()
        end

        Admin.RegisterAction({ "guns", "getguns", "grabguns", "allguns" }, "Grab selected or specified weapons", function(args, ctx)
            if not App.Weapons or type(App.Weapons.GrabWeapons) ~= "function" then
                return false, "Weapons subsystem not loaded"
            end
            local list = {}
            if #args > 0 then
                for i = 1, #args do
                    local g = H.resolveGunName(args[i])
                    if g then
                        table.insert(list, g)
                    end
                end
            else
                list = State.AutoGunsSelection or { "Remington 870", "AK-47", "M4A1", "M9" }
            end
            return H.runAsync("Grabbing " .. tostring(#list) .. " weapon(s)...", ctx.continueChain, function()
                local okG, res = pcall(App.Weapons.GrabWeapons, list, false)
                if okG then
                    return true, "Grabbed weapons (" .. tostring(#list) .. " requested)"
                end
                return false, "GrabWeapons failed: " .. tostring(res)
            end)
        end, { cat = "Guns", usage = "guns [weapon...]", argType = "gun" })

        Admin.RegisterAction({ "gun", "givegun", "weapon" }, "Grab and equip a specific weapon", function(args, ctx)
            if #args == 0 then
                return false, "Usage: gun <name> (e.g. gun ak, gun \"Remington 870\")"
            end
            if not App.Weapons or type(App.Weapons.GrabWeapons) ~= "function" then
                return false, "Weapons subsystem not loaded"
            end
            local raw = table.concat(args, " ")
            local resolved = H.resolveGunName(raw)
            if not resolved then
                return false, "Unknown weapon: " .. raw
            end
            return H.runAsync("Grabbing " .. resolved .. "...", ctx.continueChain, function()
                local okG, errG = pcall(App.Weapons.GrabWeapons, { resolved }, true)
                local tool = App.Weapons.HasTool and App.Weapons.HasTool(resolved) or nil
                if tool then
                    local hum = H.getHum(H.getChar())
                    if hum and tool.Parent ~= H.getChar() then
                        pcall(hum.EquipTool, hum, tool)
                    end
                    return true, "Equipped " .. resolved
                end
                if okG then
                    return false, "Could not obtain " .. resolved .. " (TouchGiver out of reach or unavailable)"
                end
                return false, "Failed to grab " .. resolved .. ": " .. tostring(errG)
            end)
        end, { cat = "Guns", usage = "gun <name>", argType = "gun" })

        Admin.RegisterAction({ "loadout", "kit" }, "Grab weapon kit (cop|guard|inmate|crim|combo|all)", function(args, ctx)
            local key = args[1] and string.lower(H.trimStr(args[1])) or ""
            local list = KITS[key]
            if not list then
                return false, "Usage: loadout <cop|guard|inmate|crim|combo|all>"
            end
            if not App.Weapons or type(App.Weapons.GrabWeapons) ~= "function" then
                return false, "Weapons subsystem not loaded"
            end
            return H.runAsync("Grabbing '" .. key .. "' loadout...", ctx.continueChain, function()
                local okG, res = pcall(App.Weapons.GrabWeapons, list, false)
                if okG then
                    return true, "Loadout '" .. key .. "' complete"
                end
                return false, "Loadout '" .. key .. "' failed: " .. tostring(res)
            end)
        end, { cat = "Guns", usage = "loadout <cop|guard|inmate|crim|combo|all>", argChoices = { "cop", "guard", "inmate", "crim", "combo", "all" } })

        Admin.RegisterToggle({ "autoguns", "autogetguns" }, "AutoGetGuns", "Auto Get Guns", { cat = "Guns" })
        Admin.RegisterToggle({ "gunmods", "modguns" }, "GunMods", "Gun Mods", {
            cat = "Guns",
            numericKey = "GunFireRateSPS",
            numericMin = 5,
            numericMax = 45,
            onChanged = function()
                if App.Combat and type(App.Combat.ApplyGunModsAll) == "function" then
                    pcall(App.Combat.ApplyGunModsAll)
                end
            end,
        })
        Admin.RegisterToggle({ "autoarmor" }, "AutoArmor", "Auto Armor", { cat = "Guns" })
        Admin.RegisterToggle({ "autoheal" }, "AutoHeal", "Auto Heal", { cat = "Guns" })
        Admin.RegisterToggle({ "autopickup", "autopickupdrops" }, "AutoPickupDrops", "Auto Pickup Drops", { cat = "Guns" })

        Admin.RegisterAction({ "combo1", "combo", "cmbo" }, "Execute Combo 1 burst", function()
            if not App.Weapons or type(App.Weapons.ExecuteCombo1) ~= "function" then
                return false, "Combo1 handler unavailable"
            end
            local okE, res = pcall(App.Weapons.ExecuteCombo1)
            if not okE then
                return false, "Combo 1 error: " .. tostring(res)
            end
            return true, "Executed Combo 1"
        end, { cat = "Combat", usage = "combo1" })

        Admin.RegisterToggle({ "loopcombo", "autocombo" }, "ComboLoop", "Combo 1 Loop", { cat = "Combat" })
        Admin.RegisterToggle({ "ragebot", "rage", "rb" }, "Ragebot", "Ragebot", {
            offAliases = { "unrage", "unrb" },
            cat = "Combat",
            numericKey = "RagebotRate",
            numericMin = 2,
            numericMax = 35,
        })
        Admin.RegisterRange({ "ragerate", "ragebotrate" }, "RagebotRate", "Ragebot", "RagebotRate", { cat = "Combat", min = 2, max = 35 })
        Admin.RegisterToggle({ "rage360", "ragebot360" }, "Ragebot360", "Ragebot 360", { cat = "Combat" })
        Admin.RegisterToggle({ "silentaim", "sa", "silent" }, "SilentAim", "Silent Aim", { offAliases = { "unsa", "unsilent" }, cat = "Combat" })
        Admin.RegisterRange({ "fov", "safov" }, "SilentAimFOV", "SilentAim", "SilentAimFOV", { cat = "Combat", min = 30, max = 360 })
        Admin.RegisterAction({ "camfov", "camerafov" }, "Set Camera FieldOfView (30..120)", function(args)
            local cam = App.GetCamera and App.GetCamera() or Services.Workspace.CurrentCamera
            if not cam then
                return false, "CurrentCamera unavailable"
            end
            if not args[1] then
                return true, "Camera FOV = " .. tostring(cam.FieldOfView)
            end
            local n = tonumber(args[1])
            if not n then
                return false, "Invalid number for camfov (30..120)"
            end
            local val = H.clampNum(n, 30, 120)
            cam.FieldOfView = val
            return true, "Camera FOV = " .. tostring(val)
        end, { cat = "Combat", usage = "camfov <30..120>" })
        Admin.RegisterToggle({ "showfov", "fovcircle" }, "SilentAimShowFOV", "FOV Circle", { cat = "Combat" })
        Admin.RegisterRange({ "hitchance", "hc" }, "SilentAimHitChance", nil, "SilentAimHitChance", { cat = "Combat", min = 10, max = 100 })
        Admin.RegisterRange({ "headchance", "headc", "hs" }, "SilentAimHeadChance", nil, "SilentAimHeadChance", { cat = "Combat", min = 0, max = 100 })

        Admin.RegisterAction({ "aimpart", "targetpart" }, "Set Silent Aim body part (head|torso|random)", function(args)
            local raw = args[1] and string.lower(H.trimStr(args[1])) or ""
            if raw == "" then
                return true, "Silent Aim TargetPart = " .. tostring(State.SilentAimTargetPart) .. " (options: head, torso, random)"
            end
            local map = { head = "Head", torso = "Torso", body = "Torso", hrp = "Torso", random = "Random", rand = "Random" }
            local canon = map[raw]
            if not canon then
                return false, "Invalid aimpart '" .. tostring(args[1]) .. "'. Use: head, torso, random"
            end
            App.SetState("SilentAimTargetPart", canon)
            H.syncUI()
            return true, "Silent Aim TargetPart = " .. canon
        end, { cat = "Combat", usage = "aimpart <head|torso|random>", argChoices = { "head", "torso", "random" } })

        Admin.RegisterToggle({ "wallcheck", "wc" }, "SilentAimWallcheck", "Wallcheck", { offAliases = { "unwc" }, cat = "Combat" })
        Admin.RegisterToggle({ "wallbang", "wb" }, "SilentAimWallbang", "Wallbang", { offAliases = { "unwb" }, cat = "Combat" })
        Admin.RegisterToggle({ "teamcheck", "tc" }, "SilentAimTeamCheck", "Team Check", { offAliases = { "untc" }, cat = "Combat" })
        Admin.RegisterToggle({ "hostilecheck" }, "SilentAimHostileCheck", "Hostile Inmate Check", { cat = "Combat" })
        Admin.RegisterToggle({ "killaura", "ka", "aura" }, "KillAura", "KillAura", {
            offAliases = { "unka", "unaura" },
            cat = "Combat",
            numericKey = "KillAuraRange",
            numericMin = 6,
            numericMax = 30,
        })
        Admin.RegisterRange({ "karange", "karrange" }, "KillAuraRange", "KillAura", "KillAuraRange", { cat = "Combat", min = 6, max = 30 })

        Admin.RegisterToggle({ "hitbox", "hb", "hitboxes", "expand" }, "HitboxExpander", "Hitbox Expander", {
            offAliases = { "unhb", "unhitboxes", "unexpand" },
            cat = "Combat",
            numericKey = "HitboxSize",
            numericMin = 3,
            numericMax = 25,
            onChanged = function()
                if App.Visuals and type(App.Visuals.UpdateHitboxExpander) == "function" then
                    pcall(App.Visuals.UpdateHitboxExpander)
                end
            end,
        })
        Admin.RegisterRange({ "hitboxsize", "hbsize" }, "HitboxSize", "HitboxExpander", "HitboxSize", {
            cat = "Combat",
            min = 3,
            max = 25,
            onChanged = function()
                if App.Visuals and type(App.Visuals.UpdateHitboxExpander) == "function" then
                    pcall(App.Visuals.UpdateHitboxExpander)
                end
            end,
        })
        Admin.RegisterToggle({ "aimassist", "aimbot" }, "AimAssist", "Aim Assist", {
            offAliases = { "unaimassist", "unaimbot" },
            cat = "Combat",
            numericKey = "AimAssistFOV",
            numericMin = 30,
            numericMax = 350,
        })
        Admin.RegisterToggle({ "antiriot", "antishield" }, "AntiRiotShield", "Anti-RiotShield", { cat = "Combat" })

        local function fireTargetsSeq(targets, continueChain, isBulk)
            local tool = getBestWeapon()
            if not tool then
                return false, "No loaded weapon available (run 'guns' first)"
            end
            if not App.Combat or type(App.Combat.FireGunOnce) ~= "function" then
                return false, "Combat.FireGunOnce unavailable"
            end
            local lp = H.getLP()
            return H.runAsync("Engaging " .. tostring(#targets) .. " target(s)...", continueChain, function()
                local count = 0
                for _, plr in ipairs(targets) do
                    if not App.Running then
                        break
                    end
                    if plr ~= lp then
                        local ch = H.getChar(plr)
                        local th = H.getHum(ch)
                        local part = ch and (ch:FindFirstChild("Head") or H.getRoot(ch)) or nil
                        if th and th.Health > 0 and part and not ch:FindFirstChildOfClass("ForceField") then
                            local hum = H.getHum(H.getChar())
                            if hum and tool.Parent ~= H.getChar() then
                                pcall(hum.EquipTool, hum, tool)
                            end
                            local shots = isBulk and 3 or 5
                            for s = 1, shots do
                                if not App.Running or th.Health <= 0 then
                                    break
                                end
                                pcall(App.Combat.FireGunOnce, tool, part, true, false)
                                if s < shots then
                                    task.wait(0.06)
                                end
                            end
                            count = count + 1
                            task.wait(0.04)
                        end
                    end
                end
                return count > 0, count > 0 and ("Engaged " .. tostring(count) .. " target(s)") or "No alive targets engaged"
            end)
        end

        Admin.RegisterTargetCmd({ "kill" }, "Shoot/kill specified target(s)", function(targets, _, ctx)
            return fireTargetsSeq(targets, ctx.continueChain, false)
        end, { cat = "Combat" })

        Admin.RegisterAction({ "killall" }, "Sequentially engage all valid targets", function(args, ctx)
            local query = (#args > 0) and table.concat(args, " ") or "others"
            local rawList = H.resolveTargets(query)
            local lp = H.getLP()
            local filtered = {}
            local wl = State.KillAuraWhitelist or {}
            for _, p in ipairs(rawList) do
                if p ~= lp and not wl[p.UserId] then
                    if not State.KillAuraTeamCheck or not lp or p.Team ~= lp.Team then
                        table.insert(filtered, p)
                    end
                end
            end
            if #filtered == 0 then
                return false, "No valid targets for killall"
            end
            return fireTargetsSeq(filtered, ctx.continueChain, true)
        end, { cat = "Combat", usage = "killall [targets]", argType = "target" })

        Admin.RegisterTargetCmd({ "loopkill", "lk" }, "Add target(s) to persistent LoopKill priority list", function(targets)
            mutateIdMap("LoopKillTargets", targets, true, false)
            return true, "LoopKill added " .. tostring(#targets) .. " target(s)"
        end, { cat = "Combat" })

        Admin.RegisterAction({ "unloopkill", "unlk", "clearloopkill" }, "Remove target(s) or clear LoopKill list", function(args)
            local q = args[1] and string.lower(H.trimStr(args[1])) or "all"
            if q == "" or q == "all" or q == "clear" then
                mutateIdMap("LoopKillTargets", {}, false, true)
                return true, "LoopKill list cleared"
            end
            local targets = H.resolveTargets(args)
            if #targets == 0 then
                return false, "No matching target to remove from LoopKill"
            end
            mutateIdMap("LoopKillTargets", targets, false, false)
            return true, "Removed " .. tostring(#targets) .. " target(s) from LoopKill"
        end, { cat = "Combat", usage = "unloopkill [targets|all]", argType = "target" })

        Admin.RegisterTargetCmd({ "kawl" }, "Whitelist player(s) from KillAura / LoopKill", function(targets)
            mutateIdMap("KillAuraWhitelist", targets, true, false)
            return true, "KillAura Whitelist added " .. tostring(#targets) .. " player(s)"
        end, { cat = "Combat" })

        Admin.RegisterAction({ "unkawl" }, "Remove or clear KillAura whitelist", function(args)
            local q = args[1] and string.lower(H.trimStr(args[1])) or ""
            if q == "" then
                return false, "Usage: unkawl <targets|clear>"
            end
            if q == "clear" or q == "all" then
                mutateIdMap("KillAuraWhitelist", {}, false, true)
                return true, "KillAura Whitelist cleared"
            end
            local targets = H.resolveTargets(args)
            if #targets == 0 then
                return false, "No matching player for unkawl"
            end
            mutateIdMap("KillAuraWhitelist", targets, false, false)
            return true, "KillAura Whitelist removed " .. tostring(#targets) .. " player(s)"
        end, { cat = "Combat", usage = "unkawl <targets|clear>", argType = "target" })

        Admin.RegisterTargetCmd({ "aawl" }, "Whitelist player(s) from AutoArrest / arrest", function(targets)
            mutateIdMap("ArrestWhitelist", targets, true, false)
            return true, "Arrest Whitelist added " .. tostring(#targets) .. " player(s)"
        end, { cat = "Prison" })

        Admin.RegisterAction({ "unaawl" }, "Remove or clear Arrest whitelist", function(args)
            local q = args[1] and string.lower(H.trimStr(args[1])) or ""
            if q == "" then
                return false, "Usage: unaawl <targets|clear>"
            end
            if q == "clear" or q == "all" then
                mutateIdMap("ArrestWhitelist", {}, false, true)
                return true, "Arrest Whitelist cleared"
            end
            local targets = H.resolveTargets(args)
            if #targets == 0 then
                return false, "No matching player for unaawl"
            end
            mutateIdMap("ArrestWhitelist", targets, false, false)
            return true, "Arrest Whitelist removed " .. tostring(#targets) .. " player(s)"
        end, { cat = "Prison", usage = "unaawl <targets|clear>", argType = "target" })
    end

    App.Admin._RegCombat = registerGunsAndCombat
end

-- ============================================================================
--  COMMAND REGISTRATIONS: SHIELD, PROTECTIONS & PRISON ACTIONS
-- ============================================================================
do
    local function registerShieldAndPrison(Admin, H)
        local function setShieldOn(on)
            if App.Shield and type(App.Shield.SetEnabled) == "function" then
                pcall(App.Shield.SetEnabled, on)
            else
                App.SetState("ShieldEnabled", on)
            end
            if App.Shield and type(App.Shield.NotifyShieldStateChanged) == "function" then
                pcall(App.Shield.NotifyShieldStateChanged)
            end
        end

        local function setInvisOn(on)
            if App.Shield and type(App.Shield.SetFEInvisible) == "function" then
                pcall(App.Shield.SetFEInvisible, on)
            elseif on and App.Shield and type(App.Shield.StartFEInvisible) == "function" then
                App.SetState("FEInvisible", true)
                pcall(App.Shield.StartFEInvisible)
            elseif (not on) and App.Shield and type(App.Shield.StopFEInvisible) == "function" then
                App.SetState("FEInvisible", false)
                pcall(App.Shield.StopFEInvisible)
            else
                App.SetState("FEInvisible", on)
            end
        end

        local function getArrestRemote()
            if App.Remotes and App.Remotes.ArrestPlayer then
                return App.Remotes.ArrestPlayer
            end
            local rs = Services.ReplicatedStorage
            local remFolder = rs and rs:FindFirstChild("Remotes")
            return remFolder and remFolder:FindFirstChild("ArrestPlayer") or nil
        end

        local function getC4Remote()
            if App.Remotes and (App.Remotes.DetonateC4 or App.Remotes.ActivateC4) then
                return App.Remotes.DetonateC4 or App.Remotes.ActivateC4
            end
            local rs = Services.ReplicatedStorage
            local rf = rs and rs:FindFirstChild("Remotes")
            local c4f = rf and rf:FindFirstChild("C4")
            return c4f and c4f:FindFirstChild("ActivateC4") or nil
        end

        local function countOwnedPlantedC4(lp)
            local cs = Services.CollectionService
            if not cs or not lp then
                return 0
            end
            local okT, tagged = pcall(cs.GetTagged, cs, "C4")
            if not okT or type(tagged) ~= "table" then
                return 0
            end
            local n = 0
            for _, inst in ipairs(tagged) do
                if inst and (inst:IsA("BasePart") or inst:IsA("Model")) then
                    local uidOk, uid = pcall(inst.GetAttribute, inst, "UserId")
                    if uidOk and uid == lp.UserId then
                        n = n + 1
                    end
                end
            end
            return n
        end

        local function tryFireC4Remote(rem)
            if rem.InvokeServer then
                return pcall(rem.InvokeServer, rem)
            elseif rem.FireServer then
                return pcall(rem.FireServer, rem)
            end
            return false, "Unsupported remote class"
        end

        Admin.RegisterToggle({ "shield" }, "ShieldEnabled", "Bullet Shield", {
            offAliases = { "noshield" },
            cat = "Shield",
            applyFn = function(val)
                setShieldOn(val)
                return true, "Bullet Shield: " .. (val and "ON" or "OFF")
            end,
        })

        Admin.RegisterToggle({ "shieldbox" }, "ShieldEnabled", "3D Shield Box", {
            cat = "Shield",
            desc = "Toggle 3D Shield protection",
            applyFn = function(val)
                setShieldOn(val)
                return true, "3D Bullet Shield: " .. (val and "ON" or "OFF")
            end,
        })

        Admin.RegisterToggle({ "shieldbadge", "showshield" }, "ShowShieldBadge", "Shield Status Badge", { cat = "HUD" })
        Admin.RegisterRange({ "shieldsize", "ssize" }, "ShieldSize", nil, "ShieldSize", { cat = "Shield", min = 3, max = 14 })
        Admin.RegisterToggle({ "shieldauto", "autoshieldequip" }, "ShieldAutoEquip", "Auto Equip Riot Shield", { cat = "Shield" })
        Admin.RegisterToggle({ "spinblock" }, "ShieldSpinBlock", "Shield Spin Block", { cat = "Shield" })
        Admin.RegisterToggle({ "autoshield", "autofaceshield" }, "ShieldAutoFaceShooter", "Auto Face Shooter", { cat = "Shield" })

        Admin.RegisterAction({ "shieldmode", "smode" }, "Set Shield mode (hybrid|riot|desync|ghost)", function(args)
            local raw = args[1] and string.lower(H.trimStr(args[1])) or ""
            if raw == "" then
                return true, "ShieldMode = " .. tostring(State.ShieldMode) .. " (options: hybrid, riot, desync, ghost)"
            end
            local modes = {
                hybrid = "Hybrid",
                riot = "RiotOnly",
                riotonly = "RiotOnly",
                desync = "DesyncBox",
                desyncbox = "DesyncBox",
                ghost = "FEGhost",
                feghost = "FEGhost",
                fe = "FEGhost",
            }
            local canon = modes[raw]
            if not canon then
                return false, "Invalid shieldmode '" .. tostring(args[1]) .. "'. Use: hybrid, riot, desync, ghost"
            end
            if App.Shield and type(App.Shield.SetMode) == "function" then
                pcall(App.Shield.SetMode, canon)
            else
                App.SetState("ShieldMode", canon)
            end
            H.syncUI()
            return true, "ShieldMode = " .. canon
        end, { cat = "Shield", usage = "shieldmode <hybrid|riot|desync|ghost>", argChoices = { "hybrid", "riot", "desync", "ghost" } })

        Admin.RegisterAction({ "antiaim", "desync" }, "Enable DesyncBox Anti-Aim (or toggle off)", function(args)
            local arg1 = args[1] and string.lower(H.trimStr(args[1])) or nil
            local turnOn = (arg1 == "on" or arg1 == "true" or arg1 == "1") or (arg1 == nil and not (State.ShieldEnabled and State.ShieldMode == "DesyncBox"))
            if arg1 ~= nil and arg1 ~= "on" and arg1 ~= "off" and arg1 ~= "true" and arg1 ~= "false" then
                return false, "Usage: antiaim [on|off]"
            end
            local nextMode = turnOn and "DesyncBox" or "Hybrid"
            if App.Shield and type(App.Shield.SetMode) == "function" then
                pcall(App.Shield.SetMode, nextMode)
            else
                App.SetState("ShieldMode", nextMode)
            end
            if turnOn then
                setShieldOn(true)
            end
            H.syncUI()
            return true, "Anti-Aim (DesyncBox): " .. (turnOn and "ON" or "OFF (Hybrid)")
        end, { cat = "Shield", usage = "antiaim [on|off]", argType = "toggle" })

        Admin.RegisterAction({ "unantiaim", "undesync" }, "Disable DesyncBox Anti-Aim", function()
            if App.Shield and type(App.Shield.SetMode) == "function" then
                pcall(App.Shield.SetMode, "Hybrid")
            else
                App.SetState("ShieldMode", "Hybrid")
            end
            H.syncUI()
            return true, "Anti-Aim: OFF (Hybrid)"
        end, { cat = "Shield", usage = "unantiaim" })

        Admin.RegisterToggle({ "invis", "ghost", "feghost" }, "FEInvisible", "FE Invisible", {
            offAliases = { "uninvis", "unghost", "unfeghost" },
            cat = "Shield",
            applyFn = function(val)
                setInvisOn(val)
                return true, "FE Invisible: " .. (val and "ON" or "OFF")
            end,
        })

        Admin.RegisterToggle({ "antitase", "antitaze" }, "AntiTaze", "Anti-Tase", {
            offAliases = { "unantitase", "unantitaze" },
            cat = "Shield",
            onChanged = function(val)
                if val and App.Shield and type(App.Shield.InstallAntiTaze) == "function" then
                    pcall(App.Shield.InstallAntiTaze)
                end
            end,
        })
        Admin.RegisterToggle({ "antiarrest", "antiar" }, "AntiArrest", "Anti-Arrest", { offAliases = { "unantiar", "unantiarrest" }, cat = "Shield" })
        Admin.RegisterToggle({ "antiinvis", "antiinvisible" }, "AntiInvisible", "Reveal Invisible Players", { cat = "Shield" })
        Admin.RegisterToggle({ "antifling" }, "AntiFling", "Anti-Fling", {
            cat = "Prison",
            onChanged = function(val)
                if App.World and type(App.World.SafeSetAntiFlingEnabled) == "function" then
                    pcall(App.World.SafeSetAntiFlingEnabled, val)
                end
            end,
        })
        Admin.RegisterToggle({ "antikillplane", "nokillplane" }, "AntiKillPlane", "Anti Kill Plane", { cat = "Prison" })

        Admin.RegisterTargetCmd({ "arrest", "ar" }, "Attempt arrest on target(s) or nearest", function(targets)
            local rem = getArrestRemote()
            if not rem then
                return false, "Arrest remote unavailable"
            end
            local lp = H.getLP()
            if not lp or not lp.Team or lp.Team.Name ~= "Guards" then
                return false, "Must be on Guards team to arrest (run 'team guards')"
            end
            local wl = State.ArrestWhitelist or {}
            local attempted = 0
            for _, p in ipairs(targets) do
                if p ~= lp and not wl[p.UserId] then
                    local okI = pcall(rem.InvokeServer, rem, p, 1)
                    if okI then
                        attempted = attempted + 1
                    end
                end
            end
            if attempted == 0 then
                return false, "No arrestable non-whitelisted target succeeded"
            end
            return true, "Arrest invoked for " .. tostring(attempted) .. " target(s)"
        end, { cat = "Prison", optionalTarget = true, defaultQuery = "nearest" })

        Admin.RegisterAction({ "arrestall", "aa" }, "Guard-checked sequential proximity arrest across targets", function(args, ctx)
            local rem = getArrestRemote()
            if not rem then
                return false, "Arrest remote unavailable"
            end
            local lp = H.getLP()
            if not lp or not lp.Team or lp.Team.Name ~= "Guards" then
                return false, "ArrestAll requires Guards team (run 'team guards')"
            end
            local hrp = H.getRoot(H.getChar(lp))
            if not hrp then
                return false, "No local HumanoidRootPart"
            end
            local q = (#args > 0) and table.concat(args, " ") or "others"
            local candidates = H.resolveTargets(q)
            local wl = State.ArrestWhitelist or {}
            local list = {}
            for _, p in ipairs(candidates) do
                if p ~= lp and not wl[p.UserId] and (not p.Team or p.Team.Name ~= "Guards") then
                    table.insert(list, p)
                end
            end
            if #list == 0 then
                return false, "No valid targets for arrestall"
            end

            local savedCF = hrp.CFrame
            return H.runAsync("ArrestAll running on " .. tostring(#list) .. " target(s)...", ctx.continueChain, function()
                local count = 0
                for _, p in ipairs(list) do
                    if not App.Running then
                        break
                    end
                    local tr = H.getRoot(H.getChar(p))
                    local th = H.getHum(H.getChar(p))
                    if tr and th and th.Health > 0 then
                        local okTp = true
                        if App.World and type(App.World.SafeTeleportCF) == "function" then
                            okTp = App.World.SafeTeleportCF(tr.CFrame * CFrame.new(0, 0, 2.5))
                        end
                        if okTp then
                            local okI = pcall(rem.InvokeServer, rem, p, 1)
                            if okI then
                                count = count + 1
                            end
                            task.wait(0.08)
                        end
                    end
                end
                if App.Running and App.World and type(App.World.SafeTeleportCF) == "function" then
                    pcall(App.World.SafeTeleportCF, savedCF)
                end
                return count > 0, "ArrestAll attempted " .. tostring(count) .. "/" .. tostring(#list) .. " target(s)"
            end)
        end, { cat = "Prison", usage = "arrestall [targets]", argType = "target" })

        local function fireTaseTargets(targets, continueChain)
            local taser = App.Weapons and App.Weapons.HasTool and App.Weapons.HasTool("Taser") or nil
            if not taser then
                return false, "Taser tool not owned (requires Guards loadout)"
            end
            local ammo = taser:GetAttribute("CurrentAmmo") or taser:GetAttribute("Local_CurrentAmmo")
            if ammo ~= nil and tonumber(ammo) <= 0 then
                return false, "Taser out of ammo"
            end
            if not App.Combat or type(App.Combat.FireGunOnce) ~= "function" then
                return false, "Combat.FireGunOnce unavailable"
            end
            local lp = H.getLP()
            return H.runAsync("Tasing " .. tostring(#targets) .. " target(s)...", continueChain, function()
                local fired = 0
                for _, p in ipairs(targets) do
                    if not App.Running then
                        break
                    end
                    if p ~= lp then
                        local ch = H.getChar(p)
                        local th = H.getHum(ch)
                        local tr = H.getRoot(ch)
                        if th and th.Health > 0 and tr then
                            local hum = H.getHum(H.getChar())
                            if hum and taser.Parent ~= H.getChar() then
                                pcall(hum.EquipTool, hum, taser)
                            end
                            pcall(App.Combat.FireGunOnce, taser, tr, false, true)
                            fired = fired + 1
                            task.wait(0.1)
                        end
                    end
                end
                return fired > 0, fired > 0 and ("Tased " .. tostring(fired) .. " target(s)") or "No alive targets tased"
            end)
        end

        Admin.RegisterTargetCmd({ "tase", "taze" }, "Tase specified target(s)", function(targets, _, ctx)
            return fireTaseTargets(targets, ctx.continueChain)
        end, { cat = "Prison" })

        Admin.RegisterAction({ "taseall", "tazeall" }, "Sequentially tase all valid targets", function(args, ctx)
            local q = (#args > 0) and table.concat(args, " ") or "others"
            local targets = H.resolveTargets(q)
            if #targets == 0 then
                return false, "No targets for taseall"
            end
            return fireTaseTargets(targets, ctx.continueChain)
        end, { cat = "Prison", usage = "taseall [targets]", argType = "target" })

        Admin.RegisterToggle({ "autoarrest", "araura" }, "AutoArrest", "Auto-Arrest", { offAliases = { "unautoarrest", "unaraura" }, cat = "Prison" })
        Admin.RegisterToggle({ "autotaze", "autotase" }, "AutoTaze", "Auto-Tase", { cat = "Prison" })
        Admin.RegisterToggle({ "autocrim", "autocrime", "autocriminal" }, "AutoCriminal", "Auto-Criminal", { cat = "Prison" })

        Admin.RegisterAction({ "c4" }, "Grab and equip C4 Explosive", function()
            local c4Tool = App.Weapons and App.Weapons.HasTool and App.Weapons.HasTool("C4 Explosive") or nil
            if not c4Tool and App.Weapons and type(App.Weapons.GrabWeapons) == "function" then
                pcall(App.Weapons.GrabWeapons, { "C4 Explosive" }, true)
                c4Tool = App.Weapons.HasTool and App.Weapons.HasTool("C4 Explosive") or nil
            end
            if not c4Tool then
                return false, "C4 Explosive unavailable (grab at Warehouse / Criminal Base)"
            end
            local hum = H.getHum(H.getChar())
            if hum and c4Tool.Parent ~= H.getChar() then
                pcall(hum.EquipTool, hum, c4Tool)
            end
            return true, "Equipped C4 Explosive"
        end, { cat = "Prison", usage = "c4" })

        Admin.RegisterAction({ "detonate", "det", "boom" }, "Detonate your planted C4 charges", function()
            local rem = getC4Remote()
            if not rem then
                return false, "C4 ActivateC4 remote unavailable"
            end
            local lp = H.getLP()
            local planted = countOwnedPlantedC4(lp)
            local c4Tool = App.Weapons and App.Weapons.HasTool and App.Weapons.HasTool("C4 Explosive") or nil
            if planted == 0 and not c4Tool then
                return false, "No planted C4 or C4 Explosive tool found"
            end
            local char = H.getChar(lp)
            local hum = H.getHum(char)
            local prevTool = char and char:FindFirstChildOfClass("Tool") or nil
            if hum and c4Tool and prevTool ~= c4Tool then
                pcall(hum.EquipTool, hum, c4Tool)
            end
            local okD, errD = tryFireC4Remote(rem)
            if hum and prevTool and prevTool.Parent == lp:FindFirstChildOfClass("Backpack") and prevTool ~= c4Tool then
                pcall(hum.EquipTool, hum, prevTool)
            end
            if not okD then
                return false, "Detonate failed: " .. tostring(errD)
            end
            return true, "Detonated C4 (" .. tostring(planted) .. " planted)"
        end, { cat = "Prison", usage = "detonate" })

        Admin.RegisterToggle({ "autoc4", "autodet", "autodetc4" }, "AutoDetonateC4", "Auto Detonate C4", { cat = "Prison" })
    end

    App.Admin._RegShield = registerShieldAndPrison
end

-- ============================================================================
--  COMMAND REGISTRATIONS: MOVE, TELEPORT, VIEW, VEHICLES, WORLD, VISUALS, CONFIG
-- ============================================================================
do
    local function registerMoveAndWorld(Admin, H)
        local ViewScope = Janitor.NewScope()

        local function clearSpectate()
            ViewScope:Clean()
            if App.Scheduler and type(App.Scheduler.SetViewTarget) == "function" then
                pcall(App.Scheduler.SetViewTarget, nil)
            end
            local cam = App.GetCamera and App.GetCamera() or (Services.Workspace and Services.Workspace.CurrentCamera)
            local hum = H.getHum(H.getChar())
            if cam and hum then
                pcall(function()
                    cam.CameraSubject = hum
                end)
            end
        end

        Admin._ClearSpectate = clearSpectate

        Admin.RegisterTargetCmd({ "view", "spectate" }, "Spectate a player safely", function(targets)
            local target = targets[1]
            local lp = H.getLP()
            if not target or target == lp then
                clearSpectate()
                return true, "View restored to local player"
            end

            clearSpectate()
            if App.Scheduler and type(App.Scheduler.SetViewTarget) == "function" then
                pcall(App.Scheduler.SetViewTarget, target)
            end

            local function attachCam()
                local cam = App.GetCamera and App.GetCamera() or (Services.Workspace and Services.Workspace.CurrentCamera)
                local tc = H.getChar(target)
                local subj = H.getHum(tc) or H.getRoot(tc)
                if cam and subj then
                    pcall(function()
                        cam.CameraSubject = subj
                    end)
                end
            end

            attachCam()
            ViewScope:Add(target.CharacterAdded:Connect(function()
                ViewScope:Delay(0.15, attachCam)
            end))
            if Services.Players and Services.Players.PlayerRemoving then
                ViewScope:Add(Services.Players.PlayerRemoving:Connect(function(leftPlr)
                    if leftPlr == target then
                        clearSpectate()
                        H.emitOutput(false, "View target " .. target.Name .. " left; restored camera")
                    end
                end))
            end

            return true, "Viewing " .. target.Name .. " (use 'unview' to restore)"
        end, { cat = "View", usage = "view <player>" })

        Admin.RegisterAction({ "unview", "unspectate" }, "Restore camera to local character", function()
            clearSpectate()
            return true, "View restored"
        end, { cat = "View", usage = "unview" })

        Admin.RegisterAction({ "goto", "to", "tp" }, "Teleport to location preset or player", function(args)
            local q = H.trimStr(table.concat(args, " "))
            local locs = H.getTeleportLocations()
            if q == "" then
                local names = {}
                for k in pairs(locs) do
                    table.insert(names, k)
                end
                table.sort(names)
                return true, "Locations: " .. table.concat(names, ", ")
            end

            local preset = locs[string.lower(q)]
            local targetCF = preset
            local label = string.lower(q)
            if not targetCF then
                local plrs = H.resolveTargets(args)
                local plr = plrs[1]
                local tr = plr and H.getRoot(H.getChar(plr)) or nil
                if tr then
                    targetCF = tr.CFrame * CFrame.new(0, 2, 3)
                    label = plr.Name
                end
            end
            if not targetCF then
                return false, "Unknown location or player '" .. q .. "'"
            end
            if not App.World or type(App.World.SafeTeleportCF) ~= "function" then
                local hrp = H.getRoot(H.getChar())
                if not hrp then
                    return false, "Teleport failed: no local character root"
                end
                hrp.CFrame = targetCF
                return true, "Teleported to " .. label
            end
            local okTp, resTp = pcall(App.World.SafeTeleportCF, targetCF)
            if not okTp or resTp == false then
                return false, "Teleport to '" .. label .. "' failed (no root or blocked)"
            end
            return true, "Teleported to " .. label
        end, { cat = "Movement", usage = "goto <location|player>", argType = "target" })

        local function findMultiSeatCar(myHum)
            local ws = Services.Workspace
            local container = ws and ws:FindFirstChild("CarContainer")
            if not container then
                return nil, nil, nil
            end
            -- Prefer the vehicle already driven by LocalPlayer if it has a free passenger seat
            if myHum and myHum.SeatPart and myHum.SeatPart:IsA("VehicleSeat") then
                local model = myHum.SeatPart:FindFirstAncestorOfClass("Model")
                if model then
                    for _, desc in ipairs(model:GetDescendants()) do
                        if desc:IsA("Seat") and not desc:IsA("VehicleSeat") and desc.Occupant == nil then
                            return model, myHum.SeatPart, desc
                        end
                    end
                end
            end
            for _, model in ipairs(container:GetChildren()) do
                if model:IsA("Model") then
                    local drv, pass = nil, nil
                    for _, desc in ipairs(model:GetDescendants()) do
                        if desc:IsA("VehicleSeat") and (desc.Occupant == nil or desc.Occupant == myHum) then
                            drv = desc
                        elseif desc:IsA("Seat") and desc.Occupant == nil then
                            pass = desc
                        end
                    end
                    if drv and pass then
                        return model, drv, pass
                    end
                end
            end
            return nil, nil, nil
        end

        Admin.RegisterTargetCmd({ "bring" }, "Honest FE car-seat bring attempt for a target player", function(targets, _, ctx)
            local target = targets[1]
            local lp = H.getLP()
            if not target or target == lp then
                return false, "Specify another player to bring"
            end
            local myChar = H.getChar(lp)
            local myRoot = H.getRoot(myChar)
            local myHum = H.getHum(myChar)
            local tr = H.getRoot(H.getChar(target))
            local th = H.getHum(H.getChar(target))
            if not myRoot or not myHum or not tr or not th or th.Health <= 0 then
                return false, "Local player or alive target root missing"
            end

            local carModel, drvSeat, passSeat = findMultiSeatCar(myHum)
            if not carModel or not drvSeat or not passSeat then
                return false, "FE Bring unavailable: no car in CarContainer with free driver & passenger seats (FE blocks direct player CFrame brings)"
            end

            local returnCF = myRoot.CFrame
            return H.runAsync("Attempting FE vehicle-seat bring for " .. target.Name .. "...", ctx.continueChain, function()
                if myHum.SeatPart ~= drvSeat then
                    if App.World and type(App.World.SafeTeleportCF) == "function" then
                        pcall(App.World.SafeTeleportCF, drvSeat.CFrame + Vector3.new(0, 2, 0))
                    end
                    pcall(drvSeat.Sit, drvSeat, myHum)
                    task.wait(0.2)
                end
                if myHum.SeatPart ~= drvSeat then
                    return false, "FE Bring failed: could not enter vehicle driver seat"
                end

                local deadline = os.clock() + 1.4
                local brought = false
                while App.Running and os.clock() < deadline do
                    local curTR = H.getRoot(H.getChar(target))
                    if not curTR or th.Health <= 0 then
                        break
                    end
                    if passSeat.Occupant == th or th.SeatPart == passSeat then
                        brought = true
                        break
                    end
                    local offset = passSeat.Position - carModel:GetPivot().Position
                    pcall(carModel.PivotTo, carModel, CFrame.new(curTR.Position - offset))
                    task.wait(0.08)
                end

                pcall(carModel.PivotTo, carModel, returnCF)
                if brought then
                    return true, "Brought " .. target.Name .. " via car passenger seat"
                end
                return false, "FE Bring failed: " .. target.Name .. " did not seat into passenger seat within timeout"
            end)
        end, { cat = "Prison", usage = "bring <player>" })

        local function switchTeamTo(targetTeam)
            if targetTeam == "Criminals" then
                if App.Weapons and type(App.Weapons.SwitchToTeam) == "function" then
                    pcall(App.Weapons.SwitchToTeam, "Criminals")
                end
                local lp = H.getLP()
                if not lp or not lp.Team or lp.Team.Name ~= "Criminals" then
                    local ws = Services.Workspace
                    local cs = ws and ws:FindFirstChild("Criminals Spawn")
                    local sp = cs and (cs:FindFirstChild("SpawnLocation") or cs:FindFirstChildWhichIsA("BasePart") or (cs:IsA("BasePart") and cs)) or nil
                    if sp and App.World and type(App.World.SafeTeleportCF) == "function" then
                        local okTp = App.World.SafeTeleportCF(sp.CFrame + Vector3.new(0, 3, 0))
                        if not okTp then
                            return false, "Failed to teleport to Criminals Spawn"
                        end
                    elseif not sp then
                        return false, "Criminals Spawn not found"
                    end
                end
                return true, "Team switched -> Criminals"
            end

            if not App.Weapons or type(App.Weapons.SwitchToTeam) ~= "function" then
                return false, "SwitchToTeam unavailable"
            end
            local okS, resS = pcall(App.Weapons.SwitchToTeam, targetTeam)
            if not okS or resS == false then
                return false, "Team switch to " .. targetTeam .. " failed"
            end
            return true, "Switched team -> " .. targetTeam
        end

        Admin.RegisterAction({ "team" }, "Switch team (inmates|guards|criminals|neutral)", function(args)
            local raw = args[1] and string.lower(H.trimStr(args[1])) or ""
            if raw == "" then
                return false, "Usage: team <inmates|guards|criminals|neutral>"
            end
            local map = {
                i = "Inmates",
                inmate = "Inmates",
                inmates = "Inmates",
                prisoner = "Inmates",
                g = "Guards",
                guard = "Guards",
                guards = "Guards",
                cop = "Guards",
                cops = "Guards",
                police = "Guards",
                c = "Criminals",
                crim = "Criminals",
                crims = "Criminals",
                criminal = "Criminals",
                criminals = "Criminals",
                n = "Neutral",
                neutral = "Neutral",
                lobby = "Neutral",
            }
            local targetTeam = map[raw]
            if not targetTeam then
                return false, "Invalid team '" .. tostring(args[1]) .. "'. Use: inmates, guards, criminals, neutral"
            end
            return switchTeamTo(targetTeam)
        end, { cat = "Prison", usage = "team <inmates|guards|criminals|neutral>", argChoices = { "inmates", "guards", "criminals", "neutral" } })

        Admin.RegisterAction({ "crim", "criminal", "criminals" }, "Switch team to Criminals", function()
            return switchTeamTo("Criminals")
        end, { cat = "Prison", usage = "crim" })

        Admin.RegisterAction({ "guard", "guards", "cop", "cops" }, "Switch team to Guards", function()
            return switchTeamTo("Guards")
        end, { cat = "Prison", usage = "guard" })

        Admin.RegisterAction({ "inmate", "inmates", "prisoner" }, "Switch team to Inmates", function()
            return switchTeamTo("Inmates")
        end, { cat = "Prison", usage = "inmate" })

        Admin.RegisterAction({ "re", "respawn" }, "Fast respawn at current position", function()
            if App.Weapons and type(App.Weapons.PerformFastRespawn) == "function" then
                local okR, resR = pcall(App.Weapons.PerformFastRespawn)
                if not okR or resR == false then
                    return false, "Fast respawn failed"
                end
                return true, "Respawning..."
            end
            local hum = H.getHum(H.getChar())
            if hum then
                hum.Health = 0
                return true, "Respawning..."
            end
            return false, "No humanoid to respawn"
        end, { cat = "Prison", usage = "re" })

        Admin.RegisterToggle({ "autorespawn", "autore", "fastrespawn" }, "AutoRespawn", "Auto Respawn", {
            offAliases = { "unautorespawn", "unautore", "unfastrespawn" },
            cat = "Prison",
        })

        Admin.RegisterAction({ "speed", "ws" }, "Set WalkSpeed (16..110) or toggle speed", function(args)
            if not args[1] then
                local nextVal = not (State.MaxSpeed == true)
                App.SetState("MaxSpeed", nextVal)
                H.syncUI()
                return true, "Speed: " .. (nextVal and ("ON (" .. tostring(State.WalkSpeed) .. ")") or "OFF")
            end
            local low = string.lower(H.trimStr(args[1]))
            if low == "off" or low == "false" then
                App.SetState("MaxSpeed", false)
                H.syncUI()
                return true, "Speed: OFF"
            end
            local n = tonumber(args[1])
            if not n then
                return false, "Invalid number '" .. tostring(args[1]) .. "' for speed (16..110)"
            end
            local clamped = H.clampNum(n, 16, 110)
            App.SetState("SpeedMode", "Custom")
            App.SetState("WalkSpeed", clamped)
            App.SetState("MaxSpeed", true)
            H.syncUI()
            return true, "Speed = " .. tostring(clamped) .. " (Custom)"
        end, { cat = "Move", usage = "speed <16..110|off>" })

        Admin.RegisterAction({ "unspeed" }, "Disable custom/safe WalkSpeed", function()
            App.SetState("MaxSpeed", false)
            local hum = H.getHum(H.getChar())
            if hum and hum.Health > 0 then
                hum.WalkSpeed = 16
            end
            H.syncUI()
            return true, "Speed: OFF"
        end, { cat = "Move", usage = "unspeed" })

        Admin.RegisterAction({ "speedmode", "safespeed" }, "Set SpeedMode (regionsafe|custom|alwayssprint)", function(args, ctx)
            local order = { "RegionSafe", "Custom", "AlwaysSprint" }
            if ctx.cmd == "safespeed" and not args[1] then
                App.SetState("SpeedMode", "RegionSafe")
                App.SetState("MaxSpeed", true)
                H.syncUI()
                return true, "SpeedMode = RegionSafe (ON)"
            end
            if not args[1] then
                local nextMode = order[1]
                for i = 1, #order do
                    if order[i] == State.SpeedMode then
                        nextMode = order[(i % #order) + 1]
                        break
                    end
                end
                App.SetState("SpeedMode", nextMode)
                H.syncUI()
                return true, "SpeedMode = " .. nextMode
            end
            local raw = string.lower(H.trimStr(args[1]))
            local map = { regionsafe = "RegionSafe", safe = "RegionSafe", custom = "Custom", alwayssprint = "AlwaysSprint", sprint = "AlwaysSprint" }
            local canon = map[raw]
            if not canon then
                return false, "Invalid speedmode '" .. tostring(args[1]) .. "'. Use: regionsafe, custom, alwayssprint"
            end
            App.SetState("SpeedMode", canon)
            App.SetState("MaxSpeed", true)
            H.syncUI()
            return true, "SpeedMode = " .. canon
        end, { cat = "Move", usage = "speedmode [regionsafe|custom|alwayssprint]", argChoices = { "regionsafe", "custom", "alwayssprint" } })

        Admin.RegisterAction({ "jump", "jp", "jumppower" }, "Set JumpPower (50..135) or toggle", function(args)
            if not args[1] then
                local nextVal = not (State.JumpPowerEnabled == true)
                App.SetState("JumpPowerEnabled", nextVal)
                if nextVal and App.Shield and type(App.Shield.BypassAntiJump) == "function" then
                    pcall(App.Shield.BypassAntiJump, H.getChar(), true)
                end
                H.syncUI()
                return true, "JumpPower: " .. (nextVal and ("ON (" .. tostring(State.JumpPower) .. ")") or "OFF")
            end
            local n = tonumber(args[1])
            if not n then
                return false, "Invalid number '" .. tostring(args[1]) .. "' for jump (50..135)"
            end
            local clamped = H.clampNum(n, 50, 135)
            App.SetState("JumpPower", clamped)
            App.SetState("JumpPowerEnabled", true)
            if App.Shield and type(App.Shield.BypassAntiJump) == "function" then
                pcall(App.Shield.BypassAntiJump, H.getChar(), true)
            end
            H.syncUI()
            return true, "JumpPower = " .. tostring(clamped)
        end, { cat = "Move", usage = "jump <50..135>" })

        Admin.RegisterAction({ "unjump", "unjp", "unjumppower" }, "Restore default JumpPower", function()
            App.SetState("JumpPowerEnabled", false)
            H.syncUI()
            return true, "JumpPower Restored"
        end, { cat = "Move", usage = "unjump" })

        Admin.RegisterToggle({ "infjump" }, "InfiniteJump", "Infinite Jump", {
            cat = "Move",
            onChanged = function(val)
                if val and App.Shield and type(App.Shield.BypassAntiJump) == "function" then
                    pcall(App.Shield.BypassAntiJump, H.getChar(), true)
                end
            end,
        })

        Admin.RegisterAction({ "fly" }, "Toggle character fly or set speed (20..220)", function(args)
            if not args[1] then
                local nextVal = not (State.Fly == true)
                App.SetState("Fly", nextVal)
                if not nextVal and App.World and type(App.World.MobileFlyInput) == "table" then
                    App.World.MobileFlyInput.Up = 0
                    App.World.MobileFlyInput.Down = 0
                end
                H.syncUI()
                return true, "Fly: " .. (nextVal and ("ON (" .. tostring(State.FlySpeed) .. ")") or "OFF")
            end
            local low = string.lower(H.trimStr(args[1]))
            if low == "on" or low == "true" then
                App.SetState("Fly", true)
            elseif low == "off" or low == "false" then
                App.SetState("Fly", false)
            else
                local n = tonumber(args[1])
                if not n then
                    return false, "Invalid fly speed '" .. tostring(args[1]) .. "' (20..220)"
                end
                App.SetState("FlySpeed", H.clampNum(n, 20, 220))
                App.SetState("Fly", true)
            end
            H.syncUI()
            return true, "Fly: " .. (State.Fly and ("ON (" .. tostring(State.FlySpeed) .. ")") or "OFF")
        end, { cat = "Move", usage = "fly [speed]" })

        Admin.RegisterAction({ "unfly" }, "Disable character fly", function()
            App.SetState("Fly", false)
            if App.World and type(App.World.MobileFlyInput) == "table" then
                App.World.MobileFlyInput.Up = 0
                App.World.MobileFlyInput.Down = 0
            end
            H.syncUI()
            return true, "Fly: OFF"
        end, { cat = "Move", usage = "unfly" })

        Admin.RegisterRange({ "flyspeed", "fs" }, "FlySpeed", nil, "FlySpeed", { cat = "Move", min = 20, max = 220 })

        Admin.RegisterToggle({ "noclip", "nc" }, "Noclip", "Noclip", {
            offAliases = { "clip", "unnoclip" },
            cat = "Move",
            onChanged = function(val)
                if val and App.Shield and type(App.Shield.BypassClientAntiNoclip) == "function" then
                    pcall(App.Shield.BypassClientAntiNoclip, H.getChar(), true)
                elseif (not val) and App.World and type(App.World.RestoreNoclipCollide) == "function" then
                    pcall(App.World.RestoreNoclipCollide)
                end
            end,
        })

        Admin.RegisterAction({ "car", "spawncar" }, "Spawn or enter nearest vehicle", function()
            if not App.World or type(App.World.SpawnAndEnterNearestCar) ~= "function" then
                return false, "Vehicle spawn handler unavailable"
            end
            local okC, resC, errC = pcall(App.World.SpawnAndEnterNearestCar)
            if not okC or resC == false then
                return false, tostring(errC or resC or "No available vehicle nearby")
            end
            return true, "Entered nearest vehicle"
        end, { cat = "Vehicle", usage = "car" })

        Admin.RegisterAction({ "carfly" }, "Toggle vehicle fly or set speed (25..220)", function(args)
            if not args[1] then
                local nextVal = not (State.VehicleFly == true)
                App.SetState("VehicleFly", nextVal)
                H.syncUI()
                return true, "Vehicle Fly: " .. (nextVal and ("ON (" .. tostring(State.VehicleFlySpeed) .. ")") or "OFF")
            end
            local low = string.lower(H.trimStr(args[1]))
            if low == "on" then
                App.SetState("VehicleFly", true)
            elseif low == "off" then
                App.SetState("VehicleFly", false)
            else
                local n = tonumber(args[1])
                if not n then
                    return false, "Invalid carfly speed '" .. tostring(args[1]) .. "' (25..220)"
                end
                App.SetState("VehicleFlySpeed", H.clampNum(n, 25, 220))
                App.SetState("VehicleFly", true)
            end
            H.syncUI()
            return true, "Vehicle Fly: " .. (State.VehicleFly and ("ON (" .. tostring(State.VehicleFlySpeed) .. ")") or "OFF")
        end, { cat = "Vehicle", usage = "carfly [speed]" })

        Admin.RegisterAction({ "uncarfly" }, "Disable vehicle fly", function()
            App.SetState("VehicleFly", false)
            H.syncUI()
            return true, "Vehicle Fly: OFF"
        end, { cat = "Vehicle", usage = "uncarfly" })

        Admin.RegisterRange({ "carflyspeed", "cfs" }, "VehicleFlySpeed", nil, "VehicleFlySpeed", { cat = "Vehicle", min = 25, max = 220 })

        Admin.RegisterAction({ "carspeed" }, "Toggle Vehicle Speed Mod or set multiplier (1.0..4.5)", function(args)
            if not args[1] then
                local nextVal = not (State.VehicleSpeedMod == true)
                App.SetState("VehicleSpeedMod", nextVal)
                H.syncUI()
                return true, "Vehicle Speed: " .. (nextVal and ("ON (" .. tostring(State.VehicleSpeedMult) .. "x)") or "OFF")
            end
            local low = string.lower(H.trimStr(args[1]))
            if low == "off" then
                App.SetState("VehicleSpeedMod", false)
                H.syncUI()
                return true, "Vehicle Speed: OFF"
            elseif low == "on" then
                App.SetState("VehicleSpeedMod", true)
                H.syncUI()
                return true, "Vehicle Speed: ON (" .. tostring(State.VehicleSpeedMult) .. "x)"
            end
            local n = tonumber(args[1])
            if not n then
                return false, "Invalid carspeed multiplier '" .. tostring(args[1]) .. "' (1.0..4.5)"
            end
            local clamped = H.clampNum(n, 1.0, 4.5)
            App.SetState("VehicleSpeedMult", clamped)
            App.SetState("VehicleSpeedMod", true)
            H.syncUI()
            return true, "Vehicle Speed = " .. tostring(clamped) .. "x"
        end, { cat = "Vehicle", usage = "carspeed [1.0..4.5|off]" })

        Admin.RegisterToggle({ "carfling" }, "VehicleFling", "Vehicle Fling", { cat = "Vehicle" })
        Admin.RegisterToggle({ "carwallbang", "vehiclewallbang" }, "VehicleWallbang", "Vehicle Wallbang", {
            cat = "Vehicle",
            onChanged = function()
                if App.Combat and type(App.Combat.UpdateCastRayFilter) == "function" then
                    pcall(App.Combat.UpdateCastRayFilter)
                end
            end,
        })

        Admin.RegisterToggle({ "doors", "opendoors" }, "OpenAllDoors", "Open All Doors", {
            offAliases = { "closedoors", "unopendoors" },
            cat = "World",
            onChanged = function(val)
                if App.World and type(App.World.SetOpenAllDoors) == "function" then
                    pcall(App.World.SetOpenAllDoors, val)
                end
            end,
        })

        Admin.RegisterToggle({ "fencegod", "nofence" }, "FenceGodmode", "Fence Godmode", {
            offAliases = { "unfencegod", "unnofence" },
            cat = "World",
            onChanged = function(val)
                if App.World and type(App.World.SetFenceGodmode) == "function" then
                    pcall(App.World.SetFenceGodmode, val)
                end
            end,
        })

        Admin.RegisterToggle({ "esp" }, "ESPEnabled", "ESP", { cat = "Visuals" })
        Admin.RegisterToggle({ "espboxes", "chams", "espchams" }, "ESPBoxes", "ESP Boxes / Chams", { cat = "Visuals" })
        Admin.RegisterToggle({ "espteam", "esphideteam" }, "ESPHideTeam", "ESP Hide Teammates", { cat = "Visuals" })
        Admin.RegisterRange({ "espdist" }, "ESPMaxDistance", "ESPEnabled", "ESPMaxDistance", { cat = "Visuals", min = 100, max = 1200 })
        Admin.RegisterToggle({ "tracers", "bullettracers" }, "BulletTracers", "Bullet Tracers", { cat = "Visuals" })
        Admin.RegisterToggle({ "esptracers" }, "ESPTracers", "ESP Snaplines", { cat = "Visuals" })
        Admin.RegisterToggle({ "c4esp" }, "C4ESP", "C4 ESP", { cat = "Visuals" })
        Admin.RegisterToggle({ "killfeed" }, "ShowKillfeed", "Killfeed", { cat = "Visuals" })
        Admin.RegisterToggle({ "alerts" }, "ShowAlerts", "Alerts", { cat = "Visuals" })
    end

    App.Admin._RegMoveWorld = registerMoveAndWorld
end

-- ============================================================================
--  COMMAND REGISTRATIONS: SYSTEM, PROFILES, HUD & HELP
-- ============================================================================
do
    local function registerSystemCmds(Admin, H)
        local function httpGetJson(url)
            local raw = nil
            local errMsg = "HTTP unavailable"
            if game and game.HttpGet then
                local okG, resG = pcall(game.HttpGet, game, url)
                if okG and type(resG) == "string" and resG ~= "" then
                    raw = resG
                else
                    errMsg = tostring(resG or "HttpGet failed")
                end
            end
            if not raw then
                local reqFn = (GEN_ENV and (rawget(GEN_ENV, "request") or rawget(GEN_ENV, "http_request")))
                    or request
                    or http_request
                    or rawget(_G, "request")
                    or rawget(_G, "http_request")
                if type(reqFn) == "function" then
                    local okR, resp = pcall(reqFn, { Url = url, Method = "GET" })
                    if okR and type(resp) == "table" and type(resp.Body) == "string" then
                        raw = resp.Body
                    else
                        errMsg = tostring(resp or "request failed")
                    end
                end
            end
            if not raw and Services.HttpService and Services.HttpService.GetAsync then
                local okA, resA = pcall(Services.HttpService.GetAsync, Services.HttpService, url)
                if okA and type(resA) == "string" then
                    raw = resA
                else
                    errMsg = tostring(resA or "HttpService.GetAsync failed")
                end
            end
            if not raw then
                return nil, errMsg
            end
            local hs = Services.HttpService
            if not hs or type(hs.JSONDecode) ~= "function" then
                return nil, "HttpService.JSONDecode unavailable"
            end
            local okD, data = pcall(hs.JSONDecode, hs, raw)
            if not okD or type(data) ~= "table" then
                return nil, "Invalid JSON payload from server list API"
            end
            return data, nil
        end

        local function afterProfileChanged()
            if App.Combat and type(App.Combat.ApplyGunModsAll) == "function" then
                pcall(App.Combat.ApplyGunModsAll)
            end
            if App.World then
                if type(App.World.SetFenceGodmode) == "function" then
                    pcall(App.World.SetFenceGodmode, State.FenceGodmode)
                end
                if type(App.World.SetOpenAllDoors) == "function" then
                    pcall(App.World.SetOpenAllDoors, State.OpenAllDoors)
                end
                if type(App.World.SafeSetAntiFlingEnabled) == "function" then
                    pcall(App.World.SafeSetAntiFlingEnabled, State.AntiFling)
                end
            end
            if App.Shield and type(App.Shield.SetEnabled) == "function" then
                pcall(App.Shield.SetEnabled, State.ShieldEnabled)
            end
            if App.Hub and type(App.Hub.RefreshProfiles) == "function" then
                pcall(App.Hub.RefreshProfiles)
            end
            H.syncUI(true)
        end

        Admin._AfterProfileChanged = afterProfileChanged

        Admin.RegisterToggle({ "antiafk", "afk" }, "AntiAFK", "Anti-AFK", { cat = "System" })

        Admin.RegisterAction({ "rejoin", "rj" }, "Rejoin current server instance", function()
            local ts = Services.TeleportService
            local lp = H.getLP()
            local placeId = (App.Env and App.Env.PlaceId) or 0
            local jobId = (App.Env and App.Env.JobId) or ""
            if not ts or not lp or placeId == 0 or jobId == "" then
                return false, "Rejoin unavailable (missing TeleportService, PlaceId, or JobId)"
            end
            local okT, errT = pcall(ts.TeleportToPlaceInstance, ts, placeId, jobId, lp)
            if not okT then
                return false, "Rejoin failed: " .. tostring(errT)
            end
            return true, "Rejoining server..."
        end, { cat = "System", usage = "rejoin" })

        Admin.RegisterAction({ "serverhop", "hop" }, "Join another non-full public server", function(_, ctx)
            local ts = Services.TeleportService
            local lp = H.getLP()
            local placeId = (App.Env and App.Env.PlaceId) or 0
            local jobId = (App.Env and App.Env.JobId) or ""
            if not ts or not lp or placeId == 0 then
                return false, "ServerHop unavailable (missing TeleportService or PlaceId)"
            end
            local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
            return H.runAsync("Searching public servers...", ctx.continueChain, function()
                local data, errMsg = httpGetJson(url)
                if not data then
                    return false, "ServerHop failed: " .. tostring(errMsg)
                end
                local servers = type(data.data) == "table" and data.data or {}
                local picked = nil
                for _, srv in ipairs(servers) do
                    local sid = srv and srv.id
                    local pl = srv and tonumber(srv.playing)
                    local mp = srv and tonumber(srv.maxPlayers)
                    if sid and sid ~= jobId and pl and mp and pl < mp then
                        picked = sid
                        break
                    end
                end
                if not picked then
                    return false, "ServerHop: no open non-full server found"
                end
                local okT, errT = pcall(ts.TeleportToPlaceInstance, ts, placeId, picked, lp)
                if not okT then
                    return false, "ServerHop teleport failed: " .. tostring(errT)
                end
                return true, "Hopping to server " .. tostring(picked) .. "..."
            end)
        end, { cat = "System", usage = "serverhop" })

        Admin.RegisterAction({ "saveconfig", "save" }, "Save configuration profile", function(args)
            if not App.Persistence or type(App.Persistence.Save) ~= "function" then
                return false, "Persistence unavailable"
            end
            local name = args[1] or "default"
            local okCall, okSave, info = pcall(App.Persistence.Save, name)
            if not okCall then
                return false, "Save error: " .. tostring(okSave)
            end
            if not okSave then
                return false, "Save failed: " .. tostring(info)
            end
            if App.Hub and type(App.Hub.RefreshProfiles) == "function" then
                pcall(App.Hub.RefreshProfiles)
            end
            return true, "Saved profile '" .. tostring(name) .. "' (" .. tostring(info) .. ")"
        end, { cat = "Config", usage = "saveconfig [name]", argType = "profile" })

        Admin.RegisterAction({ "loadconfig", "load" }, "Load configuration profile", function(args)
            if not App.Persistence or type(App.Persistence.Load) ~= "function" then
                return false, "Persistence unavailable"
            end
            local name = args[1] or "default"
            local okCall, okLoad, info = pcall(App.Persistence.Load, name)
            if not okCall then
                return false, "Load error: " .. tostring(okLoad)
            end
            if not okLoad then
                return false, tostring(info or ("Profile not found: " .. tostring(name)))
            end
            afterProfileChanged()
            return true, "Loaded profile '" .. tostring(info or name) .. "'"
        end, { cat = "Config", usage = "loadconfig [name]", argType = "profile" })

        Admin.RegisterAction({ "resetconfig", "reset" }, "Reset all settings to defaults", function()
            if not App.Persistence or type(App.Persistence.Reset) ~= "function" then
                return false, "Persistence unavailable"
            end
            local okCall, okReset = pcall(App.Persistence.Reset)
            if not okCall or not okReset then
                return false, "Reset failed"
            end
            afterProfileChanged()
            return true, "All settings reset to defaults"
        end, { cat = "Config", usage = "resetconfig" })

        Admin.RegisterAction({ "configs", "profiles", "listconfigs" }, "List saved configuration profiles", function()
            if not App.Persistence or type(App.Persistence.List) ~= "function" then
                return false, "Persistence unavailable"
            end
            local okL, list = pcall(App.Persistence.List)
            if not okL or type(list) ~= "table" then
                return false, "Could not list profiles"
            end
            if #list == 0 then
                return true, "No saved profiles yet (run 'saveconfig default')"
            end
            return true, "Profiles (" .. tostring(#list) .. "): " .. table.concat(list, ", ")
        end, { cat = "Config", usage = "configs" })

        Admin.RegisterAction({ "preset" }, "Apply a built-in preset (legit|rage|mobile)", function(args)
            if not args[1] then
                return false, "Usage: preset <legit|rage|mobile>"
            end
            if not App.Persistence or type(App.Persistence.ApplyPreset) ~= "function" then
                return false, "Persistence unavailable"
            end
            local okCall, okPre, info = pcall(App.Persistence.ApplyPreset, args[1])
            if not okCall then
                return false, "Preset error: " .. tostring(okPre)
            end
            if not okPre then
                return false, tostring(info or "Unknown preset (use: legit, rage, mobile)")
            end
            afterProfileChanged()
            return true, "Applied preset '" .. tostring(info) .. "'"
        end, { cat = "Config", usage = "preset <legit|rage|mobile>", argChoices = { "legit", "rage", "mobile" } })

        Admin.RegisterAction({ "resethud" }, "Reset draggable HUD layout positions", function()
            if App.HUD and type(App.HUD.ResetLayoutPositions) == "function" then
                pcall(App.HUD.ResetLayoutPositions)
            else
                App.SetState("HUDPositions", {}, false, true)
            end
            H.syncUI()
            return true, "HUD positions reset"
        end, { cat = "HUD", usage = "resethud" })

        Admin.RegisterToggle({ "lockhud" }, "LockHUDLayout", "Lock HUD Layout", { offAliases = { "unlockhud" }, cat = "HUD" })

        Admin.RegisterAction({ "cmds", "help" }, "List commands or inspect a specific command", function(args, ctx)
            local q = args[1] and string.lower(H.trimStr(args[1])) or ""
            if q ~= "" then
                local exact = Admin.Aliases[q]
                if exact and (ctx.cmd == "help" or exact.cmd == q) then
                    return true, exact.cmd .. " [" .. exact.cat .. "] | usage: " .. exact.usage .. " | aliases: " .. table.concat(exact.aliases, ", ") .. " — " .. exact.desc
                end
                local matches = {}
                for _, e in ipairs(Admin.Registry) do
                    local hit = string.find(e.cmd, q, 1, true)
                        or string.find(string.lower(e.cat), q, 1, true)
                        or string.find(string.lower(e.desc), q, 1, true)
                    if not hit then
                        for _, al in ipairs(e.aliases) do
                            if string.find(al, q, 1, true) then
                                hit = true
                                break
                            end
                        end
                    end
                    if hit then
                        table.insert(matches, e.usage)
                    end
                end
                if #matches == 0 then
                    return false, "No commands matching '" .. q .. "'"
                end
                return true, "Matches (" .. tostring(#matches) .. "): " .. table.concat(matches, " | ")
            end

            local names = {}
            for _, e in ipairs(Admin.Registry) do
                table.insert(names, e.cmd)
            end
            return true, "KX Commands (" .. tostring(#names) .. "): " .. table.concat(names, ", ") .. " (run 'help <cmd>' or 'cmds <filter>')"
        end, { cat = "System", usage = "cmds [filter] / help [cmd]", argType = "cmd" })

        Admin.RegisterAction({ "clear", "cls", "clean" }, "Clear HUD command drawer and unstuck local character", function()
            if App.HUD and type(App.HUD.ClearCmdLog) == "function" then
                pcall(App.HUD.ClearCmdLog)
            end
            if App.Shield and type(App.Shield.CleanCharacterEffects) == "function" then
                pcall(App.Shield.CleanCharacterEffects)
            end
            if Admin._ClearSpectate then
                pcall(Admin._ClearSpectate)
            end
            return { ok = true, msg = "" }
        end, { cat = "System", usage = "clear" })

        Admin.RegisterAction({ "unload", "destroy" }, "Unload Prison Life 2026 KX Edition V3", function()
            local cleanupFn = rawget(GEN_ENV, "__PL_KX_Cleanup")
            if type(cleanupFn) ~= "function" then
                return false, "Cleanup handler missing"
            end
            task.defer(function()
                pcall(cleanupFn)
            end)
            return true, "Unloading KX Edition V3..."
        end, { cat = "System", usage = "unload" })
    end

    App.Admin._RegSystem = registerSystemCmds
end

-- ============================================================================
--  REGISTER COMMANDS + LIFECYCLE, KEYBINDS, CHAT, ANTI-AFK, STARTUP & CLEANUP
-- ============================================================================
do
    local Admin = App.Admin
    local H = Admin._Helpers
    if type(Admin._RegCombat) == "function" then
        Admin._RegCombat(Admin, H)
    end
    if type(Admin._RegShield) == "function" then
        Admin._RegShield(Admin, H)
    end
    if type(Admin._RegMoveWorld) == "function" then
        Admin._RegMoveWorld(Admin, H)
    end
    if type(Admin._RegSystem) == "function" then
        Admin._RegSystem(Admin, H)
    end

    local clearSpectate = Admin._ClearSpectate
    local afterProfileChanged = Admin._AfterProfileChanged

    -- Prune LoopKillTargets cleanly when a targeted player leaves (stepper lives in Module 3 Scheduler)
    if Services.Players and Services.Players.PlayerRemoving then
        Janitor.Add(Services.Players.PlayerRemoving:Connect(function(leftPlr)
            if not leftPlr or type(State.LoopKillTargets) ~= "table" then
                return
            end
            if State.LoopKillTargets[leftPlr.UserId] then
                local nextMap = App.DeepCopy(State.LoopKillTargets)
                nextMap[leftPlr.UserId] = nil
                App.SetState("LoopKillTargets", nextMap)
                H.emitOutput(true, "LoopKill removed (player left): " .. tostring(leftPlr.Name))
            end
        end))
    end

    -- ------------------------------------------------------------------------
    -- Dynamic Keybinds (reading live State.Keybinds) & Anti-AFK
    -- ------------------------------------------------------------------------
    local function keyMatches(inputKeyCode, binding)
        if not inputKeyCode or binding == nil then
            return false
        end
        local bStr = tostring(binding)
        if bStr == "" then
            return false
        end
        bStr = (bStr:gsub("^Enum%.KeyCode%.", ""))
        local bLow = string.lower(bStr)
        local keyName = string.lower(tostring(inputKeyCode.Name or ""))
        if keyName ~= "" and keyName == bLow then
            return true
        end
        if Enum and Enum.KeyCode then
            local okE, enumVal = pcall(function()
                return Enum.KeyCode[bStr]
            end)
            if okE and enumVal == inputKeyCode then
                return true
            end
        end
        return false
    end

    local uis = Services.UserInputService
    if uis and uis.InputBegan then
        Janitor.Add(uis.InputBegan:Connect(function(inp, gameProcessed)
            if not App.Running or gameProcessed then
                return
            end
            if uis.GetFocusedTextBox and uis:GetFocusedTextBox() ~= nil then
                return
            end
            local isRebinding = App.Hub and ((type(App.Hub.IsRebinding) == "function" and App.Hub.IsRebinding()) or App.Hub.IsRebinding == true)
            if isRebinding then
                return
            end
            local kb = type(State.Keybinds) == "table" and State.Keybinds or nil
            if not kb then
                return
            end
            local kc = inp and inp.KeyCode
            if not kc then
                return
            end

            if keyMatches(kc, kb.ToggleHub) or keyMatches(kc, kb.AltToggleHub) then
                local nextVis = not (State.HubVisible == true)
                if App.Hub and type(App.Hub.SetVisible) == "function" then
                    pcall(App.Hub.SetVisible, nextVis)
                else
                    App.SetState("HubVisible", nextVis)
                end
            elseif keyMatches(kc, kb.ToggleShield) then
                local nextShield = not (State.ShieldEnabled == true)
                if App.Shield and type(App.Shield.SetEnabled) == "function" then
                    pcall(App.Shield.SetEnabled, nextShield)
                else
                    App.SetState("ShieldEnabled", nextShield)
                end
                if App.Shield and type(App.Shield.NotifyShieldStateChanged) == "function" then
                    pcall(App.Shield.NotifyShieldStateChanged)
                end
                H.syncUI()
                H.emitAlert("Shield", nextShield and "Bullet Shield ON" or "Bullet Shield OFF", nextShield and "success" or "info")
            elseif keyMatches(kc, kb.Combo1) then
                if App.Weapons and type(App.Weapons.ExecuteCombo1) == "function" then
                    pcall(App.Weapons.ExecuteCombo1)
                end
            elseif keyMatches(kc, kb.ToggleRagebot) then
                local nextRage = not (State.Ragebot == true)
                App.SetState("Ragebot", nextRage)
                H.syncUI()
                H.emitAlert("Ragebot", nextRage and "Ragebot ON" or "Ragebot OFF", nextRage and "warn" or "info")
            elseif keyMatches(kc, kb.ToggleFly) then
                local nextFly = not (State.Fly == true)
                App.SetState("Fly", nextFly)
                if not nextFly and App.World and type(App.World.MobileFlyInput) == "table" then
                    App.World.MobileFlyInput.Up = 0
                    App.World.MobileFlyInput.Down = 0
                end
                H.syncUI()
                H.emitAlert("Fly", nextFly and "Fly ON" or "Fly OFF", "info")
            elseif keyMatches(kc, kb.ToggleNoclip) then
                local nextNc = not (State.Noclip == true)
                if nextNc and App.Shield and type(App.Shield.BypassClientAntiNoclip) == "function" then
                    pcall(App.Shield.BypassClientAntiNoclip, H.getChar(), true)
                elseif (not nextNc) and App.World and type(App.World.RestoreNoclipCollide) == "function" then
                    pcall(App.World.RestoreNoclipCollide)
                end
                App.SetState("Noclip", nextNc)
                H.syncUI()
                H.emitAlert("Noclip", nextNc and "Noclip ON" or "Noclip OFF", "info")
            elseif keyMatches(kc, kb.FocusCmdBar) then
                if App.HUD and type(App.HUD.FocusCmdBar) == "function" then
                    task.defer(App.HUD.FocusCmdBar)
                end
            end
        end))
    end

    -- Anti-AFK listener
    local lp = H.getLP()
    if lp and lp.Idled then
        Janitor.Add(lp.Idled:Connect(function()
            if not App.Running or not State.AntiAFK then
                return
            end
            local vu = Services.VirtualUser
            if vu then
                pcall(function()
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end
        end))
    end

    -- ------------------------------------------------------------------------
    -- Optional Chat Command Listener (gated by State.ChatCommands + prefix)
    -- ------------------------------------------------------------------------
    local lastChatText = ""
    local lastChatClock = -10
    local function handleIncomingChat(rawText)
        if not App.Running or not State.ChatCommands then
            return
        end
        local trimmed = H.trimStr(rawText or "")
        if not string.match(trimmed, "^[-;/!%.]") then
            return
        end
        local now = os.clock()
        if trimmed == lastChatText and (now - lastChatClock) < 0.25 then
            return
        end
        lastChatText = trimmed
        lastChatClock = now
        Admin.ExecuteLine(trimmed)
    end

    if lp and lp.Chatted then
        Janitor.Add(lp.Chatted:Connect(function(msgText)
            handleIncomingChat(msgText)
        end))
    end

    local tcs = Services.TextChatService
    if tcs and tcs.MessageReceived then
        Janitor.Add(tcs.MessageReceived:Connect(function(msgObj)
            if not msgObj or not lp then
                return
            end
            local src = msgObj.TextSource
            if not src or src.UserId ~= lp.UserId then
                return
            end
            handleIncomingChat(msgObj.Text)
        end))
    end

    -- ------------------------------------------------------------------------
    -- Character Respawn Lifecycle (Scoped CharacterJanitor -> Zero Leak)
    -- ------------------------------------------------------------------------
    local CharacterJanitor = Janitor.NewScope()
    local respawnSerial = 0

    local function applyToolDeferred(child)
        if App.Running and App.Combat and type(App.Combat.ApplyGunModsToTool) == "function" then
            task.defer(App.Combat.ApplyGunModsToTool, child)
        end
    end

    local function bindContainerMods(container)
        if container and container.ChildAdded then
            CharacterJanitor:Add(container.ChildAdded:Connect(applyToolDeferred))
        end
    end

    local function OnLocalCharacterAdded(char)
        if not char or not App.Running then
            return
        end
        respawnSerial = respawnSerial + 1
        local mySerial = respawnSerial
        CharacterJanitor:Clean()

        CharacterJanitor:Spawn(function()
            task.wait(0.35)
            local curLP = H.getLP()
            if not App.Running or mySerial ~= respawnSerial or not curLP or curLP.Character ~= char then
                return
            end

            if App.Combat then
                if type(App.Combat.SetupGunControllerHooks) == "function" then
                    pcall(App.Combat.SetupGunControllerHooks)
                end
                if type(App.Combat.ApplyGunModsAll) == "function" then
                    pcall(App.Combat.ApplyGunModsAll)
                end
                if type(App.Combat.UpdateCastRayFilter) == "function" then
                    pcall(App.Combat.UpdateCastRayFilter)
                end
            end

            if App.Shield then
                if (State.AntiJumpCooldown or State.MaxSpeed or State.JumpPowerEnabled or State.InfiniteJump)
                    and type(App.Shield.BypassAntiJump) == "function" then
                    pcall(App.Shield.BypassAntiJump, char, true)
                end
                if (State.Noclip or State.MaxSpeed) and type(App.Shield.BypassClientAntiNoclip) == "function" then
                    pcall(App.Shield.BypassClientAntiNoclip, char, true)
                end
                if type(App.Shield.InstallAntiTaze) == "function" then
                    pcall(App.Shield.InstallAntiTaze)
                end
                if (State.FEInvisible or (State.ShieldEnabled and State.ShieldMode == "FEGhost"))
                    and type(App.Shield.StartFEInvisible) == "function" then
                    pcall(App.Shield.StartFEInvisible)
                end
            end

            if State.AutoGetGuns and App.Weapons and type(App.Weapons.GrabWeapons) == "function" then
                local teams = Services.Teams
                local neutral = teams and teams:FindFirstChild("Neutral") or nil
                if not neutral or curLP.Team ~= neutral then
                    pcall(App.Weapons.GrabWeapons, State.AutoGunsSelection, true)
                end
            end

            bindContainerMods(char)
            local bp = curLP:FindFirstChildOfClass("Backpack")
            if bp then
                bindContainerMods(bp)
            else
                CharacterJanitor:Add(curLP.ChildAdded:Connect(function(child)
                    if child and child:IsA("Backpack") then
                        bindContainerMods(child)
                    end
                end))
            end
        end)
    end

    App.Lifecycle = {
        CharacterJanitor = CharacterJanitor,
        OnLocalCharacterAdded = OnLocalCharacterAdded,
    }

    -- ------------------------------------------------------------------------
    -- Deterministic Cleanup & Idempotent Shutdown
    -- ------------------------------------------------------------------------
    local teardownDone = false
    local function teardownAll()
        if teardownDone then
            return
        end
        teardownDone = true

        -- Disable loop/flag states & stop scheduler/visuals while teardown helpers still operate cleanly
        State.HitboxExpander = false
        State.JumpPowerEnabled = false
        State.MaxSpeed = false
        State.Fly = false
        State.VehicleFly = false
        State.KillAura = false
        State.Ragebot = false
        if App.World and type(App.World.MobileFlyInput) == "table" then
            App.World.MobileFlyInput.Up = 0
            App.World.MobileFlyInput.Down = 0
        end

        if App.Scheduler and type(App.Scheduler.Stop) == "function" then
            pcall(App.Scheduler.Stop)
        end

        -- Restore camera / view target
        if clearSpectate then
            pcall(clearSpectate)
        end

        -- Disable Shield (explicit FireServer(false) fallback included) & FEInvisible
        if App.Shield then
            if type(App.Shield.SetEnabled) == "function" then
                pcall(App.Shield.SetEnabled, false)
            end
            if type(App.Shield.SetFEInvisible) == "function" then
                pcall(App.Shield.SetFEInvisible, false)
            elseif type(App.Shield.StopFEInvisible) == "function" then
                pcall(App.Shield.StopFEInvisible)
            end
            if type(App.Shield.RestoreAntiTaze) == "function" then
                pcall(App.Shield.RestoreAntiTaze)
            end
            if type(App.Shield.BypassAntiJump) == "function" then
                pcall(App.Shield.BypassAntiJump, nil, false)
            end
            if type(App.Shield.BypassClientAntiNoclip) == "function" then
                pcall(App.Shield.BypassClientAntiNoclip, nil, false)
            end
            if type(App.Shield.DestroyVisual) == "function" then
                pcall(App.Shield.DestroyVisual)
            end
        end
        if App.Remotes and App.Remotes.ShieldEquipped and App.Remotes.ShieldEquipped.FireServer then
            pcall(App.Remotes.ShieldEquipped.FireServer, App.Remotes.ShieldEquipped, false)
        end

        -- Restore world / doors / fence / fling / noclip / ESP / hitboxes / hooks
        if App.World then
            if type(App.World.SafeSetAntiFlingEnabled) == "function" then
                pcall(App.World.SafeSetAntiFlingEnabled, false)
            end
            if type(App.World.SetFenceGodmode) == "function" then
                pcall(App.World.SetFenceGodmode, false)
            end
            if type(App.World.SetOpenAllDoors) == "function" then
                pcall(App.World.SetOpenAllDoors, false)
            end
            if type(App.World.RestoreNoclipCollide) == "function" then
                pcall(App.World.RestoreNoclipCollide)
            end
            if type(App.World.CleanupFly) == "function" then
                pcall(App.World.CleanupFly)
            end
            if type(App.World.RestoreSeats) == "function" then
                pcall(App.World.RestoreSeats)
            end
        end

        if App.Visuals then
            if type(App.Visuals.UpdateHitboxExpander) == "function" then
                pcall(App.Visuals.UpdateHitboxExpander)
            end
            if type(App.Visuals.RemoveAllESP) == "function" then
                pcall(App.Visuals.RemoveAllESP)
            end
        end

        if App.Combat then
            if type(App.Combat.RestoreGunMods) == "function" then
                pcall(App.Combat.RestoreGunMods)
            end
            if type(App.Combat.RestoreHooks) == "function" then
                pcall(App.Combat.RestoreHooks)
            end
        end
        if App.VFX and type(App.VFX.RestoreGunTracers) == "function" then
            pcall(App.VFX.RestoreGunTracers)
        end
        if App.Anim and type(App.Anim.CleanupAll) == "function" then
            pcall(App.Anim.CleanupAll)
        end

        CharacterJanitor:Clean()
        App.Running = false
        GEN_ENV.__PL_KX_Running = false
        GEN_ENV.__PL_KX_BulletHandler = nil
        GEN_ENV.__PL_KX_TaseHandler = nil
        GEN_ENV.__PL_KX_Cleanup = nil
    end

    Janitor.AddCleanup(teardownAll)
    GEN_ENV.__PL_KX_Cleanup = function()
        teardownAll()
        if type(Janitor.CleanupAll) == "function" then
            pcall(Janitor.CleanupAll)
        end
        GEN_ENV.__PL_KX_Running = false
        GEN_ENV.__PL_KX_Cleanup = nil
    end

    -- ------------------------------------------------------------------------
    -- Startup Sequence & Bus Listeners
    -- ------------------------------------------------------------------------
    local function tryStart(label, fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then
            pcall(warn, "[KX V3 Start] " .. label .. " failed: " .. tostring(err))
        end
        return ok
    end

    Bus.On("ProfileLoaded", afterProfileChanged)
    Bus.On("ProfileReset", afterProfileChanged)
    Bus.On("PresetApplied", afterProfileChanged)

    if App.Persistence and type(App.Persistence.AutoLoad) == "function" and State.AutoLoadConfig then
        tryStart("Persistence.AutoLoad", App.Persistence.AutoLoad, "default")
    end

    if lp then
        if lp.Character then
            tryStart("OnLocalCharacterAdded", OnLocalCharacterAdded, lp.Character)
        end
        if lp.CharacterAdded then
            Janitor.Add(lp.CharacterAdded:Connect(OnLocalCharacterAdded))
        end
    end

    if App.Scheduler and type(App.Scheduler.Start) == "function" then
        local okSched, errSched = pcall(App.Scheduler.Start)
        if not okSched then
            pcall(warn, "[KX V3] Scheduler.Start failed: " .. tostring(errSched))
            H.emitAlert("Scheduler", "Start error: " .. tostring(errSched), "danger")
        end
    end
    if App.Combat then
        if type(App.Combat.SetupGunControllerHooks) == "function" then
            tryStart("Combat.SetupGunControllerHooks", App.Combat.SetupGunControllerHooks)
        end
        if type(App.Combat.ApplyGunModsAll) == "function" then
            tryStart("Combat.ApplyGunModsAll", App.Combat.ApplyGunModsAll)
        end
        if type(App.Combat.ApplyAntiRiotShield) == "function" and State.AntiRiotShield then
            tryStart("Combat.ApplyAntiRiotShield", App.Combat.ApplyAntiRiotShield, true)
        end
    end
    if App.VFX and type(App.VFX.HookGunTracers) == "function" then
        tryStart("VFX.HookGunTracers", App.VFX.HookGunTracers)
    end
    if App.Shield and type(App.Shield.InstallAntiTaze) == "function" then
        tryStart("Shield.InstallAntiTaze", App.Shield.InstallAntiTaze)
    end
    if App.World then
        if type(App.World.SetFenceGodmode) == "function" then
            tryStart("World.SetFenceGodmode", App.World.SetFenceGodmode, State.FenceGodmode)
        end
        if type(App.World.SetOpenAllDoors) == "function" then
            tryStart("World.SetOpenAllDoors", App.World.SetOpenAllDoors, State.OpenAllDoors)
        end
        if type(App.World.SafeSetAntiFlingEnabled) == "function" then
            tryStart("World.SafeSetAntiFlingEnabled", App.World.SafeSetAntiFlingEnabled, State.AntiFling)
        end
    end
    if State.ShieldEnabled and App.Shield and type(App.Shield.SetEnabled) == "function" then
        tryStart("Shield.SetEnabled", App.Shield.SetEnabled, true)
    end
    if State.HitboxExpander and App.Visuals and type(App.Visuals.UpdateHitboxExpander) == "function" then
        tryStart("Visuals.UpdateHitboxExpander", App.Visuals.UpdateHitboxExpander)
    end

    if App.HUD then
        if type(App.HUD.RefreshCommandBrowser) == "function" then
            tryStart("HUD.RefreshCommandBrowser", App.HUD.RefreshCommandBrowser)
        end
        if type(App.HUD.UpdateBadges) == "function" then
            tryStart("HUD.UpdateBadges", App.HUD.UpdateBadges, true)
        end
    end
    if App.Hub then
        if type(App.Hub.SyncHub) == "function" then
            tryStart("Hub.SyncHub", App.Hub.SyncHub, true)
        end
        if type(App.Hub.RefreshProfiles) == "function" then
            tryStart("Hub.RefreshProfiles", App.Hub.RefreshProfiles)
        end
    end

    H.emitAlert("Prison Life 2026", "KX Edition V3 Ready", "info")
end
