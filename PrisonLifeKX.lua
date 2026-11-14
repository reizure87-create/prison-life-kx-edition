--[=[
    Prison Life 2026 — KX Edition (PC & Mobile)
    PlaceId: 155615604
    Features:
      - Bullet-Blocking 3D Shield (RiotShieldPart Auto-Face Block + Universal Desync/Ghost/Car Shield Cube)
      - 2026 GunController Bullet Hook (Silent Aim + Ragebot Auto-Fire + Wallbang Scanner + Gun Mods)
      - Melee KillAura (meleeEvent), Hitbox Expander, Character Fly (PC + Mobile) & JumpPower Bypass
      - .combo1 Quick-Swap Burst Macro, Draggable KX Crest & 3 Mobile/PC Right-Side Action Buttons
      - KX ADMIN Top-Right Command Bar (55+ live commands + chaining + player matching)
      - Real Heuristic Cheater & Car-Teleport Alert Banner ([Alert] <User> Possible Car Teleport User)
      - Bottom-Center Streak & [RAGEBOT] Killfeed + Shield HP Mirror Badge
      - Self-Contained Dark Obsidian / Neon-Blue Draggable Hub UI (Zero External Dependencies)
      - Auto-Arrest, Anti-Taze, Auto-Armor, Auto-Heal, Fast Respawn, Car Spawner, Vehicle Fly, ESP, Tracers
]=]

-- ============================================================================
-- // SECTION 0: CLEANUP REGISTRY & ENVIRONMENT CAPABILITIES
-- ============================================================================
local GEN_ENV = (getgenv and getgenv()) or _G

if type(GEN_ENV.__PL_KX_Cleanup) == "function" then
    pcall(GEN_ENV.__PL_KX_Cleanup)
end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams             = game:GetService("Teams")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    Players.PlayerAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local HasGetConnections = (type(getconnections) == "function")
local HasHookFunction   = (type(hookfunction) == "function")
local HasDebugUpvalue   = (debug and type(debug.getupvalue) == "function")
local HasRestoreFunc    = (type(restorefunction) == "function")

local ActiveConnections = {}
local TrackedInstances  = {}
local BoundRenderSteps  = {}
local Running           = true

GEN_ENV.__PL_KX_Running = true

local function AddConnection(conn)
    if conn then
        if #ActiveConnections > 220 then
            for i = #ActiveConnections, 1, -1 do
                local c = ActiveConnections[i]
                local okC, alive = pcall(function() return c.Connected end)
                if okC and alive == false then
                    table.remove(ActiveConnections, i)
                end
            end
        end
        table.insert(ActiveConnections, conn)
    end
    return conn
end

local function TrackInstance(inst)
    if inst then
        table.insert(TrackedInstances, inst)
    end
    return inst
end

local function SafeBindRenderStep(name, priority, fn)
    pcall(function() RunService:UnbindFromRenderStep(name) end)
    if not table.find(BoundRenderSteps, name) then
        table.insert(BoundRenderSteps, name)
    end
    RunService:BindToRenderStep(name, priority, fn)
end

local function SafeUnbindRenderStep(name)
    pcall(function() RunService:UnbindFromRenderStep(name) end)
end

local function GetSafeGuiParent()
    if type(gethui) == "function" then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local okCore = pcall(function()
        local _ = CoreGui.Name
    end)
    if okCore then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui", 10) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local function TrimString(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function GetCamera()
    return Workspace.CurrentCamera
end

local function GetCharacter(plr)
    return plr and plr.Character
end

local function GetRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

local function GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- ============================================================================
-- // SECTION 1: CENTRALIZED STATE & COLOR PALETTE
-- ============================================================================
local State = {
    -- Hub & HUD Visibility
    HubVisible        = false,
    ShowComboButton   = true,
    ShowKXBar         = true,
    ShowRightActions  = true,
    ShowKillfeed      = true,
    ShowAlerts        = true,
    ShowShieldBadge   = true,

    -- Bullet-Blocking Shield
    ShieldEnabled          = false,
    ShieldMode             = "Hybrid",   -- "Hybrid" (RiotShield + Desync), "RiotOnly", "DesyncBox", "FEGhost"
    ShieldBoxSize          = 10.5,
    ShieldBoxTransparency  = 0.65,
    ShieldAutoFaceShooter  = true,
    ShieldAutoEquipOnIdle  = true,
    ShieldSpinBlock        = false,
    ShieldSpinSpeed        = 45,
    ShieldDesyncStrength   = 3.2,
    AntiRiotShield         = false,      -- Sets enemy RiotShieldPart.CanQuery = false
    VehicleWallbang        = false,      -- Shoot through Workspace.CarContainer

    -- Combat: Silent Aim & Ragebot
    SilentAim          = true,
    SilentAimFOV       = 110,
    SilentAimShowFOV   = true,
    SilentAimAimPart   = "Head",         -- "Head" or "HumanoidRootPart"
    SilentAimHitChance = 100,
    SilentAimHeadChance= 90,
    SilentAimWallcheck = true,
    SilentAimWallbang  = false,
    SilentAimTeamCheck = true,
    SilentAimHostile   = true,
    SilentAimSkipDown  = true,

    Ragebot            = false,
    Ragebot360         = true,           -- Ignore FOV circle in Ragebot mode
    RagebotAutoSwitch  = true,           -- Swap between loaded guns for max fire rate
    RagebotPeekShield  = true,           -- Re-equip Riot Shield when no target is visible
    RagebotRate        = 18,             -- Attempts per second

    AimAssist          = false,
    AimAssistFOV       = 140,
    AimAssistSmooth    = 0.25,

    -- .combo1 Macro
    ComboLoop          = false,
    ComboLoopInterval  = 0.28,
    ComboAutoGrabGuns  = true,
    ComboEndWithShield = true,

    -- Weapons & Gun Mods
    GunMods            = true,
    GunFireRateSPS     = 20,
    GunNoSpread        = true,
    GunFullAuto        = true,
    GunInfiniteRange   = true,
    AutoReload         = true,
    AutoGetGuns        = false,
    AutoGunsSelection  = { "Remington 870", "M4A1", "AK-47", "MP5" },
    AutoPickupDropped  = false,
    AutoArmor          = false,
    AutoHeal           = false,
    AutoHealThreshold  = 80,

    -- Prison & Utility
    AutoArrest         = false,
    AutoArrestRange    = 7.5,
    AutoTaze           = false,
    AntiTase           = true,
    AutoCriminal       = false,
    FastRespawn        = false,
    KeepPosOnRespawn   = true,
    OpenAllDoors       = false,
    FenceGodmode       = true,
    AntiKillPlane      = true,
    AutoDetonateC4     = false,

    -- Vehicles & World
    AntiFling          = true,
    VehicleFly         = false,
    VehicleFlySpeed    = 85,
    VehicleSpeedMod    = false,
    VehicleSpeedMult   = 2.2,
    VehicleFling       = false,

    -- Movement & Defense
    MaxSpeed           = false,
    MaxSpeedMode       = "RegionSafe",   -- "RegionSafe" or "Custom"
    CustomWalkSpeed    = 44,
    AlwaysSprint       = false,
    AntiJumpCooldown   = false,
    InfiniteJump       = false,
    Noclip             = false,
    FEInvisible        = false,
    AntiInvisible      = true,

    -- Cheater Detector Alerts
    CheaterAlerts      = true,
    CarTPAlerts        = true,
    AlertDuration      = 5.0,

    -- Visuals / ESP / Tracers
    ESP                = true,
    ESPChams           = true,
    ESPNames           = true,
    ESPHealthBar       = true,
    ESPDiamondMarker   = true,
    ESPDistance        = true,
    ESPHideTeam        = false,
    C4ESP              = true,
    BulletTracers      = true,

    -- Melee KillAura, Fly, JumpPower & Hitbox Expander
    KillAura            = false,
    KillAuraRange       = 12,
    KillAuraRate        = 10,
    KillAuraTeamCheck   = true,
    KillAuraHostileOnly = true,
    Fly                 = false,
    FlySpeed            = 70,
    JumpPowerEnabled    = false,
    CustomJumpPower     = 75,
    HitboxExpander      = false,
    HitboxSize          = 8,
    HitboxTeamCheck     = true,
}

local Palette = {
    BgDark       = Color3.fromRGB(13, 16, 23),
    BgPanel      = Color3.fromRGB(20, 25, 36),
    BgCard       = Color3.fromRGB(26, 32, 46),
    BgInput      = Color3.fromRGB(16, 20, 29),
    NeonBlue     = Color3.fromRGB(48, 162, 255),
    NeonCyan     = Color3.fromRGB(70, 220, 255),
    TextPrimary  = Color3.fromRGB(242, 245, 252),
    TextMuted    = Color3.fromRGB(154, 166, 188),
    ToggleOn     = Color3.fromRGB(48, 162, 255),
    ToggleOff    = Color3.fromRGB(48, 55, 72),
    RedAlert     = Color3.fromRGB(255, 68, 72),
    RageCrimson  = Color3.fromRGB(225, 48, 58),
    StreakGold   = Color3.fromRGB(255, 214, 70),
    ShieldGrey   = Color3.fromRGB(72, 74, 82),
    GuardBlue    = Color3.fromRGB(75, 145, 255),
    InmateOrange = Color3.fromRGB(255, 145, 55),
    CrimRed      = Color3.fromRGB(255, 75, 75),
    NeutralGrey  = Color3.fromRGB(200, 205, 215),
}

-- ============================================================================
-- // SECTION 2: VERIFIED 2026 PRISON LIFE REMOTES & GAME HELPERS
-- ============================================================================
local Remotes = {}
local GunRemotes = {}
local GunHook = {
    Ready = false,
    IsBulletHooked = false,
    IsEquipHooked = false,
    Shoot = nil,
    Reload = nil,
    Bullet = nil,
    Equip = nil,
    OldBullet = nil,
    OldEquip = nil,
    CastRayParams = nil,
    PlaySound = nil,
    CurrentTargetPart = nil,
    LastRageShotClock = 0,
    LastShotWasRage = false,
    RageTargetPart = nil,
}

local function RefreshRemotes()
    local rf = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 8)
    if rf then
        Remotes.RequestTeamChange      = rf:FindFirstChild("RequestTeamChange")
        Remotes.GiverPressed           = rf:FindFirstChild("GiverPressed")
        Remotes.InteractWithItem       = rf:FindFirstChild("InteractWithItem")
        Remotes.TouchGiver             = rf:FindFirstChild("TouchGiver")
        Remotes.ArrestPlayer           = rf:FindFirstChild("ArrestPlayer")
        Remotes.ShootEvent             = rf:FindFirstChild("ShootEvent")
        Remotes.ShieldEquipped         = rf:FindFirstChild("ShieldEquipped")
        Remotes.EatFood                = rf:FindFirstChild("EatFood")
        Remotes.SnackEaten             = rf:FindFirstChild("SnackEaten")
        Remotes.RequestHere            = rf:FindFirstChild("RequestHere")
        Remotes.ClientArrested         = rf:FindFirstChild("ClientArrested")
        Remotes.MessageReceived        = rf:FindFirstChild("MessageReceived")
        Remotes.RequestCollisionChange = rf:FindFirstChild("RequestCollisionChange")
        Remotes.UpdateSetting          = rf:FindFirstChild("UpdateSetting")
        local c4Folder = rf:FindFirstChild("C4")
        if c4Folder then
            Remotes.ActivateC4 = c4Folder:FindFirstChild("ActivateC4")
        end
    end
    Remotes.MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
    local gr = ReplicatedStorage:FindFirstChild("GunRemotes")
    if gr then
        GunRemotes.PlayerTased = gr:FindFirstChild("PlayerTased")
        GunRemotes.ShootEvent  = gr:FindFirstChild("ShootEvent")
        GunRemotes.Reload      = gr:FindFirstChild("Reload")
        GunRemotes.TasePlayer  = gr:FindFirstChild("TasePlayer")
    end
end
RefreshRemotes()

local function GetTeamColor(plr)
    if not plr then return Palette.NeutralGrey end
    local teamName = plr.Team and plr.Team.Name or ""
    if teamName == "Guards" then
        return Palette.GuardBlue
    elseif teamName == "Criminals" then
        return Palette.CrimRed
    elseif teamName == "Inmates" then
        local ch = plr.Character
        if ch and (ch:GetAttribute("Hostile") or ch:GetAttribute("Trespassing")) then
            return Color3.fromRGB(255, 100, 65)
        end
        return Palette.InmateOrange
    end
    return (plr.TeamColor and plr.TeamColor.Color) or Palette.NeutralGrey
end

local function IsValidCombatTarget(plr, requireHostileInmate)
    if not plr or plr == LocalPlayer then return false end
    local neutralTeam = Teams:FindFirstChild("Neutral")
    if not plr.Team or plr.Team == neutralTeam then return false end

    local char = plr.Character
    if not char then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end

    local hum = GetHumanoid(char)
    if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
        return false
    end

    if State.SilentAimSkipDown and (char:GetAttribute("Downed") or char:GetAttribute("Arrested")) then
        return false
    end

    if State.SilentAimTeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
        return false
    end

    if requireHostileInmate and LocalPlayer.Team == Teams:FindFirstChild("Guards") and plr.Team == Teams:FindFirstChild("Inmates") then
        if not (char:GetAttribute("Hostile") or char:GetAttribute("Trespassing")) then
            return false
        end
    end

    return true
end

local WallRayParams = RaycastParams.new()
WallRayParams.FilterType = Enum.RaycastFilterType.Exclude
WallRayParams.IgnoreWater = true
pcall(function()
    WallRayParams.CollisionGroup = "ClientBullet"
end)

local function GetIgnoredWallbangInstances(extraTargetChar)
    local myChar = LocalPlayer.Character
    local list = {}
    if myChar then table.insert(list, myChar) end
    if extraTargetChar then table.insert(list, extraTargetChar) end
    local cam = GetCamera()
    if cam then table.insert(list, cam) end
    if State.VehicleWallbang then
        local cc = Workspace:FindFirstChild("CarContainer")
        if cc then table.insert(list, cc) end
    end
    if State.OpenAllDoors then
        local doors = Workspace:FindFirstChild("Doors")
        if doors then table.insert(list, doors) end
    end
    if GEN_ENV.__PL_KX_ShieldBoxPart then
        table.insert(list, GEN_ENV.__PL_KX_ShieldBoxPart)
    end
    return list
end

local function HasLineOfSight(originPos, targetPart, targetChar)
    if not originPos or not targetPart then return false end
    WallRayParams.FilterDescendantsInstances = GetIgnoredWallbangInstances(targetChar)
    local dir = targetPart.Position - originPos
    local hit = Workspace:Raycast(originPos, dir, WallRayParams)
    return hit == nil
end

local function FindWallbangOrigin(basePos, targetPos, targetChar)
    if not State.SilentAimWallbang or not basePos then return nil end
    WallRayParams.FilterDescendantsInstances = GetIgnoredWallbangInstances(targetChar)
    local offsets = {
        Vector3.new(0, 3.2, 0),
        Vector3.new(3.2, 1.5, 0),
        Vector3.new(-3.2, 1.5, 0),
        Vector3.new(0, 1.5, 3.2),
        Vector3.new(0, 1.5, -3.2),
        Vector3.new(4.8, 3.0, 4.8),
        Vector3.new(-4.8, 3.0, -4.8),
    }
    for _, off in ipairs(offsets) do
        local cand = basePos + off
        if Workspace:Raycast(basePos, cand - basePos, WallRayParams) == nil then
            if Workspace:Raycast(cand, targetPos - cand, WallRayParams) == nil then
                return cand
            end
        end
    end
    return nil
end

-- Deterministic target selector used by scanning/AimAssist (no 60Hz jitter)
local function PickTargetAimPart(char, forceHead)
    if not char then return nil end
    local wantHead = forceHead or (State.SilentAimAimPart == "Head" and State.SilentAimHeadChance > 0)
    if wantHead then
        return char:FindFirstChild("Head") or GetRoot(char)
    end
    return GetRoot(char) or char:FindFirstChild("Head")
end

-- Per-bullet headshot roll invoked once per fired projectile inside BulletHandler
local function PickShotTargetPart(char, forceHead)
    if not char then return nil end
    local wantHead = forceHead or (State.SilentAimAimPart == "Head" and math.random(1, 100) <= State.SilentAimHeadChance)
    if wantHead then
        return char:FindFirstChild("Head") or GetRoot(char)
    end
    return GetRoot(char) or char:FindFirstChild("Head")
end

local function GetCursorOrCenterPos()
    local cam = GetCamera()
    if not cam then return Vector2.new(0, 0) end
    if not IsMobile and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        local m = UserInputService:GetMouseLocation()
        return Vector2.new(m.X, m.Y)
    end
    return Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
end

local function GetBestTarget(maxFOV, use360, wallcheck, requireHostile, forceHead)
    local cam = GetCamera()
    local myChar = LocalPlayer.Character
    local myHead = myChar and (myChar:FindFirstChild("Head") or GetRoot(myChar))
    if not cam or not myHead then return nil, nil, nil end

    local center = GetCursorOrCenterPos()
    local bestScore = math.huge
    local bestPart, bestPlr, bestOrigin = nil, nil, nil

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidCombatTarget(plr, requireHostile) then
            local char = plr.Character
            local part = PickTargetAimPart(char, forceHead)
            if part then
                local dist3D = (part.Position - myHead.Position).Magnitude
                if dist3D <= 1400 then
                    local okVis = true
                    local shotOrigin = myHead.Position
                    if wallcheck then
                        okVis = HasLineOfSight(myHead.Position, part, char)
                        if not okVis and State.SilentAimWallbang then
                            local wb = FindWallbangOrigin(myHead.Position, part.Position, char)
                            if wb then
                                okVis = true
                                shotOrigin = wb
                            end
                        end
                    end
                    if okVis then
                        if use360 then
                            if dist3D < bestScore then
                                bestScore = dist3D
                                bestPart = part
                                bestPlr = plr
                                bestOrigin = shotOrigin
                            end
                        else
                            local screenPt, onScreen = cam:WorldToViewportPoint(part.Position)
                            if onScreen and screenPt.Z > 0 then
                                local fovDist = (Vector2.new(screenPt.X, screenPt.Y) - center).Magnitude
                                if fovDist <= maxFOV and fovDist < bestScore then
                                    bestScore = fovDist
                                    bestPart = part
                                    bestPlr = plr
                                    bestOrigin = shotOrigin
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPart, bestPlr, bestOrigin
end

local function SpawnBulletTracerBeam(originPos, hitPos, color)
    if not State.BulletTracers or not originPos or not hitPos then return end
    task.spawn(function()
        local dist = (hitPos - originPos).Magnitude
        if dist < 0.5 or dist > 2500 then return end
        local p = Instance.new("Part")
        p.Name = "PLKX_Tracer"
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = color or Palette.StreakGold
        p.Size = Vector3.new(0.11, 0.11, dist)
        p.CFrame = CFrame.lookAt(originPos, hitPos) * CFrame.new(0, 0, -dist * 0.5)
        p.Parent = Workspace
        TweenService:Create(p, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1,
            Size = Vector3.new(0.02, 0.02, dist),
        }):Play()
        task.delay(0.26, function()
            if p and p.Parent then p:Destroy() end
        end)
    end)
end

-- ============================================================================
-- // SECTION 3: 2026 GUNCONTROLLER HOOKS & MODIFICATIONS
-- ============================================================================
local OriginalGunData = setmetatable({}, { __mode = "k" })

local function ApplyGunModsToTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    if tool:GetAttribute("ToolType") ~= "Gun" and not tool:GetAttribute("FireRate") then return end
    if tool.Name == "Taser" then return end

    pcall(function()
        if not OriginalGunData[tool] then
            OriginalGunData[tool] = {
                FireRate      = tool:GetAttribute("FireRate"),
                SpreadRadius  = tool:GetAttribute("SpreadRadius"),
                AutoFire      = tool:GetAttribute("AutoFire"),
                Range         = tool:GetAttribute("Range"),
                AccurateRange = tool:GetAttribute("AccurateRange"),
            }
        end
        local orig = OriginalGunData[tool]
        if State.GunMods then
            tool:SetAttribute("FireRate", 1 / math.max(1, State.GunFireRateSPS))
            if State.GunNoSpread then
                tool:SetAttribute("SpreadRadius", 0)
            elseif orig and orig.SpreadRadius then
                tool:SetAttribute("SpreadRadius", orig.SpreadRadius)
            end
            if State.GunFullAuto then
                tool:SetAttribute("AutoFire", true)
            elseif orig and orig.AutoFire ~= nil then
                tool:SetAttribute("AutoFire", orig.AutoFire)
            end
            if State.GunInfiniteRange then
                tool:SetAttribute("Range", 9999)
                tool:SetAttribute("AccurateRange", 9999)
            elseif orig and orig.Range then
                tool:SetAttribute("Range", orig.Range)
                tool:SetAttribute("AccurateRange", orig.AccurateRange or orig.Range)
            end
        elseif orig then
            if orig.FireRate then tool:SetAttribute("FireRate", orig.FireRate) end
            if orig.SpreadRadius then tool:SetAttribute("SpreadRadius", orig.SpreadRadius) end
            if orig.AutoFire ~= nil then tool:SetAttribute("AutoFire", orig.AutoFire) end
            if orig.Range then tool:SetAttribute("Range", orig.Range) end
            if orig.AccurateRange then tool:SetAttribute("AccurateRange", orig.AccurateRange) end
        end
    end)
end

local function ApplyGunModsAll()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            ApplyGunModsToTool(t)
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            ApplyGunModsToTool(t)
        end
    end
end

local function UpdateCastRayFilter()
    if not GunHook.CastRayParams then return end
    pcall(function()
        local filter = { LocalPlayer.Character }
        local cc = Workspace:FindFirstChild("CarContainer")
        if State.VehicleWallbang and cc then
            table.insert(filter, cc)
        end
        if GEN_ENV.__PL_KX_ShieldBoxPart then
            table.insert(filter, GEN_ENV.__PL_KX_ShieldBoxPart)
        end
        GunHook.CastRayParams.FilterDescendantsInstances = filter
    end)
end

