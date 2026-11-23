local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Gap from the screen edge
sbar.add("item", { width = settings.group_paddings })

-- Same chip as everything else: bg1 fill, bg2 ring (sizes from default.lua)
sbar.add("item", "apple", {
	icon = {
		font = { size = 16.0 },
		string = icons.apple,
		padding_left = 10,
		padding_right = 10,
	},
	label = { drawing = false },
	background = { color = colors.bg1 },
	padding_left = 0,
	padding_right = 0,
	click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})

sbar.add("item", { width = settings.group_paddings })
