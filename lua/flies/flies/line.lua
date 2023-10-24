---@class Line: _Fly
local M = require("flies.flies._fly"):new {}

M.solid = true
M.lonely_wiseness_inner = "v"
M.lonely_wiseness_outer = "V"

local buffers = require "flies.utils.buffers"

function M:around(_, match)
	-- local outer, wiseness = self:get_wiseness(0, match, "outer")
	return match.around, "V"
end

local function get_line(bufnr, row)
	local line = buffers.get_line(bufnr, row)
	local s, e = buffers.get_bol(line), buffers.get_eol(line)
	local len = math.max(1, line:len())
	local around = { { row, 1 }, { row, len } }
	local inner = { { row, s }, { row, e } }
	return {
		around = around,
		outer = inner,
		inner = inner,
	}

end

local function iter(bufnr, fwd, incl, pos)
	local sgn = fwd and 1 or -1
	local row = pos[1]
	if incl then row = row - sgn end
	local eob = buffers.get_eob(bufnr)
	return function()
		row = row + sgn
		if row < 1 then return end
		if row > eob then return end
		return get_line(bufnr, row)
	end
end

function M:iterate_upwards(bufnr, pos) return iter(bufnr, true, true, pos) end

function M:iterate_forwards(bufnr, pos) return iter(bufnr, true, false, pos) end

function M:iterate_backwards(bufnr, pos) return iter(bufnr, false, false, pos) end

return M
