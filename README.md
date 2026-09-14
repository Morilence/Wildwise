# Wildwise

[简体中文](README.zh-CN.md)

**Wildwise is a convenience mod for Don't Starve Together.** It combines information, shared exploration, item handling, queued actions, storage signs and beefalo status under one set of server permissions and personal settings. It uses native game UI and assets, with English / Simplified Chinese and keyboard / mouse support.

**0.3.0 is a development build.** On 2026-09-14 we verified the latest official **public branch: game 747465, Steam build 24700372**, and ran tests on that dedicated server. The newer updatebeta branch has not been validated. [Version evidence](docs/evidence/current-engine.json) · [Test results and limits](docs/testing.md)

## For players

| Feature | What it does |
|---|---|
| Information | Hover for health, base damage, character-aware food effects, freshness, durability, fuel, processing, crops and followers. Hold the game's inspect modifier for details. Unsupported values are omitted. |
| Combat health bars | Follows actual combat targets: your opponents by default, optionally followers or nearby teammates. Defaults to 12 bars and a two-second linger. Visible bars suppress duplicate hover health. |
| Shared maps | Teammate names / positions, permitted exploration, numbered pairs for wormholes actually travelled through, and cross-world presence. Endpoints respect fog. Four marker types, five per player, expiring after 60 seconds; charcoal signal fires. |
| Stacking and pickup | New drops merge into older eligible stacks after landing. Deliberate drops and restored ground decorations are protected by default. Pickup needs server permission plus personal opt-in; partially accepted stacks leave the remainder on the ground. |
| Action queues | Shift-select gathering, chopping, mining, farming and supported interactions; up to 200 tasks. Repeat non-structure recipes and preview batch placement. Missing tools / materials or full inventory pause the queue; manual input takes over. |
| Storage signs | Shows the first occupied slot on chests, scaled chests and ancient boat cargo holds by default. Optional Chester, Hutch, ice box, salt box and tin fishin' bin support. Bundles can show their first item; empty storage clears the image. |
| Beefalo panel | Health, domestication, obedience, tendency, saddle uses, hunger and the native buck timer while riding. Toggle with B. Woby is not assigned beefalo-specific statistics. |

Four-ingredient cooking queries use native recipes. Container contents / matching-item lookup, world event details and attack-range values require host permission and default to off. Base damage is not final damage against a particular target. Unknown custom food callbacks are not executed to predict effects. Spoilage separates the base budget from an estimate assuming the current environment stays unchanged; unknown preservers, extra acid-rain spoilage and paused processing are identified without guessing. Cooking candidates show weighted probability and base cooking time.

### Appearance and independent controls

- F7 provides separate information groups, time / temperature units and line limits with truncation hints. Server restrictions still control which data can be received.
- Information page 5 offers native mount badges or compact text, separate scaling, fine position offsets, background opacity and hunger visibility. Health / hunger show current and maximum values; badges normalize against the maximum. B saves visibility.
- Storage signs retain native inventory images, item skins, spice layers and bundle-size icons. A stored native `minisign_item` supplies its linked sign skin; removing it restores the default. Hosts control sign skins, bundle contents and sign scale separately.
- Hover a nearby supported container, open F7 and go to Items page 2 to toggle that container's sign for this server session. Restart restores it. The server requires visibility, the same platform and a distance of at most six world units; contents are unchanged.
- World / manual-drop stacking and pickup have independent radii; 0 inherits the previous `items_radius`. Nine ash / manure / seed switches default off. Native twiggy-tree drops, burning / smoldering items and operation-specific exclusion tags are protected.
- Player / ping / fire / wormhole icons have individual personal switches. Hosts can disable pings, signal fires and wormholes separately. Hiding icons does not withdraw already shared exploration.

Actual skin rendering, resolution layouts and the Combined Status combination still require graphical-client acceptance. Native Widgets, image data and entity lifecycles have been checked without graphics.

### Get started

1. Install the same version as the host and join a world with Wildwise enabled under **Server Mods**.
2. Click **Wildwise** on the HUD or press **F7**. Settings have Information, Map, Items, Queue and Diagnostics tabs.
3. Choose an information preset, then your sharing preferences. For auto pickup, ask the host to enable its server setting, then turn it on under **F7 → Items**.

Position and exploration sharing default to allowed in Survival / Endless and off in Wilderness / PvP. Personal switches stop future sharing; **exploration teammates already learned cannot be withdrawn**. F7 saves personal preferences, not server configuration.

### Controls

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

Farms support 2×2 / 3×3 / 4×4 layouts; walls and turf follow native alignment. Ordinary building placement retains the game's Shift grid controls. Chat, map, menu or window focus loss pauses the queue; returning requires explicit resume. Primary actions follow game bindings; the queue modifier can be changed.

**Drying racks support opening, collecting finished items and rehanging held ingredients.** Still-drying items stay in their slots. One native transfer is requested at a time, with a maximum of 24 transfers per rack; full inventory, missing materials or five seconds without progress pause the workflow. Optional collection after work queues legal drops within four world units of an actual work point, under the existing queue limit. Combat, enemy selection and dodging are not automated. Full controller operation still needs real-client validation.

## For hosts and server owners

Wildwise is a server-enabled mod that **all clients must load**. Reference mods are not required. Distribution currently uses manually installed GitHub build artifacts; it has not been published to Steam Workshop.

