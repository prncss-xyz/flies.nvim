local M = {}

--- replace vim-style escape characters with internal representation
---@param str string
function M.t(str) return vim.api.nvim_replace_termcodes(str, true, true, true) end

--- feed vim-style espace character sequence
---@param keys string
---@param remap boolean
function M.feedkeys(keys, remap)
	return function() vim.api.nvim_feedkeys(M.t(keys), remap and "m" or "n", true) end
end

-- local tab = vim.api.nvim_buf_get_option(bufnr, "shiftwidth")
--- get current indentation string
function M.get_indent()
	-- TODO:
	return "\t"
end

return M
