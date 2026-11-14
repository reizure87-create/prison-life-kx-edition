# Prison Life 2026 — KX Edition (PC & Mobile)

Standalone 2026 **Roblox Prison Life** (`PlaceId: 155615604`) LuaU script with full PC + Mobile support, built against verified 2026 client mechanics and remotes.

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/reizure87-create/prison-life-kx-edition/main/PrisonLifeKX.lua"))()
```

## Features

- **3D Bullet-Blocking Shield (`Shield` / `🛡`)**:
  - **Hybrid Mode**: Uses real server-replicated `RiotShieldPart` auto-equip + armed-threat facing/spin rotation on Guards (draining Riot Shield HP before health) AND micro CFrame anti-aim desync when playing as Inmates or Criminals, enclosed in a configurable translucent grey 3D shield cube whose self-shots pass straight through.
  - **Modes**: `Hybrid`, `RiotOnly`, `DesyncBox`, `FEGhost`.
  - **Shield Penetration**: `Anti-RiotShield` (`RiotShieldPart.CanQuery = false`) and `Vehicle Wallbang`.
- **Top-Left Fixed `.combo1` & Independently Draggable Neon-Blue `KX` Crest Toggle**:
  - `.combo1` stays pinned in the top-left corner (`X` on PC) for rapid multi-gun swap bursts across loaded weapons (`Remington 870`, `FAL`, `M4A1`, `AK-47`, `MP5`, `Revolver`, `M9`), with optional Auto-Loop and post-burst Riot Shield peek re-equip.
  - Drag the glowing `KX` crest button (or the tabbed Hub window) anywhere on screen with viewport clamping & multi-touch isolation, or tap `KX` / press `RightShift` / `K` to open the obsidian dark-glass Hub.
- **2026 `GunController` Bullet Hook, Ragebot, KillAura & Hitbox Expander**:
  - Single-install hot-swappable `hookfunction` on `pl.Bullet` (`ActionArea.InputBegan` upvalues) + camera-restoring `tool:Activate()` fallback on lower-UNC executors.
  - Per-bullet Silent Aim headshot/hit chance rolls (no 60Hz target-bone flicker), FOV ring, Wallcheck, Origin Wallbang scanner, Guard Hostile-only check, and 360° Ragebot with auto gun-switch.
  - Fire Rate, No Spread, Full Auto, Infinite Range, Auto Reload, Melee KillAura (`meleeEvent`), Hitbox Expander (invisible `Transparency = 1` HRP scaling), and instant `#TouchGiver` + `GiverPressed` weapon grabber.
- **Top-Right `KX ADMIN` Command Bar (65+ Commands)**:
  - Run chained `;`-separated commands from mobile (`CMD` button) or PC (`Enter`):
    - Combat & Shield: `shield`, `unshield`, `shieldmode <hybrid|riot|desync|ghost>`, `shield spin`, `shieldsize <n>`, `antishield`, `ragebot`, `silentaim`, `aimbot`, `killaura`, `hitbox`, `wallbang`, `carwallbang`, `modguns`, `combo1`, `autocombo`, `guns`
    - Prison & Car: `team <g|i|c|n>`, `tp <loc|plr>`, `goto <plr>`, `arrest`, `autoarrest`, `autotaze`, `antitase`, `autocrime`, `fastrespawn`, `autoheal`, `autoarmor`, `doors`, `fence`, `spawncar`, `carfly <n>`, `carfling`, `antifling`
    - Movement & Visuals: `fly <n>`, `unfly`, `noclip`, `clip`, `speed <n>`, `ws <n>`, `safespeed`, `jp <n>`, `infjump`, `invis`/`ghost`, `esp`, `c4esp`, `tracers`, `killfeed`, `shieldbox`, `alerts`, `clear`, `re`, `rejoin`, `serverhop`, `unload`
- **Real Heuristic Cheater & Car-Teleport Alerts + Custom Killfeed**:
  - Top-center `[Alert] <Player> Possible Car Teleport User` banner when abnormal vehicle/teleport displacement occurs.
  - Bottom-center streak & crimson `[RAGEBOT]` killfeed (`ReplicatedStorage.Killfeed` supporting `StringValue`, `TextLabel`, attributes & `[hp%]` tags) + blue `🛡` Shield HP mirror badge.
- **Right-Side Mobile/PC Quick Action Buttons**:
  - `GHOST` (FE Ghost toggle), `CLEAN` (clear HUD & unstuck tase/speed), `SHIELD` (one-tap 3D Bullet Shield), plus contextual `UP` / `DN` buttons in a dedicated side pad during Character Fly or Vehicle Fly (with slide-off touch release protection).
- **Prison, Vehicle, Movement & ESP Utilities**:
  - Instant team switching (`RequestTeamChange`), Auto-Arrest, Auto-Tase, Anti-Tase, Fast Respawn, Open All Doors, Fence Godmode, Anti-KillPlane (`Y < -12`), Auto-Armor, Auto-Heal (`EatFood` + `SnackEaten`), Auto-Pickup, Car Spawner, Character Fly, Custom JumpPower, Vehicle Fly/Speed/Fling, Safe Anti-Fling, 2026 Region-Safe Speed (`32`/`50`/`100` caps), Highlight Chams, Healthbars, Diamond Markers, Bullet Tracers, C4 ESP.

## Default Keybinds (PC)

- `RightShift` / `K` — Toggle KX Hub Menu
- `G` — Toggle 3D Bullet Shield
- `X` — Trigger `.combo1` Burst
- `B` — Toggle Ragebot