local function SetupGunControllerHooks()
    if not (HasGetConnections and HasDebugUpvalue) then
        return false
    end

    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local home = pg and pg:FindFirstChild("Home")
        local hud = home and home:FindFirstChild("hud")
        local actionArea = hud and hud:FindFirstChild("ActionArea")
        if actionArea then
            local fallbackShoot = nil
            for _, conn in ipairs(getconnections(actionArea.InputBegan)) do
                if conn.Function then
                    local shootFn = debug.getupvalue(conn.Function, 2)
                    if type(shootFn) == "function" then
                        local okB, newBullet = pcall(debug.getupvalue, shootFn, 16)
                        if okB and type(newBullet) == "function" then
                            GunHook.Shoot = shootFn
                            pcall(function() GunHook.Reload = debug.getupvalue(shootFn, 2) end)
                            GunHook.Bullet = newBullet
                            pcall(function()
                                if GunHook.Reload then
                                    GunHook.PlaySound = debug.getupvalue(GunHook.Reload, 3)
                                end
                            end)
                            GunHook.Ready = true
                            break
                        elseif not fallbackShoot then
                            fallbackShoot = shootFn
                        end
                    end
                end
            end
            if not GunHook.Ready and fallbackShoot and not GunHook.Shoot then
                GunHook.Shoot = fallbackShoot
                pcall(function() GunHook.Reload = debug.getupvalue(fallbackShoot, 2) end)
                GunHook.Ready = (GunHook.Shoot ~= nil and GunHook.Bullet ~= nil)
            end
        end

        for _, conn in ipairs(getconnections(LocalPlayer.CharacterAdded)) do
            if conn.Function then
                local okS, src = pcall(debug.info, conn.Function, "s")
                if okS and type(src) == "string" and src:find("GunController") then
                    pcall(function() GunHook.CastRayParams = debug.getupvalue(conn.Function, 2) end)
                    pcall(function()
                        local eqFn = debug.getupvalue(conn.Function, 3)
                        if type(eqFn) == "function" then
                            GunHook.Equip = eqFn
                        end
                    end)
                    break
                end
            end
        end

        UpdateCastRayFilter()

        GEN_ENV.__PL_KX_HookedBullets = GEN_ENV.__PL_KX_HookedBullets or {}
        if GunHook.Bullet and HasHookFunction then
            GunHook.IsBulletHooked = true
            GEN_ENV.__PL_KX_BulletHandler = function(origFn, ...)
                local args = table.pack(...)
                local useRage = State.Ragebot and (os.clock() - (GunHook.LastRageShotClock or 0)) < 0.25
                local useTase = (not useRage) and GunHook.TaseTargetPart and GunHook.TaseTargetPart.Parent and (os.clock() - (GunHook.LastTaseShotClock or 0)) < 0.25
                if Running and (State.SilentAim or State.Ragebot or useTase) then
                    if useRage or useTase or math.random(1, 100) <= State.SilentAimHitChance then
                        local part
                        if useTase then
                            local tPlr = Players:GetPlayerFromCharacter(GunHook.TaseTargetPart.Parent)
                            if tPlr and IsValidCombatTarget(tPlr, State.SilentAimHostile) then
                                part = GunHook.TaseTargetPart
                            end
                        elseif useRage then
                            local rageCand = GunHook.RageTargetPart
                            if rageCand and rageCand.Parent then
                                local rHum = GetHumanoid(rageCand.Parent)
                                if rHum and rHum.Health > 0 then
                                    part = PickShotTargetPart(rageCand.Parent, true) or rageCand
                                end
                            end
                            if not part then
                                part = GetBestTarget(
                                    State.SilentAimFOV,
                                    State.Ragebot360,
                                    State.SilentAimWallcheck,
                                    State.SilentAimHostile,
                                    true
                                )
                            end
                        else
                            local cand = GunHook.CurrentTargetPart
                            if cand and cand.Parent then
                                local cPlr = Players:GetPlayerFromCharacter(cand.Parent)
                                if not cPlr or not IsValidCombatTarget(cPlr, State.SilentAimHostile) then
                                    cand = nil
                                end
                            else
                                cand = nil
                            end
                            if not cand then
                                cand = GetBestTarget(
                                    State.SilentAimFOV,
                                    false,
                                    State.SilentAimWallcheck,
                                    State.SilentAimHostile,
                                    false
                                )
                            end
                            if cand and cand.Parent then
                                part = PickShotTargetPart(cand.Parent, false) or cand
                            end
                        end
                        if part and part.Parent then
                            local origOrigin = args[1]
                            if State.SilentAimWallbang and typeof(origOrigin) == "Vector3" then
                                local wbOrigin = FindWallbangOrigin(origOrigin, part.Position, part.Parent)
                                if wbOrigin then
                                    args[1] = wbOrigin
                                end
                            end
                            args[2] = part.Position
                            if type(args[3]) == "number" then
                                args[3] = 0
                            end
                            if State.BulletTracers and typeof(args[1]) == "Vector3" then
                                SpawnBulletTracerBeam(
                                    args[1],
                                    part.Position,
                                    useRage and Palette.RageCrimson or Palette.StreakGold
                                )
                            end
                        end
                    end
                elseif Running and State.GunMods and State.GunNoSpread then
                    if type(args[3]) == "number" then
                        args[3] = 0
                    end
                end
                return origFn(table.unpack(args, 1, args.n))
            end

            local hookedTarget = GunHook.Bullet
            if not GEN_ENV.__PL_KX_HookedBullets[hookedTarget] then
                local origBullet
                origBullet = hookfunction(hookedTarget, function(...)
                    local h = GEN_ENV.__PL_KX_BulletHandler
                    if type(h) == "function" then
                        return h(origBullet, ...)
                    end
                    return origBullet(...)
                end)
                GEN_ENV.__PL_KX_HookedBullets[hookedTarget] = origBullet
            end
            GunHook.OldBullet = GEN_ENV.__PL_KX_HookedBullets[hookedTarget]
        end
    end)

    return GunHook.Ready
end

task.spawn(function()
    for _ = 1, 20 do
        if not Running then break end
        if SetupGunControllerHooks() and GunHook.IsBulletHooked then break end
        task.wait(0.8)
    end
end)

local function FireGunOnce(tool, targetPart, isRage)
    if not tool or not tool.Parent then return false end
    local char = LocalPlayer.Character
    local hum = GetHumanoid(char)
    if not char or not hum or hum.Health <= 0 then return false end

    if tool.Parent ~= char then
        hum:EquipTool(tool)
    end
    local isRageShot = (isRage ~= false)
    GunHook.CurrentTargetPart = targetPart
    if isRageShot then
        GunHook.RageTargetPart = targetPart
        GunHook.LastRageShotClock = os.clock()
        GunHook.LastShotWasRage = true
    else
        GunHook.TaseTargetPart = targetPart
        GunHook.LastTaseShotClock = os.clock()
    end

    if GunHook.Ready and GunHook.Shoot then
        local cam = (targetPart and not GunHook.IsBulletHooked) and GetCamera() or nil
        local savedCamCF = cam and cam.CFrame or nil
        if cam and targetPart then
            pcall(function()
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
            end)
        end
        local obj = {
            UserInputState = Enum.UserInputState.Begin,
            UserInputType = Enum.UserInputType.MouseButton1,
            Position = Vector3.zero,
        }
        pcall(task.spawn, GunHook.Shoot, obj)
        task.defer(function()
            obj.UserInputState = Enum.UserInputState.End
            if cam and savedCamCF and (cam.Parent or cam == GetCamera()) then
                pcall(function() cam.CFrame = savedCamCF end)
            end
        end)
        return true
    else
        -- Graceful fallback for executors without getconnections/debug.getupvalue (restores camera immediately)
        local cam = GetCamera()
        local savedCamCF = cam and cam.CFrame or nil
        if cam and targetPart then
            pcall(function()
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
            end)
        end
        pcall(function() tool:Activate() end)
        if cam and savedCamCF then
            task.defer(function()
                if cam and (cam.Parent or cam == GetCamera()) then
                    pcall(function() cam.CFrame = savedCamCF end)
                end
            end)
        end
        if State.BulletTracers and char:FindFirstChild("Head") and targetPart then
            SpawnBulletTracerBeam(
                char.Head.Position,
                targetPart.Position,
                isRageShot and Palette.RageCrimson or Palette.NeonBlue
            )
        end
        return true
    end
end

-- ============================================================================
-- // SECTION 4: INSTANT WEAPON GRABBER, TEAM SWITCH, RESPAWN & FAST COMBO
-- ============================================================================
local KnownGunLocations = {
    ["Remington 870"] = Vector3.new(820.3, 97.85, 2229.4),
    ["MP5"]           = Vector3.new(813.7, 97.85, 2229.4),
    ["AK-47"]         = Vector3.new(-931.8, 91.28, 2039.3),
    ["M9"]            = Vector3.new(820.3, 97.85, 2229.4),
    ["M4A1"]          = Vector3.new(847.5, 97.85, 2229.4),
    ["FAL"]           = Vector3.new(-938.5, 91.28, 2039.3),
    ["Riot Shield"]   = Vector3.new(840.0, 97.85, 2229.4),
}

local function HasTool(name)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild(name) then return char:FindFirstChild(name) end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp and bp:FindFirstChild(name) then return bp:FindFirstChild(name) end
    return nil
end

local function IsWorldGiverCandidate(inst)
    if not inst or not inst.Parent then return false end
    if inst:IsA("Tool") or inst:FindFirstAncestorOfClass("Tool") then
        return false
    end
    local cur = inst
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and (Players:GetPlayerFromCharacter(cur) or cur:FindFirstChildOfClass("Humanoid")) then
            return false
        end
        cur = cur.Parent
    end
    return true
end

local function FindTouchGiverForTool(toolName)
    local bestGiver, bestDist = nil, math.huge
    local targetHint = KnownGunLocations[toolName]

    local okTagged, tagged = pcall(function()
        return CollectionService:GetTagged("TouchGiver")
    end)
    if okTagged and type(tagged) == "table" then
        for _, tg in ipairs(tagged) do
            if IsWorldGiverCandidate(tg) then
                local matches = (tg.Name == toolName or tg:GetAttribute("ToolName") == toolName)
                    or (tg.Parent and (tg.Parent.Name == toolName or tg.Parent:GetAttribute("ToolName") == toolName))
                if matches then
                    local okP, piv = pcall(function() return tg:GetPivot() end)
                    if okP and piv then
                        if targetHint then
                            local d = (piv.Position - targetHint).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestGiver = tg
                            end
                        else
                            return tg, CFrame.new(piv.Position - Vector3.new(0, 7.5, 0))
                        end
                    end
                end
            end
        end
        if bestGiver then
            local okP, piv = pcall(function() return bestGiver:GetPivot() end)
            if okP and piv then
                return bestGiver, CFrame.new(piv.Position - Vector3.new(0, 7.5, 0))
            end
        end
    end

    local pi = Workspace:FindFirstChild("Prison_ITEMS")
    local folders = {
        pi and pi:FindFirstChild("giver"),
        pi,
        Workspace,
    }
    for _, root in ipairs(folders) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if IsWorldGiverCandidate(obj) and (obj.Name == toolName or obj:GetAttribute("ToolName") == toolName) then
                    local giver = obj:FindFirstChild("TouchGiver")
                        or (obj.Name == "TouchGiver" and obj)
                        or obj
                    if giver and not giver:IsA("Tool") then
                        local okP, piv = pcall(function() return giver:GetPivot() end)
                        if okP and piv then
                            if targetHint then
                                local d = (piv.Position - targetHint).Magnitude
                                if d < bestDist then
                                    bestDist = d
                                    bestGiver = giver
                                end
                            else
                                return giver, CFrame.new(piv.Position - Vector3.new(0, 7.5, 0))
                            end
                        end
                    end
                end
            end
            if bestGiver then
                local okP, piv = pcall(function() return bestGiver:GetPivot() end)
                if okP and piv then
                    return bestGiver, CFrame.new(piv.Position - Vector3.new(0, 7.5, 0))
                end
            end
        end
    end
    if targetHint then
        return nil, CFrame.new(targetHint - Vector3.new(0, 7.5, 0))
    end
    return nil, nil
end

local IsGrabbingGuns = false
local function GrabWeapons(weaponList, onAlert)
    if IsGrabbingGuns or not Remotes.GiverPressed then return 0 end
    local char = LocalPlayer.Character
    local hrp = GetRoot(char)
    local hum = GetHumanoid(char)
    if not char or not hrp or not hum or hum.Health <= 0 then return 0 end

    local queue = {}
    for _, name in ipairs(weaponList) do
        if not HasTool(name) then
            local giver, underCF = FindTouchGiverForTool(name)
            if giver and underCF then
                table.insert(queue, { Name = name, Giver = giver, UnderCF = underCF })
            end
        end
    end

    if #queue == 0 then
        ApplyGunModsAll()
        return 0
    end

    IsGrabbingGuns = true
    local savedCF = hrp.CFrame
    local stepName = "PLKX_GunGrabLock"
    SafeBindRenderStep(stepName, Enum.RenderPriority.Character.Value + 1, function()
        if hrp and hrp.Parent then
            hrp.CFrame = savedCF
        end
    end)

    local grabbed = 0
    for _, item in ipairs(queue) do
        local t0 = os.clock()
        while not HasTool(item.Name) and (os.clock() - t0) < 1.25 and Running do
            if not hrp.Parent or hum.Health <= 0 then break end
            hrp.CFrame = item.UnderCF
            pcall(function() Remotes.GiverPressed:FireServer(item.Giver) end)
            RunService.Heartbeat:Wait()
        end
        if HasTool(item.Name) then
            grabbed = grabbed + 1
        end
    end

    SafeUnbindRenderStep(stepName)
    if hrp and hrp.Parent then
        hrp.CFrame = savedCF
    end
    IsGrabbingGuns = false
    SetupGunControllerHooks()
    ApplyGunModsAll()
    if onAlert and grabbed > 0 then
        onAlert("Equipped " .. grabbed .. " gun(s)", Palette.NeonBlue)
    end
    return grabbed
end

local function SwitchToTeam(teamName)
    if not Remotes.RequestTeamChange then return false end
    local targetTeam = nil
    for _, t in ipairs(Teams:GetTeams()) do
        if t.Name:lower() == teamName:lower() or t.Name:lower():sub(1, #teamName) == teamName:lower() then
            targetTeam = t
            break
        end
    end
    if not targetTeam then return false end
    local ok, res = pcall(function()
        return Remotes.RequestTeamChange:InvokeServer(targetTeam, 1)
    end)
    return ok and res ~= false
end

local LastDeathCFrame = nil
local function PerformFastRespawn()
    local oldChar = LocalPlayer.Character
    local hrp = GetRoot(oldChar)
    local savedCF = (hrp and hrp.CFrame) or LastDeathCFrame
    local curTeam = LocalPlayer.Team
    if not curTeam or curTeam == Teams:FindFirstChild("Neutral") then
        curTeam = Teams:FindFirstChild("Inmates")
    end

    task.spawn(function()
        local spawnedChar = nil
        local charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            if newChar and newChar ~= oldChar then
                spawnedChar = newChar
            end
        end)

        local function awaitRespawnedChar(timeoutSec)
            local t0 = os.clock()
            while Running and (os.clock() - t0) < timeoutSec do
                if spawnedChar and spawnedChar.Parent then
                    return spawnedChar
                end
                local cur = LocalPlayer.Character
                if cur and cur ~= oldChar and cur.Parent then
                    return cur
                end
                task.wait(0.03)
            end
            local cur = LocalPlayer.Character
            if cur and cur ~= oldChar then
                return cur
            end
            return spawnedChar
        end

        pcall(function()
            local crimTeam = Teams:FindFirstChild("Criminals")
            if curTeam == crimTeam then
                SwitchToTeam("Inmates")
                local nc = awaitRespawnedChar(5)
                local nHrp = nc and nc:WaitForChild("HumanoidRootPart", 5) or nil
                if nHrp then
                    local cs = Workspace:FindFirstChild("Criminals Spawn")
                    local sp = cs and (
                        cs:FindFirstChild("SpawnLocation")
                        or cs:FindFirstChildWhichIsA("BasePart")
                        or (cs:IsA("BasePart") and cs)
                    ) or nil
                    if sp then
                        nHrp.CFrame = sp.CFrame + Vector3.new(0, 3, 0)
                        local tC = os.clock()
                        while Running and crimTeam and LocalPlayer.Team ~= crimTeam and (os.clock() - tC) < 0.6 do
                            task.wait(0.05)
                        end
                    end
                    if State.KeepPosOnRespawn and savedCF and nHrp.Parent then
                        nHrp.CFrame = savedCF
                    end
                end
            else
                SwitchToTeam("Neutral")
                task.wait(0.08)
                if curTeam then
                    SwitchToTeam(curTeam.Name)
                end
                local nc = awaitRespawnedChar(5)
                local nHrp = nc and nc:WaitForChild("HumanoidRootPart", 5) or nil
                if nHrp and State.KeepPosOnRespawn and savedCF and nHrp.Parent then
                    task.wait(0.15)
                    if nHrp.Parent then
                        nHrp.CFrame = savedCF
                    end
                end
            end
        end)

        if charConn then
            pcall(function() charConn:Disconnect() end)
        end
    end)
end

local ComboOrder = { "Remington 870", "FAL", "M4A1", "AK-47", "MP5", "Revolver", "M9" }
local function GetOwnedLoadedGuns()
    local found = {}
    local function consider(tool)
        if tool and tool:IsA("Tool") and (tool:GetAttribute("ToolType") == "Gun" or tool:GetAttribute("FireRate")) then
            if tool.Name ~= "Taser" and (tool:GetAttribute("Local_ReloadSession") or 0) <= 0 then
                local ammo = tool:GetAttribute("Local_CurrentAmmo")
                if ammo == nil then
                    ammo = tool:GetAttribute("CurrentAmmo")
                end
                if ammo == nil or ammo > 0 then
                    return tool
                end
            end
        end
        return nil
    end

    for _, preferredName in ipairs(ComboOrder) do
        local t = HasTool(preferredName)
        if consider(t) then
            table.insert(found, t)
        end
    end
    for _, container in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if consider(t) and not table.find(found, t) then
                    table.insert(found, t)
                end
            end
        end
    end
    return found
end

local IsRunningCombo = false
local function ExecuteCombo1()
    if IsRunningCombo then return end
    IsRunningCombo = true
    task.spawn(function()
        pcall(function()
            local guns = GetOwnedLoadedGuns()
            if #guns == 0 and State.ComboAutoGrabGuns then
                GrabWeapons(State.AutoGunsSelection)
                guns = GetOwnedLoadedGuns()
            end

            local targetPart = GetBestTarget(
                State.SilentAimFOV,
                true,
                State.SilentAimWallcheck,
                State.SilentAimHostile,
                true
            )

            for _, gun in ipairs(guns) do
                if not Running then break end
                local char = LocalPlayer.Character
                local hum = GetHumanoid(char)
                if not char or not hum or hum.Health <= 0 then break end
                if gun and gun.Parent then
                    local ammo = gun:GetAttribute("Local_CurrentAmmo")
                    if ammo == nil then
                        ammo = gun:GetAttribute("CurrentAmmo")
                    end
                    if ammo == nil or ammo > 0 then
                        local needRetarget = (not targetPart or not targetPart.Parent)
                        if not needRetarget then
                            local tPlr = Players:GetPlayerFromCharacter(targetPart.Parent)
                            local tHum = GetHumanoid(targetPart.Parent)
                            if (tPlr and not IsValidCombatTarget(tPlr, State.SilentAimHostile))
                                or not tHum or tHum.Health <= 0 then
                                needRetarget = true
                            end
                        end
                        if needRetarget then
                            targetPart = GetBestTarget(
                                State.SilentAimFOV,
                                true,
                                State.SilentAimWallcheck,
                                State.SilentAimHostile,
                                true
                            )
                        end
                        if gun.Parent ~= char then
                            hum:EquipTool(gun)
                            task.wait()
                        end
                        if targetPart and targetPart.Parent then
                            FireGunOnce(gun, targetPart, true)
                        else
                            FireGunOnce(gun, nil, true)
                        end
                        task.wait(0.055)
                    end
                end
            end

            if State.ComboEndWithShield and State.ShieldEnabled then
                local shieldTool = HasTool("Riot Shield")
                local hum = GetHumanoid(LocalPlayer.Character)
                if shieldTool and hum and hum.Health > 0 then
                    pcall(function() hum:EquipTool(shieldTool) end)
                    if Remotes.ShieldEquipped then
                        pcall(function() Remotes.ShieldEquipped:FireServer(true) end)
                    end
                end
            end
        end)
        IsRunningCombo = false
    end)
end

-- ============================================================================
-- // SECTION 5: 3D BULLET-BLOCKING SHIELD, DESYNC, FE INVIS & ANTI-TASE
-- ============================================================================
local UIHooks = {
    PushAlert      = nil, -- function(playerNameOrTag, message, isWarning)
    PushKillfeed   = nil, -- function(killerPlr, killerName, killerHP, victimPlr, victimName, weaponName, streakCount, isRagebot)
    ClearHUD       = nil, -- function()
    UpdateBadges   = nil, -- function()
    LogCmd         = nil, -- function(text, color)
}

local ShieldBoxPart = nil
local ShieldSelection = nil
local DesyncRestoreCF = nil
local DesyncPhase = 0
local FEInvisTrack = nil
local FEInvisSavedTrans = {}
local LastShieldRemoteSent = false

local function DestroyShieldBoxVisual()
    if ShieldSelection then
        pcall(function() ShieldSelection:Destroy() end)
        ShieldSelection = nil
    end
    if ShieldBoxPart then
        pcall(function() ShieldBoxPart:Destroy() end)
        ShieldBoxPart = nil
    end
    GEN_ENV.__PL_KX_ShieldBoxPart = nil
    UpdateCastRayFilter()
end

local function EnsureShieldBoxVisual(hrp)
    if not hrp or not hrp.Parent then return nil end
    if not (ShieldBoxPart and ShieldBoxPart.Parent) then
        local box = Instance.new("Part")
        box.Name = "PLKX_BulletShieldBox"
        box.Shape = Enum.PartType.Block
        box.Material = Enum.Material.SmoothPlastic
        box.Color = Palette.ShieldGrey
        box.Transparency = State.ShieldBoxTransparency
        box.Size = Vector3.new(State.ShieldBoxSize, State.ShieldBoxSize * 0.88, State.ShieldBoxSize)
        box.Anchored = true
        box.CanCollide = false
        box.CanQuery = false
        box.CanTouch = false
        box.Massless = true
        box.CastShadow = false
        box.Parent = Workspace

        local sel = Instance.new("SelectionBox")
        sel.Name = "PLKX_ShieldEdge"
        sel.Adornee = box
        sel.Color3 = Color3.fromRGB(108, 112, 126)
        sel.LineThickness = 0.01
        sel.SurfaceTransparency = 1
        sel.Transparency = 0.88
        sel.Parent = box

        ShieldBoxPart = box
        ShieldSelection = sel
        GEN_ENV.__PL_KX_ShieldBoxPart = box
        UpdateCastRayFilter()
    end

    ShieldBoxPart.Size = Vector3.new(State.ShieldBoxSize, State.ShieldBoxSize * 0.88, State.ShieldBoxSize)
    ShieldBoxPart.Transparency = State.ShieldBoxTransparency
    return ShieldBoxPart
end

local function GetRiotShieldStatus()
    local char = LocalPlayer.Character
    local tool = HasTool("Riot Shield")
    local part = char and char:FindFirstChild("RiotShieldPart")
    local hasRiot = (tool ~= nil or part ~= nil)
    local hp = nil
    local maxHp = 180
    for _, src in ipairs({ part, tool }) do
        if src and not hp then
            local attrHp = src:GetAttribute("Health") or src:GetAttribute("ShieldHealth")
            if type(attrHp) == "number" then
                hp = attrHp
            else
                local nv = src:FindFirstChild("Health") or src:FindFirstChild("ShieldHealth")
                if nv and (nv:IsA("NumberValue") or nv:IsA("IntValue")) then
                    hp = nv.Value
                end
            end
        end
    end
    if not hp and hasRiot then
        pcall(function()
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local home = pg and pg:FindFirstChild("Home")
            local hud = home and home:FindFirstChild("hud")
            local shf = hud and hud:FindFirstChild("ShieldHealthFrame")
            if shf and shf.Visible then
                for _, desc in ipairs(shf:GetDescendants()) do
                    if desc:IsA("TextLabel") then
                        local num = tonumber((desc.Text or ""):match("%d+"))
                        if num then
                            hp = num
                            break
                        end
                    end
                end
                if not hp then
                    for _, desc in ipairs(shf:GetDescendants()) do
                        if desc:IsA("Frame") and desc.Name:lower():find("bar") and desc.Size.X.Scale > 0 and desc.Size.X.Scale <= 1 then
                            hp = math.floor(desc.Size.X.Scale * maxHp + 0.5)
                            break
                        end
                    end
                end
            end
        end)
    end
    return hasRiot, hp, maxHp, tool, part
