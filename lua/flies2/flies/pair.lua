local M = require("flies2.flies.subline"):new {}

function M.validator(i, m, j, m_) return i == j and m == m_ end

local buffers = require "flies2.utils.buffers"
local lists = require "flies2.utils.lists"

local function process_pair_patterns(self)
	local patterns = {}
	for i, pattern in ipairs(self.left_patterns) do
		patterns[i] = pattern
	end
	local offset = #patterns
	for i, pattern in ipairs(self.right_patterns) do
		patterns[i + offset] = pattern
	end
	return patterns
end

local function is_opening(fwd, left_len, i)
	local is_left = i <= left_len
	if fwd then return is_left end
	return not is_left
end

local function get_half_range(fwd, opening, row, line, line_, s, e)
	local inner, outer, find_next
	if fwd == opening then
		outer = { row, s }
		if line:sub(e + 1):match "^%s*$" then
			inner = { row + 1, 1 }
		else
			inner = { row, e + 1 }
		end
	else
		outer = { row, e }
		if line:sub(1, s - 1):match "^%s*$" then
			if fwd then
				inner = { row - 1, line_:len() }
			else
				find_next = true
			end
		else
			inner = { row, s - 1 }
		end
	end
	return inner, outer, find_next
end

local function np_co(self, fwd, bufnr, pos)
	local patterns = process_pair_patterns(self)
	local last = fwd
			and math.min(pos[1] + self.lookahead - 1, buffers.get_eob(bufnr))
		or math.max(pos[1] - self.lookahead + 1, 1)
	local sgn = fwd and 1 or -1
	local _ipairs = fwd and ipairs or lists.ripairs
	local finding = {}
	local found = {}
	local opening
	local prev_line, line
	local find_next
	for row = pos[1], last, sgn do
		prev_line = line
		line = buffers.get_line(bufnr, row)
		if find_next then
			find_next = false
			opening.inner = { row, line:len() }
		end
		local matches = self:get_matches(patterns, line)
		for _, match in _ipairs(matches) do
			local i, s, e, m = unpack(match)
			if lists.cmp({ row, s }, pos) == sgn then
				if is_opening(fwd, #self.left_patterns, i) then
					-- current match is an opening pattern (left)
					if opening then table.insert(finding, opening) end
					local inner, outer
					inner, outer, find_next =
						get_half_range(fwd, true, row, line, prev_line, s, e)
					opening = {
						i = i,
						m = m,
						inner = inner,
						outer = outer,
					}
				else
					-- current match is a closing pattern (right)
					-- does current match corresponds to opening pattern we are looking for?
					if opening then
						local valid
						if fwd then
							valid = self.validator(opening.i, opening.m, i - #self.left_patterns, m)
						else
							valid = self.validator(i, m, opening.i - #self.left_patterns, opening.m)
						end
						if valid then
							local inner, outer =
								get_half_range(fwd, false, row, line, prev_line, s, e)
							if fwd then
								table.insert(found, {
									opening.outer,
									opening.inner,
									inner,
									outer,
								})
							else
								table.insert(found, {
									outer,
									inner,
									opening.inner,
									opening.outer,
								})
							end
							opening = table.remove(finding)
							if not opening then
								for _, res in lists.ripairs(found) do
									coroutine.yield(res)
								end
								found = {}
							end
						end
					else
						-- return match if upward
					end
				end
			end
		end
	end
end

function M:iterate_forwards(bufnr, pos)
	return coroutine.wrap(function() np_co(self, true, bufnr, pos) end)
end

function M:iterate_backwards(bufnr, pos)
	return coroutine.wrap(function() np_co(self, false, bufnr, pos) end)
end

return M
