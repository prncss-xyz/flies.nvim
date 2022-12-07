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

local function forwards_co(self, bufnr, pos)
	local last = math.min(pos[1] + self.lookahead - 1, buffers.get_eob(bufnr))
	for row = pos[1], last do
		local line = buffers.get_line(bufnr, row)
		for _, match in ipairs(self:get_matches(self.patterns, line)) do
			local _, s, e = unpack(match)
			local os = { row, s }
			if lists.cmp(pos, os) < 0 then
				local oe = { row, e }
				local isc, iec = self:map(bufnr, row, s, e)
				if isc then coroutine.yield { os, { row, isc }, { row, iec }, oe } end
			end
		end
	end
end

function M:iterate_forwards(bufnr, pos)
	return coroutine.wrap(function() forwards_co(self, bufnr, pos) end)
end

local function backwards_co(self, bufnr, pos)
	local last = math.max(pos[1] - self.lookahead + 1, 1)
	for row = pos[1], last, -1 do
		local line = buffers.get_line(bufnr, row)
		for _, match in lists.ripairs(self:get_matches(self.patterns, line)) do
			local _, s, e = unpack(match)
			local oe = { row, e }
			if lists.cmp(oe, pos) < 0 then
				local os = { row, s }
				local isc, iec = self:map(bufnr, row, s, e)
				if isc then coroutine.yield { os, { row, isc }, { row, iec }, oe } end
			end
		end
	end
end

function M:iterate_backwards(bufnr, pos)
	return coroutine.wrap(function() backwards_co(self, bufnr, pos) end)
end

return M
