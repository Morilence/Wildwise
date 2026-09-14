local H = require("tests/harness")
local Config = require("wildwise/core/config")
local Protocol = require("wildwise/core/protocol")
local json = require("cjson")

local function native_options()
    local env, chunk = { locale = "zh" }, assert(loadfile("modinfo.lua"))
    setfenv(chunk, env)()
    local options = {}
    for _, option in ipairs(env.configuration_options) do
        assert(not options[option.name], "duplicate native option: " .. option.name)
        options[option.name] = option
    end
    return options
end

H.test("native configuration choices map to the same structured fields and defaults", function()
    local native = native_options()
    for _, field in ipairs(Config.fields) do
        local path, name = field[1], field[1]:gsub("%.", "_")
        local option = assert(native[name], "missing native field: " .. name)
        H.eq(option.default, Config.get(Config.defaults, path))
        H.eq(#option.options, field[2] and #field[2] or 2)
        for _, choice in ipairs(option.options) do
            local config, invalid = Config.load(function(key)
                if key == name then
                    return choice.data
                end
            end)
            H.eq(Config.get(config, path), choice.data)
            H.eq(#invalid, 0)
        end
        native[name] = nil
    end
    H.eq(next(native), nil)
end)

H.test("disabled modules false permissions and zero thresholds survive configuration loading", function()
    local input = {
        info_enabled = false,
        healthbars_enabled = false,
        map_enabled = false,
        items_enabled = false,
        queue_enabled = false,
        signs_enabled = false,
        beefalo_enabled = false,
        items_pickup_existing = false,
        healthbars_linger_seconds = 0,
        beefalo_hunger_threshold = 0,
    }
    local config = Config.load(function(key)
        return input[key]
    end)
    for _, module in ipairs({ "info", "healthbars", "map", "items", "queue", "signs", "beefalo" }) do
        H.eq(config[module].enabled, false)
    end
    H.eq(config.items.pickup_existing, false)
    H.eq(config.healthbars.linger_seconds, 0)
    H.eq(config.beefalo.hunger_threshold, 0)
end)

H.test("invalid public values fall back and old or private keys cannot configure services", function()
    local input = {
        items_radius = 0,
        beefalo_hunger_threshold = "25",
        map_share_position = true,
        info_enabled = {},
        hunger_threshold = 25,
        info = false,
        item_budget = 999,
        items_budget = 999,
    }
    local config, invalid = Config.load(function(key)
        return input[key]
    end)
    H.eq(#invalid, 4)
    H.eq(config.items.radius, 4)
    H.eq(config.beefalo.hunger_threshold, 15)
    H.eq(config.map.share_position, "auto")
    H.eq(config.info.enabled, true)
    H.eq(config.items.budget, 16)
end)

H.test("module settings copies cannot mutate defaults another client or server permissions", function()
    local config = Config.load(function() end)
    local a, b = Config.settings(config), Config.settings(config)
    a.healthbars.enabled = false
    a.info.categories.food = false
    H.eq(b.healthbars.enabled, true)
    H.eq(b.info.categories.food, true)
    H.eq(config.healthbars.enabled, true)
    config.items.enabled = false
    H.eq(Config.defaults.items.enabled, true)
    H.eq(a.items.enabled, nil)
    H.eq(a.beefalo.enabled, nil)
end)

H.test("nested personal settings round trip without importing server rules or flat legacy keys", function()
    local settings = Config.settings(Config.defaults)
    Config.restore(
        settings,
        json.decode(json.encode({
            ui_scale = 1.25,
            beefalo = { hunger_threshold = 0, visible = false, enabled = false },
            info = { categories = { food = false }, font_size = "bad" },
            items = { pickup = true, pickup_allowed = true },
            hunger_threshold = 25,
        }))
    )
    H.eq(settings.ui_scale, 1.25)
    H.eq(settings.beefalo.hunger_threshold, 0)
    H.eq(settings.beefalo.visible, false)
    H.eq(settings.info.categories.food, false)
    H.eq(settings.info.categories.combat, true)
    H.eq(settings.info.font_size, 22)
    H.eq(settings.items.pickup, true)
    H.eq(settings.items.pickup_allowed, nil)
    H.eq(settings.beefalo.enabled, nil)
    H.eq(settings.hunger_threshold, nil)
    Config.set(settings, "beefalo.hunger_threshold", 5)
    H.eq(Config.get(settings, "beefalo.hunger_threshold"), 5)
end)

H.test("module conflicts preserve sibling settings and only disable the requested feature", function()
    local config = Config.load(function() end)
    local reasons = Config.compat(config, { "workshop-362175979", "workshop-2477889104" })
    H.eq(config.map.enabled, true)
    H.eq(config.map.wormholes, false)
    H.eq(config.beefalo.enabled, false)
    H.eq(config.beefalo.hunger_threshold, 15)
    assert(reasons.wormholes and reasons.beefalo)
end)

H.test("structured server settings fit the welcome RPC and preserve disabled flags", function()
    local config = Config.load(function(key)
        if key == "beefalo_enabled" then
            return false
        end
    end)
    local bytes = assert(Protocol.encode(json, "welcome", "session", 1, {
        nonce = "test",
        config = config,
        conflicts = {},
        shard = "Master",
        preferences = { position = true, exploration = true },
    }))
    local message = assert(Protocol.decode(json, bytes))
    H.eq(message.data.config.beefalo.enabled, false)
    H.eq(message.data.config.beefalo.hunger_threshold, 15)
    H.eq(message.data.config.language, "auto")
end)

H.test("both README configuration examples cover exactly the native defaults", function()
    local native = native_options()
    for _, filename in ipairs({ "README.md", "README.zh-CN.md" }) do
        local file = assert(io.open(filename))
        local content = file:read("*a")
        file:close()
        local source = assert(content:match("```lua\n(.-)\n```"), "missing Lua example: " .. filename)
        local chunk = assert(loadstring(source))
        setfenv(chunk, {})
        local entry = chunk().Wildwise
        H.eq(entry.enabled, true)
        local count = 0
        for name, value in pairs(entry.configuration_options) do
            local option = assert(native[name], "unknown documented option: " .. name)
            H.eq(value, option.default)
            count = count + 1
        end
        H.eq(count, #Config.fields)
    end
end)
