local M = {}

--- get cursor position
---@return number[]
function M.get_cursor()
	local cursor = vim.api.nvim_win_get_cursor(0)
	cursor[2] = cursor[2] + 1
	return cursor
end

function M.set_cursor(pos)
	vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] - 1 })
end

--TODO: remove hop dependancy
--- get current window line range
---@return integer, integer
function M.get_win_range()
	local context = require("hop.window").get_window_context()
	context = context[1].contexts[1]
	return context.top_line + 1, context.bot_line + 1
end

return M