end

local function FindNearestShooterThreat(myPos)
    local bestPos, bestScore = nil, 280
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidCombatTarget(plr, false) then
            local ch = plr.Character
            local root = GetRoot(ch)
            if root then
                local delta = myPos - root.Position
                local dist = delta.Magnitude
                if dist > 0.5 and dist < 280 then
                    local holdingWeapon = ch:FindFirstChildOfClass("Tool")
                    local hasGun = holdingWeapon and (holdingWeapon:GetAttribute("ToolType") == "Gun" or holdingWeapon:GetAttribute("FireRate"))
                    local bonus = hasGun and 0.55 or 1.0
                    local aimDot = root.CFrame.LookVector:Dot(delta.Unit)
                    if aimDot > 0.45 and hasGun then
                        bonus = bonus * 0.65 -- Prioritize armed shooters actually facing us
                    end
                    if dist * bonus < bestScore then
                        bestScore = dist * bonus
                        bestPos = root.Position
                    end
                end
            end
        end
    end
    return bestPos
end

local function StopFEInvisible()
    if FEInvisTrack then
        pcall(function() FEInvisTrack:Stop(0) end)
        FEInvisTrack = nil
    end
    local char = LocalPlayer.Character
    local hum = GetHumanoid(char)
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local id = track.Animation and track.Animation.AnimationId or ""
            if id:find("18665825805") or id:find("215384594") then
                pcall(function() track:Stop(0) end)
            end
        end
    end
    for inst, origT in pairs(FEInvisSavedTrans) do
        if inst and inst.Parent then
            pcall(function() inst.Transparency = origT end)
        end
    end
    table.clear(FEInvisSavedTrans)
end

