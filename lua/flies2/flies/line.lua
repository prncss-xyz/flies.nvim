local M = require("flies2.flies._subline"):new {}
local buffers = require "flies2.utils.buffers"

M.solid = true

M.lonely_wiseness_inner = "V"
M.lonely_wiseness_outer = "V"
M.around_line_pattern = false

local function pattern(_, line, init)
	if init > 1 then return end
	local len = line:len()
	if len == 0 then len = 1 end
	return 1, len, line
end

function M:map(_, _, _, s, e, capture)
	if capture == "" then return s, e end
	local s_ = capture:find "%S"
	if s_ == nil then return s, e end
	local e_ = e
	while capture:sub(e_, e_):find "%s" do
		e_ = e_ - 1
	end
	return s_, e_
end

function M:right(bufnr, cursor, _)
	local row = cursor[1]
	local line = buffers.get_line(bufnr, row)
	local e = line:len()
	while line:sub(e, e):find "%s" do
		e = e - 1
	end
	return { cursor, { row, e } }, "v"
end

function M:left(bufnr, cursor, _)
	local row, col = unpack(cursor)
	col = col - 1
	if col == 0 then col = 1 end
	local line = buffers.get_line(bufnr, row)
	local s = line:find "%S" or 1
	return { { row, s }, { row, col } }, "v"
end

M.patterns = { pattern }

return M
