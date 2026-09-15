# Wildwise

A unified quality-of-life server mod for Don't Starve Together.

[简体中文](README.zh-CN.md)

Wildwise brings information, shared exploration, item handling, action queues, storage signs and beefalo status under one set of server permissions and personal settings. It uses native game UI and assets, with English / Simplified Chinese and keyboard / mouse support.

**0.3.0 is a development build**, distributed as manually installed GitHub build artifacts. It has not been published to Steam Workshop. The official public branch verified and tested on 2026-09-14 was game **747465 / Steam build 24700372**; the newer updatebeta branch has not been validated. [Version evidence](docs/evidence/current-engine.json) and the [test report](docs/testing.md) describe the environment and coverage.

Players can start with [Get playing](#get-playing), hosts can configure and maintain a server under [Run your world](#run-your-world), and developers can find architecture, extension rules and checks under [Build on Wildwise](#build-on-wildwise). The private npm project is named `wildwise-dev` for development tooling; the game mod is Wildwise. Node and Python are only needed for development.

## Table of Contents

- [Install](#install)
  - [Dependencies](#dependencies)
- [Usage](#usage)
  - [Get playing](#get-playing)
  - [Run your world](#run-your-world)
  - [Build on Wildwise](#build-on-wildwise)
- [Further reading](#further-reading)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Install

### Dependencies

Wildwise is enabled by the server, and **every client must load the same version**. It uses the Lua 5.1 runtime, UI and assets supplied by Don't Starve Together; reference mods are not required. Dedicated servers must install and enable matching versions on both Master and Caves.

1. Download `Wildwise-mod` from a successful [GitHub Actions](https://github.com/Morilence/Wildwise/actions) build, or [build from source](#build-on-wildwise).
2. Extract the artifact, then extract its `Wildwise-0.3.0.zip` into the game's `mods` directory. Check the structure below to avoid an extra enclosing folder.
3. Enable Wildwise under **Server Mods**. Every player must install the same files before joining.
4. Restart the relevant shard after changing server mod configuration. F7 shows active settings and reasons for disabled features.

```text
mods/
└── Wildwise/
    ├── modinfo.lua
    ├── modmain.lua
    └── scripts/
```

Folder names are case-sensitive, and the `modoverrides.lua` entry must match the installed folder exactly. For a folder named `Wildwise`, use the matching entry in the [complete configuration](#complete-configuration). Merge it into existing configuration while keeping other mod entries. This manual package does not need a Workshop ID.

## Usage

### Get playing

#### Start with F7

Join a world with Wildwise enabled, then click **Wildwise** on the HUD or press **F7**. Settings have Information, Map, Items, Queue and Diagnostics tabs. Choose a minimal, standard or detailed information preset, then set your position and exploration sharing preferences. If the host permits auto pickup, enable it under **F7 → Items → Auto pickup**.

Position and exploration sharing default to allowed in Survival / Endless and off in Wilderness / PvP. Personal switches stop future sharing, but **exploration teammates already learned cannot be withdrawn**. F7 saves personal preferences without changing server configuration.

#### Everyday features

| Feature | What it does and where it stops |
|---|---|
| Information | Hover for health, base damage, food effects adjusted for your character, freshness, durability, fuel, processing, crops and followers. Hold the game's inspect modifier for details. Values without a reliable interface are omitted. |
| Combat health bars | Follows actual combat targets: creatures hostile to you by default, optionally followers or nearby teammates. Defaults to 12 bars and a two-second linger. Visible bars suppress duplicate hover health. |
| Shared maps | Shows teammate names and positions, permitted exploration, numbered pairs for wormholes actually travelled through, and presence in other shards. Endpoints respect fog. Four marker types allow five markers per player, expiring after 60 seconds; charcoal signal fires are also supported. |
| Stacking and pickup | New drops merge into older eligible stacks after landing. Deliberate drops and restored ground decorations are protected by default. Pickup is off by default and needs server permission plus personal opt-in; it normally takes only types already carried and leaves any remainder on the ground. |
| Action queues | Shift-click or select an area for gathering, chopping, mining, farming and supported interactions, up to 200 tasks. Repeat non-structure recipes and preview batch placement. Missing tools / materials or full inventory pause the queue; manual input takes over. |
| Storage signs | Shows the first occupied slot on chests, scaled chests and ancient boat cargo holds by default. Chester, Hutch, ice boxes, salt boxes and tin fishin' bins have separate opt-ins. Bundles can show their first item; empty storage clears the image. |
| Beefalo panel | Shows health, domestication, obedience, tendency, saddle uses, hunger and the native buck timer while riding. B toggles and saves visibility. Woby is not assigned beefalo-specific statistics. |

Cooking queries use four ingredient slots and native recipes. Switch between ordinary and portable cookpots; Warly starts with the portable pot selected. Changing a slot or pot clears old results and invalidates pending replies. Recipe errors include a reason. Candidates show weighted probability and base cooking time, without character or cooker bonuses.

Base damage is not final damage against a target's resistances. Planar damage and defense have separate fields. Spoilage separates the base budget from an estimate assuming the current environment stays unchanged. Estimates use known native multipliers and identify unknown preservers, extra acid-rain spoilage or pauses. Unknown custom food callbacks are not executed to predict effects. Grass, sapling and berrybush regeneration and Woby drying use current native timers; paused or unsupported values are omitted.

Container contents / matching-item lookup, world event details and attack-range values require host permission and default to off. When allowed, the finder can inspect ordinary containers, one layer of bundled items and native pocket storage without unwrapping or spawning anything.

#### Controls

| Input | Action |
|---|---|
| HUD button / F7 | Open settings; menu key can be rebound |
| Game inspect modifier | Expand hover details |
| Shift + click / double-click | Add one target / nearby actionable targets of the same type |
| Shift + left drag | Select an area of targets |
| Deployable material / fertilizer held, or hoe / pitchfork / watering can equipped, Shift + right drag | Preview deployment / tilling / turf digging / soil watering, then Execute plan |
| Shift + click a non-structure recipe | Repeat crafting |
| Movement, ordinary click or attack | Take control and cancel remaining tasks |
| Queue panel | Pause, resume or clear |
| Alt + map left-click | Open the four-way marker picker; choose a type to send, right-click / Esc to cancel |
| Alt + map right-click | Delete your nearby marker |
| C | Craft the last non-structure recipe used in this session once; rebindable |
| B | Toggle and save beefalo panel visibility; rebindable |

Farms support 2×2 / 3×3 / 4×4 layouts; walls and turf follow native alignment. Ordinary building placement retains the game's Shift grid controls. Primary actions follow game bindings, and the queue modifier can be changed.

Chat, opening the map or menu, and losing window focus pause the queue; returning requires explicit resume. Wormhole travel or shard departure clears old queues and previews. Combat, enemy selection and dodging are not automated. Full controller operation still needs real-client validation.

Shift-selecting a drying rack opens it only if needed, collects finished items one slot at a time and leaves still-drying ingredients in place. If you hold a suitable ingredient on the cursor, the queue continues by hanging it. Each transfer waits for native inventory synchronization, with at most 24 collection transfers per rack. Full inventory, missing materials or five seconds without progress pause the workflow.

Collection after work is optional and off by default. Enable it in F7 to queue legal drops within four world units of an actual work point, subject to the same 200-task limit.

#### Make the display work for you

- F7 has separate controls for food effects, spoilage, equipment, processing, farming, followers, cooldowns and timers, plus time / temperature units and line limits. Truncation hints point to expanded details. Personal switches cannot retrieve data disabled by the server.
- Information page 5 offers native mount badges or compact text, separate scaling, fine position offsets, background opacity and hunger visibility. Health / hunger show current and maximum values; badges normalize against the maximum.
- Storage signs retain native inventory images, item skins, spice layers and bundle-size icons. A stored native `minisign_item` supplies its linked sign skin; removing it restores the default. Hosts control sign skins, bundle-content display and sign scale separately.
- Hover a nearby supported container, open F7 and go to Items page 2 to toggle that container's sign for this world session. Restart restores it. Nothing is removed, dug up or consumed. The container must be visible, on the same platform and within six world units.
- Player, marker, signal-fire and wormhole icons have individual display switches. Hosts can disable markers, signal fires and wormholes separately; hiding icons does not withdraw already shared exploration.

Actual skin rendering, resolution layouts and the Combined Status combination still need graphical-client acceptance. Existing headless checks cover native Widgets, image data and entity lifecycles.

### Run your world

#### Permissions and defaults

The server controls feature switches, sharing rules, information permissions, pickup permission and storage types. Players adjust display and actions within those limits; they cannot enable modules the host has disabled. Display options supply initial personal values without overwriting saved preferences.

Only new drops stack by default; manual and restored items need separate host opt-ins. Auto pickup requires **`items_enabled`, `items_pickup_allowed` and the personal switch**. Pickup permission does not enable a disabled stacking source.

World-drop stacking, manual-drop stacking and pickup have separate radii; 0 inherits `items_radius`. Nine ash / manure / seed switches default off. Native drops near twiggy trees, burning / smoldering items and items with operation-specific exclusion tags are protected.

#### Complete configuration

All **74 values below are defaults**, checked against native configuration and tests. Common settings come first; module options use flat prefixes such as `beefalo_hunger_threshold`. Apply to `Master/modoverrides.lua` and also `Caves/modoverrides.lua` if used.

<details>
<summary>Expand the complete copyable configuration</summary>

```lua
return {
    Wildwise = {
        enabled = true, -- Enable the whole mod: true / false
        configuration_options = {
            -- Initial preferences do not overwrite saved personal settings.
            -- Radii use world units; one turf tile is 4 units wide.

            -- General settings
            language = "auto",                          -- Initial interface language; choices: "auto"=Follow game / "en"=English / "zh"=简体中文
            ui_scale = 1,                               -- Initial overall HUD scale; choices: 0.75 / 1 / 1.25 / 1.5
            menu_key = 288,                             -- Initial menu key code; choices: 287=F6 / 288=F7 / 289=F8
            diagnostics = false,                        -- Local reader diagnostics; logs the first failure of each reader; choices: true / false

            -- Information
            info_enabled = true,                        -- Allow item, creature and world information; choices: true / false
            info_container_contents = false,            -- Allow container-content queries and matching-item lookup; choices: true / false
            info_world_events = false,                  -- Allow world-event timer details; choices: true / false
            info_attack_range = false,                  -- Allow attack-range numbers; choices: true / false
            info_font_size = 22,                        -- Initial information font size; choices: 18 / 22 / 26 / 30
            info_combat = true,                         -- Allow combat information; health bars have their own switch; choices: true / false
            info_food_values = true,                    -- Allow food health, hunger, sanity and ingredient details; choices: true / false
            info_perishable = true,                     -- Allow freshness, base spoilage budget and environment estimates; choices: true / false
            info_equipment = true,                      -- Allow durability, insulation, repair and other equipment details; choices: true / false
            info_progress = true,                       -- Allow processing products, remaining times and growth stages; choices: true / false
            info_farm = true,                           -- Allow soil nutrients, moisture and recorded crop stress; choices: true / false
            info_follower = true,                       -- Allow follower leader and loyalty details; choices: true / false
            info_cooldowns = true,                      -- Allow recharge percentages and cooldown times; choices: true / false
            info_timers = true,                         -- Allow timers with known meanings; excludes unnamed internal timers; choices: true / false
            info_max_lines = 10,                        -- Initial normal-hover line limit; minimal preset stays at 4; choices: 4 / 8 / 10 / 15 / 20 / 25
            info_inspect_lines = 25,                    -- Initial expanded-inspection line limit; choices: 10 / 15 / 20 / 25 / 35
            -- Choices: "clock"=Minutes:seconds / "seconds"=Seconds / "days"=Game days / "both"=Time and game days
            info_time_style = "clock",                  -- Initial time format; one game day is 480 seconds
            info_temperature_units = "game",            -- Initial temperature display units; choices: "game"=Game units / "celsius"=Celsius / "fahrenheit"=Fahrenheit

            -- Combat health bars
            healthbars_enabled = true,                  -- Allow combat health bars; choices: true / false
            healthbars_limit = 12,                      -- Initial maximum number of visible health bars; choices: 4 / 8 / 12 / 16 / 20
            healthbars_linger_seconds = 2,              -- Initial seconds to retain a bar after combat; choices: 0 / 1 / 2 / 3 / 5
            healthbars_scale = 1,                       -- Initial health-bar scale; choices: 0.75 / 1 / 1.25 / 1.5
            healthbars_numbers = true,                  -- Initially show health numbers on bars; choices: true / false
            -- Choices: "self"=Self / "followers"=Self and followers / "nearby"=Nearby players / "nearby_followers"=Players and followers
            healthbars_hostile_scope = "self",          -- Initial hostility scope used to select health bars

            -- Map collaboration
            -- Sharing "auto": enabled in Survival/Endless; disabled in Wilderness or PvP.
            -- Sharing "on" permits personal opt-in; "off" forbids sharing.
            map_enabled = true,                         -- Enable map collaboration; choices: true / false
            -- Choices: "auto"=Follow game mode / "on"=Enabled / "off"=Disabled
            map_share_position = "auto",                -- Position-sharing permission; permitted sharing still needs personal opt-in
            -- Choices: "auto"=Follow game mode / "on"=Enabled / "off"=Disabled
            map_share_exploration = "auto",             -- Exploration-sharing permission; learned exploration cannot be withdrawn
            map_wormholes = true,                       -- Enable discovered wormhole pair markers; endpoints still respect fog; choices: true / false
            map_pings = true,                           -- Allow temporary map markers; 5 per player, 60-second lifetime; choices: true / false
            map_signal_fires = true,                    -- Allow charcoal signal-fire markers; choices: true / false

            -- Item handling
            items_enabled = true,                       -- Enable the stacking and auto-pickup service; choices: true / false
            items_stack_world = true,                   -- Allow landed new world drops to merge; choices: true / false
            items_stack_manual = false,                 -- Allow deliberately dropped items to merge; choices: true / false
            items_stack_loaded = false,                 -- Allow restored ground items to merge; off protects saved decorations; choices: true / false
            items_pickup_allowed = false,               -- Allow personal auto-pickup opt-in under F7 > Items; choices: true / false
            items_pickup_existing = true,               -- Only pick up types already carried; false removes this condition; choices: true / false
            items_radius = 4,                           -- Legacy radius inherited by the three source radii when set to 0; choices: 2 / 4 / 6 / 8
            items_world_radius = 0,                     -- New/restored-drop stacking radius; 0 inherits items_radius; choices: 0 / 1 / 2 / 4 / 6 / 8 / 10 / 15 / 20 / 25
            items_manual_radius = 0,                    -- Manual-drop stacking radius; 0 inherits items_radius; choices: 0 / 1 / 2 / 4 / 6 / 8 / 10 / 15 / 20 / 25
            items_pickup_radius = 0,                    -- Auto-pickup radius; 0 inherits items_radius; choices: 0 / 1 / 2 / 4 / 6 / 8 / 10 / 15 / 20 / 25
            items_world_ash = false,                    -- Include ash in world/restored-drop stacking; other permissions still apply; choices: true / false
            items_world_poop = false,                   -- Include manure in world/restored-drop stacking; other permissions still apply; choices: true / false
            items_world_seeds = false,                  -- Include seeds, including crop seeds in world/restored-drop stacking; other permissions still apply; choices: true / false
            items_manual_ash = false,                   -- Include ash in manual-drop stacking; other permissions still apply; choices: true / false
            items_manual_poop = false,                  -- Include manure in manual-drop stacking; other permissions still apply; choices: true / false
            items_manual_seeds = false,                 -- Include seeds, including crop seeds in manual-drop stacking; other permissions still apply; choices: true / false
            items_pickup_ash = false,                   -- Include ash in auto pickup; other permissions still apply; choices: true / false
            items_pickup_poop = false,                  -- Include manure in auto pickup; other permissions still apply; choices: true / false
            items_pickup_seeds = false,                 -- Include seeds, including crop seeds in auto pickup; other permissions still apply; choices: true / false

            -- Action queues
            queue_enabled = true,                       -- Allow action queues and batch-placement previews; choices: true / false
            queue_farm_grid = 3,                        -- Initial planting grid per farm tile; choices: 2=2×2 / 3=3×3 / 4=4×4
            queue_collect_after_work = false,           -- Initially collect legal drops within 4 units after queued work; choices: true / false
            queue_double_click_speed = 0.35,            -- Initial maximum interval between selection clicks, in seconds; choices: 0.2 / 0.25 / 0.35 / 0.5 / 0.75
            queue_double_click_range = 15,              -- Initial same-type selection radius for a double-click; choices: 5 / 10 / 15 / 20 / 25

            -- Smart storage signs
            signs_enabled = true,                       -- Enable smart storage signs; each container switch also applies; choices: true / false
            signs_treasurechest = true,                 -- Show a helper sign on chests; choices: true / false
            signs_dragonflychest = true,                -- Show a helper sign on scaled chests; choices: true / false
            signs_boat_ancient_container = true,        -- Show a helper sign on ancient boat cargo holds; choices: true / false
            signs_chester = false,                      -- Show a helper sign on Chester; choices: true / false
            signs_hutch = false,                        -- Show a helper sign on Hutch; choices: true / false
            signs_icebox = false,                       -- Show a helper sign on ice boxes; choices: true / false
            signs_saltbox = false,                      -- Show a helper sign on salt boxes; choices: true / false
            signs_fish_box = false,                     -- Show a helper sign on tin fishin' bins; choices: true / false
            signs_bundle_contents = true,               -- Draw the first bundled item; false draws the native wrapper icon; choices: true / false
            signs_body_skins = true,                    -- Use a stored minisign_item linked skin for the sign body; choices: true / false
            signs_scale = 0.65,                         -- Scale of the world-space helper sign; choices: 0.5 / 0.65 / 0.8 / 1

            -- Mount status
            beefalo_enabled = true,                     -- Allow the mount status panel; choices: true / false
            beefalo_hunger_threshold = 15,              -- Initial hunger value that activates display; 0 is not an off switch; choices: 0 / 5 / 15 / 25
            beefalo_show_hunger = true,                 -- Allow mount hunger display; players can also hide it individually; choices: true / false
            beefalo_scale = 1,                          -- Initial mount-panel scale, separate from overall HUD scale; choices: 0.75 / 1 / 1.25 / 1.5
        },
    },
}
```

</details>

Keep only the overrides you need; omitted options use game-saved configuration or defaults. Do not quote booleans or numbers. `signs_enabled` is the master switch, with independent container switches. Older flat personal settings are not migrated into `wildwise_client_v2`; server settings continue to use the native fields above.

#### Upgrades, removal and troubleshooting

- Back up the whole cluster, including Master, Caves and player data. Stop the server, replace mod files on every endpoint, restart, and check versions and settings.
- Removal does not undo completed native stacking, pickup or learned exploration. Temporary markers, actions, bars and helper signs are not persisted as game content. Basic removal / reload was tested previously; try complex upgrades on a copy first.
- Unsupported or damaged Wildwise map saves are preserved unchanged and map mutations stop. Keep the save and logs before investigating so recovery does not overwrite the original data.
- When a known enabled Workshop ID has overlapping functionality, Wildwise disables the corresponding feature and shows a reason. See [feature and compatibility notes](docs/features.md); detection does not certify every combination.
- For missing pickup, check both permissions and personal opt-in. For unresponsive menus, check chat / input focus and custom bindings. For join failures, check file versions, folder nesting and both shard configurations.

Use the [bug-report checklist](#contributing) to collect versions, reproduction steps and logs. Temporarily enable `diagnostics` for a summary of the first information-reader failure in each category.

### Build on Wildwise

#### How the modules fit together

The runtime only needs the game's Lua 5.1 and native assets. `core` manages configuration, protocol and lifetimes; `services` owns rules and state; `runtime` adapts engine events and actions; `ui` handles presentation and input. The world component coordinates server services. Information categories have separate readers and error boundaries, so new categories do not require a growing bootstrap function.

Define data ownership and server permission before adding a service or hook. Public methods and non-obvious boundaries have Chinese comments. Every listener, periodic task and wrapper needs cleanup. Public configuration changes must update `modinfo`, configuration, translations, both README examples and tests. See [architecture and extension conventions](docs/architecture.md); no stable third-party plugin API is promised yet.

#### Development environment and commands

Install Lua 5.1 including `luac`, LuaRocks, Python 3 and Node.js 24, then run these commands from the repository root:

```sh
luarocks --lua-version=5.1 install luacheck 1.2.0-1
luarocks --lua-version=5.1 install lua-cjson 2.1.0.10-1
npm ci
npm run format
npm run check
npm run package
```

Pinned StyLua uses Lua 5.1, four spaces, separated function declarations and expanded bodies. `npm run check` runs formatting, static analysis, 139 pure Lua tests, 7 collector fixture tests, package allowlisting and Lua compilation. `npm run package` writes `dist/Wildwise-0.3.0.zip` and its SHA-256. Test code, development dependencies, reference sources and game assets are excluded from the mod archive.

#### What has been validated

This version passed **111 native engine / headless UI contract checks**: 85 base and existing regression checks, 17 capability checks, 6 appearance lifecycle checks and 3 asynchronous drop checks. The skin asset entry uses a stub in the appearance tests; actual skin rendering remains unverified. Earlier save-restore / unwrap checks remain historical evidence. See the [test report](docs/testing.md) for results, concentrated-drop measurements and reproduction commands.

Graphical clients, real multiplayer, actual Master/Caves travel and two-hour stability acceptance remain incomplete. New and existing saves, special characters, skinned / spiced images and external mod combinations still need in-game validation. Public-branch checks do not establish updatebeta support, and the performance probes do not establish globally optimal performance or compatibility across every combination.

## Further reading

- [Feature coverage](docs/features.md): implementation and remaining in-game checks.
- [Architecture and extension conventions](docs/architecture.md): module responsibilities, data ownership, communication and lifetimes.
- [Three-year Workshop review](docs/workshop-issues.md): 35 mods, 3,588 recent unique comments, 74 scenarios, dispositions and regression mappings.
- [0.3.0 implementation record](docs/implementation-2026-09-14.md): capability additions, skin support, configuration changes and remaining acceptance work.
- [Architecture and performance review](docs/optimization-2026-09-14.md): findings, complexity, data flow, state management and validation results.
- [Test and performance report](docs/testing.md): scope and evidence for automated checks, engine contracts and load measurements.
- [Manual regression cases](docs/manual-regressions.md): pending real-player, cave, graphical and sustained-load scenarios.
- [Source and mechanism research](docs/research.md): adopted designs, native interfaces and licensing boundaries.

These detailed documents are currently written in Chinese.

## Maintainers

[@Morilence](https://github.com/Morilence). Use the repository's [Issues](https://github.com/Morilence/Wildwise/issues) for usage questions and project suggestions.

## Contributing

Use [Issues](https://github.com/Morilence/Wildwise/issues) to ask questions, report bugs or discuss features. [Pull requests](https://github.com/Morilence/Wildwise/pulls) for code, documentation and translations are welcome.

For bug reports, include:

- Wildwise version, DST branch / version, hosting type, character and shard.
- Enabled modules, server configuration and relevant personal settings.
- Minimal reproduction steps, expected behavior and actual results.
- Relevant `client_log.txt` and `server_log.txt` excerpts from the failure.

Where possible, reproduce on an isolated copy with only Wildwise enabled. Remove account identifiers and access tokens before posting logs. Temporarily enable `diagnostics` to capture the first information-reader failure per category.

Code changes should follow the [extension conventions](docs/architecture.md) and pass `npm run check`. Describe the change and the tests actually performed in the PR. Keep both complete README examples in sync when adding configuration. Use Conventional Commits, for example `fix: handle expired subscriptions`; repository hooks run the engineering checks and commitlint. State when validation uses headless or simulated-player fixtures, since these do not replace real multiplayer or graphical checks.

## License

[MIT](LICENSE) © 2026 Morilence.

The license covers independently written Wildwise code. Native game resources and reference works retain their respective rights; see [third-party notices](THIRD_PARTY_NOTICES.md).
