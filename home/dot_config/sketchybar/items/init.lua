require("items.apple")
require("items.menus")
-- Workspace chips: use Rift when it's installed, otherwise AeroSpace.
-- Lets the config switch over by itself once Rift is installed.
local function installed(bin)
	local ok = os.execute("command -v " .. bin .. " >/dev/null 2>&1 || test -x /opt/homebrew/bin/" .. bin)
	return ok == true or ok == 0
end

if installed("rift-cli") then
	require("items.rift_workspaces")
else
	require("items.aerospace_workspaces")
end
-- require("items.front_app")
require("items.calendar")
require("items.widgets")
require("items.media")
