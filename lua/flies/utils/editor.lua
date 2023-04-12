local M = {}

function M.t(str) return vim.api.nvim_replace_termcodes(str, true, true, true) end

function M.feedkeys(keys, remap)
	return function() vim.api.nvim_feedkeys(M.t(keys), remap and "m" or "n", true) end
end

-- local tab = vim.api.nvim_buf_get_option(bufnr, "shiftwidth")
function M.indent() return "\t" end

function M.win_range()
	local context = require("hop.window").get_window_context()
	context = context[1].contexts[1]
	return context.top_line + 1, context.bot_line + 1
end

return M
