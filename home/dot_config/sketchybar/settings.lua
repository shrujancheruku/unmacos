-- The rendered Look: Theme colours plus the visual Settings (see colors.lua)
local ok, look = pcall(dofile, os.getenv("HOME") .. "/.local/state/unmacos/theme/sketchybar.lua")
if not ok or type(look) ~= "table" then
  look = {}
end

return {
  paddings = 4,
  group_paddings = 6,
  bar_height = look.bar_height or 44,
  bar_position = look.bar_position or "top",
  chip_height = look.chip_height or 30, -- every chip, bar_height - 14
  -- Chips and popups use the windows' corner radius: the Look's corner_radius, read from the
  -- rendered Look (unmacos-look render), so a change shows on the next bar reload.
  corner_radius = look.corner_radius or 8,

  icons = "sf-symbols", -- alternatively available: NerdFont

  -- The default font: Geist Mono Nerd Font (helpers/default_font.lua), installed by the setup
  -- A font from the Look (bar_font) replaces its family and the weight names that family has.
  font = (function()
    local font = require("helpers.default_font")
    if look.font_text then
      font = { text = look.font_text, numbers = look.font_text, style_map = look.font_styles or font.style_map }
    end
    return font
  end)(),

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
