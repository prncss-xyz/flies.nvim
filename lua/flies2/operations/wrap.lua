local M = require("flies2.operations._op"):new {}

local sandwich = require("flies2.utils.sandwich").sandwich
local editor = require "flies2.utils.editor"

function M:pre()
	local char = vim.fn.nr2char(vim.fn.getchar())
	if char == editor.t "<esc>" then return end
	return char
end

function M:run(params) sandwich(self, params, true, false) end

function M.exec(mode)
	if mode == "n" then
		M:normal()
	elseif mode == "x" then
		M:visual()
	end
end

return M
