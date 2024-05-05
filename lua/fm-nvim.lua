local M = {}
local api = vim.api
local fn = vim.fn

local config = {
	ui = {
		float = {
			border = "none",
			float_hl = "Normal",
			border_hl = "FloatBorder",
			blend = 0,
			height = 0.8,
			width = 0.8,
			x = 0.5,
			y = 0.5,
		},
	},
	broot_conf = fn.stdpath("data") .. "/site/pack/packer/start/fm-nvim/assets/broot_conf.hjson",
	edit_cmd = "edit",
	on_close = {},
	on_open = {},
	cmds = {
		nnn_cmd = "nnn",
	},
	mappings = {
		vert_split = "<C-v>",
		horz_split = "<C-h>",
		tabedit = "<C-t>",
		edit = "<C-e>",
		ESC = "<ESC>",
	},
}

local method = config.edit_cmd
function M.setup(user_options)
	config = vim.tbl_deep_extend("force", config, user_options)
	vim.g.loaded_netrwPlugin = 1
	vim.g.loaded_netrw = 1

	vim.schedule(function()
		M.on_enter()
	end)
end

local function window_exist()
	if M.buf == nil then
		return false
	end

	return api.nvim_buf_is_loaded(M.buf)
end

function M.on_enter()
	local bufname = api.nvim_buf_get_name(0)
	local stats = vim.loop.fs_stat(bufname)

	if not stats then
		return false
	end

	if stats.type ~= "directory" then
		return false
	end

	local exist = window_exist()

	if not exist then
		M.Nnn()
	end

	return true
end

function M.setMethod(opt)
	method = opt
end

local function checkFile(file)
	if io.open(file, "r") ~= nil then
		for line in io.lines(file) do
			vim.cmd(method .. " " .. fn.fnameescape(line))
		end
		method = config.edit_cmd
		io.close(io.open(file, "r"))
		os.remove(file)
	end
end

local function on_exit()
	M.closeCmd()
	for _, func in ipairs(config.on_close) do
		func()
	end
	checkFile("/tmp/fm-nvim")
	checkFile(fn.getenv("HOME") .. "/.cache/fff/opened_file")
	vim.cmd([[ checktime ]])
end

local function postCreation(suffix)
	for _, func in ipairs(config.on_open) do
		func()
	end
	api.nvim_buf_set_option(M.buf, "filetype", "Fm")
	api.nvim_buf_set_keymap(
		M.buf,
		"t",
		config.mappings.edit,
		'<C-\\><C-n>:lua require("fm-nvim").setMethod("edit")<CR>i' .. suffix,
		{ silent = true }
	)
	api.nvim_buf_set_keymap(
		M.buf,
		"t",
		config.mappings.tabedit,
		'<C-\\><C-n>:lua require("fm-nvim").setMethod("tabedit")<CR>i' .. suffix,
		{ silent = true }
	)
	api.nvim_buf_set_keymap(
		M.buf,
		"t",
		config.mappings.horz_split,
		'<C-\\><C-n>:lua require("fm-nvim").setMethod("split | edit")<CR>i' .. suffix,
		{ silent = true }
	)
	api.nvim_buf_set_keymap(
		M.buf,
		"t",
		config.mappings.vert_split,
		'<C-\\><C-n>:lua require("fm-nvim").setMethod("vsplit | edit")<CR>i' .. suffix,
		{ silent = true }
	)
	api.nvim_buf_set_keymap(M.buf, "t", "<ESC>", config.mappings.ESC, { silent = true })
end

local function createWin(cmd, suffix)
	M.buf = api.nvim_create_buf(false, true)
	local win_height = math.ceil(api.nvim_get_option("lines") * config.ui.float.height - 4)
	local win_width = math.ceil(api.nvim_get_option("columns") * config.ui.float.width)
	local col = math.ceil((api.nvim_get_option("columns") - win_width) * config.ui.float.x)
	local row = math.ceil((api.nvim_get_option("lines") - win_height) * config.ui.float.y - 1)
	local opts = {
		style = "minimal",
		relative = "editor",
		border = config.ui.float.border,
		width = win_width,
		height = win_height,
		row = row,
		col = col,
	}
	M.win = api.nvim_open_win(M.buf, true, opts)

	postCreation(suffix)
	fn.termopen(cmd, { on_exit = on_exit })
	api.nvim_command("startinsert")
	api.nvim_win_set_option(
		M.win,
		"winhl",
		"Normal:" .. config.ui.float.float_hl .. ",FloatBorder:" .. config.ui.float.border_hl
	)
	api.nvim_win_set_option(M.win, "winblend", config.ui.float.blend)
	M.closeCmd = function()
		api.nvim_win_close(M.win, true)
		api.nvim_buf_delete(M.buf, { force = true })
	end
end

function M.Nnn(dir)
	dir = dir or fn.expand("%:p")
	vim.schedule(function()
		createWin(config.cmds.nnn_cmd .. " -p /tmp/fm-nvim " .. dir, "<CR>")
	end)
end

return M
