# Wildwise

[简体中文](README.zh-CN.md)

Wildwise is a convenience mod for **Don't Starve Together**, bringing item and creature information, combat health bars, shared maps, item management, action queues, smart storage signs and a beefalo status panel together. It uses the game's familiar interface style and supports keyboard and mouse, English and Simplified Chinese.

> **0.2.1 is a development build.** Graphical client and real multiplayer validation are still incomplete. See the limitations below and the [test report](docs/testing.md) for details.

## Features

### Item, creature and world information

Hover over a target to see relevant health, base damage, food effects, freshness, equipment durability, fuel and processing progress. Food effects account for your character; crops and followers have their own growth and status information.

Hold the game's inspect modifier to expand details, or choose the Minimal, Standard or Detailed display preset. You can also query cooking results for four ingredients. Container contents, matching-item lookup, world event details and attack range values require the host's permission.

### Combat health bars

Bars follow creatures' current combat targets. By default, they cover creatures targeting you; you can extend this to followers or nearby teammates' fights. The default limit is **12 bars**, with a **two-second** delay before they disappear after combat. The limit, scale and health numbers are configurable.

When a creature already has a visible health bar, its hover text omits duplicate health information. If the bar is not shown, health remains available by hovering.

### Shared maps

See teammates' positions and names, share exploration, and keep numbered pairs for wormholes you have travelled through. Pairs use both colours and numbers; unexplored endpoints remain hidden by fog. Teammates in another world are listed by their world.

Place Location, Danger, Resource or Rally markers on the map. Each player can have **five markers**, which expire after **60 seconds**. Players can clear their own markers, and admins can clear everyone's. Adding charcoal to a campfire creates a signal fire; off-screen teammate indicators appear while viewing the player list by default.

### Automatic stacking and pickup

Nearby matching items from new drops stack automatically after landing. Items deliberately dropped by players and ground items restored from a save are protected by default.

Auto pickup is a separate option and, by default, collects only item types you already carry. If several players qualify, the nearest player receives the items. When only part of a stack fits in the inventory, the remainder stays on the ground.

### Action queues and batch placement

Use `Shift` with clicks or drags to select targets for gathering, chopping, mining, farming and supported structure interactions. You can also repeat non-structure crafting recipes. The default limit is **200 tasks or placement points**.

If a tool breaks, the queue tries a replacement from your inventory. It pauses when materials run out, the inventory is full or your character cannot perform the action. Move, click normally or attack at any time to take control and cancel the remaining tasks.

With material on the cursor or a hoe equipped, `Shift` + right drag creates a placement preview; choose **Execute plan** to begin. Farm layouts support **2×2, 3×3 and 4×4** patterns, while turf and walls follow the game's alignment rules. Invalid points show a cross. Ordinary single-building placement keeps its usual controls.

### Smart storage signs

Chests, scaled chests and ancient boat cargo holds display an icon for the first occupied slot by default. Signs on Chester, Hutch, ice boxes, salt boxes and tin fishin' bins are off by default; enable them individually in the server mod configuration. Each chest type can also be disabled separately. Bundles can show their first contained item, and empty containers clear the old icon, making storage easier to identify around your base.

### Beefalo status panel

While riding, view health, domestication, obedience, tendency, remaining saddle uses, hunger and estimated remaining riding time. Press `B` to toggle the panel, or adjust its position and hunger display threshold in the menu.

## Installation

The host enables Wildwise under **Server Mods**, and **the server and every player need the same version**. The current GitHub distribution requires manual installation.

