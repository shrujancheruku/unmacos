local settings = require("settings")
local colors = require("colors")

-- Gap from the screen edge
sbar.add("item", { position = "right", width = settings.group_paddings })

-- One chip, two parts: the date (dimmed) and the time on its own inner pill.
-- Right-hand items are laid out right to left, so the time comes first.
local time = sbar.add("item", "calendar.time", {
	position = "right",
	icon = { drawing = false },
	label = {
		color = colors.white,
		padding_left = 8,
		padding_right = 8,
		font = { family = settings.font.numbers, style = settings.font.style_map["Bold"], size = 14.0 },
	},
	background = {
		color = colors.ring,
		border_width = 0,
		height = settings.chip_height - 8,
		corner_radius = 7,
	},
	padding_left = 0,
	padding_right = 4,
	update_freq = 30,
})

local date = sbar.add("item", "calendar.date", {
	position = "right",
	icon = { drawing = false },
	label = {
		color = colors.dim,
		padding_left = 12,
		padding_right = 8,
		font = { style = settings.font.style_map["Semibold"], size = 14.0 },
	},
	padding_left = 0,
	padding_right = 0,
})

sbar.add("bracket", "calendar.bracket", { time.name, date.name }, {
	background = { color = colors.bg1 },
})

sbar.add("item", { position = "right", width = settings.group_paddings })

for _, it in ipairs({ time, date }) do
	it:subscribe("mouse.clicked", function()
		sbar.exec("open -a 'Calendar'")
	end)
end

-- Thin spaces keep "Mon 23 Nov" together as one part
local THIN = "\u{2009}"
time:subscribe({ "forced", "routine", "system_woke" }, function()
	date:set({ label = os.date("%a" .. THIN .. "%d" .. THIN .. "%b") })
	time:set({ label = os.date("%H:%M") })
end)
