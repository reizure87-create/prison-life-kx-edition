# Prison Life 2026 — KX Edition (PC & Mobile)

Standalone 2026 **Roblox Prison Life** (`PlaceId: 155615604`) LuaU script with full PC + Mobile support, built against verified 2026 client mechanics and remotes.

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/reizure87-create/prison-life-kx-edition/main/PrisonLifeKX.lua"))()
```

## Features

- **3D Bullet-Blocking Shield (`Shield` / `🛡️`)**:
  - **Hybrid Mode**: Uses real server-replicated `RiotShieldPart` auto-equip + threat-facing/spin rotation on Guards (draining Riot Shield HP before health) AND micro CFrame anti-aim desync when playing as Inmates or Criminals, enclosed in a configurable translucent grey 3D shield cube whose self-shots pass straight through.
  - **Modes**: `Hybrid`, `RiotOnly`, `DesyncBox`, `FEGhost`.
  - **Shield Penetration**: `Anti-RiotShield` (`RiotShieldPart.CanQuery = false`) and `Vehicle Wallbang`.
- **Top-Left `.combo1` & Draggable Neon-Blue `KX` Crest Toggle**:
  - Tap `.combo1` (or `X` on PC) for rapid multi-gun swap bursts across loaded weapons (`Remington 870`, `FAL`, `M4A1`, `AK-47`, `MP5`, `Revolver`, `M9`), with optional Auto-Loop and post-burst shield re-equip.
  - Drag or tap the glowing `KX` crest button (or `RightShift` / `K`) to open the obsidian dark-glass tabbed Hub (drag-threshold guarded for mobile touch).
- **2026 `GunController` Bullet Hook, Ragebot & Gun Mods**:
  - Single-install hot-swappable `hookfunction` on `pl.Bullet` (`ActionArea.InputBegan` upvalues) + camera/activate fallback on lower-UNC executors.
  - Silent Aim (FOV ring, Hit/Headshot %, Wallcheck, Origin Wallbang scanner, Guard Hostile-only check) & 360° Ragebot with auto gun-switch.
  - Fire Rate, No Spread, Full Auto, Infinite Range, Auto Reload, and instant `#TouchGiver` + `GiverPressed` weapon grabber.
- **Top-Right `KX ADMIN` Command Bar (35+ Commands)**:
  - Run chained `;`-separated commands from mobile (`CMD` button) or PC (`Enter`): `cmds`, `shield`, `unshield`, `shieldsize`, `antishield`, `ragebot`, `combo1`, `autocombo`, `guns`, `team`, `tp`, `goto`, `arrest`, `autoarrest`, `spawncar`, `carfly`, `carfling`, `noclip`, `speed`, `safespeed`, `invis`, `esp`, `alerts`, `clear`, `re`, `rejoin`, `serverhop`, `unload`.
- **Real Heuristic Cheater & Car-Teleport Alerts + Custom Killfeed**:
  - Top-center `[Alert] <Player> Possible Car Teleport User` banner when abnormal vehicle/teleport displacement occurs.
  - Bottom-center streak & crimson `[RAGEBOT]` killfeed (`ReplicatedStorage.Killfeed`) + `🛡️` Shield HP mirror badge.
- **Right-Side Mobile/PC Quick Action Buttons**:
  - `GHOST` (FE Ghost toggle), `CLEAN` (clear HUD & unstuck tase/speed), `SHIELD` (one-tap 3D Bullet Shield), plus contextual `UP` / `DN` buttons during Vehicle Fly.
- **Prison, Vehicle, Movement & ESP Utilities**:
  - Instant team switching (`RequestTeamChange`), Auto-Arrest, Auto-Tase, Anti-Tase, Fast Respawn, Open All Doors, Fence Godmode, Anti-KillPlane, Auto-Armor, Auto-Heal, Auto-Pickup, Car Spawner, Vehicle Fly/Speed/Fling, Anti-Fling, 2026 Region-Safe Speed (32/50/100 caps), Highlight Chams, Healthbars, Diamond Markers, Bullet Tracers, C4 ESP.

## Default Keybinds (PC)

- `RightShift` / `K` — Toggle KX Hub Menu
- `G` — Toggle 3D Bullet Shield
- `X` — Trigger `.combo1` Burst
- `B` — Toggle Ragebot
