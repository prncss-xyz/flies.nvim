---@class Wrap: _Operator
local M = require("flies.operations._operator"):new {}

function M:pre()
	local editor = require "flies.utils.editor"
	local char = vim.fn.nr2char(vim.fn.getchar())
	if char == editor.t "<esc>" then return end
	return char
end

function M:run(params)
	local sandwich = require("flies.utils.sandwich").sandwich
	sandwich(self, params, true, false)
end

M.allowed_modes = "nx"
M.default_opts = { domain = "outer", around = "never" }

return M
