local M = {}

function M.t(str) return vim.api.nvim_replace_termcodes(str, true, true, true) end

function M.feedkeys(keys)
	return function() vim.api.nvim_feedkeys(M.t(keys), "n", true) end
end

-- local tab = vim.api.nvim_buf_get_option(bufnr, "shiftwidth")
function M.indent() return "\t" end

return M
