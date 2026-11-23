-- ~/.config/sketchybar/items/rift_workspaces.lua
--
-- Rift Workspace Integration for SketchyBar
-- Workspace chips backed by `rift-cli`.
--
-- Data comes from one call, `rift-cli query workspaces`, which returns a JSON
-- array of workspaces (see rift-protocol WorkspaceData):
--   { index = 0, name = "1", is_active = true, window_count = 2,
--     windows = { { app_name = "Ghostty", ... }, ... } }
-- SbarLua parses JSON output into a Lua table before calling the callback.
--
-- Rift workspace indices are zero-based; the bar shows them as 1..5.
-- ~/.config/rift/config.toml sets workspace_names = ["1".."5"] so names match labels.

local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local RIFT_CLI = "/opt/homebrew/bin/rift-cli"
local probe = io.open(RIFT_CLI, "r")
if probe then
	probe:close()
else
	RIFT_CLI = "rift-cli"
end

local DISPLAY = 1 -- Monitor the chips are pinned to
local WORKSPACES = { "1", "2", "3", "4", "5" }

local STYLE = {
	chip_bg = colors.bg1,
	chip_border = colors.ring, -- same ring as every other chip
	active_border = colors.accent,
	active_icon_highlight = colors.accent,
	active_label_highlight = colors.white,
	inactive_icon_color = colors.dim,
	inactive_label_color = colors.dim,
}

-- Fired by the subscriptions in ~/.config/rift/config.toml (run_on_start)
sbar.add("event", "rift_workspace_changed")
sbar.add("event", "rift_windows_changed")

-- ============================================================================
-- ITEMS
-- ============================================================================

local workspace_items = {} -- name -> { item, pad }

for i, ws in ipairs(WORKSPACES) do
	local rift_index = i - 1

	local item = sbar.add("item", "rws." .. ws, {
		position = "left",
		display = DISPLAY,
		icon = {
			font = { family = settings.font.numbers },
			string = ws,
			padding_left = 12,
			padding_right = 8,
			color = STYLE.inactive_icon_color,
			highlight_color = STYLE.active_icon_highlight,
		},
		label = {
			padding_right = 12,
			color = STYLE.inactive_label_color,
			highlight_color = STYLE.active_label_highlight,
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
		},
		padding_right = 0,
		padding_left = 0,
		background = { color = STYLE.chip_bg, border_color = STYLE.chip_border },
		drawing = "off",
	})

	local pad = sbar.add("item", "rws.pad." .. ws, {
		position = "left",
		display = DISPLAY,
		width = settings.group_paddings,
		drawing = "off",
	})

	-- Left click: switch to workspace. Right click: send focused window there.
	item:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "right" then
			sbar.exec(RIFT_CLI .. " execute workspace move-window " .. rift_index)
		else
			sbar.exec(RIFT_CLI .. " execute workspace switch " .. rift_index)
		end
	end)

	workspace_items[ws] = { item = item, pad = pad }
end

-- ============================================================================
-- UPDATE
-- ============================================================================

local function icon_string(windows)
	local seen, out = {}, ""
	for _, win in ipairs(windows or {}) do
		local app = win.app_name
		if type(app) == "string" and app ~= "" and not seen[app] then
			seen[app] = true
			out = out .. (app_icons[app] or app_icons["Default"] or "·")
		end
	end
	return out ~= "" and out or " —"
end

local function render(ws, data)
	local w = workspace_items[ws]
	local is_focused = data ~= nil and data.is_active == true
	local windows = data and data.windows or {}
	local visible = is_focused or #windows > 0 or (data and (data.window_count or 0) > 0)
	local drawing = visible and "on" or "off"

	w.item:set({ drawing = drawing })
	w.pad:set({ drawing = drawing })
	if not visible then
		return
	end

	local label = icon_string(windows)
	w.item:set({
		icon = { highlight = is_focused },
		label = { string = label, highlight = is_focused },
		background = { border_color = is_focused and STYLE.active_border or STYLE.chip_border },
	})
end

local function update_all_workspaces()
	sbar.exec(RIFT_CLI .. " query workspaces", function(result)
		if type(result) ~= "table" then
			return -- rift not running, or output wasn't JSON
		end

		-- Match by name first (config names them "1".."5"), then by index.
		local by_name, by_index = {}, {}
		for _, data in ipairs(result) do
			if data.name ~= nil then
				by_name[tostring(data.name)] = data
			end
			if data.index ~= nil then
				by_index[data.index + 1] = data
			end
		end

		for i, ws in ipairs(WORKSPACES) do
			render(ws, by_name[ws] or by_index[i])
		end
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

sbar.add("item", "rws.observer", { drawing = "off", updates = true })
	:subscribe({ "rift_workspace_changed", "rift_windows_changed", "front_app_switched", "system_woke" }, function(_)
		update_all_workspaces()
	end)

-- Safety-net refresh; events cover the normal case
local function periodic_refresh()
	update_all_workspaces()
	sbar.delay(15, periodic_refresh)
end

periodic_refresh()
