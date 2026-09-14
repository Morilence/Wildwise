# Wildwise

[简体中文](README.zh-CN.md)

**Wildwise is a convenience mod for Don't Starve Together.** It combines information, shared exploration, item handling, queued actions, storage signs and beefalo status under one set of server permissions and personal settings. It uses native game UI and assets, with English / Simplified Chinese and keyboard / mouse support.

**0.2.1 is a development build.** On 2026-09-14 we verified the latest official **public branch: game 747465, Steam build 24700372**, and ran tests on that dedicated server. The newer updatebeta branch has not been validated. [Version evidence](docs/evidence/current-engine.json) · [Test results and limits](docs/testing.md)

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

Four-ingredient cooking queries use native recipes. Container contents / matching-item lookup, world event details and attack-range values require host permission and default to off. Base damage is not final damage against a particular target. Unknown custom food callbacks are not executed to predict effects.

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
| Material on cursor or hoe equipped, Shift + right drag | Preview a placement plan, then choose Execute plan |
| Shift + click a non-structure recipe | Repeat crafting |
| Movement, ordinary click or attack | Take control and cancel remaining tasks |
| Queue panel | Pause, resume or clear |
| Alt + map primary action | Place the selected marker type |
| B | Toggle beefalo panel; key can be rebound |

Farms support 2×2 / 3×3 / 4×4 layouts; walls and turf follow native alignment. Ordinary building placement retains the game's Shift grid controls. Chat, map, menu or window focus loss pauses the queue; returning requires explicit resume. Primary actions follow game bindings; the queue modifier can be changed.

**The new multi-slot drying rack must currently be opened and emptied manually.** Wildwise reads its drying progress but does not queue its RUMMAGE container toggle, avoiding an open / close loop. Queues do not automate combat, target selection or dodging. Full controller support is not available.

## For hosts and server owners

Wildwise is a server-enabled mod that **all clients must load**. Reference mods are not required. Distribution currently uses manually installed GitHub build artifacts; it has not been published to Steam Workshop.

