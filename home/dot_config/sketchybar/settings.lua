-- The rendered Look: Theme colours plus the visual Settings (see colors.lua)
local ok, look = pcall(dofile, os.getenv("HOME") .. "/.local/state/unmacos/theme/sketchybar.lua")
if not ok or type(look) ~= "table" then
  look = {}
end

return {
  paddings = 4,
  group_paddings = 6,
  chip_height = 30, -- every chip; unmacos-toggle-bar reads it for the window gap
  -- Chips and popups use the windows' corner radius: the Look's corner_radius, read from the
  -- rendered Look (unmacos-look render), so a change shows on the next bar reload.
  corner_radius = look.corner_radius or 8,

  icons = "sf-symbols", -- alternatively available: NerdFont

  -- The default font: Geist Mono Nerd Font (helpers/default_font.lua), installed by the setup
  font = require("helpers.default_font"),

  -- Alternatively, this is a font config for JetBrainsMono Nerd Font
  -- font = {
  --   text = "JetBrainsMono Nerd Font", -- Used for text
  --   numbers = "JetBrainsMono Nerd Font", -- Used for numbers
  --   style_map = {
  --     ["Regular"] = "Regular",
  --     ["Semibold"] = "Medium",
  --     ["Bold"] = "SemiBold",
  --     ["Heavy"] = "Bold",
  --     ["Black"] = "ExtraBold",
  --   },
  -- },
}
