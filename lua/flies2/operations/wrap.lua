local M = require("flies2.operations._op"):new {}

local buffers = require "flies2.utils.buffers"
local editor = require "flies2.utils.editor"

function M:pre()
	local char = vim.fn.nr2char(vim.fn.getchar())
	if char == editor.t "<esc>" then return end
	return char
end

function M:run(params)
	local range = params.range
	local left, right
	local char = params.pre
	local c = self:get_config("wrap", char, params.target)
	if c.left then
		left = c.left
		right = c.right
	elseif char:match "%p" then
		left = char
		right = char
	else
		return
	end
	buffers.subs(0, range, range, params.wiseness, left, right, editor.indent())
end

function M.exec(mode)
	if mode == "n" then
		M:normal()
	elseif mode == "x" then
		M:visual()
	end
end

return M
