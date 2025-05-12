---@class Buffer: _Fly
local M = require("flies.flies._fly"):new {}

M.solid = true

local iterators = require "flies.utils.iterators"
local buffers = require "flies.utils.buffers"

local function inner_start(bufnr)
	for row, line in buffers.get_lines(bufnr, true, 1) do
		local start = string.find(line, "%S")
		if start then return { row, start } end
	end
	return { 1, 1 }
end

local function inner_end(bufnr)
	local eob = buffers.get_eob(bufnr)
	for row, line in buffers.get_lines(bufnr, false, eob) do
		local end_ = string.find(line, ".%s*$")
		if end_ then return { row, end_ } end
	end
end

local function outer_end(bufnr)
	local eob = buffers.get_eob(bufnr)
	local line = buffers.get_line(bufnr, eob)
	local col = math.max(1, line:len())
	if col == 0 then col = 1 end
	return { eob, col }
end

function M:iterate_upwards(bufnr)
	local outer = { { 1, 1 }, outer_end(0) }
	local inner = { inner_start(bufnr), inner_end(bufnr) }
	return iterators.unit { outer = outer, inner = inner }
end

---@param opts opts
function M:move(opts)
	local windows = require "flies.utils.windows"
	local eob = buffers.get_eob(0)
	local row
	if opts.axis == "forward" then
		row = opts.count and opts.count or eob
		row = math.min(row, eob)
	elseif opts.axis == "backward" then
		row = opts.count and eob + 1 - opts.count or 1
		row = math.max(row, 1)
	else
		return
	end
	local line = buffers.get_line(0, row)
	windows.set_cursor { row, require("flies.utils.buffers").get_eol(line) }
	opts.count = 1
	require("flies.flies.line"):register(opts)
end

M.iterate_forwards = iterators.null
M.iterate_backwards = iterators.null

return M