1. Download `Wildwise-mod` from a successful [GitHub Actions](https://github.com/Morilence/Wildwise/actions) build, or build from source below.
2. Extract the artifact, then extract its `Wildwise-0.2.1.zip` into the game's `mods` directory. The result must be `mods/Wildwise/modinfo.lua`, without an extra enclosing directory.
3. Enable it under **Server Mods** and distribute the same files to every player. Install and enable the same version on both Master and Caves.
4. Restart the relevant shard after server configuration changes. Check active settings and disabled-feature reasons in F7.

Folder names are case-sensitive: the `modoverrides.lua` entry must exactly match the installed folder, such as `Wildwise` below. Merge it into existing configuration instead of removing other mod entries. This manual package does not require an invented Workshop ID.

### Permissions and defaults

The server controls feature switches, sharing rules, information permissions, pickup permission and storage types. Personal settings operate within those limits. Display options provide initial personal values without overwriting saved preferences.

Only new drops stack by default; manual / restored items need separate host opt-ins. Auto pickup requires **`items_enabled`, `items_pickup_allowed` and the personal switch**. Pickup permission does not enable a disabled stacking source.

### Complete modoverrides.lua example

All **38 values below are defaults**, checked against the native configuration. Common settings come first; module options use flat prefixes such as `beefalo_hunger_threshold`. Apply to `Master/modoverrides.lua` and also `Caves/modoverrides.lua` if used.

<details>
<summary>Expand the complete copyable configuration</summary>

```lua
return {
    ["Wildwise"] = {
        enabled = true, -- Enable the entire mod: true / false
        configuration_options = {
            -- General settings
            language = "auto",                  -- "auto" follows the game / "zh" Simplified Chinese / "en" English
            ui_scale = 1,                       -- HUD scale multiplier: 0.75 / 1 / 1.25 / 1.5
            menu_key = 288,                     -- Menu key: 287 = F6 / 288 = F7 / 289 = F8
            diagnostics = false,                -- Reader diagnostics: true / false; log the first failure per category

            -- Information
            info_enabled = true,                -- Item, creature and world information; true / false
            info_container_contents = false,    -- Allow content queries and matching-item lookup; true / false
            info_world_events = false,          -- Allow world event details; true / false
            info_attack_range = false,          -- Allow attack range values; true / false
            info_font_size = 22,                -- Information font size: 18 / 22 / 26 / 30

            -- Combat health bars
            healthbars_enabled = true,          -- Combat health bars; true / false
            healthbars_limit = 12,              -- Maximum visible bars: 4 / 8 / 12 / 16 / 20
            healthbars_linger_seconds = 2,      -- Seconds to keep bars after combat: 0 / 1 / 2 / 3 / 5
            healthbars_scale = 1,               -- Bar scale multiplier: 0.75 / 1 / 1.25 / 1.5
            healthbars_numbers = true,          -- Show health numbers: true / false
            -- "self": yourself; "followers": yourself and your followers
            -- "nearby": nearby players; "nearby_followers": nearby players and followers
            healthbars_hostile_scope = "self",  -- Which combat targets qualify for health bars

            -- Map collaboration
            map_enabled = true,                 -- Map collaboration; true / false
            -- Sharing rules: "auto" / "on" / "off"
            -- "auto": enabled in Survival/Endless; disabled in Wilderness or PvP
            -- "on": allow sharing, respecting personal switches; "off": prohibit sharing
            map_share_position = "auto",        -- Position sharing
            map_share_exploration = "auto",     -- Exploration sharing

            -- Item handling
            items_enabled = true,               -- Automatic stacking and pickup service; true / false
            items_stack_world = true,           -- Stack newly dropped items; true / false
            items_stack_manual = false,         -- Stack items deliberately dropped by players; true / false
            items_stack_loaded = false,         -- Stack ground items restored from a save; true / false
            items_pickup_allowed = false,       -- Let players enable auto pickup under F7 → Items; true / false
            items_pickup_existing = true,       -- Pick up only item types already carried; false removes this condition; true / false
            items_radius = 4,                   -- Stacking/pickup radius in game units: 2 / 4 / 6 / 8

            -- Action queues
            queue_enabled = true,               -- Action queues and batch placement; true / false
            queue_farm_grid = 3,                -- Farm layout per tile: 2 = 2×2 / 3 = 3×3 / 4 = 4×4

            -- Smart storage signs
            signs_enabled = true,               -- Smart storage signs; true / false
            signs_treasurechest = true,          -- Chests; true / false
            signs_dragonflychest = true,         -- Scaled chests; true / false
            signs_boat_ancient_container = true, -- Ancient boat cargo holds; true / false
            signs_chester = false,               -- Chester; true / false
            signs_hutch = false,                 -- Hutch; true / false
            signs_icebox = false,                -- Ice boxes; true / false
            signs_saltbox = false,               -- Salt boxes; true / false
            signs_fish_box = false,              -- Tin fishin' bins; true / false

            -- Beefalo status panel
            beefalo_enabled = true,             -- Beefalo status panel; true / false
            beefalo_hunger_threshold = 15,      -- Hunger display activation threshold, in hunger points: 0 / 5 / 15 / 25
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

Pinned StyLua uses Lua 5.1, four spaces, separated function declarations and expanded bodies. `check` runs formatting, static analysis, 99 pure Lua tests, 7 collector fixture tests, package allowlisting and Lua compilation. Packaging writes `dist/Wildwise-0.2.1.zip` and its SHA-256. Test code, development dependencies, reference sources and game assets are excluded.

This follow-up adds 34 native engine checks. Earlier native automated checks cover 26 entity tests, 9 new regressions, 7 headless UI tests, 8 container types, 2 asynchronous drop tests, 1 host-path contract and 2 save-restore / unwrap checks. **These do not certify graphics, real multiplayer, Master/Caves travel or comparative performance.** See the [test report](docs/testing.md) for scope, load measurements and reproduction commands.

## Documentation and remaining limits

- [Feature coverage](docs/features.md): implementation and remaining in-game checks.
- [Three-year Workshop review](docs/workshop-issues.md): 35 mods, 3,588 recent unique comments, 74 scenarios, dispositions and regression mappings.
- [Manual regression cases](docs/manual-regressions.md): pending real-player, cave, graphical and sustained-load scenarios.
- [Source and mechanism research](docs/research.md): adopted designs, native interfaces and licensing boundaries.

Graphical clients, real multiplayer and two-hour stability acceptance remain incomplete. Complex saves, special characters, skinned / spiced images and external mod combinations still need in-game validation. Public-branch checks do not establish updatebeta support or globally optimal performance.

Code is [MIT licensed](LICENSE). Native resources and reference works retain their respective rights; see [third-party notices](THIRD_PARTY_NOTICES.md).
