local M = {}

function M.t(str) return vim.api.nvim_replace_termcodes(str, true, true, true) end

function M.indent() return "\t" end

return M
