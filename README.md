# Prison Life 2026 — KX Edition V3 (PC & Mobile)

Standalone 2026 **Roblox Prison Life** (`PlaceId: 155615604`) LuaU script with responsive PC + Mobile UI, built against verified 2026 client mechanics and remotes.

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/reizure87-create/prison-life-kx-edition/main/PrisonLifeKX.lua"))()
```

## Highlights (V3)

- **Obsidian 6-Tab Hub (`Shield`, `Rage & Aim`, `Guns & Loot`, `Prison & Car`, `Move & ESP`, `Settings & Admin`)**:
  - Live widget search bar, animated TweenService transitions, presets (`Legit`, `Rage`, `Default`), JSON config profiles (save/load/delete/auto-load), and click-to-rebind keyboard shortcuts.
  - Compact Mobile responsive layout (`<= 740px` / `< 450px` height) with horizontal pill tabs and touch-friendly sliders that preserve vertical scrolling unless dragged horizontally.
- **3D Holographic Bullet Shield (`Shield` / `G`)**:
  - **Modes**: `Hybrid` (server-replicated `RiotShieldPart` auto-equip + armed-threat auto-facing on Guards + micro CFrame anti-aim desync on Inmates/Criminals), `RiotOnly`, `DesyncBox`, and `FEGhost`.
  - Translucent translucent-edge 3D shield enclosure (`ShieldTransparency`, `ShieldSize`), self-shot filter passthrough, Shield HP pill with animated durability meter & hit pulse VFX, `Anti-RiotShield` (`RiotShieldPart.CanQuery = false`), and `Vehicle Wallbang`.
- **Top-Left `.combo1`, `KX` Crest & Pinned Quick Pills**:
  - Fixed `.combo1` burst button (`X` on PC) for rapid multi-weapon bursts across loaded firearms (`Remington 870`, `FAL`, `M4A1`, `AK-47`, `MP5`, `Revolver`, `M9`), with Auto-Loop and post-burst shield peek.
  - Independently draggable `KX` toggle crest plus customizable pinned feature chips (`RAGE`, `SHIELD`, `FLY`, etc.).
- **2026 `GunController` Bullet Hook, Silent Aim, Ragebot & Hitbox Expander**:
  - Single-install hot-swappable `hookfunction` on `pl.Bullet` with camera-restoring `tool:Activate()` fallback.
  - Per-bullet Silent Aim headshot/hitchance rolls, FOV circle, Wallcheck, Wallbang scanner, Auto Armor Penetration (headshot priority on vested targets), Guard Hostile-only filter, 360° Ragebot with Auto-Switch & Fire-Rate SPS pacing, Gun Mods (`FireRate`, `NoSpread`, `InfiniteRange`, `AutoReload`), Melee `KillAura`, `HitboxExpander` (`Transparency = 1`), and `#TouchGiver` / `GiverPressed` instant gun grabber.
- **Top-Right `KX ADMIN` Command Bar & Drawer (119 Registered Commands)**:
  - Prefix-flexible (`;`, `/`, `-`, `!`, `.`) semicolon-chained execution (`;gun ak;rage on;shield on`), live autocomplete dropdown, pinned Quick Chips, and a 2-tab **Commands / Output** drawer.
  - Highlights:
    - **Team & Prison**: `;crim` / `;guard` / `;inmate` / `;team <name>`, `;arrest`, `;arrestall` (`;aa`), `;autoarrest`, `;autotaze`, `;antitaze`, `;autocrim`, `;re` (`;respawn`), `;opendoors`, `;fencegod`, `;autoheal`, `;autoarmor`, `;car`
    - **Combat & Defense**: `;shield`, `;unshield`, `;shieldmode <mode>`, `;antiriot`, `;ragebot`, `;silentaim`, `;aimassist`, `;killaura`, `;loopkill <plr>`, `;hitbox`, `;wallbang`, `;carwallbang`, `;combo1`, `;gun <name>`, `;guns`, `;loadout <kit>`
    - **Movement & Visuals**: `;fly [speed]`, `;unfly`, `;noclip` (`;nc`), `;clip`, `;speed [n]`, `;safespeed`, `;jp [n]`, `;infjump`, `;invis` (`;ghost`), `;esp`, `;c4esp`, `;bullettracers`, `;killfeed`, `;cheateralerts`, `;caralerts`
    - **System & Configs**: `;cmds`, `;preset <legit|rage|default>`, `;saveconfig <name>`, `;loadconfig <name>`, `;rejoin`, `;serverhop`, `;unload`
- **Safe-Area Mobile Quick Dock, Alerts & Killfeed**:
  - Bottom-right circular quick buttons (`SHIELD`, `GHOST`, `CLEAN`) and contextual `UP` / `DN` Fly pad placed clear of Roblox TopBar, Prison Clock, Mobile Ammo Box, Hotbar, and jump controls.
  - Heuristic Speed/TP & Car-TP anomaly banners (`CheaterAlerts` / `CarTPAlerts`), custom `[HS]` / `[RAGEBOT]` Killfeed (`AboveHotbar` or `TopLeft`), 30-Highlight budget LOD Player/C4 ESP, 4-tick animated Hitmarker, and idempotent full unload (`__PL_KX_Cleanup`) restoring hooks, doors, physics, and UI cleanly.

## Default Keybinds (PC)

- `K` / `RightShift` — Toggle KX Hub Menu
- `G` — Toggle 3D Bullet Shield
- `X` — Execute `.combo1` Burst
- `B` — Toggle Ragebot
- `F` — Toggle Fly
- `N` — Toggle Noclip
- `;` (`Semicolon`) — Focus KX Command Bar
