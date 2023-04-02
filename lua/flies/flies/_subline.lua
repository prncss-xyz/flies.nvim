local M = require("flies.flies._fly"):new {}

-- TODO: variable_segment, dot_segment,

local buffers = require "flies.utils.buffers"
local lists = require "flies.utils.lists"
local iterators = require "flies.utils.iterators"

function M:map(bufnr, row, i, s, e, m) return s, e end
-- M.patterns = {}

function M:get_matches(patterns, line)
	local matches = {}
	local res = {}
	local init = 1
	while true do
		local i
		for i_, pattern in ipairs(patterns) do
			if res[i_] == nil or type(res[i_]) == "table" and res[i_][2] < init then
				local s, e, capture
				if type(pattern) == "string" then
					s, e, capture = line:find(pattern, init)
				else
					s, e, capture = pattern(self, line, init)
				end
				if s then
					res[i_] = { i_, s, e, capture }
				else
					res[i_] = "done"
				end
			end
			if type(res[i_]) == "table" then
				if not i or res[i_][2] < res[i][2] then i = i_ end
			else
				assert(res[i_] == "done", "faulty logic")
			end
		end
		if not i then return matches end
		table.insert(matches, res[i])
		init = res[i][3] + 1
	end
end

function M:iterate_upwards(bufnr, pos)
	local row, col = unpack(pos)
	local line = buffers.get_line(bufnr, row)
	for _, match in ipairs(self:get_matches(self.patterns, line)) do
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

local function np_co(self, bufnr, fwd, pos)
	for row, line in buffers.get_lines(bufnr, fwd, pos[1], self.lookahead) do
		for _, match in lists.bipairs(fwd, self:get_matches(self.patterns, line)) do
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

function M:iterate_forwards(bufnr, pos)
	return coroutine.wrap(function() np_co(self, bufnr, true, pos) end)
end

function M:iterate_backwards(bufnr, pos)
	return coroutine.wrap(function() np_co(self, bufnr, false, pos) end)
end

return M