1. Download `Wildwise-mod` from a successful [GitHub Actions](https://github.com/Morilence/Wildwise/actions) build, or build from source below.
2. Extract the artifact, then extract its `Wildwise-0.3.0.zip` into the game's `mods` directory. The result must be `mods/Wildwise/modinfo.lua`, without an extra enclosing directory.
3. Enable it under **Server Mods** and distribute the same files to every player. Install and enable the same version on both Master and Caves.
4. Restart the relevant shard after server configuration changes. Check active settings and disabled-feature reasons in F7.

Folder names are case-sensitive: the `modoverrides.lua` entry must exactly match the installed folder, such as `Wildwise` below. Merge it into existing configuration instead of removing other mod entries. This manual package does not require an invented Workshop ID.

### Permissions and defaults

The server controls feature switches, sharing rules, information permissions, pickup permission and storage types. Personal settings operate within those limits. Display options provide initial personal values without overwriting saved preferences.

Only new drops stack by default; manual / restored items need separate host opt-ins. Auto pickup requires **`items_enabled`, `items_pickup_allowed` and the personal switch**. Pickup permission does not enable a disabled stacking source.

### Complete modoverrides.lua example

All **74 values below are defaults**, checked against the native configuration. Common settings come first; module options use flat prefixes such as `beefalo_hunger_threshold`. Apply to `Master/modoverrides.lua` and also `Caves/modoverrides.lua` if used.

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

You may keep only the overrides you need; omitted options use game-saved configuration or defaults. Do not quote booleans or numbers. `signs_enabled` is the master switch, with independent container switches. Older flat personal settings are not migrated into `wildwise_client_v2`; server settings continue to use the native fields above.

### Upgrades, removal and troubleshooting

- Back up the whole cluster, including Master, Caves and player data. Stop the server, replace mod files on every endpoint, restart, and check versions and settings.
- Removal does not undo completed native stacking, pickup or learned exploration. Temporary markers, actions, bars and helper signs are not persisted as game content. Basic removal / reload was tested previously; test complex upgrades on a copy first.
- Unsupported or damaged Wildwise map saves are preserved unchanged and map mutations stop. Keep the save and logs before attempting recovery.
- Known enabled Workshop IDs disable corresponding overlapping Wildwise features with a reason. See [feature and compatibility notes](docs/features.md); this is not certification of every combination.
- For missing pickup, check both permissions and personal opt-in. For keys, check chat / focus and custom bindings. For join failures, check versions, folder nesting and both shard configurations.

A useful bug report includes Wildwise version, DST branch / version, hosting type, character and shard, enabled modules / configuration, minimal steps, expected / actual results, and relevant `client_log.txt` / `server_log.txt` excerpts. Reproduce on an isolated copy with Wildwise alone where possible. Remove account identifiers and access tokens before posting logs. Enable `diagnostics` temporarily for the first information-reader failure per category.

With server permission, the finder can inspect ordinary containers, one layer of bundled items and native pocket storage without unwrapping or spawning anything. Plant regeneration and Woby drying use current native timers. Unknown or paused progress is omitted. Wormhole travel and shard departure cancel old queues and previews.

Recipe queries support ordinary and portable cookpots; Warly starts with the portable pot selected. Changing a slot or pot clears old results and invalidates pending replies. Planar damage and defense have separate fields. Spoilage is labeled as a base budget, since it is not a reliable countdown under changing preservation conditions.

## For mod developers

Runtime dependencies are native game Lua 5.1 and game assets; Node / Python are development tools only. `core` owns configuration, protocol and lifetimes; `services` owns rules and state; `runtime` adapts engine events and actions; `ui` handles presentation and input. The world component coordinates server services. Information categories use isolated readers so extensions do not require a growing bootstrap function.

Define ownership and server permission before adding a service or hook. Public methods and non-obvious boundaries have Chinese comments. Every listener, task and wrapper needs cleanup. Public configuration changes must update modinfo, configuration, translations, both README examples and tests. See [architecture and extension conventions](docs/architecture.md). No stable third-party plugin API is promised yet.

Install Lua 5.1 including `luac`, LuaRocks, Python 3 and Node.js 24, then run:

```sh
luarocks --lua-version=5.1 install luacheck 1.2.0-1
luarocks --lua-version=5.1 install lua-cjson 2.1.0.10-1
npm ci
npm run format
npm run check
npm run package
```

Pinned StyLua uses Lua 5.1, four spaces, separated function declarations and expanded bodies. `check` runs formatting, static analysis, 121 pure Lua tests, 7 collector fixture tests, package allowlisting and Lua compilation. Packaging writes `dist/Wildwise-0.3.0.zip` and its SHA-256. Test code, development dependencies, reference sources and game assets are excluded.

This version passed **111 native engine / headless UI contract checks**: 85 existing checks, 17 capability checks, 6 appearance lifecycle checks and 3 asynchronous drop checks. The skin asset entry uses a stub in the lifecycle tests; actual skin rendering remains unverified. Earlier save-restore / unwrap checks remain historical evidence. **These do not certify graphics, real multiplayer, Master/Caves travel or comparative performance.** See the [test report](docs/testing.md) for scope, load measurements and reproduction commands.

## Documentation and remaining limits

- [Feature coverage](docs/features.md): implementation and remaining in-game checks.
- [Three-year Workshop review](docs/workshop-issues.md): 35 mods, 3,588 recent unique comments, 74 scenarios, dispositions and regression mappings.
- [0.3.0 implementation record](docs/implementation-2026-09-14.md): capability additions, skin support, configuration changes and remaining acceptance work (Chinese).
- [Manual regression cases](docs/manual-regressions.md): pending real-player, cave, graphical and sustained-load scenarios.
- [Source and mechanism research](docs/research.md): adopted designs, native interfaces and licensing boundaries.

Graphical clients, real multiplayer and two-hour stability acceptance remain incomplete. Complex saves, special characters, skinned / spiced images and external mod combinations still need in-game validation. Public-branch checks do not establish updatebeta support or globally optimal performance.

Code is [MIT licensed](LICENSE). Native resources and reference works retain their respective rights; see [third-party notices](THIRD_PARTY_NOTICES.md).
