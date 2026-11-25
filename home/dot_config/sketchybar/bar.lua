local colors = require("colors")
local settings = require("settings")

-- Equivalent to the --bar domain
sbar.bar({
  height = settings.bar_height,
  position = settings.bar_position,
  color = colors.bar.bg,
  padding_right = 2,
  padding_left = 2,
})
