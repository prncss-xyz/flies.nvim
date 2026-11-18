---@class _Subline: _Fly
---@field patterns sublinePattern[]
local M = require("flies.flies._fly"):new {}

---@param bufnr integer
---@param row integer
---@param i integer
---@param s integer
---@param e integer
---@param m any
---@return integer, integer
function M:map(bufnr, row, i, s, e, m) return s, e end

function M:iterate_upwards(bufnr, pos)
	local buffers = require "flies.utils.buffers"
	local iterators = require "flies.utils.iterators"
	local subline = require "flies.utils.subline"
	local row, col = unpack(pos)
	local line = buffers.get_line(bufnr, row)
	local res = {}
	for _, match in ipairs(subline.get_matches(self, self.patterns, line)) do
		local i, s, e, capture = unpack(match)
		if col < s then break end
		if col <= e then
			local isc, iec = self:map(bufnr, row, i, s, e, capture)
			if isc then
				table.insert(res, 1, {
					index = i,
					capture = capture,
					outer = { { row, s }, { row, e } },
					inner = { { row, isc }, { row, iec } },
				})
			end
		end
	end
	return iterators.from_list_single(res)
end

---@param self _Subline
---@param bufnr integer
---@param fwd boolean
---@param pos integer[]
local function np_co(self, bufnr, fwd, pos)
	local buffers = require "flies.utils.buffers"
	local lists = require "flies.utils.lists"
	local subline = require "flies.utils.subline"
	for row, line in buffers.get_lines(bufnr, fwd, pos[1], self.lookahead) do
		local matches = subline.get_matches(self, self.patterns, line)
		if self.nested and not fwd then
			table.sort(
				matches,
				function(a, b) return a[3] < b[3] or (a[3] == b[3] and a[2] > b[2]) end
			)
		end
		for _, match in lists.bipairs(fwd, matches) do
			local i, s, e, capture = unpack(match)
			local outer = { { row, s }, { row, e } }
			if lists.relative_pos(pos, outer) == (fwd and "forward" or "backward") then
				local isc, iec = self:map(bufnr, row, i, s, e, capture)
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
