local M = require("flies2.flies.fly"):new {}

-- TODO: quote, line, variable_segment, dot_segment,

local buffers = require "flies2.utils.buffers"
local lists = require "flies2.utils.lists"
local iterators = require "flies2.utils.iterators"

M.lookahead = 200
function M:map(bufnr, row, s, e) return s, e end
-- M.patterns = {}

local function get_matches(self, line)
	local matches = {}
	local s
	local e = 0
	local ss = {}
	local ee = {}
	while true do
		local init = e + 1
		s = nil
		for i, pattern in ipairs(self.patterns) do
			if ss[i] == nil or ss[i] < init then
				if type(pattern) == "string" then
					ss[i], ee[i] = line:find(pattern, init)
				else
					ss[i], ee[i] = pattern(self, line, init)
				end
			end
			if not s or ss[i] and ss[i] < s then
				s, e = ss[i], ee[i]
			end
		end
		if s then
			table.insert(matches, { s, e })
		else
			break
		end
	end
	return matches
end

function M:iterate_upwards(bufnr, pos)
	local row = pos[1]
	local line = buffers.get_line(bufnr, row)
	for _, match in ipairs(get_matches(self, line)) do
		local os = { row, match[1] }
		local oe = { row, match[2] }
		if lists.cmp(os, pos) <= 0 then
			if lists.cmp(pos, oe) <= 0 then
				local isc, iec = self:map(bufnr, row, match[1], match[2])
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
		for _, match in ipairs(get_matches(self, line)) do
			local os = { row, match[1] }
			if lists.cmp(pos, os) < 0 then
				local oe = { row, match[2] }
				local isc, iec = self:map(bufnr, row, match[1], match[2])
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
		for _, match in lists.ripairs(get_matches(self, line)) do
			local oe = { row, match[2] }
			if lists.cmp(oe, pos) < 0 then
				local os = { row, match[1] }
				local isc, iec = self:map(bufnr, row, match[1], match[2])
				if isc then coroutine.yield { os, { row, isc }, { row, iec }, oe } end
			end
		end
	end
end

function M:iterate_backwards(bufnr, pos)
	return coroutine.wrap(function() backwards_co(self, bufnr, pos) end)
end

return M
