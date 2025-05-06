---@class Substitute: _Operator
local M = require("flies.operations._operator"):new {}

function M:pre()
	local char = vim.fn.nr2char(vim.fn.getchar())
	if char == require("flies.utils.editor").esc then return end
	return char
end

function M:run(params)
	require("flies.utils.sandwich").sandwich(self, params, true, true)
end

function M.exec(mode)
	if mode == "n" then M:normal {} end
end

return M
