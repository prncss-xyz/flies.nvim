---@class _Subline: _Fly
---@field patterns sublinePattern[]
local M = require("flies.flies._fly"):new {}

local buffers = require "flies.utils.buffers"
local lists = require "flies.utils.lists"
local iterators = require "flies.utils.iterators"
local subline = require "flies.utils.subline"

---@param bufnr integer
---@param row integer
---@param i integer
---@param s integer
---@param e integer
---@param m any
---@return integer, integer
function M:map(bufnr, row, i, s, e, m) return s, e end

function M:iterate_upwards(bufnr, pos)
	local row, col = unpack(pos)
	local line = buffers.get_line(bufnr, row)
	for _, match in ipairs(subline.get_matches(self, self.patterns, line)) do
		local i, s, e, capture = unpack(match)
		if s <= col and col <= e then
			local isc, iec = self:map(bufnr, row, i, s, e, capture)
			if isc then
				return iterators.unit {
					index = i,
					capture = capture,
					outer = { { row, s }, { row, e } },
					inner = { { row, isc }, { row, iec } },
				}
			else
				break
			end
		elseif col < e then
			break
		end
	end
	return iterators.null()
end

---@param self _Subline
---@param bufnr integer
---@param fwd boolean
---@param pos integer[]
local function np_co(self, bufnr, fwd, pos)
	for row, line in buffers.get_lines(bufnr, fwd, pos[1], self.lookahead) do
		for _, match in lists.bipairs(fwd, subline.get_matches(self, self.patterns, line)) do
			local i, s, e, capture = unpack(match)
			local outer = { { row, s }, { row, e } }
			if lists.relative_pos(pos, outer) == (fwd and "forward" or "backward") then
				local isc, iec = self:map(bufnr, row, i, s, e)
				if isc then
					coroutine.yield {
						index = i,
						capture = capture,
						outer = outer,
						inner = { { row, isc }, { row, iec } },
					}
				end
			end
		end
	end
end

---@param bufnr integer
---@param pos integer[][]
---@return fun()
function M:iterate_forwards(bufnr, pos)
	return coroutine.wrap(function() np_co(self, bufnr, true, pos) end)
end

---@param bufnr integer
---@param pos integer[][]
function M:iterate_backwards(bufnr, pos)
	return coroutine.wrap(function() np_co(self, bufnr, false, pos) end)
end

return M
