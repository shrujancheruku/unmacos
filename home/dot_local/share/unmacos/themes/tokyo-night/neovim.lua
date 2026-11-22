-- UnMacOS tokyo-night: tokyonight.nvim, transparent
return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = { transparent = true, styles = { sidebars = "transparent", floats = "transparent" } },
	},
	{ "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } },
}