local function StartFEInvisible()
    StopFEInvisible()
    local char = LocalPlayer.Character
    local hum = GetHumanoid(char)
    local hrp = GetRoot(char)
    if not char or not hum or not hrp or hum.Health <= 0 then return end

    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)

    for _, d in ipairs(char:GetDescendants()) do
        if (d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture")) and d ~= hrp then
            if d.Transparency < 0.65 then
                FEInvisSavedTrans[d] = d.Transparency
                d.Transparency = 0.65
            end
        end
    end

    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
    local anim = Instance.new("Animation")
    anim.AnimationId = isR15 and "rbxassetid://18665825805" or "rbxassetid://215384594"
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    anim:Destroy()

    if ok and track then
        FEInvisTrack = track
        track.Priority = Enum.AnimationPriority.Action4
        track:Play(0, 0.001, 0)
        task.delay(0.04, function()
            if FEInvisTrack == track and (State.FEInvisible or (State.ShieldEnabled and State.ShieldMode == "FEGhost")) then
                pcall(function()
                    track.TimePosition = isR15 and 1.95 or 0.4
                    track:AdjustSpeed(0)
                end)
            end
        end)
    end
end

local function SetFEInvisible(enabled)
    State.FEInvisible = enabled
    if enabled then
        StartFEInvisible()
    else
        StopFEInvisible()
    end
end

local function SetShieldState(enabled)
    State.ShieldEnabled = enabled
    if not enabled then
        if DesyncRestoreCF then
            local hrp = GetRoot(LocalPlayer.Character)
            if hrp and hrp.Parent then
                hrp.CFrame = DesyncRestoreCF
            end
            DesyncRestoreCF = nil
        end
        DestroyShieldBoxVisual()
        LastShieldRemoteSent = false
        if Remotes.ShieldEquipped then
            pcall(function() Remotes.ShieldEquipped:FireServer(false) end)
        end
        if not State.FEInvisible then
            StopFEInvisible()
        end
    else
        local hrp = GetRoot(LocalPlayer.Character)
        if hrp then
            local box = EnsureShieldBoxVisual(hrp)
            if box then
                box.CFrame = CFrame.new(hrp.Position)
            end
        end
        if State.ShieldMode == "FEGhost" then
            StartFEInvisible()
        elseif not State.FEInvisible then
            StopFEInvisible()
        end
    end
    if UIHooks.UpdateBadges then UIHooks.UpdateBadges() end
end

local function BypassClientAntiNoclip()
    pcall(function()
        local scriptsFolder = ReplicatedStorage:FindFirstChild("Scripts")
        local charColl = scriptsFolder and scriptsFolder:FindFirstChild("CharacterCollision")
        if charColl then charColl:Destroy() end
    end)
    pcall(function()
        local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
        if head and HasGetConnections then
            for _, conn in ipairs(getconnections(head:GetPropertyChangedSignal("CanCollide"))) do
                conn:Disable()
            end
        end
    end)
end

local DisabledJumpConns = {}
local function BypassAntiJump(char, enableBypass)
    if not char then return end
    pcall(function()
        local hum = GetHumanoid(char)
        if enableBypass then
            if hum and HasGetConnections then
                for _, conn in ipairs(getconnections(hum:GetPropertyChangedSignal("Jump"))) do
                    if conn and conn.Disable then
                        conn:Disable()
                        table.insert(DisabledJumpConns, conn)
                    end
                end
            end
            local aj = char:FindFirstChild("AntiJump")
            if aj then aj.Disabled = true end
        else
            for _, conn in ipairs(DisabledJumpConns) do
                pcall(function() conn:Enable() end)
            end
            table.clear(DisabledJumpConns)
            local aj = char:FindFirstChild("AntiJump")
            if aj then aj.Disabled = false end
        end
    end)
end

local function PurgeTaseAndRagdollEffects()
    local char = LocalPlayer.Character
    local hum = GetHumanoid(char)
    if hum then
        pcall(function()
            hum.PlatformStand = false
            if hum.WalkSpeed == 0 then hum.WalkSpeed = 16 end
            if hum.JumpHeight == 0 then hum.JumpHeight = 7.2 end
            if hum.UseJumpPower and hum.JumpPower == 0 then hum.JumpPower = 50 end
            if not (State.FEInvisible or (State.ShieldEnabled and State.ShieldMode == "FEGhost")) then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            end
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local id = track.Animation and track.Animation.AnimationId or ""
            if id:find("279227693") or id:find("279229192") then
                pcall(function() track:Stop(0) end)
            end
        end
    end
    LocalPlayer:SetAttribute("BackpackEnabled", true)
end

local AntiTazeState = { Hooked = false, Fallback = false, Guard = false }
local function InstallAntiTaze()
    if not AntiTazeState.Guard then
        AntiTazeState.Guard = true
        pcall(function()
            AddConnection(LocalPlayer:GetAttributeChangedSignal("BackpackEnabled"):Connect(function()
                if Running and State.AntiTase and LocalPlayer:GetAttribute("BackpackEnabled") == false then
                    LocalPlayer:SetAttribute("BackpackEnabled", true)
                end
            end))
        end)
    end

    if not GunRemotes.PlayerTased then
        local gr = ReplicatedStorage:FindFirstChild("GunRemotes")
        if gr then
            GunRemotes.PlayerTased = gr:FindFirstChild("PlayerTased")
        end
        if not GunRemotes.PlayerTased then
            RefreshRemotes()
        end
    end

    local pt = GunRemotes.PlayerTased
    if not pt then return false end

    if not AntiTazeState.Fallback and pt.OnClientEvent then
        AntiTazeState.Fallback = true
        AddConnection(pt.OnClientEvent:Connect(function()
            if Running and State.AntiTase then
                PurgeTaseAndRagdollEffects()
                task.defer(function()
                    if Running and State.AntiTase then
                        PurgeTaseAndRagdollEffects()
                    end
                end)
            end
        end))
    end

    if AntiTazeState.Hooked then return true end
    if HasGetConnections and HasHookFunction then
        pcall(function()
            local conns = getconnections(pt.OnClientEvent)
            GEN_ENV.__PL_KX_TaseHandler = function(origFn, ...)
                if Running and State.AntiTase then
                    PurgeTaseAndRagdollEffects()
                    return nil
                end
                return origFn(...)
            end
            GEN_ENV.__PL_KX_HookedTase = GEN_ENV.__PL_KX_HookedTase or {}
            local hookedAny = false
            for _, conn in ipairs(conns) do
                local fn = conn and conn.Function
                if type(fn) == "function" then
                    hookedAny = true
                    if not GEN_ENV.__PL_KX_HookedTase[fn] then
                        local origFn
                        origFn = hookfunction(fn, function(...)
                            local h = GEN_ENV.__PL_KX_TaseHandler
                            if type(h) == "function" then
                                return h(origFn, ...)
                            end
                            return origFn(...)
                        end)
                        GEN_ENV.__PL_KX_HookedTase[fn] = origFn
                    end
                end
            end
            if hookedAny then
                AntiTazeState.Hooked = true
            end
        end)
    end
    return AntiTazeState.Hooked or AntiTazeState.Fallback
end

InstallAntiTaze()
if not AntiTazeState.Hooked then
    task.spawn(function()
        for _ = 1, 20 do
            if not Running or AntiTazeState.Hooked then break end
            task.wait(0.8)
            InstallAntiTaze()
        end
    end)
end

local function CleanCharacterEffects()
    PurgeTaseAndRagdollEffects()
    if UIHooks.ClearHUD then
        UIHooks.ClearHUD()
    end
end

-- ============================================================================
-- // SECTION 6: HEURISTIC CHEATER & CAR-TELEPORT DETECTOR ([Alert] ENGINE)
-- ============================================================================
local PlayerMonitor = {} -- [plr] = { pos, time, seated, carPos, spawnTime, lastFlags = {} }
local FlaggedCheaters = {} -- [userId] = reason

local function EvaluatePlayerAnomalies()
    if not (State.CheaterAlerts or State.CarTPAlerts) then return end
    local now = os.clock()
    local carContainer = Workspace:FindFirstChild("CarContainer")

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hrp = GetRoot(char)
            local hum = GetHumanoid(char)
            if char and hrp and hum and hum.Health > 0 then
                local st = PlayerMonitor[plr]
                if not st or st.char ~= char then
                    PlayerMonitor[plr] = {
                        char = char,
                        pos = hrp.Position,
                        time = now,
                        seated = (hum.SeatPart ~= nil),
                        spawnTime = now,
                        lastFlags = {},
                    }
                else
                    local dt = now - st.time
                    if dt >= 0.12 then
                        local newPos = hrp.Position
                        local xzDelta = Vector3.new(newPos.X - st.pos.X, 0, newPos.Z - st.pos.Z).Magnitude
                        local xzSpeed = xzDelta / dt
                        local seatedNow = (hum.SeatPart ~= nil)

                        if (now - st.spawnTime) > 2.5 and dt < 1.0 then
                            local nearCar = false
                            if seatedNow or st.seated then
                                nearCar = true
                            elseif carContainer then
                                for _, car in ipairs(carContainer:GetChildren()) do
                                    local okP, piv = pcall(function() return car:GetPivot() end)
                                    if okP and piv and ((piv.Position - newPos).Magnitude < 32 or (piv.Position - st.pos).Magnitude < 32) then
                                        nearCar = true
                                        break
                                    end
                                end
                            end

                            local function tryFlag(key, msg)
                                local prev = st.lastFlags[key] or 0
                                if (now - prev) >= 7.0 then
                                    st.lastFlags[key] = now
                                    FlaggedCheaters[plr.UserId] = msg
                                    if UIHooks.PushAlert then
                                        UIHooks.PushAlert(plr.Name, msg)
                                    end
                                end
                            end

                            if State.CarTPAlerts and nearCar and (xzDelta > 58 or xzSpeed > 190) then
                                tryFlag("CarTP", "Possible Car Teleport User")
                            elseif State.CheaterAlerts and not nearCar and xzDelta > 62 then
                                tryFlag("TP", "Possible Teleport / Speed User")
                            end
                        end

                        st.pos = newPos
                        st.time = now
                        st.seated = seatedNow
                    end
                end
            else
                PlayerMonitor[plr] = nil
            end
        end
    end
end

-- ============================================================================
-- // SECTION 7: WORLD, DOORS, FENCES, VEHICLES, SAFE SPEED & ESP
-- ============================================================================
local OriginalFenceTouch = {}
local function SetFenceGodmode(enabled)
    local fences = Workspace:FindFirstChild("Prison_Fences")
    if not fences then return end
    for _, d in ipairs(fences:GetDescendants()) do
        if d:IsA("BasePart") and d:FindFirstChildOfClass("TouchTransmitter") then
            if enabled then
                if OriginalFenceTouch[d] == nil then
                    OriginalFenceTouch[d] = d.CanTouch
                end
                d.CanTouch = false
            elseif OriginalFenceTouch[d] ~= nil then
                d.CanTouch = OriginalFenceTouch[d]
            end
        end
    end
end

local OriginalDoorProps = {}
local function SetOpenAllDoors(enabled)
    local doors = Workspace:FindFirstChild("Doors")
    if not doors then return end
    for _, d in ipairs(doors:GetDescendants()) do
        if d:IsA("BasePart") then
            if enabled then
                if not OriginalDoorProps[d] then
                    OriginalDoorProps[d] = { CanCollide = d.CanCollide, Transparency = d.Transparency }
                end
                d.CanCollide = false
                if d.Transparency < 0.7 then
                    d.Transparency = 0.7
                end
            elseif OriginalDoorProps[d] then
                d.CanCollide = OriginalDoorProps[d].CanCollide
                d.Transparency = OriginalDoorProps[d].Transparency
                OriginalDoorProps[d] = nil
            end
        end
    end
end

local OriginalCarCollision = setmetatable({}, { __mode = "k" })
local function SafeSetAntiFlingEnabled(enabled)
    local cc = Workspace:FindFirstChild("CarContainer")
    if not cc then return end
    local char = LocalPlayer.Character
    local hum = GetHumanoid(char)
    local myCar = hum and hum.SeatPart and hum.SeatPart:FindFirstAncestorOfClass("Model") or nil
    for _, car in ipairs(cc:GetChildren()) do
        local isMyCar = (myCar ~= nil and car == myCar)
        for _, d in ipairs(car:GetDescendants()) do
            if d:IsA("BasePart") and not d:IsA("VehicleSeat") and not d:IsA("Seat") then
                if enabled and not isMyCar then
                    if not OriginalCarCollision[d] then
                        OriginalCarCollision[d] = { CanCollide = d.CanCollide, CanTouch = d.CanTouch }
                    end
                    d.CanCollide = false
                    d.CanTouch = false
                elseif OriginalCarCollision[d] then
                    d.CanCollide = OriginalCarCollision[d].CanCollide
                    d.CanTouch = OriginalCarCollision[d].CanTouch
                    OriginalCarCollision[d] = nil
                end
            end
        end
    end
end

local function SpawnAndEnterNearestCar()
    if not Remotes.InteractWithItem then return false end
    local char = LocalPlayer.Character
    local hrp = GetRoot(char)
    local hum = GetHumanoid(char)
    if not hrp or not hum then return false end

    local pi = Workspace:FindFirstChild("Prison_ITEMS")
    local buttons = pi and pi:FindFirstChild("buttons")
    if not buttons then return false end

    local nearestBtn, bestDist = nil, math.huge
    for _, model in ipairs(buttons:GetChildren()) do
        if model.Name == "Car Spawner" then
            local part = model:FindFirstChild("Car Spawner") or model:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearestBtn = part
                end
            end
        end
    end
    if not nearestBtn then return false end

    task.spawn(function()
        local oldCF = hrp.CFrame
        if bestDist > 18 then
            hrp.CFrame = nearestBtn.CFrame + Vector3.new(0, 3.5, 0)
            task.wait(0.2)
        end
        pcall(function() Remotes.InteractWithItem:InvokeServer(nearestBtn) end)
        task.wait(0.35)
        local cc = Workspace:FindFirstChild("CarContainer")
        if cc then
            local bestSeat, sDist = nil, 65
            for _, d in ipairs(cc:GetDescendants()) do
                if d:IsA("VehicleSeat") and not d.Occupant then
                    local dist = (d.Position - nearestBtn.Position).Magnitude
                    if dist < sDist then
                        sDist = dist
                        bestSeat = d
                    end
                end
            end
            if bestSeat then
                hrp.CFrame = bestSeat.CFrame + Vector3.new(0, 2, 0)
                task.wait(0.1)
                pcall(function() bestSeat:Sit(hum) end)
                return
            end
        end
        if hrp and hrp.Parent then
            hrp.CFrame = oldCF
        end
    end)
    return true
end

local IndoorSubRegions = {
    { cx = 752.77, cz = 2571.80, hx = 109.93 / 2, hz = 13.60 / 2 },
    { cx = 701.15, cz = 2313.70, hx = 69.10 / 2,  hz = 163.00 / 2 },
    { cx = 917.30, cz = 2392.60, hx = 107.00 / 2, hz = 28.00 / 2 },
    { cx = 830.30, cz = 2242.55, hx = 58.00 / 2,  hz = 34.10 / 2 },
    { cx = 748.90, cz = 2340.60, hx = 59.40 / 2,  hz = 109.20 / 2 },
    { cx = 799.10, cz = 2299.00, hx = 14.00 / 2,  hz = 33.99 / 2 },
    { cx = 826.69, cz = 2338.60, hx = 51.19 / 2,  hz = 12.00 / 2 },
    { cx = 799.65, cz = 2269.23, hx = 12.90 / 2,  hz = 21.50 / 2 },
    { cx = 765.36, cz = 2247.57, hx = 59.32 / 2,  hz = 64.82 / 2 },
    { cx = 850.20, cz = 2571.80, hx = 23.20 / 2,  hz = 13.60 / 2 },
    { cx = 779.80, cz = 2479.80, hx = 164.00 / 2, hz = 170.40 / 2 },
    { cx = 983.35, cz = 2315.15, hx = 31.10 / 2,  hz = 58.90 / 2 },
    { cx = 916.50, cz = 2225.40, hx = 99.00 / 2,  hz = 38.00 / 2 },
    { cx = 889.80, cz = 2361.60, hx = 220.00 / 2, hz = 34.00 / 2 },
    { cx = 915.80, cz = 2456.60, hx = 64.00 / 2,  hz = 100.00 / 2 },
    { cx = 820.80, cz = 2386.60, hx = 82.00 / 2,  hz = 16.00 / 2 },
    { cx = 916.90, cz = 2294.50, hx = 98.20 / 2,  hz = 100.20 / 2 },
    { cx = 836.95, cz = 2296.10, hx = 61.70 / 2,  hz = 73.00 / 2 },
    { cx = 872.30, cz = 2463.60, hx = 19.00 / 2,  hz = 62.00 / 2 },
    { cx = 959.30, cz = 2463.60, hx = 19.00 / 2,  hz = 62.00 / 2 },
}
local PrisonOuterBox = { cx = 773.62, cz = 2327.43, hx = 563.37 / 2, hz = 540.30 / 2 }

local function GetSafeRegionMaxSpeed(pos)
    local x, z = pos.X, pos.Z
    for _, b in ipairs(IndoorSubRegions) do
        if math.abs(x - b.cx) <= b.hx and math.abs(z - b.cz) <= b.hz then
            return 32
        end
    end
    if math.abs(x - PrisonOuterBox.cx) <= PrisonOuterBox.hx and math.abs(z - PrisonOuterBox.cz) <= PrisonOuterBox.hz then
        return 50
    end
    return 100
end

local TeleportLocations = {
    ["yard"]        = CFrame.new(780, 98, 2470),
    ["nexus"]       = CFrame.new(875, 100, 2390),
    ["cafeteria"]   = CFrame.new(905, 100, 2290),
    ["cells"]       = CFrame.new(915, 100, 2445),
    ["armory"]      = CFrame.new(830, 100, 2235),
    ["crimbase"]    = CFrame.new(-943, 94, 2056),
    ["roof"]        = CFrame.new(825, 119, 2350),
    ["tower"]       = CFrame.new(822, 130, 2588),
    ["gate"]        = CFrame.new(504, 103, 2250),
    ["sewer"]       = CFrame.new(917, 79, 2110),
    ["hideout"]     = CFrame.new(-97, 72, 1910),
    ["cars"]        = CFrame.new(-525, 54, 1775),
    ["store"]       = CFrame.new(415, 55, 1735),
    ["gas"]         = CFrame.new(-515, 54, 1665),
    ["neutral"]     = CFrame.new(879, 28, 2349),
}

local SavedNoclipCollide = setmetatable({}, { __mode = "k" })
local function RestoreNoclipCollide()
    if next(SavedNoclipCollide) == nil then return end
    for part, origCollide in pairs(SavedNoclipCollide) do
        if part and part.Parent then
            pcall(function() part.CanCollide = origCollide end)
        end
    end
    table.clear(SavedNoclipCollide)
end

local function SafeTeleportCF(targetCF)
    local char = LocalPlayer.Character
    local hrp = GetRoot(char)
    local hum = GetHumanoid(char)
    if not hrp or not targetCF then return false end
    DesyncRestoreCF = nil
    if hum and hum.SeatPart then
        local model = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if model and model.PrimaryPart then
            model:PivotTo(targetCF)
            return true
        end
    end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = targetCF
    return true
end

-- ESP Pool
local ESPContainer = nil
local ESPPool = {} -- [plr] = { Highlight, Billboard, Diamond, NameLbl, HpFill, HpBg }
local C4Pool  = {} -- [inst] = Highlight

local function RemovePlayerESP(plr)
    local entry = ESPPool[plr]
    if not entry then return end
    if entry.Highlight then pcall(function() entry.Highlight:Destroy() end) end
    if entry.Billboard then pcall(function() entry.Billboard:Destroy() end) end
    ESPPool[plr] = nil
end

local function UpdateAllESP()
    if not ESPContainer or not ESPContainer.Parent then return end
    local myChar = LocalPlayer.Character
    local myRoot = GetRoot(myChar)

    if not State.ESP then
        for plr in pairs(ESPPool) do
            RemovePlayerESP(plr)
        end
    else
        for plr in pairs(ESPPool) do
            if not plr.Parent then
                RemovePlayerESP(plr)
            end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hrp = GetRoot(char)
                local head = char and char:FindFirstChild("Head")
                local hum = GetHumanoid(char)
                local hide = (not char) or (not hrp) or (not hum) or hum.Health <= 0
                    or (State.ESPHideTeam and LocalPlayer.Team and plr.Team == LocalPlayer.Team)

                if hide then
                    RemovePlayerESP(plr)
                else
                    local entry = ESPPool[plr]
                    if not entry then
                        local hl = Instance.new("Highlight")
                        hl.Name = "PLKX_Cham_" .. plr.Name
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillTransparency = 0.84
                        hl.OutlineTransparency = 0.05
                        hl.Parent = ESPContainer

                        local bb = Instance.new("BillboardGui")
                        bb.Name = "PLKX_Tag_" .. plr.Name
                        bb.AlwaysOnTop = true
                        bb.Size = UDim2.fromOffset(120, 44)
                        bb.StudsOffset = Vector3.new(0, 3.2, 0)
                        bb.MaxDistance = 1200
                        bb.Parent = ESPContainer

                        local diamond = Instance.new("Frame")
                        diamond.AnchorPoint = Vector2.new(0.5, 0.5)
                        diamond.Position = UDim2.new(0.5, 0, 0, 6)
                        diamond.Size = UDim2.fromOffset(7, 7)
                        diamond.Rotation = 45
                        diamond.BorderSizePixel = 1
                        diamond.BorderColor3 = Color3.new(0, 0, 0)
                        diamond.Parent = bb

                        local nameLbl = Instance.new("TextLabel")
                        nameLbl.AnchorPoint = Vector2.new(0.5, 0)
                        nameLbl.Position = UDim2.new(0.5, 0, 0, 12)
                        nameLbl.Size = UDim2.new(1, 0, 0, 15)
                        nameLbl.BackgroundTransparency = 1
                        nameLbl.Font = Enum.Font.GothamBold
                        nameLbl.TextSize = 11
                        nameLbl.TextStrokeTransparency = 0.25
                        nameLbl.Parent = bb

                        local hpBg = Instance.new("Frame")
                        hpBg.AnchorPoint = Vector2.new(0.5, 0)
                        hpBg.Position = UDim2.new(0.5, 0, 0, 29)
                        hpBg.Size = UDim2.fromOffset(62, 4)
                        hpBg.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
                        hpBg.BorderSizePixel = 0
                        hpBg.Parent = bb
                        Instance.new("UIStroke", hpBg).Thickness = 1

                        local hpFill = Instance.new("Frame")
                        hpFill.Size = UDim2.fromScale(1, 1)
                        hpFill.BorderSizePixel = 0
                        hpFill.Parent = hpBg

                        entry = {
                            Highlight = hl,
                            Billboard = bb,
                            Diamond   = diamond,
                            NameLbl   = nameLbl,
                            HpBg      = hpBg,
                            HpFill    = hpFill,
                        }
                        ESPPool[plr] = entry
                    end

                    local tCol = GetTeamColor(plr)
                    entry.Highlight.Enabled = State.ESPChams
                    entry.Highlight.Adornee = char
                    entry.Highlight.FillColor = tCol
                    entry.Highlight.OutlineColor = FlaggedCheaters[plr.UserId] and Palette.RedAlert or tCol

                    entry.Billboard.Adornee = head or hrp
                    entry.Billboard.Enabled = (State.ESPNames or State.ESPHealthBar or State.ESPDiamondMarker)
                    entry.Diamond.Visible = State.ESPDiamondMarker
                    entry.Diamond.BackgroundColor3 = tCol

                    local distStr = ""
                    if State.ESPDistance and myRoot then
                        distStr = string.format(" [%dm]", math.floor((hrp.Position - myRoot.Position).Magnitude))
                    end
                    local cheatTag = FlaggedCheaters[plr.UserId] and " [⚠]" or ""
                    entry.NameLbl.Visible = State.ESPNames
                    entry.NameLbl.Text = plr.Name .. distStr .. cheatTag
                    entry.NameLbl.TextColor3 = tCol

                    local ratio = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                    entry.HpBg.Visible = State.ESPHealthBar
                    entry.HpFill.Size = UDim2.fromScale(ratio, 1)
                    if ratio > 0.6 then
                        entry.HpFill.BackgroundColor3 = Color3.fromRGB(70, 240, 110)
                    elseif ratio > 0.3 then
                        entry.HpFill.BackgroundColor3 = Color3.fromRGB(255, 210, 65)
                    else
                        entry.HpFill.BackgroundColor3 = Color3.fromRGB(255, 70, 75)
                    end
                end
            end
        end
    end

    -- C4 ESP
    if not State.C4ESP then
        for inst, hl in pairs(C4Pool) do
            pcall(function() hl:Destroy() end)
            C4Pool[inst] = nil
        end
    else
        for _, c4 in ipairs(CollectionService:GetTagged("C4")) do
            if c4 and c4.Parent and not C4Pool[c4] then
                local hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillColor = Color3.fromRGB(255, 65, 65)
                hl.OutlineColor = Color3.fromRGB(255, 220, 65)
                hl.FillTransparency = 0.4
                hl.Adornee = c4
                hl.Parent = ESPContainer
                C4Pool[c4] = hl
            end
        end
        for inst, hl in pairs(C4Pool) do
            if not inst or not inst.Parent then
                pcall(function() hl:Destroy() end)
                C4Pool[inst] = nil
            end
        end
    end
end

local SavedHitboxes = setmetatable({}, { __mode = "k" })
local function RestorePlayerHitbox(hrp)
    local orig = hrp and SavedHitboxes[hrp]
    if orig then
        pcall(function()
            if hrp.Parent then
                hrp.Size = orig.Size
                hrp.Transparency = orig.Transparency
                hrp.CanCollide = orig.CanCollide
            end
        end)
        SavedHitboxes[hrp] = nil
    end
end

local function UpdateHitboxExpander()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = GetHumanoid(char)
            local valid = State.HitboxExpander
                and char and hrp and hum and hum.Health > 0
                and not (State.HitboxTeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team)
            if valid then
                if not SavedHitboxes[hrp] then
                    SavedHitboxes[hrp] = {
                        Size = hrp.Size,
                        Transparency = hrp.Transparency,
                        CanCollide = hrp.CanCollide,
                    }
                end
                local sz = math.clamp(State.HitboxSize, 2, 24)
                pcall(function()
                    hrp.Size = Vector3.new(sz, sz, sz)
                    hrp.Transparency = 1
                    hrp.CanCollide = false
                end)
            elseif hrp then
                RestorePlayerHitbox(hrp)
            end
        end
    end
end

local SavedJumpProps = setmetatable({}, { __mode = "k" })
local SavedSpeedProps = setmetatable({}, { __mode = "k" })
local LastKillAuraAttempt = 0

-- ============================================================================
-- // SECTION 8: RUNTIME LOOPS (SHIELD, RAGEBOT, AIM, VEHICLES, UTILITY)
-- ============================================================================
local PlayerHealthCache = setmetatable({}, { __mode = "k" })
local KillerStreaks = {}
local MobileFlyInput = { Up = 0, Down = 0 }
local LastRageAttempt = 0
local LastArrestAttempt = 0
local LastComboLoop = 0
local LastTaseAttempt = 0
local LastUtilityTick = 0

local function GetBestRageWeapon()
    local char = LocalPlayer.Character
    local cur = char and char:FindFirstChildOfClass("Tool")
    if cur and (cur:GetAttribute("ToolType") == "Gun" or cur:GetAttribute("FireRate")) and cur.Name ~= "Taser" then
        if (cur:GetAttribute("Local_ReloadSession") or 0) <= 0 and (cur:GetAttribute("Local_CurrentAmmo") or 1) > 0 then
            return cur
        end
    end
    if State.RagebotAutoSwitch then
        local guns = GetOwnedLoadedGuns()
        if guns[1] then return guns[1] end
    end
    return nil
end

local function ShouldUseDesyncNow()
    if not State.ShieldEnabled then return false end
    if State.ShieldMode == "DesyncBox" then return true end
    if State.ShieldMode == "Hybrid" then
        local hasRiot = GetRiotShieldStatus()
        return not hasRiot
    end
    return false
end

-- Pre-Camera RenderStep: Restore micro-desync before Roblox's Camera update (RenderPriority.Camera = 200)
SafeBindRenderStep("PLKX_PreCamDesyncRestore", Enum.RenderPriority.Camera.Value - 1, function()
    if not Running then return end
    if DesyncRestoreCF then
        local hrp = GetRoot(LocalPlayer.Character)
        if hrp and hrp.Parent then
            hrp.CFrame = DesyncRestoreCF
        end
        DesyncRestoreCF = nil
    end
end)

-- RenderStepped: Fallback Desync Restore, Shield Box Follow, FOV Ring, Camera Aim Assist, WalkSpeed & JumpPower
AddConnection(RunService.RenderStepped:Connect(function(dt)
    if not Running then return end

    local char = LocalPlayer.Character
    local hrp = GetRoot(char)
    local hum = GetHumanoid(char)
    local cam = GetCamera()

    -- Fallback restore for headless/mock loops that step RenderStepped without BoundRenderSteps
    if DesyncRestoreCF and hrp and hrp.Parent then
        hrp.CFrame = DesyncRestoreCF
        DesyncRestoreCF = nil
    end

    -- 3D Shield Box visual follows character
    if State.ShieldEnabled and hrp and hum and hum.Health > 0 then
        local box = EnsureShieldBoxVisual(hrp)
        if box then
            box.CFrame = CFrame.new(hrp.Position)
        end
    elseif ShieldBoxPart then
        DestroyShieldBoxVisual()
    end

    -- Update current Silent Aim / Ragebot target cache
    if State.SilentAim or State.Ragebot then
        local rage = State.Ragebot
        GunHook.CurrentTargetPart = GetBestTarget(
            State.SilentAimFOV,
            rage and State.Ragebot360,
            State.SilentAimWallcheck,
            State.SilentAimHostile,
            rage
        )
    else
        GunHook.CurrentTargetPart = nil
    end

    -- Optional smooth Camera Aim Assist (only while holding a firearm or Taser; works on Mobile & PC)
    if State.AimAssist and cam and char and hum and hum.Health > 0 then
        local eqTool = char:FindFirstChildOfClass("Tool")
        local holdingAimTool = eqTool and (
            eqTool:GetAttribute("ToolType") == "Gun"
            or eqTool:GetAttribute("FireRate")
            or eqTool.Name == "Taser"
        )
        if holdingAimTool then
            local aimPart = GetBestTarget(State.AimAssistFOV, false, State.SilentAimWallcheck, State.SilentAimHostile, false)
            if aimPart and aimPart.Parent then
                local targetCF = CFrame.lookAt(cam.CFrame.Position, aimPart.Position)
                local alpha = math.clamp((1 - State.AimAssistSmooth * 0.85) * math.min(1, dt * 15), 0.05, 1)
                cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
            end
        end
    end

    -- Sync WalkSpeed (Region-Safe 2026 two-way clamping or Custom), Always Sprint & JumpPower
    if hum and hum.Health > 0 and hrp then
        if (State.MaxSpeed or State.AlwaysSprint) and hum.WalkSpeed > 0 then
            if SavedSpeedProps[hum] == nil then
                SavedSpeedProps[hum] = hum.WalkSpeed
            end
            if State.MaxSpeed then
                local targetWS = State.MaxSpeedMode == "RegionSafe"
                    and GetSafeRegionMaxSpeed(hrp.Position)
                    or State.CustomWalkSpeed
                if math.abs(hum.WalkSpeed - targetWS) > 0.5 then
                    hum.WalkSpeed = targetWS
                end
            elseif State.AlwaysSprint and hum.WalkSpeed < 24 then
                hum.WalkSpeed = 24
            end
        elseif SavedSpeedProps[hum] ~= nil then
            local origWS = SavedSpeedProps[hum]
            SavedSpeedProps[hum] = nil
            if hum.WalkSpeed > 0 then
                hum.WalkSpeed = origWS
            end
        end

        if State.JumpPowerEnabled then
            if not SavedJumpProps[hum] then
                SavedJumpProps[hum] = {
                    JumpPower = hum.JumpPower,
                    JumpHeight = hum.JumpHeight,
                }
            end
            pcall(function()
                if hum.UseJumpPower then
                    hum.JumpPower = State.CustomJumpPower
                else
                    local grav = Workspace.Gravity or 196.2
                    hum.JumpHeight = math.max(1, (State.CustomJumpPower * State.CustomJumpPower) / (2 * grav))
                end
            end)
        elseif SavedJumpProps[hum] then
            local origJ = SavedJumpProps[hum]
            SavedJumpProps[hum] = nil
            pcall(function()
                if origJ.JumpPower then hum.JumpPower = origJ.JumpPower end
                if origJ.JumpHeight then hum.JumpHeight = origJ.JumpHeight end
            end)
        end
    end
end))

-- Heartbeat: Shield Auto-Block / Spin / Desync, Ragebot AutoFire, Combo Loop, Noclip, Vehicle Fly, Auto-Arrest
AddConnection(RunService.Heartbeat:Connect(function(dt)
    if not Running then return end
    local now = os.clock()
    local char = LocalPlayer.Character
    local hrp = GetRoot(char)
    local hum = GetHumanoid(char)
    if not char or not hrp or not hum or hum.Health <= 0 then
        DesyncRestoreCF = nil
        return
    end

    -- Anti-KillPlane (Void & Extreme Fling Rescue)
    if State.AntiKillPlane and not IsGrabbingGuns then
        if hrp.Position.Y < -12 or (not State.Fly and not State.VehicleFly and hrp.Position.Y > 450) then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(hrp.Position.X, 105, hrp.Position.Z)
        end
    end

    if not State.Fly and not State.VehicleFly then
        MobileFlyInput.Up = 0
        MobileFlyInput.Down = 0
    end

    -- Character Fly (PC WASD/Cam + Mobile Thumbstick + UP/DN Pads)
    if State.Fly and not hum.SeatPart and not IsGrabbingGuns then
        local cam = GetCamera()
        local moveDir = hum.MoveDirection
        local vert = MobileFlyInput.Up - MobileFlyInput.Down
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
            vert = vert + 1
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            vert = vert - 1
        end
        local desired = Vector3.zero
        if moveDir.Magnitude > 0.05 and cam then
            local camLook = cam.CFrame.LookVector
            local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
            local fwdDot = flatLook.Magnitude > 0.01 and moveDir:Dot(flatLook.Unit) or 0
            desired = Vector3.new(moveDir.X, camLook.Y * fwdDot, moveDir.Z)
            if desired.Magnitude > 0.01 then desired = desired.Unit end
        end
        desired = desired * State.FlySpeed + Vector3.new(0, vert * State.FlySpeed * 0.85, 0)
        hrp.CFrame = hrp.CFrame + desired * math.min(dt, 0.05)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    -- Noclip (saves & restores original CanCollide states)
    if State.Noclip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                if SavedNoclipCollide[p] == nil then
                    SavedNoclipCollide[p] = p.CanCollide
                end
                p.CanCollide = false
            end
        end
    elseif next(SavedNoclipCollide) ~= nil then
        RestoreNoclipCollide()
    end

    -- Vehicle Fly & Vehicle Speed (PC + Mobile)
    if hum.SeatPart then
        local seat = hum.SeatPart
        local carModel = seat:FindFirstAncestorOfClass("Model")
        local basePart = (carModel and carModel.PrimaryPart) or seat
        if State.VehicleFly and basePart then
            local cam = GetCamera()
            local moveDir = hum.MoveDirection
            local vert = MobileFlyInput.Up - MobileFlyInput.Down
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
                vert = vert + 1
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                vert = vert - 1
            end
            local desired = Vector3.zero
            if moveDir.Magnitude > 0.05 and cam then
                local camLook = cam.CFrame.LookVector
                local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
                local fwdDot = flatLook.Magnitude > 0.01 and moveDir:Dot(flatLook.Unit) or 0
                desired = Vector3.new(moveDir.X, camLook.Y * fwdDot, moveDir.Z)
                if desired.Magnitude > 0.01 then desired = desired.Unit end
            end
            local grav = Workspace.Gravity or 196.2
            local gravComp = grav * math.clamp(dt, 1 / 120, 0.05) * 0.55
            desired = desired * State.VehicleFlySpeed + Vector3.new(0, vert * State.VehicleFlySpeed * 0.75 + gravComp, 0)
            basePart.AssemblyLinearVelocity = desired
            basePart.AssemblyAngularVelocity = Vector3.zero
        elseif State.VehicleSpeedMod and seat:IsA("VehicleSeat") and seat.ThrottleFloat ~= 0 then
            local v = basePart.AssemblyLinearVelocity
            local hor = Vector3.new(v.X, 0, v.Z)
            if hor.Magnitude > 5 and hor.Magnitude < 170 then
                basePart.AssemblyLinearVelocity = v + hor.Unit * (State.VehicleSpeedMult * 40 * dt)
            end
        end

        if State.VehicleFling and basePart then
            local targetPart = GetBestTarget(400, true, false, false, false)
            if targetPart and targetPart.Parent then
                local dir = (targetPart.Position - basePart.Position)
                if dir.Magnitude < 250 then
                    basePart.AssemblyAngularVelocity = Vector3.new(0, 65, 0)
                    if carModel and carModel.PrimaryPart then
                        carModel:PivotTo(CFrame.new(targetPart.Position + Vector3.new(0, 1.5, 0)))
                    else
                        basePart.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 1.5, 0))
                    end
                end
            end
        end
    end

    -- Shield Auto-Block & Riot Shield Hold
    local hasRiot, _, _, riotTool = GetRiotShieldStatus()
    local rageFiredThisTick = false

    -- Ragebot Auto-Fire
    if State.Ragebot and (now - LastRageAttempt) >= (1 / math.max(1, State.RagebotRate)) then
        local targetPart = GetBestTarget(
            State.SilentAimFOV,
            State.Ragebot360,
            State.SilentAimWallcheck,
            State.SilentAimHostile,
            true
        )
        if targetPart then
            local gun = GetBestRageWeapon()
            if gun then
                LastRageAttempt = now
                rageFiredThisTick = FireGunOnce(gun, targetPart)
            end
        end
    end

    -- .combo1 Auto-Loop Mode
    if State.ComboLoop and not IsRunningCombo and (now - LastComboLoop) >= State.ComboLoopInterval then
        local targetPart = GetBestTarget(State.SilentAimFOV, true, State.SilentAimWallcheck, State.SilentAimHostile, true)
        if targetPart then
            LastComboLoop = now
            ExecuteCombo1()
            rageFiredThisTick = true
        end
    end

    -- Melee KillAura (FE meleeEvent)
    if State.KillAura and Remotes.MeleeEvent and (now - LastKillAuraAttempt) >= (1 / math.max(1, State.KillAuraRate)) then
        for _, plr in ipairs(Players:GetPlayers()) do
            local validAura = (plr ~= LocalPlayer)
                and not (State.KillAuraTeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team)
            if validAura and IsValidCombatTarget(plr, State.KillAuraHostileOnly) then
                local tr = GetRoot(plr.Character)
                if tr and (tr.Position - hrp.Position).Magnitude <= State.KillAuraRange then
                    LastKillAuraAttempt = now
                    pcall(function() Remotes.MeleeEvent:FireServer(plr, 1, 1) end)
                    break
                end
            end
        end
    end

    if State.ShieldEnabled then
        -- Server-backed Riot Shield Hold & Facing
        if hasRiot and (State.ShieldMode == "Hybrid" or State.ShieldMode == "RiotOnly") then
            local holding = char:FindFirstChildOfClass("Tool")
            local canPeekShield = (not State.Ragebot) or State.RagebotPeekShield
            local canAutoEquip = (holding == nil) or (State.Ragebot and State.RagebotPeekShield)
            if State.ShieldAutoEquipOnIdle and canPeekShield and canAutoEquip and not rageFiredThisTick and not IsRunningCombo then
                if riotTool and holding ~= riotTool and (now - GunHook.LastRageShotClock) > 0.12 then
                    pcall(function() hum:EquipTool(riotTool) end)
                    holding = char:FindFirstChildOfClass("Tool") or riotTool
                end
            end

            local holdingRiot = (riotTool ~= nil and holding == riotTool) or (char:FindFirstChild("RiotShieldPart") ~= nil)
            if holdingRiot then
                if Remotes.ShieldEquipped and not LastShieldRemoteSent then
                    LastShieldRemoteSent = true
                    pcall(function() Remotes.ShieldEquipped:FireServer(true) end)
                end
                if not hum.SeatPart and not IsGrabbingGuns then
                    if State.ShieldSpinBlock then
                        local yaw = (now * State.ShieldSpinSpeed) % (math.pi * 2)
                        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
                    elseif State.ShieldAutoFaceShooter then
                        local threatPos = FindNearestShooterThreat(hrp.Position)
                        if threatPos then
                            local lookTarget = Vector3.new(threatPos.X, hrp.Position.Y, threatPos.Z)
                            if (lookTarget - hrp.Position).Magnitude > 0.5 then
                                hrp.CFrame = CFrame.lookAt(hrp.Position, lookTarget)
                            end
                        end
                    end
                end
            elseif LastShieldRemoteSent then
                LastShieldRemoteSent = false
                if Remotes.ShieldEquipped then
                    pcall(function() Remotes.ShieldEquipped:FireServer(false) end)
                end
            end
        elseif LastShieldRemoteSent then
            LastShieldRemoteSent = false
        end

        -- Micro Anti-Aim / CFrame Desync (when playing Inmate/Criminal or DesyncBox mode)
        if ShouldUseDesyncNow() and not hum.SeatPart and not IsGrabbingGuns then
            DesyncRestoreCF = hrp.CFrame
            DesyncPhase = DesyncPhase + dt * 28
            local s = State.ShieldDesyncStrength
            local ox = math.cos(DesyncPhase) * s
            local oz = math.sin(DesyncPhase) * s
            local oy = (math.sin(DesyncPhase * 1.7) > 0) and -0.35 or 0.25
            hrp.CFrame = DesyncRestoreCF * CFrame.new(ox, oy, oz) * CFrame.Angles(0, DesyncPhase, 0)
        end
    end

    -- Auto-Arrest nearby Criminals / Hostile Inmates (Guards)
    if State.AutoArrest and Remotes.ArrestPlayer and (now - LastArrestAttempt) >= 0.25 then
        local hc = HasTool("Handcuffs")
        if hc then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Team ~= Teams:FindFirstChild("Neutral") then
                    local tc = plr.Character
                    local tr = GetRoot(tc)
                    local th = GetHumanoid(tc)
                    if tc and tr and th and th.Health > 0 and not tc:GetAttribute("Arrested") then
                        local d = (tr.Position - hrp.Position).Magnitude
                        if d <= State.AutoArrestRange then
                            local isCrim = (plr.Team == Teams:FindFirstChild("Criminals"))
                            local isHostileInmate = (plr.Team == Teams:FindFirstChild("Inmates")) and (tc:GetAttribute("Hostile") or tc:GetAttribute("Tased"))
                            if isCrim or isHostileInmate then
                                LastArrestAttempt = now
                                task.spawn(function()
                                    pcall(function() Remotes.ArrestPlayer:InvokeServer(plr, 1) end)
                                end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    -- Slow 0.15s Utility Tick
    if (now - LastUtilityTick) >= 0.15 then
        LastUtilityTick = now

        pcall(EvaluatePlayerAnomalies)
        pcall(UpdateAllESP)
        pcall(UpdateHitboxExpander)

        if State.AntiFling then
            pcall(SafeSetAntiFlingEnabled, true)
        end

        -- Enemy Shield Bypass & Anti-Invisible
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local tc = plr.Character
                local shield = tc:FindFirstChild("RiotShieldPart")
                if shield and shield:IsA("BasePart") then
                    shield.CanQuery = not State.AntiRiotShield
                end
                if State.AntiInvisible then
                    local th = GetHumanoid(tc)
                    local anim = th and th:FindFirstChildOfClass("Animator")
                    if anim then
                        for _, tr in ipairs(anim:GetPlayingAnimationTracks()) do
                            local id = tr.Animation and tr.Animation.AnimationId or ""
                            if id:find("215384594") or id:find("18665825805") then
                                tr:AdjustWeight(0, 0)
                                tr:Stop(0)
                            end
                        end
                    end
                end
            end
        end

        -- Auto Reload
        if State.AutoReload and GunHook.Reload then
            local eq = char:FindFirstChildOfClass("Tool")
            if eq and (eq:GetAttribute("ToolType") == "Gun" or eq:GetAttribute("FireRate")) then
                local ammo = eq:GetAttribute("Local_CurrentAmmo")
                if type(ammo) == "number" and ammo <= 0 and (eq:GetAttribute("Local_ReloadSession") or 0) <= 0 then
                    pcall(task.spawn, GunHook.Reload)
                end
            end
        end

        -- Auto Tase
        if State.AutoTaze and (now - LastTaseAttempt) >= 1.2 then
            local taser = HasTool("Taser")
            local taserAmmo = taser and (taser:GetAttribute("CurrentAmmo") or taser:GetAttribute("Local_CurrentAmmo"))
            if taser and (taserAmmo == nil or taserAmmo > 0) then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if IsValidCombatTarget(plr, State.SilentAimHostile) and plr.Team ~= LocalPlayer.Team then
                        local tc = plr.Character
                        local tr = GetRoot(tc)
                        if tr and not tc:GetAttribute("Tased") and not tc:GetAttribute("Arrested") then
                            if (tr.Position - hrp.Position).Magnitude <= 45 and HasLineOfSight(hrp.Position, tr, tc) then
                                LastTaseAttempt = now
                                FireGunOnce(taser, tr, false)
                                break
                            end
                        end
                    end
                end
            end
        end

        -- Auto Heal (Cafeteria Trays + Snacks fallback)
        if State.AutoHeal and hum.Health <= State.AutoHealThreshold and (Remotes.EatFood or Remotes.SnackEaten) then
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            local healed = false
            if Remotes.EatFood then
                for _, fName in ipairs({ "Breakfast", "Lunch", "Dinner" }) do
                    local food = char:FindFirstChild(fName) or (bp and bp:FindFirstChild(fName))
                    if food and (now - (food:GetAttribute("Client_LastConsumedAt") or 0)) >= 3.1 then
                        local prev = char:FindFirstChildOfClass("Tool")
                        hum:EquipTool(food)
                        food:SetAttribute("Client_LastConsumedAt", now)
                        pcall(function() Remotes.EatFood:FireServer() end)
                        if prev and prev ~= food then hum:EquipTool(prev) else hum:UnequipTools() end
                        healed = true
                        break
                    end
                end
            end
            if not healed and Remotes.SnackEaten then
                for _, sName in ipairs({ "Chocolate", "Chips", "Soda", "Apple", "Donut" }) do
                    local snack = char:FindFirstChild(sName) or (bp and bp:FindFirstChild(sName))
                    if snack and (now - (snack:GetAttribute("Client_LastConsumedAt") or 0)) >= 2.5 then
                        local prev = char:FindFirstChildOfClass("Tool")
                        hum:EquipTool(snack)
                        snack:SetAttribute("Client_LastConsumedAt", now)
                        pcall(function() Remotes.SnackEaten:FireServer(snack) end)
                        if prev and prev ~= snack then hum:EquipTool(prev) else hum:UnequipTools() end
                        break
                    end
                end
            end
        end

        -- Auto Armor
        if State.AutoArmor and hum.MaxHealth <= 100 and Remotes.InteractWithItem then
            local pi = Workspace:FindFirstChild("Prison_ITEMS")
            local clothes = pi and pi:FindFirstChild("clothes")
            if clothes then
                for _, pick in ipairs(clothes:GetChildren()) do
                    local okP, piv = pcall(function() return pick:GetPivot() end)
                    if okP and piv and (piv.Position - hrp.Position).Magnitude <= 10 then
                        local pPart = pick:FindFirstChildWhichIsA("BasePart")
                        if pPart then
                            pcall(function() Remotes.InteractWithItem:InvokeServer(pPart) end)
                            break
                        end
                    end
                end
            end
        end

        -- Auto Pickup Dropped Items/Keycards
        if State.AutoPickupDropped and Remotes.GiverPressed then
            for _, ch in ipairs(Workspace:GetChildren()) do
                if ch:IsA("Model") and ch:GetAttribute("ToolName") then
                    local tName = ch:GetAttribute("ToolName")
                    if not HasTool(tName) then
                        local okP, piv = pcall(function() return ch:GetPivot() end)
                        if okP and piv and (piv.Position - hrp.Position).Magnitude <= 12.5 then
                            pcall(function() Remotes.GiverPressed:FireServer(ch) end)
                        end
                    end
                end
            end
        end

        -- Auto Detonate C4
        if State.AutoDetonateC4 and Remotes.ActivateC4 and HasTool("C4 Explosive") then
            for _, c4 in ipairs(CollectionService:GetTagged("C4")) do
                if c4:IsA("BasePart") and c4:GetAttribute("UserId") == LocalPlayer.UserId then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if IsValidCombatTarget(plr, false) then
                            local tr = GetRoot(plr.Character)
                            if tr and (tr.Position - c4.Position).Magnitude <= 22 and (hrp.Position - c4.Position).Magnitude > 24 then
                                local c4Tool = HasTool("C4 Explosive")
                                if c4Tool then
                                    local prev = char:FindFirstChildOfClass("Tool")
                                    hum:EquipTool(c4Tool)
                                    pcall(function() Remotes.ActivateC4:InvokeServer() end)
                                    if prev and prev ~= c4Tool then hum:EquipTool(prev) end
                                end
                                break
                            end
                        end
                    end
                end
            end
        end

        if UIHooks.UpdateBadges then
            pcall(UIHooks.UpdateBadges)
        end
    end
end))

AddConnection(UserInputService.JumpRequest:Connect(function()
    if not Running or not State.InfiniteJump then return end
    local hum = GetHumanoid(LocalPlayer.Character)
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

-- ============================================================================
-- // SECTION 9: KILLFEED PARSER, STREAK TRACKER & HEALTH CACHE
-- ============================================================================
local function TrackHealthForPlayer(plr)
    local function hookChar(char)
        if not char then return end
        task.spawn(function()
            local hum = char:WaitForChild("Humanoid", 6)
            if not hum or not Running then return end
            PlayerHealthCache[plr] = { cur = hum.Health, max = hum.MaxHealth }
            AddConnection(hum.HealthChanged:Connect(function(hp)
                PlayerHealthCache[plr] = { cur = hp, max = hum.MaxHealth }
            end))
            if plr == LocalPlayer then
                AddConnection(hum.Died:Connect(function()
                    local dr = GetRoot(char)
                    if dr then
                        LastDeathCFrame = dr.CFrame
                    end
                    if State.FastRespawn then
                        PerformFastRespawn()
                    end
                end))
            end
        end)
    end
    AddConnection(plr.CharacterAdded:Connect(hookChar))
    if plr.Character then hookChar(plr.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do
    TrackHealthForPlayer(p)
end
AddConnection(Players.PlayerAdded:Connect(TrackHealthForPlayer))
AddConnection(Players.PlayerRemoving:Connect(function(p)
    RemovePlayerESP(p)
    PlayerMonitor[p] = nil
    FlaggedCheaters[p.UserId] = nil
    KillerStreaks[p.Name] = nil
end))

-- Auto-Criminal on Arrested
if Remotes.ClientArrested then
    AddConnection(Remotes.ClientArrested.OnClientEvent:Connect(function()
        if State.AutoCriminal then
            task.delay(4.0, function()
                if not Running or not State.AutoCriminal then return end
                local spawnObj = Workspace:FindFirstChild("Criminals Spawn")
                local sp = spawnObj and spawnObj:FindFirstChild("SpawnLocation")
                if sp then
                    SafeTeleportCF(sp.CFrame + Vector3.new(0, 3, 0))
                end
            end)
        end
    end))
end

local function FindPlayerFuzzy(raw)
    if not raw or raw == "" then return nil end
    local atName = raw:match("@([%w_]+)")
    if atName then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == atName then return p end
        end
    end
    local clean = TrimString(raw:gsub("%s*%b()%s*$", ""))
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == clean or p.DisplayName == clean then
            return p
        end
    end
    return nil
end

local RecentKillCache = {}
local function ReadKillfeedRawText(child)
    if not child then return "" end
    local candidates = {}
    if child:IsA("StringValue") then
        table.insert(candidates, child.Value)
    end
    if child:IsA("TextLabel") or child:IsA("TextButton") then
        table.insert(candidates, child.Text)
    end
    local attrTxt = child:GetAttribute("Text") or child:GetAttribute("Message")
    if type(attrTxt) == "string" then
        table.insert(candidates, attrTxt)
    end
    table.insert(candidates, child.Name)
    for _, s in ipairs(candidates) do
        local trimmed = TrimString(tostring(s or "")):gsub("<[^>]+>", "")
        if trimmed ~= "" and trimmed:lower():find("killed") then
            return TrimString(trimmed)
        end
    end
    local okDesc, descs = pcall(function() return child:GetDescendants() end)
    if okDesc and type(descs) == "table" then
        for _, d in ipairs(descs) do
            local txt = nil
            if d:IsA("StringValue") then
                txt = d.Value
            elseif d:IsA("TextLabel") or d:IsA("TextButton") then
                txt = d.Text
            end
            if type(txt) == "string" then
                local clean = TrimString(txt:gsub("<[^>]+>", ""))
                if clean ~= "" and clean:lower():find("killed") then
                    return clean
                end
            end
        end
    end
    return TrimString(tostring(candidates[1] or child.Name):gsub("<[^>]+>", ""))
end

local function HandleKillfeedEntry(child)
    if not child then return end
    local lastRaw = nil
    local function process()
        if not Running or not child.Parent then return end
        local raw = ReadKillfeedRawText(child)
        if raw == "" or raw == lastRaw then return end
        local now = os.clock()
        if RecentKillCache[raw] and (now - RecentKillCache[raw]) < 0.15 then
            lastRaw = raw
            return
        end

        local hadRageTag = raw:lower():find("%[ragebot%]") ~= nil
        local cleanRaw = raw:gsub("<[^>]+>", ""):gsub("^%s*%[[Rr][Aa][Gg][Ee][Bb][Oo][Tt]%]%s*", "")
        local kRaw, vRaw, weapon = cleanRaw:match("^(.-)%s+[Kk]illed%s+(.-)%s+[Ww]ith%s+(.+)$")
        if not kRaw or not vRaw then
            kRaw, vRaw = cleanRaw:match("^(.-)%s+[Kk]illed%s+(.+)$")
            weapon = nil
        end
        if not kRaw or not vRaw then return end

        lastRaw = raw
        for k, ts in pairs(RecentKillCache) do
            if (now - ts) > 3.0 then
                RecentKillCache[k] = nil
            end
        end
        RecentKillCache[raw] = now

        local embeddedHp = nil
        local strippedK, hpStr = kRaw:match("^(.-)%s*%[(%d+)%%%]$")
        if strippedK and hpStr then
            kRaw = strippedK
            embeddedHp = tonumber(hpStr)
        end

        local kPlr = FindPlayerFuzzy(kRaw)
        local vPlr = FindPlayerFuzzy(vRaw)
        local kName = (kPlr and kPlr.Name) or TrimString(kRaw:gsub("%s*%b()%s*$", ""):gsub("%s*%b[]%s*$", ""))
        local vName = (vPlr and vPlr.Name) or TrimString(vRaw:gsub("%s*%b()%s*$", ""):gsub("%s*%b[]%s*$", ""))
        local wName = weapon and TrimString(weapon) or "Gun"

        KillerStreaks[vName] = 0
        local streak = (KillerStreaks[kName] or 0) + 1
        KillerStreaks[kName] = streak

        local hpPct = embeddedHp or 100
        if not embeddedHp and kPlr and PlayerHealthCache[kPlr] then
            local c = PlayerHealthCache[kPlr]
            hpPct = math.max(1, math.floor((c.cur / math.max(1, c.max)) * 100 + 0.5))
        end

        local isRage = hadRageTag or ((kPlr == LocalPlayer) and (State.Ragebot or (now - GunHook.LastRageShotClock) < 2.2))
        if UIHooks.PushKillfeed and State.ShowKillfeed then
            UIHooks.PushKillfeed(kPlr, kName, hpPct, vPlr, vName, wName, streak, isRage)
        end
    end

    process()
    pcall(function() AddConnection(child:GetPropertyChangedSignal("Name"):Connect(process)) end)
    if child:IsA("StringValue") then
        pcall(function() AddConnection(child:GetPropertyChangedSignal("Value"):Connect(process)) end)
    elseif child:IsA("TextLabel") or child:IsA("TextButton") then
        pcall(function() AddConnection(child:GetPropertyChangedSignal("Text"):Connect(process)) end)
    end
end

task.spawn(function()
    local kf = ReplicatedStorage:FindFirstChild("Killfeed") or ReplicatedStorage:WaitForChild("Killfeed", 10)
    if kf and Running then
        for _, existing in ipairs(kf:GetChildren()) do
            HandleKillfeedEntry(existing)
        end
        AddConnection(kf.ChildAdded:Connect(HandleKillfeedEntry))
    end
end)

-- ============================================================================
-- // SECTION 10: VIDEO-MATCHED HUD & SELF-CONTAINED OBSIDIAN KX HUB UI
-- ============================================================================
local SyncUICallbacks = {} -- table of functions to refresh UI widgets when commands change state

local MainGui = TrackInstance(Instance.new("ScreenGui"))
MainGui.Name = "PrisonLife_KX_HUD"
MainGui.IgnoreGuiInset = true
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.DisplayOrder = 100
MainGui.Parent = GetSafeGuiParent()

local function SafeMakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local activeInput, startPos, startFramePos
    handle:SetAttribute("PLKX_WasDragged", false)

    AddConnection(handle.InputBegan:Connect(function(inp)
        if dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            activeInput = inp
            startPos = inp.Position
            startFramePos = frame.Position
            handle:SetAttribute("PLKX_WasDragged", false)
            if inp.Changed then
                local changedConn
                changedConn = inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        if activeInput == inp then
                            dragging = false
                            activeInput = nil
                        end
                        if changedConn then changedConn:Disconnect() end
                    end
                end)
            end
        end
    end))

    AddConnection(UserInputService.InputEnded:Connect(function(inp)
        if dragging and inp == activeInput then
            dragging = false
            activeInput = nil
        end
    end))

    AddConnection(UserInputService.InputChanged:Connect(function(inp)
        if not dragging or not activeInput then return end
        local isSameTouch = (activeInput.UserInputType == Enum.UserInputType.Touch and inp == activeInput)
        local isMouseMove = (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and inp.UserInputType == Enum.UserInputType.MouseMovement)
        if isSameTouch or isMouseMove then
            local delta = inp.Position - startPos
            if delta.Magnitude > 7 then
                handle:SetAttribute("PLKX_WasDragged", true)
            end
            local cam = GetCamera()
            local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
            local absSz = frame.AbsoluteSize
            local uSz = frame.Size
            local w = math.max(16, (absSz and absSz.X > 0 and absSz.X) or (uSz and uSz.X.Offset > 0 and uSz.X.Offset) or 42)
            local h = math.max(16, (absSz and absSz.Y > 0 and absSz.Y) or (uSz and uSz.Y.Offset > 0 and uSz.Y.Offset) or 42)
            local ap = frame.AnchorPoint or Vector2.zero
            local scaleOffX = startFramePos.X.Scale * vp.X
            local scaleOffY = startFramePos.Y.Scale * vp.Y
            local rawX = startFramePos.X.Offset + delta.X
            local rawY = startFramePos.Y.Offset + delta.Y
            local clampedLeft = math.clamp(scaleOffX + rawX - ap.X * w, 0, math.max(0, vp.X - w))
            local clampedTop  = math.clamp(scaleOffY + rawY - ap.Y * h, 0, math.max(0, vp.Y - h))
            rawX = clampedLeft - scaleOffX + ap.X * w
            rawY = clampedTop - scaleOffY + ap.Y * h
            frame.Position = UDim2.new(startFramePos.X.Scale, rawX, startFramePos.Y.Scale, rawY)
        end
    end))
end

ESPContainer = TrackInstance(Instance.new("Folder"))
ESPContainer.Name = "PLKX_ESP_Objects"
ESPContainer.Parent = MainGui

local HUD = {}
local function EscapeRichText(str)
    return (tostring(str or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Central Aimbot / SilentAim FOV Circle
do
    local FOVRing = Instance.new("Frame")
    FOVRing.Name = "FOVRing"
    FOVRing.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVRing.Position = UDim2.fromScale(0.5, 0.5)
    FOVRing.Size = UDim2.fromOffset(220, 220)
    FOVRing.BackgroundTransparency = 1
    FOVRing.Visible = false
    FOVRing.Parent = MainGui
    Instance.new("UICorner", FOVRing).CornerRadius = UDim.new(1, 0)
    local FOVStroke = Instance.new("UIStroke", FOVRing)
    FOVStroke.Color = Palette.RedAlert
    FOVStroke.Thickness = 1.6
    FOVStroke.Transparency = 0.2
    HUD.FOVRing = FOVRing

    AddConnection(RunService.RenderStepped:Connect(function()
        if not Running then return end
        FOVRing.Visible = (State.SilentAim and State.SilentAimShowFOV)
        if FOVRing.Visible then
            local c = GetCursorOrCenterPos()
            FOVRing.Position = UDim2.fromOffset(c.X, c.Y)
            FOVRing.Size = UDim2.fromOffset(State.SilentAimFOV * 2, State.SilentAimFOV * 2)
            FOVStroke.Color = State.Ragebot and Palette.RageCrimson or Palette.RedAlert
        end
    end))
end

-- 1. Top-Left Fixed Combo Pill (.combo1) & Independently Draggable KX Crest Button
do
    local TopLeftBar = Instance.new("Frame")
    TopLeftBar.Name = "TopLeftBar"
    TopLeftBar.Position = UDim2.new(0, 14, 0, 56)
    TopLeftBar.Size = UDim2.fromOffset(96, 42)
    TopLeftBar.BackgroundTransparency = 1
    TopLeftBar.Parent = MainGui
    HUD.TopLeftBar = TopLeftBar

    local ComboBtn = Instance.new("TextButton")
    ComboBtn.Name = "ComboPillBtn"
    ComboBtn.Position = UDim2.fromOffset(0, 5)
    ComboBtn.Size = UDim2.fromOffset(92, 32)
    ComboBtn.BackgroundColor3 = Color3.fromRGB(48, 52, 60)
    ComboBtn.BackgroundTransparency = 0.15
    ComboBtn.Text = ".combo1"
    ComboBtn.Font = Enum.Font.GothamBold
    ComboBtn.TextSize = 13
    ComboBtn.TextColor3 = Color3.new(1, 1, 1)
    ComboBtn.AutoButtonColor = true
    ComboBtn.Parent = TopLeftBar
    Instance.new("UICorner", ComboBtn).CornerRadius = UDim.new(0, 10)
    local ComboStroke = Instance.new("UIStroke", ComboBtn)
    ComboStroke.Color = Color3.fromRGB(105, 112, 128)
    ComboStroke.Thickness = 1.2
    ComboStroke.Transparency = 0.35
    HUD.ComboBtn = ComboBtn
    HUD.ComboStroke = ComboStroke

    ComboBtn.Activated:Connect(function()
        ExecuteCombo1()
    end)

    local HubToggleBtn = Instance.new("TextButton")
    HubToggleBtn.Name = "KXCrestToggle"
    HubToggleBtn.Position = UDim2.fromOffset(114, 54)
    HubToggleBtn.Size = UDim2.fromOffset(42, 42)
    HubToggleBtn.BackgroundColor3 = Palette.BgDark
    HubToggleBtn.BackgroundTransparency = 0.08
    HubToggleBtn.Text = ""
    HubToggleBtn.AutoButtonColor = true
    HubToggleBtn.ZIndex = 5
    HubToggleBtn.Parent = MainGui
    Instance.new("UICorner", HubToggleBtn).CornerRadius = UDim.new(0, 11)
    local HubToggleStroke = Instance.new("UIStroke", HubToggleBtn)
    HubToggleStroke.Color = Palette.NeonBlue
    HubToggleStroke.Thickness = 1.9
    HUD.HubToggleBtn = HubToggleBtn

    local CrestLabel = Instance.new("TextLabel")
    CrestLabel.Size = UDim2.fromScale(1, 1)
    CrestLabel.BackgroundTransparency = 1
    CrestLabel.Text = "KX"
    CrestLabel.Font = Enum.Font.GothamBlack
    CrestLabel.TextSize = 15
    CrestLabel.TextColor3 = Palette.TextPrimary
    CrestLabel.TextStrokeColor3 = Palette.NeonBlue
    CrestLabel.TextStrokeTransparency = 0.65
    CrestLabel.Parent = HubToggleBtn

    SafeMakeDraggable(HubToggleBtn, HubToggleBtn)
end

-- 2. Top-Center [Alert] Banner
do
    local AlertLabel = Instance.new("TextLabel")
    AlertLabel.Name = "KXAlertBanner"
    AlertLabel.AnchorPoint = Vector2.new(0.5, 0)
    AlertLabel.Position = UDim2.new(0.5, 0, 0, 56)
    AlertLabel.Size = UDim2.new(0.55, 0, 0, 26)
    AlertLabel.BackgroundTransparency = 1
    AlertLabel.RichText = true
    AlertLabel.Font = Enum.Font.GothamBold
    AlertLabel.TextSize = 13
    AlertLabel.TextColor3 = Color3.new(1, 1, 1)
    AlertLabel.TextStrokeTransparency = 0.15
    AlertLabel.Text = ""
    AlertLabel.Visible = false
    AlertLabel.Parent = MainGui
    HUD.AlertLabel = AlertLabel

    local LastAlertToken = 0
    UIHooks.PushAlert = function(subject, message)
        if not State.ShowAlerts then return end
        LastAlertToken = LastAlertToken + 1
        local myToken = LastAlertToken
        AlertLabel.Text = string.format(
            '<font color="#FF4448">[Alert] %s</font> <font color="#FFFFFF">%s</font>',
            EscapeRichText(subject),
            EscapeRichText(message)
        )
        AlertLabel.TextTransparency = 0
        AlertLabel.TextStrokeTransparency = 0.15
        AlertLabel.Visible = true
        task.delay(State.AlertDuration, function()
            if LastAlertToken == myToken and AlertLabel and AlertLabel.Parent then
                AlertLabel.Visible = false
            end
        end)
    end
end

-- 3. Top-Right KX ADMIN Command Bar + Output Drawer
do
    local KXBarFrame = Instance.new("Frame")
    KXBarFrame.Name = "KXAdminBar"
    KXBarFrame.AnchorPoint = Vector2.new(1, 0)
    KXBarFrame.Position = UDim2.new(1, -12, 0, 54)
    KXBarFrame.Size = UDim2.fromOffset(232, 46)
    KXBarFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    KXBarFrame.BackgroundTransparency = 0.25
    KXBarFrame.Parent = MainGui
    Instance.new("UICorner", KXBarFrame).CornerRadius = UDim.new(0, 7)
    local KXBarStroke = Instance.new("UIStroke", KXBarFrame)
    KXBarStroke.Color = Color3.fromRGB(115, 125, 145)
    KXBarStroke.Thickness = 1
    KXBarStroke.Transparency = 0.45
    HUD.KXBarFrame = KXBarFrame

    local KXTitleLbl = Instance.new("TextLabel")
    KXTitleLbl.Position = UDim2.fromOffset(8, 2)
    KXTitleLbl.Size = UDim2.fromOffset(160, 14)
    KXTitleLbl.BackgroundTransparency = 1
    KXTitleLbl.Font = Enum.Font.GothamSemibold
    KXTitleLbl.TextSize = 10
    KXTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    KXTitleLbl.TextColor3 = Palette.TextMuted
    KXTitleLbl.Text = "KX ADMIN"
    KXTitleLbl.Parent = KXBarFrame

    local KXInput = Instance.new("TextBox")
    KXInput.Name = "CmdBox"
    KXInput.Position = UDim2.fromOffset(8, 17)
    KXInput.Size = UDim2.fromOffset(170, 24)
    KXInput.BackgroundTransparency = 1
    KXInput.Font = Enum.Font.GothamMedium
    KXInput.TextSize = 12
    KXInput.TextXAlignment = Enum.TextXAlignment.Left
    KXInput.PlaceholderText = "type here..."
    KXInput.PlaceholderColor3 = Color3.fromRGB(130, 140, 158)
    KXInput.TextColor3 = Palette.TextPrimary
    KXInput.ClearTextOnFocus = false
    KXInput.Text = ""
    KXInput.Parent = KXBarFrame
    HUD.KXInput = KXInput

    local KXCmdBtn = Instance.new("TextButton")
    KXCmdBtn.Name = "CmdBtn"
    KXCmdBtn.AnchorPoint = Vector2.new(1, 0.5)
    KXCmdBtn.Position = UDim2.new(1, -6, 0.5, 0)
    KXCmdBtn.Size = UDim2.fromOffset(42, 30)
    KXCmdBtn.BackgroundColor3 = Color3.fromRGB(36, 42, 56)
    KXCmdBtn.BackgroundTransparency = 0.15
    KXCmdBtn.Font = Enum.Font.GothamBold
    KXCmdBtn.TextSize = 11
    KXCmdBtn.TextColor3 = Palette.TextPrimary
    KXCmdBtn.Text = "CMD"
    KXCmdBtn.Parent = KXBarFrame
    Instance.new("UICorner", KXCmdBtn).CornerRadius = UDim.new(0, 6)
    local KXCmdStroke = Instance.new("UIStroke", KXCmdBtn)
    KXCmdStroke.Color = Palette.NeonBlue
    KXCmdStroke.Transparency = 0.65
    HUD.KXCmdBtn = KXCmdBtn

    local KXLogDrawer = Instance.new("Frame")
    KXLogDrawer.Name = "KXCmdDrawer"
    KXLogDrawer.AnchorPoint = Vector2.new(1, 0)
    KXLogDrawer.Position = UDim2.new(1, 0, 1, 6)
    KXLogDrawer.Size = UDim2.fromOffset(232, 128)
    KXLogDrawer.BackgroundColor3 = Palette.BgDark
    KXLogDrawer.BackgroundTransparency = 0.12
    KXLogDrawer.Visible = false
    KXLogDrawer.Parent = KXBarFrame
    Instance.new("UICorner", KXLogDrawer).CornerRadius = UDim.new(0, 8)
    local KXDrawerStroke = Instance.new("UIStroke", KXLogDrawer)
    KXDrawerStroke.Color = Palette.NeonBlue
    KXDrawerStroke.Transparency = 0.55

    local KXDrawerClose = Instance.new("TextButton")
    KXDrawerClose.AnchorPoint = Vector2.new(1, 0)
    KXDrawerClose.Position = UDim2.new(1, -4, 0, 4)
    KXDrawerClose.Size = UDim2.fromOffset(20, 18)
    KXDrawerClose.BackgroundColor3 = Palette.BgCard
    KXDrawerClose.Font = Enum.Font.GothamBold
    KXDrawerClose.TextSize = 11
    KXDrawerClose.TextColor3 = Palette.TextMuted
    KXDrawerClose.Text = "x"
    KXDrawerClose.ZIndex = 4
    KXDrawerClose.Parent = KXLogDrawer
    Instance.new("UICorner", KXDrawerClose).CornerRadius = UDim.new(0, 4)
    KXDrawerClose.Activated:Connect(function()
        KXLogDrawer.Visible = false
    end)

    local KXLogScroll = Instance.new("ScrollingFrame")
    KXLogScroll.Position = UDim2.fromOffset(6, 6)
    KXLogScroll.Size = UDim2.new(1, -28, 1, -12)
    KXLogScroll.BackgroundTransparency = 1
    KXLogScroll.ScrollBarThickness = 3
    KXLogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    KXLogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    KXLogScroll.Parent = KXLogDrawer
    local KXLogList = Instance.new("UIListLayout", KXLogScroll)
    KXLogList.Padding = UDim.new(0, 2)
    KXLogList.SortOrder = Enum.SortOrder.LayoutOrder

    local CmdLogCount = 0
    UIHooks.LogCmd = function(msg, color)
        KXLogDrawer.Visible = true
        CmdLogCount = CmdLogCount + 1
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -4, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 11
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextColor3 = color or Palette.TextPrimary
        lbl.Text = msg
        lbl.LayoutOrder = CmdLogCount
        lbl.Parent = KXLogScroll
        local children = KXLogScroll:GetChildren()
        if #children > 24 then
            for _, c in ipairs(children) do
                if c:IsA("TextLabel") and c.LayoutOrder <= (CmdLogCount - 20) then
                    c:Destroy()
                end
            end
        end
    end
end

-- 4. Right-Side 3 Circular Action Buttons (Ghost, Clean, Shield) + Mobile Fly Pads
do
    local RightActionStack = Instance.new("Frame")
    RightActionStack.Name = "RightQuickActions"
    RightActionStack.AnchorPoint = Vector2.new(1, 1)
    RightActionStack.Position = UDim2.new(1, -22, 1, -118)
    RightActionStack.Size = UDim2.fromOffset(48, 220)
    RightActionStack.BackgroundTransparency = 1
    RightActionStack.Parent = MainGui
    HUD.RightActionStack = RightActionStack

    local RightStackLayout = Instance.new("UIListLayout", RightActionStack)
    RightStackLayout.FillDirection = Enum.FillDirection.Vertical
    RightStackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    RightStackLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    RightStackLayout.Padding = UDim.new(0, 9)
    RightStackLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function MakeCircularActionBtn(order, symbolText, tipText, callback)
        local btn = Instance.new("TextButton")
        btn.LayoutOrder = order
        btn.Size = UDim2.fromOffset(44, 44)
        btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
        btn.BackgroundTransparency = 0.2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Text = symbolText
        btn.AutoButtonColor = true
        btn.Parent = RightActionStack
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local st = Instance.new("UIStroke", btn)
        st.Color = Color3.fromRGB(165, 175, 195)
        st.Thickness = 1.4
        st.Transparency = 0.4

        local sub = Instance.new("TextLabel")
        sub.AnchorPoint = Vector2.new(0.5, 1)
        sub.Position = UDim2.new(0.5, 0, 1, -2)
        sub.Size = UDim2.new(1, 0, 0, 10)
        sub.BackgroundTransparency = 1
        sub.Font = Enum.Font.GothamBold
        sub.TextSize = 7
        sub.TextColor3 = Palette.TextMuted
        sub.Text = tipText
        sub.Parent = btn

        btn.Activated:Connect(callback)
        return btn, st
    end

    local FlyPadStack = Instance.new("Frame")
    FlyPadStack.Name = "FlyPadStack"
    FlyPadStack.AnchorPoint = Vector2.new(1, 1)
    FlyPadStack.Position = UDim2.new(1, -78, 1, -118)
    FlyPadStack.Size = UDim2.fromOffset(48, 76)
    FlyPadStack.BackgroundTransparency = 1
    FlyPadStack.Visible = false
    FlyPadStack.Parent = MainGui
    HUD.FlyPadStack = FlyPadStack

    local FlyPadLayout = Instance.new("UIListLayout", FlyPadStack)
    FlyPadLayout.FillDirection = Enum.FillDirection.Vertical
    FlyPadLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    FlyPadLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    FlyPadLayout.Padding = UDim.new(0, 8)
    FlyPadLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function BindFlyHoldButton(btn, fieldName)
        local activeInp = nil
        AddConnection(btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                activeInp = inp
                MobileFlyInput[fieldName] = 1
                if inp.Changed then
                    local changedConn
                    changedConn = inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End then
                            if activeInp == inp then
                                activeInp = nil
                                MobileFlyInput[fieldName] = 0
                            end
                            if changedConn then changedConn:Disconnect() end
                        end
                    end)
                end
            end
        end))
        AddConnection(btn.InputEnded:Connect(function(inp)
            if inp == activeInp or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                activeInp = nil
                MobileFlyInput[fieldName] = 0
            end
        end))
        AddConnection(UserInputService.InputEnded:Connect(function(inp)
            if activeInp and inp == activeInp then
                activeInp = nil
                MobileFlyInput[fieldName] = 0
            end
        end))
    end

    local FlyUpBtn = Instance.new("TextButton")
    FlyUpBtn.Name = "FlyUpBtn"
    FlyUpBtn.LayoutOrder = 1
    FlyUpBtn.Size = UDim2.fromOffset(44, 32)
    FlyUpBtn.BackgroundColor3 = Color3.fromRGB(25, 95, 145)
    FlyUpBtn.BackgroundTransparency = 0.2
    FlyUpBtn.Font = Enum.Font.GothamBold
    FlyUpBtn.TextSize = 11
    FlyUpBtn.TextColor3 = Color3.new(1, 1, 1)
    FlyUpBtn.Text = "UP"
    FlyUpBtn.Visible = false
    FlyUpBtn.Parent = FlyPadStack
    Instance.new("UICorner", FlyUpBtn).CornerRadius = UDim.new(0, 8)
    BindFlyHoldButton(FlyUpBtn, "Up")
    HUD.FlyUpBtn = FlyUpBtn

    local FlyDownBtn = Instance.new("TextButton")
    FlyDownBtn.Name = "FlyDownBtn"
    FlyDownBtn.LayoutOrder = 2
    FlyDownBtn.Size = UDim2.fromOffset(44, 32)
    FlyDownBtn.BackgroundColor3 = Color3.fromRGB(25, 95, 145)
    FlyDownBtn.BackgroundTransparency = 0.2
    FlyDownBtn.Font = Enum.Font.GothamBold
    FlyDownBtn.TextSize = 11
    FlyDownBtn.TextColor3 = Color3.new(1, 1, 1)
    FlyDownBtn.Text = "DN"
    FlyDownBtn.Visible = false
    FlyDownBtn.Parent = FlyPadStack
    Instance.new("UICorner", FlyDownBtn).CornerRadius = UDim.new(0, 8)
    BindFlyHoldButton(FlyDownBtn, "Down")
    HUD.FlyDownBtn = FlyDownBtn

    local BtnPose, BtnPoseStroke = MakeCircularActionBtn(1, "⚡", "GHOST", function()
        SetFEInvisible(not State.FEInvisible)
        if UIHooks.PushAlert then
            UIHooks.PushAlert("KX", State.FEInvisible and "FE Ghost ON" or "FE Ghost OFF")
        end
        if UIHooks.UpdateBadges then UIHooks.UpdateBadges() end
        if UIHooks.SyncHub then UIHooks.SyncHub() end
    end)
    BtnPose.Name = "QuickBtn_GHOST"
    HUD.BtnPoseStroke = BtnPoseStroke

    local BtnClean = MakeCircularActionBtn(2, "✦", "CLEAN", function()
        CleanCharacterEffects()
        if UIHooks.PushAlert then
            UIHooks.PushAlert("KX", "Cleared HUD & Unstuck Character")
        end
    end)
    BtnClean.Name = "QuickBtn_CLEAN"

    local BtnShield, BtnShieldStroke = MakeCircularActionBtn(3, "🛡", "SHIELD", function()
        SetShieldState(not State.ShieldEnabled)
        if UIHooks.PushAlert then
            UIHooks.PushAlert("Shield", State.ShieldEnabled and ("Bullet Shield ON (" .. State.ShieldMode .. ")") or "Bullet Shield OFF")
        end
        if UIHooks.SyncHub then UIHooks.SyncHub() end
    end)
    BtnShield.Name = "QuickBtn_SHIELD"
    HUD.BtnShieldStroke = BtnShieldStroke
end

-- 5. Bottom-Center Shield HP Pill + Custom Multi-Line Killfeed
do
    local ShieldBadge = Instance.new("Frame")
    ShieldBadge.Name = "ShieldHPBadge"
    ShieldBadge.AnchorPoint = Vector2.new(0.5, 1)
    ShieldBadge.Position = UDim2.new(0.5, 0, 1, -88)
    ShieldBadge.Size = UDim2.fromOffset(92, 26)
    ShieldBadge.BackgroundColor3 = Color3.fromRGB(16, 22, 34)
    ShieldBadge.BackgroundTransparency = 0.22
    ShieldBadge.Visible = false
    ShieldBadge.Parent = MainGui
    Instance.new("UICorner", ShieldBadge).CornerRadius = UDim.new(0, 13)
    local ShieldBadgeStroke = Instance.new("UIStroke", ShieldBadge)
    ShieldBadgeStroke.Color = Color3.fromRGB(75, 163, 255)
    ShieldBadgeStroke.Thickness = 1.4
    ShieldBadgeStroke.Transparency = 0.25
    HUD.ShieldBadge = ShieldBadge

    local ShieldBadgeLabel = Instance.new("TextLabel")
    ShieldBadgeLabel.Size = UDim2.fromScale(1, 1)
    ShieldBadgeLabel.BackgroundTransparency = 1
    ShieldBadgeLabel.RichText = true
    ShieldBadgeLabel.Font = Enum.Font.GothamBold
    ShieldBadgeLabel.TextSize = 13
    ShieldBadgeLabel.TextColor3 = Color3.fromRGB(220, 238, 255)
    ShieldBadgeLabel.Text = '<font color="#4BA3FF">🛡</font> 180'
    ShieldBadgeLabel.Parent = ShieldBadge
    HUD.ShieldBadgeLabel = ShieldBadgeLabel

    local KillfeedStack = Instance.new("Frame")
    KillfeedStack.Name = "KXKillfeed"
    KillfeedStack.AnchorPoint = Vector2.new(0.5, 1)
    KillfeedStack.Position = UDim2.new(0.5, 0, 1, -118)
    KillfeedStack.Size = UDim2.fromOffset(520, 114)
    KillfeedStack.BackgroundTransparency = 1
    KillfeedStack.Parent = MainGui
    HUD.KillfeedStack = KillfeedStack

    local KillfeedLayout = Instance.new("UIListLayout", KillfeedStack)
    KillfeedLayout.FillDirection = Enum.FillDirection.Vertical
    KillfeedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    KillfeedLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    KillfeedLayout.Padding = UDim.new(0, 2)
    KillfeedLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local KillfeedRows = {}
    local KillfeedOrder = 0
    local roundNum = math.round or function(x) return math.floor(x + 0.5) end
    local function ColorToHex(c)
        return string.format(
            "#%02X%02X%02X",
            math.clamp(roundNum(c.R * 255), 0, 255),
            math.clamp(roundNum(c.G * 255), 0, 255),
            math.clamp(roundNum(c.B * 255), 0, 255)
        )
    end

    UIHooks.PushKillfeed = function(killerPlr, killerName, hpPct, victimPlr, victimName, weaponName, streak, isRagebot)
        if not State.ShowKillfeed then return end
        KillfeedOrder = KillfeedOrder + 1

        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, 0, 0, 17)
        row.BackgroundTransparency = 1
        row.RichText = true
        row.Font = Enum.Font.GothamBold
        row.TextSize = 13
        row.TextStrokeTransparency = 0.2
        row.LayoutOrder = KillfeedOrder

        local streakNum = tonumber(streak) or 1
        if isRagebot then
            row.Text = string.format(
                '<font color="#E1303A">[RAGEBOT] %s killed %s %dx Streak</font>',
                EscapeRichText(killerName),
                EscapeRichText(victimName),
                streakNum
            )
        else
            local kHex = ColorToHex(GetTeamColor(killerPlr))
            local vHex = ColorToHex(GetTeamColor(victimPlr))
            local hpHex = (hpPct >= 65 and "#58F26E") or (hpPct >= 30 and "#FFD646") or "#FF4448"
            local streakSuffix = (streakNum >= 2)
                and string.format(' <font color="#FFD646">%dx Streak</font>', streakNum)
                or ""
            row.Text = string.format(
                '<font color="%s">%s</font> <font color="%s">[%d%%]</font> <font color="#EAEAEA">killed</font> <font color="%s">%s</font> <font color="#D8DEE9">with %s</font>%s',
                kHex, EscapeRichText(killerName),
                hpHex, hpPct,
                vHex, EscapeRichText(victimName),
                EscapeRichText(weaponName),
                streakSuffix
            )
        end
        row.Parent = KillfeedStack
        table.insert(KillfeedRows, row)

        while #KillfeedRows > 5 do
            local oldRow = table.remove(KillfeedRows, 1)
            if oldRow and oldRow.Parent then oldRow:Destroy() end
        end

        task.delay(6.5, function()
            if row and row.Parent then
                row:Destroy()
                local idx = table.find(KillfeedRows, row)
                if idx then table.remove(KillfeedRows, idx) end
            end
        end)
    end

    UIHooks.ClearHUD = function()
        for _, r in ipairs(KillfeedRows) do
            if r and r.Parent then r:Destroy() end
        end
        table.clear(KillfeedRows)
        if HUD.AlertLabel then HUD.AlertLabel.Visible = false end
    end
end

UIHooks.SyncHub = function()
    for _, fn in ipairs(SyncUICallbacks) do
        pcall(fn)
    end
end

UIHooks.UpdateBadges = function()
    HUD.TopLeftBar.Visible = State.ShowComboButton
    HUD.ComboBtn.Visible = State.ShowComboButton
    HUD.KXBarFrame.Visible = State.ShowKXBar
    HUD.RightActionStack.Visible = State.ShowRightActions
    HUD.KillfeedStack.Visible = State.ShowKillfeed

    HUD.BtnShieldStroke.Color = State.ShieldEnabled and Palette.NeonBlue or Color3.fromRGB(165, 175, 195)
    HUD.BtnShieldStroke.Transparency = State.ShieldEnabled and 0.05 or 0.45
    HUD.BtnPoseStroke.Color = State.FEInvisible and Palette.NeonCyan or Color3.fromRGB(165, 175, 195)
    HUD.BtnPoseStroke.Transparency = State.FEInvisible and 0.05 or 0.45
    HUD.ComboStroke.Color = State.ComboLoop and Palette.NeonBlue or Color3.fromRGB(105, 112, 128)

    local hum = GetHumanoid(LocalPlayer.Character)
    local isSeated = (hum ~= nil and hum.SeatPart ~= nil)
    local showFlyPads = State.Fly or (State.VehicleFly and isSeated)
    if HUD.FlyPadStack then
        HUD.FlyPadStack.Visible = showFlyPads
    end
    HUD.FlyUpBtn.Visible = showFlyPads
    HUD.FlyDownBtn.Visible = showFlyPads

    local hasRiot, hp = GetRiotShieldStatus()
    if State.ShowShieldBadge and (hasRiot or State.ShieldEnabled) then
        HUD.ShieldBadge.Visible = true
        if hasRiot and hp then
            HUD.ShieldBadgeLabel.Text = '<font color="#4BA3FF">🛡</font> ' .. tostring(math.floor(hp))
        elseif hasRiot then
            HUD.ShieldBadgeLabel.Text = '<font color="#4BA3FF">🛡</font> 180'
        elseif State.ShieldEnabled then
            HUD.ShieldBadgeLabel.Text = '<font color="#4BA3FF">🛡</font> ' .. State.ShieldMode:upper()
        else
            HUD.ShieldBadgeLabel.Text = '<font color="#4BA3FF">🛡</font> 180'
        end
    else
        HUD.ShieldBadge.Visible = false
    end
end

-- 6. Self-Contained Neon-Blue Obsidian Tabbed Hub Window
local SetHubVisible
local CreateTab
do
    local HubWindow = Instance.new("Frame")
    HubWindow.Name = "KXHubWindow"
    local camVP = (GetCamera() and GetCamera().ViewportSize) or Vector2.new(900, 600)
    local winW = math.clamp(camVP.X - 32, 340, 540)
    local winH = math.clamp(camVP.Y - 96, 290, 390)
    HubWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    HubWindow.Position = UDim2.fromScale(0.5, 0.5)
    HubWindow.Size = UDim2.fromOffset(winW, winH)
    HubWindow.BackgroundColor3 = Palette.BgDark
    HubWindow.BackgroundTransparency = 0.04
    HubWindow.Visible = State.HubVisible
    HubWindow.ZIndex = 10
    HubWindow.Parent = MainGui
    Instance.new("UICorner", HubWindow).CornerRadius = UDim.new(0, 12)
    local HubStroke = Instance.new("UIStroke", HubWindow)
    HubStroke.Color = Palette.NeonBlue
    HubStroke.Thickness = 1.5
    HubStroke.Transparency = 0.2

    local HubHeader = Instance.new("Frame")
    HubHeader.Size = UDim2.new(1, 0, 0, 38)
    HubHeader.BackgroundColor3 = Palette.BgPanel
    HubHeader.BorderSizePixel = 0
    HubHeader.Parent = HubWindow
    Instance.new("UICorner", HubHeader).CornerRadius = UDim.new(0, 12)
    SafeMakeDraggable(HubWindow, HubHeader)

    local HubTitle = Instance.new("TextLabel")
    HubTitle.Position = UDim2.fromOffset(14, 0)
    HubTitle.Size = UDim2.new(1, -60, 1, 0)
    HubTitle.BackgroundTransparency = 1
    HubTitle.Font = Enum.Font.GothamBold
    HubTitle.TextSize = 14
    HubTitle.TextXAlignment = Enum.TextXAlignment.Left
    HubTitle.TextColor3 = Palette.TextPrimary
    HubTitle.Text = "PRISON LIFE 2026  •  KX SHIELD EDITION"
    HubTitle.Parent = HubHeader

    local HubCloseBtn = Instance.new("TextButton")
    HubCloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    HubCloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
    HubCloseBtn.Size = UDim2.fromOffset(26, 26)
    HubCloseBtn.BackgroundColor3 = Palette.BgCard
    HubCloseBtn.Font = Enum.Font.GothamBold
    HubCloseBtn.TextSize = 13
    HubCloseBtn.TextColor3 = Palette.TextPrimary
    HubCloseBtn.Text = "X"
    HubCloseBtn.Parent = HubHeader
    Instance.new("UICorner", HubCloseBtn).CornerRadius = UDim.new(0, 6)

    SetHubVisible = function(v)
        State.HubVisible = v
        HubWindow.Visible = v
        if v and UIHooks.SyncHub then
            UIHooks.SyncHub()
        end
    end
    HubCloseBtn.Activated:Connect(function() SetHubVisible(false) end)
    HUD.HubToggleBtn.Activated:Connect(function()
        if HUD.HubToggleBtn:GetAttribute("PLKX_WasDragged") then
            HUD.HubToggleBtn:SetAttribute("PLKX_WasDragged", false)
            return
        end
        SetHubVisible(not State.HubVisible)
    end)

    local TabRail = Instance.new("ScrollingFrame")
    TabRail.Position = UDim2.fromOffset(8, 46)
    TabRail.Size = UDim2.new(0, 118, 1, -54)
    TabRail.BackgroundColor3 = Palette.BgPanel
    TabRail.BorderSizePixel = 0
    TabRail.ScrollBarThickness = 2
    TabRail.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabRail.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabRail.Parent = HubWindow
    Instance.new("UICorner", TabRail).CornerRadius = UDim.new(0, 8)
    local TabRailLayout = Instance.new("UIListLayout", TabRail)
    TabRailLayout.Padding = UDim.new(0, 5)
    TabRailLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local TabRailPad = Instance.new("UIPadding", TabRail)
    TabRailPad.PaddingTop = UDim.new(0, 6)
    TabRailPad.PaddingBottom = UDim.new(0, 6)

    local PagesHolder = Instance.new("Frame")
    PagesHolder.Position = UDim2.fromOffset(132, 46)
    PagesHolder.Size = UDim2.new(1, -140, 1, -54)
    PagesHolder.BackgroundColor3 = Palette.BgPanel
    PagesHolder.BorderSizePixel = 0
    PagesHolder.Parent = HubWindow
    Instance.new("UICorner", PagesHolder).CornerRadius = UDim.new(0, 8)

    local TabButtons, TabPages = {}, {}
    local function SelectTab(tabName)
        for name, pg in pairs(TabPages) do
            pg.Visible = (name == tabName)
        end
        for name, btn in pairs(TabButtons) do
            local active = (name == tabName)
            btn.BackgroundColor3 = active and Palette.NeonBlue or Palette.BgCard
            btn.TextColor3 = active and Color3.new(1, 1, 1) or Palette.TextMuted
        end
    end

    local TabCount = 0
    CreateTab = function(title)
        TabCount = TabCount + 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 32)
        btn.BackgroundColor3 = Palette.BgCard
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextColor3 = Palette.TextMuted
        btn.Text = title
    btn.LayoutOrder = TabCount
    btn.Parent = TabRail
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.fromScale(1, 1)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Palette.NeonBlue
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.Parent = PagesHolder
    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 10)

    TabButtons[title] = btn
    TabPages[title] = scroll
    btn.Activated:Connect(function() SelectTab(title) end)
    if TabCount == 1 then SelectTab(title) end

    local elemOrder = 0
    local api = {}

    function api:Section(name)
        elemOrder = elemOrder + 1
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextColor3 = Palette.NeonCyan
        lbl.Text = "  " .. name:upper()
        lbl.LayoutOrder = elemOrder
        lbl.Parent = scroll
    end

    function api:Toggle(labelText, stateKey, onChange)
        elemOrder = elemOrder + 1
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 34)
        card.BackgroundColor3 = Palette.BgCard
        card.LayoutOrder = elemOrder
        card.Parent = scroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

        local txt = Instance.new("TextLabel")
        txt.Position = UDim2.fromOffset(10, 0)
        txt.Size = UDim2.new(1, -60, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamMedium
        txt.TextSize = 12
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.TextColor3 = Palette.TextPrimary
        txt.Text = labelText
        txt.Parent = card

        local pill = Instance.new("TextButton")
        pill.AnchorPoint = Vector2.new(1, 0.5)
        pill.Position = UDim2.new(1, -8, 0.5, 0)
        pill.Size = UDim2.fromOffset(42, 20)
        pill.Text = ""
        pill.Parent = card
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(16, 16)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Parent = pill
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local function render()
            local val = (State[stateKey] == true)
            pill.BackgroundColor3 = val and Palette.ToggleOn or Palette.ToggleOff
            knob.Position = val and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
        end
        render()
        table.insert(SyncUICallbacks, render)

        pill.Activated:Connect(function()
            State[stateKey] = not State[stateKey]
            render()
            if onChange then onChange(State[stateKey]) end
            UIHooks.UpdateBadges()
        end)
    end

    function api:Slider(labelText, stateKey, minV, maxV, stepV, onChange)
        elemOrder = elemOrder + 1
        stepV = stepV or 1
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 44)
        card.BackgroundColor3 = Palette.BgCard
        card.LayoutOrder = elemOrder
        card.Parent = scroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

        local txt = Instance.new("TextLabel")
        txt.Position = UDim2.fromOffset(10, 3)
        txt.Size = UDim2.new(1, -70, 0, 18)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamMedium
        txt.TextSize = 12
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.TextColor3 = Palette.TextPrimary
        txt.Text = labelText
        txt.Parent = card

        local valLbl = Instance.new("TextLabel")
        valLbl.AnchorPoint = Vector2.new(1, 0)
        valLbl.Position = UDim2.new(1, -10, 0, 3)
        valLbl.Size = UDim2.fromOffset(55, 18)
        valLbl.BackgroundTransparency = 1
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 12
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.TextColor3 = Palette.NeonCyan
        valLbl.Parent = card

        local track = Instance.new("TextButton")
        track.Position = UDim2.fromOffset(10, 26)
        track.Size = UDim2.new(1, -20, 0, 10)
        track.BackgroundColor3 = Palette.ToggleOff
        track.Text = ""
        track.Parent = card
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Palette.NeonBlue
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local function render()
            local v = math.clamp(tonumber(State[stateKey]) or minV, minV, maxV)
            local ratio = (v - minV) / math.max(0.0001, (maxV - minV))
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            valLbl.Text = (stepV < 1) and string.format("%.2f", v) or tostring(v)
        end
        render()
        table.insert(SyncUICallbacks, render)

        local sliding = false
        local activeSliderInput = nil
        local function applyAtX(absX)
            local rel = math.clamp((absX - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            local raw = minV + rel * (maxV - minV)
            local snapped = math.floor(raw / stepV + 0.5) * stepV
            snapped = math.clamp(snapped, minV, maxV)
            State[stateKey] = snapped
            render()
            if onChange then onChange(snapped) end
        end

        AddConnection(track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                if sliding and activeSliderInput and activeSliderInput ~= inp then return end
                sliding = true
                activeSliderInput = inp
                applyAtX(inp.Position.X)
                if inp.Changed then
                    local changedConn
                    changedConn = inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End then
                            if activeSliderInput == inp then
                                sliding = false
                                activeSliderInput = nil
                            end
                            if changedConn then changedConn:Disconnect() end
                        end
                    end)
                end
            end
        end))
        AddConnection(UserInputService.InputChanged:Connect(function(inp)
            if not sliding or not activeSliderInput then return end
            local isSameTouch = (activeSliderInput.UserInputType == Enum.UserInputType.Touch and inp == activeSliderInput)
            local isMouseMove = (activeSliderInput.UserInputType == Enum.UserInputType.MouseButton1 and inp.UserInputType == Enum.UserInputType.MouseMovement)
            if isSameTouch or isMouseMove then
                applyAtX(inp.Position.X)
            end
        end))
        AddConnection(UserInputService.InputEnded:Connect(function(inp)
            if sliding and inp == activeSliderInput then
                sliding = false
                activeSliderInput = nil
            end
        end))
    end

    function api:Cycle(labelText, stateKey, optionsList, onChange)
        elemOrder = elemOrder + 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Palette.BgCard
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.TextColor3 = Palette.TextPrimary
        btn.LayoutOrder = elemOrder
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

        local function render()
            btn.Text = labelText .. ":  " .. tostring(State[stateKey])
        end
        render()
        table.insert(SyncUICallbacks, render)

        btn.Activated:Connect(function()
            local idx = table.find(optionsList, State[stateKey]) or 0
            local nxt = optionsList[(idx % #optionsList) + 1]
            State[stateKey] = nxt
            render()
            if onChange then onChange(nxt) end
            UIHooks.UpdateBadges()
        end)
    end

    function api:Button(labelText, color, callback)
        elemOrder = elemOrder + 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = color or Color3.fromRGB(36, 98, 175)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Text = labelText
        btn.LayoutOrder = elemOrder
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        btn.Activated:Connect(callback)
    end

    return api
end
end

-- Populate 6 Clean Tabs
do
local TabShield = CreateTab("Shield")
TabShield:Section("Bullet-Blocking Shield Box")
TabShield:Toggle("Enable 3D Bullet Shield", "ShieldEnabled", function(v) SetShieldState(v) end)
TabShield:Cycle("Shield Defense Mode", "ShieldMode", { "Hybrid", "RiotOnly", "DesyncBox", "FEGhost" }, function()
    SetShieldState(State.ShieldEnabled)
end)
TabShield:Slider("Shield Cube Size", "ShieldBoxSize", 6, 18, 0.5)
TabShield:Slider("Shield Transparency", "ShieldBoxTransparency", 0.25, 0.9, 0.05)
TabShield:Section("Guard RiotShield + Anti-Aim")
TabShield:Toggle("Auto-Equip Riot Shield (Idle)", "ShieldAutoEquipOnIdle")
TabShield:Toggle("Auto-Face Closest Shooter", "ShieldAutoFaceShooter")
TabShield:Toggle("Spinbot Shield Block", "ShieldSpinBlock")
TabShield:Slider("Spinbot Speed", "ShieldSpinSpeed", 10, 90, 5)
TabShield:Slider("Desync Jitter Radius", "ShieldDesyncStrength", 1.5, 6.0, 0.5)
TabShield:Section("Shield Penetration")
TabShield:Toggle("Shoot Through Enemy Shields", "AntiRiotShield")
TabShield:Toggle("Vehicle Wallbang (Shoot Through Cars)", "VehicleWallbang", UpdateCastRayFilter)
TabShield:Button("Grab Riot Shield & Armory Gear", nil, function()
    task.spawn(function()
        GrabWeapons({ "Riot Shield", "M4A1", "Remington 870" }, function(m) UIHooks.PushAlert("Armory", m) end)
    end)
end)

local TabCombat = CreateTab("Rage & Aim")
TabCombat:Section("2026 Ragebot & .combo1")
TabCombat:Toggle("Ragebot Auto-Fire", "Ragebot")
TabCombat:Toggle("Ragebot 360 Target Scan", "Ragebot360")
TabCombat:Toggle("Ragebot Auto Gun-Switch", "RagebotAutoSwitch")
TabCombat:Toggle("Ragebot Re-Equip Riot Shield on Idle", "RagebotPeekShield")
TabCombat:Slider("Ragebot Rate (Shots/s)", "RagebotRate", 4, 30, 1)
TabCombat:Button("Trigger .combo1 Burst Now", nil, ExecuteCombo1)
TabCombat:Toggle(".combo1 Auto-Loop When Enemies Near", "ComboLoop")
TabCombat:Toggle(".combo1 Re-Equip Shield After Burst", "ComboEndWithShield")
TabCombat:Section("Silent Aim (GunController Hook)")
TabCombat:Toggle("Enable Silent Aim", "SilentAim")
TabCombat:Slider("Silent Aim FOV", "SilentAimFOV", 30, 400, 10)
TabCombat:Toggle("Show FOV Ring", "SilentAimShowFOV")
TabCombat:Slider("Hit Chance %", "SilentAimHitChance", 10, 100, 5)
TabCombat:Slider("Headshot Chance %", "SilentAimHeadChance", 0, 100, 5)
TabCombat:Cycle("Target Bone", "SilentAimAimPart", { "Head", "HumanoidRootPart" })
TabCombat:Toggle("Wallcheck", "SilentAimWallcheck")
TabCombat:Toggle("Origin Wallbang Scanner", "SilentAimWallbang")
TabCombat:Toggle("Guard Hostile-Only Check", "SilentAimHostile")
TabCombat:Toggle("Camera Aim Assist (Legit)", "AimAssist")
TabCombat:Section("Melee KillAura & Hitbox Expander")
TabCombat:Toggle("Melee KillAura (meleeEvent)", "KillAura")
TabCombat:Slider("KillAura Range (Studs)", "KillAuraRange", 6, 22, 1)
TabCombat:Toggle("Expand Enemy Hitboxes", "HitboxExpander", UpdateHitboxExpander)
TabCombat:Slider("Hitbox Size", "HitboxSize", 3, 20, 1, UpdateHitboxExpander)

local TabGuns = CreateTab("Guns & Loot")
TabGuns:Section("Instant Weapon Grabber (2026)")
TabGuns:Button("Grab Meta Loadout (Remington + M4A1 + AK-47 + MP5)", nil, function()
    task.spawn(function() GrabWeapons({ "Remington 870", "M4A1", "AK-47", "MP5" }, function(m) UIHooks.PushAlert("Guns", m) end) end)
end)
TabGuns:Button("Grab Guard Gear (M9 + Remington + M4A1 + Riot Shield)", nil, function()
    task.spawn(function() GrabWeapons({ "M9", "Remington 870", "M4A1", "Riot Shield" }, function(m) UIHooks.PushAlert("Guards", m) end) end)
end)
TabGuns:Button("Grab Criminal Gear (FAL + AK-47 + Remington)", nil, function()
    task.spawn(function() GrabWeapons({ "FAL", "AK-47", "Remington 870" }, function(m) UIHooks.PushAlert("Crims", m) end) end)
end)
TabGuns:Toggle("Auto-Grab Loadout on Spawn", "AutoGetGuns")
TabGuns:Section("Firearm Modifications")
TabGuns:Toggle("Enable Gun Mods", "GunMods", ApplyGunModsAll)
TabGuns:Slider("Fire Rate (Shots/s)", "GunFireRateSPS", 5, 35, 1, ApplyGunModsAll)
TabGuns:Toggle("No Spread", "GunNoSpread", ApplyGunModsAll)
TabGuns:Toggle("Full Automatic", "GunFullAuto", ApplyGunModsAll)
TabGuns:Toggle("Infinite Range", "GunInfiniteRange", ApplyGunModsAll)
TabGuns:Toggle("Auto Reload on Empty", "AutoReload")
TabGuns:Section("Consumables & Pickups")
TabGuns:Toggle("Auto-Armor (Near Vest)", "AutoArmor")
TabGuns:Toggle("Auto-Heal (Cafeteria Food)", "AutoHeal")
TabGuns:Slider("Auto-Heal Threshold", "AutoHealThreshold", 20, 95, 5)
TabGuns:Toggle("Auto-Pickup Dropped Keycards/Guns", "AutoPickupDropped")

local TabPrison = CreateTab("Prison & Car")
TabPrison:Section("Instant Team Switch (RequestTeamChange)")
TabPrison:Button("Join Guards", Color3.fromRGB(45, 95, 185), function() SwitchToTeam("Guards") end)
TabPrison:Button("Join Inmates", Color3.fromRGB(190, 105, 35), function() SwitchToTeam("Inmates") end)
TabPrison:Button("Join Criminals (Via Escape)", Color3.fromRGB(180, 50, 55), function()
    local spawnObj = Workspace:FindFirstChild("Criminals Spawn")
    local sp = spawnObj and spawnObj:FindFirstChild("SpawnLocation")
    if sp then SafeTeleportCF(sp.CFrame + Vector3.new(0, 3, 0)) end
end)
TabPrison:Section("Guard, Prisoner & Map Utilities")
TabPrison:Toggle("Auto-Arrest Nearby Threats", "AutoArrest")
TabPrison:Toggle("Auto-Tase Nearby Enemies", "AutoTaze")
TabPrison:Toggle("Anti-Tase (Bypass Stun)", "AntiTase")
TabPrison:Toggle("Fast Respawn (<1s)", "FastRespawn")
TabPrison:Toggle("Open / Phase All Prison Doors", "OpenAllDoors", SetOpenAllDoors)
TabPrison:Toggle("Fence Godmode (No Fence Damage)", "FenceGodmode", SetFenceGodmode)
TabPrison:Toggle("Anti-KillPlane Void Rescue", "AntiKillPlane")
TabPrison:Toggle("Auto-Detonate C4", "AutoDetonateC4")
TabPrison:Section("Vehicles (PC & Mobile)")
TabPrison:Button("Spawn & Enter Nearest Car", Color3.fromRGB(45, 140, 110), SpawnAndEnterNearestCar)
TabPrison:Toggle("Vehicle Fly (WASD / Mobile Stick + UP/DN)", "VehicleFly")
TabPrison:Slider("Vehicle Fly Speed", "VehicleFlySpeed", 30, 180, 5)
TabPrison:Toggle("Vehicle Speed Boost", "VehicleSpeedMod")
TabPrison:Toggle("Vehicle Fling (Seated Spin Ram)", "VehicleFling")
TabPrison:Toggle("Anti-Car Fling", "AntiFling", SafeSetAntiFlingEnabled)

local TabMoveVis = CreateTab("Move & ESP")
TabMoveVis:Section("2026 Anti-Rubberband Movement")
TabMoveVis:Toggle("Bypass WalkSpeed", "MaxSpeed")
TabMoveVis:Cycle("Speed Mode", "MaxSpeedMode", { "RegionSafe", "Custom" })
TabMoveVis:Slider("Custom WalkSpeed", "CustomWalkSpeed", 16, 100, 2)
TabMoveVis:Toggle("Character Fly (WASD / Stick + UP/DN)", "Fly")
TabMoveVis:Slider("Character Fly Speed", "FlySpeed", 25, 180, 5)
TabMoveVis:Toggle("Custom JumpPower", "JumpPowerEnabled")
TabMoveVis:Slider("JumpPower Value", "CustomJumpPower", 40, 140, 5)
TabMoveVis:Toggle("Always Sprint (24 WS)", "AlwaysSprint")
TabMoveVis:Toggle("Infinite Jump", "InfiniteJump")
TabMoveVis:Toggle("Anti-Jump Cooldown", "AntiJumpCooldown", function(v) BypassAntiJump(LocalPlayer.Character, v) end)
TabMoveVis:Toggle("Noclip (Bypass HeadCollision)", "Noclip", function(v) if v then BypassClientAntiNoclip() end end)
TabMoveVis:Toggle("FE Ghost / Invisible", "FEInvisible", SetFEInvisible)
TabMoveVis:Toggle("Anti-Invisible (Reveal Exploiters)", "AntiInvisible")
TabMoveVis:Section("ESP & Cheater Alerts")
TabMoveVis:Toggle("Enable ESP", "ESP")
TabMoveVis:Toggle("Team Highlight Chams", "ESPChams")
TabMoveVis:Toggle("Player Names + Distance", "ESPNames")
TabMoveVis:Toggle("Floating Health Bars", "ESPHealthBar")
TabMoveVis:Toggle("Diamond Markers", "ESPDiamondMarker")
TabMoveVis:Toggle("Bullet Tracers", "BulletTracers")
TabMoveVis:Toggle("C4 ESP", "C4ESP")
TabMoveVis:Toggle("Car-Teleport & Cheater Alerts", "CarTPAlerts")
TabMoveVis:Toggle("Show Top-Center Alerts", "ShowAlerts")
TabMoveVis:Toggle("Show Custom Streak Killfeed", "ShowKillfeed")

local TabCmds = CreateTab("KX Admin")
TabCmds:Section("HUD Layout Toggles")
TabCmds:Toggle("Show .combo1 Top-Left Pill", "ShowComboButton")
TabCmds:Toggle("Show KX ADMIN Command Bar", "ShowKXBar")
TabCmds:Toggle("Show Right Mobile Action Buttons", "ShowRightActions")
TabCmds:Toggle("Show Bottom Shield HP Badge", "ShowShieldBadge")
TabCmds:Section("Quick KX Commands")
TabCmds:Button("Run: ;cmds (Show Command List in KX Bar)", nil, function()
    UIHooks.LogCmd("Commands: shield, unshield, shieldmode <m>, shield spin, ragebot, silentaim, aimbot, killaura, hitbox, wallbang, modguns, combo1, autocombo, guns, team <t>, tp <loc|plr>, arrest, autoarrest, autotaze, autocrime, fastrespawn, fly <n>, carfly <n>, spawncar, carfling, noclip, speed <n>, jp <n>, infjump, esp, c4esp, tracers, killfeed, clear, re, rejoin, unload", Palette.NeonCyan)
end)
TabCmds:Button("Clear HUD Killfeed & Alerts", nil, CleanCharacterEffects)
TabCmds:Button("Server Rejoin", Color3.fromRGB(165, 110, 40), function()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end)
TabCmds:Button("Unload KX Script Completely", Palette.RedAlert, function()
    if type(GEN_ENV.__PL_KX_Cleanup) == "function" then
        pcall(GEN_ENV.__PL_KX_Cleanup)
    end
end)
end

-- ============================================================================
-- // SECTION 11: KX ADMIN COMMAND PROCESSOR (55+ COMMANDS)
-- ============================================================================
local function ResolveTargetPlayer(query)
    if not query or query == "" then return nil end
    local q = query:lower()
    if q == "me" then return LocalPlayer end
    if q == "nearest" then
        local myRoot = GetRoot(LocalPlayer.Character)
        if not myRoot then return nil end
        local best, bestD = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            local r = p ~= LocalPlayer and GetRoot(p.Character)
            if r then
                local d = (r.Position - myRoot.Position).Magnitude
                if d < bestD then bestD = d; best = p end
            end
        end
        return best
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q then
            return p
        end
    end
    return nil
end

local CommandHandlers = {}
local function RegisterCmd(aliases, fn)
    for _, name in ipairs(aliases) do
        CommandHandlers[name:lower()] = fn
    end
end

RegisterCmd({ "cmds", "help" }, function()
    UIHooks.LogCmd("KX CMDS: shield, unshield, shieldsize <n>, shieldmode <hybrid|riot|desync|ghost>, shield spin, antishield, ragebot, silentaim, aimbot, killaura, hitbox, wallbang, modguns, combo1, autocombo, guns, team <g|i|c|n>, tp <loc|plr>, arrest, autoarrest, autotaze, autocrime, fastrespawn, spawncar, fly <n>, unfly, carfly <n>, carfling, noclip, speed <n>, safespeed, jp <n>, infjump, invis, esp, c4esp, tracers, killfeed, alerts, clear, re, rejoin, serverhop, unload", Palette.NeonCyan)
end)

local function ApplyShieldModeArg(rawMode)
    if not rawMode then return false end
    local m = rawMode:lower()
    if m:find("riot") then
        State.ShieldMode = "RiotOnly"
        return true
    elseif m:find("desync") or m == "box" or m == "cube" then
        State.ShieldMode = "DesyncBox"
        return true
    elseif m:find("ghost") or m:find("invis") then
        State.ShieldMode = "FEGhost"
        return true
    elseif m:find("hybrid") then
        State.ShieldMode = "Hybrid"
        return true
    end
    return false
end

RegisterCmd({ "shield", "shieldon" }, function(args)
    if args[1] then
        local a = args[1]:lower()
        if a == "spin" or a == "spinbot" then
            State.ShieldSpinBlock = true
        elseif a == "unspin" or a == "nospin" then
            State.ShieldSpinBlock = false
            UIHooks.UpdateBadges()
            UIHooks.LogCmd("Shield Spin Block OFF", Palette.TextMuted)
            return
        elseif a == "face" or a == "autoface" then
            State.ShieldAutoFaceShooter = true
        elseif a == "unface" or a == "noface" then
            State.ShieldAutoFaceShooter = false
        else
            ApplyShieldModeArg(a)
        end
    end
    SetShieldState(true)
    UIHooks.LogCmd(
        "Bullet Shield ON (" .. State.ShieldMode .. (State.ShieldSpinBlock and ", Spin)" or ")"),
        Palette.NeonBlue
    )
end)

RegisterCmd({ "shieldmode", "smode" }, function(args)
    local m = args[1]
    if not m or not ApplyShieldModeArg(m) then
        UIHooks.LogCmd("Modes: hybrid, riot, desync, ghost", Palette.TextMuted)
        return
    end
    SetShieldState(true)
    UIHooks.LogCmd("Shield Mode -> " .. State.ShieldMode, Palette.NeonBlue)
end)

RegisterCmd({ "unshield", "noshield" }, function()
    SetShieldState(false)
    UIHooks.LogCmd("Bullet Shield OFF", Palette.TextMuted)
end)

RegisterCmd({ "shieldbox", "showshield" }, function(args)
    local toggle = args[1] and args[1]:lower()
    if toggle == "off" or toggle == "false" then
        State.ShowShieldBadge = false
    else
        State.ShowShieldBadge = true
    end
    UIHooks.UpdateBadges()
end)
RegisterCmd({ "unshieldbox" }, function() State.ShowShieldBadge = false; UIHooks.UpdateBadges() end)

RegisterCmd({ "shieldsize" }, function(args)
    local n = tonumber(args[1])
    if n then
        State.ShieldBoxSize = math.clamp(n, 6, 18)
        UIHooks.UpdateBadges()
        UIHooks.LogCmd("Shield cube size = " .. State.ShieldBoxSize, Palette.NeonBlue)
    end
end)

RegisterCmd({ "antishield" }, function()
    State.AntiRiotShield = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Anti-RiotShield ON (shoot through enemy shields)", Palette.NeonBlue)
end)
RegisterCmd({ "unantishield" }, function()
    State.AntiRiotShield = false
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Anti-RiotShield OFF", Palette.TextMuted)
end)

RegisterCmd({ "ragebot", "rage" }, function()
    State.Ragebot = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Ragebot ON", Palette.RageCrimson)
end)
RegisterCmd({ "unragebot", "unrage" }, function()
    State.Ragebot = false
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Ragebot OFF", Palette.TextMuted)
end)

RegisterCmd({ "silentaim", "silent" }, function()
    State.SilentAim = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Silent Aim ON", Palette.NeonBlue)
end)
RegisterCmd({ "unsilentaim", "unsilent" }, function()
    State.SilentAim = false
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Silent Aim OFF", Palette.TextMuted)
end)

RegisterCmd({ "aimbot", "aimassist" }, function(args)
    local fov = tonumber(args[1])
    if fov then State.AimAssistFOV = math.clamp(fov, 30, 500) end
    State.AimAssist = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Aimbot / Camera Assist ON (FOV " .. State.AimAssistFOV .. ")", Palette.NeonBlue)
end)
RegisterCmd({ "unaimbot", "unaimassist" }, function()
    State.AimAssist = false
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Aimbot / Camera Assist OFF", Palette.TextMuted)
end)

RegisterCmd({ "killaura", "aura" }, function(args)
    local rng = tonumber(args[1])
    if rng then State.KillAuraRange = math.clamp(rng, 4, 24) end
    State.KillAura = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Melee KillAura ON (" .. State.KillAuraRange .. " studs)", Palette.NeonBlue)
end)
RegisterCmd({ "unkillaura", "unaura" }, function()
    State.KillAura = false
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Melee KillAura OFF", Palette.TextMuted)
end)

RegisterCmd({ "hitbox", "hitboxes", "expand" }, function(args)
    local sz = tonumber(args[1])
    if sz then State.HitboxSize = math.clamp(sz, 2, 24) end
    State.HitboxExpander = true
    UpdateHitboxExpander()
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Hitbox Expander ON (Size " .. State.HitboxSize .. ")", Palette.NeonBlue)
end)
RegisterCmd({ "unhitbox", "unhitboxes", "unexpand" }, function()
    State.HitboxExpander = false
    UpdateHitboxExpander()
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Hitbox Expander OFF", Palette.TextMuted)
end)

RegisterCmd({ "wallbang", "wb" }, function()
    State.SilentAimWallbang = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Wallbang Scanner ON", Palette.NeonBlue)
end)
RegisterCmd({ "unwallbang", "unwb" }, function()
    State.SilentAimWallbang = false
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Wallbang Scanner OFF", Palette.TextMuted)
end)
RegisterCmd({ "carwallbang", "vehiclewallbang" }, function()
    State.VehicleWallbang = true
    UpdateCastRayFilter()
    UIHooks.LogCmd("Vehicle Wallbang ON", Palette.NeonBlue)
end)
RegisterCmd({ "uncarwallbang", "unvehiclewallbang" }, function()
    State.VehicleWallbang = false
    UpdateCastRayFilter()
    UIHooks.LogCmd("Vehicle Wallbang OFF", Palette.TextMuted)
end)

RegisterCmd({ "modguns", "gunmods" }, function(args)
    local sps = tonumber(args[1])
    if sps then State.GunFireRateSPS = math.clamp(sps, 5, 35) end
    State.GunMods = true
    ApplyGunModsAll()
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Gun Mods ON (" .. State.GunFireRateSPS .. " SPS)", Palette.NeonBlue)
end)
RegisterCmd({ "unmodguns", "ungunmods" }, function()
    State.GunMods = false
    ApplyGunModsAll()
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Gun Mods OFF", Palette.TextMuted)
end)

RegisterCmd({ "combo1", "combo" }, function()
    ExecuteCombo1()
    UIHooks.LogCmd("Executed .combo1 burst", Palette.StreakGold)
end)
RegisterCmd({ "autocombo" }, function() State.ComboLoop = true; UIHooks.UpdateBadges(); UIHooks.LogCmd(".combo1 Auto-Loop ON", Palette.NeonBlue) end)
RegisterCmd({ "unautocombo" }, function() State.ComboLoop = false; UIHooks.UpdateBadges(); UIHooks.LogCmd(".combo1 Auto-Loop OFF", Palette.TextMuted) end)

RegisterCmd({ "guns", "allguns" }, function()
    task.spawn(function() GrabWeapons(State.AutoGunsSelection, function(m) UIHooks.LogCmd(m, Palette.NeonBlue) end) end)
end)

RegisterCmd({ "team" }, function(args)
    local t = args[1] or "inmates"
    if t:lower():sub(1, 1) == "g" then SwitchToTeam("Guards")
    elseif t:lower():sub(1, 1) == "c" then
        local cs = Workspace:FindFirstChild("Criminals Spawn")
        local sp = cs and (cs:FindFirstChild("SpawnLocation") or cs:FindFirstChildWhichIsA("BasePart") or (cs:IsA("BasePart") and cs)) or nil
        if sp then SafeTeleportCF(sp.CFrame + Vector3.new(0, 3, 0)) end
    elseif t:lower():sub(1, 1) == "n" then SwitchToTeam("Neutral")
    else SwitchToTeam("Inmates") end
    UIHooks.LogCmd("Team action -> " .. t, Palette.NeonBlue)
end)

RegisterCmd({ "tp", "goto" }, function(args)
    local q = (#args > 0) and TrimString(table.concat(args, " ")) or nil
    if not q or q == "" then
        UIHooks.LogCmd("Locations: yard, nexus, cafeteria, cells, armory, crimbase, roof, tower, gate, sewer, hideout, cars, store, gas", Palette.TextMuted)
        return
    end
    local preset = TeleportLocations[q:lower()]
    if preset then
        SafeTeleportCF(preset)
        UIHooks.LogCmd("Teleported to " .. q, Palette.NeonBlue)
        return
    end
    local plr = ResolveTargetPlayer(q)
    local root = plr and GetRoot(plr.Character)
    if root then
        SafeTeleportCF(root.CFrame * CFrame.new(0, 2, 3))
        UIHooks.LogCmd("Teleported to " .. plr.Name, Palette.NeonBlue)
    else
        UIHooks.LogCmd("Unknown target/location: " .. q, Palette.RedAlert)
    end
end)

RegisterCmd({ "arrest" }, function(args)
    local target = args[1] and ResolveTargetPlayer(args[1]) or ResolveTargetPlayer("nearest")
    if target and Remotes.ArrestPlayer then
        task.spawn(function() pcall(function() Remotes.ArrestPlayer:InvokeServer(target, 1) end) end)
        UIHooks.LogCmd("Attempted arrest: " .. target.Name, Palette.NeonBlue)
    end
end)
RegisterCmd({ "autoarrest" }, function() State.AutoArrest = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Arrest ON", Palette.NeonBlue) end)
RegisterCmd({ "unautoarrest" }, function() State.AutoArrest = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Arrest OFF", Palette.TextMuted) end)
RegisterCmd({ "autotaze", "autotase" }, function() State.AutoTaze = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Tase ON", Palette.NeonBlue) end)
RegisterCmd({ "unautotaze", "unautotase" }, function() State.AutoTaze = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Tase OFF", Palette.TextMuted) end)
RegisterCmd({ "antitase", "antitaze" }, function() State.AntiTase = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Anti-Tase ON", Palette.NeonBlue) end)
RegisterCmd({ "unantitase", "unantitaze" }, function() State.AntiTase = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Anti-Tase OFF", Palette.TextMuted) end)
RegisterCmd({ "autocrime", "autocrim", "autocriminal" }, function() State.AutoCriminal = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Criminal ON", Palette.NeonBlue) end)
RegisterCmd({ "unautocrime", "unautocrim", "unautocriminal" }, function() State.AutoCriminal = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Criminal OFF", Palette.TextMuted) end)
RegisterCmd({ "fastrespawn", "autore" }, function() State.FastRespawn = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Fast Respawn ON", Palette.NeonBlue) end)
RegisterCmd({ "unfastrespawn", "unautore" }, function() State.FastRespawn = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Fast Respawn OFF", Palette.TextMuted) end)
RegisterCmd({ "autoheal" }, function() State.AutoHeal = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Heal ON", Palette.NeonBlue) end)
RegisterCmd({ "unautoheal" }, function() State.AutoHeal = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Heal OFF", Palette.TextMuted) end)
RegisterCmd({ "autoarmor" }, function() State.AutoArmor = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Armor ON", Palette.NeonBlue) end)
RegisterCmd({ "unautoarmor" }, function() State.AutoArmor = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Auto-Armor OFF", Palette.TextMuted) end)
RegisterCmd({ "doors", "opendoors" }, function() State.OpenAllDoors = true; SetOpenAllDoors(true); UIHooks.LogCmd("All Doors Phased Open", Palette.NeonBlue) end)
RegisterCmd({ "undoors", "closedoors" }, function() State.OpenAllDoors = false; SetOpenAllDoors(false); UIHooks.LogCmd("Doors Restored", Palette.TextMuted) end)
RegisterCmd({ "fence", "fencegod" }, function() State.FenceGodmode = true; SetFenceGodmode(true); UIHooks.LogCmd("Fence Godmode ON", Palette.NeonBlue) end)
RegisterCmd({ "unfence", "unfencegod" }, function() State.FenceGodmode = false; SetFenceGodmode(false); UIHooks.LogCmd("Fence Godmode OFF", Palette.TextMuted) end)

RegisterCmd({ "spawncar", "car" }, function()
    SpawnAndEnterNearestCar()
    UIHooks.LogCmd("Spawning & entering nearest car...", Palette.NeonBlue)
end)
RegisterCmd({ "fly" }, function(args)
    local spd = tonumber(args[1])
    if spd then State.FlySpeed = math.clamp(spd, 20, 220) end
    State.Fly = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Character Fly ON (" .. State.FlySpeed .. ")", Palette.NeonBlue)
end)
RegisterCmd({ "unfly" }, function()
    State.Fly = false
    MobileFlyInput.Up = 0
    MobileFlyInput.Down = 0
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Character Fly OFF", Palette.TextMuted)
end)
RegisterCmd({ "carfly" }, function(args)
    local spd = tonumber(args[1])
    if spd then State.VehicleFlySpeed = math.clamp(spd, 20, 220) end
    State.VehicleFly = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Vehicle Fly ON (" .. State.VehicleFlySpeed .. ")", Palette.NeonBlue)
end)
RegisterCmd({ "uncarfly" }, function()
    State.VehicleFly = false
    MobileFlyInput.Up = 0
    MobileFlyInput.Down = 0
    UIHooks.UpdateBadges()
end)
RegisterCmd({ "carfling" }, function() State.VehicleFling = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Vehicle Fling ON", Palette.RedAlert) end)
RegisterCmd({ "uncarfling" }, function() State.VehicleFling = false; UIHooks.UpdateBadges() end)
RegisterCmd({ "antifling" }, function() State.AntiFling = true; SafeSetAntiFlingEnabled(true); UIHooks.UpdateBadges() end)
RegisterCmd({ "unantifling" }, function() State.AntiFling = false; SafeSetAntiFlingEnabled(false); UIHooks.UpdateBadges() end)

RegisterCmd({ "noclip" }, function() BypassClientAntiNoclip(); State.Noclip = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Noclip ON", Palette.NeonBlue) end)
RegisterCmd({ "clip", "unnoclip" }, function()
    State.Noclip = false
    RestoreNoclipCollide()
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Noclip OFF", Palette.TextMuted)
end)

RegisterCmd({ "speed", "ws" }, function(args)
    local n = tonumber(args[1]) or 44
    State.MaxSpeedMode = "Custom"
    State.CustomWalkSpeed = math.clamp(n, 16, 120)
    State.MaxSpeed = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Speed = " .. State.CustomWalkSpeed, Palette.NeonBlue)
end)
RegisterCmd({ "safespeed" }, function()
    State.MaxSpeedMode = "RegionSafe"
    State.MaxSpeed = true
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("RegionSafe 2026 Speed ON", Palette.NeonBlue)
end)
RegisterCmd({ "unspeed" }, function()
    State.MaxSpeed = false
    local hum = GetHumanoid(LocalPlayer.Character)
    if hum and SavedSpeedProps[hum] ~= nil and not State.AlwaysSprint then
        local origWS = SavedSpeedProps[hum]
        SavedSpeedProps[hum] = nil
        if hum.WalkSpeed > 0 then
            hum.WalkSpeed = origWS
        end
    end
    UIHooks.UpdateBadges()
end)

RegisterCmd({ "jp", "jumppower" }, function(args)
    local n = tonumber(args[1]) or 75
    State.CustomJumpPower = math.clamp(n, 30, 180)
    State.JumpPowerEnabled = true
    BypassAntiJump(LocalPlayer.Character, true)
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("JumpPower = " .. State.CustomJumpPower, Palette.NeonBlue)
end)
RegisterCmd({ "unjp", "unjumppower" }, function()
    State.JumpPowerEnabled = false
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("JumpPower Restored", Palette.TextMuted)
end)
RegisterCmd({ "infjump" }, function()
    State.InfiniteJump = true
    BypassAntiJump(LocalPlayer.Character, true)
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Infinite Jump ON", Palette.NeonBlue)
end)
RegisterCmd({ "uninfjump" }, function()
    State.InfiniteJump = false
    UIHooks.UpdateBadges()
    UIHooks.LogCmd("Infinite Jump OFF", Palette.TextMuted)
end)

RegisterCmd({ "invis", "ghost" }, function() SetFEInvisible(true); UIHooks.UpdateBadges() end)
RegisterCmd({ "uninvis", "unghost" }, function() SetFEInvisible(false); UIHooks.UpdateBadges() end)

RegisterCmd({ "esp" }, function() State.ESP = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("ESP ON", Palette.NeonBlue) end)
RegisterCmd({ "unesp" }, function() State.ESP = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("ESP OFF", Palette.TextMuted) end)
RegisterCmd({ "c4esp" }, function() State.C4ESP = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("C4 ESP ON", Palette.NeonBlue) end)
RegisterCmd({ "unc4esp" }, function() State.C4ESP = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("C4 ESP OFF", Palette.TextMuted) end)
RegisterCmd({ "tracers", "bullettracers" }, function() State.BulletTracers = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Bullet Tracers ON", Palette.NeonBlue) end)
RegisterCmd({ "untracers", "unbullettracers" }, function() State.BulletTracers = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Bullet Tracers OFF", Palette.TextMuted) end)
RegisterCmd({ "killfeed" }, function() State.ShowKillfeed = true; UIHooks.UpdateBadges(); UIHooks.LogCmd("Killfeed ON", Palette.NeonBlue) end)
RegisterCmd({ "unkillfeed" }, function() State.ShowKillfeed = false; UIHooks.UpdateBadges(); UIHooks.LogCmd("Killfeed OFF", Palette.TextMuted) end)
RegisterCmd({ "alerts" }, function() State.CarTPAlerts = true; State.ShowAlerts = true; UIHooks.UpdateBadges() end)
RegisterCmd({ "unalerts" }, function() State.ShowAlerts = false; UIHooks.UpdateBadges() end)

RegisterCmd({ "clear", "clean" }, function() CleanCharacterEffects(); UIHooks.LogCmd("HUD cleared & character unstuck", Palette.NeonBlue) end)
RegisterCmd({ "re", "respawn" }, function() PerformFastRespawn() end)
RegisterCmd({ "rejoin", "rj" }, function()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end)
RegisterCmd({ "serverhop", "hop" }, function()
    task.spawn(function()
        local ok, raw = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        end)
        if ok and raw then
            local data = HttpService:JSONDecode(raw)
            if data and data.data then
                for _, srv in ipairs(data.data) do
                    if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                        return
                    end
                end
            end
        end
    end)
end)
RegisterCmd({ "unload" }, function()
    if type(GEN_ENV.__PL_KX_Cleanup) == "function" then pcall(GEN_ENV.__PL_KX_Cleanup) end
end)

local function ExecuteKXCommandLine(rawLine)
    local text = TrimString(rawLine)
    if text == "" then return end
    for segment in text:gmatch("[^;]+") do
        local cmdClean = TrimString(segment):gsub("^[;/!%.]+", "")
        local parts = {}
        for tok in cmdClean:gmatch("%S+") do
            table.insert(parts, tok)
        end
        if parts[1] then
            local cmdName = table.remove(parts, 1):lower()
            local handler = CommandHandlers[cmdName]
            if handler then
                local ok, err = pcall(handler, parts)
                if not ok then
                    UIHooks.LogCmd("Cmd error: " .. tostring(err), Palette.RedAlert)
                end
            else
                UIHooks.LogCmd("Unknown cmd '" .. cmdName .. "' (run 'cmds')", Palette.RedAlert)
            end
        end
    end
    if UIHooks.SyncHub then
        pcall(UIHooks.SyncHub)
    end
end

HUD.KXCmdBtn.Activated:Connect(function()
    local raw = HUD.KXInput.Text
    HUD.KXInput.Text = ""
    ExecuteKXCommandLine(raw)
end)
AddConnection(HUD.KXInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local raw = HUD.KXInput.Text
        HUD.KXInput.Text = ""
        ExecuteKXCommandLine(raw)
    end
end))

-- ============================================================================
-- // SECTION 12: KEYBINDS, RESPAWN LISTENER & FULL CLEANUP HANDLER
-- ============================================================================
AddConnection(UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if not Running or gameProcessed then return end
    if inp.KeyCode == Enum.KeyCode.RightShift or inp.KeyCode == Enum.KeyCode.K then
        SetHubVisible(not State.HubVisible)
    elseif inp.KeyCode == Enum.KeyCode.G then
        SetShieldState(not State.ShieldEnabled)
        if UIHooks.SyncHub then UIHooks.SyncHub() end
        if UIHooks.PushAlert then
            UIHooks.PushAlert("Shield", State.ShieldEnabled and "Bullet Shield ON" or "Bullet Shield OFF")
        end
    elseif inp.KeyCode == Enum.KeyCode.X then
        ExecuteCombo1()
    elseif inp.KeyCode == Enum.KeyCode.B then
        State.Ragebot = not State.Ragebot
        UIHooks.UpdateBadges()
        if UIHooks.SyncHub then UIHooks.SyncHub() end
        if UIHooks.PushAlert then
            UIHooks.PushAlert("Ragebot", State.Ragebot and "Ragebot ON" or "Ragebot OFF")
        end
    end
end))

local HookedBackpacks = setmetatable({}, { __mode = "k" })
local function OnLocalCharacterAdded(char)
    if not char or not Running then return end
    DesyncRestoreCF = nil
    LastShieldRemoteSent = false
    task.spawn(function()
        task.wait(0.35)
        if not Running or LocalPlayer.Character ~= char then return end
        SetupGunControllerHooks()
        ApplyGunModsAll()
        if State.AntiJumpCooldown or State.MaxSpeed or State.JumpPowerEnabled then
            BypassAntiJump(char, true)
        end
        if State.Noclip or State.MaxSpeed then
            BypassClientAntiNoclip()
        end
        if State.FEInvisible or (State.ShieldEnabled and State.ShieldMode == "FEGhost") then
            StartFEInvisible()
        end
        if State.AutoGetGuns and LocalPlayer.Team ~= Teams:FindFirstChild("Neutral") then
            GrabWeapons(State.AutoGunsSelection)
        end
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp and not HookedBackpacks[bp] then
            HookedBackpacks[bp] = true
            AddConnection(bp.ChildAdded:Connect(function(child)
                if Running then
                    task.defer(ApplyGunModsToTool, child)
                end
            end))
        end
        AddConnection(char.ChildAdded:Connect(function(child)
            if Running then
                task.defer(ApplyGunModsToTool, child)
            end
        end))
    end)
end

if LocalPlayer.Character then
    OnLocalCharacterAdded(LocalPlayer.Character)
end
AddConnection(LocalPlayer.CharacterAdded:Connect(OnLocalCharacterAdded))

-- Apply initial passive protections
pcall(SetFenceGodmode, State.FenceGodmode)
pcall(SafeSetAntiFlingEnabled, State.AntiFling)
UIHooks.UpdateBadges()
UIHooks.PushAlert("KX Edition", "Loaded cleanly! Tap KX crest (or RightShift/K) for menu.")

GEN_ENV.__PL_KX_Cleanup = function()
    if not Running then return end
    Running = false
    GEN_ENV.__PL_KX_Running = false

    State.HitboxExpander = false
    State.JumpPowerEnabled = false
    State.MaxSpeed = false
    State.AlwaysSprint = false
    State.Noclip = false
    State.Fly = false
    State.VehicleFly = false
    State.KillAura = false
    MobileFlyInput.Up = 0
    MobileFlyInput.Down = 0
    DesyncRestoreCF = nil

    pcall(UpdateHitboxExpander)
    for hrp in pairs(SavedHitboxes) do
        RestorePlayerHitbox(hrp)
    end
    for hum, origJ in pairs(SavedJumpProps) do
        pcall(function()
            if hum and hum.Parent then
                if origJ.JumpPower then hum.JumpPower = origJ.JumpPower end
                if origJ.JumpHeight then hum.JumpHeight = origJ.JumpHeight end
            end
        end)
        SavedJumpProps[hum] = nil
    end
    for hum, origWS in pairs(SavedSpeedProps) do
        pcall(function()
            if hum and hum.Parent and origWS and hum.WalkSpeed > 0 then
                hum.WalkSpeed = origWS
            end
        end)
        SavedSpeedProps[hum] = nil
    end

    RestoreNoclipCollide()
    SetShieldState(false)
    StopFEInvisible()
    SetFenceGodmode(false)
    SetOpenAllDoors(false)
    SafeSetAntiFlingEnabled(false)
    BypassAntiJump(LocalPlayer.Character, false)

    for _, name in ipairs(BoundRenderSteps) do
        SafeUnbindRenderStep(name)
    end
    table.clear(BoundRenderSteps)

    for _, c in ipairs(ActiveConnections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(ActiveConnections)

    for plr in pairs(ESPPool) do
        RemovePlayerESP(plr)
    end
    for _, inst in ipairs(TrackedInstances) do
        pcall(function() inst:Destroy() end)
    end
    table.clear(TrackedInstances)

    GEN_ENV.__PL_KX_BulletHandler = nil
    GEN_ENV.__PL_KX_TaseHandler = nil

    if HasRestoreFunc then
        if type(GEN_ENV.__PL_KX_HookedBullets) == "table" then
            for hookedFn in pairs(GEN_ENV.__PL_KX_HookedBullets) do
                pcall(restorefunction, hookedFn)
            end
            table.clear(GEN_ENV.__PL_KX_HookedBullets)
        elseif GunHook.IsBulletHooked and GunHook.Bullet then
            pcall(restorefunction, GunHook.Bullet)
        end
        if type(GEN_ENV.__PL_KX_HookedTase) == "table" then
            for hookedFn in pairs(GEN_ENV.__PL_KX_HookedTase) do
                pcall(restorefunction, hookedFn)
            end
            table.clear(GEN_ENV.__PL_KX_HookedTase)
        end
    end
end
