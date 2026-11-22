-- UnMacOS: the colourscheme comes from the active theme
-- (~/.local/state/unmacos/theme/neovim.lua, written by unmacos-theme-render).
local path = vim.fn.expand("~/.local/state/unmacos/theme/neovim.lua")

-- Re-apply when the theme is switched while Neovim is open (the renderer
-- writes theme.name last)
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local w = vim.uv.new_fs_event()
		if not w then
			return
		end
		w:start(vim.fn.expand("~/.local/state/unmacos"), {}, vim.schedule_wrap(function(_, name)
			if name ~= "theme.name" then
				return
			end
			local ok, spec = pcall(dofile, path)
			if not ok then
				return
			end
			for _, s in ipairs(spec) do
				local cs = s.opts and s.opts.colorscheme
				if cs then
					pcall(vim.cmd.colorscheme, cs)
				end
			end
		end))
	end,
})

local ok, spec = pcall(dofile, path)
if not ok or type(spec) ~= "table" then
	spec = { { "folke/tokyonight.nvim", opts = { transparent = true, styles = { sidebars = "transparent", floats = "transparent" } } } }
end
table.insert(spec, { "arcticicestudio/nord-vim" })
return spec
