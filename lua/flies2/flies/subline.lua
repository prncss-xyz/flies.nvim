local M = require("flies2.flies.fly"):new {}

local buffers = require "flies2.utils.buffers"
local lists = require "flies2.utils.lists"
local iterators = require "flies2.utils.iterators"

M.lookahead = 200

-- M.pattern

--TODO: pattern to function
--TODO: helpers: pattern list to fn
--TODO: map_inner

local function get_matches(self, line)
	local matches = {}
	local s
	local e = 0
	while true do
		s, e = line:find(self.pattern, e + 1, false)
		if s then
			table.insert(matches, { s, e })
		else
			break
		end
	end
	return matches
end

function M:iterate_upwards(pos)
	local row = pos[1]
	local line = buffers.get_line(0, row)
	for _, match in ipairs(get_matches(self, line)) do
		local s = { row, match[1] }
		local e = { row, match[2] }
		if lists.cmp(s, pos) <= 0 then
			if lists.cmp(pos, e) <= 0 then return iterators.unit { s, s, e, e } end
		elseif lists.cmp(pos, s) < 0 then
			break
		end
	end
	return iterators.null()
end

local function forwards_co(self, pos)
	local last = math.min(pos[1] + self.lookahead - 1, buffers.get_eob(0))
	for row = pos[1], last do
		local line = buffers.get_line(0, row)
		for _, match in ipairs(get_matches(self, line)) do
			local s = { row, match[1] }
			if lists.cmp(pos, s) < 0 then
				local e = { row, match[2] }
				coroutine.yield { s, s, e, e }
			end
		end
	end
end

function M:iterate_forwards(pos)
	return coroutine.wrap(function() forwards_co(self, pos) end)
end

local function backwards_co(self, pos)
	local last = math.max(pos[1] - self.lookahead + 1, 1)
	for row = pos[1], last, -1 do
		local line = buffers.get_line(0, row)
		for _, match in lists.ripairs(get_matches(self, line)) do
			local s = { row, match[1] }
			if lists.cmp(pos, s) > 0 then
				local e = { row, match[2] }
				coroutine.yield { s, s, e, e }
			end
		end
	end
end

function M:iterate_backwards(pos)
	return coroutine.wrap(function() backwards_co(self, pos) end)
end

return M
