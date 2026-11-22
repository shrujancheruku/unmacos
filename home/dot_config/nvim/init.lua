-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Use the nvm Node for plugins, if it's installed
local node_bin = vim.env.HOME .. "/.nvm/versions/node/v24.12.0/bin"
if vim.uv.fs_stat(node_bin .. "/node") then
	vim.g.node_host_prog = node_bin .. "/node"
	vim.env.PATH = node_bin .. ":" .. vim.env.PATH
end
