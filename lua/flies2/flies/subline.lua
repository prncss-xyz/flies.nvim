local M = require("flies2.flies.fly"):new {}

-- TODO: variable_segment, dot_segment,

local buffers = require "flies2.utils.buffers"
local lists = require "flies2.utils.lists"
local iterators = require "flies2.utils.iterators"

M.lookahead = 200

function M:map(bufnr, row, s, e) return s, e end
-- M.patterns = {}

function M:get_matches(patterns, line)
	local matches = {}
	local res = {}
	local init = 1
	while true do
		local i
		for i_, pattern in ipairs(patterns) do
			if res[i_] == nil or type(res[i_]) == "table" and res[i_][2] < init then
				local s, e, m
				if type(pattern) == "string" then
					s, e, m = line:find(pattern, init)
				else
					s, e, m = pattern(self, line, init)
				end
				if s then
					res[i_] = { i_, s, e, m }
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
	local row = pos[1]
	local line = buffers.get_line(bufnr, row)
	for _, match in ipairs(self:get_matches(self.patterns, line)) do
		local _, s, e = unpack(match)
		local os = { row, s }
		local oe = { row, e }
		if lists.cmp(os, pos) <= 0 then
			if lists.cmp(pos, oe) <= 0 then
				local isc, iec = self:map(bufnr, row, s, e)
				if isc then
					return iterators.unit { os, { row, isc }, { row, iec }, oe }
				else
					break
				end
			end
		elseif lists.cmp(pos, os) < 0 then
			break
		end
	end
	return iterators.null()
end

local function np_co(self, bufnr, fwd, pos)
	local sgn = fwd and 1 or -1
	for row, line in buffers.get_lines(bufnr, fwd, pos[1]) do
		for _, match in lists.bipairs(fwd, self:get_matches(self.patterns, line)) do
			local _, s, e = unpack(match)
			local os = { row, s }
			if lists.cmp(os, pos) == sgn then
				local oe = { row, e }
				local isc, iec = self:map(bufnr, row, s, e)
				if isc then coroutine.yield { os, { row, isc }, { row, iec }, oe } end
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
