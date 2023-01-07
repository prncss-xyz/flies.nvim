local M = require("flies2.flies._fly"):new {}

M.solid = true

local iterators = require "flies2.utils.iterators"
local buffers = require "flies2.utils.buffers"

local function inner_start(bufnr)
	for row, line in buffers.get_lines(bufnr, true, 1) do
		local start = string.find(line, "%S")
		if start then return { row, start } end
	end
	return { 1, 1 }
end

local function inner_end(bufnr)
	local eob = buffers.get_eob(bufnr)
	for row, line in buffers.get_lines(buffers, false, eob) do
		local end_ = string.find(line, ".%s*$")
		if end_ then return { row, end_ } end
	end
end

local function outer_end(bufnr)
	local eob = buffers.get_eob(bufnr)
	local line = buffers.get_line(bufnr, eob)
	local col = line:len()
	if col == 0 then col = 1 end
	return { eob, col }
end

function M.iterate_upwards(bufnr)
	local outer = { { 1, 1 }, outer_end(0) }
	local inner = { inner_start(bufnr), inner_end(bufnr) }
	return iterators.once { outer = outer, inner = inner }
end

M.iterate_forwards = iterators.null()
M.iterate_backwards = iterators.null()

return M
