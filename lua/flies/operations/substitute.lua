local M = require("flies.operations._op"):new {}

local sandwich = require("flies.utils.sandwich").sandwich
local editor = require "flies.utils.editor"

function M:pre()
	local char = vim.fn.nr2char(vim.fn.getchar())
	if char == editor.t "<esc>" then return end
	return char
end

function M:run(params) sandwich(self, params, true, true) end

function M.exec(mode)
	if mode == "n" then M:normal {} end
end

return M
