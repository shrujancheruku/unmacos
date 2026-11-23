-- ~/.config/sketchybar/helpers/app_icons.lua
--
-- App name -> sketchybar-app-font ligature (e.g. "Firefox" -> ":firefox:").
--
-- Instead of a hand-maintained table, this uses the icon_map.lua that
-- sketchybar-app-font publishes with every release, matched to the font
-- version Homebrew has installed (the cask ships only the .ttf):
--
--   1. Cached map for the installed version:
--        ~/.cache/sketchybar/sketchybar-app-font/icon_map-<version>.lua
--   2. Otherwise helpers/app_icons_vendored.lua (a snapshot), and the
--      matching map is downloaded in the background. When it lands it is
--      merged into this same table, so new apps light up without a reload.
--   3. OVERRIDES below always win: apps the font has no glyph for yet.
--
-- Apps with no entry fall back to ":default:" (callers use app_icons["Default"]).

-- Apps missing from the font. Key = app name as macOS / rift-cli reports it.
local OVERRIDES = {
	-- Orca (com.stablyai.orca): no glyph upstream yet; the dolphin fin is
	-- the closest silhouette to Orca's own logo.
	["Orca"] = ":dolphin:",
}

local CASKROOM = "/opt/homebrew/Caskroom/font-sketchybar-app-font"
local RELEASES = "https://github.com/kvndrsslr/sketchybar-app-font/releases/download"
local CACHE_DIR = (os.getenv("HOME") or "") .. "/.cache/sketchybar/sketchybar-app-font"

local icons = {}

local function merge(map)
	for name, glyph in pairs(map) do
		if type(name) == "string" and type(glyph) == "string" then
			icons[name] = glyph
		end
	end
	for name, glyph in pairs(OVERRIDES) do
		icons[name] = glyph
	end
end

-- Load a map file as data: empty environment, text only, must return a table.
local function load_map(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local src = f:read("a")
	f:close()
	local chunk = load(src, "=" .. path, "t", {})
	if not chunk then
		return nil
	end
	local ok, map = pcall(chunk)
	if ok and type(map) == "table" and map["Default"] then
		return map
	end
	return nil
end

local function installed_version()
	local p = io.popen("ls '" .. CASKROOM .. "' 2>/dev/null | sort -V | tail -1")
	if not p then
		return nil
	end
	local v = (p:read("a") or ""):gsub("%s+", "")
	p:close()
	if v:match("^%d+%.%d+%.%d+$") then
		return v
	end
	return nil
end

local helpers_dir = (debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")) or "."
merge(load_map(helpers_dir .. "/app_icons_vendored.lua") or { ["Default"] = ":default:" })

local version = installed_version()
if version then
	local cached = CACHE_DIR .. "/icon_map-" .. version .. ".lua"
	local map = load_map(cached)
	if map then
		merge(map)
	elseif sbar and sbar.exec then
		local tmp = cached .. ".part"
		local cmd = string.format(
			"mkdir -p '%s' && curl -fsSL --max-time 20 -o '%s' '%s/v%s/icon_map.lua' && mv '%s' '%s'; rm -f '%s'",
			CACHE_DIR, tmp, RELEASES, version, tmp, cached, tmp
		)
		sbar.exec(cmd, function()
			local fresh = load_map(cached)
			if fresh then
				merge(fresh)
			end
		end)
	end
end

return icons