1. Open [GitHub Actions](https://github.com/Morilence/Wildwise/actions), select a successful build and download `Wildwise-mod` under **Artifacts**.
2. Extract that download, then extract the enclosed `Wildwise-0.2.1.zip` into the game's `mods` directory. Confirm this file exists:

   ```text
   Don't Starve Together/mods/Wildwise/modinfo.lua
   ```

3. Enable Wildwise under **Server Mods** when creating the world, adjust its settings and start the world.
4. In game, click the **Wildwise** HUD button or press `F7` to open settings.

For a dedicated server, use the [complete modoverrides.lua example](#modoverrideslua-example) below. Install the same version on Master and Caves and configure each shard.

## Controls

| Input | Action |
|---|---|
| HUD button / `F7` | Open settings |
| Game inspect modifier | Expand hover details |
| `Shift` + click | Add one target |
| `Shift` + double-click | Select nearby actionable targets of the same type |
| `Shift` + left drag | Select targets within a region |
| `Shift` + right drag | Preview batch placement with cursor material or a hoe |
| `Shift` + recipe click | Repeat a non-structure recipe |
| Movement, ordinary click, attack | Take control and cancel the queue |
| Queue panel | Pause, resume or clear |
| `Alt` + map primary click | Create the selected marker type |
| `B` | Toggle the beefalo panel |

The menu key, queue modifier and beefalo key can be rebound in settings. Primary action buttons follow your game bindings. Opening chat, the map or a menu, or switching away from the game window, pauses the queue. Click **Resume** when you are ready to continue.

## Settings and defaults

The `F7` menu has five tabs: **Information, Map, Items, Queue and Diagnostics**. The host controls shared rules and available features; players choose their own display and action preferences within those rules. Personal display changes apply immediately. Server mod configuration changes require a world restart.

| Setting | Default behaviour |
|---|---|
| Information display | Standard preset; adjustable categories, font size and scale |
| Container contents, world event details, attack range values | Off; require host permission |
| Stacking new drops | On |
| Stacking manual drops and loaded ground items | Off |
| Auto pickup | Off; requires host permission and personal opt-in |
| Pickup eligibility | Only item types already carried |
| Position and exploration sharing | On in Survival/Endless; off in Wilderness/PvP |
| Off-screen teammate indicators | Shown while viewing the player list |

**Enable auto pickup:** the host first enables **Allow opt-in auto pickup** in the server mod configuration and restarts the world. Each player can then enable **Auto pickup** under `F7 → Items`.

**Adjust sharing:** use `F7 → Map` to control your position and exploration sharing separately. Turning sharing off stops future contributions; exploration already learned by teammates cannot be withdrawn. Options disabled by server rules or an overlapping mod show the reason.

### modoverrides.lua example

General settings (language, interface scale, menu key and diagnostics) come first, followed by each feature module. DST uses flat native configuration fields, so module options have explicit prefixes such as `beefalo_hunger_threshold`. This example works directly in the native configuration file without an extra script. Old configuration keys are no longer read, and previous local personal settings are not migrated.

This example lists all **38 server mod configuration options**, with their default values and comments explaining their purpose and accepted values. The world creation screen uses the same options. Boolean `true` enables a setting and `false` disables it. Leave booleans and numbers unquoted; keep quotes around strings.

Save the configuration in your save cluster's `Master/modoverrides.lua` and, if caves are enabled, configure `Caves/modoverrides.lua` too. For an existing file, merge the `["Wildwise"]` entry into its existing `return` table and keep other mod entries. Edit the existing Wildwise entry if there is one. `Wildwise` must match the manually installed mod's directory name.

```lua
return {
    ["Wildwise"] = {
        enabled = true, -- Enable the entire mod: true / false
        configuration_options = {
            -- General settings
            language = "auto",                  -- "auto" follows the game / "zh" Simplified Chinese / "en" English
            ui_scale = 1,                       -- HUD scale multiplier: 0.75 / 1 / 1.25 / 1.5
            menu_key = 288,                     -- Menu key: 287 = F6 / 288 = F7 / 289 = F8
            diagnostics = false,                -- Reserved diagnostic logging switch: true / false; currently has no effect on log output

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

You can keep only the options you want to override. Omitted options use the game's saved configuration or the mod defaults. Restart the affected worlds after editing. Keep both shards' configurations consistent when you want the same rules on the surface and in the caves.

**Enable signs by container type:** keep `signs_enabled = true` and enable each desired type, for example `signs_chester = true`. Setting `signs_enabled = false` disables signs on every type. These switches are available in both the server mod configuration screen and `modoverrides.lua`; restart the affected worlds to apply changes.

The F7 menu saves personal preferences and does not rewrite `modoverrides.lua`. Server feature switches and permissions remain authoritative: for example, `items_enabled = false` disables item handling, so auto pickup will not run even with `items_pickup_allowed = true`. Display options provide initial personal settings and do not force changes to a player's saved preferences.

## Compatibility and limitations

Wildwise does not require other convenience mods. When a known mod provides the same feature, Wildwise disables its overlapping feature and displays a notice. See the [feature and compatibility guide](docs/features.md) for the list.

Graphical UI, real multiplayer sessions, travel between the surface and caves, and combinations with Geometric Placement, Minimap HUD and Combined Status still need validation. Storage-sign visuals for some skins, spiced foods and bundles have not been verified in a graphical client. Some information may be unavailable for unsupported items or characters.

The queue does not select enemies, automate combat or dodge attacks. Full controller support is not available. Consult the [coverage guide](docs/features.md) and [test report](docs/testing.md) for detailed boundaries and validation status.

## Maintenance and development

The source uses Lua 5.1. Development and packaging require Lua 5.1 (including `luac`), LuaRocks, Python 3 and Node.js 24. After installing those tools, run these commands in the repository:

```sh
luarocks --lua-version=5.1 install luacheck 1.2.0-1
luarocks --lua-version=5.1 install lua-cjson 2.1.0.10-1
npm ci
npm run check
npm run package
```

The mod archive is written to `dist/`. See [architecture](docs/architecture.md) for the modules, [testing](docs/testing.md) for dedicated-server test instructions and [research](docs/research.md) for reference sources. Code is [MIT licensed](LICENSE); game assets and other works retain their respective rights as described in [third-party notices](THIRD_PARTY_NOTICES.md).
