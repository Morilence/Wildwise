# Wildwise

[简体中文](README.zh-CN.md)

Wildwise is a convenience mod for **Don't Starve Together**, bringing item and creature information, combat health bars, shared maps, item management, action queues, smart storage signs and a beefalo status panel together. It uses the game's familiar interface style and supports keyboard and mouse, English and Simplified Chinese.

> **0.1.0 is a development build.** Graphical client and real multiplayer validation are still incomplete. See the limitations below and the [test report](docs/testing.md) for details.

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

Supported containers, including chests, ice boxes, salt boxes, Chester and Hutch, display an icon for the first occupied slot. Bundles can show their first contained item, and empty containers clear the old icon, making storage easier to identify around your base.

### Beefalo status panel

While riding, view health, domestication, obedience, tendency, remaining saddle uses, hunger and estimated remaining riding time. Press `B` to toggle the panel, or adjust its position and hunger display threshold in the menu.

## Installation

The host enables Wildwise under **Server Mods**, and **the server and every player need the same version**. The current GitHub distribution requires manual installation.

1. Open [GitHub Actions](https://github.com/Morilence/Wildwise/actions), select a successful build and download `Wildwise-mod` under **Artifacts**.
2. Extract that download, then extract the enclosed `Wildwise-0.1.0.zip` into the game's `mods` directory. Confirm this file exists:

   ```text
   Don't Starve Together/mods/Wildwise/modinfo.lua
   ```

3. Enable Wildwise under **Server Mods** when creating the world, adjust its settings and start the world.
4. In game, click the **Wildwise** HUD button or press `F7` to open settings.

For a dedicated server, add this entry to the returned table in each shard's `modoverrides.lua`. Use the same version for Master and Caves:

```lua
["Wildwise"] = { enabled = true },
```

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
