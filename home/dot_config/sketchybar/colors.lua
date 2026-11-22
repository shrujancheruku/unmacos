-- UnMacOS: colours come from the active theme, rendered by unmacos-theme-render
-- into ~/.local/state/unmacos/theme/sketchybar.lua. The values below are the
-- Tokyo Night fallback used before the first render.
local fallback = {
	black = 0xff1a1b26,
	white = 0xffc0caf5,
	red = 0xfff7768e,
	green = 0xff9ece6a,
	blue = 0xff7aa2f7,
	yellow = 0xffe0af68,
	orange = 0xffff9e64,
	magenta = 0xffbb9af7,
	grey = 0xff565f89,
	accent = 0xff7aa2f7,
	bar_bg = 0x001a1b26,
	bar_border = 0xff292e42,
	popup_bg = 0xc01f2335,
	popup_border = 0xff565f89,
	bg1 = 0xff1f2335,
	bg2 = 0xff24283b,
}

local ok, t = pcall(dofile, os.getenv("HOME") .. "/.local/state/unmacos/theme/sketchybar.lua")
if not ok or type(t) ~= "table" then
	t = fallback
end
for k, v in pairs(fallback) do
	if t[k] == nil then
		t[k] = v
	end
end

return {
	black = t.black,
	white = t.white,
	red = t.red,
	green = t.green,
	blue = t.blue,
	yellow = t.yellow,
	orange = t.orange,
	magenta = t.magenta,
	grey = t.grey,
	accent = t.accent,
	transparent = 0x00000000,

	bar = { bg = t.bar_bg, border = t.bar_border },
	popup = { bg = t.popup_bg, border = t.popup_border },
	bg1 = t.bg1,
	bg2 = t.bg2,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
